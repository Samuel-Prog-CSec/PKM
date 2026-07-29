---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Descripción: "Una lista blanca invierte la lógica de la blacklist: solo permite las extensiones que enumera y deniega todo lo demás"
Fecha de actualización: 2026-06-21
Nota previa: "[[03 - Bypass de blacklist de extensiones]]"
Nota siguiente: "[[05 - Validación de tipo - Content-Type y magic bytes]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Una **lista blanca** invierte la lógica de la [[03 - Bypass de blacklist de extensiones|blacklist]]: <mark style="background: #ADCCFFA6;">solo permite las extensiones que enumera y deniega todo lo demás</mark>. Es más robusta —no necesita prever cada extensión peligrosa— pero su implementación suele tener un fallo recurrente: <mark style="background: #FF5582A6;">el regex comprueba que el nombre *contiene* una extensión válida, no que *termina* en ella</mark>. Esa diferencia de un carácter es la que explotamos.

# El fallo del regex

Whitelist típica mal escrita:

```php
$fileName = basename($_FILES["uploadFile"]["name"]);

if (!preg_match('^.*\.(jpg|jpeg|png|gif)', $fileName)) {
    echo "Only images are allowed";
    die();
}
```

El patrón `^.*\.(jpg|jpeg|png|gif)` no lleva ancla de fin (`$`), así que valida cualquier nombre que **contenga** `.jpg` en algún punto. <mark style="background: #8000E1A6;">Un fichero llamado `shell.jpg.php` contiene `.jpg` (pasa el filtro) y termina en `.php` (ejecuta).</mark>

## Doble extensión

El bypass directo: anteponer la extensión permitida y dejar la peligrosa al final.

```
shell.jpg.php
```

Interceptamos una subida normal, cambiamos el `filename` a `shell.jpg.php` y el contenido al web shell. Pasa la whitelist y, al visitarlo, ejecuta PHP.

## Cuando el regex es estricto

Un patrón bien escrito ancla el final:

```php
if (!preg_match('/^.*\.(jpg|jpeg|png|gif)$/', $fileName)) { ... }
```

El `$` obliga a que la **última** extensión sea de imagen, así que `shell.jpg.php` ya no pasa. Contra esto, la doble extensión simple falla y hay que recurrir a la configuración del servidor o a la inyección de caracteres.

# Reverse double extension

A veces el formulario es seguro pero **el web server no**. Configuraciones de Apache como esta determinan qué se ejecuta como PHP:

```apache
<FilesMatch ".+\.ph(ar|p|tml)">
    SetHandler application/x-httpd-php
</FilesMatch>
```

Ese patrón tampoco ancla el final (`$`), así que <mark style="background: #FFB86CA6;">cualquier fichero que *contenga* `.php` en el nombre se ejecuta, aunque no termine en él</mark>. Un nombre como:

```
shell.php.jpg
```

pasa una whitelist estricta del formulario (termina en `.jpg`) **y** ejecuta PHP por la `FilesMatch` mal anclada del servidor. Es el escenario común al auditar una app open-source instalada sobre un Apache con configuración por defecto: la subida es segura, la configuración no.

# Inyección de caracteres

Cuando ni la doble extensión ni la configuración ayudan, se intentan caracteres especiales que provoquen que el back-end **reinterprete** el nombre y lo guarde con la extensión peligrosa. Caracteres a inyectar antes o después de la extensión:

```
%20   %0a   %00   %0d0a   /   .\   .   …   :
```

Cada uno tiene su caso de uso por discrepancia de parsing entre capas:

- **`%00` (null byte)**: `shell.php%00.jpg`. El procesado en C corta la cadena en el nulo, guardando `shell.php`, mientras la validación de alto nivel ve `.jpg`. <mark style="background: #FFB8EBA6;">Funciona en PHP ≤ 5.3.4 y, hoy, en cualquier capa con bindings nativos a C/C++ que no maneje el nulo</mark> (sigue vivo en apps legacy, parsers en C, algún wrapper de imagen).
- **`::$DATA` (Windows ADS)**: `shell.aspx::$DATA` referencia el *stream* de datos por defecto de NTFS, así que el fichero se guarda como `shell.aspx` con el contenido, saltándose validaciones que comparan el final del nombre. (La variante `shell.aspx:.jpg` crea `shell.aspx` **vacío** y manda el contenido a un stream alternativo `.jpg` —menos útil—.)
- **`%20`, `%0a`, `.`, `…`**: provocan truncados o normalizaciones distintas según el sistema de ficheros.

Para barrer todas las combinaciones, generamos una wordlist de permutaciones:

```bash
for char in '%20' '%0a' '%00' '%0d0a' '/' '.\\' '.' '…' ':'; do
    for ext in '.php' '.phps' '.phtml'; do
        echo "shell$char$ext.jpg" >> wordlist.txt
        echo "shell$ext$char.jpg" >> wordlist.txt
        echo "shell.jpg$char$ext" >> wordlist.txt
        echo "shell.jpg$ext$char" >> wordlist.txt
    done
done
```

Y la lanzamos con Burp Intruder sobre el `filename`. Si el back-end o el web server están desactualizados o mal configurados, alguna permutación se cuela.

> [!warning]+ El null byte ya no es la bala de plata
> En PHP moderno (≥ 5.3.4) el truco `%00` está parcheado. No lo descartes —muchos objetivos reales corren código antiguo o cadenas de procesamiento en C— pero **no asumas que funcionará**. En stacks actualizados, el camino realista es la [[05 - Validación de tipo - Content-Type y magic bytes|validación de contenido]] y los [[06 - Uploads limitados - SVG, polyglots y metadatos|polyglots]].

> [!info]+ Fuentes
> - [PortSwigger — File upload (obfuscating file extensions)](https://portswigger.net/web-security/file-upload)
> - [HackTricks — File Upload (extension tricks)](https://book.hacktricks.xyz/pentesting-web/file-upload)
> - [PayloadsAllTheThings — Upload Insecure Files](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Upload%20Insecure%20Files)

Cuando la app deja de fiarse de la extensión y empieza a inspeccionar el contenido del fichero, cambian las reglas: [[05 - Validación de tipo - Content-Type y magic bytes]].
