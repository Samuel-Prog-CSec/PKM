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

---

# Clave — Fundamentos

1. **F1 → a)** Front-end domina HTML, CSS y JavaScript.
2. **F2 → a)** Cliente y servidor se comunican por HTTP.
3. **F3 → c)** El perfil full-stack lo popularizó Facebook.
4. **F4 → b)** El back-end gestiona la lógica y las transacciones.
5. **F5 → c)** Patrón = solución reutilizable a un problema recurrente.
6. **F6 → c)** La Vista produce el HTML de la interfaz.
7. **F7 → b)** El Modelo conecta con la BBDD vía mapeadores.
8. **F8 → a)** SPA = Single Page Application.
9. **F9 → c)** Flux: flujo de datos unidireccional, pensado para React.
10. **F10 → a)** Read = `SELECT`.
11. **F11 → b)** Delete = `DELETE`.
12. **F12 → c)** Solo `GET` es seguro (no modifica el servidor).
13. **F13 → c)** `PATCH` = actualización parcial (`PUT` sería total).
14. **F14 → a)** ECMAScript = la especificación estándar de JavaScript.
15. **F15 → c)** ES6 (ES2015) trajo clases, módulos, `let`/`const`, arrow functions.
16. **F16 → d)** Un transpilador (Babel) traduce ES6+/JSX a código compatible.
17. **F17 → c)** Una promesa representa un valor futuro.
18. **F18 → d)** `async`/`await` (ES2017) da aspecto secuencial al código asíncrono.
19. **F19 → a)** MERN usa JavaScript en cliente y servidor.
20. **F20 → b)** MEAN = MERN con Angular en lugar de React.
21. **F21 → b)** POST no es idempotente (duplica); DELETE sí lo es.
22. **F22 → c)** Front y back son apps independientes que hablan por HTTP/JSON.
23. **F23 → a)** Las transacciones ACID no son una ventaja de "JS en todo" (de hecho son típicas del modelo relacional, no del documental).
24. **F24 → b)** En el MVC moderno las vistas manejan eventos de interacción.
25. **F25 → a)** Create, Read, Update, Delete.
26. **F26 → c)** CRUD es concepto; SQL/HTTP/Mongo son implementaciones.
27. **F27 → d)** La tríada base del front-end: HTML, CSS y JavaScript.
28. **F28 → b)** La orientación a eventos de JS lo hace apto para la interfaz.
29. **F29 → d)** `PUT` reemplaza el recurso completo.
30. **F30 → a)** Web tradicional = página HTML completa por interacción, con recarga.

# Clave — MongoDB

1. **M1 → a)** MongoDB es NoSQL orientada a documentos.
2. **M2 → c)** Colecciones y documentos.
3. **M3 → d)** `_id` es la clave primaria.
4. **M4 → d)** MongoDB genera un `ObjectId`.
5. **M5 → a)** `insertMany` inserta varios.
6. **M6 → c)** `findOne` devuelve el primero.
7. **M7 → b)** `$in` = el campo está en un array de valores.
8. **M8 → b)** `$inc` incrementa un número.
9. **M9 → c)** `$push` añade a un array.
10. **M10 → b)** `.sort()` ordena.
11. **M11 → c)** El segundo argumento de `find` es la proyección.
12. **M12 → b)** Fija `status` a "minor" en los `age < 18`.
13. **M13 → c)** Atlas = DBaaS (base de datos en la Nube).
14. **M14 → d)** Compass = herramienta gráfica (GUI).
15. **M15 → b)** *Capped* = tamaño fijo; borra lo más antiguo al llenarse.
16. **M16 → d)** *Referencing* guarda el `_id` de otro documento.
17. **M17 → b)** BSON = representación binaria de JSON.
18. **M18 → c)** Relacional NO es una familia NoSQL (es la trampa).
19. **M19 → c)** El esquema dinámico permite documentos heterogéneos.
20. **M20 → b)** `$and` exige que se cumplan todas las condiciones.

# Clave — Node.js

1. **N1 → b)** Node se construye sobre el motor V8.
2. **N2 → d)** Modelo asíncrono y dirigido por eventos.
3. **N3 → a)** El *event loop* atiende eventos y dispara callbacks.
4. **N4 → b)** Al ser de un solo hilo, una tarea CPU-intensiva bloquea todo.
5. **N5 → d)** El módulo nativo `http` crea servidores.
6. **N6 → a)** `req`/`res` = request/response (petición/respuesta).
7. **N7 → d)** `server.listen(8000)` fija el puerto.
8. **N8 → b)** `require('x')` (CommonJS).
9. **N9 → b)** `fs` es nativo; no necesita npm.
10. **N10 → d)** `package.json` es el manifiesto.
11. **N11 → d)** `npm init` crea el `package.json`.
12. **N12 → d)** `dependencies` = producción; `devDependencies` = desarrollo.
13. **N13 → b)** El número MAYOR indica cambios incompatibles.
14. **N14 → c)** `~` admite solo parches.
15. **N15 → c)** `package-lock.json` fija versiones exactas y reproduce la instalación.
16. **N16 → d)** Los paquetes locales van a `/node_modules`.
17. **N17 → d)** `node_modules/` pesa mucho y se reconstruye con `npm install`.
18. **N18 → c)** `-g` instala de forma global.
19. **N19 → a)** npm y su ecosistema impulsaron a Node.
20. **N20 → a)** Node destaca en aplicaciones intensivas en E/S.

