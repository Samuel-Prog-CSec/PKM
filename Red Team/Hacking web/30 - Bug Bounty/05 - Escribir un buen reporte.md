---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Reporting
Descripción: "El reporte es el producto que cobras. Un hallazgo brillante mal documentado se paga tarde, poco o nada"
Fecha de actualización: 2026-07-27
Nota previa: "[[04 - Mindset del cazador y encadenamiento de bugs]]"
Nota siguiente: "[[06 - Ejemplos de reportes (XSS, CSRF, RCE)]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

El reporte es el producto que cobras. Un hallazgo brillante mal documentado se paga tarde, poco o nada. <mark style="background: #ADCCFFA6;">Un reporte legible y bien formateado minimiza el tiempo de reproducción y de *triage*</mark> — y eso se traduce en cobrar antes. Ante empresas poco maduras, además, hay que **traducir el problema técnico a términos de negocio** para que entiendan el impacto real.

# Elementos de un buen reporte

| Elemento | Contenido |
| - | - |
| **Título** | Tipo de vuln + dominio/parámetro/endpoint afectado + impacto |
| **CWE y CVSS** | Comunican la naturaleza y la severidad de forma estándar |
| **Descripción** | La causa raíz de la vulnerabilidad |
| **PoC** | Pasos para reproducir la explotación, claros y concisos |
| **Impacto** | Qué consigue el atacante; impacto de negocio y **daño máximo** |
| **Remediación** | Opcional en bug bounty, pero suma |

# Por qué CWE y CVSS

- **CWE** ([Common Weakness Enumeration](https://cwe.mitre.org/), de MITRE) es la lista común de *tipos* de debilidad — un lenguaje compartido. <mark style="background: #FFB8EBA6;">En una cadena de vulnerabilidades, se elige el CWE de la vulnerabilidad **inicial**</mark>.
- **CVSS** ([Common Vulnerability Scoring System](https://www.first.org/cvss/)) es el estándar para comunicar la severidad. Las métricas **Base** son las que negocias con el *triage*:

| Métrica | Valores | Qué mide |
| - | - | - |
| Attack Vector (AV) | N / A / L / P | Desde dónde se explota (Network = remoto) |
| Attack Complexity (AC) | L / H | Condiciones fuera del control del atacante |
| Privileges Required (PR) | N / L / H | Privilegios previos necesarios |
| User Interaction (UI) | N / R | ¿Hace falta que la víctima actúe? |
| Scope (S) | U / C | ¿Afecta a componentes fuera del vulnerable? |
| Confidentiality/Integrity/Availability | N / L / H | Impacto en C, I, A |

El `Scope: Changed` es el que más se malinterpreta: aplica cuando el componente **vulnerable** y el **impactado** son distintos (p. ej. XSS → el servidor es vulnerable, el navegador es el impactado). Dominar cada métrica es lo que te permite **defender tu score** ante el *triage* ([[01 - Reglas, legalidad y conducta]]).

> [!info]+ Modernización: CVSS v4.0 y EPSS
> El material clásico usa **CVSS v3.1**. Desde **noviembre de 2023** está [CVSS v4.0](https://www.first.org/cvss/v4-0/) de FIRST, que reestructura el score en **Base / Threat / Environmental / Supplemental** y añade nomenclatura (`CVSS-B`, `CVSS-BT`, `CVSS-BTE`) y métricas de impacto en sistemas subsecuentes. <mark style="background: #FFB86CA6;">Aun así, muchas plataformas siguen puntuando en 3.1</mark> — conoce ambos. Como complemento a la severidad estática, [**EPSS**](https://www.first.org/epss/) estima la *probabilidad* real de explotación, cada vez más usado para priorizar.

> [!warning]+ Por qué rechazan reportes
> Las razones más comunes de un `N/A` o `Informative`: **duplicado**, **fuera de scope**, **sin impacto demostrable**, *self-XSS*, y **falta de pasos de reproducción**. Antes de enviar: confirma que el objetivo está en scope, que el impacto es real y explotable, y que un tercero puede reproducirlo solo con tu PoC.

> [!warning]+ Reconfirma antes de enviar
> Antes de darle a *submit*, para y pregúntate si lo que reportas **es** realmente una vulnerabilidad. Mathias Karlsson —de los mejores del mundo— casi reporta un bypass de *Same-Origin Policy* que afectaba al 7% del top 10.000 de Alexa… hasta que lo reverificó: no había actualizado su SO y el bug estaba parcheado desde hacía **seis meses**. Reproduce en un entorno actualizado y, si puedes, en una segunda máquina o navegador limpio antes de enviar. Su lema: *"no grites hola antes de cruzar el charco"*.

> [!success]+ El PoC que convence
> El *triager* tiene que **vender tu bug internamente**, así que dale munición: pasos numerados reproducibles **solo con el texto** (imágenes/vídeo como apoyo, no como única prueba) y un PoC que demuestre **impacto real**. Para un XSS, no envíes `alert(1)` — prueba con `document.cookie`/`document.domain` o escala a *account takeover* ([estándar de triage de Intigriti](https://kb.intigriti.com/en/articles/10335710-intigriti-triage-standards)). Y recuerda: <mark style="background: #FFB86CA6;">no todas las plataformas usan CVSS</mark> — [Bugcrowd puntúa con su VRT (P1-P5)](https://bugcrowd.com/vulnerability-rating-taxonomy) — ten claro cuál usa tu programa.

> [!example]+ Reportes de referencia
> HackerOne mantiene una selección de reportes ejemplares públicos ([Hacktivity](https://hackerone.com/hacktivity)) — "SSRF in Exchange leads to ROOT access", "RCE in Slack desktop apps", etc. Estudiar reportes reales de bugs que dominas es la vía más rápida para calibrar profundidad y tono.

# Después de enviar: el triager y la recompensa

Al otro lado hay una persona que tiene que **validar tu bug y venderlo internamente**, muchas veces en un equipo pequeño y ahogado en *report noise* —los reportes inválidos que restan tiempo a los válidos— como describe Adam Bacchus (ex-Chief Bounty Officer de HackerOne). Por eso unos pasos de reproducción claros no son cortesía: <mark style="background: #FFB86CA6;">aceleran la validación y, con ella, el pago</mark>. Da tiempo antes de pedir *updates* (unos cinco días hábiles para programas nuevos); si el bug ya está triado, es legítimo preguntar el *timeline* del fix.

Sobre la **recompensa**: respeta la decisión del programa, pero no temas discutirla con argumentos. Jobert Abma (cofundador de HackerOne) aconseja explicar **por qué** crees que merece más, sin exigir a secas:

> Gracias por la recompensa, la aprecio. Tenía curiosidad por cómo se determinó el importe: esperaba `$X`. Creo que este bug podría usarse para `[exploit Z]`, con impacto en `[sistema/usuarios]`. Entenderlo me ayudaría a enfocar mejor mi tiempo en el futuro.

Referenciar un reporte divulgado del **mismo programa** con impacto similar refuerza tu caso; nunca lo compares con pagos de otras empresas (el bounty de A no justifica el de B).

La teoría se ve mejor en la práctica: tres reportes reales anonimizados en [[06 - Ejemplos de reportes (XSS, CSRF, RCE)]].
