---
tags:
  - Protocolos
  - Proxies
  - Redes
  - Pentesting/Explotacion
Descripción: "Los cuatro tipos de proxy de interceptación (port-forward, SOCKS, HTTP forward y reverse) y cómo montarlos hoy con mitmproxy, socat o Scapy en vez de Canape"
Fecha de actualización: 2026-08-03
Nota previa: "[[02 - Aislar el tráfico de una aplicación con trazado de syscalls]]"
Nota siguiente: "[[04 - Redirigir el tráfico hacia tu proxy]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

La captura activa se interpone entre cliente y servidor. Cuesta más de montar que un *sniffer*, pero desbloquea lo que la pasiva no puede: <mark style="background: #FFB86CA6;">modificar el tráfico en vuelo, desactivar cifrado o compresión opcionales y romper el protocolo a propósito para ver cómo reacciona</mark>. Es un *man-in-the-middle* consentido, montado por ti.

[[00 - Introducción a los proxies web|Burp y ZAP]] resuelven esto para HTTP. Aquí interesa lo demás: el binario propietario en el puerto 12345.

## Los cuatro tipos, y cuándo usar cada uno

### 1. Port-forwarding proxy

El más simple: escuchas en un puerto local, y cada conexión entrante abre otra hacia el destino fijo y las une.

```shell-session
# socat: TCP local 4444 → servidor real, volcando ambos sentidos a fichero
$ socat -v -x TCP-LISTEN:4444,reuseaddr,fork TCP:10.10.10.5:12345 2> trafico.log
```

`-x` imprime en hexadecimal y `-v` marca la dirección de cada bloque. Para UDP: `UDP-LISTEN`/`UDP`.

**Ventaja**: cero protocolo propio, funciona con cualquier cosa, y es prácticamente la única vía sencilla para UDP.
**Límite**: un destino fijo por instancia. Si la aplicación abre conexiones a varios puertos —típico en RPC tipo CORBA o DCOM, donde primero hablas con un *broker* y este te devuelve un puerto dinámico— necesitas una instancia por puerto, y los puertos ni siquiera los conoces de antemano. La salida es descubrirlos antes con captura pasiva, o subir a SOCKS.

> [!warning]+ No expongas el proxy a la red
> Un proxy de análisis no implementa ninguna defensa. Bindea a `127.0.0.1` salvo que no quede otra; si tiene que escuchar en la LAN, acota con reglas de *firewall*. Esto vale igual para `mitmproxy`, cuyo modo `--listen-host 0.0.0.0` convierte tu máquina de auditoría en un *open proxy*.

### 2. Proxy SOCKS

SOCKS es el *port-forwarding* con esteroides: el cliente **le dice al proxy a dónde quiere ir** en un pequeño *handshake*, así que una sola instancia cubre todos los destinos.

