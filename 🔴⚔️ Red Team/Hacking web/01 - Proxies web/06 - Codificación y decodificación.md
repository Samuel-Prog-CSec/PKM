---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "Al construir peticiones a mano, los datos deben ir en el encoding que el servidor espera, o la petición se rompe"
Fecha de actualización: 2026-06-23
Nota previa: "[[05 - Repeater - repetir y modificar peticiones]]"
Nota siguiente: "[[07 - Proxying de herramientas]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Al construir peticiones a mano, los datos deben ir en el encoding que el servidor espera, o la petición se rompe. Y al revés: las apps codifican datos (cookies, tokens, parámetros) que hay que decodificar para entenderlos y manipularlos. Ambos proxies traen codificadores integrados para no salir de la herramienta.

# URL encoding: el imprescindible

<mark style="background: #ADCCFFA6;">Los datos de una petición deben estar URL-encoded</mark> o el servidor los malinterpreta. Caracteres que **hay que** codificar:

| Carácter | Si no se codifica… |
| - | - |
| Espacio | puede marcar el fin de los datos |
| `&` | se interpreta como separador de parámetros |
| `#` | se interpreta como fragmento |

En Burp Repeater: selecciona el texto y `CTRL+U` (o clic derecho → `Convert Selection > URL > URL-encode key characters`). Burp puede además URL-encodear **mientras escribes** (clic derecho → activar la opción). ZAP URL-encodea automáticamente en segundo plano.

# Decodificar lo que devuelve la app

`Decoder` en Burp (o el más moderno **`Burp Inspector`**, integrado en Proxy y Repeater) y `Encoder/Decoder/Hash` en ZAP (`CTRL+E`) manejan los encodings habituales: **Base64, URL, HTML, Unicode, ASCII hex**. El caso clásico — una cookie en base64:

```text
eyJ1c2VybmFtZSI6Imd1ZXN0IiwgImlzX2FkbWluIjpmYWxzZX0=
```

`Decode as > Base64` revela:

![Burp Decoder mostrando la cadena base64 y su salida JSON decodificada con username guest e is_admin false.](https://academy.hackthebox.com/storage/modules/110/burp_b64_decode.png)

# Codificar de vuelta: el ataque

La decodificación revela `{"username":"guest", "is_admin":false}`. <mark style="background: #FFB86CA6;">Si una cookie lleva el rol sin firmar, lo manipulas y lo re-codificas</mark>: cambias `guest`→`admin` y `false`→`true`, lo vuelves a base64, y lo usas en la petición desde [[05 - Repeater - repetir y modificar peticiones|Repeater]]:

```text
{"username":"admin", "is_admin":true}  →  base64  →  cookie forjada
```

<mark style="background: #8000E1A6;">Esto es exactamente un [[10 - Ataques a tokens de sesión|ataque a token de sesión]]</mark>: el proxy es la herramienta con la que lo ejecutas. Si la cookie estuviera firmada (un [[01 - Introducción a JWT|JWT]]), re-codificarla no bastaría — necesitarías romper la firma.

> [!info]+ CyberChef cuando el encoding se complica
> Para cadenas con **múltiples capas** (base64 → gzip → URL, o cifrado) el Decoder de Burp se queda corto. <mark style="background: #FFB86CA6;">`CyberChef`</mark> (la "navaja suiza" de GCHQ) encadena decenas de operaciones con su `Magic` que detecta el encoding automáticamente. Es el complemento estándar al Decoder del proxy. Burp Decoder permite re-codificar la salida directamente con otro codificador en el panel inferior.

> [!info]+ Fuentes
> - [PortSwigger — Burp Inspector / Decoder](https://portswigger.net/burp/documentation/desktop/tools/inspector) · [CyberChef](https://gchq.github.io/CyberChef/)
