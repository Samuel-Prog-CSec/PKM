---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "El batch size está atado al ulimit del sistema: el flag que más afecta al resultado no es de red, es del sistema operativo"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a RustScan]]"
Nota siguiente: "[[02 - Precisión, evasión y detección]]"
Area: "[[RustScan.base|RustScan]]"
---
---

Como RustScan usa sockets del sistema operativo y no paquetes crudos ([[00 - Introducción a RustScan]]), su rendimiento no lo limita el ancho de banda sino **cuántos descriptores de fichero le deja abrir el sistema a la vez**. Esa es la peculiaridad que hay que dominar.

# Los flags

| Flag | Largo | Qué hace | Por defecto |
| --- | --- | --- | --- |
| `-a` | `--addresses` | CIDRs, IPs o hosts, separados por comas o un fichero por líneas | *obligatorio* |
| `-p` | `--ports` | Lista de puertos: `80,443,8080` | — |
| `-r` | `--range` | Rango `inicio-fin`: `1-65535` | — |
| — | `--top` | Los 1.000 puertos más comunes | `false` |
| `-b` | `--batch-size` | Puertos sondeados en paralelo | **4500** |
| `-t` | `--timeout` | Milisegundos antes de dar un puerto por cerrado | **1500** |
| — | `--tries` | Intentos antes de darlo por cerrado (`0` se corrige a `1`) | **1** |
| `-u` | `--ulimit` | Sube el límite de descriptores al valor indicado | — |
| — | `--scan-order` | `serial` (ascendente) o `random` | **serial** |
| — | `--scripts` | `none`, `default` o `custom` | **default** |
| `-g` | `--greppable` | Solo puertos, sin invocar a Nmap | `false` |
| `-x` | `--exclude-addresses` | CIDRs/IPs/hosts a excluir | — |
| — | `--exclude-ports` | Puertos a excluir | — |
| — | `--udp` | Modo UDP (puertos que devuelven respuesta) | `false` |
| — | `--resolver` | Resolutores DNS a usar (lista o fichero) | — |
| `-c` | `--config-path` | Ruta a un fichero de configuración propio | — |
| — | `--no-config` | Ignorar el fichero de configuración | `false` |
| — | `--accessible` | Modo accesible: apaga lo que estorba a un lector de pantalla | `false` |
| — | `--` | Todo lo que siga se le pasa a Nmap | — |

# El problema del `ulimit`

<mark style="background: #ADCCFFA6;">`--batch-size` es cuántos puertos intenta abrir a la vez, y cada intento consume un descriptor de fichero</mark>. Si el lote supera el límite del sistema (`ulimit -n`), las conexiones sobrantes fallan **por falta de descriptores, no porque el puerto esté cerrado**.

```shell-session
$ ulimit -n
1024
```

Ese 1024 es típico y está muy por debajo del `-b 4500` por defecto. Las tres salidas:

```shell-session
$ rustscan -a 10.129.2.28 -u 5000               # RustScan sube el límite él
$ ulimit -n 10000 && rustscan -a 10.129.2.28    # lo subes tú en la shell
$ rustscan -a 10.129.2.28 -b 500                # bajas el lote al límite disponible
```

> [!warning]+ El fallo silencioso que produce falsos negativos
> Sin `-u`, en un sistema con `ulimit -n 1024` y el lote por defecto de 4500, RustScan **no aborta**: agota descriptores y va contando como cerrados puertos que nunca llegó a probar. El resultado parece un escaneo normal, solo que incompleto. <mark style="background: #FF5582A6;">Es la causa número uno de "RustScan no encontró el puerto y Nmap sí"</mark>. Comprueba tu `ulimit -n` antes de la primera pasada y ajusta.

## Elegir el lote con criterio

- **Red local o laboratorio**: `-b 4500` (o más con `-u 10000`) va bien. Es donde salen los 3 segundos.
- **A través de VPN o hacia Internet**: baja a `-b 500-1000` y **sube `-t` a 3000-5000 ms**. Un lote enorme con timeout corto sobre una latencia de 200 ms es una fábrica de falsos negativos.
- **Objetivo con rate-limiting**: `-b` bajo y `--tries 3`. Un lote grande dispara las protecciones y el objetivo empieza a descartar tus SYN.
- **Reproducibilidad**: fija `-b`, `-t` y `-u` explícitamente. Si los dejas al *Adaptive Learning*, el mismo comando en dos máquinas da resultados distintos.

## `--scan-order random`

Por defecto recorre los puertos en orden ascendente, que es el patrón más reconocible que existe. `--scan-order random` los baraja. No es evasión seria —el volumen y el connect completo siguen ahí ([[02 - Precisión, evasión y detección]])— pero rompe la secuencia perfecta 1,2,3… que dispara las reglas más simples.

# Fichero de configuración

RustScan lee **`.rustscan.toml`**, buscándolo en este orden:

1. `{directorio de configuración de la plataforma}/.rustscan.toml`
2. `{directorio home}/.rustscan.toml` (compatibilidad hacia atrás)

```toml
# ~/.rustscan.toml
addresses = ["127.0.0.1"]
ports = [80, 443, 8080]
range = { start = 1, end = 65535 }
greppable = true
scan_order = "Random"
exclude_ports = [21, 23]
udp = false
```

> [!important]+ Cuidado con la configuración persistente
> <mark style="background: #FFB86CA6;">Un `.rustscan.toml` con `addresses` fijadas aplica **a todos** tus escaneos</mark> y es un modo excelente de escanear sin querer un objetivo de otro engagement. Si lo usas, deja fuera `addresses` y limítalo a parámetros de rendimiento. `--no-config` lo ignora puntualmente, y es lo que conviene tener por costumbre en trabajo de cliente.

# Scripting Engine

RustScan puede ejecutar scripts sobre los puertos encontrados, en **Python, Lua o Shell**, con ejecución condicional: correr `smb-enum` solo si aparece el 445, por ejemplo.

```shell-session
$ rustscan -a 10.129.2.28 --scripts default    # Nmap (comportamiento normal)
$ rustscan -a 10.129.2.28 --scripts none       # solo puertos
$ rustscan -a 10.129.2.28 --scripts custom     # tus scripts
```

Los scripts llevan una cabecera con etiquetas que declara a qué se aplican y cómo invocarlos, y se colocan en el directorio de scripts de RustScan.

> [!warning]+ Ecosistema pobre comparado con NSE
> El Scripting Engine es cómodo para automatizar *tu* flujo, pero <mark style="background: #FFB8EBA6;">no hay un ecosistema de scripts comunitario que se acerque a los ~600 del [[04 - Nmap Scripting Engine (NSE)|NSE]]</mark>, ni a las plantillas de `nuclei`. Úsalo para pegar herramientas propias; para enumeración por servicio, el relevo a Nmap sigue siendo el camino.

> [!info]+ Fuente
> Código fuente `src/input.rs` del [repositorio de RustScan](https://github.com/bee-san/RustScan) — definición completa de los flags con `clap`, sus valores por defecto (`-b 4500`, `-t 1500`, `--tries 1`, `--scan-order serial`, `--scripts default`) y la ruta de búsqueda de `.rustscan.toml`.
