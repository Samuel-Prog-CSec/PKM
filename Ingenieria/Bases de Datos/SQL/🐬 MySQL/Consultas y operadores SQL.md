---
tags:
  - Bases-de-Datos
  - SQL
Descripción: "Controlar *qué* registros devuelve una consulta y *en qué orden* es lo que hacen las cláusulas WHERE, ORDER BY, LIMIT y LIKE junto a los operadores lógicos"
Fecha de actualización: 2026-06-04
Nota previa: "[[💬 Sentencias SQL]]"
Nota siguiente:
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

Controlar *qué* registros devuelve una consulta y *en qué orden* es lo que hacen las cláusulas `WHERE`, `ORDER BY`, `LIMIT` y `LIKE` junto a los operadores lógicos. <mark style="background: #FFB8EBA6;">Son, con diferencia, las piezas que más se manipulan en una SQL injection</mark>: la condición `WHERE` es la que se subvierte para saltarse autenticación, `ORDER BY` la que se abusa para contar columnas, y la precedencia de operadores la que decide si un payload se ejecuta como esperamos. Esta nota cierra los fundamentos de [[💬 Sentencias SQL|SQL]] antes de pasar al ataque.

# `WHERE` — filtrar registros

`WHERE` añade una condición a un `SELECT` (o `UPDATE`/`DELETE`) y devuelve solo los registros que la cumplen:

```sql
SELECT * FROM logins WHERE id > 1;
SELECT * FROM logins WHERE username = 'admin';
```

> [!warning]+
> Los valores de tipo cadena y fecha van **entre comillas** (`'` o `"`); los números, directos. <mark style="background: #FF5582A6;">Ese par de comillas es el corazón de la inyección clásica</mark>: si la entrada del usuario se inserta dentro de las comillas sin sanear, una comilla extra rompe el literal y todo lo que sigue se interpreta como SQL. De ahí que el primer test de detección sea, casi siempre, inyectar una sola comilla.

Manipular la condición `WHERE` para que sea siempre verdadera (`' OR 1=1 -- -`) es la base del bypass de autenticación que se detalla en [[02 - Subvertir la lógica de consulta]].

# `ORDER BY` — ordenar resultados

Ordena por una o varias columnas; por defecto ascendente (`ASC`), o `DESC`. Con varias columnas, la segunda desempata:

```sql
SELECT * FROM logins ORDER BY password DESC, id ASC;
```

> [!important]+
> `ORDER BY` admite **un número de columna** en lugar del nombre (`ORDER BY 3`). Inyectar `ORDER BY 1`, `ORDER BY 2`… hasta que la consulta falla revela <mark style="background: #FFB86CA6;">cuántas columnas devuelve el `SELECT`</mark> —paso obligatorio antes de una [[05 - Inyección UNION|inyección UNION]]—. Pero hay algo más importante para 2026: <mark style="background: #8000E1A6;">una cláusula `ORDER BY` **no se puede parametrizar** con prepared statements</mark> (un placeholder `?` no vale para un nombre de columna ni una dirección de orden; ni siquiera para el número de columna, que el driver entrecomillaría como cadena). Por eso los desarrolladores la construyen concatenando strings, y por eso **`ORDER BY` injection sobrevive en aplicaciones modernas** que, por lo demás, usan consultas parametrizadas. Es uno de los pocos lugares donde SQLi aún aparece en stacks bien escritos.

# `LIMIT` — acotar el número de resultados

`LIMIT n` devuelve como máximo `n` registros; con un offset, `LIMIT offset, n` empieza en la posición `offset` (contando desde 0):

```sql
SELECT * FROM logins LIMIT 2;
SELECT * FROM logins LIMIT 1, 2;   -- empieza en el 2º registro, devuelve 2
```

Igual que `ORDER BY`, el valor de `LIMIT` tampoco se parametriza fácilmente, así que la **`LIMIT` injection** es otro vector que persiste en código que parametriza el resto de la consulta.

# `LIKE` — coincidencia por patrón

Selecciona registros que casan con un patrón. `%` sustituye cero o más caracteres; `_` exactamente uno:

```sql
SELECT * FROM logins WHERE username LIKE 'admin%';   -- empieza por 'admin'
SELECT * FROM logins WHERE username LIKE '___';      -- exactamente 3 caracteres
```

`LIKE` aparece en buscadores y filtros, contextos clásicos de inyección donde además el `%` del propio usuario puede alterar la lógica de búsqueda.

# Operadores lógicos y de comparación

Para combinar condiciones, SQL usa `AND`, `OR` y `NOT` (también escribibles como `&&`, `||` y `!`). En MySQL, cualquier valor distinto de cero es `true` (devuelve `1`); `0` es `false`.

| Operador | Símbolo | Devuelve `true` si… |
| -------- | ------- | ------------------- |
| `AND`    | `&&`    | ambas condiciones son verdaderas |
| `OR`     | `\|\|`  | al menos una es verdadera |
| `NOT`    | `!`     | invierte el valor booleano |

Los operadores de comparación son `=`, `!=`, `>`, `<`, `>=`, `<=` y `LIKE`. Combinados, permiten consultas finas:

```sql
SELECT * FROM logins WHERE username != 'john' AND id > 1;
```

## Precedencia de operadores

Cuando una consulta mezcla varias operaciones, el orden de evaluación lo fija la precedencia (de mayor a menor):

1. División (`/`), multiplicación (`*`), módulo (`%`)
2. Suma (`+`) y resta (`-`)
3. Comparación (`=`, `>`, `<`, `<=`, `>=`, `!=`, `LIKE`)
4. `NOT` (`!`)
5. `AND` (`&&`)
6. `OR` (`||`)

Así, en `WHERE username != 'tom' AND id > 3 - 2`, primero se evalúa `3 - 2 = 1`, luego las comparaciones, y por último el `AND`.

> [!important]+
> <mark style="background: #FF5582A6;">La precedencia explica por qué `OR 1=1` es tan eficaz</mark>: al tener `OR` la prioridad más baja, se evalúa el último, de modo que `usuario_inyectado' OR 1=1` hace verdadera toda la condición sin importar el resto. Entender este orden es lo que permite construir payloads que se ejecutan como uno espera —y depurarlos cuando un WAF o un filtro alteran el resultado—.

Con los fundamentos de SQL cubiertos, el salto natural es ver cómo todo esto se vuelve un arma en [[00 - Introducción a SQL Injection]] y, en concreto, cómo se [[02 - Subvertir la lógica de consulta|subvierte la lógica de una consulta]].
