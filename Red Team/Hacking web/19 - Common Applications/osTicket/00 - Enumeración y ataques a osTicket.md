---
tags:
  - Web/Red-Team
  - osTicket
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "osTicket es un sistema de ticketing de soporte open-source (PHP + MySQL), comparable a Zendesk o Jira Service Desk"
Fecha de actualización: 2026-07-16
Nota previa: "[[PRTG Network Monitor]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de GitLab]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

osTicket es un sistema de **ticketing de soporte** open-source (PHP + MySQL), comparable a Zendesk o Jira Service Desk. Su interés no está en las CVEs —es una app muy mantenida— sino en <mark style="background: #FFB86CA6;">abusar de su funcionalidad legítima</mark>. Los portales de soporte se pasan por alto y son minas de oro.

# Fingerprinting

- Cookie **`OSTSESSID`** al visitar la página.
- Pie de página con *"powered by osTicket"* / *"Support Ticket System"*.
- Nmap solo ve el webserver (Apache/IIS), no la app.

CVEs escasas; una reseñable: **CVE-2020-24881** (SSRF, v1.14.1) → acceso a recursos internos / port scanning interno.

# Abuso 1: conseguir un email corporativo

<mark style="background: #FF5582A6;">Un portal de soporte suele asignar una dirección de email interna al abrir un ticket</mark> (p. ej. `940288@inlanefreight.local`). Con ella se pueden registrar cuentas en **otros servicios de la empresa** que exigen un email corporativo + verificación (Slack, GitLab, Wiki, Bitbucket): el correo de confirmación llega al ticket. Es la técnica de la box [Delivery](https://www.youtube.com/watch?v=ULQts2hkV_M) de HTB (IppSec).

# Abuso 2: exposición de datos sensibles (reutilización de credenciales)

Escenario real de externo:

1. OSINT / leaks con **Dehashed** → credenciales en claro de empleados (`kevin:Fish1ng_s3ason!`); reutilizarlas contra el login es [[04 - Password spraying, stuffing y defaults|credential stuffing]].
2. El login de osTicket **acepta email** además de usuario → probar `kevin@inlanefreight.local`.
3. Dentro de la cola del agente de soporte: <mark style="background: #8000E1A6;">tickets cerrados que filtran resets de contraseña</mark> — el agente envió por el portal la "contraseña estándar de nuevos empleados".
4. Esa contraseña estándar + [[00 - Introducción al brute forcing|password spraying]] (con `linkedin2username` para la lista de usuarios) contra el portal VPN → acceso.

> [!important]+ Los portales de soporte no se ignoran
> Ante un portal de ticketing (sobre todo externo): abre un ticket, mira si te asignan un email corporativo, y —si consigues credenciales— busca en la cola resets de contraseña y datos sensibles. La *address book* de osTicket también exporta emails/usuarios para spraying. Sigue igual de válido en 2026 con Zendesk, Jira Service Desk o herramientas custom. Defensa: MFA en todos los portales, no usar el email corporativo en terceros, y política de contraseñas fuerte con cambio obligatorio en el primer login.

Siguiente: el repositorio de código, uno de los objetivos más jugosos, [[00 - Descubrimiento y enumeración de GitLab|GitLab]].
