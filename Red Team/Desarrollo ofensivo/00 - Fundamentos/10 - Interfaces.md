---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Descripción: "Una interfaz define un comportamiento —un conjunto de métodos— sin decir quién lo implementa"
Fecha de actualización: 2026-07-24
Nota previa: "[[09 - Structs y métodos]]"
Nota siguiente: "[[11 - Manejo de errores]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

<mark style="background: #ADCCFFA6;">Una interfaz define un comportamiento —un conjunto de métodos— sin decir quién lo implementa.</mark> Es la abstracción que hace componible todo el tooling de red: gracias a ella, dos sockets, un fichero y una conexión, o un cliente HTTP y un mock de test, encajan por la misma ranura. Si solo te llevas una idea de Go a fondo, que sea esta.

## Satisfacción implícita: sin `implements`

La característica que distingue a las interfaces de Go: <mark style="background: #8000E1A6;">un tipo satisface una interfaz por el mero hecho de tener sus métodos, sin declararlo en ninguna parte.</mark> No hay palabra clave `implements`, no hay que importar el paquete de la interfaz.

```go
type Scanner interface {
    Scan(target string) ([]int, error)
}

type TCPScanner struct{}
func (TCPScanner) Scan(target string) ([]int, error) { /* ... */ return nil, nil }
// TCPScanner ES un Scanner automáticamente: tiene el método con la firma correcta.
```

Esto invierte el diseño respecto a Java o C#: no declaras por adelantado "esta clase implementa X". La consecuencia práctica —"descubre las interfaces, no las diseñes"— es que <mark style="background: #FFB8EBA6;">creas la interfaz cuando la necesitas (2+ implementaciones o un test)</mark>, no antes. Una interfaz prematura con una sola implementación es indirección sin valor.

## Interfaces pequeñas

> "Cuanto más grande la interfaz, más débil la abstracción." — Go Proverbs

Las interfaces buenas tienen **1-3 métodos**. Cuantos menos, más fácil es implementarlas, mockearlas y componerlas. Interfaces grandes se construyen combinando pequeñas:

```go
type ReadWriteCloser interface {
    io.Reader   // Read(p []byte) (int, error)
    io.Writer   // Write(p []byte) (int, error)
    io.Closer   // Close() error
}
```

## Las interfaces que sostienen la stdlib

Cuatro interfaces de la librería estándar aparecen por todas partes. Conocerlas es media batalla:

| Interfaz | Paquete | Método |
| - | - | - |
| `error` | builtin | `Error() string` |
| `fmt.Stringer` | `fmt` | `String() string` |
| `io.Reader` | `io` | `Read(p []byte) (int, error)` |
| `io.Writer` | `io` | `Write(p []byte) (int, error)` |

`io.Reader` e `io.Writer` son el pilar de todo el I/O de Go. Como `net.Conn`, `os.File`, `bytes.Buffer` y `http.Response.Body` implementan estas interfaces, <mark style="background: #FFB86CA6;">puedes conectar cualquier fuente con cualquier destino sin saber qué son</mark>. El proxy TCP entero del Cap. 2 es exactamente esto:

```go
func proxy(client, backend net.Conn) {
    go io.Copy(backend, client)  // todo lo que llega del cliente -> al backend
    io.Copy(client, backend)     // y la respuesta de vuelta
}
```

`io.Copy(dst Writer, src Reader)` no sabe nada de TCP; solo lee de un `Reader` y escribe en un `Writer`. Esa es la potencia de las interfaces para tooling (lo aplicarás en [[Redes TCP-IP.base|el bloque de TCP]]).

## `any` y el descubrimiento de tipos

La **interfaz vacía** no exige ningún método, así que **cualquier** valor la satisface. Desde Go 1.18 se escribe `any` (alias de `interface{}`); <mark style="background: #FF5582A6;">el libro usa `interface{}` por todas partes — moderniza a `any`</mark>. Se usa en fronteras donde el tipo es genuinamente desconocido (decodificar JSON, reflexión), no como sustituto de un tipo concreto.

Para recuperar el tipo real que hay dentro, usas una **type assertion** (con la forma segura "comma-ok") o un **type switch**:

```go
func describe(i any) string {
    switch v := i.(type) {
    case string:
        return "cadena: " + v
    case net.Conn:
        return "conexión con " + v.RemoteAddr().String()
    default:
        return fmt.Sprintf("tipo desconocido %T", v)
    }
}

s, ok := i.(string)   // comma-ok: ok=false en vez de panic si no es string
```

> [!warning]+ Para colecciones type-safe, genéricos, no `any`
> `[]any` pierde toda la seguridad de tipos. Desde Go 1.18 usa **genéricos** para operaciones sobre tipos: `func Contains[T comparable](s []T, v T) bool` en vez de `func Contains(s []any, v any) bool`. `any` solo en fronteras reales. Es una modernización que el libro (Go 1.11, sin genéricos) no podía ofrecer.

## Verificación en compilación y el `nil` traicionero

Para garantizar que un tipo satisface una interfaz sin esperar a que falle en runtime, coloca esta línea junto a la definición: no cuesta nada y rompe el build si dejas de cumplir el contrato.

```go
var _ io.ReadWriter = (*MyConn)(nil)   // falla al compilar si MyConn no lo satisface
```

> [!warning]+ El `nil` de interfaz que no es `nil`
> Una interfaz guarda un par (tipo, valor). Si le asignas un **puntero nil con tipo**, la interfaz **no** es `nil` (tiene tipo, aunque el valor sea nil):
> ```go
> var p *MyError = nil
> var err error = p    // err != nil  ¡aunque p sea nil!
> ```
> Es uno de los bugs más famosos de Go. Devuelve `nil` literal, nunca un puntero nil tipado, cuando quieras decir "sin error".

La interfaz más usada de todas es `error` — que, como ves en la tabla, es solo un tipo con un método `Error() string`. Cómo se maneja bien es el siguiente tema → [[11 - Manejo de errores]].
