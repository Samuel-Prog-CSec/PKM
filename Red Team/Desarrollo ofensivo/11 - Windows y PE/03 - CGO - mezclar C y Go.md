---
tags:
  - Go
  - Go/Windows
Descripción: "CGO es el puente entre Go y C. En Windows lo necesitas para tres cosas: usar una librería que solo existe en C, llamar a la Windows API vía C, y —la más relevante para tooling—…"
Fecha de actualización: 2026-07-25
Nota previa: "[[02 - Parsear ficheros PE con debug-pe]]"
Nota siguiente: ""
Area: "[[Windows y PE.base|Windows y PE]]"
---
---

CGO es el puente entre Go y C. En Windows lo necesitas para tres cosas: usar una librería que solo existe en C, llamar a la Windows API vía C, y —la más relevante para tooling— <mark style="background: #ADCCFFA6;">exportar código Go a una DLL</mark>, algo que exige CGO sí o sí (la directiva `//export` requiere `import "C"`). Es potente pero tiene un coste real que conviene entender antes de usarlo.

## C embebido en Go

El código C va en un comentario justo antes de `import "C"`. Lo que declares ahí es invocable como `C.<func>`:

```go
package main

/*
#include <windows.h>

void box() {
    MessageBox(0, "Is Go the best?", "C GO GO", 0x00000004L);
}
*/
import "C"

func main() {
    C.box()          // ejecuta la función C, que llama a la WinAPI MessageBox
}
```

`import "C"` no es un paquete normal: le dice al compilador que active **CGO** y enlace el C nativo en tiempo de build. Necesitas un *toolchain* C: GCC en Linux/macOS, y **MinGW-w64** (vía MSYS2) en Windows, en el `PATH`.

## Go → C: construir una DLL

> [!warning]+ Matiz que el libro simplifica de más
> Black Hat Go afirma que "Go no puede compilar DLLs". <mark style="background: #FF5582A6;">No es cierto: `go build -buildmode=c-shared` genera un `.dll` directamente en Windows</mark> (usando CGO). Lo que el libro hace —y por lo que merece la pena— es la variante **c-archive + un shim C**, que da más control sobre el binario resultante para el flujo de *reflective injection* (convertirlo luego a shellcode con `sRDI`), donde la DLL de `c-shared` (con su `DllMain` y el runtime de Go) encaja peor. En ambos casos exportas la función Go con `//export`:

```go
package main

import "C"
import "fmt"

//export Start
func Start() {
    fmt.Println("hola desde Go")
}

func main() {}    // vacío, obligatorio
```

```shell-session
$ go build -buildmode=c-archive        # produce un .a y un .h
```

Un pequeño *shim* C que referencie la función (`void (*table[1]) = {Start};`) se compila con GCC enlazando el `.a` para producir la DLL. <mark style="background: #FFB86CA6;">Ese es el flujo para tener un DLL con lógica escrita en Go</mark> — la pieza que faltaba para la variante *reflective* de [[01 - Process injection clásica]]. A partir de la DLL, herramientas públicas como `sRDI` la convierten en shellcode inyectable; el detalle operativo es Red Team.

## El coste de CGO (léelo antes de usarlo)

> [!warning]+ CGO desactiva el gestor de memoria de Go
> El aviso clave: <mark style="background: #FF5582A6;">al cruzar a C, el recolector de basura de Go deja de gestionar esa memoria</mark>. Memoria reservada por C hay que liberarla con `C.free`; el GC no la ve ni la limpia. La regla segura: **reserva en Go y pásalo a C** siempre que puedas, para que el GC siga a cargo. Y usa `defer` para el *cleanup* de cualquier recurso C que Go referencie, igual que con un `os.File`.

> [!important]+ "cgo is not Go"
> El proverbio de Go. CGO <mark style="background: #8000E1A6;">rompe lo que hace a Go cómodo</mark>: el *cross-compiling* trivial (ahora necesitas un toolchain C para cada plataforma), binarios más pequeños y el análisis estático. Cada llamada Go↔C tiene *overhead*, y pierdes portabilidad. Úsalo solo cuando de verdad no hay alternativa en Go puro — construir una DLL es uno de esos casos; llamar a la WinAPI **no**, porque para eso ya tienes `syscall`/`x/sys/windows` sin salir de Go ([[00 - Llamar a la Windows API desde Go]]).

Con esto cierras el bloque de Windows: llamar a la API, inyectar en procesos, parsear PE y mezclar C. El siguiente tema esconde datos a plena vista — esteganografía → carpeta `12 - Esteganografía`.
