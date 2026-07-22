---
name: htb-extraction-workflow
description: Use when extracting content from a HackTheBox Academy module to create Zettelkasten notes in this PKM. Triggers on phrases like "extraer módulo", "vamos con X de HTB", "saca el contenido del módulo Web Fuzzing", and similar requests.
---

# Workflow de extracción HTB Academy → notas del PKM

Activar este skill **antes** de tocar el navegador, antes de crear cualquier nota nueva y antes de modificar carpetas del vault (`🔴⚔️ Red Team/`, `Redes/`, `Ingenieria/`, `02 - Recursos/🛠️ Tools/`…). Aplica a **cualquier** path HTB (CWES/CWEE web o CPTS de red/infra), no solo web.

## Precondiciones

1. El usuario tiene sesión iniciada en `academy.hackthebox.com` en su navegador Chrome.
2. **Obsidian está abierto en el vault** del PKM (requisito para que la CLI de Obsidian responda a comandos en lugar de simplemente lanzar la app).
3. **Extracción de contenido**: método principal = skill `claude-in-chrome` sobre el **Chrome ya logueado** del usuario + `fetch` a la **API interna de HTB** desde la pestaña (devuelve markdown limpio; endpoints en 0.2 y 1.1). Playwright MCP o `agent-browser` son alternativas si `claude-in-chrome` no está disponible.
4. Conoces el mapeo módulo → carpeta de `CLAUDE.md` (sección "Mapeo módulos HTB → carpetas del PKM"). **Releer ese mapeo** antes de empezar; carpetas pueden haber cambiado entre sesiones.

## Pasos obligatorios — 3 fases iterativas

La extracción de un módulo HTB se descompone en **Fase 0 (planificación) + Fase 1 (extracción capítulo a capítulo) + Fase 2 (cierre intra-capítulo) + Fase 3 (cierre intra-módulo)**. Las fases 1 y 2 se intercalan por cada capítulo; la 3 sella el módulo entero antes de darlo por terminado.

### Productos del módulo (deliverables obligatorios)

Un módulo net-new terminado contiene, **además** de las notas de capítulo, los **3 ejes del vault** (principio completo en CLAUDE.md § "Estándares de calidad — los 3 ejes"). No dependen de que el usuario los recuerde: se planifican en Fase 0.3 y se verifican en Fase 3.

- **Eje 1 — Investigar y profundizar SIEMPRE (2026)** (disciplina y jerarquía de fuentes → skill `pkm-research`): para **todo** contenido de **todo** módulo (no solo los desfasados), contrastar cada técnica/flag/herramienta con **fuentes oficiales y de confianza** y el estado del arte, para explicar mejor, profundizar y ampliar. Cuando además algo esté obsoleto, **modernizarlo** hacia los estándares de seguridad y explotación actuales. Se integra en el cuerpo de cada nota (Fase 1.2).
- **Eje 4 — Fuentes citadas**: contenido externo con fuentes actuales de referencia y **atribución por-fuente** (ver `pkm-note-format` § Fuentes). Se integra en el cuerpo.
- **Eje 2 — `Detección y evasión`** y **Eje 3 — `Arsenal de herramientas`**: **notas dedicadas** net-new.

**Regla de forma para `Detección y evasión` y `Arsenal de herramientas`:**

- **Por defecto → nota dedicada** (net-new), encadenada en el Zettelkasten y con su `Area`.
- **Excepción (predicado observable: ¿HTB ya cubre ese tema?)**: si HTB trae su propia sección de detección/evasión o de herramientas, **respetar su formato/organización** e **investigar a fondo para mejorar, ampliar y modernizar** ese contenido — sin forzar una nota aparte.

Contenido de cada deliverable:

- **`Detección y evasión`**: cómo se detecta el ataque/técnica hoy (telemetría/logs que deja el atacante: EDR/IDS/IPS, WAF, SIEM) y cómo se evade en entornos reales (timing, fragmentación, decoys, living-off-the-land, blending). **Más a fondo que HTB**, con técnicas y herramientas profesionales actuales.
- **`Arsenal de herramientas`**: tras entender la vuln/técnica a bajo nivel, el set profesional actual para **automatizar/asistir detección, evasión, explotación y registro**, con el *cómo* (comando de ejemplo, cuándo usar cada una, alternativa a la de HTB). Orientado a jornadas reales de pentest / bug bounty.

### Fase 0 — Planificación (una vez por módulo)

#### 0.1 Identificar módulo y destino

