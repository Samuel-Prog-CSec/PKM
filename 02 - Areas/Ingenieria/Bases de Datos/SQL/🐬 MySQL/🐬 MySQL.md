# Structured Query Language (SQL)

La **sintaxis de SQL** puede variar de un RDBMS a otro. Sin embargo, todos deben cumplir con el estándar ISO para lenguaje de consulta estructurado (SQL, en castellano). En los ejemplos de la carpeta [[🐬 MySQL]]  se seguirá la sintaxis **MySQL/MariaDB**. SQL se puede utilizar para realizar las siguientes acciones:
- Recuperar datos 
- Actualizar datos 
- Eliminar datos 
- Crear nuevas tablas y bases de datos 
- Agregar o eliminar usuarios 
- Asignar permisos a estos usuarios

La utilidad `mysql` es usada **para autenticar e interactuar con una BD MySQL/MariaDB**. El parámetro `-u` se usa para indicar el nombre de usuario y el parámetro `-p` para la contraseña. **La contraseña debe pasarse vacía**, de modo que se nos solicite ingresar la contraseña y no la pasemos directamente en la línea de comandos, ya que podría almacenarse en texto sin formato en el archivo `bash_history`.

```shell
mysql -u root -p

Enter password: <password>
...SNIP...
```

Nuevamente, también es posible usar la contraseña directamente en el comando, aunque esto debe evitarse, ya que podría provocar que la contraseña se guarde en los registros y el historial de la terminal:

```shell
mysql -u root -p<password>

...SNIP...

mysql> 
```
==Nota: No deberían haber espacios entre '-p' y la contraseña.==

