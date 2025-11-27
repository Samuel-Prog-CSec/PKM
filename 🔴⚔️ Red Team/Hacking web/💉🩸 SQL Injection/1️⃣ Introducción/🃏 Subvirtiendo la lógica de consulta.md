Antes de ejecutar consultas SQL completas, se va a exponer **cómo modificar la consulta original inyectando el operador OR y utilizando comentarios SQL** para ==subvertir la lógica de la consulta original==. Un ejemplo básico de esto es eludir la autenticación web, lo que demostraremos en esta sección.


# Authentication Bypass
Supongamos una **página de login** (con ==campos de contraseña y nombre de usuario== para que el usuario pueda introducir texto). En este supuesto podemos acceder con credenciales de administrador con: `admin / p@ssw0rd`.

Por simplicidad supongamos que la página también muestra la consulta SQL que se está ejecutando para comprender mejor cómo subvertiremos la lógica de la consulta. Nuestro objetivo es **iniciar sesión como usuario administrador sin usar la contraseña existente**. La consulta SQL actual que se estaría ejecutando es (en caso de logearnos con las credenciales correctas):

```SQL
SELECT * FROM logins WHERE username='admin' AND password = 'p@ssw0rd';
```


## Descubrimiento SQLi
Antes de comenzar a subvertir la lógica de la aplicación web e intentar eludir la autenticación, ==primero tenemos que probar si el formulario de inicio de sesión es **vulnerable a la inyección SQL**==. Para ello, **intentaremos agregar una de los siguientes payloads** después de nuestro nombre de usuario y veremos si provoca algún error o cambia el comportamiento de la página:

| ==Payload== | ==URL Encoded== |
| ----------- | --------------- |
| `'`         | `%27`           |
| `"`         | `%22`           |
| `#`         | `%23`           |
| `;`         | `%3B`           |
| `)`         | `%29`           |
==**Nota**: En algunos casos, es posible que tengamos que usar la versión codificada de la URL del payload Un ejemplo de esto es cuando colocamos nuestro payload directamente en la URL (es decir, **solicitud HTTP GET**).==

Usando estos payloads podríamos ver que en lugar de generarse un error en la página (por introducir unas credenciales erróneas), se puede generar **un error de SQL** . La página habría generado un error porque la consulta resultante fue:

```SQL
SELECT * FROM logins WHERE username=''' AND password = 'something';
```
==**Nota**: Es posible que introducir un número impar de comillas de lugar a un error de sintaxis de SQL.==


## Inyección OR
**Necesitaríamos que la consulta siempre devuelva `true`**, independientemente del nombre de usuario y la contraseña ingresados, para omitir la autenticación. Para hacer esto, ==podemos abusar del operador `OR` en nuestra inyección SQL==. 

La documentación de MySQL para [precedencia de operaciones](https://dev.mysql.com/doc/refman/8.0/en/operator-precedence.html) establece que el operador `AND` **se evaluaría antes** que el operador `OR`. Esto significa que si hay al menos una condición `TRUE` en toda la consulta junto con un operador `OR`, **toda la consulta se evaluará como `TRUE`, ya que el operador `OR` devuelve `TRUE` si uno de sus operandos es `TRUE`**. 

Un ejemplo de una condición que siempre devolverá `TRUE` es `'1'='1'`. Sin embargo, para mantener la consulta SQL funcionando y mantener un número par de comillas, en lugar de usar `('1'='1')`, **eliminaremos la última comilla y usaremos** `('1'='1)`, ==por lo que la comilla simple restante de la consulta original estaría en su lugar==. 

Entonces, si inyectamos la siguiente condición y tenemos un operador `OR` entre ella y la condición original, siempre debería devolver `TRUE`:

```SQL
admin' or '1'='1
```

La **consulta final** quedaría del siguiente modo:

```SQL
SELECT * FROM logins WHERE username='admin' or '1'='1' AND password = 'something';
```

==Esto significa lo siguiente==: 
- Si el nombre de usuario es `admin` 
`OR` 
- Si `1=1` devuelve `true` (que siempre devuelve `true`)
`AND` 
- Si la contraseña es `something`

**Primero se evaluará el operador `AND`** y devolverá falso. **Luego, se evaluará el operador `OR`** y, si alguna de las afirmaciones es verdadera, devolverá verdadero. ==Como `1=1` siempre devuelve verdadero, esta consulta devolverá verdadero y nos otorgará acceso.==

==**Nota**: El payload que usamos anteriormente es una de las muchas cargas útiles de omisión de autenticación que podemos usar para subvertir la lógica de autenticación. Se puede encontrar una lista completa de payloads de omisión de autenticación de SQLi en **PayloadAllTheThings**, cada una de las cuales funciona en un determinado tipo de consultas SQL.==


# Bypass de autenticación con operador OR
Pudimos iniciar sesión correctamente como administrador. Sin embargo, **¿qué pasa si no conocemos un nombre de usuario válido?** Probemos la misma solicitud con un nombre de usuario diferente esta vez.

```SQL
SELECT * FROM logins WHERE username='notAdmin' or '1'='1' AND password = 'something';
```

El ==inicio de sesión fallaría== porque `notAdmin` no existe en la tabla y resultaría en una consulta falsa en general, porque seria `FALSE or FALSE`.

Para volver a iniciar sesión correctamente, **necesitaremos una consulta general verdadera**. Esto se puede lograr inyectando una condición `OR` en el campo de contraseña, de modo que siempre devuelva verdadero. Probemos con:  `something' or '1'='1` ==como contraseña==.

```SQL
SELECT * FROM logins WHERE username='notAdmin' or '1'='1' AND password = 'something' or '1'='1';
```
La condición `OR` adicional ==resultó en una consulta verdadera en general==, ya que la cláusula `WHERE` devuelve todo en la tabla y el usuario presente en la primera fila ha iniciado sesión. En este caso, como ambas condiciones devolverán verdadero, no tenemos que proporcionar un nombre de usuario y contraseña de prueba y podemos comenzar directamente con la inyección `'` e iniciar sesión con solo `' or '1' = '1`.

==**Nota**: podemos omitir tanto la contraseña como el nombre de usuario con esta estructura porque **la consulta se evalúa como verdadera independientemente de estos** (ya que no trabajamos con ellos porque al desconocerlos asumimos que obtendremos `FALSE` en la igualdad).==

```SQL
SELECT * FROM logins WHERE username='' or '1'='1' AND password = '' or '1'='1';
```