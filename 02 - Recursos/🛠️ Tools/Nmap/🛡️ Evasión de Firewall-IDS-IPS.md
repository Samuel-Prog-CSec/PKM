[[💻 Nmap1]] ==nos ofrece muchas formas distintas de eludir== las reglas de los cortafuegos y de los sistemas IDS/IPS. Entre estos métodos se encuentran la **fragmentación de paquetes**, el **uso de señuelos** **y otros** que se analizarán en esta sección.


# Firewalls
Un **firewall** es una medida de **seguridad contra intentos de conexión no autorizados** desde redes externas. Todo sistema de seguridad de firewall se basa en un componente de ==software que supervisa el tráfico de red entre el firewall y las conexiones de datos entrantes== y decide cómo manejar la conexión en función de las **reglas** que se hayan establecido. ==Comprueba si se están transmitiendo, ignorando o bloqueando paquetes de red individuales==. Este mecanismo está diseñado para evitar conexiones no deseadas que podrían ser potencialmente peligrosas.


# IDS/IPS
El **sistema de detección de intrusiones (IDS)** y el **sistema de prevención de intrusiones (IPS)** también son componentes basados ​​en software. El **IDS** ==escanea la red en busca de posibles ataques==, los analiza e informa de los ataques detectados. El **IPS** complementa al IDS al tomar ==medidas defensivas específicas si se hubiera detectado un posible ataque==. El análisis de dichos ataques se basa en la **comparación de patrones y firmas**. Si se detectan patrones específicos, como un escaneo de detección de servicios, el IPS puede evitar los intentos de conexión pendientes.


## Determinar los firewalls y sus reglas
Ya sabemos que cuando **un puerto se muestra como filtrado**, puede deberse a varias razones. En la mayoría de los casos, los firewalls tienen determinadas reglas establecidas para gestionar conexiones específicas. Los **paquetes pueden descartarse o rechazarse**. ==Los paquetes descartados se ignoran y no se devuelve ninguna respuesta del host==. 
Esto es diferente para los paquetes rechazados que se devuelven con un indicador `RST`. Estos paquetes ==contienen distintos tipos de códigos de error ICMP o no contienen nada en absoluto==. Estos **errores ICMP** pueden ser:
- **Net Unreachable**
- **Net Prohibited**
- **Host Unreachable**
- **Host Prohibited**
- **Port Unreachable**
- **Proto Unreachable**

El método de escaneo **TCP ACK** (`-sA`) de Nmap **es mucho más difícil de filtrar para los cortafuegos y los sistemas IDS/IPS** que los escaneos **SYN** (`-sS`) o **Connect** (`-sT`), ya que ==solo envían un paquete TCP con el indicador ACK==. Cuando un puerto está cerrado o abierto, el host debe responder con un indicador RST. 

A diferencia de las conexiones salientes, todos los intentos de conexión (con el indicador **SYN**) desde redes externas ==suelen ser bloqueados por los cortafuegos==. 
Sin embargo, los paquetes con el indicador **ACK** ==suelen ser pasados ​​por el cortafuegos== porque este no puede determinar si la conexión se estableció primero desde la red externa o la red interna.


