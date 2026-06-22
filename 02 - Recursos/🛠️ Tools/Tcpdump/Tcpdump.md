`Tcpdump` es un rastreador de paquetes de línea de comandos que puede capturar e interpretar directamente  datos desde un archivo o una interfaz de red. Fue creado para usarse en cualquier sistema operativo tipo Unix y tenía un gemelo de Windows llamado `WinDump` (el apoyo a esta herramienta ha cesado). Es una herramienta potente y sencilla que se utiliza en la mayoría de los sistemas basados en Unix. 

No requiere GUI y se puede utilizar a través de cualquier terminal o conexión remota, como [[SSH]]. Sin embargo, esta herramienta puede parecer abrumadora al principio debido a las diferentes funciones y filtros que nos ofrece. Sin embargo, una vez que aprendamos las funciones esenciales, nos resultará mucho más fácil utilizar esta herramienta de manera eficiente. Para la captura y el [[Análisis del tráfico de red]], utiliza las bibliotecas `pcap` y `libpcap`, emparejado con una interfaz en modo promiscuo para escuchar datos. Esto permite que el programa vea y capture paquetes que provienen o están destinados a cualquier dispositivo en la red de área local, no solo los paquetes destinados a nosotros.

> [!todo]
> Debido al acceso directo al hardware, necesitamos privilegios de `root` o del `administrator` para ejecutar esta herramienta. 

---

# Capturas de tráfico con Tcpdump
A continuación se muestra una tabla de parámetros Tcpdump básicos que podemos usar para modificar cómo se ejecutan nuestras capturas. Estos parámetros se pueden encadenar para crear cómo se nos muestra la salida de la herramienta en `STDOUT` y qué se guarda en el archivo de captura. Esta no es una lista exhaustiva y hay muchas más que podemos utilizar, pero estas son las más comunes y valiosas. Después, se muestran algunos ejemplos de ejecución de algunos comandos.

| **Cambiar comando** | **Resultado**                                                                                                                        |
| :-----------------: | ------------------------------------------------------------------------------------------------------------------------------------ |
|        `-D`         | Mostrará todas las interfaces disponibles para capturar.                                                                             |
|        `-i`         | Selecciona una interfaz para capturar desde ella.                                                                                    |
|        `-n`         | No convertir direcciones (es decir, direcciones de host, números de puerto, etc.) en nombres.                                        |
|        `-e`         | Tomará el encabezado Ethernet junto con los datos de la capa superior.                                                               |
|        `-X`         | Mostrar contenido de paquetes en hexadecimal y ASCII.                                                                                |
|        `-XX`        | Igual que X, pero también especificará encabezados Ethernet. (como usar Xe)                                                          |
| `-v`, `-vv`, `-vvv` | Aumente la verbosidad de la salida mostrada y guardada.                                                                              |
|        `-c`         | Obtener una cantidad específica de paquetes y luego salir del programa.                                                              |
|        `-s`         | Define cuántos paquete tomar.                                                                                                        |
|        `-S`         | Cambiar los números de secuencia relativos en la pantalla de captura a números de secuencia absolutos. (13248765839 en lugar de 101) |
|        `-q`         | Imprimir menos información del protocolo.                                                                                            |
|  `-r archivo.pcap`  | Leer desde un archivo.                                                                                                               |
|  `-w archivo.pcap`  | Escribir en un archivo.                                                                                                              |

## Listado de interfaces disponibles
```shell-session
$ sudo tcpdump -D

1.eth0 [Up, Running, Connected]
2.any (Pseudo-device that captures on all interfaces) [Up, Running]
3.lo [Up, Running, Loopback]
4.bluetooth0 (Bluetooth adapter number 0) [Wireless, Association status unknown]
5.bluetooth-monitor (Bluetooth Linux Monitor) [Wireless]
6.nflog (Linux netfilter log (NFLOG) interface) [none]
7.nfqueue (Linux netfilter queue (NFQUEUE) interface) [none]
8.dbus-system (D-Bus system bus) [none]
9.dbus-session (D-Bus session bus) [none]
```

