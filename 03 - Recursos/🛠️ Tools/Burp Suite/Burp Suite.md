---
tags:
Fecha de actualización: 2025-11-08
Nota previa:
Nota siguiente:
Area: "[[Proxies web]]"
---
---

[Burp Suite](https://portswigger.net/burp) es el proxy web más común para pruebas de penetración web. Tiene una excelente interfaz de usuario para sus diversas funciones e incluso proporciona un navegador Chromium integrado para probar aplicaciones web. Ciertas funciones de Burp solo están disponibles en la versión comercial `Burp Pro/Enterprise`, pero incluso la versión gratuita es una herramienta de prueba extremadamente poderosa para mantener en nuestro arsenal.

---

Si Burp no está preinstalado en nuestra máquina virtual, podemos comenzar descargándolo desde [Página de descarga de Burp](https://portswigger.net/burp/releases/). Una vez descargado, podemos ejecutar el instalador y seguir las instrucciones, que varían de un sistema operativo a otro, pero deberían ser bastante sencillas. Hay instaladores para Windows, Linux y macOS.

Una vez instalado, Burp se puede iniciar desde la terminal escribiendo `burpsuite`, o desde el menú de la aplicación como se mencionó anteriormente. Otra opción es descargar el `JAR` archivo (que se puede utilizar en todos los sistemas operativos con un entorno de ejecución Java (JRE) instalado) desde la página de descargas anterior. Podemos ejecutarlo con la siguiente línea de comando o haciendo doble clic en ella:
```shell-session
$ java -jar </path/to/burpsuite.jar>
```

Nota: Tanto Burp como ZAP dependen de Java Runtime Environment para ejecutarse, pero este paquete debe incluirse en el instalador de forma predeterminada. Si no, podemos seguir las instrucciones que se encuentran en este [página](https://docs.oracle.com/goldengate/1212/gg-winux/GDRAD/java.htm).

Una vez que iniciamos Burp, se nos solicita que creemos un nuevo proyecto. Si estamos ejecutando la versión comunitaria, solo podremos usar proyectos temporales sin la posibilidad de guardar nuestro progreso y continuar más tarde:
![Pantalla de configuración del proyecto Burp Suite Community Edition. Opciones para proyecto temporal, nuevo proyecto en disco o abrir proyecto existente. Nota: Los proyectos basados en disco solo son compatibles con la versión profesional. Botones para "Cancelar" y "Siguiente"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_project_community.jpg)

Si utilizamos la versión pro/empresarial, tendremos la opción de iniciar un nuevo proyecto o abrir un proyecto existente.
![Pantalla de configuración del proyecto Burp Suite Professional. Opciones para proyecto temporal, nuevo proyecto en disco o abrir proyecto existente. Campos para selección de nombre y archivo. Botones para "Cancelar" y "Siguiente"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_project_prof.jpg)

Es posible que necesitemos guardar nuestro progreso si estuviéramos probando aplicaciones web enormes o ejecutando un `Active Web Scan`. Sin embargo, es posible que no necesitemos salvar nuestro progreso y, en muchos casos, podemos iniciar un `temporary` proyecto cada vez.

Entonces, seleccionemos `temporary project`, y haga clic en continuar. Una vez que lo hagamos, se nos solicitará que usemos cualquiera de los dos `Burp Default Configurations`, o a `Load a Configuration File`, y elegiremos la primera opción:

![Pantalla de configuración de Burp Suite Community Edition. Opciones para utilizar los valores predeterminados de Burp, utilizar opciones de proyecto o cargar desde el archivo de configuración. Selección de archivos disponible. Casillas de verificación para configuraciones predeterminadas y deshabilitación de extensiones. Botones para "Cancelar", "Atrás" y "Iniciar eructo"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_project_config.jpg)

Una vez que comencemos a utilizar en gran medida las funciones de Burp, es posible que queramos personalizar nuestras configuraciones y cargarlas al iniciar Burp. Por ahora podemos mantenernos `Use Burp Defaults`, y `Start Burp`. Una vez hecho todo esto, deberíamos estar listos para comenzar a usar Burp.

---

## Burp Suite
En Burp, podemos navegar hasta el `Proxy` La pestaña y la interceptación de solicitudes deben estar activadas de forma predeterminada. Si queremos activar o desactivar la interceptación de solicitudes, podemos ir al `Intercept` Subpestaña y haga clic en `Intercept is on/off` botón para hacerlo:
![Pestaña de proxy con intercepción, historial HTTP, historial de WebSockets y opciones. Botones: Avanzar, Soltar, Interceptar activado, Acción, Abrir navegador.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_intercept_htb_on.png)

Una vez que activamos la interceptación de solicitudes, podemos iniciar el navegador preconfigurado y luego visitar nuestro sitio web de destino después de generarlo a partir del ejercicio al final de esta sección. Luego, una vez que volvamos a Burp, veremos la solicitud interceptada esperando nuestra acción y podremos hacer clic en `forward` para reenviar la solicitud:
![Pestaña de proxy que muestra detalles de la solicitud HTTP con botones: Avanzar, Soltar, Interceptar está activado, Acción, Abrir navegador.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_intercept_page.png)

Nota: como todo el tráfico de Firefox será interceptado en este caso, es posible que veamos que se ha interceptado otra solicitud antes de esta. Si esto sucede, haga clic en 'Adelante' hasta que recibamos la solicitud en nuestra IP de destino, como se muestra arriba.

---

# RESPUESTAS Burp Suite
En Burp, podemos habilitar la interceptación de respuestas yendo a (`Proxy>Proxy settings`) y habilitando `Intercept Response` bajo `Response interception rules`:
![Intercepte la configuración de respuestas del servidor con la tabla de reglas y los botones: Agregar, Editar, Eliminar, Arriba, Abajo. Opciones para interceptar respuestas y actualizar el encabezado Content-Length.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/response_interception_enable.png)

Después de eso, podemos habilitar la interceptación de solicitudes una vez más y actualizar la página con [`CTRL+SHIFT+R`] en nuestro navegador (para forzar una actualización completa). Cuando volvamos a Burp, deberíamos ver la solicitud interceptada y podemos hacer clic en `forward`. Una vez que reenviemos la solicitud, veremos nuestra respuesta interceptada:
![Código de formulario HTML para 'Hacer ping a su IP' con campo de entrada para dirección IP, número de tipo, mínimo 1, máximo 255, longitud máxima 3.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/response_intercept_response_1_1.jpg)

Intentemos cambiar el `type="number"` en la línea 27 a `type="text"`, lo que debería permitirnos escribir cualquier valor que queramos. También cambiaremos el `maxlength="3"` to `maxlength="100"` para que podamos ingresar una entrada más larga:
```html
<input type="text" id="ip" name="ip" min="1" max="255" maxlength="100"
    oninput="javascript: if (this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);"
    required>
```

Ahora, una vez que hacemos clic en `forward` Nuevamente, podemos volver a Firefox para examinar la respuesta editada:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping'.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/response_intercept_response_2.jpg)

Como podemos ver, podríamos cambiar la forma en que el navegador representa la página y ahora podemos ingresar cualquier valor que queramos. Podemos utilizar la misma técnica para habilitar persistentemente cualquier botón HTML deshabilitado modificando su código HTML.

Ejercicio: Intente utilizar la carga útil que utilizamos la última vez directamente dentro del navegador para probar cómo interceptar respuestas puede facilitar las pruebas de penetración de aplicaciones web.