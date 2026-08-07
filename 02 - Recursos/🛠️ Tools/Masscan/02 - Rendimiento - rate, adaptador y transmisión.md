---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Elegir el rate sin fundir la red del cliente, fijar la interfaz de salida y repartir el escaneo entre máquinas"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Sintaxis, rangos y exclusiones]]"
Nota siguiente: "[[03 - Salidas y pipeline hacia Nmap]]"
Area: "[[Masscan.base|Masscan]]"
---
---

masscan tiene un único mando de velocidad y es el que más daño hace mal puesto. Esta nota cubre cómo elegirlo con criterio, cómo fijar por dónde salen los paquetes y cómo repartir un escaneo grande entre varias máquinas sin duplicar trabajo.

# `--rate`: el único acelerador

```shell-session
$ sudo masscan 10.0.0.0/16 -p443 --rate 10000
```

<mark style="background: #ADCCFFA6;">`--rate` fija los paquetes por segundo que **transmite**, no las conexiones ni los hosts</mark>. Su valor por defecto es **100 pps** (`masscan->max_rate = 100.0` en `main.c`), deliberadamente conservador. `--max-rate` es un **alias exacto** del mismo parámetro, no un límite superior distinto — están declarados juntos en la tabla de configuración:

```c
{"rate", SET_rate, 0, {"max-rate",0}},
```

Es un detalle que confunde porque el propio README usa `--max-rate` en un ejemplo y la man page documenta `--rate`; son la misma cosa.

## Cuánto aguanta la máquina

Los techos que documenta el proyecto, y que conviene tomar como orden de magnitud y no como promesa:

| Plataforma | Techo |
| --- | --- |
| Windows, o Linux en VM | ~250.000–300.000 pps |
| Linux moderno, adaptador normal | ~1,6–2,5 millones pps |
| Linux + **PF_RING ZC** y NIC Intel 10 GbE | ~25 millones pps |

La discrepancia entre el README (1,6 M) y la man page (2,5 M) es del propio proyecto. Para saber lo que da **tu** máquina, mídelo sin transmitir:

```shell-session
$ masscan 0.0.0.0/0 -p80 --rate 100000000 --offline
```

`--offline` recorre y construye todos los paquetes pero no los envía: el ritmo que reporte es tu techo real de CPU. masscan detecta automáticamente los adaptadores PF_RING por el nombre (`zc:enp1s0`) y admite `--pfring` para forzarlo.

> [!warning]+ El techo que importa no es el tuyo
> <mark style="background: #FF5582A6;">El eslabón débil casi nunca es tu CPU: es el firewall, el router o el enlace del cliente</mark>. Un `--rate 1000000` desde un VPS de 10 Gbps contra una oficina con un enlace de 200 Mbps y un NGFW con tabla de sesiones limitada **tumba la red del cliente**, y eso es un incidente que se explica en una reunión, no en el informe. La aleatorización de BlackRock reparte la carga entre subredes distantes, pero no te salva de saturar el punto de entrada común.

## Elegir el rate con criterio

Reglas que funcionan en engagement real:

- **Empieza bajo y sube**: `--rate 1000`, mira el comportamiento, sube. Nunca al revés.
- **Ata el rate al enlace más estrecho del camino**, no al tuyo. Un paquete SYN con cabeceras Ethernet son ~60 bytes: `pps × 60 × 8` da los bits/s aproximados. 100.000 pps ≈ **48 Mbps**.
- **Redes internas del cliente**: 1.000–10.000 pps es agresivo pero civilizado. Por encima de eso, avisa al contacto técnico.
- **Objetivos en Internet propios / bug bounty**: consulta las reglas del programa. Muchos limitan explícitamente el ritmo de peticiones ([[01 - Reglas, legalidad y conducta]]).
- **Calcula la duración antes**: `hosts × puertos ÷ rate = segundos`. Si sale un número que no te cabe en la ventana de trabajo, recorta puertos, no subas el rate.

# Por dónde salen los paquetes

Como masscan trae [[00 - Introducción a masscan y el escaneo stateless|pila propia]], tiene que saber a mano cosas que el kernel resolvería solo:

| Flag | Alias | Para qué |
| --- | --- | --- |
| `-e` / `--adapter` | `--nic` | Interfaz de salida (`eth0`, `tun0`, `zc:enp1s0`). |
| `--adapter-ip` | `--source-ip`, `--source-address` | IP de origen que pone en los paquetes. |
| `--adapter-port` | `--source-port` | Puerto de origen. |
| `--adapter-mac` | `--source-mac` | MAC de origen. |
| `--router-mac` | — | MAC destino (el siguiente salto). |