## Elegir una interfaz y deshabilitar la resolución de nombres
```shell-session
$ sudo tcpdump -i eth0 -nn

tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:02:35.580449 IP 172.16.146.2.48402 > 52.31.199.148.443: Flags [P.], seq 988167196:988167233, ack 1512376150, win 501, options [nop,nop,TS val 214282239 ecr 77421665], length 37
11:02:35.588695 IP 172.16.146.2.55272 > 172.67.1.1.443: Flags [P.], seq 940648841:940648916, ack 4248406693, win 501, length 75
11:02:35.654368 IP 172.67.1.1.443 > 172.16.146.2.55272: Flags [.], ack 75, win 70, length 0
11:02:35.728889 IP 52.31.199.148.443 > 172.16.146.2.48402: Flags [P.], seq 1:34, ack 37, win 118, options [nop,nop,TS val 77434740 ecr 214282239], length 33
11:02:35.728988 IP 172.16.146.2.48402 > 52.31.199.148.443: Flags [.], ack 34, win 501, options [nop,nop,TS val 214282388 ecr 77434740], length 0
11:02:35.729073 IP 52.31.199.148.443 > 172.16.146.2.48402: Flags [P.], seq 34:65, ack 37, win 118, options [nop,nop,TS val 77434740 ecr 214282239], length 31
11:02:35.729081 IP 172.16.146.2.48402 > 52.31.199.148.443: Flags [.], ack 65, win 501, options [nop,nop,TS val 214282388 ecr 77434740], length 0
11:02:35.729348 IP 52.31.199.148.443 > 172.16.146.2.48402: Flags [F.], seq 65, ack 37, win 118, options [nop,nop,TS val 77434740 ecr 214282239], length 0
```

> [!help]
> Una vez que emitimos el comando, tcpdump comenzará a detectar el tráfico y verá los primeros paquetes en la interfaz. Al introducir el `-nn`, le indicamos que se abstenga de resolver direcciones IP y números de puerto en sus nombres de host y nombres de puerto comunes. En esta representación, <mark style="background: #FF5582A6;">el último octeto es el puerto desde/hacia el que va la conexión</mark>.

## Incluir salida ASCII y hexadecimal (y mas verbosidad)
```shell-session
$ sudo tcpdump -i eth0 -nnvXX

tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:13:59.149599 IP (tos 0x0, ttl 64, id 24075, offset 0, flags [DF], proto TCP (6), length 89)
    172.16.146.2.42454 > 54.77.251.34.443: Flags [P.], cksum 0x6fce (incorrect -> 0xb042), seq 671020720:671020757, ack 3699222968, win 501, options [nop,nop,TS val 1154433101 ecr 1116647414], length 37
    0x0000:  8a66 5a11 8d64 000c 2997 5265 0800 4500  .fZ..d..).Re..E.
    0x0010:  0059 5e0b 4000 4006 6d11 ac10 9202 364d  .Y^.@.@.m.....6M
    0x0020:  fb22 a5d6 01bb 27fe f6b0 dc7d a9b8 8018  ."....'....}....
    0x0030:  01f5 6fce 0000 0101 080a 44cf 404d 428e  ..o.......D.@MB.
    0x0040:  aff6 1703 0300 2000 0000 0000 0000 09bb  ................
    0x0050:  38d9 d89a 2d70 73d5 a01e 9df7 2c48 5b8a  8...-ps.....,H[.
    0x0060:  d64d 8e42 2ccc 43                        .M.B,.C
11:13:59.157113 IP (tos 0x0, ttl 64, id 31823, offset 0, flags [DF], proto UDP (17), length 63)
    172.16.146.2.55351 > 172.16.146.1.53: 26460+ A? app.hackthebox.eu. (35)
    0x0000:  8a66 5a11 8d64 000c 2997 5265 0800 4500  .fZ..d..).Re..E.
    0x0010:  003f 7c4f 4000 4011 423a ac10 9202 ac10  .?|O@.@.B:......
    0x0020:  9201 d837 0035 002b 7c61 675c 0100 0001  ...7.5.+|ag\....
    0x0030:  0000 0000 0000 0361 7070 0a68 6163 6b74  .......app.hackt
    0x0040:  6865 626f 7802 6575 0000 0100 01         hebox.eu.....
11:13:59.158029 IP (tos 0x0, ttl 64, id 20784, offset 0, flags [none], proto UDP (17), length 111)
    172.16.146.1.53 > 172.16.146.2.55351: 26460 3/0/0 app.hackthebox.eu. A 104.20.55.68, app.hackthebox.eu. A 172.67.1.1, app.hackthebox.eu. A 104.20.66.68 (83)
    0x0000:  000c 2997 5265 8a66 5a11 8d64 0800 4500  ..).Re.fZ..d..E.
    0x0010:  006f 5130 0000 4011 ad29 ac10 9201 ac10  .oQ0..@..)......
    0x0020:  9202 0035 d837 005b 9d2e 675c 8180 0001  ...5.7.[..g\....
    0x0030:  0003 0000 0000 0361 7070 0a68 6163 6b74  .......app.hackt
    0x0040:  6865 626f 7802 6575 0000 0100 01c0 0c00  hebox.eu........
    0x0050:  0100 0100 0000 ab00 0468 1437 44c0 0c00  .........h.7D...
    0x0060:  0100 0100 0000 ab00 04ac 4301 01c0 0c00  ..........C.....
    0x0070:  0100 0100 0000 ab00 0468 1442 44         .........h.BD
11:13:59.158335 IP (tos 0x0, ttl 64, id 20242, offset 0, flags [DF], proto TCP (6), length 60)
    172.16.146.2.55416 > 172.67.1.1.443: Flags [S], cksum 0xeb85 (incorrect -> 0x72f7), seq 3766489491, win 64240, options [mss 1460,sackOK,TS val 508232750 ecr 0,nop,wscale 7], length 0
    0x0000:  8a66 5a11 8d64 000c 2997 5265 0800 4500  .fZ..d..).Re..E.
    0x0010:  003c 4f12 4000 4006 0053 ac10 9202 ac43  .<O.@.@..S.....C
    0x0020:  0101 d878 01bb e080 1193 0000 0000 a002  ...x............
    0x0030:  faf0 eb85 0000 0204 05b4 0402 080a 1e4b  ...............K
    0x0040:  042e 0000 0000 0103 0307                 ..........
```

