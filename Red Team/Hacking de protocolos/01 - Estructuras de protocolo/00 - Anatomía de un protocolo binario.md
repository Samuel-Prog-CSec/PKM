---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "Los tipos básicos que aparecen en todo protocolo binario — enteros con y sin signo, varints, flotantes, flags, endianness, fechas y direcciones — y el fallo que esconde cada uno"
Fecha de actualización: 2026-08-03
Nota previa: 
Nota siguiente: "[[01 - Datos de longitud variable]]"
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

«No hay nada nuevo bajo el sol»: los protocolos binarios se construyen con un puñado muy corto de piezas, y una vez las reconoces, un protocolo desconocido deja de ser ruido. Esta nota es el catálogo — y para cada pieza, <mark style="background: #FFB86CA6;">el fallo típico que esconde</mark>, porque identificar la estructura y detectar la vulnerabilidad son el mismo ejercicio.

La unidad de trabajo es el **octeto** (8 bits). El bit 7 es el más significativo (MSB), el 0 el menos (LSB) — al revés en algunas arquitecturas como PowerPC, que numeran en el otro sentido.

## Enteros sin signo

Lo más común. `0x41` es 65, y ya está. Los tamaños habituales son 8, 16, 32 y 64 bits.

## Enteros con signo y complemento a dos

Para representar negativos, la convención universal es el **complemento a dos**: negar un número es aplicar NOT bit a bit y **sumar 1**.

```text
  0111 1011   0x7B    123      ← partimos de 123
  1000 0100           NOT      ← invertimos cada bit
+ 0000 0001           +1       ← y sumamos uno
  ─────────
  1000 0101   0x85   -123      ← resultado: -123
```

Para leerlo al revés (dado un byte, ¿qué valor con signo es?): si el bit 7 vale 1, el número es negativo y su valor es `byte − 256`. Así, `0x85` = 133 − 256 = **−123**. ✓

> [!warning]+ La asimetría del complemento a dos es explotable
> Un entero de 8 bits con signo va de **-128 a 127**: el mínimo tiene mayor magnitud que el máximo. Consecuencia: `-(-128) == -128`. Negar el mínimo devuelve el mínimo, y `abs()` de un valor mínimo sigue siendo negativo.
>
> Si un protocolo lee un `int32` como longitud y el código hace `if (len > MAX) reject;` sin comprobar `len < 0`, un valor negativo pasa el filtro y luego se convierte a `size_t` en el `malloc` o el `memcpy` — donde se reinterpreta como un número gigantesco. Es una de las rutas clásicas a desbordamiento de *heap*. Ver [[02 - Errores de enteros - overflow, truncamiento y signo]].

## Enteros de longitud variable (varint)

Cuando la mayoría de valores son pequeños, se ahorra espacio codificando **7 bits útiles por octeto** y usando el bit más alto (MSB) como «sigue otro octeto». Los grupos de 7 bits van **de menos a más significativo**, es decir *little-endian en base 128*.

```text
0x3F                         → 0x3F         (1 octeto)
0x80 0x01                    → 0x80         (2 octetos)
0x84 0x86 0x88 0x08          → 0x01020304   (4 octetos)
0xFF 0xFF 0xFF 0xFF 0x0F     → 0xFFFFFFFF   (5 octetos, el máximo para 32 bits)
```

Descodificando el tercer ejemplo paso a paso, que es la única forma de que el patrón se te quede:

```text
octeto   MSB   carga (7 bits)   desplazamiento   aporta
0x84      1       0x04              << 0                  4
0x86      1       0x06              << 7                768
0x88      1       0x08              << 14           131 072
0x08      0 ←fin  0x08              << 21        16 777 216
                                                 ──────────
                                                 16 909 060  =  0x01020304 ✓
```

El MSB a 0 en el último octeto es lo que marca el final. Comprobarlo en Python:

```python
>>> b = bytes([0x84, 0x86, 0x88, 0x08])
>>> v = s = 0
>>> for o in b:
...     v |= (o & 0x7F) << s; s += 7
>>> hex(v)
'0x1020304'
```

Es la codificación de longitudes de **Protocol Buffers**, del *Remaining Length* de MQTT, de los `LEB128` de WebAssembly y de multitud de formatos propios.

<mark style="background: #FF5582A6;">El fallo vive en el caso «más de 5 octetos»</mark>: qué hace el parser si le llegan 10 octetos con el bit de continuación puesto. En C es habitual que se limite a descartar los bits sobrantes y devolver un número truncado que no se parece al que se envió — y si esa longitud gobierna una reserva de memoria, ya tienes el desajuste.

## Flotantes

`IEEE 754`: bit de signo, exponente y mantisa. En la práctica solo verás dos:

| Bits | Exponente | Mantisa | Rango |
| - | - | - | - |
| 32 (*single*) | 8 | 23 | ±3,4 × 10³⁸ |
| 64 (*double*) | 11 | 52 | ±1,8 × 10³⁰⁸ |

