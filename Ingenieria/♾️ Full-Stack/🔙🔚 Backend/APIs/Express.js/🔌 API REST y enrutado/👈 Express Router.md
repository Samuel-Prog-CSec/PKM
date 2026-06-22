En la sección Rutas y manejadores, ya vimos como implementar manejadores de rutas con express de forma sencilla, aunque no prestábamos especial atención a las operaciones CRUD asociadas. Incluso podemos crear manejadores de rutas encadenados para una ruta determinada. Como esta se especifica en una única ubicación, la creación de rutas modulares es muy útil, favoreciendo la reducción de redundancia y errores tipográficos. 

A continuación se muestra un ejemplo de manejadores de rutas encadenados que se definen utilizando app.route(). Además, podemos observar cómo se están utilizando las solicitudes HTTP vistas anteriormente; en este caso GET, POST y PUT. La única implementación en el ejemplo es el envío de una respuesta al cliente con res.send().
```javascript
app.route(‘/post’) 
	.get(function(req, res) { 
		//... 
		res.send(‘Recupera un post cualquiera’); 
	}) 
	.post(function(req, res) {
		//... 
		res.send(‘Añade un post’); 
	}) 
	.put(function(req, res) { 
		//... 
		res.send(‘Actualiza el post’); 
	});
```
 
En Express.js tenemos la clase express.Router que permite crear manejadores de rutas modulares. Una instancia Router es un sistema de middleware y direccionamiento completo; por este motivo, a menudo se conoce como una “miniaplicación”. De hecho, la potencia de Express.js radica en su manejo de rutas mediante el Router.

A continuación, se muestra un ejemplo donde se crea un direccionador como un módulo, carga una función del middleware en él, define algunas rutas y monta el módulo de direccionador en una vía de acceso en la aplicación principal.

Para ello, tendremos que crear un archivo direccionador, en este caso “posts. js” en el correspondiente directorio de la aplicación (usualmente en /routes), con este código:
```javascript
var express = require(‘express’);
var router = express.Router();

// middleware que es específico a este router
router.use(function timeLog(req, res, next) {
	console.log(‘Fecha actual: ‘, Date.now());
	next();
});

// define la ruta de la página del home
router.get(‘/’, function(req, res) {
	res.send(‘Página inicial de los posts’);
});
 
// define la ruta de la página about
router.get(‘/about’, function(req, res) {
	res.send(‘Acerca de los posts’);
});

module.exports = router;
```
 
Así, para cargar el módulo de direccionador en la aplicación (por ejemplo: en “index.js”), se haría con el siguiente código:
```javascript
var posts = require(‘./posts’);
//...
app.use(‘/posts’, posts);
```

La aplicación ahora podrá manejar solicitudes a /posts y /posts/about. Además, para ambas peticiones se ejecutará la función de middleware (timeLog) previo al código de estas.

Por supuesto, a la hora de optimizar nuestro código (a medida que aumenta la complejidad y funcionalidades), también podemos separar la lógica de negocio de forma más eficiente, y no incluir el código de las funciones de las distintas rutas en el mismo archivo. De esta forma podremos tener algo como:
```javascript
var express = require(‘express’);
var PostController = require(‘../controllers/post’);
var api = express.Router();

// ruta GET para recuperar todos los posts (o entradas de un blog)
api.get(‘/posts’, PostController.posts);

// ruta POST para guardar nuevos posts (o entradas de un blog)
api.post(‘/posts’, PostController.savePost);

//...

module.exports = api;
```

Las funciones de manejadores y su código ya no se incluyen en este script (módulo direccionador), sino que lo hacen en un archivo “post.js” en el directorio asociado a los controladores (/controllers). 

Como se puede observar, el código contenido en las funciones asociadas a las rutas de acceso de los recursos puede suponer desde el envío de un simple mensaje como respuesta, hasta la realización de transacciones con bases de datos, algo que abordaremos más adelante.