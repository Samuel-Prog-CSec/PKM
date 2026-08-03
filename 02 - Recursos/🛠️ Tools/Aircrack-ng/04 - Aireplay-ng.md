---
tags:
  - Wi-Fi
  - Pentesting/Explotacion
Descripción: "Los diez modos de ataque por inyección, la prueba previa de inyección y por qué la desautenticación falla en la mayoría de redes de 2026"
Fecha de actualización: 2026-08-01
Nota previa: "[[03 - Airgraph-ng]]"
Nota siguiente: "[[05 - Airdecap-ng]]"
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`aireplay-ng` es la herramienta de inyección de la suite: genera y transmite tramas 802.11 forjadas</mark>. Todo lo que no sea escuchar pasa por aquí — desconectar clientes, autenticarse falsamente contra un AP WEP, reinyectar tráfico para acelerar la recolección de IVs.

# Los diez modos de ataque

```shell-session
$ aireplay-ng
Attack modes (numbers can still be used):
      --deauth      count : deauthenticate 1 or all stations (-0)
      --fakeauth    delay : fake authentication with AP (-1)
      --interactive       : interactive frame selection (-2)
      --arpreplay         : standard ARP-request replay (-3)
      --chopchop          : decrypt/chopchop WEP packet (-4)
      --fragment          : generates valid keystream (-5)
      --caffe-latte       : query a client for new IVs (-6)
      --cfrag             : fragments against a client (-7)
      --migmode           : attacks WPA migration mode (-8)
      --test              : tests injection and quality (-9)
```

| Ataque | Nombre | Objetivo | Nota del vault |
| ------ | ------ | -------- | -------------- |
| `-0` | Desautenticación | WPA/WPA2 · DoS | Aquí |
| `-1` | Fake authentication | WEP sin clientes | [[09 - Atacar un AP WEP sin clientes]] |
| `-2` | Reinyección interactiva | WEP | [[05 - ARP Request Replay]] |
| `-3` | ARP request replay | WEP | [[05 - ARP Request Replay]] |
| `-4` | KoreK ChopChop | WEP | [[07 - KoreK ChopChop]] |
| `-5` | Fragmentación | WEP | [[06 - Ataque de fragmentación]] |
| `-6` | Café Latte | WEP · cliente aislado | [[08 - Café Latte y ataques al cliente]] |
| `-7` | Fragmentación al cliente | WEP · cliente aislado | [[08 - Café Latte y ataques al cliente]] |
| `-8` | WPA migration mode | Redes en modo mixto WPA/WEP | — |
| `-9` | Prueba de inyección | Diagnóstico | Aquí |

<mark style="background: #FFB8EBA6;">Siete de los diez son ataques a WEP</mark>. Es un reflejo de cuándo se escribió la herramienta, y explica por qué para WPA2 moderno la suite se reduce a `-0` y a la captura pasiva.

# Probar la inyección antes de nada

Tener modo monitor no implica poder transmitir. Es lo primero que hay que verificar al llegar al sitio, con la tarjeta ya en el canal del objetivo:

```shell-session
$ sudo iw dev wlan0mon set channel 1
$ sudo aireplay-ng --test wlan0mon

12:34:56  Trying broadcast probe requests...
12:34:56  Injection is working!
12:34:56  Found 27 APs
12:34:56  Trying directed probe requests...
12:34:56  00:09:5B:1C:AA:1D - channel: 1 - 'TOMMY'
12:34:56  Ping (min/avg/max): 0.457ms/1.813ms/2.406ms  Power: -48.00
12:34:56  30/30: 100%
```

La segunda parte —el *ping* dirigido y el porcentaje— es la que de verdad importa. `Injection is working!` sólo confirma que la tarjeta transmite; **el porcentaje mide si el AP recibe y contesta**. Un 100 % es posición óptima; por debajo del 30 % los ataques serán lentos y poco fiables, y la solución es acercarse o cambiar de antena, no insistir.

> [!success]+ Comparar dos tarjetas
> Con dos adaptadores, `--test` sobre cada uno en la misma posición dice cuál usar para inyectar y cuál dejar capturando. No siempre gana el más caro: un AR9271 de 2,4 GHz suele batir a adaptadores modernos en fiabilidad de inyección.

# Desautenticación

```shell-session
$ sudo aireplay-ng -0 5 -a 00:14:6C:7A:41:81 -c 00:0F:B5:32:31:31 wlan0mon

11:12:33  Waiting for beacon frame (BSSID: 00:14:6C:7A:41:81) on channel 1
11:12:34  Sending 64 directed DeAuth (code 7). STMAC: [00:0F:B5:32:31:31] [ 0|64 ACKs]
```

| Parámetro | Significado |
| --------- | ----------- |
| `-0 5` | Número de ráfagas. **`0` significa continuo** |
| `-a` | BSSID del AP |
| `-c` | MAC del cliente. **Si se omite, se desautentica a todos** |
| `-D` | No esperar al beacon del AP (útil si no se recibe) |