En los dos ejemplos anteriores, iniciaríamos sesión como **superusuario (o "root")** Podemos ver qué privilegios tenemos usando el comando [SHOW GRANTS](https://dev.mysql.com/doc/refman/8.0/en/show-grants.html) que analizaremos más adelante.
**Cuando no especificamos un host**, se utilizará de manera predeterminada el servidor `localhost`. Podemos especificar un host y un puerto remotos utilizando los parámetros `-h` y `-P`.

```shell
mysql -u root -h docker.hackthebox.eu -P 3306 -p 

Enter password: 
...SNIP...

mysql> 
```
==**Nota**: El puerto MySQL/MariaDB predeterminado es (**3306**), pero se puede configurar con otro puerto. Se especifica utilizando una «P» mayúscula, a diferencia de la «p» minúscula que se utiliza para las contraseñas.== 


# Creating a database
Una vez que iniciamos sesión en la base de datos mediante la utilidad `mysql`, podemos comenzar a usar consultas SQL para interactuar con el DBMS. Por ejemplo, se puede crear una nueva base de datos dentro del DBMS MySQL utilizando la instrucción [CREATE DATABASE](https://dev.mysql.com/doc/refman/5.7/en/create-database.html).

```MySQL
mysql> CREATE DATABASE users;

Query OK, 1 row affected (0.02 sec)
```

MySQL espera que las consultas de línea de comandos **finalicen con un punto y coma**. El ejemplo anterior creó una nueva base de datos llamada `users`. Podemos ver la lista de bases de datos con [SHOW DATABASES](https://dev.mysql.com/doc/refman/8.0/en/show-databases.html), y podemos cambiar a la base de datos `users` con la declaración `USE`:

```MySQL
mysql> SHOW DATABASES;

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| users              |
+--------------------+

mysql> USE users;

Database changed
```

==Las instrucciones SQL **no distinguen entre mayúsculas y minúsculas**, lo que significa que `USE users;` y `use users;` hacen referencia al mismo comando. Sin embargo, el **nombre de la base de datos distingue entre mayúsculas y minúsculas**, por lo que no podemos escribir "USE USERS;" en lugar de "USE users;". Por lo tanto, es una buena práctica **especificar las instrucciones en mayúsculas** para evitar confusiones.==


# Tablas
Los DBMS **almacenan datos en forma de tablas**. Una tabla se compone de filas horizontales y columnas verticales. La intersección de una fila y una columna se denomina **celda**. Cada tabla se crea con un conjunto fijo de columnas, donde cada columna es de un tipo de datos particular. 

Un **tipo de dato define qué tipo de valor debe contener una columna**. Algunos ejemplos comunes son `numbers`, `strings`, `date`, `time` y `binary data`. También puede haber tipos de datos específicos de los DBMS. Se puede encontrar una lista completa de los tipos de datos en MySQL [aquí](https://dev.mysql.com/doc/refman/8.0/en/data-types.html). 
Por ejemplo, podemos crear una tabla llamada `logins` para almacenar datos de usuario, utilizando la consulta SQL [CREATE TABLE](https://dev.mysql.com/doc/refman/8.0/en/creating-tables.html):

```SQL
CREATE TABLE logins (
    id INT,
    username VARCHAR(100),
    password VARCHAR(100),
    date_of_joining DATETIME
    );
```
==Primero se especifica el **nombre de la tabla** y luego (entre paréntesis) **especificamos cada columna** por su nombre y su tipo de datos, separados por comas. Después del nombre y el tipo, podemos especificar propiedades específicas.==
```MySQL
mysql> CREATE TABLE logins (
    ->     id INT,
    ->     username VARCHAR(100),
    ->     password VARCHAR(100),
    ->     date_of_joining DATETIME
    ->     );
Query OK, 0 rows affected (0.03 sec)
```

Se puede obtener una **lista de las tablas de la base de datos actual** mediante la instrucción `SHOW TABLES`. Además, se utiliza la palabra clave `DESCRIBE` para enumerar la estructura de la tabla con sus campos y tipos de datos:

```MySQL
mysql> DESCRIBE logins;

+-----------------+--------------+
| Field           | Type         |
+-----------------+--------------+
| id              | int          |
| username        | varchar(100) |
| password        | varchar(100) |
| date_of_joining | date         |
+-----------------+--------------+
4 rows in set (0.00 sec)
```


## Propiedades de las tablas
Dentro de la consulta `CREATE TABLE`, hay muchas [propiedades](https://dev.mysql.com/doc/refman/8.0/en/create-table.html) que se pueden configurar para la tabla y cada columna. 
Por ejemplo, podemos configurar la columna `id` para que se incremente automáticamente utilizando la palabra clave `AUTO_INCREMENT`, que **incrementa automáticamente el id** en uno cada vez que se agrega un nuevo elemento a la tabla:

```SQL
id INT NOT NULL AUTO_INCREMENT,
```

La restricción `NOT NULL` **garantiza que una columna en particular nunca quede vacía** (es decir, que sea un ==campo obligatorio==). También podemos utilizar la restricción `UNIQUE` para garantizar que **el elemento insertado sea siempre único**.

```SQL
username VARCHAR(100) UNIQUE NOT NULL,
```

Otra palabra clave importante es la palabra clave `DEFAULT`, que se utiliza para **especificar el valor predeterminado**. Por ejemplo, dentro de la columna `date_of_joining`, podemos establecer el valor predeterminado en `Now()`, que ==en MySQL devuelve la fecha y hora actuales==:

```SQL
date_of_joining DATETIME DEFAULT NOW(),
```

Por último, una de las propiedades más importantes es la `PRIMARY KEY`, que podemos utilizar **para identificar de forma única cada registro de la tabla**, haciendo referencia a todos los datos de un registro dentro de una tabla para bases de datos relacionales. Podemos hacer que la columna id sea la CLAVE PRINCIPAL de esta tabla:

```SQL
PRIMARY KEY (id)
```

Combinando las distintas palabras clave para mejorar la tabla del principio, quedaría de la siguiente manera:

```SQL
CREATE TABLE logins (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    date_of_joining DATETIME DEFAULT NOW(),
    PRIMARY KEY (id)
    );
```