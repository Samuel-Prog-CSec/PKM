---
tags:
  - Go
  - Go/Redes
  - Escaneo
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - El paquete net y el modelo de conexión]]"
Nota siguiente: "[[02 - Proxy TCP con io.Copy]]"
Area: "[[Redes TCP-IP.base|Redes TCP-IP]]"
---
---

El primer tool real: un escáner de puertos. Lo importante no es el escáner en sí —para eso está [[00 - Introducción a Nmap|Nmap]]— sino cómo se lleva un programa de **correcto pero lento** a **concurrente y acotado**, el patrón que reutilizarás en todo el tooling de red. El libro llega hasta un *worker pool* montado a mano; aquí lo modernizamos a la versión de 2026.

## El escaneo secuencial

La base es la de la nota anterior: `net.Dial` a cada puerto, y si no hay error, está abierto.

```go
func main() {
    for port := 1; port <= 1024; port++ {
        addr := net.JoinHostPort("scanme.nmap.org", strconv.Itoa(port))
        conn, err := net.Dial("tcp", addr)
        if err != nil {
            continue                // cerrado o filtrado
        }
        conn.Close()
        fmt.Printf("%d/tcp open\n", port)
    }
}
```

Dos mejoras ya sobre el libro: `net.JoinHostPort` en vez de `fmt.Sprintf("%s:%d")` —maneja bien las IPv6 con corchetes (`[::1]:80`)— y, sobre todo, el problema del timeout. <mark style="background: #FF5582A6;">Un `net.Dial` pelado espera ~1-2 minutos (retransmisión de `SYN` del SO) en cada puerto filtrado</mark>, así que escanear 1024 puertos de un host protegido tarda una eternidad. Correcto, pero inservible a escala.

## El salto naïf: la versión "demasiado rápida"

La tentación es envolver el `Dial` en una goroutine sin más:

```go
for port := 1; port <= 1024; port++ {
    go func() {
        // ... Dial ...
    }()
}
// main termina aquí -> el programa sale antes de que las goroutines acaben
```

Y el programa sale **casi instantáneamente**, sin resultados fiables: `main` no espera a las goroutines y termina en cuanto acaba el bucle, con los paquetes aún en vuelo. Es el anti-patrón que ya viste en [[13 - Goroutines, channels y concurrencia]]: toda goroutine necesita una forma de esperarla.

## Sincronizar con `WaitGroup`

La corrección clásica es un `sync.WaitGroup` (en Go 1.25, el método `wg.Go`):

```go
var wg sync.WaitGroup
for port := 1; port <= 1024; port++ {
    wg.Go(func() {
        // ... Dial al puerto ...
    })
}
wg.Wait()   // bloquea hasta que todas terminan
```

Ahora sí espera. Pero sigue mal a escala: <mark style="background: #FFB8EBA6;">esto lanza **todas** las goroutines de golpe</mark> — 65.535 conexiones simultáneas contra un host. El SO, la red o el propio objetivo no dan abasto y los resultados salen inconsistentes (falsos "cerrados" de conexiones que nunca llegaron a intentarse bien). Falta lo esencial: **acotar** cuántas corren a la vez.

## Acotar la concurrencia: `errgroup.SetLimit`

El libro resuelve esto con un *worker pool* manual: 100 goroutines *worker*, un channel de puertos, otro de resultados y un `sort` final — unas 40 líneas de fontanería de channels. La forma moderna es **`errgroup` con `SetLimit`** (`golang.org/x/sync/errgroup`), que acota la concurrencia y recoge errores en una fracción del código:

```go
func scanPort(ctx context.Context, host string, port int) bool {
    addr := net.JoinHostPort(host, strconv.Itoa(port))
    var d net.Dialer
    conn, err := d.DialContext(ctx, "tcp", addr)   // respeta el timeout del ctx
    if err != nil {
        return false                                // cerrado o filtrado
    }
    conn.Close()
    return true
}

func main() {
    host := "scanme.nmap.org"
    g, ctx := errgroup.WithContext(context.Background())
    g.SetLimit(100)                     // <- como máximo 100 conexiones a la vez

    var mu sync.Mutex
    var open []int
    for port := 1; port <= 1024; port++ {
        g.Go(func() error {
            pctx, cancel := context.WithTimeout(ctx, 2*time.Second)
            defer cancel()
            if scanPort(pctx, host, port) {
                mu.Lock()
                open = append(open, port)   // el slice es estado compartido -> Mutex
                mu.Unlock()
            }
            return nil
        })
    }
    g.Wait()

    slices.Sort(open)                   // slices.Sort de la nota 06
    for _, p := range open {
        fmt.Printf("%d/tcp open\n", p)
    }
}
```

Tres piezas que juntan todo el bloque de fundamentos: `SetLimit(100)` acota las goroutines simultáneas; `DialContext` con un `context.WithTimeout` de 2 s por puerto <mark style="background: #8000E1A6;">hace que un puerto filtrado falle en 2 s en vez de colgar el escáner</mark> (nota [[13 - Goroutines, channels y concurrencia]]); y el `Mutex` protege el slice de resultados (recuerda de [[06 - Slices, arrays y maps]] que escribir concurrentemente sin proteger revienta).

> [!important]+ El límite de concurrencia es OPSEC, no solo rendimiento
> <mark style="background: #FFB86CA6;">Miles de conexiones simultáneas disparan protecciones anti-SYN-flood, rate-limiting y alertas de IDS/IPS.</mark> El `SetLimit` bajo y un ritmo controlado son la diferencia entre un escaneo que pasa desapercibido y uno que enciende todas las alarmas — el "properly throttled scanner" que el libro persigue. Un tool serio expone el límite como flag (`--rate`, `--concurrency`) para que el operador ajuste sigilo vs velocidad. La técnica de escaneo sigiloso a fondo (timing templates, decoys, fragmentación) vive en [[00 - Introducción a Nmap|Nmap]] y en Red Team.

Este `net.Dial` como cliente ya te da un escáner. La otra cara del paquete `net` —montar un servidor y relayar tráfico— es el proxy TCP → [[02 - Proxy TCP con io.Copy]].
