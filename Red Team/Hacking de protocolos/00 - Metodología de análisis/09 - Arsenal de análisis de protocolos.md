---
tags:
  - Protocolos
  - Redes
  - Tipo/Arsenal
Descripción: "El set 2026 para analizar un protocolo desconocido, con versiones verificadas y el mapa de qué sustituye a las herramientas muertas del libro"
Fecha de actualización: 2026-08-03
Nota previa: "[[08 - Detección y evasión del análisis activo]]"
Nota siguiente: 
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

*Attacking Network Protocols* es de 2018 y su apéndice de herramientas ha envejecido de forma desigual: parte sigue siendo el estándar, parte está muerta y parte ha sido superada por cosas que en 2018 no existían. Esta nota es el mapa actualizado, con **versiones verificadas el 2026-08-03** contra la API de GitHub y las páginas oficiales.

## Captura y análisis pasivo

| Herramienta | Estado | Para qué |
| - | - | - |
| **Wireshark / tshark** | 4.6.x, activo | Estándar absoluto. Reensamblado TCP, `Follow Stream`, disectores Lua |
| **tcpdump / libpcap** | activo | Captura en servidores sin GUI; sintaxis BPF |
| **`pktmon`** | integrado en Windows 10 1809+ | Captura nativa por PID, sin instalar nada; exporta a `.pcap` |
| **Stratoshark** | nuevo (proyecto Wireshark) | Hermano de Wireshark para *syscalls* y logs en vez de paquetes |
| **`termshark`** | activo | TUI de Wireshark, útil por SSH |

## Interceptación activa

| Herramienta | Estado | Nota |
| - | - | - |
| **mitmproxy** | **12.2.3** (2026-05-12) | El sustituto de Canape. Modos `raw_tcp`/`raw_udp` para no-HTTP, addons en Python |
| **socat** | activo | El `nc` con esteroides: *port-forward* con volcado hex en una línea |
| **Burp Suite** | activo | HTTP y, con extensiones, protocolos binarios ([[Burp Suite.base\|Burp Suite]]) |
| **PolarProxy** | activo | Proxy TLS que escribe directamente `.pcap` descifrado |
| **proxychains-ng** | activo | `LD_PRELOAD` para forzar SOCKS en binarios dinámicos |
| ~~**Canape / Canape Core**~~ | **muerto desde 2017** | Toda la parte práctica del libro. Sin sustituto directo: usa mitmproxy |
| ~~**Mallory**~~ | abandonado | El otro proxy MITM del apéndice |

## Manipulación de paquetes

| Herramienta | Estado | Nota |
| - | - | - |
| **Scapy** | **2.7.0** (2025-12-26) | Construir, enviar y disecar paquetes arbitrarios ([[🔨📦 Scapy\|Scapy]]) |
| **hping3** | mantenimiento | Sigue en el apéndice; para lo que hace, Scapy es más flexible |
| **Nmap / NSE** | activo | Detección de servicio y *scripts* de protocolo ([[Nmap.base\|Nmap]]) |
| **netcat / ncat** | activo | Replay de flujos TCP y servidor improvisado |

## Especificación y parseo de formatos

| Herramienta | Estado | Nota |
| - | - | - |
| **Kaitai Struct** | activo | Describes el formato en `.ksy` y te genera parser en 11 lenguajes **+ disector de Wireshark** |
| **Construct** (Python) | activo | Alternativa declarativa en puro Python, bidireccional (parsea y construye) |
| **`010 Editor`** | comercial | Editor hexadecimal con plantillas binarias; el mejor para explorar a mano |
| **ImHex** | activo, libre | Editor hexadecimal moderno con lenguaje de patrones; alternativa libre a 010 |

## Instrumentación del proceso

| Herramienta | Estado | Nota |
| - | - | - |
| **Frida** | **17.16.4** (2026-07-21) | La pieza que el libro no tiene. Hookea cripto y sockets en runtime |
| **bpftrace / bcc-tools** | activo | `tcpconnect`, `tcplife`, `sslsniff` — trazado sin `ptrace` |
| **strace / ltrace** | activo | Rápido y suficiente si no hay anti-debug |
| **Process Monitor** | activo (Sysinternals) | Windows: conexiones por proceso **con pila de llamadas** |
| **ProcMon for Linux** | activo (Sysinternals) | Procmon sobre eBPF |
| ~~**DTrace en Linux**~~ | irrelevante | Sustituido por eBPF; sigue vivo en macOS (con SIP) y FreeBSD |

## Cómo se combinan en la práctica

Un análisis típico de protocolo propietario, en orden:

```shell-session
# 1. ¿Con quién habla y por qué puerto?
$ sudo tcpconnect -P            # o Process Monitor en Windows

# 2. Capturar limpio, filtrando desde el kernel
$ tshark -i eth0 -w cap.pcap 'host 10.10.10.5 and tcp port 12345'

# 3. Aislar una dirección y volcarla a binario
$ tshark -r cap.pcap -T fields -e data -Y 'tcp.dstport==12345' | xxd -p -r > out.bin

# 4. Hipótesis + parser desechable en Python  → estructura

# 5. Interponerse para manipular
$ mitmdump --mode reverse:tcp://10.10.10.5:12345@4444 -s addon.py

# 6. Formalizar: disector Lua o .ksy de Kaitai

# 7. Romperlo a propósito → 05 - Fuzzing y explotación
```

## Lo que sigue siendo válido del apéndice original

No todo ha caducado. `Wireshark`, `tcpdump`, `Scapy`, `Nmap`, `netcat`, `hping`, `Burp`, `ZAP` y `Metasploit` siguen siendo exactamente lo que eran. <mark style="background: #FFB8EBA6;">Lo que ha muerto es el *tooling* propio del autor</mark> (`Canape`, `Canape CLI`) y las piezas de nicho (`Mallory`, `Sulley` → sustituido por `boofuzz`, `Microsoft Message Analyzer` → retirado en 2019). Las de reversing van en [[03 - Reversing dinámico - debuggers y hooking]] y las de *fuzzing* en [[09 - Arsenal de fuzzing y explotación]].

> [!info]+ Fuentes
> - Versiones verificadas el 2026-08-03 contra `api.github.com/repos/<org>/<repo>/releases/latest` para mitmproxy, Frida y Scapy; página de descargas de Wireshark para la rama 4.6.
> - [Kaitai Struct](https://kaitai.io/) — soporte de exportación a disector de Wireshark.
> - Forshaw, *Attacking Network Protocols*, apéndice «Network Protocol Analysis Toolkit» (2018) — base de la comparación.
