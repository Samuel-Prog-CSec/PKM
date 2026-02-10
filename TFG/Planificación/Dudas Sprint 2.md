1. ¿Cómo hacemos para asegurarnos que el Super Admin sepa que el perfil de profesor que tiene delante es un profesor real y no un fake? ¿Con un código quizá que le de un gestor del sistema o la API?
2. Un profesor puede crear todos los alumnos que quiera, ¿Cómo nos aseguramos que no cree alumnos duplicados? En el caso de que un atacante robe credenciales de acceso o se autentique como profesor, ¿Cómo nos podemos proteger para que no cree perfiles falsos de alumnos en masa o borre perfiles reales?
3. ¿Quién es el actor que modifica los datos de los alumnos (cambios de clase, de profesor, etc.)?
4. ¿Un profesor debería tener los permisos para auto-asignarse a una clase? ¿Y para des-asignar a otro?
	1. En caso negativo, ¿Quién ejecuta estas tareas?
	2. Actualmente, el profesor al que pertenecen los alumnos es que tiene la responsabilidad de cambiar sus alumnos a otro profesor (para evitar explotación del sistema y que restringir permisos de operaciones, revisar esta implementación -> ¿demasiado restrictiva?).
5. Actualmente, el servidor del backend registra los eventos *RFID* que llegan a través del puerto serie, esta era la implementación inicial del `rfidServide.js`. Sin embargo, esto es **MUY** limitante porque sólo va a registrar el puerto serie del servidor, cuando hagamos un despliegue del backend (en `Heroku` o similares) dejará de poder conectarse con el sensor ya que no tendremos acceso directo al servidor y sus puertos. Alternativas posibles:
	1. Que el frontend sea el encargado de registrar los datos de cada puerto serie de cada dispositivo y enviarlos (con un id, del sensor por ejemplo) al backend. Puede hacerse con la `API de Web Serial`.
6. ¿Debemos poder usar cartas RFID cualesquiera o deben esta previamente registradas en el SGBD?
	1. ¿Quién es el encargado de registrar cartas, el super_admin? ¿Es el super_admin quien le proporciona cartas a los profesores?
7. ¿Los sensores RFID deben permitirse cualesquiera o deben estar registrados previamente en el SGBD e identificados?
8. ¿Cuándo se borran datos? ¿Se deben conservar datos de un año para otro o cada año es un reinicio? ¿Cada traspaso de profesor y de clase es un reinicio?
9. Ahora mismo son los profesores (o super_admin) los que gestionan el cambiar a sus alumnos a otro profesor o a otra clase, ¿se debería cambiar de manera automáticamente la clase? ¿cómo? 
	1. Implementación actual: CRUD de alumnos por el profesor "propietario" o super_admin.