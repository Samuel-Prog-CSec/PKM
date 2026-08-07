---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - OSINT
  - Tipo/Introduccion
Descripción: "Un Nmap que no manda paquetes: mismos flags, misma salida, pero los datos vienen de Shodan InternetDB y son gratis"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Límites, frescura del dato y OPSEC]]"
Area: "[[Smap.base|Smap]]"
---
---

<mark style="background: #ADCCFFA6;">`Smap` es un escáner que se comporta como Nmap pero **no manda ni un paquete al objetivo**</mark>: consulta la API **InternetDB** de Shodan y presenta el resultado con los mismos flags y los mismos formatos de salida que Nmap. Su autor lo describe como *«un escáner pasivo tipo Nmap construido con shodan.io»*.

Es la herramienta más pequeña de este arsenal y probablemente la que más veces deberías usar primero.

```shell-session
$ smap 1.1.1.1
$ smap -iL objetivos.txt
$ smap -p21-30,80,443 -iL objetivos.txt
$ smap -iL objetivos.txt -oX resultado.xml
```

# Lo que lo hace interesante

## No necesita cuenta ni clave de API

La API **InternetDB** de Shodan es pública y gratuita. <mark style="background: #8000E1A6;">Cero registro, cero clave, cero coste</mark> — a diferencia de la API principal de Shodan, de Censys o de la mayoría de fuentes de [[07 - uncover - recon pasivo vía motores de búsqueda|uncover]]. Es la fuente pasiva con mejor relación valor/fricción que existe.

## Es *drop-in* con Nmap

Acepta los flags que importan y los ignora el resto:

| Flag | Soportado |
| --- | --- |
| `-p` | Sí (puertos) |
| `-iL` | Sí (lista de objetivos) |
| `-oX`, `-oG`, `-oN`, `-oA` | Sí — **formatos de Nmap** |
| `-oJ`, `-oP`, `-oS` | Sí — JSON, `ip:puerto` y formato propio |
| `--concurrency` | Propio |
| `--active` | Propio (ver abajo) |
| Cualquier otro flag de Nmap | **Ignorado en silencio** |

Que emita **XML de Nmap** es lo que lo hace encajar sin fricción: se importa en [[Metasploit.base|Metasploit]] con `db_import`, en Faraday, en DefectDojo o en cualquier cosa que ya consuma resultados de Nmap ([[06 - Guardar y explotar resultados]]).

> [!warning]+ Ignorar flags en silencio es un footgun
> `smap -sS -A -T4 objetivo.com` **no hace nada de eso**: descarta los tres y devuelve datos pasivos. <mark style="background: #FF5582A6;">La salida se parece tanto a la de Nmap que es fácil creer que has escaneado cuando no has escaneado</mark>. En un informe eso es la diferencia entre "verificado" y "según Shodan". Si vas a mezclar ambos, deja constancia de qué salida vino de dónde.

## Qué información devuelve

Más que un simple listado de puertos: InternetDB trae **puertos abiertos, CPEs (software y versión identificados), CVEs conocidas asociadas, hostnames y etiquetas**.

<mark style="background: #FFB86CA6;">Las CVEs y las etiquetas solo aparecen en los formatos `-oS` y `-oJ`</mark> — en el XML y el *grepable* se pierden, porque el formato de Nmap no tiene dónde ponerlas:

```shell-session
$ smap -iL objetivos.txt -oJ resultado.json
$ jq -r '.[] | select(.vulns != null) | "\(.ip) \(.vulns | join(","))"' resultado.json
```

## Velocidad

Anuncia **200 hosts por segundo**. No es una cifra de red sino de consultas a una API, así que un `/24` completo tarda un par de segundos y un `/16` unos minutos, sin que el objetivo se entere de nada.

# Dónde encaja

```
1. smap / uncover        ← foto pasiva. Gratis, instantánea, invisible
2. filtrar por scope
3. naabu / masscan       ← confirmar y ampliar (activo)
4. nmap -sCV             ← enumerar en profundidad
```

Tres usos concretos:

- **Antes de tener autorización.** En la fase de propuesta o de definición de scope, `smap` da una idea de la superficie del cliente sin tocar nada — que es lo único que puedes hacer legalmente antes de firmar.
- **Como línea base para contrastar.** Lo que Shodan ve y tu escaneo no, o al revés, es información sobre el perímetro ([[07 - uncover - recon pasivo vía motores de búsqueda]]).
- **Para priorizar.** Con las CVEs de InternetDB decides qué hosts merecen el escaneo profundo primero, en vez de barrer todo por igual.

## `--active`

```shell-session
$ smap --active -Pn -sV --version-light 1.1.1.1
```

Verifica activamente los resultados **invocando a Nmap** (que tiene que estar instalado). Es la respuesta al problema de la frescura del dato, y **deja de ser pasivo** en el momento en que lo usas: los flags que pongas van a Nmap de verdad. Detalles en [[01 - Límites, frescura del dato y OPSEC]].

# Relación con `naabu -passive`

Hacen lo mismo sobre la misma fuente:

| | `Smap` | `naabu -passive` |
| --- | --- | --- |
| Fuente | Shodan InternetDB | Shodan InternetDB |
| Salida | **Formatos de Nmap** + JSON | JSONL de la suite |
| CVEs y CPEs | **Sí** (`-oS`/`-oJ`) | No |
| Encaja en | Herramientas que consumen Nmap | [[00 - La suite ProjectDiscovery y el pipeline de recon\|pipeline de PD]] |
| Verificación activa | `--active` (llama a Nmap) | No |

Elige por dónde va a ir el resultado después: si el destino es Metasploit o un gestor de hallazgos, `Smap`; si es `httpx`/`nuclei`, `naabu -passive`.

> [!info]+ Estado del proyecto (verificado 2026-08-04)
> **v0.2.0-rc (abril de 2026)**, ~3.300 estrellas, repositorio `s0md3v/Smap`. Proyecto pequeño y de un solo autor: su supervivencia depende de que la API InternetDB siga siendo gratuita y estable. No lo pongas en el camino crítico de una automatización sin alternativa.

> [!info]+ Fuente
> [README de Smap](https://github.com/s0md3v/Smap) — fuente de datos (InternetDB sin clave), flags aceptados e ignorados, formatos de salida, campos disponibles por formato, `--active`, `--concurrency` y las limitaciones declaradas.
