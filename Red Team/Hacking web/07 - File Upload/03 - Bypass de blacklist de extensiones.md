---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Descripción: "Cuando la validación se mueve al servidor, la forma más débil es comparar la extensión contra una lista negra de tipos prohibidos"
Fecha de actualización: 2026-06-21
Nota previa: "[[02 - Bypass de validación en cliente]]"
Nota siguiente: "[[04 - Bypass de whitelist y doble extensión]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Cuando la validación se mueve al servidor, la forma más débil es comparar la extensión contra una **lista negra** de tipos prohibidos. <mark style="background: #ADCCFFA6;">Una blacklist deniega lo que enumera y permite todo lo demás</mark>, y ahí está su fallo estructural: <mark style="background: #8000E1A6;">es prácticamente imposible enumerar todas las extensiones que un servidor ejecuta como código</mark>. Basta encontrar una que el filtro olvidó y que el web server siga interpretando.

El código típico vulnerable:

```php
$fileName = basename($_FILES["uploadFile"]["name"]);
$extension = pathinfo($fileName, PATHINFO_EXTENSION);
$blacklist = array('php', 'php7', 'phps');

if (in_array($extension, $blacklist)) {
    echo "File type not allowed";
    die();
}
```

Toma la extensión y la compara contra `$blacklist`. <mark style="background: #FFB8EBA6;">No es exhaustiva</mark> —faltan decenas de extensiones que PHP ejecuta— y, además, la comparación es **case-sensitive**.

# Fuzzing de extensiones

El primer paso es descubrir qué extensiones pasan. Se fuzzea el `filename` con una lista de extensiones candidatas y se observa cuáles **no** devuelven el error.

```shell-session
$ ffuf -w extensions.lst -u https://target/upload.php -X POST \
    -H "Content-Type: multipart/form-data; boundary=x" \
    -d $'--x\r\nContent-Disposition: form-data; name="uploadFile"; filename="shell.FUZZ"\r\n...'
```

En la práctica es más cómodo con **Burp Intruder**: marcar la extensión en `filename="HTB.php"` como posición, cargar la lista y **desmarcar el URL-encoding** para no codificar el punto. Las wordlists de referencia:

- [PayloadsAllTheThings — extensions.lst (PHP)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Upload%20Insecure%20Files/Extension%20PHP/extensions.lst) y su equivalente [ASP](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Upload%20Insecure%20Files/Extension%20ASP).
- [SecLists — web-extensions.txt](https://github.com/danielmiessler/SecLists/blob/master/Discovery/Web-Content/web-extensions.txt).

Ordenando por longitud/código de respuesta, las que devuelven `File successfully uploaded` son las permitidas.

# Extensiones alternativas que ejecutan código

No todas las extensiones permitidas ejecutan código, y <mark style="background: #FFB8EBA6;">no todas funcionan en toda configuración</mark> —hay que probar varias. Las más útiles por lenguaje:

| Stack | Extensiones que suelen ejecutar |
| - | - |
| PHP | `.phtml`, `.pht`, `.php3`, `.php4`, `.php5`, `.php7`, `.phar`, `.pgif`, `.inc` |
| ASP/ASP.NET | `.asp`, `.aspx`, `.asa`, `.asax`, `.cer`, `.cdx` |
| JSP | `.jsp`, `.jspx`, `.jsw`, `.jsv`, `.jspf` |
| ColdFusion | `.cfm`, `.cfml`, `.cfc` |
| SSI (Apache `mod_include` / IIS) | `.shtml`, `.shtm`, `.stm` |

<mark style="background: #FF5582A6;">`.phtml` es el comodín de PHP</mark>: los servidores PHP suelen mapearlo a ejecución por defecto. Subimos `shell.phtml` con contenido de web shell y, si pasa el filtro, visitamos el fichero para confirmar RCE.

> [!warning]+ `.phps` no ejecuta — es source disclosure
> No lo metas en la lista de extensiones para shell: `.phps` **no** da RCE. Apache lo mapea a `application/x-httpd-php-source` y devuelve el **código fuente resaltado** del script. Es un vector de *source disclosure* (leer el código de la app), no de ejecución.

> [!tip]+ Mayúsculas en Windows
> La comparación del ejemplo solo contempla minúsculas. En **Windows Server** los nombres de fichero son case-insensitive, así que `shell.pHp` o `shell.PHP` pueden saltar la blacklist y aun así ejecutarse como PHP. Prueba siempre variaciones de caso.

# El truco que HTB no cuenta: `.htaccess` / `web.config`

Esta es la técnica que convierte un upload aparentemente inútil en RCE, y el módulo original la omite. Si la blacklist bloquea todas las extensiones PHP pero **permite subir un `.htaccess`** (o cualquier extensión que podamos controlar), podemos **redefinir qué se ejecuta como PHP**.

En **Apache** con `AllowOverride` activo, un `.htaccess` en el directorio de uploads que mapee una extensión inocua a PHP:

```apache
# Subimos esto como .htaccess
AddType application/x-httpd-php .pwn
```

O la forma más robusta vía handler:

```apache
<FilesMatch "\.(pwn|jpg)$">
    SetHandler application/x-httpd-php
</FilesMatch>
```

Después subimos `shell.pwn` (o incluso `shell.jpg` con código PHP, si usamos la segunda forma): <mark style="background: #FFB86CA6;">el servidor ahora interpreta esa extensión como PHP y obtenemos ejecución pese a la blacklist</mark>. El `.htaccess` rara vez está en las listas negras porque los desarrolladores piensan en extensiones ejecutables, no en ficheros de configuración.

El equivalente en **IIS/ASP.NET** es subir un `web.config`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
   <system.webServer>
      <handlers accessPolicy="Read, Script, Write">
         <add name="pwn" path="*.pwn" verb="*" scriptProcessor="..." resourceType="Unspecified" />
      </handlers>
   </system.webServer>
</configuration>
```

Y en servidores con **`AddHandler`** mal configurado, el clásico polyglot de extensión múltiple (`shell.php.jpg`) se trata en la [[04 - Bypass de whitelist y doble extensión|nota siguiente]].

> [!warning]+ Requisitos del truco .htaccess
> Solo funciona si: (1) el upload deja el `.htaccess` en un directorio servido por Apache, (2) `AllowOverride` permite `FileInfo`/`All` (por defecto en muchas instalaciones, desactivado en hardening serio), y (3) ese directorio ejecuta PHP. Falla en Nginx (no usa `.htaccess`) y en stacks que sirven uploads desde almacenamiento sin intérprete. Aun así, es de lo primero que se prueba cuando la extensión está bloqueada.

> [!info]+ Fuentes
> - [HackTricks — File Upload (.htaccess / web.config tricks)](https://book.hacktricks.xyz/pentesting-web/file-upload)
> - [PayloadsAllTheThings — Upload Insecure Files](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Upload%20Insecure%20Files)
> - [PortSwigger — Overriding the server configuration](https://portswigger.net/web-security/file-upload#overriding-the-server-configuration)

La alternativa a la blacklist —y aparentemente más segura— es la lista blanca. Tiene sus propias grietas: [[04 - Bypass de whitelist y doble extensión]].
