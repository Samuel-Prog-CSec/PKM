---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Fecha de actualización: 2026-07-18
Nota previa: "[[00 - Introducción a Nmap]]"
Nota siguiente: "[[02 - Escaneo de puertos y hosts]]"
Area: "[[Nmap.base|Nmap]]"
---
---

Antes de escanear puertos hay que saber **qué hosts están vivos**. En un pentest interno de una `/16` no tiene sentido lanzar `-p-` contra 65.000 IPs muertas: primero se hace un *host discovery* (o *ping sweep*) para reducir el universo a las máquinas que responden. <mark style="background: #ADCCFFA6;">El *host discovery* es la fase de descubrir qué sistemas están activos en el rango objetivo</mark> antes de gastar tiempo en ellos.

# Ping sweep del rango

`-sn` le dice a Nmap **desactiva el escaneo de puertos**: solo descubre hosts. Es el barrido base:

```shell-session
$ sudo nmap 10.129.2.0/24 -sn -oA tnet | grep for | cut -d" " -f5

10.129.2.4
10.129.2.10
10.129.2.11
10.129.2.18
```

| Opción | Descripción |
| --- | --- |
| `10.129.2.0/24` | Rango objetivo (CIDR). |
| `-sn` | Desactiva el port scan (solo descubrimiento). |
| `-oA tnet` | Guarda el resultado en **todos** los formatos con prefijo `tnet`. |

> [!important]+ Guardar SIEMPRE los resultados
> `-oA` desde el primer escaneo no es opcional en un engagement: sirve para comparar, documentar y reportar. El *pipe* `grep for | cut` extrae las IPs de las líneas `Nmap scan report for X`, pero es frágil. En 2026 se prefiere parsear el formato *greppable* directamente:
> ```shell-session
> $ sudo nmap 10.129.2.0/24 -sn -oG - | awk '/Up$/{print $2}'
> ```
> Ver [[06 - Guardar y explotar resultados]] para el manejo serio de la salida.

## Definir los objetivos

Nmap acepta objetivos de varias formas, combinables:

```shell-session
$ sudo nmap -sn -oA tnet -iL hosts.lst          # lista desde fichero (-iL)
$ sudo nmap -sn -oA tnet 10.129.2.18 10.129.2.19 10.129.2.20   # IPs sueltas
$ sudo nmap -sn -oA tnet 10.129.2.18-20         # rango en el último octeto
```

En un test interno es habitual que el cliente entregue una `hosts.lst`; `-iL` la lee en vez de teclear IPs. <mark style="background: #FFB8EBA6;">Que un host no aparezca no significa que esté apagado</mark>: puede estar ignorando los `ICMP echo` por su firewall, y Nmap lo marca como inactivo al no recibir respuesta.

# Cómo descubre Nmap: ARP (L2) vs ICMP (L3)

Aquí está el detalle que casi todo el mundo pasa por alto. Cuando el objetivo está en **el mismo segmento de red** (capa 2), Nmap **no** manda primero un `ICMP echo`: manda un **ARP request**, y con la `ARP reply` ya sabe que el host vive. Se ve con `--packet-trace`:

```shell-session
$ sudo nmap 10.129.2.18 -sn -oA host -PE --packet-trace

SENT (0.0074s) ARP who-has 10.129.2.18 tell 10.10.14.2
RCVD (0.0309s) ARP reply 10.129.2.18 is-at DE:AD:00:00:BE:EF
Host is up (0.023s latency).
```

> [!success]+ `--reason` te dice el porqué
> `--reason` muestra qué respuesta concreta marcó el host como vivo (`received arp-response`). Es oro para entender por qué un host aparece o no, y para el reporte.

<mark style="background: #8000E1A6;">En una red local, el ARP es más fiable que el ICMP</mark>: un host puede filtrar ICMP, pero si está en tu segmento **tiene** que responder ARP para participar en la red. Por eso el descubrimiento interno por ARP casi nunca falla. Para forzar ICMP y ver la diferencia, se desactiva el ARP con `--disable-arp-ping`:

```shell-session
$ sudo nmap 10.129.2.18 -sn -PE --packet-trace --disable-arp-ping

SENT (0.0107s) ICMP [10.10.14.2 > 10.129.2.18 Echo request (type=8/code=0) ...]
RCVD (0.0152s) ICMP [10.129.2.18 > 10.10.14.2 Echo reply (type=0/code=0) ...]
```

# Tipos de probe de descubrimiento

Cuando el ICMP echo está filtrado (lo normal en redes bien administradas y en cualquier host expuesto a Internet), hay que probar otros vectores. Estos son los que se combinan en la práctica:

| Probe | Qué envía | Cuándo usarlo |
| --- | --- | --- |
| `-PE` / `-PP` / `-PM` | ICMP echo / timestamp / netmask | Interno; a veces pasan `-PP`/`-PM` donde `-PE` no. |
| `-PS<puertos>` | TCP SYN a esos puertos | El más útil contra hosts con ICMP filtrado (`-PS21,22,80,443,3389`). |
| `-PA<puertos>` | TCP ACK | Atraviesa algunos firewalls sin estado. |
| `-PU<puertos>` | UDP | Servicios UDP (53, 161). |
| `-PR` | ARP | Por defecto en LAN; imbloqueable dentro del segmento. |
| `-PO` | Protocolos IP crudos | Descubrir por protocolo soportado. |

<mark style="background: #FF5582A6;">Dos flags que cambian la vida en producción</mark>:

- **`-Pn`** — salta el descubrimiento y trata **todos** los hosts como vivos. Imprescindible cuando el objetivo bloquea ICMP/ARP pero sabes que está ahí (típico en objetivos de Internet y hosts Windows con firewall por defecto). Sin `-Pn`, Nmap "no ve" el host y ni siquiera escanea puertos.
- **`-n`** — desactiva la resolución DNS inversa. Acelera mucho el barrido y evita consultas DNS que delatan tu actividad al resolver de la organización.

> [!warning]+ El error clásico
> Escanear un host Windows moderno sin `-Pn` y concluir "está caído". El *Windows Defender Firewall* descarta ICMP echo por defecto → Nmap lo marca *down* → no escanea nada. Ante silencio sospechoso, repite con `-Pn` o con `-PS`/`-PA` a puertos comunes antes de descartar el host.

# Detección y evasión (micro)

Un *ping sweep* de un `/24` genera un patrón evidente (un origen tocando 254 IPs en segundos) que cualquier IDS marca como *network scan*. Si el sigilo importa: reduce la ventana de probes, usa solo `-PS` a un puerto concreto en vez de barrer, o parte de una lista de IPs ya conocida (`-iL`) para no barrer a ciegas. El desarrollo completo está en [[08 - Detección de escaneos y evasión moderna]].

# Arsenal complementario

Para descubrimiento puro, en LAN suelen ser más rápidos y sigilosos que Nmap: `arp-scan` y `netdiscover` (ARP directo), `fping` (barridos ICMP masivos y paralelos) y `masscan --ping` a escala de Internet. Se detallan en [[09 - Arsenal de herramientas de escaneo]]. Estrategias avanzadas de descubrimiento: [nmap.org/book/host-discovery-strategies.html](https://nmap.org/book/host-discovery-strategies.html).
