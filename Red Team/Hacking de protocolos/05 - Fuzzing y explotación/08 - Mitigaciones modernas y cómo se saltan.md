---
tags:
  - Corrupcion-Memoria
  - Evasion
  - Pentesting/Explotacion
  - Tipo/Defensa
Descripción: "DEP, ASLR y canarios son de 2005; hoy hay CET, PAC, BTI, MTE y CFI — qué corta cada capa, qué margen deja y cómo se comprueba en un binario"
Fecha de actualización: 2026-08-03
Nota previa: "[[07 - Shellcode - de las syscalls al payload]]"
Nota siguiente: "[[09 - Arsenal de fuzzing y explotación]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

La explotación de memoria es una carrera de treinta años entre mitigaciones y técnicas para saltarlas. El libro cubre la situación de **2005-2010** —DEP, ASLR y canarios— que es donde se quedó. Esta nota pone al día las capas actuales, porque determinan si un desbordamiento es un incidente crítico o un DoS con mucho trabajo por delante.

## La primera generación (y sus rodeos)

### DEP / NX — no ejecutar datos

Marca la pila y el heap como no ejecutables. Mata en seco el *shellcode* inyectado en un búfer.

**El rodeo es ROP** (*Return-Oriented Programming*). Si no puedes traer código nuevo, reutilizas el que ya está y **es ejecutable por definición**: pequeñas secuencias que terminan en `ret`, llamadas *gadgets*.

> [!important]+ Por qué la cadena se encadena sola
> Esta es la idea que hay que interiorizar y la que casi nunca se explica. **`ret` no es «volver»: es `pop RIP`** — saca la palabra que hay en la cima de la pila y salta ahí.
>
> Como el desbordamiento te da control de la pila, controlas **todas** las palabras que los sucesivos `ret` van a consumir. Cada gadget termina en `ret`, que consume la siguiente dirección que pusiste. <mark style="background: #8000E1A6;">No estás llamando a una función: estás alimentando un intérprete cuyo puntero de instrucción es `RSP`</mark>.

Montando `system("/bin/sh")` en x86-64 (System V: el primer argumento va en `RDI`):

```text
   Pila que dejas tras el desbordamiento          Qué pasa al ejecutarse
   ┌──────────────────────────┐
   │ &(pop rdi; ret)          │ ← RSP  (1) el `ret` de la función víctima salta aquí
   ├──────────────────────────┤
   │ &"/bin/sh"               │        (2) `pop rdi` se lleva esto a RDI
   ├──────────────────────────┤
   │ &system                  │        (3) el `ret` del gadget salta a system
   ├──────────────────────────┤
   │ &exit                    │        (4) dirección de retorno de system
   └──────────────────────────┘
```

Cada `ret` avanza `RSP` una palabra, así que la ejecución recorre tu lista de arriba abajo. Los gadgets útiles son minúsculos:

```asm
pop rdi ; ret          ← cargar el 1.er argumento
pop rsi ; pop rdx ; ret ← cargar el 2.º y el 3.º de un tirón
syscall ; ret          ← invocar directamente al kernel
```

La versión mínima, sin gadgets intermedios, es **ret2libc**: poner directamente `&system` en la dirección de retorno. Funciona en 32 bits (donde los argumentos van en la pila) y por eso es el ejemplo clásico; en 64 bits casi siempre necesitas al menos un `pop rdi; ret`.

Si el bug **no** está en la pila (heap, UAF), tu control está en otra región y hace falta un ***stack pivot***: un gadget que traiga `RSP` a la memoria que sí controlas.

```asm
xchg esp, eax    ; si controlas EAX, a partir de aquí controlas la pila
ret              ; y este ret ya consume TU cadena
```

En la práctica no se hace a mano:

```shell-session
$ ROPgadget --binary ./servidor --only "pop|ret" | grep "pop rdi"
0x00000000004011f3 : pop rdi ; ret

$ ropper --file ./servidor --search "pop rdi"
[INFO] Searching for gadgets: pop rdi
0x00000000004011f3: pop rdi; ret;
```

```python
from pwn import *

elf  = ELF('./servidor')
rop  = ROP(elf)
binsh = next(elf.search(b'/bin/sh\x00'))

rop.call('system', [binsh])      # pwntools elige los gadgets por ti
print(rop.dump())

payload = b'A' * 72 + rop.chain()   # 72 = offset hallado con cyclic()
```

```text
0x0000:         0x4011f3 pop rdi; ret
0x0008:         0x404060 [arg0] rdi = 4210784
0x0010:         0x401060 system
```

