---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Los cinco formatos de salida, por qué el binario es el que hay que usar en escaneos largos, y cómo encadenar el resultado con Nmap"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - Rendimiento - rate, adaptador y transmisión]]"
Nota siguiente: "[[04 - Banner grabbing y modo stateful]]"
Area: "[[Masscan.base|Masscan]]"
---
---

El valor de masscan no está en su salida —que es pobre a propósito— sino en lo que alimenta después. <mark style="background: #8000E1A6;">La regla del pentest moderno es de dos fases: masscan descubre *dónde* hay algo, Nmap averigua *qué* es</mark>. Esta nota cubre los formatos y el pegamento entre ambas.

# Los cinco formatos

| Flag | `--output-format` | Uso |
| --- | --- | --- |
| `-oB` | `binary` | **El de trabajo**: compacto y rápido de escribir. Se convierte después. |
| `-oJ` | `json` | El de automatizar: `jq` y cualquier script lo comen. |
| `-oX` | `xml` | Compatibilidad con herramientas que esperan XML de Nmap. |
| `-oG` | `grepable` | Una línea por resultado, para `awk`/`cut`. |
| `-oL` | `list` | El más simple: `open tcp 443 10.0.0.5 <timestamp>`. |

Equivalen a la pareja `--output-format <fmt> --output-filename <fichero>`. `--append-output` añade en vez de sobrescribir.

## Por qué el binario primero

```shell-session
$ sudo masscan -c scope.conf -oB scan.bin
$ masscan --readscan scan.bin -oJ scan.json      # convertir después
$ masscan --readscan scan.bin -oL puertos.txt
```

<mark style="background: #FFB8EBA6;">El formato binario es notablemente más pequeño y barato de escribir</mark>, y `--readscan` lo convierte a cualquier otro formato **sin volver a escanear**. En un barrido de horas eso importa por dos razones: escribir menos no roba CPU al hilo de transmisión, y si a mitad decides que querías JSON en vez de XML, no repites el escaneo.

Combinado con `--rotate` es lo que hace robusto un escaneo largo:

```shell-session
$ sudo masscan -c scope.conf -oB scan.bin --rotate 1hour --rotate-dir ./salida/
```

Un fallo a las 6 horas se lleva como mucho la última hora.

> [!warning]+ El XML de masscan no es el XML de Nmap
> Comparten aire de familia, no esquema. Herramientas que ingieren "XML de Nmap" (importadores de Faraday, DefectDojo o el `db_import` de [[Metasploit.base|Metasploit]]) pueden tragarlo, rechazarlo o —peor— aceptarlo perdiendo campos. **Verifica el importe** contando hosts, no asumas. Si el destino final es Metasploit o un gestor de hallazgos, el camino fiable es masscan → lista de puertos → Nmap `-oA` → importar el XML **de Nmap**.

# El pipeline de dos fases

## Extraer los puertos abiertos

Con `-oL`, cada línea es `open tcp <puerto> <ip> <timestamp>`:

```shell-session
$ sudo masscan 10.129.0.0/16 -p1-65535 --rate 20000 --open-only -oL fase1.txt

$ awk '/^open/ {print $4}' fase1.txt | sort -u > hosts.txt
$ awk '/^open/ {print $3}' fase1.txt | sort -un | paste -sd, - > puertos.txt
```

Con `-oJ` y `jq`, que es más robusto porque no depende de posiciones de columna:

```shell-session
$ jq -r '.[] | .ip' fase1.json | sort -u > hosts.txt
$ jq -r '.[] | .ports[].port' fase1.json | sort -un | paste -sd, - > puertos.txt
```

## Pasarle el relevo a Nmap

```shell-session
$ sudo nmap -sCV -p "$(cat puertos.txt)" -iL hosts.txt -oA fase2 \
    --max-retries 2 --host-timeout 15m
```

<mark style="background: #ADCCFFA6;">Nmap solo toca los puertos que masscan encontró abiertos</mark>: el `-sCV` que sobre `-p-` sería inviable, sobre 40 puertos reales termina en minutos. Es exactamente el reparto que hace útil a masscan sin perder la precisión de [[03 - Enumeración de servicios y versiones|la enumeración de versiones]].

> [!important]+ Por host, no en bloque
> Pasar la unión de todos los puertos a todos los hosts (como hace el ejemplo de arriba) es cómodo pero desperdicia sondas: si un host tiene el 443 y otro el 3389, Nmap probará ambos en los dos. En rangos grandes conviene agrupar por host:
> ```shell-session
> $ jq -r '.[] | "\(.ip) \(.ports[].port)"' fase1.json \
>     | awk '{a[$1]=a[$1]","$2} END{for(i in a) print i, substr(a[i],2)}' \
>     | while read ip ports; do
>         sudo nmap -sCV -p "$ports" "$ip" -oA "nmap_$ip"
>       done
> ```

## Encadenar con el resto del arsenal

La lista de hosts:puerto es la entrada natural de las herramientas de la fase siguiente:

```shell-session
# servicios web -> fingerprinting y plantillas
$ jq -r '.[] | "\(.ip):\(.ports[].port)"' fase1.json | httpx -silent -tech-detect | nuclei -severity critical,high

# TLS -> certificados, SAN y nombres internos filtrados
$ jq -r '.[] | "\(.ip):\(.ports[].port)"' fase1.json | tlsx -san -cn -silent
```

Los certificados suelen regalar nombres de host internos y dominios hermanos que no salían en el recon pasivo — es de las mejores relaciones señal/ruido de toda la fase de descubrimiento ([[07 - Certificate Transparency logs]]).

# Leer la salida sin engañarse

```text
open tcp 443 10.129.2.28 1785832291
```

Eso significa **exactamente** «llegó un SYN/ACK desde 10.129.2.28:443». No significa que haya HTTPS ahí, ni que el servicio esté sano, ni que siga abierto un minuto después. masscan no negocia, no valida y no reintenta salvo que se lo pidas.

> [!warning]+ Ausencia no es prueba de cierre
> <mark style="background: #FF5582A6;">Un puerto que no aparece en la salida puede estar cerrado, filtrado, o haber respondido cuando el paquete se perdió</mark>. masscan no distingue `closed` de `filtered` como hace Nmap — solo reporta lo que contestó. Antes de escribir en un informe que un servicio no está expuesto, confírmalo con Nmap, que sí diferencia los dos estados (ver [[02 - Escaneo de puertos y hosts]]).

> [!success]+ El one-liner de referencia
> ```shell-session
> $ sudo masscan -c scope.conf --rate 10000 --retries 2 --open-only -oJ f1.json && \
>   sudo nmap -sCV -iL <(jq -r '.[].ip' f1.json | sort -u) \
>     -p "$(jq -r '.[].ports[].port' f1.json | sort -un | paste -sd, -)" -oA f2
> ```
> Descubrir rápido, enumerar despacio y solo lo que existe. El resto del ecosistema alrededor de este flujo está en [[09 - Arsenal de herramientas de escaneo]].

> [!info]+ Fuente
> `doc/masscan.8` del [repositorio oficial](https://github.com/robertdavidgraham/masscan) — formatos de salida, `--readscan`, `--rotate` y `--append-output`.
