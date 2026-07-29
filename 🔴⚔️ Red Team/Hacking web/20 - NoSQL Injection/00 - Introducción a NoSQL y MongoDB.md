---
tags:
  - Web/Red-Team
  - Introduccion
  - NoSQLi
  - Tipo/Introduccion
Descripción: "NoSQL ('Not only SQL') agrupa las bases de datos no relacionales: en lugar de tablas, filas y columnas, guardan los datos en estructuras flexibles"
Fecha de actualización: 2026-07-16
Nota previa: ""
Nota siguiente: "[[01 - Introducción a la NoSQL injection]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

<mark style="background: #ADCCFFA6;">NoSQL ("Not only SQL") agrupa las bases de datos no relacionales</mark>: en lugar de tablas, filas y columnas, guardan los datos en estructuras flexibles. Hay cuatro familias —documentales, clave-valor, *wide-column* y grafo—; <mark style="background: #FFB8EBA6;">MongoDB, documental, es la más usada</mark> y en la que se centra este sub-tema (y casi toda la NoSQL injection que verás en la práctica).

# MongoDB en dos minutos

Los datos se guardan en **colecciones** de **documentos** (formato `BSON`, binario similar a JSON), cada uno con campos y valores. El campo `_id` es la clave primaria. Un documento típico:

```javascript
{ "_id": ObjectId("63651456d18bf6c01b8eeae9"), "type": "Granny Smith", "price": 0.65 }
```

Se interactúa desde la CLI con `mongosh`:

```shell-session
$ mongosh mongodb://127.0.0.1:27017
test> use academy
test> db.apples.find({type: "Granny Smith"})
```

# Operadores de consulta (los ladrillos de la inyección)

<mark style="background: #8000E1A6;">Las consultas MongoDB se construyen con operadores prefijados con `$`</mark> — y son exactamente lo que un atacante inyecta. Los que importan:

| Categoría | Operadores | Ejemplo |
| - | - | - |
| Comparación | `$eq` `$ne` `$gt` `$gte` `$lt` `$lte` `$in` `$nin` | `{price: {$gt: 0.30}}` |
| Lógicos | `$and` `$or` `$not` `$nor` | `{$or: [{a:1},{b:2}]}` |
| Evaluación | `$regex` `$where` `$mod` | `{type: {$regex: "^G"}}` |

> [!warning]+ Dos operadores clave para el atacante
> <mark style="background: #FFB86CA6;">`$regex` permite coincidencia parcial</mark> (`^p`, `.*`) — la base del bypass de login y de la [[05 - Extracción de datos ciega y automatización|extracción ciega]] carácter a carácter. Y <mark style="background: #FF5582A6;">`$where` ejecuta **JavaScript** en el servidor</mark> — un vector directo a [[06 - Server-Side JavaScript Injection|Server-Side JavaScript Injection]]. Recordar estos dos es media inyección NoSQL.

# CRUD básico

Para leer/escribir: `find()` / `findOne()` (leer), `insertOne()` / `insertMany()` (crear), `updateOne()` / `updateMany()` con `$set` (modificar), `remove()` / `deleteMany()` (borrar). El operando de `find()` es un documento de filtro donde encajan los operadores de arriba — el punto exacto donde entra la inyección.

Con los fundamentos claros, veamos cómo se rompe la lógica de estas consultas: [[01 - Introducción a la NoSQL injection]].
