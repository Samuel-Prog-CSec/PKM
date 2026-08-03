---
tags:
  - Web/Red-Team
  - SQLi
  - Introduccion
  - Tipo/Introduccion
Descripción: "El módulo de SQLi a ciegas usa Microsoft SQL Server (MSSQL) como motor de referencia, así que conviene conocer sus particularidades antes de atacarlo"
Fecha de actualización: 2026-06-04
Nota previa:
Nota siguiente: "[[01 - Introducción a Blind SQL Injection]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

El módulo de SQLi a ciegas usa **Microsoft SQL Server (MSSQL)** como motor de referencia, así que conviene conocer sus particularidades antes de atacarlo. MSSQL es uno de los cinco RDBMS más desplegados (junto a Oracle, MySQL, PostgreSQL e IBM Db2) y, como SQL está estandarizado, <mark style="background: #ADCCFFA6;">las técnicas de [[01 - Introducción a Blind SQL Injection|blind SQLi]] aprendidas aquí se adaptan con cambios mínimos a otros motores</mark>. Esta nota cubre cómo interactuar con MSSQL y sus diferencias de dialecto frente a [[🐬 MySQL|MySQL]].

# T-SQL: diferencias clave con MySQL

MSSQL usa `Transact-SQL` (T-SQL). Las divergencias que más afectan a un payload:

| Operación | MySQL | MSSQL (T-SQL) |
| --------- | ----- | ------------- |
| Versión | `@@version` / `VERSION()` | `@@version` |
| Limitar filas | `LIMIT 5` | `TOP 5` (o `OFFSET ... FETCH`) |
| Concatenar | `CONCAT(a,b)` / `a` `b` | `a + b` / `CONCAT(a,b)` |
| Comentario | `-- `, `#`, `/**/` | `--`, `/**/` (sin `#`) |
| Base actual | `DATABASE()` | `DB_NAME()` |
| Usuario actual | `USER()` | `SYSTEM_USER` / `USER_NAME()` |
| Espera (time-based) | `SLEEP(5)` | `WAITFOR DELAY '0:0:5'` |
| Stacked queries | No (API estándar) | **Sí, por defecto** |

<mark style="background: #FFB86CA6;">Dos diferencias son críticas para la explotación</mark>: MSSQL no tiene `#` como comentario (hay que usar `--`), y **soporta consultas apiladas** (`;`), lo que habilita ataques imposibles en MySQL como ejecutar `xp_cmdshell` tras la query vulnerable.

# Conectarse a MSSQL

## `impacket-mssqlclient` (Linux — la del pentester)

La herramienta de referencia desde Linux es `mssqlclient.py` de [Impacket](https://github.com/fortra/impacket), preinstalada en Kali/Pwnbox:

```shell-session
$ impacket-mssqlclient thomas:'TopSecretPassword23!'@SQL01 -db bsqlintro
SQL> SELECT * FROM INFORMATION_SCHEMA.TABLES;
```

<mark style="background: #FF5582A6;">Al ser una herramienta ofensiva, trae atajos como `enable_xp_cmdshell`</mark> para activar y usar la ejecución de comandos directamente:

```shell-session
SQL> enable_xp_cmdshell
SQL> xp_cmdshell whoami
nt service\mssqlserver
```

Esto es oro cuando ya tienes credenciales; con una SQLi, el equivalente se logra inyectando, como veremos en [[10 - MSSQL ejecución de comandos con xp_cmdshell|RCE vía xp_cmdshell]].

## `sqlcmd` (Windows, línea de comandos)

La utilidad nativa de Microsoft. El separador de lotes es `GO` (no `;`):

```powershell-session
PS> sqlcmd -S 'SQL01' -U 'thomas' -P 'TopSecretPassword23!' -d bsqlintro -W
1> SELECT TOP 5 firstName, lastName FROM users;
2> GO
```

El flag `-W` recorta espacios sobrantes y hace la salida más legible.

## SQL Server Management Studio (SSMS, GUI)

La interfaz gráfica de Microsoft para administrar MSSQL. Útil para explorar bases y tablas visualmente cuando se dispone de credenciales y acceso, pero en explotación remota la línea de comandos manda.

> [!info]+
> `INFORMATION_SCHEMA` existe también en MSSQL (estandarizado), así que la enumeración de tablas y columnas se hace igual que en [[06 - Enumeración de la base de datos|MySQL]]. MSSQL añade además vistas propias del sistema (`sys.databases`, `sys.tables`, `sys.columns`) que a veces son más cómodas y menos vigiladas por WAFs que `INFORMATION_SCHEMA`.

> [!important]+
> Este módulo es **avanzado**: asume soltura construyendo consultas SQL. <mark style="background: #8000E1A6;">La diferencia frente a la SQLi clásica no es la sintaxis, sino que aquí **no veremos el resultado** de nuestras consultas</mark> y tendremos que inferirlo. Ese cambio de paradigma es lo que se introduce a continuación: [[01 - Introducción a Blind SQL Injection]].
