---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/H2
Descripción: "El H2.CL/H2.TE básico requiere que el proxy arrastre un CL/TE mentido"
Fecha de actualización: 2026-07-14
Nota previa: "[[14 - HTTP2 Downgrading]]"
Nota siguiente: "[[16 - Herramientas y prevención de HTTP2 Downgrading]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

El [[14 - HTTP2 Downgrading|H2.CL/H2.TE]] básico requiere que el proxy arrastre un `CL`/`TE` mentido. Pero hay casos más sutiles: aunque el proxy valide `CL`/`TE`, se le puede **engañar para que inyecte un `TE`** aprovechando que HTTP/2 y HTTP/1.1 representan los datos de forma distinta. La clave es la misma [[01 - Introducción a CRLF Injection|CRLF injection]], ahora en la frontera de la reescritura.

# La grieta: CRLF que HTTP/2 permite y HTTP/1.1 no

<mark style="background: #ADCCFFA6;">En HTTP/1.1 una cabecera **no puede** contener `\r\n` (terminaría la cabecera). En HTTP/2, al ser **binario**, un valor de cabecera puede contener `\r\n` sin significado especial</mark>. El RFC de HTTP/2 (§8.2.1) **obliga** a validar esto para prevenir smuggling — prohíbe `CR`, `LF`, `NUL` en valores, `:` y mayúsculas/espacios en nombres, etc. — y a **no reenviar** peticiones que lo violen. Si el proxy **no** valida y reescribe a HTTP/1.1, ese `\r\n` <mark style="background: #8000E1A6;">se convierte en un **separador de cabeceras**</mark> y puedes inyectar un `Transfer-Encoding` de la nada → H2.TE.

# Tres puntos de inyección

**1. Inyección en el valor de una cabecera.** Un header HTTP/2 `dummy` con valor `asd\r\nTransfer-Encoding: chunked`:

```text
:method POST · :path / · :authority http2.htb
dummy:  asd\r\nTransfer-Encoding: chunked
```
Al degradar a HTTP/1.1, el `\r\n` parte el valor en dos cabeceras:
```http
POST / HTTP/1.1
Dummy: asd
Transfer-Encoding: chunked      ← inyectada
Content-Length: 48

0

GET /smuggled HTTP/1.1
```
El servidor da precedencia al `TE` → H2.TE.

**2. Inyección en el nombre de una cabecera.** Igual, pero el `\r\n` va en el **nombre**: header `dummy: asd\r\nTransfer-Encoding` con valor `chunked`. Mismo resultado tras la reescritura.

**3. Inyección en la request line (pseudo-headers).** <mark style="background: #FF5582A6;">Los pseudo-headers son especiales y a menudo **escapan a la validación**</mark>. Metiendo el CRLF en `:method`:

```text
:method  POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\nDummy: asd
:path /  · :authority http2.htb · :scheme http
```
Al reescribir:
```http
POST / HTTP/1.1
Transfer-Encoding: chunked        ← inyectada vía :method
Dummy: asd / HTTP/1.1
Host: http2.htb
Content-Length: 48

0

GET /smuggled HTTP/1.1
```
De nuevo H2.TE, esta vez inyectando el `TE` desde el propio método.

> [!important] Por qué probar SIEMPRE los pseudo-headers
> Muchos proxies validan las cabeceras normales pero <mark style="background: #FFB8EBA6;">tratan los pseudo-headers (`:method`, `:path`, `:authority`, `:scheme`) por un camino distinto</mark> donde la validación de CRLF puede faltar. Inyectar en `:path` o `:authority` no solo abre smuggling: puede envenenar el enrutamiento, la [[01 - Introducción a Web Cache Poisoning|caché]] (el `:authority` es el `Host`) o saltarse controles de acceso por ruta. Es de los rincones más fértiles del HTTP/2 moderno.

> [!info] La conexión con el bloque CRLF
> Esto es [[03 - HTTP Response Splitting|CRLF injection]] llevada a la capa de transporte: el mismo `\r\n` que inyecta cabeceras en una respuesta, aquí inyecta cabeceras **entre dos protocolos**. HTTP/2 lo permite, HTTP/1.1 lo interpreta, y en la costura entre ambos aparece el bug. Es la investigación de **James Kettle** *HTTP/2: The Sequel is Always Worse* (2021), que catalogó estos vectores contra objetivos reales enormes.

Detección y prevención de todo el bloque HTTP/2, en [[16 - Herramientas y prevención de HTTP2 Downgrading]].

## Referencias

- [James Kettle — HTTP/2: The Sequel is Always Worse (2021)](https://portswigger.net/research/http2)
- [RFC 9113 §8.2.1 — Field Validity](https://www.rfc-editor.org/rfc/rfc9113#section-8.2.1)
