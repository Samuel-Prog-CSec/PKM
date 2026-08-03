---
tags:
  - Wi-Fi
  - Pentesting/Enumeracion
Descripción: "Lectura correcta de cada columna, filtros por banda, canal y cifrado, ficheros de salida y las opciones que HTB no menciona"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - Airmon-ng]]"
Nota siguiente: "[[03 - Airgraph-ng]]"
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`airodump-ng` es el motor de reconocimiento de la suite: captura tramas 802.11 crudas, mantiene en pantalla un inventario vivo de APs y clientes, y escribe a disco tanto la captura como varios formatos estructurados</mark>. Casi todo lo demás consume lo que produce.

# Leer la salida

```shell-session
$ sudo airodump-ng wlan0mon

 CH  9 ][ Elapsed: 1 min ][ 2026-08-01 17:41 ][

 BSSID              PWR  Beacons  #Data, #/s  CH   MB   ENC CIPHER  AUTH ESSID

 00:09:5B:1C:AA:1D  -41       16      0    0   11  130   OPN              NETGEAR
 00:14:6C:7A:41:81  -62      100     14    1   48  866   WPA2 CCMP   PSK  CyberCorp
 00:14:6C:7E:40:80  -75      752     73    2    9  540   WPA3 CCMP   SAE  HTB-Secure

 BSSID              STATION            PWR   Rate    Lost  Frames  Notes  Probes

 00:14:6C:7A:41:81  00:0F:B5:32:31:31  -51   36-24      2      14  EAPOL  CyberCorp
 (not associated)   00:14:A4:3F:8D:13  -69    0-0        0       4         Starbucks,MiCasa
```

| Columna | Qué es | Matiz que importa |
| ------- | ------ | ----------------- |
| `BSSID` | MAC de la radio del AP | Varios BSSID pueden compartir SSID y radio |
| `PWR` | Nivel de señal | **Ver el aviso de abajo** |
| `Beacons` | Beacons recibidos | Muchos beacons y `#Data` a cero: AP sin clientes |
| `#Data` | Tramas de datos capturadas | En WEP es el contador de IVs, lo que decide el cracking |
| `#/s` | Tramas de datos en los últimos 10 s | Mide si el ataque de inyección está funcionando |
| `CH` | Canal | El que anuncia el beacon, no necesariamente donde se capturó |
| `MB` | Velocidad máxima soportada | `54` o menos indica red legada; `11e` señala QoS |
| `ENC` | Esquema de cifrado | `OPN`, `WEP`, `WPA`, `WPA2`, `WPA3`, `OWE` |
| `CIPHER` | Cifrado por pares | `CCMP`, `TKIP`, `WEP`, `GCMP` |
| `AUTH` | AKM negociado | `PSK`, `SAE`, `MGT` (802.1X), `OWE` |
| `STATION` | MAC del cliente | `(not associated)` = sólo está sondeando |
| `Notes` | Material capturado | **`EAPOL` o `PMKID` aquí es el objetivo** |
| `PROBES` | Redes que busca el cliente | Su `PNL`: dónde ha estado ese dispositivo |

