---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Descripción: "Con --banners masscan completa el handshake y lee la respuesta, pero el kernel del propio host lo sabotea con RST si no lo evitas"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - Salidas y pipeline hacia Nmap]]"
Nota siguiente: "[[05 - Evasión de firewalls e IDS con masscan]]"
Area: "[[Masscan.base|Masscan]]"
---
---

`--banners` es la función menos conocida de masscan y la que más se rompe al primer intento. Convierte el escáner en algo intermedio entre un barrido de puertos y una enumeración de servicios: <mark style="background: #ADCCFFA6;">completa el *three-way handshake* con su pila propia, lee lo primero que dice el servidor y corta</mark>, todo manteniendo la velocidad asíncrona.

```shell-session
$ sudo masscan 10.129.0.0/16 -p80,443,22 --banners --rate 5000 -oJ banners.json
```

# El sabotaje del propio kernel

Aquí está el problema que hace que la mitad de la gente concluya que «`--banners` no funciona».

masscan tiene [[00 - Introducción a masscan y el escaneo stateless|pila TCP/IP propia]] y envía el `SYN` desde un puerto de origen que **el kernel de tu máquina no conoce**. Cuando el objetivo responde `SYN/ACK`, ese paquete llega al kernel, que busca un socket abierto para esa tupla, no encuentra ninguno y hace lo correcto según el RFC: responder `RST`.

<mark style="background: #FF5582A6;">El `RST` del propio host mata la conexión antes de que masscan haya podido leer el banner</mark>. El escaneo "funciona" —los puertos salen abiertos— pero los banners vienen vacíos.

```
     masscan                    kernel local                  objetivo
        │── SYN (src :61000) ───────────────────────────────────▶│
        │◀──────────────────────────── SYN/ACK ──────────────────│
        │                            │◀─ el kernel también lo ve │
        │                            │── RST ───────────────────▶│  ✗ conexión muerta
```

## Solución 1 — darle a masscan su propia IP

```shell-session
$ sudo masscan 10.0.0.0/8 -p80 --banners --source-ip 192.168.1.200
```

Una IP **libre de la misma red**, no asignada a ninguna interfaz del host. El kernel nunca ve los `SYN/ACK` porque no van dirigidos a él, y masscan responde con su propia pila. Es la solución limpia cuando controlas el direccionamiento del segmento.

## Solución 2 — silenciar al kernel con el firewall

Si no puedes usar otra IP, reserva un puerto de origen y prohíbe al kernel contestar por él:

```shell-session
$ sudo iptables -A INPUT -p tcp --dport 61000 -j DROP
$ sudo masscan 10.0.0.0/8 -p80 --banners --source-port 61000
```

La man page muestra la variante con interfaz explícita (`iptables -A INPUT -p tcp -i eth0 --dport 61234 -j DROP`), preferible si tienes varias tarjetas.

> [!important]+ En 2026 eso es `iptables-nft`, y la forma nativa es `nft`
> En Debian 10+, RHEL 8+ y Ubuntu 20.10+, `iptables` es una capa de traducción sobre **nftables**. Funciona, pero la sintaxis nativa es más clara y es la que verás en un sistema moderno:
> ```shell-session
> $ sudo nft add table inet masscan
> $ sudo nft add chain inet masscan input '{ type filter hook input priority 0; policy accept; }'
> $ sudo nft add rule inet masscan input tcp dport 61000 drop
> $ sudo nft list table inet masscan          # comprobar
> $ sudo nft delete table inet masscan        # limpiar al terminar
> ```
> **Acuérdate de borrar la regla.** Dejar un `DROP` colgado en la máquina de trabajo produce fallos de red posteriores rarísimos de diagnosticar.

## Elegir bien el puerto de origen

<mark style="background: #FFB8EBA6;">El puerto reservado no puede caer dentro del rango efímero del sistema</mark>, o entrará en conflicto con conexiones salientes normales de la máquina:

