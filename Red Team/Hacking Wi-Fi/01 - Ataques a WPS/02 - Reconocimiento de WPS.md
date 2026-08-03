---
tags:
  - Wi-Fi/WPS
  - Pentesting/Enumeracion
Descripción: "Identificar APs con WPS, leer su versión, modo y estado de bloqueo con wash y airodump-ng, y la lectura correcta del campo wps_locked"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - El protocolo de registro y la anatomía del PIN]]"
Nota siguiente: "[[03 - Fuerza bruta online del PIN]]"
Area: "[[WPS.base|WPS]]"
---
---

<mark style="background: #ADCCFFA6;">Todo AP con WPS lo anuncia en un *information element* propietario dentro de sus beacons</mark>. El reconocimiento es por tanto **totalmente pasivo**: se lee escuchando, sin transmitir nada y sin dejar rastro.

Lo que hay que extraer antes de decidir un ataque:

| Dato | Por qué importa |
| ---- | --------------- |
| **Versión de WPS** | La 1.0 admite todos los vectores; la 2.0 suele traer bloqueo agresivo |
| **Estado de bloqueo** | Un AP bloqueado no acepta intentos de PIN |
| **Modo de configuración** | Si sólo admite `PBC`, la fuerza bruta del PIN no aplica |
| **Fabricante** | Determina si es candidato a Pixie Dust y a los generadores de PIN |

# Con airodump-ng

```shell-session
$ sudo airodump-ng --wps --ignore-negative-one wlan0mon

 BSSID              PWR Beacons  CH  MB   ENC  CIPHER AUTH WPS      ESSID
 60:38:E0:XX:XX:XX  -47      24   8  130  WPA2 CCMP   PSK  1.0 LAB  HTB-Wireless
 XX:XX:XX:XX:XX:XX  -43       1   6  195  WPA2 CCMP   PSK  2.0 PBC  FakeNetwork
 XX:XX:XX:XX:XX:XX  -43       1   6  195  WPA2 CCMP   PSK  1.0 DISP FakeNetwork
```

`--ignore-negative-one` silencia el aviso de canal fijo con ciertos drivers. Para centrarse en un objetivo:

```shell-session
$ sudo airodump-ng --wps --ignore-negative-one -c 8 --bssid 60:38:E0:XX:XX:XX wlan0mon
```

La columna `WPS` combina versión y **modo de configuración**:

| Acrónimo | Significado |
| -------- | ----------- |
| `LAB` | El PIN está impreso en una etiqueta del AP |
| `DISP` | El PIN se genera y muestra en el panel de administración |
| `KPAD` | El PIN se introduce en un teclado del cliente |
| `PBC` | Sólo botón |
| `USB` | Configuración por memoria USB |
| `ETHER` | Registro sobre Ethernet. Poco común |
| `EXTNFC` · `INTNFC` · `NFCINTF` | Variantes de NFC |
| `Locked` | WPS bloqueado, normalmente por exceso de intentos fallidos |

<mark style="background: #FF5582A6;">`LAB` es el modo más interesante</mark>: significa que el PIN es el de fábrica, impreso en la pegatina y nunca cambiado. Es el escenario donde los generadores de PIN por fabricante aciertan más — [[06 - Algoritmos de generación de PIN]].

`PBC` a secas no descarta el ataque: recuerda que la certificación obliga a soportar el método PIN aunque el AP anuncie el botón como su método de configuración. Merece la pena intentarlo.

# Con wash

`wash` viene con `reaver` y está especializado en esto:

```shell-session
$ sudo wash -i wlan0mon

BSSID               Ch  dBm  WPS  Lck  Vendor    ESSID
--------------------------------------------------------------------------
60:38:E0:XX:XX:XX    3  -07  1.0  No   AtherosC  HTB-Wireless
XX:XX:XX:XX:XX:XX    1  -63  2.0  No   LantiqML  FakeNetwork
XX:XX:XX:XX:XX:XX    1  -61  2.0  No   Quantenn  FakeNetwork
```

