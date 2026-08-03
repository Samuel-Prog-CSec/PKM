---
tags:
  - Fuzzing
  - Corrupcion-Memoria
  - Tipo/Arsenal
Descripción: "Fuzzers, sanitizers, depuradores y utilidades de explotación con versiones verificadas a 2026, y el mapa de lo que ha sustituido a Sulley, PEiD e IDA Free 5"
Fecha de actualización: 2026-08-03
Nota previa: "[[08 - Mitigaciones modernas y cómo se saltan]]"
Nota siguiente: 
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

Estado verificado el **2026-08-03**. <mark style="background: #FFB8EBA6;">El apéndice del libro cita `Sulley`, `PEiD` e `IDA Pro Free 5`; los tres han sido sustituidos</mark>.

## Fuzzers

| Herramienta | Estado | Cuándo usarlo |
| - | - | - |
| **AFL++** | **v5.02c** (2026-06-29) | Guiado por cobertura. Con fuente (`afl-clang-fast`), sin fuente (`-Q` QEMU, `-O` Frida) |
| **libFuzzer** | Parte de LLVM | Arnés en proceso, el más rápido. Ideal si aíslas la función de parseo |
| **AFLNet** | Activo | AFL++ con conciencia de la máquina de estados del protocolo |
| **StateAFL** | Activo | Infiere el estado de la memoria; no necesita códigos de respuesta |
| **boofuzz** | `master` activo (jun-2026), release v0.4.2 (2023) | Gramática y secuencia en Python. **Sucesor de Sulley** |
| **Honggfuzz** | Activo | Alternativa a AFL++, buena con multihilo |
| **libdesock** | Activo | `LD_PRELOAD` que convierte sockets en `stdin` → fuzzing a velocidad de fichero |
| ~~**Sulley**~~ | Abandonado | El del libro → `boofuzz` |
| ~~**Peach**~~ | Comercial, discontinuado | → `boofuzz` o generación propia |

## Sanitizers y detección

| Herramienta | Uso |
| - | - |
| **ASan** (`-fsanitize=address`) | Límites, UAF, doble free. **El imprescindible** |
| **UBSan** (`-fsanitize=undefined,integer`) | Errores de enteros y comportamiento indefinido. Barato |
| **MSan** (`-fsanitize=memory`) | Lectura de memoria sin inicializar |
| **TSan** (`-fsanitize=thread`) | Condiciones de carrera |
| **Valgrind / Memcheck** | Sin recompilar, pero 10-50× más lento |
| **Page Heap + gflags** | Windows, sin fuente: página de guarda por reserva |
| **Application Verifier** | Windows: handles, secciones críticas, APIs mal usadas |
| **`MALLOC_PERTURB_` / `MALLOC_CHECK_`** | glibc, coste cero, convierte UAF silenciosos en caídas |

## Depuración y triaje

| Herramienta | Plataforma |
| - | - |
| **GDB + pwndbg** o **GEF** | Linux. Los plugins son lo que lo hace usable (`cyclic`, `heap`, `checksec`) |
| **LLDB** | macOS |
| **WinDbg / CDB** | Windows, incluido modo kernel |
| **x64dbg** | Windows, libre, con `ScyllaHide` contra anti-debug |
| **crashwalk / afl-collect** | Deduplicación y clasificación de caídas en lote |
| **`afl-tmin` / `afl-cmin`** | Minimizar casos y reducir corpus |

## Análisis estático de binarios

| Herramienta | Estado | Nota |
| - | - | - |
| **Ghidra** | **12.1.2** (2026-06-05) | Libre, decompilador para todas las arquitecturas, <mark style="background: #FFB86CA6;">**uso comercial permitido**</mark>. La opción por defecto |
| **IDA Pro** | 9.3sp2 (2026-04) | El estándar comercial |
| **IDA Free** | Actual | Solo x86/x64, decompilador **en la nube**, **sin uso comercial** |
| **Binary Ninja** | Activo | Comercial, buena API |
| **rizin + Cutter** | Activo | Fork mantenido de radare2 |
| **capa** | Activo (Mandiant) | Identifica capacidades: «cifra con AES», «abre un socket» |
| **Detect It Easy** | Activo | Formato, compilador, *packer*, cripto. **Sustituye a PEiD** (muerto en 2011) |
| ~~**PEiD**~~ | Muerto (2011) | El del libro → `die` + `capa` |
| ~~**IDA Pro Free 5**~~ | Obsoleto | El del libro → **Ghidra** |

## Explotación

| Herramienta | Uso |
| - | - |
| **pwntools** | La librería. `cyclic`, `ROP`, `ELF`, `shellcraft`, `remote` |
| **ROPgadget** / **ropper** | Buscar gadgets |
| **one_gadget** | Direcciones de libc que dan shell con una sola llamada |
| **checksec** | Inventario de mitigaciones de un binario |
| **msfvenom** | Generar shellcode con bytes prohibidos (`-b`) |
| **how2heap** | Catálogo de técnicas de heap por versión de glibc |
| **Frida** | 17.16.4. Instrumentación en runtime, también para explotar |

## El flujo completo

```shell-session
# 1) Corpus a partir del tráfico real
$ tshark -r cap.pcap -T fields -e data -Y 'tcp.dstport==12345' | ... > corpus/

# 2) Compilar el objetivo instrumentado
$ CC=afl-clang-fast AFL_USE_ASAN=1 AFL_USE_UBSAN=1 make

# 3) Reducir el corpus al mínimo con la misma cobertura
$ afl-cmin -i corpus/ -o semillas/ -- ./parser @@

# 4) Fuzzear, con diccionario de valores frontera, varios núcleos
$ afl-fuzz -M main -x protocolo.dict -i semillas/ -o salida/ -- ./parser @@
$ afl-fuzz -S sec1 -x protocolo.dict -i semillas/ -o salida/ -- ./parser @@

# 5) Minimizar cada caída
$ afl-tmin -i salida/main/crashes/id_000000 -o min0 -- ./parser @@

# 6) Triar
$ ASAN_OPTIONS=symbolize=1 ./parser min0          # ASan da fichero y línea
$ gdb --args ./parser_sin_sanitizer min0          # comportamiento real

# 7) Valorar mitigaciones para estimar explotabilidad
$ checksec --file=./parser
```

## Lo que sí sigue vigente del apéndice del libro

`AFL` (hoy AFL++), `Kali Linux`, `Metasploit`, `Scapy` y los depuradores del sistema siguen siendo exactamente lo que eran. <mark style="background: #8000E1A6;">Lo que ha cambiado es **el ecosistema alrededor**</mark>: los sanitizers (que en 2018 existían pero no eran práctica estándar en pentest), Frida, Ghidra libre y el *fuzzing* con conciencia de estado.

Las herramientas de análisis de protocolo van en [[09 - Arsenal de análisis de protocolos]] y las de MITM en [[06 - Arsenal de MITM de red]].

> [!info]+ Fuentes
> - Versiones verificadas el 2026-08-03 contra `api.github.com/repos/{AFLplusplus/AFLplusplus,NationalSecurityAgency/ghidra,frida/frida,jtpereyda/boofuzz}` y las páginas oficiales de Hex-Rays.
> - [AFL++ docs](https://aflplus.plus/docs/) · [pwntools](https://docs.pwntools.com/) · [Trail of Bits Testing Handbook](https://appsec.guide/) (disponible como skill del proyecto).
> - Forshaw, *Attacking Network Protocols*, apéndice — base de la comparación.
