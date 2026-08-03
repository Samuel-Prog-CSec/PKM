---
tags:
  - Redes
  - Protocolos
  - HTTP
  - Web
Descripción: "El Hypertext Transfer Protocol (HTTP) es el protocolo de la capa de aplicación sobre el que se construye la web"
Fecha de actualización: 2026-07-14
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

El **Hypertext Transfer Protocol (HTTP)** es el protocolo de la **capa de aplicación** sobre el que se construye la web. Sigue un modelo ==cliente-servidor de petición-respuesta==: el cliente (navegador, `curl`, Burp) abre una conexión `TCP` al **puerto 80** por defecto, envía una petición, y el servidor responde. HTTP es ==**stateless**== (sin estado): cada petición es independiente y el servidor no recuerda nada de las anteriores por sí mismo — el estado se simula con **cookies** y sesiones.

Su característica más relevante para seguridad: ==HTTP transmite todo en **texto plano**==. No ofrece confidencialidad, integridad ni autenticidad. Cualquiera en la ruta (un proxy, un router, un atacante en la misma red) puede leer y modificar el tráfico. Esa carencia es exactamente lo que resuelve [[HTTPS]] envolviendo HTTP dentro de `TLS`.

# Estructura de una petición HTTP

Una petición se compone de una **línea de petición** (`request line`), un bloque de **cabeceras** (`headers`), una línea en blanco, y un **cuerpo** opcional (`body`).

```http
POST /login HTTP/1.1
Host: target.htb
User-Agent: Mozilla/5.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 29
Cookie: session=abc123

username=admin&password=admin
```

- **Método** (`POST`): la acción a realizar.
- **Ruta** (`/login`): el recurso solicitado, parte de la URL.
- **Versión** (`HTTP/1.1`): la versión del protocolo.
- **Cabeceras**: metadatos clave-valor. La cabecera `Host` es **obligatoria** desde HTTP/1.1 (permite *virtual hosting*: varios sitios en una misma IP).
- **Cuerpo**: datos enviados (formularios, JSON, ficheros). Su longitud se declara con `Content-Length` o se trocea con `Transfer-Encoding: chunked`.

> [!info] La ambigüedad `Content-Length` vs `Transfer-Encoding`
> Cuando ambas cabeceras coexisten y distintos servidores de la cadena (front-end/back-end) discrepan sobre cuál obedecer, aparece el **[[06 - Introducción a HTTP Request Smuggling|HTTP Request Smuggling]]**. Es un ejemplo perfecto de cómo un detalle "aburrido" del parsing HTTP se convierte en una vulnerabilidad crítica.

# Estructura de una respuesta HTTP

```http
HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html; charset=UTF-8
Content-Length: 1256
Set-Cookie: session=abc123; HttpOnly; Secure

<!DOCTYPE html>...
```

La **línea de estado** (`status line`) lleva la versión, un **código de estado** numérico y su frase.

# Métodos HTTP

| Método | Uso | Notas de seguridad |
| - | - | - |
| `GET` | Solicitar un recurso | Parámetros en la URL → quedan en logs, historial, `Referer` |
| `POST` | Enviar datos (crear) | Cuerpo no queda en la URL, pero no implica seguridad |
| `PUT` | Crear/reemplazar un recurso | Si está activo sin control → subida de `web shells` |
| `DELETE` | Borrar un recurso | Peligroso si no hay autorización |
| `HEAD` | Como `GET` pero solo cabeceras | Enumeración silenciosa |
| `OPTIONS` | Métodos permitidos | Revela superficie (`Allow:`) |
| `PATCH` | Modificación parcial | — |
| `TRACE` | Eco de la petición | Ligado a *Cross-Site Tracing* (histórico) |

Los ==métodos "peligrosos" (`PUT`, `DELETE`, `TRACE`) habilitados por descuido== son un hallazgo clásico de enumeración web. La manipulación del método (*HTTP verb tampering*) permite a veces saltarse controles de acceso que solo filtran `GET`/`POST`.

# Códigos de estado

| Rango | Categoría | Ejemplos clave |
| - | - | - |
| `1xx` | Informativo | `101 Switching Protocols` (WebSockets, upgrade) |
| `2xx` | Éxito | `200 OK`, `201 Created`, `204 No Content` |
| `3xx` | Redirección | `301`/`302` (redirect), `304 Not Modified` |
| `4xx` | Error del cliente | `401` (no autenticado), `403` (prohibido), `404`, `429` (rate limit) |
| `5xx` | Error del servidor | `500`, `502 Bad Gateway`, `503` |

