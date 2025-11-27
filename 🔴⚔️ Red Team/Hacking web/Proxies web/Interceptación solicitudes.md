---
tags:
Fecha de actualización: 2025-11-08
Nota previa:
Nota siguiente:
Area: "[[Proxies web]]"
---
---

# Interceptar solicitudes
Ahora que hemos configurado nuestro proxy, podemos usarlo para interceptar y manipular varias solicitudes HTTP enviadas por la aplicación web que estamos probando. Comenzaremos aprendiendo cómo interceptar solicitudes web, cambiarlas y luego enviarlas a su destino previsto.

---

# Interceptar respuestas
En algunos casos, es posible que necesitemos interceptar las respuestas HTTP del servidor antes de que lleguen al navegador. Esto puede resultar útil cuando queremos cambiar el aspecto de una página web específica, como habilitar ciertos campos deshabilitados o mostrar ciertos campos ocultos, lo que puede ayudarnos en nuestras actividades de pruebas de penetración.

Entonces, veamos cómo podemos lograrlo con el ejercicio que probamos en la sección anterior.

En nuestro ejercicio anterior, el `IP` El campo solo nos permitió ingresar valores numéricos. Si interceptamos la respuesta antes de que llegue a nuestro navegador, podemos editarla para aceptar cualquier valor, lo que nos permitiría ingresar directamente la carga útil que usamos la última vez.

---

# Manipulación de solicitudes interceptadas
Una vez que interceptemos la solicitud, permanecerá colgada hasta que la reenviemos, como hicimos anteriormente. Podemos examinar la solicitud, manipularla para realizar los cambios que queramos y luego enviarla a su destino. Esto nos ayuda a comprender mejor qué información envía una aplicación web en particular en sus solicitudes web y cómo puede responder a cualquier cambio que realicemos en esa solicitud.

Existen numerosas aplicaciones para esto en las pruebas de penetración web, como las pruebas para:
1. Inyecciones SQL
2. Inyecciones de comandos
3. Subir bypass
4. Omisión de autenticación
5. XSS
6. XXE
7. Manejo de errores
8. Deserialización

Y muchas otras vulnerabilidades web potenciales, como veremos en otros módulos web de HTB Academy. Entonces, mostremos esto con un ejemplo básico para demostrar cómo interceptar y manipular solicitudes web.

Volvamos a activar la interceptación de solicitudes en la herramienta que elijamos, configure la `IP` valor en la página, luego haga clic en el `Ping` botón. Una vez interceptada nuestra solicitud, deberíamos recibir una solicitud HTTP similar a la siguiente:
```http
POST /ping HTTP/1.1
Host: 94.237.62.138:32306
Content-Length: 4
Cache-Control: max-age=0
Accept-Language: en-US,en;q=0.9
Origin: http://94.237.62.138:32306
Content-Type: application/x-www-form-urlencoded
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Referer: http://94.237.62.138:32306/
Accept-Encoding: gzip, deflate, br
Connection: keep-alive

ip=1
```

Normalmente, solo podemos especificar números en el `IP` campo que utiliza el navegador, ya que la página web nos impide enviar caracteres no numéricos utilizando JavaScript front-end. Sin embargo, con el poder de interceptar y manipular solicitudes HTTP, podemos intentar usar otros caracteres para "romper" la aplicación ("romper" el flujo de solicitud/respuesta manipulando el parámetro de destino, sin dañar la aplicación web de destino). Si la aplicación web no verifica ni valida las solicitudes HTTP en el back-end, es posible que podamos manipularla y explotarla.

Entonces, cambiemos el `ip` valor del parámetro de `1` to `;ls;` y vea cómo la aplicación web maneja nuestra entrada:
![Cuadro de diálogo de mensaje HTTP que muestra detalles de la solicitud POST con botones: Paso, Continuar, Soltar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ping_manipulate_request.png)

