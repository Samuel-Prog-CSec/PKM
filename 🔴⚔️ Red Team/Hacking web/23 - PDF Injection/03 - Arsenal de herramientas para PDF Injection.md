---
tags:
  - Web/Red-Team
  - PDF-Injection
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "La explotación de PDF injection es sobre todo manual (inyectar payloads HTML), pero hay tooling clave en las fases de fingerprint, confirmación OOB y post-explotación"
Fecha de actualización: 2026-07-16
Nota previa: "[[02 - Explotación de la generación de PDF]]"
Nota siguiente: "[[04 - Prevención de la generación de PDF]]"
Area: "[[PDF Injection.base|PDF Injection]]"
---
---

La explotación de PDF injection es sobre todo manual (inyectar `payloads` HTML), pero hay tooling clave en las fases de fingerprint, confirmación OOB y post-explotación.

# Fingerprinting: exiftool / pdfinfo

<mark style="background: #ADCCFFA6;">La herramienta más rentable del sub-tema</mark>. Un PDF de muestra + `exiftool` revela el motor y la versión en los campos `Creator`/`Producer`:

```shell-session
$ exiftool invoice.pdf | grep -E 'Creator|Producer'
Creator   : wkhtmltopdf 0.12.6.1
Producer  : Qt 4.8.7
```

`pdfinfo invoice.pdf` da la misma información. Con la versión, se buscan CVEs del motor concreto. Es el paso que decide todo el vector (ver [[01 - Detección y fingerprinting de generadores de PDF|fingerprinting]]).

# Testing local: la propia librería

Descargar el motor objetivo (`wkhtmltopdf` como binario, `DomPDF`/`mPDF` vía Composer) y reproducir la generación en local permite desarrollar los `payloads` sin tocar producción:

```shell-session
$ wkhtmltopdf ./payload.html out.pdf
```

Es la [[05 - Bypass de caracteres comunes|regla de oro de siempre]]: desarrolla el exploit contra una réplica local antes de lanzarlo al objetivo.

# OOB: Interactsh / Burp Collaborator

Para confirmar la SSRF ciega de `<img>`/`<link>` hace falta un endpoint fuera de banda. [Interactsh](https://github.com/projectdiscovery/interactsh) (`interactsh-client` o app.interactsh.com) y Burp Collaborator registran las peticiones DNS/HTTP que fuerza el generador.

# Burp Suite / Caido y CyberChef

**Burp/Caido** (Repeater/Intruder) para inyectar los `payloads` en los campos que alimentan el PDF y automatizar variantes. **[CyberChef](https://gchq.github.io/CyberChef/)** para decodificar el base64 que extrae el [[02 - Explotación de la generación de PDF|LFI vía `btoa()`]].

# Librerías de payloads

[HackTricks — Server Side XSS (Dynamic PDF)](https://book.hacktricks.wiki/en/pentesting-web/xss-cross-site-scripting/server-side-xss-dynamic-pdf.html) y [PayloadsAllTheThings](https://swisskyrepo.github.io/PayloadsAllTheThings/) recopilan los `payloads` de SSRF/LFI/JS para generadores de PDF.

> [!important]+ El orden que rinde
> <mark style="background: #8000E1A6;">`exiftool` primero (5 segundos), réplica local después, Collaborator para la SSRF ciega</mark>. No hay un "sqlmap para PDF"; la potencia está en identificar el motor y adaptar el `payload` HTML al que corresponda. El conocimiento de la [[02 - Explotación de la generación de PDF|nota de explotación]] es lo que hace el trabajo.
