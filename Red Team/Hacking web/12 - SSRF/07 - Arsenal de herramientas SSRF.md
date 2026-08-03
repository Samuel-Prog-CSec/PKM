---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Server-Side/SSRF
  - Tipo/Arsenal
Descripción: "Herramientas que cubren el ciclo de la SSRF: confirmación OOB → enumeración interna → explotación con gopher:// → fuzzing de bypasses → DNS rebinding"
Fecha de actualización: 2026-06-22
Nota previa: "[[06 - Prevención de SSRF]]"
Nota siguiente: ""
Area: "[[SSRF.base|SSRF]]"
---
---

Herramientas que cubren el ciclo de la SSRF: confirmación **OOB** → enumeración interna → explotación con `gopher://` → fuzzing de bypasses → DNS rebinding. <mark style="background: #FFB8EBA6;">El trabajo manual sigue mandando para confirmar y entender el contexto</mark>; las herramientas automatizan lo repetitivo. Estado verificado a 2026.

# Confirmación OOB y enumeración

```shell-session
# interactsh — canal OOB (DNS/HTTP) para confirmar SSRF, sobre todo ciega
$ interactsh-client -v
# Inyectar la URL <subdominio>.oast.pro en el parámetro; un lookup ya confirma

# ffuf — port scan interno a través de la SSRF (filtra el error de puerto cerrado)
$ seq 1 10000 > ports.txt
$ ffuf -w ports.txt -u http://target/index.php -X POST \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "dateserver=http://127.0.0.1:FUZZ/&date=2024-01-01" -fr "Failed to connect to"
```

`Burp Collaborator` es el equivalente de pago a `interactsh` y captura la petición completa que envió el servidor —útil como evidencia para el informe—.

# Explotación automatizada: SSRFmap

[`SSRFmap`](https://github.com/swisskyrepo/SSRFmap) (Python 3, **funcional aunque poco actualizada**) automatiza la explotación a partir de una petición de Burp con el parámetro vulnerable marcado. Cubre los vectores de alto impacto en módulos:

```shell-session
$ python3 ssrfmap.py -r request.txt -p url -m readfiles,portscan
$ python3 ssrfmap.py -r request.txt -p url -m redis        # RCE vía Redis
$ python3 ssrfmap.py -r request.txt -p url -m aws           # credenciales IAM (metadata)
```

Módulos destacados: `portscan`, `networkscan`, `readfiles` (`file://`), `redis`/`fastcgi`/`mysql`/`smtp` (gopher → RCE/interacción), `aws`/`gce`/`digitalocean`/`alibaba` (metadata cloud), `axfr`, `tomcat`.

# Payloads gopher: Gopherus

[`Gopherus`](https://github.com/tarunkant/Gopherus) genera la URL `gopher://` por servicio (MySQL, PostgreSQL, FastCGI, Redis, SMTP, Zabbix, memcache). <mark style="background: #FFB86CA6;">Imprescindible para convertir una SSRF en RCE</mark> vía un servicio interno sin auth. El original está **abandonado y en Python 2**; usa el fork mantenido [`Gopherus3`](https://github.com/Esonhugh/Gopherus3) (Python 3):

```shell-session
$ python3 gopherus.py --exploit redis     # Gopherus3
$ python3 gopherus.py --exploit fastcgi
```

> [!warning]+ `gopher://` depende de la librería HTTP, no del lenguaje
> Lo habla **libcurl** (cURL, PHP, y `pycurl` en Python) y **Java**; **no** lo soportan `requests`/`httpx`/`urllib` de Python ni `axios`/`fetch` de Node. La regla es **qué librería** hace la petición: un stack Python con `pycurl` sí es vulnerable al vector gopher; con `requests`, no. Confírmalo antes de generar el payload.

# Fuzzing de bypasses y DNS rebinding

```shell-session
# recollapse — muta una URL base para encontrar bypasses de parser (Orange Tsai)
$ recollapse -e 1 -r 0,0xff "https://expected.com/"

# Singularity of Origin (NCC) — framework de DNS rebinding contra servicios internos
$ git clone https://github.com/nccgroup/singularity
```

- [`recollapse`](https://github.com/0xacb/recollapse) (Python 3): genera variaciones (encoding, bytes, mayúsculas) de una URL para destapar la discrepancia validador↔cliente HTTP.
- [`Singularity of Origin`](https://github.com/nccgroup/singularity): automatiza el [[05 - Evasión de defensas SSRF|DNS rebinding]] cuando el allowlist valida el host pero re-resuelve la IP.

# Wordlists y payloads

| Recurso | Uso |
| - | - |
| [PayloadsAllTheThings — SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery) | Payloads de bypass (IP encodings, parser confusion, cloud metadata) |
| SecLists — `Fuzzing/` + `Discovery/Web-Content` | Puertos, endpoints internos, parámetros |
| Rutas de metadata por proveedor (AWS/GCP/Azure) | Exfiltración de credenciales |

# Estado de mantenimiento (2026)

| Herramienta | Lenguaje | Estado | Uso |
| - | - | - | - |
| **interactsh** | Go | ✅ Activa | OOB (DNS/HTTP) para SSRF ciega |
| **ffuf** | Go | ✅ Activa | Port scan / enum interno vía SSRF |
| **SSRFmap** | Python 3 | 🟡 Funcional (poco activa) | Explotación automatizada (módulos) |
| **recollapse** | Python 3 | ✅ Activa | Fuzzing de bypasses de parser de URL |
| **Singularity of Origin** | Go/JS | ✅ Activa | DNS rebinding |
| **Gopherus3** (fork) | Python 3 | 🟡 Disponible | Generar payloads `gopher://` (el original `Gopherus` py2 está abandonado) |
| **Nuclei** | Go | ✅ Activa | Plantillas SSRF automatizadas (integra interactsh) |

> [!warning]+ A mano primero
> Como con [[10 - Arsenal de herramientas para File Upload|cualquier arsenal]]: confirma y entiende el contexto a mano (qué controlas de la URL, refleja o es ciega, qué esquema admite el cliente) antes de lanzar `SSRFmap` a saco. Un escáner a ciegas dispara WAFs y *rate limits*.

> [!info]+ Fuentes
> - [SSRFmap](https://github.com/swisskyrepo/SSRFmap) · [Gopherus](https://github.com/tarunkant/Gopherus) · [recollapse](https://github.com/0xacb/recollapse) · [Singularity of Origin](https://github.com/nccgroup/singularity)
> - [interactsh](https://github.com/projectdiscovery/interactsh) · [PayloadsAllTheThings — SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)

Con el arsenal se cierra el sub-tema **SSRF**. La MOC lo agrupa: [[SSRF.base|SSRF]]. El siguiente sub-tema server-side es la inyección en motores de plantillas: [[00 - Motores de plantillas e introducción a SSTI|SSTI]].
