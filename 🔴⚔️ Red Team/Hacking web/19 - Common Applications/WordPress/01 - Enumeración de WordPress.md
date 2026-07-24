---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-17
Nota previa: "[[00 - Estructura y roles de WordPress]]"
Nota siguiente: "[[02 - Login y fuerza bruta en WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

El objetivo de esta fase es responder tres preguntas: ¿es WordPress?, ¿qué versión de core?, y ¿qué plugins y temas monta? El **inventario de plugins/temas con sus versiones** es lo que abre el camino a la explotación — recuerda que ahí vive el 54% de las CVEs ([[00 - Estructura y roles de WordPress]]).

# Fingerprinting

Confirmar que hay WordPress detrás es trivial; casi siempre se delata solo (es un caso concreto del [[09 - Fingerprinting web|fingerprinting web]] general):

- **`/robots.txt`** suele referenciar `/wp-admin/` y `/wp-content/`.
- **`/wp-login.php`** existe y devuelve el formulario de login (`/wp-admin` redirige allí).
- **`/wp-json/`** (REST API) responde con JSON — presente por defecto en 4.7+.
- El **código fuente** está plagado de rutas `wp-content/...` y de la etiqueta `<meta name="generator">`.

# Versión del core

Saber la versión permite cruzar con CVEs conocidas. Vías manuales, de más a menos fiable:

La **etiqueta meta generator** es la más directa (visible con `CTRL+U` en el navegador o filtrando con `curl` + `grep`):

```shell-session
$ curl -s -X GET http://blog.inlanefreight.com | grep '<meta name="generator"'
<meta name="generator" content="WordPress 5.3.3" />
```

Cuando el generator está oculto, la versión se filtra por **otros canales**:

- **CSS y JS** cargan con el parámetro de cache-busting `?ver=`, que suele coincidir con la versión del core o del plugin:

```html
<link rel='stylesheet' href='.../wp-content/themes/ben_theme/style.css?ver=5.3.3' type='text/css' />
<script src='.../wp-content/plugins/mail-masta/lib/subscriber.js?ver=5.3.3'></script>
```

- **`readme.html`** en la raíz revela la versión en instalaciones antiguas.
- El **feed RSS** (`/?feed=rss2`) incluye `<generator>https://wordpress.org/?v=5.3.2</generator>`.

<mark style="background: #FFB8EBA6;">Ningún canal aislado es de fiar</mark>: un administrador puede falsear el generator y olvidarse del `?ver=`. Cruzar varios.

# Plugins y temas

## Enumeración pasiva

El código fuente ya expone buena parte de los plugins y temas activos. Extraer las rutas `wp-content/plugins/` y `wp-content/themes/` del HTML:

```shell-session
$ curl -s http://blog.inlanefreight.com | sed "s/href=/\n/g;s/src=/\n/g" | grep -oE 'wp-content/(plugins|themes)/[^/?'"'"']+' | sort -u
wp-content/plugins/mail-masta
wp-content/plugins/wp-google-places-review-slider
wp-content/themes/ben_theme
```

El `?ver=` de cada recurso da la **versión del plugin**, y las cabeceras de respuesta a veces también.

## Enumeración activa

No todos los plugins se referencian en la home. Para los que no, se sondea directamente su directorio: <mark style="background: #ADCCFFA6;">un `301`/redirección confirma que existe; un `404` que no</mark>.

```shell-session
$ curl -I http://blog.inlanefreight.com/wp-content/plugins/mail-masta
HTTP/1.1 301 Moved Permanently
Location: http://blog.inlanefreight.com/wp-content/plugins/mail-masta/

$ curl -I http://blog.inlanefreight.com/wp-content/plugins/someplugin
HTTP/1.1 404 Not Found
```

Esto se automatiza con una wordlist de plugins conocidos (`ffuf`, `wfuzz` o directamente WPScan). La versión exacta de cada plugin suele estar en su **`readme.txt`** (`/wp-content/plugins/<plugin>/readme.txt`), campo `Stable tag`.

# Directory Indexing

<mark style="background: #FF5582A6;">Desactivar un plugin no lo elimina</mark>: sus ficheros siguen en disco y son accesibles por URL, así que un plugin vulnerable desactivado sigue siendo explotable. Si además el servidor tiene el *directory listing* activo, se puede navegar su carpeta entera:

```shell-session
$ curl -s http://blog.inlanefreight.com/wp-content/plugins/mail-masta/ | html2text
****** Index of /wp-content/plugins/mail-masta ******
[DIR] inc/         2020-05-13 18:01 -
[DIR] lib/         2020-05-13 18:01 -
[TXT] readme.txt   2020-05-13 18:01 2.2K
```

<mark style="background: #FFB86CA6;">El Directory Indexing expone ficheros con código vulnerable o datos sensibles</mark> que de otro modo no descubrirías. `html2text` convierte el listado HTML en algo legible.

> [!important]+ Manual primero, automático después
> Un escáner como WPScan confirma versión y plugins conocidos, pero **se le escapan** plugins que sí ves a mano en el código fuente o por sondeo directo. La lección transferible a cualquier app: el escáner no sustituye al ojo humano. El flujo real es **manual para entender + automático para cubrir volumen**. La automatización completa (WPScan, `nuclei`, `wpprobe`) vive en [[06 - Arsenal de herramientas para WordPress]].

> [!info]+ Enumeración moderna cuando el HTML no da pistas
> En sitios cacheados/minificados donde el código fuente está limpio, la enumeración de plugins se apoya cada vez más en la **REST API** (`/wp-json/wp/v2/...`, rutas registradas por plugins) y en herramientas como `wpprobe`, que infiere plugins a partir de los endpoints REST expuestos en vez de sondear rutas a ciegas. Para plugins retirados pero aún en disco, `waybackurls`/`gau` recuperan rutas históricas. Detalle en [[06 - Arsenal de herramientas para WordPress]].

Con versión, plugins y temas inventariados, el siguiente eslabón es sacar la lista de usuarios y atacar el login: [[02 - Login y fuerza bruta en WordPress]].
