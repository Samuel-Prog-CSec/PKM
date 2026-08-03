---
tags:
  - Proxies
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Escribir addons en Python para parsear, reescribir y romper un protocolo binario en vuelo, con el framing recalculado automáticamente"
Fecha de actualización: 2026-08-03
Nota previa: "[[00 - Introducción a mitmproxy]]"
Nota siguiente: 
Area: "[[mitmproxy.base|mitmproxy]]"
---
---

Los *addons* son lo que convierte a mitmproxy en el sustituto de `Canape`. Un fichero de Python con funciones de nombre reservado que mitmproxy invoca en cada evento del flujo.

## Los eventos que importan

| Evento | Cuándo se dispara |
| - | - |
| `tcp_start(flow)` | Nueva conexión TCP cruda |
| **`tcp_message(flow)`** | **Cada mensaje**, en cualquier dirección. El principal |
| `tcp_end(flow)` / `tcp_error(flow)` | Cierre o fallo |
| `request(flow)` / `response(flow)` | Equivalentes para HTTP |
| `tls_clienthello(data)` | Antes del *handshake*: permite decidir si interceptar o dejar pasar |
| `load(loader)` | Al cargar el addon: registrar opciones propias |

En `tcp_message`, `flow.messages[-1]` es el mensaje recién llegado. Sus dos campos:

- **`.from_client`** — `True` si va del cliente al servidor.
- **`.content`** — los bytes, y es **escribible**: lo que dejes ahí es lo que sale al cable.

## Addon completo para un protocolo con longitud y checksum

```python
"""proto.py — parsea, muestra y reescribe un protocolo binario propietario.
   Formato: [len:u32][chksum:u32][tag:u8][cuerpo]
   Uso: mitmdump --mode reverse:tcp://10.10.10.5:12345@4444 \
                 --set connection_strategy=lazy -s proto.py
"""
import struct
from mitmproxy import tcp, ctx

COMANDOS = {0: "HELLO", 1: "HELLO_ACK", 2: "QUIT", 3: "MSG",
            5: "PRIVMSG", 6: "LIST_REQ", 7: "LIST_RESP"}


def desenvolver(raw: bytes):
    """flujo -> lista de (tag, cuerpo). Tolera varios mensajes por segmento."""
    fuera, off = [], 0
    while off + 9 <= len(raw):
        (length, _chk) = struct.unpack_from("!II", raw, off)
        cuerpo = raw[off + 8: off + 8 + length]
        if len(cuerpo) < length:          # mensaje partido entre segmentos
            break
        fuera.append((cuerpo[0], cuerpo[1:]))
        off += 8 + length
    return fuera


def envolver(tag: int, cuerpo: bytes) -> bytes:
    """Reconstruye el framing: longitud y checksum SIEMPRE recalculados."""
    datos = bytes([tag]) + cuerpo
    chk = (tag + sum(cuerpo)) & 0xFFFFFFFF
    return struct.pack("!II", len(datos), chk) + datos


class Proto:
    def load(self, loader):
        loader.add_option("sin_cifrado", bool, False,
                          "Fuerza el modo sin cifrado en la negociación")

    def tcp_message(self, flow: tcp.TCPFlow):
        msg = flow.messages[-1]
        origen = "C→S" if msg.from_client else "S→C"

        for tag, cuerpo in desenvolver(msg.content):
            nombre = COMANDOS.get(tag, f"DESCONOCIDO({tag})")
            ctx.log.info(f"{origen} {nombre:11} {len(cuerpo):4}B "
                         f"{cuerpo[:48].hex(' ')}")

        # --- Manipulación 1: desactivar el cifrado opcional en la negociación
        if ctx.options.sin_cifrado and msg.from_client and len(flow.messages) == 1:
            partes = desenvolver(msg.content)
            if partes and partes[0][0] == 0:                     # comando HELLO
                tag, cuerpo = partes[0]
                msg.content = envolver(tag, cuerpo[:-1] + b"\x00")
                ctx.log.warn("[+] Cifrado opcional desactivado")

        # --- Manipulación 2: inyectar una longitud imposible (prueba manual)
        # if msg.from_client and b"PAYLOAD" in msg.content:
        #     msg.content = struct.pack("!II", 0xFFFFFFFF, 0) + b"\x03AAAA"


addons = [Proto()]
```

