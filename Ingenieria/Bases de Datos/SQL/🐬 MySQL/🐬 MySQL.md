---
tags:
  - Bases-de-Datos
  - SQL
Descripción: "MySQL y su fork MariaDB son los RDBMS de referencia para aprender SQL injection: son los más desplegados en la web (todo el stack LAMP/LEMP, WordPress, etc.) y su dialecto es el…"
Fecha de actualización: 2026-06-04
Nota previa: "[[Introducción a las bases de datos]]"
Nota siguiente: "[[💬 Sentencias SQL]]"
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

<mark style="background: #ADCCFFA6;">MySQL y su fork MariaDB son los `RDBMS` de referencia para aprender SQL injection</mark>: son los más desplegados en la web (todo el stack LAMP/LEMP, WordPress, etc.) y su dialecto es el que asumen la mayoría de payloads "genéricos". Dominar la sintaxis desde el lado del desarrollador es imprescindible para atacarla: un inyector escribe exactamente las mismas consultas que un programador, solo que desde el lado equivocado del parámetro. Esta nota cubre los fundamentos de [[Introducción a las bases de datos|MySQL como DBMS]]; la manipulación de datos vive en [[💬 Sentencias SQL]].

# SQL: estándar y dialecto

La sintaxis SQL varía entre `RDBMS`, pero todos siguen el estándar ISO/IEC 9075. Los ejemplos asumen sintaxis **MySQL/MariaDB**. Con SQL se puede recuperar, actualizar y borrar datos, crear tablas y bases de datos, gestionar usuarios y asignar permisos. <mark style="background: #FFB8EBA6;">Esas dos últimas capacidades —gestión de usuarios y permisos— son las que convierten un SQLi en algo más que robo de datos</mark>: si la cuenta de la aplicación las tiene, el atacante también.

# Conexión: el cliente `mysql`

La utilidad `mysql` autentica e interactúa con la base de datos. `-u` indica el usuario y `-p` la contraseña. <mark style="background: #FF5582A6;">El flag `-p` se pasa vacío para que la contraseña se solicite por prompt y no quede registrada en `bash_history`</mark> —un detalle operativo que también aplica a tu propia higiene durante un engagement.

```shell-session
$ mysql -u root -p
Enter password: <password>
mysql>
```

Sin host explícito, conecta a `localhost`. Para un host y puerto remotos se usan `-h` y `-P`:

```shell-session
$ mysql -u root -h 10.10.10.5 -P 3306 -p
```

> [!warning]+
> El puerto por defecto de MySQL/MariaDB es el **3306**. Ojo con las mayúsculas: `-P` (mayúscula) es el puerto, `-p` (minúscula) es la contraseña; confundirlas es un error clásico. Además, **no debe haber espacio** entre `-p` y la contraseña si la pasas inline (`-pPassword123`).

> [!info]+
> **Óptica de pentest**: un `3306` abierto a Internet (búscalo en Shodan/`nmap -p3306`) es un hallazgo por sí mismo. Tras conectar, `SELECT VERSION();` revela motor y versión exactos —`fingerprinting` que decide qué payloads usar—. Distinguir MySQL de MariaDB importa: comparten dialecto casi por completo, pero divergen en funciones concretas y en el comportamiento de ciertos vectores de explotación.

# Crear y seleccionar bases de datos

Tras autenticar, las consultas SQL interactúan con el DBMS. `CREATE DATABASE` crea una base de datos nueva; cada consulta de línea de comandos **termina en punto y coma**.

```sql
CREATE DATABASE users;
```

`SHOW DATABASES` lista las bases existentes y `USE` cambia a una de ellas:

```shell-session
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| users              |
+--------------------+

mysql> USE users;
Database changed
```

> [!important]+
> Las cuatro primeras bases —`information_schema`, `mysql`, `performance_schema`, `sys`— son **bases del sistema**, presentes en toda instalación. <mark style="background: #FF5582A6;">`information_schema` es la pieza central de la enumeración por SQLi</mark>: contiene los metadatos (nombres de bases, tablas y columnas) que un atacante consulta para mapear la estructura antes de exfiltrar. Volveremos a ella al estudiar la enumeración.

# Tablas

Un DBMS almacena los datos en tablas de filas (horizontales) y columnas (verticales); la intersección es una celda. Cada columna tiene un **tipo de dato** que define qué valores admite (`numbers`, `strings`, `date`, `time`, `binary data`, y tipos específicos del motor). `CREATE TABLE` define una tabla; primero el nombre, luego cada columna como `nombre tipo`, separadas por comas:

```sql
CREATE TABLE logins (
    id INT,
    username VARCHAR(100),
    password VARCHAR(100),
    date_of_joining DATETIME
    );
```

<mark style="background: #FFB8EBA6;">En modo estricto (`STRICT_TRANS_TABLES`, por defecto desde MySQL 5.7.5) un `VARCHAR(100)` rechaza con error las entradas de más de 100 caracteres; sin modo estricto, las **trunca silenciosamente**</mark> —una restricción de longitud que, en un parámetro vulnerable, puede truncar o romper un payload largo (un *gotcha* a recordar al construir inyecciones extensas). `SHOW TABLES` lista las tablas de la base actual y `DESCRIBE` muestra su estructura:

```shell-session
mysql> SHOW TABLES;
+-----------------+
| Tables_in_users |
+-----------------+
| logins          |
+-----------------+

mysql> DESCRIBE logins;
+-----------------+--------------+
| Field           | Type         |
+-----------------+--------------+
| id              | int          |
| username        | varchar(100) |
| password        | varchar(100) |
| date_of_joining | datetime     |
+-----------------+--------------+
```

## Propiedades de columnas

Dentro de `CREATE TABLE` se configuran propiedades por columna que conviene reconocer, porque condicionan cómo se comporta una inyección contra esa tabla:

| Propiedad | Efecto |
| --------- | ------ |
| `AUTO_INCREMENT` | Incrementa el valor en uno por cada inserción (típico en `id`). |
| `NOT NULL` | La columna nunca queda vacía: campo obligatorio. |
| `UNIQUE` | Impide valores duplicados (p. ej. dos usuarios con el mismo `username`). |
| `DEFAULT` | Valor por defecto si no se especifica; p. ej. `DEFAULT NOW()` para la fecha actual. |
| `PRIMARY KEY` | Identifica unívocamente cada registro; clave de las relaciones entre tablas. |

La definición final, combinando todo:

```sql
CREATE TABLE logins (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    date_of_joining DATETIME DEFAULT NOW(),
    PRIMARY KEY (id)
    );
```

> [!important]+
> Las sentencias SQL **no distinguen mayúsculas de minúsculas** (`USE users;` ≡ `use users;`), pero **los nombres de base de datos sí** en muchos sistemas de ficheros: `USE USERS;` falla si la base se llama `users`. Por convención se escriben las palabras clave en mayúscula para legibilidad.

Con la estructura clara, el siguiente paso es manipular los datos —insertar, consultar, filtrar y ordenar— en [[💬 Sentencias SQL]], la base sobre la que se construye toda la lógica que un [[00 - Introducción a SQL Injection|SQL injection]] subvierte.
