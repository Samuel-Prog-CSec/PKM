---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
  - Introduccion
  - Tipo/Introduccion
Descripción: "Hashcat es el *password cracker* más rápido, acelerado por GPU (OpenCL/CUDA)"
Fecha de actualización: 2026-07-18
Nota previa: 
Nota siguiente: "[[01 - Ataques avanzados y optimización con Hashcat]]"
Area: "[[Hashcat.base|Hashcat]]"
---
---

<mark style="background: #ADCCFFA6;">`Hashcat` es el *password cracker* más rápido, acelerado por `GPU` (OpenCL/CUDA)</mark>. Donde [[00 - Introducción a John the Ripper|John]] brilla por versatilidad, Hashcat lo hace por velocidad bruta: con una GPU decente prueba miles de millones de candidatos por segundo contra hashes rápidos. Es el estándar para volúmenes grandes y ataques de máscara.

# Modos de ataque (`-a`)

<mark style="background: #FFB8EBA6;">El modo de ataque define cómo se generan los candidatos</mark>:

| `-a` | Modo | Qué hace |
| --- | --- | --- |
| `0` | Straight (diccionario) | Prueba una wordlist, opcionalmente con reglas |
| `1` | Combinator | Combina dos wordlists |
| `3` | Mask (fuerza bruta) | Genera candidatos por patrón (`?a?a?a...`) |
| `6` | Hybrid Wordlist + Mask | palabra + sufijo por máscara |
| `7` | Hybrid Mask + Wordlist | prefijo por máscara + palabra |
| `9` | Association | candidato derivado de un *hint* asociado a cada hash (username, pista) |

# Tipos de hash (`-m`)

Cada tipo de hash tiene un número. Los que aparecen en un pentest:

| `-m` | Hash |
| --- | --- |
| `0` | MD5 |
| `100` | SHA1 |
| `1000` | **NTLM** (SAM) |
| `1800` | sha512crypt (`$6$`, Linux) |
| `3200` | bcrypt (`$2y$`) |
| `5600` | **NetNTLMv2** (Responder) |
| `13100` | **Kerberos krb5tgs** RC4 (Kerberoasting) |
| `19700` | **Kerberos krb5tgs** AES256 (Kerberoasting con RC4 deshabilitado) |
| `18200` | Kerberos krb5asrep (AS-REP) |
| `22000` | WPA/WPA2 |

```shell-session
$ hashcat --example-hashes | less     # formato de ejemplo de cada -m
```

<mark style="background: #FF5582A6;">Elegir mal el `-m` es el error nº1</mark>: `--example-hashes` muestra el formato exacto que espera cada tipo.

# Sintaxis

```shell-session
# Diccionario contra NTLM
$ hashcat -m 1000 -a 0 hashes.txt /usr/share/wordlists/rockyou.txt

# Máscara: 8 caracteres cualquiera (fuerza bruta dirigida)
$ hashcat -m 1000 -a 3 hashes.txt '?a?a?a?a?a?a?a?a'

# Híbrido: palabra de rockyou + 3 dígitos
$ hashcat -m 1000 -a 6 hashes.txt rockyou.txt '?d?d?d'

# Ver crackeadas
$ hashcat -m 1000 hashes.txt --show
```

<mark style="background: #FFB86CA6;">El orden importa: `hashcat -m <tipo> -a <modo> <hashfile> <wordlist/máscara>`</mark>. Si el hash lleva el username (`user:hash`), añade `--username` para que lo ignore.

# El potfile

Como John, Hashcat guarda lo crackeado en `~/.local/share/hashcat/hashcat.potfile` (ruta XDG desde la 6.2.2; `~/.hashcat/hashcat.potfile` es la ubicación legacy) y no lo repite. Si un hash "no sale" pero ya lo rompiste, está en el pot — `--show` lo revela.

# Rendimiento y OPSEC

<mark style="background: #8000E1A6;">El cracking es **offline**: no toca al objetivo</mark>, así que no genera telemetría en el cliente — se hace en tu propia máquina/rig sobre los hashes ya capturados. La restricción es de hardware (GPU) y tiempo, no de detección. Esto lo diferencia de los [[03 - Ataques remotos a servicios de red|ataques online]], que sí son ruidosos.

Los ataques de máscara y reglas —donde Hashcat despliega su potencia— y la optimización, en la [[01 - Ataques avanzados y optimización con Hashcat|siguiente nota]]. Su papel dentro del flujo, en [[Ataques a contraseñas.base|ataques a contraseñas]].