> [!important]
> Al incluir el `-X`, ahora podemos ver el paquete un poco más claro. Obtenemos una salida ASCII a la derecha para interpretar cualquier cosa en texto claro que corresponda a la salida hexadecimal de la izquierda.
> También podemos notar que tenemos información sobre las opciones del encabezado IP, como tiempo de vida, desplazamiento y otros indicadores, y más detalles sobre los protocolos de la capa superior, gracias a incluir mas verbosidad con `-v`

---

# Interpretar salida de Tcpdump
Al observar la salida de `tcpdump`, puede resultar un poco abrumadora. La imagen y la tabla de a continuación definirán cada campo.

## Desglose del shell de Tcpdump
![Captura de paquetes de red que muestra la comunicación FTP entre las IP 172.16.146.2 y 172.16.146.1, incluido el mensaje de bienvenida y la solicitud de contraseña.](https://academy.hackthebox.com/storage/modules/81/breakdown.png)

| **Filtro**                                | **Resultado**                                                                                                                                                                                                                                                                                                                                                |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ==Marca de tiempo==                       | **Amarillo**: El campo de marca de tiempo viene primero y se puede configurar para mostrar la hora y la fecha en un formato que podamos ingerir fácilmente.                                                                                                                                                                                                  |
| ==Protocolo==                             | **Naranja**: Esta sección nos dirá qué es el encabezado de la capa superior. En el ejemplo, muestra IP.                                                                                                                                                                                                                                                      |
| ==Origen y destino (`IP.Port`)==          | **Naranja**: Esto nos mostrará el origen y el destino del paquete junto con el número de puerto utilizado para conectarnos. Formato => `IP.port` *==* `172.16.146.2.21`                                                                                                                                                                                      |
| ==Flags==                                 | **Verde**: Esta parte muestra las flags utilizadas.                                                                                                                                                                                                                                                                                                          |
| ==Números de secuencia y reconocimiento== | **Rojo**: Esta sección muestra la secuencia y los números de reconocimiento utilizados para rastrear el segmento *TCP*. Nuestro ejemplo utiliza números bajos para suponer que se muestran números de secuencia relativa y *ack*.                                                                                                                            |
| ==Opciones de protocolo==                 | **Azul**: veremos cualquier valor *TCP* negociado establecido entre el cliente y el servidor, como tamaño de ventana, reconocimientos selectivos, factores de escala de ventana y más.                                                                                                                                                                       |
| ==Notas / Siguiente encabezado==          | **Blanco**: Notas varias: el disector encontrado estará presente aquí. Como el tráfico que estamos viendo está encapsulado, es posible que veamos más información de encabezado para diferentes protocolos. En nuestro ejemplo, podemos ver que el disector TCPDump reconoce el tráfico [[📂🔄 FTP]] dentro de la encapsulación para mostrarlo por nosotros. |

Hay muchas otras opciones e información que se pueden mostrar. Esta información varía según la cantidad de verbosidad habilitada. Para obtener una comprensión más detallada de IP y otros encabezados de protocolo, se pueden consultar los protocolos definidos en [[Protocolos de red]].

> [!info]
> Teóricamente, podemos utilizar `tcpdump` crear un sistema *IDS/IPS* haciendo que un script [[🐧⚔️ Bash Scripting]] analice los paquetes interceptados según un patrón específico. Luego podemos establecer condiciones para, por ejemplo, prohibir una dirección *IP* particular que haya enviado demasiadas solicitudes de eco *ICMP* durante un período determinado.