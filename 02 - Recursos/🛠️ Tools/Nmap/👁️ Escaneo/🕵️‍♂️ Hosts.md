---
tags:
  - Escaneo/Redes
  - Linux
  - Pentesting/Enumeracion
  - Windows
Fecha de actualización: 2025-08-31
Nota previa: "[[💻 Nmap]]"
Nota siguiente: "[[🔌 Puertos]]"
Area: "[[💻 Nmap]]"
---
---

Siempre se recomienda almacenar cada escaneo. Esto se puede utilizar posteriormente para comparación, documentación e informes. Después de todo, diferentes herramientas pueden producir resultados diferentes. Por tanto, puede resultar beneficioso distinguir qué herramienta produce qué resultados. Hay que recordar que podemos encontrar varias estrategias de enumerar hosts en [https://nmap.org/book/host-discovery-strategies.html](https://nmap.org/book/host-discovery-strategies.html)

# Escanear rango de red
Este método de escaneo funciona sólo si los firewalls de los hosts lo permiten. De lo contrario, podemos utilizar otras técnicas de escaneo para saber si los hosts están activos o no. Analizaremos más de cerca estas técnicas en [[🛡️ Evasión de Firewall-IDS-IPS]].
```shell-session
$ sudo nmap 10.129.2.0/24 -sn -oA tnet | grep for | cut -d" " -f5

10.129.2.4
10.129.2.10
10.129.2.11
10.129.2.18
10.129.2.19
10.129.2.20
10.129.2.28
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.0/24`|Alcance de la red objetivo.|
|`-sn`|Desactiva el escaneo de puertos.|
|`-oA tnet`|Almacena los resultados en todos los formatos comenzando con el nombre 'tnet'.|

---

# Escanear lista de IP
Es posible que nos proporcionen una lista de IP con los hosts que necesitamos probar. `Nmap` También nos da la opción de trabajar con listas y leer los hosts de esta lista en lugar de definirlos o escribirlos manualmente.
```shell-session
$ cat hosts.lst

10.129.2.4
10.129.2.10
10.129.2.11
10.129.2.18
10.129.2.19
10.129.2.20
10.129.2.28
```

Si utilizamos la misma técnica de escaneo en la lista predefinida, el comando se verá así:
```shell-session
$ sudo nmap -sn -oA tnet -iL hosts.lst | grep for | cut -d" " -f5

10.129.2.18
10.129.2.19
10.129.2.20
```

| **Opciones de escaneo** | **Descripción**                                                                    |
| ----------------------- | ---------------------------------------------------------------------------------- |
| `-sn`                   | Desactiva el escaneo de puertos.                                                   |
| `-oA tnet`              | Almacena los resultados en todos los formatos comenzando con el nombre 'tnet'.     |
| `-iL`                   | Realiza escaneos definidos contra objetivos en la lista `hosts.lst` proporcionada. |

---

# Escanear varias IP
También puede suceder que sólo necesitemos escanear una pequeña parte de una red. Una alternativa al método que utilizamos la última vez es especificar múltiples direcciones IP.
```shell-session
$ sudo nmap -sn -oA tnet 10.129.2.18 10.129.2.19 10.129.2.20| grep for | cut -d" " -f5

10.129.2.18
10.129.2.19
10.129.2.20
```

> [!recomendacion]
> Si estas direcciones IP están una al lado de la otra, también podemos definir el rango en el octeto respectivo.
```shell-session
Kronno23@htb[/htb]$ sudo nmap -sn -oA tnet 10.129.2.18-20| grep for | cut -d" " -f5

10.129.2.18
10.129.2.19
10.129.2.20
```

---

# Escanear una sola IP
Antes de escanear un único host en busca de puertos abiertos y sus servicios, primero tenemos que determinar si está activo o no. Para ello podemos utilizar el mismo método que antes.
```shell-session
$ sudo nmap 10.129.2.18 -sn -oA host 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-14 23:59 CEST
Nmap scan report for 10.129.2.18
Host is up (0.087s latency).
MAC Address: DE:AD:00:00:BE:EF
Nmap done: 1 IP address (1 host up) scanned in 0.11 seconds
```

Si deshabilitamos el escaneo de puertos (`-sn`), [[💻 Nmap]] realiza un escaneo de ping automáticamente con `ICMP Echo Requests` (`-PE`). Una vez enviada dicha solicitud, normalmente esperamos una `ICMP reply` si el host que hace ping está vivo. El hecho más interesante es que nuestros escaneos anteriores no hicieron eso porque antes de que Nmap pudiera enviar una solicitud de echo ICMP, enviaría una `ARP ping` dando como resultado un `ARP reply`. Podemos confirmarlo con la opción "`--packet-trace`".
```shell-session
$ sudo nmap 10.129.2.18 -sn -oA host -PE --packet-trace 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 00:08 CEST
SENT (0.0074s) ARP who-has 10.129.2.18 tell 10.10.14.2
RCVD (0.0309s) ARP reply 10.129.2.18 is-at DE:AD:00:00:BE:EF
Nmap scan report for 10.129.2.18
Host is up (0.023s latency).
MAC Address: DE:AD:00:00:BE:EF
Nmap done: 1 IP address (1 host up) scanned in 0.05 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.18`|Realiza escaneos definidos contra el objetivo.|
|`-sn`|Desactiva el escaneo de puertos.|
|`-oA host`|Almacena los resultados en todos los formatos comenzando con el nombre 'host'.|
|`-PE`|Realiza el escaneo de ping utilizando 'solicitudes ICMP Echo' contra el objetivo.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos|

---

> [!tip]+
> Otra forma de determinar por qué Nmap tiene nuestro objetivo marcado como "vivo" es con el "`--reason`" opción.
```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.18 -sn -oA host -PE --reason 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 00:10 CEST
SENT (0.0074s) ARP who-has 10.129.2.18 tell 10.10.14.2
RCVD (0.0309s) ARP reply 10.129.2.18 is-at DE:AD:00:00:BE:EF
Nmap scan report for 10.129.2.18
Host is up, received arp-response (0.028s latency).
MAC Address: DE:AD:00:00:BE:EF
Nmap done: 1 IP address (1 host up) scanned in 0.03 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.18`|Realiza escaneos definidos contra el objetivo.|
|`-sn`|Desactiva el escaneo de puertos.|
|`-oA host`|Almacena los resultados en todos los formatos comenzando con el nombre 'host'.|
|`-PE`|Realiza el escaneo de ping utilizando 'solicitudes ICMP Echo' contra el objetivo.|
|`--reason`|Muestra el motivo del resultado específico.|

Vemos aquí que `Nmap`, detecta si el huésped está vivo o no a través del `ARP request` y `ARP reply` solo. Para deshabilitar solicitudes ARP y escanear nuestro objetivo con el deseado `ICMP echo requests`, podemos deshabilitar los pings ARP estableciendo "`--disable-arp-ping`".
```shell-session
$ sudo nmap 10.129.2.18 -sn -oA host -PE --packet-trace --disable-arp-ping 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 00:12 CEST
SENT (0.0107s) ICMP [10.10.14.2 > 10.129.2.18 Echo request (type=8/code=0) id=13607 seq=0] IP [ttl=255 id=23541 iplen=28 ]
RCVD (0.0152s) ICMP [10.129.2.18 > 10.10.14.2 Echo reply (type=0/code=0) id=13607 seq=0] IP [ttl=128 id=40622 iplen=28 ]
Nmap scan report for 10.129.2.18
Host is up (0.086s latency).
MAC Address: DE:AD:00:00:BE:EF
Nmap done: 1 IP address (1 host up) scanned in 0.11 seconds
```