- Confirmar con el usuario el módulo (slug exacto en HTB, p. ej. `web-fuzzing`, `cross-site-scripting-xss`).
- Resolver la carpeta destino con el mapeo de `CLAUDE.md`. Si no existe, marcarla como pendiente.
- Comprobar con `Glob` / `ls` que no hay carpeta equivalente bajo otro nombre (inconsistencia histórica con emojis).
- Identificar el `.base` **Level 2** del sub-tema. Si no existe todavía, marcarlo como pendiente de crear **antes** de empezar Fase 1.

#### 0.2 Navegar y listar capítulos

Con el Chrome logueado (`claude-in-chrome`), pedir el índice a la **API interna de HTB** desde la pestaña — da los IDs y títulos reales de todas las secciones:

```javascript
// ejecutar en la pestaña de HTB Academy (usa las cookies de sesión)
fetch(`/api/v3/modules/<módulo>/sections`).then(r => r.json())
// → {data:[{group, sections:[{id, title, page, type}]}]}
```

Extraer: total de capítulos, títulos e **IDs reales** (no son contiguos ni siguen el orden de visualización — no los adivines). Alternativa sin API: `browser_snapshot` del índice del módulo.

#### 0.3 Plan de fragmentación (presentar al usuario ANTES de escribir)

Reportar:

- **Total capítulos HTB**: N.
- **Notas resultantes**: 1:1, M:1 (varios cortos comparten tema), o 1:N (uno enorme se divide).
- **Cadena Zettelkasten**: orden propuesto de `Nota previa` → `Nota siguiente`.
- **Carpeta(s) destino** (rutas absolutas) y carpetas a crear.
- **`.base` Level 2** del sub-tema (existente o a crear) + Level 1 a verificar.
- **Tags propuestos** (reusar antes de inventar: `grep -r "Pentesting/"` o `obsidian tags`).
- **Deliverables de los 3 ejes** (ver "Productos del módulo"): declarar si `Detección y evasión` y `Arsenal de herramientas` serán **notas dedicadas net-new** o, si HTB ya cubre el tema, cómo se integran/modernizan.

**Esperar confirmación del usuario** salvo módulo corto (<6 capítulos) en modo auto.

### Fase 1 — Extracción capítulo a capítulo (iterativo, en orden ascendente)

> **Corte vertical, no horizontal** (inspirado en `/prd-to-issues` de aihero.dev): completar **una nota entera** (frontmatter + cuerpo enriquecido + marks + callouts + enlaces actualizados) antes de pasar al siguiente capítulo. **No** escribir todos los frontmatters primero y luego todos los cuerpos. Razón: si abortamos, dejamos notas completas + capítulos no-tocados, no N notas a medias. Y permite verificar la calidad de las primeras 2–3 notas antes de comprometer las 15 restantes a un patrón mejorable.

Por cada capítulo, en orden:

#### 1.1 Extraer

Pedir el markdown limpio de la sección a la API (más fiable que leer el DOM):

```javascript
fetch(`/api/v2/modules/<módulo>/sections/<id>?language=en`).then(r => r.json())
// → .data.content = markdown completo (encabezados, código, tablas y URLs de imágenes intactos)
```

- **Imágenes**: las URLs (`https://academy.hackthebox.com/storage/modules/<id>/<file>`) vienen ya en el markdown. Analizarlas y quedarse **solo con las que aportan** (diagramas, matrices, UI relevante); verificar que renderizan (ver `pkm-note-format` § Imágenes).
- *Gotcha*: el filtro de la herramienta puede **bloquear** trozos con material tipo credencial/clave. Si pasa, saca solo los encabezados (`content.split('\n').filter(l=>/^#/.test(l))`) y redacta desde el conocimiento experto + el outline.
- Alternativa sin API: `browser_snapshot` del capítulo + `list_network_requests` para URLs de imágenes.

#### 1.2 Transformar (aplicar **todas** las reglas — no son opcionales)

1. **Traducir al español** preservando términos técnicos en inglés con backticks: `false positive`, `payload`, `bypass`, etc.
2. **Eliminar relleno HTB**:
   - "In this module you will learn…" y derivados.
   - Conclusiones que solo repiten lo dicho.
   - Tips obvios para profesional senior.
   - Auto-referencias al curso ("skills assessment", "complete the module").
   - Listas de prerrequisitos genéricos.
   - Reformulaciones triviales.
