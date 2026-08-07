---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Recon
Descripción: "El escáner de puertos que encaja en el pipeline: SYN o connect, entrada por ASN, exclusión de CDN, modo pasivo y relevo a Nmap"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - asnmap y cdncheck - superficie por ASN y detección de CDN]]"
Nota siguiente: "[[05 - httpx - sondeo y fingerprinting HTTP a escala]]"
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

`naabu` no es el escáner de puertos más rápido ni el más preciso — no compite con [[00 - Introducción a masscan y el escaneo stateless|masscan]] en volumen ni con [[00 - Introducción a Nmap|Nmap]] en profundidad. <mark style="background: #ADCCFFA6;">Su valor es encajar en el pipeline</mark>: acepta lo que escupe `dnsx`, entiende ASN y CIDR, sabe qué IPs son de CDN, y entrega a `httpx` o a Nmap sin pegamento por el medio.

```shell-session
$ naabu -host objetivo.com
$ naabu -list hosts.txt -top-ports 1000 -silent
$ echo AS14421 | naabu -p 80,443 -silent
$ echo objetivo.com | naabu -silent | httpx -silent
```

# SYN o connect: elige a conciencia

```shell-session
$ sudo naabu -host objetivo.com -s syn        # SYN, requiere root
$ naabu -host objetivo.com -s connect         # connect, sin privilegios
```

<mark style="background: #FFB8EBA6;">El tipo de escaneo por defecto es **CONNECT**</mark>, y la documentación recomienda a la vez ejecutar como `root` *«para mejores resultados»* — que es lo que activa SYN. La diferencia importa y no es cosmética:

| | `-s syn` | `-s connect` |
| --- | --- | --- |
| Privilegios | `root` | Ninguno |
| Handshake | A medias | **Completo** |
| Huella en logs de aplicación | Poca | <mark style="background: #FF5582A6;">Una línea por puerto abierto</mark> |
| Funciona a través de SOCKS (`-proxy`) | No | **Sí** |

Es el mismo reparto que en [[02 - Precisión, evasión y detección|RustScan]]: connect es cómodo y ruidoso, SYN es más discreto y necesita privilegios. Si te importa el sigilo, `sudo naabu -s syn`. Si vas a pivotar por un túnel, `-s connect -proxy`.

# Lo que lo hace distinto

## Modo pasivo

```shell-session
$ naabu -host objetivo.com -passive -silent
```

`-passive` obtiene los puertos abiertos de la **API de Shodan InternetDB** en vez de escanear. Cero paquetes al objetivo. Es la misma fuente que usa [[00 - Smap - escaneo pasivo con datos de Shodan|Smap]], integrada en el pipeline: útil para llegar al escaneo activo sabiendo ya dónde mirar, o para una primera foto cuando aún no tienes autorización para tocar nada.

## Exclusión de CDN

```shell-session
$ naabu -l hosts.txt -exclude-cdn -silent
$ naabu -l hosts.txt -display-cdn -silent
```

`-ec/-exclude-cdn` limita a **80 y 443** el escaneo de IPs identificadas como CDN/WAF (Cloudflare, Akamai, Incapsula, Sucuri). Es la salvaguarda de scope de [[03 - asnmap y cdncheck - superficie por ASN y detección de CDN]] aplicada en el sitio correcto.

## Descubrimiento de hosts al estilo Nmap

Una batería completa de sondas, poco conocida:

| Flag | Sonda |
| --- | --- |
| `-sn`, `-host-discovery` | Solo descubrimiento, sin escanear puertos |
| `-ps`, `-probe-tcp-syn` | TCP SYN ping |
| `-pa`, `-probe-tcp-ack` | TCP ACK ping |
| `-pe`, `-probe-icmp-echo` | ICMP echo |
| `-pp`, `-probe-icmp-timestamp` | ICMP timestamp |
| `-pm`, `-probe-icmp-address-mask` | ICMP address mask |
| `-arp`, `-arp-ping` | ARP ping (red local) |
| `-nd`, `-nd-ping` | Neighbor Discovery (IPv6) |
| `-rev-ptr` | Resolución PTR inversa |

