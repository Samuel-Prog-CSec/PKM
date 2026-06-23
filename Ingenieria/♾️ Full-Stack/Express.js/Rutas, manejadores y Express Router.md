---
tags:
  - Full-Stack
  - Express
  - REST
  - Backend
Fecha de actualización: 2026-06-22
Nota previa: "[[APIs REST (principios y características)]]"
Nota siguiente: "[[CRUD, métodos HTTP y códigos de estado]]"
Area: "[[Express.js.base|Express.js]]"
---
---

<mark style="background: #ADCCFFA6;">El *routing* (direccionamiento) es la definición de los puntos finales o *endpoints* de la aplicación y de cómo responden a las solicitudes HTTP del cliente</mark>, mediante una función **manejadora** que procesa la petición y construye la respuesta.

# Estructura de una ruta

```javascript
app.METHOD(PATH, HANDLER);
```

- `app` — instancia de Express.
- `METHOD` — método HTTP en minúsculas (`get`, `post`, `put`, `delete`…).
- `PATH` — la ruta o **endpoint** en el servidor.
- `HANDLER` — la función que se ejecuta cuando la ruta coincide.

```javascript
app.get('/', function (req, res) {
  res.send('¡Hola Mundo!');
});
app.get('/about', function (req, res) {
  res.send('about');
});
```

<mark style="background: #FF5582A6;">`app.get('/', ...)` registra un manejador para una petición HTTP GET, siendo `'/'` la ruta o camino absoluto de la raíz en el servidor.</mark> Es la lectura correcta del típico enunciado de examen sobre `router.get('/', ...)`. El `PATH` admite incluso expresiones regulares.

# Manejadores y `next()`

El manejador recibe normalmente `req` (petición) y `res` (respuesta), y opcionalmente `next`. Un manejador puede ceder el control con `next()` para encadenar varias funciones en una misma ruta:

```javascript
app.get('/example/b', function (req, res, next) {
  console.log('pasa al siguiente...');
  next();
}, function (req, res) {
  res.send('¡Hola desde B!');
});
```

El objeto `res` debe cerrar el ciclo con algún método; si ninguno se invoca, la petición se queda colgada:

| Método de `res` | Acción |
| - | - |
| `res.send()` | Envía una respuesta de varios tipos |
| `res.json()` | Envía una respuesta JSON |
| `res.sendStatus()` | Fija el código de estado y lo envía como cuerpo |
| `res.redirect()` | Redirige la solicitud |
| `res.sendFile()` | Envía un archivo |
| `res.render()` | Renderiza una plantilla de vista |
| `res.end()` | Finaliza la respuesta |

# Reglas para nombrar rutas (diseño RESTful)

- **No incluir acciones**: `/posts/123` (correcto), no `/posts/123/editar`. La operación la determina el método HTTP.
- **Independientes de formato**: `/posts/123`, no `/posts/123.pdf`.
- **Jerarquía lógica**: `/usuarios/007/posts/123`, no `/posts/123/usuario/007`.
- **Filtrar, ordenar y paginar en la query**, no en la ruta: `/posts?fecha-desde=2007&orden=DESC&pagina=2`.

# Express Router

<mark style="background: #ADCCFFA6;">`express.Router()` permite crear manejadores de rutas modulares.</mark> Una instancia `Router` es un sistema completo de middleware y direccionamiento; por eso se la conoce como una **"miniaplicación"**. <mark style="background: #FFB86CA6;">La potencia de Express reside en su manejo de rutas mediante el Router.</mark>

```javascript
// routes/posts.js
var express = require('express');
var router = express.Router();

// middleware específico de este router
router.use(function (req, res, next) {
  console.log('Fecha actual:', Date.now());
  next();
});

router.get('/', function (req, res) {
  res.send('Página inicial de los posts');
});
router.get('/about', function (req, res) {
  res.send('Acerca de los posts');
});

module.exports = router;
```

Se **monta** en la aplicación principal con `app.use()`:

```javascript
var posts = require('./posts');
app.use('/posts', posts);
// ahora la app responde a /posts y /posts/about
```

> [!warning]+ Express Router ≠ React Router
> `express.Router` es **middleware del back-end** que registra manejadores de rutas modulares (*endpoints*) para responder a solicitudes HTTP. **No** es el enrutado de componentes en el cliente: eso es [[Enrutado con React Router|React Router]]. Confundirlos es una trampa típica de examen.

Para código más limpio, los manejadores se separan en **controladores**:

```javascript
var api = express.Router();
var PostController = require('../controllers/post');

api.get('/posts', PostController.posts);       // listar
api.post('/posts', PostController.savePost);   // crear
module.exports = api;
```

# Parámetros de ruta vs query string

Dos formas de pasar datos en una URL, con propósitos distintos:

- **Parámetros de ruta** (`req.params`): identifican el recurso; se declaran con `:`.
- **Query string** (`req.query`): filtran, ordenan o paginan; van tras `?`.

```javascript
// GET /posts/123?formato=corto
app.get('/posts/:id', function (req, res) {
  req.params.id;       // "123"   → qué recurso
  req.query.formato;   // "corto" → cómo lo quiero
});
```

El cuerpo de la petición (`req.body`, en POST/PUT) transporta los datos de creación o actualización y requiere el middleware `express.json()` para parsearse.

> [!important]+ Para el examen
> Ruta = `app.METHOD(PATH, HANDLER)`. `router.get('/', fn)` **registra una función manejadora para una petición HTTP GET** sobre la ruta raíz `'/'`. `express.Router()` crea routers modulares ("miniaplicaciones") que son **middleware del servidor**; se montan con `app.use('/ruta', router)`.