> [!warning]+ HTB explica mal la columna PWR
> El módulo 222 dice: "cuanto más alto el número, mejor la señal". Es engañoso. <mark style="background: #FF5582A6;">`PWR` es el RSSI que reporta el driver, casi siempre en **dBm negativos**</mark>, así que "más alto" significa *menos negativo*: `-40` es señal fuerte, `-75` es débil, `-90` está en el límite de sensibilidad. Y un valor de **`-1` no es una señal pésima: significa que el driver no soporta reportar potencia** para esa trama ([documentación oficial de airodump-ng](https://www.aircrack-ng.org/doku.php?id=airodump-ng)). Con `-1` en toda la columna, el problema es el driver.
>
> Escala práctica: `-40` excelente · `-55` buena · `-70` empieza a ser débil · `-80/-90` límite del adaptador.

# Filtrar

## Por canal

Sin `-c`, `airodump-ng` hace **salto de canal**: recorre todos los del dominio regulatorio para dar una visión de conjunto. Eso significa que <mark style="background: #FFB86CA6;">está fuera del canal del objetivo la mayor parte del tiempo, y va a perder tramas</mark>. En cuanto haya un objetivo, hay que fijarlo:

```shell-session
$ sudo airodump-ng -c 11 wlan0mon
$ sudo airodump-ng -c 1,6,11 wlan0mon
```

Fijar el canal es **obligatorio** para capturar un handshake de forma fiable: el intercambio EAPOL dura milisegundos y ocurre una vez.

## Por banda

Por defecto sólo escanea 2,4 GHz — el error silencioso más común, porque la mitad del despliegue corporativo queda invisible.

```shell-session
$ sudo airodump-ng --band a wlan0mon      # 5 GHz
$ sudo airodump-ng --band abg wlan0mon    # todas
```

Los valores son `a` (5 GHz), `b` y `g` (ambos 2,4 GHz). Para **6 GHz** hay que indicar los canales directamente: el soporte de canales Wi-Fi 6E llegó en la 1.7, pero no hay letra de banda para ellos.

## Por objetivo y por cifrado

```shell-session
$ sudo airodump-ng --bssid 00:14:6C:7A:41:81 -c 48 -w captura wlan0mon
$ sudo airodump-ng --essid CyberCorp wlan0mon
$ sudo airodump-ng -t WPA3 wlan0mon         # también WEP, WPA, WPA2, OWE, OPN
```

El filtro `-t/--encrypt` con valores `WPA3` y `OWE` es una de las incorporaciones de la 1.7 y sirve para localizar rápidamente lo moderno y lo legado en un despliegue grande.

# Opciones que HTB no menciona

| Opción | Para qué |
| ------ | -------- |
| `--wps` | Muestra versión, estado y bloqueo de **WPS**. Imprescindible antes de atacar WPS |
| `--manufacturer` | Resuelve el OUI a fabricante: identifica modelos e IoT de un vistazo |
| `--uptime` | Uptime del AP desde el *timestamp* del beacon. Delata un AP falso recién levantado |
| `-a` | Sólo clientes asociados, oculta el ruido de los que sólo sondean |
| `--write-interval <s>` | Frecuencia de volcado a disco. Bajarlo evita perder datos si el proceso muere |
| `--output-format` | `pcap,ivs,csv,gps,kismet,netxml,logcsv` — o sólo los que interesen |
| `--ignore-negative-one` | Silencia el aviso de canal fijo con ciertos drivers |
| `--gpsd` | Registra coordenadas de cada AP. Base del *war driving* y del mapa de cobertura |

<mark style="background: #8000E1A6;">`--uptime` es una defensa además de un ataque</mark>: un AP legítimo lleva semanas encendido, un evil twin lleva minutos. Es el chequeo más rápido para detectar suplantación en el propio inventario.

# Ficheros de salida

```shell-session
$ sudo airodump-ng --bssid 00:14:6C:7A:41:81 -c 48 -w HTB wlan0mon
11:32:13  Created capture file "HTB-01.cap".
```

| Fichero | Contenido | Quién lo consume |
| ------- | --------- | ---------------- |
| `HTB-01.cap` | Captura completa en pcap | `aircrack-ng`, Wireshark, `hcxpcapngtool` |
| `HTB-01.csv` | APs y clientes en tabla | `airgraph-ng`, scripts propios |
| `HTB-01.kismet.csv` | Formato Kismet legado | Compatibilidad |
| `HTB-01.kismet.netxml` | Kismet newcore XML | Importación a otras suites |
| `HTB-01.log.csv` | Registro con GPS si hay `--gpsd` | Mapas de cobertura |

El sufijo `-01` se incrementa en cada ejecución con el mismo prefijo, así que no se sobrescribe nada.

> [!success]+ Confirmar que el handshake está en el fichero
> La columna `Notes` mostrando `EAPOL` y el mensaje `WPA handshake:` en la cabecera no siempre significan una captura utilizable. Verificar antes de recoger:
> ```shell-session
> $ aircrack-ng HTB-01.cap
>    #  BSSID              ESSID       Encryption
>    1  00:14:6C:7A:41:81  CyberCorp   WPA (1 handshake)
> ```
> O, mejor, convirtiendo al formato moderno, que además informa de qué mensajes hay:
> ```shell-session
> $ hcxpcapngtool -o HTB.22000 HTB-01.cap
> ```
> <mark style="background: #FFB8EBA6;">Marcharse del sitio con una captura incompleta obliga a volver</mark>. Los mensajes 1 y 2 bastan para `hashcat`; ver [[06 - Aircrack-ng]].

# Consumo de tiempo real

Para trabajar sobre la captura mientras se llena, `airodump-ng` puede escribir a una FIFO o se puede abrir el `.cap` en Wireshark en paralelo. En capturas largas conviene bajar `--write-interval` a 1 segundo: por defecto el volcado es menos frecuente y un `Ctrl+C` mal dado pierde los últimos segundos, que son justo los del handshake que se acaba de forzar.

La visualización de las relaciones que salen de los `.csv` es [[03 - Airgraph-ng]].