### SYN-Scan:
```shell
sudo nmap 10.129.2.28 -p 21,22,25 -sS -Pn -n --disable-arp-ping --packet-trace

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-21 14:56 CEST
SENT (0.0278s) TCP 10.10.14.2:57347 > 10.129.2.28:22 S ttl=53 id=22412 iplen=44  seq=4092255222 win=1024 <mss 1460>
SENT (0.0278s) TCP 10.10.14.2:57347 > 10.129.2.28:25 S ttl=50 id=62291 iplen=44  seq=4092255222 win=1024 <mss 1460>
SENT (0.0278s) TCP 10.10.14.2:57347 > 10.129.2.28:21 S ttl=58 id=38696 iplen=44  seq=4092255222 win=1024 <mss 1460>
RCVD (0.0329s) ICMP [10.129.2.28 > 10.10.14.2 Port 21 unreachable (type=3/code=3) ] IP [ttl=64 id=40884 iplen=72 ]
RCVD (0.0341s) TCP 10.129.2.28:22 > 10.10.14.2:57347 SA ttl=64 id=0 iplen=44  seq=1153454414 win=64240 <mss 1460>
RCVD (1.0386s) TCP 10.129.2.28:22 > 10.10.14.2:57347 SA ttl=64 id=0 iplen=44  seq=1153454414 win=64240 <mss 1460>
SENT (1.1366s) TCP 10.10.14.2:57348 > 10.129.2.28:25 S ttl=44 id=6796 iplen=44  seq=4092320759 win=1024 <mss 1460>
Nmap scan report for 10.129.2.28
Host is up (0.0053s latency).

PORT   STATE    SERVICE
21/tcp filtered ftp
22/tcp open     ssh
25/tcp filtered smtp
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```


### ACK-Scan:
```shell
sudo nmap 10.129.2.28 -p 21,22,25 -sA -Pn -n --disable-arp-ping --packet-trace

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-21 14:57 CEST
SENT (0.0422s) TCP 10.10.14.2:49343 > 10.129.2.28:21 A ttl=49 id=12381 iplen=40  seq=0 win=1024
SENT (0.0423s) TCP 10.10.14.2:49343 > 10.129.2.28:22 A ttl=41 id=5146 iplen=40  seq=0 win=1024
SENT (0.0423s) TCP 10.10.14.2:49343 > 10.129.2.28:25 A ttl=49 id=5800 iplen=40  seq=0 win=1024
RCVD (0.1252s) ICMP [10.129.2.28 > 10.10.14.2 Port 21 unreachable (type=3/code=3) ] IP [ttl=64 id=55628 iplen=68 ]
RCVD (0.1268s) TCP 10.129.2.28:22 > 10.10.14.2:49343 R ttl=64 id=0 iplen=40  seq=1660784500 win=0
SENT (1.3837s) TCP 10.10.14.2:49344 > 10.129.2.28:25 A ttl=59 id=21915 iplen=40  seq=0 win=1024
Nmap scan report for 10.129.2.28
Host is up (0.083s latency).

PORT   STATE      SERVICE
21/tcp filtered   ftp
22/tcp unfiltered ssh
25/tcp filtered   smtp
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.15 seconds
```

___
- Con el escaneo **SYN** (`-sS`), nuestro objetivo intenta establecer la conexión TCP enviando un paquete de vuelta con los indicadores **SYN-ACK** (`SA`) establecidos. 
- Con el escaneo **ACK** (`-sA`) obtenemos el indicador `RST` ==porque el puerto TCP 22 está abierto==. Para el puerto TCP 25, no recibimos ningún paquete de vuelta, lo que indica que los paquetes se descartarán.
___


## Detectar IDS/IPS
Los sistemas **IDS** ==examinan todas las conexiones entre hosts==. Si el IDS encuentra paquetes que contienen los contenidos o especificaciones definidos, se notifica al administrador y se toman las medidas adecuadas en el peor de los casos.

Los sistemas **IPS** ==toman medidas configuradas por el administrador de forma independiente para prevenir ataques potenciales de forma automática==

Se recomiendan varios **servidores privados virtuales (VPS)** ==con diferentes direcciones IP para determinar si dichos sistemas están en la red objetivo durante una prueba de penetración==. Si el administrador detecta un ataque potencial de este tipo en la red objetivo, el primer paso es bloquear la dirección IP desde la que proviene el ataque potencial. 

- **Podemos activar ciertas medidas de seguridad por parte de un administrador**, por ejemplo, escaneando agresivamente un único puerto y su servicio. En función de si se toman medidas de seguridad específicas, ==podemos detectar si la red tiene alguna aplicación de monitorización o no==.

