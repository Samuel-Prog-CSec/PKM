---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - Server-Side/SSTI
  - Tipo/Defensa
Descripción: "La prevención de la SSTI parte de una regla simple, derivada de su causa raíz: la entrada del usuario nunca debe llegar al parámetro de plantilla de la función de render —solo a…"
Fecha de actualización: 2026-06-22
Nota previa: "[[04 - Evasión de filtros y sandbox en SSTI]]"
Nota siguiente: "[[06 - Arsenal de herramientas SSTI]]"
Area: "[[SSTI.base|SSTI]]"
---
---

La prevención de la SSTI parte de una regla simple, derivada de su causa raíz: <mark style="background: #ADCCFFA6;">la entrada del usuario **nunca** debe llegar al parámetro de **plantilla** de la función de render</mark> —solo a los **valores**—. Todo lo demás son capas de contención para cuando, por necesidad de negocio, esa regla no se puede cumplir del todo.

# La regla de oro: input como valor, nunca como plantilla

El parche definitivo es auditar los *code paths* y garantizar que ningún input de usuario se concatena en el string de plantilla antes de renderizar. En la práctica:

```python
# MAL: el input forma parte de la plantilla
render_template_string("<h1>Hola " + name + "</h1>")

# BIEN: el input va como valor a una plantilla fija
render_template("hello.html", name=name)
```

<mark style="background: #FF5582A6;">El motor inserta los valores sin ejecutarlos</mark>; el problema solo existe cuando el input toca la plantilla. Revisar cada llamada a `render_template_string` / equivalentes y confirmar que la plantilla es estática cierra la mayoría de casos.

# Cuando el negocio exige plantillas editables

Algunas apps necesitan que el usuario edite o suba plantillas (temas, plantillas de email/factura, *newsletters*). Ahí la SSTI es casi inevitable si no se contiene. Dos enfoques, en orden de fiabilidad:

- **Endurecer el motor** (quitar funciones peligrosas de RCE del entorno de ejecución): reduce la superficie, pero <mark style="background: #FFB86CA6;">es **propenso a bypasses**</mark> —los [[04 - Evasión de filtros y sandbox en SSTI|sandbox escapes]] de Jinja2/Twig demuestran que las listas negras de funciones se sortean—. No confíes solo en esto.
- **Aislar el entorno de ejecución** (lo robusto): renderizar las plantillas no confiables en un **entorno separado del servidor web** —un contenedor Docker dedicado, con *least privilege* y sin red interna—. Aunque haya RCE, queda confinada y no compromete la aplicación ni la red. Es la defensa que recomienda HTB y la más efectiva.

# Medidas complementarias

- **Motores *logic-less***: cuando se puede, usar plantillas sin lógica (estilo `Mustache`) para input no confiable — no ejecutan código, así que no hay SSTI.
- **Sandbox del propio motor**: Jinja2 ofrece `SandboxedEnvironment` y Twig una `SandboxPolicy`. Suben el listón, pero **han sido evadidos** (ver [[04 - Evasión de filtros y sandbox en SSTI|evasión]]) — trátalos como capa, no como garantía.
- **Least privilege**: el proceso que renderiza no debería poder leer secrets ni alcanzar servicios internos —limita el impacto de un escape—.

> [!important]+ Lo que NO ayuda
> La SSTI es **server-side**: una `Content-Security-Policy` o el escape de HTML (defensas de [[00 - Introducción a XSS|XSS]]) **no** la frenan —el código se ejecuta en el servidor antes de llegar al navegador—. El WAF puede filtrar payloads conocidos, pero es capa secundaria, no el parche.

> [!info]+ Fuentes
> - [PortSwigger — Preventing SSTI](https://portswigger.net/web-security/server-side-template-injection#how-to-prevent-server-side-template-injection-vulnerabilities) · [OWASP WSTG — SSTI](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/07-Input_Validation_Testing/18-Testing_for_Server_Side_Template_Injection)
> - [Jinja2 — Sandbox](https://jinja.palletsprojects.com/en/3.1.x/sandbox/) · [Twig — Sandbox extension](https://twig.symfony.com/doc/3.x/api.html#sandbox-extension)

Cierra el sub-tema el inventario de herramientas que automatizan la detección y explotación de SSTI: [[06 - Arsenal de herramientas SSTI]].
