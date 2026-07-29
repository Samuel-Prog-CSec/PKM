---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
  - CSP
Descripción: "Una Content Security Policy (CSP) es una medida de *defense-in-depth* que reduce la explotabilidad de un XSS limitando de dónde puede cargarse y ejecutarse código"
Fecha de actualización: 2026-06-08
Nota previa: "[[03 - Pivote a aplicaciones internas]]"
Nota siguiente: "[[05 - Bypass de CSP]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

<mark style="background: #ADCCFFA6;">Una `Content Security Policy` (CSP) es una medida de *defense-in-depth* que reduce la explotabilidad de un XSS limitando de dónde puede cargarse y ejecutarse código</mark>. Se configura en la cabecera `Content-Security-Policy` de la respuesta. No previene la inyección — la limita: aunque el atacante inyecte un `<script>`, el navegador se niega a ejecutarlo si la CSP no lo autoriza.

# Cómo funciona: directivas y valores

Una CSP es una lista de **directivas**, cada una con uno o más valores. Por ejemplo:

```http
Content-Security-Policy: script-src 'self' https://benignsite.htb
```

Esta política instruye al navegador a cargar JavaScript **solo** del mismo origen y de `benignsite.htb`. <mark style="background: #FFB86CA6;">Al no incluir `unsafe-inline`, bloquea también todo script inline</mark>, por lo que estos payloads de XSS quedan neutralizados:

```html
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<a href="javascript:alert(1)">click</a>
```

## Directivas comunes

| Directiva | Controla |
| - | - |
| `script-src` | Orígenes de los que se puede cargar/ejecutar JS |
| `style-src` | Orígenes de hojas de estilo |
| `img-src` | Orígenes de imágenes |
| `connect-src` | Destinos de peticiones desde scripts (`fetch`, `XHR`) |
| `object-src` | Orígenes de `<object>`/`<embed>` |
| `default-src` | Fallback para las directivas no especificadas |
| `frame-ancestors` | Quién puede enmarcar la página (anti-`Clickjacking`) |
| `form-action` | Destinos de envío de formularios |
| `require-trusted-types-for 'script'` + `trusted-types` | Fuerza que los sinks DOM peligrosos (`innerHTML`, `document.write`…) solo acepten objetos `TrustedHTML` verificados, no strings crudos → mata el DOM XSS por sink |

<mark style="background: #FFB8EBA6;">`connect-src` importa especialmente al atacante</mark>: una CSP que lo restrinja a `'self'` impide exfiltrar datos a un servidor externo aunque el XSS ejecute — la exfiltración, no solo la ejecución, es objetivo de la CSP.

