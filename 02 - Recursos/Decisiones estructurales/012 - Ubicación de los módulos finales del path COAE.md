---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-29
Estado: Aceptada
---
---

## Contexto

Los tres últimos módulos del path COAE (AI Red Teamer) planteaban decisiones de ubicación que el `CLAUDE.md` dejaba explícitamente abiertas:

1. **320 (*AI Evasion - Sparsity Attacks*)** — ataques $L_0$ (ElasticNet/EAD y JSMA). El mapeo tentativo decía "`07 - Ataques de primer orden/` o Level-2 hermano".
2. **335 (*AI Privacy*)** — mezcla un **ataque** (membership inference con shadow models) con dos **defensas** (DP-SGD y PATE) en un solo módulo.
3. **322 (*AI Defense*)** — 100 % ingeniería defensiva: guardrails LLM, entrenamiento adversarial y *safety fine-tuning*. El mapeo decía "`🔵🛡️ Blue Team/` *(a decidir)*".

## Decisión

**320 → Level-2 hermano `AI Hacking/08 - Ataques dispersos/`** (10 notas), que **comparte** las notas de detección/defensa y arsenal de `06 - Evasión de modelos` — extendidas con lo específico de $L_0$ (ablación aleatoria, filtrado de mediana, `sAT`/`sTRADES`, σ-zero, Sparse-RS). Es la aplicación directa del precedente de ADR 011: 318, 319 y 320 son el mismo tema (*Evasión*) en tres niveles, y los ejes 2 y 3 se escriben **una vez por tema**, no por módulo.

**335 → `AI Hacking/09 - Privacidad en IA/` completo** (12 notas), ataque y defensas juntos.

**322 → `🔵🛡️ Blue Team/007 - Defensa de sistemas de IA/`** (11 notas + `.base` propio), con enlaces cruzados densos desde `01 - Prompt Injection/13`, `02 - LLM Output Attacks/13`, `04 - Aplicación y sistema/01` y `06 - Evasión de modelos/04`.

La regla que emerge y que conviene fijar: <mark>una **nota** de defensa (eje 2/3, resumen para el atacante) vive junto al ataque en Red Team; un **módulo entero** de ingeniería defensiva vive en Blue Team.</mark>

## Alternativas descartadas

- **320 fusionado en `07 - Ataques de primer orden`** — habría dado una carpeta de ~15 notas mezclando dos familias con matemática (proximal/combinatoria frente a gradiente), modelo de amenaza (número de features frente a magnitud) y defensas (ablación aleatoria frente a PGD-AT) distintas.
- **335 partido, con DP-SGD y PATE a Blue Team** — más puro conceptualmente, pero parte una cadena Zettelkasten a mitad de módulo y separa el ataque de su contramedida directa. Y hay un argumento operativo: el red teamer necesita DP-SGD y PATE para **auditar** la afirmación de privacidad de un cliente ("dices $\varepsilon=3$, demuéstralo"), que es hoy el trabajo con más valor en esta área. La privacidad es un tema coherente; partirlo lo empeora.
- **322 partido, con los guardrails a Red Team** — se descartó por duplicación: `01 - Prompt Injection/13` y `02 - LLM Output Attacks/13` ya cubren los guardrails desde el lado ofensivo. Traer el material de construcción a Red Team habría creado dos tratamientos del mismo tema a dos metros de distancia.
- **322 entero en AI Hacking** — mantendría el path COAE junto, pero rompe la separación Red/Blue del vault e infla `AI Hacking` con contenido puramente defensivo. La cohesión del path no es un objetivo del vault: la organización es **por tema**, no por certificación (ADR 009).

## Consecuencias

- **`AI Hacking` cierra con 10 Level-2** (`00`–`09`). `Evasión` queda como tema de tres carpetas (`06`/`07`/`08`) con un único punto de detección y arsenal, sin duplicación.
- **Blue Team estrena `007`**, y con ello una distinción que hay que mantener clara: `005 - IA aplicada a la defensa` es *IA para defender* (detectores ML); `007 - Defensa de sistemas de IA` es *defender la IA*. Nombres parecidos, temas distintos.
- **Precedente para el futuro**: cuando un módulo mezcla ataque y defensa del mismo tema, se mantiene junto en Red Team; cuando el módulo **es** la defensa, va a Blue Team con puente ofensivo explícito (la nota `10 - Límites de las defensas y cómo se rompen` cumple ese papel y es net-new).
- **Impacto en `CLAUDE.md`**: filas 10-12 de la tabla COAE actualizadas; nota sobre la distinción 005/007; erratas de los tres módulos registradas. Los `.base` Level 0/1 (`AI Hacking.base`, `Blue-Team.base`) recogen las carpetas nuevas solos, por sus filtros de profundidad.
- **Migración**: ninguna. Las tres carpetas son net-new; solo se **extendieron** `06/04` y `06/05` con el contenido $L_0$ compartido.
