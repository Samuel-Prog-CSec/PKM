---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "El fingerprinting extrae los detalles técnicos de las tecnologías que sostienen un sitio web: servidor, sistema operativo, lenguaje, framework, CMS, WAF. Igual que una huella…"
Fecha de actualización: 2026-06-02
Nota previa: "[[08 - Virtual Hosts]]"
Nota siguiente: "[[10 - Crawling web]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El `fingerprinting` extrae los detalles técnicos de las tecnologías que sostienen un sitio web</mark>: servidor, sistema operativo, lenguaje, framework, `CMS`, `WAF`. Igual que una huella identifica a una persona, la firma digital de cada componente revela qué corre por debajo — y, con ello, qué exploits pueden funcionar.

# Por qué importa

- **Ataques dirigidos**: conocer la tecnología exacta permite <mark style="background: #FFB86CA6;">centrar el esfuerzo en exploits y `CVE` que afectan a esa versión concreta</mark>, en vez de disparar a ciegas.
- **Identificar *misconfigs***: delata software desactualizado, ajustes por defecto o configuraciones inseguras que otras técnicas no ven.
- **Priorizar objetivos**: ante varios hosts, el fingerprinting señala cuáles son más probablemente vulnerables o más jugosos.
- **Perfil completo**: cruzado con el resto del recon, da una visión holística de la postura de seguridad y los vectores disponibles.

# Técnicas

- **Banner grabbing**: leer los *banners* de los servicios — revelan software y versión.
- **Cabeceras HTTP**: cada respuesta lleva metadatos. `Server` delata el servidor web; `X-Powered-By`, el lenguaje o framework; las cookies (`PHPSESSID`, `JSESSIONID`, `laravel_session`) el stack.
- **Sondeo de respuestas**: peticiones especialmente formadas provocan respuestas o errores característicos de un software concreto.
- **Análisis del contenido**: la estructura de la página, sus scripts o un comentario de copyright pueden delatar el `CMS` o la versión.

# Herramientas

| Herramienta | Descripción |
| - | - |
| `Wappalyzer` | Extensión/servicio que perfila tecnologías web (CMS, frameworks, analítica) |
| `BuiltWith` | Perfilador con informes detallados del stack |
| `WhatWeb` | CLI con gran base de firmas |
| `Nmap` | Escáner versátil; con `NSE` hace fingerprinting de servicio/SO (ver [[02 - Escaneo de puertos y hosts|escaneo de puertos]]) |
| `Netcraft` | Informes de tecnología, hosting y postura de seguridad |
| `wafw00f` | Detecta e identifica `WAF` |

# Banner grabbing con `curl`

`curl -I` (o `--head`) pide **solo** las cabeceras. Seguir la cadena de redirecciones es donde está la información:

```shell-session
$ curl -I inlanefreight.com
HTTP/1.1 301 Moved Permanently
Server: Apache/2.4.41 (Ubuntu)
Location: https://inlanefreight.com/

$ curl -I https://inlanefreight.com
HTTP/1.1 301 Moved Permanently
Server: Apache/2.4.41 (Ubuntu)
X-Redirect-By: WordPress
Location: https://www.inlanefreight.com/

$ curl -I https://www.inlanefreight.com
HTTP/1.1 200 OK
Server: Apache/2.4.41 (Ubuntu)
Link: <https://www.inlanefreight.com/index.php/wp-json/>; rel="https://api.w.org/"
```

Tres datos en tres peticiones: el servidor es `Apache/2.4.41 (Ubuntu)`, la redirección la hace `WordPress` (`X-Redirect-By`) y el path `wp-json` confirma WordPress. <mark style="background: #8000E1A6;">Una versión concreta de Apache es directamente consultable en bases de `CVE`</mark>.

# Detección de WAF con `wafw00f`

Antes de sondear a fondo, conviene saber si hay un `WAF` que pueda bloquear o falsear tus pruebas:

```shell-session
$ wafw00f inlanefreight.com
[*] Checking https://inlanefreight.com
[+] The site https://inlanefreight.com is behind Wordfence (Defiant) WAF.
```

<mark style="background: #FF5582A6;">Saber que hay un WAF (aquí Wordfence) cambia tu estrategia desde el minuto uno</mark>: tus payloads pueden ser filtrados, tus IPs baneadas, y necesitarás técnicas de evasión o un ritmo más lento. Ignorarlo lleva a falsos negativos ("la app no es vulnerable") cuando en realidad el WAF estaba bloqueando.

# `nikto` para fingerprinting

`nikto` es un escáner de servidores web; con `-Tuning b` ejecuta solo los módulos de identificación de software:

```shell-session
$ nikto -h inlanefreight.com -Tuning b

+ Server: Apache/2.4.41 (Ubuntu)
+ /index.php?: Uncommon header 'x-redirect-by' found, with contents: WordPress.
+ Apache/2.4.41 appears to be outdated (current is at least 2.4.59).
+ /license.txt: License file found may identify site software.
+ /: A Wordpress installation was found.
+ /wp-login.php: Wordpress login found.
```

Hallazgos accionables: servidor Apache **desactualizado** (mapeable a `CVE`), WordPress confirmado con su `/wp-login.php`, y un `license.txt` que filtra la versión exacta del software.

> [!info]+ Técnicas modernas que HTB omite
> - **Favicon hashing**: el hash `MMH3` del `favicon.ico` identifica frameworks y paneles con altísima precisión. En `Shodan`, `http.favicon.hash:<hash>` encuentra **todos** los hosts que sirven ese mismo favicon — vía brutal para localizar instancias de un mismo software. Detalle clave: Shodan hashea el favicon en **base64 con saltos de línea cada 76 caracteres** (`RFC 2045`), no el binario crudo —`mmh3.hash(base64.encodebytes(data))`— o el hash no cuadra. Y **no es portable**: `FOFA` y `Censys` usan esquemas de hash distintos.
> - **`httpx`**: sonda listas de hosts y devuelve servidor, tecnología (`-td`), título y código de estado en masa — el fingerprinting a escala del recon continuo.
> - **`nuclei -t technologies/`**: plantillas de detección de tecnología que además encadenan con plantillas de `CVE`.
> - **Cookies de framework**: `PHPSESSID` (PHP), `JSESSIONID` (Java), `laravel_session`, `csrftoken` (Django), `ci_session` (CodeIgniter) delatan el stack sin necesidad de más sondeo.

> [!important]+ De la versión al exploit
> El objetivo final del fingerprinting es el salto a la explotación: una vez tienes `software + versión`, `searchsploit <software> <versión>`, la base de datos de `CVE` y `nuclei` te dicen qué vulnerabilidades conocidas aplican. Un `Apache 2.4.41` o un [[01 - Enumeración de WordPress|`WordPress`]] con plugins viejos son puntos de partida directos.

Con el objetivo caracterizado, toca mapear su contenido navegándolo de forma estructurada: el [[10 - Crawling web]].
