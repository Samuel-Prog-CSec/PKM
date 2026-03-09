1. ¿Cómo hacemos para asegurarnos que el Super Admin sepa que el perfil de profesor que tiene delante es un profesor real y no un fake? ¿Con un código quizá que le de un gestor del sistema o la API? ----> Sólo aceptar correos de profesores de dominios conocidos (de la junta o educativos de España).
2. Un profesor puede crear todos los alumnos que quiera, ¿Cómo nos aseguramos que no cree alumnos duplicados? En el caso de que un atacante robe credenciales de acceso o se autentique como profesor, ¿Cómo nos podemos proteger para que no cree perfiles falsos de alumnos en masa o borre perfiles reales? ----> Solo puede crear alumnos el super_admin.
	1. Ahora mismo, aunque en el backend un profesor pueda hacer CRUD de alumnos, en el frotend solo puede transferirlos a otra clase (UPDATE parcial). ¿Quién debería ser realmente el encargado de quitar alumnos, crear alumnos y sus propiedades? ¿Debería tener una pantalla exclusiva para eso?
3. ¿Quién es el actor que modifica los datos de los alumnos (cambios de clase, de profesor, etc.)? ----> El super_admin solo hace CRUD a los datos. Ningún usuario puede crear alumnos o profesores (o editarlos).
4. ¿Un profesor debería tener los permisos para auto-asignarse a una clase? ¿Y para des-asignar a otro? ----> La responsabilidad de gestionar usuarios es del super_admin.
	1. En caso negativo, ¿Quién ejecuta estas tareas?
	2. Actualmente, el profesor al que pertenecen los alumnos es que tiene la responsabilidad de cambiar sus alumnos a otro profesor (para evitar explotación del sistema y que restringir permisos de operaciones, revisar esta implementación -> ¿demasiado restrictiva?).
5. ¿Debemos poder usar cartas RFID cualesquiera o deben esta previamente registradas en el SGBD? ----> No hace falta porque las cartas se pueden perder, romper, … Las cartas deben tener mas flexibilidad en seguridad. Se deben entender como tokens "fungibles".
	1. ¿Quién es el encargado de registrar cartas, el `super_admin`? ¿Es el `super_admin` quien le proporciona cartas a los profesores?
6. ¿Los sensores RFID deben permitirse cualesquiera o deben estar registrados previamente en el SGBD e identificados? ----> Dar de alta los sensores, política de Zero Trust.
7. ¿Cuándo se borran datos? ¿Se deben conservar datos de un año para otro o cada año es un reinicio? ¿Cada traspaso de profesor y de clase es un reinicio? ----> De momento, se guarda todo.
8. Ahora mismo son los profesores (o super_admin) los que gestionan el cambiar a sus alumnos a otro profesor o a otra clase, ¿se debería cambiar de manera automáticamente la clase? ¿cómo? ----> Responsable super_admin.
	1. *Implementación actual*: transferencia de alumnos por el profesor "propietario" o super_admin.
9. El profesor cuando crea un mazo, lo primero que debe hacer es escanear las cartas que lo componen, ¿se debe avisar al profesor si quiere meter una carta que ya este en otro mazo (una carta no puede estar en 2 mazos a la misma vez)? ----> Avisa e intentar moverlo del antiguo al nuevo, si falla, dejarlo en el viejo y avisar error.
	1. ¿Se le avisa al final o se hace comprobación escaneo a escaneo?
	2. ¿Se le avisa sólo y se le señala que esa carta no puede ser o se le hace el cambio de la carta de un mazo a otro automáticamente (previo aviso)?
10. El sistema esta preparado para crear contextos y mecánicas. ¿Quién crea las mecánicas? ¿Deberían estar definidas de base ya y no poder hacer `CREATE`? ----> Mecanicas solo con seeder, no se crean nuevas ni se eliminan ni se editan. Contextos solo con seeders tambien (de momento).
	1. Todos los profesores pueden subir assets a todos los contextos y ver todos los contextos, pero, ¿quién crea contextos? ¿cualquier profesor puede?
11. ¿Se podría entender que hay 1 super_admin por centro educativo (mínimo)? 
	1. Si es así, entonces, ¿quién y cómo crea los `super_admin`?
12. Ya que vamos a trabajar con MongoDB Atlas en Cloud, ¿sería interesante incluir **Data Profiling**? ----> Perder tiempo. Se olvida.
	1. Incorporar pruebas de calidad de datos en el conjunto de datos, permitiendo establecer flujos de trabajo con `SODA`.