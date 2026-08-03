---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Reconocer ASN.1/DER, Protobuf, CBOR y MessagePack dentro de un protocolo propietario, y por qué identificarlos te ahorra el análisis entero"
Fecha de actualización: 2026-08-03
Nota previa: "[[02 - El patrón TLV, multiplexación y fragmentación]]"
Nota siguiente: "[[04 - Protocolos de texto y formatos estructurados]]"
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

No todo protocolo se inventa su formato. Muchos reutilizan uno estándar y solo definen la semántica encima. <mark style="background: #8000E1A6;">Reconocer el formato subyacente convierte un análisis de días en uno de minutos</mark>: en vez de deducir la estructura byte a byte, sueltas el volcado en un decodificador genérico y te devuelve el árbol completo.

## ASN.1 y DER

`ASN.1` (*Abstract Syntax Notation One*, ISO/IEC/ITU serie X.680) describe estructuras de datos de forma abstracta; las *encoding rules* dicen cómo se serializan. La que vas a ver es **DER** (*Distinguished Encoding Rules*, X.690), diseñada para que cada valor tenga **una sola representación posible** — propiedad imprescindible cuando se firma criptográficamente.

DER es TLV puro. Está debajo de: **X.509** (todos los certificados TLS), **LDAP**, **SNMP**, **Kerberos**, **PKCS#7/CMS**, **EMV** (tarjetas bancarias) y buena parte de la señalización de telecomunicaciones.

Cómo se reconoce en un volcado: la secuencia empieza casi siempre por `0x30` (`SEQUENCE`), seguida de la longitud. Si la longitud supera 127, el octeto tiene el bit alto puesto e indica cuántos octetos ocupa la longitud real — `0x30 0x82 0x02 0x1B` es una `SEQUENCE` de 0x021B octetos.

```shell-session
$ openssl asn1parse -in certificado.der -inform DER
    0:d=0  hl=4 l= 539 cons: SEQUENCE
    4:d=1  hl=4 l= 388 cons: SEQUENCE
   13:d=2  hl=2 l=  16 prim: INTEGER   :19BB8E9E2F7D60BE48BFE6840B50F7C3
   33:d=3  hl=2 l=   9 prim: OBJECT    :sha1WithRSAEncryption
```

Si `asn1parse` parsea tu blob desconocido sin errores, ya tienes la estructura.

> [!warning]+ Los parsers de ASN.1 son un pozo de vulnerabilidades
> Es de los formatos con peor historial de la industria, por tres razones: la codificación de longitud es variable y compleja, admite anidamiento arbitrario, y hay reglas alternativas (BER, CER, DER) con laxitudes distintas. El resultado son décadas de fallos: la familia de bugs de ASN.1 de OpenSSL, los parsers de X.509 de Microsoft (CVE-2020-0601, la confusión de curvas elípticas en `crypt32`) y un torrente de CVEs en pilas SNMP empotradas.
>
> Si el objetivo parsea ASN.1 con código propio en vez de con una librería madura, es el primer sitio donde fuzzear. Cotas que probar: longitud que declara más de lo que hay, anidamiento de 10.000 niveles, longitud indefinida (`0x80`, legal en BER pero **no** en DER — si el parser la acepta, no está haciendo DER estricto), y enteros con relleno redundante.

## Protocol Buffers

El formato de serialización de Google, omnipresente en gRPC, APIs internas y aplicaciones móviles. Es TLV con varints ([[00 - Anatomía de un protocolo binario]]): cada campo empieza por un varint de etiqueta con la forma `(número_de_campo << 3) | wire_type`.

| `wire_type` | Significa | Le sigue |
| - | - | - |
| **0** | VARINT | El varint (enteros, `bool`, `enum`) |
| **1** | I64 | 8 octetos fijos (`double`, `fixed64`) |
| **2** | LEN | Un varint de longitud + esos octetos (cadenas, `bytes`, **submensajes**) |
| **5** | I32 | 4 octetos fijos (`float`, `fixed32`) |

Con eso ya se lee un mensaje a mano. Estos 13 octetos:

```text
08 2A 12 09 0A 05 61 6C 69 63 65 18 01
```

```text
08  → (1 << 3)|0  campo 1, VARINT
2A  →             valor 42
12  → (2 << 3)|2  campo 2, LEN  (submensaje)
09  →             9 octetos de longitud
    0A  → (1 << 3)|2  campo 1, LEN
    05  →             5 octetos
    61 6C 69 63 65  →  "alice"
    18  → (3 << 3)|0  campo 3, VARINT
    01  →             valor 1
```

