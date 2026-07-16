# CLAUDE.md — Guía operativa del PKM

Este repositorio es el **segundo cerebro digital** de Samuel: un *vault* de Obsidian en español usado para estudiar, retener y consultar conocimiento técnico durante su trabajo profesional como **pentester** y su actividad en **bug bounty**. Las notas no son apuntes para aprobar un examen — son material de referencia para sesiones reales de hacking ético.

## Misión actual

Construir y mantener el corpus de notas necesario para las dos certificaciones web de Hack The Box Academy, en este orden:

1. **HTB CWES** — *Certified Web Exploitation Specialist* (path "Web Penetration Tester", antes CBBH). 20 módulos, 279 secciones, dificultad media.
2. **HTB CWEE** — *Certified Web Exploitation Expert* (path "Senior Web Penetration Tester"). 15 módulos, 245 secciones, dificultad alta. Cubre white-box, deserialización, ataques HTTP avanzados y *parameter logic bugs*.

El objetivo paralelo es que el material sirva indefinidamente como referencia profesional, no sólo durante el estudio.

## Idioma, filosofía y voz

- **Idioma de las notas: español**. Mantener en inglés (envueltos en backticks: `` `payload` ``) los términos técnicos consolidados de la industria — *false positive*, *wordlist*, *HTTP response splitting*, *web shell*, etc. — y los nombres de herramientas, parámetros y APIs.
- **Zettelkasten**: cada nota es atómica, trata un único concepto/técnica/ataque, y se enlaza por contexto con notas vecinas mediante los campos `Nota previa` / `Nota siguiente` del frontmatter y referencias `[[ ]]` en el cuerpo. Las MOC viven en archivos `.base` de Obsidian.
- **Densidad orientativa, no obligatoria.** Referencia: notas *conceptuales* (explican un mecanismo, ataque o defensa) ~1000–1500 palabras de teoría; notas *técnicas/operativas* (payloads, comandos, herramientas) menos, primando la densidad de payloads sobre la prosa. La cuenta excluye callouts, código, enlaces y sintaxis de Obsidian. **El límite inferior es solo una referencia**: si la nota explica bien el concepto y está completa, quedarse por debajo es perfectamente asumible. **Nunca añadir contenido redundante o de relleno para alcanzar un número** — no aporta valor. **Importa más respetar el límite superior** (~1500): si una nota se dispara, **dividirla** en varias atómicas. Si una nota conceptual se queda genuinamente corta de contenido útil, enriquecer con sustancia real; si no la hay, dejarla.
- **Voz profesional, no académica**. Notas escritas para un pentester que necesita ejecutar — frases cortas, ejemplos concretos, advertencias accionables. Evitar relleno motivacional, recapitulaciones obvias o frases tipo "como veremos a continuación…".

## Estructura del vault

Raíz PARA + carpetas temáticas:

```
01 - Proyectos/         (proyectos activos con fecha límite, no aplica para CWES/CWEE)
02 - Recursos/          (Biblioteca, Lenguajes, Templates, 🛠️ Tools)
03 - Archivos/          (imágenes y adjuntos, también Escalidraw)
04 - PENDIENTES/        (inbox, no aplica para CWES/CWEE)
Ingenieria/             (fundamentos y conocimientos relacionados con la ingeniería de software, bases de datos, criptografía, etc.)
🔴⚔️ Red Team/         (todo el contenido ofensivo, incluido Hacking web)
🔵🛡️ Blue Team/        (defensivo: SOC analyst, analisis de malware y redes, etc.)
Redes/                  (fundamentos de redes, utilidades, protocolos, etc. Interesante para Pentesting y Bug Bounty)
TFG/                    (trabajo fin de grado — no tocar salvo petición)
```

Todo el contenido CWES/CWEE va dentro de `🔴⚔️ Red Team/Hacking web/`, integrado por **tema** (no por módulo HTB). Las carpetas temáticas existentes son la base; se crean carpetas nuevas sólo cuando un tema todavía no existe.

*Nota*: Las carpetas PARA se irán eliminando, la única que se mantendrá será la de "Recursos", el resto irán desapareciendo, las áreas principales de conocimiento se quedarán en el directorio raíz. Estas son: Red Team, Blue Team, Redes, Ingeniería y Recursos.
## Mapeo módulos HTB → carpetas del PKM

### Path CWES (Web Penetration Tester)

