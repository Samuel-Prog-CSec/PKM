---
tags:
  - Go
  - Go/Redes
  - Proxy
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Escáner TCP - de secuencial a concurrente]]"
Nota siguiente: "[[03 - Reimplementar Netcat - ejecución remota]]"
Area: "[[Redes TCP-IP.base|Redes TCP-IP]]"
---
---

Del lado cliente (`net.Dial`) al lado servidor: un **proxy TCP** que relaya tráfico entre dos conexiones. Es la base del *port forwarding* — saltar controles de egress, pivotar a redes segmentadas — y en Go se reduce a `net.Listen` + `net.Dial` unidos por una función: `io.Copy`. Toda la potencia viene de las interfaces de la nota [[10 - Interfaces]].

## `io.Copy`: el corazón

Recuerda de [[10 - Interfaces]] que `io.Copy(dst io.Writer, src io.Reader)` lee de un `Reader` y escribe en un `Writer` sin saber qué son. Y de la nota [[00 - El paquete net y el modelo de conexión]], que una `net.Conn` es **a la vez** `Reader` y `Writer`. Junta ambas cosas y tienes relay de datos gratis.

El caso más simple, un **echo server** (devuelve al cliente lo que envía), es de una línea: copiar la conexión sobre sí misma.

```go
func echo(conn net.Conn) {
    defer conn.Close()
    io.Copy(conn, conn)   // lee de conn, escribe en conn -> eco
}
```

El libro llega aquí tras pasar por versiones manuales con buffers y por `bufio` (`ReadString`/`WriteString`/`Flush`). <mark style="background: #ADCCFFA6;">`bufio` sigue siendo útil cuando el protocolo es orientado a líneas</mark> (leer hasta `\n`), pero para relay puro `io.Copy` gana.

## Montar el servidor

El esqueleto es el de la nota 00: `Listen`, bucle de `Accept`, una goroutine por conexión.

```go
func main() {
    listener, err := net.Listen("tcp", ":20080")
    if err != nil {
        log.Fatalln(err)
    }
    for {
        conn, err := listener.Accept()
        if err != nil {
            continue
        }
        go echo(conn)   // atiende cada cliente en su goroutine
    }
}
```

## El proxy bidireccional

Un proxy real no hace eco: conecta al cliente con un **backend** distinto y copia en los dos sentidos. Como `io.Copy` bloquea hasta que el stream se cierra, un sentido va en su propia goroutine:

```go
func handle(client net.Conn) {
    backend, err := net.Dial("tcp", "joescatcam.website:80")
    if err != nil {
        client.Close()
        return
    }
    go io.Copy(backend, client)   // cliente -> backend
    io.Copy(client, backend)      // backend -> cliente (bloquea aquí)
}
```

Esto es, palabra por palabra, un **port forwarder**: todo lo que llega al listener se reenvía al backend y la respuesta vuelve al cliente. La versión del libro (Joe reenviando su cat-cam a través de un host permitido para saltarse el firewall de su empresa) es exactamente este código.

## Cierre limpio: el goroutine leak que el libro no cierra

La versión de arriba tiene un fallo sutil que en un tool de larga duración se acumula. <mark style="background: #FF5582A6;">Cuando el backend cierra, la segunda `io.Copy` retorna, pero la goroutine de la primera puede quedarse bloqueada</mark> leyendo del cliente para siempre — un *goroutine leak* (nota [[13 - Goroutines, channels y concurrencia]]). La corrección: cuando **cualquiera** de los dos sentidos termina, cierra **ambas** conexiones para desbloquear al otro.

```go
func proxy(client net.Conn, target string) {
    defer client.Close()
    backend, err := net.Dial("tcp", target)
    if err != nil {
        return
    }
    defer backend.Close()   // al salir de proxy() se cierran las dos

    done := make(chan struct{}, 2)
    go func() { io.Copy(backend, client); done <- struct{}{} }()
    go func() { io.Copy(client, backend); done <- struct{}{} }()
    <-done   // en cuanto UN sentido acaba, retornamos: los defer cierran ambos
}
```

Al cerrar las dos conexiones, la `io.Copy` que seguía viva falla y su goroutine termina; el channel con buffer 2 absorbe su señal sin bloquear. <mark style="background: #8000E1A6;">Ningún leak, sin importar qué lado corte primero.</mark>

> [!info]+ Half-close correcto con `CloseWrite`
> Para protocolos que hacen *half-close* (cerrar solo un sentido y seguir leyendo el otro), una `net.TCPConn` ofrece `CloseWrite()`, que envía el `FIN` de TCP en una sola dirección. Un proxy que respeta half-close usa eso en vez de cerrar la conexión entera. Para relay genérico, cerrar ambos lados (arriba) es suficiente y más simple.

## Esto es un port forwarder

<mark style="background: #FFB86CA6;">Cambiando el `target` por un host de una red segmentada, este mismo código es tu herramienta de pivoting.</mark> Un `net.Listen` en un host comprometido que reenvía a un destino interno te da acceso a lo que tu máquina no alcanza directamente. Las herramientas de producción que ya usas —Chisel, Ligolo-ng— son esto mismo con multiplexación, cifrado y SOCKS por encima. La técnica de pivoting a fondo vive en Red Team: [[00 - Introducción al pivoting y los túneles]] y [[13 - Pivoting moderno con Ligolo-ng]].

El último paso del capítulo lleva el proxy un peldaño más allá: en vez de reenviar a otro host, redirigir stdin/stdout de un programa sobre la conexión — la "gaping security hole" de Netcat → [[03 - Reimplementar Netcat - ejecución remota]].
