---
tags:
  - Web/Red-Team
  - PDF-Injection
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Introducción a HTML injection en generadores de PDF]]"
Nota siguiente: "[[02 - Explotación de la generación de PDF]]"
Area: "[[PDF Injection.base|PDF Injection]]"
---
---

Antes de explotar hay dos preguntas: ¿la aplicación **refleja HTML** en el PDF? y ¿qué **librería y versión** lo genera? La segunda decide toda la explotación posterior, porque cada motor tiene capacidades y CVEs distintas.

# Confirmar la HTML injection

Inyectar HTML simple en cualquier campo que acabe en el PDF (nombre, dirección, concepto de la factura, notas). Si el PDF lo renderiza **formateado** en lugar de como texto literal, es inyectable:

```html
<h1>test</h1>
<b>negrita</b>
<u>subrayado</u>
```

Si `<h1>test</h1>` sale como un título grande y no como el texto `<h1>test</h1>`, <mark style="background: #FF5582A6;">el generador está interpretando nuestro HTML</mark>. El siguiente escalón es probar etiquetas que cargan recursos (`<img src=x>`, `<iframe>`) para confirmar que el motor hace peticiones.

# Fingerprinting: identificar librería y versión

<mark style="background: #ADCCFFA6;">La mayoría de librerías dejan su firma en los metadatos del PDF</mark>. Basta con obtener un PDF generado por la app (hacer un pedido, generar un informe) y leer sus metadatos con `exiftool`:

```shell-session
$ exiftool invoice.pdf
...
Creator   : wkhtmltopdf 0.12.6.1
Producer  : Qt 4.8.7
...
```

Los campos `Creator` y `Producer` delatan el motor y su versión. Otra librería deja otra huella:

```shell-session
$ exiftool file.pdf
...
Producer  : dompdf 2.0.3 + CPDF
```

`pdfinfo` sirve igual (`Creator`/`Producer`). <mark style="background: #FFB86CA6;">Con la versión exacta, se buscan CVEs conocidas de ese motor.</mark>

# Por qué la librería lo cambia todo

Cada motor abre vectores distintos:

| Librería | Vector característico |
| - | - |
| `wkhtmltopdf` | WebKit ejecuta JS → SSRF, LFI (`file://`), lectura de ficheros vía XHR |
| `DomPDF` | RCE vía caché de fuentes `@font-face` (CVE-2022-28368) |
| `mPDF` / `TCPDF` | LFI vía adjuntos/anotaciones y `<annotation>` |

> [!important]+ El primer paso de recon
> <mark style="background: #8000E1A6;">Conseguir un PDF de muestra y pasarle `exiftool` es el reconocimiento más rentable</mark>: en segundos sabes el motor y la versión, y con eso decides si vas a por SSRF/LFI (wkhtmltopdf) o a por RCE por CVE (DomPDF). Sin esa huella estás explotando a ciegas.

Confirmada la inyección e identificado el motor, pasamos a la explotación: [[02 - Explotación de la generación de PDF]].
