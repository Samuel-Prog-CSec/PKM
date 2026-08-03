---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Hex, percent-encoding y las variantes de Base64: cómo reconocerlas en un volcado y por qué los decodificadores permisivos producen bypass de filtros"
Fecha de actualización: 2026-08-03
Nota previa: "[[04 - Protocolos de texto y formatos estructurados]]"
Nota siguiente: "[[06 - Identificación de estructuras con Kaitai Struct]]"
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

Meter binario en un protocolo de texto exige codificarlo. Históricamente el motivo fue que SMTP y NNTP asumían canales de 7 bits; hoy el motivo es más prosaico: si el transporte es JSON o XML, un byte arbitrario rompería la sintaxis o los delimitadores. La cuestión relevante aquí no es cómo se codifica —eso es trivial— sino <mark style="background: #FFB86CA6;">qué hace el decodificador con entradas que no debería aceptar</mark>.

## Hexadecimal

Cada octeto → dos caracteres. Duplica el tamaño, pero es imposible de estropear.

```text
0x06 0xE3 0x58   →   "06E358"
```

Ventaja de seguridad real: **la superficie del decodificador es mínima**. Los únicos matices son si acepta mayúsculas y minúsculas mezcladas y qué hace con longitud impar.

## Percent-encoding

La variante de HTTP ([RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986)): solo se codifica lo que no es imprimible o es reservado, prefijando con `%`.

```text
0x06 0xE3 'X'   →   "%06%E3X"
```

> [!warning]+ Doble codificación y decodificación en cadena
> Es el *bypass* de filtros más viejo y más vivo. Si el WAF decodifica una vez y la aplicación decodifica dos, `%252e%252e%252f` pasa el filtro como texto inocuo y llega a la aplicación como `../`. El vector completo está en [[00 - Introducción a File Inclusion|File Inclusion]] y en las notas de *path traversal*.
>
> Variantes que hay que probar siempre: doble (`%25xx`), *overlong* UTF-8 (`%c0%ae` para `.`), Unicode de IIS (`%u002e`), y mezcla de mayúsculas (`%2E` frente a `%2e`) por si el filtro compara literalmente.

## Base64

64 caracteres imprimibles, 3 octetos → 4 caracteres. Crecimiento del 33 % frente al 100 % del hexadecimal.

```text
0x06 0xE3 0x58  →  6 bits: 000001 101110 001101 011000  →  "BuNY"
```

Cuando la entrada no es múltiplo de 3, sobra sitio y se rellena con `=`: un octeto → dos `=`, dos octetos → un `=`.

**Las variantes importan** y confundirlas es el error práctico más común:

| Variante | Caracteres 62 y 63 | Relleno | Dónde |
| - | - | - | - |
| Estándar ([RFC 4648 §4](https://datatracker.ietf.org/doc/html/rfc4648#section-4)) | `+` `/` | `=` | MIME, HTTP Basic, certificados PEM |
| **URL-safe** ([§5](https://datatracker.ietf.org/doc/html/rfc4648#section-5)) | `-` `_` | opcional | **JWT**, URLs, nombres de fichero |
| Base32 ([§6](https://datatracker.ietf.org/doc/html/rfc4648#section-6)) | — | `=` | TOTP, direcciones onion, DNS |
| Base64 de MIME | `+` `/` | `=` | Con saltos de línea cada 76 caracteres |

Si intentas decodificar un JWT con Base64 estándar y falla, es porque es URL-safe y sin relleno. Ver `-` o `_` en una cadena Base64 es la pista.

> [!warning]+ Decodificadores permisivos = bypass de filtros
> El RFC 4648 §3.3 dice que un decodificador **debe rechazar** los caracteres fuera del alfabeto, salvo que la especificación diga lo contrario. En la práctica muchísimas librerías los **ignoran en silencio** — Python (`base64.b64decode` sin `validate=True`), Java (`MimeDecoder`), y las de PHP históricamente.
>
> Consecuencia directa: `YWRt!aW4=` y `YWRtaW4=` decodifican a lo mismo, pero **no son la misma cadena** para un filtro que compara texto. Si una lista negra bloquea un valor Base64 concreto, insertar basura lo esquiva.
>
> El mismo problema con el relleno: unas librerías exigen `=`, otras lo toleran ausente, otras aceptan relleno de más. Cuando dos componentes del sistema usan decodificadores distintos, tienes un **parser differential** listo para explotar — la clase de fallo completa está en [[09 - Conversión de codificaciones y parser differentials]]. Es exactamente el vector de varios *bypass* de firma en JWT: el verificador de firma y el consumidor del *payload* decodifican distinto, así que validan una cosa y usan otra.

Y al revés, para el analista: **si un campo Base64 decodifica a algo con estructura, sigue tirando**. Es habitual encontrar dentro un objeto Java serializado (`AC ED 00 05`), un `pickle` de Python (`80 04 95`), DER (`0x30 0x82`) o un protobuf. Ver [[03 - Formatos binarios estructurados]].

## Reconocerlo en un volcado

| Pista | Codificación probable |
| - | - |
| Solo `0-9A-F`, longitud par | Hexadecimal |
| `%` seguido de dos hex | Percent-encoding |
| `A-Za-z0-9+/` con `=` al final | Base64 estándar |
| `A-Za-z0-9-_`, sin `=`, con dos puntos separando | **JWT** (tres partes Base64url) |
| `A-Z2-7` con `=` | Base32 |
| Entropía alta y ningún patrón | Cifrado o comprimido, no codificado |

Esa última fila importa: si un bloque no se deja decodificar con nada y tiene entropía alta, no busques más codificación — está cifrado o comprimido. Compresión y cifrado se distinguen por el principio del bloque (`1F 8B` gzip, `78 9C` zlib, `50 4B` zip) y por si comprime más al recomprimir.

## Herramientas

```shell-session
$ echo -n "SGVsbG8=" | base64 -d | xxd
$ python3 -c "import base64,sys; sys.stdout.buffer.write(base64.urlsafe_b64decode(sys.argv[1]+'=='))" <jwt>
```

Para explorar a ciegas, **CyberChef** con la operación *Magic* prueba decodificaciones en cascada y detecta el formato resultante — es lo más rápido cuando no sabes ni por dónde empezar. En Burp, el *Inspector* y el *Decoder* hacen lo propio ([[06 - Codificación y decodificación]]).

> [!info]+ Fuentes
> - [RFC 4648](https://datatracker.ietf.org/doc/html/rfc4648) — Base16, Base32 y Base64, incluida la §3.3 sobre caracteres fuera del alfabeto.
> - [RFC 3986 §2.1](https://datatracker.ietf.org/doc/html/rfc3986#section-2.1) — percent-encoding.
> - Forshaw, *Attacking Network Protocols*, cap. 3, «Encoding Binary Data».
