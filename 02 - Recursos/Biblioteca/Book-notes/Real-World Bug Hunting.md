---
tags:
  - Biblioteca
  - Bug-Bounty
Fecha de actualización: 2026-07-22
Autores:
  - Peter Yaworski
Editorial: No Starch Press
Año: 2019
ISBN: 978-1-59327-861-8
Portada: 03 - Archivos/Images/Biblioteca/Real-World Bug Hunting.jpg
PDF: "[[real-worldbughunting.pdf]]"
Estado: Completado
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Real-World Bug Hunting

![Portada de Real-World Bug Hunting](03 - Archivos/Images/Biblioteca/Real-World Bug Hunting.jpg)

**A Field Guide to Web Hacking** — prólogo de Michiel Prins y Jobert Abma (cofundadores de HackerOne).

## Sinopsis

Peter Yaworski (hacker autodidacta, cazador de bug bounties reconocido por Salesforce, Twitter, Airbnb y el Departamento de Defensa de EE.UU.) plantea el libro como una guía de campo, no un manual teórico: cada capítulo introduce un tipo de vulnerabilidad web y lo ilustra con *reports* reales y pagados de programas de bug bounty de empresas como Twitter, Facebook, Google, Shopify o Uber — condiciones de carrera al transferir dinero, parámetros de URL que fuerzan a un usuario a dar "me gusta" a un tweet sin querer, y decenas de casos similares.

El enfoque es deliberadamente práctico y orientado a principiantes en ciberseguridad tanto como a desarrolladores que quieren escribir código más seguro: explica primero cómo funciona internet y los fundamentos de hacking web, para luego recorrer sistemáticamente las clases de vulnerabilidad más comunes (no solo las técnicas, también cómo reconocer la funcionalidad de una aplicación que suele esconderlas). Cierra con la parte más orientada a la profesión — cómo encontrar tus propias bounties, elegir programas y escribir *reports* de vulnerabilidad efectivos que maximicen tanto la aceptación como la recompensa.

## Qué cubre el libro

- Fundamentos de bug bounty hunting y cómo funciona la web a nivel de hacking.
- `Open redirect`, `HTTP Parameter Pollution`, `CSRF`, `HTML injection`/*content spoofing*, `CRLF injection`.
- `Cross-Site Scripting (XSS)`, `Template Injection`, `SQL Injection`, `Server-Side Request Forgery (SSRF)`, `XML External Entity (XXE)`.
- `Remote Code Execution`, vulnerabilidades de memoria, *subdomain takeover*, *race conditions*.
- `Insecure Direct Object References (IDOR)`, vulnerabilidades de `OAuth`.
- Fallos de lógica de aplicación y de configuración.
- Cómo encontrar tus propias bounties (metodología de reconocimiento y elección de programas) y cómo redactar *vulnerability reports* efectivos.
- Apéndices con arsenal de herramientas y recursos adicionales para bug bounty hunting.

## Enlace

[[real-worldbughunting.pdf|Abrir PDF]]

## Notas propias

Contenido extraído e integrado en el vault (2026-07-27), modernizado a 2025-2026 con fuentes primarias (PortSwigger, OWASP, RFCs, `can-i-take-over-xyz`) — decisión y alternativas descartadas en el [[007 - Ingesta del libro Real-World Bug Hunting|ADR 007]].

**Proceso / metodología** — `Red Team/Hacking web/30 - Bug Bounty/`:
- [[03 - Metodología de caza - mapear y atacar la aplicación]] (cap 19: mapeo de funcionalidad + tabla *marker→técnica*).
- [[04 - Mindset del cazador y encadenamiento de bugs]] (cap 1 + *chaining*).
- [[05 - Escribir un buen reporte]] enriquecida con el cap 20 (reconfirmar, triager, apelar recompensa).

**Vulns net-new** — carpetas nuevas en `Hacking web/`:
- [[00 - Introducción a Open Redirect]] (`31`) · [[00 - Introducción a HTTP Parameter Pollution]] (`32`) · [[00 - Fundamentos de Subdomain Takeover]] (`33`) · [[00 - Fundamentos de Race Conditions (TOCTOU)]] (`34`).
- [[11 - HTML Injection, Content Spoofing y Dangling Markup]] (en `04 - XSS/Avanzado`).

**Case studies** del libro (Uber, Twitter, Facebook, Microsoft, Badoo…) embebidos como callouts de ejemplo en las notas de la técnica correspondiente (SSTI, SQLi, SSRF, XXE, RCE, IDOR, CSRF, OAuth).

