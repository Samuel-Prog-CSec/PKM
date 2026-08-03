---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-03
Estado: Aceptada
---
---

## Contexto

*Cyberjutsu* (Ben McCarty, No Starch Press, 2021) no es un libro de técnicas ni de web: es un libro de **doctrina y modelo mental** que mapea los pergaminos ninja (siglos XVII) contra las TTPs modernas y cierra cada capítulo con controles NIST 800-53. Es generalista y **mitad ofensivo, mitad defensivo**. Al cruzar sus 26 capítulos con el vault, las técnicas concretas (living-off-the-land, C2, supply chain, OPSEC) ya estaban muy cubiertas, pero faltaba la capa de **doctrina, threat intelligence y mindset**: `zero-trust` (0 notas), atribución/banderas falsas (0), *threat modeling* dedicado, Diamond Model, y el mindset del atacante persistente como marco unificador.

## Decisión

Integración **híbrida, selectiva y bicéfala**, en dos áreas nuevas que leen el mismo material desde lados opuestos:

- **`Red Team/Doctrina pentesting/`** (área Level 1, 5 notas 00-04 + `.base`): lo net-new ofensivo — "cómo el atacante evade". Mindset APT, frameworks de TI/Pyramid of Pain, atribución/false flags, coordinación de operadores, timing y circunstancias.
- **`Blue Team/04 - Doctrina defensiva/`** (aprovecha el hueco 04, 5 notas 00-04 + `.base`): lo defensivo — "cómo el ingeniero de seguridad defiende". Threat modeling/guarding, sensores, zero-trust, deception, cultura del SOC.

Además: **enriquecer** notas existentes donde ya había base (Footprinting → mapa del atacante; Evasividad → disciplina light/noise/litter + timing); **modernizar** todo a 2026 (NIST CSF 2.0, ATT&CK v19, ZTMM 2.0, casos Volt Typhoon / Olympic Destroyer); **descartar** los capítulos de gestión (Hiring Shinobi) y físico (Locks); y **enlazar en vez de duplicar** lo ya cubierto.

## Alternativas descartadas

- **Extracción exhaustiva 26 notas 1:1** (estilo módulo HTB) — produce mucha redundancia con lo ya cubierto y notas de tipo "ensayo" ajenas al Zettelkasten técnico del vault.
- **Solo enriquecer, sin área nueva** — deja sin sitio propio los conceptos net-new (zero-trust, atribución), que quedarían diluidos en notas de otras áreas.
- **Meter todo (ofensivo + defensivo) en Red Team** — el libro es mitad defensivo; forzarlo a RT desperdicia esa mitad o la disfraza. Repartir a Blue Team la aprovecha y respeta que Blue Team tiene carpeta propia (decisión del usuario).
- **Colgar el área bajo `Pentesting/`** como carpetas numeradas — el mindset/doctrina es transversal a todo Red Team (AD, web, wifi), no solo al pentest de infraestructura; un área hermana lo refleja mejor.

## Consecuencias

- +2 áreas de doctrina, +10 notas atómicas, 2 cadenas Zettelkasten nuevas, 2 `.base` Level 2. **Blue Team estrena su primera área de doctrina** (estaba embrionario fuera de IA).
- **Tags nuevos**: `Doctrina`, `Threat-Intelligence`, `Atribucion` (RT); `Threat-Modeling`, `Zero-Trust`, `Deception`, `SOC` (BT). "Threat Intelligence" queda como tag, no como nombre de área.
- El área RT **no se asocia a certificación** — `Red-Team.base` la marca "Sin certificación asociada", correcto: es contenido de libro, no de un path HTB.
- Sienta el **precedente de cómo ingerir un libro de doctrina/mindset** (distinto del de técnicas — *Real-World Bug Hunting*, ADR 007 —, cuyo contenido fundaba carpetas de técnica).
- Impacto en `CLAUDE.md`: se registra en la tabla de "Módulos extra / libros".
- **Extensión net-new** (posterior, a petición del usuario): la única técnica concreta del libro —canales encubiertos por air-gap, cap. *Bridges & Ladders*— se ingirió como `Pentesting/07 - Pivoting y túneles/14 - Canales encubiertos y salto de air-gap`, insertada con renumeración de detección (→15) y arsenal (→16) vía `app.fileManager.renameFile` (auto-actualiza wikilinks), y modernizada con la investigación de Guri/BGU (RAMBO, PIXHELL 2024).
