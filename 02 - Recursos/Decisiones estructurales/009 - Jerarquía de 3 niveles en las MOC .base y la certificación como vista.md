---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-29
Estado: Aceptada
---
---

## Contexto

Las 124 MOC `.base` del vault eran plantillas clonadas: 114 Level 2 que solo se diferenciaban en una cadena de texto, todas mostrando lo mismo (nombre + tags), sin `groupBy`, sin fórmulas y sin ninguna vista transversal. La `Fecha de actualización` que se escribe en las 998 notas no se mostraba en ningún sitio.

Con Red Team en 678 notas el modelo se rompía por tres sitios: `Web Pentesting.base` listaba **34 sub-temas planos** mezclando CWES, CWEE y net-new; `02 - Recursos/🛠️ Tools/` tenía 19 herramientas y **ningún índice**; y Blue Team, Redes e Ingeniería tampoco tenían nivel raíz. Además los 8 Level 1 se **autolistaban** por un bug silencioso (`file.name != "X"` no excluye nada porque para un `.base` el `file.name` incluye la extensión) y `Red-Team.base` dependía de una lista de carpetas escrita a mano que ya había fallado una vez (ADR 008).

## Decisión

**1 · Tres niveles explícitos.** Se formaliza el Level 0 (panel de área raíz: `Red-Team`, `Blue-Team`, `Redes`, `Ingenieria`, `Tools`), que indexa Level 1 por **regex de profundidad exacta** — un área nueva aparece sola, sin editar el filtro. Level 1 indexa Level 2; solo Level 2 recibe el `Area` de las notas.

**2 · La certificación es un eje de vista, no de almacenamiento.** CWES/CWEE/CPTS/COAE se calculan con una fórmula sobre la carpeta y se explotan con `groupBy`. **Cero notas tocadas.**

**3 · Los índices muestran la fecha.** Level 2 pasa a tres columnas fijas (nombre, tags, `Fecha de actualización`) y el Level 0 añade vistas de mantenimiento (`Sin tocar (>180 días)`, `Tocadas en 30 días`) y transversales (`Detección y evasión`, `Arsenal`), que resuelven por nombre de fichero sin metadato nuevo.

**4 · Escalado por familia, no por carpeta.** Al superar ~15 sub-temas se añade una vista agrupada por una fórmula de familia. `Web Pentesting.base` agrupa sus 39 sub-temas en 9 familias sin mover un solo directorio, respetando la ADR 004 (numeración = orden de estudio).

## Alternativas descartadas

- **Propiedad `Certificación` en el frontmatter de ~700 notas.** Máxima flexibilidad, pero los módulos web son compartidos (una nota de XSS es CWES *y* CPTS *y* CWEE), así que exigiría multivalor y mantenimiento perpetuo — para un metadato que responde "de dónde salió esto", útil al estudiar e irrelevante consultando en un engagement. Contradice el principio fundacional del vault: integrar por tema, no por módulo HTB.
- **Tag `Cert/CWES`.** Más barato, pero infla una taxonomía que ya tiene dos tags saturados (`Web/Red-Team` en 430 notas, `Pentesting/Explotacion` en 392) y mezcla procedencia con contenido.
- **Carpetas intermedias por familia** en `Hacking web` (`Inyección/`, `Cliente/`…). Ordena el árbol de verdad, pero la ADR 004 ya descartó agrupar por familia para preservar el itinerario de estudio, y obligaría a renumerar 34 carpetas.
- **Partir `Hacking web` en dos Level 1** (núcleo / avanzado). La frontera es difusa (Modern Exploitation vs Web Attacks) y añade un nivel sin resolver la clasificación.
- **Propiedad `Descripción` de una línea por nota.** Es el salto de calidad real de los índices —hoy el nombre es lo único que distingue una nota de otra—, pero son ~1.000 notas. Aplazado, no descartado.
- **Un Level 2 por aplicación en `Common Applications`** (13 índices para 36 notas, 8 de ellos con 1-2 filas) y ascender su `.base` a Level 1. Descartado: metía un cuarto nivel dentro de Hacking web. Se resolvió con `groupBy: file.folder` en el índice existente, 0 notas tocadas.
- **`.base` para `Firewalk` y `Scapy`.** Descartado: son stubs (0 y 0,1 KB). Un índice sobre una carpeta vacía es ruido.

## Consecuencias

