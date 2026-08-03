---
tags:
  - Go
  - Go/Fundamentos
  - Errores
Descripción: "Go no tiene try/catch. Un error es solo un valor —un tipo con el método Error() string (nota 10 - Interfaces)— que las funciones devuelven como último resultado y que compruebas…"
Fecha de actualización: 2026-07-24
Nota previa: "[[10 - Interfaces]]"
Nota siguiente: "[[12 - JSON, XML y datos estructurados]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Go no tiene `try/catch`. Un `error` es solo un valor —un tipo con el método `Error() string` (nota [[10 - Interfaces]])— que las funciones devuelven como último resultado y que <mark style="background: #ADCCFFA6;">compruebas donde ocurre, en vez de dejarlo "burbujear" solo</mark>. Aquí es donde el libro (Go 1.11) está más anticuado: no conoce el *wrapping* con `%w` ni `errors.Is/As`, que desde Go 1.13 son el estándar. Esta nota es Go moderno, no el del libro.

## Crear y devolver errores

Dos formas de fabricar un error:

```go
errors.New("connection refused")              // error simple
fmt.Errorf("scanning %s: port %d", host, p)   // error con formato
```

Convención de estilo que conviene respetar: <mark style="background: #FFB8EBA6;">el mensaje va en minúscula y sin punto final</mark>, porque casi siempre se concatena dentro de otro error mayor (`"scanning host: connection refused"` se lee mal si cada trozo lleva mayúscula y punto).

## Envolver con `%w`: contexto sin perder la causa

El verbo `%w` de `fmt.Errorf` **envuelve** un error: le añade contexto conservando el original en una cadena que luego puedes inspeccionar. Es la diferencia entre un error que te dice *dónde* falló y uno mudo:

```go
func connect(target string) error {
    conn, err := net.Dial("tcp", target)
    if err != nil {
        return fmt.Errorf("conectando a %s: %w", target, err)  // envuelve, no aplasta
    }
    defer conn.Close()
    return nil
}
```

<mark style="background: #8000E1A6;">Al propagar hacia arriba, cada capa añade su contexto</mark> y acabas con un rastro tipo `"escaneando target: conectando a 10.10.10.1:445: connection refused"`. Usa `%w` **dentro** de tu programa (mantiene la cadena) y `%v` en las **fronteras** (logs, respuestas al usuario) cuando no quieras exponer la causa interna.

## Inspeccionar la cadena: `errors.Is` y `errors.As`

Con errores envueltos ya no puedes comparar con `==`. Dos funciones recorren la cadena por ti:

- **`errors.Is(err, ErrX)`** — ¿hay en algún punto de la cadena este error *centinela* concreto?
- **`errors.As(err, &target)`** — ¿hay un error de este *tipo*? Si sí, lo extrae para leer sus campos.

```go
var ErrRateLimited = errors.New("rate limited")   // centinela de paquete

if errors.Is(err, ErrRateLimited) {
    time.Sleep(backoff)          // el WAF nos frena -> esperar y reintentar
}

var dnsErr *net.DNSError         // error tipado de la stdlib
if errors.As(err, &dnsErr) && dnsErr.IsTimeout {
    // tratar el timeout de resolución DNS de forma específica
}
```

Esto sustituye al `if err == ErrX` directo del libro, que se rompe en cuanto alguien envuelve el error. Usa **centinelas** (`var ErrX = errors.New(...)`) para condiciones esperadas, y **tipos de error propios** (un struct con método `Error()`) cuando el error necesita transportar datos.

> [!info]+ `errors.AsType` en Go 1.26
> Go 1.26 añade `errors.AsType[T](err)`, la versión genérica y type-safe de `errors.As`: `dnsErr, ok := errors.AsType[*net.DNSError](err)`. Más limpio que declarar la variable y pasar su puntero. Como el curso apunta a Go 1.26, prefiérela cuando `T` sea un `error`.

Para agrupar varios errores independientes (p. ej. los fallos de cerrar varios recursos), `errors.Join(err1, err2)` (Go 1.20) los combina en uno solo que `errors.Is`/`As` siguen sabiendo recorrer.

> [!important]+ La regla de oro: loggear O devolver, nunca ambas
> <mark style="background: #FF5582A6;">Un error se maneja **una** vez: o lo registras, o lo devuelves — no las dos cosas.</mark> Loggear *y* devolver el mismo error genera líneas duplicadas en tus agregadores y ruido imposible de rastrear. Regla práctica: las capas internas **devuelven** (envolviendo con `%w`); la capa más alta (el `main`, el handler) **registra** una vez y decide. Para ese log, en 2026 se usa `log/slog` (structured logging), no `fmt.Println` ni `log.Printf`.

## `panic` y `recover`: solo para lo irrecuperable

`panic` aborta la ejecución y desenrolla la pila; `recover`, dentro de un `defer`, la atrapa. <mark style="background: #FF5582A6;">No son para el flujo normal de errores</mark> — un puerto cerrado o un DNS que no resuelve son valores `error`, no panics. Se reservan para estados genuinamente imposibles (un invariante roto, un índice fuera de rango).

El uso ofensivo legítimo: <mark style="background: #FFB86CA6;">un `recover` en el borde de cada goroutine mantiene vivo un servidor de larga duración</mark> aunque un handler concreto entre en panic. Para un C2 o un implante, que un fallo puntual no te tire toda la sesión es crítico:

```go
func handleConn(conn net.Conn) {
    defer func() {
        if r := recover(); r != nil {
            slog.Error("recuperado en handler", "panic", r)  // el server sigue en pie
        }
    }()
    // ... lógica que, ante entrada malformada, podría entrar en panic
}
```

Con los errores dominados, el último tema de datos: serializar y deserializar estructuras a JSON y XML, la base de hablar con APIs y protocolos → [[12 - JSON, XML y datos estructurados]].