En pentesting los códigos son ==oráculos de información==: diferenciar un `401` de un `403`, o un `200` de un `302`, revela si un usuario existe, si un recurso está protegido o si un `bypass` funcionó. El *fuzzing* de directorios se basa por completo en interpretar estos códigos.

# Cabeceras que importan

**De petición**:
- `Host`: el *virtual host* destino. Manipularlo abre los [[06 - Introducción a los Host Header Attacks|Host Header Attacks]].
- `Cookie`: transporta la sesión.
- `Authorization`: credenciales (`Basic`, `Bearer <token>`).
- `Referer` / `Origin`: de dónde viene la petición. Base de las decisiones de `CORS` y de muchas defensas [[01 - Fundamentos y defensas de CSRF|anti-CSRF]].
- `X-Forwarded-For`, `X-Forwarded-Host`: cabeceras de proxy, a menudo confiadas ciegamente → *spoofing* de IP y ataques de Host indirectos.

**De respuesta / seguridad**:
- `Set-Cookie`: crea cookies. Los flags `HttpOnly`, `Secure`, `SameSite` deciden su exposición.
- `Location`: destino de una redirección.
- `Strict-Transport-Security` (HSTS): fuerza HTTPS, mitiga [[08 - SSL Stripping|SSL Stripping]].
- `Content-Security-Policy` (CSP): mitiga [[00 - Introducción a XSS|XSS]].
- `Cache-Control`, `Vary`, `Age`: gobiernan el cacheo — nucleares para el [[01 - Introducción a Web Cache Poisoning|Web Cache Poisoning]].

# Statelessness, cookies y sesiones

Como HTTP no recuerda nada, la sesión se mantiene con un identificador que el servidor emite (`Set-Cookie: session=...`) y el navegador reenvía en cada petición. ==Toda la seguridad de la autenticación web descansa sobre la confidencialidad e imprevisibilidad de ese identificador==. De ahí que el robo de sesión (vía [[00 - Introducción a XSS|XSS]], `sniffing` sobre HTTP plano, o [[12 - Introducción a Session Puzzling|Session Puzzling]]) sea tan crítico.

# Versiones del protocolo

- **HTTP/0.9** (1991): una sola línea, solo `GET`, sin cabeceras.
- **HTTP/1.0** (1996): cabeceras, códigos de estado, `POST`.
- **HTTP/1.1** (1997): ==`Host` obligatorio, conexiones persistentes (`keep-alive`), *pipelining*, `chunked` transfer==. Es la base del texto plano que sigue circulando internamente entre proxies aún hoy.
- **HTTP/2** (2015): ==**binario** (no texto), multiplexación de streams sobre una conexión, compresión de cabeceras `HPACK`==. Elimina de raíz muchas ambigüedades de HTTP/1.1, pero cuando un front-end HTTP/2 reescribe a HTTP/1.1 hacia el back-end aparece el [[13 - Introducción a HTTP2|HTTP/2 Downgrading]].
- **HTTP/3** (2022): sobre **QUIC** (UDP + TLS 1.3 integrado), no TCP. Reduce latencia y elimina el *head-of-line blocking*.

> [!important] Por qué el pentester debe dominar el HTTP "de bajo nivel"
> La mayoría de vulnerabilidades web no están en la lógica de la aplicación, sino en **cómo se parsea e interpreta el propio HTTP**: discrepancias de `Content-Length`/`Transfer-Encoding` (smuggling), inyección de `\r\n` en cabeceras ([[01 - Introducción a CRLF Injection|CRLF Injection]]), confianza ciega en `Host`, cacheo de respuestas envenenadas. Entender la estructura exacta de una petición/respuesta es el prerrequisito de todo el módulo [[00 - Introducción a los HTTP Attacks|HTTP Attacks]].

# Ver también

- [[HTTPS]] — HTTP sobre `TLS`: cómo se resuelve el problema del texto plano.
- [[00 - Introducción a los HTTP Attacks|HTTP Attacks]] — CRLF, Request Smuggling, HTTP/2 Downgrading.
- [[00 - Introducción a las HTTP Misconfigurations|HTTP Misconfigurations]] — Cache Poisoning, Host Header, Session Puzzling.

## Referencias

- [RFC 9110 — HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110) (reemplaza al histórico RFC 2616)
- [MDN Web Docs — HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP)