> [!important]+ El mensaje dice 64, pero se transmiten 128
> `Sending 64 directed DeAuth` se lee mal. Verificado en [`aireplay-ng.c`](https://github.com/aircrack-ng/aircrack-ng/blob/master/src/aireplay-ng/aireplay-ng.c): el bucle da **64 vueltas** y en **cada una envía dos tramas**, una en cada sentido:
>
> ```c
> for (i = 0; i < 64; i++) {
>     memcpy(h80211 + 4,  opt.r_dmac,  6);   // Addr1 = cliente
>     memcpy(h80211 + 10, opt.r_bssid, 6);   // Addr2 = AP      → AP ▸ cliente
>     send_packet(...);  usleep(2000);
>     memcpy(h80211 + 4,  opt.r_bssid, 6);   // Addr1 = AP
>     memcpy(h80211 + 10, opt.r_dmac,  6);   // Addr2 = cliente → cliente ▸ AP
>     send_packet(...);  usleep(2000);
> }
> ```
>
> <mark style="background: #FF5582A6;">Son **128 tramas por ráfaga**: 64 suplantando al AP y 64 suplantando al cliente</mark>. Los 2 ms de `usleep` entre envíos fijan además el ritmo en unos 500 paquetes por segundo, que es el valor que se ve en el resto de modos.
>
> Nótese `kRewriteSequenceNumber`: aireplay-ng **reescribe el número de secuencia** de cada trama con su propio contador. No hereda la serie del AP legítimo, y esa discontinuidad es una de las señales que usa un WIDS — ver [[09 - Detección y evasión]].

Los `ACKs` del final indican cuántas de esas tramas fueron reconocidas — <mark style="background: #FF5582A6;">`[ 0| 0 ACKs]` de forma sostenida significa que no están llegando</mark>, normalmente por estar fuera de canal o demasiado lejos.

> [!warning]+ Este ataque no funciona en la mayoría de redes de 2026
> HTB presenta la desautenticación como la vía estándar para capturar un handshake y **no menciona `PMF` ni una vez**. Con `802.11w` activo las tramas de gestión unicast llevan un `MIC` y las forjadas se descartan sin efecto. `PMF` es obligatorio para certificar desde Wi-Fi 6 (2020) y Wi-Fi 7 exige además *beacon protection*.
>
> Comprobarlo **antes** de lanzar el ataque, leyendo el RSN IE del beacon:
> ```shell-session
> $ sudo iw dev wlan0 scan | grep -A 15 "SSID: CyberCorp" | grep -E "MFP|Authentication suites"
>          * Authentication suites: PSK
>          Capabilities: 1-PTKSA-RC 1-GTKSA-RC MFP-capable (0x0080)
> ```
> `MFP-required` significa que no hay nada que hacer por esta vía. `MFP-capable` a secas indica modo opcional: funcionará contra los clientes que no lo negocien. Las alternativas cuando `PMF` bloquea están en [[01 - Tramas de gestión y su valor ofensivo]].

## Consideraciones operativas

**Omitir `-c` es casi siempre mala idea.** Una desautenticación broadcast tira a todos los clientes del AP a la vez: en producción eso es un incidente, no una prueba. Con `-c` se afecta a un solo dispositivo elegido.

**La deauth es ruidosa por diseño.** Decenas de tramas por segundo con `reason code 7`, MAC de origen suplantada y números de secuencia que no encajan en la serie del AP legítimo: es la firma que busca cualquier WIDS. Un ataque de cinco ráfagas dirigidas deja mucha menos huella que `-0 0`.

**A veces no hace falta.** El propio módulo lo señala para su laboratorio, y vale también fuera: <mark style="background: #8000E1A6;">los clientes se reasocian solos al cambiar de AP, salir de suspensión o empezar la jornada</mark>. Si el alcance permite estar en el edificio a primera hora, la captura pasiva consigue lo mismo sin transmitir nada.

**Un cliente desautenticado puede no volver.** Si el dispositivo tiene otra red disponible —datos móviles, otro SSID— puede irse a ella y no reconectar. Se pierde el handshake y se interrumpe al usuario para nada.

# WPA migration mode (`-8`)

El modo que HTB lista pero no explica. Algunos AP soportan **WPA y WEP simultáneamente** sobre el mismo SSID para dar cabida a clientes antiguos. El ataque explota que el AP acepta tráfico WEP, permitiendo aplicar los ataques de WEP contra una red que se anuncia como WPA. Es raro hoy, pero aparece en entornos industriales y en equipamiento Cisco heredado — y cuando aparece, <mark style="background: #FFB86CA6;">convierte una red "WPA" en una red WEP a efectos prácticos</mark>.

# Después de la captura

Con el handshake en el `.cap`, el trabajo pasa a ser offline: [[06 - Aircrack-ng]] para recuperar la clave, y [[05 - Airdecap-ng]] para descifrar el tráfico capturado una vez que se tiene.
