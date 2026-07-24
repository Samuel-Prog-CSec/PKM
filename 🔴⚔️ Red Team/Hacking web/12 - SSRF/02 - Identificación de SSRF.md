---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Server-Side/SSRF
Fecha de actualización: 2026-06-22
Nota previa: "[[01 - Introducción a SSRF]]"
Nota siguiente: "[[03 - Explotación de SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
---

Encontrar una SSRF es reconocer dónde la app **pide algo por nosotros**. Esta nota cubre la metodología: localizar el parámetro candidato, confirmar la vulnerabilidad por canal **OOB**, distinguir si es ciega o refleja, y usarla para mapear la red interna.

# Localizar el parámetro candidato

Cualquier entrada que el servidor use para construir una petición saliente es candidata. Nombres habituales: <mark style="background: #FFB8EBA6;">`url`, `dateserver`, `dest`, `redirect`, `uri`, `path`, `feed`, `host`, `port`, `to`, `out`, `view`, `dir`, `show`, `callback`, `webhook`, `proxy`, `fetch`</mark>. Más allá del nombre, fíjate en la **funcionalidad**:

- Webhooks y callbacks configurables.
- Importadores "desde URL" (feeds, imágenes, documentos, avatares).
- Generadores de PDF / capturas de pantalla.
- Previsualización de enlaces (link unfurling).
- Cabeceras reflejadas hacia peticiones internas (`Referer`, `X-Forwarded-For` mal usados).
- Parsers XML ([[16 - XXE a RCE, SSRF y DoS|XXE]] → SSRF).

Antes de nada, determina **qué porción de la URL controlas** (completa, solo host, solo ruta): decide tus opciones.

# Confirmar la SSRF (canal OOB)

El método universal: apuntar la app a **un sistema bajo nuestro control** y ver si llega la petición. HTB lo confirma con un `netcat` a la escucha:

```shell-session
$ nc -lnvp 8000
listening on [any] 8000 ...
connect to [172.17.0.1] from (UNKNOWN) [172.17.0.2] 38782
GET /ssrf HTTP/1.1
Host: 172.17.0.1:8000
```

<mark style="background: #FFB86CA6;">En un objetivo real, usa `interactsh` o Burp Collaborator en vez de un puerto crudo</mark>: capturan **DNS y HTTP**, y el lookup DNS suele salir aunque el HTTP de egress esté bloqueado —un hit solo-DNS ya confirma la SSRF—. Es el mismo oráculo OOB que en [[01 - Detección de Command Injection|command injection ciega]] o el [[08 - Detección y fuzzing automatizado|RFI ciego]].

# ¿Refleja o es ciega?

Tras confirmarla, la pregunta que decide todo: ¿vemos la respuesta de la petición forzada? Se comprueba apuntando la app **a sí misma**:

```
dateserver=http://127.0.0.1/index.php
```

Si la respuesta contiene el HTML de la propia aplicación, <mark style="background: #ADCCFFA6;">la SSRF **no es ciega**</mark> y tenemos disponible toda la [[03 - Explotación de SSRF|explotación]]. Si solo recibimos un mensaje genérico, es una [[04 - Blind SSRF|SSRF ciega]] y el juego cambia.

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

En caja blanca, se buscan los **sinks** que reciben una URL controlable por el usuario:

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
