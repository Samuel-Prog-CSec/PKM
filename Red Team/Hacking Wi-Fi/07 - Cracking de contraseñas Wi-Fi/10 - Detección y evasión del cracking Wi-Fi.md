---
tags:
  - Wi-Fi/WPA
  - Tipo/Deteccion
  - Pentesting/Explotacion
Descripción: "El crackeo no deja rastro pero la captura sí: qué alerta cada método de obtención de handshake y qué disciplina lo mantiene por debajo del umbral de un WIPS"
Fecha de actualización: 2026-08-04
Nota previa: "[[09 - Contraseñas de dispositivos de red Cisco]]"
Nota siguiente: "[[11 - Arsenal de cracking Wi-Fi]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

<mark style="background: #ADCCFFA6;">El crackeo en sí es invisible</mark>: ocurre en una GPU, sin tocar la red, y ningún sensor del mundo lo detecta. Toda la exposición está en la fase anterior — conseguir el material. Eso invierte la intuición habitual: lo que hay que planificar con sigilo no es el ataque, es la captura.

# Qué emite cada método

| Método | Huella radioeléctrica | Registro en el lado del cliente |
| ------ | --------------------- | ------------------------------- |
| Captura pasiva | **Ninguna**. No se transmite nada | Ninguno |
| Petición de PMKID | Una asociación fallida por AP | Intento de asociación en el WLC |
| Deauth dirigida | Ráfaga de tramas forjadas | Desconexión del cliente + alerta |
| Deauth de difusión | Ráfaga masiva | Desconexión de la celda entera |
| AP falso | Beacons con SSID ajeno | Alerta de rogue AP, casi inmediata |

La escala de ruido va de cero a máximo en ese orden, y <mark style="background: #8000E1A6;">el método más silencioso es también el que más tiempo cuesta</mark>. Es la negociación real del engagement: ventana amplia y sigilo, o ventana corta y ruido asumido.

# Cómo se ve desde el lado defensor

Los WIPS comerciales del parque corporativo —**Cisco aWIPS**, **Aruba RFProtect**, **Meraki Air Marshal**— comparten el catálogo de firmas con `Kismet`, que sirve como referencia porque sus reglas son públicas. Del fichero `kismet_alerts.conf`, las que importan aquí:

| Alerta | Qué dispara | Umbral por defecto |
| ------ | ----------- | ------------------ |
| `DEAUTHFLOOD` | Exceso de desautenticaciones | 5/min, 2/s |
| `BCASTDISCON` | Desasociaciones de difusión | 5/min, 2/s |
| `APSPOOF` | SSID anunciado por un BSSID no autorizado | 10/min, 1/s |
| `OVERPOWERED` | AP con potencia anómala para su distancia | deshabilitada por defecto |
| `KARMAOUI` | Firma de un AP que responde a todo | 5/min, 1/s |
| `NOCLIENTMFP` | Cliente que no negocia PMF | 10/min, 1/s |
| `NONCEREUSE` / `NONCEDEGRADE` | Reinstalación de clave (KRACK) | deshabilitadas |
| `CRYPTODROP` | Una red baja su nivel de cifrado | 5/min, 1/s |

Dos lecturas útiles. La primera: **los umbrales son de tasa, no de presencia**. Tres deauth dirigidas separadas por segundos no llegan a `5/min`; sesenta seguidas de `aireplay-ng -0 5` sí, y por goleada. La segunda: `CRYPTODROP` es la que caza el downgrade de [[05 - WPA3 en modo transición y downgrade|WPA3 en modo transición]], porque ve a un cliente pasar de SAE a PSK.

> [!info]+ La firma del reason code es más débil de lo que se cree
> Se repite mucho que un `reason code 7` en ráfaga delata a `aireplay-ng`. Kismet marca su alerta `DEAUTHCODEINVALID` como **deprecada**, con este motivo textual: *"not typically meaningful & many modern APs seem to use custom codes at times"*. <mark style="background: #FFB8EBA6;">Lo que delata no es el código, es la tasa y la incoherencia de los números de secuencia</mark> respecto a la serie del AP legítimo.

