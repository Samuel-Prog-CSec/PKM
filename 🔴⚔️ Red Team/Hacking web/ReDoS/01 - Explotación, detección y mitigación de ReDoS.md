---
tags:
  - Web/Red-Team
  - ReDoS
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[00 - Introducción a ReDoS]]"
Nota siguiente: ""
Area: "[[ReDoS.base|ReDoS]]"
---
---

# Dónde vive una regex explotable

El primer paso es localizar una **regex del lado servidor que toque entrada del usuario**. Candidatos habituales:

- **Validadores**: email, URL, teléfono, `User-Agent`, `Content-Type`, hostname.
- **Reglas de WAF** y filtros de seguridad (irónicamente, el caso Cloudflare).
- **Parsers de logs**, sanitizadores de Markdown/BBCode, y *parsers* de fechas/duraciones.

Las APIs son terreno fértil ([[00 - Introducción a las API Attacks|API Attacks]]): validan formatos constantemente y muchas exponen la propia regex en los mensajes de error, como en el lab de `check-email`.

# El oráculo de tiempo de respuesta

ReDoS se detecta a ciegas por **latencia**: se envían inputs "casi válidos" cada vez más largos y se mide. <mark style="background: #FF5582A6;">Si el tiempo crece de forma **super-lineal** con la longitud, la regex es vulnerable</mark>. La receta del payload es siempre la misma:

> [!important]+ Receta del payload
> **Una tirada larga del carácter que el cuantificador consume + un carácter final que rompe el ancla/cola.** Contra `^(a+)+$`, el payload es `"a"*40 + "!"`: el motor casa las 40 `a` de mil maneras y, al chocar con `!` que no casa `$`, rebobina exhaustivamente ([PayloadsAllTheThings](https://swisskyrepo.github.io/PayloadsAllTheThings/Regular%20Expression/)).

El impacto se amplifica por la arquitectura: <mark style="background: #FFB86CA6;">en runtimes de un solo hilo (el *event loop* de Node.js, handlers atados al GIL de Python) una sola petición atasca al worker entero</mark>; un puñado de peticiones concurrentes = DoS total ([Snyk](https://learn.snyk.io/lesson/redos/)).

# Arsenal de detección

En white-box o auditando tu propio código, no adivines — analiza:

| Herramienta | Cómo funciona |
| - | - |
| [`regexploit`](https://github.com/doyensec/regexploit) (Doyensec) | Análisis estático de ambigüedad; genera la cadena de ataque y puntúa la complejidad (⭐⭐⭐ = cúbica). Extrae regex de Python/JS/TS/C#/JSON/YAML |
| `redos-detector` | Prueba **con certeza** si un patrón es seguro (Node/Deno/browser) |
| `recheck` | Híbrido estático+dinámico; de los mejores resultados, API JS/TS/Scala |
| `safe-regex` | Heurística barata (star-height); ruidosa, solo como *lint gate* |
| `rxxr2` | Analizador académico; sin *lookarounds*/*backreferences* |

En CI/CD: **Semgrep** trae un analizador de ReDoS por anti-patrones (+ la regla `DUO138` de Dlint para `re` de Python), y **CodeQL** hace consultas semánticas de *data-flow* "polynomial/exponential ReDoS", más profundas pero lentas ([Doyensec: Semgrep vs CodeQL](https://blog.doyensec.com/2022/10/06/semgrep-codeql.html)).

# Mitigación (por orden de eficacia)

1. <mark style="background: #ADCCFFA6;">**Motor de tiempo lineal (lo mejor): RE2**</mark> — autómata sin backtracking ni backreferences, inmune por construcción. `re2js`, `Go regexp`, `Rust regex`. Fue la solución de Cloudflare ([regular-expressions.info](https://www.regular-expressions.info/redos.html)).
2. **Límite de longitud** del input **antes** de la regex.
3. **Timeouts de regex**: `matchTimeout` en .NET, `Regexp.timeout` en Ruby 3.2+, la JEP en camino para Java.
4. **Grupos atómicos `(?>...)` / cuantificadores posesivos `a++`, `a*+`** — fijan lo casado y prohíben rebobinar (PCRE, Java, Ruby, y **Python 3.11+**).
5. **Reescribir el patrón** para eliminar ambigüedad: anclar, hacer el *trim* de espacios por separado, evitar cuantificadores anidados/solapados.
6. <mark style="background: #8000E1A6;">**Nunca aceptar regex suministrada por el usuario**</mark>.

> [!success]+ RE2 en números
> RE2JS ejecutó una regex asesina **30.000 veces en ~454 ms**, mientras `RegExp` nativo colgaba >1m45s en **una sola** evaluación ([re2js](https://github.com/le0pard/re2js)). Cuando veas código que compila regex sobre input no confiable en un motor con backtracking, esa migración es el hallazgo.