`rop.dump()` te enseña exactamente la pila que va a construir — merece la pena mirarlo antes de disparar, porque es donde se ven los fallos de alineación (en x86-64, algunas versiones de `system` exigen `RSP` alineado a 16 bytes, y la solución es intercalar un gadget `ret` suelto).

### ASLR — direcciones impredecibles

Aleatoriza dónde se cargan pila, heap, librerías y (con **PIE**) el propio ejecutable. Sin saber direcciones, no puedes construir la cadena ROP.

Sus tres grietas:

1. **Fuga de información.** Cualquier lectura fuera de límites que devuelva un puntero da la base de un módulo, y de ahí todo lo demás por desplazamiento. Es por lo que una «simple» fuga de heap es tan valiosa ([[03 - Indexación fuera de límites y expansión de datos]]).
2. **Sobrescritura parcial.** ASLR aleatoriza a granularidad de página, así que **los 12 bits bajos de una dirección no cambian**. Sobrescribiendo solo el byte o los dos bytes bajos de un puntero, lo mueves a otro sitio conocido sin saber la base.
3. **Procesos que bifurcan sin `exec`.** Un servidor que hace `fork()` por conexión da a todos los hijos **el mismo mapa de memoria**. Se puede hacer fuerza bruta byte a byte: cada intento fallido mata al hijo, no al servidor, y el padre acepta otra conexión. Es la técnica *BROP* de Bittau et al. — <mark style="background: #FF5582A6;">un modelo de concurrencia elegido por rendimiento derrota ASLR sin necesitar ninguna fuga</mark>.

### Canarios de pila

Valor aleatorio entre las locales y la dirección de retorno, comprobado antes del `ret`. Los rodeos están en [[04 - Explotación de desbordamiento de pila]]: corromper algo que se use antes del `ret`, filtrar el canario, o desbordar hacia abajo.

### RELRO

`Full RELRO` resuelve la GOT al arrancar y la marca de solo lectura, eliminando el objetivo clásico de escritura arbitraria. Es el valor por defecto en Debian, Ubuntu, Fedora y RHEL desde hace años.

## La generación actual

Aquí es donde el libro no llega, y donde está el cambio de verdad.

### Integridad de flujo de control (CFI)

La idea: comprobar que los saltos y llamadas indirectas van a destinos **legítimos**, no a cualquier sitio.

| Implementación | Plataforma | Qué comprueba |
| - | - | - |
| **Control Flow Guard (CFG)** | Windows | Que el destino de una llamada indirecta esté en un bitmap de funciones válidas |
| **XFG** (*eXtended Flow Guard*) | Windows | Además, que **la firma de tipo** coincida — mucho más estricto |
| **Clang CFI** | Linux, Android, Chrome | Comprobaciones por tipo, en compilación |
| **kCFI / FineIBT** | Kernel de Linux | CFI en modo kernel |

CFI degrada mucho el ROP clásico, pero **no lo elimina**: quedan las llamadas a funciones que sí son destinos válidos (los ataques de *Counterfeit Object-Oriented Programming*, COOP), y sobre todo **no protege el `ret`** — para eso está lo siguiente.

### Intel CET: shadow stack e IBT

Dos mecanismos en hardware:

- **Shadow stack**: la CPU mantiene una **segunda pila, protegida**, con copias de las direcciones de retorno. En cada `ret` compara ambas y si no coinciden, excepción. <mark style="background: #FFB86CA6;">Esto rompe el ROP de raíz</mark>, porque toda la técnica consiste en poner direcciones falsas en la pila.
- **IBT** (*Indirect Branch Tracking*): toda llamada o salto indirecto debe aterrizar en una instrucción `ENDBR64`, lo que reduce drásticamente el conjunto de gadgets utilizables.

**Estado de despliegue a 2026** — y aquí hay que ser preciso, porque se exagera en ambas direcciones:

- **Windows** lo tiene como *Hardware-enforced Stack Protection*, activable en modo usuario y con implementación en modo kernel. **No está universalmente activo**: cada aplicación tiene que optar por él.
- **Linux** soporta shadow stack en modo usuario desde el **kernel 6.6**, con glibc sincronizado. Pero **glibc decidió no activarlo por defecto** para no romper aplicaciones y librerías existentes: hay que pedirlo con `GLIBC_TUNABLES=glibc.cpu.hwcaps=SHSTK`.

Traducción práctica: **CET está disponible pero lejos de ser universal**. En un objetivo concreto hay que comprobarlo, no asumirlo.

### ARM64: PAC, BTI y MTE

