---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-22
Estado: Aceptada
---

## Contexto

Las 30 carpetas de primer nivel de `🔴⚔️ Red Team/Hacking web/` no tenían orden explícito: Obsidian las listaba alfabéticamente, mezclando fundamentos (Proxies web, Reconocimiento) con temas expertos (Modern Exploitation, HTTP smuggling) sin señal de por dónde empezar. Las notas *dentro* de cada carpeta ya usan prefijo numérico (`00-`, `01-`…); las carpetas no. Se quería fijar un **orden de estudio** navegable directamente desde el árbol de archivos.

## Decisión

Prefijar cada carpeta de primer nivel con `NN - ` (dos dígitos, contiguo `01`–`30`), en **orden de dificultad progresiva** que replica el arco con el que está construido el vault: fundamentos/tooling → núcleo CWES → avanzado CWEE → proceso (Bug Bounty al final). Se **quitó el emoji** de las dos carpetas que lo tenían (`💉🩸 SQL Injection` → `05 - SQL Injection`, `❌💉🩸 NoSQL Injection` → `20 - NoSQL Injection`) para homogeneizar todo a `NN - nombre`.

Renombrado con `git mv` (preserva historial). Efectos colaterales resueltos: `SQL Injection.base` (3 filtros `file.folder.startsWith(...)` con la ruta vieja) reapuntados; tabla de mapeo de `CLAUDE.md` actualizada a los nombres nuevos.

## Alternativas descartadas

- **Ordenar por fase del pentest** (recon → explotación → post) — mezclaría temas triviales y expertos dentro de cada fase; peor como *itinerario de estudio*, que es lo pedido.
- **Agrupar por familia técnica** sin gradiente de dificultad — pierde el "por dónde empiezo".
- **Mantener los emojis tras el número** (`05 - 💉🩸 SQL Injection`) — descartado por consistencia visual; solo 2 de 30 los tenían.
- **Numeración con huecos** (05, 10, 15…) para insertar futuros temas sin renumerar — descartada por incoherencia con el `00-` contiguo de las notas y menor legibilidad; renumerar carpetas es barato (solo `SQL Injection.base` está acoplado a ruta).
- **No tocar `CLAUDE.md`** — descartada: dejaría la tabla de mapeo mintiendo sobre las rutas reales.

## Consecuencias

- Wikilinks, cadena Zettelkasten y campo `Area` **intactos**: Obsidian resuelve por nombre de nota / nombre de `.base`, no por ruta. Renombrar carpetas no rompe nada de eso.
- Único `.base` acoplado a ruta (`SQL Injection.base`) migrado; el Level 1 `Web Pentesting.base` sigue igual (filtra sobre la carpeta padre, que no cambia).
- Las carpetas **aún inexistentes** del roadmap CWEE (Whitebox, Deserialization, Parameter Logic Bugs) quedan **sin numerar** en `CLAUDE.md`; recibirán su `NN - ` al crearse, insertándose en el bloque avanzado (antes de `30 - Bug Bounty`).
- Sienta convención: **carpetas de primer nivel de un área grande se numeran por orden de estudio** — aplicable a futuras áreas (AD, Pentesting ya lo hace con `000-`, `001-`…).
