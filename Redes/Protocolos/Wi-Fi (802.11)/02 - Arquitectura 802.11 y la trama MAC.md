---
tags:
  - Redes
  - Protocolos
  - Wi-Fi/802.11
Descripción: "BSS, ESS y sistema de distribución, la estructura real de la trama MAC 802.11 y la tabla completa de tipos, subtipos y reason codes"
Fecha de actualización: 2026-08-04
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

Toda comunicación 802.11 —desde un beacon hasta un paquete de datos cifrado— viaja dentro de la misma estructura: <mark style="background: #ADCCFFA6;">la **trama MAC 802.11**, cuyos dos primeros bytes (el campo *Frame Control*) determinan cómo se interpreta todo lo demás</mark>. Entender esos dos bytes es la diferencia entre copiar un filtro de Wireshark y saber por qué funciona.

# Los bloques de la arquitectura

| Elemento | Qué es |
| -------- | ------ |
| **STA** (*station*) | Cualquier dispositivo con radio 802.11, incluido el AP |
| **AP** (*access point*) | La STA que coordina un BSS y hace de puente hacia la red cableada |
| **BSS** (*Basic Service Set*) | Un AP y las estaciones asociadas a él |
| **BSSID** | El identificador del BSS. En infraestructura es la MAC de la radio del AP |
| **SSID** | El nombre legible de la red, hasta 32 bytes. **No** identifica de forma única |
| **ESS** (*Extended Service Set*) | Varios BSS con el mismo SSID unidos por el sistema de distribución |
| **DS** (*Distribution System*) | La red troncal que interconecta los AP de un ESS. Casi siempre Ethernet |
| **IBSS** | Red ad-hoc entre estaciones, sin AP. El BSSID es aleatorio |

<mark style="background: #FFB8EBA6;">Un mismo SSID puede tener decenas de BSSID</mark>: cada AP —y, en radios multibanda, cada banda— publica el suyo. Además, cada SSID adicional en un mismo AP suele obtener un BSSID derivado incrementando los bits bajos de la MAC base. Esa aritmética es lo que permite inferir que dos redes aparentemente independientes (`Corp` y `Corp-Guest`) corren sobre la misma radio.

# La trama MAC

La cabecera es de longitud variable: los campos marcados como opcionales sólo aparecen si el tipo de trama los requiere. **Todos los tamaños en bytes**:

```text
┌────┬────────┬───────┬───────┬───────┬────┬───────┬─────┬─────┬─────────────┬─────┐
│ FC │ Dur/ID │ Addr1 │ Addr2 │ Addr3 │ SC │ Addr4 │ QoS │ HTC │ Frame Body  │ FCS │
├────┼────────┼───────┼───────┼───────┼────┼───────┼─────┼─────┼─────────────┼─────┤
│  2 │   2    │   6   │   6   │   6   │  2 │   6   │  2  │  4  │   0 – 2304  │  4  │
└────┴────────┴───────┴───────┴───────┴────┴───────┴─────┴─────┴─────────────┴─────┘
                                          └── opcional ──────┘
   cabecera mínima: 24 bytes  ────────────┘
```

| Campo | Función |
| ----- | ------- |
| **Frame Control** (FC) | 2 bytes con versión, tipo, subtipo y ocho banderas de 1 bit. Lo determina todo |
| **Duration/ID** | Microsegundos que la trama reservará el medio (`NAV`), o el AID en tramas PS-Poll |
| **Address 1–4** | Direcciones MAC. Su significado depende de `To DS`/`From DS`. La 4ª sólo en WDS/mesh |
| **Sequence Control** (SC) | Número de secuencia (12 bits) y de fragmento (4 bits) |
| **QoS Control** | Sólo en tramas QoS Data (802.11e). Lleva la categoría de tráfico |
| **HT/VHT Control** (HTC) | Sólo si la bandera `+HTC` está activa (802.11n y posteriores) |
| **Frame Body** | La carga útil. Cifrada si `Protected Frame` vale 1 |
| **FCS** | CRC-32 **de la cabecera y el cuerpo** (no de sí mismo). Detecta errores, no los corrige ni autentica nada |