```shell-session
$ cat /proc/sys/net/ipv4/ip_local_port_range
32768   60999
```

Por eso los ejemplos usan `61000` y `61234`: quedan por encima. Comprueba el rango en tu máquina antes de elegir — no es idéntico en todas las distribuciones.

# Qué protocolos entiende

masscan trae *parsers* para **FTP, HTTP, IMAP4, memcached, POP3, SMTP, SSH, SSL/TLS, SMBv1 y v2, Telnet, RDP y VNC**. Para HTTP extrae la versión del servidor y el `<title>`; para TLS puede sacar el certificado.

## Control fino de la captura

| Flag | Qué hace |
| --- | --- |
| `--hello ssl \| smbv1 \| http` | Fuerza el saludo inicial en vez de esperar al servidor. Necesario en puertos no estándar. |
| `--capture cert,servername,html,heartbleed,ticketbleed` | Qué guardar de la conversación TLS/HTTP. |
| `--nocapture <lo mismo>` | Excluye piezas concretas (típico: `--nocapture html` para no inflar la salida). |
| `--http-user-agent "<UA>"` | Cambia el *user-agent*. Ver [[05 - Evasión de firewalls e IDS con masscan]]. |
| `--connection-timeout N` | Segundos que espera datos en una conexión TCP antes de rendirse. |

```shell-session
$ sudo masscan 10.0.0.0/16 -p443 --banners --hello ssl \
    --capture cert,servername --nocapture html --source-port 61000 -oJ tls.json
```

`servername` es el que más valor operativo tiene: el **SNI y los nombres del certificado** revelan hostnames internos, dominios hermanos y a menudo la estructura de nombres del cliente ([[07 - Certificate Transparency logs]]).

# Cuándo NO usar `--banners`

Sinceramente, casi siempre. `--banners` es útil cuando quieres una foto rápida de *qué tipo* de cosa hay en 50.000 hosts sin montar una segunda fase. Pero:

| Necesidad | Mejor herramienta |
| --- | --- |
| Versión exacta + CPE + scripts | `nmap -sCV` ([[03 - Enumeración de servicios y versiones]]) |
| Handshakes L7 a escala de Internet | **ZGrab2** ([[02 - ZGrab2 - handshakes L7 y banners a escala]]) |
| Superficie web (título, tecnología, status) | `httpx` ([[05 - httpx - sondeo y fingerprinting HTTP a escala]]) |
| Inteligencia de certificados | `tlsx` ([[06 - tlsx - inteligencia desde TLS]]) |

<mark style="background: #8000E1A6;">La pila de banners de masscan es la parte menos mantenida del proyecto</mark> —y recuerda que el paquete de las distros es la 1.3.2 de 2021, sin las correcciones posteriores de `master`—. Para *banner grabbing* serio a escala, el ecosistema ha convergido en ZGrab2 y en la suite de ProjectDiscovery, que están vivos y hablan más protocolos.

> [!warning]+ `--banners` completa conexiones: eso se registra
> Un SYN suelto puede pasar desapercibido; <mark style="background: #FFB86CA6;">una conexión establecida deja entrada en los logs de la aplicación</mark> (access log de Apache/nginx, log de auth de SSH, evento de sesión en RDP). Con `--banners` pasas de "ruido en el IDS" a "línea con tu IP en el log del servidor", que es lo que el cliente mirará después. Tenlo en cuenta antes de usarlo en una fase que quieras sigilosa.

> [!info]+ Fuentes
> - [README de masscan](https://github.com/robertdavidgraham/masscan) — problema del `RST`, solución con `--source-ip`, regla `iptables` y aviso sobre `ip_local_port_range`; `doc/masscan.8` para `--hello`, `--capture` y `--connection-timeout`.
> - Código fuente `src/main-conf.c` — `SET_capture()` (`cert`, `servername`, `html`, `heartbleed`, `ticketbleed`) y `SET_hello()`.
