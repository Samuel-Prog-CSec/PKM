---
name: pkm-structure-audit
description: Use when the user asks to audit, review, clean up, refactor or improve the structure of the PKM vault. Triggers on phrases like "audita el PKM", "revisa la estructura", "mejora la organización", "limpia el vault", "qué falta arreglar", or proactively after extracting 3+ modules. Produces a prioritized report of structural issues — not changes — and waits for user approval before touching anything. Adapted from /improve-codebase-architecture.
---

# Auditoría estructural del vault

El PKM acumula entropía con el tiempo: notas huérfanas, wikilinks rotos, tags casi idénticos pero distintos (`SQLi` vs `SQLInjection`), notas de 150 palabras que deberían fusionarse y notas de 4000 que deberían dividirse, dos carpetas para el mismo tema, MOCs `.base` con filtros obsoletos. Este skill **detecta y reporta**; no modifica nada sin aprobación explícita.

## Cuándo ejecutar

- A petición del usuario.
- **Proactivamente** cuando: (a) acabamos de extraer 3+ módulos HTB seguidos, (b) la última auditoría fue hace >1 mes, (c) hemos hecho un refactor estructural grande (después de `pkm-design-grilling`).

## Salida esperada

Un único informe markdown con esta estructura:

```markdown
# Auditoría del PKM — YYYY-MM-DD

## Resumen ejecutivo
- N notas en total, N tocadas en los últimos 30 días.
- N hallazgos críticos, N moderados, N de oportunidad.

## Hallazgos críticos (acción recomendada)
...

## Hallazgos moderados (a valorar)
...

## Oportunidades (mejora opcional)
...
```

## Checks que se ejecutan

> [!info]+ Herramientas dedicadas antes que bash
> Ejecutar los checks con `Grep`/`Glob`/`Read` siempre que se pueda: en este entorno son más fiables que los bucles `for`/`find` de bash y que la CLI de Obsidian encadenada con pipes (motivo en `CLAUDE.md` § «Reglas operativas para mí»). Los `obsidian deadends`/`orphans`/`base:query` de abajo quedan para lo que solo la app resuelve, y como comandos **sueltos**, no compuestos.

### 1. Wikilinks rotos
Para cada `[[Nombre]]` o `[[Nombre|alias]]` en el vault, comprobar que `Nombre.md` existe. Excepción: enlaces fantasma intencionados (notas que aún no se han escrito) — si hay más de un wikilink a la misma nota fantasma desde notas distintas, considerarla **deuda concreta** (alguien la necesita); si solo hay uno, es probablemente fantasma intencional.

```shell-session
$ obsidian deadends                              # notas sin enlaces salientes
$ obsidian orphans                               # notas sin enlaces entrantes
```

### 2. Cadenas Zettelkasten rotas
Para cada nota con `Nota previa` o `Nota siguiente`:
- Verificar que la nota apuntada existe.
- Verificar la invariante doble: si `X.next = Y`, entonces `Y.prev = X`.
- Detectar cabeceras múltiples (varias notas con `Nota previa` vacío en la misma cadena → ambigüedad).

Reglas en `zettelkasten-linking` SKILL.

### 3. Densidad de notas
- **Underweight**: notas con <600 palabras de teoría → candidatas a fusionar.
- **Overweight**: notas con >2000 palabras de teoría → candidatas a dividir.
- **Stub**: notas con frontmatter pero <50 palabras → trabajo abandonado, decidir.

Word count excluyendo callouts, código, enlaces, sintaxis Obsidian.

### 4. Taxonomía de tags
Inventario de todos los tags del vault. Detectar:
- **Casi-duplicados**: `SQLi`, `SQL-Injection`, `SQLInjection`, `sqli` → consolidar.
- **Tags huérfanos**: usados una sola vez en todo el vault → ¿realmente útil?
- **Tags genéricos**: `Pentesting` aplicado a 200+ notas → probablemente inútil para filtrar.

```shell-session
$ obsidian tags                                 # listado con conteo
```

### 5. Carpetas redundantes
Listar carpetas con emoji y sin emoji que podrían referirse al mismo tema (`SQL Injection/` vs `💉🩸 SQL Injection/`). Listar carpetas con <3 notas que podrían fusionarse con un padre.

### 6. MOCs `.base` obsoletas
Para cada archivo `.base`:
- Ejecutar el filtro y comparar el conteo de notas resultante con el conteo histórico (si lo tenemos).
- Verificar que las columnas/views referenciadas existen.
- Detectar `.base` que apuntan a tags o áreas que ya no existen.

### 7. Frontmatter inconsistente
Notas que carecen de algún campo obligatorio (`tags`, `Fecha de actualización`, `Area`), o usan formato no-estándar (fecha en otro formato, area sin `[[]]`).

