No sólo se puede manipular la consulta original, otro tipo de inyección SQL **consiste en inyectar consultas SQL completas ejecutadas junto con la consulta original**. En esta sección, se demostrará esto mediante el uso de la cláusula de unión de MySQL para realizar la **inyección de unión SQL**.


# Unión
La **cláusula de unión** se utiliza para ==combinar resultados de varias sentencias== `SELECT`. Esto significa que a través de una inyección de `UNION`, ==podremos seleccionar y volcar datos de todo el DBMS==, de varias tablas y bases de datos. 

```MySQL
mysql> SELECT * FROM ports UNION SELECT * FROM ships;

+----------+-----------+
| code     | city      |
+----------+-----------+
| CN SHA   | Shanghai  |
| SG SIN   | Singapore |
| Morrison | New York  |
| ZZ-21    | Shenzhen  |
+----------+-----------+
4 rows in set (0.00 sec)
```
`UNION` combinó la salida de ambas sentencias `SELECT` en una sola, por lo que las entradas de la tabla de puertos y la tabla de barcos se combinaron en una única salida con cuatro filas. 


## Columnas pares
Una sentencia `UNION` **solo puede funcionar en sentencias `SELECT`** con la misma cantidad de columnas. Por ejemplo, si intentamos aplicar la sentencia `UNION` a dos consultas que tienen resultados con una cantidad diferente de columnas, obtenemos el siguiente error:

```MySQL
mysql> SELECT city FROM ports UNION SELECT * FROM ships;

ERROR 1222 (21000): The used SELECT statements have a different number of columns
```
La consulta genera un error, ya que la primera consulta `SELECT` ==devuelve una columna y la segunda, dos==. Una vez que tengamos **dos consultas que devuelvan la misma cantidad de columnas**, podemos usar el operador  `UNION` para extraer datos de otras tablas y bases de datos.

Supongamos la siguiente consulta:

```SQL
SELECT * FROM products WHERE product_id = 'user_input'
```

Podemos inyectar una consulta de `UNION` en la entrada, de modo que se devuelvan filas de otra tabla:

```SQL
SELECT * from products where product_id = '1' UNION SELECT username, password from passwords-- '
```
==**Nota**: esta consulta devolvería entradas de nombre de usuario y contraseña de la tabla de contraseñas, asumiendo que la tabla de productos tiene dos columnas.==


## Columnas desiguales
**Normalmente, no tendrá la misma cantidad de columnas que la consulta `SQL` que queremos ejecutar**, por lo que tendremos que solucionarlo. 

Por ejemplo, supongamos que solo tenemos una columna. En ese caso, queremos realizar un `SELECT`, **podemos colocar datos basura para las columnas requeridas restantes** de modo que la cantidad total de columnas con las que estamos realizando la `UNION` ==siga siendo la misma que la consulta original==. 

**Podemos usar cualquier cadena como nuestros datos basura** y la consulta devolverá la cadena como su salida para esa columna. Si realizamos la `UNION` con la cadena "*junk*", la consulta `SELECT` sería:

```SQL
SELECT "junk" from passwords;
```
Esta consulta siempre devolverá "*junk*". **También podemos usar números**. Por ejemplo, la siguiente consulta siempre devolverá 1 como salida:

```SQL
SELECT 1 from passwords;
```
==**Nota**: al completar otras columnas con datos basura, debemos asegurarnos de que el tipo de datos coincida con el tipo de datos de las columnas; de lo contrario, la consulta devolverá un error. Para simplificar, utilizaremos números como datos basura, que también serán útiles para realizar un seguimiento de las posiciones de nuestros payloads.==

==**Consejo**: para una inyección SQL avanzada, es posible que queramos simplemente usar `NULL` para llenar otras columnas, ya que este se adapta a todos los tipos de datos.==

En el ejemplo anterior visto en [[#Columnas pares]], la tabla de productos tiene dos columnas, por lo que debemos realizar una unión con dos columnas. Si solo queremos obtener una columna (por ejemplo, nombre de usuario), debemos realizar nombre de usuario, ==2 (por ejemplo, como dato basura)==, de modo que tengamos la misma cantidad de columnas:

```SQL
SELECT * from products where product_id = '1' UNION SELECT username, 2 from passwords;
```

Si tuviéramos más columnas en la tabla de la consulta original, **tendríamos que agregar más números para crear las columnas restantes requeridas**. Por ejemplo, si la consulta original utilizó `SELECT` en una tabla con cuatro columnas, nuestra inyección `UNION` sería:

```SQL
SELECT * from products where product_id UNION SELECT username, 2, 3, 4 from passwords-- '
```
