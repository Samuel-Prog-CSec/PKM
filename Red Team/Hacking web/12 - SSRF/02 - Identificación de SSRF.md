---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Server-Side/SSRF
Descripción: "Encontrar una SSRF es reconocer dónde la app pide algo por nosotros"
Fecha de actualización: 2026-06-22
Nota previa: "[[01 - Introducción a SSRF]]"
Nota siguiente: "[[03 - Explotación de SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
Encontrar una SSRF es reconocer dónde la app **pide algo por nosotros**. Esta nota cubre la metodología: localizar el parámetro candidato, confirmar la vulnerabilidad por canal **OOB**, distinguir si es ciega o refleja, y usarla para mapear la red interna.

# Localizar el parámetro candidato

<mark style="background: #ADCCFFA6;">Cualquier entrada que el servidor use para construir una petición saliente es candidata</mark>. Nombres habituales: <mark style="background: #FFB8EBA6;">`url`, `dateserver`, `dest`, `redirect`, `uri`, `path`, `feed`, `host`, `port`, `to`, `out`, `view`, `dir`, `show`, `callback`, `webhook`, `proxy`, `fetch`</mark>. Más allá del nombre, fíjate en la **funcionalidad**:

- Webhooks y callbacks configurables.
- Importadores "desde URL" (feeds, imágenes, documentos, avatares).
- Generadores de PDF / capturas de pantalla.
- Previsualización de enlaces (link unfurling): Apps de chat o paneles que leen una URL para generar una miniatura y título.
- Cabeceras reflejadas hacia peticiones internas (`Referer`, `X-Forwarded-For` mal usados).
- Parsers XML ([[16 - XXE a RCE, SSRF y DoS|XXE]] → SSRF): Procesamiento de archivos XML que soportan entidades externas (XXE).

Antes de nada, determina **qué porción de la URL controlas** (completa, solo host, solo ruta): decide tus opciones.

## ¿Qué parámetros adicionales requiere un endpoint?
Para determinar qué parámetros adicionales requiere un endpoint para procesar una petición correctamente, se emplean diferentes técnicas de análisis dependiendo del acceso y la visibilidad disponible durante la auditoría.

**1. Intercepción del tráfico legítimo (Análisis pasivo)** La vía más directa consiste en interactuar con la aplicación como un usuario normal mientras se captura el tráfico:
- **Proxy de interceptación (Burp Suite / OWASP ZAP):** Se realiza la acción desde la interfaz web (por ejemplo, pulsar un botón de "Generar informe" o "Vista previa") y se examina en el historial de peticiones el cuerpo del `POST` o la _query string_ del `GET`. Ahí quedan al descubierto todos los parámetros que el navegador envía de forma nativa (incluyendo campos ocultos o tokens).
- **Herramientas de desarrollo del navegador (DevTools):** En la pestaña _Network_ (Red), seleccionando la petición correspondiente y revisando la sección _Payload_ o _Params_.

**2. Inspección del código cliente (Front-end)** Los formularios web y la lógica de envío se definen en el cliente antes de salir al servidor:
- **Campos HTML:** Revisar en el DOM si existen etiquetas `<input type="hidden">` que envíen datos fijos en el formulario.
- **Archivos JavaScript:** Analizar las funciones que realizan llamadas `fetch()`, `axios()` o `$.ajax()`. Es muy habitual que los scripts del front-end concatenen variables antes de realizar la solicitud.

**3. Análisis de errores del backend (Error-driven)** Si se prueba un parámetro candidato de forma aislada, la respuesta del servidor suele dar pistas de lo que falta:
- Si el servidor devuelve un código `400 Bad Request` o `422 Unprocessable Entity`, el cuerpo de la respuesta en formato JSON o HTML a menudo especifica el motivo: `{"error": "Missing required field: date"}` o `"Parameter 'format' cannot be empty"`.

**4. Descubrimiento automatizado de parámetros (Parameter Discovery)** Cuando se audita un endpoint donde no hay una interfaz gráfica asociada ni documentación disponible:
- **Herramientas especializadas:** Se utilizan utilidades como `Arjun` o `ffuf` cargadas con un diccionario de nombres de parámetros comunes (`SecLists/Discovery/Web-Content/burp-parameter-names.txt`).
- **Mecánica:** La herramienta envía cientos de parámetros hipotéticos y compara las respuestas buscando variaciones en la longitud de la página (`Content-Length`), el código de estado HTTP o el tiempo de respuesta, lo que indica que el servidor ha reconocido y procesado dicho parámetro.