Los alias `--source-*` **existen y funcionan** —están resueltos en la rama antigua de `masscan_set_parameter()`— aunque solo la forma `--adapter-*` aparezca en la tabla moderna de parámetros. Verlo en la fuente evita la duda cuando un blog usa una forma y la man page la otra.

```shell-session
$ masscan --iflist          # qué ve masscan: interfaces, IP y router MAC
```

Úsalo siempre antes de un escaneo en una red nueva: si masscan elige la interfaz equivocada (típico con VPN de por medio, `tun0` vs `eth0`), el escaneo sale por donde no debe o directamente no sale.

> [!important]+ `--adapter-ip` y `--adapter-port` aceptan **rangos**, y el tamaño debe ser potencia de 2
> Esa es la palanca de rotación de origen: en vez de una IP fija, masscan reparte los paquetes entre un bloque de direcciones o puertos propios. Requiere que esas direcciones sean tuyas y estén enrutadas hacia ti — no es *spoofing* gratuito. Su uso ofensivo (y sus límites) está en [[05 - Evasión de firewalls e IDS con masscan]].

# Repartir el escaneo: `--shards`

Un escaneo grande se parte entre N máquinas sin coordinación ni solapamiento:

```shell-session
# máquina 1 de 3
$ sudo masscan 10.0.0.0/8 -p443 --shard 1/3 --seed 20260804 --rate 50000
# máquina 2 de 3
$ sudo masscan 10.0.0.0/8 -p443 --shard 2/3 --seed 20260804 --rate 50000
# máquina 3 de 3
$ sudo masscan 10.0.0.0/8 -p443 --shard 3/3 --seed 20260804 --rate 50000
```

Cada instancia envía **uno de cada Y paquetes**, empezando en un desplazamiento distinto. <mark style="background: #8000E1A6;">La partición es correcta solo si todas comparten el mismo `--seed`</mark>: la permutación de BlackRock depende de la semilla, así que con semillas distintas cada nodo recorre un orden diferente y aparecen huecos y duplicados.

## `--seed`: reproducibilidad y variación

```shell-session
$ sudo masscan 10.0.0.0/16 -p80 --seed 1337     # orden reproducible
$ sudo masscan 10.0.0.0/16 -p80 --seed time     # orden distinto cada vez
```

Sirve para dos cosas opuestas y ambas útiles: <mark style="background: #FFB8EBA6;">fijar la semilla hace el escaneo repetible y auditable</mark> (mismo comando, mismo orden, comparas resultados entre pasadas), y cambiarla es lo que da valor a la **segunda pasada** contra falsos negativos — con otra semilla, las sondas caen en otro momento y sortean *rate-limiting* transitorio.

# Otros mandos de la transmisión

- **`--min-packet N`** — tamaño mínimo de paquete; rellena con *padding*. Altera la firma de tamaño característica del escáner.
- **`--wait N`** — segundos de escucha tras terminar de transmitir (por defecto 10). Con rates bajos y RTT altos, súbelo: cerrar demasiado pronto es una fuente silenciosa de resultados perdidos.
- **`--rotate <tiempo>`**, `--rotate-dir` — rota el fichero de salida cada X (`1hour`, `10min`). Imprescindible en escaneos de días para que un fallo no se lleve todo por delante (ver [[03 - Salidas y pipeline hacia Nmap]]).

> [!success]+ Perfil de arranque para una red interna de cliente
> ```shell-session
> $ sudo masscan -c scope.conf --rate 5000 --retries 2 --wait 20 \
>     -e tun0 --open-only -oJ fase1.json
> ```
> Ritmo civilizado, dos reintentos para no perder puertos, escucha holgada por si el RTT del túnel es malo, e interfaz fijada explícitamente para no escanear por la tarjeta equivocada.

> [!info]+ Fuentes
> - [Repositorio oficial de masscan](https://github.com/robertdavidgraham/masscan): `README.md` (techos de rendimiento, PF_RING, `--offline`), `doc/masscan.8` (`--shard`, `--seed`, `--rotate`).
> - Código fuente `src/main-conf.c` — tabla de parámetros que declara `max-rate` como alias de `rate` y los alias `--source-*`; `src/main.c` — `masscan->max_rate = 100.0` y `masscan->wait = 10`.
