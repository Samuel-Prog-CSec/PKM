---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "La función estrella del proxy: pausar una petición HTTP en vuelo, examinarla, modificarla y reenviarla"
Fecha de actualización: 2026-06-23
Nota previa: "[[01 - Instalación y configuración del proxy]]"
Nota siguiente: "[[03 - Interceptación de respuestas]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

La función estrella del proxy: <mark style="background: #ADCCFFA6;">pausar una petición HTTP en vuelo, examinarla, modificarla y reenviarla.</mark> Esto es lo que convierte al proxy en la herramienta central del pentesting web — porque te deja saltarte por completo las restricciones del navegador y hablar directamente con el back-end.

# Burp

En la pestaña `Proxy > Intercept`, la interceptación suele venir activada (`Intercept is on`). Con ella activa, navegas al objetivo desde el [[01 - Instalación y configuración del proxy|navegador preconfigurado]] y la petición queda **retenida** en Burp esperando tu acción: `Forward` (enviarla) o `Drop` (descartarla).

![Petición HTTP interceptada en la pestaña Proxy de Burp, con los botones Forward, Drop, Intercept is on, Action y Open Browser.](https://academy.hackthebox.com/storage/modules/110/burp_intercept_page.png)

> [!warning]+ El navegador genera mucho ruido
> Con la interceptación activa, **toda** petición de Firefox se retiene — telemetría, favicons, recursos. Verás peticiones irrelevantes antes de la tuya; pulsa `Forward` hasta llegar a la del objetivo. <mark style="background: #FFB86CA6;">Por eso los profesionales rara vez navegan con `Intercept` siempre activo</mark>: navegan con él **desactivado**, dejan que todo el tráfico caiga en `HTTP history`, y desde ahí mandan a [[05 - Repeater - repetir y modificar peticiones|Repeater]] solo lo que les interesa. Interceptar se reserva para cuando necesitas modificar una petición concreta *antes* de que salga.

# ZAP

En ZAP la interceptación está **desactivada** por defecto (botón verde = el tráfico pasa). Se conmuta con el botón o con `CTRL+B`. Al interceptar, eliges `Step` (enviar y romper en la siguiente) o `Continue` (dejar pasar el resto). ZAP añade el **HUD** (*Heads Up Display*), que controla la interceptación desde el propio navegador, superpuesto a la página.

# Manipular la petición: saltarse el cliente

Aquí está el porqué de todo. El ejemplo canónico: un campo `IP` que el JavaScript front-end **solo deja rellenar con números**. Interceptas el `Ping` y ves la petición real:

```http
POST /ping HTTP/1.1
Host: target:32306
Content-Type: application/x-www-form-urlencoded

ip=1
```

<mark style="background: #8000E1A6;">La validación de JavaScript vive en el navegador; la petición interceptada ya está fuera de su alcance.</mark> Cambias `ip=1` por `ip=;ls;` y reenvías — si el back-end no valida, ejecuta el comando:

![Resultado de la inyección: la respuesta cambia de la salida de ping a un listado de ficheros (flag.txt, index.html, server.js...), confirmando command injection.](https://academy.hackthebox.com/storage/modules/110/ping_inject.jpg)

> [!important]+ La lección que sostiene todo el hacking web
> <mark style="background: #FF5582A6;">Cualquier control de seguridad implementado **solo en el cliente** (validación JS, campos `maxlength`, listas desplegables) es decorativo</mark>: el proxy lo elude trivialmente. La seguridad real está en el back-end. Esta capacidad de interceptar-modificar habilita el testing de casi todo el PKM: [[01 - Detección de SQL Injection|SQLi]], [[00 - Introducción a Command Injection|command injection]], [[02 - Bypass de validación en cliente|bypass de subida de ficheros]], [[09 - Bypass de autenticación - modificación de parámetros|bypass de autenticación]], [[00 - Introducción a XSS|XSS]], `XXE`, deserialización...

El módulo no profundiza en esos ataques (los cubren sus propios sub-temas) — aquí importa la **mecánica** del proxy que los hace todos posibles.

> [!info]+ Fuentes
> - [PortSwigger — Intercepting HTTP requests](https://portswigger.net/burp/documentation/desktop/getting-started/intercepting-http-requests)
