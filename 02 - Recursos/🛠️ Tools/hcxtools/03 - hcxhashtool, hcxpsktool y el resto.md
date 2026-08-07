---
tags:
  - Wi-Fi
  - Seguridad/Contraseñas
  - Tipo/Arsenal
Descripción: "Filtrar el fichero de hashes por alcance y calidad, generar candidatas desde el propio hash y verificar una PSK sin conectarse a la red"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - hcxpcapngtool]]"
Nota siguiente: 
Area: "[[hcxtools.base|hcxtools]]"
---
---

Tras la conversión quedan tres tareas que deciden el rendimiento del ataque: **acotar** lo que se va a crackear, **generar** candidatas baratas y **verificar** el resultado. Un binario para cada una.

# `hcxhashtool`: filtrar por alcance y por calidad

```shell-session
$ hcxhashtool -i todo.hc22000 --essid=CorpWiFi -o objetivo.hc22000
$ hcxhashtool -i todo.hc22000 --info=stdout          # inventario sin escribir nada
```

## Filtros de alcance

| Opción | Selecciona |
| ------ | ---------- |
| `--essid`, `--essid-part`, `--essid-regex` | Por nombre de red, exacto, parcial o por expresión regular |
| `--essid-list`, `--essid-min`, `--essid-max` | Por lista o por longitud del nombre |
| `--mac-ap`, `--mac-client` | Por dirección concreta |
| `--mac-list`, `--mac-skiplist` | Lista blanca o negra de direcciones |
| `--oui-ap`, `--oui-client` | Por prefijo de fabricante |
| `--vendor`, `--info-vendor-ap` | Por nombre de fabricante, o mostrarlo |

<mark style="background: #FFB86CA6;">`--mac-skiplist` es el complemento del filtro BPF de la captura</mark>: si a pesar de todo entró material de una red ajena, esta es la forma de excluirlo antes de procesar nada. Junto con `--essid`, cierra el argumento de alcance en el informe.

## Filtros de calidad

Estos mapean directamente sobre el byte de *message pair* explicado en [[02 - El formato 22000 y los message pairs]]:

| Opción | Selecciona |
| ------ | ---------- |
| `--authorized` | Pares `M2M3`, `M3M4`, `M1M4`: **el AP validó la contraseña** |
| `--challenge` | Pares `M1M2` y `M1M2ROGUE`: sin confirmar |
| `--apless` | Sólo `M1M2ROGUE`, los obtenidos con AP falso |
| `--rc` / `--rc-not` | Con o sin replaycount verificado (el bit `0x80`) |
| `--type` | `1` = PMKID, `2` = EAPOL |

```shell-session
$ hcxhashtool -i alcance.hc22000 --authorized --rc -o prioritario.hc22000
```

<mark style="background: #8000E1A6;">Ese comando deja el subconjunto que merece la GPU primero</mark>: material confirmado por el AP y sin correcciones de nonce. Lo demás se ataca después, sabiendo que su resultado exige verificación.

## Conversión a otros formatos

| Opción | Salida |
| ------ | ------ |
| `--john` | Formato de John the Ripper |
| `--hccapx-out`, `--hccap-out` | Formatos heredados, para herramientas antiguas |
| `--pmk`, `--psk` | Trabajar con PMK o PSK conocidos |

# `hcxpsktool`: candidatas desde el propio hash

Lee el fichero de hashes, extrae ESSID y MAC, y genera las candidatas que corresponden a los patrones de fábrica de cada familia de routers. **No hace falta ninguna wordlist externa.**

```shell-session
$ hcxpsktool -c hash.hc22000 --maconly | sort -u > cand.txt
$ hcxpsktool -c hash.hc22000 --netgear --weakpass | sort -u > cand.txt
```

