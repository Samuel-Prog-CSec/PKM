---
tags:
  - Pentesting/Enumeracion
  - Recon
  - DNS
Descripción: "Generar los nombres que ninguna fuente pasiva conoce y resolverlos deprisa sin ahogarse en wildcards"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - subfinder - enumeración pasiva de subdominios]]"
Nota siguiente: "[[03 - asnmap y cdncheck - superficie por ASN y detección de CDN]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

[[01 - subfinder - enumeración pasiva de subdominios|`subfinder`]] solo encuentra lo que alguien ya había visto. Los subdominios que nunca tuvieron certificado ni se publicaron en ningún sitio hay que **adivinarlos**, y luego comprobar cuáles existen. Ese es el trabajo de `alterx` y `dnsx`.

# `alterx` — generar candidatos con criterio

La fuerza bruta clásica prueba una wordlist genérica contra el dominio. `alterx` hace algo más listo: <mark style="background: #ADCCFFA6;">toma los subdominios que **ya sabes que existen** y genera permutaciones a partir de sus propios patrones</mark>.

```shell-session
$ subfinder -d objetivo.com -silent | alterx -silent
$ subfinder -d objetivo.com -silent | alterx -enrich -silent
$ alterx -l subs.txt -p '{{sub}}-{{word}}.{{suffix}}' -pp word=entornos.txt -silent
```

La lógica: si el objetivo tiene `api-prod.objetivo.com` y `web-dev.objetivo.com`, es muy probable que existan `api-dev`, `web-prod`, `api-staging`. Ninguna fuente pasiva los lista porque nunca salieron a Internet, pero <mark style="background: #FFB86CA6;">los entornos de preproducción son donde vive la autenticación floja y el debug abierto</mark>.

`-enrich` extrae los patrones del propio conjunto de entrada en vez de usar una lista fija, que es lo que lo diferencia de un `sed` con una wordlist.

> [!important]+ Genera muchos, resuelve barato
> `alterx` produce fácilmente cientos de miles de candidatos. Eso está bien: el paso siguiente (`dnsx`) descarta los inexistentes muy deprisa y **sin tocar al objetivo** si usas resolutores públicos. El coste real está en el DNS, no en generar la lista.

# `dnsx` — resolver, y sobre todo filtrar

`dnsx` es el cuello por el que pasa todo el pipeline: convierte listas de nombres candidatos en hosts reales.

```shell-session
$ subfinder -silent -d objetivo.com | dnsx -silent -a -resp
$ subfinder -silent -d objetivo.com | dnsx -silent -a -resp-only
$ subfinder -silent -d objetivo.com | dnsx -silent -cname -resp
$ echo 173.0.84.0/24 | dnsx -silent -resp-only -ptr
```

## Tipos de consulta

`-a`, `-aaaa`, `-cname`, `-ns`, `-txt`, `-srv`, `-ptr`, `-mx`, `-soa`, `-caa`, `-any`, `-axfr`, y `-recon` para lanzarlos **todos** de una vez. `-e/-exclude-type` excluye los que no quieras.

| Registro | Por qué importa en recon |
| --- | --- |
| `-cname` | <mark style="background: #FF5582A6;">La precondición del [[Subdomain Takeover.base\|subdomain takeover]]</mark>: un CNAME apuntando a un servicio que ya no existe. |
| `-ptr` sobre un CIDR | DNS inverso de un rango entero: nombres de hosts que no salían por delante. |
| `-txt` | SPF, DKIM, verificaciones de dominio — delatan qué SaaS usa el cliente. |
| `-mx`, `-ns` | Proveedor de correo y DNS; superficie de terceros. |
| `-axfr` | Transferencia de zona. Sigue apareciendo ([[04 - Transferencias de zona DNS]]). |
| `-caa` | Qué CA puede emitir certificados para el dominio. |

## El filtrado de wildcards: lo que hace útil a `dnsx`

Este es su valor diferencial y el problema que arruina el 90 % de las enumeraciones caseras.

<mark style="background: #FFB86CA6;">Si un dominio tiene un registro comodín (`*.objetivo.com`), **todos** los nombres que pruebes resolverán</mark>. Tu lista de 300.000 candidatos devuelve 300.000 "hallazgos", todos falsos. La documentación lo describe sin adornos: *«todos los subdominios resolverán, lo que lleva a mucha basura en la salida»*.

