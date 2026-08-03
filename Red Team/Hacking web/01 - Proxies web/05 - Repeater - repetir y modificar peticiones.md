---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "Interceptar, modificar, reenviar y comprobar en el navegador son 5-6 pasos por cada intento"
Fecha de actualización: 2026-06-23
Nota previa: "[[04 - Modificación automática (Match and Replace)]]"
Nota siguiente: "[[06 - Codificación y decodificación]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Interceptar, modificar, reenviar y comprobar en el navegador son 5-6 pasos por cada intento. Para enumerar un sistema probando comando tras comando, es inviable. <mark style="background: #ADCCFFA6;">`Repeater` (Burp) y el `Request Editor` (ZAP) permiten reenviar cualquier petición ya capturada, modificarla al vuelo y ver la respuesta en la misma ventana</mark> — sin interceptar nada. Es donde el pentester pasa la mayor parte del tiempo.

# El historial: el punto de partida

Todo lo que pasa por el proxy queda en el **historial**: Burp en `Proxy > HTTP History`, ZAP en su pestaña `History`. Ambos filtran y ordenan (imprescindible cuando hay miles de peticiones).

![Historial HTTP de Burp con las peticiones POST/GET, sus códigos de estado, URL y tipo MIME.](https://academy.hackthebox.com/storage/modules/110/burp_history_tab.png)

> [!important]+ Original vs. editado (gotcha de Burp)
> Burp guarda **tanto** la petición original como la modificada; si editaste una, la cabecera del panel dice `Original Request` y puedes cambiar a `Edited Request` para ver lo que de verdad se envió. <mark style="background: #FFB8EBA6;">ZAP solo muestra la petición final.</mark> Ambos mantienen además historial de **WebSockets** (conexiones asíncronas tras la carga) — relevante en testing avanzado.

# Repeater (Burp)

Localiza la petición en el historial (o en cualquier sitio), `CTRL+R` para enviarla a `Repeater`, `CTRL+SHIFT+R` para ir a la pestaña, y `Send`. La respuesta aparece al lado. Modificas, reenvías, observas — el **bucle central** del testing manual:

![Pestaña Repeater de Burp con una petición POST a /ping modificada con command injection y la respuesta con el listado de ficheros.](https://academy.hackthebox.com/storage/modules/110/burp_repeat_modify.png)

<mark style="background: #8000E1A6;">Cambiar el comando y obtener su salida al instante</mark> convierte la enumeración por command injection en algo tan ágil como una shell. Atajo útil: clic derecho → `Change Request Method` alterna POST/GET sin reescribir la petición.

# Request Editor y HUD (ZAP)

En ZAP, clic derecho sobre la petición → `Open/Resend with Request Editor`, modificas y `Send`. El menú `Method` cambia el verbo HTTP. Desde el **HUD**, `Replay in Console` muestra la respuesta en la propia ventana, o `Replay in Browser` la renderiza.

> [!important]+ El flujo profesional real
> <mark style="background: #FF5582A6;">El 80% del hacking web manual es: navegar con interceptación **off** → encontrar la petición interesante en el historial → mandarla a Repeater → iterar payloads.</mark> Repeater es donde pruebas un `' OR 1=1`, ajustas un payload de [[00 - Introducción a XSS|XSS]], afinas un [[02 - Ataques a la verificación de firma JWT|JWT]] manipulado o reenvías el login para capturar dos tokens. Domínalo y casi todo lo demás es accesorio.

Como se ve en la petición `POST`, los datos van **URL-encoded** — manejar ese encoding correctamente es esencial y es lo siguiente.

> [!info]+ Fuentes
> - [PortSwigger — Burp Repeater](https://portswigger.net/burp/documentation/desktop/tools/repeater)
