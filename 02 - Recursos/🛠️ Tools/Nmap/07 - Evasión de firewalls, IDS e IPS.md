---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Cuando entre tú y el objetivo hay un firewall y un IDS/IPS, el escaneo directo se topa con puertos filtered y, si eres ruidoso, con un bloqueo de tu IP. Nmap trae varias…"
Fecha de actualización: 2026-07-18
Nota previa: "[[06 - Guardar y explotar resultados]]"
Nota siguiente: "[[08 - Detección de escaneos y evasión moderna]]"
Area: "[[Nmap.base|Nmap]]"
---
---

Cuando entre tú y el objetivo hay un firewall y un IDS/IPS, el escaneo directo se topa con puertos `filtered` y, si eres ruidoso, con un **bloqueo de tu IP**. Nmap trae varias palancas nativas para leer las reglas del firewall y disfrazar el origen del tráfico. Aquí van esas técnicas y por qué funcionan; lo que de verdad esquiva las defensas **modernas** (NGFW, EDR, IDS con reensamblado) se trabaja en [[08 - Detección de escaneos y evasión moderna]].

# Firewall vs IDS/IPS

- Un **firewall** decide si cada paquete pasa, se descarta (*drop*) o se rechaza (*reject*), según reglas.
- Un **IDS** (*Intrusion Detection System*) monitoriza pasivamente y **alerta** ante patrones/firmas conocidas (p. ej. un *service scan*).
- Un **IPS** complementa al IDS **actuando**: bloquea la conexión sospechosa automáticamente.

# Leer las reglas del firewall: el ACK scan (`-sA`)

<mark style="background: #ADCCFFA6;">El *ACK scan* (`-sA`) es mucho más difícil de filtrar que un SYN o un Connect</mark>: envía un paquete solo con el flag `ACK`. Un firewall suele bloquear los `SYN` entrantes (intentos de conexión desde fuera), pero deja pasar los `ACK` porque **no puede saber** si pertenecen a una conexión iniciada desde dentro. Comparando SYN vs ACK sobre los mismos puertos se deduce la política:

```shell-session
$ sudo nmap 10.129.2.28 -p 21,22,25 -sA --packet-trace -Pn -n --disable-arp-ping

SENT ... 10.129.2.28:22 A ...
RCVD ... 10.129.2.28:22 > ... R ...        # RST → puerto NO filtrado

21/tcp filtered   ftp
22/tcp unfiltered ssh
25/tcp filtered   smtp
```

Un `RST` de vuelta = puerto `unfiltered` (el ACK llegó al host → el firewall no lo bloquea). Silencio = `filtered`. El ACK scan no dice si el puerto está abierto, pero **sí revela qué deja pasar el firewall**.

## Drop vs reject

Recordando de [[02 - Escaneo de puertos y hosts]]: un firewall que **descarta** no responde (silencio, escaneo lento por reintentos); uno que **rechaza** devuelve un error explícito — `RST` en TCP, o un `ICMP` con distintos códigos que delatan la regla:

`Net/Host/Port/Proto Unreachable`, `Net Prohibited`, `Host Prohibited`. Cada uno te dice *cómo* está filtrando, información útil para elegir la evasión.

# Detectar el IDS/IPS

Los IDS/IPS son pasivos → **no se detectan directamente**, se infieren. La técnica: escanear desde varios **VPS con IPs distintas** y provocar deliberadamente (p. ej. un escaneo agresivo de un solo puerto). <mark style="background: #8000E1A6;">Si en algún momento uno de esos hosts pierde el acceso al objetivo, el administrador ha activado una contramedida</mark> → hay IPS, y toca ser mucho más silencioso (y quemar ese VPS).

> [!warning]+ Que te bloqueen es caro
> Cuando un IPS bloquea tu IP, no solo pierdes acceso: en un caso real puede escalar a que contacten a tu ISP. Por eso el descubrimiento de defensas se hace con infraestructura sacrificable y con la mínima agresividad necesaria.

# Disfrazar el origen

## Decoys (`-D`)

`-D RND:5` genera 5 IPs aleatorias en la cabecera IP; tu IP real se coloca al azar entre ellas. Al objetivo le llegan 6 orígenes y no sabe cuál es el real:

```shell-session
$ sudo nmap 10.129.2.28 -p 80 -sS -D RND:5 --packet-trace -Pn -n

SENT ... 102.52.161.59:59289  > 10.129.2.28:80 S ...   # decoy
SENT ... 10.10.14.2:59289     > 10.129.2.28:80 S ...   # ← nuestra IP real
SENT ... 210.120.38.29:59289  > 10.129.2.28:80 S ...   # decoy
```

<mark style="background: #FFB8EBA6;">Los decoys deben estar vivos</mark>, o los mecanismos anti *SYN-flood* pueden dejar inalcanzable el servicio. Además, los ISPs suelen filtrar paquetes con IP de origen falsa, así que su eficacia real es limitada.

## Source IP e interfaz (`-S`, `-e`)

Si solo ciertas subredes tienen acceso, se puede fijar la IP de origen (`-S`) y la interfaz de salida (`-e`). En el ejemplo, el puerto 445 salía `filtered` desde nuestra IP, pero `open` cambiando el origen:

```shell-session
$ sudo nmap 10.129.2.28 -p 445 -O -S 10.129.2.200 -e tun0 -n -Pn
445/tcp open microsoft-ds
```

## Source port (`--source-port`) — el truco que más funciona

Muchos firewalls **confían** en el tráfico que viene de puertos "de servicio" como el `53` (DNS), `20` (FTP-data) o `88` (Kerberos). Si el admin no filtra bien el IDS/IPS, mandar desde ese puerto de origen pasa el filtro:

```shell-session
$ sudo nmap 10.129.2.28 -p 50000 -sS -Pn -n --source-port 53
50000/tcp open ibm-db2        # ¡el mismo puerto salía 'filtered' sin --source-port!
```

Confirmado que el firewall se fía del puerto 53, puedes incluso **conectarte** al servicio con el mismo truco:

```shell-session
$ ncat -nv --source-port 53 10.129.2.28 50000
220 ProFTPd
```

## DNS proxying (`--dns-servers`)

Nmap resuelve por DNS por defecto. En una **DMZ**, los servidores DNS internos son más confiables que los de Internet; `--dns-servers <ns1,ns2,...>` (en **plural**, admite lista separada por comas) fuerza tus consultas a través de ellos, útil para interactuar con hosts de la red interna desde una posición de confianza.

# Fragmentación y otros knobs

HTB lo menciona de pasada, pero forma parte del arsenal nativo:

- **`-f` / `-f -f` / `--mtu <n>`**: fragmenta los paquetes para partir la firma que busca el IDS. `-f` = **8 bytes fijos**; `-f -f` (repetido) = **16 bytes fijos**; `--mtu <n>` fija un tamaño propio (**múltiplo de 8**). `-f`/`-f -f` y `--mtu` son excluyentes. (`-ff` concatenado suele funcionar por cómo Nmap agrupa los flags cortos, pero la forma documentada es `-f -f`.)
- **`--data-length <n>`**: añade *padding* aleatorio para alterar el tamaño característico de las sondas de Nmap.
- **`--spoof-mac <mac>`**: falsifica la MAC de origen (solo útil en la misma L2).
- **`--scan-delay <t>` / `-T0`/`-T1`**: espacia las sondas para diluir el patrón temporal de *portscan* (ver [[05 - Rendimiento y timing]]).
- **`--badsum`**: envía un *checksum* TCP/UDP inválido. Los stacks reales descartan el paquete, pero muchos IDS/firewalls que **no** validan el checksum sí responden — sirve para distinguir un host real de un dispositivo de inspección.
- **`-6`**: escanea por **IPv6**. En redes *dual-stack* es frecuente que el firewall filtre IPv4 a conciencia y deje IPv6 mucho más abierto — un vector de evasión real, no exótico.

> [!important]+ La mayoría de esto ya no basta en 2026
> Fragmentación, decoys y `--badsum` funcionaban contra IDS de firma simple. <mark style="background: #FF5582A6;">Los NGFW e IDS modernos reensamblan paquetes, hacen análisis de flujo y correlacionan por comportamiento</mark>, así que estas técnicas por sí solas rara vez esquivan una defensa seria hoy. Lo que de verdad se usa en pentest actual —*low-and-slow*, blending con tráfico legítimo, alternativas a Nmap, OPSEC de infraestructura— está en [[08 - Detección de escaneos y evasión moderna]]. Para mapear ACLs de firewall a fondo, la herramienta dedicada es [[👣🏰 Firewalk|Firewalk]].
