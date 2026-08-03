---
tags:
  - Corrupcion-Memoria
  - Fuzzing
  - Pentesting/Explotacion
Descripción: "De controlar la dirección de retorno a ejecutar código: offset exacto, restricciones de bytes y por qué en 2026 el objetivo ya no es saltar a la pila"
Fecha de actualización: 2026-08-03
Nota previa: "[[03 - Sanitizers y heap de depuración]]"
Nota siguiente: "[[05 - Explotación de heap y VTables]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

Es el caso canónico: un búfer local se desborda y la escritura alcanza la **dirección de retorno** guardada en la pila. <mark style="background: #FFB86CA6;">Cuando la función ejecuta `ret`, salta a donde tú digas</mark>.

```text
 Direcciones altas
 ┌──────────────────────┐
 │ Dirección de retorno │ ← objetivo
 ├──────────────────────┤
 │ RBP guardado         │
 ├──────────────────────┤
 │ Canario de pila      │ ← si el compilador lo puso
 ├──────────────────────┤
 │ Variables locales    │
 │   char buf[64]       │ ← el desbordamiento empieza aquí y sube
 └──────────────────────┘
 Direcciones bajas
```

Si ese diagrama no te dice nada —qué es `RBP`, por qué `ret` usa la pila, por qué el búfer crece hacia arriba— la base está en [[01 - Arquitectura y ABI - lo mínimo para leer desensamblado]]. Sin eso, lo que viene no se sostiene.

## Paso 1: el offset exacto

Nunca a base de contar bytes a ojo. Se usa un **patrón cíclico de De Bruijn**, donde cada subcadena de 4 u 8 bytes aparece una sola vez:

```shell-session
$ python3 -c "from pwn import *; print(cyclic(2000).decode('latin1'))" > patron.txt
# ...enviar y provocar la caída...
(gdb) info registers rsp
rsp  0x7fffffffe3a8
(gdb) x/gx $rsp-8
0x7fffffffe3a0: 0x6161617461616173
$ python3 -c "from pwn import *; print(cyclic_find(0x6161617461616173, n=8))"
72
```

72 bytes hasta la dirección de retorno. Sin adivinar nada.

## Paso 2: qué bytes puedes usar

Esto decide la mitad del exploit, y se ignora constantemente:

| Cómo llega el desbordamiento | Bytes prohibidos |
| - | - |
| `strcpy` / `strcat` | `\x00` (corta la copia) |
| `sprintf("%s")` | `\x00` |
| Protocolo de texto por líneas | `\x00`, `\x0a`, `\x0d` |
| `scanf("%s")` | `\x00`, espacio, `\t`, `\n` |
| `memcpy` con longitud | **Ninguno** — el caso cómodo |
| Tras decodificar Base64 | Ninguno, pero hay que codificar la carga |

Con `strcpy`, cualquier dirección que contenga un byte nulo trunca el *payload*. Y en x86-64 las direcciones de usuario suelen ser tipo `0x00007fffffffe3a0` — **con dos bytes nulos arriba**. Es una de las razones por las que la explotación en 64 bits es más incómoda.

## Paso 3: a dónde saltar

Y aquí es donde el libro se ha quedado atrás. <mark style="background: #FF5582A6;">Su propuesta —meter el *shellcode* al final del desbordamiento y apuntar el retorno a la pila— **no funciona en ningún sistema moderno**</mark>:

| Mitigación | Qué rompe | Estado en 2026 |
| - | - | - |
| **DEP / NX** | Ejecutar código en la pila o el heap | Universal desde hace ~20 años |
| **Canarios** | Alcanzar el retorno sin ser detectado | Por defecto en GCC/Clang/MSVC |
| **ASLR / PIE** | Conocer direcciones de antemano | Por defecto en todos los SO |
| **RELRO completo** | Sobrescribir la GOT | Por defecto en las distros principales |
| **CET / shadow stack** | Que `ret` vaya a un sitio no legítimo | Desplegándose (ver abajo) |

Así que, en la práctica, la cadena es:

