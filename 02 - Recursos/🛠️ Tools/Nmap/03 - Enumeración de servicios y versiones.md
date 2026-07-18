---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Fecha de actualización: 2026-07-18
Nota previa: "[[02 - Escaneo de puertos y hosts]]"
Nota siguiente: "[[04 - Nmap Scripting Engine (NSE)]]"
Area: "[[Nmap.base|Nmap]]"
---
---

Saber que el puerto 80 está abierto vale poco; saber que corre <mark style="background: #ADCCFFA6;">`Apache httpd 2.4.29`</mark> lo cambia todo. <mark style="background: #FFB86CA6;">La versión exacta de un servicio es la que te permite buscar el exploit preciso</mark>, revisar el código fuente de esa versión y descartar falsos positivos. La detección de servicio y versión (`-sV`) es el puente entre "hay algo escuchando" y "sé qué atacar".

# `-sV`: detección de servicio y versión

El flujo recomendado en un objetivo real es en **dos tiempos** para no generar ruido innecesario: un escaneo rápido de puertos primero (poco tráfico, menos probable que salte una alarma), y luego `-sV` dirigido solo a los puertos abiertos. En paralelo puedes lanzar un `-p-` de fondo.

```shell-session
$ sudo nmap 10.129.2.28 -p- -sV

PORT    STATE SERVICE  VERSION
22/tcp  open  ssh      OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
25/tcp  open  smtp     Postfix smtpd
80/tcp  open  http     Apache httpd 2.4.29 ((Ubuntu))
110/tcp open  pop3     Dovecot pop3d
143/tcp open  imap     Dovecot imapd (Ubuntu)
993/tcp open  ssl/imap Dovecot imapd (Ubuntu)
995/tcp open  ssl/pop3 Dovecot pop3d
Service Info: Host: inlane; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

La línea `Service Info` regala el **hostname**, el **SO** y el **CPE** — este último es el identificador estandarizado que luego usarás para cruzar contra bases de CVE (ver [[01 - Evaluación de vulnerabilidades|Evaluación de vulnerabilidades]]).

## Ver el progreso de un escaneo largo

Un `-p- -sV` puede tardar minutos. Tres formas de no quedarte a ciegas:

- Pulsar **`[Espacio]`** durante el escaneo → estado puntual (`% done`, ETC).
- **`--stats-every=5s`** → reporta el progreso cada N segundos/minutos.
- **`-v` / `-vv`** → muestra cada puerto abierto **en cuanto lo descubre**, sin esperar al final.

## Cómo deduce Nmap la versión

<mark style="background: #FFB8EBA6;">Primero lee el *banner*</mark> que el servicio anuncia al conectar; si el banner no basta para identificarlo, pasa a un sistema de *matching* por firmas que envía sondas específicas — más preciso pero **más lento**. El detalle fino de la agresividad se controla con `--version-intensity <0-9>` (`0` = solo banners ligeros, `9` = todas las sondas; `--version-all` es el atajo a 9).

# El gotcha: Nmap se deja información

<mark style="background: #FF5582A6;">El escaneo automático puede ocultarte datos que un banner grab manual sí revela</mark>. En el ejemplo, `-sV` reportó el SMTP como `Postfix smtpd` a secas, pero el banner real llevaba más:

```shell-session
$ nc -nv 10.129.2.28 25

Connection to 10.129.2.28 port 25 [tcp/*] succeeded!
220 inlane ESMTP Postfix (Ubuntu)
```

Ese `(Ubuntu)` — la distribución — Nmap no lo mostró. El servidor envía el banner tras el *three-way handshake* en un paquete con el flag **`PSH`** (el que fuerza la entrega inmediata de datos a la aplicación), como se ve interceptando con [[Tcpdump]]:

```shell-session
$ sudo tcpdump -i eth0 host 10.10.14.2 and 10.129.2.28
...
IP 10.129.2.28.smtp > 10.10.14.2: Flags [P.], ... length 35: SMTP: 220 inlane ESMTP Postfix (Ubuntu)
```

> [!important]+ Regla de oro: confirma a mano lo interesante
> Los banners se pueden **manipular o eliminar**, y `-sV` no siempre sabe interpretar la respuesta. Ante un servicio que importa, conéctate manualmente (`nc`, `ncat`, `curl -I`, `openssl s_client -connect host:443`) y lee el banner crudo. Es más fiable que fiarte del resumen de Nmap y muchas veces revela versión, distro o configuración que el escáner se salta.

# Detección de SO (`-O`)

`-O` intenta identificar el sistema operativo por *fingerprinting* de la pila TCP/IP. Es orientativo (`Aggressive OS guesses: Linux 3.2 - 4.9 (96%)…`) y poco fiable si no hay al menos un puerto abierto **y** uno cerrado. El combo estándar en enumeración es `-sCV` (versión + scripts por defecto) — a menudo junto a `-O` bajo el paraguas de `-A`, que se detalla en [[04 - Nmap Scripting Engine (NSE)]].

# Enfoque profesional 2026

- **Confirmación web**: para servicios HTTP, `whatweb`, `httpx` y `nuclei` identifican tecnología y versión mejor y más rápido que `-sV`; para el resto, el banner grab manual sigue mandando. Arsenal completo en [[09 - Arsenal de herramientas de escaneo]].
- **Ruido**: la detección de versión agresiva (`--version-all`, `-A`) dispara muchas sondas atípicas y es de lo más detectable por un IDS moderno. Si el sigilo importa, baja la intensidad y enumera a mano — ver [[08 - Detección de escaneos y evasión moderna]].
- El siguiente escalón —interrogar el servicio con lógica específica (vuln checks, brute, discovery)— es el motor de scripts: [[04 - Nmap Scripting Engine (NSE)]]. Referencia oficial de detección de servicios: [nmap.org/book/vscan.html](https://nmap.org/book/vscan.html).
