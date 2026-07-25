---
tags:
  - Go
  - Go/Esteganografia
  - Post-Explotacion
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - El formato PNG - leer chunks]]"
Nota siguiente: "[[02 - Ofuscar el payload con XOR]]"
Area: "[[Esteganografía.base|Esteganografía]]"
---
---

Sabiendo leer los chunks ([[00 - El formato PNG - leer chunks]]), el siguiente paso es escribir el tuyo. <mark style="background: #ADCCFFA6;">La clave está en los chunks *auxiliares* (los de nombre en minúscula): son opcionales, el decodificador de imagen los ignora</mark>. Insertas un chunk auxiliar con tu payload dentro y el PNG se sigue viendo idéntico, pero lleva tu carga escondida. El payload suele ser shellcode ([[04 - Shellcode Go-friendly con msfvenom]]).

## Dónde insertar

Cualquier posición en zona auxiliar sirve; lo cómodo es **justo antes del chunk `IEND`** (el que marca el EOF). Localizas ese offset recorriendo los chunks hasta el último — el `getOffset` de la nota anterior te lo da. Con el offset elegido, construyes el chunk nuevo con la misma estructura `SIZE·TYPE·DATA·CRC`.

## Construir el chunk

Un `MetaChunk` con los cuatro campos. El `TYPE` es un nombre de 4 caracteres que te inventas (auxiliar → primera letra minúscula, p. ej. `rNDm`); `SIZE` es la longitud del payload; y `CRC` hay que **recalcularlo** o el PNG queda corrupto:

```go
func (mc *MetaChunk) createChunkCRC() uint32 {
    var buf bytes.Buffer
    binary.Write(&buf, binary.BigEndian, mc.Chk.Type)   // el CRC cubre TYPE...
    binary.Write(&buf, binary.BigEndian, mc.Chk.Data)   // ...y DATA
    return crc32.ChecksumIEEE(buf.Bytes())              // hash/crc32, algoritmo IEEE
}
```

<mark style="background: #FFB86CA6;">El `CRC` es un checksum CRC-32 de `TYPE+DATA`</mark> (paquete `hash/crc32`). Si lo dejas mal, un visor estricto rechaza la imagen. Luego se serializa todo el chunk a bytes con `binary.Write` en big-endian (mismo patrón de [[01 - Codificación binaria a medida - reflection y struct tags]]):

```go
func (mc *MetaChunk) marshalData() *bytes.Buffer {
    var buf bytes.Buffer
    binary.Write(&buf, binary.BigEndian, mc.Chk.Size)
    binary.Write(&buf, binary.BigEndian, mc.Chk.Type)
    binary.Write(&buf, binary.BigEndian, mc.Chk.Data)
    binary.Write(&buf, binary.BigEndian, mc.Chk.CRC)
    return &buf
}
```

## Escribir el nuevo PNG

`WriteData` reconstruye la imagen: los bytes originales **hasta** el offset, luego tu chunk, luego **el resto** del original. Así tu chunk queda intercalado sin corromper los demás:

```go
func WriteData(r *bytes.Reader, out string, offset int64, chunk []byte) error {
    w, err := os.Create(out)
    if err != nil {
        return err
    }
    defer w.Close()

    r.Seek(0, io.SeekStart)              // volver al inicio del original
    head := make([]byte, offset)
    r.Read(head)
    w.Write(head)                        // 1. bytes originales hasta el offset
    w.Write(chunk)                       // 2. el chunk nuevo con el payload
    _, err = io.Copy(w, r)               // 3. el resto del original (r ya está en offset)
    return err
}
```

`r.Seek(0, io.SeekStart)` rebobina al principio (los 8 bytes del header van también en la salida); lees `offset` bytes, escribes tu chunk, y `io.Copy` vuelca lo que queda del reader —que ya avanzó hasta `offset`— al final. <mark style="background: #8000E1A6;">Resultado: una imagen visualmente idéntica que oculta tu payload en un chunk auxiliar</mark>.

```shell-session
$ go run main.go -i battlecat.png -o out.png --inject --offset 0x85258 \
    --type rNDm --payload <bytes>
```

> [!warning]+ Devuelve `error`, no `log.Fatal`
> El código del libro usa `log.Fatal` dentro de estos métodos de librería y `os.Create` con permisos `0777`. Ambos son malos hábitos: <mark style="background: #FF5582A6;">`log.Fatal` mata el proceso desde código reutilizable</mark> (devuelve `error` y decide en `main`, nota [[11 - Manejo de errores]]), y `0777` da permisos de ejecución al fichero de salida sin motivo — usa `0644`. Y no olvides recalcular el CRC si modificas el `DATA` después (un bug que el propio libro deja como ejercicio en la parte de decodificado).

> [!info]+ Esteganografía ≠ invisible
> Ocultar el payload en un chunk auxiliar lo esconde de una **inspección visual**, pero no de un análisis. Un chunk con nombre inventado (`rNDm`), datos de alta entropía y un tamaño que no cuadra con la imagen es exactamente lo que busca el *steganalysis*. Es ofuscación de presentación, no invisibilidad — combínalo con cifrado real para que el contenido tampoco sea legible.

El payload va en claro dentro del chunk. Para que ni siquiera un extractor casual lo lea, hay que transformarlo — el libro empieza por XOR → [[02 - Ofuscar el payload con XOR]].
