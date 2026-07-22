---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions]]"
Nota siguiente: "[[09 - Prevención de File Upload Attacks]]"
Area: "[[File Upload.base|File Upload]]"
---
---

En el lab, detectar es trivial: hay un formulario, subes un `.php` y ves el resultado. En un objetivo real con defensas, <mark style="background: #FFB86CA6;">el trabajo está en encontrar la superficie, identificar qué valida cada endpoint y confirmar el éxito cuando no ves nada</mark>. Esta nota sistematiza esa metodología —la parte que HTB da por supuesta— para pentest y bug bounty.

# Mapear la superficie de subida

El formulario obvio es la punta del iceberg. Ordenado por laxitud de validación típica:

- **Perfiles / avatares**: la validación más débil ("es solo una foto"). Primer punto a probar (SVG, EXIF, dimensiones extremas).
- **Import de CSV/XML** (`importar`, `bulk`, `template`): validación distinta del resto → XXE, CSV formula injection, traversal en nombres de campo.
- **Attachments de ticketing/CRM/email**: el parser del adjunto (Tika, LibreOffice headless, ImageMagick) arrastra sus propios CVE.
- **APIs REST sin UI**: `/api/upload`, `/api/files`, `/api/media`, `/api/attachments` suelen carecer de los validadores del formulario web equivalente.
- **GraphQL**: busca en la introspección tipos `Upload` y mutaciones con ese argumento; el endpoint acepta `multipart/form-data`.
- **Backup/restore, themes/plugins** (WordPress, Drupal): procesan ZIPs con contenido arbitrario → [[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions|ZIP Slip]].

<mark style="background: #FF5582A6;">Los endpoints de subida más jugosos no están en el menú</mark>: viven en el JavaScript. Análisis de JS, activo y archivado:

```shell-session
$ katana -list alive.txt -d 2 -jc -silent | grep -E '\.js$' | sort -u > live.js
$ gau --subs target.com | grep -E '\.js$' | sort -u >> archive.js
$ cat *.js | grep -aoE '(upload|attachment|presigned|multipart|/api/[a-z]+)' | sort -u
```

Después, `LinkFinder`/`GAP`/`JSpector` sobre los ficheros, y **los source maps `.js.map`** (exponen el código fuente original con rutas internas). Dorking: `inurl:upload site:target.com`, `intitle:"index of" /uploads`.

# Presigned URLs de S3 (patrón cloud moderno)

Cada vez más apps piden al backend una **URL prefirmada** y el cliente sube directo a S3. Se identifica al instante por los query params:

```text
https://bucket.s3.amazonaws.com/key.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=...&X-Amz-Signature=...&X-Amz-Expires=3600
```

<mark style="background: #FFB86CA6;">Vector central: si la validación (tamaño/tipo) ocurre solo al *generar* la URL pero no en el `PUT` efectivo, subes cualquier contenido directo</mark> —eludiendo límites de API Gateway y validación client-side—:

```python
requests.put(presigned_url, data=open("xss.html","rb"))
```

