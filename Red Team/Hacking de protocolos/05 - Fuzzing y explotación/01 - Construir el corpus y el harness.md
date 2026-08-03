---
tags:
  - Fuzzing
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Lo que decide si un fuzzer encuentra algo: semillas del tráfico real, diccionario de valores frontera, harness persistente y reparación del framing"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Fuzzing de protocolos de red]]"
Nota siguiente: "[[02 - Triage de crashes con depurador]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

Un fuzzer bien montado con un corpus mediocre encuentra menos que un fuzzer sencillo con un corpus bueno. <mark style="background: #ADCCFFA6;">La calidad de las semillas y del arnés determina el resultado mucho más que la elección de herramienta</mark>.

## El corpus semilla

Debe **cubrir el máximo de código con el mínimo de ficheros**. Reglas:

1. **Salen del tráfico real.** Ejercita todas las funciones del cliente y captura ([[01 - Captura pasiva y sus límites]]). Cada comando del protocolo debe tener al menos una semilla.
2. **Un mensaje por fichero**, no la sesión entera. Así el fuzzer muta unidades con sentido.
3. **Pequeños.** El tiempo de ejecución crece con el tamaño de la entrada. AFL++ prefiere semillas de menos de 1 KB; si tienes una de 10 MB, recórtala.
4. **Sin duplicados por cobertura.** `afl-cmin` reduce el corpus al conjunto mínimo que preserva la cobertura, y `afl-tmin` recorta cada fichero individualmente.

```shell-session
$ afl-cmin -i crudo/ -o corpus/ -- ./parser @@       # elimina redundantes
$ afl-tmin -i corpus/x -o min/x -- ./parser @@       # recorta uno
```

Extraer las semillas de la captura:

```shell-session
$ mkdir -p corpus && n=0
$ tshark -r captura.pcap -T fields -e data -Y 'tcp.dstport==12345' \
  | grep -v '^$' \
  | while read -r hex; do
      n=$((n+1)); printf '%s' "$hex" | xxd -p -r > "corpus/msg_$(printf '%03d' $n).bin"
    done
$ ls -l corpus/ | head -4
-rw-r--r-- 1 user user  27 msg_001.bin
-rw-r--r-- 1 user user  30 msg_002.bin
-rw-r--r-- 1 user user  40 msg_003.bin
```

El `grep -v '^$'` no es opcional: `tshark` emite una línea vacía por cada paquete sin carga útil (los ACK puros), y sin filtrarlas acabas con decenas de ficheros de 0 bytes que solo sirven para ensuciar el corpus.

## El diccionario

Un fuzzer aleatorio **nunca** va a inventar el número mágico `BINX` ni un token de cuatro caracteres. El diccionario le da esas cadenas para que las inserte:

```text
# protocolo.dict
magic="BINX"
cmd_hello="\x00"
cmd_msg="\x03"
len_zero="\x00\x00\x00\x00"
len_max="\xff\xff\xff\xff"
len_intmax="\x7f\xff\xff\xff"
len_negative="\x80\x00\x00\x00"
len_overflow4="\x40\x00\x00\x01"
```

```shell-session
$ afl-fuzz -x protocolo.dict -i corpus/ -o out/ -- ./parser @@
```

Los valores frontera de [[02 - Errores de enteros - overflow, truncamiento y signo]] deben estar **todos** en el diccionario: son los que disparan los desbordamientos, y la probabilidad de que un mutador aleatorio genere `0x40000001` en la posición correcta es despreciable.

## El arnés

El arnés es el programa que recibe la entrada del fuzzer y la mete en el parser. Cuanto más cerca del código objetivo, mejor.

### Nivel 1 — Persistente con libFuzzer (lo ideal)

La versión ingenua, que sirve si el parser no valida integridad:

```c
#include <stdint.h>
#include <stddef.h>
extern int parsear_mensaje(const uint8_t *datos, size_t len);

int LLVMFuzzerTestOneInput(const uint8_t *datos, size_t len) {
    parsear_mensaje(datos, len);
    return 0;                    // SIEMPRE 0: libFuzzer ignora el valor de retorno
}
```

Pero si el protocolo lleva longitud y checksum, ese arnés **no llega al parser**: cada caso muere en la comprobación de integridad. La versión que sí funciona **construye el marco alrededor de la entrada del fuzzer**:

```c
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

extern int parsear_mensaje(const uint8_t *datos, size_t len);

// El fuzzer solo controla el CUERPO; el marco lo generamos nosotros y siempre válido.
int LLVMFuzzerTestOneInput(const uint8_t *cuerpo, size_t n) {
    if (n < 1 || n > 0x10000) return 0;   // cota propia, para no reservar de más

    uint8_t *msg = malloc(8 + n);
    if (!msg) return 0;

    uint32_t chk = 0;
    for (size_t i = 0; i < n; i++) chk += cuerpo[i];

    msg[0] = (n >> 24) & 0xFF; msg[1] = (n >> 16) & 0xFF;   // longitud, big endian
    msg[2] = (n >>  8) & 0xFF; msg[3] =  n        & 0xFF;
    msg[4] = (chk >> 24) & 0xFF; msg[5] = (chk >> 16) & 0xFF; // checksum recalculado
    msg[6] = (chk >>  8) & 0xFF; msg[7] =  chk        & 0xFF;
    memcpy(msg + 8, cuerpo, n);

    parsear_mensaje(msg, 8 + n);
    free(msg);                            // imprescindible con ASan: si no, se acumula
    return 0;
}
```