### 8. Contenido disperso
Búsqueda de keywords clave en el cuerpo de notas para detectar contenido que está en una nota pero "debería" estar en otra. Heurística: si la nota X menciona el concepto Y >5 veces y existe una nota dedicada a Y, ¿no debería el contenido vivir allí o estar enlazado?

### 9. Jerarquía `.base` Level 0 / Level 1 / Level 2

Convención del vault en `CLAUDE.md` § "Vista `.base`" y **ADR 009**. Checks:

- **Sub-carpetas con notas pero sin `.base` Level 2** → falta el índice. Listar.
- **Notas con `Area` apuntando a un Level 0/1 o a una nota** (`Area: "[[Wireshark]]"`, `Area: "[[Web Pentesting.base]]"`) → legacy roto. El `Area` solo apunta a un Level 2, con alias.
- **`.base` Level 0/1 que no listan algún hijo existente** → filtro desactualizado.
- **`.base` Level 2 con filtro `Area == link(...)` apuntando a un nombre distinto al del propio fichero** → roto, no devolverá notas.
- **`.base` Level 2 huérfano**: ninguna nota lo tiene como `Area` → o es prematuro (crear `.base` antes que las notas está prohibido) o quedó vacío tras una migración.
- **Level 1 que se autolista** → el filtro de auto-exclusión olvida la extensión. `file.name != "X"` **no funciona**: para un `.base`, `file.name` es `"X.base"`.
- **Level 1 con lista de carpetas hardcoded** → se olvidará al añadir un área. Sustituir por regex de profundidad: `'/^<Área>\/[^\/]+$/.matches(file.folder)'`.
- **Level 2 sin la columna `Fecha de actualización`** → índice sin señal de mantenimiento; no cumple la plantilla canónica.
- **Level 1 con >15 sub-temas y sin vista `groupBy`** → lista plana, difícil de navegar. Añadir fórmula de familia.

El script de integridad completo (recorre todos los `.base` y todas las notas, cruza `Area` ↔ fichero, y reporta filtros mal apuntados, `Area` rotos, MOC huérfanas y notas sin `Area`) está en `references/audit-bases.ps1`.

> [!warning]+ Validar `.base` correctamente
> - **`obsidian base:query` NO indexa ficheros `.base`**, solo `.md`. Toda vista Level 0/1 devuelve `[]` por CLI aunque funcione en la app → validarlas con `obsidian dev:screenshot`.
> - **Tras editar por fuera de Obsidian, ejecutar `obsidian command id="app:reload"` y esperar ~20 s** antes de consultar: el caché de metadatos devuelve conteos obsoletos y hace creer que un filtro está mal.
> - **Abrir un `.base` en la app puede reescribirlo** (normaliza `columnSize`, mueve `groupBy`). No editarlo por fuera mientras está abierto en una pestaña.

```shell-session
$ obsidian bases                                    # listado de .base
$ obsidian command id="app:reload"                  # SIEMPRE antes de validar
$ obsidian base:query file="XSS.base" view="Notas"  # solo sirve para Level 2
$ obsidian dev:errors                               # errores de fórmula tras recargar
```

## Cómo priorizar hallazgos

- **Crítico**: rompe la navegación (wikilink roto a nota muy enlazada, cadena Zettelkasten rota, frontmatter ausente).
- **Moderado**: causa fricción notable (tags casi-duplicados que dividen un tema, notas underweight/overweight, MOC obsoleta).
- **Oportunidad**: mejoraría la coherencia pero el vault funciona sin tocarlo (carpetas con <3 notas, tags huérfanos).

## Después del informe

1. **Presentar el informe completo** al usuario.
2. **No ejecutar cambios** hasta que el usuario priorice qué arreglar.
3. Para hallazgos aprobados, si afectan a más de 5 archivos o introducen una convención nueva, **activar `pkm-design-grilling`** antes de planificar la ejecución.
4. Ejecutar cambios en orden de criticidad, con `git status` antes y después de cada bloque para tener checkpoints.
5. Al terminar, regenerar un mini-informe de "antes/después" con conteos.

## Anti-patrones

- ❌ Modificar archivos durante la auditoría (la auditoría es solo lectura).
- ❌ Reportar absolutamente todo (200 hallazgos paraliza al usuario; priorizar).
- ❌ Confundir "intencional" con "problema" — preguntar al usuario antes de marcar algo como bug (p. ej. una nota underweight puede ser un placeholder consciente).
- ❌ Auditar mientras el usuario está extrayendo un módulo nuevo — concentrarse en una cosa a la vez.

## Heurísticas de freno

- Si el informe pasa de 30 hallazgos: dividir por temas y atacar uno a uno.
- Si una "consolidación de tags" tocaría >50 notas: usar `pkm-design-grilling` primero.
- Si un wikilink "roto" parece intencional (fantasma con 1 sola referencia): reportarlo como oportunidad, no crítico.
