---
tags:
  - Reversing
  - Corrupcion-Memoria
  - Pentesting/Enumeracion
Descripción: "Registros, instrucciones y convenciones de llamada de x86-64 y ARM64: lo justo para seguir el flujo de datos de un paquete dentro de un binario"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Cuándo hay que abrir el binario]]"
Nota siguiente: "[[02 - Localizar el código de red en un binario]]"
Area: "[[Reversing de protocolos.base|Reversing de protocolos]]"
---
---

No hace falta dominar el ensamblador para analizar un protocolo. Hace falta lo justo para <mark style="background: #ADCCFFA6;">seguir un búfer desde `recv()` hasta donde se parsea</mark>, y para entender la pila cuando llegue el momento de explotar la corrupción. Esta nota es ese mínimo.

> [!important]+ El libro solo cubre x86 de 32 bits
> *Attacking Network Protocols* explica `EAX`, `ESP` y la convención `cdecl` de apilar argumentos. Eso es **legado**: hoy el objetivo por defecto es **x86-64**, donde los argumentos van en registros, y **ARM64** domina móvil, Apple Silicon y una parte creciente del servidor (AWS Graviton, Ampere). Las dos ABI modernas están abajo.

## Registros de x86-64

| Registro | Uso habitual | ¿Lo preserva la función llamada? |
| - | - | - |
| `RAX` | **Valor de retorno** | No |
| `RDI`, `RSI`, `RDX`, `RCX`, `R8`, `R9` | Argumentos 1-6 (System V) | No |
| `RCX`, `RDX`, `R8`, `R9` | Argumentos 1-4 (Microsoft x64) | No |
| `RBX`, `RBP`, `R12`-`R15` | Uso general | **Sí** |
| `RSP` | Puntero de pila | Sí |
| `RIP` | Instrucción actual (no se escribe directamente) | — |
| `RFLAGS` | Banderas de resultado (Zero, Sign, Carry, Overflow) | — |

Cada registro de 64 bits tiene sus vistas menores: `RAX` (64) → `EAX` (32) → `AX` (16) → `AL`/`AH` (8). Ver `mov eax, ...` en código de 64 bits es normal: escribir en la mitad baja **pone a cero la mitad alta**, y la instrucción es más corta.

## Las dos ABI que te vas a encontrar

| | **System V AMD64** (Linux, macOS, BSD) | **Microsoft x64** (Windows) |
| - | - | - |
| Argumentos enteros | `RDI, RSI, RDX, RCX, R8, R9` | `RCX, RDX, R8, R9` |
| Argumentos flotantes | `XMM0`-`XMM7` | `XMM0`-`XMM3` |
| Resto | Pila (derecha a izquierda) | Pila |
| Retorno | `RAX` (`RAX:RDX` si 128 bits) | `RAX` |
| Espacio reservado | *Red zone* de 128 bytes bajo `RSP` | ***Shadow space*** de 32 bytes que reserva el llamante |
| Limpieza de pila | El llamante | El llamante |

Confundirlas es la fuente número uno de análisis erróneos. En un `recv(sock, buf, len, flags)` de Linux, `buf` está en `RSI`; en Windows, en `RDX`. <mark style="background: #FF5582A6;">Ese registro es el que hay que seguir</mark>: es el búfer donde acaban los datos que tú controlas.

## Instrucciones que importan

| Instrucción | Qué hace |
| - | - |
| `MOV dst, src` | Copia |
| `LEA dst, [expr]` | Calcula una dirección **sin acceder a memoria** — muy usada para aritmética |
| `ADD` / `SUB` / `IMUL` | Aritmética (actualizan banderas) |
| `CMP a, b` | Resta y descarta el resultado, solo para fijar banderas |
| `TEST a, b` | AND y descarta; `test eax, eax` es el idioma de «¿es cero?» |
| `Jcc destino` | Salto condicional: `JZ`/`JE`, `JNZ`, `JG`, `JB`… |
| `JMP` | Salto incondicional |
| `CALL destino` | **Apila la dirección de retorno** y salta |
| `RET` | **Desapila esa dirección y salta a ella** |
| `PUSH` / `POP` | Apila / desapila (mueven `RSP`) |
| `REP MOVSB` | Copia bloque — un `memcpy` en línea |

