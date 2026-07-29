---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/CRLF
Descripción: "El HTTP Response Splitting es la variante grave de CRLF injection: cuando el servidor refleja input en una cabecera de respuesta sin sanear, inyectar \r\n rompe la cabecera…"
Fecha de actualización: 2026-07-14
Nota previa: "[[02 - Log Injection]]"
Nota siguiente: "[[04 - SMTP Header Injection]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

El **HTTP Response Splitting** es la variante grave de [[01 - Introducción a CRLF Injection|CRLF injection]]: cuando el servidor refleja input en una **cabecera de respuesta** sin sanear, inyectar `\r\n` <mark style="background: #ADCCFFA6;">rompe la cabecera prevista y permite añadir cabeceras arbitrarias e incluso **controlar el cuerpo** de la respuesta</mark>. El resultado directo es un XSS reflejado, pero da para mucho más.

# Identificación

Un servicio de redirección pone el dominio del usuario en la cabecera `Refresh` (carga la URL tras N segundos). Se confirma que no hay sanitización inyectando CRLF y añadiendo una cabecera propia:

```http
GET /?target=http%3A%2F%2Fhackthebox.com%0d%0aTest:%20test HTTP/1.1
Host: responsesplitting.htb
```

Si la respuesta incluye `Test: test` como **cabecera real**, el salto de línea se procesó → response splitting.

# Explotación: XSS controlando el cuerpo

Como puedo añadir líneas a la sección de cabeceras, con **dos** saltos de línea (`%0d%0a%0d%0a`) cierro las cabeceras y empiezo el **cuerpo**, donde meto el XSS:

```http
GET /?target=http%3A%2F%2Fhackthebox.com%0d%0a%0d%0a<html><script>alert(1)</script></html> HTTP/1.1
Host: responsesplitting.htb
```

<mark style="background: #FFB86CA6;">La página original se añade después, pero eso no impide que mi JavaScript se ejecute</mark>. Controlo la respuesta entera sin restricciones.

# El caso del redirect 302 (Location)

Es más común una redirección con `302` + cabecera `Location` que con `Refresh`. Ahí el navegador **redirige de inmediato** e ignora el cuerpo, así que el payload anterior no ejecuta. El truco: <mark style="background: #FF5582A6;">inyectar un `Location` **vacío**</mark>:

```http
GET /?target=%0d%0a%0d%0a<html><script>alert(1)</script></html> HTTP/1.1
Host: responsesplitting.htb
```

Un `Location` vacío es inválido, el navegador no sabe a dónde ir y **muestra el cuerpo** → el XSS ejecuta.

> [!warning] Comportamiento dependiente del navegador
> Este truco del `Location` vacío ejecuta en **Chromium** pero en **Firefox** da un error de redirección. Los ataques de response splitting son sensibles al parser del navegador y del servidor; siempre prueba en varios. La misma sensibilidad hace que el response splitting "clásico" esté **mitigado** en la mayoría de servidores modernos, que **rechazan** `CR`/`LF` crudos en cabeceras — pero sigue apareciendo en servicios de redirect, cabeceras custom y setups con proxy.

# Más allá del XSS

Controlar la respuesta abre otros impactos:

- **Defacement**: inyectar HTML arbitrario.
- **Escalado con [[01 - Introducción a Web Cache Poisoning|cache poisoning]]**: si la respuesta partida se **cachea**, el XSS se sirve a **todos** los usuarios (impacto masivo, sin interacción).
- <mark style="background: #FFB86CA6;">**Bypass de cabeceras de seguridad**</mark>: si la app usa cabeceras para protegerse ([[04 - Content Security Policy (CSP)|CSP]], `X-Frame-Options` anti-[[08 - Clickjacking|clickjacking]]), el response splitting permite **inyectar o sobrescribir** esas cabeceras — colar un CSP permisivo o eliminar el anti-framing, desactivando la defensa que bloqueaba tu XSS.

# Detección y prevención

- **Detección**: inyecta `%0d%0a` en cada input reflejado en cabeceras (`Location`, `Refresh`, `Set-Cookie`, custom); busca cabeceras nuevas o cuerpo controlado.
- **Prevención**: **sanear/rechazar `CR` y `LF`** en cualquier valor que vaya a una cabecera; usar las funciones de redirect del framework (bloquean CRLF); no reflejar input crudo en cabeceras.

## Referencias

- [OWASP — HTTP Response Splitting](https://owasp.org/www-community/attacks/HTTP_Response_Splitting)
- [PortSwigger — HTTP response header injection](https://portswigger.net/kb/issues/00200200_http-response-header-injection)
