---
tags:
  - Pentesting/Enumeracion
  - Recon
  - Web/Red-Team
Descripción: "De una lista de hosts y puertos a un inventario web con status, título, tecnología, hash de favicon y captura de pantalla"
Fecha de actualización: 2026-08-04
Nota previa: "[[04 - naabu - descubrimiento de puertos]]"
Nota siguiente: "[[06 - tlsx - inteligencia desde TLS]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

<mark style="background: #ADCCFFA6;">`httpx` convierte una lista de hosts en un inventario de superficie web</mark>: qué responde HTTP, con qué código, qué título tiene, qué tecnología corre debajo y a qué IP resuelve. Es la herramienta más usada de la suite y la que más tiempo ahorra, porque sustituye el trabajo de abrir cientos de URLs a mano.

```shell-session
$ cat hosts.txt | httpx -silent
$ cat hosts.txt | httpx -silent -sc -title -tech-detect -ip -cname
$ naabu -l hosts.txt -silent | httpx -silent -json -o web.jsonl
```

# Las sondas que valen la pena

```shell-session
$ cat hosts.txt | httpx -silent -sc -cl -title -server -td -ip -asn -json -o inventario.jsonl
```

| Flag | Qué añade | Por qué importa |
| --- | --- | --- |
| `-sc`, `-status-code` | Código HTTP | Lo básico. `401`/`403` marcan lo interesante. |
| `-title` | `<title>` de la página | Identifica el panel de un vistazo: "Grafana", "phpMyAdmin", "Jenkins". |
| `-td`, `-tech-detect` | Tecnologías (dataset de Wappalyzer) | Inventario para cruzar con CVEs. |
| `-server`, `-web-server` | Cabecera `Server` | Versiones concretas. |
| `-ip`, `-cname`, `-asn` | IP, CNAME y ASN | Separar cliente de terceros. |
| `-cdn` | CDN/WAF detectado (**activo por defecto**) | Saber qué tienes delante. |
| `-favicon` | Hash **MMH3** del `favicon.ico` | Ver abajo — es más potente de lo que parece. |
| `-jarm` | Huella JARM | Agrupar hosts por pila TLS. |
| `-hash` | Hash del cuerpo (md5, mmh3, simhash, sha1/256/512) | Agrupar páginas idénticas. |
| `-location` | Destino del redirect | Ver a dónde te mandan sin seguirlo. |
| `-bp`, `-body-preview` | Primeros N caracteres | Contexto sin descargar todo. |
| `-websocket`, `-http2`, `-pipeline` | Capacidades del servidor | Superficie adicional. |

## El hash de favicon: el atajo infravalorado

`-favicon` calcula el hash MMH3 del `favicon.ico`. <mark style="background: #8000E1A6;">Ese hash es un identificador casi único de la aplicación</mark>, y como Shodan lo indexa (`http.favicon.hash:`), permite dos jugadas:

1. **Identificar** qué producto corre en un host que no dice nada más (sin título, sin cabecera `Server`, `403` en todo).
2. **Encontrar el resto de instalaciones** del mismo producto en Internet, o el **origen real** de un host tras CDN: la IP de origen sirve el mismo favicon que el dominio protegido ([[28 - Origen real tras WAF, CDN y balanceadores]]).

```shell-session
$ cat hosts.txt | httpx -silent -favicon
$ cat hosts.txt | httpx -silent -mfc 1234567890        # solo los de ese favicon
```

## Capturas de pantalla

```shell-session
$ cat hosts.txt | httpx -silent -ss -srd ./capturas/
$ cat hosts.txt | httpx -silent -ss -system-chrome -esb -json -o web.jsonl
```

`-ss/-screenshot` levanta un Chrome headless y guarda la imagen de cada host. Con cientos de subdominios, **mirar una hoja de contactos de capturas es la forma más rápida que existe de encontrar el panel olvidado**. `-esb` saca los bytes de la imagen del JSON (si no, el fichero se dispara) y `-svrc` agrupa por similitud visual.

# Matchers y filtros: quedarse con lo que importa

La familia de flags que convierte 5.000 hosts en 20 que mirar.

```shell-session
$ cat hosts.txt | httpx -silent -mc 200,302,401,403
$ cat hosts.txt | httpx -silent -fc 404,400
$ cat hosts.txt | httpx -silent -ms "admin"
$ cat hosts.txt | httpx -silent -mr "(?i)(api[_-]?key|secret)"
$ cat hosts.txt | httpx -silent -fd
$ cat hosts.txt | httpx -silent -fpt login,captcha,parked
$ cat hosts.txt | httpx -silent -mdc "status_code==200 && contains(body,'jenkins')"
```

