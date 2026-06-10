---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa: "[[05 - Bypass de CSP]]"
Nota siguiente: "[[07 - Herramientas para XSS]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

Los fundamentos de evasión —contextos de inyección, bypass de blacklists, encodings, strings sin comillas, *execution sinks* y polyglots— están en [[05 - Evasión y ofuscación de XSS]] del nivel básico. Esta nota asume eso y profundiza en lo que de verdad encuentras en producción: <mark style="background: #FFB86CA6;">WAFs comerciales, sanitizadores de DOM y mutation XSS</mark>, donde el payload de manual no basta.

# Las tres vías de ejecución (recordatorio)

Toda evasión necesita primero un primitivo de ejecución. Hay tres familias, desarrolladas en la [[05 - Evasión y ofuscación de XSS|nota básica]]: la etiqueta `<script>`, los **pseudo-protocolos** (`javascript:`, `data:` en `href`/`data`) y los **event handlers** (`onerror`, `onload`, `ontoggle`). La referencia exhaustiva por navegador es la [XSS cheat sheet de PortSwigger](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet). Lo que sigue es cómo colar esos primitivos a través de defensas reales.

# Evasión de WAF moderno

Un WAF comercial (Cloudflare, Akamai, Imperva) no es una blacklist ingenua: usa firmas, puntuación y a veces ML. Pero sigue inspeccionando **bytes**, y su modelo del HTML rara vez coincide con el del navegador. Las palancas:

- <mark style="background: #ADCCFFA6;">**Parser differentials**: explotar que el WAF parsea el HTML distinto a como lo parsea el navegador</mark>. Etiquetas malformadas, atributos con separadores raros (`/`, `%0c`, backticks) o comentarios HTML que el navegador tolera y el WAF no entiende.
- **Vectores poco firmados**: eventos exóticos (`onpointerrawupdate`, `onbeforetoggle`), etiquetas modernas (`<dialog>`, `<details>`) o construcciones que las firmas, escritas para `onerror`/`onload`, no contemplan.
- **Codificación en la capa correcta**: HTML entities, `\u`, `&#x...;` aplicadas donde el WAF no decodifica pero el navegador sí (ver [[05 - Evasión y ofuscación de XSS|encodings]]).

<mark style="background: #FF5582A6;">La metodología es de caja negra: probar carácter a carácter qué bloquea el WAF</mark>, identificar la firma y construir un payload equivalente que no la dispare pero siga siendo válido para el navegador. No hay payload mágico; hay un proceso de diferenciación.

# Mutation XSS (mXSS): romper sanitizadores

Cuando la app sanea el HTML antes de insertarlo (en vez de bloquear por blacklist), el ataque cambia de naturaleza. <mark style="background: #8000E1A6;">El `mutation XSS` explota que el HTML se parsea **dos veces**: una al sanearlo y otra cuando el DOM lo recibe</mark>, y que el navegador "arregla" HTML malformado mutándolo. Si consigues que el HTML inocuo que aprueba el sanitizador se **mute** en HTML ejecutable al insertarse en el DOM, has saltado el sanitizado.

El payload se esconde típicamente en valores de atributo o en contextos que el navegador reinterpreta al re-parsear (`</style>`, `</title>`, anidamientos), creando un contexto distinto entre los dos parseos. Es la clase de bug más relevante contra sanitizadores modernos.

# Bypasses de `DOMPurify`

[`DOMPurify`](https://github.com/cure53/DOMPurify) es el sanitizador de referencia, y aun así <mark style="background: #FFB86CA6;">acumula bypasses año tras año vía mXSS y prototype pollution</mark> — prueba de que sanear HTML de forma infalible es un problema abierto:

- **CVE-2024-47875** y **CVE-2024-45801**: mXSS basado en **anidamiento**, sorteando la lógica de comprobación de profundidad (la segunda, ayudándose de *prototype pollution*).
- **CVE-2025-26791**: regex defectuosa de *template literals* con `SAFE_FOR_TEMPLATES`, que deja pasar mXSS.
- Cadena continua de *prototype pollution gadgets* en el parser de configuración.

> [!warning]+ La lección operativa
> Si una app usa `DOMPurify`, **comprueba la versión**: una desactualizada es vulnerable a bypasses públicos con PoC. Y aunque esté al día, un sanitizador es código complejo con superficie de bug; ante contenido HTML rico controlado por el usuario, vale la pena probar los vectores mXSS conocidos. El trabajo de referencia es la [investigación de PortSwigger sobre mXSS en DOMPurify](https://portswigger.net/research/bypassing-dompurify-again-with-mutation-xss) y los análisis de [Kévin Mizu](https://mizu.re/post/exploring-the-dompurify-library-bypasses-and-fixes).

# Metodología de evasión en caja negra

<mark style="background: #FF5582A6;">El bypass real nunca es un payload de lista: es un proceso</mark>. Igual que con [[05 - Bypass de SameSite y defensas de cabecera|otros filtros]], el método es:

1. Identificar **qué** se filtra: enviar caracteres y construcciones uno a uno y observar qué pasa y qué se bloquea o transforma.
2. Determinar si es **blacklist** (bloquea ciertos tokens → ofuscación) o **sanitizado** (transforma el HTML → mXSS).
3. Construir el payload que respeta lo permitido pero ejecuta — adaptado al contexto y a la defensa concreta.

Cuando los paréntesis o las comillas están vetados, recurre a colecciones especializadas: [XSS without Parentheses](https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md) y el [HTML5 Security Cheatsheet](https://html5sec.org/).

Con la evasión cubierta, el sub-tema se cierra con el instrumental de explotación avanzada: [[07 - Herramientas para XSS]].

> [!info]+ Fuentes de referencia
> - [PortSwigger Research — Bypassing DOMPurify with mutation XSS](https://portswigger.net/research/bypassing-dompurify-again-with-mutation-xss)
> - [Kévin Mizu — Exploring the DOMPurify library](https://mizu.re/post/exploring-the-dompurify-library-bypasses-and-fixes)
> - [OWASP — XSS Filter Evasion Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html) · [html5sec.org](https://html5sec.org/)