Que es exactamente lo que devuelve el decodificador genérico:

```shell-session
$ protoc --decode_raw < mensaje.bin
1: 42
2 {
  1: "alice"
  3: 1
}
```

Lo relevante para un análisis: <mark style="background: #FF5582A6;">Protobuf es autodescriptivo en estructura pero no en semántica</mark>. Sabes que el campo 1 es un varint de valor 42, pero no que se llama `user_id`. Y hay una ambigüedad que hay que tener presente: **el `wire_type` 2 no distingue entre una cadena, un `bytes` y un submensaje** — `protoc` intenta interpretarlo como submensaje y, si no cuadra, lo muestra como cadena. Cuando veas una cadena con basura binaria, prueba a re-decodificarla como mensaje anidado.

Y muchas veces el `.proto` se puede **recuperar del binario**: los descriptores suelen quedar embebidos en las aplicaciones Java/Kotlin y en los binarios Go. Herramientas: `protobuf-inspector`, `blackboxprotobuf` (con extensión para Burp) y `pbtk` para extraerlos de APKs.

## CBOR y MessagePack

Serialización binaria compacta con la semántica de JSON.

- **CBOR** ([RFC 8949](https://datatracker.ietf.org/doc/html/rfc8949)) es estándar IETF y está en **COSE**, **WebAuthn/FIDO2**, **CoAP** (IoT) y credenciales verificables. Se reconoce por los *major types* en los 3 bits altos del primer octeto.
- **MessagePack** es su equivalente de facto no estandarizado, habitual en RPC internos, juegos, telemetría y en el *scripting* Lua de Redis (`cmsgpack`) — **no** en el protocolo nativo de Redis, que es RESP y es de texto.

Riesgo característico de ambos: soportan **tipos extendidos** y mapas con claves arbitrarias, y algunas librerías los deserializan a objetos nativos. Cuando la deserialización instancia clases con lógica asociada, se cae en el mismo terreno que la deserialización insegura de Java o .NET.

## Otros que aparecen

| Formato | Dónde | Pista |
| - | - | - |
| **FlatBuffers / Cap'n Proto** | Juegos, alto rendimiento | Acceso sin copia, offsets en vez de longitudes |
| **BSON** | MongoDB y su protocolo de cable | `int32` de longitud total al principio ([[NoSQL Injection.base\|NoSQL Injection]]) |
| **Thrift** | Servicios de Meta y derivados | Compacto o binario, TLV con tipo |
| **Avro** | Ecosistema Kafka/Hadoop | El esquema viaja aparte |
| **Java serialization** | RMI, JMX, protocolos JVM | **Cabecera `AC ED 00 05`** — bandera roja inmediata |
| **.NET BinaryFormatter** | WCF, remoting legado | Empieza por `00 01 00 00 00 FF FF FF FF` |

> [!important]+ `AC ED 00 05` es lo más rentable que puedes ver
> Si un volcado empieza por esos cuatro octetos, el protocolo transporta **objetos Java serializados**. Eso significa que el destino llama a `readObject()` sobre datos que tú controlas, y con un *gadget chain* adecuado (`ysoserial`) eso es ejecución remota de código sin autenticar. La cabecera de `.NET BinaryFormatter` juega el mismo papel — y Microsoft lo declaró obsoleto y lo **eliminó de .NET 9** precisamente por esto.
>
> Vale la pena buscar esas firmas en **todo** volcado, incluso dentro de campos Base64 de protocolos de texto.

## El flujo práctico

1. **Mira los primeros octetos** contra la tabla de firmas de arriba.
2. **Prueba decodificadores genéricos** en cascada: `openssl asn1parse`, `protoc --decode_raw`, `cbor.loads`, `msgpack.unpackb`. Cuesta un minuto y resuelve el caso a menudo.
3. **Si uno parsea limpiamente el volcado entero**, ya tienes la estructura — céntrate en la semántica.
4. **Si ninguno parsea**, es formato propio: vuelve a [[05 - Del hex dump a la estructura del protocolo]].

> [!info]+ Fuentes
> - [ITU-T X.690](https://www.itu.int/rec/T-REC-X.690/) — especificación de BER, CER y DER.
> - [RFC 8949](https://datatracker.ietf.org/doc/html/rfc8949) — CBOR.
> - [Protocol Buffers — Encoding](https://protobuf.dev/programming-guides/encoding/).
> - [.NET 9 — BinaryFormatter removal](https://learn.microsoft.com/en-us/dotnet/standard/serialization/binaryformatter-migration-guide/) — eliminado por riesgo de deserialización insegura.
