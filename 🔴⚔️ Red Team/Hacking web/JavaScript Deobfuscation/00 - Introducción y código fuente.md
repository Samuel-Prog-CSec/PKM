---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - JavaScript
  - Introduccion
Fecha de actualización: 2026-06-02
Nota previa:
Nota siguiente: "[[01 - Ofuscación de código JavaScript]]"
Area: "[[JavaScript Deobfuscation.base|JavaScript Deobfuscation]]"
---
---

<mark style="background: #ADCCFFA6;">La **desofuscación de código** es la habilidad de revertir código deliberadamente vuelto ilegible para entender qué hace</mark>. Es una destreza central del análisis de código y la ingeniería inversa: en ejercicios red/blue team te topas constantemente con JavaScript ofuscado que esconde su función real —el caso típico es el *malware* que ofusca su JS para descargar el *payload* principal sin que se vea—. Sin desofuscarlo, no sabes qué hace ni puedes neutralizarlo o replicarlo.

# Dónde aparece la ofuscación

No es solo malware. En aplicaciones web legítimas verás JavaScript ofuscado para:

- **Ocultar lógica de negocio o claves**: validaciones del lado cliente, *feature flags*, tokens o claves de API embebidas que el desarrollador no quiere que se lean a simple vista.
- **Anti-tampering y protección anti-bot**: scripts de detección de automatización, *fingerprinting* y soluciones tipo Akamai/PerimeterX que ofuscan su código para frenar el *reversing*.
- **Gating de funciones premium**: lógica que decide qué puede hacer un usuario, a veces *bypasseable* una vez entiendes el código.

<mark style="background: #FFB86CA6;">Para un pentester, desofuscar el JS de un objetivo destapa endpoints ocultos, secretos del lado cliente y lógica de validación</mark> que de otro modo quedaría enterrada — conecta directamente con el análisis de `js_files` del [[11 - Spidering con Scrapy|recon]].

# Localizar el JavaScript de una web

Casi toda web moderna reparte responsabilidades en tres lenguajes: <mark style="background: #FFB8EBA6;">`HTML` define la estructura, `CSS` el diseño y `JavaScript` ejecuta la funcionalidad</mark>. Todo ese código vive en el cliente y lo renderiza tu navegador, así que está a tu alcance — solo hay que mirarlo.

El primer paso es ver el código fuente. Con `[CTRL + U]` abres el `view-source` de la página. Tanto el `CSS` como el `JS` pueden estar **internos** (en línea) o **externos** (en un fichero aparte referenciado):

```html
<!-- CSS interno -->
<style> h1 { font-size: 144px; } </style>

<!-- CSS externo -->
<link rel="stylesheet" href="style.css">

<!-- JS externo: el objetivo a analizar -->
<script src="secret.js"></script>
```

Al abrir `secret.js` te encuentras algo así, ilegible:

```javascript
eval(function (p, a, c, k, e, d) { e = function (c) { ...SNIP... |true|function'.split('|'), 0, {})) 
```

Eso es `code obfuscation`. El resto del módulo trata de revertirlo.

> [!info]+ `view-source` se queda corto: usa las DevTools
> `[CTRL+U]` muestra el HTML **inicial** que envió el servidor, pero las SPA modernas (React, Vue) generan el DOM y cargan scripts dinámicamente, así que mucho JS no aparece ahí. La pestaña **Sources / Debugger** de las DevTools (`F12`) lista **todos** los scripts realmente cargados, permite poner *breakpoints* y usar "pretty print" (`{}`) para formatear sobre la marcha. Para recolectar el JS de un objetivo en masa, `getJS`, `subjs` y los *crawlers* JS-aware (`katana -jc`) lo automatizan.

> [!important]+ Lee siempre los comentarios HTML
> El código fuente HTML suele contener comentarios que los desarrolladores dejan olvidados —rutas internas, credenciales de prueba, notas sobre endpoints—. Es de lo primero que se revisa: información sensible regalada.

Antes de poder desofuscar hay que entender qué es la ofuscación, cómo se hace y por qué. Eso es [[01 - Ofuscación de código JavaScript]].
