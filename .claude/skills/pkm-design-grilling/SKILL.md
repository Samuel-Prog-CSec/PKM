---
name: pkm-design-grilling
description: Use BEFORE any structural change to the PKM that's not a simple note creation. Triggers when the user proposes reorganizing folders, creating new MOCs, merging or splitting topics, mass-renaming, changing the tag taxonomy, or adopting a new convention. Forces a question-driven exploration of the decision space before any file is touched. Inspired by /grill-me but scoped to PKM design decisions.
---

# Interrogatorio antes de decisiones estructurales del PKM

Las decisiones estructurales del PKM son **caras de revertir**: cuando movemos 30 notas, renombramos un tema, o creamos una MOC nueva, romper la cadena Zettelkasten o dejar wikilinks rotos es trivial. Este skill obliga a parar y explorar el espacio de la decisión **antes** de tocar ningún archivo.

## Cuándo activar

- "Quiero reorganizar la carpeta XSS / Hacking web / Red Team…"
- "¿Y si fusiono `XSS Reflejado.md` con `XSS Almacenado.md`?"
- "Crea una MOC para deserialización."
- "Cambia el tag `Pentesting/Explotacion` por `Explotacion`."
- "Mueve todas las notas de Information Gathering a la carpeta de Pentesting."
- Cualquier acción que afecte a **más de 5 archivos** o introduzca un concepto/convención nuevo.

**No** activarlo para:
- Crear una nota nueva en una carpeta existente (eso lo cubre `htb-extraction-workflow` o `pkm-note-format`).
- Edición puntual del contenido de una nota.
- Pequeños ajustes de frontmatter en 1–2 archivos.

## Filosofía

> No se mueve un archivo hasta saber **por qué** se mueve, **dónde** debería estar idealmente, **qué se rompe** al moverlo, y **qué cambia en mi modelo mental** del vault si lo movemos.

Antes de cualquier ejecución, presentar al usuario el conjunto de preguntas relevantes (con valores por defecto sugeridos cuando los haya). Esperar respuestas. **No proponer un plan** hasta que las respuestas estén claras.

## Categorías de preguntas

Recorrer estas categorías y formular las preguntas que apliquen al cambio concreto. Una decisión típica genera 8–20 preguntas, no 50 como en software (los PKM son más simples).

### 1. Motivación

- ¿Qué problema concreto resuelve este cambio? (Si la respuesta es "para que esté más ordenado", insistir: ¿qué fricción está causando la organización actual?)
- ¿Es un problema activo o anticipado? (Si es anticipado: ¿qué disparador haría que el problema se vuelva real?)
- ¿Has tenido esta tentación de cambiar antes y la has descartado? Si sí, ¿qué te hizo cambiar de opinión ahora?

### 2. Alcance

- ¿Cuántas notas se ven afectadas? (Listar con `Glob` antes de seguir.)
- ¿Hay notas fuera de la carpeta destino que apuntan a las afectadas? (`Grep` por wikilinks.)
- ¿Hay archivos `.base` que filtran por el área/tag actual? Si sí, ¿hay que actualizar el filtro?
- ¿El cambio toca alguna nota con `Nota previa` / `Nota siguiente` que cruce a otra cadena Zettelkasten?

### 3. Convenciones existentes

- ¿Existe ya una convención en el vault para casos similares? (P. ej. "carpetas con emoji vs sin emoji", "tags `Foo/Bar` vs `foo-bar`".)
- Si la respuesta es sí, ¿por qué desviarse de ella? Si no, ¿qué patrón estamos sentando como precedente para el futuro?
- ¿El cambio crea inconsistencia con `CLAUDE.md` (la guía operativa)? Si sí, ¿hay que actualizar CLAUDE.md como parte del cambio?

### 4. Reversibilidad

- ¿Cómo deshacer este cambio si en 2 semanas decidimos que fue un error?
- ¿Hay backup vía `obsidian-git` reciente? (Comprobar `git log` antes de seguir.)
- ¿El cambio es atómico (todo o nada) o se puede dividir en pasos verificables?

### 5. Mapeo con CWES/CWEE

- Si el cambio afecta a `Red Team/Hacking web/`, ¿sigue compatible con el mapeo de módulos HTB → carpetas que vive en `CLAUDE.md`?
- ¿Adelanta o complica la integración futura de módulos que aún no hemos extraído?

### 6. Modelo mental

- Después del cambio, si el usuario abre Obsidian y busca "X" donde estaba antes, ¿lo encuentra? Si no, ¿cómo lo encuentra?
- ¿El cambio mejora o empeora el grafo de Obsidian (densidad de enlaces, clusters temáticos)?

### 7. Coste de oportunidad

