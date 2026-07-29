---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Enumeracion
Descripción: "El recon (02 - Recon y herramientas para bug bounty) te da la superficie; encontrar bugs es lo que haces encima de ella"
Fecha de actualización: 2026-07-27
Nota previa: "[[02 - Recon y herramientas para bug bounty]]"
Nota siguiente: "[[04 - Mindset del cazador y encadenamiento de bugs]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

El recon ([[02 - Recon y herramientas para bug bounty]]) te da la superficie; encontrar bugs es lo que haces **encima** de ella. No hay fórmula mágica —demasiadas tecnologías cambiando a la vez—, pero sí un patrón que siguen los cazadores que cobran: <mark style="background: #ADCCFFA6;">entender la aplicación a fondo, mapear su funcionalidad y proyectar cada pieza contra los tipos de vulnerabilidad que encajan</mark>. Yaworski lo resume en una proporción: ⅓ conocimiento, ⅓ observación, ⅓ perseverancia. Y una regla de Mathias Karlsson: *"trata cada objetivo como si nadie hubiera estado antes; si no encuentras nada, elige otro"* — nunca asumas que "ya lo han mirado todo".

# 1. Fingerprint del stack

Lo primero al abrir un objetivo nuevo: identificar **qué tecnología corre por debajo**. <mark style="background: #FFB86CA6;">El stack dicta los payloads</mark> — probar `{{7*7}}` en un sitio ASP.NET es perder el tiempo; en uno con AngularJS es el primer disparo. Se saca del historial del [[13 - Flujo profesional y alternativas modernas|proxy]] (qué ficheros sirve, qué dominios aparecen, si devuelve JSON/XML, las cabeceras). `Wappalyzer` sigue siendo el atajo en navegador; en pipeline, `httpx -td` (tech-detect) o los templates de `nuclei` lo automatizan. La nota [[09 - Fingerprinting web]] lo cubre a fondo.

Lo que el stack sugiere priorizar:

| Señal del stack | Qué priorizar |
| - | - |
| Framework JS que renderiza plantillas en cliente (AngularJS, Vue) | [[00 - Motores de plantillas e introducción a SSTI\|SSTI/CSTI]] — probar `{{7*7}}` · `{{8*8}}[[5*5]]` |
| ASP.NET con protección XSS activa | Dejar el XSS para el final; atacar otras clases primero |
| Rails / URLs tipo `/recurso/ID` con enteros incrementales | [[06 - Introducción a IDOR\|IDOR]] — los IDs predecibles son un regalo |
| API que devuelve JSON/XML sin renderizar | Info disclosure · [[14 - Introducción a XXE\|XXE]] |
| Acepta `.docx`/`.xlsx`/`.pptx` (son XML por dentro) | [[14 - Introducción a XXE\|XXE]] |
| Flujo OAuth/SSO propio | `redirect_uri`, `state`, fuga de token ([[07 - Introducción a OAuth 2.0\|OAuth]]) |

# 2. Mapeo de funcionalidad

Con la tecnología clara, toca el <mark style="background: #ADCCFFA6;">*mapeo de funcionalidad*: recorrer la aplicación como un usuario real, entendiendo qué hace cada parte</mark>, mientras el proxy lo registra todo en segundo plano. No es buscar el bug todavía — es construir el mapa mental de dónde **podría** estar. Tres formas de abordarlo, y conviene combinarlas:

- **Buscar markers**: localizar comportamientos que suelen esconder vulnerabilidades (tabla siguiente). El enfoque por defecto.
- **Orientado a objetivo**: fijar de antemano *"hoy solo busco SSRF"* e ignorar lo demás. Jobert Abma (HackerOne) y Philippe Harewood lo defienden — concentra la atención y evita la dispersión.
- **Checklist**: seguir una metodología cerrada como la [OWASP WSTG](https://owasp.org/www-project-web-security-testing-guide/). Monótona pero exhaustiva; útil para no olvidar clases enteras (revisar los ficheros JS, por ejemplo).

# 3. De marker a técnica

El núcleo del método: cada señal que ves en el historial del proxy apunta a una clase de vulnerabilidad concreta — y a la nota donde vive su explotación. Este es el mapa que conviene tener delante mientras testeas:

| Marker que observas | Qué probar |
| - | - |
| Petición que cambia estado sin token / sin check de origin | [[00 - Primitivas y entorno de explotación\|CSRF]] |
| Parámetro con un ID (numérico, UUID, hash) | [[06 - Introducción a IDOR\|IDOR]] |
| Repetir la misma acción entre 2 cuentas o en paralelo | [[06 - Unrestricted Access to Sensitive Business Flows (API6)\|Lógica de negocio]] · [[00 - Fundamentos de Race Conditions (TOCTOU)\|Race conditions]] |
| Petición que acepta/procesa XML (`.docx`, SOAP, feeds) | [[14 - Introducción a XXE\|XXE]] |
| Parámetro reflejado en la respuesta | [[00 - Introducción a XSS\|XSS]] · [[01 - Introducción a CRLF Injection\|CRLF]] |
| Parámetro con URL de destino / redirección | [[00 - Introducción a Open Redirect\|Open redirect]] · [[00 - Introducción a los ataques server-side\|SSRF]] |
| Webhook / integración / "fetch de una URL" | [[00 - Introducción a los ataques server-side\|SSRF]] |
| Comilla, bracket o `;` cambian la respuesta | [[00 - Introducción a SQL Injection\|SQLi]] |
| Upload de fichero o manipulación de imagen | [[00 - Introducción a los File Upload Attacks\|File upload]] · [[00 - Introducción a Command Injection\|RCE]] |
| Suplantación de usuario / datos privados en la respuesta | Info disclosure ([[06 - Introducción a IDOR\|IDOR]]) |
| Versión de software expuesta (PHP, nginx, framework) | CVE sin parchear ([[09 - Fingerprinting web\|fingerprint]]) |
| Flujo OAuth / SSO custom | `redirect_uri`, `state`, fuga de token ([[07 - Introducción a OAuth 2.0\|OAuth]]) |

<mark style="background: #FF5582A6;">Cuando cae uno de estos markers, para de mapear y empieza a atacar esa pieza</mark> con la técnica específica.

# 4. Atacar: el testing manual

Los bugs que pagan salen del **testing manual**, no del escáner. <mark style="background: #FFB8EBA6;">La mayoría de programas prohíben los escáneres automáticos de vulnerabilidad</mark> (Burp Scanner y similares): son ruidosos y no requieren habilidad. El escáner encuentra CVEs conocidas —casi siempre duplicados o fuera de scope—; tú buscas lo que no ve.

La técnica de Yaworski: usar la app **como un cliente** (crear contenido, usuarios, equipos) e inyectar en cada input un <mark style="background: #ADCCFFA6;">*polyglot*: un payload que combina los caracteres que romperían el contexto en HTML, JS o SQL a la vez</mark>:

```text
<s>000'"</s>};--//
```

El `<s>` (tachado) se detecta a ojo: si el sitio lo renderiza sin sanear, ves el texto tachado en la página. La comilla, el `};` y el `--` disparan anomalías en JS y SQL. Donde el polyglot provoque algo raro, ahí se profundiza.

> [!warning]+ Blind XSS: moderniza la herramienta
> El libro (2019) recomienda **XSSHunter** de Matt Bryant para XSS ciego en paneles de admin. El servicio original **cerró en 2023**. Alternativas actuales: [XSS Hunter self-hosted](https://github.com/mandatoryprogrammer/xsshunter-express), la versión mantenida por [Truffle Security](https://xsshunter.trufflesecurity.com/), o un callback OOB genérico con [`interactsh`](https://github.com/projectdiscovery/interactsh) de ProjectDiscovery. Para plantillas, añadir `{{8*8}}` / `<%= 7*7 %>` y ver si el `64`/`49` aparece renderizado.

# 5. Ir más allá

Cuando agotas la funcionalidad visible, quedan palancas para encontrar más:

- **Automatización / continuous recon**: convertir el pipeline de [[14 - Automatización del recon|recon]] en algo que corre solo y avisa de activos nuevos. Rojan Rijal reportó un bug de Shopify **cinco minutos** después de que el subdominio saliera vivo — porque lo tenía automatizado.
- **Apps móviles**: si están en scope, proxear el tráfico del móvil por Burp abre APIs que la web no expone (IDOR, RCE). Muchas apps usan *SSL pinning*; hoy se sortea con [`Frida`](https://frida.re/) / [`objection`](https://github.com/sensepost/objection) o `apk-mitm`, no con las técnicas de 2019.
- **Funcionalidad nueva**: el código recién desplegado es el menos testeado. Seguir los blogs de ingeniería del objetivo y **trackear los ficheros JS** — sus cambios revelan endpoints nuevos antes de que aparezcan en la UI.
- **Pagar por acceso**: comprar el plan de pago o una función premium amplía tu superficie a una zona que casi nadie testea.
- **Aprender la tecnología a fondo**: FileDescriptor encontró bugs de OAuth leyendo los RFCs y comparando *cómo debería funcionar* con *cómo está implementado*. El dominio profundo de una tecnología concreta es una ventaja competitiva sostenible.

Mapeada y atacada la aplicación, lo que separa al cazador medio del que cobra alto no es una técnica más, sino **cómo piensa** y **cómo encadena** lo que encuentra: [[04 - Mindset del cazador y encadenamiento de bugs]].
