El **routing o direccionamiento** hace referencia a la ==definición de puntos finales de aplicación para el acceso a recursos== o también llamados **endpoints**; y ==cómo responden a las solicitudes HTTP== del cliente (normalmente asociadas a esas operaciones CRUD), **mediante una función de manejador** que procesa la petición y ==construye una respuesta para ser retornada== al cliente. 

**Cada ruta puede tener una o varias funciones de manejador**, y tienen la siguiente estructura:
```javascript
app.METHOD(PATH, HANDLER); 
```
- `app` es una instancia de express.
- `METHOD` es un ==método de solicitud HTTP==.
- `PATH` es una **vía de acceso o ruta en el servidor**, que caracteriza al ==punto final o endpoint para el acceso a los recursos==. 
- `HANDLER` **o manejador** es la **función** que ==se ejecuta cuando se correlaciona la ruta==. 

En el ejemplo del “Hola Mundo” en [[Express.js]] ya ilustrábamos esta estructura, con una solicitud GET simple: 
```javascript
app.get(‘/’, function (req, res) { 
	res.send(‘¡Hola Mundo!’); 
});
```
>[!Nota]
>Esa solicitud `GET` se **corresponde con uno de los métodos de ruta derivados de solicitudes HTTP** (por ejemplo: get, post, update, delete), que a su vez ==coinciden con las operaciones CRUD== (create, read, update, delete). 

Podemos **implementar otros endpoints de rutas** de la misma manera. En el siguiente ejemplo podemos ver lo propio con la ruta `/about`: 
```javascript
app.get(‘/about’, function (req, res) { 
	res.send(‘about’); 
}); 
```

`HANDLER` ==proporciona el manejador a través de una función con unos parámetros determinados==, que normalmente son `req` (**solicitud**) y `res` (**respuesta**). 

Excepcionalmente, la devolución de llamada de la función del manejador puede invocar `next(‘route’)` **para omitir el resto de las devoluciones de llamada de ruta**. Este mecanismo ==se puede utilizar para imponer condiciones previas en una ruta==, y a continuación pasar el control a las rutas posteriores si no hay motivo para continuar con la ruta actual. En la [página de Express](https://expressjs.com/en/guide/writing-middleware.html) se profundiza más acerca del uso de `next()`. A continuación podemos ver un ejemplo de función con `next()`:
```javascript
app.get(‘/example/b’, function (req, res, next) { 
	console.log(‘la respuesta será enviada por la función next...’); 
	next(); 
}, function (req, res) { 
	res.send(‘¡Hola desde B!’); 
});
```

Los [métodos](https://expressjs.com/es/4x/api.html#res) en el objeto de respuesta `res` de la tabla **pueden enviar una respuesta al cliente** y finalizar el ciclo de solicitud/respuestas. ==Si ninguno de estos métodos se invoca desde un manejador de rutas, la solicitud de cliente se quedará colgada==. Algunos métodos son:

| Método             | Descripción                                                                                                   |
| ------------------ | ------------------------------------------------------------------------------------------------------------- |
| `res.download()`   | Descripción Solicita un archivo para descargarlo.                                                             |
| `res.end()`        | Finaliza el proceso de respuesta.                                                                             |
| `res.json()`       | Envía una respuesta JSON.                                                                                     |
| `res.jsonp()`      | Envía una respuesta JSON con soporte [JSONP28](https://www.w3schools.com/js/js_json_jsonp.asp).               |
| `res.redirect()`   | Redirecciona una solicitud.                                                                                   |
| `res.render()`     | Representa una plantilla de vista.                                                                            |
| `res.send()`       | Envía una respuesta de varios tipos.                                                                          |
| `res.sendFile()`   | Envía un archivo como una secuencia de octetos.                                                               |
| `res.sendStatus()` | Establece el código de estado de la respuesta y envía su representación de serie como el cuerpo de respuesta. |
