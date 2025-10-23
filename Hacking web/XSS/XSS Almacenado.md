---
tags:
Fecha de actualización: 2025-10-16
Nota previa: "[[Cross-Site Scripting (XSS)]]"
Nota siguiente: "[[XSS Almacenado]]"
Area: "[[Cross-Site Scripting (XSS)]]"
---
---

El primer y más crítico tipo de vulnerabilidad XSS es **XSS Almacenado** (o, *XSS persistente*). Si nuestra <mark style="background: #ADCCFFA6;">carga útil XSS inyectada se almacena en la base de datos back-end y se recupera al visitar la página</mark>, esto significa que nuestro ataque <mark style="background: #FFB8EBA6;">XSS es persistente</mark> y <mark style="background: #8000E1A6;">puede afectar a cualquier usuario que visite la página</mark>. Además, es posible que el XSS almacenado no se pueda eliminar fácilmente y que sea necesario eliminar la carga útil de la base de datos del back-end.

# Cargas útiles de pruebas XSS
Podemos probar si la página es vulnerable a XSS con la siguiente carga útil XSS básica:
```html
<script>alert(window.origin)</script>
```

Utilizamos esta carga útil porque es un método muy fácil de detectar para saber cuándo nuestra carga útil XSS se ha ejecutado correctamente. Supongamos que la página permite cualquier entrada y no realiza ninguna desinfección en ella. En ese caso, la alerta debería aparecer con la URL de la página en la que se está ejecutando, directamente después de ingresar nuestra carga útil o cuando actualizamos la página:
![Dirección IP 139.59.166.56:31323 con botón OK.](https://academy.hackthebox.com/storage/modules/103/xss_stored_xss_alert.jpg)

Como podemos ver, efectivamente recibimos la alerta, lo que significa que la página es vulnerable a XSS, ya que nuestra carga útil se ejecutó correctamente. Podemos confirmarlo con más detalle mirando el código fuente de la página haciendo clic en [`CTRL+U`] o hacer clic derecho y seleccionar `View Page Source`, y deberíamos ver nuestra carga útil en la fuente de la página:
```html
<div></div><ul class="list-unstyled" id="todo"><ul><script>alert(window.origin)</script>
</ul></ul>
```
> [!important]+
> Muchas aplicaciones web modernas utilizan IFrames entre dominios para manejar la entrada del usuario, de modo que incluso si el formulario web es vulnerable a XSS, no sería una vulnerabilidad en la aplicación web principal. Por eso mostramos el valor de `window.origin` en el cuadro de alerta, en lugar de un valor estático como `1`. En este caso, el cuadro de alerta revelaría la URL en la que se está ejecutando y confirmaría qué formulario es el vulnerable, en caso de que se estuviera utilizando un IFrame.

Como algunos navegadores modernos pueden bloquear el `alert()` Función JavaScript en ubicaciones específicas, puede resultar útil conocer algunas otras cargas útiles básicas de XSS para verificar la existencia de XSS. Una de esas cargas útiles XSS es `<plaintext>`, que dejará de representar el código HTML que viene después y lo mostrará como texto sin formato. Otra carga útil fácil de detectar es `<script>print()</script>` que abrirá el cuadro de diálogo de impresión del navegador, que es poco probable que sea bloqueado por ningún navegador. Intente utilizar estas cargas útiles para ver cómo funciona cada una. Puede utilizar el botón de reinicio para eliminar cualquier carga útil actual.

<mark style="background: #ADCCFFA6;">Para ver si el payload es persistente y está almacenado en el back-end, podemos actualizar la página y ver si recibimos la alerta nuevamente</mark>. Si lo hacemos, veremos que seguimos recibiendo la alerta incluso durante las actualizaciones de la página, lo que confirma que esto es realmente una vulnerabilidad `Stored/Persistent XSS`. Esto no es exclusivo para nosotros, ya que cualquier usuario que visite la página activará el payload XSS y recibirá la misma alerta.