---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-21
Estado: Aceptada
---

## Contexto

Se evaluaron 4 skills de Matt Pocock (aihero.dev / `github.com/mattpocock/skills`): **grill-with-docs**, **research**, **wayfinder** (la 4ª URL era grill-with-docs duplicada). Son piezas de un sistema SWE componible en torno a un **repo de código + issue tracker**; el PKM es un **vault de notas**. Ya habíamos adaptado antes `grill-me` → `pkm-design-grilling` e `improve-codebase-architecture` → `pkm-structure-audit`.

## Decisión

1. **`research` → nueva skill `pkm-research`**: fuentes primarias/oficiales, cita por-claim, subagente en background. Referenciada por el **eje 1** de `htb-extraction-workflow` e invocable a demanda (bug bounty/pentest).
2. **`grill-with-docs` → idea de ADR log** en `pkm-design-grilling`: registrar la decisión ejecutada como ADR (contexto → decisión → alternativas → consecuencias) en `02 - Recursos/Decisiones estructurales/`.
3. **`wayfinder` → obviado.**

## Alternativas descartadas

- **Adoptar `wayfinder`** — atada a un issue tracker con dependencias nativas + orquestación SWE multi-sesión; fuera de dominio. El "mapa de decisiones" ya lo cubren las MOC `.base` + las tablas-roadmap de `CLAUDE.md`.
- **Instalar las skills vía `npx skills add`** — descartada por **postura de seguridad** (skills de terceros); adopción por **lectura + reimplementación** local, como con las anteriores.
- **Bakear `research` inline en el eje 1 sin skill propia** — una skill fina da **reutilización a demanda** + DRY (el eje 1 la referencia en vez de duplicar el "cómo").
- **Adoptar el glosario/`CONTEXT.md` de grill-with-docs** — en un vault ya lo cubren las MOC `.base` + `CLAUDE.md`.

## Consecuencias

- Nueva skill `pkm-research`; ADR log en `pkm-design-grilling` (paso final del interrogatorio).
- El eje 1 y el inventario de skills de `CLAUDE.md` apuntan a `pkm-research`.
- **Este mismo conjunto de ADR estrena el mecanismo** (dogfooding).
