---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "Con el código decompilado, buscar las consultas vulnerables a mano entre miles de líneas es inviable"
Fecha de actualización: 2026-06-04
Nota previa: "[[01 - Decompilación de archivos Java]]"
Nota siguiente: "[[03 - Live-debugging de aplicaciones Java]]"
Area: "[[SQLi Avanzado.base|SQLi Avanzado]]"
---
---

Con el [[01 - Decompilación de archivos Java|código decompilado]], buscar las consultas vulnerables a mano entre miles de líneas es inviable. <mark style="background: #ADCCFFA6;">Las consultas SQL son cadenas, así que se localizan con expresiones regulares</mark>. La clave es distinguir las consultas **parametrizadas** (seguras) de las que **concatenan** entrada del usuario (vulnerables).

# Patrones RegEx útiles

| Patrón | Qué busca |
| ------ | --------- |
| `SELECT\|UPDATE\|DELETE\|INSERT\|CREATE\|ALTER\|DROP` | Comandos SQL básicos (la inyección no es solo en `SELECT`) |
| `(WHERE\|VALUES).*?'` | Una comilla simple tras `WHERE`/`VALUES`: posible concatenación |
| `(WHERE\|VALUES).*" \+` | Comilla doble y un `+`: concatenación de strings en Java |
| `.*sql.*"` | Líneas con `sql` y comilla doble |
| `jdbcTemplate` | Uso de `JdbcTemplate` (una de las APIs SQL de Java; otras: JPA, Hibernate) |

> [!important]+
> <mark style="background: #8000E1A6;">Adapta los patrones al estilo del código</mark>. Al revisar `BlueBird` se observa que el desarrollador siempre guarda las consultas en una variable llamada `sql`, así que buscar `sql =` es muy efectivo. Identificar las librerías (aquí `JdbcTemplate`) y las convenciones del autor enfoca la búsqueda.

# `grep` y VS Code

```shell-session
$ grep -irnE 'SELECT|UPDATE|DELETE|INSERT|CREATE|ALTER|DROP' --include=*.java .
```

Las flags: `-i` (ignora mayúsculas), `-r` (recursivo), `-n` (números de línea), `-E` (regex extendida), `--include=*.java`. VS Code ofrece lo mismo gráficamente con la búsqueda en modo RegEx.

# La señal: `?` vs `+`

En `JdbcTemplate`, el patrón seguro usa **placeholders** `?` y pasa los valores aparte:

```java
String sql = "SELECT * FROM users WHERE id = ?";
jdbcTemplate.queryForObject(sql, new Object[]{id}, ...);   // SEGURO
```

El patrón vulnerable **concatena** con `+`:

```java
String sql = "SELECT * FROM users WHERE email = '" + email + "'";   // VULNERABLE
```

<mark style="background: #FF5582A6;">Buscar el `'" +` (cierre de string + concatenación) localiza directamente las inyecciones</mark>.

# Las tres SQLi de BlueBird

La búsqueda revela tres puntos que se explotarán en las notas siguientes:

- **`/find-user`** (`IndexController`): `... WHERE username LIKE ?` — parametrizada, **pero** el parámetro `u` pasa por un filtro RegEx que bloquea espacios y ciertos caracteres. Es una SQLi explotable solo si se [[05 - Bypass de caracteres comunes|burla el filtro]].
- **`/forgot`** (`AuthController`): `... WHERE email = '" + email + "'` — concatenación directa. Además, si la IP del cliente es `127.0.1.1`, devuelve el *stacktrace* completo del error → candidato a [[06 - SQL Injection basada en errores|error-based]].
- **`/profile`** (`ProfileController`): `... WHERE email = '" + user.getEmail() + "'` — concatena un valor que **no viene directo del usuario**, sino de otra consulta. Si logramos controlar ese `email` almacenado, es una [[07 - SQL Injection de segundo orden|inyección de segundo orden]].

> [!info]+
> En 2026, el análisis estático manual con `grep` se complementa con **SAST automatizado**: <mark style="background: #FFB8EBA6;">`semgrep` y `CodeQL` detectan concatenación de SQL con reglas dedicadas</mark> (`java.lang.security.audit.sqli`), siguiendo el flujo de datos de la entrada del usuario hasta la query (taint analysis). En una base de código grande, lanzar semgrep primero y revisar los hallazgos a mano es mucho más eficiente que grep a ciegas. `grep` sigue siendo insustituible para patrones específicos del estilo del autor. Esta caza manual de consultas vulnerables es la versión artesanal de la [[02 - Code review - alcance, priorización y lectura|revisión de código]] de un whitebox pentest; [[00 - Qué es Semgrep y para qué sirve|Semgrep]] y el [[02 - Taint tracking y consultas de flujo de datos|taint tracking de CodeQL]] la automatizan siguiendo el flujo `source`→`sink`.

Localizadas las consultas sospechosas estáticamente, confirmar cómo se comportan en ejecución se hace con dos técnicas complementarias: el [[03 - Live-debugging de aplicaciones Java|live-debugging]] y la [[04 - Búsqueda de errores SQL en los logs|inspección de logs SQL]].
