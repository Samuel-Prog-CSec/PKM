---
tags:
  - Go
  - Go/SMB
  - Encoding
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - SMB en Go - usar go-smb2]]"
Nota siguiente: "[[02 - Password spraying y pass-the-hash sobre SMB]]"
Area: "[[SMB y NTLM.base|SMB y NTLM]]"
---
---

La técnica más **reutilizable** del capítulo: codificar y decodificar un protocolo binario a medida en Go. El libro la usa para SMB, pero —como para SMB ya usas `go-smb2` (nota [[00 - SMB en Go - usar go-smb2]])— lo que de verdad te llevas es el patrón, que sirve para **cualquier formato binario posicional**: parsear paquetes crudos, cabeceras de fichero (PE, PNG), otros protocolos sin librería. Esta es la lección de Go que sobrevive a la obsolescencia del resto del capítulo.

## El problema: encoding mixto

Los formatos estructurados que ya viste (JSON, XML, nota [[12 - JSON, XML y datos estructurados]]) codifican **todo el struct con el mismo esquema**, de forma recursiva. `encoding/binary` hace lo mismo:

```go
binary.Write(w, binary.LittleEndian, message)   // codifica TODOS los campos igual
```

<mark style="background: #FF5582A6;">Eso no sirve cuando distintos campos del mismo mensaje van en formatos distintos.</mark> SMB, por ejemplo, es binario posicional *little-endian* en casi todo, pero algunos campos van en **ASN.1**. Y hay un problema añadido: los **campos referenciales**. Un dato de longitud variable no va solo; lleva por delante dos campos fijos que dicen su **longitud** y su **offset** dentro del mensaje. No puedes codificar el struct de un tirón porque esos metadatos no se conocen hasta haber codificado el dato.

## La solución: una interfaz de marshaling propia

El truco es definir una interfaz que permita a cada tipo **controlar su propio encoding**:

```go
type BinaryMarshallable interface {
    MarshalBinary(*Metadata) ([]byte, error)
    UnmarshalBinary([]byte, *Metadata) error
}
```

Y un *wrapper* que, antes de codificar por defecto, comprueba si el tipo implementa la interfaz y delega en él (type assertion, nota [[10 - Interfaces]]):

```go
func marshal(v any, meta *Metadata) ([]byte, error) {
    if bm, ok := v.(BinaryMarshallable); ok {   // ¿el tipo sabe codificarse solo?
        return bm.MarshalBinary(meta)           // sí -> le cedo el control
    }
    // ...encoding por defecto con reflection
}
```

<mark style="background: #ADCCFFA6;">Así, un campo concreto puede desviarse a ASN.1</mark> (implementando `MarshalBinary` con `asn1.Marshal`) mientras el resto sigue el camino binario normal. La stdlib tiene una interfaz parecida, `encoding.BinaryMarshaler`, pero sin el parámetro de metadatos que aquí hace falta para los campos referenciales.

## Struct tags para los metadatos

Igual que `json:"..."` describe cómo mapear un campo (nota [[12 - JSON, XML y datos estructurados]]), aquí se inventan tags `smb:"..."` para describir la relación entre campos:

```go
type NegotiateRes struct {
    // ...
    ServerGuid           []byte `smb:"fixed:16"`             // []byte de 16 bytes fijos
    SecurityBufferOffset uint16 `smb:"offset:SecurityBlob"`  // soy el offset de SecurityBlob
    SecurityBufferLength uint16 `smb:"len:SecurityBlob"`     // soy la longitud de SecurityBlob
    SecurityBlob         *gss.NegTokenInit                    // dato de longitud variable
}
```

- `fixed:N` — slice de longitud fija N.
- `len:Campo` / `offset:Campo` — este campo **es** la longitud/offset de otro campo del mismo struct.

Los nombres de los tags son arbitrarios (los eligió el autor); lo que importa es que el código que los parsea use la misma clave.

## Reflection: recorrer el struct por tipos

Los tags no hacen nada solos; hace falta código que los lea y actúe. Ahí entra `reflect`: <mark style="background: #8000E1A6;">permite a un programa inspeccionarse a sí mismo</mark> — cuántos campos tiene un struct, de qué tipo es cada uno, qué tags lleva. El `unmarshal` recorre el struct campo a campo y, según el **Kind** de cada tipo, decide cuántos bytes leer:

```go
func unmarshal(r *bytes.Reader, v reflect.Value, meta *Metadata) error {
    switch v.Kind() {
    case reflect.Struct:
        for i := 0; i < v.NumField(); i++ {
            tags, _ := parseTags(v.Type().Field(i))   // .Tag.Get("smb")
            _ = tags
            unmarshal(r, v.Field(i), meta)            // recursión respetando fixed/len/offset
        }
    case reflect.Uint16:
        var n uint16
        binary.Read(r, binary.LittleEndian, &n)       // avanza el cursor de r 2 bytes
        v.SetUint(uint64(n))                          // ESCRIBE en el campo (vía reflection)
    // case Uint32, Uint64, Slice... (un case por tipo)
    }
    return nil
}
```

Dos piezas hacen que funcione, y son las que el libro deja en el `// ...`: un **lector compartido** `r` cuyo cursor avanza con cada `binary.Read`, y `reflect.Value.Set…` para **escribir** el valor decodificado en el campo (`v` es un `reflect.Value`, no un `reflect.Type`, sacado de `reflect.ValueOf(punteroAlStruct).Elem()`). `binary.Read` sabe cuántos bytes leer según el tipo destino (2 para `uint16`, 8 para `uint64`). Al toparse con un slice de longitud variable, usa la longitud y el offset que guardó al leer los campos referenciales previos. Es verboso —un `case` por cada tipo— pero es la única forma de convertir bytes arbitrarios en un struct sin conocer su forma de antemano.

## Cuándo lo necesitas de verdad

<mark style="background: #FFB8EBA6;">Para un layout binario **fijo** (sin campos referenciales) no necesitas nada de esto</mark>: `binary.Read` sobre un struct de campos de tamaño fijo basta.

```go
type Header struct {   // cabecera de tamaño fijo
    Magic   uint32
    Version uint16
    Length  uint16
}
var h Header
binary.Read(conn, binary.LittleEndian, &h)   // y ya está
```

La maquinaria de reflection + tags solo hace falta para el caso difícil: **longitud variable con campos de longitud/offset que se referencian entre sí**. Ese patrón reaparece al construir y parsear paquetes a mano (Cap. 8, [[Raw packets.base|Raw packets]]) y al leer formatos de fichero binarios (PE en Windows, PNG en esteganografía). Por eso vale la pena entenderlo aunque para SMB uses la librería.

Con la mecánica de SMB clara, pasamos a lo ofensivo: autenticarse contra SMB para spraying de contraseñas y pass-the-hash → [[02 - Password spraying y pass-the-hash sobre SMB]].
