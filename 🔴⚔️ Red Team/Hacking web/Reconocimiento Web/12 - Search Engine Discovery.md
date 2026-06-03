---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[11 - Spidering con Scrapy]]"
Nota siguiente: "[[13 - Web Archives]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El `search engine discovery` (o `OSINT` con buscadores) usa los motores de búsqueda como herramientas para descubrir información sobre un objetivo</mark>: documentos sensibles, páginas de login ocultas, credenciales expuestas, datos de empleados. Aprovecha que los buscadores ya han indexado una porción enorme de la web por ti.

# Por qué importa

- <mark style="background: #FFB8EBA6;">**Open source y legal**: la información es de acceso público</mark>, así que recopilarla no toca al objetivo ni viola nada.
- **Amplitud**: los buscadores indexan una parte gigantesca de la web.
- **Coste cero y sin barrera técnica**: gratis y sin necesidad de herramientas especializadas.

Su límite: no todo está indexado, y parte de la información se oculta o protege deliberadamente.

# Operadores de búsqueda

Los operadores son el lenguaje de precisión del buscador. La sintaxis varía algo entre motores, pero el principio es común:

| Operador | Qué hace | Ejemplo |
| - | - | - |
| `site:` | Limita a un dominio | `site:example.com` |
| `inurl:` | Término en la URL | `inurl:login` |
| `filetype:` / `ext:` | Tipo de fichero | `filetype:pdf` |
| `intitle:` | Término en el título | `intitle:"confidential report"` |
| `intext:` | Término en el cuerpo | `intext:"password reset"` |
| `cache:` | Versión cacheada (⚠️ Google lo **retiró en 2024**; usa [[13 - Web Archives|Wayback]]) | `cache:example.com` |
| `allintext:` | Todos los términos en el cuerpo | `allintext:admin password reset` |
| `allinurl:` | Todos los términos en la URL | `allinurl:admin panel` |
| `AND` / `OR` / `NOT` | Combinan o excluyen términos | `site:example.com AND (inurl:admin OR inurl:login)` |
| `*` | Comodín (cualquier palabra) | `site:x.com filetype:pdf user* manual` |
| `..` | Rango numérico | `site:shop.com "price" 100..500` |
| `" "` | Frase exacta | `"information security policy"` |
| `-` | Excluye un término | `site:news.com -inurl:sports` |

# Google Dorking

<mark style="background: #ADCCFFA6;">`Google Dorking` (o `Google Hacking`) combina estos operadores para destapar información sensible, vulnerabilidades o contenido oculto</mark>. Patrones habituales:

```text
# Páginas de login y admin
site:example.com (inurl:login OR inurl:admin)

# Ficheros expuestos
site:example.com (filetype:xls OR filetype:docx OR filetype:pdf)

# Ficheros de configuración
site:example.com inurl:config.php
site:example.com (ext:conf OR ext:cnf)

# Backups de base de datos
site:example.com (inurl:backup OR filetype:sql)
```

<mark style="background: #FF5582A6;">Un `.sql` de backup, un `.env` o un `config.php` indexados son credenciales servidas en bandeja</mark>. La `Google Hacking Database` (GHDB, en Exploit-DB) recopila miles de dorks por categoría: ficheros con contraseñas, dispositivos expuestos, mensajes de error reveladores.

> [!info]+ Más allá de Google
> - **Otros buscadores**: Bing, DuckDuckGo y Yandex tienen índices distintos — un dork que no da nada en Google puede acertar en otro. `Shodan`, `Censys` y `FOFA` indexan **dispositivos** y servicios (banners, certificados, paneles) en vez de páginas.
> - **Búsqueda en código fuente**: `grep.app`, `publicwww` y `SearchCode` buscan en el HTML/JS de millones de sitios — útil para encontrar quién usa una librería vulnerable o un endpoint concreto.
> - **GitHub dorking**: buscar en GitHub el dominio del objetivo junto a `password`, `api_key`, `secret` destapa credenciales filtradas en commits. Herramientas como `trufflehog` y `gitleaks` lo automatizan sobre repos de la organización.
> - **`theHarvester`** agrega resultados de buscadores y fuentes OSINT para volcar correos y subdominios.

> [!warning]+ Google bloquea el dorking automatizado
> Google detecta y frena el *scraping*: tras unas pocas consultas automáticas con operadores aparecen captchas o bloqueos temporales de IP. El dorking masivo programático no es fiable contra Google directamente; para automatizar conviene usar APIs de búsqueda de pago, rotación o motores más permisivos. El dorking manual sigue siendo la vía más fiable para hallazgos puntuales.

Los buscadores indexan el presente. Para ver lo que el sitio **mostraba antes** —rutas borradas, parámetros antiguos, versiones vulnerables— se recurre a los archivos históricos: [[13 - Web Archives]].