- Un método para determinar si dicho sistema IPS está presente en la red de destino es **escanear desde un único host (VPS)**. ==Si en algún momento este host está bloqueado y no tiene acceso a la red de destino, sabemos que el administrador ha tomado algunas medidas de seguridad==. En consecuencia, podemos continuar nuestra prueba de penetración con otro VPS.


# Decoys (señuelos)
Con este método, **Nmap genera varias direcciones IP aleatorias insertadas en el encabezado IP para disfrazar el origen del paquete enviado**. Con este método (`-D`), podemos generar aleatoriamente (`RND`) un número específico (por ejemplo: `5`) de direcciones IP separadas por dos puntos (`:`). ==Nuestra dirección IP real se coloca entonces aleatoriamente entre las direcciones IP generadas==. Otro punto crítico es que **los señuelos deben estar activos**. De lo contrario, el servicio en el objetivo puede ser inaccesible debido a los mecanismos de seguridad de inundación `SYN`.

```shell
sudo nmap 10.129.2.28 -p 80 -sS -Pn -n --disable-arp-ping --packet-trace -D RND:5

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-21 16:14 CEST
SENT (0.0378s) TCP 102.52.161.59:59289 > 10.129.2.28:80 S ttl=42 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
SENT (0.0378s) TCP 10.10.14.2:59289 > 10.129.2.28:80 S ttl=59 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
SENT (0.0379s) TCP 210.120.38.29:59289 > 10.129.2.28:80 S ttl=37 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
SENT (0.0379s) TCP 191.6.64.171:59289 > 10.129.2.28:80 S ttl=38 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
SENT (0.0379s) TCP 184.178.194.209:59289 > 10.129.2.28:80 S ttl=39 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
SENT (0.0379s) TCP 43.21.121.33:59289 > 10.129.2.28:80 S ttl=55 id=29822 iplen=44  seq=3687542010 win=1024 <mss 1460>
RCVD (0.1370s) TCP 10.129.2.28:80 > 10.10.14.2:59289 SA ttl=64 id=0 iplen=44  seq=4056111701 win=64240 <mss 1460>
Nmap scan report for 10.129.2.28
Host is up (0.099s latency).

PORT   STATE SERVICE
80/tcp open  http
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.15 seconds
```
==Los ISP y los enrutadores suelen filtrar los paquetes falsificados==, aunque provengan del mismo rango de red. Por lo tanto, también podemos especificar las direcciones IP de nuestros servidores VPS y usarlas en combinación con la manipulación de "*ID de IP*" en los encabezados de IP para escanear el objetivo. 
Otro escenario sería que solo las subredes individuales no tuvieran acceso a los servicios específicos del servidor. Por lo tanto, **también podemos especificar manualmente la dirección IP de origen** (`-S`) para probar si obtenemos mejores resultados con este. 
**Los señuelos se pueden utilizar para escaneos `SYN`, `ACK`, `ICMP` y de `detección de SO`**. 

## Escanear utilizando diferente IP de origen
**Primer escaneo**:

```shell
sudo nmap 10.129.2.28 -n -Pn -p445 -O

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-22 01:23 CEST
Nmap scan report for 10.129.2.28
Host is up (0.032s latency).

PORT    STATE    SERVICE
445/tcp filtered microsoft-ds
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)
Too many fingerprints match this host to give specific OS details
Network Distance: 1 hop

OS detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 3.14 seconds
```

**Suponemos que hay un firewall así que vamos a cambiar la dirección IP de origen**:

```shell
sudo nmap 10.129.2.28 -n -Pn -p 445 -O -S 10.129.2.200 -e tun0

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-22 01:16 CEST
Nmap scan report for 10.129.2.28
Host is up (0.010s latency).

PORT    STATE SERVICE
445/tcp open  microsoft-ds
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Aggressive OS guesses: Linux 2.6.32 (96%), Linux 3.2 - 4.9 (96%), Linux 2.6.32 - 3.10 (96%), Linux 3.4 - 3.10 (95%), Linux 3.1 (95%), Linux 3.2 (95%), AXIS 210A or 211 Network Camera (Linux 2.6.17) (94%), Synology DiskStation Manager 5.2-5644 (94%), Linux 2.6.32 - 2.6.35 (94%), Linux 2.6.32 - 3.5 (94%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 1 hop

OS detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 4.11 seconds
```
==**Nota**: Se envían todas las solicitudes a través de la interfaz especificada (`-e tun0`).==


