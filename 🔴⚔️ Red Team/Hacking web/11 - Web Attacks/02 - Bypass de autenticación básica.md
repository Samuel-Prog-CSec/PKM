---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Verb-Tampering
Fecha de actualización: 2026-07-15
Nota previa: "[[01 - Introducción a HTTP Verb Tampering]]"
Nota siguiente: "[[03 - Bypass de filtros de seguridad]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Primer vector canónico: una **configuración insegura del servidor** limita la autenticación a ciertos métodos, y usamos un método fuera de esa lista para <mark style="background: #FFB86CA6;">saltarnos el `HTTP Basic Auth` por completo</mark>. El objetivo es una funcionalidad protegida (un botón *Reset* que borra ficheros) que solo pueden usar usuarios autenticados.

# Identificar la zona protegida

En la app de ejemplo (un *File Manager*), crear archivos está permitido, pero pulsar el botón rojo *Reset* dispara un prompt de `HTTP Basic Auth`. Sin credenciales, obtenemos un `401 Unauthorized`.

El primer paso es delimitar **qué** está protegido. Mirando la URL a la que apunta el botón vemos que es `/admin/reset.php`. Visitando directamente `/admin/` también nos pide login → <mark style="background: #ADCCFFA6;">todo el directorio `/admin` está restringido</mark>, no solo esa página.

> [!tip]+ Enumerar el alcance de la protección
> Antes de intentar el bypass, mapea el directorio protegido con un fuzzer ([[15 - Introducción al web fuzzing|ffuf]], `feroxbuster`). Saber qué endpoints viven bajo `/admin` te dice qué acciones podrás disparar una vez saltada la auth.

# Explotación

Interceptamos la petición del *Reset* en [[01 - Instalación y configuración del proxy|Burp]] y examinamos el método. La página usa `GET`. Probamos a cambiarlo con **Change Request Method** (clic derecho → `Change Request Method`):

- `GET` → `POST`: seguimos recibiendo `401`. La autenticación **cubre** también `POST`.

No basta con `POST`. El truco es usar un método que el servidor acepte pero que **no** esté en la regla de autorización. El candidato estrella es `HEAD`, idéntico a `GET` salvo que la respuesta no lleva cuerpo — pero el servidor **ejecuta la misma lógica** que en un `GET`. Primero confirmamos qué métodos acepta el servidor con `OPTIONS`:

```shell-session
$ curl -i -X OPTIONS http://SERVER_IP:PORT/

HTTP/1.1 200 OK
Date: ...
Server: Apache/2.4.41 (Ubuntu)
Allow: POST,OPTIONS,HEAD,GET
Content-Length: 0
Content-Type: httpd/unix-directory
```

La cabecera <mark style="background: #FF5582A6;">`Allow: POST,OPTIONS,HEAD,GET`</mark> confirma que `HEAD` está aceptado (el comportamiento por defecto de muchos servidores). Cambiamos el método de la petición de *Reset* a `HEAD` y la reenviamos:

```http
HEAD /admin/reset.php HTTP/1.1
Host: SERVER_IP
```

Ya no hay prompt de login ni `401`: recibimos una respuesta **vacía** (esperable en un `HEAD`), pero <mark style="background: #8000E1A6;">la función de *Reset* se ejecuta igual</mark> — al volver al *File Manager* vemos que todos los ficheros han sido borrados. Hemos disparado una acción de administrador **sin credenciales**.

# Por qué funciona

La configuración vulnerable en Apache es algo como:

```xml
<Directory "/var/www/html/admin">
    AuthType Basic
    AuthName "Admin Panel"
    AuthUserFile /etc/apache2/.htpasswd
    <Limit GET>
        Require valid-user
    </Limit>
</Directory>
```

`<Limit GET>` (o `<Limit GET POST>`) aplica `Require valid-user` **solo** a los verbos listados. Cualquier otro método aceptado por el servidor (`HEAD`, `OPTIONS`, verbos arbitrarios) llega al recurso <mark style="background: #FFB86CA6;">sin pasar por la autenticación</mark>. Esto es lo que el paper clásico de Arshan Dabirsiaghi llama *VBAAC* (`Verb-Based Authentication and Access Control`) y su bypass mediante verb tampering.

> [!warning]+ Gotchas en un pentest real
> - `HEAD` no devuelve cuerpo: si la acción **depende** de leer la respuesta (p. ej. exfiltrar datos), `HEAD` no sirve; úsalo para acciones con **efecto de lado** (borrar, resetear, crear).
> - Prueba **todos** los métodos, no solo `HEAD`: `PUT`, `DELETE`, `PATCH`, `TRACE`, e incluso verbos **inventados** (`FOO`, `CATZ`). Apache trata a menudo los métodos desconocidos como `GET`, saltándose reglas `<Limit>` que solo listan verbos estándar.
> - Si hay un balanceador/WAF delante, combina con [[04 - Detección, evasión y prevención de Verb Tampering|cabeceras de method override]] (`X-HTTP-Method-Override`).

En la siguiente sección atacamos el segundo tipo: [[03 - Bypass de filtros de seguridad|saltar un filtro de inyección]] causado por código inseguro. La caza sistemática de estos casos y su automatización está en [[04 - Detección, evasión y prevención de Verb Tampering|Detección y evasión]] y [[05 - Herramientas para HTTP Verb Tampering|Herramientas]].

## Referencias

- OWASP — [Bypassing VBAAC with HTTP Verb Tampering](https://cheatsheetseries.owasp.org/assets/REST_Security_Cheat_Sheet_Bypassing_VBAAC_with_HTTP_Verb_Tampering.pdf) (paper clásico de Arshan Dabirsiaghi)
- HackTricks — [403 & 401 Bypasses](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/403-and-401-bypasses)
- Apache HTTP Server — [`<Limit>` y `<LimitExcept>`](https://httpd.apache.org/docs/2.4/mod/core.html#limitexcept)
