---
tags:
  - Wi-Fi
  - Tipo/Deteccion
  - Blue-Team
Descripción: "El catálogo público de alertas de Kismet, sus umbrales por defecto y qué firma deja cada ataque inalámbrico en un WIDS"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Fuentes de datos y uso operativo]]"
Nota siguiente: 
Area: "[[Kismet.base|Kismet]]"
---
---

<mark style="background: #ADCCFFA6;">El catálogo de alertas de Kismet es público, y eso lo convierte en la mejor referencia disponible de qué detecta un WIDS</mark>. Los productos comerciales —Cisco aWIPS, Aruba RFProtect, Meraki Air Marshal— no publican sus firmas, pero comparten el mismo repertorio de fenómenos observables.

Sirve para las dos ópticas: montar detección, y saber qué umbral no conviene superar durante un engagement.

# Las alertas que importan

Extraídas de `kismet_alerts.conf`. La segunda columna es el umbral por defecto, en formato `por minuto / por segundo`:

| Alerta | Umbral | Qué la dispara |
| ------ | ------ | -------------- |
| `DEAUTHFLOOD` | 5/min, 2/s | Exceso de desautenticaciones |
| `BCASTDISCON` | 5/min, 2/s | Desasociaciones de difusión |
| `APSPOOF` | 10/min, 1/s | SSID anunciado por un BSSID **no autorizado** |
| `CRYPTODROP` | 5/min, 1/s | Una red baja su nivel de cifrado |
| `KARMAOUI` | 5/min, 1/s | AP que responde a cualquier *probe* |
| `NOCLIENTMFP` | 10/min, 1/s | Cliente que no negocia PMF |
| `NULLPROBERESP` | 5/min, 1/s | Respuesta de *probe* malformada |
| `OVERPOWERED` | **deshabilitada** | AP con potencia anómala para su distancia |
| `NONCEREUSE` / `NONCEDEGRADE` | **deshabilitadas** | Reinstalación de clave (KRACK) |
| `ADVCRYPTCHANGE` | — | Un AP cambia su configuración de cifrado |
| `MALFORMMGMT` | — | Trama de gestión malformada: fuzzing |
| `LONGSSID` | — | SSID que excede los 32 bytes: desbordamiento |
| `FLIPPERZERO` | — | Firma de un Flipper Zero |
| `BLEEDINGTOOTH` | — | Explotación de la vulnerabilidad Bluetooth |

# Qué ataque dispara qué

| Ataque | Alerta |
| ------ | ------ |
| Deauth para forzar handshake | `DEAUTHFLOOD` |
| Deauth de difusión | `BCASTDISCON` |
| Evil twin / MANA | `APSPOOF`, y `OVERPOWERED` si está más cerca |
| **Downgrade de WPA3 a WPA2** | `CRYPTODROP` |
| Karma clásico | `KARMAOUI` |
| Fuzzing de tramas de gestión | `MALFORMMGMT`, `NULLPROBERESP` |

<mark style="background: #8000E1A6;">`CRYPTODROP` es la que caza el ataque más rentable contra WPA3</mark>: ve a un cliente pasar de SAE a PSK, que es exactamente la firma del downgrade de modo transición descrito en [[05 - WPA3 en modo transición y downgrade]].

# Dos alertas apagadas por defecto que conviene encender

`OVERPOWERED`, `NONCEREUSE` y `NONCEDEGRADE` vienen con umbral `0/min, 0/sec` — desactivadas. Las dos últimas detectan **KRACK**, y la primera es de las mejores contra un evil twin, porque un AP falso casi siempre está más cerca del cliente que el legítimo.

```text
kismet_site.conf
alert=OVERPOWERED,5/min,1/sec
alert=NONCEREUSE,5/min,1/sec
alert=NONCEDEGRADE,5/min,1/sec
```

Están apagadas porque generan falsos positivos en entornos con topología cambiante. En un despliegue fijo —una oficina, una planta— compensan.

# `APSPOOF` necesita configuración

Es la alerta más valiosa y la única que **no funciona sin declarar antes qué es legítimo**. Su comentario en el fichero lo explica: se dispara *"when a SSID is advertised by a device not in the approved list"*.

```text
kismet_site.conf
apspoof=CorpWiFi:ssidregex="^CorpWiFi$",validmacs="00:11:22:33:44:55,00:11:22:33:44:66"
```

<mark style="background: #FFB86CA6;">Sin la lista de BSSID autorizados, Kismet no puede saber que un AP es falso</mark> — para él es un AP más con ese nombre. Es la recomendación concreta que hay que llevar al informe cuando el cliente dice tener WIDS: **tenerlo instalado no basta si nadie declaró el inventario legítimo**.

# La firma del reason code es más débil de lo que se cree

Se repite mucho que un `reason code 7` en ráfaga delata a `aireplay-ng`. Kismet marca su alerta `DEAUTHCODEINVALID` como **deprecada**, con este motivo textual:

> *"Deprecated; not typically meaningful & many modern APs seem to use custom codes at times"*

Lo que delata no es el código, sino <mark style="background: #FFB8EBA6;">la **tasa** y la incoherencia de los números de secuencia</mark> respecto a la serie del AP legítimo. Por eso tres tramas dirigidas pasan y sesenta no: los umbrales son de frecuencia, no de presencia.

# Consumir las alertas fuera de Kismet

```shell-session
$ curl -s http://localhost:2501/alerts/all_alerts.json | jq '.[] | {time: .kismet.alert.timestamp, type: .kismet.alert.class, text: .kismet.alert.text}'
```

La API REST permite integrar Kismet en un SIEM sin depender de su interfaz. Para un cliente sin WIPS comercial, un sensor con Kismet y sus alertas enviadas al SIEM es una recomendación barata y real — el argumento completo, en [[12 - Detección y evasión en entorno corporativo]].

> [!important]+ Lo que ningún WIDS de radio ve
> Conviene ser honesto sobre el límite en el informe: <mark style="background: #FF5582A6;">el ataque que abre un dominio a través del Wi-Fi corporativo —un cliente aceptando un certificado RADIUS falso— no genera ninguna alerta de radio</mark>. Sólo aparece como `APSPOOF`, y sólo si el inventario está declarado.
>
> La detección de ese ataque vive en el RADIUS, no en el aire: un usuario cuyas sesiones desaparecen del servidor mientras sigue en el edificio. Recomendar únicamente un WIDS deja el vector principal sin cubrir.
