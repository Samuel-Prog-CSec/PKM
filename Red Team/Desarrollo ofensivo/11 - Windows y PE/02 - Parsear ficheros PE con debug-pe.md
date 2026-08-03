---
tags:
  - Go
  - Go/Windows
  - Reverse-Engineering
Descripción: "El PE (*Portable Executable*) es el formato de los .exe, .dll y object files de Windows"
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - Process injection clásica]]"
Nota siguiente: "[[03 - CGO - mezclar C y Go]]"
Area: "[[Windows y PE.base|Windows y PE]]"
---
---

<mark style="background: #ADCCFFA6;">El PE (*Portable Executable*) es el formato de los `.exe`, `.dll` y object files de Windows</mark>. Entender su estructura sirve para analizar un binario (malware analysis), verificar qué hace, o modificar un ejecutable existente. Go trae un parser en la stdlib —`debug/pe`— que hace el trabajo pesado; parsear los offsets a mano es el ejercicio para *entender* qué hay dentro.

## La estructura, de arriba abajo

Un PE es una pila de cabeceras con dos firmas invariantes que lo identifican:

| Zona | Qué es |
| - | - |
| **DOS header** | Empieza con `0x4D 0x5A` (`MZ` en ASCII). En el offset `0x3C` hay un puntero al PE header. |
| **DOS stub** | El clásico "This program cannot be run in DOS mode". |
| **PE signature** | En el offset que apunta `0x3C`: `0x50 0x45 0x00 0x00` (`PE\0\0`). |
| **COFF file header** | Número de secciones, arquitectura, timestamp. |
| **Optional header** | 32 o 64 bits; *entry point*, *image base*, data directories (EAT, IAT…). |
| **Section table** | Las secciones: `.text` (código), `.rodata`, `.data`, etc. |

## Parsear con `debug/pe`

Lo idiomático es dejar que la stdlib abra el fichero y te dé la estructura ya parseada:

```go
f, err := os.Open("Telegram.exe")
if err != nil {
    log.Fatal(err)
}
defer f.Close()

pefile, err := pe.NewFile(f)          // debug/pe: parsea cabeceras y secciones
if err != nil {
    log.Fatal(err)
}
defer pefile.Close()

for _, s := range pefile.Sections {
    fmt.Printf("%-8s vaddr=%#x vsize=%#x rawsize=%#x flags=%#x\n",
        s.Name, s.VirtualAddress, s.VirtualSize, s.Size, s.Characteristics)
}
```

`pe.NewFile` te devuelve un `*pe.File` con `.Sections`, `.Symbols`, `.OptionalHeader` y demás — <mark style="background: #FFB86CA6;">no reinventes el parseo salvo para aprender</mark>.

## Parseo manual: leer los offsets a pelo

Para entender el formato, se leen los bytes crudos con `encoding/binary` (mismo patrón que [[01 - Codificación binaria a medida - reflection y struct tags]]):

```go
dosHeader := make([]byte, 96)
f.Read(dosHeader)
// Firma MZ en los dos primeros bytes:
fmt.Printf("Magic: %s\n", string(dosHeader[0:2]))            // "MZ"

// El offset del PE header vive en 0x3C, little-endian:
peOffset := int64(binary.LittleEndian.Uint32(dosHeader[0x3c:]))
sig := make([]byte, 4)
f.ReadAt(sig, peOffset)
fmt.Printf("Sig: %s\n", string(sig[:2]))                     // "PE"
```

<mark style="background: #8000E1A6;">Todos los enteros del PE son *little-endian*</mark> — por eso `binary.LittleEndian.Uint32`. Este es el corazón del formato: `MZ` en el byte 0, el puntero al `PE` en `0x3C`.

## Las secciones y sus permisos

Cada sección declara sus permisos en el campo *Characteristics*, un OR de flags:

| Flag | Valor | Significado |
| - | - | - |
| `IMAGE_SCN_CNT_CODE` | `0x00000020` | Contiene código ejecutable. |
| `IMAGE_SCN_MEM_EXECUTE` | `0x20000000` | Se puede ejecutar. |
| `IMAGE_SCN_MEM_READ` | `0x40000000` | Se puede leer. |

Una `.text` típica trae `0x60000020` = la suma de los tres (código + ejecutable + legible). <mark style="background: #FFB8EBA6;">Leer estos flags te dice qué zonas del binario contienen código</mark> y cuáles son datos — el primer paso de cualquier análisis o modificación.

> [!info]+ Para qué se usa esto en ofensiva y RE
> Más allá de analizar: se pueden **añadir secciones** o reutilizar un *code cave* (hueco de bytes nulos en una sección existente) para inyectar shellcode ([[04 - Shellcode Go-friendly con msfvenom]]) y *backdoorear* un binario legítimo — actualizando entry point, número de secciones y offsets. Y el parser revela **packers**: un binario con pocas secciones, nombres raros (`UPX0`, `UPX1`) y entropía alta está empaquetado. Navegar la **EAT** (funciones exportadas) e **IAT** (importadas) con `debug/pe` te dice qué APIs usa el binario — perfilar un ejecutable sin ejecutarlo.

De leer binarios ajenos pasamos a construirlos mezclando lenguajes: usar C desde Go (y viceversa) con CGO → [[03 - CGO - mezclar C y Go]].
