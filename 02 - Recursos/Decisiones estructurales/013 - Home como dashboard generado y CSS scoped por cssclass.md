---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-31
Estado: Aceptada
---
---

## Contexto

El plugin comunitario **Homepage** llevaba tiempo configurado (`openOnStartup`, `pin`, `Replace all open notes`) apuntando a `🏡 Home.md` — un archivo de **0 bytes**. Cada arranque de Obsidian abría una nota vacía y cerraba el resto de pestañas.

El vault tiene 1142 notas y 150 `.base` en la jerarquía de 3 niveles de la ADR 009. Esa jerarquía resuelve muy bien la navegación **dentro** de un área, pero deja dos huecos que ningún `.base` cubre:

1. **Nada cruza áreas.** Para ir de Red Team a Tools hay que pasar por el explorador. No existe un punto donde las 6 áreas convivan.
2. **Nada muestra estado.** El progreso de las 4 certificaciones, qué se tocó esta semana y la deuda acumulada (notas sin `Area`, sin `Descripción`, sin tocar en 180 días) solo se ven abriendo cada Level 0 por separado — o no se ven.

Los `.base` Level 0 ya traen vistas de mantenimiento (`Sin tocar (>180 días)`, `Arsenal`, `Detección y evasión`), pero **por área**. La pregunta "¿qué hago hoy y qué tengo pendiente en todo el vault?" no la responde ninguno.

## Decisión

**1 · La home es un dashboard generado por `dataviewjs`, no un `.base` ni una MOC manual.** Dos bloques: hero + áreas + certificaciones + qué toca ahora, y buscador + los 3 ejes + actividad/deuda/cadenas rotas. Todo sale del índice de Dataview o de las casillas del temario; **no queda ningún dato escrito a mano en la Home**. Ambos bloques van envueltos en `try/catch` con fallback estático.

**1b · El progreso vive en `📋 Temario.md`, no en la Home.** Los módulos son casillas agrupadas bajo encabezados `## SIGLA · Nombre`. La Home **no contiene ninguna lista de certificaciones**: parsea el temario crudo y crea un anillo por cada encabezado que lleve `·`, con el color asignado solo y la descripción tomada del párrafo que hay debajo. Añadir una certificación nueva es escribirla en el temario y nada más. Los **saltados van sin casilla** (`- ~~Módulo~~ — motivo`) en vez de con `[-]`, porque un checkbox solo alterna vacío ↔ marcado y un clic destruía el estado. `Check List Red Team.md` —una nota suelta con un plan semanal— queda absorbida y borrada.

**1c · Las secciones declaran su criterio.** Ningún bloque muestra una lista sin explicar de dónde sale: los ejes indican su etiqueta (`#Tipo/Arsenal`…), qué representan y cómo se reparte el total por área. Una lista sin criterio visible es ruido, por muy bien que se vea. Los ejes se **descubren del índice de etiquetas** —un `Tipo/` nuevo aparece solo— y su nombre, color y criterio se declaran en la sección `## Ejes` del temario, no en la Home.

**1e · Toda la configuración del panel vive en el temario, ninguna en la Home.** Certificaciones, planificación y fichas de los ejes se editan en `📋 Temario.md`; la Home solo lee, calcula y pinta. El listón que se aplicó a cada pieza: *si añadir algo obliga a abrir la Home, no está terminado*. Se comprobó con las dos: una certificación de prueba y un eje `Tipo/` de prueba aparecieron completos sin tocar una línea de la nota.

**1d · La planificación va en el temario, no en una nota aparte.** Una sección reservada `## Plan de estudio` con una tarea por línea, apoyada en el plugin **Tasks** que ya estaba instalado (estados `[ ]`/`[/]`/`[x]`/`[-]`, fechas `🛫`/`📅`, prioridades) más campos inline de Dataview para lo que Tasks no cubre: `esfuerzo`, `depende`, `nota`. El temario pasa así a contener el **qué** (catálogo de módulos) y el **cuándo** (plazos), que es lo que se consulta a la vez. La Home no guarda ni una fecha: calcula el plazo consumido, diagnostica (`vencida`, `sin arrancar`, `en riesgo`, `bloqueada`) y suma la carga pendiente en horas.

**2 · El CSS vive en un snippet dedicado y va *scoped* por `cssclasses`.** `.obsidian/snippets/home-dashboard.css` (~640 líneas) actúa solo bajo `.home`, que llega por el frontmatter de la nota. Ninguna regla escapa a otra nota del vault.

**3 · Doble tema por tokens, no por duplicación.** Los colores se declaran una vez como variables en `.theme-light .home` (Soft Paper: acentos profundos sobre papel) y `.theme-dark .home` (AnuPpuccin: pasteles Catppuccin Mocha). El resto del CSS es agnóstico al tema.

