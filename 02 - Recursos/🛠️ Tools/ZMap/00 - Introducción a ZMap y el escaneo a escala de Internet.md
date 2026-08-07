---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Introduccion
Descripción: "El escáner de la investigación académica y de Censys: cómo recorre todo IPv4 sin memoria usando un grupo cíclico, y por qué eso importa para tu recon pasivo"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Uso de ZMap - probe modules, blocklist y sharding]]"
Area: "[[ZMap.base|ZMap]]"
---
---

<mark style="background: #ADCCFFA6;">ZMap es un escáner *stateless* de un solo paquete diseñado para censos de Internet completos</mark>, nacido en la Universidad de Michigan y hoy mantenido por el ZMap Project. Anuncia recorrer todo el espacio IPv4 público en un puerto **en menos de 45 minutos** con una tarjeta gigabit corriente, y en **menos de 5** con 10 GbE usando `netmap` o PF_RING.

En un engagement con scope de un `/24` no vas a usar ZMap. Está aquí por dos razones concretas:

1. **Es la maquinaria que hay debajo de Censys** y de buena parte de la investigación pública sobre exposición en Internet. Tu recon pasivo con Shodan/Censys ([[08 - Detección de escaneos y evasión moderna|recon sin tocar el objetivo]]) consume datos que se producen así — entender cómo se generan te dice qué frescura, qué cobertura y qué sesgos tienen.
2. **Con ZGrab2 y ZDNS forma la única cadena libre** capaz de hacer descubrimiento L4 + handshake L7 + resolución DNS a escala de millones de objetivos, que es lo que necesita un programa de *attack surface management* o una caza de bug bounty sobre un ASN entero.

# Cómo recorre 4.000 millones de direcciones sin recordar nada

masscan y ZMap resuelven el mismo problema —permutar el espacio de objetivos sin guardarlo— con matemáticas distintas, y la de ZMap es la más elegante.

ZMap trata el espacio de direcciones como el **grupo multiplicativo cíclico** de los enteros módulo un primo. El comentario del propio `src/cyclic.c` lo dice sin rodeos:

> *«We know that 3 is a generator of (Z mod 2^32 + 15 - {0}, \*) and that we have coverage over the entire address space because 2\*\*32 + 15 is prime»*

La idea: <mark style="background: #8000E1A6;">si eliges un **raíz primitiva** (generador) del grupo y vas multiplicando, recorres **todos** los elementos exactamente una vez antes de volver al principio</mark>. No hace falta lista, ni bitmap, ni tabla: el "siguiente objetivo" es una multiplicación modular sobre el anterior.

- El primo elegido es **2³² + 15**, ligeramente mayor que el espacio IPv4, así que lo cubre entero.
- Para cada escaneo, `make_cycle()` deriva de la **semilla** dos valores: un generador nuevo (vía `find_primroot()`) y un desplazamiento de arranque. Generador distinto = orden distinto; misma semilla = orden reproducible.
- La búsqueda de generadores explota el isomorfismo entre el grupo aditivo $(\mathbb{Z}_{p-1}, +)$ y el multiplicativo $(\mathbb{Z}_p^*, \cdot)$: basta encontrar coprimos con $p-1$ y validarlos con exponenciación modular.

## Comparado con masscan

| | ZMap | masscan |
| --- | --- | --- |
| **Permutación** | Grupo cíclico multiplicativo mód. $2^{32}+15$ | [[00 - Introducción a masscan y el escaneo stateless\|BlackRock2]], cifrado que preserva el formato (Feistel + S-boxes de DES) |
| **Validación de respuesta** | Puerto de origen / campos derivados de la semilla | SYN cookie **SipHash-2-4** en el número de secuencia |
| **Rate por defecto** | **10.000 pps** | **100 pps** |
| **Objetivo por defecto** | <mark style="background: #FF5582A6;">Todo IPv4</mark> | Ninguno (obliga a especificar) |
| **Exclusiones por defecto** | **Sí**, `blocklist.conf` activo | No |
| **Módulos** | *Probe* y *output* enchufables | Fijo (SYN + parsers de banner) |
| **Enfoque** | Censo reproducible y auditable | Barrido operativo rápido |