Aparecen en protocolos de juegos, telemetría y control industrial. Valores especiales —`NaN`, `±Inf`, denormales— rompen comparaciones (`NaN != NaN`) y son un vector de *fuzzing* barato: si el parser usa el valor para indexar o dimensionar, un `NaN` convertido a entero es comportamiento indefinido en C.

## Booleanos y banderas de bits

Un bit basta, pero por comodidad casi siempre se usa un octeto entero (`0` falso, distinto de `0` verdadero). Cuando varios estados pueden darse **a la vez**, se usan banderas de bits: el ejemplo canónico es TCP, donde `SYN` y `ACK` conviven en el mismo campo para el segundo paso del *handshake*. Con valores enumerados eso obligaría a inventar un estado `SYN/ACK` explícito.

Al analizar: si un byte toma valores como `0x01`, `0x02`, `0x03`, `0x04`, `0x05`… es un enumerado. Si toma `0x01`, `0x02`, `0x04`, `0x08`, `0x0C`… son banderas. **Bit sin documentar = funcionalidad sin probar**, y esos son los que hay que activar.

## Endianness

El orden en que viajan los octetos de un valor multi-byte:

```text
0x01020304  big endian    →  01 02 03 04     (MSB primero)
0x01020304  little endian →  04 03 02 01     (LSB primero)
```

Los RFC especifican **big endian**, y por eso se le llama *network order*; x86 y ARM (en su configuración habitual) son *little endian*, el *host order*. De ahí las funciones `htons`/`htonl`/`ntohs`/`ntohl`.

> [!important]+ El endian es la primera prueba de una hipótesis de longitud
> Si crees haber encontrado un campo de longitud y los números salen absurdos, prueba el otro orden antes de descartar la hipótesis. `00 00 01 00` es 256 en big endian y 65536 en little endian: uno de los dos casará con el tamaño del bloque. Muchos protocolos propietarios usan little endian porque el desarrollador volcó la estructura de C directamente al socket — y eso, además, te dice que probablemente **no hay validación** en el otro extremo, solo un `memcpy` sobre un `struct`.

Existe el *middle endian* (PDP-11, que intercambia palabras de 16 bits), pero no te lo vas a encontrar.

## Fechas y horas

| Formato | Representación | Época | Nota |
| - | - | - | - |
| **POSIX / Unix** | `int32` o `int64`, segundos | 1970-01-01 UTC | El de 32 bits **desborda el 19-01-2038** |
| **Windows FILETIME** | `uint64`, intervalos de 100 ns | 1601-01-01 UTC | Rango mucho mayor; aparece en SMB, NTLM y Kerberos |

El *Year 2038 problem* no es teórico: cualquier sistema empotrado que siga usando `time_t` de 32 bits en 2038 producirá fechas negativas. Y en protocolos con credenciales, una fecha de caducidad que desborda es un **fallo de autenticación**: el token nunca expira, o expiró en 1901.

Reconocer un *timestamp* en un volcado es fácil: un `uint32` cercano a `0x68…` hoy, o un `uint64` que empieza por `0x01D…` para FILETIME.

## Direcciones de red

```text
7F 00 00 01  00 50            → 127.0.0.1 : 80         (IPv4 + puerto, big endian)
00 ... 00 01  00 50           → ::1 : 80               (IPv6, 16 octetos)
'a' '.' 'c' 'o' 'm' 00  00 50 → a.com : 80             (nombre terminado en NUL)
```

Por convención van en *network order*. Cuando el protocolo transporta **la dirección a la que hay que conectarse después** —patrón de FTP activo, SIP, RTSP, o cualquier *broker* que devuelve el puerto del servicio real— tienes dos cosas: una pesadilla para el proxy (necesitas reescribir la dirección en vuelo) y un candidato claro a **SSRF a nivel de protocolo**, porque si puedes influir en ese campo, decides a dónde se conecta el servidor.

## Cómo se usa esto

Con el catálogo en la cabeza, el volcado hexadecimal de [[05 - Del hex dump a la estructura del protocolo]] deja de ser opaco. El siguiente eslabón es cómo el protocolo delimita lo que **no** tiene tamaño fijo: [[01 - Datos de longitud variable]].

> [!info]+ Fuentes
> - [RFC 1700](https://datatracker.ietf.org/doc/html/rfc1700) (*Assigned Numbers*) fija el orden de red big endian; [RFC 791 §3.1](https://datatracker.ietf.org/doc/html/rfc791) lo aplica a IP.
> - [IEEE 754-2019](https://standards.ieee.org/ieee/754/6210/) para la representación en coma flotante.
> - [Protocol Buffers — Encoding](https://protobuf.dev/programming-guides/encoding/) para la definición de varint.
> - Forshaw, *Attacking Network Protocols*, cap. 3.