`CALL` y `RET` son el par que hay que interiorizar: **la dirección de retorno vive en la pila**, junto a las variables locales. Toda la explotación de desbordamientos de pila sale de ahí ([[04 - Explotación de desbordamiento de pila]]).

## El marco de pila

```text
   Direcciones altas
   ┌─────────────────────────┐
   │ Argumentos en pila (7+) │
   ├─────────────────────────┤
   │ Dirección de retorno    │  ← lo que RET va a usar
   ├─────────────────────────┤
   │ RBP guardado            │  ← RBP apunta aquí
   ├─────────────────────────┤
   │ Canario de pila         │  ← si el compilador lo emitió
   ├─────────────────────────┤
   │ Variables locales       │
   │   char buf[64]          │  ← desbordar esto sube hacia el retorno
   └─────────────────────────┘  ← RSP
   Direcciones bajas
```

La pila **crece hacia direcciones bajas**, pero `memcpy` y `strcpy` **escriben hacia arriba**. Por eso un desbordamiento de búfer local llega al canario y luego a la dirección de retorno, y no al revés.

Prólogo y epílogo típicos:

```asm
push rbp            ; prólogo
mov  rbp, rsp
sub  rsp, 0x40      ; reserva 64 bytes de locales
...
leave               ; equivale a: mov rsp, rbp / pop rbp
ret
```

Con optimizaciones, el compilador suele **omitir `RBP`** como puntero de marco y direccionar todo relativo a `RSP` — verás `[rsp+0x20]` en vez de `[rbp-0x20]`.

## ARM64 (AArch64) en una tabla

| Elemento | ARM64 |
| - | - |
| Argumentos | `X0`-`X7` |
| Retorno | `X0` |
| Dirección de retorno | **`X30` (LR)**, un registro — no la pila |
| Puntero de marco / pila | `X29` (FP) / `SP` |
| Carga y almacenamiento | **Solo** `LDR`/`STR` (arquitectura load-store) |
| Llamada / retorno | `BL destino` / `RET` |
| Tamaño de instrucción | Fijo, 4 bytes |

Las dos diferencias que cambian el análisis: **las instrucciones tienen tamaño fijo** (no hay solapamiento de instrucciones, lo que elimina toda una clase de trucos de x86), y **la dirección de retorno empieza en un registro**, no en la pila. Solo se guarda en la pila si la función llama a otra — y de ahí que **PAC** (*Pointer Authentication*) pueda firmarla criptográficamente antes de guardarla, que es la mitigación que hace mucho más difícil el ROP en ARM64 moderno ([[08 - Mitigaciones modernas y cómo se saltan]]).

## Leer el decompilador, no el ensamblador

En la práctica, con Ghidra o Hex-Rays vas a leer pseudo-C, no ensamblador. El ensamblador se mira cuando el decompilador se equivoca — que pasa, sobre todo con estructuras, uniones y código optimizado con SIMD. Saber lo de arriba sirve exactamente para eso: **detectar cuándo el pseudo-C no dice la verdad**.

Ejemplo típico: el decompilador muestra `memcpy(dst, src, len)` con `len` como `int`. Si en el ensamblador ves que ese valor viene de un registro de 32 bits que se extiende con **`MOVSXD`** (extensión con signo) en vez de `MOV`, el valor **puede ser negativo**, y al convertirse a `size_t` en el `memcpy` se vuelve gigantesco. Eso es un desbordamiento que el pseudo-C oculta ([[02 - Errores de enteros - overflow, truncamiento y signo]]).

> [!info]+ Fuentes
> - [System V AMD64 ABI](https://gitlab.com/x86-psABIs/x86-64-ABI) — convención de llamada de Linux/macOS/BSD.
> - [Microsoft x64 calling convention](https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention) — incluido el *shadow space*.
> - [Arm 64-bit Architecture Procedure Call Standard (AAPCS64)](https://github.com/ARM-software/abi-aa/blob/main/aapcs64/aapcs64.rst).
> - [Intel 64 and IA-32 Architectures Software Developer Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) para la referencia de instrucciones.
