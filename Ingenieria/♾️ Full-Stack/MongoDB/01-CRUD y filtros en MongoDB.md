---
tags:
  - Full-Stack
  - MongoDB
  - CRUD
  - NoSQL
Fecha de actualización: 2026-06-22
Nota previa: "[[00-MongoDB y el modelo NoSQL documental]]"
Nota siguiente: "[[00-Node.js, entorno de ejecución del servidor]]"
Area: "[[MongoDB.base|MongoDB]]"
---
---

Operaciones CRUD sobre MongoDB desde la **shell** (`mongo`). Es la base sobre la que luego trabajan el ODM [[04-Mongoose y el patrón ODM en Express|mongoose]] y la API REST. Para la correspondencia conceptual CRUD↔SQL↔HTTP, ver [[Operaciones CRUD, HTTP y SQL]].

# Comandos básicos de la shell

```shell-session
db                  # base de datos actual
show dbs            # listar bases de datos
use mymerndb        # seleccionar (o crear) una base de datos
show collections    # listar colecciones
```

# Create

```javascript
db.users.insertOne({ name: "Ada", age: 36 })
db.users.insertMany([{ name: "Linus" }, { name: "Grace" }])  // requiere corchetes [ ]
```

<mark style="background: #FFB8EBA6;">`insertMany` recibe un array; si la colección no existe, la inserción la crea.</mark>

# Read

```javascript
db.users.find()                        // todos los documentos
db.users.find({ age: { $gt: 18 } })    // con filtro
db.users.findOne({ name: "Ada" })      // primer documento coincidente
db.users.find({ age: { $gte: 18 } }).sort({ age: 1 }).limit(5)
```

`find` devuelve todos los coincidentes; `findOne`, solo el primero. Métodos encadenables: `.count()` (número de resultados), `.sort({ campo: 1 | -1 })` (1 ascendente, -1 descendente) y `.limit(n)`.

# Update

```javascript
db.users.updateOne({ name: "Ada" }, { $set: { age: 37 } })
db.users.updateMany({ age: { $lt: 18 } }, { $set: { status: "minor" } })
db.users.replaceOne({ name: "Ada" }, { name: "Ada Lovelace", age: 37 })
```

<mark style="background: #FFB8EBA6;">`updateOne`/`updateMany` modifican campos concretos (con `$set`); `replaceOne` sustituye el documento entero.</mark>

# Delete

```javascript
db.users.deleteOne({ name: "Ada" })
db.users.deleteMany({ status: "reject" })
```

# Filtros y operadores de consulta

Formas de un filtro:

- `{ "key": "value" }` — igualdad directa.
- `{ key: { $operator: value } }` — operador de consulta.
- `{ key: { $exists: true } }` — documentos que contienen la clave.

Operadores más frecuentes:

| Operador | Significado |
| - | - |
| `$eq` / `$ne` | Igual / distinto a un valor |
| `$gt` / `$gte` | Mayor / mayor o igual que |
| `$lt` / `$lte` | Menor / menor o igual que |
| `$in` / `$nin` | Está / no está en un array de valores |
| `$and` / `$or` | Combinación lógica de condiciones |
| `$exists` | El campo existe en el documento |

```javascript
// edad entre 18 y 65
db.users.find({ age: { $gte: 18, $lte: 65 } })
// rol admin o editor
db.users.find({ role: { $in: ["admin", "editor"] } })
// AND explícito (mismo campo, dos condiciones)
db.users.find({ $and: [ { age: { $gt: 18 } }, { age: { $lt: 30 } } ] })
```

# Operadores de actualización

Igual que la lectura usa operadores de consulta, la actualización usa **operadores de modificación** dentro de `update*`:

| Operador | Acción |
| - | - |
| `$set` | Fija el valor de un campo |
| `$unset` | Elimina un campo |
| `$inc` | Incrementa un valor numérico |
| `$push` | Añade un elemento a un array |
| `$pull` | Quita de un array los elementos que cumplan un criterio |
| `$rename` | Renombra un campo |

```javascript
db.users.updateOne({ name: "Ada" }, { $inc: { visitas: 1 } })
db.users.updateOne({ name: "Ada" }, { $push: { roles: "editor" } })
```

# Proyección: devolver solo algunos campos

El segundo argumento de `find` es la **proyección**: `1` incluye un campo, `0` lo excluye.

```javascript
db.users.find({ age: { $gt: 18 } }, { name: 1, email: 1, _id: 0 })
```

Equivale al `SELECT name, email` de SQL (frente al `SELECT *`, que sería un `find` sin proyección).

> [!important]+ Para el examen
> Create = `insertOne`/`insertMany` · Read = `find`/`findOne` · Update = `updateOne`/`updateMany`/`replaceOne` (con `$set`) · Delete = `deleteOne`/`deleteMany`. Un filtro es un objeto `{ campo: valor }` o `{ campo: { $op: valor } }`. Operadores de comparación con prefijo `$`: `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`, `$ne`…

> [!info]+ De la shell al ODM
> En la aplicación MERN no se usa la shell directamente: [[04-Mongoose y el patrón ODM en Express|mongoose]] envuelve estas operaciones en métodos sobre modelos (`Model.find()`, `Model.create()`…) y añade esquema y validación. Ver también [[💽🧬 Modelos en Mongoose]] y [[📶📡 Conexión con MongoDB]].
