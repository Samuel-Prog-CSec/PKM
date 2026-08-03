---
tags:
  - Redes
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Escribir una clase Packet propia para que Scapy entienda, construya y fuzzee un protocolo binario que no está en su catálogo"
Fecha de actualización: 2026-08-03
Nota previa: "[[🔨📦 Scapy]]"
Nota siguiente: 
Area: "[[Scapy.base|Scapy]]"
---
---

El catálogo de Scapy cubre los protocolos estándar. Para uno propietario —el que has deducido analizando el cable ([[05 - Del hex dump a la estructura del protocolo]])— defines tu propia capa, y a partir de ahí Scapy la **construye, la disecciona, la muestra y la fuzzea** como si fuera nativa.

## Una capa mínima

Para un formato `[len:u32][chksum:u32][tag:u8][cuerpo]`:

```python
import struct                      # necesario para post_build; scapy.all NO lo exporta
from scapy.all import *

COMANDOS = {0: "HELLO", 1: "HELLO_ACK", 2: "QUIT", 3: "MSG",
            5: "PRIVMSG", 6: "LIST_REQ", 7: "LIST_RESP"}

class ChatMsg(Packet):
    name = "ChatProto"
    fields_desc = [
        FieldLenField("len", None, length_of="cuerpo", fmt="!I", adjust=lambda p, x: x + 1),
        XIntField("chksum", None),
        ByteEnumField("tag", 3, COMANDOS),
        StrLenField("cuerpo", b"", length_from=lambda p: p.len - 1),
    ]

    def post_build(self, p, pay):
        """Calcula el checksum una vez el paquete está serializado."""
        if self.chksum is None:
            chk = sum(p[8:]) & 0xFFFFFFFF          # tag + cuerpo
            p = p[:4] + struct.pack("!I", chk) + p[8:]
        return p + pay

bind_layers(TCP, ChatMsg, dport=12345)
bind_layers(TCP, ChatMsg, sport=12345)
```

Las piezas que hacen el trabajo:

- **`FieldLenField`** — calcula la longitud sola a partir de otro campo. `adjust` añade el byte del tag, que va contado dentro.
- **`length_from`** — al **disecar**, dice cuántos bytes leer del campo variable. Es lo que hace que Scapy sepa dónde acaba un mensaje.
- **`ByteEnumField`** — muestra `MSG` en vez de `3` en `show()`, y acepta ambos al construir.
- **`post_build`** — el gancho para checksums y cualquier campo que dependa de la serialización completa.

Con eso ya funciona en las dos direcciones:

```python
>>> p = ChatMsg(tag="MSG", cuerpo=b"\x05alice\x0chola mundo!")
>>> p.show2()                # show2() muestra los campos YA calculados
###[ ChatProto ]###
  len       = 19
  chksum    = 0x61a
  tag       = MSG
  cuerpo    = b'\x05alice\x0chola mundo!'

>>> raw(p)                   # los octetos que saldrían al cable
b'\x00\x00\x00\x13\x00\x00\x06\x1a\x03\x05alice\x0chola mundo!'

>>> ChatMsg(raw(p)).tag      # ida y vuelta: se disecciona lo que se construyó
'MSG'
```

Comprobando la aritmética a mano, que es como se detecta que la capa está bien definida:

- `cuerpo` mide 18 octetos; `len` sale **19** porque `adjust` le suma el octeto del `tag` → `0x00000013`.
- `chksum` = `tag` + suma de `cuerpo` = 3 + 1559 = **1562** = `0x0000061a`.

Si `show2()` te devuelve `len = None` o `chksum = 0`, es que `post_build` no se está ejecutando — normalmente por haber usado `show()` en vez de `show2()`.

Y `sniff()` y `rdpcap()` empiezan a mostrar el protocolo con nombre gracias a `bind_layers`.

## Campos que se usan a menudo

