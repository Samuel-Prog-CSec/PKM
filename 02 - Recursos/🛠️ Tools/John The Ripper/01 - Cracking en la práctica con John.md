---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-18
Nota previa: "[[00 - Introducción a John the Ripper]]"
Nota siguiente: 
Area: "[[John the Ripper.base|John the Ripper]]"
---
---

Más allá de los modos, el valor de John en un engagement está en dos cosas: los `*2john` que convierten cualquier fichero protegido en un hash crackeable, y las reglas que multiplican una wordlist.

# Los `*2john`: de un fichero a un hash

<mark style="background: #ADCCFFA6;">Los scripts `*2john` extraen un hash crackeable del material protegido</mark> — clave SSH, ZIP, documento, base de KeePass…:

| Utilidad | Origen |
| --- | --- |
| `zip2john` / `rar2john` / `7z2john` | Archivos comprimidos protegidos |
| `ssh2john` | Claves privadas SSH con passphrase |
| `pdf2john` / `office2john` | PDF y documentos Office |
| `keepass2john` | Bases de KeePass (`.kdbx`) |
| `bitlocker2john` | Volúmenes BitLocker |

```shell-session
$ zip2john secret.zip > zip.hash
$ john --wordlist=/usr/share/wordlists/rockyou.txt zip.hash

$ ssh2john id_rsa > ssh.hash
$ john --wordlist=rockyou.txt ssh.hash
```

Esto es la base de [[02 - Cracking de ficheros y archivos protegidos|cracking de ficheros protegidos]] en el módulo de ataques a contraseñas.

# Reglas de mutación

<mark style="background: #FFB86CA6;">Las reglas transforman cada palabra de la lista</mark> (añadir números, capitalizar, sustituir `a→@`) para cubrir las mutaciones que la gente hace sobre contraseñas base:

```shell-session
$ john --wordlist=rockyou.txt --rules=Jumbo hashes.txt      # ruleset amplio
$ john --wordlist=rockyou.txt --rules=Single hashes.txt      # rápido
```

Las reglas se definen en `john.conf`; los rulesets `Jumbo` y `KoreLogic` son un enorme multiplicador. El diseño de reglas propias se trata en [[01 - Wordlists y reglas personalizadas]].

# Formatos que importan en pentest

Los hashes que realmente aparecen en un test de intrusión Windows/Linux:

| `--format` | Origen |
| --- | --- |
| `nt` | NTLM — hashes de la [[06 - Ataque a SAM, SYSTEM y SECURITY\|SAM]] |
| `netntlmv2` | NetNTLMv2 capturado con Responder |
| `krb5tgs` | Kerberoasting (TGS de servicio) |
| `krb5asrep` | AS-REP Roasting |
| `sha512crypt` | `/etc/shadow` (`$6$`) en [[11 - Autenticación y credential hunting en Linux\|Linux]] |
| `bcrypt` | `$2y$` (apps modernas) |

<mark style="background: #FF5582A6;">`nt`, `netntlmv2` y `krb5tgs`/`krb5asrep` son el pan de cada día de un pentest de AD</mark> — enlazan con la [[05 - Autenticación de Windows - NTLM y Kerberos|autenticación de Windows]].

# Sesiones, paralelismo y reanudación

Los trabajos largos hay que gestionarlos:

```shell-session
$ john --wordlist=rockyou.txt --fork=4 hashes.txt     # 4 procesos en paralelo
$ john --session=eng1 --wordlist=rockyou.txt hashes.txt
$ john --restore=eng1                                  # reanudar tras un corte
```

> [!info]+ ¿John o Hashcat aquí?
> Para los `*2john` y el *single crack*, John es insuperable. Para volúmenes grandes con GPU (miles de NTLM, ataques de máscara), [[00 - Introducción a Hashcat|Hashcat]] es mucho más rápido. En la práctica se usan **los dos**: John para extraer y probar rápido, Hashcat para la fuerza bruta pesada. El arsenal completo, en [[18 - Arsenal de herramientas]] del módulo de contraseñas.
