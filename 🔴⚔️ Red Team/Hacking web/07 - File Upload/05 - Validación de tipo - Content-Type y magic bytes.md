---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Fecha de actualización: 2026-06-21
Nota previa: "[[04 - Bypass de whitelist y doble extensión]]"
Nota siguiente: "[[06 - Uploads limitados - SVG, polyglots y metadatos]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Validar solo la extensión no basta —ya hemos visto que `shell.php.jpg` puede ejecutar código—, así que las apps serias **inspeccionan también el contenido** para confirmar que el fichero es del tipo declarado. Hay dos mecanismos, de robustez muy distinta: la <mark style="background: #ADCCFFA6;">cabecera `Content-Type`</mark>, que pone el cliente y por tanto controlamos, y los <mark style="background: #ADCCFFA6;">`magic bytes`</mark> (la firma real del fichero), que se imitan anteponiéndolos al payload.

# Content-Type

El navegador adjunta automáticamente un `Content-Type` a cada parte del `multipart`, derivado de la extensión. El back-end puede confiar en él:

```php
$type = $_FILES['uploadFile']['type'];

if (!in_array($type, array('image/jpg', 'image/jpeg', 'image/png', 'image/gif'))) {
    echo "Only images are allowed";
    die();
}
```

Como lo fija el cliente, <mark style="background: #FF5582A6;">es una validación client-side disfrazada de server-side</mark>: lo cambiamos en el proxy. Para descubrir qué tipos se aceptan, fuzzeamos la cabecera con la [wordlist de Content-Types de SecLists](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/web-all-content-types.txt), reducida a imágenes para ir más rápido:

```shell-session
$ wget https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/Web-Content/web-all-content-types.txt
$ grep 'image/' web-all-content-types.txt > image-content-types.txt
```

Después basta con interceptar la subida del web shell y cambiar su `Content-Type` a, por ejemplo, `image/jpeg` (el tipo MIME canónico según IANA; `image/jpg` es un alias informal, conviene probar ambos).

> [!note]+ Hay dos cabeceras Content-Type
> Una petición de upload lleva el `Content-Type` **del fichero** (en su parte del `multipart`, abajo) y el `Content-Type` **de la petición** completa (arriba, normalmente `multipart/form-data`). Casi siempre hay que tocar el del fichero; pero si el contenido se envía como `POST` plano, solo existe el principal y es ese el que se modifica.

# MIME / magic bytes

La validación más común y más fiable inspecciona el **MIME real** del fichero a partir de su [firma o magic bytes](https://en.wikipedia.org/wiki/List_of_file_signatures): los primeros bytes que identifican el formato, independientemente de la extensión.

| Tipo | Firma (hex) | ASCII |
| - | - | - |
| GIF | `47 49 46 38 39 61` | `GIF89a` |
| JPEG | `FF D8 FF` | (no imprimible) |
| PNG | `89 50 4E 47` | `.PNG` |
| PDF | `25 50 44 46` | `%PDF` |

<mark style="background: #FFB8EBA6;">La firma de GIF (`GIF89a`, o la antigua `GIF87a`) es la más fácil de falsificar porque es ASCII imprimible</mark> —el resto empiezan por bytes no imprimibles—. A `libmagic` (lo que usan `file`, `finfo` y `mime_content_type()`) le basta incluso con el prefijo de 4 bytes `GIF8` para clasificar el fichero como GIF. Demostración con el comando `file`:

```shell-session
$ echo "this is a text file" > text.jpg && file text.jpg
text.jpg: ASCII text
$ echo "GIF89a" > text.jpg && file text.jpg
text.jpg: GIF image data
```

Anteponer la firma cambió el MIME percibido a imagen GIF, pese a que el contenido y la extensión no lo son. En PHP la comprobación se hace con `mime_content_type()`:

```php
$type = mime_content_type($_FILES['uploadFile']['tmp_name']);
if (!in_array($type, array('image/jpg','image/jpeg','image/png','image/gif'))) {
    echo "Only images are allowed"; die();
}
```

El bypass: <mark style="background: #8000E1A6;">anteponer `GIF89a` al web shell y mantener la extensión `.php`</mark>. El fichero pasa como imagen GIF para `mime_content_type()` y, al servirse con extensión `.php`, ejecuta el código:

```php
GIF89a
<?php system($_REQUEST['cmd']); ?>
```

Combinado con el spoofing del `Content-Type`, supera filtros que validan ambas cosas a la vez.

# Cuando los magic bytes no bastan

Aquí está el matiz que separa el lab del objetivo real, y que conviene tener claro:

- **`mime_content_type()` / `finfo`** miran solo los primeros bytes → el prefijo `GIF89a` (o el mínimo `GIF8`) los engaña.
- **`getimagesize()`** intenta **parsear la estructura** de la imagen (dimensiones, cabeceras del formato). <mark style="background: #FFB86CA6;">Un `GIF89a` seguido de código PHP falla aquí</mark>, porque el resto no es un GIF válido. Para superarlo necesitas un fichero que sea **imagen válida de verdad** y contenga código.
- **Re-procesado** (la app redimensiona o re-codifica la imagen con Pillow/ImageMagick): destruye cualquier payload que no sobreviva a la transformación. Es la defensa más dura.

La respuesta a las dos últimas es el **polyglot**: una imagen real con el payload incrustado donde sobrevive (típicamente en metadatos EXIF o en un *chunk* que el re-encode preserva). Eso, junto con SVG y el resto de vectores de los uploads "limitados", se trata en la [[06 - Uploads limitados - SVG, polyglots y metadatos|nota siguiente]].

> [!info]+ Fuentes
> - [PortSwigger — Flawed validation of the file's contents](https://portswigger.net/web-security/file-upload#flawed-validation-of-the-file-s-contents)
> - [Wikipedia — List of file signatures](https://en.wikipedia.org/wiki/List_of_file_signatures)
> - [HackTricks — File Upload (magic bytes)](https://book.hacktricks.xyz/pentesting-web/file-upload)

Aunque no logremos un upload arbitrario, un tipo permitido puede seguir siendo un arma: [[06 - Uploads limitados - SVG, polyglots y metadatos]].
