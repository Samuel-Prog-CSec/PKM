---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP
  - Tipo/Introduccion
Descripción: "Este módulo ataca el protocolo HTTP en sí cuando varios sistemas —navegador, proxy inverso, servidor— lo interpretan de forma inconsistente"
Fecha de actualización: 2026-07-14
Nota previa: ""
Nota siguiente: "[[01 - Introducción a CRLF Injection]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Este módulo ataca el **protocolo HTTP en sí** cuando varios sistemas —navegador, proxy inverso, servidor— lo interpretan de forma **inconsistente**. Es el terreno más rentable de todo el path para bug bounty: los desync attacks comprometen a otros usuarios y saltan WAFs. Cubre tres vectores: [[01 - Introducción a CRLF Injection|CRLF Injection]], [[06 - Introducción a HTTP Request Smuggling|Request Smuggling/Desync]] y [[13 - Introducción a HTTP2|HTTP/2 Downgrading]].

# El concepto raíz: ¿dónde acaba una petición?

[[HTTP]]/1.1 reutiliza un mismo socket `TCP` para enviar **varias** peticiones y respuestas seguidas (`keep-alive`), por rendimiento. Eso obliga al servidor a saber **dónde termina** cada petición para empezar a leer la siguiente. Hay dos formas de declarar la longitud del cuerpo, y ahí está toda la munición del módulo:

| Cabecera | Cómo declara la longitud |
| - | - |
| `Content-Length` | Longitud exacta del cuerpo **en bytes** |
| `Transfer-Encoding: chunked` | El cuerpo llega en **trozos** (`chunks`), cada uno con su tamaño en hex, terminando en un chunk de tamaño `0` |

<mark style="background: #FFB86CA6;">Cuando dos sistemas de la cadena (el proxy y el servidor) discrepan sobre **cuál** de las dos obedecer, o sobre cómo parsearlas, la frontera entre peticiones se desincroniza</mark> — y una parte de "tu" petición se interpreta como el principio de la petición de **otro** usuario. Eso es el [[06 - Introducción a HTTP Request Smuggling|Request Smuggling]].

# HTTP/2 cambia las reglas

[[HTTP]]/2 es **binario** (no basado en texto como HTTP/1.1) y lleva un **mecanismo interno** de longitud, lo que elimina la ambigüedad `CL`/`TE` de raíz. En teoría, HTTP/2 mata el smuggling. El problema: <mark style="background: #FFB8EBA6;">muchos despliegues hablan HTTP/2 en el **front-end** pero **reescriben** a HTTP/1.1 hacia el back-end</mark>. Esa reescritura (`HTTP/2 downgrading`) reintroduce la ambigüedad — el [[13 - Introducción a HTTP2|HTTP/2 Downgrading]].

# Los tres ataques

- **CRLF Injection**: los caracteres de control `CR` (`\r`, Carriage Return) y `LF` (`\n`, Line Feed) marcan el fin de línea en HTTP. Si la app no los **sanea** en la entrada del usuario, el atacante inyecta líneas nuevas y <mark style="background: #FFB86CA6;">manipula cabeceras, logs o respuestas</mark>. Impacto variable, desde envenenar logs hasta [[03 - HTTP Response Splitting|response splitting]].
- **HTTP Request Smuggling / Desync**: la desincronización proxy↔servidor descrita arriba. <mark style="background: #FFB86CA6;">Permite saltar WAFs y controles, y comprometer a otros usuarios</mark> inyectando en sus peticiones. Es el ataque estrella del módulo.
- **HTTP/2 Downgrading**: smuggling que aprovecha la reescritura HTTP/2→HTTP/1.1 en el borde.

> [!info] Contexto: la investigación de James Kettle
> El request smuggling moderno lo (re)definió **James Kettle (PortSwigger)** con *HTTP Desync Attacks* (2019) y trabajos posteriores (*Browser-Powered Desync*, *HTTP/2 smuggling*). Es de los campos más activos del web hacking y de los mejor pagados en bug bounty, porque un solo desync puede afectar a **todos** los usuarios de un sitio. Buena parte del enriquecimiento de estas notas viene de ahí, ya que el material de HTB tiene años y no cubre las técnicas más recientes.

El prerrequisito conceptual —`keep-alive`, `Content-Length`, `Transfer-Encoding`, HTTP/2— está en [[HTTP]]. No hace falta haber hecho el módulo de [[00 - Introducción a las HTTP Misconfigurations|HTTP Misconfigurations]], aunque comparten filosofía: atacar la **infraestructura**, no la lógica de la app.

## Referencias

- [PortSwigger — HTTP request smuggling](https://portswigger.net/web-security/request-smuggling)
- [James Kettle — HTTP Desync Attacks (2019)](https://portswigger.net/research/http-desync-attacks-request-smuggling-reborn)
- HTB Academy — *HTTP Attacks* (módulo base de estas notas)
