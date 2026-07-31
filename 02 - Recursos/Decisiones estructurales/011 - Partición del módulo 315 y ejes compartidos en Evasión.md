---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-29
Estado: Aceptada
---
---

## Contexto

Tres módulos del path COAE (AI Red Teamer) planteaban dos decisiones de estructura al extraerlos:

1. **Módulo 315 (*Attacking AI - Application and System*)** mezcla dos cuerpos muy distintos: 8 secciones de ataques a la aplicación/infraestructura de ML (reverse engineering, DoS, rogue actions, stack de MLOps, MLflow) y 5 secciones sobre **MCP** (*Model Context Protocol*). MCP es un protocolo con superficie propia, especificación propia (reescrita a *stateless* el 2026-07-28) y más de 40 CVEs en el primer trimestre de 2026 — y va a seguir creciendo.
2. **Módulos 318 (*Evasion - Foundations*) y 319 (*Evasion - First-Order Attacks*)** son el mismo tema —evasión de modelos— en dos niveles: clasificadores clásicos (GoodWords sobre Naive Bayes) y redes neuronales (FGSM, DeepFool). Comparten fundamentos, defensas y arsenal.

El `CLAUDE.md` ubicaba tentativamente 315 en una carpeta y 318+319 juntos en `05 - Evasión de modelos/`.

## Decisión

**315 → dos Level-2 hermanos**: `04 - Aplicación y sistema/` (11 notas) y `05 - MCP y seguridad de agentes/` (13 notas), cada uno con su `.base`. La herramienta `mcp-scan` se extrae a `02 - Recursos/🛠️ Tools/MCP-Scan/` (3 notas + `.base`), como cualquier herramienta.

**318 y 319 → dos Level-2 hermanos** (`06 - Evasión de modelos/`, `07 - Ataques de primer orden/`) que **comparten los ejes 2 y 3**: las notas de `Detección y defensa` y `Arsenal` viven solo en `06` y cubren explícitamente ambas carpetas; `07` las referencia en vez de duplicarlas.

## Alternativas descartadas

- **315 en una sola carpeta de 24 notas** — un índice `.base` mezclando dos temas sin relación técnica (infra de ML vs. protocolo de agentes), y sin espacio para que MCP crezca como sub-tema propio. La superficie de MCP (spec, CVEs, tooling) justifica carpeta dedicada por sí sola.
- **MCP fusionado con Prompt Injection** — el tool poisoning es prompt injection, sí, pero MCP tiene mucho más (protocolo, inyecciones directas al servidor, OAuth, rug pull, CVEs) que no encaja en el sub-tema de PI.
- **318+319 en una sola carpeta** — habría dado una carpeta de ~13 notas con dos familias técnicas distintas (features estructuradas vs. gradientes). El patrón del vault para esto es Level-2 hermanos (`XSS` + `XSS Avanzado`).
- **Duplicar detección/arsenal en cada carpeta de evasión** — el arsenal (ART, Foolbox, AutoAttack) y las defensas (entrenamiento adversarial, robustez certificada) son **idénticos** para GoodWords y para FGSM/DeepFool. Duplicarlos sería mantenimiento doble de contenido igual. Se centralizan en la carpeta de fundamentos (`06`).

## Consecuencias

- **Mejora**: MCP queda como sub-tema autónomo, listo para crecer con la evolución del protocolo (el módulo se extrajo modernizado a la spec 2026-07-28, no a la de HTB de 2024). Evasión queda con un solo punto de detección/arsenal, coherente y sin duplicación.
- **Precedente**: cuando dos módulos HTB forman **un solo tema**, los ejes 2 (detección/evasión) y 3 (arsenal) se escriben **una vez** para el tema, no por módulo. Es una excepción explícita a "cada módulo net-new cierra con detección + arsenal" del `htb-extraction-workflow`, justificada cuando el contenido sería idéntico.
- **Impacto en `CLAUDE.md`**: tabla del path COAE actualizada (módulos 7-9); el módulo 10 (320, *Sparsity Attacks*) probablemente entra en `07` o como hermano. El `AI Hacking.base` (Level 1) recoge las carpetas nuevas solo, por su filtro de profundidad por regex.
- **Migración**: ninguna — son carpetas net-new, no se movió contenido existente.
