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

5. ¿Qué es **REST**? Enumera sus características principales.

6. ¿Qué es un **middleware** en Express.js? Describe el **ciclo petición-respuesta** y el papel de `next()`.

7. ¿Qué es un **ODM**? Explica el papel de **mongoose** en la pila MERN (esquema, modelo, relaciones).

8. Explica la **autenticación basada en tokens** y la estructura de un **JWT** (sus tres partes).

9. Diferencia entre **props** y **state** en React: origen, mutabilidad y cómo se modifica cada uno.

10. ¿Qué son los **React hooks**? Explica `useState` y `useEffect`, y qué controla el segundo argumento de `useEffect`.

# Parte II — Preguntas tipo test

Marca la **única** opción correcta.

**1.** ¿Qué método HTTP se corresponde con la operación **Create** de CRUD?
- a) `GET`
- b) `POST`
- c) `PUT`
- d) `DELETE`

**2.** Sobre el desarrollador **full-stack**, ¿qué afirmación es correcta?
- a) Trabaja exclusivamente del lado del cliente.
- b) Solo se ocupa de la base de datos.
- c) Es responsable de la implementación tanto en el cliente como en el servidor.
- d) No necesita conocer protocolos de comunicación.

**3.** ¿Cuál de los siguientes métodos HTTP **NO** es idempotente?
- a) `GET`
- b) `PUT`
- c) `DELETE`
- d) `POST`

**4.** En el patrón MVC, ¿qué capa contiene la lógica que responde a las acciones del usuario y enlaza vista y modelo?
- a) Modelo
- b) Vista
- c) Controlador
- d) Servicio

**5.** ¿Qué tecnologías componen la pila MERN?
- a) MySQL, Express, React, Node
- b) MongoDB, Express, React, Node
- c) MongoDB, Ember, React, Node
- d) MongoDB, Express, Redux, Node

**6.** En una SPA construida con MERN, ¿qué devuelve normalmente el servidor ante una petición del cliente?
- a) Una página HTML completa renderizada en el servidor.
- b) Datos en formato JSON.
- c) Una hoja de estilos CSS.
- d) Código SQL.

**7.** ¿En qué formato almacena MongoDB los documentos?
- a) JSON
- b) BSON
- c) XML
- d) CSV

**8.** ¿Qué hace la consulta `db.users.find({ age: { $gte: 18 } })`?
- a) Inserta usuarios mayores o iguales a 18.
- b) Devuelve los usuarios con `age` mayor o igual que 18.
- c) Borra los usuarios menores de 18.
- d) Actualiza la edad a 18.

**9.** ¿Cuál es el equivalente en MongoDB de una **fila/registro** de una base de datos relacional?
- a) Colección
- b) Documento
- c) Campo
- d) Índice

**10.** ¿Qué afirmación describe mejor a **Node.js**?
- a) Un framework de front-end.
- b) Una base de datos NoSQL.
- c) Un entorno de ejecución de JavaScript del lado del servidor.
- d) Un gestor de paquetes.

**11.** ¿Qué comando instala un paquete y lo añade a las dependencias de `package.json`?
- a) `npm start`
- b) `npm install <pkg> --save`
- c) `npm init`
- d) `node <pkg>`

**12.** En `"express": "^4.17.1"`, ¿qué actualizaciones admite el prefijo `^`?
- a) Solo la versión exacta 4.17.1.
- b) Cualquier versión, incluida la 5.x.
- c) Versiones menores y parches dentro de 4.x.x.
- d) Solo parches (4.17.x).

**13.** Dada la llamada `router.get('/', function(req, res){ ... })`, ¿qué hace?
- a) Registra el componente React que se renderiza en la *home page*.
- b) Instala una función manejadora para una petición HTTP `GET` sobre la ruta raíz `/` del servidor.
- c) Define una ruta de navegación del cliente con React Router.
- d) Crea una conexión con la base de datos en la raíz.

**14.** ¿Qué es un **middleware** en Express?
- a) Una base de datos intermedia.
- b) Una función con acceso a `req`, `res` y `next` que se ejecuta en el ciclo petición-respuesta.
- c) Un componente visual de React.
- d) Un tipo de documento de MongoDB.

**15.** ¿Qué distingue a un middleware de **manejo de errores** en Express?
- a) Se registra siempre el primero.
- b) Tiene cuatro parámetros: `(err, req, res, next)`.
- c) Solo funciona con peticiones `GET`.
- d) No puede llamar a `next()`.

**16.** ¿Qué significa que REST sea **stateless**?
- a) Que no usa el protocolo HTTP.
- b) Que el servidor guarda la sesión de cada cliente.
- c) Que cada petición contiene toda la información necesaria y el servidor no guarda estado entre peticiones.
- d) Que no devuelve códigos de estado.

**17.** Una petición a la que le falta un dato de entrada obligatorio debería responder con:
- a) `200 OK`
- b) `400 Bad Request`
- c) `301 Moved Permanently`
- d) `500 Internal Server Error`

**18.** Un usuario **autenticado** intenta acceder a un recurso para el que no tiene permisos. ¿Qué código es el correcto?
- a) `401 Unauthorized`
- b) `403 Forbidden`
- c) `404 Not Found`
- d) `200 OK`

**19.** ¿Qué clase de código de estado HTTP indica un **error del lado del servidor**?
- a) `2xx`
- b) `3xx`
- c) `4xx`
- d) `5xx`

**20.** ¿Qué es **mongoose** en la pila MERN?
- a) Un empaquetador de módulos (*bundler*).
- b) Un ODM (Object Document Mapper) entre MongoDB y la aplicación.
- c) Un cliente HTTP.
- d) Un motor de plantillas de vistas.

**21.** ¿Cuál de las tres partes de un **JWT** garantiza que el contenido no ha sido alterado?
- a) Header
- b) Payload
- c) Signature
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
- b) Express Router enruta en el servidor (endpoints HTTP); React Router enruta en el cliente (componentes).
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
