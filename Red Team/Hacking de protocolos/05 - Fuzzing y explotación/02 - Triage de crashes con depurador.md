---
tags:
  - Fuzzing
  - Corrupcion-Memoria
  - Pentesting/Explotacion
Descripción: "De un directorio con 4.000 caídas a un hallazgo: comandos de gdb, lldb y cdb, cómo leer un crash y cómo estimar explotabilidad"
Fecha de actualización: 2026-08-03
Nota previa: "[[01 - Construir el corpus y el harness]]"
Nota siguiente: "[[03 - Sanitizers y heap de depuración]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

El fuzzer ha dejado 4.000 ficheros en `crashes/`. Eso no es un hallazgo: probablemente son **tres bugs** repetidos mil veces cada uno. El triaje convierte ese montón en algo reportable: identificar los bugs distintos, encontrar la causa raíz de cada uno y estimar si son explotables.

## Deduplicar primero

Antes de abrir un depurador, reduce el volumen:

```shell-session
# ASan ya agrupa por pila: quedarse con una caída por firma
$ for f in crashes/id*; do ./objetivo "$f" 2>&1 | grep -m1 '#1 0x' ; done \
  | sort -u | wc -l

# Minimizar cada caso superviviente
$ afl-tmin -i crashes/id_000012 -o min_012 -- ./objetivo @@
```

De 4.000 ficheros se suele bajar a un puñado de firmas distintas. **Minimizar es imprescindible**: un caso de 4 KB no dice nada; el mismo reducido a 12 bytes te enseña el bug directamente.

## Arrancar el depurador

| | Proceso nuevo | Adjuntar a uno existente |
| - | - | - |
| **gdb** (Linux) | `gdb --args ./app args` | `gdb -p PID` |
| **lldb** (macOS) | `lldb -- ./app args` | `lldb -p PID` |
| **cdb/WinDbg** (Windows) | `cdb app.exe args` | `cdb -p PID` |

Y ejecutar: `run`/`r` en gdb y lldb, `g` en cdb.

> [!warning]+ Servidores que bifurcan: el crash está en el hijo
> Un servidor con modelo `fork()` por conexión **no se cae en el proceso que estás depurando**. Hay que seguir al hijo:
>
> ```shell-session
> (gdb) set follow-fork-mode child
> (gdb) set detach-on-fork off          # sigue depurando ambos
> ```
>
> En `cdb`: `.childdbg 1`. En `lldb` **no hay opción de seguir hijos**: hay que lanzar otra instancia con `process attach --name NOMBRE --waitfor`.
>
> Si se te olvida, verás el servidor «funcionando bien» mientras el fuzzer reporta caídas, y perderás una tarde.

## Los seis comandos que necesitas

| Qué | gdb | lldb | cdb |
| - | - | - | - |
| Registros | `info registers` | `register read` | `r` |
| Desensamblar aquí | `x/10i $pc` | `disassemble --frame` | `u` |
| Pila de llamadas | `bt full` | `bt` | `kb` |
| Ver memoria | `x/16xg $sp` | `memory read --size 8 --count 16 $sp` | `dq @rsp L10` |
| Mapa de memoria | `info proc mappings` | `image list` | `!address` |
| Escribir registro | `set $rax = 0x41` | `register write rax 0x41` | `r @rax = 41` |

En gdb y lldb hay dos pseudoregistros muy cómodos: **`$pc`** (instrucción actual, `RIP` en x86-64) y **`$sp`** (pila). Para saber qué registro mirar en cada llamada —dónde está el búfer en un `recv`, dónde el tamaño en un `memcpy`— la tabla de convenciones de llamada está en [[01 - Arquitectura y ABI - lo mínimo para leer desensamblado]]; y ojo, **no es la misma en Linux que en Windows**.

## Leer una caída

### Caso 1: desbordamiento de pila

```text
Program received signal SIGSEGV, Segmentation fault.
0x4141414141414141 in ?? ()                     ← ①
(gdb) x/i $pc
=> 0x4141414141414141:  Cannot access memory at address 0x4141414141414141
(gdb) x/4xg $sp-32                              ← ②
0x7fffffffe420: 0x4141414141414141  0x4141414141414141
0x7fffffffe430: 0x4141414141414141  0x4141414141414141
(gdb) bt
#0  0x4141414141414141 in ?? ()                 ← ③
#1  0x4141414141414141 in ?? ()
Backtrace stopped: previous frame inner to this frame (corrupt stack)
```

**①** El puntero de instrucción es `0x41` repetido: son tus `A`. El programa saltó a una dirección construida con datos del atacante — <mark style="background: #FF5582A6;">control directo del flujo de ejecución</mark>.
**②** La pila alrededor también está llena del patrón: confirma corrupción de pila y no otra cosa.
**③** Y aquí está el precio: `bt` no reconstruye nada y gdb lo dice explícitamente (*corrupt stack*).

**Problema**: al corromper la pila has destruido la información de quién llamaba, así que la pila de llamadas es inútil justo cuando más falta hace. Para encontrar la función culpable, busca **por debajo** de la zona corrupta alguna dirección de retorno que sobreviva, o repite con un patrón cíclico (`cyclic 2000` de pwntools / `msf-pattern_create`) para saber **el desplazamiento exacto** al retorno.

