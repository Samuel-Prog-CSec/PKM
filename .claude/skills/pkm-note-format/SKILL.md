---
name: pkm-note-format
description: Use when creating, editing or reviewing any note inside this PKM (Obsidian vault). Triggers on phrases like "crea una nota", "escribe la nota de X", "revisa el formato", "actualiza esta nota". Defines the exact frontmatter, color glossary, callouts, code blocks and image rules.
---

# Formato de nota del PKM

Aplicar **siempre** que se cree o modifique una nota `.md` dentro del vault `C:\Users\Samuel\Documents\PKM\`.

## Esqueleto obligatorio

```markdown
---
tags:
  - <tag-primario>
  - <tag-fase-pentesting>
Fecha de actualización: YYYY-MM-DD
Nota previa: "[[<nota anterior o vacío>]]"
Nota siguiente: "[[<nota siguiente o vacío>]]"
Area: "[[<MOC>.base|<MOC alias>]]"
---
---

<contenido>
```

Las dos líneas `---` consecutivas tras el frontmatter son intencionales:
- La primera cierra el YAML.
- La segunda es regla horizontal visible que separa metadatos de contenido.

### Campos del frontmatter

> Para escribir frontmatter desde la CLI oficial: `obsidian property:set file="X" name="Nota siguiente" value="[[Y]]"`. Para crear una nota nueva con frontmatter inicial, **preferir `Write` directo** — es más eficiente que múltiples `obsidian property:set`. Usar la CLI para retoques posteriores.

- **`tags`**: lista YAML. Reusar tags existentes antes de inventar nuevos — buscar con `Grep` pattern `^  - <candidato>$` sobre el vault o con `obsidian tags`. Tags más comunes en `Hacking web/`:
  - Categoría: `Web/Red-Team`, `Pentesting`, `Linux`.
  - Fase del pentest: `Pentesting/Enumeracion`, `Pentesting/Explotacion`, `Pentesting/Post-Explotacion`, `Pentesting/Reporting`.
  - Tema específico: `XSS`, `SQLi`, `Fuzzing`, `Introduccion`.
- **`Fecha de actualización`**: formato estricto `YYYY-MM-DD`. Hoy = obtener fecha del sistema.
- **`Nota previa`**: nombre EXACTO de la nota anterior en la cadena Zettelkasten, entre `"[[ ]]"`. Vacío sin comillas si es la primera del tema.
- **`Nota siguiente`**: ídem para la siguiente. Vacío si es la última.
- **`Area`**: enlace al `.base` **Level 2** del sub-tema (no al Level 1). Sintaxis con alias: `"[[XSS.base|XSS]]"`, `"[[SQL Injection.base|SQL Injection]]"`, `"[[Fuzzing.base|Fuzzing]]"`, etc. El Level 1 (`Web Pentesting.base` y similares) agrega Level 2, no notas. Si el `.base` Level 2 del sub-tema **no existe** todavía, crearlo **antes** que la nota. Las notas legacy con `Area` apuntando al Level 1 son deuda a migrar — al crear el Level 2 correspondiente, migrar en lote.

## Glosario de colores (marks)

Sintaxis: `<mark style="background: #HEXVALUE;">texto</mark>`

**Cada color tiene un único significado.** No usar al azar.

| Color | Hex | Cuándo usar | Ejemplo |
| - | - | - | - |
| Azul claro | `#ADCCFFA6` | Definir un concepto / "qué es X" | `<mark style="background: #ADCCFFA6;">FFUF es un fuzzer web escrito en Go</mark>` |
| Rosa claro | `#FFB8EBA6` | Matices, condiciones, detalles importantes pero secundarios | `<mark style="background: #FFB8EBA6;">se encuentran muy comúnmente</mark>` |
| Naranja | `#FFB86CA6` | Impacto, criticidad, lo que el atacante consigue | `<mark style="background: #FFB86CA6;">ejecuta el código JavaScript malicioso</mark>` |
| Morado | `#8000E1A6` | Reformulación o consecuencia destacable, "esto significa que…" | `<mark style="background: #8000E1A6;">puede afectar a cualquier usuario</mark>` |
| Coral-rojo | `#FF5582A6` | Hallazgo accionable / "esto importa para los próximos pasos" | `<mark style="background: #FF5582A6;">posible punto de entrada</mark>` |

**Reglas de densidad**:
- Nota de 1000–1500 palabras → 4–8 marks total.
- Más de 10 marks por nota → estás marcando ruido. Reducir.
- No marcar oraciones completas; marcar la frase/cláusula clave.

