---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "El crawling (o spidering) es el proceso automatizado de navegar un sitio siguiendo enlaces de página en página para recopilar información"
Fecha de actualización: 2026-06-02
Nota previa: "[[09 - Fingerprinting web]]"
Nota siguiente: "[[11 - Spidering con Scrapy]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El `crawling` (o `spidering`) es el proceso automatizado de navegar un sitio siguiendo enlaces de página en página para recopilar información</mark>. Un *crawler* parte de una `seed URL`, descarga la página, extrae sus enlaces, los encola y repite el proceso. Según su alcance, recorre un sitio entero o una porción enorme de la web.

![Árbol de crawling: desde la seed URL el crawler descubre páginas enlazadas en cascada](https://academy.hackthebox.com/storage/modules/144/ig_crawling_1.png)

<mark style="background: #8000E1A6;">La diferencia con el [[15 - Introducción al web fuzzing|fuzzing]] es clave: el crawler **sigue** enlaces que existen; el fuzzing **adivina** rutas que no están enlazadas</mark>. Son complementarios — el crawler mapea lo visible, el fuzzing descubre lo oculto.

# Estrategias y qué extraer

- **Breadth-first (anchura)**: recorre primero todos los enlaces de un nivel antes de profundizar. Da una visión amplia de la estructura.
- **Depth-first (profundidad)**: sigue un camino hasta el final antes de retroceder. Útil para llegar a contenido profundo concreto.

Un crawler no solo lista URLs; cosecha datos de valor:

- **Enlaces** (internos y externos): el esqueleto del sitio. Permiten mapear la estructura, descubrir páginas no enlazadas en el menú y ver relaciones con recursos externos.
- **Comentarios**: en HTML, blogs o foros. Los desarrolladores filtran rutas internas, credenciales de prueba o pistas de versiones en comentarios.
- **Metadatos**: títulos, descripciones, autores, fechas — contexto sobre el contenido y la tecnología.
- **Ficheros sensibles**: <mark style="background: #FF5582A6;">backups (`.bak`, `.old`), configuración (`web.config`, `settings.php`), logs (`error_log`)</mark>. Un fichero de configuración o un backup puede contener credenciales de base de datos, claves de API o incluso código fuente.

> [!important]+ El contexto lo es todo
> Un dato aislado rara vez importa; el valor está en **conectar puntos**. Imagina que entre los enlaces extraídos varios apuntan a `/files/`. Lo visitas manualmente y descubres que el *directory listing* está activo, exponiendo backups y documentos internos. Ese hallazgo no salía de mirar un enlace suelto: salió de detectar el patrón. Cruza siempre los comentarios, los metadatos y las rutas entre sí.

> [!info]+ Herramientas de crawling
> El crawling lo hacen `Burp Suite Spider` y `OWASP ZAP` (en proxies interactivos — ver [[00 - Introducción a los proxies web]]), y en CLI moderna `katana` (ProjectDiscovery), `hakrawler` y `gospider`, que vuelcan todas las URLs de un objetivo para alimentar el resto del pipeline. El enfoque programable con `Scrapy` se ve en [[11 - Spidering con Scrapy]].

# `robots.txt`

<mark style="background: #ADCCFFA6;">`robots.txt` es un fichero de texto en la raíz del sitio (`/robots.txt`) que indica a los bots qué partes pueden y no pueden rastrear</mark>, según el `Robots Exclusion Standard`. Cada registro tiene un `User-agent` y una serie de directivas:

| Directiva | Descripción | Ejemplo |
| - | - | - |
| `Disallow` | Rutas que el bot no debe rastrear | `Disallow: /admin/` |
| `Allow` | Permite explícitamente una ruta dentro de un `Disallow` más amplio | `Allow: /public/` |
| `Crawl-delay` | Segundos entre peticiones (no estándar: lo respetan Bing/Yandex, Google lo **ignora**) | `Crawl-delay: 10` |
| `Sitemap` | URL de un sitemap XML | `Sitemap: https://example.com/sitemap.xml` |

```text
User-agent: *
Disallow: /admin/
Disallow: /private/
Allow: /public/

Sitemap: https://www.example.com/sitemap.xml
```

Para recon, `robots.txt` es inteligencia regalada: <mark style="background: #FFB86CA6;">las rutas en `Disallow` señalan precisamente lo que el dueño quiere ocultar a los buscadores</mark> —paneles de admin, backups, áreas internas—. Del ejemplo se infiere de inmediato que existen `/admin/` y `/private/`. `Disallow` no protege nada: solo es un cartel que apunta a lo interesante. Revisa también el `sitemap.xml` referenciado, que lista URLs que el sitio considera importantes (y a veces páginas no enlazadas).

> [!warning]+ Trampas para bots
> Algunos sitios incluyen directorios *honeypot* en `robots.txt` para cazar bots maliciosos que los visiten. Identificar esas trampas dice mucho de la madurez defensiva del objetivo — y te evita morder el anzuelo.

# `.well-known`

El estándar `.well-known` (`RFC 8615`) define un directorio normalizado bajo `/.well-known/` que centraliza metadatos críticos del sitio: configuración, políticas y mecanismos de seguridad. <mark style="background: #FFB8EBA6;">Al ser una ubicación fija, cualquier cliente sabe construir la URL exacta</mark> (p. ej. `https://example.com/.well-known/security.txt`). IANA mantiene el registro de URIs:

| URI | Descripción |
| - | - |
| `security.txt` | Contacto para reportar vulnerabilidades (`RFC 9116`) |
| `change-password` | URL estándar para cambiar contraseña |
| `openid-configuration` | Configuración de OpenID Connect (sobre OAuth 2.0) |
| `assetlinks.json` | Verifica la propiedad de apps asociadas al dominio |
| `mta-sts.txt` | Política `MTA-STS` para seguridad de correo |

El más jugoso en recon es `openid-configuration`: al pedirlo, devuelve un JSON con **toda** la superficie de autenticación del proveedor:

```json
{
  "issuer": "https://example.com",
  "authorization_endpoint": "https://example.com/oauth2/authorize",
  "token_endpoint": "https://example.com/oauth2/token",
  "userinfo_endpoint": "https://example.com/oauth2/userinfo",
  "jwks_uri": "https://example.com/oauth2/jwks",
  "response_types_supported": ["code", "token", "id_token"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "scopes_supported": ["openid", "profile", "email"]
}
```

<mark style="background: #FFB86CA6;">De un solo fichero obtienes los endpoints de autorización y token, el `jwks_uri` con las claves criptográficas, los algoritmos de firma soportados y los scopes</mark> — el mapa completo para atacar después la lógica de `OAuth`/`OIDC`.

> [!info]+ Otros `.well-known` que merece la pena probar
> `/.well-known/acme-challenge/` (validación de Let's Encrypt), `/.well-known/apple-app-site-association` y `/.well-known/assetlinks.json` (enlazado con apps móviles — revelan los *package names* de las apps de la organización, útil para pivotar a su superficie móvil). Recorrer el registro de IANA probando URIs es una vía barata de descubrir endpoints de configuración.

El crawling manual y con herramientas CLI cubre lo básico. Para un control total —reglas de extracción, profundidad, filtrado— se programa un *spider* con `Scrapy`: [[11 - Spidering con Scrapy]].