<mark style="background: #8000E1A6;">El **ACK ping** y el **ICMP timestamp** son los que sobreviven donde el ICMP echo está bloqueado</mark>, que es prácticamente siempre en perímetro corporativo. Mismo razonamiento que en [[01 - Host Discovery|el host discovery de Nmap]].

## `-smart-scan`

```shell-session
$ naabu -l hosts.txt -ss -pt 30 -silent
```

Escaneo predictivo: correlaciona puertos que suelen aparecer juntos y prioriza. `-pt/-prediction-threshold` fija la confianza mínima (0-100, por defecto **20**). Ahorra tiempo en rangos grandes a cambio de poder saltarse un puerto atípico — <mark style="background: #FFB8EBA6;">no lo uses en la pasada final que va al informe</mark>.

# Ritmo y precisión

| Flag | Por defecto |
| --- | --- |
| `-rate` | **1000** paquetes/s |
| `-c` | **25** workers |
| `-retries` | **3** |
| `-timeout` | **1000** ms |
| `-warm-up-time` | **2** s entre fases |
| `-port-threshold`, `-pts` | — (salta el host si supera N puertos abiertos) |

> [!warning]+ 1.000 pps por defecto es mucho para bug bounty
> Es un valor pensado para ir rápido, no para pasar desapercibido ni para respetar las reglas de un programa. <mark style="background: #FF5582A6;">Muchos programas de bug bounty limitan explícitamente el volumen de peticiones</mark> y un `-p -` a 1.000 pps contra su infraestructura es exactamente lo que prohíben ([[01 - Reglas, legalidad y conducta]]). Baja `-rate` y `-c` conscientemente.

`-port-threshold` es la defensa contra los honeypots y los dispositivos que responden a todo: si un host devuelve más de N puertos abiertos, lo descarta en vez de inundarte de falsos positivos.

# Salidas y relevo

```shell-session
$ naabu -l hosts.txt -json -o puertos.jsonl -silent
$ naabu -l hosts.txt -csv -o puertos.csv -silent
$ naabu -host objetivo.com -nmap-cli 'nmap -sV -oX nmap-output' -silent
$ naabu -l hosts.txt -silent | httpx -silent -sc -title -tech-detect
```

`-nmap-cli` invoca a Nmap sobre los puertos encontrados — el patrón de dos fases de siempre ([[03 - Salidas y pipeline hacia Nmap]]), con Nmap instalado aparte.

## Flags que evitan sorpresas

- **`-sa`, `-scan-all-ips`** — un nombre puede resolver a varias IPs; por defecto solo se escanea una. Con balanceadores y multi-región, `-sa` es la diferencia entre ver la superficie entera y ver un trozo.
- **`-iv`, `-ip-version`** — por defecto **ambas**. En redes dual-stack conviene mirar IPv6 explícitamente: <mark style="background: #FFB86CA6;">el firewall IPv6 suele estar bastante más flojo que el IPv4</mark>.
- **`-resume`** — retoma un escaneo interrumpido.
- **`-stream`** — emite según encuentra, pero **desactiva** `resume`, la integración con Nmap, la verificación y los reintentos. Úsalo solo cuando la latencia importe más que la exactitud.
- **`-verify`** — reverifica por TCP los puertos encontrados. Cuesta tiempo y quita falsos positivos: es lo que quieres antes de escribir un informe.

> [!success]+ Invocación de referencia
> ```shell-session
> $ sudo naabu -l hosts_en_scope.txt -s syn -top-ports 1000 \
>     -exclude-cdn -sa -rate 300 -c 25 -retries 3 -verify \
>     -json -o puertos.jsonl -silent
> ```
> SYN, ritmo contenido, CDN acotada, todas las IPs de cada nombre y verificación final.

> [!info]+ Fuente
> [README de naabu](https://github.com/projectdiscovery/naabu) — tipos de escaneo y privilegios, flags por sección, defaults (`-rate 1000`, `-c 25`, `-retries 3`, `-timeout 1000`, `-s connect`, `-pt 20`), `-passive` sobre Shodan InternetDB, `-exclude-cdn` y sus proveedores, y sondas de host discovery.
