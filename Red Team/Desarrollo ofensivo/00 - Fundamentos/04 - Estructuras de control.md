---
tags:
  - Go
  - Go/Fundamentos
  - Sintaxis
Descripción: "Go tiene menos estructuras de control que casi cualquier otro lenguaje moderno: if, switch, for y defer"
Fecha de actualización: 2026-07-24
Nota previa: "[[03 - Tipos, variables y constantes]]"
Nota siguiente: "[[05 - Funciones]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Go tiene menos estructuras de control que casi cualquier otro lenguaje moderno: `if`, `switch`, `for` y `defer`. No hay `while`, no hay `do-while`, no hay operador ternario. <mark style="background: #ADCCFFA6;">Menos formas de escribir lo mismo se traduce en código más uniforme</mark> — cualquier herramienta ofensiva en Go, la tuya o la de ProjectDiscovery, se lee igual.

## `if`: sin paréntesis, con llaves obligatorias

La condición **no** se envuelve en paréntesis, y las llaves son obligatorias incluso para una sola línea (a diferencia de C o Java):

```go
if port == 443 {
    useTLS = true
}
```

La variante más idiomática de Go es el `if` con **sentencia de inicialización**: declaras una variable acotada al propio `if` y la evalúas en la misma línea. Es el patrón que verás en cada llamada que devuelve un `error`:

```go
if err := os.Remove(path); err != nil {
    log.Println(err)    // `err` solo existe dentro del if
}
```

De aquí sale el idiom más importante del estilo Go: <mark style="background: #FFB8EBA6;">maneja el error primero y sal cuanto antes</mark> (*guard clause*), dejando el camino feliz sin anidar. Cuando el cuerpo del `if` termina en `return`, el `else` sobra:

```go
func connect(host string, port int) (net.Conn, error) {
    if host == "" {
        return nil, errors.New("host vacío")
    }
    conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", host, port))
    if err != nil {
        return nil, fmt.Errorf("conectando a %s: %w", host, err)   // wrapping -> nota 11
    }
    return conn, nil    // el camino feliz, sin indentar
}
```

## `switch`: sin `fallthrough` por defecto

<mark style="background: #FFB8EBA6;">A diferencia de C, en Go cada `case` termina solo: no hace falta `break`</mark> y no hay caída en cascada. Si de verdad quieres continuar al siguiente case, lo pides explícitamente con `fallthrough`.

```go
switch state {
case Open:
    report(port)
case Closed, Filtered:      // varios valores en un mismo case
    // no hacer nada
default:
    log.Printf("estado desconocido: %v", state)
}
```

El `switch` **sin expresión** es la forma limpia de sustituir una cadena de `if/else if`: cada `case` es una condición booleana. Es más legible que el ternario que Go no tiene:

```go
switch {
case rtt < 10*time.Millisecond:
    quality = "excelente"
case rtt < 100*time.Millisecond:
    quality = "aceptable"
default:
    quality = "lenta"
}
```

Existe además el **type switch**, que descubre el tipo concreto detrás de una interfaz (`switch v := i.(type)`). Como depende de entender interfaces, lo vemos en [[10 - Interfaces]].

## `for`: el único bucle

`for` es la **única** construcción de iteración de Go, pero absorbe todas las formas de las demás:

```go
for i := 0; i < 10; i++ { }      // clásico estilo C
for scanning { }                  // solo condición = "while"
for { }                           // infinito (romper con break/return)
for i := range 10 { }             // contar 0..9 (Go 1.22, posterior al libro)
for idx, val := range ports { }   // recorrer slice/array/map/string/channel
```

`range` devuelve índice y una **copia** del valor en slices; sobre un `map` devuelve clave/valor (en orden aleatorio); sobre un `channel` drena valores hasta que se cierra — así recoge resultados un escáner concurrente (nota [[13 - Goroutines, channels y concurrencia]]). Si no usas el índice, sustitúyelo por `_`.

> [!warning]+ El cambio silencioso de Go 1.22 que el libro no puede conocer
> Hasta Go 1.21, **la variable del bucle se reutilizaba** en cada iteración. Lanzar goroutines dentro de un `for range` era el bug clásico: todas capturaban la misma variable y veían el **último** valor. Desde **Go 1.22** cada iteración tiene su propia copia y el bug desapareció.
> ```go
> for _, port := range ports {
>     go func() { scan(host, port) }()   // Go 1.22+: cada goroutine ve SU port
> }
> ```
> <mark style="background: #FF5582A6;">Si copias código de un tutorial pre-2024 que hace `port := port` dentro del bucle, ese apaño ya sobra.</mark> Fuente: [go.dev/blog/loopvar-preview](https://go.dev/blog/loopvar-preview).

## `defer`: agenda limpieza para la salida

`defer` pospone una llamada hasta que la función que la contiene retorna, pase lo que pase. Es el mecanismo estándar para cerrar recursos junto al sitio donde se abren, sin olvidos:

```go
conn, err := net.Dial("tcp", target)
if err != nil {
    return err
}
defer conn.Close()   // se ejecuta al salir de la función, aunque haya un return por medio
```

Dos matices: los `defer` se ejecutan en orden **LIFO** (el último agendado, primero en correr), y <mark style="background: #FFB86CA6;">los argumentos se evalúan en el momento del `defer`, no al ejecutarse</mark>. Su otro gran uso —recuperarse de un `panic` con `recover`— lo veremos en [[11 - Manejo de errores]].

Con el control de flujo cubierto, toca empaquetar lógica reutilizable: las funciones → [[05 - Funciones]].
