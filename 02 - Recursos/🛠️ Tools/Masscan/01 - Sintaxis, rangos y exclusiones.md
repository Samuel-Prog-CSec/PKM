---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Cómo se le dice a masscan qué escanear y —más importante en un engagement real— qué NO tocar"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a masscan y el escaneo stateless]]"
Nota siguiente: "[[02 - Rendimiento - rate, adaptador y transmisión]]"
Area: "[[Masscan.base|Masscan]]"
---
---

La interfaz de masscan imita a la de Nmap lo justo para confundir. Esta nota fija la sintaxis real y, sobre todo, el mecanismo de **exclusión**, que en un pentest con *scope* firmado no es una comodidad sino la barrera que evita escanear a un tercero.

# Invocación mínima

```shell-session
$ sudo masscan 10.129.0.0/16 -p80,443
```

Hace falta `root` (o `CAP_NET_RAW`+`CAP_NET_ADMIN` vía `setcap`) porque construye la trama Ethernet completa. <mark style="background: #FFB8EBA6;">Sin `-p` no escanea nada</mark>: a diferencia de Nmap, masscan no tiene lista de puertos por defecto.

## Objetivos

Solo tres formas, y **ninguna admite nombres DNS**:

| Forma | Ejemplo |
| --- | --- |
| IP suelta | `192.168.1.10` |
| Rango | `10.0.0.1-10.0.0.100` |
| CIDR (IPv4 e IPv6) | `10.0.0.0/8`, `2603:3001:2d00:da00::/112` |

Se pueden encadenar varios en la misma línea, o pasarlos con `--range`:

```shell-session
$ sudo masscan --range 10.0.0.0/8,192.168.0.0/16 -p22,80,443,3389
```

La notación con comodines de Nmap (`10.0.0.*`, `192.168.[1-3].0/24`) **no funciona**.

## Puertos

```shell-session
$ sudo masscan 10.10.0.0/16 -p80,8000-8100        # TCP
$ sudo masscan 10.10.0.0/16 -pU:161,U:500         # UDP (prefijo U:)
$ sudo masscan 10.10.0.0/16 -p0-65535             # todos
$ sudo masscan 10.10.0.0/16 --top-ports 100       # los N más comunes
```

`--top-ports` añade los puertos TCP/UDP más frecuentes; es el equivalente rápido al `--top-ports` de Nmap y el punto de partida sensato cuando el rango es grande y el tiempo, corto.

> [!warning]+ `-p0-65535` sobre un `/16` son 4.300 millones de sondas
> El producto `hosts × puertos` crece muy rápido y es lo que fija la duración real del escaneo, no el tamaño del rango. Un `/16` completo a 100.000 pps son unas **12 horas**. Calcula antes de lanzar: `hosts × puertos ÷ rate = segundos`.

# Exclusiones: la parte que de verdad importa

<mark style="background: #FF5582A6;">En un engagement, un rango mal tecleado no es un error técnico sino un incidente legal</mark>. masscan tiene dos mecanismos y la exclusión **siempre gana** sobre la inclusión, aunque el objetivo aparezca explícitamente en la línea de comandos:

```shell-session
$ sudo masscan 0.0.0.0/0 -p443 --excludefile exclude.txt --max-rate 100000 -oX scan.xml
$ sudo masscan 10.0.0.0/8 -p80 --exclude 10.0.5.0/24
```

El fichero de exclusión usa **la misma sintaxis que los objetivos**, una entrada por línea:

```text
# infraestructura del cliente fuera de scope
10.0.5.0/24
10.0.9.17
192.168.100.1-192.168.100.50
```

> [!important]+ Convierte el scope en un fichero, no en un flag
> La práctica profesional es mantener `scope.txt` y `exclude.txt` como artefactos del engagement —versionados junto a las notas— y **no volver a teclear rangos nunca**. Es también lo que enseñas en el informe para demostrar que respetaste el alcance ([[Documentación y reporting.base|documentación y reporting]]). masscan aplica las exclusiones **después** de resolver los objetivos y aborta si no queda nada, con un aviso explícito (`all addresses were removed by exclusion ranges`); no da ninguna señal equivalente si el fichero simplemente no aporta lo que esperabas, así que **verifica siempre con `--echo` antes de subir el rate**.

