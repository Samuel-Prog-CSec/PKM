---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-29
Estado: Aceptada
---
---

## Contexto

Tras la reforma de las MOC (ADR 009) quedaban tres carencias. **Una**: los índices `.base` mostraban nombre, tags y fecha, y con 124 índices el nombre del fichero era lo único que distinguía una nota de otra. **Dos**: los dos tags dominantes —`Web/Red-Team` (432 notas) y `Pentesting/Explotacion` (392)— no discriminaban nada, así que el filtrado por tag era inútil en medio vault. **Tres**: el curso de Go ofensivo (94 notas, 18 `.base`) vivía en `01 - Proyectos/`, una carpeta PARA que el propio `CLAUDE.md` daba por eliminada.

## Decisión

**1 · El problema de los tags saturados no se arregla quitando, sino añadiendo.** El análisis mostró que `Web/Red-Team` está en 411 de 432 casos dentro de `Hacking web`: es ~95% equivalente a "estar en esa carpeta", redundante pero inofensivo. Lo que faltaba era un **eje ortogonal**: qué *clase* de nota es. Se crea `Tipo/` con cuatro valores —`Introduccion` (125), `Deteccion` (46), `Arsenal` (34), `Defensa` (33)— aplicados a 238 notas por heurística sobre el nombre de fichero. **Las notas de técnica no se etiquetan**: son ~75% del vault y marcarlas produciría otro tag inútil. Se marca la excepción, no la norma.

**2 · Propiedad `Descripción` autogenerada.** Una frase (≤180 caracteres) extraída de la primera oración real del cuerpo —saltando frontmatter, encabezados, callouts, tablas, listas y bloques de código, y limpiando marcas, wikilinks y negritas—. 972 notas cubiertas de golpe; el repaso manual es incremental. Pasa a ser columna en los 124 Level 2 y obligatoria en notas nuevas.

**3 · Go pasa a ser un área de Red Team**: `🔴⚔️ Red Team/Desarrollo ofensivo/`. Con ello `01 - Proyectos/` desaparece y se cierra la migración PARA pendiente.

## Alternativas descartadas

- **Borrar `Web/Red-Team` de las 411 notas** de `Hacking web` dejándolo solo en las 21 de fuera. Más limpio sobre el papel, pero toca 411 notas para ganar poco, y sin git no hay checkpoint. El coste/beneficio no sale.
- **Subdividir `Pentesting/Explotacion`** en sub-fases. Requiere reclasificar 392 notas a mano: ninguna heurística distingue "explotación web" de "explotación de servicio" por el nombre.
- **`Tipo/Tecnica` para las 753 restantes.** Simétrico y "completo", pero sería el tercer tag saturado del vault. Un tag que tiene el 75% de las notas no filtra nada.
- **`Descripción` a mano, nota a nota.** Máxima calidad, pero a ~1.000 notas los índices tardarían meses en ser útiles. La autogeneración da el 90% del valor hoy y deja el pulido como trabajo incremental.
- **Extraer la descripción del cuerpo con una fórmula del `.base`** en lugar de materializarla como propiedad. Imposible: Bases no puede leer el cuerpo de una nota, solo su frontmatter y metadatos.
- **Dividir Go entre `Ingenieria/` (lenguaje) y Red Team (ofensiva)**, como se hizo con COAE en la ADR 008. Descartado aquí: partiría una cadena Zettelkasten de 94 notas y, a diferencia de COAE, los "fundamentos" de este curso ya están escritos desde la óptica ofensiva (compilación cruzada, tamaño de binario, OPSEC), no como teoría de lenguaje neutra.
- **Go a `02 - Recursos/Lenguajes/`.** Enterraría 94 notas de tradecraft (C2, process injection, BYOVD, shellcode) en una carpeta de recursos.

## Consecuencias

- **138 `.base`** (14 Level 0/1 + 124 Level 2), **0 hallazgos críticos** en la auditoría de integridad.
- Las vistas transversales de `Red-Team.base` pasan de `file.name.contains(...)` a `file.hasTag("Tipo/…")`: dejan de romperse al renombrar una nota. Se añaden dos vistas nuevas (`Defensa y mitigación`, `Puertas de entrada`).
- `02 - Recursos` gana Level 0 (`Recursos.base`) con vista de ADRs y de notas sin índice. `01 - Proyectos` eliminada.
- **29 notas quedan sin `Descripción`**: 8 sin primer párrafo aprovechable (6 de `000 - Fases del Pentesting`, la plantilla Templater y una de Wireshark) y las 19 fichas de `Biblioteca`, excluidas a propósito porque tienen esquema de catálogo propio.
- El backup previo a los cambios masivos vive en el scratchpad de la sesión (`backup-vault-*.zip`, 1.203 ficheros). **Sin git, es la única red**: cualquier operación futura sobre cientos de notas debe crear uno antes.
- Pendiente y consciente: los 2 tags saturados siguen ahí (decisión tomada, no olvido), `04 - PENDIENTES` sin vaciar, y no existe *home* del vault — tema abierto para otra sesión.
