---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - File-Inclusion
Fecha de actualización: 2026-06-21
Nota previa: "[[02 - Bypasses básicos - traversal, null byte y encoding]]"
Nota siguiente: "[[04 - PHP wrappers II - RCE y filter chains]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

En aplicaciones PHP, una LFI se potencia muchísimo con los [PHP wrappers](https://www.php.net/manual/en/wrappers.php.php): esquemas como `php://` que dan acceso a streams de I/O. <mark style="background: #ADCCFFA6;">El wrapper `php://filter` aplica filtros a un recurso mientras se lee</mark>, y eso resuelve un problema central: cuando incluimos un `.php`, el `include()` lo **ejecuta** en vez de mostrar su código. Con el filtro adecuado, recuperamos el código fuente en lugar de su salida.

# El problema: incluir PHP lo ejecuta

Si incluimos `config.php` directamente, no vemos nada útil: el fichero se ejecuta (define configuración, no imprime HTML) y la respuesta sale vacía. <mark style="background: #FFB8EBA6;">Necesitamos leer el **código**, no ejecutarlo</mark> —el código suele contener credenciales, claves de base de datos y referencias a otros ficheros—.

# La solución: `convert.base64-encode`

`php://filter` admite dos parámetros clave: `resource` (el fichero objetivo) y `read` (el filtro a aplicar). El filtro útil para LFI es `convert.base64-encode`: codifica el contenido en Base64 **antes** de que PHP lo interprete, así que recibimos el fuente codificado en vez de su ejecución.

```
php://filter/read=convert.base64-encode/resource=config
```

<mark style="background: #FF5582A6;">Al devolver Base64, el código nunca se ejecuta</mark>; lo decodificamos en local:

```shell-session
$ curl -s "http://target/index.php?language=php://filter/read=convert.base64-encode/resource=config"
$ echo 'PD9waHAK...KICB9Ciov' | base64 -d
```

> [!tip]+ Detalles que importan
> - <mark style="background: #8000E1A6;">Funciona incluso con la extensión `.php` añadida</mark>: si el código hace `include($_GET['language'].".php")`, ponemos `resource=config` (sin `.php`) y la extensión se añade sola → `config.php`. Por eso este wrapper es la respuesta real a la [[02 - Bypasses básicos - traversal, null byte y encoding|extensión añadida]].
> - Copia la cadena Base64 **entera** (mira el código fuente de la página); si la truncas, no decodifica.
> - Hay otros tipos de filtro (string, conversion, compression, encryption), pero `convert.base64-encode` es el que sirve aquí.

# Mapear el código fuente

Leer un fichero es el principio; el valor está en **reconstruir la app**. Primero, fuzzear qué páginas PHP existen (con LFI no nos limita el código de respuesta: leemos `200`, `301`, `302`, `403`…):

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt:FUZZ \
    -u http://target/FUZZ.php
```

Después, leer cada fichero con el filtro base64, y <mark style="background: #FFB86CA6;">buscar en su fuente referencias a otros ficheros</mark> (`include`, `require`, rutas) para encadenar la lectura hasta cubrir casi toda la aplicación. Empezar por `index.php` y seguir las referencias también funciona, pero el fuzzing descubre ficheros que el código no enlaza directamente.

El botín típico de esta fase: credenciales de base de datos en `config.php`/`.env`, claves de API, lógica de autenticación que revela otros fallos, y rutas que alimentan los siguientes ataques (dónde están los uploads, qué wrappers están activos).

> [!info]+ Más allá de LFI
> `php://filter` y los wrappers también son munición en **XXE** (el [[Web Attacks|módulo Web Attacks]] los usa para leer ficheros vía entidades externas) y aparecen en el [[06 - Uploads limitados - SVG, polyglots y metadatos|XXE por SVG]] de file upload. Dominarlos aquí se reaprovecha en todo el pentesting web.

> [!info]+ Fuentes
> - [PHP — php://filter](https://www.php.net/manual/en/wrappers.php.php) · [Conversion filters](https://www.php.net/manual/en/filters.convert.php)
> - [HackTricks — LFI2RCE via PHP filters](https://book.hacktricks.xyz/pentesting-web/file-inclusion)
> - [PayloadsAllTheThings — File Inclusion (wrappers)](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion)

Leer el código es solo el primer uso de los wrappers. Los siguientes los convierten en **ejecución de comandos** —incluida la técnica moderna que transforma una LFI de solo lectura en RCE—: [[04 - PHP wrappers II - RCE y filter chains]].
