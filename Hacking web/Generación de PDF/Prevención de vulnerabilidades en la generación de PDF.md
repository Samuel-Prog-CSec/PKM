---
tags:
  - Web/Red-Team
  - Pentesting/Vulnerabilidad
  - Seguridad/Prevencion-Vulnerabilidad
Fecha de actualización: 2025-10-27
Nota previa: "[[Explotación de vulnerabilidades de generación de PDF]]"
Nota siguiente:
Area: "[[Vulnerabilidades de generación de PDF]]"
---
---

# Configuraciones inseguras
Muchas de las vulnerabilidades que analizamos en las secciones anteriores son resultado de la configuración incorrecta de las bibliotecas de generación de PDF. Hay muchos casos en los que la configuración predeterminada de estas bibliotecas es insegura. Si bien muchos de ellos han sido descubiertos y corregidos, no debemos confiar en la seguridad de la configuración predeterminada. Por lo tanto, leer la documentación, recorrer el archivo de configuración y configurar la biblioteca de generación de PDF según nuestras necesidades son esenciales. Por ejemplo, muchas bibliotecas de generación de PDF establecen de forma predeterminada la configuración para permitir el acceso a recursos externos. Configurar esta opción para `false` previene eficazmente las vulnerabilidades SSRF. En el `DomPDf` biblioteca, esta opción se llama `enable_remote`.

En algunas bibliotecas, existen otras opciones de configuración que permiten la ejecución de código JavaScript e incluso PHP en el servidor. Si bien el uso de funciones como estas puede ser útil para la generación dinámica de archivos PDF, también son extremadamente peligrosas, ya que la inyección de código PHP puede provocar la ejecución remota de código (RCE). Por ejemplo, el `DomPDF` La biblioteca tiene una opción de configuración llamada `isPhpEnabled` que permite la ejecución de código PHP; esta opción debe estar deshabilitada porque supone un riesgo para la seguridad.

Generalmente, la mayoría de las bibliotecas ofrecen las mejores prácticas de seguridad que debemos seguir al utilizarlas. Por ejemplo, [aquí](https://github.com/dompdf/dompdf/wiki/Securing-dompdf) son las mejores prácticas de seguridad para DomPDF.

---

# Prevención
Todas las vulnerabilidades analizadas anteriormente son resultado del uso de etiquetas HTML proporcionadas por el usuario como entrada a la biblioteca de generación de PDF. Una aplicación web puede prevenir estas vulnerabilidades al no permitir etiquetas HTML en la entrada del usuario. Esto se puede lograr codificando la entrada del usuario mediante una entidad HTML, por ejemplo, utilizando el [htmlentities](https://www.php.net/manual/en/function.htmlentities.php) función en PHP. `htmlentities` convertirá todos los caracteres aplicables a [Entidades HTML](https://www.freeformatter.com/html-entities.html), como en `<` becoming `&lt;` y `>` becoming `&gt;`, lo que hace imposible inyectar etiquetas HTML, evitando así problemas de seguridad.

Sin embargo, en muchos casos, esta mitigación puede ser demasiado restrictiva, ya que puede ser deseable que el usuario pueda inyectar ciertos elementos de estilo, como texto en negrita o cursiva, o recursos, como imágenes. En ese caso, el usuario debe poder insertar etiquetas HTML en la entrada de generación de PDF. Podemos mitigar las vulnerabilidades que discutimos configurando adecuadamente las opciones de la biblioteca de generación de PDF teniendo en cuenta todos los problemas de seguridad. Como mínimo, debemos asegurarnos de que las siguientes configuraciones estén configuradas correctamente:
- El código JavaScript no debe ejecutarse bajo ninguna circunstancia
- No se debe permitir el acceso a archivos locales
- El acceso a recursos externos debe prohibirse o limitarse si es necesario

En muchos casos, el código HTML depende de recursos externos como imágenes y hojas de estilo. Si son parte de la plantilla, la aplicación web debe recuperar estos recursos con anticipación y almacenarlos localmente. Luego podemos editar los elementos HTML para hacer referencia a la copia local de estos recursos de modo que no se carguen recursos externos. Esto nos permite establecer reglas estrictas de firewall que impiden todas las solicitudes salientes del servidor web que ejecuta la aplicación web. Esto evitará por completo las vulnerabilidades SSRF. Sin embargo, si los usuarios necesitan poder cargar recursos externos, se recomienda implementar un enfoque de lista blanca de puntos finales externos desde los cuales se pueden cargar recursos. Esto evita la explotación de vulnerabilidades SSRF al bloquear el acceso a la red interna.