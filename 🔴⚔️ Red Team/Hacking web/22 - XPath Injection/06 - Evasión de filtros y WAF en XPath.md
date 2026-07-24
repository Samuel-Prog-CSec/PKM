---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[05 - XPath ciega y basada en tiempo]]"
Nota siguiente: "[[07 - Arsenal de herramientas XPath]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

Lo que separa al profesional es explotar **a pesar de los filtros**. En XPath hay dos capas que evadir: el **filtro de aplicación** (allowlist/blacklist de caracteres de control) y el **WAF**. La metodología es la misma que en la [[05 - Bypass de caracteres comunes|evasión de SQLi]]: identificar qué bloquea el filtro y sustituir cada elemento prohibido por un equivalente.

# Saltar el filtro de aplicación

El blacklist típico bloquea `' " / @ = * [ ] ( )` (ver [[08 - Prevención de XPath Injection|prevención]]). Sustituciones por elemento:

| Bloqueado | Técnica de bypass |
| - | - |
| `=` | `contains(a,b)`, `starts-with(a,b)`, `not(a != b)`, comparación `<` / `>` |
| `or` / `and` (keyword) | `\|` (unión) hace de `or`; predicados anidados `[..][..]` hacen de `and` |
| Espacios | XPath 2.0 admite comentarios `(: :)` como separador; el tokenizer no exige espacios alrededor de operadores/paréntesis |
| `1=1` / patrones obvios | `' or true() or '`, `' or /* or '` (el `/*` selecciona nodos → *truthy*) |

> [!warning]+ Comillas bloqueadas: el caso duro
> Si el filtro bloquea `'` **y** `"`, en **XPath 1.0** construir un literal de cadena es muy limitado: hay que <mark style="background: #FFB86CA6;">reutilizar valores de nodos existentes</mark> (`name(/*[1])`, atributos conocidos) o trabajar en contexto numérico. En **XPath 2.0+** existe `codepoints-to-string(104)` para fabricar caracteres **sin comillas** — un primitivo de evasión potente. Si solo se bloquea un tipo de comilla, usa el otro.

# Evasión de WAF

<mark style="background: #ADCCFFA6;">A diferencia de la SQLi, los WAF rara vez modelan sintaxis XPath</mark>, así que muchos `payloads` pasan intactos. Cuando sí hay una firma que bloquea (p. ej. `' or `):

- **Encoding en la capa HTTP**: URL-encoding y *double URL-encoding* (`%2527` → `%27` → `'`) del `payload` conocido.
- **Encoding por entidades XML**: <mark style="background: #8000E1A6;">si la entrada atraviesa un parser XML antes de la evaluación XPath</mark>, codificar caracteres como entidades (`&#x27;` = `'`, `&#x6f;r` = `or`) rompe el patrón que busca el WAF pero el parser XML lo decodifica antes de la consulta. Es la misma idea que el [bypass por XML encoding de PortSwigger](https://portswigger.net/web-security/sql-injection/lab-sql-injection-with-filter-bypass-via-xml-encoding).
- **Lógica alternativa**: reescribir el `payload` para evitar los tokens marcados (`' or '1'='1` → `'|//user['`, o vía `contains()`).

> [!important]+ Principio de evasión
> El blacklist es **finito**; el espacio de representaciones equivalentes es prácticamente **infinito**. Contra un WAF por firmas no ofusques el `payload` conocido — usa una sintaxis que su parser no contemple. Idéntico a la regla de 2026 en [[05 - Bypass de caracteres comunes|SQLi]].

# XPath 2.0/3.x amplía la superficie (y la evasión)

Detectar la versión del motor (el `detect` de [[07 - Arsenal de herramientas XPath|XCat]] lo hace) abre funciones que XPath 1.0 no tiene y que sirven tanto para explotar como para evadir:

- `doc()` / `document()` → peticiones *out-of-band* (SSRF, exfiltración).
- `unparsed-text()` → **lectura de ficheros** arbitrarios del servidor.
- `matches()` (regex) y `codepoints-to-string()` → construcción de cadenas y comparaciones sin los caracteres filtrados.

> [!info]+ Fuentes
> Técnicas de [OWASP — XPATH Injection](https://owasp.org/www-community/attacks/XPATH_Injection), [HackTricks — XPATH injection](https://book.hacktricks.wiki/en/pentesting-web/xpath-injection.html) y el trabajo de referencia sobre explotación avanzada [*"Hacking XPath 2.0"* (Tom Forbes & Sumit Siddharth, Black Hat EU 2012)](https://media.blackhat.com/bh-eu-12/Siddharth/bh-eu-12-Siddharth-Xpath-WP.pdf), que documenta el abuso de `doc()`, `unparsed-text()` y funciones XPath 2.0 para OOB y lectura de ficheros.
