---
tags:
  - Full-Stack
  - Examen
  - Repaso
Fecha de actualización: 2026-06-22
---
---

> [!info]+ Instrucciones
> **Parte I** — 10 preguntas de desarrollo (respuesta breve: un par de párrafos como mucho).
> **Parte II** — 30 preguntas tipo test (4 opciones, **una sola válida**).
> Las soluciones están en [[Soluciones del examen de práctica]]. No las mires hasta terminar.

# Parte I — Preguntas de desarrollo

1. Define los perfiles de desarrollador **front-end**, **back-end** y **full-stack**, indicando el criterio que los diferencia.

2. Define las operaciones **CRUD** y explica su correspondencia con las **operaciones SQL** y las **peticiones HTTP**.

3. ¿Qué es la **pila MERN**? Nombra sus cuatro tecnologías e indica el lado de la arquitectura (cliente/servidor) en que actúa cada una.

4. Explica el patrón **MVC** (sus tres capas) y cómo se reorganiza en una aplicación de tipo **SPA** como las que construye React.

5. ¿Qué es **REST**? Enumera sus características principales. Es un estilo de intercambio y manipulación de datos en servicios en Internet basado en HTTP. Devuelve los datos en un formato estandarizado (JSON o XML). Características:
Petición-respuesta: el cliente debe contruir la petición con toda la información necesaria y espera una respuesta concreta.
Basado en HTTP y en sus métodos principales (PUT, GET, POST, DELETE, PATCH).
Es independiente de sistemas y plataformas.
Stateless: las peticiones son autónomas, el servidor no guarda estado entre peticiones.

7. ¿Qué es un **middleware** en Express.js? Describe el **ciclo petición-respuesta** y el papel de `next()`.

8. ¿Qué es un **ODM**? Explica el papel de **mongoose** en la pila MERN (esquema, modelo, relaciones).

9. Explica la **autenticación basada en tokens** y la estructura de un **JWT** (sus tres partes).

10. Diferencia entre **props** y **state** en React: origen, mutabilidad y cómo se modifica cada uno.

11. ¿Qué son los **React hooks**? Explica `useState` y `useEffect`, y qué controla el segundo argumento de `useEffect`.

# Parte II — Preguntas tipo test

Marca la **única** opción correcta.

**1.** ¿Qué método HTTP se corresponde con la operación **Create** de CRUD?
- a) `GET`
- <mark style="background: #40FF00A6;">b</mark>) `POST`
- c) `PUT`
- d) `DELETE`

**2.** Sobre el desarrollador **full-stack**, ¿qué afirmación es correcta?
- a) Trabaja exclusivamente del lado del cliente.
- b) Solo se ocupa de la base de datos.
- <mark style="background: #40FF00A6;">c</mark>) Es responsable de la implementación tanto en el cliente como en el servidor.
- d) No necesita conocer protocolos de comunicación.

**3.** ¿Cuál de los siguientes métodos HTTP **NO** es idempotente?
- a) `GET`
- b) `PUT`
- c) `DELETE`
- <mark style="background: #40FF00A6;">d</mark>) `POST`

**4.** En el patrón MVC, ¿qué capa contiene la lógica que responde a las acciones del usuario y enlaza vista y modelo?
- a) Modelo
- b) Vista
- <mark style="background: #40FF00A6;">c</mark>) Controlador
- d) Servicio

**5.** ¿Qué tecnologías componen la pila MERN?
- a) MySQL, Express, React, Node
- <mark style="background: #40FF00A6;">b</mark>) MongoDB, Express, React, Node
- c) MongoDB, Ember, React, Node
- d) MongoDB, Express, Redux, Node

**6.** En una SPA construida con MERN, ¿qué devuelve normalmente el servidor ante una petición del cliente?
- a) Una página HTML completa renderizada en el servidor.
- <mark style="background: #40FF00A6;">b</mark>) Datos en formato JSON.
- c) Una hoja de estilos CSS.
- d) Código SQL.

**7.** ¿En qué formato almacena MongoDB los documentos?
- a) JSON
- <mark style="background: #40FF00A6;">b</mark>) BSON
- c) XML
- d) CSV

**8.** ¿Qué hace la consulta `db.users.find({ age: { $gte: 18 } })`?
- a) Inserta usuarios mayores o iguales a 18.
- <mark style="background: #40FF00A6;">b</mark>) Devuelve los usuarios con `age` mayor o igual que 18.
- c) Borra los usuarios menores de 18.
- d) Actualiza la edad a 18.

**9.** ¿Cuál es el equivalente en MongoDB de una **fila/registro** de una base de datos relacional?
- a) Colección
- <mark style="background: #40FF00A6;">b)</mark> Documento
- c) Campo
- d) Índice

**10.** ¿Qué afirmación describe mejor a **Node.js**?
- a) Un framework de front-end.
- b) Una base de datos NoSQL.
- <mark style="background: #40FF00A6;">c)</mark> Un entorno de ejecución de JavaScript del lado del servidor.
- d) Un gestor de paquetes.

**11.** ¿Qué comando instala un paquete y lo añade a las dependencias de `package.json`?
- a) `npm start`
- <mark style="background: #40FF00A6;">b</mark>) `npm install <pkg> --save`
- c) `npm init`
- d) `node <pkg>`

