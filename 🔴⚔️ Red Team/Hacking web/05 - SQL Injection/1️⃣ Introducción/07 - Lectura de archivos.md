---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[06 - Enumeración de la base de datos]]"
Nota siguiente: "[[08 - Escritura de archivos]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Una SQL injection no se limita a leer la base de datos: con los privilegios adecuados puede leer ficheros del servidor —incluido el código fuente de la propia aplicación— y, como veremos en la [[08 - Escritura de archivos|siguiente nota]], escribir una web shell. La lectura de ficheros es más común que la escritura, pero en DBMS modernos ya exige privilegios elevados.

# Privilegios necesarios

En MySQL, leer ficheros requiere que el usuario de la base de datos tenga el privilegio `FILE`. <mark style="background: #FFB8EBA6;">Cada vez más, estos privilegios se reservan a cuentas DBA</mark>, así que el primer paso es averiguar quiénes somos y qué podemos hacer.

## Identificar el usuario actual

```sql
cn' UNION SELECT 1, user(), 3, 4-- -
```

`USER()`, `CURRENT_USER()` o `SELECT user FROM mysql.user` revelan la cuenta. Si devuelve `root@localhost`, es muy probable que sea DBA con todos los privilegios —un escenario óptimo—.

## Comprobar privilegios

Para confirmar privilegios de superusuario:

```sql
cn' UNION SELECT 1, super_priv, 3, 4 FROM mysql.user WHERE user="root"-- -
```

Una `Y` indica superusuario. El detalle completo está en `user_privileges`:

```sql
cn' UNION SELECT 1, grantee, privilege_type, 4 FROM information_schema.user_privileges WHERE grantee="'root'@'localhost'"-- -
```

<mark style="background: #FF5582A6;">Si entre los privilegios aparece `FILE`, podemos leer (y potencialmente escribir) ficheros</mark>.

# `LOAD_FILE()`

La función `LOAD_FILE()` lee el contenido de un fichero; toma como único argumento la ruta:

```sql
cn' UNION SELECT 1, LOAD_FILE("/etc/passwd"), 3, 4-- -
```

> [!warning]+
> Dos condiciones adicionales limitan la lectura: el **usuario del SO** que ejecuta MySQL debe tener permiso de lectura sobre el fichero, y la variable `secure_file_priv` (detallada en la [[08 - Escritura de archivos|siguiente nota]]) debe permitirlo. <mark style="background: #8000E1A6;">En instalaciones modernas de MySQL, `secure_file_priv` suele restringir la lectura a un directorio concreto o desactivarla del todo</mark>, por lo que `LOAD_FILE()` arbitrario funciona con menos frecuencia que hace años —MariaDB, en cambio, la deja abierta por defecto—.

# Leer el código fuente: el verdadero premio

Leer `/etc/passwd` confirma la capacidad, pero el objetivo real suele ser el **código fuente** de la aplicación. Conociendo la página actual (`search.php`) y el webroot por defecto de Apache (`/var/www/html`):

```sql
cn' UNION SELECT 1, LOAD_FILE("/var/www/html/search.php"), 3, 4-- -
```

> [!important]+
> El navegador renderiza el HTML, así que el código PHP no se ve directamente: hay que abrir el **código fuente de la página** (`Ctrl + U`) para leerlo. <mark style="background: #FFB86CA6;">El código fuente revela las credenciales de conexión a la base de datos, rutas internas y, a menudo, más vulnerabilidades</mark> —convirtiendo una SQLi a ciegas en una caja blanca—.

> [!info]+
> **Ficheros de alto valor** para leer vía SQLi, más allá del source: configuraciones con credenciales (`/var/www/html/config.php`, `.env`, `wp-config.php`), claves SSH (`/home/<user>/.ssh/id_rsa`), configuración del servidor web (`/etc/apache2/apache2.conf`, `/etc/nginx/nginx.conf`) para localizar el webroot, e historiales (`.bash_history`). En entornos containerizados, `/proc/self/environ` suele filtrar variables de entorno con secretos.

> [!warning]+
> En 2026, la lectura arbitraria de ficheros vía SQLi es **poco habitual**: requiere cuenta con `FILE` (rara en apps bien configuradas, que usan una cuenta de mínimos privilegios) y un `secure_file_priv` permisivo. Cuando se da, suele ser en despliegues legacy o mal endurecidos —pero el impacto, leer cualquier fichero del sistema, lo hace prioritario de comprobar—.

Si además de leer podemos **escribir**, la SQLi escala a ejecución de comandos en el servidor: [[08 - Escritura de archivos]].
