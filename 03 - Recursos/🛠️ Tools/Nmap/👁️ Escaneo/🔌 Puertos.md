---
tags:
  - Escaneo/Redes
  - Linux
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2025-08-31
Nota previa: "[[🕵️‍♂️ Hosts]]"
Nota siguiente: "[[⚡ Servicios]]"
Area: "[[💻 Nmap]]"
---
---

Podemos encontrar más información sobre las técnicas de escaneo de puertos en: [https://nmap.org/book/man-port-scanning-techniques.html](https://nmap.org/book/man-port-scanning-techniques.html) Hay un total de **6 estados diferentes para un puerto escaneado** que podemos obtener:

| **Estado**             | **Descripción**                                                                                                                                                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `open`                 | Esto indica que<mark style="background: #ADCCFFA6;"> se ha establecido la conexión al puerto escaneado</mark>. Estas conexiones pueden ser **Conexiones TCP**, **Datagramas UDP** así como **Asociaciones SCTP**.                                |
| `closed`               | Cuando el puerto se muestra cerrado, el protocolo TCP indica que el paquete que recibimos **contiene una flag** `RST`. Este método de escaneo también se puede utilizar para determinar si nuestro objetivo está vivo o no.                      |
| `filtered`             | Nmap no puede identificar correctamente si el puerto escaneado está abierto o cerrado porque <mark style="background: #ADCCFFA6;">no se devuelve ninguna respuesta del destino para el puerto o recibimos un código</mark> de error del destino. |
| `unfiltered`           | Este estado de un puerto *sólo ocurre durante* el **TCP-ACK** scan y <mark style="background: #ADCCFFA6;">significa que el puerto es accesible, pero no se puede determinar si está abierto o cerrado</mark>.                                    |
| `open` \| `filtered`   | Si <mark style="background: #FFB86CA6;">no obtenemos una respuesta para un puerto específico</mark>, [[💻 Nmap]] lo establecerá en ese estado. Esto indica que un firewall o un filtro de paquetes pueden proteger el puerto.                    |
| `closed` \| `filtered` | Este estado sólo ocurre en el **ID de IP inactivo** escanea e indica que <mark style="background: #FF5582A6;">fue imposible determinar si el puerto escaneado está cerrado o filtrado por un firewal</mark>l.                                    |

---

# Descubriendo puertos TCP abiertos
Por defecto, `Nmap` <mark style="background: #8000E1A6;">escanea los 1000 puertos TCP principales</mark> con el escaneo *SYN* (`-sS`). Este escaneo *SYN* está configurado solo de forma predeterminada cuando lo ejecutamos como *root* debido a los <mark style="background: #FF5582A6;">permisos de socket necesarios</mark> para crear paquetes TCP sin procesar. De lo contrario, el **escaneo TCP** (`-sT`) se realiza de forma predeterminada. Esto significa que si no definimos puertos y métodos de escaneo, estos parámetros se configuran automáticamente. Podemos definir los puertos uno por uno (`-p 22,25,80,139,445`), por rango (`-p 22-445`), por puertos superiores (`--top-ports=10`) de las bases de datos que han sido firmadas como más frecuencia, escaneando todos los puertos (`-p-`) pero también definiendo un escaneo rápido de puertos, que contiene los 100 puertos principales (`-F`).

## Rastrear los paquetes
Si rastreamos los paquetes que `Nmap` envía, veremos el flag `RST` en `TCP port 21` que nuestro objetivo nos envía de vuelta. Para tener una vista clara del escaneo *SYN*, deshabilitamos las solicitudes de echo ICMP (`-Pn`), resolución [[🧭 DNS]] (`-n`), y escaneo de ping *ARP* (`--disable-arp-ping`).
```shell-session
$ sudo nmap 10.129.2.28 -p 21 --packet-trace -Pn -n --disable-arp-ping

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 15:39 CEST
SENT (0.0429s) TCP 10.10.14.2:63090 > 10.129.2.28:21 S ttl=56 id=57322 iplen=44  seq=1699105818 win=1024 <mss 1460>
RCVD (0.0573s) TCP 10.129.2.28:21 > 10.10.14.2:63090 RA ttl=64 id=0 iplen=40  seq=0 win=0
Nmap scan report for 10.11.1.28
Host is up (0.014s latency).

PORT   STATE  SERVICE
21/tcp closed ftp
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

> [!check]
> Podemos ver desde la línea *SENT* que nosotros (`10.10.14.2`) <mark style="background: #FFB8EBA6;">enviamos un paquete TCP</mark> con el flag `SYN` (`S`) a nuestro objetivo (`10.129.2.28`). En la siguiente línea *RCVD*, podemos ver que <mark style="background: #FFB8EBA6;">el objetivo responde con un paquete TCP</mark> que contiene el `RST` y `ACK` (`RA`). `RST` y `ACK` Los indicadores se utilizan para **indicar el recibo del paquete TCP** (`ACK`) **y para finalizar la sesión TCP** (`RST`).

---

# Escaneo de conexión TCP
El mapa N [Escaneo de conexión TCP](https://nmap.org/book/scan-methods-connect-scan.html) (`-sT`) utiliza el protocolo de enlace de tres vías TCP para determinar si un puerto específico en un host de destino está abierto o cerrado. El escaneo envía un `SYN` paquete al puerto de destino y espera una respuesta. Se considera abierto si el puerto de destino responde con un `SYN-ACK` paquete y cerrado si responde con un `RST` paquete.

El `Connect`El escaneo (también conocido como escaneo de conexión TCP completa) es muy preciso porque completa el protocolo de enlace TCP de tres vías, lo que nos permite determinar el estado exacto de un puerto (abierto, cerrado o filtrado). Sin embargo, no es el más sigiloso. De hecho, el escaneo Connect es una de las técnicas menos sigilosas, ya que establece completamente una conexión, lo que crea registros en la mayoría de los sistemas y es fácilmente detectado por las soluciones IDS/IPS modernas. Dicho esto, el escaneo Connect aún puede ser útil en ciertas situaciones, particularmente cuando la precisión es una prioridad y el objetivo es mapear la red sin causar interrupciones significativas en los servicios. Dado que el escaneo establece completamente una conexión TCP, interactúa limpiamente con los servicios, lo que hace que sea menos probable que cause errores de servicio o inestabilidad en comparación con escaneos más intrusivos. Si bien no es el método más sigiloso,A veces se considera un escaneo más "educado" porque se comporta como una conexión de cliente normal, teniendo así un impacto mínimo en los servicios de destino.

También es útil cuando el host de destino tiene un firewall personal que descarta los paquetes entrantes pero permite los paquetes salientes. En este caso, un escaneo Connect puede eludir el firewall y determinar con precisión el estado de los puertos de destino. Sin embargo, es importante tener en cuenta que el escaneo Connect es más lento que otros tipos de escaneos porque requiere que el escáner espere una respuesta del objetivo después de cada paquete que envía, lo que podría llevar algún tiempo si el objetivo está ocupado o no responde.

Los escaneos como el escaneo SYN (también conocido como escaneo semiabierto) generalmente se consideran más sigilosos porque no completan el protocolo de enlace completo, dejando la conexión incompleta después de enviar el paquete SYN inicial. Esto minimiza la posibilidad de activar registros de conexión y al mismo tiempo recopilar información sobre el estado del puerto. Sin embargo, los sistemas IDS/IPS avanzados se han adaptado para detectar incluso estas técnicas más sutiles.

## Escaneo de conexión en el puerto TCP 443
```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -p 443 --packet-trace --disable-arp-ping -Pn -n --reason -sT 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 16:26 CET
CONN (0.0385s) TCP localhost > 10.129.2.28:443 => Operation now in progress
CONN (0.0396s) TCP localhost > 10.129.2.28:443 => Connected
Nmap scan report for 10.129.2.28
Host is up, received user-set (0.013s latency).

PORT    STATE SERVICE REASON
443/tcp open  https   syn-ack

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

---

## Puertos filtrados

Cuando un puerto se muestra como filtrado, puede tener varias razones. En la mayoría de los casos, los firewalls tienen ciertas reglas establecidas para manejar conexiones específicas. Los paquetes pueden ser: `dropped`, o `rejected`. Cuando se cae un paquete, `Nmap` no recibe respuesta de nuestro objetivo y, de forma predeterminada, la tasa de reintentos (`--max-retries`) está configurado en `10`. Esto significa `Nmap` reenviará la solicitud al puerto de destino para determinar si el paquete anterior se manejó mal accidentalmente o no.

Veamos un ejemplo donde el firewall `drops` los paquetes TCP que enviamos para el escaneo del puerto. Por eso escaneamos el puerto TCP **139**, que ya se mostró como filtrado. Para poder rastrear cómo se manejan nuestros paquetes enviados, desactivamos las solicitudes de eco ICMP (`-Pn`), resolución DNS (`-n`), y escaneo de ping ARP (`--disable-arp-ping`) din nou.

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -p 139 --packet-trace -n --disable-arp-ping -Pn

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 15:45 CEST
SENT (0.0381s) TCP 10.10.14.2:60277 > 10.129.2.28:139 S ttl=47 id=14523 iplen=44  seq=4175236769 win=1024 <mss 1460>
SENT (1.0411s) TCP 10.10.14.2:60278 > 10.129.2.28:139 S ttl=45 id=7372 iplen=44  seq=4175171232 win=1024 <mss 1460>
Nmap scan report for 10.129.2.28
Host is up.

PORT    STATE    SERVICE
139/tcp filtered netbios-ssn
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 2.06 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-p 139`|Escanea sólo el puerto especificado.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|

---

Vemos en el último escaneo que `Nmap` envió dos paquetes TCP con el indicador SYN. Por la duración (`2.06s`) del escaneo, podemos reconocer que tomó mucho más tiempo que los anteriores (`~0.05s`). El caso es diferente si el firewall rechaza los paquetes. Para ello, analizamos el puerto TCP `445`, que se maneja en consecuencia mediante dicha regla del firewall.

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -p 445 --packet-trace -n --disable-arp-ping -Pn

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 15:55 CEST
SENT (0.0388s) TCP 10.129.2.28:52472 > 10.129.2.28:445 S ttl=49 id=21763 iplen=44  seq=1418633433 win=1024 <mss 1460>
RCVD (0.0487s) ICMP [10.129.2.28 > 10.129.2.28 Port 445 unreachable (type=3/code=3) ] IP [ttl=64 id=20998 iplen=72 ]
Nmap scan report for 10.129.2.28
Host is up (0.0099s latency).

PORT    STATE    SERVICE
445/tcp filtered microsoft-ds
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.05 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-p 445`|Escanea sólo el puerto especificado.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|

Como respuesta, recibimos un `ICMP` responder con `type 3` y `error code 3`, lo que indica que el puerto deseado es inalcanzable. Sin embargo, si sabemos que el host está activo, podemos asumir firmemente que el firewall de este puerto está rechazando los paquetes, y tendremos que analizar este puerto más de cerca más adelante.

---

# Descubriendo puertos UDP abiertos

Algunos administradores de sistemas a veces olvidan filtrar los puertos UDP además de los TCP. Desde `UDP` es un `stateless protocol` y no requiere un protocolo de enlace de tres vías como TCP. No recibimos ningún reconocimiento. En consecuencia, el tiempo de espera es mucho más largo, lo que hace que todo `UDP scan` (`-sU`) mucho más lento que el `TCP scan` (`-sS`).

Veamos un ejemplo de lo que es un escaneo UDP (`-sU`) puede verse y qué resultados nos da.

#### Escaneo de puertos UDP

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -F -sU

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 16:01 CEST
Nmap scan report for 10.129.2.28
Host is up (0.059s latency).
Not shown: 95 closed ports
PORT     STATE         SERVICE
68/udp   open|filtered dhcpc
137/udp  open          netbios-ns
138/udp  open|filtered netbios-dgm
631/udp  open|filtered ipp
5353/udp open          zeroconf
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 98.07 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-F`|Escanea los 100 puertos principales.|
|`-sU`|Realiza un escaneo UDP.|

---

Otra desventaja de esto es que a menudo no recibimos una respuesta porque `Nmap` envía datagramas vacíos a los puertos UDP escaneados y no recibimos ninguna respuesta. Por lo tanto, no podemos determinar si el paquete UDP ha llegado o no. Si el puerto UDP es `open`, solo obtenemos una respuesta si la aplicación está configurada para hacerlo.

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -sU -Pn -n --disable-arp-ping --packet-trace -p 137 --reason 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 16:15 CEST
SENT (0.0367s) UDP 10.10.14.2:55478 > 10.129.2.28:137 ttl=57 id=9122 iplen=78
RCVD (0.0398s) UDP 10.129.2.28:137 > 10.10.14.2:55478 ttl=64 id=13222 iplen=257
Nmap scan report for 10.129.2.28
Host is up, received user-set (0.0031s latency).

PORT    STATE SERVICE    REASON
137/udp open  netbios-ns udp-response ttl 64
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.04 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-sU`|Realiza un escaneo UDP.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-p 137`|Escanea sólo el puerto especificado.|
|`--reason`|Muestra el motivo por el cual un puerto se encuentra en un estado particular.|

---

Si obtenemos una respuesta ICMP con `error code 3` (puerto inalcanzable), sabemos que el puerto es efectivamente `closed`.

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -sU -Pn -n --disable-arp-ping --packet-trace -p 100 --reason 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 16:25 CEST
SENT (0.0445s) UDP 10.10.14.2:63825 > 10.129.2.28:100 ttl=57 id=29925 iplen=28
RCVD (0.1498s) ICMP [10.129.2.28 > 10.10.14.2 Port unreachable (type=3/code=3) ] IP [ttl=64 id=11903 iplen=56 ]
Nmap scan report for 10.129.2.28
Host is up, received user-set (0.11s latency).

PORT    STATE  SERVICE REASON
100/udp closed unknown port-unreach ttl 64
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in  0.15 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-sU`|Realiza un escaneo UDP.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-p 100`|Escanea sólo el puerto especificado.|
|`--reason`|Muestra el motivo por el cual un puerto se encuentra en un estado particular.|

---

Para todas las demás respuestas ICMP, los puertos escaneados están marcados como (`open|filtered`).

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -sU -Pn -n --disable-arp-ping --packet-trace -p 138 --reason 

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-15 16:32 CEST
SENT (0.0380s) UDP 10.10.14.2:52341 > 10.129.2.28:138 ttl=50 id=65159 iplen=28
SENT (1.0392s) UDP 10.10.14.2:52342 > 10.129.2.28:138 ttl=40 id=24444 iplen=28
Nmap scan report for 10.129.2.28
Host is up, received user-set.

PORT    STATE         SERVICE     REASON
138/udp open|filtered netbios-dgm no-response
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 2.06 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-sU`|Realiza un escaneo UDP.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-p 138`|Escanea sólo el puerto especificado.|
|`--reason`|Muestra el motivo por el cual un puerto se encuentra en un estado particular.|

Otro método útil para escanear puertos es el `-sV` opción que se utiliza para obtener información adicional disponible de los puertos abiertos. Este método puede identificar versiones, nombres de servicios y detalles sobre nuestro objetivo.

#### Escaneo de versiones

  Escaneo de host y puerto

```shell-session
Kronno23@htb[/htb]$ sudo nmap 10.129.2.28 -Pn -n --disable-arp-ping --packet-trace -p 445 --reason  -sV

Starting Nmap 7.80 ( https://nmap.org ) at 2022-11-04 11:10 GMT
SENT (0.3426s) TCP 10.10.14.2:44641 > 10.129.2.28:445 S ttl=55 id=43401 iplen=44  seq=3589068008 win=1024 <mss 1460>
RCVD (0.3556s) TCP 10.129.2.28:445 > 10.10.14.2:44641 SA ttl=63 id=0 iplen=44  seq=2881527699 win=29200 <mss 1337>
NSOCK INFO [0.4980s] nsock_iod_new2(): nsock_iod_new (IOD #1)
NSOCK INFO [0.4980s] nsock_connect_tcp(): TCP connection requested to 10.129.2.28:445 (IOD #1) EID 8
NSOCK INFO [0.5130s] nsock_trace_handler_callback(): Callback: CONNECT SUCCESS for EID 8 [10.129.2.28:445]
Service scan sending probe NULL to 10.129.2.28:445 (tcp)
NSOCK INFO [0.5130s] nsock_read(): Read request from IOD #1 [10.129.2.28:445] (timeout: 6000ms) EID 18
NSOCK INFO [6.5190s] nsock_trace_handler_callback(): Callback: READ TIMEOUT for EID 18 [10.129.2.28:445]
Service scan sending probe SMBProgNeg to 10.129.2.28:445 (tcp)
NSOCK INFO [6.5190s] nsock_write(): Write request for 168 bytes to IOD #1 EID 27 [10.129.2.28:445]
NSOCK INFO [6.5190s] nsock_read(): Read request from IOD #1 [10.129.2.28:445] (timeout: 5000ms) EID 34
NSOCK INFO [6.5190s] nsock_trace_handler_callback(): Callback: WRITE SUCCESS for EID 27 [10.129.2.28:445]
NSOCK INFO [6.5320s] nsock_trace_handler_callback(): Callback: READ SUCCESS for EID 34 [10.129.2.28:445] (135 bytes)
Service scan match (Probe SMBProgNeg matched with SMBProgNeg line 13836): 10.129.2.28:445 is netbios-ssn.  Version: |Samba smbd|3.X - 4.X|workgroup: WORKGROUP|
NSOCK INFO [6.5320s] nsock_iod_delete(): nsock_iod_delete (IOD #1)
Nmap scan report for 10.129.2.28
Host is up, received user-set (0.013s latency).

PORT    STATE SERVICE     REASON         VERSION
445/tcp open  netbios-ssn syn-ack ttl 63 Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
Service Info: Host: Ubuntu

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 6.55 seconds
```

|**Opciones de escaneo**|**Descripción**|
|---|---|
|`10.129.2.28`|Escanea el objetivo especificado.|
|`-Pn`|Deshabilita las solicitudes ICMP Echo.|
|`-n`|Desactiva la resolución de DNS.|
|`--disable-arp-ping`|Desactiva el ping ARP.|
|`--packet-trace`|Muestra todos los paquetes enviados y recibidos.|
|`-p 445`|Escanea sólo el puerto especificado.|
|`--reason`|Muestra el motivo por el cual un puerto se encuentra en un estado particular.|
|`-sV`|Realiza un escaneo de servicio.|

Puede encontrar más información sobre las técnicas de escaneo de puertos en: [https://nmap.org/book/man-port-scanning-techniques.html](https://nmap.org/book/man-port-scanning-techniques.html)