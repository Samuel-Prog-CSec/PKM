---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-22
Estado: Aceptada
---

## Contexto

Samuel tenía 19 PDFs de seguridad ya guardados en `02 - Recursos/Biblioteca/PDF/` sin catalogar, y quería construir una librería navegable en Obsidian a partir de ellos. El intento inicial fue el plugin `obsidian-book-search-plugin` (Google Books API), que devolvía **503 de forma persistente**. El diagnóstico inicial apuntaba a la key compartida hardcodeada del plugin (causa documentada y real), pero tras configurar una **API key propia** correctamente (campo `apiKey` correcto, formato válido, Books API habilitada), el 503 seguía. Se reprodujo el fallo directamente contra la API de Google con la key del usuario: `reason: "backendFailed"`, `"Service temporarily unavailable"` — es el **propio backend de Google Books** el que falla de forma intermitente, no la configuración del cliente. Sin ETA de arreglo posible desde nuestro lado.

## Decisión

Construir el catálogo con un **pipeline propio, sin depender de Google Books para nada crítico**:

- Metadatos (título, subtítulo, autores, editorial, año, ISBN) extraídos **directamente del propio PDF** (portada + página de copyright), no de una API externa.
- **Open Library** (gratis, sin key, sin el backend inestable de Google) como fuente de **contraste**, nunca de verdad única — cuando discrepa del propio PDF (pasa con metadata de catalogación anticipada: títulos de trabajo, años LCCN adelantados), gana el dato impreso en el libro.
- Portada: primero se intenta `covers.openlibrary.org` (verificando que sea una imagen real, no el placeholder de ~1x1px); si no hay portada real ahí (6 de 18 libros), se **extrae directamente de la página de portada del propio PDF** con `PyMuPDF`, recortando si es un *spread* envolvente tapa+lomo+contratapa (iterativo, verificado visualmente antes de guardar).
- Notas de catálogo en `Book-notes/`, **sin cadena Zettelkasten** (`Nota previa`/`Nota siguiente`) — se tratan como las notas de ADR: catálogo, no concepto. Sí llevan `Area` apuntando a `Librería.base`.
- Esquema de frontmatter fijo nuevo: `Autores`, `Editorial`, `Año`, `ISBN`, `Portada`, `PDF`, `Estado` (Pendiente/Leyendo/Leído), `Rating`.
- Procedimiento documentado como skill nueva (`pkm-library-workflow`) para que sea repetible al añadir un libro futuro, con puntero corto en `CLAUDE.md`.
- 7 tags temáticos nuevos creados por no existir ninguno apropiado (`Malware`, `Malware/macOS`, `Malware/Android`, `Evasion`, `Reverse-Engineering`, `IoT`, `Python`); el resto reutilizados.
- `Biblioteca.base` (apuntaba a la ruta rota `03 - Recursos/Biblioteca`, inexistente) eliminado; `Librería.base` es el único MOC, reapuntado (`image: Portada`) y con columnas ampliadas.
- Los 18 libros existentes se procesaron en 6 lotes de subagentes en paralelo (2-3 libros cada uno) para no consumir el contexto principal leyendo 19 PDFs uno a uno.

## Alternativas descartadas

- **Esperar a que Google arregle el backend** — descartado: el fallo es intermitente e impredecible, sin ETA; hubiera bloqueado la librería indefinidamente.
- **Migrar a un plugin alternativo con Open Library como fuente** (`Book Search + Covers`, `Global Book Search`, `Library`) — válido y más simple para libros futuros añadidos manualmente desde la UI de Obsidian, pero no resuelve retroactivamente los 19 PDFs ya en el vault sin trabajo manual equivalente, y añade una dependencia de plugin de terceros cuando ya se tiene un pipeline propio funcionando, auditable y sin caja negra. Queda como opción B si el catalogado manual se vuelve tedioso a mayor volumen.
- **Dejar los 19 libros sin catalogar** hasta resolver el plugin — descartado: no había fecha cierta, y el volumen ya estaba disponible para procesar con el pipeline propio.
- **Incluir estas notas en la cadena Zettelkasten** (`Nota previa`/`Nota siguiente`) como el resto del vault — descartado: un catálogo de libros independientes no tiene secuencia lógica real entre entradas; se optó por el mismo tratamiento que las ADR (exentas, con `Area`).

## Consecuencias

- Cero dependencia del plugin Book Search / Google Books API para el catálogo ya construido; las 18 notas tienen portada real (12 vía Open Library, 6 extraídas directamente del PDF).
- Nueva convención de "nota de catálogo" (sin Zettelkasten, con `Area`) queda establecida en el vault — reutilizable si aparece otro tipo de índice bibliográfico/referencial en el futuro (no solo libros).
- Procedimiento repetible documentado en `pkm-library-workflow`; añadir un libro nuevo no requiere re-derivar el pipeline ni el esquema de frontmatter.
- 7 tags nuevos a tener en cuenta (reutilizar, no duplicar) en futuras notas de malware, evasión, ingeniería inversa, IoT o Python.
- Si el volumen de la librería crece mucho y el catalogado asistido por Claude se vuelve tedioso, reconsiderar un plugin con Open Library nativo (ver alternativas descartadas) para altas puntuales desde la UI de Obsidian.
