---
tags:
  - Reversing
  - Protocolos
  - Pentesting/Enumeracion
Descripción: "Las cuatro vías para encontrar dónde se habla el protocolo dentro de un ejecutable: importaciones, cadenas, símbolos y constantes criptográficas"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - Arquitectura y ABI - lo mínimo para leer desensamblado]]"
Nota siguiente: "[[03 - Reversing dinámico - debuggers y hooking]]"
Area: "[[Reversing de protocolos.base|Reversing de protocolos]]"
---
---

Un binario comercial puede tener decenas de miles de funciones. Inspeccionarlas en orden no es viable. <mark style="background: #ADCCFFA6;">Hay cuatro vías rápidas hacia el código que importa</mark>, y en la práctica se usan las cuatro a la vez.

## Vía 1: la tabla de importaciones

La más directa. Un ejecutable enlazado dinámicamente **declara** qué funciones externas usa.

```shell-session
$ nm -D --defined-only binario | head          # símbolos exportados (ELF)
$ objdump -T binario | grep -E 'send|recv|socket|connect|SSL_'
$ readelf -d binario | grep NEEDED             # librerías de las que depende
$ rabin2 -i binario                            # imports, con radare2/rizin
```

En Ghidra, la ventana `Symbol Tree → Imports`; en IDA, la pestaña `Imports`.

Qué buscar:

| Familia | Símbolos | Qué te dice |
| - | - | - |
| Sockets POSIX | `socket`, `connect`, `bind`, `listen`, `accept`, `send`, `recv`, `sendto`, `recvfrom` | Red cruda |
| Winsock | `WSAStartup`, `send`, `recv`, `WSASend`, `WSARecv`, `connect` (`ws2_32.dll`) | Red cruda en Windows |
| HTTP de alto nivel | `WinHttpSendRequest`, `InternetOpenUrl`, `curl_easy_perform` | HTTP, no protocolo propio |
| TLS | `SSL_read`, `SSL_write`, `SSL_CTX_new` (OpenSSL); `SChannel`/`Secur32` (Windows) | **Punto de enganche ideal** |
| Cripto | `EVP_EncryptInit`, `CryptEncrypt`, `BCryptEncrypt` | Cifrado del protocolo |
| Compresión | `deflate`, `inflate`, `BZ2_*`, `LZ4_*`, `ZSTD_*` | Explica la entropía del volcado |

> [!important]+ `SSL_read` y `SSL_write` son el premio gordo
> Si el binario usa OpenSSL (o `libssl`, `mbedTLS`, `wolfSSL`, `BoringSSL`) enlazado dinámicamente, **enganchar `SSL_read`/`SSL_write` te da el texto plano** sin descifrar nada, sin CA propia y sin proxy. Ni el *pinning* estorba, porque no te estás interponiendo. Es la razón por la que `sslsniff` de bcc y los *scripts* estándar de Frida funcionan contra tanta cosa.

Desde ahí, **referencias cruzadas**: seleccionar el import y pedir *xrefs* (`X` en IDA, `Ctrl+Shift+F` en Ghidra) lista todos los sitios que lo llaman. <mark style="background: #FF5582A6;">El que sea, está en la ruta del protocolo</mark>.

## Vía 2: cadenas

```shell-session
$ strings -n 8 binario | less
$ strings -el binario                 # UTF-16LE — imprescindible en Windows
$ rabin2 -zz binario                  # incluye cadenas en secciones no estándar
```

Lo que más rinde:

- **Mensajes de error y depuración**: `"Invalid packet length %d"`, `"protocol version mismatch"`. A menudo describen la estructura mejor que la documentación.
- **Rutas de fuente**: los compiladores dejan `/home/dev/proyecto/src/net/parser.c` incrustado en las cadenas de aserción. Te da la arquitectura del proyecto gratis.
- **Nombres de comandos** del protocolo si es textual.
- **Banners de librerías estáticas**: `inflate 1.2.13 Copyright 1995-2022 Mark Adler` te dice que zlib va dentro; `OpenSSL 3.0.x` idem. <mark style="background: #FFB86CA6;">Saber qué librerías lleva es también un inventario de CVEs conocidos</mark>.

En Ghidra, ventana `Defined Strings`; doble clic sobre una cadena y luego *xrefs* lleva a la función que la usa.

