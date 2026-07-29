---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Descripción: "Un struct es un tipo compuesto que agrupa campos"
Fecha de actualización: 2026-07-24
Nota previa: "[[08 - Punteros]]"
Nota siguiente: "[[10 - Interfaces]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Un **struct** es un tipo compuesto que agrupa campos. Al definir **métodos** sobre él, obtienes lo más parecido a un "objeto" que tiene Go — pero <mark style="background: #ADCCFFA6;">sin clases, sin herencia y sin constructores como palabra clave</mark>. Go modela el comportamiento con composición, no con jerarquías. Este es el tipo con el que representarás objetivos, resultados de escaneo y estructuras de protocolo.

## Definir e inicializar structs

Defines un struct con `type` y `struct`, y lo inicializas con un *composite literal* nombrando los campos:

```go
type Target struct {
    Host  string
    Ports []int
    open  []int   // minúscula = privado, solo visible dentro del paquete
}

t := Target{
    Host:  "10.10.10.1",
    Ports: []int{22, 80, 443},
}
```

Dos reglas clave:

- <mark style="background: #FFB8EBA6;">La mayúscula inicial decide el ámbito</mark>: `Host` es exportado (accesible desde otros paquetes); `open` es privado. Go no tiene `public`/`private`, usa la capitalización. Es el mismo mecanismo para campos, tipos y funciones.
- Un struct sin inicializar tiene su zero value con cada campo en cero. Diseña tus structs para que ese cero sea **usable** (idea de [[03 - Tipos, variables y constantes]]): así evitas obligar a pasar por un constructor.

## Métodos y receivers

Un método es una función con un **receiver**: el tipo al que se ancla, declarado entre `func` y el nombre.

```go
func (t Target) String() string {      // receiver de tipo Target
    return fmt.Sprintf("%s (%d puertos)", t.Host, len(t.Ports))
}
```

El receiver es el equivalente al `self`/`this` de otros lenguajes. Puede ser un **valor** (`t Target`) o un **puntero** (`t *Target`), y la elección importa.

## Value vs pointer receivers

| Usa puntero `(*Target)` | Usa valor `(Target)` |
| - | - |
| El método **modifica** el receiver | El receiver es pequeño e inmutable |
| El struct es grande (evitar copias) | Método de solo lectura / accesor |
| Contiene un `sync.Mutex` o similar | Tipos básicos (`int`, `string`…) |

```go
type Port int
func (p Port) IsPrivileged() bool { return p < 1024 }   // pequeño, solo lee -> valor

func (t *Target) MarkOpen(p int)  { t.open = append(t.open, p) }  // muta -> puntero
func (t *Target) OpenPorts() []int { return t.open }
```

> [!important]+ Regla de consistencia
> <mark style="background: #FF5582A6;">Si un método del tipo usa receiver de puntero, todos deberían usarlo.</mark> Mezclar `(t Target)` y `(t *Target)` en el mismo tipo genera confusión y sutiles bugs de copia. `Target` tiene un método que muta (`MarkOpen`), así que **todos** sus métodos van con `*Target`.

## Composición por embedding

Go sustituye la herencia por **embedding**: incrustas un tipo dentro de otro y sus campos y métodos se **promocionan** al tipo externo. Es "composición sobre herencia" hecha lenguaje.

```go
type BaseClient struct {
    Timeout time.Duration
}
func (c *BaseClient) Do(req string) ([]byte, error) { /* ... */ }

type ShodanClient struct {
    *BaseClient          // embebido, sin nombre de campo
    APIKey string
}

sc := &ShodanClient{BaseClient: &BaseClient{Timeout: 10 * time.Second}}
sc.Do("...")             // promocionado desde BaseClient
sc.Timeout               // también promocionado
```

<mark style="background: #8000E1A6;">`ShodanClient` reutiliza toda la API de `BaseClient` sin reescribirla</mark>, y puede sobrescribir un método definiendo el suyo con el mismo nombre. Es el patrón con el que extenderás clientes HTTP y envolverás conexiones de red en los capítulos siguientes (Cap. 3, `02 - Clientes HTTP`). Si solo necesitas *usar* el tipo interno sin exponer su API, usa un campo con nombre en vez de embedding.

## Constructores: la convención `NewX`

Go no tiene constructores como palabra clave. La convención es una función de paquete llamada `NewX` que devuelve `*X` con valores por defecto sensatos y validando la entrada:

```go
func NewTarget(host string) *Target {
    return &Target{
        Host:  host,
        Ports: []int{22, 80, 443},   // por defecto: puertos comunes
    }
}
```

Los campos exportados de un struct que vas a serializar (JSON, XML, la BBDD) llevan **struct tags** —esas anotaciones entre backticks— que controlan el mapeo. Como son la puerta a serialización, las tratamos a fondo en [[12 - JSON, XML y datos estructurados]]:

```go
type Result struct {
    Host string `json:"host"`
    Open bool   `json:"open,omitempty"`
}
```

Los structs definen datos con comportamiento concreto. Las **interfaces** definen comportamiento sin atarlo a un tipo concreto — y son la abstracción que hace componible todo el tooling de red → [[10 - Interfaces]].
