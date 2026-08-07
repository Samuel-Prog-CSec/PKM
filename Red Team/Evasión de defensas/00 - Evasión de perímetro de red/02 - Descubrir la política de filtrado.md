---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "Reconstruir qué permite la ACL y hacia dónde, combinando ACK scan, firewalking y sondas de flags — y saber leer el silencio"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Perfilar el perímetro antes de escanear]]"
Nota siguiente: "[[03 - Egress filtering - por dónde se sale]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Saber **qué** filtra el perímetro es distinto de saber qué puertos están abiertos. La ACL es una política, existe independientemente de los servicios, y conocerla vale para toda la fase posterior: te dice por dónde vas a poder entrar, salir y moverte cuando tengas un punto de apoyo.

# Las tres sondas y qué pregunta cada una

| Técnica | Pregunta que responde | Herramienta |
| --- | --- | --- |
| **ACK scan** | ¿Este puerto está filtrado o solo cerrado? | [[07 - Evasión de firewalls, IDS e IPS\|`nmap -sA`]] |
| **Firewalking** | ¿**Qué dispositivo** del camino lo filtra? | [[01 - Implementaciones vivas del firewalking\|`nmap --script firewalk`]] |
| **Sondas de flags** | ¿El filtro lleva estado o no? | [[01 - Tipos de escaneo con sx\|`sx tcp --flags`]] |

Se usan en ese orden y se contrastan entre sí. Ninguna es concluyente sola.

## ACK scan: filtrado vs cerrado

```shell-session
$ sudo nmap -sA -p 21,22,25,80,443,445,3389 objetivo -Pn -n --reason
```

Un `RST` de vuelta significa que el `ACK` llegó al host: el puerto está **no filtrado** (esté abierto o cerrado). Silencio significa **filtrado**. <mark style="background: #ADCCFFA6;">No dice si el puerto está abierto — dice si el firewall lo deja pasar</mark>, que es justo lo que queremos aquí.

Comparar `-sS` y `-sA` sobre el mismo conjunto de puertos es lo que da la lectura completa:

| `-sS` | `-sA` | Interpretación |
| --- | --- | --- |
| `open` | `unfiltered` | Servicio accesible, sin filtro. |
| `filtered` | `unfiltered` | <mark style="background: #FF5582A6;">El firewall lo permite pero **no hay servicio** escuchando</mark> — hueco en la ACL. |
| `filtered` | `filtered` | El firewall lo bloquea. |
| `closed` | `unfiltered` | Sin filtro, sin servicio. |

La segunda fila es el hallazgo que buscas: **una regla abierta sin nada detrás**. Es la puerta que estará ahí cuando controles un host de ese segmento.

## Firewalking: quién filtra

```shell-session
$ sudo nmap -sS -p- --traceroute objetivo -oA base
$ sudo nmap --script=firewalk --traceroute \
    --script-args=firewalk.max-probed-ports=-1 objetivo
```

Devuelve una tabla salto a salto de qué bloquea cada dispositivo del camino. Es lo que convierte "hay filtrado" en "el salto 5 filtra 21-23 y el salto 7 filtra 25", que ya es una descripción de arquitectura. Mecanismo, argumentos y —sobre todo— las cuatro condiciones que tienen que darse para que funcione, en [[00 - Firewalking - mapear ACLs con TTL]].

## Sondas de flags: ¿hay estado?

```shell-session
$ cat arp.cache | sudo sx tcp --flags ack --json -p 1-1000 objetivo
$ cat arp.cache | sudo sx tcp fin --json -p 23 objetivo
```

Si las sondas huérfanas (`ACK` suelto, `FIN` suelto) **producen alguna respuesta**, el filtro no lleva estado y tienes margen. Si todas mueren en silencio mientras un `SYN` normal sí llega, el filtro es **con estado** y toda la familia de técnicas de deformación de paquete queda descartada de entrada ([[04 - Fragmentación y evasión a nivel IP y TCP]]).

