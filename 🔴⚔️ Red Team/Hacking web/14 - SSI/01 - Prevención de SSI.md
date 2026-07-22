---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - Server-Side/SSI
Fecha de actualización: 2026-06-22
Nota previa: "[[00 - Inyección SSI (Server-Side Includes)]]"
Nota siguiente: ""
Area: "[[SSI.base|SSI]]"
---
---

La SSI Injection se previene como cualquier inyección —**no dejar que el input del usuario forme directivas**— más una capa de configuración del servidor que acota dónde y qué se ejecuta.

# Validar y codificar el input

Lo esencial: <mark style="background: #ADCCFFA6;">validar y sanear el input del usuario</mark>, sobre todo cuando se usa dentro de directivas SSI o **se escribe en ficheros que el servidor procesa como SSI**. La defensa concreta más efectiva es **HTML-encodear** el input antes de insertarlo: convertir `<` en `&lt;` y `>` en `&gt;` impide que se forme la sintaxis `<!--#...-->`, neutralizando la inyección. Es el mismo principio que frena el [[00 - Introducción a XSS|XSS]], aplicado aquí a la sintaxis de directivas.

# Acotar SSI en la configuración del servidor

Defensa en profundidad a nivel de servidor:

- **Restringir SSI a extensiones y directorios concretos**: que solo se procesen directivas en los ficheros que realmente lo necesitan (`.shtml` en una carpeta específica), nunca en ficheros donde aterriza contenido del usuario.
- <mark style="background: #FFB86CA6;">**Deshabilitar la directiva `exec`** si no se usa</mark> (en Apache, `Options +IncludesNOEXEC`): elimina el salto a RCE aunque haya inyección, dejándola en, como mucho, fuga de variables o lectura de ficheros del webroot.
- **Least privilege**: el proceso del servidor con permisos mínimos, para contener el impacto de un `exec` que sí se cuele.

> [!important]+ El punto crítico
> El error que habilita la SSI Injection es casi siempre **escribir input de usuario en un fichero SSI-enabled** (directamente o vía [[00 - Introducción a los File Upload Attacks|upload]]). Si el contenido del usuario nunca toca un fichero procesado como SSI —o va HTML-encodeado—, no hay inyección. Combinar `IncludesNOEXEC` con esa regla cierra el vector.

> [!info]+ Fuentes
> - [OWASP — SSI Injection](https://owasp.org/www-community/attacks/Server-Side_Includes_(SSI)_Injection) · [Apache — `Options IncludesNOEXEC`](https://httpd.apache.org/docs/current/mod/core.html#options)

Con esto se cierra el sub-tema **SSI**. La MOC lo agrupa: [[SSI.base|SSI]]. El último sub-tema server-side es la inyección en transformaciones XML: [[00 - Inyección XSLT|XSLT]].