**12.** En `"express": "^4.17.1"`, ¿qué actualizaciones admite el prefijo `^`?
- a) Solo la versión exacta 4.17.1.
- b) Cualquier versión, incluida la 5.x.
- <mark style="background: #40FF00A6;">c)</mark> Versiones menores y parches dentro de 4.x.x.
- d) Solo parches (4.17.x).

**13.** Dada la llamada `router.get('/', function(req, res){ ... })`, ¿qué hace?
- a) Registra el componente React que se renderiza en la *home page*.
- <mark style="background: #40FF00A6;"> b</mark>) Instala una función manejadora para una petición HTTP `GET` sobre la ruta raíz `/` del servidor.
- c) Define una ruta de navegación del cliente con React Router.
- d) Crea una conexión con la base de datos en la raíz.

**14.** ¿Qué es un **middleware** en Express?
- a) Una base de datos intermedia.
- <mark style="background: #40FF00A6;">b</mark>) Una función con acceso a `req`, `res` y `next` que se ejecuta en el ciclo petición-respuesta.
- c) Un componente visual de React.
- d) Un tipo de documento de MongoDB.

**15.** ¿Qué distingue a un middleware de **manejo de errores** en Express?
- a) Se registra siempre el primero.
- <mark style="background: #40FF00A6;">b</mark>) Tiene cuatro parámetros: `(err, req, res, next)`.
- c) Solo funciona con peticiones `GET`.
- d) No puede llamar a `next()`.

**16.** ¿Qué significa que REST sea **stateless**?
- a) Que no usa el protocolo HTTP.
- b) Que el servidor guarda la sesión de cada cliente.
- <mark style="background: #40FF00A6;">c)</mark> Que cada petición contiene toda la información necesaria y el servidor no guarda estado entre peticiones.
- d) Que no devuelve códigos de estado.

**17.** Una petición a la que le falta un dato de entrada obligatorio debería responder con:
- a) `200 OK`
- <mark style="background: #40FF00A6;">b</mark>) `400 Bad Request`
- c) `301 Moved Permanently`
- d) `500 Internal Server Error`

**18.** Un usuario **autenticado** intenta acceder a un recurso para el que no tiene permisos. ¿Qué código es el correcto?
- a) `401 Unauthorized`
- <mark style="background: #40FF00A6;">b</mark>) `403 Forbidden`
- c) `404 Not Found`
- d) `200 OK`

**19.** ¿Qué clase de código de estado HTTP indica un **error del lado del servidor**?
- a) `2xx`
- b) `3xx`
- c) `4xx`
- <mark style="background: #40FF00A6;">d</mark>) `5xx`

**20.** ¿Qué es **mongoose** en la pila MERN?
- a) Un empaquetador de módulos (*bundler*).
- <mark style="background: #40FF00A6;">b)</mark> Un ODM (Object Document Mapper) entre MongoDB y la aplicación.
- c) Un cliente HTTP.
- d) Un motor de plantillas de vistas.

**21.** ¿Cuál de las tres partes de un **JWT** garantiza que el contenido no ha sido alterado?
- a) Header
- b) Payload
- <mark style="background: #40FF00A6;">c)</mark> Signature
- d) Cookie

**22.** ¿Qué es **JSX**?
- a) Un motor de base de datos.
- b) Una extensión de la sintaxis de JavaScript que mezcla JS y HTML/XML.
- c) Un gestor de estados global.
- d) Un protocolo de red.

**23.** En JSX, ¿cómo se escribe el atributo de clase CSS de un elemento?
- a) `class`
- b) `className`
- c) `cssClass`
- d) `class-name`

**24.** ¿Cuál es la diferencia clave entre **props** y **state**?
- a) Las props son mutables y el state inmutable.
- b) El state lo recibe del padre y las props las gestiona el componente.
- c) Las props son inmutables (vienen del padre) y el state es mutable (lo gestiona el componente).
- d) No hay diferencia, son sinónimos.

**25.** ¿Por qué el **Virtual DOM** mejora el rendimiento?
- a) Porque guarda los datos en el servidor.
- b) Porque renderiza solo las partes que cambian, evitando repintar todo el DOM.
- c) Porque elimina la necesidad de JavaScript.
- d) Porque comprime las imágenes.

**26.** ¿Qué devuelve `const [count, setCount] = useState(0)`?
- a) Un objeto con el estado y las props.
- b) Un array con el valor del estado y una función para actualizarlo.
- c) Una promesa.
- d) Únicamente el valor 0.

**27.** ¿Qué efecto tiene pasar un array vacío `[]` como segundo argumento de `useEffect`?
- a) El efecto se ejecuta en cada render.
- b) El efecto no se ejecuta nunca.
- c) El efecto se ejecuta una sola vez, tras el primer render (como `componentDidMount`).
- d) Provoca un bucle infinito de renderizado.

**28.** ¿Cuál de estas afirmaciones sobre **Express Router** y **React Router** es correcta?
- a) Ambos enrutan peticiones HTTP en el servidor.
- <mark style="background: #40FF00A6;">b)</mark> Express Router enruta en el servidor (endpoints HTTP); React Router enruta en el cliente (componentes).
- c) React Router es un middleware de Express.
- d) Express Router renderiza componentes en el navegador.

**29.** Según los principios de **Redux**, ¿cómo se modifica el estado?
- a) Modificando directamente el `store`.
- b) Emitiendo una acción que un *reducer* (función pura) procesa para devolver un nuevo estado.
- c) Llamando a `setState` sobre el `store`.
- d) Con una petición HTTP `PUT`.

