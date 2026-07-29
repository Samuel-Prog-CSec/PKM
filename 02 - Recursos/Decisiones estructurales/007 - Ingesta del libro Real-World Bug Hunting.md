---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-27
Estado: Aceptada
---
---

## Contexto

*Real-World Bug Hunting* (Peter Yaworski, No Starch Press, 2019) es material de referencia para bug bounty real, con decenas de *reports* pagados como casos de estudio. Se decidió ingerir su contenido útil al vault distinguiendo **proceso/metodología** de **vulns concretas**, sin duplicar las explicaciones de explotación que ya viven en `🔴⚔️ Red Team/Hacking web/`. El libro es de 2019, así que exigía modernización, no traducción literal.

## Decisión

1. **Proceso → sección Bug Bounty** (`30 - Bug Bounty/`): 2 notas net-new (metodología de caza, cap 19; mindset + *chaining*, cap 1) + enriquecimiento de la nota de reporte con el cap 20. Renumeradas las notas de reporte `03/04 → 05/06` para el orden lógico recon → caza → mindset → reporte → ejemplos.
2. **Vulns net-new → carpetas propias `31-34`** en `Hacking web/` (continuando la numeración por orden de estudio del ADR 004): Open Redirect, HTTP Parameter Pollution, Subdomain Takeover, Race Conditions — cada una con su `.base` Level 2 y los 3 ejes **proporcionados al tamaño del tema**. HTML Injection / Content Spoofing / Dangling Markup → nota en `04 - XSS/Avanzado/` (por afinidad y bajo volumen, sin carpeta propia).
3. **Case studies → embebidos** como callouts de ejemplo en la nota de la técnica correspondiente (Uber Jinja2 SSTI → nota SSTI, etc.), no en un índice aparte.
4. **Modernización obligatoria** con fuentes primarias 2025-2026 (PortSwigger, OWASP, RFCs, `can-i-take-over-xyz`) vía subagentes de investigación en background; lo desfasado se señala explícitamente.

## Alternativas descartadas

- **Fundir Race Conditions en `28 - Modern Exploitation` y Content Spoofing en XSS, sin carpetas propias** — descartado para Race (da para 4 notas con la modernización de PortSwigger 2023: *single-packet attack*, *First Sequence Sync*), aceptado solo para Content Spoofing (bajo volumen).
- **Índice de casos centralizado en Bug Bounty** — descartado: duplicaría contenido y sacaría los casos de su contexto técnico. El embedding en la nota de la técnica es más Zettelkasten.
- **Traducir el libro tal cual** — descartado: propagaría técnicas de 2019 obsoletas (p. ej. Fastly/Zendesk/SendGrid ya no son explotables por CNAME colgante; el open redirect ya no es "informativo").
- **Un folder paraguas para todas las vulns del libro** — descartado: mezcla temas dispares; las carpetas atómicas encajan con el resto del vault.

## Consecuencias

- `Hacking web/` pasa de 30 a **34 carpetas** numeradas; el `.base` Level 1 (`Web Pentesting.base`) las auto-descubre (filtra por `file.folder.startsWith`), sin tocar su filtro.
- Sección Bug Bounty: **5 → 7 notas**, cadena recosida (renumerado de reporte).
- **+13 notas net-new + 4 `.base`**; ~8 notas de explotación existentes enriquecidas con un case study cada una.
- `CLAUDE.md` actualizado (mapeo del libro + recuento Bug Bounty); catálogo del libro marcado como leído.
- El libro queda como material **vivo**: futuras relecturas pueden re-embeber más casos sin cambiar la estructura.
