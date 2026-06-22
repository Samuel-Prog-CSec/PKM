**REST (Representational State Transfer)** se define como un ==protocolo de intercambio y manipulación de datos== en los servicios de Internet **basado a su vez en HTTP**. Los ==datos son devueltos en formatos específicos y estandarizados==, como pueden ser **XML** y **JSON**. 

Desde el punto de vista del desarrollador, una API REST no es más que una **librería de servicios REST (funcionalidades) que satisface diferentes necesidades de intercambio y manipulación de datos a través de Internet**. 


# ¿Qué es un servicio?
Realmente cuando hablamos de REST, el concepto de servicio puede desvanecerse, ya que ==es más apropiado usar el término **recurso**==. El acceso a los recursos se realiza a través de URLs que los identifican. 

Si por ejemplo tenemos un recurso llamado “colección de usuarios” con la URL `/users` que lo identifica; si ==invocamos con REST dicha URL, bajo un esquema== **URI (Uniform Resource Identifier)**, deberíamos obtener una representación de dicho recurso, es decir, el listado de todos los usuarios de la colección. 

Si quisiéramos obtener los datos de un usuario en concreto, ==habrá otro recurso (usuario) con un esquema URI asociado==. Además, **entre los recursos existen relaciones**: está claro que un usuario forma parte de la “colección de usuarios”, así que parece lógico que a partir de esa colección pueda acceder a uno de sus elementos con una ruta del tipo `/users/12`, siendo “12” el ID del usuario.


# Características generales de REST
- Todo servicio REST **se apoya en el protocolo de Internet HTTP** y en sus métodos básicos (`GET`, `POST`, `PUT`, `DELETE`), que corresponden a **operaciones CRUD** (==Create, Read, Update, Delete==). 
- Crea una petición HTTP con toda la información necesaria, es decir, un “**request**” ==que envía a un servidor==, y solo espera un “**response**”, una ==respuesta en concreto a esa solicitud==. 
- **Todos los objetos/recursos se manipulan mediante URI**s. Una URI (Uniform Resource Identifier) nos ==facilita el acceso a la información del recurso== para su modificación o borrado, o bien para compartir su ubicación con terceros. 
- Nos aporta escalabilidad y ==diferenciación entre la parte cliente y servidor==. 
- Es **totalmente independiente de la plataforma**, pudiendo hacer uso de REST desde cualquier sistema operativo y lenguaje. 

Las **APIs REST pueden ser públicas o privadas**. Si son públicas, pueden consumir sus servicios otros usuarios. A su vez, determinadas APIs REST ==pueden requerir de autenticación previa para acceder a sus recursos==.
