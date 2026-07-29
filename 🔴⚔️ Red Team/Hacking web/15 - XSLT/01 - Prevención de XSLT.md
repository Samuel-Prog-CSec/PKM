---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - Server-Side/XSLT
  - Tipo/Defensa
Descripción: "Como toda inyección de este módulo, la XSLT Injection se previene impidiendo que el input del usuario se inserte en los datos XSL antes de que el procesador los transforme — más…"
Fecha de actualización: 2026-06-22
Nota previa: "[[00 - Inyección XSLT]]"
Nota siguiente: ""
Area: "[[XSLT.base|XSLT]]"
---
---

Como toda inyección de este módulo, la XSLT Injection se previene impidiendo que el input del usuario **se inserte en los datos XSL antes** de que el procesador los transforme — más unas medidas de *hardening* del propio procesador.

# Validar y codificar el input

Lo ideal es que el input del usuario **no llegue** a la hoja XSL antes del procesado. Cuando la salida debe reflejar datos del usuario y no queda más remedio que insertarlos, hay que **sanear y validar**. La defensa concreta depende del formato de salida: <mark style="background: #ADCCFFA6;">si el procesador genera HTML, HTML-encodear el input antes de insertarlo</mark> —convertir `<` en `&lt;` y `>` en `&gt;`— impide que se formen elementos `<xsl:...>`, cerrando la inyección. Es el mismo principio que en [[01 - Prevención de SSI|SSI]] y [[00 - Introducción a XSS|XSS]]: si el atacante no puede introducir la sintaxis del lenguaje, no inyecta.

# Hardening del procesador

Medidas que contienen el impacto si la inyección se cuela:

- <mark style="background: #FFB86CA6;">**Deshabilitar las funciones externas / PHP**</mark> en el procesador XSLT: sin `php:function`, desaparece el salto a LFI y RCE —la inyección queda, como mucho, en fuga de información—. Es la medida de mayor impacto.
- **Least privilege**: ejecutar el procesador XSLT como un proceso de bajo privilegio, para limitar qué puede leer o ejecutar un payload que sí funcione.
- **Mantener la librería actualizada** (`libxslt`, Saxon…): cierra vulnerabilidades conocidas del propio procesador.

> [!important]+ El control que de verdad corta el RCE
> En stacks PHP, el `php:function` es lo que convierte una inyección XSLT en RCE. **Deshabilitarlo** (no registrar el namespace de funciones PHP) y restringir el procesador con `XSL_SECPREF` —`XSL_SECPREF_READ_FILE` bloquea `document('file://…')`, `XSL_SECPREF_WRITE_FILE` la escritura— reduce drásticamente el impacto aunque exista la inyección. Combínalo con el HTML-encoding del input para cerrar el vector de raíz.

> [!info]+ Fuentes
> - [HackTricks — XSLT Server Side Injection](https://book.hacktricks.xyz/pentesting-web/xslt-server-side-injection-extensible-stylesheet-language-transformations) · [OWASP WSTG — Testing for XSLT Injection](https://owasp.org/www-project-web-security-testing-guide/)
> - [libxslt — security preferences (`XSL_SECPREF`)](https://gitlab.gnome.org/GNOME/libxslt)

Con esto se cierra el sub-tema **XSLT** y la rama de los cuatro ataques server-side. La MOC lo agrupa: [[XSLT.base|XSLT]].
