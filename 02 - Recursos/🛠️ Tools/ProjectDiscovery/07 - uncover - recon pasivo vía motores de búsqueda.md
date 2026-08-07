---
tags:
  - Pentesting/Enumeracion
  - Recon
  - OSINT
Descripción: "Preguntar a quince buscadores de dispositivos desde la terminal: el escaneo que otro ya hizo por ti, sin mandar un paquete"
Fecha de actualización: 2026-08-04
Nota previa: "[[06 - tlsx - inteligencia desde TLS]]"
Nota siguiente: "[[08 - notify y automatización del pipeline]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

<mark style="background: #ADCCFFA6;">`uncover` es un envoltorio sobre las APIs de los buscadores de dispositivos expuestos</mark>: haces una consulta, la lanza contra varios motores a la vez y devuelve `ip:puerto` listo para encadenar. La mejor evasión sigue siendo no escanear, y esta es la herramienta que la materializa dentro del pipeline.

```shell-session
$ echo 'ssl:"ACME Technologies, Inc."' | uncover
$ echo jira | uncover -e shodan,censys,fofa,quake,hunter,zoomeye
$ uncover -q 'org:"ACME Inc."' -silent | httpx -silent | nuclei -severity critical,high
```

# Los motores

Integra cerca de una veintena de proveedores: **Shodan**, **Shodan-InternetDB**, **Censys**, **FOFA**, **Quake**, **Hunter**, **ZoomEye**, **Netlas**, **CriminalIP**, **BinaryEdge**, **GreyNoise**, **PublicWWW**, **HunterHow**, **Google**, **ODIN**, **Onyphe**, **Driftnet**, **DayDayMap** y **NerdyData**.

<mark style="background: #FFB8EBA6;">Consultar varios a la vez no es redundante: cada uno escanea con su propia cadencia, su propio conjunto de puertos y su propia cobertura geográfica</mark>. FOFA y Quake tienen mucho mejor cubierta Asia; Censys destaca en TLS y certificados; PublicWWW y NerdyData indexan el **código fuente** de las páginas, que es otra cosa completamente distinta.

```shell-session
$ uncover -q 'http.title:"Grafana"' -e shodan,censys,fofa -l 500 -silent
```

## Configuración de claves

```yaml
# ~/.config/uncover/provider-config.yaml
shodan:
  - API_KEY_1
  - API_KEY_2
censys:
  - API_TOKEN:ORGANIZATION_ID
fofa:
  - EMAIL:KEY
```

Admite **varias claves por proveedor** —las rota— y también variables de entorno (`SHODAN_API_KEY`, `CENSYS_API_TOKEN`…).

> [!important]+ `shodan-idb` es gratis y no necesita clave
> La API **InternetDB** de Shodan es pública y sin autenticación: devuelve puertos, CPEs, hostnames y CVEs conocidas de una IP. Es la misma fuente que usan `naabu -passive` y [[00 - Smap - escaneo pasivo con datos de Shodan|Smap]]. <mark style="background: #8000E1A6;">Da el 80 % del valor con el 0 % del coste</mark>, así que es por donde empezar antes de pagar nada.

# Flags

| Flag | Uso |
| --- | --- |
| `-q`, `-query` | La consulta (también por `stdin` o fichero). |
| `-e`, `-engine` | Motores a usar (por defecto **shodan**). |
| `-f`, `-field` | Campos de salida: `ip`, `port`, `host` — **con plantilla**. |
| `-l`, `-limit` | Resultados (por defecto **100**). |
| `-json` | JSONL. |
| `-o` | Fichero de salida. |
| `-silent` | Solo resultados. |
| `-shodan`, `-censys`, `-fofa`… | Consulta específica por motor. |

## Plantillas en `-f`

```shell-session
$ uncover -q jira -f host -silent
$ uncover -q jira -f 'https://ip:port/login' -silent
```

<mark style="background: #8000E1A6;">`-f` sustituye `ip`, `port` y `host` dentro de una cadena arbitraria</mark>, así que la salida sale ya con la forma que necesita la herramienta siguiente. Es lo que evita el `awk`/`sed` de pegamento entre etapas.

## Consultas específicas por motor

La sintaxis de búsqueda **no es la misma** en todos los proveedores, y por eso hay flags dedicados:

```shell-session
$ uncover -shodan 'http.favicon.hash:-1234567890' -silent
$ uncover -censys 'services.tls.certificates.leaf_data.subject.common_name:"acme.com"' -silent
$ uncover -fofa 'app="Grafana"' -silent
```

# Cómo encaja en el engagement

## Antes de tocar nada

```shell-session
$ uncover -q 'org:"ACME Inc."' -e shodan,censys -l 1000 -silent -o pasivo.txt
```

Llegas al escaneo activo **sabiendo ya** qué puertos y servicios esperar. Eso reduce el escaneo activo a confirmación dirigida en vez de barrido a ciegas, que es la mejor OPSEC disponible ([[08 - Detección de escaneos y evasión moderna]]).

## Contraste: lo que hay y no debería

Comparar el inventario pasivo con el resultado del escaneo activo da dos hallazgos distintos:

- **En Shodan pero no en tu escaneo** → el servicio se apagó, cambió de IP, o **hay filtrado que te está bloqueando a ti**. Lo último es información sobre el perímetro.
- **En tu escaneo pero no en Shodan** → superficie que no está indexada públicamente. Suele ser lo más interesante y lo menos vigilado.

## Encontrar el origen tras la CDN

```shell-session
$ echo objetivo.com | httpx -silent -favicon                   # sacar el hash MMH3
$ uncover -shodan 'http.favicon.hash:-1234567890' -silent       # buscarlo en Shodan
```

El mismo favicon servido desde una IP que **no** es de la CDN es, con mucha probabilidad, el origen real ([[28 - Origen real tras WAF, CDN y balanceadores]]). Es el uso combinado de `httpx` + `uncover` que más rentabilidad da.

# Límites que hay que tener claros

> [!warning]+ El dato es de segunda mano y puede estar caducado
> <mark style="background: #FF5582A6;">Shodan y compañía escanean con su propia cadencia — de días a semanas</mark>. Un puerto que aparece puede llevar meses cerrado, y uno que no aparece puede haberse abierto ayer. **Nunca reportes un hallazgo basándote solo en datos pasivos**: confírmalo activamente o repórtalo explícitamente como "según Shodan, con fecha X". Además, los buscadores tienen sesgos de cobertura: sondean un subconjunto de puertos, no los 65.535.

> [!important]+ Las consultas quedan registradas contra tu cuenta
> No tocas al objetivo, pero **el proveedor sí sabe qué buscaste, cuándo y desde dónde**. En un engagement eso es normalmente irrelevante; en trabajo sensible, no lo es. Y en términos prácticos: cada consulta consume créditos de una cuenta de pago, así que `-l 1000` contra seis motores gasta dinero de verdad.

> [!info]+ Fuente
> [README de uncover](https://github.com/projectdiscovery/uncover) — lista de proveedores, formato de `provider-config.yaml`, flags, plantillas de `-f` y ejemplos de encadenado. Contexto de recon pasivo en [[08 - Detección de escaneos y evasión moderna]] y [[12 - Search Engine Discovery]].
