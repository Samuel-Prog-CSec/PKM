---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Explotacion
Descripción: "Los plugins de terceros son el vector de ataque número uno de WordPress, muy por encima del core"
Fecha de actualización: 2026-07-17
Nota previa: "[[02 - Login y fuerza bruta en WordPress]]"
Nota siguiente: "[[04 - RCE como administrador en WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Los plugins de terceros son el vector de ataque número uno de WordPress</mark>, muy por encima del core. El dato lo confirma el informe de [Patchstack *State of WordPress Security 2025*](https://patchstack.com/whitepaper/state-of-wordpress-security-in-2025/): en 2024 se publicaron **7.966 vulnerabilidades** en el ecosistema (+34% interanual), **abrumadoramente en plugins**, y <mark style="background: #FFB86CA6;">~43% eran explotables sin autenticación</mark>. El core de WordPress rara vez trae un RCE no-auth; los plugins, constantemente. Ese es el modelo mental correcto para un *bug bounty hunter*.

# Metodología

El flujo es siempre el mismo: **enumerar plugin + versión** ([[01 - Enumeración de WordPress]]) → **cruzar con base de datos de vulnerabilidades** → **localizar PoC** → explotar.

- Bases de datos de referencia: la [WordPress Vulnerability Database de WPScan](https://wpscan.com/) (60.000+ entradas, API v4) y la [base de datos de Patchstack](https://patchstack.com/database/) — ambas mapean *plugin@versión* → CVE + parche. La automatización con `wpscan --api-token` / `nuclei` está en [[06 - Arsenal de herramientas para WordPress]].
- Para el PoC: [Exploit-DB](https://www.exploit-db.com/), el aviso del propio investigador (Wordfence/Patchstack suelen publicar *technical writeup*), y el *changelog* del plugin (el *patch diffing* entre la versión vulnerable y la parcheada revela el bug).

# Caso de laboratorio: `mail-masta` LFI no autenticada

WPScan marca `mail-masta 1.0` con dos vulnerabilidades: **[[00 - Introducción a File Inclusion|Local File Inclusion]]** y **[[00 - Introducción a SQL Injection|SQL Injection]]** (múltiple). La LFI ([Exploit-DB 40290](https://www.exploit-db.com/exploits/40290/)) es no autenticada: el parámetro `pl` se incluye sin sanear.

```shell-session
$ curl "http://blog.inlanefreight.com/wp-content/plugins/mail-masta/inc/campaign/count_of_send.php?pl=/etc/passwd"
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
...
```

<mark style="background: #FF5582A6;">Una LFI así encadena directo a `wp-config.php`</mark> (`?pl=/var/www/html/wp-config.php`) → credenciales de la BD ([[00 - Estructura y roles de WordPress|el santo grial]]). Y con un LFI sobre logs o *wrappers* PHP puede escalar a RCE.

# Caso: `wpDiscuz 7.0.4` — RCE no autenticada

<mark style="background: #FFB86CA6;">CVE-2020-24186</mark>: un *bypass* del filtro de MIME en la subida de adjuntos de comentarios permite subir una *web shell* PHP **sin autenticación** y ejecutar comandos (`?cmd=id`). Arquetipo de "validación de tipo de fichero rota" — la misma clase que ves en [[05 - Validación de tipo - Content-Type y magic bytes|File Upload]].

# Arquetipos de CVE modernas (2023-2025)

No memorices CVEs; memoriza **patrones**. Esta es la selección que todo cazador debería reconocer, verificada con WPScan/Patchstack/NVD:

| CVE | Componente | Clase | Auth | Impacto |
| - | - | - | - | - |
| **CVE-2024-25600** | Bricks ≤1.9.6 | RCE vía `eval()` | No-auth | POST a `/wp-json/bricks/v1/render_element` → PHP. CVSS 9.8, explotada in-the-wild |
| **CVE-2023-6553** | Backup Migration ≤1.3.7 | RCE (LFI→PHP filter chain) | No-auth | Cabecera `Content-Dir` → include. CVSS 9.8 |
| **CVE-2024-28000** | LiteSpeed Cache ≤6.3.0.1 | Priv-esc | No-auth | Fuerza bruta de un hash débil (~1M valores) → admin. Masivamente explotada |
| **CVE-2024-27956** | WP-Automatic ≤3.92.0 | SQLi | No-auth | Param `auth` en export CSV → crea admin. CVSS 9.9 |
| **CVE-2023-28121** | WooCommerce Payments 4.8–5.6.1 | Auth bypass | No-auth | Cabecera `X-Wcpay-Platform-Checkout-User: 1` → actúa como admin |
| **CVE-2024-10924** | Really Simple Security 9.0–9.1.1.1 | Auth bypass | No-auth | `two_fa/skip_onboarding` con cualquier `user_id` → login como cualquiera **con 2FA activo**. CVSS 9.8, 4M sitios |
| **CVE-2023-32243** | Essential Addons (Elementor) 5.4–5.7.1 | Priv-esc | No-auth | Reset de password sin validar la *key* → cambia la de cualquiera |
| **CVE-2024-5709 / 5708** | WPBakery ≤7.7 | LFI / Stored XSS | **Auth (Author+)** | Requieren rol Author — no confundir con las no-auth de arriba |

> [!important]+ El patrón que más rinde: "confiar en una cabecera"
> La <mark style="background: #8000E1A6;">CVE-2023-28121 (WooCommerce Payments) es el arquetipo a interiorizar</mark>: el plugin creía el header `X-Wcpay-Platform-Checkout-User` y te dejaba actuar como el usuario que dijeras. Un *header spoof* de una línea = admin. Provocó **1,3M de ataques sobre 157k sitios en julio de 2023** ([RCE Security patch-diff](https://www.rcesecurity.com/2023/07/patch-diffing-cve-2023-28121-to-compromise-a-woocommerce/), [WPScan](https://wpscan.com/vulnerability/0f78a245-866c-462e-bd23-43dfadb57072/)). Cuando audites un plugin, busca todo dato de autenticación/identidad que venga de un header, cookie o parámetro **controlable por el cliente**.

> [!info]+ Fuentes de la tabla
> Bricks: [WPScan](https://wpscan.com/vulnerability/afea4f8c-4d45-4cc0-8eb7-6fa6748158bd/) · Backup Migration: [Patchstack](https://patchstack.com/database/wordpress/plugin/backup-backup/vulnerability/wordpress-backup-migration-plugin-1-3-7-unauthenticated-remote-code-execution-vulnerability) · LiteSpeed CVE-2024-28000: [Patchstack](https://patchstack.com/articles/critical-privilege-escalation-in-litespeed-cache-plugin-affecting-5-million-sites/) · WP-Automatic: [WPScan](https://wpscan.com/vulnerability/53a51e79-a216-4ca3-ac2d-57098fd2ebb5/) · Really Simple Security: [Wordfence](https://www.wordfence.com/blog/2024/11/really-simple-security-vulnerability/) · Essential Addons: [Patchstack](https://patchstack.com/articles/critical-privilege-escalation-in-essential-addons-for-elementor-plugin-affecting-1-million-sites/).

Cuando el plugin no da un camino directo pero sí has conseguido credenciales admin, la escalada a RCE se hace por el panel: [[04 - RCE como administrador en WordPress]].