# DNS Proxying
De forma predeterminada, **Nmap realiza una resolución DNS inversa** a menos que se especifique lo contrario para encontrar información más importante sobre nuestro objetivo. ==Estas consultas DNS también se pasan en la mayoría de los casos== porque se supone que se debe encontrar y visitar el servidor web en cuestión. **Las consultas DNS se realizan a través del puerto UDP 53**. El **puerto TCP 53** se utilizaba anteriormente ==solo para las denominadas "transferencias de zona" entre los servidores DNS o la transferencia de datos de más de 512 bytes==. Esto está cambiando cada vez más debido a las ampliaciones de **IPv6** y **DNSSEC**. Estos cambios hacen que **muchas solicitudes DNS se realicen a través del puerto TCP 53**.

Sin embargo, **Nmap todavía nos ofrece una forma de especificar servidores DNS nosotros mismos** (`--dns-server <ns>,<ns>`). Este método podría ser fundamental para nosotros si estamos en una zona desmilitarizada (DMZ). ==Los servidores DNS de la empresa suelen ser más fiables que los de Internet==. Por lo tanto, por ejemplo, **podríamos usarlos para interactuar con los hosts de la red interna**. 
**Podemos utilizar el puerto TCP 53 como puerto de origen** (`--source-port`) para nuestros análisis. ==Si el administrador utiliza el firewall para controlar este puerto y no filtra los IDS/IPS correctamente, nuestros paquetes TCP serán confiables y pasarán.==


## SYN-Scan de un puerto filtrado
```shell
sudo nmap 10.129.2.28 -p50000 -sS -Pn -n --disable-arp-ping --packet-trace

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-21 22:50 CEST
SENT (0.0417s) TCP 10.10.14.2:33436 > 10.129.2.28:50000 S ttl=41 id=21939 iplen=44  seq=736533153 win=1024 <mss 1460>
SENT (1.0481s) TCP 10.10.14.2:33437 > 10.129.2.28:50000 S ttl=46 id=6446 iplen=44  seq=736598688 win=1024 <mss 1460>
Nmap scan report for 10.129.2.28
Host is up.

PORT      STATE    SERVICE
50000/tcp filtered ibm-db2

Nmap done: 1 IP address (1 host up) scanned in 2.06 seconds
```


## SYN-Scan desde el puerto DNS
```shell
sudo nmap 10.129.2.28 -p50000 -sS -Pn -n --disable-arp-ping --packet-trace --source-port 53

SENT (0.0482s) TCP 10.10.14.2:53 > 10.129.2.28:50000 S ttl=58 id=27470 iplen=44  seq=4003923435 win=1024 <mss 1460>
RCVD (0.0608s) TCP 10.129.2.28:50000 > 10.10.14.2:53 SA ttl=64 id=0 iplen=44  seq=540635485 win=64240 <mss 1460>
Nmap scan report for 10.129.2.28
Host is up (0.013s latency).

PORT      STATE SERVICE
50000/tcp open  ibm-db2
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)

Nmap done: 1 IP address (1 host up) scanned in 0.08 seconds
```
Ahora que **hemos descubierto que el firewall acepta el puerto TCP 53**, es ==muy probable que los filtros IDS/IPS también estén configurados de forma mucho más débil que otros==. Podemos comprobarlo intentando conectarnos a este puerto mediante `Netcat`.


## Conectarse al puerto filtrado
```shell
ncat -nv --source-port 53 10.129.2.28 50000

Ncat: Version 7.80 ( https://nmap.org/ncat )
Ncat: Connected to 10.129.2.28:50000.
220 ProFTPd
```