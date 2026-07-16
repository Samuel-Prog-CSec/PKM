---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/H2
Fecha de actualización: 2026-07-14
Nota previa: "[[12 - Herramientas y prevención de Request Smuggling]]"
Nota siguiente: "[[14 - HTTP2 Downgrading]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

[[HTTP]]/2 (2015) reduce latencia y mejora rendimiento, y —clave para este bloque— <mark style="background: #FFB86CA6;">**cierra de raíz el [[06 - Introducción a HTTP Request Smuggling|request smuggling]]**</mark> cuando se usa bien. El problema, que veremos en la siguiente nota, es cuando se **degrada** a HTTP/1.1 por detrás. Primero hay que entender por qué HTTP/2 es inmune al smuggling.

# Qué cambia en HTTP/2

Es **totalmente compatible** con HTTP/1.1 a nivel conceptual: siguen existiendo métodos, cabeceras y rutas. Lo que cambia es **cómo viajan los datos**:

- <mark style="background: #ADCCFFA6;">HTTP/1.1 es un protocolo **basado en texto**; HTTP/2 es **binario**</mark> (como TCP), no legible por humanos. Por eso en Burp no notas diferencia — Burp te muestra las peticiones HTTP/2 en formato HTTP/1.1 por comodidad.
- **Multiplexación**: varios streams sobre una conexión sin bloqueo *head-of-line* de HTTP/1.1.
- **Compresión de cabeceras** (`HPACK`).
- **Server push** (el servidor manda recursos estáticos sin que el cliente los pida). *Nota moderna: Chrome lo **deprecó y retiró** en 2022 por poco útil.*

# Pseudo-headers

En HTTP/2, la línea de petición de HTTP/1.1 se sustituye por **pseudo-headers** (empiezan por `:`):

```http
# HTTP/1.1
GET /index.php HTTP/1.1
Host: http2.htb
```
```text
# HTTP/2 (equivalente)
:method   GET
:path     /index.php
:authority http2.htb
:scheme   http
```

| Pseudo-header | Equivale a |
| - | - |
| `:method` | El método HTTP |
| `:scheme` | El esquema (`http`/`https`) |
| `:authority` | La cabecera `Host` |
| `:path` | La ruta + query string |

En Burp Repeater, estos pseudo-headers se ven y editan en el **Inspector**. Poder manipularlos a bajo nivel es lo que habilita los ataques de la siguiente nota.

# Por qué HTTP/2 mata el smuggling

Dos cambios lo hacen inmune a la ambigüedad de longitud que explota el [[06 - Introducción a HTTP Request Smuggling|smuggling]]:

1. <mark style="background: #ADCCFFA6;">El **chunked encoding** (`Transfer-Encoding: chunked`) **NO** está permitido en HTTP/2</mark> (lo prohíbe el RFC).
2. El cuerpo viaja en **DATA frames binarios**, cada uno con un **campo de longitud incorporado**. No hace falta `Content-Length` para saber dónde acaba la petición.

<mark style="background: #8000E1A6;">Sin `CL` vs `TE` que puedan discrepar, no hay dos formas de interpretar la frontera de la petición</mark> → el smuggling es prácticamente imposible **si toda la cadena habla HTTP/2**.

> [!warning] El "si se usa correctamente" es la trampa
> HTTP/2 solo protege si se usa **extremo a extremo**. En cuanto un proxy inverso habla HTTP/2 con el cliente pero **reescribe a HTTP/1.1** hacia el servidor, la ambigüedad `CL`/`TE` **reaparece** durante esa reescritura. Ese es el [[14 - HTTP2 Downgrading|HTTP/2 Downgrading]], y es sorprendentemente común porque muchos back-ends aún no hablan HTTP/2. Además, HTTP/2 da al atacante una ventaja: puede enviar valores en los pseudo-headers y cabeceras que un cliente HTTP/1.1 **no podría** (bytes prohibidos, longitudes mentidas), y esa libertad se aprovecha al degradar.

> [!info] Estado actual
> HTTP/2 es hoy mayoritario en Internet, y su sucesor **HTTP/3** (sobre `QUIC`/UDP) ya está desplegado. Para el pentester, lo relevante es identificar **dónde ocurre la reescritura** HTTP/2→HTTP/1.1 en la cadena, porque ahí vive el bug.

## Referencias

- [RFC 9113 — HTTP/2](https://www.rfc-editor.org/rfc/rfc9113)
- [PortSwigger — HTTP/2 (Kettle research)](https://portswigger.net/research/http2)