Una vez que hagamos clic en continuar/avanzar, veremos que la respuesta cambió de la salida de ping predeterminada a la `ls` salida, lo que significa que manipulamos con éxito la solicitud para inyectar nuestro comando:
![Lista de archivos: flag.txt, index.html, node_modules, package-lock.json, public, server.js.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/ping_inject.jpg)

Esto demuestra un ejemplo básico de cómo la interceptación y manipulación de solicitudes puede ayudar a probar aplicaciones web en busca de diversas vulnerabilidades, lo que se considera una herramienta esencial para poder probar diferentes aplicaciones web de manera efectiva.

Nota: Como se mencionó anteriormente, no cubriremos ataques web específicos en este módulo, sino más bien cómo Web Proxies puede facilitar varios tipos de ataques. Otros módulos web de HTB Academy cubren este tipo de ataques en profundidad.

---

# Modificación automática
Es posible que queramos aplicar ciertas modificaciones a todas las solicitudes HTTP salientes o a todas las respuestas HTTP entrantes en determinadas situaciones. En estos casos, podemos utilizar modificaciones automáticas basadas en las reglas que establezcamos, por lo que las herramientas de proxy web las aplicarán automáticamente.

## Modificación automática de solicitudes
Comencemos con un ejemplo de modificación automática de solicitudes. Podemos elegir hacer coincidir cualquier texto dentro de nuestras solicitudes, ya sea en el encabezado o en el cuerpo de la solicitud, y luego reemplazarlo con un texto diferente. Para fines de demostración, reemplacemos nuestro `User-Agent` con `HackTheBox Agent 1.0`, lo que puede resultar útil en los casos en los que podamos estar tratando con filtros que bloquean ciertos agentes de usuario.

### Combinación y reemplazo de eructos
Podemos ir a (`Proxy>Proxy settings>HTTP match and replace rules`) y haga clic en `Add` en eructo. Como muestra la siguiente captura de pantalla, configuraremos las siguientes opciones:
![Cuadro de diálogo de reglas de coincidencia/reemplazo para el encabezado de solicitud, que coincide con '^User-Agent.*$', que reemplaza con 'User-Agent: HackTheBox Agent 1.0', expresión regular habilitada, botones Aceptar y Cancelar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_match_replace_user_agent_1.png)