| Campo | Para qué |
| - | - |
| `ByteField`, `ShortField`, `IntField`, `LongField` | Enteros de 1, 2, 4, 8 octetos (big endian) |
| `LEShortField`, `LEIntField` | Little endian ([[00 - Anatomía de un protocolo binario]]) |
| `XByteField`, `XIntField` | Igual, pero se muestran en hexadecimal |
| `SignedIntField` | Con signo — útil para provocar confusión de signo |
| `FieldLenField` | Longitud calculada de otro campo |
| `StrLenField` | Cadena de longitud dada por otro campo |
| `StrNullField` | Cadena terminada en NUL |
| `StrFixedLenField` | Longitud fija, con relleno |
| `ByteEnumField`, `ShortEnumField` | Enumerados con nombre |
| `FlagsField` | Banderas de bits con nombre |
| `PacketListField` | **Lista de sub-paquetes anidados: para TLV** |
| `ConditionalField` | Campo que solo existe si se cumple una condición |

`ConditionalField` es la clave para protocolos donde el cuerpo depende del tag:

```python
ConditionalField(StrNullField("usuario", b""), lambda p: p.tag in (3, 5)),
ConditionalField(IntField("codigo", 0),        lambda p: p.tag == 1),
```

## TLV anidado

```python
class TLV(Packet):
    name = "TLV"
    fields_desc = [
        ByteField("tipo", 0),
        FieldLenField("longitud", None, length_of="valor", fmt="!H"),
        StrLenField("valor", b"", length_from=lambda p: p.longitud),
    ]
    def extract_padding(self, s):
        return b"", s          # imprescindible dentro de PacketListField

class Contenedor(Packet):
    fields_desc = [
        ByteField("version", 1),
        PacketListField("items", [], TLV),
    ]
```

`extract_padding` devolviendo `(b"", s)` es el detalle que hace que `PacketListField` siga parseando el siguiente TLV en vez de tragarse el resto como relleno. Sin eso, solo parsea el primero.

## Fuzzear con la capa definida

Aquí es donde se rentabiliza todo lo anterior:

```python
# fuzz() aleatoriza los campos, pero respeta los calculados (len, chksum)
send(IP(dst="10.10.10.5") / TCP(dport=12345) / fuzz(ChatMsg()), loop=1, inter=0.01)
```

<mark style="background: #FF5582A6;">`fuzz()` mantiene coherentes los campos que definiste como calculados</mark>, así que los casos **llegan al parser** en vez de morir en la validación de integridad — que es el fallo número uno del *fuzzing* de protocolos ([[00 - Fuzzing de protocolos de red]]).

Y para un barrido dirigido, que suele encontrar más que lo aleatorio:

```python
FRONTERAS = [0, 1, 0x7F, 0x80, 0xFF, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, 0x40000001]

# Todos los tags posibles: busca comandos ocultos y fallos de despacho
for tag in range(256):
    sr1(IP(dst=DST)/TCP(dport=12345)/ChatMsg(tag=tag, cuerpo=b"A"*8), timeout=1, verbose=0)

# Longitudes mentirosas: el campo len declarado a mano ignora el cálculo
for v in FRONTERAS:
    send(IP(dst=DST)/TCP(dport=12345)/ChatMsg(len=v, tag=3, cuerpo=b"A"*32), verbose=0)
```

Ese segundo bucle es el que busca los desbordamientos de [[01 - Datos de longitud variable]]: se declara `len` explícitamente para que **no** se recalcule y se envíe una longitud que no corresponde con el contenido.

## Cuándo Scapy no es la respuesta

Si el protocolo va sobre TCP con estado y necesitas mantener una sesión, Scapy es incómodo: no gestiona el flujo TCP por ti (existe `StreamSocket`, pero es limitado). Para eso, un `socket` de Python normal con tu capa de Scapy solo para construir y parsear:

```python
import socket
s = socket.create_connection(("10.10.10.5", 12345))
s.sendall(raw(ChatMsg(tag="HELLO", cuerpo=b"\x05alice")))
resp = ChatMsg(s.recv(4096))
resp.show()
```

Ese híbrido —`socket` para el transporte, Scapy para el formato— es lo que mejor funciona en la práctica con protocolos de aplicación.

> [!info]+ Fuentes
> - [Scapy — Adding new protocols](https://scapy.readthedocs.io/en/latest/build_dissect.html), la referencia para `fields_desc`, `post_build` y `extract_padding`.
> - [Lista completa de tipos de campo](https://scapy.readthedocs.io/en/latest/api/scapy.fields.html).
