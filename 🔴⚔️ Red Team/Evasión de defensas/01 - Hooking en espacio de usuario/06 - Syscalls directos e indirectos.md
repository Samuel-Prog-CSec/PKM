---
tags:
  - Evasion
  - Windows
  - EDR
  - Hooking
Descripción: "El unhooking repara ntdll; los *syscalls* la saltan"
Fecha de actualización: 2026-07-28
Nota previa: "[[05 - Unhooking y remapping de ntdll]]"
Nota siguiente: "[[07 - Notificaciones de creación de proceso e hilo]]"
Area: "[[Hooking userland.base|Hooking userland]]"
---
---

El [[05 - Unhooking y remapping de ntdll|unhooking]] repara `ntdll`; los *syscalls* la **saltan**. La idea: si el `stub` de `ntdll` no hace más que meter un número en `EAX` y ejecutar `syscall`, puedes reproducir esas cuatro instrucciones tú mismo y hablar con el kernel sin pasar por la función enganchada. Es la evasión de hooks más usada de la historia reciente… y también la que peor ha envejecido. <mark style="background: #FF5582A6;">La diferencia entre *directo* e *indirecto* es hoy la diferencia entre disparar una alerta y no disparar nada</mark>, y hay que entender exactamente por qué.

# El `stub` y el SSN

Cada función nativa tiene un **SSN** (*System Service Number*), el índice de su entrada en la tabla de servicios del kernel:

```asm
mov r10, rcx                 ; preserva RCX (volátil en el paso a kernel)
mov eax, 18h                 ; SSN de NtAllocateVirtualMemory en esta build
test byte ptr [SharedUserData+0x308], 1   ; ¿Restricted User Mode?
jne  <ruta int 2Eh>
syscall                      ; 0F 05 -> transición al kernel
ret
```

> [!warning]+ No copies el `stub` de 4 líneas del libro y te olvides
> El `test`/`jne` no es decorativo: en sistemas con **HVCI + Restricted User Mode** (VBS activo, cada vez más común en flotas corporativas y por defecto en Windows 11 en hardware compatible) la transición se hace por `int 2Eh`, no por `syscall`. Un `stub` hecho a mano que omita ese *check* funciona en tu VM de laboratorio y **falla o se comporta raro** en el endpoint del cliente. Copia la forma real de la build objetivo, no la simplificada.

# Syscalls directos: cómo se hacen y por qué murieron

Un *syscall directo* es reimplementar el `stub` en tu propio `.asm` y llamarlo desde C. El problema histórico fue el SSN: <mark style="background: #ADCCFFA6;">Microsoft **renumera** los servicios entre builds</mark> — `NtCreateThreadEx` es `0xBD` en Windows 10 1909 y `0xC1` en 20H1 —, así que hardcodearlos ata la herramienta a una versión. De ahí toda una genealogía de técnicas para resolverlos en runtime:

| Técnica | Cómo obtiene el SSN | Punto débil |
| --- | --- | --- |
| **SysWhispers** (2019) | Tabla estática por build, leída del PEB | Hay que actualizarla en cada release de Windows |
| **SysWhispers2 / FreshyCalls** | Ordena los exports `Zw*` por **RVA**; el índice tras ordenar *es* el SSN | Falla si el EDR reordena/parchea el EAT |
| **Hell's Gate** | Lee los bytes del `stub` y extrae el `mov eax, SSN` | Si la función está enganchada, lee basura |
| **Halo's Gate** | Si detecta hook (`0xE9` al inicio), salta a los vecinos: los `stub` van cada **32 bytes**, así que SSN vecino ∓ *n* | Asume que los vecinos están limpios |
| **Tartarus' Gate** | Como Halo's, pero valida con el prefijo `4C 8B D1` completo y tolera hooks desplazados | Más código, misma idea |

Todas resuelven el mismo problema —el número— y **ninguna resuelve el que importa**. Cuando ejecutas `syscall` desde tu propio módulo, el kernel guarda en el *trap frame* la dirección de retorno a userland, y esa dirección **apunta a tu código**, no a `ntdll`. Para el EDR es un regalo:

```text
Flujo legítimo   :  app.exe -> kernelbase!VirtualAlloc -> ntdll!NtAllocateVirtualMemory -> [syscall]
Syscall directo  :  loader.bin(unbacked) -> [syscall]        <-- ni rastro de ntdll
```

<mark style="background: #FFB86CA6;">Ningún proceso legítimo de Windows ejecuta la instrucción `syscall` fuera de `ntdll.dll` o `win32u.dll`</mark>. La regla de detección es de una línea, no tiene falsos positivos y la aplican desde el kernel —donde no la puedes tocar— vía [[16 - EtwTi y Protected Processes|ETW-TI]]. Si además tu código vive en memoria *unbacked* (shellcode, DLL reflectiva), sumas un segundo indicador crítico. Los syscalls directos llevan detectados de forma fiable desde ~2022: **hoy solo sirven contra AV y EDR de gama baja**.

# Syscalls indirectos: pedir prestada la instrucción

La corrección es quirúrgica: monta los registros tú, pero **ejecuta el `syscall` que ya está dentro de `ntdll`**. En vez de terminar tu `stub` con `syscall`, termina con un `jmp` a la dirección de la instrucción `syscall` de la función correspondiente:

```asm
NtAllocateVirtualMemory PROC
    mov r10, rcx
    mov eax, dwSSN                 ; SSN resuelto en runtime
    jmp qword ptr [qwSyscallAddr]  ; -> dirección de `syscall` DENTRO de ntdll
NtAllocateVirtualMemory ENDP
```

Se usa `jmp` y no `call` a propósito: no se apila un marco extra, y cuando el kernel captura el RIP de retorno, este cae **dentro de `ntdll.dll`**, exactamente donde lo esperaría un flujo normal. <mark style="background: #8000E1A6;">El indicador estrella del syscall directo desaparece por completo</mark>, sin escribir un solo byte en memoria de imagen (a diferencia del [[05 - Unhooking y remapping de ntdll|unhooking]]). Implementaciones de referencia: **SysWhispers3** (modo `-jumper`), **Hell's Hall**, **RecycledGate**.

## Lo que sigue quedando visible

Los indirectos **no son invisibles**; suben el listón. Dos cosas siguen delatándote:

1. **Mismatch SSN ↔ dirección de `syscall`.** Cada instrucción `syscall` de `ntdll` pertenece al `stub` de *una* función concreta. Si saltas a la `syscall` de `NtDrawText` con el SSN de `NtAllocateVirtualMemory` en `EAX`, el par es imposible en un flujo real. Un detector que enumere los `stub` al arrancar y compare puede pillarlo — es justo lo que hacen PoC defensivos como `HallWatch`. **Mitigación**: usa la dirección de `syscall` de la **misma** función cuyo SSN vas a invocar (lo que hace Hell's Hall bien implementado); si la función está enganchada, resuelve la dirección desde una copia limpia por [[05 - Unhooking y remapping de ntdll|`\KnownDlls`]] en lugar de reciclar la del vecino.
2. **El resto de la pila.** El marco superior ya es `ntdll`, pero justo debajo sigue estando **tu módulo**. Un EDR que hace *stack unwinding* ve `ntdll!syscall → memoria no respaldada por imagen` y no ve el `kernelbase` que debería estar en medio. Esta es la razón de ser del [[20 - Call-stack spoofing|call-stack spoofing]]: sin él, los syscalls indirectos son la mitad del trabajo.

# La tabla de decisión

| Enfoque | Evade hook userland | RIP de `syscall` en `ntdll` | Pila coherente | Uso hoy |
| --- | --- | --- | --- | --- |
| API de Win32 normal | ❌ | ✅ | ✅ | Solo si la API no está enganchada |
| [[05 - Unhooking y remapping de ntdll\|Unhooking]] | ✅ | ✅ | ✅ | Ruidoso (`RWX` sobre imagen) |
| Syscall **directo** | ✅ | ❌ | ❌ | Quemado |
| Syscall **indirecto** | ✅ | ✅ | ❌ | Estándar actual |
| Indirecto + [[20 - Call-stack spoofing\|spoofing de pila]] | ✅ | ✅ | ✅ | Tradecraft de 2026 |

# Cómo se detecta y cómo se audita

- **ETW-TI** entrega eventos de kernel firmados con la pila de llamadas de operaciones sensibles (`ALLOCVM`, `PROTECTVM`, `WRITEVM`, `MAPVIEW`). Es la fuente que mata los syscalls directos y estrecha los indirectos. No la puedes parchear desde tu proceso ([[16 - EtwTi y Protected Processes|nota 16]]).
- **Sysmon no ve esto.** Ni EID 1 ni EID 7 registran desde dónde se ejecutó un `syscall`. Si tu única referencia de "no me detectan" es un lab con Sysmon, tienes un falso negativo.
- **Auditar tu propia huella**: `Moneta` y `PE-sieve` marcan regiones ejecutables *unbacked* y `stub` alterados; `SilkETW`/`SealighterTI` permiten ver los eventos ETW-TI que generas. Medir antes de operar es lo que separa a un red teamer de alguien ejecutando un PoC de GitHub.

> [!important]+ Regla operativa
> <mark style="background: #FFB8EBA6;">Indirecto por defecto, directo nunca, y asume que ninguno de los dos te salva del kernel</mark>. El syscall (de cualquier tipo) solo evade el sensor de userland: la [[07 - Notificaciones de creación de proceso e hilo|notificación de creación de proceso]], el [[10 - Object callbacks y robo de handles|object callback]] al abrir un handle a `lsass.exe` y el `ALLOCVM` de ETW-TI **siguen ocurriendo**, porque los genera el propio kernel al atender tu petición. Cambiar cómo llamas no cambia qué pides.

Fuentes: Matt Hand, *Evading EDR* cap. 2 · [MDSec — Bypassing User-Mode Hooks and Direct Invocation of System Calls](https://www.mdsec.co.uk/2020/12/bypassing-user-mode-hooks-and-direct-invocation-of-system-calls-for-red-teams/) · [RedOps — Direct vs Indirect Syscalls](https://redops.at/en/blog/direct-syscalls-vs-indirect-syscalls) e [Indirect Syscalls and Hooked SSNs](https://redops.at/en/blog/indirect-syscalls-and-hooked-ssns) · [Alice Climent-Pommeret — Hell's Gate / Halo's Gate / FreshyCalls / SysWhispers2](https://alice.climent-pommeret.red/posts/direct-syscalls-hells-halos-syswhispers2/) · [TartarusGate](https://github.com/trickster0/TartarusGate) · [SysWhispers3](https://github.com/klezVirus/SysWhispers3) · Windows Internals 7th ed. (SSDT y transición a kernel).
