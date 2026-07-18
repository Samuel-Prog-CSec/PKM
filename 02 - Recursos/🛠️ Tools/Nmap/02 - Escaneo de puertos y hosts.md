---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Fecha de actualización: 2026-07-18
Nota previa: "[[01 - Host Discovery]]"
Nota siguiente: "[[03 - Enumeración de servicios y versiones]]"
Area: "[[Nmap.base|Nmap]]"
---
---

Con los hosts vivos localizados ([[01 - Host Discovery]]), el siguiente paso es averiguar **qué puertos y servicios** exponen. Interpretar bien la salida exige entender cómo Nmap deduce el estado de cada puerto a partir de los paquetes de respuesta — repasa los fundamentos de TCP/IP en [[Protocolos de red]] si el *three-way handshake* y los flags no te suenan de memoria.

# Los 6 estados de un puerto

<mark style="background: #ADCCFFA6;">Todo el resto del módulo se apoya en distinguir estos estados</mark>:

| Estado | Significado |
| --- | --- |
| `open` | La conexión al puerto se estableció (TCP, datagrama UDP o asociación SCTP). Hay un servicio escuchando. |
| `closed` | El objetivo respondió con un `RST`. El puerto es alcanzable pero no hay servicio. |
| `filtered` | Nmap no puede determinar si está abierto o cerrado: sin respuesta o con un error. Casi siempre = firewall. |
| `unfiltered` | Solo en el *ACK scan* (`-sA`): el puerto es alcanzable pero no se sabe si abierto o cerrado. |
| `open\|filtered` | Sin respuesta. Nmap no puede distinguir abierto de filtrado (típico en UDP y escaneos FIN/NULL/Xmas). |
| `closed\|filtered` | Solo en el *idle scan* (`-sI`): imposible saber si cerrado o filtrado. |

# Descubrir puertos TCP abiertos

Por defecto Nmap escanea los **top 1000** puertos TCP con SYN (`-sS`) — pero solo usa SYN si corres como `root` (los paquetes crudos requieren permisos de socket); si no, cae a *connect* (`-sT`). La selección de puertos se controla así:

```shell-session
$ nmap -p 22,25,80,445 <objetivo>     # puertos concretos
$ nmap -p 22-445 <objetivo>           # rango
$ nmap --top-ports=10 <objetivo>      # los N más frecuentes de la BD de Nmap
$ nmap -F <objetivo>                  # "fast": top 100
$ nmap -p- <objetivo>                 # los 65.535 puertos
```

## Leer un SYN scan a bajo nivel

Con `--packet-trace` (y desactivando ruido con `-Pn -n --disable-arp-ping`) se ve el intercambio real. Un puerto **cerrado** responde `RST/ACK`:

```shell-session
$ sudo nmap 10.129.2.28 -p 21 --packet-trace -Pn -n --disable-arp-ping

SENT (0.0429s) TCP 10.10.14.2:63090 > 10.129.2.28:21 S   ttl=56 ...
RCVD (0.0573s) TCP 10.129.2.28:21 > 10.10.14.2:63090 RA  ttl=64 ...

PORT   STATE  SERVICE
21/tcp closed ftp
```

`SENT ... S` = enviamos un SYN; `RCVD ... RA` = el objetivo responde con `RST+ACK` (`RA`): el `ACK` acusa recibo y el `RST` cierra la sesión → puerto cerrado. Un `SA` (`SYN/ACK`) en su lugar significaría abierto.

## Connect scan (`-sT`)

<mark style="background: #8000E1A6;">El *connect scan* completa el *three-way handshake* entero</mark>, así que es **el más preciso** para determinar el estado exacto — y **el menos sigiloso**: deja registro en los logs de casi cualquier servicio y lo detecta trivialmente cualquier IDS/IPS. Se usa cuando:

- No tienes `root` (es el único TCP scan sin privilegios).
- La precisión prima sobre el sigilo.
- Quieres ser "**educado**": al conectar como un cliente normal, es menos probable que desestabilices un servicio frágil que con escaneos más intrusivos.

