---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
Descripción: "Elegir dispositivo y perfil de carga con criterio: qué mide realmente -w, cuándo -O recorta la contraseña y qué opciones se citan mal en los cursos"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - Máscaras y charsets personalizados]]"
Nota siguiente: "[[05 - Cracking en la nube y rigs]]"
Area: "[[Hashcat.base|Hashcat]]"
---
---

Ajustar hashcat es media docena de opciones, pero varias se explican mal de forma sistemática. <mark style="background: #ADCCFFA6;">La diferencia entre un rig bien configurado y uno mal configurado es un factor 2-3</mark>; la diferencia entre entender `-O` y no entenderlo puede ser dar por agotado un espacio que nunca se recorrió.

# Ver qué hay disponible

```shell-session
$ hashcat -I          # información de backends y dispositivos
$ hashcat -II         # versión extendida
$ hashcat -b -m 22000 # benchmark del modo concreto
$ hashcat --identify hash.txt   # qué modos encajan con ese hash
```

`-b` sobre el modo real es el dato que importa: los benchmarks genéricos de MD5 no dicen nada sobre PBKDF2. La diferencia no es de matiz — en una RTX 4090, `-m 1000` (NTLM) va a **288,5 GH/s** y `-m 22000` (WPA) a **2.533,3 kH/s**: unas 114.000 veces menos. Y `--identify` ahorra buscar el número de modo en la wiki.

Ese dato de `-b` es el que se combina con `--keyspace` para saber si un ataque cabe en la ventana del engagement, tal como se calcula en [[03 - Máscaras y charsets personalizados]].

# Seleccionar dispositivo

| Opción | Qué selecciona |
| ------ | -------------- |
| `-D 1` | CPU |
| `-D 2` | GPU |
| `-D 3` | FPGA, DSP, coprocesador |
| `-d N` | Un **backend device ID** concreto, de los que lista `-I` |

```shell-session
$ hashcat -m 22000 hash.hc22000 wordlist.txt -D 2 -d 1,2
```

`-D` filtra por **tipo** y `-d` por **identificador**. Conviene no mezclarlos a ciegas: los IDs de `-I` son globales y una misma GPU puede aparecer dos veces con alias distintos (una por CUDA y otra por OpenCL), en cuyo caso seleccionar ambas duplica trabajo en vez de repartirlo.

# `-w`: no es "más potencia", es tiempo de kernel

El perfil de carga define **cuánto tarda cada invocación del kernel**, y de ahí se derivan el consumo y la interactividad del escritorio:

| `-w` | Perfil | Tiempo de kernel | Impacto en el escritorio |
| ---- | ------ | ---------------- | ------------------------ |
| `1` | Low | 2 ms | Mínimo |
| `2` | Default | 12 ms | Apreciable |
| `3` | High | 96 ms | Sin respuesta |
| `4` | Nightmare | 480 ms | Sólo headless |

<mark style="background: #8000E1A6;">Ese es el motivo real de que `-w 4` "vaya más rápido"</mark>: menos invocaciones significa menos sobrecarga por invocación, no más frecuencia de reloj. Y por eso `-w 3` deja el equipo inutilizable —el driver gráfico no puede intercalar trabajo durante 96 ms— y `-w 4` puede disparar el *watchdog* del sistema operativo en una máquina con pantalla.

En un rig dedicado, `-w 4`. En el portátil con el que se está trabajando, `-w 1` o `-w 2`.

# `-O`: depende del modo, y hay que comprobarlo

`-O` activa los kernels optimizados, más rápidos a cambio de **limitar la longitud del candidato**. La documentación lo dice así de escueto: *"Enable optimized kernels (limits password length)"*.

> [!warning]+ El límite no es siempre 31, y en WPA2 no existe
> Se repite que `-O` recorta a 31 caracteres. Es cierto para muchos hashes rápidos —`-m 5700`, `-m 1000`— pero **no es una constante global**. En `-m 22000`, `module_22000.c` devuelve `pw_min = 8` y `pw_max = 63` sin variante optimizada: <mark style="background: #FF5582A6;">`-O` no recorta nada</mark>. El rango 8-63 no es de hashcat sino del estándar, y sus consecuencias sobre qué diccionarios sirven están en [[04 - Anatomía de una contraseña Wi-Fi]].
>
> La consecuencia práctica va en los dos sentidos. Con hashes rápidos, `-O` puede saltarse candidatas largas sin avisar y hacer creer que un espacio se agotó. Con WPA2 se puede usar sin miedo. La forma de saberlo es mirar lo que hashcat imprime al arrancar: `Minimum password length supported by kernel` y `Maximum password length supported by kernel`.