Si el endpoint acepta el `key`/`filename` del cliente para generar la URL, se puede sobrescribir el fichero de otro usuario. [Detectify](https://labs.detectify.com/writeups/bypassing-and-exploiting-bucket-upload-policies-and-signed-urls/) documenta el abuso de las bucket policies. Los equivalentes en **Azure** (`*.blob.core.windows.net?sv=...&sig=...`, SAS tokens) y **GCS** (`storage.googleapis.com/...?X-Goog-Signature=...`) comparten el patrón: la validación ocurre al *generar* la URL, no en el `PUT`.

# Fuzzing y huella del validador

Capturada la petición multipart en Burp (guardada como `upload.req` con `FUZZ` en la extensión), `ffuf` barre extensiones y Content-Types:

```shell-session
$ ffuf -request upload.req -request-proto https \
    -w web-extensions.txt:EXT -w web-all-content-types.txt:CT -fr "not allowed" -mc 200
```

El **mensaje de rechazo delata el validador** y guía el bypass:

| Señal en la respuesta | Validador activo | Bypass |
| - | - | - |
| "extension not allowed" | Extensión | `.phar`, `.phtml`, doble ext, case |
| "invalid file type" + MIME | `Content-Type` | Cambiar a `image/jpeg` |
| "file signature invalid" | Magic bytes | Prepend `GIF89a` / `FF D8 FF` |
| bloqueo de `../` | Path traversal | `%2e%2e%2f`, `..%252f` |
| acepta, pero respuesta tardía/distinta | Procesamiento async | [[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions|second-order]] |

# Oráculos: dónde aterriza y cómo confirmar

Primero, **identificar el almacenamiento** por la respuesta: `s3.amazonaws.com`/`Server: AmazonS3` (S3), `*.cloudfront.net` (CDN), `*.blob.core.windows.net` (Azure), `/uploads/2026/06/...` (local). Si la ruta no se filtra: leak en el cuerpo/`Location`, **forzar un error verboso** (fichero malformado → `move_uploaded_file(): failed` revela la ruta absoluta), o fuzzear el directorio.

El **esquema de nombres** decide si el ataque es viable: secuencial (`avatar_1042`) → predecible; `time()` → espacio acotable; hash del nombre → predecible si conoces el original; <mark style="background: #FFB8EBA6;">UUID v4 aleatorio → impredecible, hay que pivotar a otro oráculo</mark>.

# Blind upload: cuando no ves nada

Sin ruta visible ni output, necesitas un **oráculo**. Por fiabilidad:

| Oráculo | Señal | Cuándo |
| - | - | - |
| **OOB (el más potente)** | Callback DNS/HTTP a tu Collaborator/interactsh | El fichero se **procesa** server-side |
| Timing | Diferencia de tiempo (`sleep`) | RCE potencial, respuesta uniforme |
| Efecto lateral | Fichero accesible vía HTTP | Conoces/adivinas la ruta |
| Error | Mensaje que cambia con el payload | El parser falla distinguible |

> [!important]+ Gotcha: el HTTP saliente se bloquea, el DNS casi nunca
> Muchos entornos cortan el HTTP de salida pero **no el DNS**. interactsh/Collaborator capturan el A-lookup aunque el HTTP falle: <mark style="background: #FF5582A6;">un hit solo-DNS ya confirma la vulnerabilidad</mark>. Y se puede exfiltrar codificando datos en el subdominio. Es el mismo oráculo OOB que en [[01 - Detección de Command Injection|command injection ciega]].

Los vectores ciegos clásicos: **SVG → SSRF/XXE** (si el server devuelve una imagen distinta a la subida, hay procesamiento), **generadores HTML→PDF** (wkhtmltopdf, Headless Chrome cargan recursos en el contexto del servidor → `<iframe src="file:///etc/passwd">` o SSRF a metadata), y el **second-order**: el upload pasa el WAF pero un *worker* asíncrono lo procesa después, sin WAF y con más privilegios (indicio: un retardo observable entre subir y ver el resultado).

# Tras WAF y validación moderna

- <mark style="background: #8000E1A6;">La recodificación en cloud (Cloudflare Images, AWS `sharp`, Azure) destruye los polyglots</mark>: solo funcionan si el server guarda y sirve el **fichero original**. El único payload que sobrevive a un *resize* GD/ImageMagick es el inyectado en el chunk **IDAT** de un PNG ([Synacktiv](https://www.synacktiv.com/en/publications/persistent-php-payloads-in-pngs-how-to-inject-php-code-in-an-image-and-keep-it-there)).
- Sube un **EICAR** para detectar si hay AV/EDR antes de quemar payloads reales.
- Evasión de WAF en el `multipart`: doble `Content-Type` en el *part*, boundary malformado, `charset` en el Content-Type (ver el [paper WAFFLED](https://arxiv.org/abs/2503.10846), que cataloga 1207 bypasses de WAF por discrepancias de parseo en `multipart`/JSON/XML).

> [!info]+ Fuentes
> - [PortSwigger — File upload](https://portswigger.net/web-security/file-upload) · [Blind SSRF](https://portswigger.net/web-security/ssrf/blind) · [XXE via file upload](https://portswigger.net/web-security/xxe/lab-xxe-via-file-upload)
> - [Detectify — Bucket upload policies & signed URLs](https://labs.detectify.com/writeups/bypassing-and-exploiting-bucket-upload-policies-and-signed-urls/)
> - [Intigriti — Exploiting PDF generators (SSRF)](https://www.intigriti.com/researchers/blog/hacking-tools/exploiting-pdf-generators-a-complete-guide-to-finding-ssrf-vulnerabilities-in-pdf-generators)
> - [Synacktiv — Persistent PHP payloads in PNGs (IDAT)](https://www.synacktiv.com/en/publications/persistent-php-payloads-in-pngs-how-to-inject-php-code-in-an-image-and-keep-it-there) · [interactsh](https://github.com/projectdiscovery/interactsh)

> [!important]+ Subida vía API — sin navegador, sin validación de cliente
> Cuando la subida va por API, los bytes suelen llegar **Base64 dentro de JSON o XML** (p. ej. una acción SOAP `uploadFile`), así que <mark style="background: #8000E1A6;">todas las validaciones de cliente (extensión, MIME del navegador) son irrelevantes</mark> — solo defienden la allowlist server-side, los *magic bytes* y la canonicalización de ruta. Un `backdoor.php` con `system($_REQUEST['cmd'])` subido a `/api/upload/` y accesible en `/uploads/backdoor.php` es RCE directo; un `../` en el nombre suministrado → escritura arbitraria. Fuente: [PortSwigger — File upload](https://portswigger.net/web-security/file-upload).

Localizada y confirmada la vulnerabilidad, la [[09 - Prevención de File Upload Attacks|prevención]] cierra el ciclo del informe; y el [[10 - Arsenal de herramientas para File Upload|arsenal]] automatiza toda esta metodología.