**30.** ¿Qué métodos del ciclo de vida unifica el hook `useEffect`?
- a) `constructor` y `render`.
- b) `componentDidMount`, `componentDidUpdate` y `componentWillUnmount`.
- c) `shouldComponentUpdate` y `render`.
- d) `componentWillMount` únicamente.

---

# Preguntas Fundamentos (30)

Las marcadas con 🔴 son de mayor dificultad.

**F1.** ¿Qué tecnologías del lado del cliente domina típicamente un desarrollador front-end?
- a) HTML, CSS y JavaScript
- b) Node.js y Express
- c) MongoDB y SQL
- d) Solo protocolos de red

**F2.** ¿Qué protocolo usan principalmente cliente y servidor en una aplicación web?
- a) HTTP
- b) FTP
- c) SMTP
- d) SSH

**F3.** El perfil de desarrollador full-stack fue popularizado por el departamento de ingeniería de:
- a) Google
- b) Microsoft
- c) Facebook
- d) Amazon

**F4.** ¿Qué tipo de desarrollador se ocupa principalmente de la lógica de negocio y las transacciones?
- a) Front-end
- b) Back-end
- c) Diseñador UX
- d) Maquetador

**F5.** ¿Qué es un patrón de diseño?
- a) Una librería de JavaScript
- b) Un tipo de base de datos
- c) Una solución reutilizable a un problema típico y recurrente del desarrollo
- d) Un protocolo de red

**F6.** En el patrón MVC, ¿qué capa produce, en última instancia, el código HTML de la interfaz?
- a) Modelo
- b) Controlador
- c) Vista
- d) Servicio

**F7.** En el patrón MVC, ¿qué capa conecta con la base de datos a través de mapeadores de datos?
- a) Vista
- b) Modelo
- c) Controlador
- d) Router

**F8.** ¿Qué significa SPA?
- a) Single Page Application
- b) Server Page Application
- c) Secure Protocol Architecture
- d) Simple Page Adapter

**F9.** 🔴 ¿Qué patrón de flujo de datos, pensado para React, hace que los datos fluyan en una sola dirección?
- a) MVC
- b) MVVM
- c) Flux
- d) REST

**F10.** En la correspondencia CRUD, ¿con qué sentencia SQL se corresponde la operación Read?
- a) `SELECT`
- b) `INSERT`
- c) `UPDATE`
- d) `DELETE`

**F11.** ¿Con qué método HTTP se corresponde la operación Delete de CRUD?
- a) `GET`
- b) `DELETE`
- c) `POST`
- d) `PUT`

**F12.** 🔴 ¿Cuál de estos métodos HTTP es el único considerado "seguro" (*safe*)?
- a) `POST`
- b) `PUT`
- c) `GET`
- d) `DELETE`

**F13.** 🔴 ¿Qué método HTTP se usa para una actualización **parcial** de un recurso?
- a) `PUT`
- b) `POST`
- c) `PATCH`
- d) `GET`

**F14.** ¿Qué es ECMAScript?
- a) La especificación estándar que define el lenguaje JavaScript
- b) Un framework de React
- c) Una base de datos
- d) Un gestor de paquetes

**F15.** ¿Qué versión de ECMAScript introdujo clases, módulos, `let`/`const` y *arrow functions*?
- a) ES3
- b) ES5
- c) ES6 (ES2015)
- d) ES2020

**F16.** ¿Qué herramienta traduce código ES6+ o JSX a JavaScript compatible con la mayoría de navegadores?
- a) Un linter
- b) Un ODM
- c) Un servidor web
- d) Un transpilador (como Babel)

**F17.** ¿Qué construcción de ES6 representa un valor que estará disponible en el futuro?
- a) Un callback
- b) Un closure
- c) Una promesa (`Promise`)
- d) Un módulo

**F18.** 🔴 ¿Qué pareja de palabras clave (ES2017) permite escribir código asíncrono con aspecto secuencial?
- a) `try`/`catch`
- b) `let`/`const`
- c) `import`/`export`
- d) `async`/`await`

**F19.** ¿Qué afirmación sobre el lenguaje de la pila MERN es correcta?
- a) Usa JavaScript tanto en cliente como en servidor
- b) Usa Python en el servidor y JavaScript en el cliente
- c) Usa Java en ambos lados
- d) Usa TypeScript obligatoriamente

**F20.** ¿Qué stack es equivalente a MERN pero usa Angular en lugar de React?
- a) MEVN
- b) MEAN
- c) LAMP
- d) JAMstack

**F21.** 🔴 ¿Por qué reintentar una petición POST puede ser problemático mientras que reintentar un DELETE no?
- a) Porque POST es seguro y DELETE no
- b) Porque POST no es idempotente (puede crear duplicados) y DELETE sí lo es
- c) Porque DELETE no modifica el servidor
- d) Porque POST no usa HTTP

**F22.** En una arquitectura SPA + API REST, ¿cómo se relacionan el front-end y el back-end?
- a) Son el mismo programa monolítico
- b) El front-end accede directamente a la base de datos
- c) Son dos aplicaciones independientes que se comunican por HTTP intercambiando JSON
- d) El back-end renderiza los componentes React

**F23.** 🔴 ¿Cuál de las siguientes **NO** es una ventaja del enfoque "JavaScript de extremo a extremo" de MERN?
- a) Garantizar transacciones ACID en la base de datos
- b) Reutilizar modelos de datos entre cliente y servidor
- c) Compartir el formato JSON en toda la pila
- d) Un único ecosistema de paquetes (npm)

