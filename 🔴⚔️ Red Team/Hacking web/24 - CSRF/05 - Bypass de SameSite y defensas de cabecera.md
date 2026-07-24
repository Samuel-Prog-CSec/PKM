---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CSRF
Fecha de actualización: 2026-06-08
Nota previa: "[[04 - Bypass de tokens CSRF vía CORS]]"
Nota siguiente: "[[06 - Tokens CSRF débiles y CSRF con JSON]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Cuando no hay una [[03 - CORS Misconfigurations|CORS misconfiguration]] que explotar, quedan varias vías para sortear las defensas CSRF "modernas". Casi todas explotan un detalle: <mark style="background: #ADCCFFA6;">`SameSite` razona en términos de **site**, no de **origin**</mark>, y esa diferencia abre huecos.

# `site` ≠ `origin`

La [[02 - Same-Origin Policy y CORS|Same-Origin Policy]] distingue orígenes por scheme + host + **puerto**. `SameSite`, en cambio, razona por *site*, y <mark style="background: #FFB8EBA6;">el puerto y el subdominio **no** forman parte del site</mark>:

| Par de URLs | ¿Same-site? |
| - | - |
| `https://vuln.htb` y `https://sub.vuln.htb` | Sí (subdominio no cuenta) |
| `https://vuln.htb` y `https://vuln.htb:9001` | Sí (puerto no cuenta) |
| `http://vuln.htb` y `https://vuln.htb` | **No** (distinto scheme) |
| `https://vuln.htb` y `https://exploitserver.htb` | **No** (distinto site) |

<mark style="background: #8000E1A6;">Esto significa que un subdominio cuenta como same-site</mark>, y una petición desde él lleva las cookies aunque sea cross-origin — la base de dos de los bypass siguientes.

# Bypass de `Lax`: endpoints `GET` state-changing

`SameSite=Lax` (el valor por defecto) sí envía la cookie en navegaciones top-level seguras, es decir, peticiones `GET`. <mark style="background: #FF5582A6;">Si la aplicación tiene un endpoint que cambia estado por `GET` —o acepta `GET` en uno que debería ser `POST`— la protección `Lax` es inútil</mark>. Basta una navegación o un formulario `GET` auto-enviado para disparar la acción con la sesión de la víctima.

# Bypass de `Strict`: redirección client-side

`SameSite=Strict` no envía la cookie en **ninguna** petición cross-site, así que los trucos anteriores fallan. La vía es encadenar con una **redirección del lado cliente** en el propio sitio objetivo: como el redirect lo inicia el target site, la petición resultante se considera same-site y la cookie viaja.

Si la aplicación redirige con una etiqueta `meta` (client-side) y copia un parámetro controlable en la URL de destino, podemos inyectar parámetros extra. El `%26` es un `&` codificado que añade un segundo parámetro a la URL del redirect:

```html
<!-- Ojo con dónde corre esto: este redirect se ejecuta YA DENTRO de vulnerablesite.htb
     (la víctima ha llegado antes a una página del propio sitio, p. ej. vía un open redirect).
     Por eso la navegación a admin.php es same-site y la cookie SameSite=Strict SÍ viaja.
     Si lanzas el mismo document.location desde el exploit server del atacante (cross-site),
     la cookie Strict NO viaja y no funciona. Ese es el "salto" que hace falta. -->
<script>
document.location = "https://vulnerablesite.htb/admin.php?user=htb-stdnt%26promote=htb-stdnt";
</script>
```

> [!warning]+ Lo decisivo: quién origina la navegación
> El matiz real no es client-side vs server-side, sino que la petición al endpoint sensible la origine el **propio target site**. El caso habitual es un redirect del lado cliente (una etiqueta `<meta http-equiv="refresh">` o `document.location` en el HTML del target), pero también sirve un open-redirect del propio target que la víctima alcanza por navegación top-level: el redirect lo emite el target → la petición se considera same-site → la cookie `Strict` viaja. Lo que **no** sirve es un redirect alojado en el sitio del atacante. Detéctalo en el código fuente de la respuesta del target.

# Bypass vía XSS en un subdominio

Como los subdominios son same-site, <mark style="background: #FFB86CA6;">un XSS en cualquier subdominio (`guestbook.vulnerablesite.htb`) permite lanzar peticiones same-site contra el dominio principal</mark>, con la cookie de la víctima incluida — incluso con `SameSite=Strict`. Primero se enumeran subdominios:

```shell-session
$ gobuster vhost -k -u https://vulnerablesite.htb -w /path/to/SecLists/Discovery/DNS/subdomains-top1million-20000.txt
Found: guestbook.vulnerablesite.htb (Status: 200) [Size: 2317]
```

Y desde el XSS en el subdominio se dispara el CSRF contra el dominio padre:

```html
<script>
    var csrf_req = new XMLHttpRequest();
    csrf_req.open('POST', 'https://vulnerablesite.htb/profile.php', false);
    csrf_req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    csrf_req.withCredentials = true;
    csrf_req.send('promote=htb-stdnt');
</script>
```

Es el primer ejemplo de cómo un XSS reactiva ataques que las defensas modernas habían cerrado — el tema central del nivel [[00 - Introducción a la explotación XSS avanzada|XSS avanzado]].

# Bypass de validación de `Referer` / `Origin`

Cuando la defensa es comprobar la cabecera `Referer`, el fallo habitual es validar por **subcadena** en vez de por origen exacto. Si la app solo comprueba que `Referer` *contenga* `vulnerablesite.htb`, alojas el payload en una URL que incluya esa cadena:

```text
https://exploitserver.htb/vulnerablesite.htb/exploit
https://vulnerablesite.htb.exploitserver.htb/exploit
```

<mark style="background: #FF5582A6;">El mismo error que en la [[03 - CORS Misconfigurations|whitelist de CORS]]: comprobar prefijo/sufijo/subcadena en lugar del valor completo</mark>. Detéctalo manipulando el `Referer` en Repeater y observando hasta dónde afloja la validación.

Otra familia de bypass ataca el token en sí cuando es débil, o el formato del cuerpo cuando la app espera JSON: [[06 - Tokens CSRF débiles y CSRF con JSON]].

> [!info]+ Fuentes de referencia
> - [PortSwigger — Bypassing SameSite Restrictions](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions)
> - [web.dev — SameSite cookies explained](https://web.dev/articles/samesite-cookies-explained)