**4 · Iconos SVG inline (Lucide), nunca emoji**, en cualquier elemento que el CSS deba teñir o dimensionar.

**5 · La home es nota meta**: sin cadena Zettelkasten, sin `Area` y sin tags de contenido — como las propias ADR y las fichas de la Biblioteca. No es conocimiento, es mobiliario.

**6 · La Home escribe, no solo lee — pero solo en el temario y solo el estado.** El círculo de cada tarea cicla pendiente → en progreso → hecha y reescribe esa línea con `vault.process()` (atómico, no pisa una edición simultánea), localizando la tarea por **número de línea** y comprobando antes que sigue siendo una tarea. Es la única escritura que hace el panel: nada más del vault se modifica desde aquí.

## Alternativas descartadas

- **Un `.base` como home** (un "Level −1" que indexara los Level 0). El plugin Homepage los acepta y sería coherente con "los índices son `.base`". Descartado: un `.base` es *una consulta con vistas*, no un panel — no puede mezclar hero, barras de progreso y tres bloques heterogéneos, y no da ningún control tipográfico. Además `base:query` no indexa ficheros `.base` (gotcha ya documentado), así que el propio índice sería ciego a lo que quiere listar.
- **Embeber los Level 0 con `![[Red-Team.base]]`.** Es la opción más "nativa" y la primera que se considera. Descartada por dos motivos: cada embed arrastra su UI completa (selector de vistas, barra de filtros, botón de añadir), de modo que seis embeds dan una pantalla ruidosa y sin jerarquía visual; y el coste de renderizar seis consultas sobre 1142 notas al arrancar es justo lo que no quieres en la nota que se abre sola.
- **MOC manual en Markdown con wikilinks.** Cero dependencias y a prueba de futuro. Descartada porque obliga a mantener a mano seis listas y todos los contadores: exactamente la clase de trabajo que la ADR 009 quitó de encima al pasar de MOC manuales a `.base`.
- **Dataview DQL sin JavaScript.** Se probó y se midió: **las queries inline no se procesan dentro de HTML crudo** — un `` `$= …` `` dentro de un `<div>` sale literal en pantalla. Sin JS no hay forma de meter un contador dentro de una tarjeta; habría que elegir entre tarjetas sin números o números escritos a mano que envejecen.
- **Emoji como iconos de las tarjetas.** Es lo obvio y lo que usa el resto del vault en nombres de carpeta. Descartado tras verlo fallar: un plugin instalado reescribe los emoji a `<img class="emoji">` **sin retirar el glifo de texto**, así que cada icono se pintaba dos veces. Los SVG además se tiñen con el acento del área vía `currentColor`, cosa que un emoji no permite.
- **El plugin `obsidian-dynamic-background`** (ya instalado, desactivado) para el fondo animado. Descartado: actúa sobre **todo el workspace**, no sobre una nota. El fondo animado de la home se resuelve con cuatro capas CSS dentro del propio hero.
- **CSS global sin `cssclasses`.** Más simple de escribir. Descartado por principio: 900 líneas de reglas sueltas sobre un vault de 1150 notas es una fuente de efectos colaterales imposible de depurar meses después.
- **El progreso como array dentro de la Home** (primera versión, descartada el mismo día). Un `CERTIS = [{sigla:"CPTS", hechos:27, total:28}]` es trivial de escribir, pero convierte el panel en un cartel: los números los mantienes tú, envejecen en silencio y no hay forma de ver *qué* módulo falta. Con las casillas, el dato y su estado son la misma cosa.
- **Un array con solo las siglas y sus colores** (segunda versión, también descartada). Quitaba los números pero dejaba la lista de certificaciones escrita en la Home, de modo que añadir una OSCP al temario **no habría hecho nada**: sin su línea en el array, ni anillo ni pendientes. Se sustituye por descubrimiento desde el propio temario. La prueba que zanjó el asunto: añadir una certificación de prueba y comprobar que aparecía sin tocar la Home.
- **Leer el temario con `file.tasks` de Dataview** en vez de parsear el fichero crudo. Es la vía natural y fue la primera. Falla por dos sitios a la vez: Obsidian **normaliza el subpath del heading y se come el `·`**, que es justo el carácter que distingue una certificación de una sección auxiliar; y los saltados, al no ser casillas, **no se indexan como tareas**, así que no habría manera de contarlos. Se lee con `cachedRead` y se parsea a mano.
- **Derivar el progreso de las tablas de `CLAUDE.md`.** Es donde ya vivía la verdad, así que sería fuente única de verdad. Descartado: `CLAUDE.md` no es una nota del vault (Dataview no lo indexa como contenido consultable) y parsear tablas markdown por regex para pintar un anillo es frágil de un modo que no compensa.
- **Un heatmap de actividad estilo GitHub.** Se midió antes de construirlo: solo hay **11 meses distintos** con `Fecha de actualización` y las notas se escriben en lotes al extraer un módulo. El calendario habría salido casi vacío con tres manchas densas — vistoso en la captura, ilegible como información.
- **Dejar la "cabina operativa" mostrando las 12 notas más recientes de cada eje.** Era la primera versión. Se retiró porque *"las 12 más recientes de un tag"* no responde a ninguna pregunta que alguien se haga de verdad, y nada en pantalla explicaba el criterio. Se sustituye por el reparto por área, que sí dice algo: dónde está concentrado cada eje y qué área lo tiene flojo.

