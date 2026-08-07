---
tags:
  - Wi-Fi/Enterprise
  - Pentesting/Enumeracion
Descripción: "Leer el RSN IE para decidir el ataque antes de lanzarlo, distinguir un ESS de una red ad-hoc y por qué conviene cruzar airodump-ng con Kismet"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - El engagement Wi-Fi corporativo]]"
Nota siguiente: "[[02 - Redes guest y portales cautivos]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

El reconocimiento de un parque corporativo tiene un objetivo muy concreto: <mark style="background: #ADCCFFA6;">responder, para cada SSID en alcance, qué AKM usa y si tiene `PMF`</mark>. Con esas dos respuestas el árbol de ataque queda decidido y se evitan horas de intentos contra vías cerradas.

# Barrido acotado al alcance

```shell-session
$ sudo airmon-ng start wlan0
$ sudo airodump-ng wlan0mon --essid StarLight-WCD
$ sudo airodump-ng wlan0mon --essid StarLight-WCD --wps -c 1 --bssid 10:7B:EF:08:A3:B4 -w recon
```

Un barrido sin filtros en una oficina devuelve decenas de redes ajenas. Filtrar por ESSID autorizado no es comodidad: es lo que mantiene la captura dentro del alcance contratado, como se argumenta en [[00 - El engagement Wi-Fi corporativo]].

La columna `WPS` de `--wps` es el primer atajo que hay que buscar: si aparece una versión (`2.0`) en vez de `0.0`, hay una vía potencialmente mucho más corta que crackear la PSK — ver [[02 - Reconocimiento de WPS]].

> [!warning]+ Varios BSSID con el mismo SSID **no** es una red ad-hoc
> HTB describe repetidamente un despliegue con varios AP anunciando el mismo ESSID como *"ad-hoc style setup"*, y llega a hablar de *"a station connected to an AP operating in ad-hoc mode"*. <mark style="background: #FF5582A6;">Es exactamente lo contrario</mark>.
>
> | Concepto | Qué es |
> | -------- | ------ |
> | **BSS** | Un AP y sus clientes |
> | **ESS** | Varios BSS con el mismo SSID unidos por el sistema de distribución. **Esto es lo que se ve** |
> | **IBSS / ad-hoc** | Red entre estaciones **sin AP**. No hay infraestructura que atacar |
>
> Un ESS es el despliegue normal de cualquier organización: permite roaming y cobertura. Confundirlo con ad-hoc lleva a conclusiones erróneas sobre segmentación y sobre qué se puede suplantar. El detalle está en [[02 - Arquitectura 802.11 y la trama MAC]].

En un ESS, cada BSSID es un AP (o una radio) distinto, y **cada uno puede estar configurado de forma diferente**. En el caso guía sólo uno de los once AP de `WCD` tiene WPS activo, y sólo uno de los tres de `PRT` está en modo transición. Tratar el SSID como una unidad homogénea hace perder justo el AP explotable.

# Lo que decide el ataque: el RSN IE

`airodump-ng` resume la seguridad en dos columnas (`ENC`, `AUTH`) y eso no basta. La información completa está en el elemento RSN del beacon, y se lee en Wireshark sobre la captura de `-w`:

```text
wlan.fc.type_subtype == 8 && wlan.ssid == "StarLight-PRT"
```

| Campo a mirar | Filtro | Qué revela |
| ------------- | ------ | ---------- |
| Lista de AKM | `wlan.rsn.akms.type` | PSK (2), SAE (8), 802.1X (1), OWE (18) |
| PMF disponible | `wlan.rsn.capabilities.mfpc` | El AP soporta 802.11w |
| PMF obligatorio | `wlan.rsn.capabilities.mfpr` | La deauth **no** funcionará |
| Cifrado de grupo | `wlan.rsn.gcs.type` | TKIP (2) es un hallazgo por sí solo |

<mark style="background: #FFB86CA6;">Ver `PSK` y `SAE` juntos en la misma lista de AKM es el hallazgo más rentable del reconocimiento</mark>: significa modo transición WPA3, y por tanto una vía de downgrade a WPA2 — ver [[05 - WPA3 en modo transición y downgrade]]. Ver sólo `SAE` cierra esa puerta.

