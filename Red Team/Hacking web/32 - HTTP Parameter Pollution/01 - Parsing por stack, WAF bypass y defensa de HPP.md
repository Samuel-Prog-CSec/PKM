---
tags:
  - Web/Red-Team
  - HPP
  - Pentesting/Explotacion
  - Tipo/Defensa
Descripción: "El HPP server-side vive de que las capas del path (WAF, proxy, framework, microservicio) no se ponen de acuerdo en qué copia de un parámetro duplicado es la buena"
Fecha de actualización: 2026-07-27
Nota previa: "[[00 - Introducción a HTTP Parameter Pollution]]"
Nota siguiente: ""
Area: "[[HTTP Parameter Pollution.base|HTTP Parameter Pollution]]"
---
---

El HPP server-side vive de que las capas del path (WAF, proxy, framework, microservicio) **no se ponen de acuerdo** en qué copia de un parámetro duplicado es la buena. Metodología del WSTG para detectarlo: manda (1) petición limpia, (2) con el valor manipulado, (3) las dos combinadas — si la respuesta (3) no coincide con (1) ni con (2), los parámetros interactúan y hay que perseguirlo.

# Cómo resuelve cada stack los duplicados

<mark style="background: #ADCCFFA6;">La tabla de referencia</mark>, dado `?color=red&color=blue`:

| Stack | Resultado | Acceso a todos |
| - | - | - |
| **PHP** (cualquier SAPI) | último: `blue` | `color[]=red&color[]=blue` fuerza array |
| **ASP.NET / IIS** (+ Core/Kestrel) | concatenados con coma: `red,blue` | `StringValues` |
| **ASP clásico** | `red,blue` | `Request.QueryString` |
| **JSP / Servlet** (Tomcat, Jetty… por spec) | primero: `red` | `getParameterValues()` → `["red","blue"]` |
| **Spring MVC** (`@RequestParam String`) | coma: `red,blue` (¡3.ª conducta!) | bind a `List`/`String[]` |
| **Node.js / Express** (4.x `qs`, 5.x `querystring`) | **array**: `['red','blue']` | ya es array |
| **Python / Flask** (Werkzeug) | primero: `red` | `.getlist()` |
| **Python / Django** | último: `blue` | `.getlist()` |
| **Ruby on Rails** (Rack) | último: `blue` | `color[]=` array (`WEBrick` puro → primero) |
| **Go** (`net/http`) | `.Get()`→primero; map directo→todos | `url.Values` = `map[string][]string` |
| **Perl** (CGI.pm) | escalar→primero; `multi_param()`→todos | |

> [!warning]+ La tabla de OWASP está mal para Node/Express
> El WSTG lista "Node.js/Express: primera ocurrencia", citándolo a la charla de **2009**… pero Node no existía hasta 2009 ni Express hasta 2010. Verificado contra la doc oficial: **ambos parsers producen un array**, nunca "el primero". Si ves comas en black-box es porque el código hace `toString()` implícito del array (`Array.prototype.toString()` une con comas) — *imita* a ASP.NET sin compartir su causa. Además "PHP/Apache" y "JSP/Tomcat" son nombres engañosos: parsea **el lenguaje/la spec**, no el servidor web (Nginx+PHP-FPM se comporta igual que Apache+mod_php).

# WAF bypass: vivo en 2025

El uso más rentable hoy. <mark style="background: #FFB86CA6;">Combinando la concatenación-por-coma de ASP.NET con el operador coma de JavaScript</mark>, se parte un payload XSS entre parámetros duplicados:

```text
q=1'&q=alert(1)&q='2      →  el servidor reconstruye:  1',alert(1),'2   (JS válido)
```