**F24.** 🔴 En el MVC moderno, ¿qué papel asumen las vistas además de mostrar la interfaz?
- a) Conectar directamente con la base de datos
- b) Funciones de interacción mediante el manejo de eventos de la interfaz
- c) Ejecutar las consultas SQL
- d) Validar los tokens JWT

**F25.** ¿Cuál es el desarrollo correcto del acrónimo CRUD?
- a) Create, Read, Update, Delete
- b) Copy, Read, Undo, Delete
- c) Create, Remove, Update, Drop
- d) Connect, Read, Update, Deploy

**F26.** 🔴 ¿Qué afirmación sobre la relación entre CRUD, SQL, HTTP y MongoDB es correcta?
- a) Son cuatro tecnologías incompatibles entre sí
- b) CRUD solo se aplica a bases de datos relacionales
- c) CRUD es un concepto, y SQL, HTTP y las funciones de MongoDB son implementaciones en planos distintos
- d) HTTP sustituye a SQL en MongoDB

**F27.** ¿Qué tres tecnologías forman "la tríada" base del front-end web?
- a) React, Angular, Vue
- b) Node, Express, MongoDB
- c) HTTP, REST, JSON
- d) HTML, CSS y JavaScript

**F28.** ¿Qué característica de JavaScript lo hace especialmente apto para manipular el comportamiento de la interfaz?
- a) Su tipado estático
- b) Su orientación a eventos
- c) Su compilación a código máquina
- d) Su modelo multihilo

**F29.** 🔴 ¿Qué método HTTP usarías para **reemplazar por completo** un recurso existente?
- a) `GET`
- b) `POST`
- c) `PATCH`
- d) `PUT`

**F30.** 🔴 ¿Qué afirmación describe la "web tradicional" (*server-side rendering*) frente a una SPA?
- a) En la web tradicional cada interacción pide una página HTML completa y el navegador recarga
- b) La web tradicional envía solo datos JSON en cada interacción
- c) La SPA recarga la página completa en cada clic
- d) Ambas renderizan exclusivamente en el servidor

---

# Preguntas MongoDB (20)

**M1.** ¿Qué tipo de base de datos es MongoDB?
- a) NoSQL orientada a documentos
- b) Relacional
- c) Clave-valor en memoria
- d) Orientada a grafos

**M2.** En MongoDB, los datos se organizan en:
- a) Tablas y filas
- b) Nodos y aristas
- c) Colecciones y documentos
- d) Hojas de cálculo

**M3.** ¿Qué campo actúa como clave primaria única de cada documento?
- a) `id`
- b) `key`
- c) `primary`
- d) `_id`

**M4.** Si no se especifica, ¿qué genera MongoDB como identificador de un documento?
- a) Un UUID v4
- b) Un entero autoincremental
- c) Un hash MD5
- d) Un `ObjectId`

**M5.** ¿Qué función inserta varios documentos a la vez?
- a) `insertMany`
- b) `insertOne`
- c) `addAll`
- d) `bulkCreate`

**M6.** ¿Qué función devuelve solo el primer documento que coincide con un filtro?
- a) `find`
- b) `findFirst`
- c) `findOne`
- d) `getOne`

**M7.** 🔴 ¿Qué operador selecciona documentos cuyo campo está dentro de un array de valores?
- a) `$all`
- b) `$in`
- c) `$has`
- d) `$contains`

**M8.** 🔴 ¿Qué operador de actualización incrementa un valor numérico?
- a) `$set`
- b) `$inc`
- c) `$add`
- d) `$push`

**M9.** 🔴 ¿Qué operador añade un elemento a un array de un documento?
- a) `$append`
- b) `$add`
- c) `$push`
- d) `$concat`

**M10.** ¿Qué método encadenable ordena los resultados de una consulta?
- a) `.order()`
- b) `.sort()`
- c) `.orderBy()`
- d) `.arrange()`

**M11.** 🔴 En `db.users.find({}, { name: 1, _id: 0 })`, ¿qué representa el segundo argumento?
- a) Un filtro
- b) Un criterio de ordenación
- c) Una proyección (qué campos devolver)
- d) Un límite de resultados

**M12.** 🔴 ¿Qué hace `db.users.updateMany({ age: { $lt: 18 } }, { $set: { status: "minor" } })`?
- a) Borra los usuarios menores de 18
- b) Fija `status` a "minor" en todos los usuarios con `age` menor que 18
- c) Inserta un usuario menor de 18
- d) Devuelve los usuarios menores de 18

**M13.** ¿Qué es MongoDB Atlas?
- a) Una herramienta gráfica de escritorio
- b) Un ODM
- c) Un servicio de base de datos en la Nube (DBaaS)
- d) Un driver de Node

**M14.** ¿Qué es MongoDB Compass?
- a) Un lenguaje de consulta
- b) Un servicio en la Nube
- c) Un bundler
- d) Una herramienta gráfica (GUI) para explorar y manipular los datos

**M15.** 🔴 ¿Qué es una colección *capped*?
- a) Una colección cifrada
- b) Una colección de tamaño fijo que borra los documentos más antiguos al llenarse
- c) Una colección de solo lectura
- d) Una colección sin índices

