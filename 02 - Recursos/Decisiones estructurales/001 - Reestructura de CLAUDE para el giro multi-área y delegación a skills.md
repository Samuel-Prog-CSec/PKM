---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-21
Estado: Aceptada
---

## Contexto

`CLAUDE.md` se escribió al arrancar las notas de Red Team **web** (CWES/CWEE). Con el giro a **CPTS** (pentest generalista) y la voluntad de explorar más áreas y certificaciones, el documento quedó **web-céntrico** (misión, plantilla con tag `Web/Red-Team` hardcodeado, anotaciones "no aplica para CWES/CWEE"). Además **re-codificaba ~230 líneas** que las skills locales (`pkm-note-format`, `htb-extraction-workflow`, `zettelkasten-linking`) ya poseían de forma más rica → **dos fuentes de verdad** con riesgo de *drift*. También arrastraba un changelog fechado que crecía sin fin y rutas stale.

## Decisión

1. **Reencuadrar** `CLAUDE.md` como guía **multi-área / multi-certi**, con una **receta genérica** para dar de alta certis/áreas nuevas (no solo web).
2. Sacar el **changelog fechado** de la misión → vive en memoria (`project_cpts_*`) + columna `Estado` de la tabla CPTS.
3. **Adelgazar** "Convenciones de nota" y "Flujo de extracción" a lo esencial siempre-cargado + **puntero a las skills** como **fuente autoritativa** del workflow.

## Alternativas descartadas

- **Mantener todo inline en `CLAUDE.md`** — *drift* garantizado + contexto inflado cada sesión.
- **Borrar por completo de `CLAUDE.md` lo que cubren las skills** — se pierde la red de seguridad "siempre en contexto" (frontmatter, glosario de color, 3 ejes) si la skill no se dispara. Por eso se conservó un núcleo compacto.
- **Condensar/borrar las tablas de mapeo web ya completadas** — son referencia estructural estable y útil; se conservan.

## Consecuencias

- `CLAUDE.md` pasa de ~545 a ~450 líneas; las **skills son la fuente autoritativa** del formato/flujo.
- Se conservan por ser **exclusivos** del `CLAUDE.md`: la jerarquía `.base` de 2 niveles y el atajo de extracción vía API de HTB.
- Se arreglaron rutas stale (`Ingenieria/`, `02 - Recursos/Templates/`, `03 - Archivos/Images/`) y se generalizó el tag `Web/Red-Team` → `<área>`.
- Habilita el patrón repetible para futuras certis/áreas sin re-improvisar.
