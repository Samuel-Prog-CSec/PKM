---
tags:
  - Full-Stack
  - Examen
  - Repaso
Fecha de actualización: 2026-06-22
---
---

> [!warning]+ Spoiler
> Soluciones de [[Examen de práctica (MERN Full-Stack)]]. Úsalas solo para corregir.

# Parte I — Preguntas de desarrollo

**1. Front-end, back-end y full-stack.**
Un desarrollador **front-end** trabaja del lado del **cliente**: todo lo que el usuario ve y con lo que interactúa (vistas, interacción, usabilidad, accesibilidad), con tecnologías como HTML, CSS, JavaScript y React. Un desarrollador **back-end** trabaja del lado del **servidor**: la lógica de negocio, las transacciones, los protocolos de comunicación (HTTP) y las bases de datos; en MERN, Node, Express y MongoDB. El **full-stack** es responsable de ambos lados —diseña, implementa y despliega la aplicación completa—, aunque suele especializarse más en uno. El criterio que los separa es **el lado de la arquitectura cliente-servidor** en el que actúa cada uno.

**2. CRUD ↔ SQL ↔ HTTP.**
CRUD es el acrónimo de **Create, Read, Update, Delete**, las cuatro operaciones básicas sobre información almacenada. Correspondencias: **Create** = `INSERT` (SQL) = `POST` (HTTP); **Read** = `SELECT` = `GET`; **Update** = `UPDATE` = `PUT`/`PATCH`; **Delete** = `DELETE` = `DELETE`. CRUD es un **concepto**; SQL, HTTP y las funciones de MongoDB (`insertOne`, `find`, `updateOne`, `deleteOne`) son **implementaciones** del mismo en planos distintos.

**3. La pila MERN.**
MERN = **MongoDB + Express + React + Node**: cuatro tecnologías que permiten construir una aplicación full-stack usando **JavaScript** en cliente y servidor. **React** = front-end/cliente (SPA con componentes y Virtual DOM); **Node.js** = servidor (entorno de ejecución de JS, asíncrono); **Express.js** = servidor (framework ligero para la API REST); **MongoDB** = servidor/datos (base de datos NoSQL documental). MEAN es el stack equivalente con Angular en lugar de React.

**4. MVC y SPA.**
MVC separa la aplicación en tres capas: **Modelo** (datos y acceso a la BBDD, a través de mapeadores), **Vista** (presentación, en última instancia HTML) y **Controlador** (lógica; enlaza vista y modelo). En una **SPA**, las capas se reorganizan: la vista y buena parte de la lógica se ejecutan **en el navegador del cliente**, y el servidor expone una **API** cuyos controladores responden con **JSON** a peticiones HTTP, en lugar de enviar HTML completo. Así, front-end (React) y back-end (la API REST con Express) son dos aplicaciones independientes que se comunican por HTTP/JSON; React añade además un flujo de datos **unidireccional** (Flux).

**5. REST y sus características.**
REST (*REpresentational State Transfer*) es un **estilo** de intercambio y manipulación de datos en servicios de Internet, **basado en HTTP**, con respuestas en formatos estándar (JSON/XML). Características: se apoya en los **métodos HTTP** (GET/POST/PUT/DELETE) que corresponden a CRUD; sigue un esquema **petición-respuesta**; es **stateless** (cada petición es autónoma, sin sesión en el servidor); manipula **recursos** identificados por **URIs**; aporta **escalabilidad** y **separación cliente/servidor**; y es **independiente de plataforma y lenguaje**. Las APIs pueden ser públicas o privadas y requerir autenticación.

**6. Middleware y ciclo petición-respuesta.**
Un **middleware** es una función con acceso a la petición (`req`), la respuesta (`res`) y la siguiente función del ciclo (`next`). Puede ejecutar código, modificar `req`/`res`, terminar el ciclo o ceder el control con `next()`. Toda petición atraviesa una **cadena de middlewares** (logging, parseo de JSON, ficheros estáticos, autenticación, CORS) antes de llegar a su manejador final, y **el orden de registro importa**. El manejador debe cerrar el ciclo con un método de `res` (`send`, `json`, `status`…); si no, la petición se queda colgada.

**7. ODM y mongoose.**
Un **ODM** (*Object Document Mapper*) traduce entre un modelo de objetos y una base de datos documental (MongoDB), aportando abstracción de alto nivel sin escribir consultas a mano; es la capa **Modelo** del MVC. **mongoose** es el ODM de MERN: define **esquemas** con datos fuertemente tipados (8 SchemaTypes: `String`, `Number`, `Date`, `Buffer`, `Boolean`, `Mixed`, `ObjectId`, `Array`), deriva **modelos** de esos esquemas (`mongoose.model`), mapea cada modelo a un documento de MongoDB, valida los datos y relaciona modelos con `ref` (equivalente a las claves ajenas; se resuelven con `populate`).

