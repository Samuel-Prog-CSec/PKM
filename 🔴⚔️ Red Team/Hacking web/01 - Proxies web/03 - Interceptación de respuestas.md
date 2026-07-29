---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "A veces el control que estorba no está en la petición sino en la respuesta: el HTML que el servidor manda trae campos deshabilitados, ocultos o con restricciones (maxlength…"
Fecha de actualización: 2026-06-23
Nota previa: "[[02 - Interceptación de peticiones]]"
Nota siguiente: "[[04 - Modificación automática (Match and Replace)]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

A veces el control que estorba no está en la petición sino en la **respuesta**: el HTML que el servidor manda trae campos deshabilitados, ocultos o con restricciones (`maxlength`, `type="number"`). <mark style="background: #ADCCFFA6;">Interceptar la respuesta antes de que llegue al navegador permite reescribir ese HTML y cambiar cómo se renderiza la página.</mark>

# Burp

La interceptación de respuestas no viene activada: se habilita en `Proxy > Proxy settings > Response interception rules` (`Intercept responses`). Con ella activa, reenvías la petición (`CTRL+SHIFT+R` para forzar recarga completa) y Burp te entrega la **respuesta** para editar. En el ejemplo del campo `IP`, reescribes el HTML:

```html
<input type="text" id="ip" name="ip" maxlength="100" ...>
```

Cambiar `type="number"` → `type="text"` y `maxlength="3"` → `maxlength="100"` <mark style="background: #FFB86CA6;">desactiva la restricción de cliente directamente en la página</mark>: ahora escribes el payload en el propio campo del navegador, sin interceptar cada petición.

# ZAP: el HUD lo hace en un clic

En ZAP, `Step` intercepta la respuesta tras la petición y la editas igual. Pero el **HUD** tiene un atajo potente para el caso más común — habilitar campos sin tocar el HTML a mano:

- <mark style="background: #FFB86CA6;">**Show/Enable fields**</mark> (icono de la bombilla): habilita campos deshabilitados y muestra los ocultos sin interceptar ni recargar.
- **Comments**: marca en la página las posiciones con comentarios HTML (normalmente solo visibles en el código fuente) — útil para encontrar pistas que los devs dejaron olvidadas.

Burp tiene equivalentes en `Proxy > Proxy settings > Response modification rules` (p. ej. `Unhide hidden form fields`).

> [!important]+ Para qué sirve de verdad
> Editar la respuesta es cómodo, pero recuerda: <mark style="background: #8000E1A6;">solo cambia lo que **tú** ves</mark>, no el comportamiento del servidor. Su valor real es operativo — desbloquear un formulario restringido para inyectar más rápido, o **revelar campos ocultos** (`<input type="hidden">`) y comentarios que filtran lógica, endpoints o parámetros que luego atacas. Los cambios son temporales salvo que los automatices con [[04 - Modificación automática (Match and Replace)|Match & Replace]].

> [!info]+ Fuentes
> - [PortSwigger — Intercepting HTTP responses](https://portswigger.net/burp/documentation/desktop/tools/proxy/intercept-messages)
