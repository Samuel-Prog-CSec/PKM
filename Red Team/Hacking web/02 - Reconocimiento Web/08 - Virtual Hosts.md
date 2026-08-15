---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "El DNS lleva el tráfico a la IP correcta; a partir de ahí, es el servidor web quien decide qué contenido servir"
Fecha de actualización: 2026-06-02
Nota previa: "[[07 - Certificate Transparency logs]]"
Nota siguiente: "[[09 - Fingerprinting web]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El DNS lleva el tráfico a la IP correcta; a partir de ahí, es el **servidor web** quien decide qué contenido servir. Apache, Nginx o IIS pueden alojar muchos sitios en una sola IP mediante `virtual hosting`. <mark style="background: #ADCCFFA6;">Un `Virtual Host` (VHost) es una configuración del servidor web que permite servir varios sitios distintos desde la misma IP</mark>, diferenciándolos por la cabecera HTTP `Host`.

# La cabecera `Host` como interruptor

Cuando pides `www.inlanefreight.com`, el navegador incluye ese nombre en la cabecera `Host` de la petición. El servidor la lee y sirve el sitio correspondiente:

1. El navegador hace la petición HTTP a la IP del dominio.
2. La cabecera `Host` indica **qué** sitio se pide.
3. El servidor consulta su configuración de *virtual hosts* y busca la entrada que coincide.
4. Sirve los ficheros del `DocumentRoot` de ese vhost.

![Diagrama de secuencia: el servidor elige el vhost según la cabecera Host de la petición](https://academy.hackthebox.com/storage/modules/144/ig_virtualhosts_1.png)

La cabecera `Host` <mark style="background: #ADCCFFA6;">funciona como un conmutador</mark>: una <mark style="background: #FFB8EBA6;">misma IP devuelve sitios completamente distintos según el nombre que envíes</mark>. Y no solo subdominios — <mark style="background: #FFB86CA6;">pueden ser dominios totalmente diferentes</mark>:

```xml
<VirtualHost *:80>
    ServerName www.example1.com
    DocumentRoot /var/www/example1
</VirtualHost>

<VirtualHost *:80>
    ServerName www.example2.org
    DocumentRoot /var/www/example2
</VirtualHost>
```

# VHost ≠ subdominio

La distinción es la que más confunde y la más importante para el recon:

| | Subdominio | Virtual Host |
| - | - | - |
| **Relación con DNS** | Tiene su propio registro DNS (`A`/`CNAME`) | Puede **no** tener registro DNS |
| **Cómo se descubre** | Resolviendo nombres (DNS bruteforce, CT, pasivo) | Fuzzeando la cabecera `Host` contra una IP conocida |
| **Visibilidad** | Público si resuelve | Puede ser interno/oculto |

<mark style="background: #FF5582A6;">Aquí está lo jugoso: muchos sitios tienen vhosts que **no** aparecen en DNS</mark> —entornos internos, paneles, *staging*— <mark style="background: #ADCCFFA6;">accesibles solo si envías el `Host` correcto a la IP</mark>. La enumeración de subdominios por DNS **nunca** los encontrará; <mark style="background: #FFB86CA6;">solo el `VHost fuzzing` los revela</mark>.

Si descubres un vhost sin registro DNS, lo accedes mapeándolo a la IP en tu fichero [[02 - DNS - fundamentos|`/etc/hosts`]]:

```text
10.129.42.190   forum.inlanefreight.htb
```

# Tipos de virtual hosting

- **Name-based**: distingue los sitios **solo** por la cabecera `Host`. Es el más común y flexible; no requiere varias IPs. Limitaciones históricas con `SSL/TLS` (resueltas por `SNI`, que envía el nombre del host en el handshake TLS; con `ECH`/`ESNI` —cada vez más en Cloudflare— ese `SNI` viaja cifrado y deja de verse en el tráfico). Al fuzzear vhosts por HTTPS necesitarás `-k` <mark style="background: #FFB8EBA6;">para ignorar el error de certificado</mark>, porque el del <mark style="background: #ADCCFFA6;">vhost por defecto no coincidirá con el `Host` que inyectas</mark>.
- **IP-based**: <mark style="background: #ADCCFFA6;">una IP distinta por sitio</mark>. No depende del `Host`, funciona con cualquier protocolo y aísla mejor, pero gastar IPs es caro y poco escalable.
- **Port-based**: <mark style="background: #ADCCFFA6;">cada sitio en un puerto distinto de la misma IP</mark> (80, 8080…). Sirve cuando faltan IPs, pero obliga al usuario a indicar el puerto.

# Descubrimiento con `gobuster`

`gobuster vhost` envía peticiones con distintas cabeceras `Host` a la IP y analiza las respuestas para detectar vhosts válidos:

```shell-session
$ gobuster vhost -u http://inlanefreight.htb:81 \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
  --append-domain

Found: forum.inlanefreight.htb:81 Status: 200 [Size: 100]
[...]
```

**Flags relevantes**:

- `--append-domain`: <mark style="background: #ADCCFFA6;">añade el dominio base a cada palabra</mark> de la `wordlist` (requerido en versiones modernas para construir el vhost completo).
- `-t`: <mark style="background: #FFB8EBA6;">más hilos</mark>, escaneo más rápido.
- `-k`: <mark style="background: #FFB86CA6;">ignora errores de certificado</mark> `SSL/TLS`.
- `-o`: guarda la salida a fichero.

`feroxbuster` (en Rust, muy rápido) y `ffuf` (fuzzeando la cabecera `Host`) hacen lo mismo. El detalle fino —cómo filtrar la respuesta por defecto del servidor para eliminar falsos positivos— es el núcleo del [[20 - Fuzzing de vhosts y subdominios]].

> [!warning]+ Falsos positivos y baseline
> El servidor responde **a todo** con su vhost por defecto, así que un barrido ingenuo marca como "encontrados" todos los nombres. La clave es establecer una *baseline* (tamaño/código de la respuesta por defecto) y filtrar todo lo que coincida con ella. `ffuf -fs <tamaño>` y los filtros de `gobuster` existen precisamente para esto — se detalla en [[20 - Fuzzing de vhosts y subdominios]] y [[21 - Filtrado de la salida de fuzzing]].

> [!warning]+ Ruido y autorización
> El `VHost fuzzing` genera mucho tráfico y lo detectan IDS y WAF con facilidad. Confirma autorización y alcance antes de lanzarlo.

Con el inventario de hosts y vhosts construido, el siguiente paso es caracterizar **qué** corre en cada uno: el [[09 - Fingerprinting web]].
