---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "El instrumental de descubrimiento de XSS (recolección de parámetros, escáneres, blind) está en 06 - Herramientas para XSS del nivel básico"
Fecha de actualización: 2026-06-08
Nota previa: "[[06 - Evasión de filtros XSS y ofuscación]]"
Nota siguiente: "[[08 - DOM Clobbering]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

El instrumental de **descubrimiento** de XSS (recolección de parámetros, escáneres, blind) está en [[06 - Herramientas para XSS]] del nivel básico. Esta nota cubre el otro lado: las herramientas para **explotar** un XSS confirmado de forma encadenada — exfiltración, post-explotación del navegador y bypass de defensas.

# Infraestructura de exfiltración

La explotación avanzada gira en torno a recibir datos del navegador de la víctima. Dos enfoques:

- **Servidor propio**: el [[00 - Primitivas y entorno de explotación|servidor de exfiltración HTTPS]] en Python, cuando necesitas control total sobre el logging (cuerpos `POST`, cabeceras, múltiples endpoints) o vas a iterar mucho el payload.
- **Colaboradores OOB**: <mark style="background: #ADCCFFA6;">`Burp Collaborator` e `Interactsh` dan un endpoint con TLS válido y DNS público</mark> para recibir *callbacks* sin montar infraestructura. Imprescindibles para [[06 - Herramientas para XSS|blind XSS]] y para confirmar exfiltración cuando no quieres exponer tu IP ni lidiar con certificados autofirmados.

> [!warning]+ El certificado importa
> En un engagement real, el navegador de la víctima rechazará tu servidor si usa un certificado autofirmado (ver [[00 - Primitivas y entorno de explotación]]). Usa un dominio propio con Let's Encrypt o un colaborador con TLS de confianza; de lo contrario, los `fetch`/`XHR` de exfiltración fallarán en silencio.

# Post-explotación del navegador: BeEF

<mark style="background: #FFB8EBA6;">`BeEF` (Browser Exploitation Framework) "engancha" el navegador de la víctima vía un XSS y abre un panel de control</mark> para lanzar módulos: keylogging, pivoting, fingerprinting, ingeniería social. Es potente para demostrar impacto en un informe o en un *red team*. En bug bounty, en cambio, suele bastar un payload a medida (como los de este sub-tema) y BeEF resulta pesado; además, su `hook.js` es muy detectado. Útil para demos de impacto y escenarios de phishing elaborados (ver [[08 - Phishing|phishing con XSS]]).

# Evaluación y bypass de CSP

Cuando hay una [[04 - Content Security Policy (CSP)|CSP]] de por medio, el arsenal es el del [[05 - Bypass de CSP|flujo de bypass de CSP]]: el **[CSP Evaluator](https://csp-evaluator.withgoogle.com/)** para hallar el eslabón débil y **[CSPBypass](https://github.com/renniepak/CSPBypass)** para buscar gadgets JSONP por dominio permitido. Empieza siempre pegando la cabecera en el evaluador.

# Ofuscación de payloads

<mark style="background: #FFB86CA6;">`Hackvertor`</mark> ([extensión de Burp, de Gareth Heyes](https://github.com/hackvertor/hackvertor)) aplica codificaciones y ofuscación con etiquetas inline (`<@base64>...<@/base64>`, `<@hex_entities>`) directamente sobre la petición en Repeater. Es la herramienta clave para iterar bypass de [[06 - Evasión de filtros XSS y ofuscación|WAF y filtros]] sin codificar a mano cada intento — encadenas transformaciones y pruebas variantes en segundos.

# Cierre del sub-tema

```text
Descubrir (básico): gau/Dalfox/DOM Invader/ezXSS
        │
        ▼
Explotar (avanzado): payload a medida (XHR/Fetch)
        ├─ exfil → servidor propio / Interactsh
        ├─ CSP   → CSP Evaluator / CSPBypass
        ├─ filtros → Hackvertor
        └─ post   → BeEF (demos / red team)
```

<mark style="background: #8000E1A6;">La explotación avanzada de XSS es, sobre todo, programación de payloads a medida</mark>: las herramientas asisten (ofuscar, recibir datos, evaluar CSP), pero el núcleo es el JavaScript que escribes para actuar en el contexto de la víctima. Con esto se cierra el recorrido de XSS avanzado y CSRF: del `alert(1)` al pivote completo hacia la red interna.

Tres vectores modernos que el módulo clásico de HTB no cubre amplían el sub-tema, atacando el XSS a través de las abstracciones de la web actual: [[08 - DOM Clobbering]], [[09 - Prototype Pollution hacia XSS]] y [[10 - XSS en frameworks modernos]].

> [!info]+ Fuentes y repos
> - [BeEF](https://github.com/beefproject/beef) · [Hackvertor](https://github.com/hackvertor/hackvertor)
> - [Interactsh](https://github.com/projectdiscovery/interactsh) · [CSP Evaluator](https://csp-evaluator.withgoogle.com/) · [CSPBypass](https://github.com/renniepak/CSPBypass)
