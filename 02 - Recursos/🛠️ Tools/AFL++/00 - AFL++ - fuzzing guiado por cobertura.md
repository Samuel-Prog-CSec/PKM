---
tags:
  - Fuzzing
  - Corrupcion-Memoria
  - Tipo/Introduccion
Descripción: "El fuzzer de referencia: modos con y sin código fuente, cómo leer su panel de estado y los ajustes que multiplican los hallazgos"
Fecha de actualización: 2026-08-03
Nota previa: 
Nota siguiente: 
Area: "[[AFL++.base|AFL++]]"
---
---

`AFL++` es el sucesor mantenido de `american fuzzy lop`, y el fuzzer guiado por cobertura de referencia. Instrumenta el objetivo para saber **qué ramas ejecuta cada entrada**, conserva las que descubren código nuevo y las muta: convierte una búsqueda ciega en una búsqueda con retroalimentación.

Versión verificada: **v5.02c** (29 de junio de 2026).

## Los modos, según lo que tengas

| Tienes | Modo | Comando |
| - | - | - |
| Código fuente | Instrumentación en compilación | `CC=afl-clang-fast make` |
| Solo el binario | **QEMU** | `afl-fuzz -Q ...` |
| Solo el binario (a veces más rápido) | **Frida** | `afl-fuzz -O ...` |
| Binario, misma arquitectura | **Unicorn** | Para trozos de código aislados |
| Binario de otra arquitectura | QEMU con `AFL_QEMU_...` | Firmware ARM/MIPS |
| Núcleo o driver | **Nyx** | Virtualización completa |

La instrumentación en compilación es **10-100× más rápida** que QEMU. Si hay fuente, siempre esa.

```shell-session
# Con fuente, con sanitizers puestos
$ CC=afl-clang-fast CXX=afl-clang-fast++ AFL_USE_ASAN=1 AFL_USE_UBSAN=1 ./configure
$ make

# Fuzzear
$ afl-fuzz -i semillas/ -o salida/ -x protocolo.dict -- ./parser @@

# Sin fuente
$ afl-fuzz -Q -i semillas/ -o salida/ -- ./binario_cerrado @@
```

`@@` es el marcador que AFL++ sustituye por la ruta del caso de prueba. Si el objetivo lee de `stdin`, se omite.

## Preparar antes de lanzar

```shell-session
# 1) Reducir el corpus al mínimo con la misma cobertura
$ afl-cmin -i corpus_crudo/ -o semillas/ -- ./parser @@

# 2) Recortar cada semilla individualmente
$ for f in semillas/*; do afl-tmin -i "$f" -o "min/$(basename $f)" -- ./parser @@; done

# 3) Configurar el sistema (AFL++ se queja si no)
$ sudo afl-system-config
```

`afl-system-config` desactiva el `core_pattern` que envía las caídas a `systemd-coredump` —lo que las haría invisibles para AFL++— y ajusta el gobernador de CPU. **Sin esto, AFL++ se niega a arrancar** o pierde caídas.

## Paralelizar

```shell-session
$ afl-fuzz -M principal -i semillas/ -o salida/ -- ./parser @@   # maestro (determinista)
$ afl-fuzz -S sec1     -i semillas/ -o salida/ -- ./parser @@   # secundarios
$ afl-fuzz -S sec2     -i semillas/ -o salida/ -- ./parser @@
```

Comparten el directorio de salida y sincronizan hallazgos. Regla práctica: un maestro y **N-1 secundarios** para N núcleos. `afl-whatsup salida/` da el estado agregado.

## Leer el panel

Los cuatro números que importan:

| Campo | Qué mirar |
| - | - |
| **`corpus count`** / `total paths` | Si no sube en horas, el fuzzer está atascado: faltan semillas o diccionario |
| **`exec speed`** | Por debajo de 100/s hay un problema: E/S, arranque de proceso lento, o QEMU |
| **`saved crashes`** | Caídas únicas por firma de cobertura (**no** por bug: hay que deduplicar) |
| **`last new find`** | Si lleva horas sin novedad, replantea el corpus o cambia de estrategia |
| **`map density`** | Por encima del 10-20 % el mapa satura: reduce el corpus con `afl-cmin` |

## Ajustes que multiplican los hallazgos

```shell-session
export AFL_USE_ASAN=1          # detecta corrupción silenciosa, no solo caídas
export AFL_USE_UBSAN=1         # errores de enteros
export AFL_AUTORESUME=1        # reanudar sin borrar la salida
export AFL_IMPORT_FIRST=1      # importar hallazgos de otros nodos al arrancar
export AFL_TESTCACHE_SIZE=500  # cachear casos en RAM (MB): mucho más rápido
export AFL_MAP_SIZE=256000     # binarios grandes con muchas ramas
```

Y los dos que más rinden:

1. **El diccionario (`-x`).** Un fuzzer aleatorio no inventará nunca el número mágico de tu protocolo ni el valor `0x40000001` que desborda una multiplicación. Con el diccionario, sí ([[01 - Construir el corpus y el harness]]).
2. **El modo persistente.** Con un arnés `LLVMFuzzerTestOneInput`, AFL++ ejecuta miles de casos **en el mismo proceso**, sin `fork`. Pasa de cientos a decenas de miles de ejecuciones por segundo.

## Fuzzear un servicio de red

AFL++ está pensado para ficheros. Para un servicio hay tres vías, de mejor a peor:

| Vía | Cómo |
| - | - |
| **Aislar el parser** | Arnés que llama directo a la función de parseo. **Lo ideal** |
| **`libdesock`** | `AFL_PRELOAD=libdesock.so` convierte el socket en `stdin` |
| **AFLNet / StateAFL** | Forks conscientes de la máquina de estados |

```shell-session
$ AFL_PRELOAD=/usr/lib/libdesock.so afl-fuzz -i semillas/ -o out/ -- ./servidor
```

Detalle del planteamiento en [[00 - Fuzzing de protocolos de red]].

## Después: minimizar y triar

```shell-session
$ afl-tmin -i salida/principal/crashes/id_000003 -o min3 -- ./parser @@
$ ASAN_OPTIONS=symbolize=1 ./parser min3            # fichero y línea del fallo
```

Un directorio con 4.000 caídas sin minimizar ni triar no es un hallazgo ([[02 - Triage de crashes con depurador]]).

> [!info]+ Fuentes
> - [AFL++ — documentación](https://aflplus.plus/docs/) y [variables de entorno](https://aflplus.plus/docs/env_variables/).
> - Versión verificada el 2026-08-03 contra `api.github.com/repos/AFLplusplus/AFLplusplus/releases/latest`.
> - Trail of Bits *Testing Handbook*, capítulo de AFL++ — disponible como skill del proyecto.