| #   | Módulo HTB                          | Carpeta destino                                                       | Estado            |
| --- | ----------------------------------- | --------------------------------------------------------------------- | ----------------- |
| 1   | Web Requests                        | `Hacking web/Web Requests/` *(lo saltamos, no lo tratamos)*           |                   |
| 2   | Introduction to Web Applications    | `Hacking web/Web Applications/` *(lo saltamos, no lo tratamos)*       |                   |
| 3   | Using Web Proxies                   | `Hacking web/Proxies web/`                                            | Completado        |
| 4   | Information Gathering – Web Edition | `Hacking web/Reconocimiento Web/` (notas 00-14)                       | Completado        |
| 5   | Web Fuzzing                         | `Hacking web/Reconocimiento Web/` (notas 15-24, tag `Fuzzing`)        | Completado        |
| 6   | JavaScript Deobfuscation            | `Hacking web/JavaScript Deobfuscation/` *(crear)*                     | Completado        |
| 7   | Cross-Site Scripting (XSS)          | `Hacking web/XSS/`                                                    | Completado        |
| 8   | SQL Injection Fundamentals          | `Hacking web/💉🩸 SQL Injection/1️⃣ Introducción/` (fundamentos DB/SQL en `02 - Areas/Ingeniería/Bases de Datos/`) | Completado |
| 9   | SQLMap Essentials                   | `03 - Recursos/🛠️ Tools/SQLMap/` (herramienta → Tools, NO bajo SQL Injection) | Completado |
| 10  | Command Injections                  | `Hacking web/Command Injection/`                                      | Completado        |
| 11  | File Upload Attacks                 | `Hacking web/File Upload/`                                            | Completado        |
| 12  | Server-side Attacks                 | `Hacking web/{SSRF,SSTI,SSI,XSLT}/` (4 carpetas hermanas · tag `Server-Side`) | Completado |
| 13  | Login Brute Forcing                 | `Hacking web/Brute Forcing/`                                          | Completado        |
| 14  | Broken Authentication               | `Hacking web/Authentication/`                                         | Completado        |
| 15  | Web Attacks                         | `Hacking web/Web Attacks/` (verb tampering, IDOR, XXE · notas 00-20)  | Completado        |
| 16  | File Inclusion                      | `Hacking web/File Inclusion/`                                         | Completado        |
| 17  | Attacking GraphQL                   | `Hacking web/GraphQL/` (notas 00-07)                                  | Completado        |
| 18  | API Attacks                         | `Hacking web/API Attacks/` (OWASP API Top 10 2023 · notas 00-12)      | Completado        |
| 19  | Attacking Common Applications       | `Hacking web/Common Applications/` *(crear)*                          | Pendiente         |
| 20  | Bug Bounty Hunting Process          | `Hacking web/Bug Bounty/` *(crear)*                                   | Pendiente         |

### Path CWEE (Senior Web Penetration Tester)

| # | Módulo HTB | Carpeta destino | Estado |
| - | - | - | - |
| 1 | Injection Attacks | `Hacking web/💉🩸 SQL Injection/2️⃣ Nivel avanzado/Injection Attacks/` | Pendiente |
| 2 | Introduction to NoSQL Injection | `Hacking web/❌💉🩸 NoSQL Injection/` | Pendiente |
| 3 | Attacking Authentication Mechanisms | `Hacking web/Authentication/Avanzado/` | Completado |
| 4 | Advanced XSS and CSRF Exploitation | `Hacking web/XSS/Avanzado/` + `Hacking web/CSRF/` | Completado |
| 5 | HTTPs/TLS Attacks | `Hacking web/HTTPs-TLS/` | Completado |
| 6 | Abusing HTTP Misconfigurations | `Hacking web/HTTP/Misconfigurations/` | Completado |
| 7 | HTTP Attacks | `Hacking web/HTTP/Attacks/` | Completado |
| 8 | Blind SQL Injection | `Hacking web/💉🩸 SQL Injection/2️⃣ Nivel avanzado/Blind/` | Completado |
| 9 | Intro to Whitebox Pentesting | `Hacking web/Whitebox/Intro/` *(crear)* | Pendiente |
| 10 | Modern Web Exploitation Techniques | `Hacking web/Modern Exploitation/` (DNS rebinding · second-order · WebSockets · notas 00-17) | Completado |
| 11 | Introduction to Deserialization Attacks | `Hacking web/Deserialization/Intro/` *(crear)* | Pendiente |
| 12 | Whitebox Attacks | `Hacking web/Whitebox/Attacks/` *(crear)* | Pendiente |
| 13 | Advanced SQL Injections | `Hacking web/💉🩸 SQL Injection/2️⃣ Nivel avanzado/Advanced/` | Completado |
| 14 | Advanced Deserialization Attacks | `Hacking web/Deserialization/Advanced/` *(crear)* | Pendiente |
| 15 | Parameter Logic Bugs | `Hacking web/Parameter Logic Bugs/` *(crear)* | Pendiente |

