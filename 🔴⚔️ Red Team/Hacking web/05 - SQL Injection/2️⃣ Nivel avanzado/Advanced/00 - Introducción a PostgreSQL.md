---
tags:
  - Web/Red-Team
  - SQLi
  - Introduccion
Fecha de actualización: 2026-06-04
Nota previa:
Nota siguiente: "[[01 - Decompilación de archivos Java]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

El módulo de SQLi avanzado explora técnicas modernas (error-based, second-order, bypass de filtros) y ataques específicos de **PostgreSQL**, todo desde un enfoque **white-box**: tenemos acceso al código (o al binario) de la aplicación. PostgreSQL es el tercer motor del path, tras [[🐬 MySQL|MySQL]] y [[00 - Introducción a MSSQL|MSSQL]]; conocer su dialecto cierra el trío de motores que cubren casi toda la web.

# Dialecto PostgreSQL: lo que cambia

PostgreSQL tiene particularidades que afectan a cada payload:

| Operación | PostgreSQL | Comparación |
| --------- | ---------- | ----------- |
| Concatenar | `'a' \|\| 'b'` | MSSQL usa `+`, MySQL espacios/`CONCAT` |
| Limitar filas | `LIMIT 5` | Como MySQL (MSSQL usa `TOP`) |
| Versión | `version()` | — |
| Base / usuario actual | `current_database()` / `current_user` | — |
| Espera (time-based) | `pg_sleep(5)` | MySQL `SLEEP`, MSSQL `WAITFOR` |
| Comentarios | `--`, `/* */` | Sin `#` |
| Stacked queries | **Sí, por defecto** | Como MSSQL |
| Cadena literal especial | `$$texto$$` (dollar quoting) | Propio de PG |

> [!important]+
> Dos rasgos de PostgreSQL son oro para la explotación: <mark style="background: #FF5582A6;">soporta consultas apiladas y el *dollar quoting* (`$$...$$`)</mark>. El dollar quoting permite escribir cadenas sin comillas simples —`$$texto$$` equivale a `'texto'`—, lo que [[05 - Bypass de caracteres comunes|evade filtros]] que bloquean la comilla. Y las stacked queries habilitan la [[09 - PostgreSQL ejecución de comandos|ejecución de comandos]] vía `COPY ... FROM PROGRAM`.

# Interactuar con PostgreSQL

## `psql` (CLI — la del pentester)

El cliente de línea de comandos oficial. Se instala con `postgresql-client` y conecta así (puerto por defecto **5432**):

```shell-session
$ psql -h 127.0.0.1 -p 5432 -U acdbuser acmecorp
Password for user acdbuser:
acmecorp=>
```

Comandos meta de `psql` (con backslash, no son SQL):

| Comando | Acción |
| ------- | ------ |
| `\l` | Listar bases de datos |
| `\c <base>` | Cambiar de base |
| `\dt` | Listar tablas de la base actual |
| `\d <tabla>` | Describir una tabla |

Las consultas SQL normales terminan en `;`:

```shell-session
acmecorp=> SELECT first_name, last_name, email FROM employees LIMIT 5;
```

## pgAdmin4 (GUI)

Interfaz gráfica para administrar PostgreSQL. Cómoda para explorar bases y tablas visualmente cuando se tienen credenciales; pide una *master password* local para proteger las credenciales guardadas. En explotación remota, `psql` y la inyección mandan.

> [!info]+
> Igual que MySQL y MSSQL, PostgreSQL implementa `INFORMATION_SCHEMA` (estandarizado), así que la [[06 - Enumeración de la base de datos|enumeración]] de tablas y columnas es portable. PostgreSQL añade además los catálogos del sistema `pg_catalog` (`pg_tables`, `pg_user`, `pg_roles`), a veces más cómodos.

# El enfoque white-box

<mark style="background: #ADCCFFA6;">A diferencia de los módulos anteriores (caja negra), aquí partimos del código</mark>. En un assessment white-box el cliente entrega el fuente o el binario; nuestro trabajo es leerlo para encontrar las consultas vulnerables directamente, en lugar de inferirlas a ciegas. <mark style="background: #8000E1A6;">Es mucho más eficiente: vemos exactamente cómo se construye cada query y qué filtros se aplican</mark>, lo que permite diseñar el payload exacto y descubrir vulnerabilidades sutiles (second-order) que la caja negra ocultaría.

La aplicación objetivo del módulo, `BlueBird`, es una web Java Spring Boot con PostgreSQL, de la que solo tenemos el binario compilado. El primer paso white-box es recuperar su código fuente: [[01 - Decompilación de archivos Java]].
