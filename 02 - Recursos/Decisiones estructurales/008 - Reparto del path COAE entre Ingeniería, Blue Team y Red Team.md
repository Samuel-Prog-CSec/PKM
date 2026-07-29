---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-28
Estado: Aceptada
---
---

## Contexto

El path **AI Red Teamer** (certificación HTB COAE) tiene 12 módulos, pero solo una parte es ofensiva. Los dos primeros módulos son teoría de ML/DL pura (`Fundamentals of AI`) y tres detectores **defensivos** — spam, anomalías de red y malware — construidos con `scikit-learn` y `PyTorch` (`Applications of AI in InfoSec`). Meter todo eso bajo `🔴⚔️ Red Team/AI Hacking/` habría contradicho dos reglas ya establecidas del vault: *fundamentos ≠ ofensiva* y *lo Blue Team va a su carpeta*.

## Decisión

El path se reparte en **tres áreas**, con cross-links entre ellas:

- **`Ingenieria/Inteligencia Artificial/`** — teoría de ML/DL (mód. 290) y el pipeline de trabajo con datos (parte del mód. 292). Tres sub-temas con `.base` Level 2 e índice Level 1 propio.
- **`🔵🛡️ Blue Team/005 - IA aplicada a la defensa/`** — los tres detectores defensivos del mód. 292, más una nota net-new sobre cómo se evaden.
- **`🔴⚔️ Red Team/AI Hacking/`** — todo el contenido ofensivo (mód. 294 en adelante), en carpetas numeradas por módulo del path.

La cadena Zettelkasten atraviesa las tres áreas sin cortarse: fundamentos → pipeline → detectores forman una sola cadena; el bloque ofensivo arranca su propia cadena.

## Alternativas descartadas

- **Todo en `🔴⚔️ Red Team/AI Hacking/`** (lo que se pidió literalmente al principio). Autocontenido y fiel al path, pero entierra conocimiento de ingeniería y contenido defensivo bajo Red Team, donde queda invisible para los módulos futuros de **AI Privacy** (335) y **AI Defense** (322), y para cualquier trabajo de Blue Team. Rompe el precedente Footprinting↔`Redes/Protocolos` y SQLi↔`Ingenieria/Bases de Datos`.
- **Todo el módulo 292 a Blue Team.** Más simple —un módulo, una carpeta—, pero encierra en Blue Team el pipeline genérico (métricas, preprocesado, transformación) que reutilizan todos los demás módulos y que no tiene nada de defensivo.
- **Carpetas de AI Hacking por superficie de ataque** (modelo/datos/aplicación/sistema) en vez de por módulo. Más conceptual y alineado con la taxonomía de SAIF, pero obliga a repartir cada módulo futuro entre varias carpetas y rompe el orden de estudio.

## Consecuencias

- Un módulo puede repartirse entre dos áreas (el 292 lo hace). Ya había precedente: Footprinting se repartió entre `Pentesting/`, `Redes/` e `Ingenieria/`.
- `🔵🛡️ Blue Team/` recibe su **primer `.base`** y sus primeras notas con frontmatter completo y tags. El resto del área sigue siendo legacy sin tags ni bases — deuda pendiente, no abordada aquí.
- `Ingenieria/` gana un área nueva con índice Level 1 (`Inteligencia Artificial.base`) y tres Level 2.
- Se arregló de paso `🔴⚔️ Red Team/Red-Team.base`, que filtraba por `file.basename.contains("Pentesting")` y por tanto **ya se dejaba fuera** Active Directory y Evasión de defensas. Ahora indexa por regex los `.base` a un nivel de profundidad.
- Tags nuevos: `IA` (área), `IA/Machine-Learning`, `IA/Deep-Learning`, `IA/Generativa`, `IA/LLM`, `IA/Pipeline`, `IA/Adversarial`, `IA/Defensa`, `IA/Red-Team` (paralelo a `Web/Red-Team`) y `Blue-Team`.
- `CLAUDE.md` incorpora la certificación COAE, su tabla de mapeo módulo→carpeta y las notas operativas del path.
