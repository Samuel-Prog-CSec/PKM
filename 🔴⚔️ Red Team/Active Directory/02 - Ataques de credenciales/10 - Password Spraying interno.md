---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Explotacion
Descripción: "Con la lista de usuarios (09 - Construir la lista de usuarios objetivo) y la política (08 - Enumerar políticas de contraseñas) en la mano, toca rociar — respetando siempre la…"
Fecha de actualización: 2026-07-21
Nota previa: "[[09 - Construir la lista de usuarios objetivo]]"
Nota siguiente: "[[11 - Kerberoasting]]"
Area: "[[AD Ataques de credenciales.base|Ataques de credenciales]]"
---
---

Con la lista de usuarios ([[09 - Construir la lista de usuarios objetivo]]) y la política ([[08 - Enumerar políticas de contraseñas]]) en la mano, toca rociar — respetando siempre la ventana de observación para no bloquear nada.

# Desde Linux

La opción más sigilosa es Kerberos, con `Kerbrute`:

```shell-session
$ kerbrute passwordspray -d inlanefreight.local --dc 172.16.5.5 valid_users.txt Welcome1
```

Con SMB, `NetExec` rocía y filtra los aciertos:

```shell-session
$ nxc smb 172.16.5.5 -u valid_users.txt -p 'Welcome1' --continue-on-success | grep '[+]'
```

<mark style="background: #FFB86CA6;">Cada `[+]` es un usuario:contraseña válido</mark>; un `Pwn3d!` significa además admin local en ese host.

# Desde Windows

`DomainPasswordSpray.ps1` saca la lista de usuarios del propio dominio y rocía:

```powershell
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password Welcome1 -OutFile hits.txt
```

<mark style="background: #FFB8EBA6;">Por defecto lee la política del dominio para no bloquear cuentas</mark>, pero verifícalo: un `-Force` mal puesto se pasa del umbral.

# Reutilización del admin local

Si capturaste el hash del administrador local de un equipo (SAM, LSASS), <mark style="background: #FF5582A6;">rociarlo con `--local-auth` contra toda la red revela dónde se reutilizó</mark> — clásico por imágenes clonadas:

```shell-session
$ nxc smb 172.16.5.0/23 -u administrator -H <hash> --local-auth | grep '[+]'
```

Esto ya es *Pass-the-Hash* de admin local; el detalle en [[13 - Pass the Hash (PtH)]].

> [!warning]+ La firma del spraying
> Muchos `4625` (fallo de logon) desde un mismo origen en poco tiempo es el patrón que todo SIEM busca. <mark style="background: #ADCCFFA6;">Reparte en el tiempo, respeta la ventana</mark>, y si puedes usa Kerberos (un fallo de contraseña genera `4771` — *Kerberos pre-authentication failed*, código `0x18` —, **no** `4768`, que es el patrón de la *enumeración* de usuarios inexistentes). Kerberos suele estar menos vigilado que el `4625` de SMB, pero los SOC modernos cazan ráfagas de `4771`. Telemetría completa en [[25 - Detección y evasión en AD]].

Un acierto reabre el bucle: con la nueva credencial, vuelve a [[04 - Enumeración con credenciales]] con más visibilidad.
