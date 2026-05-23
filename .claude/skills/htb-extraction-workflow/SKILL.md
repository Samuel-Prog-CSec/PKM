---
name: htb-extraction-workflow
description: Use when extracting content from a HackTheBox Academy module to create Zettelkasten notes in this PKM. Triggers on phrases like "extraer módulo", "vamos con X de HTB", "saca el contenido del módulo Web Fuzzing", and similar requests. Defines the multi-step Playwright MCP workflow plus all transformation rules.
---

# Workflow de extracción HTB Academy → notas del PKM

Activar este skill **antes** de tocar Playwright, antes de crear cualquier nota nueva y antes de modificar carpetas dentro de `🔴⚔️ Red Team/Hacking web/`.

## Precondiciones

1. El usuario tiene sesión iniciada en `academy.hackthebox.com` en su navegador Chrome.
2. **Obsidian está abierto en el vault** del PKM (requisito para que la CLI de Obsidian responda a comandos en lugar de simplemente lanzar la app).
3. El plugin `playwright@claude-plugins-official` está activo (verificar con `mcp__plugin_playwright_playwright__browser_navigate` disponible).
4. Conoces el mapeo módulo → carpeta de `CLAUDE.md` (sección "Mapeo módulos HTB → carpetas del PKM"). **Releer ese mapeo** antes de empezar; carpetas pueden haber cambiado entre sesiones.

## Pasos obligatorios — 3 fases iterativas

La extracción de un módulo HTB se descompone en **Fase 0 (planificación) + Fase 1 (extracción capítulo a capítulo) + Fase 2 (cierre intra-capítulo) + Fase 3 (cierre intra-módulo)**. Las fases 1 y 2 se intercalan por cada capítulo; la 3 sella el módulo entero antes de darlo por terminado.

### Fase 0 — Planificación (una vez por módulo)

#### 0.1 Identificar módulo y destino

- Confirmar con el usuario el módulo (slug exacto en HTB, p. ej. `web-fuzzing`, `cross-site-scripting-xss`).
- Resolver la carpeta destino con el mapeo de `CLAUDE.md`. Si no existe, marcarla como pendiente.
- Comprobar con `Glob` / `ls` que no hay carpeta equivalente bajo otro nombre (inconsistencia histórica con emojis).
- Identificar el `.base` **Level 2** del sub-tema. Si no existe todavía, marcarlo como pendiente de crear **antes** de empezar Fase 1.

#### 0.2 Navegar y listar capítulos

```
mcp__plugin_playwright_playwright__browser_navigate → URL del preview del módulo
mcp__plugin_playwright_playwright__browser_snapshot → ver índice de capítulos
```

Extraer: número total de capítulos, nombres, URLs.

#### 0.3 Plan de fragmentación (presentar al usuario ANTES de escribir)

Reportar:

- **Total capítulos HTB**: N.
- **Notas resultantes**: 1:1, M:1 (varios cortos comparten tema), o 1:N (uno enorme se divide).
- **Cadena Zettelkasten**: orden propuesto de `Nota previa` → `Nota siguiente`.
- **Carpeta(s) destino** (rutas absolutas) y carpetas a crear.
- **`.base` Level 2** del sub-tema (existente o a crear) + Level 1 a verificar.
- **Tags propuestos** (reusar antes de inventar: `grep -r "Pentesting/"` o `obsidian tags`).

**Esperar confirmación del usuario** salvo módulo corto (<6 capítulos) en modo auto.

### Fase 1 — Extracción capítulo a capítulo (iterativo, en orden ascendente)

> **Corte vertical, no horizontal** (inspirado en `/prd-to-issues` de aihero.dev): completar **una nota entera** (frontmatter + cuerpo enriquecido + marks + callouts + enlaces actualizados) antes de pasar al siguiente capítulo. **No** escribir todos los frontmatters primero y luego todos los cuerpos. Razón: si abortamos, dejamos notas completas + capítulos no-tocados, no N notas a medias. Y permite verificar la calidad de las primeras 2–3 notas antes de comprometer las 15 restantes a un patrón mejorable.

Por cada capítulo, en orden:

#### 1.1 Extraer

```
browser_navigate → URL del capítulo
browser_snapshot → contenido renderizado
list_network_requests → para imágenes con URLs estables
```

Capturar: texto por bloques, URLs de imágenes (`https://academy.hackthebox.com/storage/modules/<id>/<file>`), bloques de código con su lenguaje.

#### 1.2 Transformar (aplicar **todas** las reglas — no son opcionales)

1. **Traducir al español** preservando términos técnicos en inglés con backticks: `false positive`, `payload`, `bypass`, etc.
2. **Eliminar relleno HTB**:
   - "In this module you will learn…" y derivados.
   - Conclusiones que solo repiten lo dicho.
   - Tips obvios para profesional senior.
   - Auto-referencias al curso ("skills assessment", "complete the module").
   - Listas de prerrequisitos genéricos.
   - Reformulaciones triviales.
3. **Enriquecer con contexto profesional**:
   - Gotchas de producción (WAF, rate limiting, sanitización moderna, cookies `SameSite`).
   - Herramientas alternativas más usadas en bug bounty actual.
   - CVE famosas o hallazgos reales de bug bounty que ilustran el concepto.
   - Diagramas mentales o tablas comparativas cuando ayuden.
   - Definiciones de conceptos asumidos por el original.