## Callouts (Obsidian)

Sintaxis `> [!tipo]+` (expandido) o `> [!tipo]-` (colapsado). Tipos usados:

```markdown
> [!important]+
> Aclaración crítica o nota lateral que el lector debe ver de inmediato.

> [!warning]+
> Gotcha, edge case, comportamiento sorpresivo (WAF rompe el payload, navegador moderno bloquea, etc).

> [!success]+
> Interpretación de salida exitosa de una herramienta o ataque.

> [!info]+
> Contexto adicional, RFC, CVE, historia, lectura complementaria.

> [!example]+
> Ejemplo extenso de payload, comando o flujo.
```

**Las palabras dentro de callouts NO cuentan** para la métrica 1000–1500 de teoría.

## Bloques de código

Lenguaje declarado siempre:

| Contenido | Tag |
| - | - |
| Comandos shell (con `$` o `#`) | `shell-session` |
| HTML | `html` |
| JavaScript | `javascript` o `js` |
| TypeScript | `typescript` o `ts` |
| SQL | `sql` |
| Petición/respuesta HTTP | `http` |
| Python | `python` |
| PHP | `php` |
| Go | `go` |
| Bash script (no interactivo) | `bash` |
| JSON | `json` |
| XML | `xml` |
| YAML | `yaml` |
| GraphQL | `graphql` |
| Salida sin formato | `text` o sin tag |

Ejemplo:
````markdown
```shell-session
$ ffuf -u http://target/FUZZ -w wordlist.txt
```
````

## Enlaces internos

- A otra nota: `[[Nombre exacto]]` o `[[Nombre|alias]]`.
- A una nota que aún no existe: crear el wikilink igualmente — Obsidian lo mostrará como nota fantasma y servirá de TODO.
- A una sección de otra nota: `[[Nombre#Sección]]`.

## Imágenes

- HTB Academy: por URL pública.
  ```markdown
  ![Descripción accesible breve](https://academy.hackthebox.com/storage/modules/<id>/<file>.jpg)
  ```
- Propias / del lab personal: ruta relativa.
  ```markdown
  ![Captura del payload ejecutándose](04 - Archivos/Images/<contexto>/captura.png)
  ```
- **Criterio**: incluir solo si aporta valor (diagramas, screenshots de UI relevante, matrices). Una captura de terminal trivial → bloque de código, no imagen.

## Tablas

Para comparativas. Cabeceras cortas, ≤8 filas idealmente.

```markdown
| Tipo               | Descripción                  | Persistencia |
| ------------------ | ---------------------------- | ------------ |
| [[XSS Reflejado]]  | Refleja la entrada del user  | No           |
| [[XSS Almacenado]] | Persiste en backend          | Sí           |
```

## Subcarpeta `Nuevo-Formato` (excepción)

Si la nota va dentro de `🔴⚔️ Red Team/Hacking web/💉🩸 SQL Injection/Nuevo-Formato/`, **NO usar marks con color**. Usar:
- `==highlight==` (resaltado único de Obsidian) para destacar.
- `**bold**` / `***bold italic***` para énfasis.
- El resto de convenciones (frontmatter, callouts, bloques de código, enlaces) iguales.

Esta carpeta es un experimento del usuario con formato más limpio. No mezclar estilos.

## Voz y estilo

- Frases cortas, directas. Voz activa siempre que sea posible.
- Voz profesional, no académica: hablar al pentester operativo, no al estudiante motivado.
- Evitar:
  - "Como veremos a continuación…"
  - "Es importante destacar que…"
  - "En conclusión…"
  - "Ahora que ya hemos visto X, pasaremos a Y…"
- Preferir ejemplos concretos a explicaciones abstractas.

## Comprobación final (auto-check antes de marcar tarea completa)

- [ ] Frontmatter completo, fecha `YYYY-MM-DD`, `Area` apunta a un `.base` real.
- [ ] 1000–1500 palabras de teoría (excluyendo callouts/código/enlaces/sintaxis).
- [ ] 4–8 marks con colores correctamente asignados.
- [ ] Bloques de código con lenguaje.
- [ ] Imágenes solo si aportan valor.
- [ ] Enlaces `[[ ]]` apuntan a notas reales (o son fantasmas intencionales).
- [ ] Tags reutilizados, no inventados sin razón.
- [ ] Nota encadenada con `prev`/`next` correctamente (ver `zettelkasten-linking` skill).