> [!important]+ Trusted Types: mitigación DOM-XSS universal desde 2026
> `require-trusted-types-for 'script'` + `trusted-types <política>` es la defensa de navegador diseñada específicamente contra el **DOM XSS por sink**: obliga a que `innerHTML`/`outerHTML`/`document.write()`/`eval` reciban objetos `TrustedHTML`/`TrustedScript` verificados por una política, no strings crudos del atacante. Era "solo Chrome/Edge" desde 2020, pero <mark style="background: #FF5582A6;">desde el **24 de febrero de 2026** tiene soporte cross-browser completo</mark> (Firefox 148 fue el último; Safari lo trae desde su v26). Consecuencia: ya no basta con "abrirlo en Firefox" para esquivarlo — si la app la implementa bien, el DOM XSS por sink queda cerrado en los 4 motores. Fuente: [MDN — Trusted Types](https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API) · [caniuse](https://caniuse.com/trusted-types).

## Valores de directiva

| Valor | Significado |
| - | - |
| `*` | Cualquier origen |
| `'none'` | Ningún origen |
| `'self'` | El mismo origen |
| `*.dominio.htb` | Todos los subdominios |
| `unsafe-inline` | Permite scripts/estilos inline |
| `unsafe-eval` | Permite evaluación dinámica (`eval`) |
| `sha256-...` | Permite un elemento por su hash |
| `nonce-...` | Permite un elemento por su nonce |

# El enfoque moderno: `nonce` + `strict-dynamic`

El modelo de whitelist por host (`script-src 'self' https://cdn.htb`) es frágil: como veremos en [[05 - Bypass de CSP]], basta un gadget JSONP o un *upload* en un origen permitido para saltarlo. La defensa moderna recomendada usa **nonces** y `strict-dynamic`:

- <mark style="background: #ADCCFFA6;">Un `nonce` es un valor aleatorio, distinto en cada respuesta, que va en la cabecera CSP y en cada `<script nonce="...">` legítimo</mark>. El navegador solo ejecuta los scripts con el nonce correcto; como el atacante no puede predecirlo, su `<script>` inyectado no ejecuta.
- `'strict-dynamic'` permite que un script ya confiado (por nonce o hash) cargue otros scripts dinámicamente, **ignorando** las whitelists de host. Esto elimina la dependencia de listas de dominios, que son la fuente de la mayoría de bypass.

```http
Content-Security-Policy: script-src 'nonce-R4nd0mPerRequest' 'strict-dynamic'; object-src 'none'; base-uri 'none';
```

> [!important]+ CSP3 y `unsafe-inline`
> En CSP nivel 3, si hay un `nonce` o `hash` presente en `script-src`, los navegadores **ignoran** `unsafe-inline` por compatibilidad. Esto permite desplegar una CSP basada en nonces sin romper navegadores viejos: los modernos respetan el nonce, los antiguos caen al `unsafe-inline`. No es un agujero, es retrocompatibilidad intencional. De forma análoga, `strict-dynamic` hace que el navegador ignore no solo `unsafe-inline` sino también `'self'`, `https:` y las whitelists de host: confía únicamente en lo que cargue un script ya autorizado por nonce o hash.

# Modos de entrega y monitorización

La CSP puede entregarse de dos formas y en dos modos, y la diferencia importa al atacante:

- **Cabecera HTTP** vs **etiqueta `<meta http-equiv="Content-Security-Policy">`**: la versión `meta` es más limitada — no soporta `frame-ancestors`, `sandbox` ni `report-uri`. Una CSP que dependa de `meta` deja esas protecciones fuera.
- **`Content-Security-Policy-Report-Only`**: <mark style="background: #FF5582A6;">esta cabecera **no bloquea nada**, solo reporta las violaciones</mark>. Si la ves en la respuesta, la CSP está en modo prueba y tu XSS ejecutará igualmente — es un hallazgo a favor del atacante. Las violaciones se envían a la URL de `report-uri` (legacy) o `report-to`, que de paso delata un endpoint de telemetría.

# Una CSP segura

La estrategia recomendada es partir de una base estricta y aflojar solo lo necesario:

```http
Content-Security-Policy: default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; frame-ancestors 'self'; form-action 'self';
```

Esto exige **eliminar todo JavaScript inline**, moviéndolo a ficheros `.js` cargados desde el origen — incluidos los manejadores `onclick`, que se reescriben con `addEventListener`. <mark style="background: #8000E1A6;">Una CSP es tan fuerte como su directiva más débil</mark>: evalúala con el [CSP Evaluator](https://csp-evaluator.withgoogle.com/) de Google, que señala automáticamente directivas peligrosas (`unsafe-inline`, hosts demasiado abiertos, falta de `object-src`/`base-uri`).

Una CSP débil, sin embargo, da una falsa sensación de seguridad: existen múltiples técnicas para sortearla, que vemos en [[05 - Bypass de CSP]].

> [!info]+ Fuentes de referencia
> - [MDN — Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) y [content-security-policy.com](https://content-security-policy.com/)
> - [Google CSP Evaluator](https://csp-evaluator.withgoogle.com/) · [OWASP CSP Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html)
> - [web.dev — strict CSP](https://web.dev/articles/strict-csp)