<mark style="background: #FFB86CA6;">La diferencia de defaults es la que te puede meter en un problema</mark>: `sudo zmap -p 80` sin más argumentos **empieza a escanear Internet entero a 10.000 paquetes por segundo**. masscan sin `-p` no hace nada; ZMap sin rango lo hace todo.

> [!warning]+ El footgun de ZMap
> ```shell-session
> $ sudo zmap -p 80              # ← esto NO es una prueba inofensiva
> ```
> Es el ejemplo que aparece en el propio README, y escanea el espacio IPv4 público completo. En un engagement, en una red corporativa o desde tu VPS, eso es como mínimo una violación de scope y probablemente una queja de abuso a tu proveedor. **Nunca ejecutes ZMap sin `-w/--allowlist-file` o un rango explícito.**

# La ética está en el código, no en un aviso legal

ZMap es el único de estos escáneres que trae las limitaciones incorporadas por diseño, herencia de su origen académico. `conf/zmap.conf` activa la exclusión **por defecto**, sin comentar:

```text
blocklist-file "/etc/zmap/blocklist.conf"
```

Y `conf/blocklist.conf` excluye los rangos de propósito especial del registro IANA: `0.0.0.0/8`, `10.0.0.0/8`, `100.64.0.0/10` (CGNAT, RFC 6598), `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12`, `192.0.0.0/24`, `192.0.2.0/24`, `192.88.99.0/24`, `192.168.0.0/16`, `198.18.0.0/15` (benchmarking, RFC 2544), `198.51.100.0/24`, `203.0.113.0/24`, `224.0.0.0/4`, `240.0.0.0/4` y `255.255.255.255/32`.

> [!important]+ Ese blocklist lleva desde 2013 sin refrescarse
> Las cabeceras del fichero dicen literalmente `Updated 2013-05-22` y `Updated 2013-06-25`. Cubre bien lo clásico, pero <mark style="background: #FFB8EBA6;">no incluye asignaciones posteriores</mark>. Y más importante en la práctica: **excluye rangos privados**, lo que significa que si lo usas para escanear la red interna de un cliente (`10.0.0.0/8`, `192.168.0.0/16`), ZMap no escaneará nada y parecerá que la red está vacía. Para uso interno hay que pasar un blocklist propio o `-b /dev/null` — y en ese caso las exclusiones de scope las pones tú.

La documentación del proyecto resume su postura en tres reglas que valen para cualquier escaneo, no solo ZMap: **escanea a la velocidad mínima necesaria, más lento aún si el espacio objetivo es pequeño, y ofrece a los operadores una vía para excluirse.**

# Cuándo tiene sentido de verdad

| Escenario | ¿ZMap? |
| --- | --- |
| Censo de un puerto en un ASN o país entero | **Sí**, es su caso de uso |
| Superficie de un cliente grande (varios `/16` públicos) | Sí, con blocklist propio |
| Investigación: prevalencia de una CVE, medir un despliegue | **Sí**, y es reproducible por la semilla |
| Red interna de un cliente | No — usa [[00 - Introducción a masscan y el escaneo stateless\|masscan]] o [[00 - Introducción a Nmap\|Nmap]] |
| Un `/24` o un host | No, es matar moscas a cañonazos |
| Enumerar versiones y vulnerabilidades | No directamente — para eso está [[02 - ZGrab2 - handshakes L7 y banners a escala\|ZGrab2]] |

> [!info]+ Estado del proyecto (verificado 2026-08-04 contra la API de GitHub)
> **ZMap 4.4.0** (mayo 2026), **ZGrab2 1.0.0** (diciembre 2025 — su primer estable tras años en pre-release) y **ZDNS 2.1.1** (mayo 2026). Los tres con commits este mismo mes. Es, con diferencia, el ecosistema de escaneo a escala mejor mantenido: frente a masscan, cuyo último *release* etiquetado es de enero de 2021.

> [!info]+ Fuentes
> - [ZMap Project](https://github.com/zmap/zmap): `README.md` (rendimiento, guía ética), `src/cyclic.c` (grupo cíclico, primo $2^{32}+15$, `find_primroot()`, `make_cycle()`), `conf/zmap.conf` y `conf/blocklist.conf`.
> - Zakir Durumeric, Eric Wustrow y J. Alex Halderman — *ZMap: Fast Internet-Wide Scanning and its Security Applications*, USENIX Security 2013 (el paper original que introduce el diseño).
