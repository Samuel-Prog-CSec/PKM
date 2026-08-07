---
tags:
  - Wi-Fi
  - Tipo/Introduccion
  - Redes
Descripción: "El demonio que convierte una tarjeta en punto de acceso: los parámetros que de verdad importan y las trampas de nomenclatura que arrastran los tutoriales"
Fecha de actualización: 2026-08-04
Nota previa: 
Nota siguiente: "[[01 - AP falso con hostapd]]"
Area: "[[hostapd.base|hostapd]]"
---
---

<mark style="background: #ADCCFFA6;">`hostapd` es el demonio que convierte una tarjeta Wi-Fi en punto de acceso</mark>, e incluye además un servidor de autenticación IEEE 802.1X/EAP integrado. Es la implementación de referencia: casi todo el ecosistema —desde los routers domésticos hasta `EAPHammer` o `airgeddon`— lo lleva dentro.

| Dato | Valor |
| ---- | ----- |
| Versión estable | **2.11** (20 de julio de 2024) |
| Proyecto | `hostap`, de Jouni Malinen — [w1.fi](https://w1.fi/) |
| Novedades de 2.11 | Wi-Fi 7 (EHT) preliminar, DPP R3, OpenSSL 3.0, PASN |
| Gemelo | `wpa_supplicant`, el lado cliente, del mismo proyecto |

Conocerlo importa por dos motivos opuestos: es lo que se levanta para montar un [[01 - AP falso con hostapd|AP falso]], y es donde se leen las contramedidas que hay que recomendar al cliente, porque su `hostapd.conf` documenta cada parámetro de seguridad de 802.11 con precisión.

# La configuración mínima

```config
interface=wlan1
driver=nl80211
ssid=MiRed
hw_mode=g
channel=6

wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=UnaContraseñaLarga
```

```shell-session
$ sudo hostapd hostapd.conf
$ sudo hostapd -dd hostapd.conf     # depuración
$ sudo hostapd -B hostapd.conf      # segundo plano
```

# Las tres trampas de nomenclatura

> [!warning]+ `wpa=3` **no** es WPA3
> El campo `wpa` es un **mapa de bits**, no un número de versión:
>
> | Valor | Significado |
> | ----- | ----------- |
> | `1` | WPA original (TKIP) |
> | `2` | RSN / WPA2 |
> | `3` | **Ambos a la vez** |
>
> <mark style="background: #FF5582A6;">Poner `wpa=3` habilita WPA1 con TKIP</mark>, justo lo contrario de lo que sugiere el nombre. WPA3 se expresa con `wpa=2` + `wpa_key_mgmt=SAE` + `ieee80211w=2`. Es un error que aparece en material de formación y que produce un AP más débil del que se pretendía.

La segunda trampa es la pareja `wpa_pairwise` / `rsn_pairwise`:

| Parámetro | Aplica a |
| --------- | -------- |
| `wpa_pairwise` | Cifrados para **WPA1** |
| `rsn_pairwise` | Cifrados para **WPA2/WPA3** |

Declarar `wpa_pairwise=TKIP CCMP` con `wpa=2` no hace nada útil: para RSN el parámetro correcto es `rsn_pairwise`. Muchas configuraciones que circulan mezclan ambos por copia.

La tercera es `auth_algs`, que se refiere a la autenticación **802.11**, no a la de WPA:

| Valor | Significado |
| ----- | ----------- |
| `1` | Open System — lo correcto para WPA2/WPA3 |
| `2` | Shared Key — **es de WEP** |
| `3` | Ambos |

<mark style="background: #FFB8EBA6;">`Shared Key` pertenece a WEP y no tiene nada que ver con la clave precompartida de WPA</mark>. La confusión es tan común que HTB la comete en su módulo de fundamentos; el detalle está en [[03 - Métodos de autenticación y cifrado]].

# Parámetros de seguridad que hay que auditar

Estos son los que se comprueban en un engagement y los que se recomiendan en el informe:

| Parámetro | Valor recomendado | Qué protege |
| --------- | ----------------- | ----------- |
| `ieee80211w` | `2` (obligatorio) | **PMF**: invalida la desautenticación forjada |
| `sae_require_mfp` | `1` | Exige PMF a los clientes SAE |
| `sae_pwe` | `1` o `2` | Hash-to-element: cierra el canal lateral de Dragonblood |
| `transition_disable` | `0x01` | Impide el downgrade de WPA3 a WPA2 |
| `wpa_key_mgmt` | `SAE` (sin `WPA-PSK`) | Elimina el modo transición |
| `rsn_pairwise` | `CCMP` (nunca `TKIP`) | TKIP está deautorizado desde 802.11-2012 |
| `beacon_prot` | `1` | Protección de beacons (Wi-Fi 7) |
| `ignore_broadcast_ssid` | — | **No es una medida de seguridad**: el SSID se descubre igual |

> [!important]+ Los valores por defecto no son los seguros
> `sae_pwe` vale `0` por defecto —hunting-and-pecking, el vulnerable— y `transition_disable` vale `0`, es decir, **no se envía**. <mark style="background: #FF5582A6;">Un AP WPA3 con la configuración de serie sigue expuesto</mark> al canal lateral de Dragonblood y al downgrade. Son las dos preguntas de auditoría más rentables contra un despliegue WPA3, desarrolladas en [[04 - WPA3, SAE y OWE]].

# Configuración WPA3-Personal

```config
interface=wlan1
ssid=MiRedSegura
hw_mode=g
channel=6

wpa=2
wpa_key_mgmt=SAE
rsn_pairwise=CCMP
sae_password=UnaContraseñaLarga
ieee80211w=2
sae_require_mfp=1
sae_pwe=2
transition_disable=0x01
```

Nótese `sae_password` en vez de `wpa_passphrase`: son parámetros distintos, y usar el segundo con `key_mgmt=SAE` no funciona como se espera. Para modo transición se declaran ambos y `wpa_key_mgmt=WPA-PSK SAE`, con `ieee80211w=1` — porque `2` impediría conectarse a los clientes WPA2, que es justo el motivo de existir del modo transición.

# El fichero como documentación

`hostapd.conf` es, en la práctica, **la mejor documentación de los parámetros de seguridad de 802.11** que existe en texto plano: cada opción viene con su explicación, sus valores y sus implicaciones. Cuando hay duda sobre qué hace exactamente un bit del RSN IE o cómo se configura una contramedida, es la fuente a consultar antes que cualquier blog.

```shell-session
$ zless /usr/share/doc/hostapd/examples/hostapd.conf.gz
$ curl -s https://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf | less
```
