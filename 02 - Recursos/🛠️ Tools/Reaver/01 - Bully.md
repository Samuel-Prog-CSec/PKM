---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "La reimplementación en C de reaver: qué hace distinto, cuándo funciona donde reaver falla y su estado de mantenimiento"
Fecha de actualización: 2026-08-01
Nota previa: "[[00 - Reaver y wash]]"
Nota siguiente: "[[02 - Pixiewps]]"
Area: "[[Reaver.base|Reaver]]"
---
---

<mark style="background: #ADCCFFA6;">`bully` es una reimplementación en C del ataque al PIN de WPS, escrita desde cero para corregir problemas de robustez y de rendimiento de reaver</mark>. Hace lo mismo y a menudo funciona en APs donde reaver se atasca, lo que lo convierte en la segunda opción obligada antes de dar un objetivo por perdido.

# Qué hace distinto

| Aspecto | Diferencia frente a reaver |
| ------- | -------------------------- |
| **Manejo de sockets** | Gestión propia en lugar de depender de `libpcap` para la inyección |
| **Detección de bloqueo** | Más agresiva: detecta antes el *rate limiting* y ajusta |
| **Tolerancia a errores** | Menos sensible a tramas malformadas y a `NACK` fuera de orden |
| **Consumo** | Menor huella de memoria. Pensado para sistemas empotrados |
| **Fuerza bruta del checksum** | Puede probar todos los dígitos finales en lugar de calcularlo |

Ese último punto importa: algunos firmwares **no validan el checksum** del PIN, y bully puede aprovecharlo donde reaver asume que el octavo dígito es determinista.

# Uso

```shell-session
$ sudo bully mon0 -b 60:38:E0:XX:XX:XX -c 1 -v 3

[!] Bully v1.4-00 - WPS vulnerability assessment utility
[+] Switching interface 'mon0' to channel 1
[!] Restored session from '/root/.bully/60ea8fXXXXXX.run'
[+] Got beacon for 'HTB-Wireless' (60:38:e0:xx:xx:xx)
[+] Trying pin '12345670'
[+] Rx( M5 ) = 'Pin1Bad'   Next pin '00005678'
```

| Opción | Función |
| ------ | ------- |
| `-b, --bssid` | BSSID del objetivo |
| `-c, --channel` | Canal |
| `-e, --essid` | ESSID |
| `-p, --pin` | PIN inicial o mitad conocida |
| `-d, --pixiewps` | Ataque Pixie Dust |
| `-v, --verbosity` | Nivel `1`–`4` |
| `-B, --bruteforce` | Fuerza bruta del checksum |
| `-F, --force` | Ignorar el bloqueo reportado |
| `-l, --lockwait=<s>` | Espera al detectar bloqueo |
| `-r, --pinrate=<n>` | Límite de PINs por minuto |
| `-S, --sequential` | Orden secuencial en lugar del orden estadístico por defecto |
| `-L, --lockignore` | No detenerse ante el bloqueo |

<mark style="background: #FFB8EBA6;">Por defecto bully **no** prueba los PINs en orden numérico</mark>: usa una lista ordenada por frecuencia observada en el mundo real, así que los primeros candidatos tienen bastante más probabilidad. `-S` fuerza el orden secuencial, útil sólo para reanudar un barrido sistemático.

La lectura de la salida es más informativa que la de reaver: `Rx( M5 ) = 'Pin1Bad'` indica exactamente en qué mensaje llegó el rechazo y qué mitad falló — <mark style="background: #8000E1A6;">confirmación directa de que la validación es en dos fases</mark>, ver [[01 - El protocolo de registro y la anatomía del PIN]].

# Pixie Dust

```shell-session
$ sudo bully mon0 -b 60:38:E0:XX:XX:XX -c 1 -d -v 3
```

`-d` invoca `pixiewps` internamente, igual que `-K` en reaver. El resultado es el mismo porque el motor es el mismo — ver [[02 - Pixiewps]].

# Sesiones

Guarda el progreso en `~/.bully/<bssid>.run`. Se restaura solo al relanzar; para empezar de cero hay que borrarlo:

```shell-session
$ rm ~/.bully/60ea8fXXXXXX.run
```

Igual que con reaver, un fichero de sesión obsoleto hace que se salte candidatos que ya no lo son.

# Estado del proyecto

> [!warning]+ Estancado desde 2023
> El repositorio de referencia, [aanarchyy/bully](https://github.com/aanarchyy/bully), **no recibe cambios desde octubre de 2023**. Sigue empaquetado en Kali y funciona, pero no hay que esperar correcciones para chipsets o drivers nuevos.
>
> <mark style="background: #FFB86CA6;">Su valor hoy es ser una **segunda implementación**</mark>: cuando reaver falla contra un AP concreto —por temporización, por manejo de `NACK` o por un firmware peculiar—, probar bully cuesta un minuto y resuelve una parte de los casos.

# Cuándo elegir cuál

| Situación | Herramienta |
| --------- | ----------- |
| Caso general | `reaver` |
| reaver falla al asociarse repetidamente | `bully` |
| Firmware que no valida el checksum | `bully -B` |
| Hace falta control fino del ritmo | `bully -r` |
| Sistema con poca memoria (Pi, OpenWrt) | `bully` |
| El driver no inyecta bien | Ninguno de los dos — [[03 - OneShot y el estado del arte]] |

En un engagement, el orden práctico es reaver primero por ser el más mantenido, y bully como comprobación antes de descartar el objetivo. Que fallen **los dos** contra un AP no bloqueado suele significar problema de señal o de driver, no de la herramienta — comprobarlo con `aireplay-ng --test`.
