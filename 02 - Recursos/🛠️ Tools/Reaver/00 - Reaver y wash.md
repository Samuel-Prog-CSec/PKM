---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "Referencia de reaver y su escáner wash: opciones completas, gestión de sesiones y los fallos conocidos con interfaces creadas por airmon-ng"
Fecha de actualización: 2026-08-01
Nota previa: 
Nota siguiente: "[[01 - Bully]]"
Area: "[[Reaver.base|Reaver]]"
---
---

<mark style="background: #ADCCFFA6;">`reaver` es la implementación de referencia del ataque al PIN de WPS</mark>: se hace pasar por un *Registrar externo*, prueba PINs contra el AP y, al acertar, canjea el PIN por la `WPA-PSK`. Incorpora además `pixiewps` para el ataque offline y `wash` como escáner pasivo.

El proyecto vivo es el fork **[t6x/reaver-wps-fork-t6x](https://github.com/t6x/reaver-wps-fork-t6x)**; el original de Tactical Network Solutions está abandonado desde 2012. La última **release** etiquetada es la **v1.6.6 de marzo de 2020**, aunque `master` sigue recibiendo correcciones — último movimiento en octubre de 2025.

# wash — reconocimiento pasivo

Lee el WPS *information element* de los beacons. **No transmite nada.**

```shell-session
$ sudo wash -i mon0

BSSID               Ch  dBm  WPS  Lck  Vendor    ESSID
--------------------------------------------------------------------------
60:38:E0:XX:XX:XX    3  -07  1.0  No   AtherosC  HTB-Wireless
XX:XX:XX:XX:XX:XX    1  -63  2.0  No   LantiqML  FakeNetwork
```

| Opción | Función |
| ------ | ------- |
| `-i` | Interfaz en modo monitor |
| `-c` | Fijar canal en lugar de saltar |
| `-j` | Salida JSON con todos los campos del IE |
| `-a` | Mostrar también APs sin WPS |
| `-s` | Modo escaneo (activo) en lugar de pasivo |
| `-f` | Leer de un fichero `.pcap` en lugar de una interfaz |

La salida JSON da lo que la tabla resume:

```shell-session
$ sudo wash -j -i mon0
{"bssid" : "XX:XX:XX:XX:XX:XX", "essid" : "FakeNetwork", "channel" : 1,
 "rssi" : -61, "wps_version" : 32, "wps_state" : 2, "wps_locked" : 2,
 "wps_response_type" : "03", "wps_config_methods" : "0000", "wps_rf_bands" : "03"}
```

| Campo | Interpretación |
| ----- | -------------- |
| `wps_version` | **Hexadecimal**: `16` = `0x10` = v1.0 · `32` = `0x20` = v2.0 |
| `wps_state` | `1` no configurado · `2` configurado |
| `wps_locked` | `0` desbloqueado · `1` bloqueado · **`2` sin especificar** |
| `wps_config_methods` | Máscara de bits de los métodos soportados |
| `wps_rf_bands` | `01` 2,4 GHz · `02` 5 GHz · `03` ambas |

> [!warning]+ `wps_locked: 2` no significa "desbloqueado"
> Verificado en [`src/libwps/libwps.h`](https://github.com/t6x/reaver-wps-fork-t6x/blob/master/src/libwps/libwps.h):
> ```c
> enum wps_locked_state { UNLOCKED, WPSLOCKED, UNSPECIFIED };
> ```
> <mark style="background: #FF5582A6;">`2` es `UNSPECIFIED`</mark>: el AP no publica el atributo *AP Setup Locked*. Lo habitual es que no esté bloqueado, pero la confirmación es el `0`.

# reaver — opciones

```shell-session
$ sudo reaver -i mon0 -b <BSSID> -c <canal> -vv
```

Todas las opciones de abajo están verificadas contra el `usage` de [`src/wpscrack.c`](https://github.com/t6x/reaver-wps-fork-t6x/blob/master/src/wpscrack.c).

## Objetivo e interfaz

| Opción | Función |
| ------ | ------- |
| `-i, --interface` | Interfaz en modo monitor |
| `-b, --bssid` | BSSID del AP |
| `-c, --channel` | Canal. **Implica `-f`**: fijarlo desactiva el salto de canal |
| `-e, --essid` | ESSID, necesario con SSID ocultos |
| `-m, --mac` | MAC del sistema atacante |
| `-5, --5ghz` | Usar canales de 5 GHz |

## Control del ataque

| Opción | Función |
| ------ | ------- |
| `-p, --pin` | PIN concreto. Acepta **4 u 8 dígitos, o una cadena arbitraria** — de ahí que `-p ""` valga para el PIN nulo |
| `-K, --pixie-dust` · `-Z` | Ataque Pixie Dust. **Sin argumento** |
| `-g, --max-attempts=<n>` | Salir tras `n` intentos |
| `-S, --dh-small` | Claves Diffie-Hellman pequeñas: acelera el crackeo |
| `-A, --no-associate` | No asociarse; la asociación la hace otra herramienta |
| `-C, --exec=<cmd>` | Ejecutar un comando al recuperar el PIN |

## Temporización y bloqueo

| Opción | Función |
| ------ | ------- |
| `-d, --delay=<s>` | Retardo entre intentos |
| `-l, --lock-delay=<s>` | Espera al detectar bloqueo |
| `-r, --recurring-delay=<x:y>` | Dormir `y` segundos cada `x` intentos |
| `-x, --fail-wait=<s>` | Dormir tras una racha de fallos inesperados |
| `-T, --m57-timeout=<s>` | Timeout de M5/M7 |
| `-t, --timeout=<s>` | Timeout de recepción |
| `-L, --ignore-locks` | Ignorar el estado de bloqueo reportado |
| `-N, --no-nacks` | No enviar `NACK` ante paquetes fuera de orden |

## Compatibilidad y evasión

<mark style="background: #FF5582A6;">Estas cuatro son las que sacan adelante un ataque que no arranca, y ninguna aparece en el material de HTB</mark>:

| Opción | Función |
| ------ | ------- |
| `-M, --mac-changer` | **Cambia el último dígito de la MAC en cada intento.** Rompe los contadores de bloqueo que cuentan por origen y dificulta la correlación en un WIDS |
| `-w, --win7` | Se hace pasar por un *registrar* de Windows 7. Algunos AP sólo responden bien a registrars conocidos |
| `-E, --eap-terminate` | Cierra cada sesión WPS con un `EAP FAIL`. Evita que el AP se quede con sesiones colgadas |
| `-J, --timeout-is-nack` | Tratar el timeout como `NACK`. Necesario en D-Link DIR-300/320 |
| `-F, --ignore-fcs` | Ignorar errores de checksum de trama. Útil con señal mediocre |

## Salida y sesión

| Opción | Función |
| ------ | ------- |
| `-v` · `-vv` · `-vvv` | Verbosidad creciente |
| `-q, --quiet` | Sólo mensajes críticos |
| `-O, --output-file=<f>` | Volcar las tramas de interés a un `.pcap` |
| `-s, --session=<f>` | Restaurar un fichero de sesión concreto |

# Sesiones

reaver **guarda el progreso automáticamente** en `/var/lib/reaver/<BSSID>.wpc` (o `/etc/reaver/` según la distribución). Un ataque interrumpido se reanuda solo al relanzarlo contra el mismo BSSID.

```shell-session
$ cat /var/lib/reaver/60:38:E0:XX:XX:XX.wpc
0            # índice de la primera mitad
0            # índice de la segunda mitad
...          # lista de candidatos ya descartados
```

<mark style="background: #FFB8EBA6;">Es un arma de doble filo</mark>: si el AP se reconfiguró entre sesiones, reaver reanuda con un estado inválido y descarta candidatos que ya no lo son. Para empezar limpio:

```shell-session
$ sudo rm /var/lib/reaver/60:38:E0:XX:XX:XX.wpc
```

# Fallos conocidos

> [!warning]+ No crear la interfaz con `airmon-ng`
> Es el problema práctico más frecuente. Una interfaz creada con `airmon-ng start` puede hacer que reaver no funcione. La vía fiable:
> ```shell-session
> $ sudo iw dev wlan0 interface add mon0 type monitor
> $ sudo ip link set mon0 up
> ```

| Síntoma | Causa habitual |
| ------- | -------------- |
| `Failed to associate with <BSSID>` | Señal insuficiente o canal equivocado |
| `WARNING: Failed to associate` en bucle | El AP filtra por MAC, o está bloqueado |
| `Found packet with bad FCS, skipping...` | Normal en cantidad moderada; masivo indica mala posición |
| `Detected AP rate limiting` | Bloqueo activo. Ver [[04 - APs con bloqueo y rate limiting]] |
| `WPS transaction failed (code: 0x03)` | El AP rechazó el intercambio. Probar `-N` o subir `-T` |
| Reanuda en un punto extraño | Fichero de sesión antiguo. Borrarlo |

# Cuándo usar otra cosa

| Situación | Alternativa |
| --------- | ----------- |
| El driver no inyecta bien | [[03 - OneShot y el estado del arte]] — usa `wpa_supplicant` |
| reaver falla contra un AP concreto | [[01 - Bully]] — otra implementación |
| Ya se tienen los valores del intercambio | [[02 - Pixiewps]] — el motor solo |
| Se quiere encadenar todo el flujo | `airgeddon` |

La explotación completa, con el orden de vectores, está en [[00 - Qué es WPS y por qué sigue vivo]] y siguientes.
