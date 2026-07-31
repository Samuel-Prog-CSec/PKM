---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-31
Estado: Aceptada
---

## Contexto

Cierre de los dos módulos CPTS que quedaban sueltos: el **#1 (Penetration Testing Process)**, teórico, cuya carpeta `000 - Fases del Pentesting/` contenía 1 nota real (`Pentesting.md`) + 6 placeholders vacíos con nombres emoji (`1️⃣ Enumeracion`, `2️⃣ Búsqueda de vulnerabilidades`…); y el **#28 (Attacking Enterprise Networks)**, capstone que es un walkthrough guiado de un pentest completo cuyas técnicas ya están **casi todas cubiertas** en el vault (Footprinting, web, AD, privesc, pivoting).

Dos decisiones de diseño, ambas con alternativa real descartada.

## Decisión

**1. Renumerar `000 - Fases del Pentesting/` a la convención numérica del resto de `Pentesting/`.** Se borran los 6 placeholders emoji y se reescribe `Pentesting.md`, quedando 14 notas `00`-`13`. Alinea el sub-tema con `001 - Footprinting/`, `002 -`, etc. Se recosen los 3 wikilinks externos que apuntaban a los nombres viejos (Metasploit, Footprinting, AI Hacking, más 3 de otros módulos de Pentesting).

**2. Escribir el capstone #28 en modo *playbook + cadena de ataque*, no como walkthrough fiel.** Cada nota desarrolla la **metodología, las decisiones, los callejones sin salida y las transiciones** entre técnicas; las técnicas ya cubiertas se **enlazan** en vez de reexplicarse, y solo se desarrolla a fondo lo net-new. 18 notas `00`-`17`.

## Alternativas descartadas

- **Mantener los nombres emoji del 000** — cero renombrados y cero wikilinks que recoser, pero dejaba el sub-tema desalineado del resto de `Pentesting/` (todos numéricos `NN - `). El coste del recosido (6 archivos) era bajo y la coherencia vale más.
- **Capstone como walkthrough fiel paso a paso** — más autocontenido, pero habría duplicado ~40k palabras ya presentes en Footprinting/AD/privesc/web. El vault es Zettelkasten: la redundancia masiva es deuda, no valor.
- **Capstone híbrido (playbook + apéndice de comandos copy-paste)** — descartado por ahora; el apéndice de comandos es justo lo que la cadena de ataque de la nota 00 y el arsenal de la 17 ya condensan sin duplicar.

## Consecuencias

- **CPTS queda completa**: los 28 módulos net-new hechos. Tablas de path y sección "Misión y estado" de `CLAUDE.md` actualizadas.
- `000 - Fases del Pentesting/` pasa de 1+6 a **14 notas** con cadena Zettelkasten `00`→`13`, `.base` Level 2 intacto (mismo filtro por `Area`).
- Nuevo sub-tema **`011 - Ataque a redes empresariales/`** (18 notas + `.base`), recogido automáticamente por el Level 1 `Pentesting.base` (regex de carpeta) y su fórmula `fase` (ampliada con `/011 -` → "5 · Engagement completo").
- El capstone sienta un **precedente de forma** para futuros módulos-recopilatorio o capstones de otras certis: playbook que enlaza lo existente y solo desarrolla lo net-new + los 2 ejes (detección/evasión y arsenal). Reutilizable para el capstone de COAE si lo hubiera.
- Deuda cerrada: los placeholders emoji eran deuda estructural señalada desde que se creó el sub-tema.