## Vía 3: símbolos de depuración

Si están, el trabajo cae en picado. Ver [[00 - Cuándo hay que abrir el binario]] para dónde vive cada tipo. Lo práctico:

```shell-session
$ file binario                    # "not stripped" = símbolos dentro
$ nm binario | wc -l              # si devuelve muchos, tienes suerte
```

Con Windows, configurar el servidor de símbolos de Microsoft en Ghidra o IDA es lo primero que hay que hacer: los nombres de todas las APIs del sistema aparecen resueltos.

## Vía 4: constantes mágicas de criptografía

Los algoritmos criptográficos llevan constantes fijas por diseño. Encontrarlas identifica el algoritmo aunque no haya un solo símbolo.

```c
// Inicialización de MD5 — reconocible de inmediato
ctx->state[0] = 0x67452301;
ctx->state[1] = 0xEFCDAB89;
ctx->state[2] = 0x98BADCFE;
ctx->state[3] = 0x10325476;
```

| Algoritmo | Firma |
| - | - |
| MD5 | `67452301 EFCDAB89 98BADCFE 10325476` |
| SHA-1 | Los cuatro de MD5 **+ `C3D2E1F0`** |
| SHA-256 | `6A09E667 BB67AE85 3C6EF372 A54FF53A` |
| AES | S-box de 256 bytes que empieza `63 7C 77 7B F2 6B 6F C5` |
| CRC32 | Tabla de 256 `uint32` que empieza `00000000 77073096 EE0E612C` |
| ChaCha20 | La cadena ASCII `expand 32-byte k` |

> [!warning]+ MD5 y SHA-1 comparten las cuatro primeras constantes
> Buscar `0x67452301` encuentra ambos. Distínguelos por la quinta (`0xC3D2E1F0` solo en SHA-1) y por el tamaño de salida. Es un error de identificación frecuente.

**El `PEiD` que usa el libro está muerto desde 2011.** Los sustitutos actuales:

```shell-session
$ die -a binario                  # Detect It Easy: packers, compiladores, cripto
$ capa -v binario                 # Mandiant: describe capacidades en lenguaje natural
$ yara -r reglas_cripto.yar bin   # con reglas públicas de detección de algoritmos
```

`capa` es el que más ha cambiado el juego: en vez de decirte «hay constantes de AES», te dice **«cifra datos con AES», «se comunica por TCP», «lee datos de un socket»** con las direcciones de las funciones. En Ghidra hay además `findcrypt` como script y en IDA el plugin homónimo.

## Y la vía cero: preguntarle al programa

A veces lo más rápido es no desensamblar nada:

```shell-session
$ ltrace -e 'send+recv+SSL_*' ./cliente     # llamadas a librería, no syscalls
$ sudo bpftrace -e 'uprobe:/usr/lib/libssl.so:SSL_write { printf("%s\n", str(arg1)); }'
```

Un `uprobe` de eBPF sobre `SSL_write` te vuelca el texto plano sin escribir una línea de análisis estático. Cuando funciona, ahorra días — y conecta con [[03 - Reversing dinámico - debuggers y hooking]].

## Flujo recomendado

1. `file` + `die` → formato, arquitectura, compilador, *packer*.
2. `capa` → capacidades y direcciones de las funciones relevantes.
3. Imports de red y cripto → *xrefs* → funciones candidatas.
4. Cadenas de error → confirmar y nombrar las funciones.
5. Constantes cripto → identificar el algoritmo.
6. Confirmar con *breakpoints* o Frida.

> [!info]+ Fuentes
> - [capa](https://github.com/mandiant/capa) (Mandiant) y su [reglario público](https://github.com/mandiant/capa-rules).
> - [Detect It Easy](https://github.com/horsicq/Detect-It-Easy) — sustituto vivo de PEiD (abandonado en 2011).
> - Constantes verificables en el fuente de referencia: [RFC 1321](https://datatracker.ietf.org/doc/html/rfc1321) (MD5), [RFC 3174](https://datatracker.ietf.org/doc/html/rfc3174) (SHA-1), [FIPS 197](https://csrc.nist.gov/pubs/fips/197/final) (AES).
> - Forshaw, *Attacking Network Protocols*, cap. 6 (el flujo original con IDA Pro Free y PEiD, aquí actualizado).