- ¿Cuánto trabajo nos lleva el cambio? (Estimar en notas tocadas, no en tiempo.)
- ¿Hay algo más urgente o de más impacto que podríamos hacer con ese tiempo? (P. ej. extraer el siguiente módulo HTB.)

## Después del interrogatorio

Cuando el usuario haya respondido las preguntas clave:

1. **Resumir las respuestas** en 3–5 líneas para verificar que las he interpretado bien.
2. **Proponer un plan concreto** con pasos numerados, archivos afectados (rutas absolutas) y operaciones (move/rename/edit/create).
3. **Identificar puntos de no-retorno** del plan (ej. "después del paso 4, las cadenas Zettelkasten quedan rotas hasta el paso 7 — si abortamos en medio, hay que recoser").
4. **Pedir confirmación explícita** antes de ejecutar el primer paso.
5. **Registrar la decisión (ADR)**: si la decisión se **ejecuta** (no se descarta), dejar constancia del **porqué** en un ADR — es lo que la memoria y el `CLAUDE.md` capturan peor: las **alternativas descartadas** y el razonamiento. Ver "Registro de decisiones (ADR)".

## Registro de decisiones (ADR)

Las decisiones estructurales ejecutadas se registran como **ADR** (*Architecture Decision Record*) — idea tomada de `grill-with-docs` de aihero.dev. Capturan el porqué de forma permanente y versionada en git, incluidas las **alternativas descartadas** (que la memoria no guarda bien).

- **Ubicación**: `02 - Recursos/Decisiones estructurales/NNN - <título corto>.md` (NNN incremental: `001`, `002`…). Crear la carpeta al primer ADR.
- Son **notas meta**: **exentas** de la cadena Zettelkasten (`Nota previa`/`Nota siguiente`) y de `Area`. Frontmatter mínimo:

```yaml
---
tags:
  - PKM/Decisiones
Fecha de actualización: YYYY-MM-DD
Estado: Aceptada          # o: Reemplazada por [[NNN - ...]]
---
```

- **Cuerpo** (media pantalla, no un ensayo):

```markdown
## Contexto
Qué fricción/problema motivó la decisión (2-4 líneas).

## Decisión
Qué se decidió, en concreto.

## Alternativas descartadas
- Opción X — por qué no.
- Opción Y — por qué no.

## Consecuencias
Qué mejora, qué se rompe/complica, qué se migra, impacto en `CLAUDE.md`/MOCs.
```

- Si una decisión **reemplaza** a otra, marcar la vieja `Estado: Reemplazada por [[NNN - ...]]` y enlazarlas.
- **Escueto**: si no hay alternativas reales que descartar, quizá **no** merece ADR — basta memoria/`CLAUDE.md`.

## Anti-patrones

- ❌ Saltar al plan sin preguntar (asumir motivación).
- ❌ Hacer las preguntas pero ignorar las respuestas al proponer el plan.
- ❌ Más de 25 preguntas — significa que la decisión es demasiado grande para una sola sesión, dividirla.
- ❌ Hacer preguntas que se pueden responder leyendo el código/vault directamente (`Grep` primero, preguntar después).
- ❌ Escribir un ADR extenso o para decisiones triviales — es media pantalla y solo cuando hubo alternativas reales que descartar.

## Ejemplo abreviado

Usuario: *"Quiero crear una carpeta `Modern Web/` y mover ahí las notas de Deserialization, HTTP smuggling y Parameter Logic Bugs porque son temas modernos."*

Aplicar este skill →

> Antes de tocar nada, déjame entender la decisión:
> 
> **Motivación**:
> 1. "Modernos" es una categoría temporal, no técnica — ¿esperas que en 2 años sigas considerándolos modernos? ¿O lo categorizarías por otra propiedad estructural (p. ej. "complejidad de explotación" o "fase del pentest")?
> 2. ¿El problema actual es que están dispersos y te cuesta encontrarlos, o que cuando alguien (tú mismo en 6 meses) busca "HTTP smuggling" no sabe en qué carpeta mirar?
> 
> **Alcance** (verificado con `Glob`):
> 3. Encuentro 0 notas de Deserialization, 0 de HTTP smuggling, 0 de Parameter Logic Bugs — todavía no las hemos extraído (son módulos CWEE pendientes). ¿Quieres crear la carpeta vacía ahora como decisión arquitectónica, o esperar al primer módulo?
> 
> **Convenciones**:
> 4. El mapeo en `CLAUDE.md` ubica esos módulos en `HTTP/Attacks/`, `Deserialization/Intro/` y `Parameter Logic Bugs/`. ¿Quieres reescribir el mapeo o crear `Modern Web/` como agrupador que contenga esas subcarpetas?
> 
> *(seguir hasta tener todas las respuestas, luego proponer plan)*