Todos los nombres de campo están verificados contra el disector `packet-ieee80211.c` de Wireshark. La interpretación de cada valor de AKM está en [[03 - RSN, WPA2 y el 4-way handshake]].

# Kismet como segunda opinión

`airodump-ng` salta de canal y muestra una instantánea; en un entorno con decenas de AP y mucho ruido pierde cosas. `Kismet` mantiene estado, correlaciona cliente con AP a lo largo del tiempo y expone una interfaz web con filtros.

```shell-session
$ sudo kismet -c wlan0mon
```

Su servidor levanta en `http://localhost:2501`. La primera vez pide crear credenciales; conviene fijarlas en `~/.kismet/kismet_httpd.conf` para no repetir el paso en cada caja desplegada.

| Vista | Para qué |
| ----- | -------- |
| `Devices` filtrado por SSID | Todos los BSSID de un ESS y sus clientes |
| Ficha del AP | Fabricante, canal, cifrado, clientes asociados |
| Pestaña `SSID` | Redes **buscadas** por clientes: `Advertising` y `Responding` a 0 = el AP no está |
| `Data Sources` | Configuración de salto de canal (por defecto ~5 saltos/s) |

<mark style="background: #8000E1A6;">Ese contador `Responding: 0` es el que identifica una red fantasma</mark>: un SSID que los clientes siguen buscando aunque su AP ya no exista. Es la condición exacta que habilita [[07 - Karma y MANA]].

No es que una herramienta sea mejor: es que fallan de forma distinta. Cruzar ambas —y `Wireshark` sobre la captura— es lo que evita cerrar el reconocimiento con un AP sin descubrir.

# Clientes que buscan redes ausentes

```shell-session
$ sudo airodump-ng wlan0mon --essid StarLight-INT -w INT
$ sudo airgraph-ng -i INT-01.csv -g CPG -o INT_CPG.png
```

El **Common Probe Graph** de `airgraph-ng` dibuja qué cliente busca qué red. Un cliente que emite *probe requests* dirigidas por un SSID que nadie anuncia es una oportunidad servida en bandeja, y el grafo lo hace evidente de un vistazo.

> [!info]+ La PNL se ha reducido mucho, pero no ha desaparecido
> Desde ~2015, iOS, Android y Windows dejaron de emitir *probe requests* dirigidas para todas las redes conocidas y usan sobre todo escaneo pasivo con MAC aleatoria. <mark style="background: #FFB8EBA6;">Que un cliente siga preguntando por su nombre indica un dispositivo antiguo, un perfil de red oculta, o un equipo gestionado con configuración específica</mark> — y todos ellos son objetivos de calidad. La consecuencia es que hoy hay **menos** material que hace diez años, no que la técnica esté muerta.

# Qué se anota

El reconocimiento produce una tabla que gobierna todo lo demás:

| SSID | BSSID | Canal | AKM | PMF | WPS | Clientes | Vía prevista |
| ---- | ----- | ----- | --- | --- | --- | -------- | ------------ |
| `WCD` | `10:7B:EF:08:A3:B4` | 1 | PSK | No | **2.0** | 0 | PIN WPS |
| `PRT` | `9C:9A:03:39:BD:7A` | 1 | **PSK+SAE** | Sí | — | 1 | Downgrade |
| `SEC` | `D8:D4:3D:E1:29:D5` | 1 | SAE | **Sí** | — | 0 | Online / colisión |
| `BYOD` | `FE:E1:DE:CE:A5:E1` | 1 | PSK (**TKIP**) | No | 0.0 | 1 | Handshake + evil twin |
| `INT` | — | — | — | — | — | 1 probando | Karma / MANA |

Esa tabla es a la vez el plan de ataque y el esqueleto del apartado de enumeración del informe. Anotar `PMF: No` y `TKIP` ya son dos hallazgos reportables antes de haber atacado nada.
