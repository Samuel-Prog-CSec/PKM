---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Request-Smuggling
Fecha de actualización: 2026-07-14
Nota previa: "[[09 - TE.CL]]"
Nota siguiente: "[[11 - Explotación de Request Smuggling]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Las variantes [[07 - CL.TE|CL.TE]]/[[09 - TE.CL|TE.CL]]/[[08 - TE.TE|TE.TE]] nacen del conflicto `CL`/`TE`. Pero <mark style="background: #8000E1A6;">cualquier **bug de parseo** que haga a dos sistemas discrepar en la longitud de una petición produce smuggling</mark>, aunque no toque `CL` ni `TE`. Esta nota muestra un bug de implementación concreto y generaliza el enfoque.

# Caso: bug de Gunicorn con `Sec-Websocket-Key1`

**Gunicorn 20.0.4** (servidor Python) tenía un bug: al encontrar la cabecera `Sec-Websocket-Key1` (usada para WebSockets), <mark style="background: #FFB8EBA6;">**truncaba el cuerpo a 8 bytes**</mark> ignorando por completo `CL` y `TE`. Como el proxy inverso **no** sufre el bug, se crea la desync.

```http
GET / HTTP/1.1
Host: gunicorn.htb
Content-Length: 49
Sec-Websocket-Key1: x

xxxxxxxxGET /404 HTTP/1.1
Host: gunicorn.htb
```

- **Proxy (CL:49)**: el cuerpo son 49 bytes; ve un `GET /` y luego el `GET /` normal siguiente.
- **Gunicorn (bug)**: en cuanto ve `Sec-Websocket-Key1`, el cuerpo son **8 bytes** = `xxxxxxxx`. Lo que sigue lo parsea como peticiones nuevas: `GET /404` (→ 404) y el `GET /` siguiente como tercera.

Enviadas por una sola conexión, la **segunda** respuesta llega con `404` en vez del index → desync confirmada. La explotación es idéntica a [[09 - TE.CL|TE.CL]]: esconder un `GET /admin` del WAF dentro de la petición inicial.

# El principio general

<mark style="background: #ADCCFFA6;">El smuggling es, en el fondo, **cualquier discrepancia de parseo** entre front-end y back-end sobre dónde acaba una petición</mark>. El conflicto CL/TE es el caso más común, pero un bug específico de un servidor (una cabecera que malinterpreta, un límite de tamaño distinto, un carácter que uno acepta y el otro no) sirve igual. Por eso el enfoque profesional es:

1. **Fingerprintear** el stack: qué proxy/CDN hay delante (`Server`, `Via`, cabeceras del CDN) y qué servidor detrás.
2. **Buscar CVEs de smuggling conocidas** para esas versiones.
3. **Probar la matriz** de desyncs con herramientas (ver [[12 - Herramientas y prevención de Request Smuggling]]).

> [!info] Vectores modernos que HTB no cubre (CL.0 y familia)
> Desde el trabajo de **James Kettle** *Browser-Powered Desync Attacks* (2022) hay toda una familia más allá de CL/TE:
> - **CL.0**: el back-end **ignora** el `Content-Length` para ciertos endpoints (ficheros estáticos, redirects, endpoints que no esperan cuerpo) y lo trata como `0`. El front lo respeta → desync. No necesita `TE` en absoluto.
> - **0.CL**: la inversa (el front ignora el CL).
> - **Client-side desync**: el desync ocurre entre el **navegador de la víctima** y el servidor, explotable <mark style="background: #FFB8EBA6;">**sin** proxy intermedio y sin acceso a la conexión de la víctima</mark>, disparado con JavaScript desde una web del atacante.
> - **Connection-state attacks** (`first-request routing`, `first-request validation`): el front-end aplica reglas solo a la **primera** petición de una conexión.
> Son de lo más rentable en bug bounty actual y ninguno aparece en el material original.

> [!warning] Ejemplos reales de software vulnerable
> A lo largo de los años han caído nginx, HAProxy, Apache Traffic Server, Squid, Varnish, AWS ALB/CloudFront, Akamai, Envoy y muchos más con CVEs de smuggling. La lección: <mark style="background: #8000E1A6;">mantener actualizado **todo** el camino de la petición</mark> (CDN, WAF, proxy, servidor), porque el bug puede estar en cualquier eslabón.

## Referencias

- [PortSwigger — Browser-Powered Desync Attacks (Kettle, 2022)](https://portswigger.net/research/browser-powered-desync-attacks)
- [Gunicorn 20.0.4 request smuggling (grenfeldt.dev)](https://grenfeldt.dev/2021/04/01/gunicorn-20.0.4-request-smuggling/)
