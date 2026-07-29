---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
  - Introduccion
  - Tipo/Introduccion
Descripción: "John the Ripper (JtR) es un *password cracker* open source de Openwall, orientado a CPU (con soporte OpenCL para GPU), multiplataforma y con soporte para cientos de tipos de hash"
Fecha de actualización: 2026-07-18
Nota previa: 
Nota siguiente: "[[01 - Cracking en la práctica con John]]"
Area: "[[John the Ripper.base|John the Ripper]]"
---
---

<mark style="background: #ADCCFFA6;">`John the Ripper` (JtR) es un *password cracker* open source de Openwall</mark>, orientado a `CPU` (con soporte `OpenCL` para GPU), multiplataforma y con soporte para cientos de tipos de hash. Es, junto a [[00 - Introducción a Hashcat|Hashcat]], la herramienta de referencia para el descifrado offline de hashes capturados durante un pentest.

> [!important]+ Usa siempre la versión "Jumbo"
> La versión "core" de John soporta pocos formatos. <mark style="background: #FFB86CA6;">La que se usa en pentest es `John the Ripper Jumbo` (community edition)</mark> — trae cientos de formatos (NTLM, Kerberos, sha512crypt, bcrypt…) y los *2john* que extraen hashes de ficheros. Kali/Parrot ya la traen. Repo: [github.com/openwall/john](https://github.com/openwall/john).

# Los modos de ataque

<mark style="background: #FFB8EBA6;">JtR no es solo "diccionario": tiene varios modos, y elegir el correcto define el éxito</mark>:

| Modo | Flag | Qué hace |
| --- | --- | --- |
| **Single crack** | `--single` | Deriva candidatos del propio *username* y GECOS — rapidísimo y sorprendentemente eficaz |
| **Wordlist** | `--wordlist=` | Prueba una lista, opcionalmente con reglas de mutación (`--rules`) |
| **Mask** | `--mask=` | Fuerza bruta por patrón (`?u?l?l?l?d?d`), calcado del `-a 3` de Hashcat — útil sin GPU (solo Jumbo) |
| **Incremental** | `--incremental` | Fuerza bruta inteligente por frecuencia de caracteres |
| **External** | `--external=` | Modo programable en C definido por el usuario |

El flujo habitual: **single → wordlist con reglas → incremental** como último recurso (el incremental puede tardar eternidades). Jumbo añade también `--loopback`, que recrackea usando las contraseñas ya rotas (del *potfile*) como diccionario — muy eficaz para cazar reutilización de patrones entre cuentas.

# Sintaxis

```shell-session
# Modo wordlist con formato explícito
$ john --wordlist=/usr/share/wordlists/rockyou.txt --format=raw-md5 hashes.txt

# Single crack (aprovecha el username del propio fichero)
$ john --single --format=nt hashes.txt

# Ver lo ya crackeado
$ john --show --format=raw-md5 hashes.txt
```

<mark style="background: #FF5582A6;">El formato del hash (`--format`) es la causa nº1 de "no cracker nada"</mark>: si le dices `raw-md5` a un NTLM, no funciona. Cuando dudes, deja que JtR intente autodetectar (omite `--format`) o identifica primero.

# Identificar el tipo de hash

Antes de crackear hay que saber **qué** hash es:

```shell-session
$ john --list=formats | tr ',' '\n' | grep -i ntlm    # ¿qué formatos hay?
$ hashid '$6$xyz...'                                    # identificar por patrón
$ nth --text '<hash>'                                   # name-that-hash (moderno)
```

Herramientas como [hashid](https://github.com/psypanda/hashID) y [Name-That-Hash](https://github.com/HashPals/Name-That-Hash) reconocen el tipo por su estructura (`$6$` = sha512crypt, `$2y$` = bcrypt, 32 hex sin sal = posible NTLM/MD5).

# El potfile

<mark style="background: #8000E1A6;">JtR guarda cada hash crackeado en `~/.john/john.pot`</mark> y no lo vuelve a intentar. Útil (no repite trabajo) pero traicionero: si "no crackea" un hash que ya rompiste antes, es porque está en el pot — revísalo con `--show` o borra el pot para empezar limpio.

# JtR vs. Hashcat

Ambos crackean; se complementan. Regla rápida:

- **John**: mejor para *single crack*, formatos raros, y cuando solo hay CPU. Trae los *2john integrados.
- **[[00 - Introducción a Hashcat|Hashcat]]**: mucho más rápido con **GPU**, el estándar para grandes volúmenes y ataques de máscara.

El detalle operativo —los *2john para extraer hashes de ficheros, las reglas y los formatos de pentest— en la [[01 - Cracking en la práctica con John|siguiente nota]]. Y su papel dentro del flujo de [[Ataques a contraseñas.base|ataques a contraseñas]].
