---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "El ataque clásico con reaver: recorrer las 11.000 combinaciones, reanudar desde media mitad conocida y probar el PIN nulo"
Fecha de actualización: 2026-08-01
Nota previa: "[[02 - Reconocimiento de WPS]]"
Nota siguiente: "[[04 - APs con bloqueo y rate limiting]]"
Area: "[[WPS.base|WPS]]"
---
---

<mark style="background: #ADCCFFA6;">La fuerza bruta *online* consiste en abrir un intercambio WPS por cada PIN candidato y leer en qué mensaje llega el `NACK`</mark>. Como el AP valida las dos mitades por separado, el espacio de búsqueda son 11.000 intentos, no 10⁸ — el detalle está en [[01 - El protocolo de registro y la anatomía del PIN]].

![Diagrama del ataque de fuerza bruta online: el atacante prueba PINs consecutivos contra el AP hasta acertar](https://academy.hackthebox.com/storage/modules/186/BruteForcing/Online/WPS_BRUTE.png)

# Preparar la interfaz

> [!warning]+ No usar `airmon-ng` con reaver
> Existe un fallo conocido por el que una interfaz creada con `airmon-ng start` hace que `reaver` no funcione correctamente. <mark style="background: #FF5582A6;">Crear la interfaz de monitor a mano con `iw`</mark>:
> ```shell-session
> $ sudo iw dev wlan0 interface add mon0 type monitor
> $ sudo ip link set mon0 up
> $ iw dev mon0 info | grep type
>         type monitor
> ```
> Tiene además la ventaja de conservar `wlan0` como interfaz gestionada — ver [[05 - Modos de operación y modo monitor]].

# El ataque básico

```shell-session
$ sudo reaver -i mon0 -b AE:EB:B0:11:A0:1E -c 1 -v

Reaver v1.6.6 WiFi Protected Setup Attack Tool
[+] Waiting for beacon from AE:EB:B0:11:A0:1E
[+] Received beacon from AE:EB:B0:11:A0:1E
[+] Associated with AE:EB:B0:11:A0:1E (ESSID: HackMe)
[+] Trying pin "12345670"
[+] 90.91% complete @ 2026-08-01 11:32:33 (1 seconds/pin)
[+] WPS PIN: '96457896'
[+] WPA PSK: 'Contrasena-de-la-red'
[+] AP SSID: 'HackMe'
```

| Opción | Función |
| ------ | ------- |
| `-i` | Interfaz en modo monitor |
| `-b` | BSSID del objetivo |
| `-c` | Canal — evita que reaver tenga que buscarlo |
| `-v` / `-vv` | Verbosidad: muestra cada PIN probado |
| `-p` | Probar un PIN concreto, o fijar la primera mitad |
| `-d` | Retardo entre intentos |
| `-l` | Tiempo de espera cuando el AP bloquea |
| `-r x:y` | Dormir `y` segundos cada `x` intentos |
| `-L` | Ignorar el estado de bloqueo que reporte el AP |
| `-K` / `-Z` | Ataque Pixie Dust |
| `-O` | Volcar las tramas relevantes a un `.pcap` |
| `--max-attempts=N` | Detenerse tras `N` intentos |

<mark style="background: #FFB8EBA6;">El porcentaje de progreso engaña</mark>: reaver lo calcula sobre el espacio total, pero al encontrar la primera mitad el trabajo restante se desploma. Un 90 % puede significar que quedan minutos o que quedan tres horas, según en qué fase esté.

# Reanudar con media mitad conocida

Si la primera mitad ya se conoce —de una sesión previa, de un generador de PIN o de la etiqueta del AP—, `-p` con cuatro dígitos ahorra el 90 % del trabajo:

```shell-session
$ sudo reaver -i mon0 -b B2:A5:1D:E1:B2:11 -c 1 -p 1234
```

Quedan como mucho 1.000 candidatos, es decir, minutos en lugar de horas. Reaver además **guarda la sesión** en `/var/lib/reaver/` o `/etc/reaver/`, así que un ataque interrumpido se reanuda solo al relanzarlo contra el mismo BSSID. Conviene saberlo por dos razones: no hay que empezar de cero tras un corte, y <mark style="background: #FF5582A6;">un fichero de sesión viejo puede hacer que reaver reanude en un punto equivocado</mark> si el AP se ha reconfigurado. Para forzar el reinicio, borrar el `.wpc` correspondiente.

# El PIN nulo

Algunos APs entregan la `WPA-PSK` sin comprobar nada cuando reciben un PIN vacío. Es un fallo de implementación, no del protocolo, y merece ser lo primero que se prueba porque cuesta un solo intento:

```shell-session
$ sudo reaver -i mon0 -b 5A:1A:59:B7:E7:97 -c 1 -p ""

[+] Associated with 5A:1A:59:B7:E7:97 (ESSID: Teddy)
[+] WPS PIN: ''
[+] WPA PSK: 'Contrasena-de-la-red'
[+] AP SSID: 'Teddy'
```

Si `-p ""` no es aceptado por el intérprete, `-p " "` con un espacio funciona igual.

# Verificar un PIN conocido

Cuando el PIN se obtiene por otra vía —Pixie Dust, un generador o la etiqueta física del router— reaver lo canjea por la contraseña en un intercambio:

```shell-session
$ sudo reaver -i mon0 -b 60:38:E0:2A:4F:21 -c 1 -p 88766197

[+] Pin cracked in 5 seconds
[+] WPS PIN: '88766197'
[+] WPA PSK: 'WPS-Attacks'
[+] AP SSID: 'HTB-Wireless'
```

<mark style="background: #8000E1A6;">Para que el PIN de la etiqueta funcione, el AP tiene que estar en modo `LAB`</mark> — es lo que indica que el PIN activo es el de fábrica y no uno regenerado. Se comprueba en el reconocimiento, [[02 - Reconocimiento de WPS]].

# El coste real del ataque

| Escenario | Intentos | Tiempo aproximado |
| --------- | -------- | ----------------- |
| PIN nulo vulnerable | 1 | Segundos |
| PIN por defecto acertado | 1–50 | Minutos |
| Primera mitad conocida | ≤ 1.000 | 20 min – 1 h |
| Fuerza bruta completa, sin bloqueo | ≤ 11.000 | 3 – 10 h |
| AP con bloqueo agresivo | — | Inviable por esta vía |

A 1–3 PIN por segundo en el mejor caso, y bastante menos en la práctica por retransmisiones y reasociaciones. <mark style="background: #FFB86CA6;">Ese es el motivo por el que este ataque es hoy la última opción y no la primera</mark>: Pixie Dust resuelve en segundos lo que aquí cuesta horas, y los PINs por defecto cubren buena parte del resto.

> [!important]+ El orden correcto
> 1. **PIN nulo** — un intento.
> 2. **Pixie Dust** — un intercambio, ver [[08 - Ejecución del ataque Pixie Dust]].
> 3. **PINs por defecto del fabricante** — decenas de intentos, ver [[05 - PINs por defecto y bases de datos]].
> 4. **Fuerza bruta completa** — sólo si nada de lo anterior funciona y el AP no bloquea.
>
> Ir directo al punto 4 es lo que enseña el material clásico y es la peor decisión: horas de tráfico contra el AP, riesgo alto de bloquearlo para el resto del engagement y ruido garantizado en el WIDS.

# Estado de las herramientas

`reaver` en el fork de [t6x](https://github.com/t6x/reaver-wps-fork-t6x) sigue siendo el estándar: la última **release** etiquetada es la **v1.6.6, de marzo de 2020**, pero la rama principal recibe correcciones —último movimiento en octubre de 2025—. <mark style="background: #FFB8EBA6;">La versión empaquetada en las distribuciones es la 1.6.6</mark>; compilar desde `master` merece la pena si se topa con un AP problemático.

`bully` es la alternativa histórica, pero su repositorio ([aanarchyy/bully](https://github.com/aanarchyy/bully)) no recibe cambios desde octubre de 2023. Sigue funcionando y a veces tiene éxito donde reaver falla, sobre todo con temporizaciones agresivas — ver [[01 - Bully]].

Qué hacer cuando el AP se defiende es [[04 - APs con bloqueo y rate limiting]].