Ethiack (2025) lo probó contra **17 configuraciones de WAF**: los payloads simples pasaban ~17,6%, pero los de **parameter pollution el 70,6%**. Solo Cloud Armor, Azure WAF y open-appsec bloquearon de inicio; **Cloud Armor aguantó** todo el ejercicio, pero Azure WAF y open-appsec cayeron con variantes. <mark style="background: #FF5582A6;">La evasión de WAF vía HPP está muy viva contra productos actuales</mark>, no es cosa de 2009.

# SSPP: la encarnación moderna

*Server-Side Parameter Pollution* (PortSwigger lo añadió a su ruta de API Testing) es HPP donde la app **concatena** tu entrada en una petición que **ella misma** construye hacia una API interna o un tercero, sin codificar. Inyectas delimitadores para reinterpretar esa petición:
- `%23` (`#`) trunca la query y borra los parámetros que van detrás.
- `&campo=valor` añade o sobreescribe un parámetro fijo.
- `../` en un segmento de ruta REST (`peter/../admin`).
- En JSON, `","access_level":"administrator` escala un payload concatenado a mano.

Es el vector relevante en 2025 porque encaja con la arquitectura real: gateways, BFFs y microservicios que re-serializan y reenvían peticiones.

# JSON: el mismo mal, otro content-type

El [RFC 8259 §4](https://www.rfc-editor.org/rfc/rfc8259) dice que las claves duplicadas en un objeto JSON son *comportamiento impredecible*: la mayoría (JS, Python, Java, Go `encoding/json`, Ruby, PHP) toman la **última**, pero algunas librerías (Go `jsonparser`, o `json-iterator` en su puerto **Java**) toman la **primera**. En una cadena de microservicios donde dos servicios parsean el mismo body con librerías distintas, ahí aparece el desacuerdo explotable.

# Relevancia, defensa y arsenal

Honestamente: <mark style="background: #FFB8EBA6;">HPP rara vez saca CVE propio hoy</mark> y una app mono-stack consistente es casi inmune al truco de "qué copia gana" dentro de su frontera. Pero **no está muerto** — WAF bypass, SSPP, y el client-side HPP (un bug de lógica que cada nueva *share button*/redirect reintroduce). Trátalo como **técnica que habilita** otras clases (evasión de WAF, auth bypass, [[00 - Introducción a los ataques server-side|SSRF]], open redirect vía `redirect_uri`), no como vuln standalone — por eso su frecuencia real supera su huella en CVEs.

**Arsenal**: Burp [Param Miner](https://portswigger.net/bappstore/17d2949a985c4b7ca092728dba871943) (descubre parámetros ocultos y diffea respuestas; el estándar de facto, mantenido por PortSwigger) y el **método manual de 3 peticiones** del WSTG. No hay escáner dedicado fiable: HPP pide criterio de negocio y automatizarlo genera muchos falsos positivos.

**Defensa**: (1) **canonicalizar** la entrada al principio del path y que **todas** las capas (WAF, proxy, framework, microservicio) resuelvan los duplicados **igual** — el bug es desacuerdo de parsers, el fix es acuerdo entre ellos; (2) **rechazar** duplicados inesperados (validar contra OpenAPI/JSON-Schema estricto y responder `400`); (3) **URL-encodear** toda entrada antes de meterla en una URL que construyas (mata SSPP y client-side HPP); (4) usar APIs *collection-aware* (`getParameterValues()`, `.getlist()`) y **fallar** si un parámetro escalar llega con N>1 valores en vez de coercerlo en silencio.

> [!info]+ Fuentes
> [OWASP WSTG — Testing for HTTP Parameter Pollution](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/04-Testing_for_HTTP_Parameter_Pollution); [PortSwigger — Server-side parameter pollution](https://portswigger.net/web-security/api-testing/server-side-parameter-pollution); [Ethiack — Bypassing WAFs with Parameter Pollution](https://blog.ethiack.com/blog/bypassing-wafs-for-fun-and-js-injection-with-parameter-pollution) (2025-08); Carettoni & Di Paola, *HTTP Parameter Pollution* (AppSec EU 2009); [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259).
