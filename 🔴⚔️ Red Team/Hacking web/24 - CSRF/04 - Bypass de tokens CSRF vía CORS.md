---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CORS
  - CSRF
Fecha de actualización: 2026-06-08
Nota previa: "[[03 - CORS Misconfigurations]]"
Nota siguiente: "[[05 - Bypass de SameSite y defensas de cabecera]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Un [[01 - Fundamentos y defensas de CSRF|token CSRF]] bien implementado debería bloquear todo ataque cross-site: el atacante no puede adivinar el valor. Pero si la aplicación tiene además una [[03 - CORS Misconfigurations|CORS misconfiguration]] que permite leer respuestas autenticadas, <mark style="background: #FFB86CA6;">el atacante deja de necesitar adivinar el token: lo **lee** directamente de la sesión de la víctima y lo incrusta en su petición</mark>. La defensa primaria contra CSRF cae por un fallo en una capa distinta.

# El requisito doble

Para que esta técnica funcione hacen falta **dos** condiciones simultáneas:

1. <mark style="background: #ADCCFFA6;">Una CORS misconfig que permita leer respuestas autenticadas cross-origin</mark> (reflejo de origen + `Access-Control-Allow-Credentials: true`). Sin poder leer la respuesta, no hay forma de extraer el token.
2. <mark style="background: #FF5582A6;">La cookie de sesión con `SameSite=None`</mark>. Solo así el navegador la adjunta a las peticiones que lanza nuestro JavaScript; con `Lax` (el valor por defecto), la cookie no viajaría en las peticiones desde el payload y todo el ataque fracasa. Por especificación, `SameSite=None` exige `Secure`, de ahí que estos labs sean solo HTTPS.

Esa exigencia de `SameSite=None` es la razón por la que esta técnica, devastadora cuando se da, es **poco frecuente**: la mayoría de aplicaciones dejan la cookie en `Lax` por defecto.

# Detección

Aplica el [[03 - CORS Misconfigurations|test base de CORS]] (Origin inventado reflejado + credenciales) y verifica el atributo de la cookie de sesión en la respuesta del login:

```http
Set-Cookie: PHPSESSID=...; Secure; SameSite=None
Access-Control-Allow-Origin: https://somearbitraryvalue.htb
Access-Control-Allow-Credentials: true
```

Si se dan las dos cosas, busca un endpoint state-changing protegido por token (un `POST /profile.php` con `csrf_token`) y el endpoint `GET` que **sirve** ese token en un formulario.

# Explotación: leer el token y reenviarlo

El payload hace dos peticiones en la sesión de la víctima. Primero un `GET` al endpoint que genera el formulario, del que extrae el token con `DOMParser`; después el `POST` state-changing con el token válido incrustado:

```js
// 1) Leer un token CSRF válido de la sesión de la víctima
var xhr = new XMLHttpRequest();
xhr.open('GET', 'https://bypassing-csrftokens.htb/profile.php', false);
xhr.withCredentials = true;
xhr.send();
var doc = new DOMParser().parseFromString(xhr.responseText, 'text/html');
var csrftoken = encodeURIComponent(doc.getElementById('csrf_token').value);

// 2) Enviar la petición state-changing con el token válido
var csrf_req = new XMLHttpRequest();
var params = `promote=htb-stdnt&csrf_token=${csrftoken}`;
csrf_req.open('POST', 'https://bypassing-csrftokens.htb/profile.php', false);
csrf_req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
csrf_req.withCredentials = true;
csrf_req.send(params);
```

<mark style="background: #8000E1A6;">Como todo ocurre dentro de la sesión de la víctima, el token es válido incluso si está correctamente atado a la sesión y verificado en el backend</mark>: el servidor no distingue esta petición de una legítima. `DOMParser` es la pieza clave: convierte el HTML de la respuesta en un documento navegable del que se extrae el `value` del campo oculto sin tener que parsear texto a mano.

> [!important]+ Por qué la defensa "correcta" no salva aquí
> El token CSRF cumple su requisito —es impredecible y está atado a la sesión—, pero su seguridad depende de que **nadie más pueda leerlo**. La CORS misconfig rompe justo esa premisa. Es un recordatorio de que las defensas no se evalúan en aislamiento: un token CSRF perfecto y una cabecera CORS laxa, combinados, dejan la aplicación tan expuesta como si no hubiera token.

# Variantes según cómo se gestione el token

El ataque base asume un token en un campo oculto del HTML, pero tres variantes habituales cambian los detalles de la explotación:

- **Token de un solo uso**: si el token rota tras cada petición, el `GET` que lo lee y el `POST` que lo usa deben ir **seguidos**, sin que ninguna otra petición de la víctima consuma el token entre medias. El XHR síncrono ayuda precisamente a encadenarlos sin huecos.
- **Token en cabecera custom** (`X-CSRF-Token`, el patrón típico de las SPA): la aplicación espera el token en una cabecera, no en el cuerpo. Hay que leerlo (del HTML, de una etiqueta `<meta>` o de un endpoint) y añadirlo con `setRequestHeader`. <mark style="background: #FFB8EBA6;">Pero añadir una cabecera custom convierte la petición en *preflighted*</mark>, así que exige una CORS misconfig **aún más permisiva** que incluya esa cabecera en `Access-Control-Allow-Headers`.
- **Double-submit cookie**: el token viaja a la vez en una cookie y en un parámetro, y el backend solo comprueba que coincidan. El patrón cae si el atacante consigue el valor del token: una CORS misconfig **no** da acceso directo al `document.cookie` de otro origen (eso no existe como primitiva del navegador), pero **sí** deja leer el **cuerpo de una respuesta** que, por diseño de la app, refleja ese mismo valor (un endpoint que devuelve el token en JSON/HTML) — y con él se rellena el parámetro. También cae si el atacante puede **fijar** la cookie (*cookie tossing*).

Las CORS misconfigs son una vía; existen otras para sortear las defensas CSRF cuando no hay un fallo de CORS tan limpio. Las recogemos en [[05 - Bypass de SameSite y defensas de cabecera]].

> [!info]+ Fuentes de referencia
> - [PortSwigger — Bypassing SameSite with CORS / reading CSRF tokens](https://portswigger.net/web-security/cors)
> - [MDN — DOMParser](https://developer.mozilla.org/en-US/docs/Web/API/DOMParser)
