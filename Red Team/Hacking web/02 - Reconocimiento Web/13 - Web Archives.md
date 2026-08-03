---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "Las webs cambian y desaparecen, pero su rastro queda"
Fecha de actualización: 2026-06-02
Nota previa: "[[12 - Search Engine Discovery]]"
Nota siguiente: "[[14 - Automatización del recon]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Las webs cambian y desaparecen, pero su rastro queda. <mark style="background: #ADCCFFA6;">La `Wayback Machine` (del Internet Archive) es un archivo digital de la web que guarda instantáneas de los sitios tal como eran en distintos momentos desde 1996</mark>. Permite "viajar al pasado" y ver versiones antiguas de un sitio: su diseño, su contenido y —lo que nos importa— sus rutas y parámetros de entonces.

# Cómo funciona

Tres pasos:

1. **Crawling**: bots automatizados recorren la web siguiendo enlaces y **descargan** copias completas de las páginas (HTML, CSS, JS, imágenes).
2. **Archiving**: cada captura se almacena asociada a una fecha y hora, creando una instantánea histórica. La frecuencia depende de la popularidad y el ritmo de cambio del sitio —desde varias veces al día hasta unas pocas capturas en años—.
3. **Accessing**: introduces una URL y eliges una fecha para ver cómo lucía el sitio en ese momento.

![Flujo de la Wayback Machine: Crawling → Archiving → Accessing](https://academy.hackthebox.com/storage/modules/144/ig_webarchives_1.png)

No archiva todo: prioriza sitios de valor cultural, histórico o de investigación, y los dueños pueden pedir exclusión (sin garantía).

# Por qué importa en recon

- **Activos y vulnerabilidades olvidadas**: <mark style="background: #FF5582A6;">descubre páginas, directorios, ficheros o subdominios que ya no existen en el sitio actual</mark> pero siguen archivados — y a veces siguen vivos en el servidor aunque ya no estén enlazados.
- **Seguir la evolución**: comparar instantáneas revela cambios de estructura, tecnología y posibles puntos donde se introdujo o se "parcheó" una debilidad.
- **OSINT**: el contenido antiguo aporta inteligencia sobre actividades pasadas, empleados y decisiones tecnológicas del objetivo.
- **Sigilo**: consultar el archivo es <mark style="background: #FFB8EBA6;">totalmente pasivo</mark> — no tocas la infraestructura del objetivo, así que es indetectable.

> [!important]+ La técnica que de verdad importa: volcar URLs históricas
> HTB se queda en navegar la interfaz web, pero el uso pro es **automatizar la extracción de todas las URLs archivadas** de un dominio:
> - `waybackurls example.com` y `gau example.com` (getallurls) vuelcan cada URL que el archivo conoce del objetivo, incluidos endpoints muertos y rutas con parámetros.
> - `waymore` combina varias fuentes (Wayback, Common Crawl, URLScan, VirusTotal) y descarga incluso el contenido archivado.
>
> ¿Por qué importa? Esas URLs históricas contienen <mark style="background: #FFB86CA6;">parámetros antiguos (`?id=`, `?file=`, `?redirect=`) que siguen funcionando en el backend pero ya no se enlazan</mark> — candidatos directos a `IDOR`, `SQLi`, `LFI` u `open redirect`—. Filtrar esa lista por parámetros (`gf` patterns) y probarlos es un flujo de bug bounty de altísimo rendimiento.

> [!info]+ La CDX API y otros archivos
> El Internet Archive expone una API programable (`CDX`) para consultar capturas sin la interfaz:
> ```shell-session
> $ curl -s "http://web.archive.org/cdx/search/cdx?url=*.example.com/*&output=text&fl=original&collapse=urlkey"
> ```
> Útil también: recuperar un `robots.txt` o un fichero JS **antiguo** que filtraba rutas o secretos ya retirados de la versión actual. Más allá de Wayback, `archive.today` y `Common Crawl` son fuentes complementarias con índices distintos.

Hemos recorrido todas las técnicas a mano. El último paso es encadenarlas en un flujo automatizado que las ejecute por ti: [[14 - Automatización del recon]].
