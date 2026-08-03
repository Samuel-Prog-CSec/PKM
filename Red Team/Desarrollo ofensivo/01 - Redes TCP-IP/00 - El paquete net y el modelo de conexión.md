---
tags:
  - Go
  - Go/Redes
  - TCP
  - Tipo/Introduccion
Descripción: "Empieza la parte práctica: aplicar el Go de los fundamentos a construir tooling real"
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - Escáner TCP - de secuencial a concurrente]]"
Area: "[[Redes TCP-IP.base|Redes TCP-IP]]"
---
---

Empieza la parte práctica: aplicar el Go de los fundamentos a construir tooling real. Todo lo que harás en este bloque —escáner de puertos, proxy, reverse shell— sale de **un solo paquete de la stdlib, `net`**. Esta nota fija el modelo mental: cómo Go representa una conexión y las dos caras (cliente y servidor) que usarás en todo lo demás.

## Cliente: `net.Dial`

Para conectarte a un servicio, `net.Dial`:

```go
conn, err := net.Dial("tcp", "scanme.nmap.org:80")
if err != nil {
    // conexión fallida: puerto cerrado, filtrado, host inalcanzable...
}
defer conn.Close()
```

Dos argumentos: la **red** (`"tcp"`, pero también `"udp"`, `"tcp6"`, `"unix"`…) y la **dirección** como una sola cadena `host:puerto` (no un string y un int por separado). <mark style="background: #ADCCFFA6;">Devuelve una `net.Conn` y un `error`; si `error` es `nil`, estás conectado.</mark> `Dial` resuelve nombres DNS por ti, así que `scanme.nmap.org:80` funciona sin resolver la IP a mano.

## `net.Conn` es un stream: `Reader` + `Writer`

Aquí conecta con lo que aprendiste en [[10 - Interfaces]]. <mark style="background: #8000E1A6;">`net.Conn` implementa `io.Reader` e `io.Writer` a la vez</mark> (y `io.Closer`): una conexión TCP es bidireccional, así que puedes **leer** (recibir) y **escribir** (enviar) sobre ella como sobre cualquier stream.

```go
conn.Write([]byte("GET / HTTP/1.0\r\n\r\n"))  // enviar
buf := make([]byte, 4096)
n, _ := conn.Read(buf)                         // recibir
```

Esta es la idea que lo desbloquea todo: como una `Conn` es un `Reader` y un `Writer`, <mark style="background: #FFB86CA6;">`io.Copy` puede conectar dos conexiones sin saber qué transportan</mark> — y eso es, literalmente, un proxy (nota [[02 - Proxy TCP con io.Copy]]). Métodos útiles: `conn.RemoteAddr()` te da la dirección del otro extremo, `conn.SetDeadline()` pone un límite de tiempo.

## Servidor: `net.Listen` + `Accept`

Un servidor no fabrica conexiones: **espera** a que un cliente conecte. El patrón es siempre el mismo:

```go
listener, err := net.Listen("tcp", ":20080")   // bind en el puerto 20080, todas las interfaces
if err != nil {
    log.Fatalln(err)
}
for {
    conn, err := listener.Accept()   // BLOQUEA hasta que llega un cliente
    if err != nil {
        continue
    }
    go handle(conn)                  // una goroutine por conexión -> no bloquea a las demás
}
```

`net.Listen` abre el listener; `listener.Accept()` bloquea hasta que alguien conecta y entonces devuelve una `Conn`. <mark style="background: #FFB8EBA6;">El idiom es `go handle(conn)`</mark>: cada conexión se atiende en su propia goroutine (nota [[13 - Goroutines, channels y concurrencia]]) mientras el bucle vuelve a `Accept` a esperar la siguiente. Este esqueleto es tu bind listener, tu servidor C2 y tu proxy.

## Los tres estados de un puerto

El escáner de la siguiente nota se apoya en cómo responde TCP al intento de conexión. Resumen operativo (los fundamentos del protocolo viven en `Redes/`, aquí solo lo justo para interpretar resultados):

| Estado | Respuesta al `SYN` | Qué ve tu `net.Dial` |
| - | - | - |
| **Abierto** | `SYN-ACK` (completa el 3-way handshake) | `err == nil` |
| **Cerrado** | `RST` | `err` inmediato (connection refused) |
| **Filtrado** | Nada (lo traga un firewall) | `err` por **timeout** (tarda) |

> [!warning]+ Cerrado y filtrado no son lo mismo, y `net.Dial` casi no los distingue
> Un `net.Dial` pelado devuelve error en los tres casos "no abierto", pero el **cerrado** falla al instante (`RST`) y el **filtrado** tarda hasta ~1-2 minutos (el SO retransmite el `SYN` varias veces antes de rendirse). <mark style="background: #FF5582A6;">Sin un timeout propio, un puerto filtrado cuelga tu escáner</mark> — por eso en la nota siguiente usaremos `DialContext` con deadline. Distinguir cerrado/filtrado con precisión requiere paquetes crudos (SYN scan), tema del Cap. 8 (`07 - Raw packets`).

## Port forwarding: por qué construimos proxies

El otro gran uso del paquete `net` es **relayar** conexiones. Un firewall puede impedirte llegar directo a un destino, pero si controlas un host intermedio que sí es alcanzable, ese host puede reenviar tu tráfico al destino real — *port forwarding*. Es la base para saltar controles de egress y segmentación de red (jump box, pivoting).

<mark style="background: #FFB86CA6;">En Go, un port forwarder es apenas un `net.Listen` + dos `net.Dial` unidos con `io.Copy`</mark> — lo construyes en la nota [[02 - Proxy TCP con io.Copy]]. La técnica de pentest a fondo (túneles SOCKS, pivoting encadenado con Chisel/Ligolo-ng) vive en Red Team: [[00 - Introducción al pivoting y los túneles]].

Con el modelo de conexión claro, el primer tool: un escáner de puertos que evoluciona de secuencial a concurrente y acotado → [[01 - Escáner TCP - de secuencial a concurrente]].
