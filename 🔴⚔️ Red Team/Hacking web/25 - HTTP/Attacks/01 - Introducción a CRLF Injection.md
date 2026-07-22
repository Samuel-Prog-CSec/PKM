---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/CRLF
Fecha de actualización: 2026-07-14
Nota previa: "[[00 - Introducción a los HTTP Attacks]]"
Nota siguiente: "[[02 - Log Injection]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

La **CRLF Injection** consiste en inyectar **saltos de línea** en un contexto donde el inicio de una nueva línea tiene <mark style="background: #FFB8EBA6;">significado semántico</mark> y la aplicación no sanea la entrada. Muchos protocolos y formatos (HTTP, SMTP, logs) separan sus elementos con una nueva línea, así que colar un salto de línea permite **inyectar elementos nuevos** — cabeceras, entradas de log, líneas de protocolo.

# Los dos caracteres

`CRLF` combina dos caracteres de control:

| Carácter | Símbolo | ASCII | Hex | URL-encoded |
| - | - | - | - | - |
| **CR** (Carriage Return) | `\r` | 13 | `0x0D` | `%0D` |
| **LF** (Line Feed) | `\n` | 10 | `0x0A` | `%0A` |

`CR` devuelve el cursor al inicio de la línea; `LF` lo baja a la siguiente. Juntos (`\r\n` / `%0d%0a`) <mark style="background: #ADCCFFA6;">denotan el inicio de una nueva línea</mark>. En HTTP, las cabeceras se separan **exactamente** con `\r\n`, y una línea en blanco (`\r\n\r\n`) separa cabeceras de cuerpo.

# Dónde aparece

Surge donde una entrada del usuario **mal saneada** acaba en un contexto sensible a los saltos de línea:

- **Cabeceras HTTP**: input reflejado en una cabecera de respuesta (`Location`, `Set-Cookie`, cabeceras custom).
- **Ficheros de log**: input escrito a un log.
- **Cabeceras SMTP**: input que fija el remitente/asunto de un email.

La entrada suele venir de barras de búsqueda, formularios de comentarios o **parámetros GET**.

# Impacto según el contexto

Los caracteres en sí son inofensivos; el daño viene de <mark style="background: #8000E1A6;">alterar la **semántica** del mensaje</mark>:

- **Inyección de cabeceras HTTP → XSS**: si la app refleja tu input en una cabecera sin sanear `CR`/`LF`, inyectas cabeceras arbitrarias en la respuesta y, escribiendo `\r\n\r\n` seguido de HTML, **partes la respuesta** y controlas el cuerpo → [[03 - HTTP Response Splitting|HTTP Response Splitting]] y XSS reflejado. Combinado con [[01 - Introducción a Web Cache Poisoning|cache poisoning]], se sirve a muchos usuarios.
- **[[02 - Log Injection|Log forging]]**: inyectar saltos de línea permite **falsificar entradas de log**, invalidando la trazabilidad (el admin no sabe qué es real). Por sí solo es de severidad baja.
- **[[04 - SMTP Header Injection|Inyección de cabeceras SMTP]]**: colar cabeceras SMTP arbitrarias (añadir `Bcc`, cambiar remitente) en formularios que generan emails.

<mark style="background: #FFB86CA6;">El impacto va de un problema menor (log forging) a uno serio (XSS masivo vía response splitting)</mark>, según la app y el contexto.

# Detección

La técnica base: inyectar la secuencia CRLF URL-encodeada en **cada** parámetro reflejado y observar si aparece una línea/cabecera nueva en la respuesta:

```http
GET /page?param=value%0d%0aInjected-Header:%20true HTTP/1.1
```

Si la respuesta incluye `Injected-Header: true` como cabecera real, hay CRLF injection. Variantes a probar cuando el filtro bloquea `%0d%0a`:

```text
%0d%0a      (CRLF estándar)
%0a         (solo LF — muchos parsers lo aceptan)
%0d         (solo CR)
%23%0d%0a   (con un # delante)
%E5%98%8D%E5%98%8A   (bytes Unicode que algunos backends normalizan a \r\n)
```

> [!warning] Estado moderno: más difícil, no muerto
> Los servidores y frameworks modernos suelen **rechazar** `CR`/`LF` crudos en cabeceras, así que el CRLF "clásico" en respuestas está mitigado en muchos stacks. Pero sigue vivo en: cabeceras `Location` de redirects, `Set-Cookie`, cabeceras generadas por **proxies inversos** mal configurados, y — el más relevante hoy — como pieza del [[06 - Introducción a HTTP Request Smuggling|request smuggling]], donde inyectar `\r\n` en el sitio justo desincroniza proxy y servidor. En bug bounty, CRLF suele encadenarse (open redirect, cache poisoning, smuggling) más que explotarse solo.

Las siguientes notas desarrollan cada contexto: [[02 - Log Injection|logs]], [[03 - HTTP Response Splitting|response splitting]] y [[04 - SMTP Header Injection|SMTP]].

## Referencias

- [OWASP — CRLF Injection](https://owasp.org/www-community/vulnerabilities/CRLF_Injection)
- [PortSwigger — HTTP response header injection](https://portswigger.net/kb/issues/00200200_http-response-header-injection)
