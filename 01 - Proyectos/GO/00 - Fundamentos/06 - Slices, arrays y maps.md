---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Fecha de actualización: 2026-07-24
Nota previa: "[[05 - Funciones]]"
Nota siguiente: "[[07 - Strings, runes y bytes]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Los **slices** y los **maps** son las dos colecciones que de verdad manejarás en tooling: listas de puertos, resultados de escaneo, hosts vistos, cabeceras HTTP. Los **arrays** casi nunca se usan directamente, pero conviene saber qué son porque sostienen a los slices por debajo.

## Arrays: tamaño fijo, semántica de valor

Un array tiene tamaño fijo que **forma parte de su tipo**: `[4]byte` y `[16]byte` son tipos distintos. Se copian enteros al asignarlos o pasarlos a una función (semántica de valor). Su nicho son los tamaños conocidos en compilación:

```go
type Digest [32]byte      // un hash SHA-256, tamaño fijo
var ipv4 [4]byte          // una dirección IPv4 cruda
cache := map[[2]int]bool{} // los arrays son comparables -> sirven de clave de map
```

Para todo lo demás, slices.

## Slices: el caballo de batalla

<mark style="background: #ADCCFFA6;">Un slice es una cabecera de tres palabras: puntero al array subyacente, longitud (`len`) y capacidad (`cap`).</mark> Esa indirección es lo que le permite crecer y pasarse a funciones de forma barata (se copia la cabecera, no los datos).

```go
ports := []int{22, 80, 443}          // literal
results := make([]string, 0, 1024)   // len 0, cap 1024 -> preasignado
results = append(results, "10.10.10.1:22 open")
n := len(results)                    // elementos actuales
```

<mark style="background: #FFB8EBA6;">Preasigna con `make([]T, 0, n)` cuando conoces o estimas el tamaño</mark>: cada vez que `append` supera la capacidad, Go asigna un array nuevo y **copia todo** (crece doblando por debajo de 256 elementos, ~25% por encima). En un escáner que acumula miles de resultados, preasignar evita decenas de recopiados.

> [!warning]+ El footgun del array subyacente compartido
> Trocear un slice (`b := a[1:3]`) **no copia**: `b` apunta al mismo array que `a`. Escribir en `b[0]` cambia `a[1]`. Y un `append` sobre `b` puede sobrescribir datos de `a` si hay capacidad de sobra, o reasignar y volverse independiente — comportamiento difícil de predecir.
> ```go
> a := []int{1, 2, 3, 4}
> b := a[1:3]        // comparte memoria con a
> b[0] = 99          // ¡a ahora es [1, 99, 3, 4]!
> ```
> <mark style="background: #FF5582A6;">Si necesitas una copia independiente, usa `slices.Clone(a)`</mark> (Go 1.21). Este bug corrompe payloads y buffers de red de forma silenciosa. Detalle en la skill `golang-safety`.

Un **slice `nil`** (`var s []int`) y uno **vacío** (`[]int{}`) se comportan casi igual —ambos tienen `len 0` y aceptan `append`— pero se serializan distinto en JSON: el `nil` produce `null`, el vacío produce `[]`. Si tu herramienta expone una API, devuelve slices inicializados para no sorprender al consumidor (nota [[12 - JSON, XML y datos estructurados]]).

## Maps: tablas hash asociativas

Un `map[K]V` asocia claves a valores. Se crea con `make` (o literal) y se consulta con el **idiom "comma-ok"**, que distingue "la clave no existe" de "existe con el valor cero":

```go
seen := make(map[string]bool)
seen["10.10.10.1"] = true

if _, ok := seen[host]; ok {
    return   // ya lo habíamos visto -> deduplicación
}
delete(seen, host)   // eliminar una clave
```

Cuatro cosas que muerden:

- <mark style="background: #FF5582A6;">Escribir en un map `nil` provoca `panic`.</mark> Inicialízalo siempre con `make` antes de escribir (leer de un map nil sí es seguro y devuelve el valor cero).
- El **orden de iteración es aleatorio** por diseño; no dependas de él. Si necesitas orden, extrae las claves y ordénalas.
- Los maps son **tipos referencia**: asignar un map a otra variable copia el puntero, no los datos. Para una copia real usa `maps.Clone(m)`.
- <mark style="background: #FFB86CA6;">No son seguros para acceso concurrente</mark>: dos goroutines escribiendo a la vez hacen que el programa aborte. Con concurrencia, protégelo con `sync.Mutex` o usa `sync.Map` (nota [[13 - Goroutines, channels y concurrencia]]).

## Modernizar: los paquetes `slices` y `maps`

El libro recorre slices y maps con bucles escritos a mano. Desde **Go 1.21** la librería estándar trae los paquetes `slices` y `maps`, que sustituyen todo ese código repetitivo:

```go
import "slices"

ports := []int{443, 22, 80, 22}
slices.Sort(ports)                    // ordena in-place -> [22 22 80 443]
slices.Contains(ports, 443)           // devuelve true
slices.BinarySearch(ports, 80)        // devuelve (índice, ¿encontrado?)
ports = slices.Compact(ports)         // elimina duplicados consecutivos
_ = slices.Clone(ports)               // copia independiente (aquí no la guardamos)
```

Un patrón que vale la pena memorizar: un **conjunto genérico** (`Set`) construido sobre un map con valor vacío `struct{}` (que ocupa 0 bytes). Es el tipo ideal para acumular subdominios únicos al enumerar DNS (Cap. 5) o hosts ya escaneados:

```go
type Set[T comparable] map[T]struct{}

func (s Set[T]) Add(v T)           { s[v] = struct{}{} }
func (s Set[T]) Has(v T) bool      { _, ok := s[v]; return ok }

subdominios := Set[string]{}
subdominios.Add("mail.target.com")
```

> [!info]+ Recoger claves de un map (Go 1.23)
> Desde Go 1.23 `maps.Keys(m)` y `maps.Values(m)` devuelven **iteradores**. Para materializarlos en un slice se combinan con `slices.Collect`: `hosts := slices.Collect(maps.Keys(seen))`. En código anterior verás bucles `for k := range m` haciendo lo mismo a mano.

Con las colecciones cubiertas, toca el tipo que más vas a parsear en red y cripto: las cadenas y los bytes → [[07 - Strings, runes y bytes]].
