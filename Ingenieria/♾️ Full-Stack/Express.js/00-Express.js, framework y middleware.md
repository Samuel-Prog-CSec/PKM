---
tags:
  - Full-Stack
  - Express
  - Backend
Fecha de actualización: 2026-06-22
Nota previa: "[[01-package.json y el gestor de paquetes npm]]"
Nota siguiente: "[[01-APIs REST (principios y características)]]"
Area: "[[Express.js.base|Express.js]]"
---
---

<mark style="background: #ADCCFFA6;">Express.js es un framework ligero para Node.js</mark>, una de las piezas del back-end en MERN. Destaca por su facilidad y optimización en el manejo de solicitudes HTTP, y es la herramienta esencial para implementar una **API REST**. Se instala como un paquete más del proyecto:

```shell-session
$ npm install express --save
```

# Hola Mundo en Express

```javascript
var express = require('express');
var app = express();

app.get('/', function (req, res) {
  res.send('¡Hola Mundo!');
});

app.listen(3000, function () {
  console.log('Escuchando en el puerto 3000');
});
```

Se importa el módulo `express` y se crea una instancia `app`. `app.get('/', ...)` registra un manejador para una **petición GET** a la ruta raíz, que responde con un mensaje (otra ruta devolvería `404 Not Found`). `app.listen(3000)` arranca el servidor en el puerto 3000. Las rutas pueden llevar **parámetros**:

```javascript
app.get('/:name', function (req, res) {
  res.send('¡Hola ' + req.params.name + '!');
});
// GET /Jesus  →  "¡Hola Jesus!"
```

<mark style="background: #8000E1A6;">Frente al servidor `http` puro de Node, Express elimina el código repetitivo y aporta enrutado, parámetros, middleware y utilidades de respuesta.</mark> Por eso se ejecuta **sobre** [[00-Node.js, entorno de ejecución del servidor|Node.js]], no en su lugar.

# Middleware: el corazón de Express

<mark style="background: #ADCCFFA6;">Un middleware es una función con acceso a la petición (`req`), la respuesta (`res`) y la siguiente función del ciclo (`next`).</mark> Puede ejecutar código, modificar `req`/`res`, terminar el ciclo de petición-respuesta o ceder el control al siguiente middleware con `next()`.

```javascript
app.use(function (req, res, next) {
  console.log('Petición recibida:', Date.now());
  next();   // pasa al siguiente middleware / manejador
});
```

<mark style="background: #FFB86CA6;">Toda petición en Express atraviesa una cadena de middlewares antes de llegar a su manejador final.</mark> Express integra middlewares para *logging*, parseo de JSON (`express.json()`), servir ficheros estáticos (`express.static`), cookies, etc. El propio enrutado ([[02-Rutas, manejadores y Express Router|Express Router]]) es un sistema de middleware.

# Tipos de middleware

Express clasifica los middlewares según dónde y cómo se registran:

| Tipo | Ejemplo |
| - | - |
| **De aplicación** | `app.use(fn)` — corre en toda petición |
| **De router** | `router.use(fn)` — limitado a un router |
| **De manejo de errores** | `(err, req, res, next) => {}` — 4 argumentos |
| **Integrado** | `express.json()`, `express.static()` |
| **De terceros** | `cors`, `morgan`, `helmet` |

<mark style="background: #FFB86CA6;">El orden importa: los middlewares se ejecutan en el orden en que se registran.</mark> Uno de autenticación debe registrarse antes que las rutas que protege.

```javascript
app.use(express.json());            // parsea el body JSON de las peticiones
app.use(cors());                    // habilita CORS
app.use('/api', autenticar, api);   // 'autenticar' corre antes que las rutas /api
```

> [!info]+ CORS, en breve
> **CORS** (*Cross-Origin Resource Sharing*) es el mecanismo del navegador que controla si una página de un **origen** (dominio + puerto) puede pedir recursos a otro. En MERN, el front-end (React, puerto 3000) y la API (Express, puerto 5000) están en orígenes distintos, así que el navegador bloquea las peticiones salvo que el servidor responda con las cabeceras CORS adecuadas; el middleware `cors()` las añade. Es un punto clásico de fricción —y de revisión en pentest web—.

> [!info]+ El middleware de errores
> Se distingue por tener **cuatro** parámetros `(err, req, res, next)`. Express lo reconoce por esa aridad y lo invoca cuando un manejador llama a `next(err)`. Suele registrarse el último.

> [!important]+ Para el examen
> Express.js = **framework de Node.js** para construir servidores web y **APIs REST**. Un **middleware** es una función `(req, res, next)` que se ejecuta dentro del ciclo de petición-respuesta; con `next()` cede el control al siguiente. `app.get/post/put/delete(ruta, manejador)` registra rutas; `app.use(mw)` registra middleware.

# Generación y configuración

Existe la herramienta de *scaffolding* `express-generator` (comando `express`), que crea el **esqueleto** de una aplicación (directorios `/routes`, `/public`, `/bin/www`, `app.js`…). En MERN las vistas las pone React, así que de ese esqueleto interesa sobre todo la gestión de rutas y recursos.

Configuración y objetos de petición/respuesta (recetario):

```javascript
// Configuración
app.set('title', 'MiApp');      app.get('title');
app.enable('trust proxy');      app.disable('trust proxy');

// Petición (req)
req.path;  req.method;  req.params.name;  req.query.q;  req.cookies;  req.headers['host'];

// Respuesta (res)
res.send('hi');     res.json({ a: 2 });     res.status(404);
res.redirect('/');  res.set('Content-Type', 'text/html');
```

`app.use(express.static(__dirname + '/public'))` sirve ficheros estáticos; `app.locals` define variables accesibles desde las vistas.
