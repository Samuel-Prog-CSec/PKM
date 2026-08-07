---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Acotar el objetivo, elegir la sonda, filtrar la salida y repartir el escaneo — la operativa real de ZMap sin fundir nada"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - Introducción a ZMap y el escaneo a escala de Internet]]"
Nota siguiente: "[[02 - ZGrab2 - handshakes L7 y banners a escala]]"
Area: "[[ZMap.base|ZMap]]"
---
---

ZMap se maneja distinto a masscan: menos flags sueltos y más **módulos enchufables**. La sonda que se envía, el formato de salida y los campos que se emiten son piezas intercambiables, y esa modularidad es lo que lo hace útil para investigación reproducible.

# Acotar el objetivo (primero, siempre)

```shell-session
$ sudo zmap -p 443 -w scope.txt -o resultado.csv
$ sudo zmap -p 443 203.0.113.0/24 -o resultado.csv
$ sudo zmap -p 443 -I lista_ips.txt -o resultado.csv
```

| Flag | Qué hace |
| --- | --- |
| `-w`, `--allowlist-file` | Fichero de subredes **a escanear**, CIDR una por línea. |
| `-b`, `--blocklist-file` | Fichero de subredes **a excluir**. Por defecto `/etc/zmap/blocklist.conf`. |
| `-I`, `--list-of-ips-file` | Lista de IPs sueltas. La documentación recomienda usarlo **solo por encima de 10 millones** de direcciones; por debajo, `-w` es más eficiente. |
| `-p`, `--target-ports` | Puertos y rangos (`80,443,8000-8100`). `*` = todos. |
| `-n`, `--max-targets` | Tope de objetivos a sondear. |
| `-N`, `--max-results` | Sale tras N resultados. |
| `-t`, `--max-runtime` | Tope de tiempo de transmisión. |

<mark style="background: #FF5582A6;">`-w scope.txt` es obligatorio en la práctica</mark>: sin rango ni allowlist, ZMap escanea Internet entero (ver [[00 - Introducción a ZMap y el escaneo a escala de Internet]]).

> [!important]+ El blocklist por defecto sabotea el escaneo interno
> `/etc/zmap/blocklist.conf` excluye `10.0.0.0/8`, `172.16.0.0/12` y `192.168.0.0/16`. Si apuntas ZMap a la red interna de un cliente, **no escanea nada y no falla ruidosamente**: termina con 0 resultados y parece que la red está vacía. Para uso interno: `-b /dev/null` (o un blocklist propio) y las exclusiones de scope las gestionas tú con `-b exclude.txt`.

## Ensayo en seco

```shell-session
$ sudo zmap -p 443 -w scope.txt --dryrun | head -20
```

`-d/--dryrun` imprime cada paquete por `stdout` **en vez de enviarlo**. Es el equivalente al `--echo`/`-sL` de masscan y no hay excusa para no usarlo antes de un escaneo grande. `--fast-dryrun` hace lo mismo en binario, para medir ritmo.

# Velocidad

```shell-session
$ sudo zmap -p 443 -w scope.txt -r 1000            # 1.000 paquetes/segundo
$ sudo zmap -p 443 -w scope.txt -B 10M             # 10 Mbps (manda sobre -r)
```

- **`-r`, `--rate`** — paquetes por segundo. <mark style="background: #FFB8EBA6;">Por defecto **10.000 pps**</mark>, cien veces el default de masscan.
- **`-B`, `--bandwidth`** — bits por segundo con sufijos `K`/`M`/`G`. **Sobrescribe** a `-r`, y suele ser la forma sensata de razonar: sabes el ancho de banda del enlace, no los pps.
- **`-T`, `--sender-threads`** — hilos de envío; por defecto `min(4, núcleos - 1)`.
- **`-c`, `--cooldown-time`** — segundos que sigue recibiendo tras acabar de enviar (por defecto **8**). Con RTT altos, súbelo.
- **`-P`, `--probes`** — sondas por par IP/puerto (por defecto **1**). El equivalente a `--retries`: subirlo a 2-3 compra precisión en redes con pérdidas.

# Módulos de sonda

```shell-session
$ zmap --list-probe-modules
$ sudo zmap -M icmp_echoscan -w scope.txt -o vivos.csv
$ sudo zmap -M udp -p 161 --probe-args=file:/usr/share/zmap/snmp.pkt -w scope.txt
```

El módulo por defecto es **`tcp_synscan`**. El proyecto trae además sondas ICMP, DNS, UPnP, BACnet y una familia amplia de UDP con *payloads* precargados por protocolo. `--probe-args` pasa parámetros al módulo (típicamente el fichero de *payload* UDP), y `--probe-ttl` fija el TTL de la sonda.