4. **Densidad 1000–1500 palabras de teoría** (excluyendo callouts/código/enlaces/sintaxis). Si el capítulo era corto y no hay nada significativo que enriquecer → fusionar con el siguiente. Si es enorme → dividir.
5. **Formato del PKM** (ver `pkm-note-format` skill):
   - Frontmatter completo con `Area` apuntando al **`.base` Level 2** del sub-tema, nunca al Level 1.
   - Marks con colores semánticos: 4–8 por nota.
   - Callouts (`> [!important]+`, `> [!warning]+`, `> [!success]+`, `> [!info]+`).
   - Bloques de código con lenguaje declarado: ` ```shell-session `, ` ```html `, ` ```javascript `, ` ```sql `, ` ```http `, etc.
   - Imágenes HTB por URL pública sólo si aportan valor real.
   - Tablas para comparativas (≤8 filas).
6. **Encadenar Zettelkasten** (ver `zettelkasten-linking` skill): rellenar `Nota previa`/`Nota siguiente` de la nueva **y actualizar `Nota siguiente` de la nota anterior** para apuntar a ella.

### Fase 2 — Cierre del capítulo (al terminar cada nota de Fase 1)

Antes de pasar al siguiente capítulo:

1. **Re-leer la nota recién creada** y añadir `[[wikilinks]]` donde un concepto ya tiene nota propia (módulo actual + sub-tema actual).
2. **Mejorar redacción, explicaciones, ejemplos** con el contexto adquirido. Se permite **modificar capítulos anteriores del mismo módulo** si surge una mejora obvia (renombrar un término para alinear, añadir una referencia cruzada).
3. **No avanzar al siguiente capítulo** hasta sellar el actual.

### Fase 3 — Cierre del módulo (obligatoria antes de darlo por terminado)

Aplica **siempre**, también al primer módulo del path aunque haya poco PKM con el que cruzar. **No se omite** aunque ya hayas enlazado oportunísticamente durante Fases 1 y 2 — esta es la pasada explícita y exhaustiva.

1. **Revisión cruzada con el resto del PKM**: para cada nota del módulo recién terminado, buscar enlaces a notas de **otros módulos / otros sub-temas / otras áreas**. Herramientas:
   - `obsidian backlinks file="<nota>"` para ver qué le apunta hoy.
   - `obsidian search:context "<concepto>"` para localizar menciones repartidas.
   - `Grep` rápido sobre el vault con la lista de conceptos clave del módulo.
2. **Integrar los enlaces** en el cuerpo reescribiendo párrafos si hace falta. No basta con añadir `[[X]]` sueltos — la referencia debe tener sentido en el flujo.
3. **Mejorar redacción a nivel global del módulo**: detectar repeticiones entre capítulos, ajustar definiciones que ahora se ven incoherentes, refinar la cadena `prev`/`next` si el orden óptimo cambió tras escribir todo.
4. **Actualizar la MOC `.base` Level 2** del sub-tema (filtro, columnas, vistas). Si apareció un sub-tema nuevo, comprobar también el Level 1 (`Web Pentesting.base` o el que toque).
5. **Reportar al usuario** al cierre:
   - Notas creadas (rutas absolutas).
   - Carpetas creadas.
   - MOCs Level 1/2 modificadas.
   - Tags nuevos introducidos.
   - Imágenes incrustadas y su origen.
   - **Enlaces cross-módulo añadidos** (resumen cuantitativo).
   - Pendientes (notas fantasma, enlaces a contenido aún no escrito).
   - **No hacer `git commit`** — esperar instrucción explícita.

### Herramientas a usar para operaciones del vault

- **CLI oficial `obsidian`** (preferida) para operaciones estructuradas: `obsidian property:set`, `obsidian backlinks`, `obsidian bases`, `obsidian base:query`, `obsidian search:context`, `obsidian plugins`, `obsidian command`. Requiere Obsidian abierto en el vault. Skill auxiliar: `obsidian:obsidian-cli`.
- **`Read` / `Write` / `Edit` directos** sobre el filesystem para crear y modificar contenido masivo de notas (más rápido para cuerpo de texto que `obsidian append` línea a línea).
- **`Grep` / `Glob`** para inventario rápido de tags, enlaces o estructura sin invocar a Obsidian.

## Anti-patrones (no hacer)

- ❌ Traducir literal sin filtrar relleno.
- ❌ Saltarte el plan de fragmentación de Fase 0 e ir escribiendo.
- ❌ Inventar tags nuevos sin verificar que no existe equivalente.
- ❌ Descargar imágenes localmente (preferir URL pública de HTB).
- ❌ Crear carpetas sin verificar duplicados con emoji vs sin emoji.
- ❌ Olvidar actualizar la `Nota siguiente` de la nota anterior.
- ❌ Hacer commit al terminar — el usuario tiene Obsidian Git que automatiza eso.
- ❌ Comercializar o redistribuir el contenido — HTB lo prohíbe (uso personal sí permitido).
- ❌ Avanzar al siguiente capítulo sin haber ejecutado Fase 2 sobre el actual.
- ❌ **Omitir Fase 3** porque "no había mucho que enlazar". Se ejecuta siempre, aunque sea breve.
- ❌ Apuntar `Area` de una nota nueva al `.base` **Level 1** (`Web Pentesting.base`). Siempre va al Level 2 del sub-tema.

## Indicadores de calidad para revisión final

- Frontmatter completo, fecha `YYYY-MM-DD`, `Area` apuntando al `.base` **Level 2** del sub-tema.
- 1000–1500 palabras de teoría (cuenta excluyendo callouts/código/enlaces).
- Entre 4 y 8 marks con colores semánticos correctos.
- Cadena prev/next coherente y sin enlaces rotos.
- Al menos un callout (matiz, advertencia o info adicional) si el contenido lo justifica.
- Tags reutilizados, no inventados.
- Sin frases tipo "este módulo enseña…" ni "como hemos visto…".
- **Fase 3 ejecutada y reportada** antes de cerrar el módulo (enlaces cross-módulo añadidos, MOCs Level 1/2 actualizadas).
