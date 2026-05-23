---
name: zettelkasten-linking
description: Use when creating, deleting, renaming or reordering notes that are part of a Zettelkasten chain in this PKM. Triggers on phrases like "crear nota", "insertar nota entre X e Y", "borrar nota", "renombrar nota", "reordenar". Ensures the prev/next chain stays consistent — the easiest thing to forget.
---

# Mantenimiento de cadenas Zettelkasten en el PKM

El PKM usa los campos `Nota previa` y `Nota siguiente` del frontmatter para encadenar notas secuencialmente dentro de un tema. **Olvidar actualizar el vecino es el error más fácil y más común.**

## Modelo mental

Una cadena es una **lista enlazada doble**:

```
NULL ← [Nota A] ⇄ [Nota B] ⇄ [Nota C] → NULL
       prev=null  prev=A     prev=B
       next=B     next=C     next=null
```

Cada operación (crear / borrar / insertar / reordenar) debe mantener la invariante: si X.next = Y, entonces Y.prev = X. Cualquier ruptura genera una cadena "rota" silenciosamente (Obsidian no avisa).

## Operación 1: crear nota al final de la cadena

Sea `LastOld` la última nota actual (next vacío).

1. Crear `New` con `prev=LastOld`, `next=""`.
2. Editar `LastOld`: cambiar `Nota siguiente: ""` → `Nota siguiente: "[[New]]"`.
3. Si el tema tiene MOC `.base`, verificar que el filtro recoge a `New`.

**No olvidar el paso 2**. Es el error más común.

## Operación 2: insertar nota entre dos existentes

Sean `Before` y `After` dos notas consecutivas (Before.next = After, After.prev = Before). Queremos insertar `Mid` entre ellas.

1. Crear `Mid` con `prev=Before`, `next=After`.
2. Editar `Before`: `Nota siguiente: "[[After]]"` → `Nota siguiente: "[[Mid]]"`.
3. Editar `After`: `Nota previa: "[[Before]]"` → `Nota previa: "[[Mid]]"`.

3 archivos modificados, no 1.

## Operación 3: borrar nota

Sea `Doomed` la nota a borrar, con `prev=A` y `next=B`.

1. Editar `A`: `Nota siguiente: "[[Doomed]]"` → `Nota siguiente: "[[B]]"`. (Si `A` no existe, ignorar.)
2. Editar `B`: `Nota previa: "[[Doomed]]"` → `Nota previa: "[[A]]"`. (Si `B` no existe, ignorar.)
3. Buscar referencias entrantes a `Doomed` en el resto del vault (`Grep "[[Doomed" -r`). Cada referencia es:
   - Una mención temática → reescribir o redirigir a la nota más cercana.
   - Otro `Nota previa`/`Nota siguiente` del frontmatter → indica que `Doomed` estaba en MÁS de una cadena, alertar al usuario.
4. Borrar el archivo `Doomed`.

## Operación 4: renombrar nota

Renombrar el archivo NO actualiza las referencias automáticamente (a menos que el usuario tenga "Update links on file rename" en Obsidian, que sí suele tenerlo).

1. Renombrar archivo `OldName.md` → `NewName.md`.
2. Buscar y reemplazar en TODO el vault: `[[OldName` → `[[NewName`, incluyendo alias `[[OldName|...]]` → `[[NewName|...]]`.
3. Asegurarse de que el cuerpo de la propia nota no contiene referencias autorreferenciales con el nombre viejo.

Si Obsidian está abierto y el plugin `obsidian-linter` (instalado en este vault) actualiza enlaces, verificar manualmente igualmente.

## Operación 5: dividir una nota en dos

Tomar `Original` con `prev=A`, `next=B`, partir su contenido en `Part1` (primera mitad) y `Part2` (segunda mitad).

1. Crear `Part1` con contenido primer bloque, `prev=A`, `next=Part2`.
2. Crear `Part2` con contenido segundo bloque, `prev=Part1`, `next=B`.
3. Editar `A`: `next=Original` → `next=Part1`.
4. Editar `B`: `prev=Original` → `prev=Part2`.
5. Borrar `Original`.
6. Buscar referencias externas a `Original` (`Grep "[[Original"`) y redirigir según contexto.

## Operación 6: fusionar dos notas

Inverso de dividir. Tomar `First` y `Second` consecutivas → producir `Merged`.

1. Crear `Merged` con contenido combinado, `prev=First.prev`, `next=Second.next`.
2. Si `First.prev` existe: editar su `next` para apuntar a `Merged`.
3. Si `Second.next` existe: editar su `prev` para apuntar a `Merged`.
4. Borrar `First` y `Second`.
5. Redirigir referencias entrantes.

## Verificación de cadenas

**Opción A — CLI de Obsidian (rápido y nativo, requiere Obsidian abierto)**:

```shell-session
$ obsidian property:read file="<nota>" name="Nota previa"
$ obsidian property:read file="<nota>" name="Nota siguiente"
$ obsidian backlinks file="<nota>" format=json
```

Para una auditoría completa de una carpeta, iterar:

```shell-session
$ obsidian files | grep "XSS/" | while read f; do
    obsidian property:read path="$f" name="Nota previa"
    obsidian property:read path="$f" name="Nota siguiente"
  done
```

**Opción B — Filesystem directo (cuando Obsidian está cerrado)**:

```bash
cd "C:/Users/Samuel/Documents/PKM/🔴⚔️ Red Team/Hacking web/XSS"
for f in *.md; do
  prev=$(grep '^Nota previa:' "$f" | sed 's/Nota previa: //')
  next=$(grep '^Nota siguiente:' "$f" | sed 's/Nota siguiente: //')
  echo "$f | prev=$prev | next=$next"
done
```

O usar `Grep` con `output_mode: content` sobre `^Nota (previa|siguiente):` para inventariar.

Verificar:
- Una y solo una nota tiene `prev` vacío (la cabecera del tema).
- Una y solo una nota tiene `next` vacío (la cola).
- Para cada par (X, Y) donde `X.next = Y`, debe cumplirse `Y.prev = X`.

## Reglas no negociables

1. **Nunca crear una nota sin actualizar el vecino inmediato** que la precede en la cadena.
2. **Nunca borrar una nota sin recoser** la cadena.
3. **Renombrar = renombrar + reemplazar todas las referencias**. Si no se hace ambas cosas, el vault queda con enlaces rotos.
4. **Reportar al usuario los cambios colaterales**: "He modificado X y Y para mantener la cadena coherente después de crear Z."

## Anti-patrón

- ❌ Crear `Mid` entre `A` y `B`, dejar `A.next = B` (cadena salta a `Mid`).
- ❌ Renombrar archivo sin reemplazar referencias entrantes.
- ❌ Borrar nota y dejar `A.next = NotaBorrada` (rompe la cadena visual y de navegación).
- ❌ Crear cadena circular `A.next = B`, `B.next = A`.
