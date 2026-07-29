---
tags:
  - Full-Stack
  - CRUD
  - HTTP
Descripción: "CRUD es el acrónimo de Create, Read, Update, Delete: las cuatro maneras básicas de operar sobre información almacenada"
Fecha de actualización: 2026-06-22
Nota previa: "[[La pila MERN]]"
Nota siguiente: "[[La especificación JavaScript]]"
Area: "[[Fundamentos.base|Fundamentos]]"
---
---

<mark style="background: #ADCCFFA6;">CRUD es el acrónimo de Create, Read, Update, Delete: las cuatro maneras básicas de operar sobre información almacenada.</mark>. Aunque normalmente se refieren a operaciones sobre una base de datos, también se aplican a funciones de nivel superior. A bajo nivel, las funciones concretas dependen del lenguaje y del sistema gestor de base de datos.

# Las cuatro operaciones

- **Create** (crear/insertar): añade nuevos registros o documentos a un almacén.
- **Read** (leer): devuelve uno o más registros, opcionalmente filtrando por criterios.
- **Update** (actualizar): modifica registros existentes, también según criterios.
- **Delete** (borrar): elimina registros, según criterios.

# Correspondencia CRUD ↔ SQL ↔ HTTP

<mark style="background: #8000E1A6;">Cuando se invocan operaciones CRUD desde un cliente web o una API, se usan solicitudes HTTP.</mark> Cada operación CRUD tiene una solicitud HTTP asociada y, en una base de datos relacional, una sentencia SQL equivalente. Esta tripleta es la tabla clave del tema:

| CRUD | SQL | HTTP | MongoDB (NoSQL) |
| - | - | - | - |
| **Create** | `INSERT` | `POST` | `insertOne` / `insertMany` |
| **Read** | `SELECT` | `GET` | `find` / `findOne` |
| **Update** | `UPDATE` | `PUT` / `PATCH` | `updateOne` / `updateMany` / `replaceOne` |
| **Delete** | `DELETE` | `DELETE` | `deleteOne` / `deleteMany` |

<mark style="background: #FFB8EBA6;">`PUT` reemplaza el recurso completo; `PATCH` lo actualiza parcialmente.</mark>

> [!warning]+ No confundir los niveles
> CRUD es un **concepto**. SQL, HTTP y las funciones de MongoDB son **implementaciones** de ese concepto en tres planos distintos: lenguaje de consulta relacional, protocolo de transporte web y API de un motor NoSQL. Una misma operación Read puede ser a la vez un `SELECT`, un `GET` y un `find`.

# CRUD en MongoDB (lo que usa MERN)

Como MERN trabaja con MongoDB —<mark style="background: #ADCCFFA6;">NoSQL orientada a documentos: documentos en lugar de registros, colecciones en lugar de tablas</mark>—, las operaciones CRUD se expresan así:

- **Create**: `insertOne` (un documento) o `insertMany` (varios). Si la colección no existe, la inserción la crea.
- **Read**: `find`, que admite **filtros** para devolver solo los documentos que cumplen un criterio.
- **Update**: `updateOne`, `updateMany` o `replaceOne`; con los mismos filtros que Read para identificar qué documentos modificar.
- **Delete**: `deleteOne` o `deleteMany`, también con filtros.

```javascript
// Create
db.users.insertOne({ name: "Ada", age: 36 })
// Read (con filtro)
db.users.find({ age: { $gt: 18 } })
// Update (con filtro y operador $set)
db.users.updateMany({ age: { $lt: 18 } }, { $set: { status: "minor" } })
// Delete (con filtro)
db.users.deleteMany({ status: "reject" })
```

<mark style="background: #FFB8EBA6;">Todas estas operaciones pueden ejecutarse de forma masiva</mark> (secuencialmente sobre una colección bajo una misma función). La sintaxis y los filtros se amplían en [[01-CRUD y filtros en MongoDB]]; su integración en una API REST con Express, en [[03-CRUD, métodos HTTP y códigos de estado]].

# Propiedades de los métodos HTTP

Más allá de la correspondencia con CRUD, los métodos HTTP tienen dos propiedades que suelen caer en examen:

- **Seguro** (*safe*): no modifica el estado del servidor. Solo **GET**.
- **Idempotente**: repetir la petición produce el mismo resultado que hacerla una vez.

| Método | Seguro | Idempotente | CRUD |
| - | - | - | - |
| GET | Sí | Sí | Read |
| POST | No | **No** | Create |
| PUT | No | Sí | Update (total) |
| PATCH | No | No | Update (parcial) |
| DELETE | No | Sí | Delete |

<mark style="background: #FFB8EBA6;">POST no es idempotente: repetirlo crea recursos duplicados; PUT y DELETE sí lo son.</mark> Por eso reenviar un formulario con POST puede duplicar datos, mientras que reintentar un DELETE es seguro.

# CRUD no es solo bases de datos

Aunque CRUD nace en el contexto del almacenamiento, el patrón se aplica a cualquier recurso: ficheros, entradas de caché, objetos en memoria. En una API REST, **cada recurso expone sus operaciones CRUD** a través de los métodos HTTP sobre su URI.

> [!important]+ Para el examen
> Memoriza la tripleta: **Create = INSERT = POST**, **Read = SELECT = GET**, **Update = UPDATE = PUT/PATCH**, **Delete = DELETE = DELETE**. En MongoDB: `insert*` / `find` / `update*` / `delete*`. CRUD es "el corazón del back-end" porque casi toda la lógica de servidor se reduce a estas cuatro operaciones sobre datos.
