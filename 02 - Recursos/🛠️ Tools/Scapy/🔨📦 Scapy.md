---
tags:
  - Redes
  - Protocolos
  - Escaneo/Redes
  - Tipo/Introduccion
Descripción: "Construir, enviar, capturar y disecar paquetes arbitrarios desde Python — la herramienta cuando ninguna otra hace exactamente lo que necesitas"
Fecha de actualización: 2026-08-03
Nota previa: 
Nota siguiente: "[[01 - Definir un protocolo propietario en Scapy]]"
Area: "[[Scapy.base|Scapy]]"
---
---

`Scapy` es una librería de Python para **construir, enviar, capturar y disecar paquetes arbitrarios**. A diferencia de `nmap` o `hping`, no implementa ataques concretos: te da control byte a byte sobre cualquier capa y tú decides qué construir. <mark style="background: #ADCCFFA6;">Es la herramienta a la que se recurre cuando ninguna otra hace exactamente lo que hace falta</mark>.

Versión verificada: **2.7.0** (26 de diciembre de 2025).

## El modelo: capas que se apilan

```python
from scapy.all import *

paquete = IP(dst="10.10.10.5") / TCP(dport=12345, flags="S")
```

El operador `/` apila capas. Cada campo que no fijes se calcula solo (longitudes, checksums, puertos de origen) — y **eso se puede desactivar**, que es justo lo que interesa para atacar:

```python
# Checksum deliberadamente inválido: prueba de evasión de IDS
mal = IP(dst="10.10.10.5", chksum=0xdead) / TCP(dport=80, flags="S")

# Longitud IP que miente sobre el contenido real
mentira = IP(dst="10.10.10.5", len=20) / TCP() / ("A" * 500)
```

## Enviar y recibir

| Función | Capa | Qué hace |
| - | - | - |
| `send(p)` | 3 (IP) | Envía, no espera respuesta |
| `sendp(p)` | 2 (Ethernet) | Envía trama cruda, tú pones las MAC |
| `sr(p)` | 3 | Envía y recoge respuestas (respondidos, no respondidos) |
| **`sr1(p)`** | 3 | Envía y devuelve **la primera** respuesta. El más usado |
| `srp(p)` / `srp1(p)` | 2 | Equivalentes en capa de enlace |
| `sniff()` | — | Captura, con `filter=` BPF y `prn=` para procesar |

```python
r = sr1(IP(dst="10.10.10.5") / TCP(dport=12345, flags="S"), timeout=2, verbose=0)
if r and r.haslayer(TCP):
    print("SYN-ACK" if r[TCP].flags.SA else "RST" if r[TCP].flags.RA else "?")
```

## Inspeccionar

```python
p.show()          # árbol completo con todos los campos
p.show2()         # igual, pero con los campos calculados ya resueltos
hexdump(p)        # volcado hexadecimal
p.summary()       # una línea
ls(TCP)           # todos los campos de una capa y sus valores por defecto
raw(p)            # los bytes que saldrían al cable
```

`show2()` frente a `show()` es la distinción práctica: `show()` muestra `chksum=None` porque aún no se ha calculado; `show2()` muestra el valor real que se enviará.

## Casos donde Scapy es la respuesta

| Necesidad | Por qué Scapy |
| - | - |
| **Protocolo propietario** | Defines tu propia capa ([[01 - Definir un protocolo propietario en Scapy]]) |
| **Campos inválidos a propósito** | Checksums, longitudes y flags que ninguna herramienta te deja poner |
| **Fragmentación a medida** | `fragment()`, y fragmentos solapados para evadir IDS |
| **Control fino del ritmo** | `inter=` y `loop=` para *low-and-slow* |
| **Tramas 802.11** | `Dot11`, con control de `reason code` y número de secuencia ([[10 - Arsenal de herramientas Wi-Fi]]) |
| **Leer y reescribir un `.pcap`** | `rdpcap()` / `wrpcap()` |

Ese control fino es lo que lo hace útil para evasión: `aireplay-ng` y `mdk4` mandan tramas de desautenticación con una firma reconocible; Scapy te deja variar todo lo que un WIDS mira.

```python
# Reproducir tráfico de una captura, alterando un campo
paquetes = rdpcap("captura.pcap")
for p in paquetes:
    if p.haslayer(TCP) and p[TCP].dport == 12345:
        del p[IP].chksum, p[TCP].chksum       # forzar recálculo
        p[TCP].seq += 1
        send(p, verbose=0)
```

Borrar los checksums antes de reenviar es imprescindible: si no, Scapy conserva los del paquete original y el destino los descarta.

## Límites

> [!warning]+ Scapy es lento y necesita privilegios
> Va en Python puro y **no es apto para volumen**: unos pocos miles de paquetes por segundo frente a los millones de `hping3` o de un generador en C. Para escaneo masivo, `masscan` o `zmap`; para pruebas de carga, otra cosa. Scapy es para **precisión, no para caudal**.
>
> Y requiere `root`/`CAP_NET_RAW` para sockets crudos. En Windows necesita `Npcap`.

Otra limitación práctica: `sniff()` con `store=True` (por defecto) acumula todo en memoria. Para capturas largas, `store=False` con un `prn=` que procese al vuelo.

## Ecosistema

| Complemento | Uso |
| - | - |
| `scapy.contrib.*` | Docenas de protocolos extra: Modbus, CAN, MQTT, BGP, LLDP, DNP3 |
| `scapy-ssl_tls` | Capa TLS (verificar estado antes de usar) |
| `libpcap` / `Npcap` | Motor de captura subyacente |

Los módulos de `contrib` merecen atención para pentest industrial: **Modbus y DNP3** están ahí, y con ellos se construyen tramas OT arbitrarias sin escribir el protocolo desde cero.

> [!info]+ Fuentes
> - [Scapy — documentación oficial](https://scapy.readthedocs.io/) y [uso avanzado](https://scapy.readthedocs.io/en/latest/advanced_usage.html).
> - Versión verificada el 2026-08-03 contra `api.github.com/repos/secdev/scapy/releases/latest`.