## Consecuencias

- **Dependencia nueva y explícita: Dataview con JavaScript habilitado** (`enableDataviewJs`, `enableInlineDataviewJs`). Es la primera vez que el vault depende de ejecución de JS para que algo se vea. Acotada a la home, con `try/catch` y fallback: si Dataview se cae o se desinstala, la home degrada a hero estático en vez de romperse.
- **Precedente: la "nota-panel" como tercer tipo.** El vault tenía notas atómicas (conocimiento) e índices `.base` (navegación). Aparece un tercero: la nota que ni enseña ni indexa, sino que **presenta estado**. Se rige por reglas propias — sin Zettelkasten, sin `Area`, con CSS scoped, y con datos calculados en vez de escritos.
- **La deuda del vault deja de ser invisible.** El radar destapa de un vistazo: **75 notas sin `Area`** (no aparecen en ningún Level 2), **59 sin `Fecha de actualización`** —que en la primera versión ni se contaban, porque el radar solo miraba las que la tenían y justo las peores se escapaban—, **25 con `Area` pero sin `Descripción`** y **24 sin tocar en más de 180 días** (las peores rondan los 665). Ninguna se ha tocado: la home informa, no limpia.
- **Aparece un vigilante de cadenas Zettelkasten.** Los wikilinks rotos son silenciosos en Obsidian y nada los revisaba; el panel compara cada `Nota previa` / `Nota siguiente` contra `metadataCache` y lista las que no resuelven. Primera pasada: **2 rotas**, ambas notas-cola apuntando a una nota planificada y no escrita — pueden ser enlaces fantasma deliberados (el vault los admite como TODO), pero ahora se ven.
- **Doble anotación al cerrar un módulo**, y es el coste consciente de esta decisión: las tablas de path de `CLAUDE.md` guardan el **mapeo y el detalle** (carpeta destino, número de notas, qué se modernizó, erratas de HTB); el temario guarda solo el **estado**. Fusionarlos exigiría meter todo el detalle en una nota del vault o parsear `CLAUDE.md`, y ninguna de las dos compensa. Queda anotado en `CLAUDE.md` como aviso explícito.
- **`Decisiones estructurales.base`**: las ADR pasan a tener índice propio, como cualquier sub-tema. Nace de un fallo real — el chip de la home enlazaba a la *carpeta*, y al pulsarlo Obsidian **creó una nota vacía homónima** que además secuestraba el wikilink `[[Decisiones estructurales]]`. Regla que queda sentada: **nunca enlazar a una carpeta**; se enlaza a un `.base` o a una nota real.
- **Hallazgos técnicos reutilizables**, verificados contra Obsidian 1.13.4 y anotados en `CLAUDE.md`: las queries inline mueren dentro de HTML crudo; `<a class="internal-link" href="…">` **sí** resuelve rutas a `.base` desde HTML generado; Live Preview recorta el ancho **dos veces** (el sizer y además `.cm-content` con el *readable line length*), de modo que liberar solo el primero deja el panel a media anchura en edición y ancho en lectura; y **en el arranque el índice de Dataview todavía no está montado**, así que un fichero se localiza con `metadataCache.getFirstLinkpathDest` y no con `dv.page()`.
- **Una nota-panel que se abre al arrancar corre contra el índice.** Es el riesgo propio de este tipo de nota y no aplica a ninguna otra del vault: los anillos llegaban a pintarse a `0/0` durante un instante en cada arranque, hasta el refresco siguiente de Dataview. Se resuelve resolviendo el fichero por `metadataCache` y reintentando la lectura si sale vacía. Comprobado con tres reinicios seguidos.
- **Mantenimiento acotado a una cosa**: el array `CERTIS`. Si un día las certificaciones dejan de ser el motor de contenido, se borra el array y la sección desaparece sin tocar nada más.
- **Migración**: ninguna. La nota estaba vacía y el snippet es nuevo. El único cambio de configuración es una línea en `appearance.json` (`enabledCssSnippets`); tema, fuente y tamaño quedan intactos.