> [!important]+ Dónde está el material de cifrado
> Cuando `Protected Frame` vale 1, entre la cabecera MAC y el cuerpo se inserta una **cabecera de cifrado** que el diagrama de arriba no muestra porque no forma parte de la trama MAC:
>
> | Esquema | Bytes | Contenido |
> | ------- | ----- | --------- |
> | WEP | 4 | IV de 3 bytes + `Key ID` |
> | TKIP | 8 | TSC + `Key ID` + `Ext IV` |
> | CCMP / GCMP | 8 | PN (número de paquete) + `Key ID` |
>
> <mark style="background: #FFB8EBA6;">Ahí es donde vive el IV de 3 bytes que hace explotable a WEP</mark>, y ahí se lee en Wireshark como `wlan.wep.iv` — ver [[03 - Cifrado y descifrado WEP paso a paso]]. Además, cada esquema añade al final del cuerpo su valor de integridad: 4 bytes de ICV en WEP, 8 de MIC en CCMP.

## Las banderas de Frame Control

| Bit(s) | Campo | Uso ofensivo |
| ------ | ----- | ------------ |
| 0–1 | Protocol Version | Siempre `0`. Un valor distinto revela un fuzzer o una implementación rota |
| 2–3 | **Type** | 00 gestión · 01 control · 10 datos · 11 extensión |
| 4–7 | **Subtype** | Ver tabla siguiente |
| 8 | To DS | Trama dirigida al sistema de distribución |
| 9 | From DS | Trama procedente del sistema de distribución |
| 10 | More Fragments | Hay más fragmentos de esta MSDU |
| 11 | Retry | Retransmisión. **Un exceso de retries delata inyección o interferencia** |
| 12 | Power Management | La estación entra en modo de ahorro. Falsificarlo hace que el AP encole el tráfico del cliente |
| 13 | More Data | El AP tiene tráfico encolado para una estación dormida |
| 14 | **Protected Frame** | El cuerpo va cifrado (WEP/TKIP/CCMP/GCMP) |
| 15 | +HTC/Order | Presencia del campo HT Control |

Los bits `To DS`/`From DS` son los que resuelven la ambigüedad de las direcciones, y es lo que HTB despacha con un "podrían significar cosas diferentes":

| To DS | From DS | Addr1 | Addr2 | Addr3 | Addr4 | Escenario |
| ----- | ------- | ----- | ----- | ----- | ----- | --------- |
| 0 | 0 | Destino | Origen | BSSID | — | Gestión, control e IBSS |
| 0 | 1 | Destino | BSSID | Origen | — | AP → estación |
| 1 | 0 | BSSID | Origen | Destino | — | Estación → AP |
| 1 | 1 | Receptor | Transmisor | Destino | Origen | WDS / mesh, 4 direcciones |

<mark style="background: #8000E1A6;">Esto significa que el "origen" de una trama no está siempre en el mismo sitio</mark>: leer `Addr2` como si siempre fuera el emisor real es un error clásico al escribir filtros o parsers propios.

# Tipos y subtipos

## Gestión (tipo 0)

| Subtipo | Trama | Relevancia |
| ------- | ----- | ---------- |
| 0 / 1 | Association Request / Response | Publican las capacidades del cliente |
| 2 / 3 | Reassociation Request / Response | Roaming entre AP del mismo ESS |
| 4 / 5 | Probe Request / Response | **El cliente revela SSIDs de su PNL** |
| 8 | Beacon | Anuncio periódico del AP, ~10 por segundo |
| 10 | Disassociation | Termina la asociación, mantiene la autenticación |
| 11 | Authentication | Autenticación 802.11 (no la de WPA) |
| 12 | Deauthentication | Termina autenticación y asociación |
| 13 / 14 | Action / Action No Ack | Vehículo de 802.11k/v/r, Block Ack, medidas |