| Versión | Aporta | RFC |
| - | - | - |
| SOCKS 4 | Solo IPv4 literal; auth = campo `USERNAME` en claro | — |
| SOCKS 4a | Resolución por **nombre** en el proxy | — |
| SOCKS 5 | IPv6, UDP *associate*, autenticación negociada | [RFC 1928](https://datatracker.ietf.org/doc/html/rfc1928) |

Petición SOCKS 4: `VER(1) CMD(1) PUERTO(2) IP(4) USERNAME(var) NULL(1)`, con `CMD=1` conectar y `CMD=2` *bind*. Ese `CMD=2` importa: protocolos como FTP activo necesitan que el **servidor** abra conexión hacia el cliente, y SOCKS lo contempla — a costa de complicar mucho el análisis, porque pasas a tener varios flujos por sesión.

Cómo empujar una aplicación a un SOCKS sin que lo soporte:

```shell-session
# Java: propiedades del runtime, sin tocar el código
$ java -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1080 -jar cliente.jar

# Cualquier binario dinámico en Linux: proxychains-ng (LD_PRELOAD)
$ proxychains4 -f proxychains.conf ./cliente
```

En Windows/macOS el equivalente comercial es `Proxifier`; el `Dante` que cita el libro sigue mantenido pero `proxychains-ng` es hoy lo habitual. **Ojo**: el proxy del sistema en Windows solo habla SOCKS 4 — sin IPv6 y resolviendo nombres en local.

### 3. Proxy HTTP directo (*forward*)

El cliente pone la **URI absoluta** en la línea de petición:

```http
GET http://www.domain.com/image.jpg HTTP/1.1
```

Y para TLS, `CONNECT` abre un túnel opaco ([RFC 9110 §9.3.6](https://datatracker.ietf.org/doc/html/rfc9110#section-9.3.6)):

```http
CONNECT www.domain.com:443 HTTP/1.1
```

```http
HTTP/1.1 200 Connection Established
```

A partir de la respuesta el TCP es transparente. <mark style="background: #FF5582A6;">Nadie comprueba que dentro vaya TLS de verdad</mark> — es el truco clásico para tunelizar protocolos binarios a través de un proxy corporativo, y la razón por la que los despliegues serios limitan `CONNECT` a 443. Como ofensiva, mirar [[00 - Introducción al pivoting y los túneles]].

Variables de entorno que respetan `curl`, `wget`, `apt`, `pip`, `git` y casi todo lo de consola:

```shell-session
$ export http_proxy=http://127.0.0.1:8080 https_proxy=http://127.0.0.1:8080
$ export no_proxy=localhost,127.0.0.1     # importante: evita lazos de proxy
```

### 4. Proxy HTTP inverso

Cuando **no controlas la configuración del cliente**. En vez de la URI absoluta, el proxy deduce el destino de la cabecera `Host`, obligatoria en HTTP/1.1:

```http
GET /image.jpg HTTP/1.1
Host: www.domain.com
```

Se combina siempre con una redirección de red ([[04 - Redirigir el tráfico hacia tu proxy]]): cambiar el `Host` a mano provocaría un **lazo de proxy** (el proxy se conecta a sí mismo recursivamente hasta agotar recursos).

## El *tooling*: Canape ha muerto, mitmproxy manda

El libro construye todos los ejemplos sobre **Canape Core**, la librería en C# del propio Forshaw. <mark style="background: #FF5582A6;">Canape lleva sin mantenimiento desde 2017</mark> y no es una opción hoy. La sustitución directa, con la ventaja de estar viva y en Python:

**`mitmproxy` (12.2.3, mayo 2026)** cubre los cuatro modos: `regular` (forward), `reverse`, `socks5`, `transparent`, `upstream` — y, crucialmente para esto, **`raw_tcp`** y **`raw_udp`** para protocolos que no son HTTP:

```shell-session
$ mitmdump --mode reverse:tcp://10.10.10.5:12345@4444 --set connection_strategy=lazy -s dump.py
```

```python
# dump.py — volcar un protocolo binario arbitrario en ambos sentidos
from mitmproxy import tcp, ctx

def tcp_start(flow: tcp.TCPFlow):
    ctx.log.info(f"[+] Conexión: {flow.client_conn.peername} -> {flow.server_conn.address}")

def tcp_message(flow: tcp.TCPFlow):
    msg = flow.messages[-1]
    origen = "C→S" if msg.from_client else "S→C"
    ctx.log.info(f"{origen} {len(msg.content):4}B  {msg.content[:32].hex(' ')}")
```

```text
[+] Conexión: ('127.0.0.1', 51544) -> ('10.10.10.5', 12345)
C→S    4B  42 49 4e 58
C→S   21B  00 00 00 0d 00 00 03 55 00 05 61 6c 69 63 65 04 4f 4e 59 58 00
S→C   10B  00 00 00 02 00 00 00 01 01 00
```

Fíjate en el primer mensaje: **4 octetos sueltos** con el mágico `BINX`. Es el recordatorio de que en TCP `tcp_message` te entrega **lo que trajo cada segmento**, no unidades del protocolo: un mensaje puede llegar partido en tres eventos y tres mensajes en uno solo. Cualquier addon que vaya más allá de volcar tiene que reensamblar por su cuenta ([[07 - Modificar el protocolo en vuelo]]).

`msg.content` es además **escribible**: lo que dejes ahí es lo que sale al cable. Ese único gancho es todo lo que hace falta para manipular el protocolo.

Cuando el *framing* es demasiado raro para mitmproxy, el escalón siguiente es un proxy propio en **Scapy** o en Python plano sobre `socketserver` — más trabajo, control total. Y para UDP con límites de paquete significativos, casi siempre acaba siendo Python plano.

> [!info]+ Fuentes
> - [mitmproxy — Modes of Operation](https://docs.mitmproxy.org/stable/concepts-modes/) y [addon API para TCP](https://docs.mitmproxy.org/stable/addons-examples/). Versión verificada: 12.2.3 (2026-05-12).
> - [RFC 1928](https://datatracker.ietf.org/doc/html/rfc1928) — SOCKS 5.
> - Forshaw, *Attacking Network Protocols*, cap. 2 — taxonomía original de proxies (implementada sobre Canape, hoy sin mantenimiento).
