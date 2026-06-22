---
tags:
Fecha de actualización: 2025-11-08
Nota previa:
Nota siguiente:
Area: "[[Proxies web]]"
---
---

[Proxy de ataque OWASP Zed (ZAP)](https://www.zaproxy.org/) es otra herramienta proxy web común para pruebas de penetración web.  es un proyecto gratuito y de código abierto iniciado por el [Proyecto de seguridad de aplicaciones web abiertas (OWASP)](https://owasp.org/) y mantenido por la comunidad, por lo que no tiene funciones de pago únicamente como Burp. Ha crecido significativamente en los últimos años y está ganando rápidamente reconocimiento en el mercado como la herramienta proxy web líder de código abierto.

Al igual que Burp, ZAP proporciona varias funciones básicas y avanzadas que se pueden utilizar para realizar pruebas de penetración web. ZAP también tiene ciertas fortalezas sobre Burp, que cubriremos a lo largo de este módulo. La principal ventaja de ZAP sobre Burp es ser un proyecto gratuito y de código abierto, lo que significa que no enfrentaremos ninguna limitación o limitación en nuestros escaneos que solo se elimine con una suscripción paga. Además, con una creciente comunidad de contribuyentes, ZAP está obteniendo muchas de las funciones de Burp de pago de forma gratuita.

Al final, aprender ambas herramientas puede ser bastante similar y nos brindará opciones para cada situación a través de un pentest web, pudiendo optar por utilizar la que encontremos más adecuada a nuestras necesidades. En algunos casos, es posible que no veamos suficiente valor para justificar una suscripción paga a Burp y que cambiemos a ZAP para tener una experiencia completamente abierta y gratuita. En otras situaciones en las que queremos una solución más madura para pentests avanzados o pentesting corporativos, podemos encontrar que el valor proporcionado por Burp Pro está justificado y podemos cambiar a Burp para estas funciones.

---

Podemos descargar ZAP desde su [descargar página](https://www.zaproxy.org/download/), elija el instalador que se adapte a nuestro sistema operativo y siga las instrucciones básicas de instalación para instalarlo. ZAP también se puede descargar como un archivo JAR multiplataforma y ejecutarse con el `java -jar` comando o haciendo doble clic en él, de forma similar a Burp.

Para comenzar con ZAP, podemos iniciarlo desde la terminal con el `zaproxy` comando o acceda a él desde el menú de la aplicación como Burp. Una vez que ZAP se inicie, a diferencia de la versión gratuita de Burp, se nos pedirá que creemos un nuevo proyecto o un proyecto temporal. Utilicemos un proyecto temporal eligiendo `no`, ya que no trabajaremos en un gran proyecto que tendremos que persistir durante varios días:

![Opciones de persistencia de la sesión ZAP. Opciones: persistir con marca de tiempo, especificar nombre y ubicación o no persistir. Casilla de verificación para recordar la elección. Botones para "Ayuda" e "Inicio"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_new_project.jpg)

Después de eso, tendremos ZAP ejecutándose y podremos continuar con el proceso de configuración del proxy, como analizaremos en la siguiente sección.

Consejo: Si prefieres utilizar un tema oscuro, puedes hacerlo en Burp yendo a (`Burp>Settings>User interface>Display`) y seleccionando "oscuro" en (`theme`), y en ZAP yendo a (`Tools>Options>Display`) y seleccionando "Flat Dark" en (`Look and Feel`).

---

## ZAP
En ZAP, la interceptación está desactivada de forma predeterminada, como lo muestra el botón verde en la barra superior (el verde indica que las solicitudes pueden pasar y no ser interceptadas). Podemos hacer clic en este botón para activar o desactivar la Intercepción de solicitud, o podemos usar el acceso directo [`CTRL+B`] para activarlo o desactivarlo:
![Barra de herramientas con varios íconos y menú desplegable 'Modo estándar', sección 'Sitios' con un ícono más.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_intercept_htb_on.jpg)

Luego, podemos iniciar el navegador preconfigurado y volver a visitar la página web del ejercicio. Veremos la solicitud interceptada en el panel superior derecho y podremos hacer clic en el paso (a la derecha del rojo `break` botón) para reenviar la solicitud:
![Detalles de la solicitud HTTP con botones 'Solicitar' y 'Romper', métodos, encabezado y menús desplegables del cuerpo.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_intercept_page.png)

ZAP también tiene una poderosa característica llamada `Heads Up Display (HUD)`, lo que nos permite controlar la mayoría de las funciones principales de ZAP desde dentro del navegador preconfigurado. Podemos habilitar el `HUD` haciendo clic en su botón al final de la barra de menú superior:
![Barra de herramientas con íconos, menú desplegable 'Modo estándar' y sección 'Sitios' con un ícono más.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_enable_HUD.jpg)

El HUD tiene muchas características que cubriremos a medida que avancemos en el módulo. Para interceptar solicitudes, podemos hacer clic en el segundo botón desde arriba en el panel izquierdo para activar la interceptación de solicitudes:
![Interfaz de ping con entrada IP '127.0.0.0', botón de ping y controles laterales para sitios, indicadores de inicio y estado.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_hud_break.jpg)

Nota: En algunas versiones de navegadores, es posible que el HUD del ZAP no funcione según lo previsto.

Ahora, una vez que actualicemos la página o enviemos otra solicitud, el HUD interceptará la solicitud y nos la presentará para que tomemos medidas:
![Cuadro de diálogo de mensaje HTTP que muestra los detalles de la solicitud con botones: Paso, Continuar, Soltar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_hud_break_request.png)

Podemos elegir `step` para enviar la solicitud y examinar su respuesta y cancelar cualquier solicitud adicional, o podemos optar por `continue` y deje que la página envíe las solicitudes restantes. El `step` El botón es útil cuando queremos examinar cada paso de la funcionalidad de la página, mientras `continue` es útil cuando solo estamos interesados en una única solicitud y podemos reenviar las solicitudes restantes una vez que alcanzamos nuestra solicitud objetivo.

**Consejo:** La primera vez que utilice el navegador ZAP preconfigurado, se le presentará el tutorial de HUD. Puede considerar tomar este tutorial después de esta sección, ya que le enseñará los conceptos básicos del HUD. Incluso si no lo entiendes todo, las próximas secciones deberían cubrir todo lo que te perdiste. Si no obtiene el tutorial, puede hacer clic en el botón de configuración en la parte inferior derecha y elegir "Tomar el tutorial de HUD".

---

# REPUESTAS ZAP
Intentemos ver cómo podemos hacer lo mismo con ZAP. Como vimos en el apartado anterior, cuando nuestras solicitudes son interceptadas por ZAP, podemos hacer clic en `Step`, y enviará la solicitud e interceptará automáticamente la respuesta:
![Cuadro de diálogo de mensaje HTTP que muestra encabezados de respuesta y código de formulario HTML con botones: Paso, Continuar, Soltar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_response_intercept_response.jpg)

Una vez que hagamos los mismos cambios que hicimos anteriormente y hagamos clic en `Continue`, veremos que también podemos utilizar cualquier valor de entrada:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping', controles laterales para sitios y estado.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ZAP_edit_response.jpg)

Sin embargo, ZAP HUD también tiene otra característica poderosa que puede ayudarnos en casos como este. Si bien en muchos casos es posible que necesitemos interceptar la respuesta para realizar cambios personalizados, si todo lo que queríamos era habilitar los campos de entrada deshabilitados o mostrar los campos de entrada ocultos, entonces podemos hacer clic en el tercer botón a la izquierda (el ícono de la bombilla) y habilitará/mostrará estos campos sin que tengamos que interceptar la respuesta o actualizar la página.

Por ejemplo, la siguiente aplicación web tiene el `IP` campo de entrada deshabilitado:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping', controles laterales para sitios y estado.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ZAP_disabled_field.jpg)

En estos casos, podemos hacer clic en el `Show/Enable` botón, y habilitará el botón para nosotros, y podemos interactuar con él para agregar nuestra entrada:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping', controles laterales para sitios y estado.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ZAP_enable_field.jpg)

De manera similar, podemos utilizar esta función para mostrar todos los campos o botones ocultos. `Burp` También tiene una característica similar, que podemos habilitar en `Proxy>Proxy settings>Response modification rules`, luego seleccione una de las opciones, como `Unhide hidden form fields`.

Otra característica similar es la `Comments` botón, que indicará las posiciones donde hay comentarios HTML que normalmente sólo son visibles en el código fuente. Podemos hacer clic en el `+` Botón en el panel izquierdo y seleccione `Comments` para agregar el `Comments` botón, y una vez que hacemos clic en él, el `Comments` Se deben mostrar indicadores. Por ejemplo, la siguiente captura de pantalla muestra un indicador de una posición que tiene un comentario, y al pasar el cursor sobre él se muestra el contenido del comentario:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping', controles laterales para sitios, estado y comentarios.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ZAP_show_comments.jpg)

Poder modificar la apariencia de la página web nos facilita mucho realizar pruebas de penetración de aplicaciones web en ciertos escenarios en lugar de tener que enviar nuestra entrada a través de una solicitud interceptada. A continuación, veremos cómo podemos automatizar este proceso para modificar nuestros cambios en la respuesta automáticamente para no tener que seguir interceptando y cambiando manualmente las respuestas.