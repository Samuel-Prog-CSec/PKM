---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[08 - Detección y metodología en entornos reales]]"
Nota siguiente: "[[10 - Arsenal de herramientas para File Upload]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Un pentest no termina con la PoC: el valor para el cliente está en los *action points*. Esta nota es la **contramedida de cada técnica** vista en el sub-tema, ordenada como checklist para el informe. La idea rectora: <mark style="background: #ADCCFFA6;">la subida segura apila defensas (defensa en profundidad), porque cualquier capa aislada se puede saltar</mark>.

# Validación de extensión

Whitelist **y** blacklist en tándem: la whitelist define lo permitido; la blacklist atrapa lo peligroso si la whitelist se elude (`shell.php.jpg`). La clave está en el regex —anclado al final con `$`—:

```php
// blacklist: ¿contiene una extensión peligrosa en CUALQUIER posición? (case-insensitive)
if (preg_match('/\.(php[0-9]?|pht|phtml|phar|phps|shtml)/i', $fileName)) { die("No permitido"); }
// whitelist: ¿TERMINA en una extensión de imagen?
if (!preg_match('/^.*\.(jpg|jpeg|png|gif)$/', $fileName)) { die("Solo imágenes"); }
```

Validar en el back-end siempre; la validación en cliente solo reduce ruido. <mark style="background: #FFB8EBA6;">La diferencia que rompe los bypasses: la blacklist comprueba si la extensión aparece *en cualquier parte*; la whitelist, si el nombre *termina* en ella.</mark> Ambas comparaciones deben ser **case-insensitive** (flag `/i`): sin él, `shell.PhP` salta la blacklist y aun así ejecuta en Windows. La blacklist además debe cubrir `.pht`, `.php3`–`.php7`, `.phar`, `.shtml`, no solo `.php`.

# Validación de contenido

La extensión no basta: hay que validar también el contenido y que **coincida** con el tipo declarado —firma (magic bytes) y `Content-Type`—:

```php
$fileName = basename($_FILES["uploadFile"]["name"]);
$contentType = $_FILES['uploadFile']['type'];
$MIMEtype = mime_content_type($_FILES['uploadFile']['tmp_name']);

if (!preg_match('/^.*\.png$/', $fileName)) { die("Solo PNG"); }
foreach (array($contentType, $MIMEtype) as $type) {
    if (!in_array($type, array('image/png'))) { die("Solo PNG"); }
}
```

> [!success]+ La defensa que de verdad mata los polyglots
> <mark style="background: #FF5582A6;">Re-procesar la imagen en el servidor (re-encode / resize) destruye cualquier payload incrustado</mark> —EXIF, polyglots GIF/PHP, JPEG con código— porque genera un fichero nuevo desde los píxeles. Es más efectivo que validar magic bytes. Con SVG, sanitizar con un **DOMPurify** en perfil SVG o, mejor, **convertir el SVG a PNG**. El patrón industrial es **CDR** (*Content Disarm & Reconstruction*): reconstruir el fichero a partir de su contenido seguro.

# No exponer el directorio de uploads

Varias medidas combinadas reducen drásticamente el impacto aunque se cuele un fichero:

- **Servir vía script controlado** (`download.php`) en vez de acceso directo, con autorización estricta (evita [[06 - Introducción a IDOR|IDOR]]) y validación de ruta (evita [[00 - Introducción a File Inclusion|LFI]]).
- **Devolver `403`** a cualquier petición directa al directorio.
- **Cabeceras de seguridad** al servir: `Content-Disposition: attachment`, `Content-Type` correcto y, crítico, `X-Content-Type-Options: nosniff` (frena el *MIME sniffing* del navegador).
- **Randomizar el nombre** almacenado (UUID) y guardar el nombre original saneado en BD. <mark style="background: #8000E1A6;">Si el atacante no conoce la ruta ni el nombre, no puede invocar su fichero</mark> —y de paso anula la inyección en el nombre.
- **Almacenar fuera de la raíz web**, o en un servidor/contenedor/bucket separado: un RCE compromete solo el almacenamiento, no la app. En PHP, `open_basedir` restringe el acceso.

> [!important]+ Dominio sandbox: la defensa moderna contra el XSS por upload
> Servir el contenido subido desde un **dominio aislado y sin cookies** (p. ej. `usercontent.example.net`, el patrón de GitHub/Google) hace que un SVG o HTML con XSS ejecute en un origen sin valor, no en el de la aplicación. Combínalo con una `Content-Security-Policy` restrictiva. Es lo que neutraliza los vectores de [[06 - Uploads limitados - SVG, polyglots y metadatos|uploads limitados]].

# Endurecimiento adicional

Medidas que contienen el daño si todo lo anterior falla:

| Medida | Qué frena |
| - | - |
| `disable_functions` y `disable_classes` en `php.ini` | Ejecución de comandos desde un web shell (`disable_classes` corta el escape vía `FFI`/`ReflectionFunction`) |
| Límite de tamaño de fichero | DoS por disco / *pixel flood* |
| Actualizar librerías (ImageMagick, Ghostscript, Pillow, ffmpeg) | [[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions|exploits de procesamiento]] |
| Validar rutas de entrada al descomprimir | [[07 - Vectores avanzados - procesamiento, ZIP Slip y race conditions|ZIP Slip]] |
| Antivirus / YARA (ClamAV) sobre lo subido | Web shells y malware conocidos |
| WAF como capa secundaria | Payloads conocidos (no es la defensa primaria) |
| Ocultar errores del servidor | Divulgación del directorio de uploads |

<mark style="background: #FFB86CA6;">Ninguna medida es suficiente por sí sola</mark>; la seguridad emerge de la suma. Al reportar, este listado sirve de checklist: marcar lo que falta y entregarlo al equipo de desarrollo como recomendaciones priorizadas.

> [!info]+ Fuentes
> - [OWASP — File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)
> - [PortSwigger — Preventing file upload vulnerabilities](https://portswigger.net/web-security/file-upload#how-to-prevent-file-upload-vulnerabilities)
> - [OWASP WSTG — Unrestricted File Upload](https://owasp.org/www-community/vulnerabilities/Unrestricted_File_Upload)

Para cerrar el sub-tema, el conjunto de herramientas que automatiza y acelera todo lo anterior en un engagement real: [[10 - Arsenal de herramientas para File Upload]].
