---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Descripción: "Con credenciales válidas, el siguiente paso suele ser ejecutar en otros hosts"
Fecha de actualización: 2026-07-21
Nota previa: "[[15 - DCSync]]"
Nota siguiente: "[[17 - El problema Double Hop de Kerberos]]"
Area: "[[AD Escalada y movimiento.base|Escalada y movimiento]]"
---
---

Con credenciales válidas, el siguiente paso suele ser **ejecutar en otros hosts**. AD ofrece varias vías de acceso remoto según a qué grupos pertenezca tu usuario; <mark style="background: #ADCCFFA6;">BloodHound las marca como aristas `CanRDP`, `CanPSRemote` y `SQLAdmin`</mark> — mira ahí antes de probar a ciegas.

# RDP

Pertenecer a `Remote Desktop Users` en un host da escritorio remoto:

```shell-session
$ xfreerdp /u:forend /p:Klmcargo2 /d:inlanefreight.local /v:172.16.5.25
```

# WinRM

Pertenecer a `Remote Management Users` da ejecución remota vía WinRM. Desde Linux, <mark style="background: #FFB86CA6;">`evil-winrm` es la herramienta estándar</mark>:

```shell-session
$ evil-winrm -i 172.16.5.25 -u forend -p Klmcargo2
```

Desde Windows, `Enter-PSSession -ComputerName ... -Credential ...`. Ojo: WinRM sufre el [[17 - El problema Double Hop de Kerberos|problema del double hop]].

# MSSQL

Si tu usuario es `sysadmin` en un SQL Server (<mark style="background: #FFB8EBA6;">frecuente para cuentas de servicio</mark>), `xp_cmdshell` da <mark style="background: #FF5582A6;">RCE como la cuenta de servicio</mark>:

```shell-session
$ mssqlclient.py inlanefreight.local/forend:Klmcargo2@172.16.5.25 -windows-auth
SQL> enable_xp_cmdshell
SQL> xp_cmdshell whoami
```

`PowerUpSQL` (Windows) enumera instancias y derechos `SQLAdmin`; `nxc mssql` hace lo propio desde Linux. La enumeración a fondo de MSSQL está en [[12 - MSSQL]], y los *SQL links* entre servidores son una vía de pivoting adicional.

> [!success]+ Empieza por el grafo
> Antes de probar accesos, la *query* de BloodHound *"Find Computers where Domain Users can RDP"* o las aristas `CanPSRemote`/`SQLAdmin` te dicen exactamente dónde tienes ejecución con las credenciales actuales. Menos ruido, cero adivinar.

> [!warning]+ Huella
> El acceso legítimo también deja rastro: `4624` (logon tipo 10 por RDP, tipo 3 por WinRM), el log operacional de WinRM y, sobre todo, **activar `xp_cmdshell`** (deshabilitado por defecto desde SQL Server 2005) es un evento de alta fidelidad que audita cualquier SIEM. Usa cuentas ya validadas en el grafo y evita `xp_cmdshell` si hay otra vía. Ver [[25 - Detección y evasión en AD]].
