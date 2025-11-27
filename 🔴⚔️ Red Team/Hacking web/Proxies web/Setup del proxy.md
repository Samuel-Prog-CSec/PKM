---
tags:
Fecha de actualización:
Nota previa:
Nota siguiente:
Area:
---
---

Ahora que hemos instalado e iniciado ambas herramientas, aprenderemos a utilizar la función más utilizada: `Web Proxy`.

Podemos configurar estas herramientas como un proxy para cualquier aplicación, de modo que todas las solicitudes web se enruten a través de ellas para que podamos examinar manualmente qué solicitudes web envía y recibe una aplicación. Esto nos permitirá comprender mejor lo que hace la aplicación en segundo plano y nos permitirá interceptar y cambiar estas solicitudes o reutilizarlas con varios cambios para ver cómo responde la aplicación.

---

# Navegador preconfigurado
Para utilizar las herramientas como proxies web, debemos configurar los ajustes del proxy de nuestro navegador para usarlas como proxy o utilizar el navegador preconfigurado. Ambas herramientas tienen un navegador preconfigurado que viene con configuraciones de proxy preconfiguradas y los certificados CA preinstalados, lo que hace que iniciar una prueba de penetración web sea muy rápido y fácil.

En Burp (`Proxy>Intercept`), podemos hacer clic en `Open Browser`, que abrirá el navegador preconfigurado de Burp y enrutará automáticamente todo el tráfico web a través de Burp: ![Pestaña Proxy de Burp Suite con Intercept desactivado. Opción de utilizar el navegador integrado de Burp. Botón para "Abrir navegador" La navegación incluye panel, objetivo, proxy y más.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_preconfigured_browser.png)

En ZAP, podemos hacer clic en el icono del navegador Firefox al final de la barra superior y se abrirá el navegador preconfigurado:

![Barra de herramientas con varios iconos. Información sobre herramientas: "Abra el navegador que haya elegido en la pestaña Inicio rápido preconfigurado para proxy a través de ZAP"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_preconfigured_browser.jpg)

Para nuestros usos en este módulo, utilizar el navegador preconfigurado debería ser suficiente.

---

## Configuración del proxy

En muchos casos, es posible que queramos utilizar un navegador real para realizar pruebas de penetración, como Firefox. Para utilizar Firefox con nuestras herramientas de proxy web, primero debemos configurarlo para usarlas como proxy. Podemos ir manualmente a las preferencias de Firefox y configurar el proxy para utilizar el puerto de escucha del proxy web. Tanto Burp como ZAP utilizan puerto `8080` de forma predeterminada, pero podemos utilizar cualquier puerto disponible. Si elegimos un puerto que está en uso, el proxy no podrá iniciarse y recibiremos un mensaje de error.

**Nota:** En caso de que quisiéramos servir el proxy web en un puerto diferente, podemos hacerlo en Burp en (`Proxy>Proxy settings>Proxy listeners`), o en ZAP bajo (`Tools>Options>Network>Local Servers/Proxies`). En ambos casos, debemos asegurarnos de que el proxy configurado en Firefox utilice el mismo puerto.

En lugar de cambiar manualmente el proxy, podemos utilizar la extensión Firefox [Proxy Foxy](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/) para cambiar fácil y rápidamente el proxy de Firefox. Esta extensión está preinstalada en su instancia de PwnBox y se puede instalar en su propio navegador Firefox visitando el [Página de extensiones de Firefox](https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/) y haciendo clic `Add to Firefox` para instalarlo.

Una vez que hayamos agregado la extensión, podemos configurar el proxy web haciendo clic en su ícono en la barra superior de Firefox y luego eligiendo `Options`
![Menú FoxyProxy con opciones para "Opciones", "¿Cuál es mi IP?" y "Registro"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/foxyproxy_options.png)

Una vez que estemos en el `Options` página, podemos hacer clic en `Add` en el panel izquierdo y luego use `127.0.0.1` como IP, `8080` Como puerto, nómbralo `Burp` o `ZAP`, y haga clic `Save`:
![Editar la configuración de Proxy Burp/ZAP. Campos para título, color, tipo de proxy, dirección IP, puerto, nombre de usuario y contraseña. Botones para "Cancelar", "Guardar y agregar otro", "Guardar y editar patrones" y "Guardar"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/foxyproxy_add.png)

Nota: Esta configuración ya está agregada a FoxyProxy en PwnBox, por lo que no es necesario realizar este paso si está usando PwnBox.

Por último, podemos hacer clic en el `FoxyProxy` icono y seleccione `Burp`/`ZAP`. ![Menú FoxyProxy con Burp/ZAP habilitado. Opciones para "Opciones", "¿Cuál es mi IP?" y "Registro"](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/foxyproxy_use.png)

---

# Instalación del certificado CA
Otro paso importante al utilizar Burp Proxy/ZAP con nuestro navegador es instalar los certificados CA del proxy web. Si no realizamos este paso, es posible que parte del tráfico HTTPS no se enrute correctamente o que necesitemos hacer clic `accept` cada vez que Firefox necesita enviar una solicitud HTTPS.

Podemos instalar el certificado de Burp una vez que seleccionemos Burp como nuestro proxy en `Foxy Proxy`, navegando a `http://burp`, y descargar el certificado desde allí haciendo clic en `CA Certificate`:
![Encabezado de Burp Suite Community Edition con botón 'Certificado CA'.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_cert.jpg)

Para obtener el certificado de ZAP, podemos ir a (`Tools>Options>Network>Server Certificates`), luego haga clic en `Save`:
![Ventana de certificados SSL dinámicos con lista de opciones, texto del certificado y botones 'Generar', 'Importar', 'Ver', 'Guardar'.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_cert.png)

También podemos cambiar nuestro certificado generando uno nuevo con el `Generate` botón.

Una vez que tengamos nuestros certificados, podremos instalarlos dentro de Firefox navegando a [Acerca de:preferencias#privacy](about:preferences#privacy), desplazándose hacia abajo y haciendo clic `View Certificates`:
![Configuración de certificados con opciones de selección automática, solicitud en todo momento, consulta OCSP y botones para 'Ver certificados' y 'Dispositivos de seguridad'.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/firefox_cert.png)

Después de eso, podemos seleccionar el `Authorities` pestaña y luego haga clic en `import`, y seleccione el certificado CA descargado:
![Ventana del Administrador de certificados que muestra la pestaña Autoridades con la lista de certificados y opciones para Ver, Editar confianza, Importar, Exportar y Eliminar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/firefox_import_cert.png)

Finalmente, debemos seleccionar `Trust this CA to identify websites` y `Trust this CA to identify email users`, y luego haga clic en Aceptar: 
![Descargar cuadro de diálogo de certificado que solicita confiar en 'PortSwigger CA' para sitios web y correo electrónico, con opciones para Ver, Examinar, Cancelar y Aceptar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/firefox_trust_cert.jpg)

Una vez que instalemos el certificado y configuremos el proxy de Firefox, todo el tráfico web de Firefox comenzará a enrutarse a través de nuestro proxy web.