Antes de crear una carpeta nueva, **siempre verificar** con `ls` o `Glob` que no existe ya bajo otro nombre — el vault tiene cierta inconsistencia histórica (carpetas con emoji vs sin emoji).

## Convenciones de nota

### Frontmatter

Toda nota empieza con este bloque YAML, seguido inmediatamente de dos líneas `---` (la primera cierra el YAML, la segunda es regla horizontal visible):

```yaml
---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion        # fase del pentesting que aplica
  - <tag-tema-específico>         # p. ej. Pentesting/Enumeracion, XSS, SQLi
Fecha de actualización: 2026-05-11
Nota previa: "[[Nombre nota anterior]]"
Nota siguiente: "[[Nombre nota siguiente]]"
Area: "[[XSS.base|XSS]]"     # ← .base Level 2 del sub-tema, NO Level 1 (Web Pentesting.base)
---
---
```

Reglas:
- `Fecha de actualización`: siempre en formato `YYYY-MM-DD` (ISO 8601), fecha real en la que se crea/edita la nota.
- `Nota previa` / `Nota siguiente`: alias entre comillas (`"[[ ]]"`), forman la cadena Zettelkasten dentro de un tema. La primera nota del tema tiene `Nota previa` vacía; la última, `Nota siguiente` vacía.
- `Area`: enlace al `.base` **Level 2** del sub-tema, no al Level 1. Ejemplos: XSS → `[[XSS.base|XSS]]`; SQLi → `[[SQL Injection.base|SQL Injection]]`; Fuzzing → `[[Fuzzing.base|Fuzzing]]`. El Level 1 (`Web Pentesting.base`) agrega Level 2, no notas. Las notas legacy con `Area` apuntando a Level 1 son **deuda a migrar** cuando se trabaje su sub-tema. Ver sección "Vista `.base`" más abajo para la jerarquía completa.
- `tags`: tema + fase pentesting. Reusar tags existentes antes de inventar nuevos (`grep` en el vault para confirmar).

### Marcas con colores (glosario semántico)

Las marcas usan la sintaxis `<mark style="background: COLOR;">texto</mark>`. **Cada color tiene un significado fijo** — no usar al azar:

| Color | Hex | Uso semántico |
| - | - | - |
| Azul claro | `#ADCCFFA6` | Definiciones, conceptos clave, "qué es X". |
| Rosa claro | `#FFB8EBA6` | Matices, detalles importantes, condiciones, probabilidades. |
| Naranja | `#FFB86CA6` | Impacto, criticidad, lo que un atacante consigue/un defensor pierde. |
| Morado | `#8000E1A6` | Reformulaciones / consecuencias destacables, "esto significa que…". |
| Coral-rojo | `#FF5582A6` | Hallazgos accionables durante un pentest, "esto importa para los próximos pasos". También útil para destacar información crítica (errores, resultados) o restricciones muy importantes. |
| Gris claro | `#CACFD9A6` | Apenas usado — información de baja prioridad. Evitar salvo necesidad real. |

Una nota saturada de marcas pierde el sistema. Marcar **lo importante**, no todo.

### Callouts

Para mini-notas aclaratorias, avisos y curiosidades, usar callouts de Obsidian. Puedes crear callouts personalizados siempre que quieras o lo necesites o explorar los que ya hay. Los más usados:

```markdown
> [!important]+
> Texto del callout — aclaración, advertencia o nota lateral.

> [!success]+
> Cuando interpretamos salida de una herramienta y queremos resaltar lo que indica éxito.

> [!warning]+
> Cuando hay un *gotcha* o algo que rompe un payload, evade un WAF, etc.

> [!info]+
> Contexto adicional, historia, RFC, CVE relevante.

> [!fail]+
> Cuando interpretamos salida de una herramienta y queremos resaltar lo que indica fallo o error o que se ha hecho mal algo.
```

El sufijo `+` deja el callout expandido por defecto; `-` lo colapsa. **Las palabras dentro de callouts no cuentan** para el objetivo de 1000–1500 — son contexto complementario.

### Bloques de código

Siempre con lenguaje declarado para que Obsidian aplique syntax highlighting:

- Comandos de shell: ` ```shell-session ` (con `$` o `#` antes del comando).
- HTML: ` ```html `
- JavaScript: ` ```javascript ` o ` ```js `
- SQL: ` ```sql `
- HTTP requests/responses: ` ```http `
- PHP, Python, Bash, Go: lenguaje correspondiente.

```shell-session
$ ffuf -u http://target/FUZZ -w wordlist.txt
```

### Enlaces internos

- Referencias a otras notas del vault: `[[Nombre exacto de la nota]]` o con alias `[[Nombre|alias]]`. También se puede refenciar a apartandos concretos de otra nota con `[[Nombre#Apartado]]`, como eso queda feo de leer, habría que añadir también un alias, quedando algo como `[[Nombre#Apartado|Alias]]`.
- Las notas siguientes/previas se encadenan en el frontmatter; los enlaces "tematicos" (XSS → menciona `[[HTTP]]`) van en el cuerpo.
- Si una nota referencia un concepto que **todavía no existe**, crear el wikilink igualmente (`[[Deserialización Java]]`) — Obsidian lo mostrará como nota fantasma y servirá de TODO.

### Imágenes

- Las imágenes de HTB Academy se incrustan **directamente desde su URL pública**:
  ```markdown
  ![Descripción accesible breve de la imagen](https://academy.hackthebox.com/storage/modules/XXX/imagen.jpg)
  ```
  Esto preserva el ancho de banda local y mantiene la atribución implícita.
- Capturas propias (TFG, proyectos, lab personal) se guardan en `04 - Archivos/Images/<contexto>/` y se referencian con la ruta relativa.
- **Criterio para incluir una imagen HTB**: incluirla solo si aporta valor real — diagramas, screenshots de payloads ejecutándose, matrices conceptuales, capturas de UI específicas. Una captura de terminal trivial que se puede expresar como bloque de código → no incluir.

### Tablas

Usar para comparativas (herramientas, tipos de vulnerabilidad, payloads por contexto). Mantener cabeceras concisas. Si una tabla pasa de 8 filas, considerar si conviene una lista o múltiples tablas más pequeñas.

## Flujo de extracción HTB → nota (usando la agent skill agent-browser, para saber cómo utilizar el navegador)

El usuario inicia sesión en HTB Academy desde su navegador. La extracción de un módulo se ejecuta en **3 fases iterativas** (más una Fase 0 de planificación). **No avanzar** a la siguiente fase sin terminar la actual.

### Fase 0 — Planificación (una vez por módulo)

1. **Negociar el módulo**. El usuario dice "vamos con `Web Fuzzing`" o equivalente. Identificar el módulo en el path y la carpeta destino del mapeo de arriba.
2. **Navegar con un browser (usando la agent skill mencionada)**. Abrir el módulo, listar todos sus capítulos (nombres, URLs, número total).
3. **Presentar al usuario el plan** y esperar confirmación:
   - Nº de capítulos HTB y mapeo capítulo → nota(s): 1:1, M:1 (varios cortos comparten tema), 1:N (uno enorme se divide).
   - Cadena Zettelkasten propuesta (`prev`/`next`).
   - Carpeta(s) destino (ruta absoluta) y carpetas a crear.
   - `.base` **Level 2** del sub-tema (a usar o a crear antes de Fase 1).
   - Tags propuestos (reusar antes de inventar).

### Fase 1 — Extracción capítulo a capítulo (iterativo, en orden ascendente)

Para cada capítulo, completar **una nota entera antes de pasar a la siguiente** (corte vertical):

1. Extraer texto + URLs de imágenes + bloques de código del capítulo.
2. **Traducir al español** preservando términos técnicos en inglés con backticks.
3. **Eliminar relleno HTB**: introducciones motivacionales, "in this module you will learn…", reformulaciones triviales, transiciones obvias, recapitulaciones, "as we saw earlier…", elogios genéricos.
4. **Enriquecer con contexto profesional**: cuándo aparece la técnica en un pentest real, herramientas alternativas, *gotchas* de producción (WAF, rate limiting, sanitización moderna, cookies `SameSite`), CVE relevantes, definiciones de conceptos asumidos.
5. **Alcanzar 1000–1500 palabras de teoría**. Si era corto y no hay nada que enriquecer → fusionar con la siguiente sección. Si es enorme → dividir.
6. **Aplicar formato del PKM**: frontmatter (`Area` → `.base` Level 2), marks semánticos, callouts, bloques de código con lenguaje, imágenes HTB cuando aporten.
7. **Encadenar Zettelkasten**: rellenar `Nota previa`/`Nota siguiente` de la nueva **y actualizar `Nota siguiente` de la nota anterior** para apuntar a ella.

### Fase 2 — Cierre del capítulo (al terminar cada nota de Fase 1)

Antes de pasar al siguiente capítulo:

1. **Re-leer la nota recién creada** y añadir `[[wikilinks]]` en el cuerpo donde un concepto ya tiene nota propia (módulo actual + sub-tema actual).
2. **Mejorar redacción, explicaciones, ejemplos** con el contexto adquirido. Se permite **modificar capítulos anteriores del mismo módulo** si surge una mejora obvia (renombrar un término para alinear, añadir una referencia cruzada).
3. **No avanzar al siguiente capítulo** hasta sellar el actual.

### Fase 3 — Cierre del módulo (obligatoria antes de dar el módulo por terminado)

Aplica siempre, también al primer módulo del path aunque haya poco PKM con el que cruzar. **No se omite** aunque ya hayas enlazado oportunísticamente durante Fases 1 y 2 — es la pasada explícita y exhaustiva.

1. **Revisión cruzada con el resto del PKM**: para cada nota del módulo, buscar enlaces a notas de **otros módulos / otros sub-temas / otras áreas**. Herramientas: `obsidian backlinks`, `obsidian search:context`, `Grep` sobre conceptos clave.
2. **Integrar los enlaces** en el cuerpo de las notas reescribiendo párrafos cuando aporte coherencia. No basta con añadir `[[X]]` sueltos — la referencia debe encajar en el flujo.
3. **Mejorar redacción a nivel global del módulo** con la perspectiva completa: detectar repeticiones entre capítulos, ajustar definiciones que ahora se ven incoherentes, refinar la cadena `prev`/`next` si el orden óptimo cambió.
4. **Actualizar la MOC `.base` Level 2** del sub-tema (filtro, columnas, vistas). Si apareció un sub-tema nuevo, comprobar también el Level 1.
5. **Reportar al usuario**: notas creadas, carpetas tocadas, MOCs Level 1/2 modificadas, enlaces cross-módulo añadidos (cuantitativo), pendientes (notas fantasma). No hacer `git commit` — esperar instrucción explícita.

> **Atajo permitido**: los enlaces cross-módulo de Fase 3 se pueden empezar oportunísticamente en Fases 1 o 2 cuando salten a la vista. **Pero Fase 3 nunca se omite** — es el sello del módulo dentro del grafo del PKM.

### Criterios de "relleno" a eliminar

- Introducciones de tipo "este módulo enseña X" / "veremos cómo Y".
- Repeticiones de definiciones ya dadas en notas previas.
- "Conclusiones" que solo resumen lo dicho.
- Frases auto-referenciales al curso HTB que no aplican al PKM ("complete the skills assessment", "this section is graded").
- Listas de prerrequisitos genéricos.
- "Tips" o "best practices" obvias para alguien con experiencia.

### Criterios para añadir contexto propio

- Cuando el original asume conocimiento que conviene explicitar (referencia un concepto sin definirlo).
- Cuando hay un *gotcha* en producción que HTB omite por estar en lab controlado (WAFs, rate limiting, sanitización moderna, cookies `SameSite`).
- Cuando existe una herramienta más usada en bug bounty actual que la del módulo (p. ej. `caido` vs Burp, `nuclei` para fuzzing dirigido).
- Cuando una CVE famosa o un hallazgo real de bug bounty ilustra el concepto.
- Cuando la explicación se beneficia de un diagrama mental o una tabla comparativa que el original no tiene.

## Vista `.base` (MOCs de Obsidian) — jerarquía de 2 niveles

Las MOC del vault usan el formato nativo de Obsidian Bases (`.base`) y se organizan en **dos niveles**:

### Level 1 — Índice de tema grande

- **Ubicación**: raíz de una carpeta temática mayor (ej. `🔴⚔️ Red Team/Hacking web/Web Pentesting.base`).
- **Función**: índice de los `.base` **Level 2 hijos**, no de notas individuales. Equivalente a una tabla de contenidos del tema mayor — lista sub-temas (XSS, SQL Injection, Fuzzing, ...) cada uno representado por su Level 2.
- Las notas **no apuntan aquí** con `Area`.

Filtro estándar Level 1 (lista los `.base` Level 2 bajo la carpeta del tema):

```yaml
views:
  - type: table
    name: Sub-temas
    filters:
      and:
        - file.ext == "base"
        - file.folder.startsWith("🔴⚔️ Red Team/Hacking web")
        - file.name != "Web Pentesting"   # excluir el propio Level 1
    sort:
      - property: file.name
        direction: ASC
```

### Level 2 — Índice de sub-tema concreto

- **Ubicación**: dentro de la sub-carpeta del sub-tema (ej. `🔴⚔️ Red Team/Hacking web/XSS/XSS.base`).
- **Función**: índice de las notas atómicas del sub-tema. A este `.base` apuntan las notas vía su propiedad `Area`.
- **Filtro estándar**: `Area == link("<este .base>.base", "<alias>")`. Desacopla el listado de la ubicación física de la nota — robusto ante reorganizaciones.

Ejemplo (XSS.base):

```yaml
views:
  - type: table
    name: Notas del sub-tema
    filters:
      Area == link("XSS.base", "XSS")
    order:
      - file.name
      - file.tags
    sort:
      - property: file.name
        direction: ASC
```

### Reglas operativas

- Cuando una nota nueva entra en un sub-tema, su `Area` apunta al **Level 2** del sub-tema. Si el Level 2 no existe todavía, **crearlo primero** (en Fase 0 del módulo HTB que se vaya a extraer, o como acción previa a la nota suelta).
- **No crear `.base` Level 2 prematuros** (vacíos, sin notas inminentes). Crearlos justo antes de necesitarlos.
- Cuando aparece un Level 2 nuevo bajo una carpeta de tema grande, verificar que el filtro del Level 1 lo recoge (puede requerir actualizar la cláusula `file.folder.startsWith(...)`).
- Notas legacy con `Area` apuntando al Level 1 (p. ej. `Web Pentesting.base`) son **deuda a migrar**. Al crear el Level 2 correspondiente, migrar `Area` de **todas** las notas del sub-tema en lote (`obsidian property:set` o `Edit` directo del frontmatter).

## Plantilla base (Templater)

Existe `03 - Recursos/Templates/Template para proyectos.md` con el frontmatter vacío. Para crear una nota a mano siguiendo la convención, copiar este esqueleto:

```markdown
---
tags:
  - Web/Red-Team
  - <tag-tema>
Fecha de actualización: YYYY-MM-DD
Nota previa: "[[<previa>]]"
Nota siguiente: "[[<siguiente>]]"
Area: "[[<MOC>.base|<MOC display>]]"
---
---

<contenido aquí>
```

## Plugins, skills y MCP disponibles

### Skills locales del proyecto (en `.claude/skills/`)

Estas se activan automáticamente cuando la descripción coincide con la tarea. **Son las que codifican el workflow del PKM**:

- `htb-extraction-workflow` — Playbook completo para extraer un módulo de HTB Academy con Playwright MCP: precondiciones, plan de fragmentación, transformaciones obligatorias, corte vertical (nota completa antes de pasar a la siguiente), MOC, reporte. Se activa al mencionar "extraer módulo X", "vamos con X de HTB", etc.
- `pkm-note-format` — Referencia del formato exacto: frontmatter, glosario de colores hex con ejemplos, callouts, bloques de código con lenguaje, imágenes, voz/estilo, checklist final. Se activa al crear/editar cualquier nota del vault.
- `zettelkasten-linking` — Procedimientos de mantenimiento de la cadena `Nota previa`/`Nota siguiente` para las 6 operaciones (crear al final, insertar, borrar, renombrar, dividir, fusionar). Evita romper enlaces silenciosamente.
- `pkm-design-grilling` — Interrogatorio dirigido antes de cualquier decisión estructural del PKM (reorganizar carpetas, crear MOCs, fusionar temas, renombrados masivos). 8–20 preguntas categorizadas por motivación, alcance, convenciones, reversibilidad y modelo mental antes de proponer plan. Adaptación PKM de `/grill-me` de aihero.dev.
- `pkm-structure-audit` — Auditoría de salud del vault: wikilinks rotos, cadenas Zettelkasten rotas, densidad de notas fuera de rango, taxonomía de tags duplicada, MOCs `.base` obsoletas, frontmatter inconsistente. Produce informe priorizado sin tocar archivos. Adaptación PKM de `/improve-codebase-architecture` de aihero.dev.

### Plugins ya instalados a nivel usuario (`~/.claude/settings.json`)

- `playwright@claude-plugins-official` — MCP para HTB Academy. **Núcleo del flujo de extracción.**
- `superpowers@claude-plugins-official` — skills generales de desarrollo, brainstorming, debugging.
- `claude-md-management@claude-plugins-official` — gestión de este propio archivo.
- `context7@claude-plugins-official` — documentación de librerías y frameworks.
- `chrome-devtools-mcp@claude-plugins-official` — debugging de páginas web.
- `feature-dev`, `code-review`, `code-simplifier`, `commit-commands`, `mongodb`, `security-guidance`, `frontend-design`, `typescript-lsp` (todos `@claude-plugins-official`).

### Plugins instalados de Trail of Bits (`trailofbits` marketplace)

Marketplace clonado en `~/.claude/plugins/marketplaces/trailofbits/`. Plugins habilitados, relevantes para web pentesting / white-box / bug bounty:

- `ask-questions-if-underspecified` — Clarifica requisitos ambiguos antes de implementar. Útil para planificar la fragmentación de módulos HTB.
- `audit-context-building` — Análisis ultra-granular para construir contexto arquitectónico antes de cazar vulnerabilidades. **Clave para módulos white-box de CWEE**.
- `burpsuite-project-parser` — Extracción de datos de archivos `.burp`. Requiere Burp Suite Pro + extensión `burpsuite-project-file-parser` para uso completo. Útil cuando documentemos hallazgos reales.
- `differential-review` — Revisión de cambios de código con análisis de blast radius y git history. Útil para analizar parches de CVEs.
- ~~`fp-check`~~ — *Deshabilitado* (2026-05-13): su Stop hook con `matcher: "*"` se ejecutaba en cada cierre de turno y producía ruido visible. Para reactivarlo cuando se necesite (verificación de hallazgos de bug bounty, análisis de FPs), cambiar `"fp-check@trailofbits": false` → `true` en `~/.claude/settings.json` y ejecutar `/reload-plugins`.
- `insecure-defaults` — Detecta credenciales hardcodeadas, autenticación débil, configuraciones fail-open.
- `semgrep-rule-creator` — Desarrolla reglas Semgrep personalizadas. Útil para módulos white-box.
- `sharp-edges` — Identifica APIs propensas a error, configuraciones peligrosas y *footguns* de diseño.
- `static-analysis` — Toolkit con CodeQL + Semgrep + SARIF parsing. Requiere CodeQL/Semgrep instalados para ejecución completa. **Clave para white-box de CWEE**.
- `testing-handbook-skills` — Metodologías del Trail of Bits Testing Handbook (fuzzers, static analysis, sanitizers, coverage).
- `variant-analysis` — Encuentra vulnerabilidades similares en bases de código mediante pattern matching. Útil para escalar un hallazgo.
- ~~`second-opinion`~~ — *Desactivado*: requiere OpenAI Codex CLI o Google Gemini CLI instalado. Si en el futuro instalas alguno de los dos, se puede reactivar añadiendo `"second-opinion@trailofbits": true` a `~/.claude/settings.json`.

### Plugin bundle `example-skills` de Anthropic

Marketplace `anthropic-agent-skills` ya configurado. Habilitado `example-skills@anthropic-agent-skills` que incluye:

- **`doc-coauthoring`** — Workflow estructurado para co-autoría de docs (Context Gathering → Refinement → Reader Testing). **Útil para notas largas o complejas**.
- `skill-creator` — Para crear más skills si surgen necesidades nuevas.
- `mcp-builder` — Para construir MCP servers personalizados.
- `webapp-testing` — Pruebas de aplicaciones web.
- Otras skills decorativas (algorithmic-art, slack-gif-creator, theme-factory) que se ignoran salvo que se invoquen.

### Marketplaces a nivel usuario (`~/.claude/settings.json`)

- `claude-plugins-official` (anthropics/claude-plugins-official)
- `anthropic-agent-skills` (anthropics/skills)
- `trailofbits` (trailofbits/skills)

### Obsidian CLI oficial — herramienta principal de manipulación del vault

Obsidian 1.12.4+ (febrero 2026) incluye una **CLI oficial** que se instala automáticamente con la app de escritorio. El binario `obsidian` está en `PATH` (`C:\Users\Samuel\AppData\Local\Programs\Obsidian\Obsidian.exe`) y se invoca **vía Bash** sin necesidad de MCP intermedio.

**Por qué CLI > cualquier MCP de Obsidian**: es oficial, mantenida por el equipo de Obsidian, cubre 80+ comandos (más que cualquier MCP de terceros), no requiere API key ni proceso adicional, y Claude la invoca como cualquier otro comando shell.

**Requisito de uso**: Obsidian debe estar **abierto** en el vault del PKM. La CLI actúa como cliente del proceso de Obsidian — si la app está cerrada, los comandos fallan.

**Comandos esenciales** (lista completa con `obsidian help`):

```shell-session
# Archivos y contenido
$ obsidian files                              # listar todos los archivos
$ obsidian read file="XSS Almacenado"         # leer una nota
$ obsidian create path="XSS/Avanzado.md" content="..."
$ obsidian append file="..." content="..."
$ obsidian move file="..." path="nuevo/path.md"
$ obsidian delete file="..."

# Frontmatter (properties)
$ obsidian property:set file="X" name="Nota siguiente" value="[[Y]]"
$ obsidian property:read file="X" name="tags"
$ obsidian properties                         # inventario de properties del vault

# Links y estructura
$ obsidian backlinks file="X" format=json    # backlinks de una nota
$ obsidian links file="X"                     # links salientes
$ obsidian orphans                            # notas sin enlaces entrantes
$ obsidian deadends                           # notas sin enlaces salientes

# Bases (MOCs)
$ obsidian bases                              # listar archivos .base
$ obsidian base:query file="Web Pentesting.base" view="Tabla"

# Plugins
$ obsidian plugins                            # listados instalados
$ obsidian plugins:enabled                    # solo los activos
$ obsidian plugin:install <plugin-id>         # instalar uno del catálogo
$ obsidian plugin:enable <plugin-id>
$ obsidian plugin:disable <plugin-id>

# Search
$ obsidian search "XSS reflected"
$ obsidian search:context "payload" 

# Templates
$ obsidian templates
$ obsidian template:insert file="X" name="Template para proyectos"

# Tags
$ obsidian tags
$ obsidian tag name="Pentesting/Enumeracion"

# Command palette directo (puerta de escape)
$ obsidian commands                           # listar comandos disponibles
$ obsidian command id="<command-id>"
```

**Skills oficiales instaladas** (plugin `obsidian@obsidian-skills`, autor Steph Ango — fundador de Obsidian). Cárgalas todas siempre antes de empezar a crear notas y a investigar. Es siempre lo primero de todo que debes hacer. Skills Obsidian:

- `obsidian-cli` — Cómo usar la CLI correctamente, patrones idiomáticos, escapes seguros.
- `obsidian-markdown` — Crear/editar markdown con sintaxis Obsidian (wikilinks, callouts, embeds).
- `obsidian-bases` — Crear y manipular archivos `.base` (las MOCs del vault).
- `json-canvas` — Trabajar con archivos `.canvas` (vistas canvas de Obsidian).
- `defuddle` — Extracción de contenido web limpio (artículos → notas).

### Skills/plugins de terceros NO instalados (con razón)

- **Skills de Zettelkasten/PKM de marketplaces no oficiales** (mcpmarket.com, skillsllm.com): Snyk encontró *prompt injection* en el 36% de skills auditadas en estos marketplaces. Las skills locales del proyecto (`htb-extraction-workflow`, `pkm-note-format`, `zettelkasten-linking`) cubren la funcionalidad sin importar código de terceros.
- **Plugins HTB-machine-pwning** (`allsmog/blackbox-claude-plugin`, etc.): orientados a explotar máquinas HTB Labs, no a crear notas. Fuera de alcance.

## Operativa con Git

- El vault es un repositorio git con su origen en `Obsidian Git` (plugin de Obsidian). Los commits con mensaje `Fecha: DD/MM/YYYY` los hace el plugin automáticamente al cerrar Obsidian.
- **Claude no hace commits a menos que el usuario lo pida explícitamente.** Cuando lo pida, seguir las reglas de la sección "Committing changes with git" del system prompt (mensajes en español si se acompaña al estilo del repo; firmar con `Co-Authored-By` solo si el usuario lo pide).
- No tocar `.obsidian/` salvo que se solicite cambiar configuración. Los cambios de ese directorio que aparezcan modificados (`M .obsidian/...`) en `git status` son actualizaciones de plugins gestionadas por Obsidian.

## Consideraciones de uso del contenido HTB

- HTB Academy **permite** usar su contenido para apuntes personales/educativos. **Prohíbe** la comercialización o redistribución como producto. Este PKM es de uso estrictamente personal.
- Las imágenes se referencian por URL pública (`academy.hackthebox.com/storage/...`) — eso preserva la atribución implícita.
- Si el contenido se va a publicar fuera del vault (blog, charla), revisar con HTB.

## Reglas operativas para mí (Claude)

- **Idioma de las notas**: español. **Idioma de mensajes al usuario**: español por defecto (es nativo del usuario).
- Antes de crear una carpeta nueva, comprobar con `Glob`/`ls` que no existe ya bajo otro nombre.
- Antes de crear un tag nuevo, hacer `grep` en el vault por el tag deseado o variantes.
- Antes de enlazar a una nota, comprobar que el nombre exacto coincide (los wikilinks rotos en Obsidian son silenciosos).
- Cuando extraiga un módulo HTB completo, **resumir al usuario el plan de fragmentación antes de escribir**, salvo en módulos cortos (<8 secciones).
- No tocar `TFG/` salvo petición explícita. Tampoco `🔵🛡️ Blue Team/` ni `Redes/` salvo que la tarea lo requiera.
- Si encuentro inconsistencia en el vault (notas con frontmatter incompleto, enlaces rotos, MOCs desactualizadas), **flaggear al usuario** — no "limpiar" silenciosamente.
- El campo `Fecha de actualización` se rellena con la fecha real del día (hoy es `2026-05-11`); convertir fechas relativas siempre a absolutas.