# Las opciones que se citan mal

| Opción | Qué hace de verdad | Qué se suele decir |
| ------ | ------------------ | ------------------ |
| `-T`, `--kernel-threads` | Ajuste manual del número de hilos del kernel | — |
| `--hook-threads` | *"Sets number of threads for a hook (per compute unit)"* | "Los hilos de CPU que usa hashcat" ❌ |
| `--cpu-affinity` | Fija el proceso a núcleos concretos | Correcto |
| `--force` | **Ignorar avisos** | "Necesario para que funcione" ❌ |

<mark style="background: #FFB86CA6;">`--hook-threads` sólo afecta a los modos que usan *hooks*</mark> —una pasada de código en CPU intercalada en el kernel, que emplean algoritmos como los de Ethereum o SecureZIP—. En `-m 22000` no hay hook, así que la opción no hace absolutamente nada. El control real de hilos es `-T`.

`--force` merece énfasis aparte: no es un flag de uso normal. Silencia avisos que casi siempre señalan un backend mal instalado, y la documentación del propio hashcat advierte de que puede ocultar problemas serios y producir resultados incorrectos. <mark style="background: #FFB8EBA6;">Si un comando necesita `--force`, lo que hay que arreglar es el driver</mark>, no añadir el flag.

# Novedades de hashcat 7

La rama 7.x (v7.0.0 en agosto de 2025, **v7.1.2** en agosto de 2025) aporta tres cosas relevantes para el tuning:

| Novedad | Para qué |
| ------- | -------- |
| **Assimilation bridge** | Repartir un algoritmo entre backends: PBKDF2 en GPU, otra fase en FPGA o CPU |
| `-Y`, `--backend-devices-virtmulti` | Crear N instancias virtuales sobre una GPU real |
| `-R`, `--backend-devices-virthost` | Elegir sobre qué dispositivo real se crean |
| Plugins en Python y Rust | Añadir algoritmos sin recompilar |

Los dispositivos virtuales resuelven un problema concreto: los algoritmos con poco paralelismo interno dejan la GPU infrautilizada, y partirla en varias instancias lógicas la satura. Para `-m 22000`, que ya paraleliza bien, la ganancia es marginal.

# Temperatura, sesiones y límites

```shell-session
$ hashcat -m 22000 hash.hc22000 rockyou.txt --session=cliente1 -w 4
$ hashcat --session=cliente1 --restore
$ hashcat -m 22000 ... --hwmon-temp-abort=95
$ hashcat -m 22000 ... --runtime=3600        # abortar tras una hora
```

El *watchdog* aborta por defecto al alcanzar el umbral de temperatura, y eso es deseable: un rig que se apaga a 90 °C es preferible a uno que se degrada. `--hwmon-disable` lo desactiva por completo y sólo tiene sentido cuando el sensor no funciona — nunca "para que no moleste".

`--runtime` es la opción que más se agradece en un engagement con ventana cerrada: garantiza que el ataque termina a tiempo y deja el fichero de restauración listo para continuar al día siguiente.

El resto de la cadena de un ataque a WPA —de dónde sale el hash y cómo se filtra antes de llegar aquí— está en [[02 - hcxpcapngtool]] y [[03 - hcxhashtool, hcxpsktool y el resto]].

> [!info]+ Markov está activo por defecto
> hashcat ordena los candidatos de un ataque de máscara por probabilidad usando cadenas de Markov (`hashcat.hcstat2`), no en orden lexicográfico. <mark style="background: #8000E1A6;">Eso significa que un ataque interrumpido a mitad ha cubierto mucho más del espacio *probable* que del espacio *total*</mark>. `--markov-disable` vuelve a la fuerza bruta clásica, y casi nunca interesa. Se puede sustituir el fichero estadístico con `--markov-hcstat2` por uno generado a partir de contraseñas del propio cliente (`hcstat2gen` de `hashcat-utils`), que es de las mejoras más rentables en un análisis de dominio.
