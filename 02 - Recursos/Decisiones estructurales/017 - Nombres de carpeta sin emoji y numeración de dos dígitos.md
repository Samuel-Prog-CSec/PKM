---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-01
Estado: Aceptada
---
---

## Contexto

Dos inconsistencias arrastradas desde la migración PARA se volvieron un coste operativo real:

**1 · Los emoji en las carpetas raíz.** `🔴⚔️ Red Team/` y `🔵🛡️ Blue Team/` obligaban a entrecomillar y a pelearse con la codificación en cada `cd`, `grep` o script de PowerShell. El prefijo de Red Team son cuatro unidades UTF-16 (`D83D DD34 2694 FE0F`) y el de Blue Team cinco (`D83D DD35 D83D DEE1 FE0F`), con selectores de variación incluidos — suficiente para que las herramientas fallen de forma silenciosa. Durante esta misma reorganización, la herramienta `Grep` devolvió **"sin resultados" sobre patrones que sí existían**, y el fallo solo se detectó porque el panel de cadenas rotas de la Home lo delató. Un vault donde la búsqueda miente es un vault en el que no se puede confiar para auditar.

**2 · La numeración de tres dígitos.** `Pentesting/` (12 sub-carpetas) y `Blue Team/` (7) usaban `000 - `, `001 - `… mientras el resto del vault usa dos dígitos (`04 - XSS`, `01 - Prompt Injection`, `02 - Ataques a WEP`). No había razón para la excepción: ni de lejos llegan a los 100 sub-temas que justificarían el tercer dígito.

## Decisión

**1 · `🔴⚔️ Red Team/` → `Red Team/` y `🔵🛡️ Blue Team/` → `Blue Team/`.** Los emoji desaparecen del nombre de carpeta. La identidad visual en el explorador **no se pierde**: la aportan los iconos del plugin `obsidian-icon-folder`, que ya asignaba icono a estas carpetas por ruta y se reasignó solo al renombrar.

**2 · `0XX - ` → `0X - `** en las 12 sub-carpetas de `Pentesting/` (`000`→`00` … `011`→`11`) y en las 7 de `Blue Team/` (`000`→`00` … `007`→`07`). **El hueco del `04` en Blue Team se conserva**: el salto `03 → 05` marca un sub-tema reservado, y cerrarlo habría cambiado la semántica de la numeración, no solo su formato.

**3 · El renombrado se ejecuta por la API de Obsidian** (`app.fileManager.renameFile`), no con `mv` ni `git mv`. Es lo que hace la app al renombrar desde el explorador: mantiene coherente el `metadataCache`, reescribe `workspace.json` y avisa a los plugins — `icon-folder` y `file-explorer-plus` actualizaron sus rutas solos. Lo que **no** actualiza son los literales de texto dentro de los filtros `.base` ni el código `dataviewjs`, que hubo que reescribir a mano: 31 líneas en 10 `.base` y 4 en `🏡 Home.md`.

**4 · Las ADR anteriores no se tocan.** Siguen citando las rutas con emoji y la numeración de tres dígitos porque documentan el estado del vault *en el momento de cada decisión*. Reescribirlas convertiría la ADR 014 en un sinsentido ("renumerar `00 - Fases del Pentesting` a la convención numérica…"). Esta ADR es el puntero que explica el desfase.

## Alternativas descartadas

- **Dejar los emoji y arreglar solo el tinglado de las herramientas** (alias de shell, comodines en los `cd`). Descartada: traslada el coste a cada script futuro y no arregla el problema de fondo — que hay herramientas que fallan en silencio con estos caracteres. El emoji no aportaba nada que no diera ya el icono del plugin.
- **Renombrar con `git mv` y luego recargar Obsidian.** Más simple de auditar en el diff, pero deja al `metadataCache` reconstruyéndose desde cero y a los plugins con sus rutas obsoletas — habría que arreglar a mano lo que la API resuelve sola. Descartada por eso.
- **Cerrar el hueco del `04` en Blue Team** y dejar `00`-`06` corrido. Descartada: el hueco es información — reserva un sitio en el orden lógico del área. Renumerar por estética habría desplazado `05`, `06` y `07`, tocando cuatro `.base`, el temario y el mapeo de `CLAUDE.md` para no ganar nada.
- **Mover `Red Team`/`Blue Team` a nombres sin espacio** (`Red-Team/`) para no tener que entrecomillar en shell. Descartada: rompería la simetría con `02 - Recursos/` y `Ingenieria/`, y el espacio no causa fallos silenciosos — solo obliga a comillas, que es un coste trivial y visible.

## Consecuencias

- **Ningún enlace roto por el cambio.** Los `[[wikilinks]]` del vault van por nombre de nota, no por ruta: 6.109 enlaces revisados, 0 rotos con ruta. Los 81 rotos que quedan son enlaces fantasma preexistentes (los TODO intencionales de la convención) y la única cadena `prev/next` rota es anterior al cambio.
- **Integridad probada por hash**, comparando cada fichero contra su blob en `HEAD`: de los 994 bajo las carpetas renombradas, 973 son byte-idénticos en su ruta nueva y los 21 restantes están todos justificados (17 editados a propósito, 2 borrados legacy previos, 2 con edición previa sin commitear). En la renumeración de Blue Team, 34 de 37 idénticos y los 3 restantes son los editados en el paso anterior.
- **Orden del explorador**: `Red Team` y `Blue Team` dejan de agruparse al final por el emoji y se ordenan alfabéticamente entre `04 - PENDIENTES` e `Ingenieria`.
- **El índice de Dataview queda obsoleto tras un renombrado masivo** y sigue devolviendo las rutas viejas en los objetos `Link`, lo que hace que la Home reporte cadenas rotas falsas. Hay que ejecutar `dataview:dataview-drop-cache` y esperar al reindexado. Gotcha nuevo, no documentado hasta ahora.
- **Toda la numeración de carpetas del vault queda en dos dígitos.** No quedan excepciones.
- **Deuda declarada, no abordada**: `file-explorer-plus` arrastra pins muertos a rutas de layouts antiguos (`03 - Recursos/`, `02 - Areas/`, `AI Pentesting.base` — el fichero es `AI Hacking.base`).
