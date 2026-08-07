---
tags:
  - Wi-Fi/WPA
  - Pentesting/Explotacion
Descripción: "Las tres fuentes de material crackeable —handshake completo, PMKID y medio handshake— y cómo obtener cada una con la cadena moderna en vez de deauth a ciegas"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Metodología del cracking de PSK]]"
Nota siguiente: "[[02 - El formato 22000 y los message pairs]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

Hay <mark style="background: #ADCCFFA6;">tres artefactos distintos que sirven para atacar una PSK offline</mark>, y sólo uno de ellos —el que enseñan todos los tutoriales— depende de desautenticar a alguien. Elegir mal cuesta horas de espera contra una red que nunca iba a soltar nada.

| Artefacto | Qué hace falta | Ventaja | Límite |
| --------- | -------------- | ------- | ------ |
| **4-way handshake** (M1..M4) | Un cliente que se asocie | Confirma que el AP acepta esa PSK | Necesita cliente y, sin PMF, una deauth |
| **PMKID** | Sólo el AP | **No requiere cliente ni deauth** | El AP debe incluirlo en M1 |
| **Medio handshake** (M1+M2) | Un AP falso y un cliente | Funciona sin acceso al AP real | Prueba lo que el cliente cree, no lo que el AP acepta |

# La vía clásica y su techo

El flujo de `aircrack-ng` sigue siendo el denominador común: [[02 - Airodump-ng|`airodump-ng`]] fija canal y BSSID y escribe la captura, [[04 - Aireplay-ng|`aireplay-ng`]] desautentica y el cliente se reasocia.

```shell-session
$ sudo airodump-ng wlan0mon -c 6 --bssid 80:2D:BF:FE:13:83 -w captura
$ sudo aireplay-ng -0 3 -a 80:2D:BF:FE:13:83 -c 8A:00:A9:9B:ED:1A wlan0mon
```

Dos matices que casi nunca se dicen:

- **La deauth dirigida (`-c`) es mucho mejor que la de difusión.** La de difusión molesta a toda la celda —incluidos dispositivos fuera del alcance del engagement— y muchos clientes la ignoran. Tres tramas dirigidas bastan; sesenta son ruido para el WIDS.
- **`airodump-ng` escribe «WPA handshake» con criterio laxo.** Que aparezca la cabecera no significa que haya un par utilizable. La verificación real la hace `hcxpcapngtool` al convertir — ver [[02 - El formato 22000 y los message pairs]].

> [!warning]+ Con PMF activo esta vía está muerta
> Si el `RSN IE` anuncia `MFPR=1`, la trama de desautenticación forjada se descarta sin efecto y se queda uno mirando la terminal. <mark style="background: #FF5582A6;">Comprobar `PMF` **antes** de desautenticar</mark> es la diferencia entre veinte segundos y una hora perdida. En Wireshark: `wlan.rsn.capabilities.mfpr`.

# PMKID: el atajo sin cliente

