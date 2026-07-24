---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Cache-Poisoning
Fecha de actualización: 2026-07-14
Nota previa: "[[03 - Ataques de Web Cache Poisoning]]"
Nota siguiente: "[[05 - Detección, herramientas y prevención de Cache Poisoning]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Cuando no hay entradas unkeyed reflejadas obvias, la caché parece segura. Las técnicas avanzadas la rompen creando una **discrepancia entre lo que la caché usa para la cache key y lo que el servidor usa para generar la respuesta**. <mark style="background: #ADCCFFA6;">Si la caché "ve" un parámetro y el servidor "ve" otro, puedes envenenar una key legítima con un payload que la caché ni siquiera registra</mark>. Es, en esencia, el eje de **evasión** del cache poisoning.

# Fat GET: meter parámetros en el cuerpo de un GET

Una `Fat GET` es una petición **GET con cuerpo**. Suena raro porque los parámetros GET van en la query string, pero cualquier petición puede llevar body. La [RFC 7231 §4.3.1](https://www.rfc-editor.org/rfc/rfc7231#section-4.3.1) lo permite pero dice que <mark style="background: #FFB8EBA6;">un payload en un GET **no tiene semántica definida**</mark>. El fallo: algunos servidores mal implementados **sí parsean** parámetros del cuerpo de un GET.

Si `ref` es ahora **keyed** (no sirve el ataque básico), probamos si el servidor lee el cuerpo:

```http
GET /index.php?language=en HTTP/1.1
Host: fatget.wcp.htb
Content-Length: 11

language=de
```

La URL dice `language=en` pero la respuesta muestra **alemán** → el servidor **prefiere el parámetro del cuerpo**. La discrepancia:

```text
Caché ve:    /index.php?language=en          → cache key = language=en
Servidor ve: language=en (URL) + language=de (body) → sirve ALEMÁN
```

Resultado: la respuesta alemana se cachea bajo la key `language=en`. Se envenena metiendo el payload keyed en el cuerpo:

```http
GET /index.php?language=de HTTP/1.1
Host: fatget.wcp.htb
Content-Length: 142

ref="><script>...xhr a /admin.php?reveal_flag=1...</script>
```

> [!info] Fat GET es un fallo del **servidor**, no de la app
> El bug está en que el servidor web (o un framework) lee el body de un GET. La app y la caché son "correctas"; la discrepancia nace del servidor. Por eso escapa a revisiones centradas solo en el código de la aplicación.

# Parameter Cloaking: parseos de parámetros divergentes

El **parameter cloaking** explota que la **caché** y el **servidor** parsean los parámetros de forma distinta. El caso de libro es **Bottle** (framework Python, `CVE-2020-28473`): Bottle trata el `;` como **separador** de parámetros, la caché no.

```http
GET /?language=en&a=b;language=de HTTP/1.1
Host: cloak.wcp.htb
```

```text
Caché ve:    language=en  ·  a = "b;language=de"   → a es unkeyed → key = language=en
Bottle ve:   language=en  ·  a=b  ·  language=de    → última gana → ALEMÁN
```

La respuesta alemana se cachea bajo `language=en`. El truco: <mark style="background: #FF5582A6;">**esconder** el parámetro "clonado" pegándolo a un parámetro **unkeyed**</mark> (`a`), para que la caché no lo meta en la key. El payload XSS se entrega igual, URL-encodeando los `;` para que sobrevivan hasta Bottle:

```http
GET /?language=de&a=b;ref=%22%3E%3Cscript%3E...%3C/script%3E HTTP/1.1
Host: cloak.wcp.htb
```

# El patrón general: discrepancias de parseo

Ambas técnicas son casos de un principio más amplio — la **cache key injection / normalización divergente**:

| Fuente de discrepancia | Ejemplo |
| - | - |
| Body en GET | Fat GET |
| Separador de parámetros | `;` en Bottle/Ruby, `&` estándar |
| **Precedencia** de duplicados | PHP/Bottle toman el **último**; otros el **primero** → base de la [HTTP Parameter Pollution](https://owasp.org/www-community/attacks/HTTP_Parameter_Pollution) |
| Normalización de la ruta | La caché decodifica/normaliza `%2F`, mayúsculas o el puerto distinto que el servidor |

> [!important] Web Cache Entanglement (Kettle, 2020)
> James Kettle llevó esto al extremo en *Web Cache Entanglement*: cuando la caché **normaliza** la key (decodifica caracteres, quita parámetros, reordena) de forma distinta al servidor, aparecen la **cache key injection**, el **internal cache poisoning** y el envenenamiento de recursos "estáticos". La caza consiste en encontrar dónde caché y servidor **discrepan** en interpretar la misma petición. Es la referencia moderna imprescindible de este vector.

> [!info]+ Estado del arte 2024: "Gotta Cache 'Em All" (Doyhenard, Black Hat USA 2024)
> [Gotta Cache 'Em All](https://portswigger.net/research/gotta-cache-em-all) (Martin Doyhenard, ago 2024) generaliza la discrepancia caché↔origen con técnicas nuevas de alto impacto:
> - **Delimitadores de extensión estática**: los CDN cachean por extensión reconocida (`.js`, `.css`); un delimitador que el CDN no reconoce cuela una extensión falsa — ej. `/myAccount$a.css` hace que el CDN cachee una página dinámica como si fuera estática. El `;` de Spring (`/myAccount;x=1`) es la técnica hermana.
> - **Bypass de directorios estáticos por normalización divergente**: CloudFront/Azure/Imperva **normalizan** la ruta antes de aplicar las reglas de caché; Cloudflare/Google Cloud/Fastly **no** — la discrepancia permite envenenar rutas "estáticas".
> - **Envenenamiento de ficheros estáticos** (`/robots.txt`, `/favicon.ico`, cacheados por defecto en Cloudflare) y **Cache-What-Where**: encadenar bugs "no explotables" (un open redirect vía `X-Forwarded-Host` que el navegador no puede enviar) con el cache poisoning para lograr *takeover* de dominio.

<mark style="background: #FF5582A6;">La clave de detección: buscar cualquier lugar donde caché y servidor no coincidan al interpretar la petición</mark> — un carácter separador, un duplicado, un encoding, un puerto. `Param Miner` incluye pruebas específicas para estas discrepancias; lo vemos en [[05 - Detección, herramientas y prevención de Cache Poisoning]].

## Referencias

- [PortSwigger — Web Cache Entanglement (James Kettle, 2020)](https://portswigger.net/research/web-cache-entanglement)
- [PortSwigger — Gotta Cache 'Em All (Martin Doyhenard, 2024)](https://portswigger.net/research/gotta-cache-em-all)
- [CVE-2020-28473 — Bottle parameter cloaking](https://nvd.nist.gov/vuln/detail/CVE-2020-28473)
- [OWASP — HTTP Parameter Pollution](https://owasp.org/www-community/attacks/HTTP_Parameter_Pollution)