3. **Revisar como experto y enriquecer (eje 1 + eje 4 de los 3 ejes)**:
   - **Eje 1 — investigar/profundizar (siempre)** (skill `pkm-research`): en **cada** capítulo, contrastar con fuentes oficiales/de confianza y el estado del arte 2026 para explicar mejor, profundizar y ampliar — no solo si parece desfasado. Para investigación pesada, despachar un `Agent` en background mientras se redacta. Si hay vía mejor / más sigilosa / más fiable, **actualizar y modernizar** (nunca traducir a ciegas). Señalar lo desfasado.
   - Gotchas de producción (WAF, EDR, rate limiting, sanitización moderna, cookies `SameSite`).
   - Herramientas alternativas más usadas en bug bounty actual.
   - CVE famosas o hallazgos reales de bug bounty que ilustran el concepto.
   - Diagramas/tablas comparativas cuando expliquen mejor que un párrafo denso.
   - Definiciones de conceptos asumidos por el original.
   - **Eje 4 — fuentes**: al añadir contenido externo, citar fuentes **actuales y de referencia** (PortSwigger, HackTricks, nmap.org, SANS, RFCs, advisories, blogs recientes) con **atribución por-fuente** en el texto (ver `pkm-note-format` § Fuentes).
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

1. **Revisión cruzada con TODO el PKM**: para cada nota del módulo recién terminado, buscar enlaces a notas de **todas las áreas relevantes**, no solo el sub-tema actual — otros módulos del path, otros sub-temas de `Hacking web/`, `Pentesting/`, `Redes/`, `Ingenieria/` y herramientas en `Tools/`, lo que aplique. Herramientas:
   - `obsidian backlinks file="<nota>"` para ver qué le apunta hoy.
   - `obsidian search:context "<concepto>"` para localizar menciones repartidas.
   - `Grep` rápido sobre el vault con la lista de conceptos clave del módulo.
2. **Integrar los enlaces** en el cuerpo reescribiendo párrafos si hace falta. No basta con añadir `[[X]]` sueltos — la referencia debe tener sentido en el flujo.
3. **Mejorar redacción a nivel global del módulo**: detectar repeticiones entre capítulos, ajustar definiciones que ahora se ven incoherentes, refinar la cadena `prev`/`next` si el orden óptimo cambió tras escribir todo.
4. **Actualizar la MOC `.base` Level 2** del sub-tema (filtro, columnas, vistas). Si apareció un sub-tema nuevo, comprobar también el Level 1 (`Web Pentesting.base` o el que toque).
5. **Verificar los deliverables de los 3 ejes**: existen `Detección y evasión` y `Arsenal de herramientas` (notas dedicadas net-new, o contenido modernizado si HTB ya cubría el tema). Si falta alguno → no cerrar el módulo.
6. **Reportar al usuario** al cierre:
   - Notas creadas (rutas absolutas).
   - Carpetas creadas.
   - MOCs Level 1/2 modificadas.
   - Tags nuevos introducidos.
   - Imágenes incrustadas y su origen.
   - **Enlaces cross-módulo añadidos** (resumen cuantitativo).
   - **Deliverables de los 3 ejes**: `Detección y evasión` y `Arsenal de herramientas` (net-new o modernizados), y fuentes citadas.
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
- ❌ Traducir HTB sin investigar/contrastar con fuentes oficiales y el estado del arte 2026 — la investigación es **siempre**, no solo si el contenido parece desfasado (eje 1).
- ❌ Cerrar un módulo sin `Detección y evasión` ni `Arsenal de herramientas` — salvo que HTB los cubra y se hayan modernizado (ejes 2 y 3).
- ❌ Añadir contenido de fuentes externas sin citarlas ni atribuir por-fuente (eje 4).
- ❌ Limitar la revisión cruzada de Fase 3 al sub-tema actual — debe barrer todas las áreas relevantes.
- ❌ Incrustar imágenes que no aportan, o sin verificar que renderizan.

## Indicadores de calidad para revisión final

- Frontmatter completo, fecha `YYYY-MM-DD`, `Area` apuntando al `.base` **Level 2** del sub-tema.
- 1000–1500 palabras de teoría (cuenta excluyendo callouts/código/enlaces).
- Entre 4 y 8 marks con colores semánticos correctos.
- Cadena prev/next coherente y sin enlaces rotos.
- Al menos un callout (matiz, advertencia o info adicional) si el contenido lo justifica.
- Tags reutilizados, no inventados.
- Sin frases tipo "este módulo enseña…" ni "como hemos visto…".
- **Fase 3 ejecutada y reportada** antes de cerrar el módulo (enlaces cross-módulo añadidos, MOCs Level 1/2 actualizadas).
- **Todo** el contenido investigado/contrastado con fuentes oficiales y el estado del arte 2026 (no solo lo desfasado); lo obsoleto señalado o modernizado (eje 1).
- Deliverables `Detección y evasión` y `Arsenal de herramientas` presentes (net-new o modernizados si HTB los cubría).
- Fuentes externas citadas y atribuidas por-fuente (eje 4).
- Imágenes/diagramas solo si aportan y **renderizan** correctamente.
