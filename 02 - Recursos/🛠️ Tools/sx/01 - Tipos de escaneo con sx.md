---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "ARP, ICMP, TCP con cualquier combinación de flags, UDP y descubrimiento de proxies SOCKS5 — un subcomando por técnica"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - sx - escaneo componible en Go]]"
Nota siguiente: "[[02 - Evasión de firewalls y detección con sx]]"
Area: "[[sx.base|sx]]"
---
---

Cada técnica es un subcomando independiente. Esta nota los recorre en el orden en que se usan durante un pentest interno: primero saber quién está, luego qué tiene abierto, luego lo que sirve para pivotar.

# `sx arp` — quién está en el segmento

```shell-session
$ sudo sx arp 192.168.0.1/24
$ sudo sx arp --json 192.168.0.1/24 | tee arp.cache
$ sudo sx arp --exit-delay 5s 192.168.0.1/24
$ sudo sx arp 192.168.0.1/24 --live 10s
```

<mark style="background: #ADCCFFA6;">El escaneo ARP es la forma más fiable de descubrir hosts en tu propio segmento</mark>, y la única que no se puede filtrar: un host que ignora ICMP y tiene todos los puertos cerrados **tiene que responder ARP** o no puede comunicarse con nadie. Por eso es el primer movimiento en una red interna, por delante de cualquier ping sweep.

La salida incluye el **fabricante** deducido del OUI de la MAC, que es inteligencia gratis: te dice de un vistazo dónde están las impresoras, las cámaras IP, los teléfonos VoIP, el equipamiento de red y los hipervisores — todos ellos objetivos con credenciales por defecto y superficie propia.

`--exit-delay` (por defecto **300 ms**) es cuánto espera antes de salir para recoger respuestas rezagadas. En una red lenta o con muchos hosts, súbelo o perderás equipos.

> [!important]+ ARP no cruza el router
> Solo ve tu **dominio de difusión**. Para otros segmentos hace falta estar en ellos —o pivotar hasta ellos ([[Pivoting y túneles.base|pivoting y túneles]])— y repetir. Ese es el flujo real: comprometes un host, montas el túnel, y vuelves a hacer `sx arp` desde dentro del nuevo segmento.

# `sx icmp` — hosts vivos y reglas de firewall