## Ensayo en seco

Antes de mandar un solo paquete conviene ver **qué** se va a escanear y **en qué orden**:

```shell-session
$ masscan 10.0.0.0/24 -p80 -sL | head          # lista los objetivos, no escanea
$ masscan 10.0.0.0/24 -p80 --echo > scan.conf  # vuelca la configuración resuelta
```

`-sL` genera la lista ya aleatorizada por BlackRock (ver [[00 - Introducción a masscan y el escaneo stateless]]) sin transmitir nada. `--echo` imprime la configuración completa tal y como masscan la ha interpretado — es la forma fiable de comprobar que tus exclusiones se han cargado y que el rango es el que crees.

# Ficheros de configuración

Todo flag de la línea de comandos tiene equivalente en un `.conf`, y es como se lanzan los escaneos serios:

```text
# scan.conf
range = 10.0.0.0/8
ports = 80,443,8080,8443
excludefile = exclude.txt
rate = 50000
output-format = json
output-filename = resultado.json
```

```shell-session
$ sudo masscan -c scan.conf
```

Un `.conf` es reproducible, revisable por un compañero antes de ejecutarlo y adjuntable al informe. <mark style="background: #8000E1A6;">Es la diferencia entre "lancé un escaneo" y "ejecuté *este* escaneo, aquí está la definición exacta"</mark>.

# Pausar y reanudar

masscan captura `Ctrl+C`, guarda el estado en **`paused.conf`** y espera (por defecto 10 s, ajustable con `--wait`) a que lleguen las respuestas en vuelo antes de salir:

```shell-session
$ sudo masscan -c scan.conf
^C
waiting 10 seconds to exit...
saving resume file to: paused.conf

$ sudo masscan --resume paused.conf
```

Como el recorrido es un índice cifrado y no una lista, reanudar es literalmente **retomar el contador**: `--resume-index` y `--resume-count` permiten incluso trocear a mano un escaneo largo en ventanas de tiempo, algo que se aprovecha para el *low-and-slow* de [[05 - Evasión de firewalls e IDS con masscan]].

# Flags de comportamiento que conviene conocer

| Flag | Qué hace |
| --- | --- |
| `--ping` | Añade sondas ICMP echo al escaneo TCP/UDP. |
| `--open-only` | Solo reporta puertos abiertos (limpia la salida). |
| `--retries N` | Reenvía la sonda N veces con 1 s de separación. <mark style="background: #FFB8EBA6;">No hay reintentos por defecto</mark> — de ahí los falsos negativos. |
| `--wait N` | Segundos de escucha tras terminar de transmitir (por defecto **10**, fijado en `main.c`). |
| `--ttl N` | TTL de los paquetes salientes. **255 por defecto**: viene cableado en la plantilla de paquete (`templ-pkt.c`), y `--ttl` la sobrescribe. Es un valor delator — ver [[05 - Evasión de firewalls e IDS con masscan]]. |
| `--iflist` | Lista las interfaces que ve masscan, con su IP y router MAC. |
| `--offline` | Hace todo el trabajo **sin transmitir**: sirve para medir el ritmo máximo real de tu máquina. |

> [!success]+ El comando de arranque razonable
> ```shell-session
> $ sudo masscan -c scan.conf --retries 2 --open-only -oJ out.json
> ```
> `--retries 2` compra precisión a cambio del triple de paquetes y sigue siendo mucho más rápido que Nmap. Es el ajuste que evita el fallo clásico descrito en [[00 - Introducción a masscan y el escaneo stateless]].

> [!info]+ Fuente
> `doc/masscan.8` y `README.md` del [repositorio oficial](https://github.com/robertdavidgraham/masscan) — sintaxis de objetivos, precedencia de las exclusiones, `paused.conf` y comportamiento de `--wait`.
