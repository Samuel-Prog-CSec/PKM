---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - API
  - Tipo/Deteccion
Descripción: "Nota dedicada a la metodología del pentest de APIs, que HTB no consolida: cómo descubrir la superficie (lo más difícil, no hay UI que navegar), cómo detectar sistemáticamente…"
Fecha de actualización: 2026-07-15
Nota previa: "[[10 - Unsafe Consumption of APIs (API10)]]"
Nota siguiente: "[[12 - Herramientas para pentesting de APIs]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Nota dedicada a la **metodología** del pentest de APIs, que HTB no consolida: cómo descubrir la superficie (lo más difícil, no hay UI que navegar), cómo detectar sistemáticamente las vulns de autorización, y cómo evadir defensas como el rate-limiting.

# Descubrir la superficie

<mark style="background: #FFB86CA6;">El 80% del trabajo en un pentest de API es enumerar qué endpoints existen</mark>. Fuentes, de más a menos "regalada":

- <mark style="background: #ADCCFFA6;">**Documentación**</mark>: Swagger UI (`/swagger`, `/swagger/index.html`), spec OpenAPI (`/openapi.json`, `/swagger/v1/swagger.json`, `/api-docs`, `/v2/api-docs`), colecciones de Postman filtradas. Es el mapa completo si está expuesto.
- **Tráfico**: proxear la app con Burp y, mejor aún, capturar con `mitmproxy` y reconstruir un OpenAPI con **mitmproxy2swagger** — reverse-engineering de la API solo con usarla.
- **Front-end**: minar los `.js` con `LinkFinder`/`xnLinkFinder` en busca de rutas y parámetros que nunca aparecen navegando.
- **Fuerza bruta de rutas**: **kiterunner** con wordlists específicas de API (mucho más efectivo que un dir-buster clásico: prueba métodos y patrones típicos de API), y `ffuf` para endpoints/parámetros.
- **Recon histórico y de infra**: `gau`/`waybackurls` para endpoints viejos ([[09 - Improper Inventory Management (API9)|versiones olvidadas]]), enumeración de subdominios (`api.`, `dev.`, `staging.`) — ver [[05 - Enumeración de subdominios|recon]].

# Entender el modelo de autorización

Antes de atacar, mapea **quién debería poder hacer qué**: roles, tenants, y los **claims del `JWT`** (decodifícalo: `sub`, `role`, `tenant`, `scope`). En el lab, los roles se llamaban como los endpoints (`Suppliers_GetAll`); en general, reconstruye la matriz rol × endpoint. Las vulnerabilidades de autorización son desviaciones de esa matriz.

# Detectar las vulns clave

| Vuln | Cómo probarla |
| - | - |
| [[01 - Broken Object Level Authorization (API1)\|BOLA]] | Enumera **cada** endpoint con un ID, loguéate como A, cambia a IDs de B, verifica si responde. <mark style="background: #FFB8EBA6;">Los IDs en **body/cabeceras** son más vulnerables que en la URL</mark> — empieza por ahí |
| [[05 - Broken Function Level Authorization (API5)\|BFLA]] | Invoca endpoints privilegiados como usuario sin rol; **cambia el método** (`GET`→`DELETE`/`POST`/`PUT`); adivina rutas admin por convención REST |
| [[03 - Broken Object Property Level Authorization (API3)\|Mass Assignment]] | Añade campos "extra" al `PUT`/`POST` (`isAdmin`, `role`, `verified`, `price`) y compara la respuesta del `GET` |
| [[02 - Broken Authentication (API2)\|Broken Auth]] | Brute-force sin rate-limit, ataques al JWT, tokens que no expiran |

<mark style="background: #FF5582A6;">La automatización estándar es [[13 - Herramientas para IDOR|Autorize/Auth Analyzer]]</mark>: reproducen cada petición con otra identidad y marcan las que no fueron bloqueadas. Primer barrido obligatorio.

# Evasión

## Bypass de rate-limiting

El rate-limit es la defensa que más se evade en bug bounty (documentado por **HackTricks** y las metodologías de la comunidad):

- **Cabeceras de IP**: rotar `X-Forwarded-For`, `X-Real-IP`, `X-Originating-IP`, `X-Client-IP` — muchos limitadores cuentan por la IP de estas cabeceras.
- **Endpoints bulk/batch**: si el límite está solo en el endpoint individual, un `/v2/batch` o un body con **array** de operaciones mete N acciones en 1 petición. Es la misma idea que el [[04 - Denegación de servicio (DoS) y Batching|batching de GraphQL]].
- **Timing**: si `X-RateLimit-Reset` revela la ventana, dispara el máximo justo antes del reset y otra ráfaga completa justo después.
- **Variaciones**: cambiar mayúsculas de la ruta, añadir `/`, parámetros basura, o distribuir desde varias IPs.

## Otras evasiones

- **Versión sin control**: si `v2` tiene el límite/authz y `v1` no, usa `v1` ([[09 - Improper Inventory Management (API9)|inventory]]).
- **Verb tampering**: control presente en `GET`, ausente en otros métodos ([[04 - Detección, evasión y prevención de Verb Tampering|verb tampering]]).
- **JWT**: `alg:none`, secreto débil, `kid`/`jku` injection para forjar tokens y saltar authz ([[01 - Introducción a JWT|JWT]]).

> [!tip]+ Prioridad en un pentest de API
> 1. **Enumerar** toda la superficie (docs + tráfico + brute-force + versiones). 2. **Mapear** roles/tenants/claims. 3. **Autorización primero** (BOLA/BFLA/BOPLA son el grueso de los hallazgos): Autorize + swap de IDs + method fuzzing. 4. **Inyección y misconfig** en los puntos que acepten input. 5. **Rate-limit y business logic** para el impacto económico.

Las herramientas concretas, en [[12 - Herramientas para pentesting de APIs|Herramientas para pentesting de APIs]].

## Referencias

- HackTricks — [Web API Pentesting](https://hacktricks.wiki/en/network-services-pentesting/pentesting-web/web-api-pentesting.html) y [Rate Limit Bypass](https://book.hacktricks.xyz/pentesting-web/rate-limit-bypass)
- Inon Shkedy — [31 Days of API Security Tips](https://github.com/inonshk/31-days-of-API-Security-Tips)
- APIsec University — [API Tools & Resources](https://university.apisec.ai/api-tools-and-resources)
- OWASP — [API Security Top 10 (2023)](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)