**M16.** 🔴 ¿Qué estrategia de modelado guarda el `_id` de otro documento como referencia?
- a) *Embedding* (incrustar)
- b) *Sharding*
- c) *Indexing*
- d) *Referencing* (referenciar)

**M17.** BSON es:
- a) Un formato de texto plano
- b) Una representación binaria del formato JSON
- c) Un lenguaje de consulta
- d) Un protocolo de red

**M18.** 🔴 ¿Cuál de las siguientes **NO** es una familia de bases de datos NoSQL?
- a) Documental
- b) Clave-valor
- c) Relacional
- d) Grafo

**M19.** 🔴 ¿Qué característica permite que documentos de una misma colección no compartan la misma estructura?
- a) Las claves ajenas
- b) La normalización
- c) El esquema dinámico
- d) Las transacciones ACID

**M20.** 🔴 ¿Qué operador combina varias condiciones que deben cumplirse **todas** a la vez?
- a) `$or`
- b) `$and`
- c) `$nor`
- d) `$not`

---

# Preguntas Node.js (20)

**N1.** ¿Sobre qué motor de JavaScript se construye Node.js?
- a) SpiderMonkey
- <mark style="background: #40FF00A6;">b)</mark> V8 (de Google)
- c) Chakra
- d) JavaScriptCore

**N2.** El modelo de ejecución de Node.js es:
- a) Síncrono y bloqueante
- b) Multihilo con un hilo por conexión
- c) Basado en procesos independientes
- <mark style="background: #40FF00A6;">d</mark>) Asíncrono y dirigido por eventos

**N3.** 🔴 ¿Qué nombre recibe el bucle que atiende eventos y dispara los callbacks en Node?
- <mark style="background: #40FF00A6;">a</mark>) *Event loop*
- b) *Render loop*
- c) *Thread pool*
- d) *Message queue*

**N4.** 🔴 ¿Por qué una operación síncrona intensiva en CPU es problemática en Node.js?
- a) Porque Node no soporta CPU
- <mark style="background: #40FF00A6;">b)</mark> Porque, al ser de un solo hilo, bloquea la atención de todos los demás eventos
- c) Porque consume toda la RAM
- d) Porque cierra las conexiones HTTP

**N5.** ¿Qué módulo nativo permite crear un servidor HTTP básico?
- a) `fs`
- b) `path`
- c) `url`
- <mark style="background: #40FF00A6;">d</mark>) `http`

**N6.** 🔴 En `http.createServer(function (req, res) { ... })`, ¿qué representan `req` y `res`?
- <mark style="background: #40FF00A6;">a</mark>) *Request* y *response* (petición y respuesta)
- b) *Router* y *server*
- c) *Read* y *send*
- d) *Resource* y *result*

**N7.** ¿Qué método arranca el servidor e indica el puerto de escucha?
- a) `server.start(8000)`
- b) `server.run(8000)`
- c) `server.open(8000)`
- <mark style="background: #40FF00A6;">d</mark>) `server.listen(8000)`

**N8.** ¿Qué sintaxis clásica (CommonJS) usa Node para importar un módulo?
- a) `import x from 'x'`
- <mark style="background: #40FF00A6;">b</mark>) `require('x')`
- c) `include 'x'`
- d) `using x`

**N9.** 🔴 ¿Cuál de estos módulos **NO** requiere instalarse con npm por venir incluido en Node?
- a) `express`
- <mark style="background: #40FF00A6;">b</mark>) `fs`
- c) `mongoose`
- d) `axios`

**N10.** ¿Qué fichero actúa como "manifiesto" de un proyecto Node?
- a) `node.config`
- b) `index.js`
- c) `.npmrc`
- <mark style="background: #40FF00A6;">d</mark>) `package.json`

**N11.** ¿Qué comando crea un `package.json` mediante un asistente?
- a) `npm new`
- b) `npm create`
- c) `node init`
- <mark style="background: #40FF00A6;">d</mark>) `npm init`

**N12.** 🔴 ¿En qué se diferencian `dependencies` y `devDependencies`?
- a) No hay diferencia
- b) `devDependencies` se instalan globalmente siempre
- c) `dependencies` no se guardan en `package.json`
- <mark style="background: #40FF00A6;">d)</mark> `dependencies` se necesitan en producción; `devDependencies`, solo en desarrollo

**N13.** 🔴 En versionado semántico `MAYOR.MENOR.PARCHE`, ¿qué cambia el número MAYOR?
- a) Una corrección de bug compatible
- <mark style="background: #40FF00A6;">b)</mark> Un cambio incompatible (*breaking change*)
- c) Una nueva funcionalidad compatible
- d) Nada, es decorativo

**N14.** 🔴 ¿Qué prefijo de versión admite **solo** actualizaciones de parche?
- a) `^`
- b) `*`
- <mark style="background: #40FF00A6;">c</mark>) `~`
- d) `>=`

**N15.** 🔴 ¿Para qué sirve `package-lock.json`?
- a) Para cifrar las dependencias
- b) Para listar los scripts
- <mark style="background: #40FF00A6;">c)</mark> Para fijar las versiones exactas de todo el árbol de dependencias y reproducir la instalación
- d) Para configurar el servidor

**N16.** ¿Dónde instala npm los paquetes de un proyecto de forma local?
- a) En `/bin`
- b) En `/lib`
- c) En `/packages`
- <mark style="background: #40FF00A6;">d</mark>) En `/node_modules`

