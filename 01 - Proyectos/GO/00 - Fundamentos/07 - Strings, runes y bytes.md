---
tags:
  - Go
  - Go/Fundamentos
  - Tipos
Fecha de actualización: 2026-07-24
Nota previa: "[[06 - Slices, arrays y maps]]"
Nota siguiente: "[[08 - Punteros]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

En tooling de red y criptografía vives entre tres tipos: `string`, `[]byte` y `rune`. Entender cómo se relacionan evita los bugs más comunes al parsear banners, construir payloads o codificar en hex/base64. La confusión clásica —tratar bytes como caracteres— corrompe datos binarios en silencio.

## `string`: bytes inmutables en UTF-8

<mark style="background: #ADCCFFA6;">Un `string` en Go es una secuencia de bytes de solo lectura, codificada en UTF-8.</mark> Es inmutable: no puedes cambiar un carácter in situ. Y el detalle que más sorprende: `len(s)` cuenta **bytes, no caracteres**, y `s[i]` devuelve un **byte** (`uint8`), no una letra.

```go
s := "héby"
len(s)      // 5, no 4 -> la 'é' ocupa 2 bytes en UTF-8
s[0]        // 104 (el byte 'h'), no "h"
```

Para tooling esto rara vez molesta: banners, cabeceras y comandos son ASCII, donde un byte = un carácter. Pero al tocar texto Unicode, tenlo presente.

## `[]byte`: el buffer mutable

Cuando necesitas **modificar** datos o trabajar con bytes crudos, usas `[]byte`. <mark style="background: #8000E1A6;">Es la materia prima de todo lo binario</mark>: paquetes de red, respuestas de socket, shellcode, buffers de cifrado. La conversión entre `string` y `[]byte` es directa, pero **copia** (asigna memoria nueva), porque el string es inmutable y el slice no:

```go
payload := []byte("GET / HTTP/1.1\r\n\r\n")   // string -> []byte (mutable)
payload[0] = 'P'                               // ahora puedes modificarlo
banner := string(buf[:n])                      // []byte -> string tras un Read
```

Casi todas las APIs de I/O de Go (`conn.Read`, `conn.Write`, `crypto/*`) hablan en `[]byte`, así que este ida y vuelta lo harás constantemente. La shellcode que portes en el Cap. 9 vive como `[]byte`, y los buffers de AES-GCM del Cap. 11 también.

## `rune`: cuando el texto no es ASCII

Un `rune` (alias de `int32`) es un **code point Unicode**: un carácter lógico, ocupe los bytes que ocupe. Recorrer un string con `range` **decodifica** UTF-8 y te da runes, con el índice en bytes:

```go
for i, r := range "héby" {
    fmt.Printf("%d: %c\n", i, r)   // i salta: 0:h 1:é 3:b 4:y
}
```

<mark style="background: #FFB8EBA6;">Si necesitas contar o indexar por carácter, convierte a `[]rune`</mark>: `[]rune(s)` produce un slice donde cada elemento es un carácter completo, y `len([]rune(s))` sí es el número de caracteres (equivalente a `utf8.RuneCountInString(s)`).

| Tipo | Es | `len` cuenta | Mutable |
| - | - | - | - |
| `string` | Bytes UTF-8 de solo lectura | Bytes | No |
| `[]byte` | Slice de bytes crudos | Bytes | Sí |
| `[]rune` | Slice de code points | Caracteres | Sí |

## Construir cadenas: `strings.Builder`

Concatenar con `+` dentro de un bucle es O(n²): cada `+` crea un string nuevo y copia todo lo anterior. <mark style="background: #FF5582A6;">Para construir texto en un bucle usa `strings.Builder`</mark>, que acumula en un buffer y evita las copias:

```go
var b strings.Builder
for _, host := range hosts {
    b.WriteString(host)
    b.WriteByte('\n')
}
report := b.String()
```

Si además necesitas leer del buffer (implementa `io.Reader` e `io.Writer`), usa `bytes.Buffer` — el tipo que conectarás a lecturas y escrituras de red en el bloque de [[Redes TCP-IP.base|TCP]].

## La caja de herramientas

Tres paquetes de la stdlib cubren casi todo el manejo de texto, más los de codificación:

```go
strings.HasPrefix(banner, "SSH-")        // ¿es un servicio SSH?
user, rest, found := strings.Cut(line, ":")   // partir en el PRIMER separador (Go 1.18)
parts := strings.Fields(cmd)             // trocear por espacios en blanco
port, err := strconv.Atoi(portStr)       // "443" -> 443
hexHash := hex.EncodeToString(digest)    // bytes -> "a1b2c3..."
b64 := base64.StdEncoding.EncodeToString(payload)  // payload -> base64
```

- **`strings`**: `Split`, `Contains`, `HasPrefix`/`HasSuffix`, `TrimSpace`, `ToLower`, `ReplaceAll`, `Join`, y `Cut` (Go 1.18) para "partir en la primera aparición" — más limpio que el viejo `SplitN`.
- **`strconv`**: conversiones número↔texto (`Atoi`, `Itoa`, `ParseInt`, `Quote`). Más rápido que `fmt.Sprintf` para casos simples.
- **`bytes`**: espejo de `strings` pero sobre `[]byte`, para no convertir a string y volver.
- **`encoding/hex` y `encoding/base64`**: codificar payloads y hashes. Reaparecen al [[Exploits y shellcode.base|transformar shellcode]] (Cap. 9) y en [[Criptografía.base|criptografía]] (Cap. 11).

> [!info]+ Iteradores de texto (Go 1.24)
> Go 1.24 añadió variantes *iterator* como `strings.Lines`, `strings.SplitSeq` y `strings.FieldsSeq`, que recorren sin materializar un slice intermedio. En código anterior verás `strings.Split(...)` seguido de un `for range` haciendo lo mismo con más memoria.

Ya controlas los datos; ahora, cómo Go los referencia en memoria: los punteros → [[08 - Punteros]].