**8. Autenticación con tokens y JWT.**
En la autenticación basada en **tokens**, el cliente se autentica una vez (usuario y contraseña), el servidor valida y **genera un token** que le devuelve, y en cada petición posterior el cliente **envía el token** para que el servidor lo valide. **JWT** (JSON Web Token) es el formato más usado: tiene tres partes codificadas en Base64URL —**Header** (tipo y algoritmo), **Payload** (datos del usuario) y **Signature** (valida la integridad)—. Es **stateless** (no se guarda en el servidor; el payload lleva la información), se almacena en una Cookie o en LocalStorage, se envía en la cabecera y **expira**. El header y el payload solo están **codificados**, no cifrados.

**9. props vs state.**
Ambos son objetos JavaScript planos cuyo cambio dispara `render()`. Las **props** son atributos de **configuración recibidos del componente padre** y son **inmutables** (un componente no cambia sus propias props). El **state** es la representación del componente en un instante, lo **gestiona el propio componente** y es **mutable** solo a través de `setState()` (se define en el constructor con `this.state`). Regla: si el componente necesita **modificar** el dato durante su vida → **state**; si no → **prop**. El flujo de datos es unidireccional (el state de un padre se pasa como props a los hijos).

**10. React hooks.**
Los **hooks** (React 16.8) son funciones que permiten "enganchar" el estado y el ciclo de vida desde **componentes funcionales**, eliminando la necesidad de clases. **`useState`** gestiona el estado: devuelve un par `[valor, función actualizadora]` y su argumento es el estado inicial. **`useEffect`** ejecuta **efectos secundarios** y unifica `componentDidMount` + `componentDidUpdate` + `componentWillUnmount`; su **segundo argumento** (array de dependencias) controla **cuándo** se ejecuta: `[]` lo ejecuta una sola vez tras el primer render, `[deps]` cuando cambian esas dependencias, y **omitirlo provoca un bucle infinito**; devolver una función dentro del efecto sirve para limpiar. Reglas: solo en el nivel superior y solo desde componentes funcionales.

# Parte II — Clave de respuestas (tipo test)

1. **b)** `POST` — Create = `INSERT` (SQL) = `POST` (HTTP).
2. **c)** El full-stack implementa cliente **y** servidor.
3. **d)** `POST` no es idempotente (repetirlo crea recursos duplicados; GET, PUT y DELETE sí lo son).
4. **c)** Controlador: responde a las acciones y enlaza vista y modelo.
5. **b)** MongoDB, Express, React, Node.
6. **b)** JSON — en una SPA el servidor expone una API que responde datos, no HTML completo.
7. **b)** BSON (representación binaria de JSON).
8. **b)** `find` con `$gte` devuelve los documentos con `age` ≥ 18.
9. **b)** Documento (colección ≈ tabla, documento ≈ fila/registro).
10. **c)** Entorno de ejecución de JavaScript del lado del servidor.
11. **b)** `npm install <pkg> --save` instala y guarda en `dependencies`.
12. **c)** `^4.17.1` admite menores y parches dentro de `4.x.x` (no salta a 5.x).
13. **b)** Registra una función manejadora para una petición HTTP `GET` sobre la ruta raíz `/`. *(La opción a es la trampa típica: confundirlo con un componente React.)*
14. **b)** Función `(req, res, next)` del ciclo petición-respuesta.
15. **b)** Cuatro parámetros `(err, req, res, next)`; Express lo reconoce por esa aridad.
16. **c)** Cada petición es autónoma; el servidor no guarda estado entre peticiones.
17. **b)** `400 Bad Request` (datos de entrada inválidos/ausentes).
18. **b)** `403 Forbidden` — autenticado pero sin permiso. *(401 sería "no identificado".)*
19. **d)** `5xx` = error del servidor (`4xx` sería error del cliente).
20. **b)** Un ODM entre MongoDB y la aplicación.
21. **c)** Signature — se genera con header y payload y valida que no se han alterado.
22. **b)** Extensión de la sintaxis de JavaScript que mezcla JS y HTML/XML.
23. **b)** `className` (`class` es palabra reservada en JS).
24. **c)** Props inmutables (del padre); state mutable (del propio componente).
25. **b)** Renderiza solo lo que cambia, evitando repintar todo el DOM.
26. **b)** Un array `[valor, setter]`.
27. **c)** Una sola vez tras el primer render (como `componentDidMount`). *(Omitir el array sí causaría el bucle de la opción d.)*
28. **b)** Express Router = servidor (endpoints HTTP); React Router = cliente (componentes).
29. **b)** Emitiendo una **acción** que un **reducer** (función pura) procesa para devolver un nuevo estado.
30. **b)** `componentDidMount`, `componentDidUpdate` y `componentWillUnmount`.

> [!tip]+ Las más difíciles
> Las preguntas **3** (idempotencia), **12** (semver `^`), **18** (401 vs 403), **21** (firma del JWT), **27** (dependencias de `useEffect`) y **28** (Express vs React Router) son las de mayor dificultad: repásalas si fallaste alguna.