**N17.** 🔴 ¿Por qué `node_modules/` suele incluirse en `.gitignore`?
- a) Porque contiene secretos
- b) Porque git no admite carpetas
- c) Porque es código propietario
- <mark style="background: #40FF00A6;">d)</mark> Porque pesa mucho y se reconstruye con `npm install` desde `package.json`

**N18.** ¿Qué opción instala un paquete de forma global?
- a) `--save`
- b) `--global-only`
- <mark style="background: #40FF00A6;">c</mark>) `-g`
- d) `--dev`

**N19.** ¿Qué característica, además del entorno, contribuyó al éxito de Node.js?
- <mark style="background: #40FF00A6;">a) </mark>Su gestor de paquetes npm y su enorme ecosistema
- b) Su compilador de C++
- c) Su servidor Apache integrado
- d) Su lenguaje de plantillas

**N20.** 🔴 ¿En qué tipo de aplicaciones destaca especialmente Node.js?
- <mark style="background: #40FF00A6;">a)</mark> Aplicaciones intensivas en E/S (APIs, tiempo real)
- b) Cómputo científico intensivo en CPU
- c) Procesamiento por lotes de larga duración
- d) Renderizado 3D

---

# Preguntas Express.js (30)

**E1.** ¿Qué es Express.js?
- a) Una base de datos NoSQL
- <mark style="background: #40FF00A6;">b</mark>) Un framework ligero para Node.js
- c) Una librería de front-end
- d) Un gestor de paquetes

**E2.** ¿Qué hace `app.listen(3000)` en una app Express?
- a) Define una ruta GET
- <mark style="background: #40FF00A6;">b</mark>) Arranca el servidor y escucha en el puerto 3000
- c) Conecta con MongoDB
- d) Registra un middleware

**E3.** En `app.get('/:name', (req, res) => res.send(req.params.name))`, ¿qué es `:name`?
- a) Un query string
- b) Un middleware
- c) Una cabecera HTTP
- <mark style="background: #40FF00A6;">d</mark>) Un parámetro de ruta

**E4.** ¿Con qué método de `res` se envía una respuesta en formato JSON?
- <mark style="background: #40FF00A6;">a</mark>) `res.json()`
- b) `res.send()`
- c) `res.end()`
- d) `res.write()`

**E5.** 🔴 Si un manejador de ruta no invoca ningún método de `res`, ¿qué ocurre?
- a) Express devuelve 200 automáticamente
- b) Se lanza una excepción inmediata
- <mark style="background: #40FF00A6;">c</mark>) La petición del cliente se queda colgada
- d) Se reinicia el servidor

**E6.** ¿Qué significan las siglas REST?
- <mark style="background: #40FF00A6;">a</mark>) Representational State Transfer
- b) Remote Execution Standard Transport
- c) Reliable Service Transaction
- d) Resource Exchange Standard Type

**E7.** En REST, los recursos se identifican y acceden mediante:
- a) Punteros de memoria
- b) Claves primarias SQL
- <mark style="background: #40FF00A6;">c</mark>) URIs
- d) Variables de entorno

**E8.** ¿Qué crea `express.Router()`?
- a) Una conexión a la base de datos
- <mark style="background: #40FF00A6;">b</mark>) Un sistema modular de middleware y rutas (una "miniaplicación")
- c) Un componente React
- d) Un nuevo proceso de Node

**E9.** 🔴 ¿Cómo se monta un router modular `posts` bajo la ruta `/posts` en la app principal?
- <mark style="background: #40FF00A6;">a</mark>) `app.use('/posts', posts)`
- b) `app.get('/posts', posts)`
- c) `app.route('/posts', posts)`
- d) `app.mount('/posts', posts)`

**E10.** Según las reglas de diseño RESTful, ¿cuál de estas rutas es **correcta**?
- a) `/posts/123/editar`
- <mark style="background: #40FF00A6;">b</mark>) `/posts/123`
- c) `/posts/123.pdf`
- d) `/posts/orden/desc`

**E11.** 🔴 Para filtrar, ordenar o paginar un listado de recursos, lo correcto es usar:
- a) La ruta del recurso (`/posts/orden/desc/pagina/2`)
- b) Una cabecera personalizada
- c) El cuerpo de un GET
- <mark style="background: #40FF00A6;">d</mark>) La query string (`/posts?orden=desc&pagina=2`)

**E12.** ¿Qué objeto de Express contiene los parámetros de ruta?
- a) `req.query`
- <mark style="background: #40FF00A6;">b</mark>) `req.params`
- c) `req.body`
- d) `req.headers`

**E13.** ¿Dónde llegan los datos enviados en el cuerpo de una petición POST?
- a) `req.params`
- <mark style="background: #40FF00A6;">b</mark>) `req.body` (con `express.json()`)
- c) `req.query`
- d) `req.cookies`

**E14.** Según REST, ¿qué método HTTP se usa para crear un nuevo recurso?
- <mark style="background: #40FF00A6;">a</mark>) `POST`
- b) `GET`
- c) `PUT`
- d) `PATCH`

**E15.** ¿Qué código de estado indica que un recurso se ha **creado** correctamente?
- a) 200 OK
- <mark style="background: #40FF00A6;">b</mark>) 201 Created
- c) 204 No Content
- d) 301 Moved Permanently

**E16.** 🔴 Tras un `DELETE` correcto que no devuelve cuerpo, ¿qué código es el más adecuado?
- a) 200 OK
- b) 201 Created
- c) 404 Not Found
- <mark style="background: #40FF00A6;">d</mark>) 204 No Content

