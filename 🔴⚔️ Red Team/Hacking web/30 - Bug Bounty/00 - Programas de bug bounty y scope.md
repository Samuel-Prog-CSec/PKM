---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Introduccion
  - Tipo/Introduccion
Descripción: "Un programa de bug bounty (o *Vulnerability Rewards Program*, VRP) es testing de seguridad continuo y proactivo que complementa las auditorías internas y los pentests puntuales…"
Fecha de actualización: 2026-07-17
Nota previa: ""
Nota siguiente: "[[01 - Reglas, legalidad y conducta]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

<mark style="background: #ADCCFFA6;">Un programa de bug bounty (o *Vulnerability Rewards Program*, VRP) es testing de seguridad continuo y proactivo</mark> que complementa las auditorías internas y los pentests puntuales dentro de la estrategia de gestión de vulnerabilidades de una organización. A diferencia de un pentest con reloj, es *crowdsourcing*: muchos ojos, pago por resultados.

# Tipos de programa

- **Privados**: no son públicos; se entra **por invitación**. La mayoría de programas arrancan privados y se hacen públicos cuando la organización sabe recibir y *triar* reportes. <mark style="background: #FFB8EBA6;">Las invitaciones dependen de tu *track record*</mark>: consistencia de hallazgos válidos e historial de violaciones. Algunos exigen incluso *background check*.
- **Públicos**: accesibles por toda la comunidad.
- **Parent/Child**: una empresa matriz y sus filiales comparten *pool* de recompensas y equipo de seguridad; el programa de una filial (child) se enlaza al de la matriz.

# BBP vs VDP — no son lo mismo

<mark style="background: #FF5582A6;">No uses los términos indistintamente</mark>:

| | Qué es | Recompensa |
| - | - | - |
| **VDP** (Vulnerability Disclosure Program) | Solo da **guía de cómo reportar** vulnerabilidades encontradas por terceros | No |
| **BBP** (Bug Bounty Program) | **Incentiva** a terceros a encontrar y reportar bugs | Sí, monetaria |

> [!info]+ PTaaS — el tercer modelo
> Además de BBP y VDP existe el **Pentest-as-a-Service (PTaaS)**: testing programado por un equipo fijo y vetado, con reporte formal para **cumplimiento** (ISO 27001, PCI DSS). No depende de una *crowd* abierta ni paga por bug. Las plataformas modernas los venden en capas: VDP (visibilidad) → BBP (profundidad continua) → PTaaS (garantía auditable).

# Anatomía de un programa: la Policy

Todo gira en torno a la **política** del programa, que publica lo que puedes tocar y cómo. Sus elementos habituales:

| Elemento | Contenido |
| - | - |
| **Scope** | IPs, dominios, apps y tipos de vuln **dentro** de alcance |
| **Out of Scope** | Lo que está **fuera** — territorio prohibido |
| Rules of Engagement | Cómo se permite testear |
| Responsible Disclosure Policy | Plazos y coordinación de divulgación |
| Rewards | Tabla de recompensas por severidad |
| Safe Harbor | Compromiso de no acciones legales ([[01 - Reglas, legalidad y conducta]]) |
| Vendor Response SLAs | Cuándo y cómo responde el *vendor* |
| Eligibility / Access / Legal / Contact | Criterios, cuentas de prueba, términos, contacto |

<mark style="background: #FFB86CA6;">El **scope** es lo primero que se lee y lo más importante</mark>: define qué es un hallazgo válido y qué te deja sin cobertura legal. Léelo meticuloso — en bug bounty, el tiempo es oro y un reporte fuera de scope es tiempo perdido.

# Encontrar programas: el panorama actual

El material clásico es muy HackerOne-céntrico (su [Directory](https://hackerone.com/directory/programs) sigue siendo una gran fuente), pero <mark style="background: #8000E1A6;">el ecosistema es mucho más amplio hoy</mark>:

| Plataforma | Posicionamiento |
| - | - |
| [HackerOne](https://hackerone.com) | La más grande; gran volumen de programas enterprise |
| [Bugcrowd](https://bugcrowd.com) | Competidora directa; usa su taxonomía **VRT (P1-P5)** en vez de CVSS crudo |
| [Intigriti](https://intigriti.com) | Foco europeo; creciendo rápido |
| [YesWeHack](https://yeswehack.com) | Europa/APAC; presencia en sector público europeo |
| [Immunefi](https://immunefi.com) | **Web3/cripto**; las recompensas más altas del sector (millones) |
| [Synack](https://synack.com) | Red *vetada* y privada (SRT); enfoque más de pentest gestionado |
| Auto-hospedados (Google, Apple, MSRC) | VRPs propios de big tech, sin fees de plataforma; tiers altísimos ([Google pagó $17M en 2025](https://blog.google/security/vrp-2025-year-in-review/), [Apple](https://security.apple.com/bounty/) hasta $2M) |

> [!info]+ Elegir plataforma y programa
> Diversifica: cada plataforma tiene programas distintos. Para empezar, los **públicos** con scope amplio (wildcards `*.dominio.com`) dan más superficie. Immunefi es su propio mundo (requiere saber Solidity/smart contracts). El *track record* en una plataforma abre las invitaciones privadas, donde hay menos competencia y mejores pagos.

Antes de lanzar el primer `subfinder`, entiende las reglas y el marco legal que te protege: [[01 - Reglas, legalidad y conducta]].