`dnsx` lo detecta contando cuántos nombres distintos apuntan a la misma IP; al pasar del umbral, comprueba comodines **en todos los niveles del host de forma iterativa**:

```shell-session
$ dnsx -l candidatos.txt -wd objetivo.com -o reales.txt      # filtrado manual
$ dnsx -l candidatos.txt -auto-wildcard -o reales.txt        # detección automática
```

| Flag | Uso |
| --- | --- |
| `-wd`, `-wildcard-domain` | Dominio raíz sobre el que filtrar. Para **un** dominio. |
| `-auto-wildcard` | Detecta solo la raíz comodín. Para entrada **multi-dominio**. |
| `-wt`, `-wildcard-threshold` | Umbral de nombres por IP que dispara la comprobación (por defecto **5**). |

Son **mutuamente excluyentes**: `-wd` para un dominio, `-auto-wildcard` cuando la entrada mezcla varios.

> [!warning]+ Sin filtrado de wildcards, el resto del pipeline se va al garete
> Si pasas 300.000 falsos positivos a `naabu` y `httpx`, estás lanzando un escaneo masivo contra la misma IP comodín, disparando cualquier protección del objetivo y quemando horas. **El filtrado de wildcards no es una optimización: es lo que hace viable la fase activa.**

## Fuerza bruta integrada

```shell-session
$ dnsx -silent -d objetivo.com -w wordlist.txt
$ dnsx -silent -d dominios.txt -w jira,grafana,jenkins
$ dnsx -d google.FUZZ -w tld.txt -resp                 # FUZZ como marcador
$ cat dominios.txt | dnsx -silent -w jira,grafana -d -
```

`-d` (dominios) + `-w` (palabras) genera y resuelve en una pasada. El marcador `FUZZ` permite colocar la variable donde quieras — el ejemplo `google.FUZZ` con una lista de TLDs busca el mismo nombre en todos los dominios de primer nivel, que es como se encuentran las variantes por país.

## Rendimiento y resolutores

| Flag | Por defecto | Nota |
| --- | --- | --- |
| `-t`, `-threads` | **100** | Concurrencia. |
| `-rl`, `-rate-limit` | *desactivado* | <mark style="background: #FF5582A6;">Sin límite por defecto</mark>. |
| `-retry` | **2** | Reintentos por consulta. |
| `-timeout` | **3 s** | Tope por consulta. |
| `-r`, `-resolver` | — | Lista propia. Admite **UDP, TCP, DoH y DoT**. |
| `-rc`, `-rcode` | — | Filtrar por código: `noerror,servfail,refused`. |
| `-trace` | — | Traza la resolución completa, salto a salto. |

> [!warning]+ El rate limit desactivado por defecto es un problema real
> Con `-t 100` y sin `-rl`, `dnsx` satura resolutores públicos, que empiezan a devolver `SERVFAIL` — y tú lo lees como "no existe". <mark style="background: #FFB8EBA6;">Es la causa habitual de que la misma lista dé resultados distintos en dos ejecuciones</mark>. Usa una lista de resolutores propia y fiable, pon `-rl` explícito, y antes de dar por muerta una lista, **repite los `SERVFAIL` con menos hilos**. Es el mismo error de medida que en [[03 - ZDNS - resolución DNS masiva|ZDNS]].

## Enriquecimiento

```shell-session
$ subfinder -silent -d objetivo.com | dnsx -silent -asn
$ subfinder -silent -d objetivo.com | dnsx -silent -cdn
$ echo objetivo.com | dnsx -silent -a -ot '{{host}} {{a}}'
```

`-asn` y `-cdn` añaden a quién pertenece la IP y si está tras una CDN — el atajo para separar infraestructura propia del cliente de la de terceros antes de escanear ([[03 - asnmap y cdncheck - superficie por ASN y detección de CDN]]). `-ot` da formato de salida a medida con plantillas.

> [!info]+ Fuentes
> READMEs de [alterx](https://github.com/projectdiscovery/alterx) y [dnsx](https://github.com/projectdiscovery/dnsx) — tipos de consulta, mecanismo y flags de filtrado de comodines (`-wd`, `-auto-wildcard`, `-wt 5`), modo de fuerza bruta con `FUZZ`, y defaults (`-t 100`, `-retry 2`, `-timeout 3s`, rate limit desactivado). Técnica relacionada en [[06 - Fuerza bruta de subdominios]].
