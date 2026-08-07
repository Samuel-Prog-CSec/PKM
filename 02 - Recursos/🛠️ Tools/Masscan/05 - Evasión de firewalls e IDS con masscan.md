---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Deteccion
Descripción: "masscan no está diseñado para el sigilo: qué palancas tiene de verdad, cuáles no existen y por qué su paquete es trivial de fingerprintear"
Fecha de actualización: 2026-08-04
Nota previa: "[[04 - Banner grabbing y modo stateful]]"
Nota siguiente:
Area: "[[Masscan.base|Masscan]]"
---
---

Conviene empezar por la conclusión: <mark style="background: #FF5582A6;">masscan no es una herramienta sigilosa y ninguna combinación de flags la convierte en una</mark>. Su diseño entero —pila propia mínima, sin estado, volumen— va en dirección contraria al sigilo. Pero tiene palancas reales, tiene una propiedad emergente que casi nadie explota, y su paquete tiene una firma tan característica que merece entenderla aunque solo sea para saber cuándo **no** usarlo.

# Lo que masscan NO tiene

Antes de buscar equivalencias con [[07 - Evasión de firewalls, IDS e IPS|el arsenal de evasión de Nmap]], conviene saber qué falta, porque es la mitad de la lista:

| Técnica de Nmap | ¿En masscan? |
| --- | --- |
| Fragmentación (`-f`, `--mtu`) | **No** |
| Decoys (`-D`) | **No** |
| Idle scan (`-sI`) | **No** |
| Plantillas de timing (`-T0`…`-T5`) | **No** (solo `--rate`) |
| Checksum inválido (`--badsum`) | **No** |
| Tipos de escaneo alternativos (FIN, NULL, Xmas, ACK) | **No** — solo SYN |

Todo lo que en Nmap va de *deformar el paquete* está ausente. Lo que masscan sí tiene va de *repartir y disimular el origen*.

# Las palancas que sí existen

## 1. La propiedad emergente: aleatorización + rate bajo

Esta es la buena, y se pierde porque la gente asocia masscan a "rápido". Recuerda que el recorrido es una [[00 - Introducción a masscan y el escaneo stateless|permutación pseudoaleatoria del espacio completo]], no un barrido secuencial.

<mark style="background: #8000E1A6;">Consecuencia: el ritmo que ve **un objetivo concreto** no es tu `--rate`, sino tu `--rate` dividido entre el número de objetivos</mark>. Un `--rate 1000` sobre un `/16` (65.536 hosts × 10 puertos = 655.360 sondas) significa que cada host recibe un paquete cada ~655 segundos. Eso está **muy por debajo** del umbral de cualquier detector de *portscan* por host.

```shell-session
$ sudo masscan 10.0.0.0/16 -p22,80,443,445,3389,8080 --rate 500 --seed time -oB barrido.bin
```

Un IDS que dispara con «X conexiones nuevas desde una IP a Y puertos en Z segundos» no ve el patrón, porque el patrón está diluido en el espacio en vez de concentrado en el tiempo. Lo que sí lo ve es un motor que **agregue por IP de origen a través de todos los destinos** —correlación de flujo, NDR, un SIEM con la regla bien puesta— y esa es exactamente la detección que la nota [[08 - Detección de escaneos y evasión moderna|de detección moderna]] describe como la que sobrevive.

> [!important]+ Esto invierte la intuición
> Contra un rango grande, masscan a ritmo bajo es **más silencioso por objetivo** que Nmap, porque Nmap agota un host antes de pasar al siguiente. Contra **un solo host**, masscan es lo más ruidoso que puedes hacer: toda la aleatorización se colapsa y le mandas todo el rate a la cara. Regla: masscan para lo ancho, Nmap para lo profundo.

## 2. Repartir el origen: `--shard`

```shell-session
$ sudo masscan 10.0.0.0/8 -p443 --shard 1/4 --seed 20260804 --rate 2000   # VPS 1
$ sudo masscan 10.0.0.0/8 -p443 --shard 2/4 --seed 20260804 --rate 2000   # VPS 2
```

Cuatro IPs de origen distintas, cada una con la cuarta parte del volumen. Sube el listón que el defensor necesita para correlacionar y limita el daño si le queman una IP. La misma semilla en todos es **obligatoria** o la partición se rompe.

## 3. Rotar la IP de origen: `--adapter-ip` con rango

```shell-session
$ sudo masscan 10.0.0.0/16 -p443 --adapter-ip 192.0.2.16-192.0.2.31 --rate 5000
```

masscan reparte los paquetes entre ese bloque (el tamaño debe ser **potencia de 2**). <mark style="background: #FFB8EBA6;">No es *spoofing*: esas IPs tienen que estar enrutadas hacia ti o no verás las respuestas</mark>. Es la técnica cuando tienes un bloque asignado en el VPS o un rango cloud propio, y multiplica por 16 el esfuerzo de correlación del defensor.

## 4. Puerto de origen de confianza

```shell-session
$ sudo masscan 10.0.0.0/16 -p50000 --source-port 53 --rate 1000
```