> [!warning]+ Contra Windows, FIN/NULL/Xmas mienten
> La pila de Windows responde `RST` a estos paquetes tanto si el puerto está abierto como si está cerrado, así que reporta **todo cerrado**. No es "no encontré nada": es un resultado positivo y falso. Identifica el sistema antes de interpretar ([[02 - Evasión de firewalls y detección con sx]]).

# Las dos vías que la gente olvida

## IPv6

```shell-session
$ sudo nmap -6 -sS -p- <dirección-ipv6> -Pn
$ naabu -host objetivo.com -iv 6 -silent
$ dnsx -l nombres.txt -aaaa -resp -silent
```

<mark style="background: #FFB86CA6;">En una red *dual-stack*, es muy frecuente que la política IPv6 no replique la de IPv4</mark>. Las reglas se escribieron para IPv4 hace años, IPv6 se habilitó después, y nadie duplicó la ACL. El resultado es un perímetro cuidadosamente cerrado por un lado y bastante abierto por el otro.

No es una técnica exótica: es una de las **diferencias de política más rentables** que quedan, y encontrarla es además un hallazgo excelente para el informe ("la política de filtrado IPv6 no replica la de IPv4, exponiendo los servicios X e Y").

## Puerto de origen de confianza

```shell-session
$ sudo nmap -sS -p 50000 --source-port 53 objetivo -Pn -n
$ ncat -nv --source-port 53 objetivo 50000
```

Sigue funcionando en firewalls con reglas perezosas que confían en el tráfico "de vuelta" de DNS (53), FTP-data (20) o Kerberos (88). Es de lo poco de la era clásica que aún cuela, porque la regla mal escrita sigue siendo mal escrita ([[07 - Evasión de firewalls, IDS e IPS#Source port (`--source-port`) — el truco que más funciona|el caso documentado en Nmap]]).

# Leer el silencio sin engañarte

Es la parte que más informes estropea.

> [!important]+ Silencio tiene cuatro causas y solo una es "bloqueado"
> 1. El firewall lo **descarta** (lo que asumes).
> 2. El paquete **se perdió** y no hubo reintento — el fallo clásico de [[00 - Introducción a masscan y el escaneo stateless|masscan]] y [[02 - Precisión, evasión y detección|RustScan]] con timeouts cortos.
> 3. **Te han bloqueado a ti** hace diez minutos y todo lo posterior es silencio, midas lo que midas.
> 4. El **método no aplica** en ese camino (sin router detrás, ICMP saliente filtrado…).
>
> <mark style="background: #8000E1A6;">Contramedida: ten siempre un **control positivo**</mark> — un puerto que sabes que responde (el 443 del web público). Sondéalo periódicamente durante la sesión. Si el control deja de responder, no has descubierto una política restrictiva: te han cortado, y todo lo medido desde ese momento es basura.

Y el corolario de método: **repite las mediciones con otro origen y en otro momento**. Una política de filtrado se confirma cuando dos orígenes independientes ven lo mismo.

# Qué llevarte al informe

No una lista de puertos, sino la política y su consecuencia:

> *«El perímetro permite tráfico entrante a 445/tcp, 3389/tcp y 5985/tcp hacia el segmento 10.0.20.0/24, sin que existan servicios publicados en esos puertos. Estas reglas no cumplen ninguna función actual y habilitan movimiento lateral hacia ese segmento desde la DMZ en caso de compromiso de un host de zona.»*

<mark style="background: #ADCCFFA6;">Reglas abiertas sin servicio detrás son residuos de migraciones que nadie limpió</mark>, y son de los hallazgos con mejor relación impacto/coste de remediación que se pueden entregar ([[06 - Cómo redactar un hallazgo|reporting]]).

> [!info]+ Fuentes
> `nmap -sA` y `--source-port` en [[07 - Evasión de firewalls, IDS e IPS]]; mecanismo y límites del firewalking en [[00 - Firewalking - mapear ACLs con TTL]] y [[01 - Implementaciones vivas del firewalking]]; sondas de flags y RFC 9293 en [[02 - Evasión de firewalls y detección con sx]].
