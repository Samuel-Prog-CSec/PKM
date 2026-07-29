---
tags:
  - Full-Stack
  - MongoDB
  - NoSQL
  - Bases-de-Datos
Descripción: "MongoDB es el motor de base de datos de la pila MERN y la pieza sobre la que se asienta el modelo de datos de la aplicación"
Fecha de actualización: 2026-06-22
Nota previa: "[[La especificación JavaScript]]"
Nota siguiente: "[[01-CRUD y filtros en MongoDB]]"
Area: "[[MongoDB.base|MongoDB]]"
---
---

MongoDB es el motor de base de datos de la pila MERN y la pieza sobre la que se asienta el modelo de datos de la aplicación. <mark style="background: #ADCCFFA6;">MongoDB es una base de datos NoSQL orientada a documentos, una de las más extendidas y populares.</mark>

# Documentos, colecciones y BSON

A diferencia de una base de datos relacional, <mark style="background: #ADCCFFA6;">en MongoDB los datos no se almacenan en tablas ni en registros, sino en colecciones de documentos en formato BSON</mark> —`Binary JSON`, una <mark style="background: #FFB8EBA6;">representación binaria del formato JSON</mark>—. La equivalencia mental con el mundo relacional:

| **Relacional (SQL)** | **MongoDB (NoSQL documental)** |
| -------------------- | ------------------------------ |
| Base de datos        | Base de datos                  |
| Tabla                | Colección                      |
| Fila / registro      | Documento (BSON/JSON)          |
| Columna / campo      | Campo del documento            |

Un documento es, en esencia, un <mark style="background: #ADCCFFA6;">objeto JSON con pares clave-valor</mark> que <mark style="background: #FFB86CA6;">puede anidar otros documentos y arrays</mark>:

```json
{
  "_id": "65a1f0c2e3b4...",
  "name": "Ada",
  "age": 36,
  "roles": ["admin", "editor"],
  "address": 
	  { 
		  "city": "Madrid", 
		  "zip": "28001" 
	  }
}
```

# Esquema dinámico y ventajas

<mark style="background: #FFB86CA6;">La característica diferencial es el esquema dinámico</mark>: los <mark style="background: #FF5582A6;">documentos de una misma colección no están obligados a compartir la misma estructura</mark>. Esto, junto con su diseño, aporta <mark style="background: #FFB8EBA6;">rapidez y facilidad de acceso</mark>, por lo que muchos sistemas que manejan grandes volúmenes de datos optan por MongoDB. Ventajas habituales: **escalabilidad**, **rapidez** y **eficiencia con grandes cantidades de datos**.

> [!info]+ ¿Cuándo NoSQL documental?
> El **modelo documental encaja cuando los datos son jerárquicos o heterogéneos**, el <mark style="background: #FFB8EBA6;">esquema evoluciona rápido</mark>, o se <mark style="background: #FFB8EBA6;">prioriza la escalabilidad horizontal</mark> sobre las garantías transaccionales estrictas de las bases relacionales. Para un repaso del modelo relacional y los DBMS, ver [[Introducción a las bases de datos]].

# Base de datos local vs servicios en la Nube

Hay dos formas de alojar la base de datos: un **servidor propio** que gestionas tú, o **servicios de terceros** en la Nube. <mark style="background: #FFB8EBA6;">La mayoría de las aplicaciones comerciales optan por la Nube</mark> para no ocuparse del mantenimiento del servidor, su seguridad ni su escalabilidad.

<mark style="background: #ADCCFFA6;">MongoDB Atlas es el servicio en la Nube oficial de MongoDB: un DBaaS (Database as a Service)</mark> que permite crear clústeres MongoDB sin instalar ni administrar nada, con una opción gratuita. Un **clúster** es el conjunto de <mark style="background: #8000E1A6;">servidores que alojan y replican la base de datos</mark>.

> [!important]+ Conceptos que pueden caer
> - **DBaaS** (*Database as a Service*): <mark style="background: #FFB8EBA6;">base de datos gestionada en la Nube</mark> por un tercero (Atlas).
> - **Colección *capped***: <mark style="background: #FFB8EBA6;">colección de tamaño fijo</mark> (en bytes) que, al llenarse, **borra los documentos más antiguos** para seguir almacenando los nuevos.
> - **IP whitelist**: lista de <mark style="background: #FFB8EBA6;">direcciones IP autorizadas</mark> a conectar con el clúster.

# Herramientas de acceso

Tres vías para operar sobre los datos:

- **Shell de MongoDB** (`mongo`): cliente de línea de comandos. Es la base de [[01-CRUD y filtros en MongoDB]].
- **Driver desde la aplicación**: el back-end conecta por código; en MERN, normalmente a través del ODM [[04-Mongoose y el patrón ODM en Express|mongoose]].
- **MongoDB Compass**: herramienta **gráfica (GUI)** para explorar y manipular los datos visualmente.

# Tipos de bases de datos NoSQL

MongoDB es **documental**, pero NoSQL engloba varias familias, todas alejadas del modelo tabular relacional:

| Familia | Idea | Ejemplos |
| - | - | - |
| **Documental** | Documentos JSON/BSON en colecciones | MongoDB, CouchDB |
| **Clave-valor** | Pares clave → valor | Redis, DynamoDB |
| **Columnar** | Familias de columnas | Cassandra, HBase |
| **Grafo** | Nodos y relaciones | Neo4j |

# El campo `_id`

<mark style="background: #FFB8EBA6;">Cada documento tiene un campo `_id` único que actúa de clave primaria.</mark> Si no se especifica, MongoDB genera un **`ObjectId`**: un <mark style="background: #FFB86CA6;">identificador de 12 bytes que incluye una marca de tiempo</mark>. Es el equivalente a la clave primaria del mundo relacional.

# Incrustar vs referenciar

Al modelar relaciones hay dos estrategias, y <mark style="background: #FF5582A6;">elegir bien afecta al rendimiento</mark>:

- **Incrustar** (*embedding*): meter el <mark style="background: #ADCCFFA6;">subdocumento dentro del documento padre</mark> (p. ej. la dirección dentro del usuario). Lectura rápida en una sola consulta; <mark style="background: #FFB86CA6;">ideal para datos que se leen juntos</mark>.
- **Referenciar** (*referencing*): <mark style="background: #ADCCFFA6;">guardar el `_id` de otro documento</mark> (como una <mark style="background: #8000E1A6;">clave ajena</mark>). Evita duplicación; <mark style="background: #FFB86CA6;">ideal para relaciones muchos-a-muchos o datos compartidos</mark>. Es lo que hace [[04-Mongoose y el patrón ODM en Express|mongoose]] con `ref`.

La definición del esquema de la base de datos son los cimientos de la aplicación: sobre estas colecciones se construyen las operaciones [[Operaciones CRUD, HTTP y SQL|CRUD]] que expondrá la API REST.