Mismo truco que en Nmap y sigue funcionando en firewalls con reglas perezosas que confían en el tráfico "de vuelta" del DNS. Es probablemente la palanca de mayor relación éxito/esfuerzo que queda de la era clásica ([[07 - Evasión de firewalls, IDS e IPS#Source port (`--source-port`) — el truco que más funciona|el mismo caso en Nmap]]).

## 5. Retocar la firma del paquete

```shell-session
$ sudo masscan 10.0.0.0/16 -p443 --ttl 64 --min-packet 64 --source-port 53
```

- **`--ttl 64`** — sacar el TTL de 255 por defecto, que es delator (ver abajo).
- **`--min-packet N`** — rellena con *padding* para romper el tamaño constante.
- **`--http-user-agent`** — en modo `--banners`, evita el UA por defecto, que los WAF conocen.
- **`--seed time`** — orden distinto en cada pasada, para que dos escaneos no produzcan el mismo patrón temporal.

# Cómo se detecta masscan

## La firma del paquete: es delatora por construcción

La plantilla del `SYN` está **cableada** en `src/templ-pkt.c`, y comparada con la de un sistema operativo real canta:

| Campo | masscan (por defecto) | Linux / Windows modernos |
| --- | --- | --- |
| **TTL inicial** | **255** | 64 (Linux) / 128 (Windows) |
| **Opciones TCP** | **Solo MSS 1460** | MSS + SACK-permitted + Timestamps + Window Scale + NOP |
| **Ventana TCP** | Fija y pequeña (1024 según el comentario del código) | Grande y variable |
| **Flag DF** | **Sin poner** | Puesto |

<mark style="background: #FFB86CA6;">Un `SYN` con TTL 255, sin `DF`, con ventana 1024 y una sola opción TCP no lo genera ningún sistema operativo de escritorio o servidor</mark>. Basta mirar dos campos de la cabecera para clasificarlo como escáner, sin necesidad de contar paquetes ni esperar a que se cumpla un umbral. Es detección de **un solo paquete**, la peor clase para el atacante.

> [!info]+ Un matiz histórico que invalida fuentes viejas
> El artículo clásico de Michael Rash (cipherdyne, **2013**) propone detectar masscan por tener el `SYN` **sin ninguna opción TCP**. Ya no es cierto: el código actual incluye la opción MSS 1460 —el propio comentario del fuente acredita la aportación (`h/t @IvreRocks`)—. La heurística "cero opciones" produce hoy falsos negativos. Lo que sigue siendo válido es la idea de fondo: **el número y orden de las opciones TCP es un identificador de pila**, que es justo la base de los métodos de *fingerprinting* activo modernos tipo JA4TScan.

## Lo demás que te ve

- **Umbral y flujo** — `Suricata`, `Zeek` y los *flow logs* cloud agregan por IP de origen. El truco de diluir en el espacio (§1) funciona contra reglas por-host y **falla** contra agregación por origen.
- **Honeypots y canary tokens** — barrer `-p0-65535` a ciegas sobre un rango entero es la forma más rápida de pisar un puerto-trampa. Un solo paquete a un canario es una alerta de alta confianza.
- **Logs de aplicación** — con `--banners` completas conexiones, así que apareces en el `access.log`, no solo en el IDS ([[04 - Banner grabbing y modo stateful]]).
- **Falta de reintentos** — irónicamente, un defensor con *rate-limiting* puede **envenenar tus resultados** sin bloquearte: descarta un porcentaje de tus SYN y masscan, que no reintenta por defecto, te reporta cerrados los puertos que sí están abiertos. Es una contramedida barata y silenciosa.

# Regla operativa

```
¿Rango grande y no me importa que se sepa?      → masscan a rate alto
¿Rango grande y quiero pasar desapercibido?     → masscan --rate bajo + --shard + --seed time
¿Un host y quiero sigilo?                       → NO uses masscan. Nmap -T1 o recon pasivo
¿No quiero mandar ni un paquete?                → Smap / uncover / Shodan
```

<mark style="background: #ADCCFFA6;">El sigilo real en 2026 no sale de un flag: sale de mandar menos paquetes y de que los que mandes se parezcan a algo legítimo</mark>. masscan puede colaborar con lo primero y no puede ayudar con lo segundo. La doctrina completa —perfilar el perímetro, egress filtering, rotación de infraestructura, low-and-slow— está en [[00 - El perímetro moderno - firewall, NGFW, IDS-IPS, NDR y WAF|el bloque de evasión de perímetro]].

> [!info]+ Fuentes
> - Código fuente de masscan, `src/templ-pkt.c` — plantilla `default_tcp_template[]` con TTL 255, opción MSS 1460 única, ventana fija y flags IP a cero; `src/main-conf.c` para `--adapter-ip` y `--source-port`.
> - Michael Rash — [*TCP Options and Detection of Masscan Port Scans*](https://www.cipherdyne.org/blog/2013/09/tcp-options-and-detection-of-masscan-port-scans.html) (2013, **parcialmente obsoleto**, ver el callout).
> - Contexto defensivo en [[08 - Detección de escaneos y evasión moderna]] (Suricata/Zeek, flow logs, GuardDuty) y MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/).
