---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-13
Nota previa: "[[09 - Prototype Pollution hacia XSS]]"
Nota siguiente:
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

La web moderna corre sobre React, Angular y Vue, y los tres <mark style="background: #ADCCFFA6;">escapan la salida por defecto</mark>: interpolar `{{ dato }}` o `{dato}` produce texto, no HTML, lo que mata el XSS clásico por reflexión. Por eso el XSS en un *target* serio hoy rara vez es el `<script>` de manual —vive en los **escape hatches** del framework, en las **URLs**, y en la inyección de **plantillas** (CSTI)—. Saber dónde mira cada framework es lo que diferencia probar `alert(1)` de encontrar el bug real.

# React

React escapa el contenido de `{}` automáticamente. Los sinks son las salidas explícitas de ese escape:

- <mark style="background: #FF5582A6;">`dangerouslySetInnerHTML={{__html: userInput}}`</mark> — el nombre lo avisa: inyecta HTML crudo. Si `userInput` no se sanea, XSS directo.
- **URLs en `href`/`src`**: `<a href={userInput}>` permite `javascript:alert(1)` —React **no** filtra el esquema `javascript:` en versiones previas a la 16.9, y aun después solo avisa—.
- **Inyección en SSR** y *spread* de props (`{...userProps}`) que cuele un `dangerouslySetInnerHTML`.

# Angular: Client-Side Template Injection (CSTI)

Angular es el caso más jugoso. Usa `[innerHTML]` (sanitizado por su `DomSanitizer`) y `bypassSecurityTrustHtml`/`bypassSecurityTrustResourceUrl` como escape hatches. Pero la joya es la **CSTI**: <mark style="background: #FFB86CA6;">si el usuario controla parte de la **plantilla** (no solo los datos), Angular evalúa su expresión</mark>.

```html
<!-- Si la entrada del usuario se renderiza como template Angular -->
{{constructor.constructor('alert(document.domain)')()}}
```

`AngularJS` (1.x) tenía un *sandbox* de expresiones que se fue rompiendo hasta que lo **eliminaron en la 1.6** por inseguro: hoy una expresión en una plantilla controlada es ejecución directa. En Angular moderno (2+), la CSTI requiere que la app compile plantillas con entrada del usuario (anti-patrón, pero aparece en CMS y *page builders*).

> [!warning]+ La combinación letal: CSTI + CSP
> La CSTI de AngularJS fue históricamente la forma estrella de [[05 - Bypass de CSP|saltarse una CSP]]: el JS se ejecuta a través del propio Angular (ya permitido por la política), sin inyectar un `<script>` propio. Si ves AngularJS y CSP, busca CSTI.

# Vue

Vue se comporta como una mezcla de los dos:

- <mark style="background: #FF5582A6;">`v-html="userInput"`</mark> — el equivalente a `innerHTML`/`dangerouslySetInnerHTML`: inserta HTML sin escapar.
- **`:href="userInput"`** con `javascript:`.
- **CSTI**: Vue compila plantillas, así que una plantilla controlada por el usuario ejecuta expresiones igual que Angular (`{{_c.constructor('alert(1)')()}}` y variantes según versión).

# El patrón común

Los tres frameworks comparten el mismo mapa de riesgo, útil como checklist en un assessment:

| Vector | React | Angular | Vue |
| - | - | - | - |
| HTML crudo | `dangerouslySetInnerHTML` | `[innerHTML]`, `bypassSecurityTrustHtml` | `v-html` |
| URL `javascript:` | `href={...}` | `[href]`, `bypassSecurityTrustUrl` | `:href` |
| Template injection (CSTI) | raro (JSX compilado) | `{{...}}` en template controlado | `{{...}}` en template controlado |

# Server-Side Rendering e hidratación

Los frameworks modernos renderizan en el servidor (Next.js, Nuxt, SvelteKit) y "hidratan" en el cliente, lo que añade sinks propios. <mark style="background: #FFB86CA6;">El más peligroso es la inyección en el estado serializado</mark>: el servidor incrusta un JSON con el estado inicial (`__NEXT_DATA__`, `window.__NUXT__`) en la página, y si un dato del usuario entra ahí sin escapar la secuencia `</script>`, rompe el bloque y permite inyectar HTML/JS. A vigilar también: `dangerouslySetInnerHTML` en componentes que se renderizan en servidor, y las URLs en props que se hidratan sin validar el esquema.

En CSTI, la versión manda: `AngularJS` 1.0–1.5 tenía un *sandbox* de expresiones (con bypasses públicos por versión), y la **1.6 lo eliminó** —cualquier expresión en una plantilla controlada ejecuta sin más—. Entre `Vue 2` y `Vue 3` cambia la sintaxis del gadget, pero el principio se mantiene: <mark style="background: #8000E1A6;">plantilla controlada por el usuario = ejecución</mark>. Por eso el `{{7*7}}`→`49` es la sonda universal de CSTI en cualquiera de ellos.

# Detección y defensa

- **Detección**: identifica el framework y su versión ([[06 - Herramientas para XSS|fingerprinting]], Wappalyzer) —las versiones viejas tienen bypasses públicos—. Busca los sinks por nombre en el bundle JS (recupéralo con [[17 - Fuzzing de directorios y archivos|sourcemaps]] si los hay). Prueba `javascript:` en cada URL reflejada y `{{7*7}}` donde sospeches CSTI (si devuelve `49`, hay evaluación).
- **Defensa**: no pasar datos del usuario a los escape hatches; sanitizar con [[10 - Prevención de XSS|DOMPurify]] si hay que renderizar HTML; validar el esquema de las URLs (solo `http`/`https`); **nunca** compilar plantillas con entrada del usuario.

> [!info]+ Fuentes
> - [PortSwigger — Client-side template injection](https://portswigger.net/research/xss-without-html-client-side-template-injection-with-angularjs)
> - [React XSS pitfalls](https://portswigger.net/web-security/cross-site-scripting) · documentación de seguridad de Angular (`DomSanitizer`) y Vue (`v-html`).

Con los frameworks se cierra el sub-tema de XSS avanzado, ya cubriendo lo que el material clásico no alcanza: la explotación a través de las abstracciones —[[08 - DOM Clobbering|DOM]], [[09 - Prototype Pollution hacia XSS|prototipo]] y plantillas— sobre las que se construye la web actual.
