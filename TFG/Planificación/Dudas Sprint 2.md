1. ¿Cómo hacemos para asegurarnos que el Super Admin sepa que el perfil de profesor que tiene delante es un profesor real y no un fake? ¿Con un código quizá que le de un gestor del sistema o la API?
2. Un profesor puede crear todos los alumnos que quiera, ¿Cómo nos aseguramos que no cree alumnos duplicados? En el caso de que un atacante robe credenciales de acceso o se autentique como profesor, ¿Cómo nos podemos proteger para que no cree perfiles falsos de alumnos en masa o borre perfiles reales?
3. ¿Quién es el actor que modifica los datos de los alumnos (cambios de clase, de profesor, etc.)?
4. ¿Un profesor debería tener los permisos para auto-asignarse a una clase? ¿Y para des-asignar a otro?
	1. En caso negativo, ¿Quién ejecuta estas tareas?