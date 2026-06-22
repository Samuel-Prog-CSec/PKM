Express.js es uno de los ==framework de Node.js== más interesantes. El framework Express.js destaca por su facilidad y optimización de recursos en el **manejo de solicitudes HTTP complejas**, y supone una ==herramienta esencial en la implementación== de una **API REST**, necesaria en la mayoría de las aplicaciones web. 


# Índice
1. Instalación y creación del servidor web con Express.js
2. Generación de una aplicación Express.js
3. [[🔨👷 Ejecución y depuración]]
4. 🔌 **API REST y enrutado**
	- [[0️⃣ Introducción a REST]]
	- [[1️⃣ Introducción a rutas y manejadores]]
	- [[📬 CRUD y enrutado]]
	- [[👈 Express Router]]
	- [[🏗️ Creación de una API REST]]
	- 🍴 **Clientes REST**
		- 
5. 
6. 
7. 
8. 
9. 
10. 


# Instalación y creación del servidor web con Express.js
Dado que Express.js es un framework de Node.js podremos **instalarlo como un paquete** en el directorio de nuestro proyecto:
```bash
C:\microblogging-example-api> npm install express --save
```
Igualmente podemos ==añadir `-g` al comando de instalación== si lo que queremos es instalar Express de forma global y tenerlo accesible al resto de proyectos que se creen.

Ahora podemos crear nuestro servidor web empleando Express:
```javascript
var express = require(‘express’); 
var app = express();

app.get(‘/’, function (req, res) { 
	res.send(‘¡Hola Mundo!’); 
}); 

app.listen(3000, function () { 
	console.log(‘Aplicación de ejemplo escuchando en el puerto 3000’); 
});
```
>[!Nota]
>Implementación de una solicitud `GET` cuando llamamos a una ruta específica que, en este caso, será la URL raíz (`/`). Como respuesta, enviará al cliente que lo solicitó el mensaje “¡Hola Mundo!”. En caso de usar otra ruta, el servidor nos responderá con un error `404 Not Found`.

Si queremos ir más allá y ==pasar como parámetro a la ruta anterior nuestro nombre==, también lo podemos hacer, simplemente cambiando nuestro código de la petición `GET` a:
```javascript
app.get(‘/:name’, function (req, res) { 
	res.send(‘¡Hola ‘+ req.params.name +’!’); 
});
```
>[!Nota]
>En este caso, si volvemos a ejecutar la aplicación y cargamos la página con la siguiente URL: `http://localhost:3000/Jesus`, la salida será “¡Hola Jesus!”. Como vemos, las solicitudes pueden ir acompañadas de parámetros.


# Generación de una aplicación Express.js
```bash
C:\>npm install -g express-generator
``` 

A continuación, prepararemos el directorio  para alojar en él nuestra aplicación de back-end La herramienta ==express-generator nos proporciona el comando express==, que nos **permitirá crear el esqueleto de la aplicación Express.js**. Podemos acceder a las opciones de dicho comando con:
```bash
C:\>express -h
```

Por tanto, si queremos crear una aplicación Express.js con un nombre, lo haremos de la siguiente forma: 
```bash
C:\>express <nombre aplicación>
```
>[!Nota]
>Esto creará el directorio del proyecto, así como todos los subdirectorios y ficheros correspondientes

Una vez creada la aplicación, entraremos al directorio de la misma e **instalaremos las dependencias**, definidas en el `package.json`, con el comando: 
```bash
C:\nombre-aplicacion>npm install 
```

==Y ya podemos ejecutar la aplicación generada==, que usaremos como base para nuestra propia **API REST** gracias a esta herramienta de [[scaffolding]]. Para ello, usaremos el siguiente comando: 
```bash
C:\nombre-aplicacion> npm start 
```

Cargamos la URL `http://localhost:3000/` en el navegador **para acceder a la aplicación**. Igualmente, desde la consola podemos ver la realización de las peticiones a las páginas o servicios asociados a las rutas definidas en el código. 

Gracias a Node.js, se nos ha creado un servidor escuchando en el puerto 3000, que servirá nuestra aplicación Express.js en el navegador. ==Si deseamos usar otro puerto==, lo podemos cambiar en el fichero `/bin/www` o **mediante una variable de entorno**. 

Desde el navegador, podemos acceder al recurso de la URL `http:// localhost:3000/users` y comprobar el resultado, la salida por consola asociada a la solicitud del recurso, y el código en `app.js` y `routes/users.js`.