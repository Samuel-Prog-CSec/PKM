---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-21
Estado: Aceptada
---

## Contexto

El estándar de calidad **detección · evasión · arsenal + fuentes + gráficos** estaba **enterrado dentro de la sección CPTS** del `CLAUDE.md`, pero aplica a **todo** contenido net-new del vault. Faltaba además: (a) una **regla de forma** clara para los deliverables `Detección y evasión` y `Arsenal de herramientas`; (b) enmarcar bien el eje de investigación, que estaba redactado como **condicional a que el contenido estuviese desfasado**.

## Decisión

1. **Promover los 3 ejes** a sección transversal `## Estándares de calidad — los 3 ejes (todo el vault)`.
2. **Investigar/profundizar con fuentes oficiales = SIEMPRE**, para todo contenido de todo módulo. La desactualización es un **sub-caso** en el que, además, se **moderniza**.
3. **Regla de forma** para `Detección y evasión` y `Arsenal de herramientas`: **nota dedicada por defecto**; **excepción** si HTB ya cubre el tema → respetar su formato e investigar a fondo para modernizar/ampliar (sin forzar nota aparte).

## Alternativas descartadas

- **Dejar el estándar solo bajo CPTS** — aplica a todo el vault, no solo a red/infra.
- **Investigar solo cuando el contenido parece desfasado** — rechazada por el usuario: la investigación es constante.
- **Deliverables según volumen** (abundante → dedicada, poco → embebida) — sustituida por el predicado observable *¿HTB lo cubre?*.
- **Nota dedicada SIEMPRE sin excepción** — redundante cuando HTB ya estructura el tema; mejor respetar su formato y modernizar.

## Consecuencias

- Sección transversal en `CLAUDE.md`; en la tabla CPTS queda un puntero.
- `htb-extraction-workflow` **enforcea** los deliverables: se declaran en el plan (Fase 0.3) y se verifican en el cierre (Fase 3, "si falta alguno → no cerrar el módulo").
- `pkm-note-format` gana la sección **§ Fuentes**; el eje 1 se materializa en la skill [[003 - Adopción selectiva de skills de aihero.dev|pkm-research]].
