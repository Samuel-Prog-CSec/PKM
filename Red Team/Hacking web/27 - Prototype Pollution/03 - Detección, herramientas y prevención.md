---
tags:
  - Web/Red-Team
  - Server-Side/Prototype-Pollution
  - Pentesting/Enumeracion
  - Tipo/Deteccion
Descripción: "En un target real rara vez hay reflexión de propiedad, y contaminar propiedades de negocio a ciegas puede tumbar la app de forma persistente (DoS)"
Fecha de actualización: 2026-07-17
Nota previa: "[[02 - Gadgets y RCE server-side]]"
Nota siguiente: ""
Area: "[[Prototype Pollution.base|Prototype Pollution]]"
---
---

En un target real rara vez hay [[01 - Prototype Pollution server-side|reflexión de propiedad]], y contaminar propiedades de negocio a ciegas puede tumbar la app de forma persistente (DoS). La detección seria resuelve ambos problemas con **gadgets seguros**: <mark style="background: #ADCCFFA6;">propiedades internas de frameworks comunes cuyo efecto es observable **y** no destructivo</mark>.

# Gadgets de detección segura

Todos se envían dentro de `__proto__` en un cuerpo JSON, y se prueban con la propiedad puesta vs. quitada para confirmar que el cambio es tuyo:

- **`json spaces`** (Express) — controla la indentación del JSON de respuesta. Es <mark style="background: #FFB8EBA6;">el mejor gadget: no depende de que se refleje nada y es 100% reversible</mark>.
```json
{"__proto__":{"json spaces":10}}
```
Con la propiedad, la respuesta sale indentada; sin ella, compacta.

- **`status` / `statusCode`** (módulo `http-errors`) — fuerza un código de estado. Usar uno obscuro para no confundirlo con uno legítimo:
```json
{"__proto__":{"status":510}}
```

- **`content-type` + charset UTF-7** (bug de `_http_incoming`) — contamina el charset y luego envías un string en UTF-7 (`foo` → `+AGYAbwBv-`); si el servidor lo decodifica en la respuesta, hay contaminación:
```json
{"__proto__":{"content-type":"application/json; charset=utf-7"}}
```

- **`exposedHeaders`** (CORS) — se refleja en la cabecera `Access-Control-Expose-Headers`.
- **Prototipo inmutable** — asignar a `__proto__.__proto__` lanza una excepción; un `500` controlado también delata la contaminación.

<mark style="background: #FF5582A6;">Con cualquiera de estos confirmas la vulnerabilidad sin escribir en una sola propiedad que la app use de verdad.</mark>

# Herramientas

- **Server-Side Prototype Pollution Scanner** — extensión de Burp de PortSwigger ([repo](https://github.com/portswigger/server-side-prototype-pollution)). Automatiza exactamente estos gadgets seguros contra cada request; es el barrido inicial de referencia.
- **DOM Invader** (Burp) es <mark style="background: #FFB8EBA6;">solo client-side</mark> —detecta PP en el navegador, no sirve para server-side—. No confundir el ámbito.
- **Catálogo de gadgets de explotación**: [KTH-LangSec/server-side-prototype-pollution](https://github.com/KTH-LangSec/server-side-prototype-pollution) (paper *Silent Spring*), para saber qué gadget aplica según el `package.json`.
- `ppmap`, `ppfuzz` — orientados a la rama client-side.

# Prevención

Del lado defensivo, en orden de contundencia:

- <mark style="background: #8000E1A6;">`Object.freeze(Object.prototype)`</mark> congela el prototipo global. Matiz: la escritura contaminante **falla en silencio solo en modo *sloppy*** (CommonJS sin `'use strict'`); en **modo estricto** (ESM, `'use strict'`, dentro de `class` — cada vez más habitual en Node) lanza `TypeError`. Útil saberlo: un `500`/excepción no capturada al probar `__proto__` contra un target ya "frozen" es en sí mismo un **indicador** de esta mitigación. Aun así, es la más contundente y barata.
- **Flag de Node** `--disable-proto=delete` (elimina `__proto__` como vía de acceso) o `--disable-proto=throw` (lanza excepción).
- **Objetos sin prototipo** para datos clave-valor del usuario: `Object.create(null)` o `Map` no heredan de `Object.prototype`, así que `__proto__` pasa a ser una clave normal inofensiva.
- **Validación con JSON schema** del cuerpo entrante: rechaza propiedades no esperadas, incluidas `__proto__`/`constructor`.
- **No mergear recursivamente entrada no confiable**; si es inevitable, usar librerías parcheadas que bloqueen las claves mágicas.

> [!warning]+ Filtros que solo bloquean `__proto__`
> Rechazar la cadena literal `__proto__` no basta: `constructor.prototype` llega al mismo sitio (`{"constructor":{"prototype":{"x":1}}}`), y un parser que decodifica dos veces (URL, unicode) puede recomponer `__proto__` tras el filtro. <mark style="background: #8000E1A6;">La defensa robusta es estructural</mark> (freeze / null-proto / schema), no una blacklist de strings —el mismo error que en cualquier otra inyección—.

> [!info]+ Fuentes
> - PortSwigger — [Server-side prototype pollution](https://portswigger.net/web-security/prototype-pollution/server-side) (detección sin reflexión y *bypass* de filtros).
> - Research original: Gareth Heyes, [Server-side prototype pollution: black-box detection without the DoS](https://portswigger.net/research/server-side-prototype-pollution).

Cierra el sub-tema. Para la rama client-side (salida a XSS en el navegador), ver [[09 - Prototype Pollution hacia XSS]].
