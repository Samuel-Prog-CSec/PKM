---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-02
Nota previa: "[[02 - XSS Reflejado]]"
Nota siguiente: "[[04 - Descubrimiento de XSS]]"
Area: "[[XSS.base|XSS]]"
---
---

El tercer tipo, también no persistente, es el `DOM-based XSS`. Mientras el [[02 - XSS Reflejado|reflected]] envía la entrada al servidor, <mark style="background: #ADCCFFA6;">el DOM XSS se procesa **100% en el cliente**: JavaScript modifica la página a través del `Document Object Model (DOM)` sin que la entrada llegue nunca al back-end</mark>.

# Cómo reconocerlo

En una To-Do app vulnerable, al añadir un ítem notas tres cosas en las DevTools:

- En la pestaña **Network**, en este lab **no se genera ninguna petición HTTP** al añadir el ítem — la entrada no sale del navegador. (En una SPA real sí habrá tráfico hacia su API; lo definitorio del DOM XSS es que **tu entrada** no llega al servidor, no que no haya peticiones.)
- El parámetro en la URL usa un **hashtag** (`#task=...`): un parámetro del lado cliente que el navegador procesa localmente (<mark style="background: #FFB86CA6;">el fragmento tras `#` ni siquiera se envía al servidor</mark>, así que un WAF de servidor no lo ve).
- En el código fuente (`CTRL+U`) tu entrada **no aparece**: el JS actualiza la página *después* de cargarse. Para ver el DOM renderizado usas el inspector (`CTRL+SHIFT+C`).

# Source y Sink

El concepto que define el DOM XSS:

- <mark style="background: #ADCCFFA6;">El **`Source`** es el objeto JavaScript que toma la entrada del usuario</mark> (un parámetro de URL, un campo de formulario).
- <mark style="background: #ADCCFFA6;">El **`Sink`** es la función que escribe esa entrada en un objeto del DOM</mark>. Si el `Sink` no sanea la entrada, hay XSS.

`Sinks` peligrosos habituales: `document.write()`, `innerHTML`, `outerHTML`; y en `jQuery`: `add()`, `after()`, `append()`, `.html()`. En el `script.js` de la app, el `Source` es el parámetro `task=`:

```javascript
var pos = document.URL.indexOf("task=");
var task = document.URL.substring(pos + 5, document.URL.length);
```

Y el `Sink` escribe `task` sin sanear con `innerHTML`:

```javascript
document.getElementById("todo").innerHTML = "<b>Next Task:</b> " + decodeURIComponent(task);
```

Entrada controlada + salida sin sanear = vulnerable.

# Ataque: payloads sin `<script>`

El payload `<script>` clásico **no funciona** aquí: <mark style="background: #FFB8EBA6;">`innerHTML` no ejecuta etiquetas `<script>` insertadas dinámicamente</mark> — no por seguridad, sino por cómo la especificación HTML trata los scripts insertados al parsear un fragmento. <mark style="background: #FF5582A6;">No es una protección</mark>: los manejadores de evento (`onerror`, `onload`) sí ejecutan, así que `innerHTML` sigue siendo un *sink* peligroso. La solución es justamente un manejador de evento:

```html
<img src="" onerror=alert(window.origin)>
```

Crea una imagen con una URL vacía; al fallar la carga, el atributo `onerror` <mark style="background: #FF5582A6;">ejecuta el JavaScript sin necesidad de `<script>`</mark>. Para atacar a una víctima, le compartes la URL con el payload en el fragmento (`#task=...`).

> [!info]+ DOM XSS en el mundo real
> - Distingue dos clases de *sink*: los que **inyectan HTML** (`innerHTML`, `document.write`) requieren payload con etiqueta/evento (`<img onerror>`); los que **ejecutan JS directamente** (`eval()`, `setTimeout()`/`setInterval()` con string, `location='javascript:...'`) aceptan código JS a secas. Vigila también `element.setAttribute()`.
> - **`DOM Invader`** (integrado en el navegador de Burp Suite) automatiza el rastreo de *sources* a *sinks*, encontrando DOM XSS que a mano es tedioso.
> - Los frameworks modernos (React, Angular, Vue) escapan la salida por defecto, pero <mark style="background: #FFB86CA6;">reintroduces DOM XSS al usar escotillas como `dangerouslySetInnerHTML` (React) o `bypassSecurityTrustHtml` (Angular)</mark> — los primeros sitios a mirar en una SPA.

Conocidos los tres tipos, el siguiente paso es **encontrarlos** de forma sistemática: el [[04 - Descubrimiento de XSS]].
