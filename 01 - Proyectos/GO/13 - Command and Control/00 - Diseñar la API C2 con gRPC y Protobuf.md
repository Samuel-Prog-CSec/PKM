---
tags:
  - Go
  - Go/C2
  - Post-Explotacion
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - El servidor C2 - proxy con channels]]"
Area: "[[Command and Control.base|Command and Control]]"
---
---

El capstone del libro ata muchos hilos en una sola herramienta: un **RAT** (*Remote Access Trojan*) de command-and-control. Es, en el fondo, un ejercicio de **sistemas distribuidos**: tres componentes que se comunican. El valor técnico aquí es cómo se diseña esa comunicación cliente-servidor con **gRPC** — la operativa C2 real (evasión, persistencia, movimiento lateral) es metodología de Red Team ([[00 - Introducción a Metasploit|C2 con Metasploit]]).

## Los tres componentes

<mark style="background: #ADCCFFA6;">El RAT son tres binarios independientes</mark>:

- **Implant**: corre en la máquina comprometida. Sondea al servidor pidiendo trabajo, ejecuta el comando y devuelve la salida.
- **Server**: el intermediario. Recibe trabajo del admin y lo enruta al implant; recoge la salida del implant y se la devuelve al admin.
- **Admin**: la consola del operador (tú). Envía comandos al servidor.

Cada uno es su propio `main` package en su carpeta — el patrón `cmd/` de un proyecto multi-binario (project layout de Go): compilas cada componente por separado con un nombre de binario descriptivo.

## gRPC y Protobuf

<mark style="background: #FFB8EBA6;">gRPC es el framework RPC de Google sobre HTTP/2</mark>, con serialización binaria eficiente. A diferencia de REST (verbos HTTP + rutas), en gRPC defines un **servicio** con sus métodos y tipos de datos usando **Protocol Buffers** (`.proto`). El schema del RAT:

```proto
syntax = "proto3";
package grpcapi;

service Implant {                                 // API que consume el implant
    rpc FetchCommand (Empty) returns (Command);   // "¿tienes trabajo para mí?"
    rpc SendOutput (Command) returns (Empty);     // "aquí está la salida"
}

service Admin {                                   // API que consume el operador
    rpc RunCommand (Command) returns (Command);   // "ejecuta esto y dame el resultado"
}

message Command {
    string In  = 1;    // el comando a ejecutar
    string Out = 2;    // su salida
}

message Empty {}       // protobuf no permite null: Empty es el apaño
```

Tres claves del schema:

- **Los servicios son como interfaces Go** (nota [[10 - Interfaces]]): declaran los métodos que cualquier implementación debe cumplir. `FetchCommand` toma un `Empty` y devuelve un `Command`.
- **Los números (`= 1`, `= 2`) no son valores**: son el offset del campo dentro del mensaje serializado — el orden en el binario, no el contenido.
- **Dos servicios separados por OPSEC**: <mark style="background: #8000E1A6;">el implant no debería poder enviar trabajo, ni el admin recibir la salida cruda del implant</mark>. Separar `Implant` y `Admin` mantiene los roles mutuamente exclusivos.

## Compilar el schema

`protoc` genera el código Go (structs, interfaces y *stubs* de cliente/servidor) a partir del `.proto`:

```shell-session
$ protoc -I . implant.proto --go_out=. --go-grpc_out=.
```

> [!warning]+ Modernización: el comando del libro está obsoleto
> El libro usa `protoc --go_out=plugins=grpc:./`. <mark style="background: #FF5582A6;">El plugin `plugins=grpc` está deprecado</mark>: hoy se usan **dos plugins separados**, `protoc-gen-go` (mensajes) y `protoc-gen-go-grpc` (servicios), con `--go_out` y `--go-grpc_out`. Instálalos con `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest` y `.../grpc/cmd/protoc-gen-go-grpc@latest`. La alternativa moderna que gestiona todo esto (lint, breaking-change detection, generación) es **`buf`** — el estándar de facto para proyectos gRPC serios en 2026.

El código generado (`implant.pb.go` + `implant_grpc.pb.go`) te da `RegisterImplantServer`, `NewImplantClient` y demás — funciones que no escribiste tú, sino `protoc`. Sobre esos *stubs* se construye el servidor, que es la pieza más compleja → [[01 - El servidor C2 - proxy con channels]].
