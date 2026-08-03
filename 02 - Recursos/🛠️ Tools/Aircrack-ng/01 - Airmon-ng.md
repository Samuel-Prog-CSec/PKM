---
tags:
  - Wi-Fi
  - Pentesting/Enumeracion
Descripción: "Activar y desactivar el modo monitor con airmon-ng, gestionar los procesos que interfieren y qué hacer cuando falla con drivers modernos"
Fecha de actualización: 2026-08-01
Nota previa: "[[00 - La suite Aircrack-ng]]"
Nota siguiente: "[[02 - Airodump-ng]]"
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`airmon-ng` es un script de shell que envuelve las llamadas de `iw` para activar el modo monitor, y añade lo que `iw` no hace: detectar y matar los procesos que van a estropear la captura</mark>. Ese segundo trabajo es su verdadero valor — el cambio de modo se puede hacer a mano, la gestión de conflictos es lo que ahorra tiempo.

# Inventario de interfaces

Sin argumentos, lista las interfaces inalámbricas con su driver y chipset:

```shell-session
$ sudo airmon-ng

PHY     Interface       Driver          Chipset
phy0    wlan0           mt76x2u         MediaTek MT7612U
phy1    wlan1           ath9k_htc       Atheros AR9271
```

<mark style="background: #FF5582A6;">Ésta es la comprobación que hay que hacer antes de comprar o confiar en un adaptador</mark>: la columna `Chipset` dice qué hay realmente dentro, más allá de lo que ponga la caja. Si el driver es un módulo DKMS de terceros, aquí se ve.

# Activar el modo monitor

```shell-session
$ sudo airmon-ng start wlan0

Found 2 processes that could cause trouble.
Kill them using 'airmon-ng check kill' before putting
the card in monitor mode, they will interfere by changing channels
and sometimes putting the interface back in managed mode

    PID Name
    559 NetworkManager
    798 wpa_supplicant

PHY     Interface       Driver          Chipset
phy0    wlan0           mt76x2u         MediaTek MT7612U
        (mac80211 monitor mode vif enabled for [phy0]wlan0 on [phy0]wlan0mon)
        (mac80211 station mode vif disabled for [phy0]wlan0)
```

Dos cosas ocurren aquí. Se crea una **interfaz virtual** de monitor y se destruye la de estación, y la interfaz cambia de nombre a `wlan0mon`.

> [!warning]+ El renombrado no es universal
> Con algunos drivers `airmon-ng` conserva el nombre original en lugar de añadir el sufijo `mon`. Dar por hecho que existe `wlan0mon` y encadenar comandos con ese nombre es una causa frecuente de `No such device`. <mark style="background: #FFB8EBA6;">Comprobar siempre el nombre real después</mark>:
> ```shell-session
> $ iw dev | grep -E "Interface|type"
>         Interface wlan0mon
>                 type monitor
> ```

Se puede fijar el canal en el mismo paso:

```shell-session
$ sudo airmon-ng start wlan0 11
```

Equivale a activar el modo monitor y hacer después `iw dev wlan0mon set channel 11`.

# Los procesos que interfieren

Es el problema práctico número uno. `NetworkManager` y `wpa_supplicant` siguen viendo la tarjeta como un recurso propio: escanean periódicamente, lo que **la saca del canal** durante cientos de milisegundos, y a veces la devuelven a modo managed sin avisar. El síntoma es una captura con huecos o un `airodump-ng` que cambia de canal solo.

```shell-session
$ sudo airmon-ng check

Found 5 processes that could cause trouble.
    PID Name
    718 NetworkManager
    870 dhclient
   1104 avahi-daemon
   1115 wpa_supplicant
```

```shell-session
$ sudo airmon-ng check kill
```

> [!warning]+ `check kill` corta la conectividad de la máquina
> Mata `NetworkManager`, así que si el portátil está conectado por Wi-Fi con otra tarjeta —o por VPN sobre esa conexión— se pierde el acceso. En un engagement con SSH a una máquina de salto eso significa quedarse fuera. <mark style="background: #FFB86CA6;">La alternativa quirúrgica es marcar sólo el adaptador de auditoría como no gestionado</mark> y dejar el resto intacto:
> ```shell-session
> $ cat /etc/NetworkManager/conf.d/99-unmanaged-wifi.conf
> [keyfile]
> unmanaged-devices=interface-name:wlan1
>
> $ sudo systemctl reload NetworkManager
> ```
> Para restaurarlos tras un `check kill`: `sudo systemctl start NetworkManager`.

# Volver a modo managed

```shell-session
$ sudo airmon-ng stop wlan0mon

PHY     Interface       Driver          Chipset
phy0    wlan0mon        mt76x2u         MediaTek MT7612U
        (mac80211 station mode vif enabled on [phy0]wlan0)
        (mac80211 monitor mode vif disabled for [phy0]wlan0)
```

# Cuando airmon-ng falla

Con drivers modernos —especialmente `mt7921u` y algunos Realtek DKMS— `airmon-ng` puede fallar, dejar la interfaz en un estado intermedio o no crear la VIF. Hacerlo a mano con `iw` funciona en más casos porque no depende de la heurística del script:

```shell-session
$ sudo ip link set wlan0 down
$ sudo iw dev wlan0 set type monitor
$ sudo iw dev wlan0 set monitor control otherbss
$ sudo ip link set wlan0 up
$ sudo iw dev wlan0 set channel 36
```

Y para tener monitor **sin perder** la interfaz gestionada, creando una VIF adicional:

```shell-session
$ sudo iw dev wlan0 interface add mon0 type monitor
$ sudo ip link set mon0 up
```

<mark style="background: #8000E1A6;">Esa segunda vía es preferible siempre que el chipset soporte VIF</mark>: permite mantener la conexión a la red del cliente mientras se captura, algo imposible con `airmon-ng start`, que destruye la interfaz de estación. Los modos y flags están en [[05 - Modos de operación y modo monitor]].

# Verificación final

Antes de dar por buena la preparación conviene comprobar las tres cosas que pueden fallar por separado — modo, canal e inyección:

```shell-session
$ iw dev wlan0mon info | grep -E "type|channel"
        type monitor
        channel 36 (5180 MHz), width: 20 MHz

$ sudo aireplay-ng --test wlan0mon
15:22:41  Trying broadcast probe requests...
15:22:41  Injection is working!
```

Si la inyección no funciona pero el modo monitor sí, el problema es el driver, no la configuración — ver [[04 - Interfaces, chipsets y drivers]].