| `Type`: `Request header`                      | Ya que el cambio que queremos realizar será en el encabezado de la solicitud y no en su cuerpo.                                                                                                            |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Match`: `^User-Agent.*$`                     | El patrón de expresión regular que coincide con toda la línea `User-Agent` en él.                                                                                                                          |
| `Replace`: `User-Agent: HackTheBox Agent 1.0` | Este es el valor que reemplazará la línea que igualamos anteriormente.                                                                                                                                     |
| `Regex match`: True                           | No sabemos la cadena User-Agent exacta que queremos reemplazar, por lo que usaremos expresiones regulares para hacer coincidir cualquier valor que coincida con el patrón que especificamos anteriormente. |

Una vez que ingresamos las opciones anteriores y hacemos clic `Ok`, nuestra nueva opción Coincidir y Reemplazar se agregará y habilitará y comenzará a reemplazar automáticamente la `User-Agent` encabezado en nuestras solicitudes con nuestro nuevo User-Agent. Podemos verificarlo visitando cualquier sitio web utilizando el navegador Burp preconfigurado y revisando la solicitud interceptada. Veremos que nuestro User-Agent efectivamente ha sido reemplazado automáticamente:
![Detalles de la solicitud HTTP con 'User-Agent: HackTheBox Agent 1.0', botones: Avanzar, Soltar, La intersección está activada, Acción, Abrir navegador.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_match_replace_user_agent_2.png)

### Reemplazante de ZAP
ZAP tiene una característica similar llamada `Replacer`, al que podemos acceder presionando [`CTRL+R`] o haciendo clic en `Replacer` en el menú de opciones de ZAP. Es bastante similar a lo que hicimos anteriormente, por lo que podemos hacer clic en `Add` y agregue las mismas opciones que usamos anteriormente:
![Configuración de reglas para 'HTB User-Agent', coincidencia con 'User-Agent' en el encabezado de la solicitud, reemplazo con 'HackTheBox Agent 1.0', botones habilitados, Guardar y Cancelar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_match_replace_user_agent_1.png)

- `Description`: `HTB User-Agent`.
- `Match Type`: `Request Header (will add if not present)`.
- `Match String`: `User-Agent`. Podemos seleccionar el encabezado que queramos del menú desplegable y ZAP reemplazará su valor.
- `Replacement String`: `HackTheBox Agent 1.0`.
- `Enable`: Cierto.

ZAP también tiene el `Request Header String` que podemos usar con un patrón Regex. `Try using this option with the same values we used for Burp to see how it works.`

ZAP también ofrece la opción de configurar el `Initiators`, al que podemos acceder haciendo clic en la otra pestaña de las ventanas que se muestran arriba. Los iniciadores nos permiten seleccionar dónde está nuestro `Replacer` Se aplicará la opción. Mantendremos la opción predeterminada de `Apply to all HTTP(S) messages` para aplicar en todas partes.

Ahora podemos habilitar la interceptación de solicitudes presionando [`CTRL+B`], luego puede visitar cualquier página en el navegador ZAP preconfigurado:
![Detalles de la solicitud HTTP con 'User-Agent: HackTheBox Agent 1.0' resaltado.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/zap_match_replace_user_agent_2.png)

---

# Modificación automática de la respuesta
El mismo concepto también se puede utilizar con respuestas HTTP. En la sección anterior, es posible que hayas notado cuando interceptamos la respuesta que las modificaciones que hicimos a la `IP` Los campos eran temporales y no se aplicaban cuando actualizábamos la página a menos que interceptáramos la respuesta y los agregáramos nuevamente. Para resolver esto, podemos automatizar la modificación de la respuesta de manera similar a lo que hicimos anteriormente para habilitar automáticamente cualquier carácter en el `IP` campo para facilitar la inyección de comandos.

Volvamos a (`Proxy>Options>Match and Replace`) en Burp para agregar otra regla. Esta vez utilizaremos el tipo de `Response body` ya que el cambio que queremos realizar existe en el cuerpo de la respuesta y no en sus encabezados. En este caso, no tenemos que usar expresiones regulares ya que sabemos la cadena exacta que queremos reemplazar, aunque es posible usar expresiones regulares para hacer lo mismo si lo preferimos.
![Cuadro de diálogo de reglas de coincidencia/reemplazo para el cuerpo de la respuesta, que coincide con los botones 'type="number"', reemplazo con 'type="text"', Aceptar y Cancelar.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_match_replace_response_1.png)

- `Type`: `Response body`.
- `Match`: `type="number"`.
- `Replace`: `type="text"`.
- `Regex match`: Falso.

Intente agregar otra regla para cambiar `maxlength="3"` to `maxlength="100"`.

Ahora, una vez que actualicemos la página con [`CTRL+SHIFT+R`], veremos que podemos agregar cualquier entrada al campo de entrada, y esto también debería persistir entre actualizaciones de página:
![Interfaz de ping con entrada IP '127.0.0.0' y botón 'Ping'.](https://cdn.services-k8s.prod.aws.htb.systems/content/modules/110/burp_match_replace_response_2.jpg)

Ahora podemos hacer clic en `Ping`, y nuestra inyección de comandos debería funcionar sin interceptar ni modificar la solicitud.

Ejercicio 1: Intente aplicar las mismas reglas con ZAP Replacer. Puede hacer clic en la pestaña a continuación para mostrar las opciones correctas.

Cambiar el tipo de entrada a texto:  
- `Match Type`: `Response Body String`.  
- `Match Regex`: `False`.  
- `Match String`: `type="number"`.  
- `Replacement String`: `type="text"`.  
- `Enable`: `True`.  
  
Cambie la longitud máxima a 100:  
- `Match Type`: `Response Body String`.  
- `Match Regex`: `False`.  
- `Match String`: `maxlength="3"`.  
- `Replacement String`: `maxlength="100"`.  
- `Enable`: `True`.  