Descubrimiento por ICMP y, según la documentación del proyecto, **identificación de reglas de firewall**. La idea es la de siempre: los distintos tipos y códigos ICMP que devuelve (o deja de devolver) un dispositivo revelan si hay filtrado y de qué clase ([[07 - Evasión de firewalls, IDS e IPS#Drop vs reject|drop vs reject]]).

# `sx tcp` — el subcomando principal

```shell-session
$ cat arp.cache | sudo sx tcp -p 1-65535 192.168.0.171
$ cat arp.cache | sudo sx tcp --json -p 1-23,25-443 192.168.0.171
$ sudo sx tcp -a arp.cache -p 22,443 192.168.0.171
$ cat arp.cache | sudo sx tcp --json -f ip_ports_file.jsonl
```

Por defecto hace **SYN scan** (`sx tcp syn` es la forma explícita). La caché ARP llega por `stdin` o por `-a`; los objetivos, por argumento o por `-f` desde un JSONL.

## Los escaneos de flags

Aquí está lo que hace único a `sx` en este arsenal:

```shell-session
$ cat arp.cache | sudo sx tcp fin  --json -p 23 192.168.0.171
$ cat arp.cache | sudo sx tcp null --json -p 23 192.168.0.171
$ cat arp.cache | sudo sx tcp xmas --json -p 23 192.168.0.171
$ cat arp.cache | sudo sx tcp --flags syn,fin,ack --json -p 23 192.168.0.171
```

| Subcomando | Flags TCP enviados |
| --- | --- |
| `syn` (por defecto) | `SYN` |
| `fin` | `FIN` |
| `null` | *ninguno* |
| `xmas` | `FIN` + `PSH` + `URG` |
| `--flags a,b,c` | Los que le digas |

<mark style="background: #FFB86CA6;">`--flags` con combinaciones arbitrarias es lo que convierte a `sx` en una herramienta de sondeo de perímetro</mark> y no solo en un escáner: puedes construir el paquete exacto que quieres probar contra una regla concreta sin bajar a [[01 - Definir un protocolo propietario en Scapy|Scapy]]. El razonamiento detrás de cada combinación y sus límites reales están en [[02 - Evasión de firewalls y detección con sx]].

## Interpretar la salida

El JSONL trae el campo `flags` con lo que respondió el objetivo:

```shell-session
$ cat arp.cache | sudo sx tcp --json -p 1-1000 192.168.0.171 \
    | jq -r 'select(.flags=="sa") | .port'      # sa = SYN+ACK -> abierto
```

`sa` (`SYN/ACK`) es puerto abierto; `r`/`ra` (`RST`) es cerrado; ausencia de respuesta es filtrado **o** puerto abierto según el tipo de escaneo — la ambigüedad clásica de FIN/NULL/Xmas.

# `sx udp` — puertos UDP

```shell-session
$ cat arp.cache | sudo sx udp --json -p 53 192.168.0.171
```

UDP es el escaneo difícil y `sx` no escapa a la regla: sin respuesta puede significar abierto-y-callado o filtrado. Se apoya en el análisis de las respuestas ICMP (`port unreachable` = cerrado). Para UDP con *payloads* específicos por protocolo, [[00 - Introducción a Nmap|Nmap]] (`-sU` con sus sondas) y ZMap (módulos UDP con *payload* precargado) siguen siendo mejores.

# `sx socks` — cazar proxies SOCKS5

```shell-session
$ sudo sx socks -p 1080 10.0.0.1/16
$ sudo sx socks --json -f ip_ports_file.jsonl
$ sudo sx socks -p 1080-4567 -f ips_file.jsonl
```

Detecta proxies SOCKS5 **vivos y funcionales**, no solo el puerto abierto: negocia el protocolo. Es un subcomando de nicho con un valor muy concreto en post-explotación — <mark style="background: #8000E1A6;">un SOCKS5 abierto en la red interna es una ruta de pivote regalada</mark>, sin necesidad de subir un túnel propio y sin dejar el binario de Ligolo-ng o `chisel` en disco ([[Pivoting y túneles.base|pivoting]]).

También es un hallazgo reportable por sí mismo: un SOCKS5 sin autenticar expuesto permite a cualquiera usar la red del cliente como salida.

# Flujo de referencia en red interna

```shell-session
# 1) inventario L2 (y ya sabes qué fabricantes hay)
$ sudo sx arp 192.168.0.0/24 --json | tee arp.cache

# 2) puertos de todos los hosts descubiertos, a ritmo civilizado
$ cat arp.cache | sudo sx tcp --json -p 1-65535 --rate 500/1s -f arp.cache > tcp.jsonl

# 3) quedarte con lo abierto y pasarlo a Nmap para la enumeración fina
$ jq -r 'select(.flags=="sa") | "\(.ip):\(.port)"' tcp.jsonl > abiertos.txt
$ sudo nmap -sCV -iL <(cut -d: -f1 abiertos.txt | sort -u) \
    -p "$(cut -d: -f2 abiertos.txt | sort -un | paste -sd, -)" -oA interno
```

El mismo reparto de siempre: descubrir rápido, enumerar despacio y solo lo que existe ([[03 - Salidas y pipeline hacia Nmap]]).

> [!info]+ Fuente
> [README de sx](https://github.com/v-byte-cpu/sx) — subcomandos `arp`, `icmp`, `tcp` (`syn`/`fin`/`null`/`xmas`/`--flags`), `udp` y `socks`, opción `--exit-delay` (300 ms por defecto), `--live`, entrada por `-a`/`-f` y todos los ejemplos citados.