Desde el [hallazgo de `atom` en 2018](https://hashcat.net/forum/thread-7717.html), muchos AP incluyen el **PMKID** en el campo *Key Data* del primer mensaje del handshake. Basta con **asociarse** —cosa que se puede hacer sin conocer la contraseña— para que el AP lo entregue.

Su derivación (`PMKID = Truncate-128(HMAC(PMK, "PMK Name" || AA || SPA))`, detallada en [[03 - RSN, WPA2 y el 4-way handshake]]) depende del PMK, así que se craquea exactamente igual que un handshake.

<mark style="background: #8000E1A6;">Esto convierte un ataque que necesitaba víctima en uno que sólo necesita al AP</mark>: sirve de madrugada, con la oficina vacía, y no genera desconexiones que el cliente note.

No todos los AP son vulnerables: los que no cachean PMK (roaming deshabilitado) no envían PMKID, y varios fabricantes lo desactivaron tras 2018. Es lo primero que se prueba, no lo único.

# La cadena moderna: `hcxdumptool`

`hcxdumptool` sustituye a `airodump-ng` + `aireplay-ng` en la fase de captura: solicita PMKID, provoca handshakes y escribe directamente en `pcapng`.

```shell-session
$ sudo hcxdumptool -i wlan0 -c 6a --bpf=alcance.bpf -w captura.pcapng
```

Detalles de la versión 7.x que rompen los tutoriales antiguos:

- **`-c` exige letra de banda**: `6a` es el canal 6 de 2,4 GHz, `36b` el 36 de 5 GHz, `37c` el de 6 GHz. Un `-c 6` a secas se ignora en silencio. Por defecto recorre `1a,6a,11a`.
- **Gestiona la interfaz él mismo**: no hace falta `airmon-ng`; cambia modo, canal y MAC virtual por su cuenta. Pasarle una interfaz `wlan0mon` creada a mano sobra.
- **Las viejas `--enable_status`, `--filterlist_ap` y `--filtermode` ya no existen.** El filtrado de captura se hace **sólo** con un BPF compilado (`--bpf`). Cuidado con `--essidlist`: pese al nombre, **no filtra** — inicializa la lista de ESSID que la herramienta *transmite* en sus `PROBERESPONSE`.
- **`--exitoneapol`** termina al conseguir el material, ideal para dejarlo desatendido.

## El filtro BPF es control de alcance, no una optimización

```shell-session
$ hcxdumptool --bpfc="wlan addr3 802dbffe1383 || wlan addr3 802dbffe1384" > alcance.bpf
$ sudo hcxdumptool -i wlan0 --bpf=alcance.bpf -w captura.pcapng
```

<mark style="background: #FF5582A6;">Compilar el alcance autorizado en un BPF y capturar sólo eso es la forma técnica de demostrar que no se tocó lo que no se debía</mark>. En un edificio compartido, una captura sin filtrar contiene tráfico de terceros ajenos al contrato — un problema legal y de RGPD, no un descuido. Es la evidencia que respalda el apartado de alcance del informe.

# Medio handshake desde un AP falso

Si no se alcanza al AP real pero sí a sus clientes, se levanta un AP con el mismo SSID y una contraseña cualquiera. El cliente intenta asociarse, calcula el PTK con **su** PSK y firma M2. Ese par M1+M2 es crackeable.

```config
interface=wlan1
ssid=CorpWiFi
channel=6
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=noimportacual
```

`hostapd` avisa con `AP-STA-POSSIBLE-PSK-MISMATCH` cuando el MIC de M2 no cuadra con su contraseña — que es justo la señal de éxito.

> [!important]+ Un medio handshake prueba al cliente, no a la red
> El MIC de M2 demuestra que **el cliente** conoce ese PMK. Si el usuario tenía la contraseña mal guardada, o si el dispositivo es de otra red homónima, se craquea una passphrase que la red real rechaza. Por eso el paso de verificación es obligatorio y por eso `hcxtools` etiqueta estos pares como *challenge*.

Esta misma técnica es la base del downgrade contra [[05 - WPA3 en modo transición y downgrade|WPA3 en modo transición]], donde el AP falso ofrece WPA2 a un cliente que hablaría SAE.

# Capturar sin provocar nada

La opción más limpia es esperar. Los clientes se reasocian solos con más frecuencia de la que parece: al salir y volver del ahorro de energía, al hacer roaming entre APs de un mismo ESS, al despertar el portátil, y en masa a primera hora de la mañana.

| Momento | Por qué sirve |
| ------- | ------------- |
| Inicio de jornada | Decenas de asociaciones en pocos minutos |
| Vuelta de la pausa | Reasociación masiva al mismo AP |
| Roaming entre plantas | Un ESS con varios BSSID genera handshakes continuamente |

<mark style="background: #FFB8EBA6;">Una captura pasiva de una hora en el momento correcto suele dar más que una tarde de deauths</mark>, y no aparece en ningún panel de WIDS. El coste es tiempo de ventana, que es precisamente lo que se negocia en el alcance cuando la prueba es 24/7.

# Verificar antes de crackear

Antes de encender la GPU conviene saber qué hay realmente en el fichero:

```shell-session
$ hcxpcapngtool -o hash.hc22000 captura.pcapng
$ hcxhashtool -i hash.hc22000 --essid=CorpWiFi --info=stdout
```

`hcxpcapngtool` imprime cuántos M1/M2/M3/M4 vio, cuántos pares formó y de qué tipo. `hcxhashtool` filtra por ESSID o BSSID cuando la captura mezcla varias redes — necesario para no crackear por error material fuera de alcance. La lectura de esa salida es el contenido de [[02 - El formato 22000 y los message pairs]].
