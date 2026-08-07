---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-04
Estado: Aceptada
---
---

## Contexto

El vault acumula mucho conocimiento de Red Team (web, pentesting, AD, IA ofensiva, evasión, Wi-Fi, protocolos, desarrollo ofensivo) pero ninguna pieza que lo materialice en **herramientas propias para el portfolio profesional** de Samuel como pentester. Se quería un catálogo de proyectos **originales** (no el clásico "escáner de puertos"), cada uno resolviendo un problema real, ordenados por dificultad y **todos en Go moderno** como lenguaje único. El catálogo se planteó como *definición* (alcance, funcionalidades, consideraciones), no como código.

## Decisión

Crear el área **`Red Team/Proyectos/`** con un **tercer tipo de nota** del vault —la **ficha de proyecto**—, que describe un proyecto sin construirlo. Convenciones propias:

- **Frontmatter extendido** sobre el estándar: `Estado` (Idea / En curso / Terminado / Descartado), `Dificultad` (1-5), `Esfuerzo`, y tag `Tipo/Proyecto`. Sí conservan cadena Zettelkasten y `Area` (a diferencia de ADR/Biblioteca/Home).
- **Numeración incremental `0X`** que marca el orden de la cadena. Los proyectos nuevos **se añaden al final** (07, 08…), **sin renumerar** los existentes; el `.base` Level 2 `Proyectos ofensivos.base` es quien **ordena por `Dificultad`** de verdad en sus vistas. La numeración de fichero y la dificultad se mantienen mayormente alineadas, pero la fuente de orden es el campo, no el nombre.
- **Estructura de nota fija**: problema · alcance · funcionalidades · qué existe ya y dónde se queda corto · cosas a tener en cuenta · fuera de alcance · criterio de terminado · conexiones en el vault · fuentes citadas (con fecha de consulta). Cada proyecto cruza-enlaza con las notas de técnica que lo fundamentan.
- **Presencia en la Home**: sección dedicada «Proyectos ofensivos» (bloque `dataviewjs` nuevo) que lista el catálogo coloreado por dificultad. `Tipo/Proyecto` **se excluye** de la sección «Los ejes del vault» de la Home.

Alta inicial: **16 fichas** (00-15), de dificultad 1 a 5, cerrando con dos capstones integradores (`overwatch`, `lowprofile`).

## Alternativas descartadas

- **Renumerar por dificultad al insertar** cada proyecto nuevo — obligaría a recoser la cadena Zettelkasten y reescribir enlaces/`.base` de N notas por cada alta. Frágil y de poco valor: el `.base` ya ordena por `Dificultad`, así que el número de fichero no necesita ser estrictamente monótono.
- **Dispersar los proyectos por sus áreas temáticas** (el de SSRF en `Hacking web`, el de AD en `Active Directory`…) — se pierde el catálogo como unidad de portfolio, y los capstones cruzan varias áreas y no tienen carpeta natural. Un área única transversal es más fiel a lo que es: una colección de portfolio, no conocimiento nuevo.
- **Tratar `Tipo/Proyecto` como un eje más** en la Home (como Detección/Arsenal/Defensa) — un proyecto es una nota-artefacto, no una faceta transversal del conocimiento; listarlo entre los ejes lo mezcla con algo de otra naturaleza y duplica su nueva sección dedicada.
- **Un proyecto por módulo HTB o por área, por cobertura** — se priorizó originalidad y valor real de portfolio sobre la cobertura mecánica; algunos bloques (Wi-Fi) quedan fuera de la primera tanda a propósito.

## Consecuencias

- El área la recoge sola el Level 0 `Red-Team.base` por su regex de profundidad; no hay que tocar ningún `.base` superior. Las fichas se indexan por `Area` en `Proyectos ofensivos.base`.
- La Home gana un bloque `dataviewjs` (el tercero) y su CSS en `home-dashboard.css` (`.pkm-proj*`, sección 5e), con el mismo doble tema y tokens del resto. Al excluir `Tipo/Proyecto` de los ejes, esa sección queda en sus cuatro ejes de conocimiento.
- `CLAUDE.md` **no** lista el catálogo (lo hace el `.base`); solo se documenta el hallazgo operativo del safeguard (ver más abajo) y esta convención de forma de manera implícita vía este ADR.
- Los ficheros nuevos se crearon por fuera de Obsidian: requieren un **reload** para que el índice y el `.base` los recojan (patrón ya conocido).
- Precedente para futuras altas: proyecto nuevo → siguiente número libre, `prev`/`next` recosidos solo en el vecino anterior, `Dificultad` como orden real. Marcar `Estado: Terminado` al construir uno lo mueve solo a la vista «Portfolio» del `.base` y actualiza los contadores de la Home.
