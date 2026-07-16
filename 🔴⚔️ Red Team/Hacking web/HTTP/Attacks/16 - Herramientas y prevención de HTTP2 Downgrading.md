---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/H2
Fecha de actualización: 2026-07-14
Nota previa: "[[15 - Más vulnerabilidades HTTP2]]"
Nota siguiente: ""
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Cierre del bloque HTTP/2 y del módulo: cómo **detectar** el downgrade smuggling con herramientas y la **prevención** de fondo.

# Arsenal

La misma extensión **HTTP Request Smuggler** cubre HTTP/2. El flujo:

1. Envía una petición HTTP/2 a Repeater.
2. Botón derecho → *Extensions → HTTP Request Smuggler → **CL.0***.
3. Deja los ajustes por defecto y lanza el scan.
4. Resultados en *Extensions → Installed → HTTP Request Smuggler → Output*.

> [!info] CL.0: pariente de H2.CL, pero no es lo mismo
> El scan **CL.0** detecta desyncs donde <mark style="background: #ADCCFFA6;">el **back-end ignora** el `Content-Length`</mark> (lo trata como `0`) en endpoints que no esperan cuerpo (estáticos, redirects). Es HTTP/1.1 puro, de *Browser-Powered Desync Attacks* (Kettle, **2022**). Es **primo** de la [[14 - HTTP2 Downgrading|H2.CL]] (que vive en el downgrade HTTP/2→1.1, 2021) pero **no** es lo mismo: <mark style="background: #FFB8EBA6;">el `0` de "CL.0" designa el **comportamiento del back-end**, no el valor del header</mark>. La herramienta reporta algo así:
> ```text
> Found issue: CL.0 desync: h2CL|TRACE /
> ... got a response that appears to have been poisoned by the body of the previous request
> ```
> …y te da un **PoC** listo para verificar manualmente.

Verificación manual del PoC (tab group, *Update Content-Length* desactivado en la 1ª, enviadas por conexiones separadas para probar que afecta a otros):

```http
# Request 1 (smuggled)
POST /index.php HTTP/1.1
Host: target:8443
Content-Type: application/x-www-form-urlencoded
Content-Length: 0

TRACE / HTTP/1.1
X-YzBqv: 
```
```http
# Request 2
GET /index.php HTTP/2
Host: target:8443
```

Si la primera responde `200` y la **segunda** `405`, el `TRACE` smuggled se coló y contaminó la segunda petición → desync confirmada.

```shell-session
# Complementos de línea de comandos
$ python3 smuggler.py -u https://target/     # detección clásica (también útil aquí)
$ python3 h2csmuggler.py ...                 # HTTP/2 cleartext (h2c) upgrade smuggling
```

> [!success] Prevención: HTTP/2 extremo a extremo
> La causa de **todo** este bloque es el **downgrade**. La cura es única y tajante:
> - <mark style="background: #FF5582A6;">Los proxies **no deben reescribir** HTTP/2 a HTTP/1.1</mark>. Hay que implementar **HTTP/2 de punta a punta** (cliente→proxy→servidor), sin reescritura.
> - Si el downgrade es inevitable (back-end sin HTTP/2), el proxy debe **validar estrictamente** las peticiones HTTP/2 según el RFC 9113 §8.2.1 (rechazar `CR`/`LF`/`:` en cabeceras, validar que el `content-length` casa con los DATA frames) y **no reenviar** lo malformado.
> - Como siempre en smuggling: mantener **todo** el stack actualizado y **cerrar la conexión** ante errores de parseo.
>
> Sin diferencias entre versiones que explotar, el smuggling desaparece.

# Cierre del módulo HTTP Attacks

Con esto termina el módulo. El hilo conductor ha sido la **ambigüedad de interpretación** del protocolo entre sistemas:

- [[01 - Introducción a CRLF Injection|CRLF Injection]] — inyectar `\r\n` donde tiene significado (logs, cabeceras HTTP/SMTP).
- [[06 - Introducción a HTTP Request Smuggling|Request Smuggling]] — desincronizar proxy y servidor por la longitud de la petición (CL/TE).
- [[13 - Introducción a HTTP2|HTTP/2 Downgrading]] — reintroducir esa ambigüedad al reescribir HTTP/2 a HTTP/1.1.

Los tres comparten defensa: <mark style="background: #8000E1A6;">no dejar que datos controlados por el usuario alteren cómo un sistema **parsea** el mensaje</mark>, y homogeneizar el protocolo en toda la cadena.

## Referencias

- [HTTP Request Smuggler (Burp)](https://github.com/PortSwigger/http-request-smuggler)
- [PortSwigger — Browser-Powered Desync Attacks](https://portswigger.net/research/browser-powered-desync-attacks)