> [!warning]+ HTB se equivoca aquí
> El módulo 222 afirma que "las tramas de desasociación y desautenticación se envían **desde el punto de acceso al cliente**". Es falso: <mark style="background: #FF5582A6;">son bidireccionales</mark>, y el propio módulo se contradice, porque su captura de ejemplo muestra una desasociación que va del cliente (`Apple_82:36:3a`) al AP. Esa bidireccionalidad es justo lo que explota el ataque: `aireplay-ng --deauth` puede falsificar el AP hacia el cliente, el cliente hacia el AP, o ambos a la vez.

## Control (tipo 1)

| Subtipo | Trama |
| ------- | ----- |
| 2 | Trigger (802.11ax) |
| 8 / 9 | Block Ack Request / Block Ack |
| 10 | PS-Poll |
| 11 / 12 / 13 | RTS / CTS / ACK |

Las tramas de control nunca se cifran ni se protegen con `PMF`. Esa es su debilidad estructural: un RTS/CTS forjado con un `Duration` alto reserva el medio y silencia a todos los que lo escuchan (*virtual jamming*), y las Block Ack se pueden manipular para bloquear una sesión, como demuestra el ataque [Bl0ck](https://arxiv.org/pdf/2302.05899).

## Datos (tipo 2) y extensión (tipo 3)

Los subtipos de datos relevantes son `0` (Data), `4` (Null Function — sin carga, se usa para señalizar ahorro de energía) y `8` (QoS Data, el habitual en cualquier red moderna).

El **tipo 3 (Extension)** no aparece en el material de HTB, que lo da por reservado. Dejó de serlo con 802.11ad-2012: hoy alberga el **DMG Beacon** (subtipo 0, 60 GHz) y el **S1G Beacon** (subtipo 1, sub-1 GHz de Wi-Fi HaLow). Un filtro que asuma que sólo existen los tipos 0–2 es ciego a esas redes.

# Reason codes

Las tramas de desautenticación y desasociación llevan un código de motivo de 2 bytes. Los que se ven en la práctica:

| Código | Motivo |
| ------ | ------ |
| 1 | Sin especificar |
| 2 | Autenticación previa ya no válida |
| 3 | La estación abandona el BSS |
| 4 | Desasociada por inactividad |
| 6 | Trama de clase 2 desde estación no autenticada |
| 7 | Trama de clase 3 desde estación no asociada |
| 15 | Timeout del *4-way handshake* |

<mark style="background: #FFB86CA6;">`aireplay-ng` emite por defecto el código 7, y lo hace en ráfagas idénticas</mark>. Un motivo 7 repetido decenas de veces por segundo, con números de secuencia que no encajan en la serie del AP legítimo, es la firma más obvia de un ataque de desautenticación — y lo primero que busca cualquier WIDS.

# Qué protege PMF y qué no

Con `802.11w` activo, las tramas de gestión **unicast posteriores a la asociación** llevan un `MIC` derivado de la `IGTK`/`PTK`, así que una deauth forjada se descarta. Beacons y *probe requests* quedan fuera por necesidad: deben ser legibles por quien todavía no se ha asociado.

Ese hueco es donde vive la ofensiva moderna. Schepers y Vanhoef demostraron que un beacon falsificado que anuncie un ancho de canal inválido basta para que el cliente se desconecte solo ([WiSec 2022](https://papers.mathyvanhoef.com/wisec2022.pdf)), y el vector sigue produciendo CVE: **`CVE-2025-71127`** cubre beacons unicast dirigidos contra estaciones asociadas en el kernel de Linux. Wi-Fi 7 responde exigiendo **beacon protection**, pero sólo cubre el beacon, no la *probe request*.

La explotación concreta de cada una de estas tramas se desarrolla en [[01 - Tramas de gestión y su valor ofensivo]] y [[02 - El ciclo de conexión y sus puntos de ruptura]].

Lo que va **dentro** del cuerpo de esas tramas —el elemento RSN que declara cifrados y método de autenticación, la jerarquía de claves y el 4-way handshake— continúa en [[03 - RSN, WPA2 y el 4-way handshake]], y lo que WPA3 cambia de ese modelo, en [[04 - WPA3, SAE y OWE]].
