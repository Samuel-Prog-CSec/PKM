---
tags:
  - Protocolos
  - Proxies
  - Pentesting/Explotacion
Descripción: "Degradar el protocolo desde el proxy para poder analizarlo: apagar cifrado y compresión opcionales, recalcular checksums y longitudes, y replay del tráfico capturado"
Fecha de actualización: 2026-08-03
Nota previa: "[[06 - Dissectors de Wireshark en Lua]]"
Nota siguiente: "[[08 - Detección y evasión del análisis activo]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

Un proxy que solo mira es un *sniffer* caro. Lo que justifica el coste de interponerse es poder **reescribir**: y la primera aplicación no es atacar, es <mark style="background: #8000E1A6;">quitarle al protocolo todo lo que estorba para entenderlo</mark>.

## La jugada: degradar la negociación

Casi todo protocolo con cifrado o compresión **opcionales** los negocia al principio de la conexión: el cliente anuncia qué soporta, el servidor elige. Si controlas ese primer paquete, eliges tú.

Comparativa de la misma conexión con y sin el `--xor` del cliente:

```text
SALIENTE con XOR : 00 05 75 73 65 72 32 04 4F 4E 59 58 01   ..user2.ONYX.
SALIENTE sin XOR : 00 05 75 73 65 72 32 04 4F 4E 59 58 00   ..user2.ONYX.
ENTRANTE con XOR : 01 E7                                    ..
ENTRANTE sin XOR : 01 00                                    ..
```

Dos diferencias de un byte. El **último byte del paquete saliente** (`01` vs `00`) es la bandera «soporto cifrado»; el **último byte de la respuesta** (`0xE7` vs `0x00`) es la clave XOR que asigna el servidor. Poner la bandera a `0` hace que el servidor devuelva clave `0`, y `A XOR 0 = A`: <mark style="background: #8000E1A6;">el cifrado queda anulado sin haber implementado nada</mark>.

> [!warning]+ Esos volcados son el **cuerpo**, no el flujo crudo
> Las líneas de arriba muestran el mensaje **ya sin el *framing***: empiezan por el tag (`00` = HELLO, `01` = HELLO_ACK). Lo que llega a `tcp_message` en mitmproxy es el flujo TCP tal cual, con sus 8 octetos de longitud y checksum delante. Si escribes la condición sobre `msg.content[0]` estarás mirando el byte alto de la longitud —que casi siempre vale `0x00`— y creerás haber encontrado el HELLO en todos los mensajes.
>
> Por eso el addon tiene que **desenvolver primero**:

```python
# addon de mitmproxy: forzar el modo sin cifrado en la negociación
import struct
from mitmproxy import tcp, ctx

def desenvolver(raw: bytes):
    """[len:u32][chk:u32][tag:u8][cuerpo] -> (tag, cuerpo), o None si no cuadra."""
    if len(raw) < 9:
        return None
    length = struct.unpack_from("!I", raw, 0)[0]
    cuerpo = raw[8:8 + length]
    if len(cuerpo) < length:
        return None
    return cuerpo[0], cuerpo[1:]

def envolver(tag: int, cuerpo: bytes) -> bytes:
    datos = bytes([tag]) + cuerpo
    chk = (tag + sum(cuerpo)) & 0xFFFFFFFF          # recalculado, no copiado
    return struct.pack("!II", len(datos), chk) + datos

def tcp_message(flow: tcp.TCPFlow):
    msg = flow.messages[-1]
    if not (msg.from_client and len(flow.messages) == 1):
        return                                       # solo el primer mensaje del cliente
    p = desenvolver(msg.content)
    if not p or p[0] != 0x00:                        # tag 0 = HELLO
        return
    tag, cuerpo = p
    msg.content = envolver(tag, cuerpo[:-1] + b"\x00")   # último byte = flag de cifrado
    ctx.log.warn("[+] Cifrado opcional desactivado en la negociación")
```

```text
[+] Cifrado opcional desactivado en la negociación
S→C HELLO_ACK  2B: 01 00          ← la respuesta ya trae clave 0x00
```

Que el servidor conteste `01 00` en vez de `01 E7` es la confirmación de que ha funcionado: a partir de ahí todo el tráfico va en claro.

> [!important]+ Por qué es tan rentable
> Implementar un XOR de un byte cuesta nada, pero el mismo patrón sirve cuando la opción es un **algoritmo de compresión propietario** o un cifrado que no piensas reimplementar. Desactivar la funcionalidad en la negociación te ahorra revertirla. Y si el protocolo **no permite desactivarla** pero acepta un algoritmo débil de la lista, estás ante un *downgrade attack* de manual — el mismo patrón que [[10 - Downgrade Attacks]] en TLS, y un hallazgo reportable por sí solo.

