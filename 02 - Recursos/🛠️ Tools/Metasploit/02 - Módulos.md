---
tags:
  - Pentesting/Explotacion
  - Metasploit
Descripción: "Un módulo es cada pieza ejecutable de Metasploit"
Fecha de actualización: 2026-07-18
Nota previa: "[[01 - MSFconsole]]"
Nota siguiente: "[[03 - Targets]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

Un `módulo` es cada pieza ejecutable de Metasploit. Entender su **taxonomía** y cómo **leer** uno es lo que convierte el framework de una caja negra en una herramienta que se maneja con criterio.

# La nomenclatura: la ruta ES la descripción

El nombre completo de un módulo codifica qué hace y contra qué:

```text
exploit/windows/smb/ms17_010_eternalblue
   │       │      │            │
   │       │      │            └── nombre concreto del módulo
   │       │      └── servicio / protocolo objetivo
   │       └── plataforma objetivo
   └── tipo de módulo
```

<mark style="background: #8000E1A6;">Leer el nombre te dice de un vistazo si un módulo aplica</mark>: `auxiliary/scanner/ssh/ssh_login` es un escáner de login SSH; `post/windows/gather/hashdump` recolecta hashes en Windows tras el acceso.

# Las categorías en la práctica

| Tipo | Da shell | Ejemplos reales |
| --- | --- | --- |
| `exploit` | Sí | `windows/smb/ms17_010_eternalblue`, `multi/http/...` |
| `auxiliary` | No | `scanner/smb/smb_version`, `scanner/ssh/ssh_login` (brute), `admin/...`, `dos/...` |
| `post` | — (ya hay sesión) | `windows/gather/hashdump`, `multi/recon/local_exploit_suggester` |
| `payload` | Es la shell | Ver [[04 - Payloads en Metasploit]] |
| `encoder` | No | `x86/shikata_ga_nai` (adaptación de charset, no evasión) |
| `nop` | No | Generadores de `NOP sleds` |
| `evasion` | Genera artefacto | Intentos de payload anti-AV (con matices, ver [[12 - Detección y evasión]]) |

## Auxiliary: el caballo de batalla infravalorado

<mark style="background: #FF5582A6;">Los `auxiliary` no entregan shell, pero hacen gran parte del trabajo real</mark>: escanean versiones, hacen brute-force, capturan hashes, enumeran. Encajan directamente con la fase de [[00 - Principios y metodología de enumeración|enumeración]] y a menudo son la vía más rápida:

```shell-session
msf6 > use auxiliary/scanner/smb/smb_version
msf6 auxiliary(...) > set RHOSTS 10.10.10.0/24
msf6 auxiliary(...) > run                       # versión SMB de toda la subred
```

## Post: después de la sesión

Los `post` operan **sobre una sesión existente**. Uno imprescindible es el *local exploit suggester*, que analiza el host comprometido y sugiere exploits de escalada:

```shell-session
msf6 > use post/multi/recon/local_exploit_suggester
msf6 post(...) > set SESSION 1
msf6 post(...) > run
```

# Leer un módulo: `info` y opciones

Antes de lanzar nada, `info` da la ficha completa — descripción, autor, plataformas, **referencias (CVE)**, `disclosure date` y, crucialmente, el **rank**:

```shell-session
msf6 exploit(...) > info
msf6 exploit(...) > show options       # parámetros (Required=yes son obligatorios)
msf6 exploit(...) > show advanced      # opciones avanzadas (timeouts, evasión...)
msf6 exploit(...) > show missing       # solo lo que falta por configurar
```

<mark style="background: #FFB8EBA6;">`show advanced` esconde ajustes valiosos</mark> — por ejemplo opciones de OPSEC, `SSL`, `HttpUserAgent` o timings que ayudan a reducir la huella del módulo.

# El ranking de fiabilidad

Cada exploit declara cómo de fiable y seguro es. Es información de seguridad operacional, no un detalle:

| Rank | Significado |
| --- | --- |
| `excellent` | No crashea el servicio. El ideal. |
| `great` / `good` | Fiable, con objetivo autodetectado o por defecto razonable. |
| `normal` / `average` | Funciona, fiabilidad media. |
| `low` / `manual` | Difícil, poco fiable **o puede tumbar el objetivo**. |

> [!warning]+ Rank bajo = riesgo de DoS
> <mark style="background: #FFB86CA6;">Un exploit `low`/`manual` puede dejar el servicio caído</mark> si falla. En un engagement real eso es un incidente que interrumpe al cliente. Prioriza `excellent`/`great`, y si solo hay uno de rank bajo, coordina la ventana con el cliente antes de lanzarlo.

Con el módulo elegido y comprendido, queda afinar contra **qué versión concreta** del objetivo apunta: los [[03 - Targets|targets]].
