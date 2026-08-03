---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Con la mecánica de UNION clara, la inyección práctica sigue tres pasos: averiguar cuántas columnas devuelve la consulta, identificar cuáles son visibles en la respuesta, y…"
Fecha de actualización: 2026-06-04
Nota previa: "[[04 - La cláusula UNION]]"
Nota siguiente: "[[06 - Enumeración de la base de datos]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Con la [[04 - La cláusula UNION|mecánica de `UNION`]] clara, la inyección práctica sigue tres pasos: averiguar **cuántas columnas** devuelve la consulta, identificar **cuáles son visibles** en la respuesta, y dirigir ahí la extracción. El escenario ideal es un parámetro cuyo resultado se imprime en la página —un buscador, un listado— donde una comilla provoca un error, confirmando la inyección según la [[01 - Detección de SQL Injection|metodología de detección]].

# Detectar el número de columnas

`UNION` exige que ambos `SELECT` tengan el mismo número de columnas, así que primero hay que contarlas. Dos métodos:

## Método `ORDER BY`

Se ordena por número de columna, incrementando hasta que el motor falla porque la columna no existe:

```sql
' ORDER BY 1-- -
' ORDER BY 2-- -
' ORDER BY 3-- -
' ORDER BY 4-- -   -- OK
' ORDER BY 5-- -   -- ERROR: Unknown column '5' in 'order clause'
```

<mark style="background: #ADCCFFA6;">El último número que funciona es el total de columnas</mark>. Si falla en `5`, la tabla tiene 4. Este método **devuelve resultados hasta que aparece el error**.

## Método `UNION SELECT`

Se inyecta un `UNION` con un número creciente de columnas de relleno hasta que la consulta deja de fallar:

```sql
cn' UNION SELECT 1,2,3-- -      -- ERROR: different number of columns
cn' UNION SELECT 1,2,3,4-- -    -- OK: 4 columnas
```

A la inversa del anterior: **da error hasta que aciertas**. <mark style="background: #FFB8EBA6;">`ORDER BY` suele ser preferible para contar</mark> porque genera menos ruido (no introduce datos nuevos) y funciona aunque los tipos de columna sean estrictos; el método `UNION` confirma además que la inyección `UNION` es viable.

# Localizar las columnas visibles

Una consulta puede devolver varias columnas pero la aplicación imprimir solo algunas. <mark style="background: #FF5582A6;">Si colocamos el payload en una columna que no se muestra, no veremos su salida</mark>. Por eso, tras conocer el número de columnas, se inyecta con marcadores numéricos para ver cuáles se reflejan:

```sql
cn' UNION SELECT 1,2,3,4-- -
```

Si en la página aparecen `2`, `3` y `4` pero no `1`, esas tres posiciones son visibles y la `1` no (típico de un campo `id` que la app usa internamente pero no muestra). <mark style="background: #8000E1A6;">Esta es la ventaja de rellenar con números: actúan como marcadores de posición</mark> que revelan dónde escribir. La regla de oro: **no pongas el payload en una columna no visible** (frecuentemente la primera).

> [!info]+
> En motores estrictos (MSSQL, PostgreSQL) los números pueden chocar con columnas de tipo texto. La táctica robusta es contar y tipar con `NULL` (`UNION SELECT NULL,NULL,NULL,NULL`) y, una vez localizada una posición visible y de tipo compatible, sustituir ahí el `NULL` por un marcador o por el dato real.

# Confirmar extracción real

Localizada una columna visible, se prueba que podemos sacar datos reales —no solo números— colocando una función del motor en su lugar. `@@version` (o `VERSION()`) es el test estándar y además hace `fingerprinting`:

```sql
cn' UNION SELECT 1,@@version,3,4-- -
```

```text
| 10.3.22-MariaDB-1ubuntu1 | 3 | 4 |
```

<mark style="background: #FFB86CA6;">La respuesta no solo confirma la extracción: revela el motor y versión exactos</mark> (aquí MariaDB 10.3.22), lo que decide la sintaxis de toda la enumeración posterior.

> [!warning]+
> En 2026, una `UNION` injection con salida directa es cada vez más rara: los WAF detectan la palabra `UNION SELECT` con firmas básicas, y muchas apps ocultan errores. Cuando el conteo por `ORDER BY` funciona pero la salida no se refleja, probablemente estás ante una inyección **a ciegas** (boolean o time-based) y debes cambiar de enfoque hacia [[01 - Introducción a Blind SQL Injection|Blind SQLi]]. Si el `UNION SELECT` se bloquea pero la inyección existe, toca [[05 - Bypass de caracteres comunes|evadir el filtro]] (`UNION/**/SELECT`, mayúsculas mixtas, `/*!UNION*/`).

Con la posición de inyección fijada y el motor identificado, el siguiente paso es mapear y volcar el contenido de la base de datos: [[06 - Enumeración de la base de datos]].
