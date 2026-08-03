---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Descripción: "Una Web API es un conjunto de reglas que permite a distintas aplicaciones comunicarse por la web, intercambiando datos y servicios sin importar su tecnología"
Fecha de actualización: 2026-06-02
Nota previa: "[[22 - Validación de hallazgos]]"
Nota siguiente: "[[24 - Fuzzing de APIs]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">Una `Web API` es un conjunto de reglas que permite a distintas aplicaciones comunicarse por la web</mark>, intercambiando datos y servicios sin importar su tecnología. Es el puente entre un servidor (que aloja datos y funcionalidad) y un cliente (navegador, app móvil, otro servidor) que los consume. Antes de fuzzear una API hay que saber **dónde** mirar — y eso depende de su tipo.

# Tipos de API

| Tipo | Modelo | Ejemplo |
| - | - | - |
| `REST` | Stateless, recursos por URL, métodos HTTP (`GET`/`POST`/`PUT`/`DELETE`) para CRUD, datos en JSON/XML | `GET /users/123` |
| `SOAP` | Protocolo formal basado en XML, mensajes en sobres `SOAP`, interfaz definida por `WSDL` | `<soapenv:Envelope>...</soapenv:Envelope>` |
| `GraphQL` | Un único endpoint, lenguaje de consulta flexible; el cliente pide exactamente los campos que necesita | `query { user(id:123){ name email } }` |

`REST` domina por su simplicidad; `SOAP` persiste en entornos *enterprise*; `GraphQL` crece en apps modernas por evitar el *over-fetching*.

# API vs servidor web (por qué cambia el fuzzing)

| | Servidor web | API |
| - | - | - |
| **Propósito** | Servir HTML/CSS/JS y páginas | Que las aplicaciones intercambien datos |
| **Formato** | HTML, recursos web | JSON, XML, según especificación |
| **Interacción** | El usuario navega directamente | El usuario no la toca; la app la usa por detrás |
| **Acceso** | Normalmente público | Público, privado o de partner |

<mark style="background: #8000E1A6;">La consecuencia práctica: en una API no fuzzeas directorios y archivos, sino **endpoints** y sus **parámetros**</mark>, prestando atención al formato de datos (JSON/XML) de peticiones y respuestas.

# Identificar endpoints REST

Los endpoints REST son URLs jerárquicas que representan recursos:

```text
/users          → colección de usuarios
/users/123      → usuario con ID 123
/products/456   → producto con ID 456
```

Y aceptan tres tipos de parámetros:

| Tipo | Dónde va | Ejemplo |
| - | - | - |
| Query | Tras `?` en la URL (filtrado, orden, paginación) | `/users?limit=10&sort=name` |
| Path | Incrustado en la URL (identifica el recurso) | `/products/{id}` |
| Body | En el cuerpo de `POST`/`PUT`/`PATCH` (crear/actualizar) | `{ "name": "X", "price": 99.99 }` |

> [!important]+ BOLA/IDOR: el bug nº1 de las APIs
> Los path parameters como `/users/123` son el origen del fallo de API más reportado: <mark style="background: #FFB86CA6;">`BOLA` (Broken Object Level Authorization), el `IDOR` de las APIs</mark>. Si cambias `123` por `124` y obtienes los datos de otro usuario, la API no valida la autorización a nivel de objeto. Fuzzear el `id` sobre un rango numérico es una de las pruebas más rentables — encadena con el [[19 - Fuzzing de parámetros y valores|fuzzing de valores]].

# Identificar endpoints SOAP

`SOAP` expone **un único endpoint** donde el servidor escucha; la operación concreta la determina el contenido XML del mensaje. La pieza clave es el **`WSDL`** (Web Services Description Language): un XML que describe operaciones, parámetros de entrada/salida, tipos de datos y la URL del endpoint. Conseguir el `WSDL` (a menudo en `?wsdl`) te da el mapa completo de la API.

# Identificar endpoints GraphQL

`GraphQL` también usa **un único endpoint** (`/graphql`), punto de entrada de todas las *queries* (leer) y *mutations* (modificar):

```graphql
query    { user(id: 123) { name email posts(limit: 5) { title } } }
mutation { createPost(title: "X", body: "...") { id title } }
```

> [!important]+ Introspección: GraphQL se autodescribe
> La función más explotable de GraphQL es la **introspección**: <mark style="background: #FF5582A6;">una query especial al endpoint devuelve el esquema completo</mark> —todos los tipos, campos, queries y mutations disponibles—. Si la introspección está habilitada (por defecto en desarrollo y en bastantes despliegues mal configurados; los frameworks modernos como Apollo v3+ la desactivan en producción — pruébala siempre, pero no la des por hecha), tienes el mapa entero de la API sin documentación. Herramientas como `InQL` y `graphql-voyager` la visualizan; `graphw00f` identifica **qué motor** GraphQL corre por detrás (Apollo, Hasura, Graphene…), y `clairvoyance` reconstruye el esquema incluso con la introspección **deshabilitada**. Es la base del pentest de [[00 - Introducción a GraphQL|GraphQL]].

# Métodos de descubrimiento

Comunes a todos los tipos:

- **Documentación / especificaciones**: lo más fiable. Busca `Swagger`/`OpenAPI` (`/swagger.json`, `/openapi.json`, `/api-docs`, `/v2/api-docs`, `/swagger-ui/`), `RAML` o el `WSDL`. <mark style="background: #FF5582A6;">Un `swagger.json` expuesto te entrega todos los endpoints y parámetros en bandeja</mark> — fuzzéalos como rutas con [[17 - Fuzzing de directorios y archivos|`ffuf`]].
- **Análisis de tráfico**: con [[00 - Introducción a los proxies web|Burp/Caido]] o las DevTools del navegador, intercepta las peticiones reales que la app hace a su API y observa endpoints, parámetros y formatos.
- **Análisis de JavaScript**: el front-end consume la API, así que sus `js_files` contienen las rutas. Extráelas con `LinkFinder` (ver [[11 - Spidering con Scrapy]]).
- **Fuzzing de nombres de parámetros**: igual que con directorios, `ffuf`/`arjun` con `wordlists` de API descubren parámetros y endpoints no documentados.

Versionado (`/v1/`, `/v2/`) y endpoints legacy son otra mina: <mark style="background: #FFB86CA6;">una versión antigua de la API suele tener menos controles que la actual</mark>.

Con los endpoints localizados, el último paso es fuzzearlos sistemáticamente: [[24 - Fuzzing de APIs]].