### Caso 2: corrupción de heap

```text
Program received signal SIGSEGV, Segmentation fault.
0x000055555555562b in procesar ()
(gdb) x/i $pc
=> 0x55555555562b <procesar+112>:  mov    (%rax),%rax          ← ①
(gdb) info registers rax
rax            0x4141414141414141   4702111234474983745        ← ②
(gdb) x/4i $pc
=> 0x55555555562b <procesar+112>:  mov    (%rax),%rax
   0x55555555562e <procesar+115>:  mov    -0x10(%rbp),%rdi
   0x555555555632 <procesar+119>:  call   *%rax                ← ③
   0x555555555634 <procesar+121>:  add    $0x10,%rsp
(gdb) bt
#0  0x000055555555562b in procesar ()                          ← ④
#1  0x00005555555556f2 in manejar_mensaje ()
#2  0x0000555555555810 in main ()
(gdb) info proc mappings
      Start Addr           End Addr       Size  objfile
  0x555555559000     0x55555557a000    0x21000  [heap]         ← ⑤
```

**①** Falla al desreferenciar `RAX`. **②** `RAX` contiene tu patrón de relleno. **③** Dos instrucciones más allá hay un `call *%rax`: la secuencia `mov (%rax),%rax` + `call *%rax` es la firma inconfundible de una **llamada a función virtual** — se lee el puntero a la VTable del objeto y se salta por él. **④** A diferencia del caso 1, **la pila está intacta** y `bt` te da el camino completo hasta el parser. **⑤** La dirección corrupta cae dentro de `[heap]`.

Diagnóstico: desbordamiento de heap que ha machacado el puntero a la VTable de un objeto C++ ([[05 - Explotación de heap y VTables]]). Y como la pila sobrevive, `bt` señala directamente la función que hay que revisar: `manejar_mensaje`.

<mark style="background: #FFB8EBA6;">Esa es la diferencia práctica entre pila y heap en el triaje</mark>: la corrupción de pila te da control inmediato pero destruye el contexto; la de heap conserva el contexto pero exige más trabajo para llegar a ejecutar.

## Estimar explotabilidad

Sin un análisis completo, para priorizar:

| Señal | Lectura |
| - | - |
| `$pc` contiene datos controlados | **Control directo del flujo → probablemente RCE** |
| Escritura en dirección controlada | **Escritura arbitraria → normalmente explotable** |
| `call`/`jmp` sobre registro controlado | Alta probabilidad |
| Lectura de dirección controlada | Fuga de información; con suerte, derrota ASLR |
| Escritura cerca del búfer, sin control de dirección | Media: depende de qué haya al lado |
| Desreferencia de `NULL` (`0x0`) | Normalmente **solo DoS** en sistemas modernos |
| División por cero, aserción, `abort()` | DoS |
| Agotamiento de pila por recursión | DoS |

Las herramientas de clasificación automática (`!exploitable` de Microsoft, `exploitable` de CERT para gdb, `crashwalk`) dan una etiqueta orientativa. **Sirven para priorizar, no para concluir**: se equivocan en ambos sentidos, y un «probably not exploitable» sobre un UAF ha resultado ser RCE más de una vez.

## Cuando el crash está lejos del bug

Es lo normal en heap y UAF ([[04 - Use-after-free, double-free y confusión de tipos]]): la corrupción ocurre mucho antes de la caída. La respuesta no es el depurador, son los **sanitizers**, que abortan en el instante exacto y con la pila del `free` original ([[03 - Sanitizers y heap de depuración]]).

Si no puedes recompilar, hay dos apaños que ayudan mucho:

```shell-session
$ MALLOC_PERTURB_=42 ./servidor      # glibc rellena la memoria liberada con 0xdb...
$ MALLOC_CHECK_=3 ./servidor         # comprobaciones de consistencia del heap
```

Con `MALLOC_PERTURB_`, un UAF que antes pasaba desapercibido se convierte en una caída ruidosa sobre `0xdbdbdbdb`, que además es un patrón inconfundible en el volcado.

## Lo que va al informe

Un hallazgo triado necesita: **el caso mínimo** que lo reproduce, la **función y línea** (o dirección) donde ocurre, la **causa raíz** en términos del catálogo ([[00 - Clases de vulnerabilidad en un servicio de red]]), el **CWE**, y una **valoración de impacto** justificada. Un fichero de 4 KB y «se cae» no es reportable.

> [!info]+ Fuentes
> - [GDB Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/) y [LLDB Tutorial](https://lldb.llvm.org/use/tutorial.html).
> - [Debugging Tools for Windows — CDB/WinDbg](https://learn.microsoft.com/en-us/windows-hardware/drivers/debugger/).
> - [glibc — Memory Allocation Tunables](https://www.gnu.org/software/libc/manual/html_node/Memory-Allocation-Tunables.html) para `MALLOC_PERTURB_` y `MALLOC_CHECK_`.
> - [pwndbg](https://github.com/pwndbg/pwndbg) — `cyclic`, `heap`, `vis_heap_chunks` aceleran mucho este trabajo.
