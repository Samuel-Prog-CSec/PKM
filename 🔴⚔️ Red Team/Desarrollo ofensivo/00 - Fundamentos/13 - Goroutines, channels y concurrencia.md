---
tags:
  - Go
  - Go/Fundamentos
  - Concurrencia
Descripción: "La concurrencia es la razón principal por la que Go domina el tooling de red: un escáner de miles de puertos cabe en veinte líneas"
Fecha de actualización: 2026-07-24
Nota previa: "[[12 - JSON, XML y datos estructurados]]"
Nota siguiente: 
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

La concurrencia es <mark style="background: #ADCCFFA6;">la razón principal por la que Go domina el tooling de red</mark>: un escáner de miles de puertos cabe en veinte líneas. El libro enseña lo básico pero con un anti-patrón grave (`time.Sleep` para sincronizar). Esta nota es la versión moderna y correcta, y termina en el patrón que sostiene el escáner concurrente del Cap. 2.

## Goroutines y el anti-patrón del `time.Sleep`

`go f()` lanza `f` como **goroutine**: un hilo ligero que el runtime multiplexa sobre hilos del SO. Son tan baratas que lanzar miles es normal. El problema es sincronizarlas. El libro hace esto:

```go
go f()
time.Sleep(1 * time.Second)   // ❌ el anti-patrón: "espero que haya acabado en 1s"
```

<mark style="background: #FF5582A6;">Eso es una carrera</mark>: si `f` tarda más, pierdes el resultado; si tarda menos, malgastas tiempo. La regla moderna: toda goroutine necesita una salida clara y una forma de esperarla. Nunca `time.Sleep` para coordinar.

## Esperar con `sync.WaitGroup`

Un `WaitGroup` cuenta goroutines pendientes y bloquea hasta que todas terminan. Go 1.25 lo reduce al método `wg.Go`:

```go
var wg sync.WaitGroup
for _, port := range ports {
    wg.Go(func() {        // Go 1.25: encapsula Add(1) + go + Done()
        scan(host, port)
    })
}
wg.Wait()                 // bloquea hasta que TODAS terminan
```

En Go anterior a 1.25 se escribe a mano: `wg.Add(1)` **antes** del `go`, y `defer wg.Done()` dentro. Llamar a `Add` dentro de la goroutine es un bug clásico: `Wait` puede retornar antes de tiempo.

## Channels: comunicar en vez de compartir

El lema de Go es "no comuniques compartiendo memoria; comparte memoria comunicando". Un **channel** transfiere un valor —y su propiedad— de una goroutine a otra con el operador `<-`:

```go
results := make(chan string)                       // sin buffer: envío y recepción se citan
go func() { results <- scan(host, port) }()
r := <-results                                     // bloquea hasta que llega un valor
```

Tres reglas que evitan la mayoría de bugs:

- **Sin buffer por defecto.** `make(chan T)` sincroniza emisor y receptor; `make(chan T, n)` permite `n` envíos sin bloquear. Un buffer grande oculta *backpressure* — úsalo solo con motivo medido.
- **Solo el emisor cierra.** Enviar a un canal ya cerrado provoca `panic` (en la goroutine **emisora**), así que cerrar es responsabilidad de quien envía. `for r := range ch` drena hasta el cierre.
- **Declara la dirección** en las firmas (`chan<- T` solo envío, `<-chan T` solo recepción): el compilador impide el mal uso.

```go
func producer(out chan<- int) {   // esta función solo escribe
    defer close(out)              // el emisor cierra al terminar
    for _, p := range ports {
        out <- p
    }
}
```

## `select`: multiplexar y no colgarse

`select` espera sobre varias operaciones de channel a la vez. Combinado con `context`, es lo que impide que una conexión colgada bloquee para siempre:

```go
select {
case r := <-results:
    handle(r)
case <-ctx.Done():                 // cancelación
    return ctx.Err()
case <-time.After(2 * time.Second):
    return errTimeout
}
```

<mark style="background: #FFB8EBA6;">Incluye siempre `ctx.Done()` en un `select`</mark>: sin él, la goroutine sigue viva después de cancelar y se **filtra** (goroutine leak). Cada goroutine filtrada es memoria que no se libera hasta que el proceso muere.

## Estado compartido: Mutex y el detector de carreras

Cuando de verdad debes compartir estado, protégelo. Recuerda de [[06 - Slices, arrays y maps]] que dos goroutines escribiendo el mismo `map` **hacen crashear el programa**. Un `sync.Mutex` serializa el acceso; para un contador simple, un atómico tipado (`atomic.Int64`) es más barato:

```go
var mu sync.Mutex
open := map[int]bool{}
// dentro de cada goroutine:
mu.Lock()
open[port] = true
mu.Unlock()
```

> [!warning]+ Desarrolla siempre con `-race`
> Las *data races* son bugs no deterministas: fallan 1 de cada mil ejecuciones y nunca cuando depuras. El detector de carreras de Go las caza en el acto — `go run -race` y `go test -race ./...`. En tooling concurrente es innegociable.

## `context`: cancelar y acotar en el tiempo

`context.Context` propaga cancelación y *deadlines* por toda la cadena de llamadas. Un `context.WithTimeout` aborta una operación que tarda demasiado, para que un escáner no se quede clavado en un host mudo:

```go
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
defer cancel()
conn, err := (&net.Dialer{}).DialContext(ctx, "tcp", target)  // respeta el timeout
```

Tiene profundidad propia (skill `golang-context`); por ahora quédate con que el `ctx` viaja como **primer parámetro** de las funciones y `ctx.Done()` es la señal de parar.

## El patrón completo: escáner concurrente y acotado

Aquí converge todo el bloque. El libro monta a mano un pool de workers para "throttlear" el escáner. La forma moderna es **`errgroup` con `SetLimit`** (del paquete `golang.org/x/sync/errgroup`), que acota la concurrencia y propaga el primer error:

```go
import "golang.org/x/sync/errgroup"

g, ctx := errgroup.WithContext(ctx)
g.SetLimit(100)                    // como máximo 100 conexiones simultáneas
for _, port := range ports {
    g.Go(func() error {
        return scanPort(ctx, host, port)
    })
}
if err := g.Wait(); err != nil {   // espera a todas; devuelve el primer error
    return err
}
```

<mark style="background: #FFB86CA6;">Acotar la concurrencia no es solo higiene de recursos: es OPSEC.</mark> Miles de conexiones simultáneas disparan protecciones anti-SYN-flood, *rate-limiting* y alertas de IDS. El `SetLimit` y un ritmo controlado son lo que separa un escáner sigiloso de uno que enciende todas las alarmas — el "properly throttled" del libro, pero hecho como se hace hoy. La detección y evasión a fondo pertenecen al bloque de [[Redes TCP-IP.base|TCP]] y a Red Team.

---

Con esto cierras los **fundamentos de Go moderno**: tipos, control, funciones, datos, punteros, structs, interfaces, errores, serialización y concurrencia. Ya tienes el lenguaje entero para construir. El siguiente bloque lo aplica al primer tool real —un escáner y un proxy TCP— donde todo lo de esta nota paga: [[Redes TCP-IP.base|Redes TCP-IP]].