Del lado cableado hay una fuente que se olvida: el **WLC y el RADIUS**. Cada asociación fallida y cada `Access-Reject` quedan registrados con MAC, hora y AP. Un barrido de PMKID contra treinta AP es silencioso en el aire y perfectamente visible en el syslog del controlador.

# Disciplina de captura

Lo que sigue funcionando no es ocultar el ataque, es **hacer menos y parecerse a lo normal** — el mismo principio que en [[08 - Cómo te ve el defensor|evasión de perímetro]].

| Práctica | Por qué |
| -------- | ------- |
| MAC aleatoria y distinta por sesión | El identificador que acaba en el informe de incidentes |
| Fijar canal en vez de saltar | Menos tiempo de radio, menos oportunidad de correlación |
| Deauth dirigida, 2-3 tramas | Por debajo de cualquier umbral de tasa |
| Potencia mínima suficiente | `OVERPOWERED` y la triangulación se alimentan de dBm |
| Ventanas de alta rotación | Los handshakes llegan solos a las 9:00 |
| Filtro BPF al alcance | Reduce lo capturado **y** documenta el alcance |

```shell-session
$ sudo macchanger -r wlan0
$ sudo hcxdumptool -i wlan0 -c 6a --bpf=alcance.bpf --exitoneapol -w captura.pcapng
```

<mark style="background: #FFB86CA6;">`--exitoneapol` es la mejor medida de sigilo que ofrece la herramienta</mark>: en cuanto tiene material utilizable deja de transmitir, en vez de seguir insistiendo contra APs que ya no aportan nada.

# Lo que ya no evade

| Técnica | Estado |
| ------- | ------ |
| Suplantar la MAC de un cliente legítimo | Provoca colisión y DoS — se detecta **y** rompe servicio |
| Deauth masiva "para ir más rápido" | Alerta garantizada, y muchos clientes la ignoran |
| Confiar en que nadie mira el 2,4 GHz | Los AP modernos escanean fuera de banda de forma continua |
| Evitar PMF cambiando de canal | `PMF` es por asociación, no por canal |

Con `PMF` obligatorio la deauth no es que se detecte: es que **no funciona**. Insistir sólo genera alertas sin resultado, que es el peor de los dos mundos.

# El límite que no es técnico

Un handshake es material de autenticación de la red del cliente, y a menudo arrastra identidades de personas ([[08 - Cracking de identidades WPA-Enterprise|EAP Identity]] en claro, nombres de dispositivo). Eso lo convierte en **dato personal** a efectos del RGPD en cuanto sale del entorno del cliente.

Tres consecuencias operativas concretas:

1. **Autorización expresa antes de capturar**, no después. Debe constar en el RoE si el material saldrá del entorno del cliente y a dónde (rig propio, nube).
2. **El filtro BPF y `hcxhashtool --essid` son la prueba** de que no se procesó lo que no estaba en alcance. Sin ellos, la captura de un edificio compartido contiene redes de terceros.
3. **Borrado documentado al cierre**, con el resto de artefactos del engagement — ver [[15 - Cierre del engagement]].

En España la interceptación de comunicaciones ajenas encaja en el `art. 197.1 CP` y el acceso posterior en el `art. 197 bis`. La autorización del titular es lo único que separa el engagement del tipo penal, y **su alcance geográfico importa tanto como el técnico**: las ondas no se detienen en el perímetro contratado.

# Qué recomendar al cliente

| Hallazgo | Medida |
| -------- | ------ |
| PSK recuperada | Passphrase ≥ 15 caracteres generada, o migrar a Enterprise |
| Deauth efectiva | Activar `PMF` (`ieee80211w=2` donde el parque lo permita) |
| PMKID entregado | Deshabilitar el cacheo de PMK si no se usa roaming rápido |
| Sin WIPS | Detección de rogue AP y umbrales de deauth en el controlador |
| WPA3 en transición | `transition_disable` y plan de retirada de WPA2 |

La medida de más recorrido casi nunca es la más técnica: <mark style="background: #FF5582A6;">una passphrase larga y generada elimina de raíz todo lo descrito en este sub-tema</mark>, mientras que `PMF` sólo encarece la captura.
