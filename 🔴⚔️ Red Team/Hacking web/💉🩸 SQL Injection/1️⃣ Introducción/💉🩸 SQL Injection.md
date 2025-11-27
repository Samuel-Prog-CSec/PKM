==La mayoría de las aplicaciones web modernas utilizan una estructura de base de datos en el back-end.== Estas bases de datos se utilizan para almacenar y recuperar datos relacionados con la aplicación web, desde el contenido de la web, hasta la información y el contenido del usuario. 

Para que las aplicaciones web sean dinámicas, la aplicación web tiene que interactuar con la base de datos en tiempo real. A medida que llegan **solicitudes HTTP(S)** del usuario, el back-end de la aplicación web **emitirá consultas a la base de datos para generar la respuesta**. Estas consultas pueden incluir información de la solicitud HTTP(S) u otra información relevante.

Cuando se utiliza información proporcionada por el usuario para construir la consulta a la base de datos, los ==usuarios malintencionados pueden engañar a la consulta para que se utilice con un fin distinto al previsto por el programador original==, lo que proporciona al usuario acceso para consultar la base de datos mediante un ataque conocido como **inyección SQL (SQLi)**. 

La inyección SQL se refiere a los ataques ==contra bases de datos relacionales== como **MySQL** (mientras que las ==inyecciones contra bases de datos no relacionales==, como **MongoDB**, son **inyecciones NoSQL**). 


# Índice
- **Bases de datos**:
	* [[🐬 MySQL]]
	* [[💬 Sentencias SQL]]
- **SQLi**:
	- [[💉🩸 SQL Injection]]
	- [[🃏 Subvirtiendo la lógica de consulta]]
	- [[⏸️ Usando comentarios]]
	- [[🧲 Cláusula de Unión]]
	- [[Inyección de Unión]]


# Introducción a SQLi
Existen muchos tipos de vulnerabilidades de inyección posibles en las aplicaciones web, como la **inyección HTTP**, la **inyección de código** y la **inyección de comandos**. Sin embargo, el ejemplo más común es la inyección SQL. 

Una inyección SQL se produce cuando un usuario malintencionado intenta pasar ***una entrada que cambia la consulta SQL final enviada por la aplicación web a la base de datos***, lo que permite al usuario realizar otras consultas SQL no deseadas directamente en la base de datos.

Para que funcione una inyección SQL, primero, el atacante debe inyectar código fuera de los límites de entrada (de datos) del usuario esperados, de modo que no se ejecute como una simple entrada (u orden) del usuario. 

En el ==caso más básico==, esto se hace inyectando una **comilla simple** (`'`) o una **comilla doble** (`"`) para escapar de los límites de entrada del usuario e inyectar datos directamente en la consulta SQL. Una vez que un atacante puede inyectar, ==tiene que buscar una forma de ejecutar una consulta SQL diferente==. Esto se puede hacer usando código SQL para crear una consulta funcional que ejecute tanto la consulta SQL deseada como la nueva. Hay muchas formas de lograr esto, como usar consultas apiladas o usar consultas de unión. 

Finalmente, para recuperar el resultado de nuestra nueva consulta, tenemos que interpretarlo o capturarlo en el front-end de la aplicación web.


# Casos de uso e impacto
En primer lugar, ==podemos recuperar información secreta o confidencial que no debería ser visible== para nosotros, como los nombres de usuario y las contraseñas o la información de la tarjeta de crédito, que luego se puede utilizar para otros fines maliciosos. Las inyecciones SQL provocan muchas violaciones de contraseñas y datos contra sitios web, que luego se reutilizan para robar cuentas de usuario, acceder a otros servicios o realizar otras acciones nefastas. 

Otro caso de uso de la inyección SQL es **subvertir la lógica de la aplicación web prevista**. El ejemplo más común de esto es omitir el inicio de sesión sin pasar un par válido de credenciales de nombre de usuario y contraseña. 

Otro ejemplo, es **acceder a funciones que están bloqueadas para usuarios específicos**, como los paneles de administración. Los atacantes también pueden **leer y escribir archivos directamente en el servidor back-end**, lo que, a su vez, puede llevar a colocar puertas traseras en el servidor back-end y obtener control directo sobre él, y eventualmente tomar el control de todo el sitio web.


# Prevención 
Las inyecciones SQL ==suelen ser causadas por aplicaciones web mal codificadas o por privilegios de bases de datos y servidores back-end mal protegidos==. Más adelante, analizaremos formas de reducir las posibilidades de ser vulnerable a las inyecciones SQL mediante **métodos de codificación seguros**, como la **validación** y el **saneamiento de la entrada del usuario**, y los **privilegios** y el **control adecuados de los usuarios back-end**.