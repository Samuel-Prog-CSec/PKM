---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Introducción a XPath Injection]]"
Nota siguiente: "[[02 - Bypass de autenticación con XPath]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

HTB da la detección por supuesta y salta directo a explotar. En un test real el reto es doble: <mark style="background: #ADCCFFA6;">reconocer que hay un backend XML/XPath detrás</mark> —algo poco habitual— y confirmar la inyección sin falsos positivos. Sistematizamos la fase igual que en la [[01 - Detección de SQL Injection|detección de SQLi]].

# Reconocer un backend XML/XPath

El primer obstáculo en caja negra es sospechar que la consulta es XPath y no SQL. Señales:

- **Mensajes de error** que delatan el parser: `XPathException`, `SimpleXMLElement`, `DOMXPath::query()`, `System.Xml.XPath`, o textos como *"unterminated string in XPath expression"* / *"Invalid predicate"*.
- **Stack tecnológico**: PHP (`SimpleXML`/`DOMXPath`), Java (`javax.xml.xpath`), .NET (`System.Xml`), Python (`lxml`). Endpoints que consumen o devuelven XML.
- **Contexto de la app**: <mark style="background: #FFB8EBA6;">logins y buscadores de aplicaciones pequeñas, appliances, IoT o sistemas legacy</mark>, donde un fichero XML sustituye a la base de datos.

# Superficie de inyección

Cualquier entrada que termine en una expresión XPath: usuario y contraseña, parámetros de búsqueda/filtro, campos de ordenación y —esto se pasa por alto— <mark style="background: #FF5582A6;">el parámetro que elige el campo de salida</mark> (la **ruta de nodo**, no solo el predicado, como el `f` del buscador de calles en [[03 - Exfiltración de datos con XPath|exfiltración]]). Mapea todos los puntos de entrada con un proxy antes de probar.

# Contexto de inyección

Antes de explotar hay que saber qué carácter rompe la consulta:

| Contexto | Consulta típica | Cómo romperlo |
| - | - | - |
| Literal en predicado | `[x='INPUT']` | `'` |
| Dentro de función | `[contains(d,'INPUT')]` | `')` |
| Numérico | `[position()=INPUT]` | sin comillas |
| Ruta de nodo | `/a/b/INPUT` | pasos de ruta / `\| //...` |

# Técnicas de detección

- **Basada en error**: inyectar una comilla sola `'`. Al desbalancear el literal, el parser XPath lanza un error o un 500 — la señal más directa. Confirmar con `''` (rebalancea).
- **Diferencial booleano**: comparar verdadero vs falso. `' or '1'='1` (todos los resultados) frente a `' or '1'='2` (ninguno); en contexto de función, `') or ('1'='1` vs `') or ('1'='2`. Si la respuesta cambia, hay inyección.
- **Ciega / basada en tiempo**: sin salida ni error, se usa el oráculo de comportamiento o se fuerza retardo con `count((//.)[count((//.))])` — XPath no tiene `sleep()` (ver [[05 - XPath ciega y basada en tiempo]]).
- **Out-of-band**: si el motor soporta `doc()`/`document()`, se fuerza una petición saliente a un dominio controlado → confirma ejecución y sirve para exfiltrar. [`XCat`](https://github.com/orf/xcat) automatiza esta vía.

# Fingerprinting: distinguir XPath de SQLi y LDAP

<mark style="background: #FF5582A6;">`' or '1'='1` dispara bypass de login en SQLi, XPath **y** LDAP</mark> — por sí solo no dice qué motor hay detrás. Diferenciar es crítico para no perder el tiempo con `payloads` del motor equivocado:

| Prueba | SQLi | XPath | LDAP |
| - | - | - | - |
| Comentario `-- ` / `#` | ✅ funciona | ❌ | ❌ |
| `UNION SELECT` | ✅ | ❌ | ❌ |
| `count(/*)`, `substring()`, `name()` | ❌ | ✅ | ❌ |
| Sintaxis de filtro `*)(uid=*` | ❌ | ❌ | ✅ |

<mark style="background: #8000E1A6;">Confirmar con funciones propias de XPath</mark> (`count`, `string-length`, `name`) descarta SQLi/LDAP y fija el vector antes de invertir esfuerzo. La [[01 - Detección de LDAP Injection|detección de LDAP]] y la [[02 - Detección de NoSQL injection|detección de NoSQL]] aplican el mismo criterio en espejo.

> [!info]+ WAF y realidad en 2026
> A diferencia de la SQLi, <mark style="background: #FFB86CA6;">los WAF rara vez traen firmas específicas de XPath</mark>: menos ruido y menos bloqueo, pero el bug es intrínsecamente más raro. Las herramientas confirman y explotan, no descubren el punto de entrada — para eso, proxy + [[19 - Fuzzing de parámetros y valores|fuzzing de parámetros]].

> [!info]+ Fuentes
> Metodología contrastada con [PortSwigger — XPath injection](https://portswigger.net/web-security/xpath-injection), [OWASP WSTG-INPV-09 (Testing for XPath Injection)](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/09-Testing_for_XPath_Injection), [HackTricks — XPATH injection](https://book.hacktricks.wiki/en/pentesting-web/xpath-injection.html) y la librería de `payloads` de [PayloadsAllTheThings](https://swisskyrepo.github.io/PayloadsAllTheThings/XPATH%20Injection/).

Confirmada la inyección y el contexto, el primer objetivo práctico suele ser saltarse la autenticación: [[02 - Bypass de autenticación con XPath]].
