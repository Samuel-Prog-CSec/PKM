---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Reporting
Fecha de actualización: 2026-07-17
Nota previa: "[[03 - Escribir un buen reporte]]"
Nota siguiente: ""
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

Tres reportes reales anonimizados que aplican la plantilla de [[03 - Escribir un buen reporte]]. Lo instructivo no es el bug — es **cómo se justifica cada métrica CVSS** y cómo se redacta el impacto en términos de negocio.

# Ejemplo 1 · Stored XSS

- **Título**: Stored Cross-Site Scripting (XSS) in X Admin Panel
- **CWE**: [CWE-79](https://cwe.mitre.org/data/definitions/79.html) — Improper Neutralization of Input During Web Page Generation
- **CVSS 3.1**: `5.5 (Medium)` — `AV:N/AC:L/PR:H/UI:N/S:C/C:L/I:L/A:N`

El nombre de un fichero subido (en *Admin Info → Secure Data Transfer*) se refleja y **se almacena** sin sanear — un [[01 - XSS Almacenado|XSS almacenado]] de manual. Un admin malicioso sube un fichero con JS en el nombre; otro admin lo dispara al visualizarlo.

```html
"><svg onload=alert(document.cookie)>.docx
```

<mark style="background: #FFB86CA6;">Justificación clave</mark>: `PR:H` (solo un admin llega al panel), `S:C` (el componente vulnerable es el servidor pero el impactado es el navegador → *scope changed*), `C:L/I:L` (XSS toca el DOM y altera la integridad de forma limitada), `A:N` (XSS no tira el servicio).

# Ejemplo 2 · CSRF

- **Título**: Cross-Site Request Forgery (CSRF) in Consumer Registration
- **CWE**: [CWE-352](https://cwe.mitre.org/data/definitions/352.html) — Cross-Site Request Forgery
- **CVSS 3.1**: `5.4 (Medium)` — `AV:N/AC:L/PR:N/UI:R/S:U/C:L/I:L/A:N`

La petición que crea una *fintech application* **no lleva [[01 - Fundamentos y defensas de CSRF|token anti-CSRF]]**. Se craftea una página HTML maliciosa que, si la visita una víctima con sesión activa, crea la aplicación en su nombre.

<mark style="background: #FFB86CA6;">Justificación clave</mark>: `PR:N` (el atacante no necesita privilegios), `UI:R` (la víctima **debe** visitar la página maliciosa — diferencia esencial con el XSS almacenado). Nota profesional del reporte: *"podría ejecutarse en background si se combina con el hallazgo 6.1.1"* (un XSS) — <mark style="background: #FF5582A6;">encadenar hallazgos sube el impacto</mark> y es lo que distingue un buen reporte.

# Ejemplo 3 · RCE (deserialización)

- **Título**: IBM WebSphere Java Object Deserialization RCE
- **CWE**: [CWE-502](https://cwe.mitre.org/data/definitions/502.html) — Deserialization of Untrusted Data
- **CVSS 3.1**: `9.8 (Critical)` — `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H`

El servidor WebSphere (HTTPS puerto 8880) acepta objetos Java serializados en base64 — <mark style="background: #ADCCFFA6;">identificables por la cabecera `rO0`</mark> — los bytes mágicos `AC ED 00 05` de un stream Java serializado, en base64, empiezan por `rO0`. Se craftea una petición SOAP con un objeto que explota la librería Apache Commons Collections (ACC) → ejecución de un `ping` en el servidor.

<mark style="background: #FFB86CA6;">Justificación clave</mark>: todo `None`/`High` en los peores valores — no-auth (`PR:N`), sin interacción (`UI:N`), y `C:H/I:H/A:H` porque RCE = control total. Resultado: el `9.8` casi máximo.

> [!info]+ Modernización: dónde queda esto hoy
> Los tres ejemplos usan **CVSS v3.1**; desde **noviembre de 2023** existe [CVSS v4.0](https://www.first.org/cvss/) (detalle en [[03 - Escribir un buen reporte]]), aunque muchas plataformas siguen en 3.1. El ejemplo de RCE es un **gadget de deserialización Java** (`rO0` + Apache Commons Collections) — la puerta de entrada al mundo de [[Deserialización Java|deserialización insegura]], uno de los temas centrales del path CWEE. El `rO0` en cualquier parámetro es un *tell* que todo cazador debe reconocer al instante.
