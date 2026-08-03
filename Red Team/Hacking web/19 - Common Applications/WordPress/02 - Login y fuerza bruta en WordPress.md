---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Explotacion
Descripción: "Con la instalación inventariada, el siguiente objetivo es una sesión autenticada"
Fecha de actualización: 2026-07-17
Nota previa: "[[01 - Enumeración de WordPress]]"
Nota siguiente: "[[03 - Explotación de plugins vulnerables]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Con la instalación inventariada, el siguiente objetivo es **una sesión autenticada**. Se hace en dos pasos encadenados: enumerar usuarios válidos y luego forzar sus contraseñas. Un login como Administrator es prácticamente RCE ([[04 - RCE como administrador en WordPress]]); incluso Editor/Author sirven para alcanzar plugins vulnerables.

# Enumeración de usuarios

Dos vías manuales clásicas, ambas por defecto en instalaciones sin *hardening*:

**1 · Parámetro `?author=<id>`.** WordPress asigna IDs incrementales; `admin` suele ser el `1`. La petición redirige (`301`) a la URL del perfil, cuya `Location` <mark style="background: #FF5582A6;">revela el `login` real del usuario</mark>. Un `404` significa que ese ID no existe:

```shell-session
$ curl -s -I "http://blog.inlanefreight.com/?author=1"
HTTP/1.1 301 Moved Permanently
X-Redirect-By: WordPress
Location: http://blog.inlanefreight.com/index.php/author/admin/

$ curl -s -I "http://blog.inlanefreight.com/?author=100"
HTTP/1.1 404 Not Found
```

Iterando el ID (1, 2, 3…) se reconstruye el listado.

**2 · REST API `/wp-json/wp/v2/users`.** Devuelve directamente los usuarios en JSON:

```shell-session
$ curl -s "http://blog.inlanefreight.com/wp-json/wp/v2/users" | jq '.[] | {id, name, slug}'
{ "id": 1, "name": "admin", "slug": "admin" }
{ "id": 2, "name": "ch4p", "slug": "ch4p" }
```

<mark style="background: #FFB8EBA6;">Desde el core 4.7.1 este endpoint solo lista usuarios que hayan publicado</mark>; antes exponía todos. Sigue siendo el método de enumeración más limpio hoy, y el que sobrevive cuando `?author=` está capado.

> [!info]+ Enumeración de usuarios cuando lo obvio está bloqueado
> Si `?author=` y la REST API están filtrados, quedan canales secundarios: el **sitemap de autores** (`/wp-sitemap-users-1.xml`, generado por defecto desde 5.5), el proxy **oEmbed** (`/wp-json/oembed/1.0/embed?url=<post>`), y sobre todo los **mensajes de error del login** — si `/wp-login.php` responde distinto ante *usuario válido + password mala* (`Error: The password you entered...`) que ante *usuario inexistente* (`Error: Unknown username`), eso es *username enumeration* de manual. Fuente: [WPScan](https://wpscan.com/blog/).

# Fuerza bruta del login

Con la lista de usuarios, se fuerzan contraseñas por dos vectores (las técnicas y wordlists genéricas están en [[00 - Introducción al brute forcing|Brute Forcing]]):

| Vector | Ruta | Nota |
| - | - | - |
| `wp-login` | `/wp-login.php` | Formulario estándar, un intento por request |
| `xmlrpc` | `/xmlrpc.php` | Vía API, **más rápida** y preferida |

Contra `xmlrpc.php` se prueba el método `wp.getUsersBlogs`. Credenciales válidas devuelven la estructura del blog; inválidas, un `faultCode 403`:

```shell-session
$ curl -X POST -d "<methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value>admin</value></param><param><value>CORRECT-PASSWORD</value></param></params></methodCall>" http://blog.inlanefreight.com/xmlrpc.php
# válida →
<member><name>isAdmin</name><value><boolean>1</boolean></value></member>
# inválida →
<name>faultString</name><value><string>Incorrect username or password.</string></value>
```

WPScan automatiza el ataque por cualquiera de los dos vectores (`--password-attack xmlrpc` es el rápido):

```shell-session
$ wpscan --password-attack xmlrpc -t 20 -U admin,david -P passwords.txt --url http://blog.inlanefreight.com
[SUCCESS] - admin / sunshine1
```

> [!warning]+ `system.multicall`: fuerza bruta amplificada
> El verdadero motivo por el que `xmlrpc` sigue importando es el método **`system.multicall`**: empaqueta **cientos de llamadas `wp.getUsersBlogs` en una sola petición HTTP**. <mark style="background: #FFB86CA6;">Un request = cientos de intentos de contraseña</mark>, lo que multiplica la velocidad y **evade** las defensas que cuentan *requests* (fail2ban, rate-limit por IP, límites de intentos de login). Por eso el *hardening* moderno bloquea `system.multicall` o desactiva `xmlrpc.php` entero ([[05 - Detección y evasión en WordPress]]). Su superficie completa como web service — pingback SSRF, XSPA, IP disclosure — está en [[04 - Ataques a xmlrpc.php]].

# Application Passwords — el vector moderno

Desde **WordPress 5.6** (2020) existen las **Application Passwords**: credenciales por usuario, de 24 caracteres, pensadas para clientes API y usadas vía **HTTP Basic Auth** contra la REST API. Se validan contra cualquier endpoint autenticado:

```shell-session
$ curl -s --user "admin:xxxx xxxx xxxx xxxx xxxx xxxx" https://target/wp-json/wp/v2/users/me
```

<mark style="background: #ADCCFFA6;">Son un canal de autenticación paralelo al login web</mark>, y ahí está su peligro: <mark style="background: #8000E1A6;">no las cubre el 2FA</mark> (por diseño, para automatización) y a menudo **no tienen el mismo rate-limiting** que `/wp-login.php`. Fuerza bruta contra `/wp-json/wp/v2/users/me` con Basic Auth es un vector que el material clásico ni menciona. Si consigues una (fuga, phishing, o creándola con una sesión ya comprometida), tienes acceso API persistente que sobrevive a un cambio de contraseña. Fuente: [WordPress REST API Handbook](https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/).

Con credenciales en mano, o bien escalas por el panel de administración ([[04 - RCE como administrador en WordPress]]) o atacas un plugin vulnerable sin necesitar login: [[03 - Explotación de plugins vulnerables]].
