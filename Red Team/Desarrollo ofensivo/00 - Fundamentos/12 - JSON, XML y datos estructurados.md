---
tags:
  - Go
  - Go/Fundamentos
  - Datos
Descripción: "Un pentester escribe código que habla con APIs y protocolos constantemente: consultar Shodan, pilotar el RPC de Metasploit, parsear la respuesta de un servicio, mover mensajes…"
Fecha de actualización: 2026-07-24
Nota previa: "[[11 - Manejo de errores]]"
Nota siguiente: "[[13 - Goroutines, channels y concurrencia]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Un pentester escribe código que habla con APIs y protocolos constantemente: consultar Shodan, pilotar el RPC de Metasploit, parsear la respuesta de un servicio, mover mensajes por un canal C2. Todo eso es **datos estructurados** — JSON, XML, y formatos binarios. Go los serializa con los paquetes `encoding/*`, y el patrón es idéntico para todos.

## Marshal y Unmarshal

Serializar (*marshal*) convierte una estructura en bytes; deserializar (*unmarshal*) hace lo contrario. Con `encoding/json`:

```go
type Host struct {
    IP    string `json:"ip"`
    Ports []int  `json:"ports"`
    Vuln  bool   `json:"vuln,omitempty"`
}

b, err := json.Marshal(Host{IP: "10.10.10.1", Ports: []int{22, 80}})
if err != nil {
    return err          // el libro ignora este error con `_`; en real se comprueba
}
// b = {"ip":"10.10.10.1","ports":[22,80]}

var h Host
if err := json.Unmarshal(b, &h); err != nil {   // OJO: puntero, para que pueda rellenarlo
    return err
}
```

> [!warning]+ Solo los campos exportados se serializan
> <mark style="background: #FF5582A6;">Un campo en minúscula es invisible para el encoder.</mark> Si tu struct de salida tiene `ip string` (privado), el JSON saldrá vacío y no habrá error que te avise. Los campos que quieras serializar deben empezar por mayúscula; el nombre "bonito" en el JSON lo pones con el struct tag.

## Struct tags: controlar el mapeo

Los **struct tags** —esas anotaciones entre backticks— le dicen al encoder cómo tratar cada campo. Sin ellos, el JSON usa el nombre del campo tal cual (`"IP"`, `"Ports"`), que es justo lo que hace el ejemplo `Foo{Bar, Baz}` del libro y no es idiomático.

| Directiva | Efecto |
| - | - |
| `json:"ip"` | Nombre del campo en el JSON |
| `json:"vuln,omitempty"` | Omite el campo si tiene su valor cero |
| `json:"-"` | Excluye el campo siempre (aunque sea exportado) |
| `json:",string"` | Codifica el número/bool como string JSON |

## Decodificar JSON desconocido

Cuando no controlas la forma de la respuesta (una API de terceros que cambia, un servicio que no documenta su salida), deserializa en un `map[string]any` o `any` y navega desde ahí. Es la frontera legítima donde `any` (nota [[10 - Interfaces]]) tiene sentido:

```go
var raw map[string]any
json.Unmarshal(body, &raw)
matches, ok := raw["matches"].([]any)   // comma-ok: sin él, un panic si no es []any
if !ok {
    return errors.New("respuesta con forma inesperada")
}
```

Lo habitual, sin embargo, es <mark style="background: #FFB8EBA6;">definir un struct con solo los campos que te interesan</mark>: el decoder ignora el resto de la respuesta. Así parseas una respuesta tipo Shodan quedándote con lo justo:

```go
var resp struct {
    Matches []struct {
        IP   string `json:"ip_str"`
        Port int    `json:"port"`
    } `json:"matches"`
}
json.Unmarshal(body, &resp)
```

## Streaming: `Encoder` y `Decoder` sobre `io`

`Marshal`/`Unmarshal` trabajan sobre `[]byte` en memoria. Para leer y escribir directamente de un stream —una conexión de red, el body de una respuesta HTTP— usa `json.NewDecoder`/`NewEncoder`, que consumen cualquier `io.Reader`/`io.Writer` (nota [[10 - Interfaces]]):

```go
// Leer un mensaje JSON directamente del socket, sin buffer intermedio:
var cmd Command
if err := json.NewDecoder(conn).Decode(&cmd); err != nil {
    return err
}
json.NewEncoder(conn).Encode(Response{OK: true})   // y responder por el mismo socket
```

<mark style="background: #8000E1A6;">Este es el patrón que usarás en el canal C2</mark>: decodificar comandos que llegan por la conexión y encodear las respuestas, sin cargar nada entero en memoria (Cap. 14, `13 - Command and Control`).

## XML y los demás formatos

`encoding/xml` es casi idéntico: mismos `Marshal`/`Unmarshal`, distintos tags. El libro los muestra para atributos y elementos anidados:

```go
type Config struct {
    ID    string `xml:"id,attr"`       // atributo -> <Config id="...">
    Child string `xml:"parent>child"`  // ruta anidada -> <parent><child>...</child></parent>
}
```

El mismo mecanismo de tags gobierna **cualquier** formato de serialización de Go: ASN.1, MessagePack, YAML (de terceros) y hasta el protocolo SMB, donde definirás **tags propios** para mapear campos de la estructura del paquete (Cap. 6, `05 - SMB y NTLM`). Aprender el patrón una vez te vale para todos.

> [!info]+ `encoding/json/v2` en el horizonte (Go 1.25)
> Go 1.25 introdujo `encoding/json/v2` de forma **experimental** (tras `GOEXPERIMENT=jsonv2`): más rápido, con mejor manejo de errores y streaming, y semántica más estricta. Todavía no es el estándar por defecto — úsalo solo si optas explícitamente. Para tu tooling de hoy, `encoding/json` sigue siendo la elección correcta.

Queda el rasgo que hace de Go el lenguaje de tooling de red por excelencia, y el más potente de todo el bloque: la concurrencia → [[13 - Goroutines, channels y concurrencia]].
