Podría decirse que es una representación de un tipo de contenido mediante el cual podemos, a alto nivel, trabajar con objetos de esa representación, haciendo más sencillo y eficiente la manipulación de los datos y la interacción con las bases de datos. 

Los modelos son creados mediante esquemas, siguiendo unos “estándares” para la definición de atributos y sus tipos, aparte de algún comportamiento adicional. 

Así, si queremos por ejemplo almacenar y/o recuperar datos de una base de datos, lo haremos a través de objetos de un modelo previamente definido siguiendo un esquema. Obviamente podemos optar por no usar modelos ni mapeadores a la hora de manipular los datos y realizar las transacciones con la base de datos, pero sin duda nos estaremos perdiendo un sinfín de ventajas de los ORM/ODM relacionadas con la mantenibilidad, eficiencia, optimización, validación de datos, o agnosticismo. 

A continuación, se muestra un ejemplo de modelo implementado en JavaScript siguiendo un esquema Mongoose:
```javascript
var userSchema = mongoose.Schema({ 
	_id: mongoose.Schema.Types.ObjectId, 
	name: { 
		firstName: String, 
		lastName: String 
	}, 
	biography: String, 
	twitter: String, 
	facebook: String, 
	linkedin: String, 
	profilePicture: Buffer, 
	created: { 
		type: Date, 
		default: Date.now 
	} 
});
```
A partir de este esquema podremos derivar el modelo correspondiente con:
```javascript
var User = mongoose.model(‘User’, userSchema);
```
Y crear objetos user a partir de una serie de datos de entrada. Incluso relacionar modelos (por ejemplo: `user -> posts`), como si se tratase de una relación entre tablas a través de claves ajenas, si buscamos el símil con las bases de datos relacionales. 

Usualmente, los modelos suelen almacenarse como archivos *.js*, en un directorio `/models` de nuestro proyecto por cuestiones organizativas y de mantenimiento. 

Cuando trabajamos con MERN o cualquier otro stack, los modelos deben ser conocidos por el back-end y muchas veces también por el front-end, para poder operar sobre los objetos creados a partir de esos modelos de forma apropiada. 

Dentro del entorno Node.js, tenemos la librería mongoose que se encontraría entre lo que es la base de datos MongoDB y el framework Express.js, a nivel del back end. Aunque no es esencial usar esta librería como ODM, y podemos usar otra diferente, se ha optado por esta debido a su potencial e integración con MongoDB y Node.js
