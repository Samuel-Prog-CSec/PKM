---
tags:
  - Wi-Fi
  - Seguridad/Contraseñas
Descripción: "El conversor a formato 22000 y, sobre todo, el informe que dice qué calidad tiene la captura antes de gastar una hora de GPU"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - hcxdumptool]]"
Nota siguiente: "[[03 - hcxhashtool, hcxpsktool y el resto]]"
Area: "[[hcxtools.base|hcxtools]]"
---
---

Convertir es lo de menos. <mark style="background: #ADCCFFA6;">El valor real de `hcxpcapngtool` está en su informe</mark>: dice cuántos pares utilizables hay, de qué mensajes salen y si el AP llegó a confirmar la contraseña — información que `airodump-ng` no da y que decide si merece la pena crackear.

```shell-session
$ hcxpcapngtool -o hash.hc22000 captura.pcapng
```

# Salidas

| Opción | Produce |
| ------ | ------- |
| `-o <fichero>` | Hashes en formato **22000** (PMKID + EAPOL). El habitual |
| `-f <fichero>` | Formato `37100` — modo aún **no implementado en hashcat** |
| `-E <fichero>` | Wordlist con todos los ESSID vistos |
| `-R <fichero>` | Wordlist sólo de *probe requests* — la **PNL** de los clientes |
| `-I <fichero>` | Lista de identidades EAP |
| `-U <fichero>` | Lista de usuarios EAP |
| `-D <fichero>` | Información de dispositivo: `MAC MANUFACTURER MODELNAME SERIALNUMBER DEVICENAME UUID ESSID` |

```shell-session
$ hcxpcapngtool -o hash.hc22000 -E essids -R probes -I identidades -D dispositivos captura.pcapng
```

<mark style="background: #FFB86CA6;">`-D` y `-R` son las dos opciones infrautilizadas de toda la suite</mark>. La primera saca fabricante, modelo y nombre de dispositivo en claro de las tramas WPS y de asociación; la segunda, los nombres de red que los clientes buscan. Ambas alimentan wordlists dirigidas —ver [[05 - Wordlists dirigidas a redes Wi-Fi]]— y la segunda identifica objetivos para [[07 - Karma y MANA]].

`-I` y `-U` son el equivalente para redes corporativas: extraen las identidades 802.1X que viajan en claro antes del túnel TLS, tal y como se explota en [[08 - Cracking de identidades WPA-Enterprise]].

# Leer el informe

```text
EAPOL M1 messages (total)................: 1
EAPOL M2 messages (total)................: 1
EAPOL M3 messages (total)................: 1
EAPOL M4 messages (total)................: 1
EAPOL M4 messages (zeroed NONCE).........: 1
EAPOL pairs (total)......................: 2
EAPOL pairs (best).......................: 1
EAPOL pairs written to 22000 hash file...: 1 (RC checked)
EAPOL M32E2 (authorized - ANONCE from M3): 1
REPLAYCOUNT gap (measured maximum).......: 0
```

Las líneas que hay que mirar, por orden:

| Línea | Qué decide |
| ----- | ---------- |
| `EAPOL pairs written` | Si es `0`, **no hay nada que crackear** por muchos M1 sueltos que aparezcan |
| `M32E2 (authorized)` vs `M12E2 (challenge)` | El primero está confirmado por el AP; el segundo hay que verificarlo |
| `REPLAYCOUNT gap` | Si es `> 0`, harán falta correcciones de nonce y el ataque se encarece |
| `PMKID` | Si aparece, se puede crackear sin haber tocado a ningún cliente |
| `M4 messages (zeroed NONCE)` | Normal: el estándar lo exige. Inutiliza algunos tipos de par |

<mark style="background: #8000E1A6;">La distinción *challenge* frente a *authorized* es la que más veces se pasa por alto</mark>. Un par `challenge` (M1+M2) demuestra que **el cliente** conoce esa contraseña, no que la red la acepte: si el usuario la tenía mal guardada, se craquea una passphrase inservible. El desglose completo del byte de *message pair* está en [[02 - El formato 22000 y los message pairs]].

# Correcciones de nonce

Cuando el informe reporta un hueco en los contadores de repetición, la herramienta lo marca en el hash con el bit `0x80` y sugiere un valor:

```text
REPLAYCOUNT gap (suggested NC)...........: 11
```

```shell-session
$ hashcat -m 22000 --nonce-error-corrections=11 hash.hc22000 wordlist.txt
```

Cada unidad multiplica el trabajo, porque hashcat prueba variaciones de los últimos bytes del nonce por cada candidata. <mark style="background: #FFB8EBA6;">Un hash con `NC` alto puede tardar un orden de magnitud más</mark>, así que casi siempre compensa volver a capturar en mejores condiciones antes que forzar la GPU.

La documentación insiste en un punto: **las herramientas no aplican correcciones de nonce por su cuenta**; si se perdieron tramas, el PTK derivado será incorrecto y hay que compensarlo en el crackeador.

# Avisos frecuentes

| Aviso | Significado |
| ----- | ----------- |
| `missing frames!` | La captura se filtró o se limpió; falta contexto |
| `does not contain undirected proberequest frames` | Sin *probes* no dirigidas: menos información sobre la red |
| `very basic format without any additional information` | La captura es `.cap` antiguo, no `pcapng` |

El tercero explica por qué conviene capturar directamente en `pcapng` con [[01 - hcxdumptool]]: el formato `.cap` de `airodump-ng` pierde metadatos —potencia, marcas de tiempo precisas, información de interfaz— que la suite usa para el diagnóstico.

# Conversión desde capturas antiguas

`hcxpcapngtool` acepta `.cap`, `.pcap` y `.pcapng`, comprimidos con gzip incluidos. Eso permite reprocesar material antiguo con la versión actual, que detecta pares que las versiones 6.x no formaban:

```shell-session
$ hcxpcapngtool -o hash.hc22000 *.cap
$ hcxpcapngtool -o hash.hc22000 antigua.pcapng.gz
```

Procesar un lote entero es lo habitual al cerrar un engagement: se convierten todas las capturas de la semana de una vez y después se filtran por red con [[03 - hcxhashtool, hcxpsktool y el resto|`hcxhashtool`]].
