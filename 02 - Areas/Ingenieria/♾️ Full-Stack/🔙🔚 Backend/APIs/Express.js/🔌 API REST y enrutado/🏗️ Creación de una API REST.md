Después de explicar los fundamentos que envolverán al desarrollo de una API REST con Express.js, es hora de ponernos manos a la obra, y comenzar a construir la API REST de nuestra aplicación. Para ello, iremos al directorio “/microblogging example-api” creado con el generador de express (ver sección Generación de una aplicación Express.js). 

Como primer paso, editaremos el fichero “users.js”, construido automáticamente por el generador express y alojado inicialmente en “/ microblogging-example-api/routes/”, con la intención de implementar en él todos los manejadores CRUD que tienen que ver con las operaciones relativas a los usuarios. A continuación, describiremos las funciones a desarrollar.


# Obtener usuarios 
Usando la raíz de la URL “/users” en el navegador, tal y como se muestra en el fichero “app.js” generado por express y una solicitud GET, devolveremos todos los usuarios al cliente que realizó la petición. Como aún no hemos visto como conectar nuestra API REST a la base de datos construida, devolveremos un documento JSON de usuarios estático para comprobar su funcionamiento.
```javascript
// GET  del listado de usuarios
router.get(‘/’, function(req, res) {
	res.json({
		“users”: [
			{“id”: 123,
			“name”: “Eladio Guardiola”,
			“phones”: {
				“home”: “800-123-4567”,
				“mobile”: “877-123-1234”
			},
			“email”: [
				“jd@example.com”,
				“jd@example.org”],
			“dateOfBirth”: “1980-01-02T00:00:00.000Z”,
			“registered”: true
			},
			
			{“id”: 456,
			“name”: “Nemesio Tornero”,
			“phones”: {
				“home”: “800-123-3498”,
				“mobile”: “877-432-1278”
			},
			“email”: [
				 “pt@example.com”,
				 “pt@example.org”],
			 “dateOfBirth”: “1983-01-09T00:00:00.000Z”,
			 “registered”: false
			}
		]
	});
});
```

Conforme al código presentado, el cliente recibirá como respuesta el documento JSON con todos los usuarios existentes, en este caso se trata de un array de 2 usuarios y toda la información de estos, convenientemente formateada en JSON. 

Para crear documentos JSON bien formados y hacer pruebas con ellos, es aconsejable echar un vistazo a herramientas online como ObjGen30.


# Obtener un usuario por su Id 
Usando la URL “/users/:id” y una solicitud GET, devolveremos al usuario cuyo “Id” sea el indicado en parámetro “id” de la URL. En este caso “id” es un número entero, pero podría ser de cualquier otro tipo que se quiera pasar en la petición, por ejemplo, una cadena. También, devolvemos un documento JSON, pero esta vez con la información del usuario cuyo Id es “123” (el cual es un parámetro de la propia URL), en caso de no encontrarlo devolveremos el estado 404 (Not found) acompañado de un mensaje. A continuación, se presenta el código asociado.
```javascript
// GET de un usuario por su id
router.get(‘/:id’, function(req, res) {
	if (req.params.id == ‘123’){
		res.json({
			“id”: 123,
			“name”: “Eladio Guardiola”,
			“phones”: {
				“home”: “800-123-4567”,
				“mobile”: “877-123-1234”
			},
			“email”: [
				“jd@example.com”,
				“jd@example.org”],
			“dateOfBirth”: “1980-01-02T00:00:00.000Z”,
			“registered”: true
		});
	} else 
		res.status(404).send(‘¡Lo siento, el ítem no se ha encontrado!’);
});
```

Nuevamente, el JSON a devolver al cliente por parte del servidor, es un documento estático. El objetivo de estos ejemplos es observar el comportamiento de las funciones conforme a las rutas establecidas. Recuerda que en el caso de nuestra API REST final, realizaremos peticiones al servidor sobre datos almacenados en una base de datos, lo que se verá en las secciones **Conexión con MongoDB Atlas** y **Servicios REST para la gestión de usuarios**.