```shell-session
$ sudo nmap 10.129.2.28 -p 443 -sT --reason -Pn -n

PORT    STATE SERVICE REASON
443/tcp open  https   syn-ack
```

# Puertos filtrados: *drop* vs *reject*

`filtered` no es un callejón sin salida: el **cómo** filtra el firewall es información. Hay dos comportamientos:

- **Drop** (descarta en silencio): no llega respuesta. Nmap reintenta hasta `--max-retries` (10 por defecto) → el escaneo de ese puerto se **alarga** notablemente (~2 s vs ~0,05 s). Silencio prolongado = paquetes descartados.
- **Reject** (rechaza activamente): el firewall responde con `ICMP type 3 code 3` (*port unreachable*).

```shell-session
$ sudo nmap 10.129.2.28 -p 445 --packet-trace -n --disable-arp-ping -Pn

SENT (0.0388s) TCP 10.10.14.2:52472 > 10.129.2.28:445 S ...
RCVD (0.0487s) ICMP 10.129.2.28 > 10.10.14.2 Port 445 unreachable (type=3/code=3)

445/tcp filtered microsoft-ds
```

> [!important]+ Un puerto rechazado por firewall es una pista, no un fin
> Si sabes que el host está vivo y un puerto vuelve `filtered` con *reject* (ICMP unreachable), <mark style="background: #FF5582A6;">hay un firewall protegiendo activamente ese puerto</mark> — casi siempre porque detrás hay algo que merece la pena. Anótalo para revisitarlo (evasión, otro vector, pivoting). El `--reason` te confirma si fue `no-response` (drop) o `port-unreach` (reject).

# Descubrir puertos UDP abiertos

<mark style="background: #FFB8EBA6;">Muchos administradores filtran los TCP y se olvidan de los UDP</mark>. UDP es *stateless* y sin *handshake*: Nmap manda un datagrama y, si no hay respuesta, no sabe si llegó → *timeout* largo y escaneo `-sU` **mucho más lento** que TCP.

```shell-session
$ sudo nmap 10.129.2.28 -F -sU

PORT     STATE         SERVICE
68/udp   open|filtered dhcpc
137/udp  open          netbios-ns
138/udp  open|filtered netbios-dgm
5353/udp open          zeroconf
... scanned in 98.07 seconds
```

La lectura del estado UDP:

- **Respuesta UDP de la aplicación** → `open` (solo si el servicio está configurado para responder).
- **`ICMP type 3 code 3`** (*port unreachable*) → `closed`.
- **Otro `ICMP unreachable`** (códigos ≠ 3) → `filtered`; **silencio** tras reintentos → `open|filtered` (la ambigüedad más común en UDP).

> [!warning]+ El UDP full-scan no es viable en tiempo real
> Un `-sU -p-` puede tardar horas. En un engagement real se escanean solo los UDP que importan (`53,67,123,137,161,500,1900,5353`) con `-sU --top-ports 20`, o se delega el barrido masivo a herramientas dedicadas (`udp-proto-scanner`, `masscan`) — ver [[09 - Arsenal de herramientas de escaneo]]. Para acelerar sin perder demasiado, combínalo con timing agresivo de [[05 - Rendimiento y timing]].

El flag `-sV` que aparece al final de estos escaneos abre la **enumeración de servicios y versiones**, que tratamos en [[03 - Enumeración de servicios y versiones]]. Referencia oficial de técnicas: [nmap.org/book/man-port-scanning-techniques.html](https://nmap.org/book/man-port-scanning-techniques.html).

# Enfoque profesional 2026

El `-p-` con Nmap sobre un `/24` es lento. El patrón actual es **descubrir rápido, enumerar despacio**: `masscan`/`RustScan` sacan los puertos abiertos de todo el rango en segundos, y luego Nmap hace `-sCV -p<puertos>` solo sobre ellos. Sube la velocidad con `--min-rate` (ver [[05 - Rendimiento y timing]]). Y recuerda que un barrido de top-1000 SYN es una firma de *portscan* evidente para cualquier IDS moderno: el sigilo real se trabaja en [[08 - Detección de escaneos y evasión moderna]].