**5. Documentación de la API** En entornos modernos basados en microservicios, se buscan endpoints estándar de especificación como `/swagger.json`, `/api-docs`, `/v1/openapi.json` o `GraphQL schemas`, los cuales definen de forma explícita todos los campos obligatorios de cada ruta.

# Confirmar la SSRF (canal OOB)

El método universal: apuntar la app a **un sistema bajo nuestro control** y ver si llega la petición. HTB lo confirma con un `netcat` a la escucha:

```shell-session
$ nc -lnvp 8000
listening on [any] 8000 ...
connect to [172.17.0.1] from (UNKNOWN) [172.17.0.2] 38782
GET /ssrf HTTP/1.1
Host: 172.17.0.1:8000
```

Cuando pruebas si un parámetro es vulnerable a SSRF,<mark style="background: #FF5582A6;"> no sabes si la respuesta de esa petición se mostrará en pantalla o si la aplicación procesa la solicitud silenciosamente en segundo plano</mark>. El canal OOB elimina esa incertidumbre.
1. Configuras un servidor escuchando en internet (usando herramientas como `interactsh`, Burp Collaborator o una máquina propia con `netcat`).
2. Inyectas la dirección de tu servidor en el parámetro sospechoso (ej. `dateserver=http://tu-servidor-oob.com`).
3. Si en el panel de tu servidor ves entrar una petición HTTP o una consulta DNS proveniente de la dirección IP del objetivo, **la SSRF está 100% confirmada**. El servidor web ha sido coaccionado a realizar la conexión saliente.

<mark style="background: #FFB86CA6;">En un objetivo real, usa `interactsh` o Burp Collaborator en vez de un puerto crudo</mark>: capturan **DNS y HTTP**, y el lookup DNS suele salir aunque el HTTP de egress esté bloqueado —un hit solo-DNS ya confirma la SSRF—. Es el mismo oráculo OOB que en [[01 - Detección de Command Injection|command injection ciega]] o el [[08 - Detección y fuzzing automatizado|RFI ciego]].

> [!tip] El lookup de DNS suele salir incluso cuando los cortafuegos bloquean el tráfico HTTP saliente. Por eso, registrar una consulta DNS en tu servidor OOB basta para dar el hallazgo por confirmado.

> [!hacker]+ OOB
> El concepto "Out-Of-Band" (fuera de banda) se entiende mejor por contraste con el canal normal de comunicación:
> - **In-Band (En banda / Canal principal):** Es el flujo habitual. Tu navegador envía una petición al servidor web y espera recibir la respuesta directamente en la pantalla de tu navegador.
> - **Out-Of-Band (Fuera de banda / Canal secundario):** Consiste en hacer que el objetivo interactúe con **un tercer sistema externo que tú controlas independientemente**. No esperas a que la aplicación web te muestre un resultado en pantalla; en su lugar, monitoreas los registros (_logs_) de tu propia máquina externa para ver si la petición del servidor llegó.

# ¿Refleja o es ciega?

Tras confirmarla, la pregunta que decide todo: ¿vemos la respuesta de la petición forzada? Se comprueba apuntando la app **a sí misma**:

```
dateserver=http://127.0.0.1/index.php
```

Si la respuesta contiene el HTML de la propia aplicación, <mark style="background: #ADCCFFA6;">la SSRF **no es ciega**</mark> y tenemos disponible toda la [[03 - Explotación de SSRF|explotación]]. Si solo recibimos un mensaje genérico, es una [[04 - Blind SSRF|SSRF ciega]] y el juego cambia.

# ¿El servidor fija el método internamente?
Para comprobar si el servidor fija el método internamente (por ejemplo, forzando un `GET`), la prueba definitiva consiste en apuntar el parámetro vulnerable a un servidor propio que esté a la escucha (canal OOB) e inspeccionar los datos en bruto de la petición entrante.

