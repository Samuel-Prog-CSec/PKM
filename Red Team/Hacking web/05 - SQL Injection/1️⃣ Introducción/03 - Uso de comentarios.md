---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "Equilibrar comillas manualmente para que la consulta inyectada quede válida es frágil"
Fecha de actualización: 2026-06-04
Nota previa: "[[02 - Subvertir la lógica de consulta]]"
Nota siguiente: "[[04 - La cláusula UNION]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Equilibrar comillas manualmente para que la consulta inyectada quede válida es frágil. La técnica que generaliza la explotación es **comentar** el resto de la consulta original: todo lo que venga después del payload se ignora, evitando errores de sintaxis sin importar qué columnas o condiciones quedaban por evaluar. Es la herramienta que convierte un [[02 - Subvertir la lógica de consulta|bypass]] tentativo en uno fiable.

# Comentarios en SQL

MySQL admite tres formas de comentario:

| Sintaxis | Tipo | Nota |
| -------- | ---- | ---- |
| `-- ` | Línea | **Requiere un espacio** tras los dos guiones. |
| `#` | Línea | En URL hay que codificarlo como `%23`. |
| `/* */` | En línea | Poco usado en SQLi básica; clave para [[05 - Bypass de caracteres comunes\|evasión de filtros]]. |

> [!warning]+
> Dos guiones **no bastan** para iniciar un comentario en MySQL: tiene que haber un espacio después (`-- `). Como los espacios finales son invisibles y se pierden con facilidad, la convención es escribir `-- -`: el guion final hace visible que hay un espacio. En una URL, ese espacio se codifica como `+` (`--+`) o se usa `-- -`. Y si el payload va en la barra del navegador, el `#` se interpreta como ancla de fragmento y **no llega al servidor**: hay que enviarlo como `%23`.

# Bypass de autenticación con comentarios

Volviendo al login vulnerable, inyectar `admin'-- -` como usuario produce:

```sql
SELECT * FROM logins WHERE username='admin'-- ' AND password='something';
```

La comilla cierra el literal del usuario y `-- -` comenta toda la comprobación de contraseña. La consulta efectiva queda en `WHERE username='admin'`, devuelve la fila del admin y la sesión se concede. <mark style="background: #ADCCFFA6;">Comentar es más robusto que el `OR` porque no depende de la estructura del resto de la query</mark>: la elimina.

# Manejar paréntesis

Las consultas reales a veces agrupan condiciones entre paréntesis, que tienen mayor precedencia:

```sql
SELECT * FROM logins WHERE (username='admin' AND id > 1) AND password='...';
```

Aquí dos defensas se combinan: el `id > 1` impide entrar como `admin` (cuyo `id` es 1) y la contraseña se **hashea** antes de la consulta. <mark style="background: #FFB8EBA6;">Hashear impide el bypass `OR` clásico por el campo de contraseña (el hash hexadecimal no rompe la sintaxis), pero no eliminaría una SQLi latente si ese hash se concatenara sin parametrizar</mark>. Inyectar `admin'-- -` falla con error de sintaxis: hay un paréntesis abierto que queda sin cerrar.

```sql
SELECT * FROM logins WHERE (username='admin'-- ' AND id > 1) AND password='...';
```

<mark style="background: #FF5582A6;">La solución es cerrar el paréntesis dentro del propio payload</mark>: `admin')-- -`.

```sql
SELECT * FROM logins WHERE (username='admin')-- ' AND id > 1) ...
```

La consulta efectiva se reduce a `WHERE (username='admin')` y devuelve la fila del admin, saltándose tanto la restricción de `id` como la del hash. <mark style="background: #8000E1A6;">Esto ilustra una regla general: hay que reconstruir mentalmente la query original y equilibrar su sintaxis</mark> —paréntesis, comillas— para que lo que queda antes del comentario sea válido.

> [!info]+
> **Comentarios por motor**, útil para el `fingerprinting` y la portabilidad de payloads:
> - **MySQL/MariaDB**: `-- ` (con espacio), `#`, `/* */`. El comentario `/*! ... */` es especial: ejecuta el contenido solo en MySQL (executable comment), técnica de evasión de WAF.
> - **MSSQL**: `--` (no exige espacio) y `/* */`.
> - **PostgreSQL**: `--` y `/* */`.
> - **Oracle**: `--` y `/* */`.

> [!warning]+
> El comentario en línea `/**/` tiene un segundo uso crítico para 2026: <mark style="background: #FFB86CA6;">sustituir espacios cuando un filtro o WAF los bloquea</mark> (`UNION/**/SELECT`), e incluso `/*!50000UNION*/` para evadir firmas que buscan la palabra `UNION` literal. Se desarrolla en la nota de [[05 - Bypass de caracteres comunes|bypass y evasión]].

Comentar y subvertir la lógica son manipulaciones de la consulta existente. El siguiente salto cualitativo es **inyectar consultas completas** para extraer datos de cualquier tabla, empezando por entender la [[04 - La cláusula UNION]].