| Familia | `-m*` (quedarse) | `-f*` (descartar) |
| --- | --- | --- |
| Código | `-mc` | `-fc` |
| Longitud | `-ml` | `-fl` |
| Líneas / palabras | `-mlc` / `-mwc` | `-flc` / `-fwc` |
| Cadena / regex | `-ms` / `-mr` | `-fs` / `-fe` |
| Favicon | `-mfc` | `-ffc` |
| CDN | `-mcdn` | `-fcdn` |
| Tiempo de respuesta | `-mrt` | `-frt` |
| Condición DSL | `-mdc` | `-fdc` |

Dos que ahorran horas y casi nadie usa:

- **`-fd`, `-filter-duplicates`** — descarta páginas casi idénticas. En un objetivo con 400 subdominios sirviendo la misma landing, deja los que son distintos de verdad.
- **`-fpt`, `-filter-page-type`** — filtra por tipo: `login`, `captcha`, `parked`. <mark style="background: #FFB86CA6;">Quitar los dominios aparcados de un recon de bug bounty limpia la mitad del ruido</mark>.

Y el extractor, para sacar datos del cuerpo en la misma pasada:

```shell-session
$ cat hosts.txt | httpx -silent -er "(?i)aws_access_key_id\s*=\s*\S+"
$ cat hosts.txt | httpx -silent -ep url,mail
$ cat hosts.txt | httpx -silent -efqdn        # dominios nuevos desde la respuesta
```

`-efqdn` realimenta el pipeline: los dominios que aparecen en las respuestas vuelven a entrar por `dnsx`.

# Ritmo, cabeceras y proxy

| Flag | Por defecto |
| --- | --- |
| `-t`, `-threads` | **50** |
| `-rl`, `-rate-limit` | **150** req/s |
| `-timeout` | **10** s |
| `-delay` | — (`200ms`, `1s`…) |
| `-random-agent` | **activado** |
| `-maxhr`, `-max-host-error` | **30** errores antes de saltar el host |

```shell-session
$ cat hosts.txt | httpx -silent -rl 10 -t 5 -delay 500ms
$ cat hosts.txt | httpx -silent -H "X-Bug-Bounty: usuario-h1" -H "User-Agent: recon"
$ cat hosts.txt | httpx -silent -proxy http://127.0.0.1:8080
$ cat hosts.txt | httpx -silent -x all -path /admin,/.git/config
```

> [!important]+ Identifícate en bug bounty
> <mark style="background: #FF5582A6;">Muchos programas **exigen** una cabecera identificativa</mark> (`X-Bug-Bounty: <tu-handle>`) para poder distinguir tu tráfico de un ataque real. Es la diferencia entre que el equipo azul te ignore y que llamen a un incidente. `-H` es el flag, y añadirlo cuesta cero ([[01 - Reglas, legalidad y conducta]]).

> [!warning]+ Los defaults son de "ir rápido", no de "no molestar"
> **150 req/s con 50 hilos** es agresivo contra la mayoría de objetivos. Sumado a `-x all` (probar todos los métodos HTTP) y `-path`, un `httpx` mal calibrado es indistinguible de un ataque. Para bug bounty: `-rl 10 -t 5 -delay 500ms` y a partir de ahí, sube si el programa lo permite.

`-proxy http://127.0.0.1:8080` manda todo por [[Burp Suite|Burp]] o [[ZAP.base|ZAP]], que es como se convierte un recon en un objetivo de pruebas manual ([[Proxies web.base|proxies web]]).

# Salida

```shell-session
$ cat hosts.txt | httpx -silent -json -o web.jsonl
$ cat hosts.txt | httpx -silent -csv -o web.csv
$ cat hosts.txt | httpx -silent -sr -srd ./respuestas/     # guardar cada respuesta
$ cat hosts.txt | httpx -silent -oa -o inventario           # todos los formatos
```

`-sr/-store-response` guarda la respuesta completa de cada host en disco. Es lo que convierte el recon en **evidencia**: cuando reportes algo, tienes la respuesta original con su fecha, sin depender de que el objetivo siga igual.

> [!info]+ Fuente
> [README de httpx](https://github.com/projectdiscovery/httpx) — sondas, matchers/filtros/extractores, flags de headless, defaults (`-t 50`, `-rl 150`, `-timeout 10`, `-random-agent` y `-cdn` activos, `-maxhr 30`) y la advertencia del propio proyecto sobre qué flags no conviene usar por defecto (`-ports`, `-path`, `-vhost`, `-screenshot`, `-favicon`, `-http2`…). Técnica relacionada en [[09 - Fingerprinting web]].
