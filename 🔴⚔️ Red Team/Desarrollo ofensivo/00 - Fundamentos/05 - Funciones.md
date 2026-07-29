---
tags:
  - Go
  - Go/Fundamentos
  - Sintaxis
Descripción: "Las funciones en Go son valores de primera clase: las asignas a variables, las pasas como argumento y las devuelves desde otras funciones"
Fecha de actualización: 2026-07-24
Nota previa: "[[04 - Estructuras de control]]"
Nota siguiente: "[[06 - Slices, arrays y maps]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Las funciones en Go son **valores de primera clase**: las asignas a variables, las pasas como argumento y las devuelves desde otras funciones. Y pueden devolver **varios valores a la vez**, un detalle que define el estilo de manejo de errores de todo el lenguaje. Esta nota cubre la mecánica que usarás en cada herramienta que escribas.

## Firma y retornos múltiples

La firma declara el tipo después del nombre; parámetros del mismo tipo comparten declaración:

```go
func scan(host string, port, timeout int) bool { ... }
```

Lo que distingue a Go es que <mark style="background: #ADCCFFA6;">una función puede devolver múltiples valores</mark>, y la convención universal es devolver el resultado y un `error` como último valor:

```go
func grabBanner(target string) (string, error) {
    conn, err := net.Dial("tcp", target)
    if err != nil {
        return "", err           // valor cero + el error
    }
    defer conn.Close()
    buf := make([]byte, 1024)
    n, err := conn.Read(buf)
    if err != nil {
        return "", err
    }
    return string(buf[:n]), nil  // resultado + nil = todo OK
}

banner, err := grabBanner("10.10.10.1:22")
if err != nil {
    log.Fatal(err)
}
```

<mark style="background: #8000E1A6;">Este patrón `(valor, error)` es el latido de Go</mark>: no hay excepciones que se propaguen solas, el error viaja como un valor más y lo compruebas donde ocurre (a fondo en [[11 - Manejo de errores]]).

Puedes **nombrar** los valores de retorno; entonces un `return` "desnudo" los devuelve implícitos:

```go
func split(sum int) (x, y int) {
    x = sum * 4 / 9
    y = sum - x
    return   // devuelve x, y
}
```

Úsalo con moderación: el *naked return* solo se lee bien en funciones de 1-3 líneas. En funciones largas nombra el `return` explícitamente para que quien lee no tenga que buscar qué se devuelve.

## Funciones variádicas

Una función puede aceptar un número arbitrario de argumentos con `...`. Dentro, ese parámetro es un slice:

```go
func scanPorts(host string, ports ...int) {
    for _, p := range ports {
        scan(host, p, 2)
    }
}

scanPorts("10.10.10.1", 22, 80, 443)     // varios argumentos sueltos
common := []int{22, 80, 443, 445, 3389}
scanPorts("10.10.10.1", common...)        // "desparramar" un slice con ...
```

<mark style="background: #FFB8EBA6;">El parámetro variádico debe ir siempre el último</mark>. La sintaxis `slice...` en la llamada expande un slice existente en argumentos individuales — la verás al reenviar argumentos de una función a otra.

## Funciones como valores: tablas de despacho

Al ser valores, puedes guardarlas en variables y en estructuras de datos. Una **tabla de despacho** (un `map` de nombre → función) es el patrón idiomático para enrutar comandos, justo lo que necesita el manejador de un implante o un C2:

```go
var handlers = map[string]func(net.Conn) error{
    "shell":  handleShell,
    "upload": handleUpload,
    "exec":   handleExec,
}

if h, ok := handlers[cmd]; ok {
    h(conn)
}
```

<mark style="background: #FFB86CA6;">Añadir un comando nuevo es añadir una entrada al map</mark>, no ampliar un `switch` gigante. Este mismo mecanismo sostiene los sistemas de plugins (Cap. 10, `09 - Plugins y extensibilidad`) y el enrutado de un servidor HTTP (Cap. 4, `03 - Servidores HTTP`).

## Closures

Una **closure** es una función anónima que captura variables de su entorno y las mantiene vivas entre llamadas. <mark style="background: #ADCCFFA6;">La closure "recuerda" el estado del ámbito donde se creó</mark>:

```go
func counter() func() int {
    n := 0
    return func() int {   // captura n por referencia
        n++
        return n
    }
}

next := counter()
next()  // 1
next()  // 2  -> n persiste entre llamadas
```

El uso que más vas a explotar es el **middleware**: una función que envuelve a otra para añadir comportamiento (logging, autenticación, un delay de evasión) sin tocar la original. Es la columna vertebral del enrutado HTTP que montarás en el bloque de servidores:

```go
func withAuth(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        if r.Header.Get("X-Key") != secret {
            http.Error(w, "forbidden", http.StatusForbidden)
            return
        }
        next(w, r)   // la closure envuelve al handler real
    }
}
```

> [!info]+ Built-ins modernos que el libro no tenía
> Go 1.21 añadió las funciones integradas `min`, `max` y `clear`, disponibles sin importar nada: `max(a, b)`, `min(timeout, deadline)`, `clear(m)` para vaciar un map. Sustituyen a helpers manuales que en código pre-2023 verás escritos a mano.

Con las funciones dominadas, toca el tipo de dato que más manejarás en tooling de red: las colecciones → [[06 - Slices, arrays y maps]].
