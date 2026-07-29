---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Explotacion
  - Tipo/Deteccion
Descripción: "El WordPress de 2026 no es el del lab. Entre tu petición y el PHP suele haber un WAF de borde, un plugin de seguridad y una capa de *hardening*"
Fecha de actualización: 2026-07-17
Nota previa: "[[04 - RCE como administrador en WordPress]]"
Nota siguiente: "[[06 - Arsenal de herramientas para WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

El WordPress de 2026 no es el del lab. Entre tu petición y el PHP suele haber un WAF de borde, un plugin de seguridad y una capa de *hardening*. Esta nota cubre las dos caras: **detectar** qué defensas hay y **evadirlas** o convivir con ellas. Es la diferencia entre un escaneo que rebota con `403` y uno que rinde en un objetivo real.

# El panorama defensivo actual

Lo que te vas a encontrar, de fuera hacia dentro:

- **Rate-limiting en el borde (CDN/WAF).** Reglas típicas de Cloudflare: `/wp-login.php` **5 req/min**, `/xmlrpc.php` **10 req/30s**, `/wp-json/` **~120 req/min**, con bloqueo de 1h al superarlas ([Jorijn](https://jorijn.com/en/knowledge-base/wordpress/security/brute-force-attack-protection-in-wordpress/), [Topsyde](https://topsyde.com/blog/wordpress-api-rate-limiting)). Sucuri bloquea `xmlrpc.php` en el CDN **antes** de que llegue a PHP.
- **Plugins de seguridad.** [Wordfence](https://www.wordfence.com/help/firewall/brute-force/) (WAF + límite de intentos de login + puede desactivar xmlrpc), Solid Security (ex-iThemes), All-In-One Security (AIOS), Sucuri. Limitan intentos de login y aplican rate-limit a la autenticación por xmlrpc; Wordfence puede además **desactivar `xmlrpc.php` por completo**.
- **Hardening de configuración.** Versión oculta, `xmlrpc.php`/REST desactivados, `wp-login.php` renombrado, `DISALLOW_FILE_EDIT`.

# Fingerprint de las defensas

Antes de lanzar nada ruidoso, identifica qué te vigila:

- **WAF/CDN de borde:** cabeceras de respuesta (`Server: cloudflare`, `X-Sucuri-ID`, `cf-ray`), páginas `403`/`406` características, o `wafw00f <url>` ([[06 - Arsenal de herramientas para WordPress]]).
- **Plugin de seguridad:** su propia huella. Wordfence deja rastro en `/wp-content/plugins/wordfence/`, cookies `wfvt_*`/`wf_loginalerted_*` y su página de bloqueo característica. Un `403` selectivo solo en `/xmlrpc.php` apunta a hardening específico.
- **¿Vive xmlrpc?** `POST` con `system.listMethods` a `/xmlrpc.php`: si responde con la lista de métodos, tienes superficie ([[02 - Login y fuerza bruta en WordPress]]); si da `403`/`405`, está capado.

# Técnicas de evasión

**Amplificación con `system.multicall`.** Es la evasión de rate-limiting por excelencia: cientos de intentos de contraseña en **una sola petición HTTP** derrotan a las defensas que cuentan *requests*. Cloudflare demostró **1.000 llamadas `wp.getUsersBlogs` en un request** ([Cloudflare](https://blog.cloudflare.com/a-look-at-the-new-wordpress-brute-force-amplification-attack/)). Detalle en [[02 - Login y fuerza bruta en WordPress|la nota de login]].

**Password spraying en vez de fuerza bruta.** Contra límites por cuenta, invertir el bucle: <mark style="background: #FF5582A6;">pocas contraseñas comunes contra muchos usuarios enumerados</mark>, en vez de muchas contra una. Se mantiene por debajo del umbral de bloqueo por cuenta. Complementar con *timing* lento (*slow-and-low*) y, en ataques reales, distribución por múltiples IPs.

**Enumeración por canales secundarios.** Cuando `?author=` y la REST `/users` están capados, la enumeración de usuarios rara vez muere del todo: **sitemap de autores** (`/wp-sitemap-users-1.xml`), **oEmbed** (`/wp-json/oembed/1.0/embed?url=...`) y **diferenciales en el error de login** siguen filtrando ([[02 - Login y fuerza bruta en WordPress]]). Fuente: [Melapress](https://melapress.com/user-enumeration-wordpress/).

**Fingerprint de versión cuando está oculta.** Muchos defensores eliminan `wp_generator`, quitan el `?ver=` de los assets y borran `readme.html`/`license.txt` ([InspectWP](https://inspectwp.com/en/knowledge-base/how-to-hide-wordpress-version-number)). Pero <mark style="background: #8000E1A6;">ocultar la versión no es un control</mark>: sigue siendo deducible por el **hash de los ficheros JS/CSS del core**, por la respuesta de `/wp-json/` y por el `?ver=` residual que casi siempre se cuela en algún asset.

**Evasión de payload en el WAF.** Para explotar un plugin a través de un WAF genérico aplican las mismas técnicas que en cualquier vuln web (codificaciones, *case*, ofuscación, fragmentación). Ver los patrones transversales en [[06 - Evasión de filtros y WAF en XPath|evasión de WAF]] y las notas de evasión de cada vuln concreta.

> [!warning]+ Ruido, alertas y autorización
> Casi todo lo anterior es **ruidoso**: Wordfence y compañía **alertan** ante intentos de login, ediciones de ficheros y escaneos. En un pentest con reloj eso puede ser deseable (probar la detección) o contraproducente (quemar el acceso). <mark style="background: #FFB86CA6;">En bug bounty, la fuerza bruta suele estar fuera de scope</mark> y el rate-limiting de la plataforma existe por algo — lee el programa antes de lanzar `wpscan --passwords`. La evasión es una herramienta, no un permiso.

La automatización de todo esto — fingerprint, enumeración sigilosa, correlación de CVEs — vive en el arsenal: [[06 - Arsenal de herramientas para WordPress]].