## Reparar lo que rompes

En cuanto modificas la carga útil, las longitudes y los *checksums* dejan de cuadrar y el otro extremo cierra la conexión. La solución no es calcularlos a mano: es que el proxy **quite el *framing* al leer y lo reconstruya al escribir**.

```python
import struct

def desenvolver(raw: bytes):
    """flujo → (tag, datos), descartando longitud y checksum"""
    length, chksum = struct.unpack("!II", raw[:8])
    cuerpo = raw[8:8 + length]
    return cuerpo[0], cuerpo[1:]

def envolver(tag: int, datos: bytes) -> bytes:
    cuerpo = bytes([tag]) + datos
    chksum = tag + sum(datos)                      # recalculado, no copiado
    return struct.pack("!II", len(cuerpo), chksum) + cuerpo
```

Con esas dos funciones en la capa de parseo, <mark style="background: #FF5582A6;">puedes alterar `datos` libremente y el paquete sale siempre bien formado</mark>. Es exactamente el mismo mecanismo que en Burp hace que puedas editar un cuerpo HTTP sin tocar el `Content-Length` — solo que aquí lo escribes tú.

Si el campo de integridad resulta ser un **MAC con clave** en vez de un checksum, esto no funciona: sin la clave no puedes reconstruirlo. Ahí el camino es sacar la clave del binario ([[02 - Localizar el código de red en un binario]]) o enganchar la función que lo calcula con Frida.

## Replay del tráfico capturado

A veces no hace falta proxy: basta reproducir bytes contra el servidor. Es la vía más rápida para probar si un mensaje concreto dispara algo.

```shell-session
# 1) Exportar una dirección de la captura a binario
$ tshark -r captura.pcap -T fields -e data -Y 'tcp.srcport==26082' | xxd -p -r > saliente.bin

# 2) Reproducirlo contra el servidor, guardando la respuesta
$ nc 10.10.10.5 12345 < saliente.bin > respuesta.bin

# 3) Y al revés: hacerse pasar por el servidor ante un cliente real
$ nc -l -p 12345 < entrante.bin > nueva_saliente.bin
```

Editas `saliente.bin` con un editor hexadecimal y vuelves a lanzarlo. Es *fuzzing* manual, y sorprendentemente productivo.

**UDP no se puede reproducir así**: `nc` vuelca el fichero como un flujo y se cargan los límites de datagrama, que en UDP son semánticos. Hay que respetarlos:

```python
import sys, binascii
from socket import socket, AF_INET, SOCK_DGRAM

s = socket(AF_INET, SOCK_DGRAM); s.settimeout(1)
destino = (sys.argv[1], int(sys.argv[2]))
for linea in sys.stdin:                       # una línea hex = un datagrama
    s.sendto(binascii.unhexlify(linea.strip()), destino)
    try:
        datos, _ = s.recvfrom(65535)
        print(datos.hex(" "))
    except OSError:
        pass
```

Se alimenta con `tshark -T fields -e data -r udp.pcap 'udp.dstport==12345'`. Recuerda `--disable-protocol <x>` si Wireshark ha decidido disecar tu tráfico como otra cosa y `data` sale vacío.

> [!warning]+ El replay ciego rompe protocolos con estado
> Si el protocolo lleva números de secuencia, *nonces*, tokens de sesión o marcas de tiempo, reproducir una captura antigua falla en el segundo mensaje. Y si **no falla** —si el servidor acepta tal cual una sesión grabada— acabas de encontrar un **fallo de anti-replay**, que suele ser vulnerabilidad por derecho propio: reproducir la autenticación de otro usuario es *authentication bypass*.

## De aquí al hallazgo

Modificar en vuelo es también el mecanismo de prueba manual: cambia una longitud por `0xFFFFFFFF`, mete un índice negativo, alarga una cadena hasta 10.000 bytes, envía un tag que el cliente nunca usa. Cada uno de esos gestos corresponde a una clase concreta del catálogo de [[00 - Clases de vulnerabilidad en un servicio de red]]. Automatizarlos es, literalmente, [[00 - Fuzzing de protocolos de red|fuzzing]].

> [!info]+ Fuentes
> - [mitmproxy — Addons and Events](https://docs.mitmproxy.org/stable/addons-events/): `tcp_message`, `tcp_start`, `tcp_end`.
> - Forshaw, *Attacking Network Protocols*, caps. 5 y 8 (ejemplos originales en Canape, sin mantenimiento desde 2017).
