---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Proxies
Fecha de actualización: 2026-06-23
Nota previa: "[[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer]]"
Nota siguiente: "[[10 - Extensiones y BApp Store]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Ambos proxies traen un **escáner de vulnerabilidades** (DAST) que mapea la app y prueba clases comunes de fallos automáticamente. <mark style="background: #FFB8EBA6;">El de Burp es **solo Pro**; el de ZAP es gratis</mark> — y es uno de los principales motivos para tener ZAP en el arsenal aunque trabajes con Burp.

# Las tres fases del escaneo

| Fase | Qué hace | Ruido |
| - | - | - |
| `Crawl` / `Spider` | Sigue enlaces y formularios para construir el **mapa** del sitio | Bajo |
| `Passive scan` | Analiza las respuestas ya vistas **sin enviar** nada nuevo (cabeceras ausentes, DOM XSS potencial) | Cero |
| `Active scan` | **Envía payloads** y verifica (XSS, SQLi, command injection...) | Alto |

<mark style="background: #FFB86CA6;">El crawler solo sigue enlaces existentes</mark> — no descubre páginas no referenciadas (eso es [[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|fuzzing de contenido]] con ffuf/Intruder, que luego añades al scope).

# Burp Scanner (Pro)

Define primero el **scope** (`Target > Scope`): qué entra y, crucialmente, qué se **excluye** (un `/logout` o un endpoint peligroso puede romper tu sesión o causar daño). Desde el historial, clic derecho → `Scan`, o `New Scan` en el Dashboard. Eliges `Crawl` o `Crawl and Audit` (crawl + escaneo). Puedes grabar un **login** para escanear autenticado (cubre más superficie). El active scan tarda mucho; filtras los hallazgos por `High` severidad + `Certain/Firm` confianza:

![Hallazgo de Burp Scanner: OS command injection en el parámetro ip, severidad High, confianza Firm.](https://academy.hackthebox.com/storage/modules/110/burp_high_vulnerabilities.jpg)

# ZAP Scanner (gratis)

Mismo flujo sin coste: **Spider** (clic derecho → `Attack > Spider`) y **Ajax Spider** (sigue enlaces generados por JavaScript/AJAX — importante en SPAs). El passive scan corre solo según el Spider avanza, poblando los **Alerts**. El **Active Scan** prueba payloads y marca los `High`:

![Alerta de ZAP: Remote OS Command Injection, riesgo High, con la evidencia (root:x:0:0... de /etc/passwd).](https://academy.hackthebox.com/storage/modules/110/zap_alert_details.jpg)

Ambos generan **informes** (HTML/XML/Markdown) con severidad, PoC y remediación.

> [!warning]+ Un informe de scanner NO es un pentest
> El error profesional más grave: exportar el informe del scanner y entregárselo al cliente como producto final. <mark style="background: #FF5582A6;">Los DAST encuentran *low-hanging fruit* y generan falsos positivos; no encuentran lógica de negocio, IDOR, bypass de auth ni cadenas complejas</mark> — el grueso del valor de un pentest es **manual** ([[05 - Repeater - repetir y modificar peticiones|Repeater]]). El active scan además es **ruidoso y destructivo**: jamás lo lances contra producción sin autorización explícita y scope acotado. El informe sirve como **anexo** de datos crudos, nunca como el entregable.

> [!info]+ Vigencia: DAST en 2026
> Burp Scanner (DAST) es referencia en pentesting y **Burp Suite DAST** (renombrado desde "Enterprise Edition" en el release 2025.5, mayo 2025) lo lleva a CI/CD. ZAP es el DAST open-source para automatización (`zap-baseline`, Automation Framework) — encaja en pipelines DevSecOps. Como complemento community-driven, <mark style="background: #FFB86CA6;">`nuclei`</mark> (plantillas YAML) cubre CVEs conocidos y exposiciones a una velocidad que los DAST clásicos no igualan. El trío Burp/ZAP/nuclei cubre la mayor parte del escaneo automatizado actual.

> [!info]+ Fuentes
> - [PortSwigger — Burp Scanner](https://portswigger.net/burp/documentation/desktop/scanning) · [ZAP — Automate](https://www.zaproxy.org/docs/automate/) · [nuclei](https://github.com/projectdiscovery/nuclei)