**E17.** ¿Qué clase de códigos HTTP corresponde a errores del **cliente**?
- a) 2xx
- b) 3xx
- c) 5xx
- <mark style="background: #40FF00A6;">d</mark>) 4xx

**E18.** 🔴 En la negociación de contenido, ¿qué cabecera envía el **cliente** para indicar el formato que desea?
- a) `Content-Type`
- b) `Authorization`
- c) `Host`
- <mark style="background: #40FF00A6;">d</mark>) `Accept`

**E19.** 🔴 Si el servidor no puede devolver el recurso en ninguno de los formatos solicitados, devuelve:
- a) 400 Bad Request
- b) 415 Unsupported Media Type
- c) 200 OK
- <mark style="background: #40FF00A6;">d</mark>) 406 Not Acceptable

**E20.** ¿Qué es un ODM como mongoose?
- <mark style="background: #40FF00A6;">a</mark>) Un mapeador entre un modelo de objetos y una base de datos documental
- b) Un mapeador entre objetos y una base de datos relacional
- c) Un cliente HTTP
- d) Un bundler

**E21.** 🔴 ¿Qué hace `ref` al definir un esquema en mongoose?
- a) Crea un índice único
- b) Valida el formato del campo
- <mark style="background: #40FF00A6;">c</mark>) Establece una relación con otro modelo (similar a una clave ajena)
- d) Cifra el campo

**E22.** 🔴 ¿Qué método de mongoose resuelve una referencia sustituyendo el `_id` por el documento completo?
- a) `join()`
- <mark style="background: #40FF00A6;">b</mark>) `populate()`
- c) `lookup()`
- d) `expand()`

**E23.** ¿Cómo se accede a una variable de entorno en Node/Express?
- a) `env.VARIABLE`
- b) `global.VARIABLE`
- c) `config.VARIABLE`
- <mark style="background: #40FF00A6;">d</mark>) `process.env.VARIABLE`

**E24.** ¿Qué paquete carga habitualmente las variables de un fichero `.env`?
- a) `envconfig`
- b) `nconf`
- c) `vars`
- <mark style="background: #40FF00A6;">d</mark>) `dotenv`

**E25.** ¿Por qué el fichero `.env` debe añadirse a `.gitignore`?
- <mark style="background: #40FF00A6;">a</mark>) Porque contiene credenciales/datos sensibles que no deben subirse al repositorio
- b) Porque es muy pesado
- c) Porque git no soporta ese formato
- d) Porque cambia en cada ejecución

**E26.** En la autenticación con tokens, ¿qué hace el cliente en cada petición tras autenticarse?
- <mark style="background: #40FF00A6;">a</mark>) Envía el token (normalmente en la cabecera)
- b) Vuelve a enviar usuario y contraseña
- c) Abre una nueva sesión en el servidor
- d) No envía nada más

**E27.** 🔴 ¿Cuántas partes tiene un JWT y cuáles son?
- a) Dos: usuario y contraseña
- <mark style="background: #40FF00A6;">b</mark>) Tres: Header, Payload y Signature
- c) Cuatro: Header, Body, Footer y Hash
- d) Una: el token cifrado

**E28.** 🔴 ¿Qué afirmación sobre el payload de un JWT es correcta?
- a) Está cifrado y nadie puede leerlo
- b) Contiene la clave secreta del servidor
- c) Se almacena siempre en el servidor
- <mark style="background: #40FF00A6;">d</mark>) Está solo codificado en Base64URL; cualquiera puede leer su contenido

**E29.** ¿Qué es CORS?
- a) Un formato de base de datos
- <mark style="background: #40FF00A6;">b</mark>) El mecanismo del navegador que controla las peticiones entre orígenes distintos
- c) Un método HTTP
- d) Un tipo de middleware de errores

**E30.** ¿Qué middleware integrado de Express parsea el cuerpo JSON de las peticiones?
- a) `express.static()`
- b) `express.urlencoded()` solamente
- c) `express.cookies()`
- <mark style="background: #40FF00A6;">d</mark>) `express.json()`

---

# Preguntas React.js (30)

**R1.** ¿Qué es React.js, técnicamente?
- a) Un framework completo
- b) Una librería de JavaScript para construir interfaces (SPA)
- c) Un entorno de ejecución del lado del servidor
- d) Una base de datos

**R2.** ¿Qué es el DOM (Document Object Model)?
- a) Un gestor de estados
- b) Un protocolo HTTP
- c) Un motor de base de datos
- d) La representación en árbol jerárquico de las etiquetas de una interfaz

**R3.** 🔴 ¿Qué es el **isomorfismo** en React?
- a) Que todos los componentes tienen la misma forma
- b) Que el estado es inmutable
- c) La capacidad de renderizar HTML tanto en el servidor como en el cliente
- d) Que la app usa un solo componente

**R4.** ¿Qué herramienta genera el esqueleto de un proyecto React?
- a) `express-generator`
- b) `react new`
- c) `create-react-app`
- d) `npm scaffold`

**R5.** 🔴 ¿Qué papel cumple Babel en un proyecto React?
- a) Empaquetar los assets finales
- b) Gestionar el estado global
- c) Transpilar JSX y JavaScript moderno a código compatible con los navegadores
- d) Enrutar las peticiones

