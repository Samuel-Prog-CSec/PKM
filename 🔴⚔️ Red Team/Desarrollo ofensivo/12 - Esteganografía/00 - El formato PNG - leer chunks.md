---
tags:
  - Go
  - Go/Esteganografia
  - Tipo/Introduccion
Descripción: "Esteganografía es ocultar datos dentro de otros datos —una imagen, por ejemplo— para extraerlos más tarde"
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - Implantar un payload en un chunk PNG]]"
Area: "[[Esteganografía.base|Esteganografía]]"
---
---

<mark style="background: #ADCCFFA6;">Esteganografía es ocultar datos dentro de otros datos —una imagen, por ejemplo— para extraerlos más tarde</mark>. En ofensiva: escondes un payload que recuperas una vez entregado al objetivo, sin que salte a la vista. El vehículo de este capítulo es el PNG. Antes de implantar nada, hay que saber leer su estructura byte a byte — y Go lo hace cómodo con `encoding/binary` (nota [[01 - Codificación binaria a medida - reflection y struct tags]]).

## La estructura de un PNG

Un PNG es un **header** de 8 bytes seguido de una secuencia repetitiva de **chunks** hasta el final:

- **Header** (8 bytes): `89 50 4E 47 0D 0A 1A 0A` — los bytes 2-4 son `PNG` en ASCII. Son los *magic bytes*, idénticos en todo PNG válido.
- **Chunk** (se repite): `SIZE` (4 bytes, longitud del DATA) · `TYPE` (4 bytes) · `DATA` (SIZE bytes) · `CRC` (4 bytes, checksum de TYPE+DATA).

Los tipos de chunk que importan: `IHDR` (metadatos), `IDAT` (los bytes de la imagen) e `IEND` (marca el EOF). <mark style="background: #FFB8EBA6;">Un detalle clave: los chunks *críticos* empiezan por mayúscula y los *auxiliares* por minúscula</mark> — esa distinción es la que explota la siguiente nota.

Se modela con dos structs (el header cabe en un `uint64`):

```go
type Header struct {
    Magic uint64          // los 8 magic bytes
}
type Chunk struct {
    Size uint32
    Type uint32
    Data []byte
    CRC  uint32
}
```

## Leer y validar

Se carga el fichero en un `*bytes.Reader` y se lee con `binary.Read` en **big-endian** (los formatos de red y muchos binarios usan *most significant byte first*):

```go
func validate(b *bytes.Reader) error {
    var h Header
    if err := binary.Read(b, binary.BigEndian, &h.Magic); err != nil {
        return err
    }
    magic := make([]byte, 8)
    binary.BigEndian.PutUint64(magic, h.Magic)
    if string(magic[1:4]) != "PNG" {
        return errors.New("no es un PNG válido")
    }
    return nil
}
```

> [!warning]+ Dos mejoras sobre el libro
> El libro valida leyendo a `uint64` y comparando `string(bArr[1:4])`. Más directo: comparar el prefijo crudo con `bytes.HasPrefix(raw, []byte{0x89, 'P', 'N', 'G', 0x0d, 0x0a, 0x1a, 0x0a})` — sin marshaling intermedio. Y <mark style="background: #FF5582A6;">el libro usa `log.Fatal` dentro de métodos de librería</mark>: eso mata el programa entero desde código reutilizable. Devuelve `error` y decide arriba (nota [[11 - Manejo de errores]]); `log.Fatal` solo en `main`.

## Recorrer los chunks

El header aparece una vez; los chunks se repiten hasta `IEND`. Un bucle los recorre, guardando el *offset* de cada uno (su posición absoluta, que necesitarás para implantar):

```go
func (mc *MetaChunk) ProcessImage(b *bytes.Reader) {
    for chunkType := ""; chunkType != "IEND"; {
        mc.Offset, _ = b.Seek(0, io.SeekCurrent)   // offset actual sin moverlo
        mc.readChunk(b)                            // lee SIZE, TYPE, DATA, CRC
        chunkType = mc.chunkTypeToString()
    }
}

func (mc *MetaChunk) readChunk(b *bytes.Reader) {
    binary.Read(b, binary.BigEndian, &mc.Chk.Size)
    binary.Read(b, binary.BigEndian, &mc.Chk.Type)
    mc.Chk.Data = make([]byte, mc.Chk.Size)        // el slice se dimensiona con SIZE
    binary.Read(b, binary.BigEndian, &mc.Chk.Data)
    binary.Read(b, binary.BigEndian, &mc.Chk.CRC)
}
```

`b.Seek(0, io.SeekCurrent)` devuelve la posición actual sin moverla — así capturas el offset de cada chunk. Y `readChunkBytes` dimensiona el slice con el `SIZE` que acabas de leer: es la única parte de longitud variable.

> [!important]+ Por qué se pasa `*bytes.Reader` por puntero
> `validate` y `ProcessImage` reciben el **mismo** `*bytes.Reader`. Como es un puntero (nota [[08 - Punteros]]), <mark style="background: #8000E1A6;">el avance del reader se comparte entre llamadas</mark>: cuando `validate` consume los 8 bytes del header, `ProcessImage` continúa desde el byte 8, no desde el 0. Pasarlo por valor daría copias, cada una posicionada al inicio — tendrías que gestionar la posición a mano. El puntero mantiene un único cursor.

> [!info]+ ¿Y `image/png` de la stdlib?
> Go trae `image/png`, pero **decodifica** la imagen (píxeles), no te da los chunks crudos. Para inyectar un chunk arbitrario necesitas el parseo manual de esta nota — `image/png` no expone esa capa.

Con la estructura leída y los offsets localizados, el siguiente paso es escribir tu propio chunk con el payload dentro → [[01 - Implantar un payload en un chunk PNG]].
