---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
  - Tipo/Introduccion
Descripción: "Una Server-Side Request Forgery (SSRF) ocurre cuando una aplicación web obtiene un recurso remoto a partir de datos que controla el usuario —típicamente una URL—"
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
```javascript
// El servidor recibe el input del usuario
const userInput = req.query.url;

// El servidor hace la petición directamente a lo que introdujiste
const response = await axios.get(userInput);
```
- **Solo el host/dominio** (la app fija el esquema y la ruta): aún sirve para apuntar a hosts internos, pero limita los trucos de esquema.
```javascript
// El esquema (https://) y la ruta (/api/status) están fijados
const userInput = req.query.dominio;

// Tu input se concatena en medio de la URL base
const target = 'https://' + userInput + '/api/status';
const response = await axios.get(target);
```
- **Solo la ruta** (host fijo): el más restringido. El servidor sabe exactamente a qué máquina y con qué protocolo conectarse, y solo usa tu _input_ para buscar un recurso específico. A veces explotable con [[05 - Evasión de defensas SSRF|path traversal o confusión de parser]].
```javascript
// El servidor apunta a una API interna con una estructura fija
const baseURL = 'http://api.backend-interno.local/v1/recursos/';
const userInput = req.query.archivo;

// Tu input solo se añade al final de la ruta
const target = baseURL + userInput;
const response = await axios.get(target);
```

<mark style="background: #FFB8EBA6;">Antes de elegir payload, identifica qué porción controlas</mark>: decide qué técnicas tienes disponibles.

## ¿Cómo identificar qué porción controlamos?
En la práctica, la forma de clasificar el nivel de control consiste en **enviar la petición a un escuchador bajo tu control (OOB)** (como `netcat` o `interactsh`) y observar qué recibe tu servidor.

### Método práctico de clasificación
- **Paso 1: Probar si controlas la URL completa**
    - _Payload:_ <mark style="background: #ADCCFFA6;">Envías una URL absoluta con protocolo</mark>: `http://TU-IP-OOB:8000/prueba`.
    - _Resultado:_ Si en tu escuchador entra exactamente `GET /prueba HTTP/1.1`, o si al cambiar el protocolo a `file:///etc/passwd` lee el archivo local, controlas la **URL completa**.
- **Paso 2: Probar si solo controlas el Host/Dominio**
    - _Payload:_ <mark style="background: #ADCCFFA6;">Envías solo tu IP o dominio sin protocolo</mark>: `TU-IP-OOB:8000`.
    - _Resultado:_ Si en tu escuchador entra una petición del tipo `GET /api/v1/fetch HTTP/1.1` (con una ruta fija que tú no escribiste), la app concatena tu entrada en medio (`http://` + `INPUT` + `/ruta_fija`). Solo controlas el **Host/Dominio**.
- **Paso 3: Probar si solo controlas la Ruta**
    - _Payload:_ <mark style="background: #ADCCFFA6;">Si intentar meter tu IP externa falla o no genera ninguna conexión OOB</mark>, pruebas una<mark style="background: #FFB86CA6;"> ruta relativa o absoluta</mark>: `/admin.php` o `../admin.php`.
    - _Resultado:_ Si la <mark style="background: #FF5582A6;">aplicación responde devolviendo el contenido del recurso interno</mark>, el backend tiene el Host fijo (`http://servidor-interno/` + `INPUT`). Solo controlas la **Ruta**.

### Ejemplo práctico en un entorno real
Imagina que interceptas un parámetro `?avatar=...` en Burp Suite y tienes `netcat` escuchando en tu máquina (`nc -lnvp 8000`).

```HTTP
POST /user/profile HTTP/1.1
Host: app-vulnerable.com
Content-Type: application/x-www-form-urlencoded

avatar=http://10.10.14.5:8000/test
```

1. **Prueba A:** Envías `avatar=http://10.10.14.5:8000/test`.
    - _En Netcat entra:_ `GET /test HTTP/1.1`.
    - _Diagnóstico:_ **URL completa**. Tienes total libertad para probar esquemas como `gopher://` o `file://`.
2. **Prueba B:** Si la prueba A devuelve un error de "URL inválida", pruebas enviar `avatar=10.10.14.5:8000`.
    - _En Netcat entra:_ `GET /images/default.png HTTP/1.1`.
    - _Diagnóstico:_ **Solo Host/Dominio**. El código backend hace algo como `'https://' + input + '/images/default.png'`. No puedes usar `file://`, pero podrías intentar apuntar a `169.254.169.254` si esa ruta fija existe en el endpoint de metadatos.
3. **Prueba C:** Si las conexiones externas no llegan a tu Netcat, pruebas `avatar=/admin`.
    - _Respuesta en Burp:_ La aplicación devuelve el HTML del panel de administración interno.
    - _Diagnóstico:_ **Solo Ruta**. El backend apunta a un servidor interno fijo (`http://internal-api/` + `input`). Quedas limitado a _path traversal_ (`../../admin`) o a buscar otros endpoints en ese host.

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
- **Parsers XML** con entidades externas: una [[16 - XXE a RCE, SSRF y DoS|XXE]] suele degenerar en SSRF.

> [!warning]+ SSRF ciega: otro juego
> Si la respuesta de la petición forzada **no se nos devuelve**, estamos ante una [[04 - Blind SSRF|SSRF ciega]]: el impacto cae y la confirmación exige un canal **OOB** (Burp Collaborator / interactsh). No la descartes —sigue permitiendo barrer puertos internos y, a veces, atacar servicios a ciegas—.

> [!info]+ Fuentes
> - [OWASP Top 10 — A10:2021 SSRF](https://owasp.org/Top10/A10_2021-Server-Side_Request_Forgery_%28SSRF%29/) · [PortSwigger — SSRF](https://portswigger.net/web-security/ssrf)
> - [PayloadsAllTheThings — Server Side Request Forgery](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)

Con el concepto claro, el primer paso en un objetivo real es **encontrar y confirmar** la SSRF, y usarla para mapear la red interna: [[02 - Identificación de SSRF]].