<mark style="background: #8000E1A6;">La arquitectura de módulos es la diferencia de fondo con masscan</mark>: escribir una sonda nueva para un protocolo UDP propietario es añadir un módulo, no parchear el escáner. Es lo que permite usar ZMap para medir despliegues de protocolos raros — y lo que lo emparenta con el trabajo de [[00 - Modelo de análisis de protocolos de red|análisis de protocolos]].

# Salida: módulos, campos y filtros

```shell-session
$ zmap --list-output-modules
$ zmap --list-output-fields -M tcp_synscan
$ sudo zmap -p 443 -w scope.txt -O csv -f "saddr,sport,classification,success" \
    --output-filter="success = 1 && repeat = 0" -o abiertos.csv
```

- **`-O`, `--output-module`** — por defecto `csv`.
- **`-f`, `--output-fields`** — lista separada por comas de los campos a emitir.
- **`--output-filter`** — expresión sobre esos campos. `success = 1 && repeat = 0` es el idioma canónico: solo respuestas positivas y solo la primera de cada host.
- **`--no-header-row`** — quita la cabecera, para encadenar con `awk`/`jq` sin cortar la primera línea.

## Deduplicación

`--dedup-method` (`full`, `window`, `none`) y `--dedup-window-size` controlan cómo se descartan respuestas repetidas. Importa porque <mark style="background: #FFB8EBA6;">un host puede responder varias veces a la misma sonda</mark> (retransmisiones, balanceadores) y sin deduplicar inflas el recuento de "hosts vivos" en el informe.

## Metadatos: lo que hace el escaneo auditable

```shell-session
$ sudo zmap -p 443 -w scope.txt -m metadata.json --notes "Engagement ACME, fase 1" \
    -u progreso.csv -L ./logs/ -o out.csv
```

`-m/--metadata-file` vuelca un JSON con la configuración completa, tiempos y estadísticas del escaneo. Junto con `--notes` y `--user-metadata`, es lo que convierte un escaneo en **evidencia reproducible** para el informe ([[Documentación y reporting.base|documentación y reporting]]): qué se lanzó, cuándo, contra qué y con qué resultado agregado.

# Red: por dónde salen los paquetes

| Flag | Uso |
| --- | --- |
| `-i`, `--interface` | Interfaz de salida. |
| `-S`, `--source-ip` | IP(s) de origen — **acepta rango**, base de la rotación de origen. |
| `-s`, `--source-port` | Puerto(s) de origen. |
| `-G`, `--gateway-mac` | MAC del siguiente salto si la autodetección falla. |
| `--source-mac` | MAC de origen. |
| `-X`, `--iplayer` | Envía a nivel IP en vez de construir la trama Ethernet (útil en túneles/VPN). |
| `--validate-source-port` | Valida el puerto de origen en las respuestas. |

`-X` es el que resuelve el caso frecuente de escanear a través de un `tun0` de VPN, donde no hay Ethernet ni MAC de gateway que detectar.

# Sharding

```shell-session
$ sudo zmap -p 443 -w scope.txt --shards 4 --shard 0 -e 20260804 -r 2500
$ sudo zmap -p 443 -w scope.txt --shards 4 --shard 1 -e 20260804 -r 2500
```

Igual que en masscan, pero ZMap **obliga** a lo que allí era una buena práctica: <mark style="background: #ADCCFFA6;">al usar `--shard`, la semilla `-e/--seed` es obligatoria</mark>. Sin ella no hay partición coherente, porque cada instancia elegiría un generador distinto del grupo cíclico y recorrería otro orden. Es un buen ejemplo de API que evita el error por diseño en vez de documentarlo.

`-e/--seed` sirve además para lo de siempre: repetir un escaneo en idéntico orden y comparar resultados entre pasadas.

# Frenos de seguridad

Dos flags que conviene conocer porque **abortan el escaneo solos**:

- **`--min-hitrate`** — si el porcentaje de respuestas cae por debajo del umbral, para. Protege contra el caso "me han bloqueado y llevo dos horas mandando paquetes al vacío".
- **`--max-sendto-failures`** — corta tras N fallos de la NIC al enviar.

> [!success]+ Invocación de referencia para superficie pública de un cliente
> ```shell-session
> $ sudo zmap -p 80,443,8080,8443 -w scope.txt -b exclude.txt \
>     -B 5M -P 2 -c 15 -i eth0 \
>     -f "saddr,sport,classification,success" --output-filter="success = 1 && repeat = 0" \
>     -m meta.json --notes "ACME fase 1" -o abiertos.csv
> ```
> Ancho de banda acotado, doble sonda contra falsos negativos, salida limpia y metadatos para el informe.

> [!info]+ Fuente
> `src/zmap.1` (man page oficial) y `conf/zmap.conf` del [repositorio de ZMap](https://github.com/zmap/zmap) — todos los flags, defaults (`-r 10000`, `-c 8`, `-P 1`, `-M tcp_synscan`, `-O csv`) y la obligatoriedad de `--seed` con `--shard`.