| Opción | Familia | Tamaño de la lista |
| ------ | ------- | ------------------ |
| `--maconly` | Sólo lo derivado de la MAC del AP | Muy pequeña |
| `--netgear` | NETGEAR, ORBI, NTGR_VMB, ARLO_VMB, FoxtelHub | — |
| `--spectrum` | MySpectrumWiFi, SpectrumSetup, MyCharterWiFi | > 3,3 GB |
| `--digit10` | INFINITUM, ALHN, INEA, VodafoneNet, VIVACOM | > 1 GB |
| `--phome` | PEGATRON / Vantiva (CBCI, HOME, SPSETUP) | > 2,9 GB |
| `--alticeoptimum` | MyAltice, MyOptimum | > 6,3 GB |
| `--ee` / `--eeupper` | EE, BrightBox, EE-Hub | > 1,4 / 4,0 GB |
| `--tenda`, `--asus` | Tenda/NOVA/BrosTrend, ASUS RT-AC | — |
| `--wpskeys` | Claves WPS completas | — |
| `--weakpass`, `--simple` | Débiles genéricas y patrones simples | — |
| `--eudate` / `--usdate` | Fechas completas europeas / americanas | — |
| `--egn` | Números de identidad búlgaros | — |

<mark style="background: #ADCCFFA6;">`--maconly` es el arranque más barato que existe</mark>: unos miles de candidatas derivadas del BSSID que resuelven un porcentaje real de routers domésticos en menos de un segundo. Se lanza **antes** que cualquier diccionario.

Los tamaños documentados importan: `--alticeoptimum` genera más de 6 GB, así que conviene canalizar a `hashcat` en vez de escribir a disco.

```shell-session
$ hcxpsktool -c hash.hc22000 --netgear | hashcat -m 22000 hash.hc22000
```

Esta herramienta sustituye a la colección de generadores sueltos de GitHub que circulan por los cursos —varios de ellos abandonados desde 2016-2017, y dos **desaparecidos**— como se detalla en [[06 - Credenciales por defecto y keyspaces de fabricante]].

# `hcxeiutool`: wordlists desde el ESSID

Toma la lista de ESSID que produce `hcxpcapngtool -E` y deriva las variantes que la gente construye con el nombre de su red:

```shell-session
$ hcxeiutool -i essids -d digitos -x hexadecimal -c letras -s separados
```

| Salida | Contiene |
| ------ | -------- |
| `-d` | Sólo los dígitos de cada ESSID |
| `-x` | Los caracteres hexadecimales |
| `-c` | Sólo `A-Za-z`, el resto eliminado |
| `-s` | Igual, partiendo por separadores. **La recomendada para aplicar reglas** |

El flujo que documenta la propia herramienta combina las salidas y las multiplica con reglas de hashcat:

```shell-session
$ cat essids digitos hexadecimal letras separados > tmp.txt
$ hashcat --stdout -r best64.rule letras    >> tmp.txt
$ hashcat --stdout -r best64.rule separados >> tmp.txt
$ sort -u tmp.txt > dirigida.txt
```

# `hcxpmktool`: verificar sin conectarse

Confirma si una PSK o un PMK corresponden a un hash concreto. Es el cierre correcto del paso de verificación, sin asociarse a la red del cliente:

```shell-session
$ hcxpmktool -l "$(head -1 hash.hc22000)" -p 'CandidataRecuperada'   # -l espera UNA línea
$ echo $?
```

| Código de salida | Significado |
| ---------------- | ----------- |
| `0` | PSK/PMK confirmados |
| `1` | Error |
| `2` | No confirmados |

Acepta también `-e <ESSID>` y `-p -` para leer de entrada estándar, aunque su propia ayuda advierte de que sólo sirve para **listas pequeñas**: no es un crackeador.

> [!warning]+ No aplica correcciones de nonce
> La ayuda lo dice explícitamente: *"does not do NONCE ERROR CORRECTIONS; in case of a packet loss, you get a wrong PTK"*. <mark style="background: #FF5582A6;">Contra un hash marcado con el bit `0x80` puede devolver un negativo falso</mark> aunque la contraseña sea correcta. En ese caso hay que verificar con `hashcat --nonce-error-corrections` o asociándose de verdad.

# El resto de binarios

| Binario | Uso |
| ------- | --- |
| `whoismac` | Fabricante de una MAC, incluidos los registros MA-M y MA-S |
| `hcxhash2cap` | Reconstruye un `pcapng` desde un hash — útil para compartir evidencia mínima |
| `hcxwltool` | Manipulación y limpieza de wordlists |
| `hcxpottool` | Procesa ficheros *potfile* de hashcat |
| `wlancap2wpasec` | Sube capturas al servicio comunitario `wpa-sec.stanev.org` |

El último requiere una advertencia: <mark style="background: #FF5582A6;">subir la captura de un cliente a un servicio público es exfiltrar material de autenticación suyo</mark>. Nunca en un engagement, por muy cómodo que resulte.