La columna `Vendor` es la que orienta el resto del trabajo: identifica el chipset, y el chipset determina si el AP es vulnerable a Pixie Dust. Atheros, Ralink, Broadcom y Realtek tienen historial conocido.

La salida en JSON da todos los campos del *information element*:

```shell-session
$ sudo wash -j -i wlan0mon
{"bssid" : "XX:XX:XX:XX:XX:XX", "essid" : "FakeNetwork", "channel" : 1,
 "rssi" : -61, "wps_version" : 32, "wps_state" : 2, "wps_locked" : 2,
 "wps_response_type" : "03", "wps_config_methods" : "0000", "wps_rf_bands" : "03"}
```

## Cómo leer esos campos

`wps_version: 32` no es "versión 32": es **hexadecimal** — `0x20` = versión **2.0**. La 1.0 aparece como `16` (`0x10`).

`wps_state: 2` significa *configured*: el AP ya tiene una red configurada. `1` sería *not configured*, típico de un equipo recién sacado de la caja.

> [!warning]+ HTB interpreta mal `wps_locked`
> El módulo afirma: *"si `wps_locked` vale 2, significa que WPS no está bloqueado"*. <mark style="background: #FF5582A6;">No es exacto</mark>. Verificado en el código fuente de reaver ([`src/libwps/libwps.h`](https://github.com/t6x/reaver-wps-fork-t6x/blob/master/src/libwps/libwps.h)):
>
> ```c
> enum wps_locked_state
> {
>     UNLOCKED,      /* 0 */
>     WPSLOCKED,     /* 1 */
>     UNSPECIFIED    /* 2 */
> };
> ```
>
> - `0` = **no bloqueado**, confirmado por el AP.
> - `1` = **bloqueado**.
> - `2` = **sin especificar**: el AP no publica el atributo *AP Setup Locked* en su WPS IE.
>
> El valor que confirma que se puede atacar es el `0`. Un `2` significa "no lo sé", y lo habitual es que no esté bloqueado —de hecho `wpsmon.c` usa `locked != 2` como parte de su heurística de WPS activo—, pero **no es una confirmación**. La única forma de saberlo con certeza es probar un PIN y ver si responde.

# Identificar el fabricante

```shell-session
$ grep -i "84-1B-5E" /var/lib/ieee-data/oui.txt
84-1B-5E   (hex)		NETGEAR
```

O directamente durante la captura:

```shell-session
$ sudo airodump-ng --wps --manufacturer wlan0mon
```

<mark style="background: #FFB8EBA6;">El OUI del BSSID identifica al fabricante de la carcasa, no siempre al del chipset</mark>, que es lo que determina la vulnerabilidad a Pixie Dust. Los campos `manufacturer`, `model_name` y `model_number` del WPS IE —que `wash -j` extrae— son más fiables: los publica el propio AP.

# La lista de comprobación antes de atacar

Con la información recogida, la decisión se toma así:

| Observación | Vector recomendado |
| ----------- | ------------------ |
| WPS 1.0, no bloqueado, chipset conocido | **Pixie Dust primero** — segundos, un solo intercambio |
| WPS 1.0, no bloqueado, chipset desconocido | Pixie Dust y, si falla, fuerza bruta online |
| WPS 2.0, no bloqueado | Pixie Dust, PIN nulo, y PINs por defecto del fabricante |
| Bloqueado (`Lck: Yes`) | Esperar al desbloqueo, o forzarlo — ver [[04 - APs con bloqueo y rate limiting]] |
| Sólo `PBC` anunciado | Intentar PIN igualmente; si no, ver [[09 - Push Button Configuration y sus abusos]] |

> [!important]+ Siempre Pixie Dust antes que fuerza bruta
> Pixie Dust necesita **un único intercambio EAP**: si funciona, el PIN aparece en segundos y sin acercarse al umbral de bloqueo. La fuerza bruta online son horas de tráfico contra el AP, con alta probabilidad de bloquearlo y de generar alertas. Probar primero lo barato es también lo más silencioso.

El vector clásico, y el que hay que entender antes que ninguno, es [[03 - Fuerza bruta online del PIN]].
