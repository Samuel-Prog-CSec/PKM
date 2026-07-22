---
tags:
  - Web/Red-Team
  - Pentesting/Reporting
  - XSS
Fecha de actualización: 2026-06-02
Nota previa: "[[09 - Robo de sesión]]"
Nota siguiente:
Area: "[[XSS.base|XSS]]"
---
---

La XSS se ancla en dos puntos: un [[03 - XSS basado en DOM|`Source`]] (la entrada del usuario) y un `Sink` (donde se muestra). <mark style="background: #ADCCFFA6;">Prevenirla es asegurar ambos, en front-end **y** back-end</mark>. La pieza central es el **output encoding por contexto** (más sanitización con `DOMPurify` cuando hay que permitir HTML); la validación de entrada y el resto son capas que refuerzan.

# Front-end

- **Validación**: comprobar que la entrada tiene el formato esperado (un `regex` de email rechaza lo que no lo sea). Filtra entradas obviamente malformadas.
- **Sanitización**: escapar los caracteres especiales. La librería estándar es <mark style="background: #ADCCFFA6;">`DOMPurify`</mark>, imprescindible cuando **debes** permitir HTML (editores de texto rico):
  ```javascript
  let clean = DOMPurify.sanitize(dirty);
  ```
- **No usar entrada directa** dentro de `<script>`, `<style>`, atributos o comentarios, y evitar los *sinks* peligrosos vistos en [[03 - XSS basado en DOM|DOM XSS]]: `innerHTML`, `outerHTML`, `document.write()`, y las funciones jQuery `html()`, `append()`, `after()`, etc.

> [!warning]+ El front-end nunca es suficiente
> <mark style="background: #FF5582A6;">La validación de front-end se salta trivialmente</mark> enviando una petición `GET`/`POST` a mano (con `curl` o Burp), sin pasar por el JavaScript del navegador. **Toda** validación cliente es cosmética para la seguridad: el control real va en el back-end. El front-end mejora la UX; no defiende.

# Back-end

- **Validación**: igual que en front, con `regex` o funciones de librería. En PHP, `filter_var($_GET['email'], FILTER_VALIDATE_EMAIL)`.
- **Sanitización**: en Node, `DOMPurify` (sobre `jsdom` en servidor, p. ej. `isomorphic-dompurify`). ⚠️ En PHP, `addslashes()` —que sugiere HTB— **no previene XSS**: solo escapa comillas y backslash, no toca `<`, `>` ni `&`, así que un `<script>` pasa intacto. El fix real es el *output encoding* (abajo). La entrada directa (`$_GET['email']`) **nunca** debe mostrarse tal cual.
- **Output encoding**: <mark style="background: #FFB86CA6;">codificar los caracteres especiales a sus entidades HTML al **mostrar** la entrada</mark> (`<` → `&lt;`), de modo que el navegador los pinte como texto y no como código. En PHP, `htmlspecialchars()` / `htmlentities()`.

> [!important]+ El output encoding context-aware es el verdadero fix
> HTB lista `htmlentities` como una medida más, pero <mark style="background: #FFB86CA6;">la defensa más efectiva contra XSS es codificar la salida según el **contexto** donde aterriza</mark>. No es lo mismo escapar para cuerpo HTML que para un atributo, para un string de JavaScript o para una URL — cada contexto tiene su codificación (la guía de referencia es el *OWASP XSS Prevention Cheat Sheet*). Aplicar la codificación equivocada deja huecos. Por eso los frameworks modernos (React, Angular, Vue) escapan la salida **por contexto automáticamente** — y son hoy la defensa de base; los agujeros aparecen solo en sus escotillas (`dangerouslySetInnerHTML`).

# Defensa en profundidad

Ninguna capa basta por sí sola. Sobre el servidor:

- **`Content-Security-Policy`**: la capa moderna clave. Una buena `CSP` (`script-src 'self'`, sin `unsafe-inline`, con *nonces*) <mark style="background: #FFB86CA6;">neutraliza la mayoría de XSS aunque exista la inyección</mark>, porque el navegador se niega a ejecutar scripts no autorizados (su funcionamiento y sus bypasses se desarrollan en [[04 - Content Security Policy (CSP)]] y [[05 - Bypass de CSP]]). Su punto débil: un `unsafe-inline` la anula (aunque, con un *nonce* o *hash* presente, los navegadores **ignoran** `unsafe-inline` por compatibilidad — CSP3). El *bypass* real de una CSP por lo demás estricta son los **gadgets JSONP** en `'self'` o en dominios permitidos; la mitigación moderna es `strict-dynamic` + *nonces* (investigación de Google *"CSP Is Dead, Long Live CSP"*).
- **`HttpOnly` y `Secure`** en las cookies: `HttpOnly` impide que `document.cookie` lea la cookie (mata el [[09 - Robo de sesión|robo de sesión]]); `Secure` la restringe a HTTPS.
- **Cabeceras** como `X-Content-Type-Options: nosniff` y HTTPS en todo el dominio.
- **WAF**: detecta y bloquea inyecciones en las peticiones (aunque es evadible — ver la [[05 - Evasión y ofuscación de XSS|ofuscación de payloads]]).

> [!important]+ El modelo mental: capas, no balas de plata
> <mark style="background: #8000E1A6;">La seguridad frente a XSS es defensa en profundidad</mark>: validar → sanitizar/codificar por contexto → CSP → cookies `HttpOnly` → WAF. Si una capa falla, otra contiene el daño. Como pentester, tu trabajo es encontrar el hueco entre capas; como defensor, no confiar en una sola. Practicar ambos lados —ofensivo y defensivo— es lo que da una protección fiable.

---

Con esto cerramos XSS: <mark style="background: #8000E1A6;">qué es, sus tres tipos ([[01 - XSS Almacenado|almacenado]], [[02 - XSS Reflejado|reflejado]], [[03 - XSS basado en DOM|DOM]]), cómo descubrirla, explotarla (defacing, phishing, robo de sesión) y prevenirla</mark>. El primitivo —ejecución de JavaScript arbitrario en el navegador de la víctima— es simple, pero su impacto, bien encadenado, llega al *Account Takeover* completo y al [[00 - Introducción a la explotación XSS avanzada|pivote a la red interna de la víctima]]. La lectura de payloads ofuscados que aparecen en estos ataques se apoya en la [[00 - Introducción y código fuente|desofuscación de JavaScript]].