- **PAC** (*Pointer Authentication*) firma criptográficamente los punteros —incluida la dirección de retorno— usando bits altos que no se usan para direccionar. Antes de usar el puntero, se verifica la firma. Falsificar una dirección de retorno requiere falsificar el PAC. Es lo que hace la explotación en Apple Silicon y en Android moderno **sustancialmente más difícil**.
- **BTI** (*Branch Target Identification*) es el equivalente de IBT: los saltos indirectos deben aterrizar en una instrucción `BTI`.
- **MTE** (*Memory Tagging Extension*, ARMv9) etiqueta bloques y punteros con 4 bits y comprueba la correspondencia en cada acceso. Detecta **desbordamientos y use-after-free en producción**, con coste bajo. Android lo despliega ya en componentes seleccionados y está ampliando la lista.

Soporte de compilador: PAC y BTI están en LLVM y GCC, y **Debian y Red Hat ya distribuyen binarios compatibles**.

MTE es el más interesante de los tres, porque no protege el flujo de control: **ataca la causa raíz**. Un UAF con MTE activo no llega a ser explotable, se detecta en el acceso.

## Tabla de estado

| Mitigación | Impide | Rodeo | Estado 2026 |
| - | - | - | - |
| DEP / NX | Ejecutar datos | ROP | Universal |
| ASLR / PIE | Conocer direcciones | Fuga, sobrescritura parcial, BROP | Universal |
| Canarios | Alcanzar el retorno | Fuga, corromper antes del `ret` | Por defecto al compilar |
| Full RELRO | Escribir la GOT | Otros punteros | Por defecto en distros |
| CFG / XFG | Llamadas indirectas ilegítimas | COOP, destinos válidos | Windows, opcional |
| CET shadow stack | **ROP** | Data-only, JOP | Disponible, **no por defecto** |
| CET IBT | Saltos a mitad de gadget | Gadgets con `ENDBR64` | Con CET |
| PAC | Falsificar punteros | Fugas de firmas, reutilización | ARM64 moderno |
| MTE | UAF y desbordamientos | Colisión de etiquetas (1/16) | Android, creciendo |

## Lo que sobrevive a todo

Dos cosas, y conviene tenerlas presentes:

1. **Los ataques que solo tocan datos.** Ninguna de las mitigaciones de la tabla impide cambiar un `is_admin` de 0 a 1 ([[06 - Escritura arbitraria y subversión de lógica]]). Protegen el **flujo de control**, no la **integridad de los datos**. Es la razón de que sea una línea de investigación activa y de que sea, casi siempre, el camino más corto en un objetivo endurecido.
2. **El código que no tiene nada de esto.** Firmware, dispositivos empotrados, sistemas industriales y médicos, *appliances* con binarios de hace ocho años. Ahí sigue funcionando el manual de 2005 tal cual — y es justo donde viven los protocolos propietarios que motivan esta área entera.

## Comprobarlo en un binario

```shell-session
$ checksec --file=./servidor
RELRO      STACK CANARY  NX       PIE      RPATH   FORTIFY
Full RELRO Canary found  NX enab  PIE enab No RPATH Yes

$ readelf -n ./servidor | grep -i -A2 'properties'      # ¿IBT/SHSTK/BTI/PAC?
      Properties: x86 feature: IBT, SHSTK

$ pwn checksec ./servidor                                # equivalente de pwntools
```

En Windows, el módulo `Get-ProcessMitigation` de PowerShell y `binskim` de Microsoft dan el inventario equivalente.

<mark style="background: #FF5582A6;">Un binario sin canario, sin PIE y sin RELRO es un hallazgo reportable por sí mismo</mark>, aunque no encuentres ninguna vulnerabilidad de memoria: significa que cualquiera que aparezca en el futuro será trivialmente explotable. Es una recomendación barata de implementar (banderas del compilador) y de alto valor.

> [!info]+ Fuentes
> - [Intel CET — Shadow Stack en el kernel de Linux](https://docs.kernel.org/next/arch/x86/shstk.html) y la decisión de glibc de no activarlo por defecto.
> - [Windows — Hardware-enforced Stack Protection](https://techcommunity.microsoft.com/blog/windowsosplatform/understanding-hardware-enforced-stack-protection/1247815).
> - [Arm — *Providing protection for complex software*](https://developer.arm.com/documentation/102433/latest/) (PAC, BTI, MTE) y [MTE en Android](https://source.android.com/docs/security/test/memory-safety/arm-mte).
> - Bittau et al., *Hacking Blind* (IEEE S&P 2014) — la técnica BROP contra ASLR en servidores que bifurcan.
> - [checksec](https://github.com/slimm609/checksec.sh), [ROPgadget](https://github.com/JonathanSalwan/ROPgadget), [ropper](https://github.com/sashs/Ropper).
