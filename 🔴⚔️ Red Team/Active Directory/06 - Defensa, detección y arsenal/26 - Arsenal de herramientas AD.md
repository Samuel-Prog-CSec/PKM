---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[25 - Detección y evasión en AD]]"
Nota siguiente:
Area: "[[AD Defensa y arsenal.base|Defensa y arsenal]]"
---
---

El set profesional 2026 para atacar AD, por fase. <mark style="background: #ADCCFFA6;">La regla del 90%: `NetExec` + `BloodHound` + `impacket` + `Rubeus` cubren casi cualquier engagement AD</mark>; el resto son especialistas. Con ⭐ los imprescindibles.

# Enumeración

| Herramienta | Uso | Nota |
| --- | --- | --- |
| ⭐ `NetExec` (`nxc`) | barrido, enum de usuarios/grupos/shares, exec | <mark style="background: #FFB86CA6;">sustituye a `CrackMapExec` (abandonado 2023)</mark> |
| ⭐ `BloodHound CE` + SharpHound / bloodhound-ce-python | grafo de rutas a DA | CE, no el legacy |
| `PowerView` / `SharpView` | enum ofensiva desde Windows | |
| `ldapsearch` / `ldeep` / `windapsearch` | consultas LDAP crudas | |
| `enum4linux-ng` | enum sin credenciales | reescritura del viejo `enum4linux` |
| `Snaffler` | credenciales en *shares* | |
| `Kerbrute` | enum de usuarios vía Kerberos | sigiloso |

# Acceso inicial y credenciales

| Herramienta | Uso |
| --- | --- |
| ⭐ `Responder` / `InveighZero` | envenenamiento LLMNR/NBT-NS |
| ⭐ `mitm6` + `ntlmrelayx` | relay IPv6/NTLM (combo potente) |
| `Coercer` | coacción de autenticación (PetitPotam, PrinterBug, DFSCoerce) |
| `DomainPasswordSpray` | spraying desde Windows |
| ⭐ `hashcat` / `john` | cracking offline |

# Kerberos y post-explotación

| Herramienta | Uso |
| --- | --- |
| ⭐ `impacket` | GetUserSPNs, GetNPUsers, secretsdump, ticketer, psexec/wmiexec, raiseChild |
| ⭐ `Rubeus` | kerberoasting, PtT, golden/silver/**diamond** tickets (Windows) |
| `mimikatz` | volcado de credenciales, DCSync, golden ticket |
| `evil-winrm` | shell WinRM desde Linux |

# Abuso de ACLs y ADCS

| Herramienta | Uso |
| --- | --- |
| `bloodyAD` / `dacledit.py` | modificar ACLs/objetos desde Linux |
| `pywhisker` / `Whisker` | *shadow credentials* |
| ⭐ `Certipy` | toda la familia ADCS (`ESC1`-`ESC17`) |

# Auditoría (lado defensivo)

`PingCastle`, `Group3r`, `ADRecon`, `AD Explorer`, `Purple Knight` — miden la postura del dominio ([[24 - Auditoría avanzada en AD]]).

> [!info]+ La migración que no debes olvidar
> Si una guía (incluida la de HTB) usa `crackmapexec`, cámbialo por <mark style="background: #FF5582A6;">`netexec` (`nxc`)</mark>: misma sintaxis, mantenido y con más protocolos. Es el cambio de tooling más importante en AD de los últimos años.

Con esto se cierra el módulo. El recorrido completo arranca en [[00 - Introducción a la enumeración y ataques en AD]].
