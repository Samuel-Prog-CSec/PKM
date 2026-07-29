---
tags:
  - Web/Red-Team
  - Subdomain-Takeover
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "Las herramientas de 'verdad contra tu propio inventario' (dnsReaper por API, Ghostbuster, Get-DanglingDnsRecords, AWS Config) son más fiables que el fingerprint HTTP ciego…"
Fecha de actualización: 2026-07-27
Nota previa: "[[01 - Identificación y explotación de Subdomain Takeover]]"
Nota siguiente: ""
Area: "[[Subdomain Takeover.base|Subdomain Takeover]]"
---
---

# Arsenal de detección

| Herramienta | Enfoque | Estado 2025 |
| - | - | - |
| [subzy](https://github.com/PentestPad/subzy) | Fingerprint HTTP; consume `can-i-take-over-xyz` | **Actual** — el que recomienda OWASP WSTG |
| [dnsReaper](https://github.com/punk-security/dnsReaper) | Lee registros vía **API** del proveedor (Route53/Azure/CF/DO/GCP) | **Actual** — pilla lo que el fingerprint HTTP no ve (NS, sin listener) |
| [nuclei](https://github.com/projectdiscovery/nuclei-templates) `http/takeovers/` | Templates de comunidad | Mantenido pero con **drift** (templates rotos por cambios de proveedor) — verifica a mano |
| [Ghostbuster](https://github.com/assetnote/ghostbuster) | Dangling **Elastic IP/ENI** en tu cuenta AWS | Actual — otra clase de bug (IPs, no CNAME) |
| [second-order](https://github.com/mhmdiaa/second-order) | Crawlea la app por hosts referenciados externamente | Para la variante *second-order* |
| ~~subjack~~ / ~~SubOver~~ | Fingerprint HTTP | **Legacy / sin mantener** — superados por subzy/dnsReaper |
| Get-DanglingDnsRecords (MS) · AWS Config | Cruzan CNAMEs contra el inventario real de la cuenta | Blue-team (requiere acceso a la cuenta) |

<mark style="background: #ADCCFFA6;">Las herramientas de "verdad contra tu propio inventario"</mark> (dnsReaper por API, Ghostbuster, Get-DanglingDnsRecords, AWS Config) son más fiables que el fingerprint HTTP ciego, porque no dependen de adivinar el mensaje de error.

# Recon continuo (bug bounty)

Los subdominios no son estáticos — un takeover aparece el día que alguien desaprovisiona un recurso. La práctica estándar:
1. Enumeración **recurrente** (`amass`/`subfinder`/`chaos`) diffeada día a día ([[05 - Enumeración de subdominios|enum de subdominios]]).
2. Los CNAME nuevos/cambiados → directos a `subzy`/`dnsReaper`.
3. Monitorizar los **CT logs** (`crt.sh`): un certificado nuevo sobre un subdominio dormido es señal fuerte de que **algo** se acaba de (re)aprovisionar ahí — legítimo o un atacante que acaba de reclamarlo.

<mark style="background: #FF5582A6;">PoC discreta</mark>: `can-i-take-over-xyz` recomienda servir una página oculta e inofensiva (no un index, nada disruptivo), como hizo Frans Rosen con un `<!-- FRANS ROSEN -->` en HTML plano.

> [!important]+ La allowlist de CSP también es un inventario de dominios
> Un dominio caducado no solo se usa para servir contenido bajo la marca: si figura en la **allowlist de CSP** de una aplicación, recomprarlo convierte el takeover en un bypass de control de seguridad. Ocurrió en `ForcedLeak` (Salesforce Agentforce, 2025), donde ese dominio fue el canal de exfiltración de datos del CRM — ver [[06 - EchoLeak y la exfiltración zero-click]]. **El inventario de dominios de la organización debe incluir los que aparecen en cabeceras de seguridad, no solo los que resuelven en su zona DNS.**

# Prevención

1. <mark style="background: #FFB86CA6;">**Orden de desaprovisionamiento**: borra/repunta el registro DNS **primero**, espera el TTL, **luego** libera el recurso</mark> (literal de AWS y Microsoft). La regla de oro.
2. **Orden de aprovisionamiento**: reclama el recurso **antes** de crear el DNS que lo apunta (evita que otro coja el identificador en medio).
3. **Verificación de propiedad** del proveedor (TXT): GitHub Pages, Azure `asuid.`, Vercel/Netlify — pero **no** retroactiva; la higiene DNS sigue siendo necesaria.
4. **Inventario DNS / CMDB**: cada registro con dueño, cuenta/ARN, fecha y justificación. La zona es infraestructura trackeada, no conocimiento tribal.
5. **Tipos de registro atados al ciclo de vida**: los ALIAS de Route 53 / alias de Azure DNS se **vacían solos** al borrar el recurso, en vez de seguir resolviendo.
6. **Sin wildcard DNS** hacia plataformas multi-tenant (`*.example.com`) — convierte un binding colgante en infinitos hostnames a elección del atacante.
7. **Null MX** ([RFC 7505](https://www.rfc-editor.org/rfc/rfc7505), `0 .`) en dominios que nunca envían/reciben correo — cierra el spoofing SPF/MX estructuralmente.
8. **Delete-locks / checklists**: atar un lock al recurso que fuerce reconocer el mapeo DNS antes de borrarlo (patrón de Azure, copiable en cualquier cloud).

> [!info]+ Fuentes
> [can-i-take-over-xyz (EdOverflow)](https://github.com/EdOverflow/can-i-take-over-xyz); [OWASP WSTG — Test for Subdomain Takeover](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/10-Test_for_Subdomain_Takeover.html) y [Subdomain Takeover Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Subdomain_Takeover_Prevention_Cheat_Sheet.html); [Microsoft Learn — Prevent dangling DNS](https://learn.microsoft.com/en-us/azure/security/fundamentals/subdomain-takeover); [Snyk Labs — Cookie Tossing / CVE-2024-21583](https://labs.snyk.io/resources/hijacking-oauth-flows-via-cookie-tossing/); IONIX (2025); Form3 (2023).
