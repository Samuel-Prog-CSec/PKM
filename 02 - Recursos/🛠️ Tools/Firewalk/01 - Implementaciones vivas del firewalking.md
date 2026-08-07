---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "El binario firewalk murió en 2002: hoy la técnica se ejecuta con el NSE de Nmap, y las alternativas que quedan vivas para sondear un camino"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Firewalking - mapear ACLs con TTL]]"
Nota siguiente: "[[02 - Límites, detección y contramedidas]]"
Area: "[[Firewalk.base|Firewalk]]"
---
---

<mark style="background: #FF5582A6;">La herramienta `firewalk` original está muerta</mark> — su última versión es de alrededor de 2002 y sigue apareciendo en tutoriales que nadie ha revisado. Esta nota recoge lo que de verdad se usa hoy para lo mismo.

# La implementación de referencia: el NSE de Nmap

```shell-session
$ sudo nmap --script=firewalk --traceroute <objetivo>
$ sudo nmap --script=firewalk --traceroute --script-args=firewalk.max-retries=1 <objetivo>
$ sudo nmap --script=firewalk --traceroute --script-args=firewalk.probe-timeout=400ms <objetivo>
$ sudo nmap --script=firewalk --traceroute --script-args=firewalk.max-probed-ports=7 <objetivo>
```

`--traceroute` **no es opcional**: el script consume los datos de traza de Nmap para saber la distancia a cada salto. Sin él no arranca. Y necesita privilegios, porque construye los paquetes a mano.

## Cómo trabaja (y en qué mejora al original)

El clásico sondeaba con un TTL fijo. El NSE hace algo más útil: <mark style="background: #ADCCFFA6;">empieza con el TTL a la distancia del objetivo y, cada vez que una sonda expira sin respuesta, la reenvía con el TTL decrementado en uno, hasta llegar a 1</mark>. Al recibir un `ICMP Time Exceeded` marca ese puerto como reenviado por ese salto.

El efecto es que no solo te dice *qué* está bloqueado, sino **en qué salto** se bloquea:

```
| firewalk:
| HOP HOST         PROTOCOL  BLOCKED PORTS
| 2   192.168.1.1  tcp       21-23,80
|                  udp       21-23,80
| 6   10.0.1.1     tcp       67-68
| 7   10.0.1.254   tcp       25
|_                 udp       25
```

Esa tabla es un mapa de la política de filtrado a lo largo del camino: el salto 2 bloquea FTP/Telnet/SSH/HTTP, el 6 bloquea DHCP y el 7 bloquea SMTP. <mark style="background: #8000E1A6;">En un informe, eso es una descripción de la arquitectura de red del cliente</mark>, no una lista de puertos.

## Argumentos

| Argumento | Por defecto | Qué controla |
| --- | --- | --- |
| `firewalk.max-retries` | **2** | Retransmisiones por sonda |
| `firewalk.probe-timeout` | **2000 ms** | Cuánto se considera válida una sonda |
| `firewalk.recv-timeout` | **20 ms** | Duración del bucle de captura |
| `firewalk.max-active-probes` | **20** | Sondas en paralelo |
| `firewalk.max-probed-ports` | **10** | Puertos por protocolo (**-1** = todos) |

> [!important]+ El default de 10 puertos es lo primero que hay que cambiar
> `max-probed-ports=10` limita el sondeo a diez puertos por protocolo, lo que da una foto muy parcial. Para un mapeo serio, `-1`. Pero ojo con el aviso del propio script: <mark style="background: #FFB8EBA6;">el sondeo UDP se vuelve muy lento cuando hay muchos puertos bloqueados cerca del escáner</mark>, porque cada uno agota el timeout completo.

> [!warning]+ Solo sondea puertos "sin respuesta"
> El script trabaja **únicamente** sobre puertos que Nmap marcó como `filtered` (TCP) u `open|filtered` (UDP) con razón *no-response*. Los que devolvieron un rechazo administrativo explícito (`ICMP prohibited`) quedan fuera, porque ahí ya sabes la respuesta. Consecuencia práctica: hay que **hacer primero un escaneo que produzca esos estados** — si escaneas solo los top-100 y todos salen `closed`, el firewalk no tiene sobre qué trabajar.

# Alternativas vivas

## `hping3` — el clásico, hoy legado

```shell-session
$ sudo hping3 --traceroute -S -p 80 <objetivo>
$ sudo hping3 -S -p 80 -t 6 -c 1 <objetivo>       # TTL fijado a mano
```

