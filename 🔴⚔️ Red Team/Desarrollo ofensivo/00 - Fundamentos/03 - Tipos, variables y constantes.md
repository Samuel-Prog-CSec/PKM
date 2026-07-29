---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Descripción: "Go es de tipado estático: el tipo de cada variable se conoce en compilación y no cambia en runtime"
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Toolchain y compilación]]"
Nota siguiente: "[[04 - Estructuras de control]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

<mark style="background: #ADCCFFA6;">Go es de tipado estático: el tipo de cada variable se conoce en compilación y no cambia en runtime.</mark> Recuerda de [[00 - Por qué Go para el hacking]] por qué eso importa en tooling — un error de tipo salta al compilar, no en mitad de un engagement. Esta nota cubre los ladrillos del lenguaje: cómo declarar variables, los tipos primitivos y las constantes.

## Declarar variables: `var` y `:=`

Hay dos formas de crear una variable:

```go
var host string = "10.10.10.1"  // explícita y completa
var host = "10.10.10.1"         // el tipo se infiere (string)
host := "10.10.10.1"            // forma corta, SOLO dentro de funciones
```

El libro las presenta y zanja con "no hay diferencia, usa la que quieras". La convención moderna sí distingue por **intención**: <mark style="background: #FFB8EBA6;">`:=` para valores no-cero; `var` para arrancar en el valor cero</mark>. `var buf bytes.Buffer` comunica "empieza vacío y lo lleno luego"; `port := 8080` comunica "empieza con esto". `:=` solo funciona dentro de funciones; a nivel de paquete únicamente `var`.

Declaración múltiple y en bloque:

```go
host, port := "10.10.10.1", 443
var (
    timeout = 5 * time.Second
    retries = 3
)
```

## Zero values: en Go no existe "sin inicializar"

Toda variable declarada sin valor recibe un **zero value** determinista. <mark style="background: #8000E1A6;">Nunca hay basura de memoria como en C</mark>: una variable no inicializada tiene un valor conocido y seguro.

| Tipo | Zero value |
| - | - |
| Numéricos (`int`, `float64`, `byte`…) | `0` |
| `bool` | `false` |
| `string` | `""` |
| Puntero, slice, map, channel, func, interface | `nil` |

Es diseño deliberado: muchos tipos son útiles ya en su zero value — un `bytes.Buffer` vacío escribe sin más, un `sync.Mutex` recién declarado ya bloquea. Consecuencia práctica: `var s []string` es un slice `nil` pero perfectamente usable con `append`. La trampa: <mark style="background: #FF5582A6;">escribir en un `map` nil provoca `panic`</mark> — los maps hay que inicializarlos con `make` antes de usarlos (nota [[06 - Slices, arrays y maps]]).

## Tipos primitivos

| Grupo | Tipos |
| - | - |
| Booleano | `bool` |
| Cadena | `string` |
| Enteros con signo | `int`, `int8`, `int16`, `int32`, `int64` |
| Enteros sin signo | `uint`, `uint8`, `uint16`, `uint32`, `uint64`, `uintptr` |
| Reales / complejos | `float32`, `float64`, `complex64`, `complex128` |
| Alias | `byte` (= `uint8`), `rune` (= `int32`) |

Reglas que importan al construir tooling:

- **`int` por defecto.** Su tamaño depende de la plataforma (64 bits en `amd64`). Usa tamaños fijos (`uint32`, `int64`) solo cuando el formato lo exige — parsear un campo de una cabecera de protocolo, por ejemplo.
- **`byte` = `uint8` es el ladrillo de todo lo binario.** Un `[]byte` es un buffer crudo: payloads, paquetes, respuestas de red y de socket viven como `[]byte` (nota [[07 - Strings, runes y bytes]]).
- **`rune` = `int32` es un code point Unicode**, relevante al recorrer texto carácter a carácter.

Los literales numéricos tienen sintaxis moderna (Go 1.13, posterior al libro): separador `_` y bases binaria/octal explícitas.

```go
const maxConns = 1_000_000   // separador de dígitos, legibilidad
mask  := 0b1111_0000         // binario
perm  := 0o755               // octal
magic := 0xDEADBEEF          // hexadecimal
```

## Conversiones: siempre explícitas

<mark style="background: #FF5582A6;">Go no convierte tipos numéricos de forma implícita</mark> — ni siquiera de `int` a `int64`. Hay que pedir la conversión con la sintaxis `T(v)`:

```go
var i int = 42
var f float64 = float64(i)   // obligatorio; `var f float64 = i` NO compila
var b byte = byte(i)         // aquí 42 cabe; byte(257) daría 1 (trunca a 8 bits)
```

Esto es exactamente lo que hace el libro al escribir `z := int(42)`: forzar el tipo. Es más verboso, pero elimina toda una clase de bugs silenciosos de conversión que en C o Python te estallan en runtime.

## Constantes e `iota`

`const` define valores fijos en compilación. Una constante **sin tipo** (*untyped*) tiene precisión arbitraria hasta que se asigna, así que `const big = 1 << 62` es legal y no desborda mientras no la metas donde no cabe.

`iota` es el generador de enumeraciones: dentro de un bloque `const` arranca en `0` y se incrementa una unidad por línea. Ideal para estados y, combinado con desplazamiento de bits, para flags de protocolo:

```go
type PortState int
const (
    Closed PortState = iota  // 0
    Open                     // 1
    Filtered                 // 2
)

// Flags TCP como bits, tal cual viajan en la cabecera:
const (
    FIN = 1 << iota  // 1   0b000001
    SYN              // 2   0b000010
    RST              // 4
    PSH              // 8
    ACK              // 16
    URG              // 32
)
```

El patrón `1 << iota` reaparece cuando construyes o parseas paquetes crudos a mano (Cap. 8 del curso, carpeta `07 - Raw packets`), y el tipo `PortState` es justo el tipo de dato que devolverá tu escáner TCP del [[Redes TCP-IP.base|siguiente bloque]].

Con los tipos claros, el siguiente paso es ramificar y repetir: las estructuras de control → [[04 - Estructuras de control]].
