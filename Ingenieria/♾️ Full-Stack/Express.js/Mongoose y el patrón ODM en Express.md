---
tags:
  - Full-Stack
  - Express
  - Mongoose
  - MongoDB
Fecha de actualización: 2026-06-22
Nota previa: "[[CRUD, métodos HTTP y códigos de estado]]"
Nota siguiente: "[[Seguridad de APIs REST (tokens y JWT)]]"
Area: "[[Express.js.base|Express.js]]"
---
---

<mark style="background: #ADCCFFA6;">Un ODM (Object Document Mapper) es un mapeador que traduce entre un modelo de objetos y una base de datos de documentos</mark> (como MongoDB), igual que un **ORM** (Object Relational Mapper) lo hace con una base de datos relacional. Aporta un **alto nivel de abstracción**: se manipulan los datos como objetos, sin escribir consultas a mano, logrando independencia entre los modelos y la fuente de datos. → [[🗺️ ODM y ORM]]

# ¿Qué es un modelo?

<mark style="background: #ADCCFFA6;">Un modelo es la representación de un tipo de contenido con la que se trabaja a alto nivel mediante objetos.</mark> Los modelos se crean a partir de **esquemas**, que definen los atributos, sus tipos y comportamiento adicional (validación, valores por defecto…). Para guardar o recuperar datos se opera sobre objetos de un modelo previamente definido. → [[¿Qué es un modelo❓]]

Renunciar a los ODM y a los modelos es posible, pero se pierden ventajas de mantenibilidad, validación de datos, optimización y *agnosticismo* respecto al motor.

# mongoose: el ODM de MERN

<mark style="background: #8000E1A6;">mongoose es una librería JavaScript que implementa un ODM y se sitúa, en el back-end, entre MongoDB y Express.</mark> Es la capa **Modelo** del patrón [[Patrones de diseño web (MVC y SPA)|MVC]]. Define esquemas con **datos fuertemente tipados**; a partir de un esquema crea un **modelo**, y ese modelo se asigna a un documento MongoDB. Se instala como dependencia:

```shell-session
$ npm install mongoose --save
```

# Esquema → modelo

```javascript
var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var PostSchema = new Schema({
  user: { type: Schema.ObjectId, ref: 'User' },   // relación con User
  title: String,
  description: String,
  publicationdate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Post', PostSchema);
```

`mongoose.model('Post', PostSchema)` deriva el modelo `Post` del esquema. Los modelos suelen guardarse como ficheros `.js` en un directorio `/models`. → [[💽🧬 Modelos en Mongoose]]

# SchemaTypes

mongoose ofrece 8 tipos para los atributos:

| | | | |
| - | - | - | - |
| `String` | `Number` | `Date` | `Buffer` |
| `Boolean` | `Mixed` | `ObjectId` | `Array` |

Cada atributo puede especificar: un **valor por defecto**, una **función de validación** personalizada, la **obligatoriedad** (`required`), funciones `get`/`set` para transformar datos antes de devolverlos o guardarlos, e **índices** para acelerar las consultas.

```javascript
var UserSchema = new Schema({
  username: { type: String, required: true, index: { unique: true } },
  password: { type: String, required: true },
  email:    { type: String, required: true },
  role:     { type: String, enum: ['admin', 'subscriber'], default: 'subscriber' },
  posts:    [{ type: Schema.ObjectId, ref: 'Post', default: null }]   // array de refs
});
```

# Relaciones entre modelos

<mark style="background: #FFB8EBA6;">Con `ref` se relacionan modelos (p. ej. `User` ↔ `Post`), de forma análoga a las claves ajenas entre tablas relacionales.</mark> Un post referencia a su usuario; un usuario guarda un array de referencias a sus posts.

Definidos esquemas y modelos, mongoose aporta funciones para **validar, guardar, eliminar y consultar** datos, apoyándose por debajo en las operaciones de [[CRUD y filtros en MongoDB|MongoDB]]. La conexión a la base de datos se establece con `mongoose.connect(...)`. → [[📶📡 Conexión con MongoDB]]

# Métodos del modelo (las operaciones CRUD)

Creado el modelo, mongoose expone métodos que envuelven las operaciones de MongoDB y devuelven promesas:

```javascript
User.find({ role: 'admin' });          // Read (varios)
User.findById(id);                     // Read (por _id)
User.create({ username: 'ada' });      // Create
user.save();                           // Create/Update de una instancia
User.updateOne({ _id: id }, { ... });  // Update
User.deleteOne({ _id: id });           // Delete
```

# Validación y `populate`

- **Validación**: el esquema valida antes de guardar (`required`, `min`/`max`, `enum`, validadores propios). Si falla, `save` rechaza la promesa con un error de validación —validación a nivel de modelo, no solo de base de datos—.
- **`populate`**: resuelve una referencia (`ref`) sustituyendo el `_id` por el documento completo. Es el equivalente a un *JOIN* del mundo relacional.

```javascript
Post.find().populate('user');   // trae cada post con su usuario completo
```

> [!important]+ Para el examen
> **ORM** ↔ BBDD relacional; **ODM** ↔ BBDD documental (MongoDB). **mongoose** es el ODM de MERN: define **esquemas** tipados → **modelos** que mapean a documentos. Es la capa **Modelo** del MVC. 8 SchemaTypes (`String`, `Number`, `Date`, `Buffer`, `Boolean`, `Mixed`, `ObjectId`, `Array`). `ref` crea relaciones entre modelos.
