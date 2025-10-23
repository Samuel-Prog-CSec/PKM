Cuando queremos acceder a recursos en `Express`, lo hacemos a través de puntos finales o endpoints, como ya habíamos mencionado anteriormente. Estas ==URLs se asocian a solicitudes del cliente==, y dichas solicitudes son transmitidas mediante el protocolo HTTP para el acceso y manipulación de recursos. 

En HTTP encontramos distintos tipos de solicitudes, que a su vez suelen corresponderse con operaciones CRUD, base de cualquier back-end. Una vez **realizadas las solicitudes al servidor, este debería devolver una respuesta al cliente**. De esta forma tendremos:
- **GET**: accede a los recursos a través de un endpoint, permitiendo **leerlos y/o consultarlos** (por ejemplo, de una base de datos). Análogo a READ. 
- **POST**: permite **crear un nuevo recurso a partir de la información suministrada** por el cliente. Por ejemplo, para almacenarlo en una base de datos. Análogo a CREATE. 
- **PUT**: permite **actualizar un recurso**, usando la ==información suministrada por el cliente==. Análogo a UPDATE. 
- **DELETE**: accede a un recurso gracias a su endpoint para **eliminarlo**. Igual que DELETE en el modelo CRUD. 

Aparte, existe otra solicitud denominada **PATCH** que nos ==permite editar partes concretas de un recurso==. Esta operación es la menos conocida y utilizada. Las URIs contienen varias partes, entre ellas la propia ruta o URL de acceso, que además de permitir identificar de forma única el recurso, nos permite localizarlo para poder acceder a él o compartir su ubicación. ==Una URI se podría estructurar de la siguiente forma==: 
`{protocolo}://{dominio o hostname}[:puerto (opcional)]/{ruta del recurso}?{consulta de filtrado}` 

---

Existen varias reglas adoptadas para nombrar a la ruta de un recurso, las cuales se presentan a continuación:
# 1.- Las rutas no deben implicar acciones y deben ser únicas 
Por ejemplo, la siguiente ruta sería incorrecta ya que tenemos el verbo editar (la acción) en la misma. 
`/posts/123/editar` 

Para el recurso post con el identificador 123, la siguiente ruta sería correcta, independientemente de que vayamos a editarla, borrarla, consultarla o leer solo uno de sus conceptos (==estas operaciones vendrán determinadas por la solicitud HTTP implementada en la lógica de negocio==). 
`/posts/123`

# 2.- Las rutas deben ser independientes de formato
Por ejemplo, la siguiente ruta sería incorrecta, ya que estamos indicando la extensión pdf en la misma: 
`/posts/123.pdf` 

Mientras, la siguiente ruta sí sería correcta, ==independientemente de que vayamos a consultarla en formato pdf, txt, xml o JSON==. 
`/posts/123`

# 3.- Las rutas deben mantener una jerarquía lógica
Por ejemplo, la siguiente URI no sería correcta por no seguir una jerarquía lógica. 
`/posts/123/usuario/007` 

Para el recurso post con el identificador 123 del usuario 007, la siguiente ruta sería la correcta: 
`/usuarios/007/posts/123`

# 4.- Filtrados y otras operaciones no se hacen en la URL
Para **filtrar, ordenar, paginar o buscar información en un recurso, podremos hacer una consulta sobre la ruta, utilizando parámetros HTTP en lugar de incluirlos en la misma**. Por ejemplo, la siguiente ruta sería incorrecta ya que el recurso de listado de posts sería el mismo, pero utilizaríamos una ruta distinta para filtrarlo, ordenarlo o paginarlo. 
`/posts/orden/desc/fecha-desde/2007/pagina/2` 

En este caso, la ruta correcta sería: 
`/posts?fecha-desde=2007&orden=DESC&pagina=2` 

Visto todo lo anterior, para un recurso posts tendríamos las solicitudes mostradas en siguiente tabla:

| Tipo de solicitud | URL          | Descripción                                                                                    |
| ----------------- | ------------ | ---------------------------------------------------------------------------------------------- |
| `GET`             | `/posts`     | Nos permite acceder al listado de posts.                                                       |
| `POST`            | `/posts`     | Nos permite crear un post nuevo.                                                               |
| `GET`             | `/posts/123` | Nos permite acceder al detalle de un post.                                                     |
| `PUT`             | `/posts/123` | Nos permite editar el post, sustituyendo la totalidad de la información anterior por la nueva. |
| `DELETE`          | `/posts/123` | Nos permite eliminar el post.                                                                  |
| `PATCH`           | `/posts/123` | Nos permite modificar cierta información del post, como la descripción o la fecha del mismo.   |


# Códigos de estado y formatos de contenido
Cuando realizamos una solicitud como las anteriores a una API REST, es de vital importancia saber si dicha operación se ha realizado con éxito o en caso contrario, por qué ha fallado.

En la actualidad existe una ==lista bastante completa de estos códigos de estado que nos permiten conocer cómo ha ido la petición cuando esta es procesada== por el [servidor](https://developer.mozilla.org/es/docs/Web/HTTP/Status).

Cuando construimos servicios (entendidos como funcionalidades de una API REST), **deberíamos devolver el código de estado asociado al resultado de la solicitud**. De esta forma tendremos un código más mantenible y eficiente en depuración y después en producción.

En el siguiente ejemplo vemos una respuesta a una solicitud HTTP que nos ==devuelve el código 200 (petición satisfactoria, “OK”==). No obstante, si miramos con detenimiento el contenido de la respuesta, comprobamos que **refleja un error,** por falta de datos de entrada en la petición del cliente. Así pues, **el código devuelto no es el adecuado ni tampoco el contenido y formato de la respuesta emitida**. 
```HTTP 
 Petición
 ========
 PUT /posts/123
 
 Respuesta
 =========
 Status Code 200
 Content:
 {
	 success: false,
	 code: 734,
	 error: “datos insuficientes”
 }
```

En el siguiente ejemplo, sin embargo, sí ==estaría bien construida la respuesta emitida, retornando el código de estado 400 (de petición mal formalizada o “bad request”==), al faltar un identificador de usuario (dato de entrada) en la petición:
```HTTP
 Petición
 ========
 PUT /posts/123
 
 Respuesta
 =========
 Status Code 400
 Content:
 {
	 message: “se debe especificar un id de usuario para el post”
 }
```

---

Por otra parte, y como vimos en la sección anterior, no era correcto especificar, en la URL, el tipo de formato de un recurso al que queremos acceder o manipular.

**HTTP nos permite especificar en qué formato queremos recibir el recurso**, pudiendo indicar varios en orden de preferencia, para lo que ==usaremos el header (o cabecera) `Accept` en la petición==.

Nuestra API ==deberá devolver el recurso en el formato correcto y/o disponible de los indicados== y, en el caso de no poder mostrarlo, retornará el código de estado **HTTP 406** (“Not aceptable”).

Tras la negociación del formato de contenido entre el cliente y el servidor, **en la respuesta se devolverá el header** `Content-Type`, ==para que el cliente sepa en qué formato recibirá el contenido==, por ejemplo:
```HTTP
 Petición
 ========
 GET /posts/123
 Accept: application/epub+zip, application/pdf, application/json
 
 Respuesta
 =========
 Status Code 200
 Content-Type: application/pdf
```
>[!Nota]
>En este caso, el **cliente solicita el post en “epub” comprimido con “zip”**, y ==de no tenerlo, en “pdf” o “json”== por orden de preferencia.