---
tags:
  - Web/Red-Team
  - Introduccion
  - PDF-Injection
  - Tipo/Introduccion
Descripción: "Muchas aplicaciones generan PDFs —facturas, informes, tickets— a partir de datos del usuario"
Fecha de actualización: 2026-07-16
Nota previa: ""
Nota siguiente: "[[01 - Detección y fingerprinting de generadores de PDF]]"
Area: "[[PDF Injection.base|PDF Injection]]"
---
<mark style="background: #ADCCFFA6;">Muchas aplicaciones generan PDFs —facturas, informes, tickets— a partir de datos del usuario</mark>. Para controlar el diseño del documento, las librerías de generación aceptan **HTML como entrada** y lo renderizan a PDF. Si parte de ese HTML proviene del usuario sin sanitizar, tenemos **HTML injection en el generador de PDF**. Y como el renderizado ocurre en el **servidor**, el impacto va mucho más allá de un [[00 - Introducción a XSS|XSS]] de cliente.

<mark style="background: #FFB86CA6;">El motor de PDF suele ser un navegador *headless*</mark> —wkhtmltopdf usa WebKit/Qt— que, al procesar el HTML inyectado, descarga recursos externos y ejecuta JavaScript en el servidor. Eso abre la puerta a [[01 - Introducción a SSRF|SSRF]] (`<img>`/`<iframe>` apuntando a URLs internas), LFI (`file:///etc/passwd`) y lectura de ficheros locales vía JS. La propia documentación de wkhtmltopdf lo advierte sin rodeos:

> [!warning]+ Aviso oficial de wkhtmltopdf
> *"Do not use wkhtmltopdf with any untrusted HTML – be sure to sanitize any user-supplied HTML/JS, otherwise it can lead to <mark style="background: #FF5582A6;">complete takeover of the server</mark> it is running on!"*

# Cómo funciona la generación de PDF

Las librerías parsean el HTML, lo renderizan (aplicando CSS para el diseño) y producen el PDF. Las más comunes en aplicaciones web:

| Librería | Lenguaje / motor |
| - | - |
| `wkhtmltopdf` | binario, WebKit + Qt |
| `DomPDF` | PHP |
| `mPDF`, `TCPDF` | PHP |
| `PDFKit`, `html2pdf` | Ruby / JS wrappers |
| `PD4ML` | Java |
| `Puppeteer`, `Playwright` | Chromium headless (Node) — **el estándar de facto en 2026** |

Como el motor procesa etiquetas `<img>`, `<iframe>`, `<link>` o `<script>` **en el servidor**, cualquiera de ellas inyectada en el HTML del PDF se ejecuta con los privilegios del backend.

> [!warning]+ Modernización 2026: `wkhtmltopdf` está muerto — el motor real hoy es Chromium headless
> `wkhtmltopdf` (WebKit/Qt) lleva años sin desarrollo: el repo está archivado y **toda la organización en GitHub fue archivada en jul-2024** (ya ni admite parches de seguridad). El motor dominante en stacks Node modernos es **Puppeteer/Playwright** (Chromium headless vía CDP). Impacto para el fingerprinting de la [[01 - Detección y fingerprinting|nota 01]]: un PDF de Puppeteer/Playwright **no** lleva la firma `Creator: wkhtmltopdf` / `Producer: Qt`, sino <mark style="background: #FFB86CA6;">`Creator: Chromium` / `Producer: Skia/PDF mNNN`</mark>. Y cambia la superficie: en vez de un WebKit congelado de 2013 corres contra un Chromium parcheado (menos RCE por motor viejo), pero el mismo `<iframe src="file://">` / `fetch()` interno sigue dando SSRF/LFI, mitigable con los flags de sandbox de Chromium.

# El escenario típico: la factura

El caso de libro es una tienda online que entrega una factura en PDF tras cada pedido, generada a partir de una plantilla HTML + datos del cliente (nombre, dirección, concepto). <mark style="background: #8000E1A6;">Esos campos controlados por el usuario acaban dentro del HTML que renderiza el generador</mark> — si no se sanitizan, son el punto de inyección.

> [!important]+ No es un XSS de cliente
> La diferencia clave con el [[00 - Introducción a XSS|XSS]]: aquí el HTML/JS lo ejecuta el **servidor** al generar el PDF, no el navegador de una víctima. Por eso el resultado no es robo de sesión sino <mark style="background: #FFB86CA6;">SSRF, lectura de ficheros del servidor y, según la librería, RCE</mark>. Es un ataque server-side, primo de la [[00 - Introducción a los ataques server-side|familia SSRF/SSTI]].

Antes de explotar hay que confirmar la inyección e identificar qué librería (y versión) genera el PDF: [[01 - Detección y fingerprinting de generadores de PDF]].