<mark style="background: #FF5582A6;">Esa diferencia es la que decide si el fuzzing encuentra algo o no</mark>. Con el primer arnés estarías midiendo la robustez del validador de checksum; con el segundo, la del parser de verdad.

```shell-session
$ clang -g -O1 -fsanitize=fuzzer,address,undefined arnes.c parser.c -o fuzz
$ ./fuzz corpus/ -dict=protocolo.dict -max_len=4096 -jobs=8
...
#4096  NEW    cov: 312 ft: 508 corp: 41/2431b exec/s: 21430 rss: 42Mb
#8192  NEW    cov: 340 ft: 561 corp: 47/3102b exec/s: 20981 rss: 43Mb
```

Las tres cifras que hay que mirar en esa salida: **`cov`** (aristas cubiertas — si no sube, no estás llegando a código nuevo), **`corp`** (casos guardados) y **`exec/s`** (velocidad; por debajo de 1.000 con un arnés en proceso, algo va mal).

> [!warning]+ Cuatro errores que arruinan un arnés
> 1. **Estado global entre ejecuciones.** El modo persistente no reinicia el proceso: si el parser deja estado, un caso contamina el siguiente y las caídas no reproducen. Reinicia explícitamente en cada llamada.
> 2. **No liberar memoria.** Con ASan, cada fuga se acumula hasta agotar la RAM — de ahí el `free(msg)` del ejemplo.
> 3. **Filtrar por estructura.** Acotar el tamaño para no reservar gigabytes (`n > 0x10000`) está bien; un `if (datos[0] != 0x03) return 0;` **no**, porque reduce el espacio explorable a una fracción. La regla: guárdate de tus propios desbordamientos, no del contenido del fuzzer.
> 4. **Fuzzear el validador en vez del parser.** Es el error de arriba, y el más caro: puedes estar días con el fuzzer al máximo sin que un solo caso pase de la primera comprobación.

### Nivel 2 — Servidor desocketizado

Sin fuente pero con binario, `libdesock` convierte los sockets en `stdin`:

```shell-session
$ AFL_PRELOAD=/usr/lib/libdesock.so afl-fuzz -i corpus/ -o out/ -- ./servidor
```

El servidor lee el caso de prueba como si viniera de una conexión. Velocidad de fuzzing de fichero contra un binario de red.

### Nivel 3 — Por la red, con estado

Cuando no queda otra. `boofuzz` define la gramática y la secuencia:

```python
from boofuzz import *

s_initialize("mensaje")
s_static(b"BINX")
s_size("cuerpo", length=4, endian=">", fuzzable=True)   # también fuzzea la longitud
s_checksum("cuerpo", algorithm="crc32", length=4, endian=">")
if s_block_start("cuerpo"):
    s_byte(0x03, name="comando", fuzzable=True)
    s_size("usuario", length=1, fuzzable=False)
    if s_block_start("usuario"):
        s_string("alice")
    s_block_end()
    s_string("hola mundo")
s_block_end()

sesion = Session(target=Target(connection=TCPSocketConnection("10.10.10.5", 12345)))
sesion.connect(s_get("mensaje"))
sesion.fuzz()
```

`s_size` y `s_checksum` **recalculan solos** — es lo que resuelve el problema del *framing*.

## Reparar el framing en un mutador propio

Si escribes el fuzzer tú, la pieza imprescindible:

```python
import struct, random

def mutar(cuerpo: bytes) -> bytes:
    b = bytearray(cuerpo)
    for _ in range(random.randint(1, 3)):
        pos = random.randrange(len(b))
        op = random.random()
        if op < 0.5:   b[pos] ^= 1 << random.randrange(8)         # bit flip
        elif op < 0.8: b[pos] = random.choice([0, 1, 0x7f, 0x80, 0xff])
        else:          b[pos:pos+4] = random.choice(FRONTERAS)     # entero frontera
    return bytes(b)

def envolver(cuerpo: bytes) -> bytes:
    """Recalcula longitud y checksum: SIN esto el fuzzer no pasa del validador."""
    return struct.pack("!II", len(cuerpo), sum(cuerpo) & 0xFFFFFFFF) + cuerpo

FRONTERAS = [struct.pack("!I", v) for v in
             (0, 1, 0x7F, 0x80, 0xFF, 0x7FFF, 0x8000, 0xFFFF,
              0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0x40000001)]
```

## Medir si está funcionando

| Señal | Qué significa |
| - | - |
| **Cobertura estancada** | Las semillas no llegan a código nuevo → faltan comandos en el corpus o el diccionario |
| **Muchas ejecuciones, ninguna ruta nueva** | Probablemente estás fuzzeando el validador |
| **`exec/s` bajo (<100)** | El arnés es lento: quita la red, usa modo persistente |
| **Caídas idénticas repetidas** | Falta deduplicar; usa el *stack hash* de ASan |
| **Mapa de cobertura saturado** | Corpus demasiado grande; pasa `afl-cmin` |

`afl-fuzz` muestra todo esto en su panel; con libFuzzer se saca con `-print_final_stats=1` y `llvm-cov` sobre el corpus.

> [!info]+ Fuentes
> - [libFuzzer — documentación de LLVM](https://llvm.org/docs/LibFuzzer.html) y la [guía de escritura de arneses de Google](https://github.com/google/fuzzing/blob/master/docs/good-fuzz-target.md).
> - [AFL++ — docs de `afl-cmin`, `afl-tmin` y diccionarios](https://aflplus.plus/docs/).
> - [boofuzz — documentación](https://boofuzz.readthedocs.io/) (`s_size`, `s_checksum`).
> - Trail of Bits *Testing Handbook* — capítulos de escritura de arneses y diccionarios.