Fue durante años la navaja para construir paquetes a mano. Sigue empaquetado en Kali y funciona, pero <mark style="background: #FF5582A6;">su último *release* real es de 2005 y el repositorio (`antirez/hping`) solo recibió un *push* en julio de 2024</mark>, sin versiones. No tiene IPv6 usable. Úsalo si ya lo conoces; no lo aprendas hoy desde cero.

## `nping` — el sustituto natural

```shell-session
$ sudo nping --tcp -p 80 --ttl 6 -c 1 <objetivo>
$ sudo nping --tcp -p 80 --flags ack --ttl 6 <objetivo>
```

Viene **con Nmap**, así que ya lo tienes instalado y se mantiene con él. Cubre lo mismo que `hping3` para construir sondas sueltas con TTL y flags arbitrarios, con IPv6 incluido. Es la respuesta correcta cuando quieres una sonda concreta y no un escaneo.

## `Scapy` — cuando necesitas exactamente tu paquete

```python
from scapy.all import IP, TCP, sr1

# sonda de firewalking: TTL justo detrás del filtro
ans = sr1(IP(dst="203.0.113.10", ttl=6) / TCP(dport=80, flags="S"),
          timeout=2, verbose=0)

if ans is None:
    print("80/tcp -> bloqueado por la ACL (silencio)")
elif ans.haslayer("ICMP") and ans["ICMP"].type == 11:
    print(f"80/tcp -> permitido; expiró en {ans.src}")
else:
    print(f"80/tcp -> respuesta inesperada: {ans.summary()}")
```

Es la vía cuando el caso se sale de lo que cubren las herramientas: TTL por puerto, combinaciones de flags raras, protocolos no TCP/UDP. Ver [[01 - Definir un protocolo propietario en Scapy]].

## `sx` — sondas de flags a escala

```shell-session
$ cat arp.cache | sudo sx tcp --flags ack --json -p 1-1000 192.168.0.171
```

No hace firewalking por TTL, pero cubre la otra mitad del problema: sondear muchos puertos con flags arbitrarios para deducir la política ([[02 - Evasión de firewalls y detección con sx]]).

## Traceroute a nivel 4

Cuando el ICMP está bloqueado —lo normal— un `traceroute` clásico no llega ni a la fase 1:

| Herramienta | Qué aporta |
| --- | --- |
| **`tcptraceroute`** | Traza con `SYN` a un puerto concreto en vez de UDP/ICMP. Atraviesa donde el traceroute normal muere. |
| **`lft`** (*Layer Four Traceroute*) | Lo mismo con más opciones y detección de firewalls por el camino. |
| **`nmap --traceroute`** | Integrado; usa el mismo tipo de sonda del escaneo, así que hereda su capacidad de atravesar. |
| **`0trace`** | Traza **dentro de una conexión TCP ya establecida**. <mark style="background: #8000E1A6;">Sortea firewalls con estado</mark>, porque las sondas pertenecen a una sesión legítima. Herramienta antigua (Michal Zalewski) y sin mantenimiento, pero la idea es la buena y se reimplementa fácil con Scapy. |

<mark style="background: #FFB86CA6;">La idea de `0trace` es la que sigue siendo relevante en 2026</mark>: contra un perímetro con inspección de estado, cualquier sonda huérfana se descarta; una que viaja dentro de una sesión establecida, no. Si el firewalking clásico falla por la condición del estado ([[00 - Firewalking - mapear ACLs con TTL]]), ese es el camino a explorar.

> [!success]+ Secuencia práctica
> ```shell-session
> $ sudo nmap -sS -p- --traceroute <objetivo> -oA base       # 1) generar estados filtered
> $ sudo nmap --script=firewalk --traceroute \
>     --script-args=firewalk.max-probed-ports=-1 <objetivo>  # 2) mapear la ACL
> $ sudo nping --tcp -p <puerto> --ttl <n> -c 3 <objetivo>   # 3) confirmar a mano
> ```
> El paso 3 no es opcional: el resultado del NSE es una inferencia y conviene verificar al menos los puertos que vayas a reportar.

> [!info]+ Fuentes
> - [`firewalk.nse`](https://github.com/nmap/nmap/blob/master/scripts/firewalk.nse) del repositorio de Nmap — mecanismo de decremento de TTL, argumentos y sus valores por defecto, salida de ejemplo, prerrequisitos (`--traceroute`, privilegios) y limitaciones declaradas.
> - Estado de `hping` verificado el 2026-08-04 contra la API de GitHub (`antirez/hping`: sin *releases*, último *push* julio de 2024).