# Clave — Express.js

1. **E1 → b)** Express = framework ligero para Node.
2. **E2 → b)** `app.listen(3000)` arranca el servidor en el puerto.
3. **E3 → d)** `:name` es un parámetro de ruta.
4. **E4 → a)** `res.json()` envía JSON.
5. **E5 → c)** Sin método de `res`, la petición se queda colgada.
6. **E6 → a)** REST = Representational State Transfer.
7. **E7 → c)** Los recursos se identifican por URIs.
8. **E8 → b)** `express.Router()` crea una "miniaplicación" modular.
9. **E9 → a)** Se monta con `app.use('/posts', posts)`.
10. **E10 → b)** `/posts/123` (sin acciones ni formato en la ruta).
11. **E11 → d)** Filtrar/ordenar/paginar va en la query string.
12. **E12 → b)** `req.params` contiene los parámetros de ruta.
13. **E13 → b)** El cuerpo llega en `req.body` (con `express.json()`).
14. **E14 → a)** `POST` crea un recurso.
15. **E15 → b)** `201 Created` para una creación correcta.
16. **E16 → d)** `204 No Content` tras un DELETE sin cuerpo.
17. **E17 → d)** `4xx` = error del cliente.
18. **E18 → d)** El cliente envía `Accept` para indicar el formato deseado.
19. **E19 → d)** `406 Not Acceptable` si no puede servir ningún formato.
20. **E20 → a)** ODM = mapeador objeto ↔ base de datos documental.
21. **E21 → c)** `ref` relaciona modelos (como una clave ajena).
22. **E22 → b)** `populate()` sustituye el `_id` por el documento completo.
23. **E23 → d)** `process.env.VARIABLE`.
24. **E24 → d)** `dotenv` carga el `.env`.
25. **E25 → a)** El `.env` lleva credenciales; no debe subirse al repositorio.
26. **E26 → a)** El cliente envía el token en cada petición (en la cabecera).
27. **E27 → b)** JWT = Header + Payload + Signature.
28. **E28 → d)** El payload solo está codificado en Base64URL, no cifrado.
29. **E29 → b)** CORS controla las peticiones entre orígenes distintos.
30. **E30 → d)** `express.json()` parsea el cuerpo JSON.

# Clave — React.js

1. **R1 → b)** React es una librería para construir interfaces (SPA).
2. **R2 → d)** El DOM es el árbol jerárquico de etiquetas de la interfaz.
3. **R3 → c)** Isomorfismo = renderizar HTML en servidor y cliente.
4. **R4 → c)** `create-react-app` genera el esqueleto.
5. **R5 → c)** Babel transpila JSX/JS moderno a código compatible.
6. **R6 → a)** Declarativo = describes la UI según el estado; React actualiza el DOM.
7. **R7 → c)** Flujo unidireccional: de padres a hijos vía props.
8. **R8 → d)** Las expresiones JS van entre llaves `{ }`.
9. **R9 → c)** Cada elemento de una lista necesita una `key` única.
10. **R10 → b)** Los Fragmentos devuelven varios elementos sin nodo extra.
11. **R11 → a)** Un componente funcional es `function X(props) { return ...; }`.
12. **R12 → a)** Un *Pure Component* solo se rerenderiza si cambian sus props.
13. **R13 → d)** Un HOC envuelve un componente y lo devuelve con más funcionalidad.
14. **R14 → a)** El **montaje** inserta el componente en el DOM por primera vez.
15. **R15 → a)** `componentDidMount` para peticiones tras el primer render.
16. **R16 → b)** `shouldComponentUpdate` puede saltar el render devolviendo `false`.
17. **R17 → c)** El contenido envuelto llega por `children`.
18. **R18 → a)** `defaultProps` define valores por defecto.
19. **R19 → c)** `propTypes` declara y valida el tipo de cada prop.
20. **R20 → d)** El estado se modifica con `this.setState()`.
21. **R21 → d)** *Lifting state up* = mover el estado al ancestro común.
22. **R22 → c)** React compara por referencia; mutar en el sitio impide el rerender.
23. **R23 → a)** Para web se usa `react-router-dom`.
24. **R24 → c)** `Switch` renderiza solo la primera ruta coincidente.
25. **R25 → a)** `Link` crea el hipervínculo de navegación.
26. **R26 → d)** axios = cliente HTTP basado en promesas.
27. **R27 → a)** Los datos llegan en `res.data`.
28. **R28 → c)** reactstrap aporta componentes de Bootstrap.
29. **R29 → a)** Los hooks llegan en React 16.8 y dan estado/ciclo de vida a componentes funcionales.
30. **R30 → a)** Un *custom hook* reutiliza lógica sin añadir componentes al árbol.

> [!tip]+ Preguntas marcadas como difíciles (🔴)
> **Fundamentos**: F9, F12, F13, F18, F21, F23, F24, F26, F29, F30.
> **MongoDB**: M7, M8, M9, M11, M12, M15, M16, M18, M19, M20.
> **Node.js**: N3, N4, N6, N9, N12, N13, N14, N15, N17, N20.
> **Express.js**: E5, E9, E11, E16, E18, E19, E21, E22, E27, E28.
> **React.js**: R3, R5, R6, R9, R12, R13, R15, R16, R21, R22.
