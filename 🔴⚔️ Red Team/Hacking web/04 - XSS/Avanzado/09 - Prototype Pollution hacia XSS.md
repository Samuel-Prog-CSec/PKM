---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "En JavaScript, casi todos los objetos heredan de Object.prototype"
Fecha de actualización: 2026-06-13
Nota previa: "[[08 - DOM Clobbering]]"
Nota siguiente: "[[10 - XSS en frameworks modernos]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

En JavaScript, casi todos los objetos heredan de `Object.prototype`. La `prototype pollution` (client-side) explota esto: <mark style="background: #ADCCFFA6;">si el atacante consigue escribir una propiedad en `Object.prototype`, **todos** los objetos de la página la heredan</mark>, incluidos los que el código asume vacíos o de confianza. Cuando esa propiedad contaminada llega a un *sink* peligroso, el resultado es XSS. Es uno de los vectores client-side más rentables de 2026 —y la [[06 - Evasión de filtros XSS y ofuscación|cadena de bypasses de DOMPurify]] se apoya precisamente en él (CVE-2024-45801)—.

# La mecánica: source → contaminación → gadget

El ataque tiene tres piezas que hay que encadenar:

1. **Source**: un punto donde la entrada del usuario se escribe en una propiedad cuyo nombre también controla, usando las claves mágicas `__proto__`, `constructor` o `prototype`.
2. **Contaminación**: la escritura acaba en `Object.prototype`, afectando a toda la aplicación.
3. **Gadget**: código que **lee** una propiedad del objeto contaminado y la pasa a un sink (`innerHTML`, `script.src`, `eval`).

## Sources típicos

- <mark style="background: #FFB86CA6;">Parsing de la query string o el hash a un objeto</mark>: `?__proto__[innerHTML]=<img src=x onerror=alert(1)>`. Muchos routers y parsers de URL caseros son vulnerables.
- **Merge/clone recursivo inseguro**: `$.extend(true, ...)` (jQuery < 3.4), `_.merge`/`_.set` (Lodash antiguo), `Object.assign` profundo casero, mezcla de JSON del usuario en config.
- **`JSON.parse` + merge** de datos controlados.

```javascript
// Source clásico: merge profundo de entrada del usuario
merge({}, JSON.parse('{"__proto__":{"polluted":"yes"}}'));
({}).polluted   // → "yes"  : todo objeto lo hereda ahora
```

## Gadgets que llevan a XSS

El gadget es código legítimo de la app o de una librería que lee una propiedad no inicializada del objeto. Ejemplos reales:

- Una opción de configuración que setea `innerHTML`/`html` desde un objeto contaminable.
- `<script>` cargado con `src` tomado de una propiedad heredada.
- Gadgets conocidos en **jQuery** (manipulación de `attr`/`html`), **Lodash**, plantillas de **AdMob/GTM**, y en los propios sanitizadores —contaminar la **config de DOMPurify** vía PP desactiva comprobaciones y abre mXSS—.

```javascript
// Gadget: la librería usa una opción que cree segura
let opts = config.div || {};
div.innerHTML = opts.template;   // si __proto__.template está contaminado → XSS
```

<mark style="background: #FF5582A6;">La gracia es que el código del gadget es perfectamente normal</mark>: no tiene un bug visible. El fallo está en la combinación de un merge inseguro en otro punto y una lectura confiada de una propiedad heredada.

# Detección

- **DOM Invader** (Burp) detecta prototype pollution automáticamente: inyecta sondas en sources y reporta si llega a `Object.prototype`, y busca gadgets.
- Manual: en la consola, tras navegar con un payload `?__proto__[probe]=1`, comprueba `({}).probe`. Si devuelve `1`, hay contaminación; luego se busca el gadget hasta el sink.
- Herramientas: `ppmap`, y la colección de gadgets de **BlackFan** (`client-side-prototype-pollution`).

# El gadget universal y la detección paso a paso

Algunos gadgets son casi universales porque viven en APIs muy usadas. El más conocido: contaminar una propiedad que termina como atributo `src` de un `<script>`/`<link>` que la app crea dinámicamente —si el elemento no fija su `src`, hereda el contaminado y carga JS remoto—. Variantes equivalentes con `srcdoc`, con `innerHTML` de plantillas y con atributos de configuración de librerías de UI.

El flujo de detección con **DOM Invader** (Burp) es sistemático: activarlo, navegar con la sonda `?__proto__[probe]=1` (y la variante `constructor.prototype`), y dejar que marque tanto la **contaminación** (`Object.prototype.probe` definido) como los **gadgets** que alcanzan un sink. A mano: tras contaminar, comprobar `({}).probe` en consola y rastrear qué propiedad no inicializada lee el código hasta dar con la que desemboca en `innerHTML`/`src`/`eval`. <mark style="background: #FFB86CA6;">El reto rara vez es contaminar; es encontrar el gadget que convierte la contaminación en ejecución</mark>.

# Defensa

- <mark style="background: #8000E1A6;">`Object.freeze(Object.prototype)`</mark> impide cualquier escritura — la mitigación más contundente.
- Rechazar las claves `__proto__`/`constructor`/`prototype` al parsear o mergear entrada.
- Usar `Map` en vez de objetos para datos clave-valor, u objetos con `Object.create(null)` (sin prototipo).
- Mantener librerías al día (jQuery ≥ 3.4, Lodash parcheado).

> [!warning]+ No es solo XSS
> La prototype pollution es un **primitivo**, no un fin: además de XSS, según el gadget puede derivar en bypass de autorización, DoS o, en Node.js, RCE *server-side*. Aquí la tratamos por su salida a XSS, pero al encontrarla en un parámetro conviene mapear **todos** los gadgets disponibles —su impacto puede escalar mucho. Ver [[00 - Introducción a Prototype Pollution|la familia completa]] y, para la explotación en Node.js (bypass de autorización, DoS, RCE), [[01 - Prototype Pollution server-side]].

> [!info]+ Fuentes
> - [PortSwigger — Client-side prototype pollution](https://portswigger.net/web-security/prototype-pollution)
> - [BlackFan — client-side-prototype-pollution](https://github.com/BlackFan/client-side-prototype-pollution) (catálogo de gadgets) · research de s1r1us.
> - [PortSwigger Research — DOMPurify bypass vía PP](https://portswigger.net/research/bypassing-dompurify-again-with-mutation-xss)

DOM Clobbering y prototype pollution atacan el JavaScript genérico de la página. El siguiente bloque aborda los sinks específicos de los frameworks que dominan la web moderna: [[10 - XSS en frameworks modernos]].