Los dos puntos que hacen que esto funcione:

1. **`envolver()` recalcula longitud y checksum.** Modificas el cuerpo libremente y el paquete sale bien formado — sin esto, el otro extremo cierra la conexión en cuanto tocas un byte ([[07 - Modificar el protocolo en vuelo]]).
2. **`desenvolver()` itera**, porque un segmento puede traer varios mensajes seguidos. Un addon que asuma «un evento = un mensaje» falla en cuanto haya carga real.

> [!warning]+ Lo que este addon todavía NO hace: bufferizar entre eventos
> `desenvolver()` corta cuando el último mensaje viene incompleto (`if len(cuerpo) < length: break`), pero **descarta ese resto**. Si un mensaje llega partido entre dos segmentos TCP, se pierde.
>
> Para volcar y observar da igual. Para **modificar de forma fiable** hay que acumular por conexión:
>
> ```python
> class Proto:
>     def tcp_start(self, flow):
>         flow.metadata["buf_c"] = b""      # un búfer por sentido y por conexión
>         flow.metadata["buf_s"] = b""
>
>     def tcp_message(self, flow):
>         msg = flow.messages[-1]
>         clave = "buf_c" if msg.from_client else "buf_s"
>         datos = flow.metadata[clave] + msg.content
>         mensajes, resto = desenvolver_todo(datos)   # devuelve también lo no consumido
>         flow.metadata[clave] = resto                # se guarda para el evento siguiente
> ```
>
> Es el equivalente en el proxy de lo que `dissect_tcp_pdus` hace por ti en un disector de Wireshark ([[06 - Dissectors de Wireshark en Lua]]). Aquí no hay atajo: lo escribes tú.

## Opciones y control desde la línea de comandos

```shell-session
$ mitmdump -s proto.py --set sin_cifrado=true --mode reverse:tcp://host:12345@4444
```

`loader.add_option` registra opciones propias, así que el mismo addon sirve para observar y para atacar sin editar el fichero.

## Patrones útiles

**Volcar a fichero para analizar aparte:**

```python
def tcp_message(self, flow):
    m = flow.messages[-1]
    d = "out" if m.from_client else "in"
    with open(f"{d}.bin", "ab") as fh:
        fh.write(m.content)
```

**Interceptar TLS de forma selectiva** (dejar pasar sin descifrar lo que no interesa, para no romper el *pinning* de otros dominios):

```python
def tls_clienthello(self, data):
    if data.client_hello.sni not in ("api.objetivo.com",):
        data.ignore_connection = True
```

**Fuzzear desde el propio proxy**, mutando el tráfico legítimo del cliente:

```python
import random

def tcp_message(self, flow):
    m = flow.messages[-1]
    if m.from_client and random.random() < 0.05:      # 5 % de los mensajes
        b = bytearray(m.content)
        b[random.randrange(len(b))] ^= 1 << random.randrange(8)
        m.content = bytes(b)
        ctx.log.warn("[fuzz] mensaje mutado")
```

Es *fuzzing* con corpus perfecto —tráfico real de la aplicación— y sin escribir un generador. Con el `envolver()` de arriba aplicado después de mutar, los casos llegan al parser en vez de morir en la validación ([[00 - Fuzzing de protocolos de red]]).

> [!warning]+ Depurar addons
> Un fallo en el addon **no** detiene mitmproxy: aparece en el log y el mensaje pasa sin tocar. Si «no hace nada», mira la salida con `-v`. Y para recargar sin reiniciar, mitmproxy vigila el fichero y lo recarga solo al guardarlo.

> [!info]+ Fuentes
> - [mitmproxy — Addons](https://docs.mitmproxy.org/stable/addons-overview/), [Events](https://docs.mitmproxy.org/stable/addons-events/) y [ejemplos oficiales](https://github.com/mitmproxy/mitmproxy/tree/main/examples/addons).