# Agregar un nuevo usuario 
Usando la URL raíz “/users” y una solicitud POST, podremos agregar un nuevo usuario a la lista de usuarios. En este ejemplo, el nuevo usuario será un documento JSON bien formado como por ejemplo el siguiente (que no necesariamente debe contener todos los campos de los usuarios de anteriores ejemplos):
```javascript
{ 
	“id”: 789, 
	“name”: “Tomás Rabero”, 
	“phones”: { 
		“home”: “855-123-8884”, 
		“mobile”: “877-555-1234” 
	}
}
```

A la operación anterior podemos añadir la devolución de un mensaje, por parte del servidor, que indique si la operación de agregación tuvo éxito. El código de la función podría ser el siguiente:
```javascript
// POST de un nuevo usuario 
router.post(‘/’, function(req, res) { 
	var new_user = req.body; 
	//ToDo (hacer algo con el nuevo usuario) 
	res.status(200).send(‘Usuario ‘+ req.body.name + ‘ ha sido añadido satisfacto riamente’); 
});
```

En este caso, el nuevo usuario a agregar se encuentra en el cuerpo del mensaje enviado por el cliente, de ahí que accedamos a él con la sentencia req. body. Una vez recuperado, haremos lo necesario y devolveremos la respuesta de la operación al cliente.


# Actualizar un usuario por su Id 
Usando la URL “/users/:id” y una solicitud PUT, podremos actualizar un usuario existente de la lista de usuarios. Se actualizará el documento JSON del usuario cuyo Id coincida con el dado. En este caso se pasa a la función el id del usuario como parámetro y el JSON del usuario actualizado en el cuerpo de la solicitud. Un ejemplo del nuevo JSON podría ser:
```javascript
{ 
“id”: 789, 
“name”: “Tomás Rabero”, 
“phones”: { 
	“home”: “855-123-8884”, 
	“mobile”: “877-555-1234” 
}, 
“registered”: true
}
```

Y el código de la función el siguiente:
```javascript
// PUT de un usuario por su Id 
router.put(‘/:id’, function(req, res) { 
	var updated_user = req.body; 
	//ToDo (hacer algo con el usuario) 
	res.status(200).send(‘Usuario ‘+ req.body.name + ‘ ha sido actualizado satis factoriamente’); 
});
```

Igualmente, necesitamos procesar la solicitud (en base al nuevo usuario) para determinar si se realizó correctamente, por ejemplo, al actualizar el documento en la base de datos, pero por ahora lo dejaremos así, enviando un mensaje con el *código 200* al cliente.


# Eliminar un usuario por su Id 
Usando la URL “/users/:id” y una solicitud DELETE, ==podremos borrar un usuario existente de la lista de usuarios.== En este caso se pasa a la función el id del usuario como parámetro, se comprobará la existencia del usuario y se eliminará, pudiendo devolver un mensaje asociado a la operación. De esta forma, si queremos borrar el documento JSON del usuario con id = 123, lo haríamos como muestra el bloque de código siguiente. 

Una vez implementada la parte del API dedicada al manejo de recursos “usuarios”, podremos desplegarla y hacer uso de sus funciones a través del navegador (para peticiones GET) o un cliente REST, para probar todas las solicitudes implementadas. Podremos ver el resultado de estas operaciones también en la consola. En la siguiente sección, explicaremos como consumir una API REST.
```javascript
// DELETE de un usuario por su Id 
router.delete(‘/:id’, function(req, res) { 
	//ToDo (hacer algo con el usuario) 
	res.status(200).send(‘Usuario con id ‘+ req.params.id + ‘ ha sido borrado sa tisfactoriamente’); 
});
```

Adicionalmente, recuerda que, si inicializaste tu proyecto con Git puedes crear un archivo “.gitignore” en el directorio raíz con el siguiente contenido antes de sincronizarlo con el repositorio correspondiente de Github (ver sección Introducción a Github).
`# dependencies`
`/node_modules`

Con esto le indicaremos al control de versiones que no sincronice el directorio “/node_modules”, que contiene todas las dependencias del proyecto (definidas en el “package.json”). Si quisiéramos instalar dichas dependencias lo haríamos con el comando npm install (por ejemplo, cuando clonamos un repositorio de Github que no tiene el “/node_modules” pero cuyas dependencias están definidas en el “package.json”).