- **134 `.base`** (13 Level 0/1 + 121 Level 2). Auditoría de integridad: **0 filtros mal apuntados, 0 `Area` rotos**, 983 notas indexadas.
- `SQL Injection` se parte en tres Level 2 hermanos (`SQL Injection` 10 · `SQLi Blind` 15 · `SQLi Avanzado` 12); 27 notas cambian de `Area`. Sienta el patrón: **un sub-tema que crece se parte en hermanos, nunca en un Level 1 intermedio**.
- `Tools.base` nace con 17 herramientas en 7 categorías. Se crean 4 Level 2 que faltaban (Burp Suite, ZAP, Wireshark, Tcpdump) y se reparan 5 `Area` legacy que apuntaban a **notas** en vez de a `.base`.
- Blue Team pasa a numeración contigua `000`–`006` (`(2) Análisis de red`, `IDS & IPS` y `🛡️🖥️🗂️ Asegurar Windows` renombradas); `Redes/Protocolos` pierde los emojis-número (`FTP (21)`, `SMB (445)`). Renombrar carpetas no rompe wikilinks ni `Area`.
- Los Level 0 de Blue Team, Redes e Ingeniería incluyen una vista **`Deuda · sin frontmatter`**: la deuda legacy queda visible en la propia MOC en vez de en un informe que se pierde.
- `CLAUDE.md` incorpora las plantillas de los 3 niveles y **8 gotchas verificados** contra Obsidian real (extensión en `file.name`, `base:query` ciego a `.base`, necesidad de `app:reload`, sintaxis `note[...]`…). `pkm-structure-audit` y `pkm-note-format` se actualizan en consecuencia.
- **Taxonomía de tags: casi-duplicados consolidados** (30 notas). Regla que queda sentada: **kebab-case con mayúsculas iniciales** (`Bases-de-Datos`, no `Bases de Datos` — un tag con espacios no funciona como `#tag` inline) y **gana siempre la variante jerárquica** (`Pentesting/Enumeracion` sobre `Enumeracion`, `Escaneo/Redes` sobre `Escaneo`, `Análisis/Datos` sobre `Análisis`). Donde una nota llevaba padre e hijo redundantes (`Reporting` + `Pentesting/Reporting`) se elimina el suelto. **Excepción deliberada**: `Server-Side` a secas se mantiene en `00 - Introducción a los ataques server-side`, que es la nota paraguas de la familia.
- **Los 2 tags saturados siguen pendientes**: `Web/Red-Team` (430 notas) y `Pentesting/Explotacion` (392) no discriminan nada. Arreglarlo no es una consolidación mecánica sino rediseñar la taxonomía sobre ~800 notas — requiere su propio `pkm-design-grilling` y su propio ADR.

## Ejecución de la deuda detectada (segunda ronda, mismo día)

- **Blue Team**: 3 Level 2 nuevos (`Manejo de incidentes`, `Análisis de red`, `Manejo de logs`) y frontmatter completo —tags, fecha real del fichero y cadena Zettelkasten— en sus 9 notas legacy. Tags nuevos mínimos: `Incident-Response` y `Logs`.
- **Redes**: frontmatter en TFTP, vsFTPd y Ajustes peligrosos; `Area` añadida a HTTP y HTTPS. Se respeta el patrón del sub-tema: las fichas de protocolo **no llevan cadena Zettelkasten** (son referencia, no secuencia).
- **Colisión `Protocolos de red`**: la nota homónima del `.base` estaba **vacía (0 KB) con 5 enlaces entrantes**. Se sustituye por `Introducción a los protocolos de red.md` con contenido real de nota-entrada (modelo de capas, patrón histórico de protocolos sin cifrar, tabla de los 17 protocolos documentados) y se recosen los enlaces. El campo `Area` de 14 notas —que usa `[[Protocolos de red.base|…]]`— queda intacto por construcción del reemplazo.
- Burp Suite y ZAP reciben tags (`Web/Red-Team`, `Proxies`, `Herramientas`); se borran dos carpetas vacías.
- **Deuda que se deja a propósito**: los 6 Level 2 de `Evasión de defensas` (área en construcción, no son prematuros sino trabajo en curso), 4 stubs de 0 KB (`IDS-IPS`, `Capas de red 1-4` y `5-7`, `Scapy`) y las notas de asignaturas de `Ingenieria/`.
