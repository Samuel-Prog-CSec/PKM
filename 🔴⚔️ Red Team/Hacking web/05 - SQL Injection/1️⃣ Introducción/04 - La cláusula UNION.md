---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Hasta ahora hemos manipulado la consulta existente"
Fecha de actualización: 2026-06-04
Nota previa: "[[03 - Uso de comentarios]]"
Nota siguiente: "[[05 - Inyección UNION]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Hasta ahora hemos manipulado la consulta existente. El siguiente nivel es **inyectar una consulta `SELECT` completa** que se ejecute junto a la original y vuelque datos de cualquier tabla de la base de datos. La pieza que lo permite es la cláusula `UNION`, base de la inyección `Union`-based —la variante in-band más potente y la que cubre este módulo.

# Qué hace `UNION`

<mark style="background: #ADCCFFA6;">`UNION` combina los resultados de varias sentencias `SELECT` en una sola salida</mark>. Con dos tablas, `ports` y `ships`:

```sql
SELECT * FROM ports UNION SELECT * FROM ships;
```

```shell-session
+----------+-----------+
| code     | city      |
+----------+-----------+
| CN SHA   | Shanghai  |
| SG SIN   | Singapore |
| Morrison | New York  |   <- fila procedente de 'ships'
| ZZ-21    | Shenzhen  |
+----------+-----------+
```

La salida fusiona las filas de ambas tablas. <mark style="background: #8000E1A6;">Aplicado a una inyección, esto significa que podemos "colgar" un `SELECT` propio del original y leer datos de tablas que la consulta legítima nunca tocaría</mark> —credenciales, tokens, lo que sea—.

# Requisito 1: mismo número de columnas

`UNION` solo opera entre `SELECT` con **idéntico número de columnas**. Si no coinciden, el motor lanza un error inequívoco:

```shell-session
mysql> SELECT city FROM ports UNION SELECT * FROM ships;
ERROR 1222 (21000): The used SELECT statements have a different number of columns
```

Ese error es, de hecho, la herramienta que usaremos para **descubrir cuántas columnas** devuelve la consulta original (siguiente nota). Una vez igualado el número, podemos extraer datos de otras tablas. Si la consulta original es:

```sql
SELECT * FROM products WHERE product_id = '1'
```

y `products` tiene dos columnas, inyectamos:

```sql
SELECT * FROM products WHERE product_id = '1' UNION SELECT username, password FROM passwords-- -
```

y obtenemos `username` y `password` de la tabla `passwords`.

# Requisito 2: columnas de relleno cuando no cuadran

Rara vez la tabla que queremos leer tiene tantas columnas como la original. <mark style="background: #FFB8EBA6;">Se rellenan las posiciones sobrantes con datos "basura"</mark> para igualar el conteo. Sirven números o cadenas; el valor de relleno se devuelve tal cual en su columna. Si `products` tiene dos columnas pero solo queremos `username`:

```sql
UNION SELECT username, 2 FROM passwords
```

Con cuatro columnas en la original:

```sql
UNION SELECT username, 2, 3, 4 FROM passwords-- -
```

```shell-session
+-----------+-----------+-----------+-----------+
| product_1 | product_2 | product_3 | product_4 |
+-----------+-----------+-----------+-----------+
|   admin   |    2      |    3      |    4      |
+-----------+-----------+-----------+-----------+
```

El dato útil (`admin`) aparece en la primera posición; los números rellenan el resto.

> [!important]+
> Usar **números** como relleno tiene una ventaja táctica: sirven de **marcadores de posición**. Al ver qué número aparece reflejado en la página sabremos exactamente en qué columna podemos escribir nuestra salida —técnica central de la [[05 - Inyección UNION|inyección UNION]]—.

> [!warning]+
> Los tipos de dato de las columnas unidas deben ser **compatibles**, o el motor falla. MySQL es laxo y suele tolerar mezclas, pero MSSQL y PostgreSQL son estrictos. <mark style="background: #FF5582A6;">La solución universal es rellenar con `NULL`</mark>: `NULL` encaja en cualquier tipo de dato, así que `UNION SELECT NULL, NULL, NULL` evita errores de tipado mientras se determina la estructura. Se cambian los `NULL` por datos reales solo en las posiciones visibles. Es el enfoque recomendado para SQLi avanzada y en motores estrictos.

> [!info]+
> `UNION` (sin más) elimina filas duplicadas; `UNION ALL` las conserva y es ligeramente más rápido. En explotación rara vez importa, pero `UNION ALL` puede sortear algún filtro que solo busca la palabra `UNION` seguida de `SELECT`.

Con la mecánica de `UNION` clara, la inyección práctica consiste en averiguar el número de columnas, localizar cuáles son visibles en la respuesta y dirigir ahí la extracción: [[05 - Inyección UNION]].
