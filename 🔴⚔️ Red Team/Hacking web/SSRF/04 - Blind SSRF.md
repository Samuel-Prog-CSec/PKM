---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
Fecha de actualización: 2026-06-22
Nota previa: "[[03 - Explotación de SSRF]]"
Nota siguiente: "[[05 - Evasión de defensas SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
---

En muchas SSRF reales <mark style="background: #ADCCFFA6;">la respuesta de la petición forzada **no se nos devuelve**</mark>. Son las SSRF **ciegas**: sabemos que el servidor hace la petición, pero no vemos su contenido. Eso anula casi toda la [[03 - Explotación de SSRF|explotación directa]] —que dependía de leer la respuesta— y reduce bastante el impacto. Aun así, no es un callejón sin salida.

# Identificar una SSRF ciega

Se confirma igual que cualquier SSRF: apuntando la app a un sistema propio y recibiendo la conexión (idealmente vía [[02 - Identificación de SSRF|OOB con interactsh/Collaborator]]):

```shell-session
$ nc -lnvp 8000
listening on [any] 8000 ...
connect to [172.17.0.1] from (UNKNOWN) [172.17.0.2] 32928
GET /index.php HTTP/1.1
Host: 172.17.0.1:8000
```

La diferencia se ve al apuntar la app **a sí misma** (`http://127.0.0.1/index.php`): si la respuesta **no** trae el HTML de la aplicación —solo un mensaje genérico como *"date unavailable"*— estamos ante una SSRF ciega. <mark style="background: #FFB86CA6;">El canal OOB pasa a ser obligatorio</mark>: sin él no hay forma de confirmar siquiera que la petición sale.

# Qué se puede hacer a ciegas

La explotación es limitada pero no nula. La palanca es cualquier **diferencia observable** en la respuesta (mensaje de error, código de estado, tiempo) entre dos casos.

**Port scan interno por diferencia de error.** Si un puerto cerrado da `Something went wrong!` y uno abierto (que responde HTTP válido) da el mensaje de *"date unavailable"*, podemos distinguirlos y barrer puertos:

```
puerto cerrado  → "Something went wrong!"
puerto abierto  → "date unavailable"   (respuesta HTTP válida)
```

<mark style="background: #FFB8EBA6;">Limitación clave: solo detectamos servicios que devuelven HTTP válido</mark>. Un MySQL en `3306`, que no habla HTTP, provoca el mismo error que un puerto cerrado → invisible por esta vía.

**Existencia de ficheros.** El mismo principio con `file://`: si el mensaje difiere entre un fichero que existe y uno que no, enumeramos el sistema de ficheros (sin leer contenido):

```
file:///etc/passwd        → "date unavailable"     (existe)
file:///etc/noexiste      → "Something went wrong!" (no existe)
```

**Interacción a ciegas con servicios internos.** Aunque no veamos la respuesta, las peticiones **llegan**. <mark style="background: #FF5582A6;">Un payload `gopher://` a un Redis interno escribe igual aunque no leamos la salida</mark>: si conocemos el efecto deseado (escribir un cron, una webshell), una SSRF ciega contra un servicio sin autenticar sigue dando RCE. La SSRF ciega "a oscuras" se explota lanzando payloads conocidos contra servicios probables.

# Subir el impacto de una ciega

Más allá de lo que cubre HTB, en un objetivo real una SSRF ciega aún rinde:

- **Exfiltración por DNS**: si controlamos un dominio, codificar datos en el subdominio del lookup (`<datos>.attacker.oast.fun`) saca información aunque el HTTP de salida esté cerrado. El [[02 - Identificación de SSRF|oráculo OOB]] captura el DNS.
- **Cloud metadata + redirect**: una ciega puede no devolver el token IAM, pero encadenada con un endpoint que **refleje** o exfiltre por OOB, sí. Las técnicas por proveedor (incl. el reto de `IMDSv2`) están en [[05 - Evasión de defensas SSRF|evasión]].
- **CSRF interno**: forzar acciones de cambio de estado en endpoints internos `GET` (o `POST` vía gopher) sin necesidad de leer la respuesta.

> [!important]+ La ciega no es "no explotable"
> El error más común es descartar una SSRF ciega. Sigue permitiendo <mark style="background: #8000E1A6;">mapear la red interna, enumerar ficheros y atacar servicios internos a ciegas</mark>. Documenta el alcance real: incluso sin lectura, el acceso a la red interna es un hallazgo serio.

> [!info]+ Fuentes
> - [PortSwigger — Blind SSRF](https://portswigger.net/web-security/ssrf/blind) · [PortSwigger Research — Cracking the lens (blind SSRF)](https://portswigger.net/research/cracking-the-lens-targeting-https-hidden-attack-surface)
> - [HackTricks — SSRF](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery) · [interactsh](https://github.com/projectdiscovery/interactsh)

Tanto en SSRF ciega como reflejada, en producción chocaremos con allowlists, filtros de IP y protecciones de metadatos. Sortearlos es la [[05 - Evasión de defensas SSRF]].
