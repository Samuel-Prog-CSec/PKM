---
tags:
  - Wi-Fi/WEP
  - Pentesting/Enumeracion
Descripción: "Localizar una red WEP, capturar su tráfico y leer el IV, el índice de clave y el ICV en Wireshark, con los filtros y el conteo de IVs únicos"
Fecha de actualización: 2026-08-01
Nota previa: "[[03 - Cifrado y descifrado WEP paso a paso]]"
Nota siguiente: "[[05 - ARP Request Replay]]"
Area: "[[WEP.base|WEP]]"
---
---

Todo ataque a WEP se reduce a **acumular IVs distintos**. Antes de acelerarlos con inyección conviene ver de dónde salen y cómo se leen, porque es lo que permite saber si una captura sirve o hay que seguir.

# Localizar la red

```shell-session
$ sudo airmon-ng check kill
$ sudo airmon-ng start wlan0
$ sudo airodump-ng --band abg -t WEP wlan0mon

 BSSID              PWR Beacons  #Data  CH  MB    ENC  CIPHER AUTH ESSID
 60:38:E0:71:E9:DC   -3       2      0   3  54e.  WEP  WEP         HTB-Wireless
```

`-t WEP` filtra por esquema de cifrado y evita revisar decenas de redes WPA2. <mark style="background: #FFB8EBA6;">Merece la pena barrer las tres bandas</mark>: el equipamiento legado que aún usa WEP suele estar en 2,4 GHz, pero un AP en modo mixto puede anunciar WEP en una banda y WPA2 en otra.

Con el objetivo identificado, fijar canal y BSSID y empezar a escribir:

```shell-session
$ sudo airodump-ng -c 3 --bssid 60:38:E0:71:E9:DC -w WEP wlan0mon

 BSSID              PWR RXQ Beacons  #Data  #/s  CH  ENC  CIPHER AUTH ESSID
 60:38:E0:71:E9:DC   -3 100     445    731   28   3  WEP  WEP    OPN  HTB-Wireless

 BSSID              STATION            PWR  Rate     Lost  Frames
 60:38:E0:71:E9:DC  2C:6D:C1:XX:XX:XX  -22  54e-54e     2     464
```

<mark style="background: #FF5582A6;">La columna que importa es `#Data`</mark>: en WEP no cuenta paquetes genéricos sino **tramas de datos con IV**, que es exactamente el material del cracking. `#/s` mide el ritmo de acumulación y dice si hace falta inyectar.

La columna `AUTH` distingue `OPN` de `SKA` (*Shared Key Authentication*). Si aparece `SKA`, hay una vía adicional: capturar el desafío regala 128 bytes de keystream — ver [[09 - Atacar un AP WEP sin clientes]].

# Sólo los IVs

Para capturas largas, `--ivs` guarda únicamente los vectores y descarta el resto:

```shell-session
$ sudo airodump-ng -c 3 --bssid 60:38:E0:71:E9:DC --ivs -w WEP wlan0mon
```

Reduce el fichero en más de un orden de magnitud. La contrapartida: <mark style="background: #FFB86CA6;">un `.ivs` sólo sirve para crackear</mark> — no se puede descifrar el tráfico después con [[05 - Airdecap-ng]] ni analizarlo en Wireshark. En un engagement real, donde el hallazgo se demuestra enseñando el tráfico descifrado, casi siempre interesa la captura completa.

# Leer el IV en Wireshark

Abriendo el `.cap` y seleccionando una trama de datos, los campos viven bajo *IEEE 802.11 Data ▸ WEP parameters*:

![Detalle de una trama 802.11 en Wireshark mostrando los parámetros WEP: vector de inicialización, índice de clave e ICV](https://academy.hackthebox.com/storage/modules/185/Wireshark/IV.png)

| Campo | Filtro | Contenido |
| ----- | ------ | --------- |
| Initialization Vector | `wlan.wep.iv` | 3 bytes, **en claro** |
| Key Index | `wlan.wep.key` | Cuál de las 4 claves configurables se usó |
| WEP ICV | `wlan.wep.icv` | El checksum, cifrado. Wireshark no lo verifica sin la clave |

Filtros útiles:

```text
wlan.fc.protected == 1                       # tramas cifradas
wlan.wep.iv                                  # tramas con IV, es decir WEP
wlan.wep.key == 0                            # las que usan la clave 0
wlan.fc.type_subtype == 11 && wlan.wep.iv    # autenticación Shared Key
```

# Contar IVs únicos

Es la métrica que decide si ya se puede crackear. `aircrack-ng` lo reporta, pero se puede comprobar antes con `tshark`:

```shell-session
$ tshark -r WEP-01.cap -T fields -e wlan.wep.iv 2>/dev/null | sort -u | wc -l
41827
```

| Método | IVs para 64 bits | IVs para 128 bits |
| ------ | ---------------- | ----------------- |
| **PTW** (por defecto) | ~20.000 | ~40.000 |
| KoreK / FMS (`-K`) | 250.000+ | 1.500.000+ |

<mark style="background: #8000E1A6;">Cuarenta mil IVs únicos suelen bastar para una clave de 104 bits con PTW</mark>. La diferencia entre tenerlos en cinco minutos o en dos días la marca la inyección.

Un detalle que se olvida: lo que cuenta son IVs **únicos**, no paquetes. Una captura con 200.000 paquetes puede tener muchos menos IVs distintos si el AP los reutiliza — y con IV secuencial desde cero tras un reinicio, la repetición es masiva.

# El ritmo natural, sin inyección

| Escenario | `#/s` típico | Tiempo hasta 40.000 IVs |
| --------- | ------------ | ----------------------- |
| AP sin clientes | 0 | Nunca |
| Un cliente inactivo | 1–5 | Horas o días |
| Un cliente navegando | 20–50 | 15–30 min |
| Con ARP replay | 300–800 | **1–3 min** |

Esa última fila es el motivo de todo lo que viene: <mark style="background: #FFB86CA6;">la inyección no descubre nada nuevo, sólo comprime días en minutos</mark>.

> [!important]+ Comprobar antes de irse del sitio
> Como con el handshake WPA2, conviene verificar la captura sobre el terreno en lugar de descubrir en la oficina que faltaban IVs:
> ```shell-session
> $ aircrack-ng -b 60:38:E0:71:E9:DC WEP-01.cap
> Read 195576 packets.
> Got 97822 out of 95000 IVs
> Starting PTW attack with 97822 IVs.
> ```
> Si dice `Got 12000 out of 95000 IVs`, hay que seguir capturando.

La forma clásica y más fiable de acelerar es [[05 - ARP Request Replay]].
