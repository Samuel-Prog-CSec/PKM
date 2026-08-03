---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Descripción: "Un puntero guarda la dirección de memoria donde vive un valor, en lugar del valor en sí"
Fecha de actualización: 2026-07-24
Nota previa: "[[07 - Strings, runes y bytes]]"
Nota siguiente: "[[09 - Structs y métodos]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

<mark style="background: #ADCCFFA6;">Un puntero guarda la dirección de memoria donde vive un valor, en lugar del valor en sí.</mark> Si vienes de C, la sintaxis `&` y `*` te resultará familiar, pero Go quita los pies de plomo: no hay aritmética de punteros y el recolector de basura gestiona la memoria — nada de `malloc`/`free` ni de punteros colgantes.

## `&` y `*`: dirección y desreferencia

El operador `&` obtiene la dirección de una variable; `*` sobre un puntero hace lo contrario, **desreferencia** para llegar al valor:

```go
count := 42
ptr := &count      // ptr es *int -> la dirección de count
fmt.Println(*ptr)  // 42  -> desreferencia: el valor apuntado
*ptr = 100         // escribe a través del puntero
fmt.Println(count) // 100 -> hemos cambiado la variable original
```

El tipo se escribe `*int` ("puntero a int"). Su zero value es `nil`; <mark style="background: #FF5582A6;">desreferenciar un puntero `nil` provoca `panic`</mark>, así que compruébalo cuando pueda venir vacío.

## Para qué sirven de verdad

Tres motivos justifican usar un puntero, no la costumbre de C de usarlos para todo:

1. **Mutación.** Para que una función modifique el valor del que llama, recibe un puntero. Sin él, Go pasa una copia y tus cambios se pierden:

```go
type Result struct {
    Host string
    Open bool
}

func markOpen(r *Result) {  // recibe *Result -> modifica el original
    r.Open = true
}

res := Result{Host: "10.10.10.1"}
markOpen(&res)              // pasas la dirección
// res.Open == true
```

2. **Evitar copias caras.** Pasar un struct grande por valor lo copia entero cada vez; un puntero (una palabra) evita ese coste.
3. **Opcionalidad.** Un `*T` puede ser `nil`, así que sirve para expresar "este valor puede no existir" — un resultado ausente, un campo opcional.

## Crear punteros: `new(T)` y `&T{}`

El libro inicializa structs con `new(Person)`, que reserva un `Person` en cero y devuelve su `*Person`. Funciona, pero <mark style="background: #FFB8EBA6;">el idiom moderno prefiere el *composite literal* `&T{}`</mark>, más flexible porque puedes rellenar campos a la vez:

```go
p1 := new(Person)              // *Person, todo a cero (estilo del libro)
p2 := &Person{Name: "Dave"}    // *Person con campos inicializados (idiomático)
```

Ambos te dan un puntero; usa `&T{...}` salvo que de verdad quieras el cero puro.

## Sin aritmética, y sin miedo a devolver locales

Go **no** permite aritmética de punteros (nada de `ptr++` para recorrer memoria): esa es una de las razones por las que el lenguaje es memory-safe. Dos comodidades que lo acompañan:

- **Acceso a campos sin `->`.** Go desreferencia automáticamente al acceder a un campo: escribes `p.Name` tanto si `p` es `Person` como `*Person`. No existe el operador `->` de C.
- **Devolver la dirección de una variable local es seguro.** En C, `return &local` es un bug (puntero colgante). En Go, el compilador detecta que la variable "escapa" y la coloca en el *heap* por ti:

```go
func newResult(host string) *Result {
    r := Result{Host: host}  // variable local
    return &r                // seguro: Go la mueve al heap (escape analysis)
}
```

<mark style="background: #8000E1A6;">El recolector de basura la liberará cuando nadie la referencie</mark> — no hay que preocuparse de la memoria manualmente.

## `unsafe.Pointer`: la puerta de atrás

Existe una vía para saltarse todas estas garantías: `unsafe.Pointer` permite convertir entre tipos de puntero incompatibles y tocar memoria a bajo nivel. <mark style="background: #FFB86CA6;">La necesitarás para interoperar con la API de Windows</mark> — inyección de procesos, parseo de la estructura de un PE, llamadas a `syscall` que esperan punteros crudos:

```go
ptr := unsafe.Pointer(&data[0])  // rompe la seguridad de tipos a propósito
```

> [!warning]+ La regla de oro de `unsafe`
> Nunca guardes un `uintptr` (la dirección como número) en una variable a través de varias sentencias: el recolector puede mover el objeto y tu `uintptr` quedaría apuntando a memoria inválida. Las conversiones `unsafe.Pointer`↔`uintptr` deben ocurrir en **una sola expresión**. El uso ofensivo a fondo está en el bloque de [[Windows y PE.base|Windows y PE]] (Cap. 12); aquí basta con saber que la puerta existe y que Go te avisa de que es peligrosa.

Los punteros brillan de verdad al combinarlos con tipos propios. Toca definir los tuyos: structs y métodos → [[09 - Structs y métodos]].
