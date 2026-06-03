---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[10 - Crawling web]]"
Nota siguiente: "[[12 - Search Engine Discovery]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El crawling manual no escala. Para mapear un sitio entero se automatiza con herramientas que recorren y extraen los datos por ti, dejándote la parte de **analizar**.

# Crawlers populares

| Herramienta | Descripción |
| - | - |
| `Burp Suite Spider` | Crawler activo del proxy de pentest más usado; mapea apps y descubre contenido oculto (ver [[Proxies web]]) |
| `OWASP ZAP` | Escáner open-source con componente *spider*, modo manual y automático |
| `Scrapy` | Framework Python para construir crawlers a medida; extracción estructurada y escalable |
| `Apache Nutch` | Crawler Java extensible y escalable para *crawls* masivos |

# `Scrapy`: el framework

<mark style="background: #ADCCFFA6;">`Scrapy` es un framework de Python para construir *spiders* a medida</mark>: defines una clase con las URLs semilla, las reglas de extracción (selectores CSS/XPath) y los *callbacks* que procesan cada respuesta. Su flexibilidad lo hace ideal para recon dirigido, donde quieres extraer exactamente los datos que te interesan y volcarlos en un formato procesable.

```shell-session
$ pip3 install scrapy
```

# `ReconSpider` en acción

HTB proporciona un *spider* de Scrapy preconstruido, `ReconSpider`, orientado a recon:

```shell-session
$ wget -O ReconSpider.zip https://academy.hackthebox.com/storage/modules/144/ReconSpider.v1.2.zip
$ unzip ReconSpider.zip
$ python3 ReconSpider.py http://inlanefreight.com
```

Recorre el objetivo y vuelca todo lo encontrado en `results.json`.

# `results.json`: qué mirar

El spider clasifica lo extraído por tipo:

| Clave | Contenido |
| - | - |
| `emails` | Correos hallados en el dominio |
| `links` | URLs internas descubiertas |
| `external_files` | Ficheros externos (PDFs…) |
| `js_files` | Ficheros JavaScript del sitio |
| `form_fields` | Campos de formularios |
| `images` / `videos` / `audio` | Recursos multimedia |
| `comments` | Comentarios HTML del código fuente |

No todas las claves valen lo mismo. Las que de verdad mueven un pentest:

- <mark style="background: #FF5582A6;">`js_files`</mark>: es la mina de oro moderna. El JavaScript del front-end suele contener rutas de API, endpoints internos, claves y lógica de negocio. Analizarlos descubre superficie que ningún crawler de HTML ve.
- `emails`: alimentan enumeración de usuarios y campañas de phishing; revelan el patrón de cuentas (`nombre.apellido@`).
- `comments`: los desarrolladores filtran rutas, credenciales de prueba y TODOs reveladores.
- `external_files`: PDFs y documentos con metadatos (autores, software, rutas internas) explotables con `exiftool`.

> [!important]+ Exprimir los `js_files` — el paso que HTB no da
> Tener la lista de `js_files` es solo el principio. El valor está en **analizarlos**:
> - `LinkFinder` y `xnLinkFinder` extraen endpoints y rutas embebidas en el JS — a menudo APIs sin documentar que conectan con [[23 - APIs web e identificación de endpoints]].
> - `SecretFinder` y `trufflehog` buscan claves de API, tokens y secretos *hardcodeados*.
> - `getJS` / `subjs` recopilan todos los `.js` de un objetivo para procesarlos en lote.
> - Si el JS está **ofuscado** (minificado, *packed*, obfuscator.io), primero hay que revertirlo para poder leerlo: [[00 - Introducción y código fuente|desofuscación de JavaScript]].
> Encontrar una clave de AWS o un endpoint de admin en un bundle de JavaScript es un patrón recurrente de bug bounty.

> [!info]+ Crawlers modernos *JS-aware*
> `ReconSpider` y los spiders clásicos no ejecutan JavaScript, así que pierden el contenido de las SPA (React, Vue, Angular). `katana -jc` (con *crawling* de JS) y `gospider` renderizan o parsean el JS para descubrir rutas dinámicas. Para sitios modernos, un crawler que entienda JS es imprescindible.

> [!warning]+ Ética y alcance
> El crawling extensivo genera mucho tráfico y puede sobrecargar el servidor. Obtén permiso antes de un *spidering* intrusivo y respeta los recursos del objetivo y su `robots.txt`.

El crawling explota lo que el sitio enlaza. La vía complementaria es aprovechar lo que **otros** ya han indexado por ti: los motores de búsqueda. Eso es [[12 - Search Engine Discovery]].
