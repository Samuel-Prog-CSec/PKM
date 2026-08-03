---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Descripción: "A veces no puedes soltar herramientas: EDR agresivo, AppLocker, Constrained Language Mode o un host sin salida a internet. *Living off the land* (LotL) es enumerar el dominio…"
Fecha de actualización: 2026-07-21
Nota previa: "[[04 - Enumeración con credenciales]]"
Nota siguiente: "[[06 - Envenenamiento LLMNR y NBT-NS]]"
Area: "[[AD Enumeración.base|Enumeración]]"
---
---

A veces no puedes soltar herramientas: EDR agresivo, AppLocker, `Constrained Language Mode` o un host sin salida a internet. <mark style="background: #ADCCFFA6;">*Living off the land* (LotL) es enumerar el dominio con lo que Windows ya trae</mark> —binarios firmados y cmdlets nativos— para no dejar artefactos ni despertar al AV.

# Reconocimiento con comandos nativos

```cmd
whoami /all
systeminfo
ipconfig /all
arp -a
route print
qwinsta
```

`whoami /all` da privilegios y grupos; `arp -a` y `route print`, vecinos y rutas hacia otras redes; `qwinsta`, otras sesiones activas en el host (cuidado con quién te ve).

# Comandos `net`

```cmd
net user /domain
net group "Domain Admins" /domain
net accounts /domain
```

<mark style="background: #FFB86CA6;">`net accounts /domain` devuelve la política de bloqueo</mark> — imprescindible antes de un [[07 - Password Spraying - visión general|spraying]] para no bloquear cuentas. Truco: si `net` está monitorizado, `net1` hace lo mismo y a veces pasa desapercibido.

# `dsquery`

`dsquery` lanza consultas LDAP nativas, con toda la potencia de los filtros crudos:

```cmd
dsquery user
dsquery * -filter "(userAccountControl:1.2.840.113556.1.4.803:=4194304)" -attr samaccountname
```

<mark style="background: #FF5582A6;">Ese segundo filtro (`DONT_REQ_PREAUTH`, bit `4194304`) lista cuentas vulnerables a AS-REP roasting</mark> sin cargar una sola herramienta externa; variando el bit encuentras `PASSWD_NOTREQD` u otros *quick wins*.

# WMI y PowerShell

`wmic` (en desuso pero aún presente) y su relevo `Get-CimInstance` consultan el sistema; PowerShell accede a LDAP vía `[adsisearcher]` sin módulos. <mark style="background: #FFB8EBA6;">Ojo con la telemetría</mark>: el *Script Block Logging* y `AMSI` modernos registran casi todo en PowerShell 5+. El *downgrade* a v2 (`powershell -v 2`) evita ese logging, pero requiere `.NET 3.5` + la *feature* PSv2 Engine (ninguno por defecto); en 2026 solo aplica a hosts legacy.

> [!warning]+ LotL no es invisible, es "menos evidente"
> No dejar binarios ≠ no dejar rastro. Un usuario de RRHH ejecutando `dsquery` o `net group "Domain Admins"` es una anomalía de comportamiento que un buen SOC marca. LotL reduce la superficie de detección, no la elimina. Las defensas del host las viste en [[03 - Enumeración de controles de seguridad]]; la telemetría concreta, en [[25 - Detección y evasión en AD]].
