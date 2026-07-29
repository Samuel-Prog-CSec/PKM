---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "El *Nmap Scripting Engine* (NSE) permite ejecutar scripts en Lua que interactúan con los servicios detectados: desde leer un banner hasta hacer *brute force*, comprobar CVEs o…"
Fecha de actualización: 2026-07-18
Nota previa: "[[03 - Enumeración de servicios y versiones]]"
Nota siguiente: "[[05 - Rendimiento y timing]]"
Area: "[[Nmap.base|Nmap]]"
---
---

<mark style="background: #ADCCFFA6;">El *Nmap Scripting Engine* (NSE) permite ejecutar scripts en Lua que interactúan con los servicios detectados</mark>: desde leer un banner hasta hacer *brute force*, comprobar CVEs o explotar un fallo conocido. Convierte a Nmap de un escáner de puertos en una navaja suiza de enumeración. Los scripts (`.nse`) viven en `/usr/share/nmap/scripts/`, y `--script-help <nombre>` documenta cualquiera.

# Las 14 categorías

Cada script pertenece a una o varias categorías. Conocerlas evita disparar algo destructivo por accidente:

| Categoría | Qué hace |
| --- | --- |
| `auth` | Trata credenciales de autenticación. |
| `broadcast` | Descubre hosts por *broadcast* y los añade al escaneo. |
| `brute` | Fuerza credenciales contra el servicio. |
| `default` | Los que ejecuta `-sC`. |
| `discovery` | Evalúa servicios accesibles (extrae info). |
| `dos` | Prueba *denial of service* — **daña el servicio**, casi nunca se usa. |
| `exploit` | Intenta explotar vulnerabilidades conocidas. |
| `external` | Usa servicios externos (ej. bases de datos online). |
| `fuzzer` | Envía campos malformados buscando fallos — lento. |
| `intrusive` | Puede afectar negativamente al sistema objetivo. |
| `malware` | Detecta si el objetivo está infectado. |
| `safe` | Defensivos, no intrusivos ni destructivos. |
| `version` | Extensión de la detección de versión. |
| `vuln` | Identifica vulnerabilidades concretas. |

# Cómo invocar scripts

```shell-session
$ sudo nmap <target> -sC                              # scripts 'default'
$ sudo nmap <target> --script <categoría>             # toda una categoría (p.ej. vuln)
$ sudo nmap <target> --script <script1>,<script2>     # scripts concretos
```

Ejemplo dirigido al SMTP, combinando dos scripts:

```shell-session
$ sudo nmap 10.129.2.28 -p 25 --script banner,smtp-commands

PORT   STATE SERVICE
25/tcp open  smtp
|_banner: 220 inlane ESMTP Postfix (Ubuntu)
|_smtp-commands: inlane, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN, SMTPUTF8,
```

<mark style="background: #FFB86CA6;">`smtp-commands` revela que `VRFY` está activo</mark> → posible enumeración de usuarios del sistema. Ese es el valor del NSE: no solo detecta, sino que interroga la lógica del servicio.

## El escaneo agresivo `-A`

`-A` es un atajo que agrupa detección de versión (`-sV`), de SO (`-O`), `--traceroute` y los scripts `default` (`-sC`) de golpe:

```shell-session
$ sudo nmap 10.129.2.28 -p 80 -A

80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-generator: WordPress 5.3.4
|_http-title: blog.inlanefreight.com
```

En una pasada saca servidor (`Apache 2.4.29`), aplicación (`WordPress 5.3.4`) y título. <mark style="background: #FF5582A6;">`-A` es potentísimo pero de todo menos sigiloso</mark>: mete OS fingerprinting, traceroute y una batería de scripts que cualquier IDS marca al instante. Úsalo en cajas blancas o cuando el sigilo no importa, nunca como primer toque a un objetivo sensible.

# La categoría `vuln` y `vulners`

`--script vuln` lanza todos los scripts de identificación de vulnerabilidades. Combinado con `vulners` (que cruza el CPE contra la base de [vulners.com](https://vulners.com)), obtienes CVEs directamente:

```shell-session
$ sudo nmap 10.129.2.28 -p 80 -sV --script vuln

| http-enum:
|   /wp-login.php: Possible admin folder
|_  /: WordPress version: 5.3.4
| http-wordpress-users:
|_  Username found: admin
| vulners:
|   cpe:/a:apache:http_server:2.4.29:
|     CVE-2019-0211  7.2  https://vulners.com/cve/CVE-2019-0211
|_    CVE-2017-15715 6.8  https://vulners.com/cve/CVE-2017-15715
```

`http-enum`, `http-wordpress-users` (enumera usuarios — enlaza con [[01 - Enumeración de WordPress|WordPress]]) y `vulners` en una sola orden. Esto es ya *vulnerability assessment* embrionario — ver [[01 - Evaluación de vulnerabilidades|Evaluación de vulnerabilidades]].

> [!warning]+ `vuln`, `exploit` y `dos` NO son inocuos
> `-sC` es relativamente seguro, pero `--script vuln`/`exploit`/`brute` **tocan la capa de aplicación**, generan tráfico anómalo y pueden tumbar servicios frágiles o disparar bloqueos de IPS/WAF. La categoría `dos` directamente rompe el servicio. En bug bounty y en producción: nunca lances `dos`/`exploit` sin autorización explícita, y acota `vuln`/`brute` a lo imprescindible.

# Enfoque profesional 2026

- **Mantener la base al día**: `sudo nmap --script-updatedb` tras instalar scripts nuevos. `vulners` y `vulscan` (bases de CVE externas) hay que clonarlos a la carpeta de scripts; sin actualizar, sus resultados envejecen rápido.
- **Parámetros**: `--script-args` afina un script (`--script http-wordpress-users --script-args http-wordpress-users.limit=50`).
- **Alternativas modernas**: para *vuln scanning* real, `nuclei` (plantillas comunitarias actualizadas a diario) ha desplazado en gran medida a los scripts `vuln` de NSE, que están algo anticuados; `vulners` sí sigue siendo útil como primer cruce CVE. Todo esto, en [[09 - Arsenal de herramientas de escaneo]].
- **Detección**: los scripts `brute`/`vuln`/`exploit` son de lo más ruidoso que puede lanzar Nmap — desarrollo en [[08 - Detección de escaneos y evasión moderna]].

Catálogo completo de scripts: [nmap.org/nsedoc/index.html](https://nmap.org/nsedoc/index.html).
