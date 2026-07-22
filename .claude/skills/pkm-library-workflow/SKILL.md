---
name: pkm-library-workflow
description: Use when adding a new book PDF to the Biblioteca personal library in this PKM, or when asked how the library catalog works. Triggers on phrases like "añade este libro a la biblioteca", "cataloga este PDF", "nuevo libro en la librería", "cómo funciona la biblioteca".
---

# Biblioteca personal — catálogo de libros en PDF

`02 - Recursos/Biblioteca/` cataloga los libros de seguridad que Samuel ya tiene en PDF. Es un **catálogo bibliográfico**, no notas de concepto — trátalo con reglas distintas al resto del vault (ver "Por qué estas notas son diferentes" más abajo).

## Por qué no usamos el plugin Book Search

El plugin `obsidian-book-search-plugin` (Google Books API) fallaba con 503 de forma persistente, incluso con API key propia correctamente configurada. Diagnóstico confirmado contra la API real: `reason: "backendFailed"` — es el propio backend de Google Books el que está caído de forma intermitente, no un problema de configuración del lado del usuario. Detalle completo → ADR `005 - Catálogo de la Biblioteca personal`.

Por eso el catálogo se construye con un pipeline propio que no depende de esa API para nada crítico.

## Estructura

- PDFs: `02 - Recursos/Biblioteca/PDF/<archivo>.pdf` (ya existen, no se tocan).
- Notas de catálogo: `02 - Recursos/Biblioteca/Book-notes/<Título>.md` (una por libro).
- Portadas propias (cuando Open Library no tiene una real): `03 - Archivos/Images/Biblioteca/<Título>.jpg`.
- MOC: `02 - Recursos/Biblioteca/Librería.base` (filtra por `file.folder == "02 - Recursos/Biblioteca/Book-notes"`, no requiere tocarlo al añadir un libro nuevo salvo que cambies el esquema de frontmatter).

## Procedimiento para un PDF nuevo

1. **Extraer metadatos del propio PDF.** `Read` con `pages="1-10"` (portada + página de copyright suelen estar ahí; si no aparece el ISBN, probar `"10-20"`). Saca: título exacto, subtítulo, autor(es), editorial, año, ISBN-13 tal cual aparece impreso.

2. **Verificar contra Open Library** (gratis, sin key, sin el backend inestable de Google):
   ```
   GET https://openlibrary.org/isbn/<ISBN-SIN-GUIONES>.json
   ```
   Si el PDF no trae ISBN claro, fallback a búsqueda por título+autor:
   ```
   GET https://openlibrary.org/search.json?q=<titulo>+<autor>
   ```
   **Prioridad de la verdad**: si Open Library discrepa del propio PDF (pasa con metadata de catalogación anticipada / pre-lanzamiento — título de trabajo distinto, año LCCN adelantado), **gana el dato impreso en el PDF**. Open Library es solo contraste, no fuente única. Nunca inventar un ISBN — mejor dejarlo vacío.

3. **Conseguir la portada**, en este orden:
   - `https://covers.openlibrary.org/b/isbn/<ISBN-SIN-GUIONES>-L.jpg` — verificar que es una imagen real y no el placeholder de ~1x1px/43 bytes (comprobar tamaño en bytes, no solo el status 200).
   - Si no hay portada real en Open Library: **extraerla directamente del PDF** con `PyMuPDF` (`fitz`, ya instalado). Renderiza la página de portada (normalmente página 1) a alta resolución y recorta si es un *spread* envolvente (tapa+lomo+contratapa en una sola página, común en covers de No Starch Press):

     ```python
     import io, fitz
     from PIL import Image

     def extract(pdf_path, page_index, out_path, left_frac=0.0, right_frac=1.0, zoom=3.0):
         doc = fitz.open(pdf_path)
         pix = doc[page_index].get_pixmap(matrix=fitz.Matrix(zoom, zoom))
         im = Image.open(io.BytesIO(pix.tobytes("png")))
         if left_frac != 0.0 or right_frac != 1.0:
             w, h = im.size
             im = im.crop((int(w * left_frac), 0, int(w * right_frac), h))
         im.convert("RGB").save(out_path, "JPEG", quality=92)
     ```

     El punto de corte del *spread* no es fijo — varía por libro. Itera: renderiza sin recorte primero, mira el resultado con `Read` sobre el JPG generado, ajusta `left_frac` hasta que el título completo, el arte y el nombre del autor entren sin colar texto de la contraportada. 2-3 iteraciones es normal.
   - Si ninguna de las dos da portada real, deja `Portada: ""` vacío — nunca un enlace roto ni un placeholder.

4. **Tags**: reutiliza antes de inventar. Corre `obsidian tags` o `Grep` sobre `^  - <candidato>$` para ver qué existe ya. Solo crea un tag nuevo si genuinamente no hay uno apropiado, con el mismo estilo `Kebab-Case-Con-Mayúsculas` del resto del vault (así se crearon `Malware`, `Malware/macOS`, `Malware/Android`, `Evasion`, `Reverse-Engineering`, `IoT`, `Python` — reutilízalos si el libro nuevo encaja en alguno).

## Frontmatter exacto (nota de catálogo)

```yaml
---
tags:
  - Biblioteca
  - <tag temático>
Fecha de actualización: YYYY-MM-DD
Autores:
  - <Autor 1>
Editorial: <Editorial>
Año: <año numérico>
ISBN: "<ISBN con guiones, o vacío si no se encontró>"
Portada: "<URL de covers.openlibrary.org, o ruta local 03 - Archivos/Images/Biblioteca/<Título>.jpg, o vacío>"
PDF: "[[<nombre_exacto_del_archivo>.pdf]]"
Estado: Pendiente
Rating:
Area: "[[Librería.base|Librería]]"
---
---
```

## Por qué estas notas son diferentes (excepciones al resto del vault)

- **Sin `Nota previa` / `Nota siguiente`**: un catálogo no tiene secuencia lógica entre libros. Se tratan como las notas de ADR — exentas de la cadena Zettelkasten, pero sí con `Area` apuntando al `.base` del sub-tema (`Librería.base`).
- **Sin las 1000-1500 palabras de teoría ni el glosario de colores** de `pkm-note-format` — son fichas bibliográficas, no notas de concepto. Sinopsis corta (2-4 párrafos, parafraseada y mejorada a partir de la contraportada, nunca copiada literal) + lista de temas + enlace al PDF + sección `## Notas propias` vacía para anotaciones futuras del usuario.

## Cuerpo de la nota (plantilla)

```markdown
# <Título>

![Portada de <Título>](<URL o ruta de Portada, omite esta línea entera si no hay portada>)

**<Subtítulo>** — <dato relevante si aplica: prólogo, edición, etc. Omite si no aplica>.

## Sinopsis

<2-4 párrafos en español, parafraseados y mejorados desde la contraportada/introducción del propio PDF. Términos técnicos consolidados en `backticks`.>

## Qué cubre el libro

- <5-8 bullets con temas/técnicas concretas>

## Enlace

[[<archivo>.pdf|Abrir PDF]]

## Notas propias

```

## Varios PDFs a la vez

Si llegan varios libros de golpe, repartir en agentes en paralelo (2-3 libros por agente) en vez de procesarlos uno a uno en el hilo principal — cada libro es independiente (lectura de PDF + verificación Open Library + escritura de nota), ideal para paralelizar. Dar a cada agente el mismo esquema de frontmatter, la lista de tags existentes y la nota piloto como referencia de tono.