1. **Fuga de información** para derrotar ASLR — a menudo el propio desbordamiento sirve, corrompiendo una longitud para leer de más ([[03 - Indexación fuera de límites y expansión de datos]]).
2. **ROP** con gadgets del binario o de las librerías ya cargadas, porque no puedes inyectar código ([[08 - Mitigaciones modernas y cómo se saltan]]).
3. **Objetivo típico**: `mprotect()` para hacer ejecutable una región y saltar ahí, o directamente `system("/bin/sh")` / `execve`.

## El canario y cómo se esquiva

El compilador guarda un valor aleatorio entre las locales y el retorno, y lo comprueba antes de salir. Si no coincide, `__stack_chk_fail()` mata el proceso.

Las tres vías conocidas:

1. **Corromper algo antes de que se compruebe.** El canario solo se valida en el `ret`. Si en el marco hay un **puntero a función** o un puntero a objeto **por encima** del búfer y se usa antes de salir, tienes ejecución sin haber tocado el canario:

```c
int hacer_algo(const char *s) {
    int (*f)(const char*) = manejador_por_defecto;   // ← puntero en la pila
    char buffer[32];
    strcpy(buffer, s);                                // ← desborda
    return f(buffer);                                 // ← se usa ANTES del ret
}
```

Los compiladores modernos mitigan esto **reordenando** las variables para poner los arrays por encima de todo lo demás (`-fstack-protector-strong` lo hace), pero no siempre es posible.

2. **Filtrarlo.** Con una fuga de memoria que lea la pila, se conoce el valor y se reescribe idéntico. En procesos que bifurcan **sin `exec`**, el canario es el mismo en todos los hijos: se puede sacar byte a byte forzando caídas (*byte-by-byte brute force*), 256 intentos por byte.

3. **Desbordamiento hacia abajo (*underflow*).** Si el bug escribe en índices negativos (`p[-1]`), corrompe el marco de la función **llamante**, cuyo retorno puede no estar protegido — el compilador solo pone canario en funciones que manipulan búferes locales.

## Cuándo sigue siendo fácil

Toda la dificultad anterior asume un sistema moderno bien compilado. En el mundo real hay mucho que no lo es:

- **Firmware y dispositivos empotrados**: sin ASLR, sin DEP, sin canarios, binarios compilados hace ocho años con un toolchain antiguo. Aquí el *shellcode* en la pila **sigue funcionando tal cual**, con las restricciones de bytes de [[07 - Shellcode - de las syscalls al payload]] como única complicación real.
- **Sistemas industriales y médicos** que no se pueden actualizar.
- **Binarios propietarios** compilados sin las banderas de endurecimiento — que se comprueba en un segundo:

```shell-session
$ checksec --file=./servidor
RELRO   STACK CANARY  NX     PIE     RPATH  Symbols
Partial No canary     NX     No PIE  No     92 symbols
```

Ese `No canary` + `No PIE` es un hallazgo por sí mismo, aunque no llegues a explotarlo: <mark style="background: #8000E1A6;">significa que **cualquier** desbordamiento en ese binario es explotable con esfuerzo mínimo</mark>.

> [!warning]+ En un pentest, la PoC no es el exploit
> Salvo que el alcance pida demostrar impacto con ejecución, **una prueba de concepto que demuestre control del puntero de instrucción es suficiente** para reportar la vulnerabilidad como crítica. Desarrollar un exploit fiable, con evasión de todas las mitigaciones, es trabajo de días y no suele estar en el alcance. Documenta el control de `$pc` y las mitigaciones presentes o ausentes, y deja la valoración de explotabilidad argumentada.

> [!info]+ Fuentes
> - [pwntools](https://docs.pwntools.com/) — `cyclic`, `cyclic_find`, `ROP`, `ELF`.
> - [checksec](https://github.com/slimm609/checksec.sh) — inventario de mitigaciones de un binario.
> - [GCC — `-fstack-protector-strong` y reordenación de variables](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html).
> - Forshaw, *Attacking Network Protocols*, cap. 10 (el escenario original, previo a la generalización de las mitigaciones).