## Paso a paso para comprobarlo:
1. **Levantar un oyente (Listener):** En tu máquina de ataque, inicias un puerto a la escucha con Netcat o usas una herramienta OOB:
	```
	nc -lnvp 8000
	```
2. **Enviar una petición `POST` desde tu cliente:** En Burp Suite o `curl`, envías una solicitud con método `POST` y un cuerpo de datos hacia el parámetro de la aplicación web vulnerable:
	```HTTP
	POST /index.php HTTP/1.1
	Host: target.com
	Content-Type: application/x-www-form-urlencoded
	    
	dateserver=http://TU-IP-ATACANTE:8000/test&midebug=1
	```
3. **Analizar la petición que llega a tu Netcat**:
	- **El servidor fija el método internamente:** Si a tu Netcat (o al OOB) le entra esto, significa que, aunque tú le enviaste un `POST` a la web, el código del backend utiliza una función como `axios.get()` o `file_get_contents()` que **fuerza una petición `GET`** de forma dura y descarta cualquier cuerpo que le hayas enviado.
	    ```HTTP
	    GET /test HTTP/1.1
	    Host: TU-IP-ATACANTE:8000
	    User-Agent: curl/7.68.0
	    ```
	- **El servidor reenvía el método (Comportamiento de Proxy):** Si a tu Netcat le entra un `POST` conservando tus parámetros, el backend sí respeta el método HTTP que usas en el origen.

# Mapear la red interna: port scan vía SSRF

Una SSRF reflejada permite **escanear puertos internos**, siempre que la respuesta difiera entre puerto abierto y cerrado. Un puerto cerrado devuelve un error reconocible. <mark style="background: #FFB8EBA6;">El string de filtro depende del stack</mark> —`Failed to connect to` en cURL/PHP, `Connection refused`/`ECONNREFUSED` en Python/Node/Java—: identifícalo primero enviando a un puerto cerrado conocido (p. ej. `9999`). Generamos la lista de puertos y fuzzeamos con `ffuf`, filtrando ese error:

```shell-session
$ seq 1 10000 > ports.txt
$ ffuf -w ./ports.txt -u http://172.17.0.2/index.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "dateserver=http://127.0.0.1:FUZZ/&date=2024-01-01" -fr "Failed to connect to"
```

```
[Status: 200, Size: 45]    FUZZ: 3306
[Status: 200, Size: 8285]  FUZZ: 80
```

Aquí asoman un MySQL (`3306`) y el propio web (`80`). <mark style="background: #FF5582A6;">El mismo barrido apunta a otros destinos internos</mark>: el host de metadatos cloud (`169.254.169.254`), el rango de Docker (`172.17.0.0/16`), redes privadas (`10.0.0.0/8`, `192.168.0.0/16`) y hostnames internos (`dateserver.htb`, `redis`, `db`). Cada servicio interno descubierto es una nueva superficie a través de la SSRF.

# Detección white-box

En [[00 - Qué es el whitebox pentesting|white-box]], se buscan los **sinks** que reciben una URL controlable por el usuario:

| Lenguaje | Sinks de petición saliente |
| - | - |
| **PHP** | `curl_exec` · `file_get_contents` · `fopen` · `fsockopen` |
| **Python** | `requests.get` · `urllib.request.urlopen` · `httpx` |
| **Node.js** | `http(s).get` · `axios` · `got` · `node-fetch` |
| **Java** | `URL.openConnection` · `HttpURLConnection` · `HttpClient` |
| **Go** | `http.Get` · `http.NewRequest` |
| **Ruby** | `open-uri` · `Net::HTTP` |

El *taint* va desde la URL del usuario hasta esos sinks sin una validación de destino (allowlist). Un sink que también soporte esquemas extra (`file://`, `gopher://` en cURL) eleva el impacto.

> [!info]+ Fuentes
> - [PortSwigger — Finding SSRF](https://portswigger.net/web-security/ssrf) · [interactsh](https://github.com/projectdiscovery/interactsh)
> - [PayloadsAllTheThings — SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)
> - [HackTricks — SSRF](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery)

Confirmada y mapeada, toca exprimirla: acceder a endpoints internos, leer ficheros y saltar de `GET` a peticiones arbitrarias con `gopher://`: [[03 - Explotación de SSRF]].
