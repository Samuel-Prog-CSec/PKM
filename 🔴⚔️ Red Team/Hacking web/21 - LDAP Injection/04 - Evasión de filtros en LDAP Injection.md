---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[03 - Exfiltración de datos y explotación ciega]]"
Nota siguiente: "[[05 - Arsenal de herramientas LDAP]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

Como en el resto de inyecciones, lo que marca la diferencia es explotar **a pesar de los filtros**. En LDAP hay dos capas: el **filtro de aplicación** (que suele bloquear el comodín o escapar caracteres) y el **WAF**. La metodología es la de siempre: identificar qué se bloquea y sustituirlo.

# Saltar el filtro de aplicación

| Bloqueado | Técnica de bypass |
| - | - |
| Comodín `*` | Inyección de estructura de filtro `)(\|(&` (el [[02 - Bypass de autenticación con LDAP|bypass sin comodín]]); operadores de rango `>=` / `<=` para inferir valores sin `*` |
| `&` / `\|` | Usar el otro operador de combinación, o anidar (`(!(...))`) |
| `=` | Aproximado `~=`, o rangos `>=` / `<=` |
| `(` / `)` | Son el núcleo de la sintaxis: si el filtro solo escapa parcialmente, buscar el campo no saneado; si escapa todo, la inyección se cierra |

> [!important]+ Extracción ciega sin comodín: operadores de rango
> Si el `*` está filtrado no puedes hacer `password=a*`, pero <mark style="background: #8000E1A6;">los operadores `>=` y `<=` permiten una búsqueda binaria sobre el valor</mark>: `(password>=m)` divide el espacio en dos, y afinas hasta el carácter exacto. Es el equivalente LDAP de la [[05 - XPath ciega y basada en tiempo|búsqueda binaria en blind XPath]], y esquiva por completo el comodín.

# Evasión de WAF

<mark style="background: #ADCCFFA6;">Como XPath, los WAF rara vez modelan sintaxis LDAP</mark>, así que la mayoría de `payloads` pasan sin bloqueo. Cuando sí hay una firma:

- **Encoding en la capa HTTP**: URL-encoding y *double URL-encoding* del `payload` (`%28` = `(`, `%2a` = `*`).
- **Escape hex de LDAP** (con un matiz que se malinterpreta a menudo): los valores admiten `\XX` (`\2a` = `*`), pero por [RFC 4515 §3](https://www.rfc-editor.org/rfc/rfc4515) el escape representa el **byte literal como dato**, no preserva la función de metacarácter. <mark style="background: #FF5582A6;">`(uid=\2a)` se evalúa como igualdad exacta contra la cadena `"*"`, no como comodín</mark> — no casa ningún usuario real. Por eso solo evade un filtro si hay una **decodificación intermedia no estándar** (la app decodifica `\XX` *antes* de construir el filtro); si quien lo procesa es el parser LDAP, la técnica no cuela un wildcard ni rompe la estructura.
- **Lógica alternativa**: reescribir para evitar el token marcado (comodín → rangos, `|` → `!` anidado).

> [!important]+ Principio de evasión
> El blacklist es finito; las representaciones equivalentes, prácticamente infinitas. No ofusques el `payload` conocido — usa una construcción que el WAF no contemple (rangos en vez de comodín, escape hex, estructura de filtro). Misma regla que en [[06 - Evasión de filtros y WAF en XPath|XPath]] y [[05 - Bypass de caracteres comunes|SQLi]].

> [!info]+ Fuentes
> Técnicas de [HackTricks — LDAP Injection](https://book.hacktricks.wiki/en/pentesting-web/ldap-injection.html) y [PayloadsAllTheThings — LDAP Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/LDAP%20Injection/); el trabajo de referencia sobre explotación ciega es [*"LDAP Injection & Blind LDAP Injection in Web Applications"* (Alonso & Parada, Black Hat Europe 2008)](https://www.blackhat.com/presentations/bh-europe-08/Alonso-Parada/Whitepaper/bh-eu-08-alonso-parada-WP.pdf), que formalizó la extracción con `>=`/`<=` y comodines.
