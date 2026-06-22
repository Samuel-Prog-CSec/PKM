---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
Fecha de actualización: 2026-06-22
Nota previa: "[[00 - Introducción a los ataques server-side]]"
Nota siguiente: "[[02 - Identificación de SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
---

Una `Server-Side Request Forgery` (SSRF) ocurre cuando <mark style="background: #ADCCFFA6;">una aplicación web obtiene un recurso remoto a partir de datos que controla el usuario —típicamente una URL—</mark>. Si el atacante puede dictar esa URL, **coacciona al servidor para que haga peticiones a destinos arbitrarios** en su nombre. Es parte del [OWASP Top 10 (A10:2021)](https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29/), y su gravedad real no se intuye a primera vista.

# Por qué es devastador

La clave es **dónde está el servidor**. <mark style="background: #FFB86CA6;">El servidor vive dentro de la frontera de confianza</mark>: detrás del firewall, con visibilidad de servicios internos (bases de datos, paneles de administración, APIs sin autenticar, otros microservicios) y —en cloud— del endpoint de metadatos que custodia las credenciales de la instancia. Una petición que desde internet sería imposible, lanzada *desde* el servidor, atraviesa esas barreras. Por eso una SSRF "que solo pide una URL" puede acabar en lectura de la red interna, robo de credenciales cloud o ejecución de comandos en servicios internos.

# El factor decisivo: cuánto de la URL controlas

No todas las SSRF rinden igual. Lo que determina el alcance es qué parte de la URL es nuestra:

- **URL completa** (`?url=https://...`): control total. El caso ideal —podemos cambiar host, puerto y esquema—.
- **Solo el host/dominio** (la app fija el esquema y la ruta): aún sirve para apuntar a hosts internos, pero limita los trucos de esquema.
- **Solo la ruta** (host fijo): el más restringido; a veces explotable con [[05 - Evasión de defensas SSRF|path traversal o confusión de parser]].

<mark style="background: #FFB8EBA6;">Antes de elegir payload, identifica qué porción controlas</mark>: decide qué técnicas tienes disponibles.

# Los esquemas de URL: la segunda palanca

Si la app respeta el esquema que enviamos, manipularlo multiplica el impacto. Los más usados en SSRF:

- **`http://` / `https://`**: traer contenido por HTTP/S. Sirve para alcanzar endpoints internos, restringidos o sandbox, y para [[05 - Evasión de defensas SSRF|evadir WAFs]].
- **`file://`**: leer un fichero del sistema de ficheros local del servidor — convierte la SSRF en una [[01 - Local File Inclusion (LFI)|lectura de ficheros locales]] (`file:///etc/passwd`).
- **`gopher://`**: <mark style="background: #8000E1A6;">enviar **bytes arbitrarios** a un socket TCP</mark>. Es el esquema más potente: permite construir peticiones `POST` completas o hablar con servicios no-HTTP (SMTP, Redis, MySQL, FastCGI). Se trata a fondo en [[03 - Explotación de SSRF|explotación]].

Otros que aparecen según el cliente HTTP: `dict://`, `ftp://`, `ldap://`, `tftp://`. La superficie de esquemas depende de la librería que haga la petición (cURL soporta muchos; un cliente HTTP "puro" de Node o Go, casi ninguno).

# El premio en cloud: el endpoint de metadatos

<mark style="background: #FF5582A6;">El objetivo más valioso de una SSRF moderna es el servicio de metadatos de la instancia</mark>, accesible solo desde dentro en `http://169.254.169.254/`. En AWS, GCP y Azure expone configuración y —lo crítico— **credenciales temporales de IAM** de la máquina. Una SSRF que llegue ahí suele significar acceso a la cuenta cloud. Las particularidades por proveedor (incluido por qué AWS `IMDSv2` complica el ataque) están en [[05 - Evasión de defensas SSRF|evasión]].

# Dónde aparece hoy

HTB ilustra la SSRF con un parámetro `dateserver` que trae disponibilidad de otra máquina, pero el patrón se repite en funcionalidades muy comunes de 2026:

- **Webhooks** y callbacks configurables por el usuario.
- **Importadores "desde URL"** (importar un feed, una imagen, un documento).
- **Generadores de PDF / capturas** (HTML→PDF con Headless Chrome, wkhtmltopdf) que cargan recursos en el contexto del servidor.
- **Previsualizaciones de enlaces** (link unfurling) en chats y redes.
- **Arquitecturas de microservicios**, donde un servicio llama a otro por URL.
- **Parsers XML** con entidades externas: una [[Web Attacks|XXE]] suele degenerar en SSRF.

> [!warning]+ SSRF ciega: otro juego
> Si la respuesta de la petición forzada **no se nos devuelve**, estamos ante una [[04 - Blind SSRF|SSRF ciega]]: el impacto cae y la confirmación exige un canal **OOB** (Burp Collaborator / interactsh). No la descartes —sigue permitiendo barrer puertos internos y, a veces, atacar servicios a ciegas—.

> [!info]+ Fuentes
> - [OWASP Top 10 — A10:2021 SSRF](https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29/) · [PortSwigger — SSRF](https://portswigger.net/web-security/ssrf)
> - [PayloadsAllTheThings — Server Side Request Forgery](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)

Con el concepto claro, el primer paso en un objetivo real es **encontrar y confirmar** la SSRF, y usarla para mapear la red interna: [[02 - Identificación de SSRF]].
