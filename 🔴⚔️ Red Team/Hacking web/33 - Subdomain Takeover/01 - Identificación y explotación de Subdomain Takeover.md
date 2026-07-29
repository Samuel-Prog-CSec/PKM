---
tags:
  - Web/Red-Team
  - Subdomain-Takeover
  - Pentesting/Explotacion
Descripción: "Encontrar un takeover es reconocer el *fingerprint*: el mensaje de error que devuelve un servicio de terceros cuando el recurso apuntado no existe o no está reclamado"
Fecha de actualización: 2026-07-27
Nota previa: "[[00 - Fundamentos de Subdomain Takeover]]"
Nota siguiente: "[[02 - Detección, prevención y arsenal de Subdomain Takeover]]"
Area: "[[Subdomain Takeover.base|Subdomain Takeover]]"
---
---

Encontrar un takeover es reconocer el <mark style="background: #ADCCFFA6;">*fingerprint*: el mensaje de error que devuelve un servicio de terceros cuando el recurso apuntado no existe o no está reclamado</mark>. La fuente de verdad es el proyecto [`can-i-take-over-xyz`](https://github.com/EdOverflow/can-i-take-over-xyz) de EdOverflow.

> [!warning]+ Verifica el fingerprint, no te fíes de la tabla
> Los fingerprints son de la comunidad y muchos están marcados internamente como *"CI verification not passing"* — el re-chequeo automático no confirmó que el PoC siga funcionando. <mark style="background: #FF5582A6;">Confirma siempre a mano antes de reportar</mark>: pincha el issue/PR original del repo y comprueba el comportamiento actual del servicio.

# ¿Qué sigue siendo explotable? (2025)

**Explotables** (claim self-service, sin verificación de propiedad):

| Servicio | Fingerprint |
| - | - |
| AWS S3 | `NoSuchBucket` / `The specified bucket does not exist` |
| AWS Elastic Beanstalk | `NXDOMAIN` |
| Bitbucket Pages | `Repository not found` |
| Surge.sh | `project not found` |
| Ghost(Pro) | `Site unavailable` / `Failed to resolve DNS path` |
| WordPress.com, Ngrok, YouTrack InCloud, Strikingly, Readme.io, Canny… | strings propios (ver repo) |
| **Azure** (17+ patrones: App Service, Traffic Manager, CDN clásico [en retirada hacia Front Door], Front Door, Blob, ACI, APIM) | `NXDOMAIN` |

<mark style="background: #FFB8EBA6;">Azure es único: Microsoft **documenta su propia** exposición a dangling DNS</mark> y publica una herramienta de detección, en vez de decir que está arreglado.

**Casos límite** (dangling ≠ explotable directo — hace falta una condición extra):

| Servicio | La pega |
| - | - |
| GitHub Pages | Verificación de dominio (TXT) desde 2021 protege los subdominios de un dominio verificado; **wildcards y dominios no verificados siguen explotables** |
| Heroku / Shopify | Hay que registrar el **nombre exacto** de la app/tienda (puede estar cogido) |
| Vercel / Netlify | Verifican propiedad **en bindings nuevos**, pero **no** retroactivamente — los dangling viejos siguen explotables |

**Ya arreglados** (no explotables por CNAME colgante simple): **Fastly** (exige validación TLS del dominio), **Zendesk** (verificación de propiedad), **SendGrid**, **CloudFront**, GCS, Firebase, Squarespace, HubSpot, Statuspage… — ojo, tres de ellos protagonizan casos del libro que **hoy ya no valen**.

# Variantes avanzadas

- **NS takeover** (el de mayor blast radius): si la delegación `NS` de un subdominio apunta a un dominio base expirado o a una zona nunca creada en un DNS multi-tenant (Route 53, Cloudflare), quien la controle es **autoritativo de todo el subárbol** (A, CNAME, MX, TXT, wildcard). Form3 (2023) *bypasseó* incluso la protección de Route 53 creando la zona del **dominio padre**. IONIX (2025) documentó una delegación NS colgante que generó **9.500 subdominios maliciosos en 48h** bajo un dominio Fortune 500.
- **Second-order** (Patrik Hudak): el host vulnerable **no** es un subdominio del objetivo. Si `target.com` carga un script/iframe/webhook de `vendor-assets.io` (subdominio colgante de **un tercero**), tomarlo da ejecución de JS **en el contexto de `target.com`** sin tocar su DNS. Por eso el recon serio rastrea los hosts **referenciados externamente**, no solo los subdominios propios.
- **Dangling A / IPs liberadas**: un `A` que apunta a una IP elástica ya liberada; otro cliente del mismo cloud puede recibir esa IP. La detecta [Ghostbuster](https://github.com/assetnote/ghostbuster) cruzando tus `A` contra tu inventario real de IPs.

# Impacto avanzado y chaining

Más allá del phishing, controlar un subdominio de confianza permite:
- **Cookie tossing**: un subdominio bajo control del atacante hace `Set-Cookie` con `Domain=.example.com` → <mark style="background: #FFB86CA6;">envenena cookies del dominio padre sin necesidad de XSS</mark>. En plataformas multi-tenant **ni hace falta un takeover**: en `CVE-2024-21583` (Gitpod) bastó un subdominio de workspace **legítimo** —el que recibe cualquier usuario registrado— para setear el JWT del padre y secuestrar el flujo OAuth (arreglado con el prefijo `__Host-`). Habilita también **session fixation** si la app no rota el session-id al hacer login.
- **OAuth / CSP allowlist**: si el `redirect_uri` de OAuth o el `script-src` de CSP incluyen (o wildcardean) un subdominio colgante, tomarlo roba el `code`/token o ejecuta JS que la CSP acepta ([[08 - Robo de tokens de acceso OAuth|token theft]] · [[05 - Bypass de CSP|CSP bypass]]).
- **SSO**: si una cookie de sesión se comparte entre `*.corp.example.com`, **un solo** subdominio colgante compromete todo el perímetro de confianza (Okta).
- **Email spoofing**: si un `include:` de SPF, un `MX` o un selector DKIM referencian un recurso colgante, el atacante que lo reclame **pasa SPF/DKIM** para el dominio víctima → phishing/BEC con `From:` legítimo.

# Los seis casos del libro

> [!example]+ Ubiquiti (S3) — $500 · [H1 #109699](https://hackerone.com/reports/109699)
> `CNAME assets.goubiquiti.com → uwn-images` (bucket S3) sin registrar → reclamarlo. El caso S3 de manual.

> [!example]+ Scan.me → Zendesk — $1.000 · [H1 #114134](https://hackerone.com/reports/114134)
> `support.scan.me → scan.zendesk.com`. Snapchat compró scan.me, liberó el subdominio de Zendesk pero **olvidó el CNAME**. **Lección**: las **adquisiciones** cambian servicios; vigila los CNAME tras una compra. *(Zendesk hoy verifica propiedad — ya no vale.)*

> [!example]+ Shopify Windsor — $500 · [H1 #150374](https://hackerone.com/reports/150374)
> No todo takeover es de un tercero. `windsor.shopify.com → aislingofwindsor.com`, un **dominio expirado** que zseano compró por $10. Lo encontró en **`crt.sh`** (Certificate Transparency) buscando subdominios de Shopify; los wildcards salen como `*` y su hash se rastrea en **`censys.io`**.

> [!example]+ Snapchat Fastly — $3.000 · [H1 #154425](https://hackerone.com/reports/154425)
> `fastly.sc-cdn.net` apuntaba a un subdominio de Fastly no reclamado (error *"Fastly error: unknown domain"*). Ebrietas confirmó en `censys.io` que Snapchat poseía `sc-cdn.net` antes de reportar. **Lección**: un servicio que devuelve error → lee su doc y comprueba si puedes reclamarlo. *(Hoy Fastly exige validación TLS — ya no vale.)*

> [!example]+ Legal Robot — $100 · [H1 #148770](https://hackerone.com/reports/148770)
> `api.legalrobot.com → Modulus.io`, ya reclamado. Frans Rosen no se rindió: reclamó el **wildcard** `*.legalrobot.com` (Modulus dejaba que un wildcard sobreescribiera subdominios específicos). **Lección**: si el subdominio exacto está cogido, prueba el wildcard.

> [!example]+ Uber SendGrid Mail — $10.000 · [H1 #156536](https://hackerone.com/reports/156536)
> `em.uber.com → SendGrid` con un `MX`. SendGrid no aloja contenido, pero su *Inbound Parse Webhook* parsea correos entrantes y los manda a una URL. Uber tenía el `MX` pero **no había reclamado** el paso del webhook. Rojan Rijal lo reclamó → interceptar correos de Uber *(SendGrid hoy exige verificación de dominio para el Inbound Parse Webhook — ya no vale)*. **Lección**: lee la doc del tercero y explora **toda** su funcionalidad — el mayor pago del capítulo salió de ahí.

Cómo automatizar el descubrimiento, monitorizar en continuo y cerrar el agujero, en la [[02 - Detección, prevención y arsenal de Subdomain Takeover|nota siguiente]].