**R6.** 🔴 Que React sea "declarativo" significa que:
- a) Describes cómo debe verse la UI para un estado dado y React actualiza el DOM
- b) Manipulas el DOM a mano con `document.getElementById`
- c) El código se ejecuta en el servidor
- d) No se puede usar JavaScript

**R7.** ¿En qué dirección fluyen los datos en React?
- a) Bidireccional
- b) De hijos a padres directamente
- c) Unidireccional, de padres a hijos vía props
- d) Aleatoria

**R8.** En JSX, ¿cómo se inserta una expresión JavaScript en el marcado?
- a) Entre paréntesis `( )`
- b) Entre corchetes `[ ]`
- c) Entre comillas
- d) Entre llaves `{ }`

**R9.** 🔴 Al renderizar una lista con `.map()`, ¿qué prop debe llevar cada elemento?
- a) `id`
- b) `index`
- c) `key`
- d) `ref`

**R10.** ¿Para qué sirven los Fragmentos (`<>…</>`)?
- a) Cifrar el componente
- b) Devolver varios elementos sin añadir un nodo extra al DOM
- c) Crear rutas
- d) Gestionar el estado

**R11.** ¿Cómo se define un componente funcional (sin estado)?
- a) `function X(props) { return ...; }`
- b) `class X extends React.Component { ... }`
- c) `new Component(X)`
- d) `React.create(X)`

**R12.** 🔴 ¿Qué caracteriza a un *Pure Component*?
- a) Solo se rerenderiza si sus props cambian de valor
- b) No tiene método `render`
- c) Siempre se rerenderiza
- d) No puede recibir props

**R13.** 🔴 Un HOC (*Higher Order Component*) es:
- a) Un componente con estado global
- b) Un hook personalizado
- c) Un tipo de ruta
- d) Una función que toma un componente y devuelve otro con funcionalidad extendida

**R14.** ¿Qué fase del ciclo de vida ocurre cuando el componente se inserta por primera vez en el DOM?
- a) Montaje
- b) Actualización
- c) Desmontaje
- d) Renderizado parcial

**R15.** 🔴 ¿Qué método del ciclo de vida es idóneo para lanzar una petición a una API tras el primer render?
- a) `componentDidMount`
- b) `constructor`
- c) `componentWillUnmount`
- d) `render`

**R16.** 🔴 ¿Qué método del ciclo de vida puede **evitar** un render devolviendo `false`?
- a) `componentDidUpdate`
- b) `shouldComponentUpdate`
- c) `componentDidMount`
- d) `render`

**R17.** ¿Qué prop especial recibe el contenido que un componente envuelve?
- a) `content`
- b) `slot`
- c) `children`
- d) `inner`

**R18.** ¿Con qué se definen valores por defecto para las props?
- a) `defaultProps`
- b) `initialProps`
- c) `props.default`
- d) `setDefaults`

**R19.** ¿Para qué sirve `propTypes`?
- a) Cifrar las props
- b) Crear estado
- c) Declarar el tipo de cada prop y si es obligatoria, para validarlas
- d) Definir rutas

**R20.** ¿Cómo se modifica el estado en un componente de clase?
- a) Asignando a `this.state` directamente
- b) Con `this.update()`
- c) Reasignando las props
- d) Con `this.setState()`

**R21.** 🔴 "Elevar el estado" (*lifting state up*) consiste en:
- a) Convertir props en estado
- b) Borrar el estado de un componente
- c) Guardarlo en LocalStorage
- d) Mover el estado al ancestro común más cercano para compartirlo entre hermanos

**R22.** 🔴 ¿Por qué no se debe mutar el estado directamente (p. ej. `state.lista.push(x)`)?
- a) Porque JavaScript lo prohíbe
- b) Porque borra las props
- c) Porque React detecta cambios por referencia; mutar en el sitio puede impedir el rerender
- d) Porque cierra la app

**R23.** ¿Qué add-on de React Router se usa en aplicaciones web?
- a) `react-router-dom`
- b) `react-router-native`
- c) `react-router-web`
- d) `react-dom`

**R24.** ¿Qué componente de React Router renderiza **solo la primera** ruta que coincide?
- a) `BrowserRouter`
- b) `Route`
- c) `Switch`
- d) `Link`

**R25.** ¿Qué componente de React Router crea un hipervínculo de navegación?
- a) `Link`
- b) `Redirect`
- c) `Route`
- d) `Switch`

**R26.** ¿Qué es axios?
- a) Un gestor de estados global
- b) Un bundler
- c) Una base de datos
- d) Un cliente HTTP basado en promesas para consumir APIs REST

**R27.** Tras `axios.get(url).then(res => ...)`, ¿dónde están los datos de la respuesta?
- a) `res.data`
- b) `res.body`
- c) `res.content`
- d) `res.payload`

**R28.** ¿Qué librería aporta componentes de Bootstrap a React?
- a) Redux
- b) axios
- c) reactstrap
- d) mongoose

**R29.** ¿En qué versión se incorporaron los hooks y qué permiten?
- a) React 16.8; usar estado y ciclo de vida en componentes funcionales
- b) React 15; enrutar componentes
- c) React 17; conectar con MongoDB
- d) React 18; cifrar el estado

**R30.** ¿Qué permite un *hook* personalizado (*custom hook*)?
- a) Reutilizar lógica de estado entre componentes sin añadir componentes al árbol
- b) Crear nuevas etiquetas HTML
- c) Sustituir a Babel
- d) Definir rutas del servidor
