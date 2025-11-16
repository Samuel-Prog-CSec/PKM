---
tags:
  - "#Windows"
  - "#Linux"
  - Escaneo/Redes
Fecha de actualización: 2025-07-30
Nota siguiente: "[[Uso avanzado de Wireshark]]"
Area: "[[Análisis del tráfico de red]]"
---
---

`Wireshark` es un analizador de [[Análisis del tráfico de red | tráfico de red]] gratuito y de código abierto muy parecido a [[Tcpdump]] pero con una interfaz gráfica. Wireshark es multiplataforma y capaz de capturar datos en vivo desde muchos tipos de interfaces diferentes (incluidos *WiFi*, *USB* y *Bluetooth*) y guardar el tráfico en varios formatos diferentes. Permite al usuario profundizar mucho más en la inspección de paquetes de red que otras herramientas. Lo que hace que Wireshark sea verdaderamente poderoso es la capacidad de análisis que proporciona, brindando una visión detallada del tráfico.

> [!attention]
> Dependiendo del host que estemos usando, es posible que no siempre tengamos una GUI para utilizar Wireshark tradicional. Por suerte para nosotros, hay variantes que nos permiten utilizarlo desde la línea de comandos.

# Características y capacidades
- Inspección profunda de paquetes para cientos de [[Protocolos de red]] diferentes para un [[Proceso de análisis]] más profundo.
- Interfaces gráficas y TTY
- Capaz de ejecutarse en la mayoría de los sistemas operativos
- Ethernet, IEEE 802.11, PPP/HDLC, ATM, Bluetooth, USB, Token Ring, Frame Relay, FDDI, entre otros
- Capacidades de descifrado para IPsec, ISAKMP, Kerberos, SNMPv3, SSL/TLS, WEP y WPA/WPA2
- Muchos muchos más...

---

# Requisitos de uso
## Windows
- El tiempo de ejecución universal de C. Esto está incluido con Windows 10 y Windows Server 2019 y se instala automáticamente en versiones anteriores si Microsoft Windows Update está habilitado. De lo contrario, se debe instalar KB2999226 o KB3118401.
- Cualquier procesador moderno AMD64/x86-64 o x86 de 64 bits.
- 500 MB de RAM disponible. Los archivos de captura más grandes requieren más RAM.
- 500 MB de espacio en disco disponible. La captura de archivos requiere espacio adicional en disco.
- Cualquier pantalla moderna. Se recomienda una resolución de 1280 × 1024 o superior. Wireshark utilizará resoluciones HiDPI o Retina si están disponibles. Los usuarios avanzados encontrarán útiles varios monitores.
- Una tarjeta de red compatible para capturar:
    - Ethernet. Cualquier tarjeta compatible con Windows debería funcionar.
    - 802.11. Consulte la página wiki de Wireshark. Capturar información 802.11 sin procesar puede resultar difícil sin un equipo especial.
- Para instalar, descargue el ejecutable desde [su pagina web](https://www.wireshark.org/), valide el hash e instálelo.

## Linux
- Wireshark se ejecuta en la mayoría de las plataformas UNIX y similares, incluidas Linux y la mayoría de las variantes BSD. Los requisitos del sistema deben ser comparables a las especificaciones enumeradas anteriormente para Windows.
- Los paquetes binarios están disponibles para la mayoría de las distribuciones de Unix y Linux.
- Para validar si el paquete existe en un host, se puede utilizar el siguiente comando: `which wireshark`

---

# TShark vs. Wireshark (Terminal vs. GUI)
Ambas opciones tienen sus méritos. **TShark** es una herramienta de terminal basada en Wireshark. TShark comparte muchas de las mismas características que se incluyen en Wireshark e incluso comparte sintaxis y opciones. 

TShark es perfecto para usar en máquinas con poco o ningún entorno de escritorio y puede pasar fácilmente la información de captura que recibe a otra herramienta a través de la línea de comandos. Wireshark es la opción GUI rica en funciones para la captura y análisis de tráfico. Si desea tener la experiencia completa y trabajar desde una máquina con un entorno de escritorio, la GUI de Wireshark es el camino a seguir.

## Parámetros básicos de TShark

| **Cambiar comando** | **Resultado**                                                                                                                                               |
| :-----------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|        `-D`         | Mostrará todas las interfaces disponibles para capturar y luego salir.                                                                                      |
|        `-L`         | Enumerará los medios de **capa de enlace** desde los que puede capturar y luego salir.                                                                      |
|        `-i`         | Elija una interfaz desde la que capturar.                                                                                                                   |
|        `-f`         | Filtro de paquetes en sintaxis *libpcap*. Utilizado durante la captura.                                                                                     |
|        `-c`         | Obtenga una cantidad específica de paquetes y luego salga del programa. Define una condición de parada.                                                     |
|        `-a`         | Define una condición de parada automática. Puede ser después de una duración, un tamaño de archivo específico o después de una cierta cantidad de paquetes. |
| `-r <archivo pcap>` | Leer desde un archivo.                                                                                                                                      |
| `-W <archivo pcap>` | Escriba en un archivo usando el formato *pcapng*.                                                                                                           |
|        `-P`         | Imprimirá el resumen del paquete mientras escribe en un archivo.                                                                                            |
|        `-x`         | Agregará salida hexadecimal y ASCII a la captura.                                                                                                           |
|        `-h`         | Ver el menú de ayuda.                                                                                                                                       |

### Uso básico de TShark
TShark puede utilizar filtros para protocolos, elementos comunes como hosts y puertos, e incluso la capacidad de profundizar en los paquetes y diseccionar campos individuales del paquete.

#### Captura de tráfico con TShark
```shell-session
$ which tshark

$ tshark -D

$ tshark -i 1 -w /tmp/test.pcap

Capturing on 'Wi-Fi: en0'
484
```
> [!info]
> Para capturar en `en0`, especificado con el `-i` y la `-w` para guardar la captura en un archivo de salida específico. El uso de TShark es muy similar a [[Tcpdump]] en los filtros y parámetros que podemos utilizar. Ambas herramientas utilizan la sintaxis *BPF*.

> [!important]
> Podemos usar el parámetro `-P` para que *TShark* imprima los resúmenes de los paquetes mientras escribe en un archivo.

#### Aplicación de filtros
`-f` nos permite aplicar filtros a la captura. En el ejemplo, utilizamos `host`, pero se pueden usar casi cualquier filtro que Wireshark reconozca.
```shell-session
$ sudo tshark -i eth0 -f "host 172.16.146.2"

Capturing on 'eth0'
    1 0.000000000 172.16.146.2 → 172.16.146.1 DNS 70 Standard query 0x0804 A github.com
    2 0.258861645 172.16.146.1 → 172.16.146.2 DNS 86 Standard query response 0x0804 A github.com A 140.82.113.4
    3 0.259866711 172.16.146.2 → 140.82.113.4 TCP 74 48256 → 443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM=1 TSval=1321417850 TSecr=0 WS=128
    4 0.299681376 140.82.113.4 → 172.16.146.2 TCP 74 443 → 48256 [SYN, ACK] Seq=0 Ack=1 Win=65535 Len=0 MSS=1436 SACK_PERM=1 TSval=3885991869 TSecr=1321417850 WS=1024
    5 0.299771728 172.16.146.2 → 140.82.113.4 TCP 66 48256 → 443 [ACK] Seq=1 Ack=1 Win=64256 Len=0 TSval=1321417889 TSecr=3885991869
    6 0.306888828 172.16.146.2 → 140.82.113.4 TLSv1 579 Client Hello
    7 0.347570701 140.82.113.4 → 172.16.146.2 TLSv1.3 2785 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.347653593 172.16.146.2 → 140.82.113.4 TCP 66 48256 → 443 [ACK] Seq=514 Ack=2720 Win=63488 Len=0 TSval=1321417937 TSecr=3885991916
    9 0.358887130 172.16.146.2 → 140.82.113.4 TLSv1.3 130 Change Cipher Spec, Application Data
   10 0.359781588 172.16.146.2 → 140.82.113.4 TLSv1.3 236 Application Data
   11 0.360037927 172.16.146.2 → 140.82.113.4 TLSv1.3 758 Application Data
   12 0.360482668 172.16.146.2 → 140.82.113.4 TLSv1.3 258 Application Data
   13 0.397331368 140.82.113.4 → 172.16.146.2 TLSv1.3 145 Application Data 
```

---

# GUI de Wireshark
Analicemos esta vista de la GUI de Wireshark.
![Captura de Wireshark que muestra el tráfico HTTP y TCP entre las IP 10.1.1.101 y 10.1.1.1, con detalles sobre solicitudes GET y datos de paquetes en hexadecimal y ASCII.](https://academy.hackthebox.com/storage/modules/81/wireshark-interface.png)

Tres paneles principales: 
1. **Lista de paquetes**: <mark style="background: #FFB86CA6;">Naranja</mark>
    - En esta ventana, vemos una línea de resumen de cada paquete que incluye los campos enumerados a continuación de forma predeterminada. Podemos agregar o eliminar columnas para cambiar qué información se presenta.
        - `No.`: Ordene que el paquete llegue a Wireshark
        - `Time`: Formato de hora Unix
        - `Source`: Fuente IP
        - `Destination`: IP de destino
        - `Protocol`: El protocolo utilizado (TCP, UDP, DNS, etc.)
        - `Info`: Información sobre el paquete. Este campo puede variar según el tipo de protocolo utilizado. Mostrará, por ejemplo, qué tipo de consulta es para un paquete DNS.
2. **Detalles del paquete**: <mark style="background: #ADCCFFA6;">Azul</mark>
    - La ventana "*Detalles*" del paquete nos permite profundizar en el paquete para inspeccionar los protocolos con mayor detalle. Lo dividirá en capas del **modelo OSI**.
    - Wireshark mostrará esta encapsulación en orden inverso, con la encapsulación de la capa inferior en la parte superior de la ventana y los niveles superiores en la parte inferior (es decir desde la capa física modelo a la ultima)
3. **Bytes de paquete**: <mark style="background: #40FF00A6;">Verde</mark>
    - La ventana "*Bytes*" del paquete nos permite ver el contenido del paquete en salida ASCII o hexadecimal. A medida que seleccionamos un campo de las ventanas anteriores, se resaltará en la ventana *Bytes* del paquete y nos mostrará dónde se encuentra ese bit o byte dentro del paquete general.
    - Esta es una excelente manera de validar que lo que vemos en el panel *Detalles* es preciso y que la interpretación que hizo Wireshark coincide con la salida del paquete.
    - Cada línea de la salida contiene el desplazamiento de datos, dieciséis bytes hexadecimales y dieciséis bytes ASCII. Los bytes no imprimibles se reemplazan por un período en formato ASCII.

## Realizando una captura en Wireshark
El siguiente gif mostrará los pasos.

### Pasos para iniciar una captura
![GIF que muestra las opciones de captura.](https://academy.hackthebox.com/storage/modules/81/first-capture-ws.gif)

> [!danger]
> Cada vez que cambiemos las opciones de captura, Wireshark reiniciará el seguimiento. Wireshark tiene opciones de filtro de captura y visualización que se pueden utilizar.

---

## Procesamiento y filtrado previo y posterior a la captura
Al capturar tráfico con Wireshark, tenemos varias opciones sobre cómo y cuándo filtramos el tráfico. Esto se logra utilizando filtros de captura y visualización. El primero se inicia antes de que comience la captura y el segundo durante o después de que se complete la captura.

> [!recomendacion]
> Cuantos más paquetes se capturen, más tiempo le llevará a Wireshark ejecutar el filtro de visualización o análisis. Si trabajamos con un archivo *pcap* grande, puede ser mejor dividirlo primero en fragmentos más pequeños.

### Filtros de captura
Se ingresan antes de que se inicie la captura. Estos utilizan *sintaxis BPF*. De esta manera tenemos menos opciones de filtro y un filtro de captura eliminará todo el resto del tráfico que no cumpla explícitamente con los criterios establecidos. Esta es una excelente manera de reducir los datos que escribe en el disco al solucionar problemas de conexión, como capturar las conversaciones entre dos hosts.

Aquí hay una tabla de filtros de captura comunes y útiles con una descripción de cada uno:

|         **Capturar filtros**          | **Resultado**                                                                                             |
| :-----------------------------------: | --------------------------------------------------------------------------------------------------------- |
|            `host x.x.x.x`             | Captura solo el tráfico perteneciente a un host determinado.                                              |
|           `net x.x.x.x/24`            | Capturar tráfico hacia o desde una red específica (usando notación de barra para especificar la máscara). |
|       `src/dst net x.x.x.x/24`        | Solo capturará el tráfico procedente de la red especificada o destinado a la red de destino.              |
|               `port #`                | Filtrará solo el tráfico del puerto que se especifique.                                                   |
|             `not port #`              | Capturará todo excepto el puerto especificado.                                                            |
|            `port # and #`             | `AND` concatenará sus puertos especificados.                                                              |
|            `portrange x-x`            | Captará tráfico únicamente de todos los puertos dentro del rango.                                         |
|        `ip` / `ether` / `tcp`         | Estos filtros solo captarán tráfico de encabezados de protocolo específicos.                              |
| `broadcast` / `multicast` / `unicast` | Capta un tipo específico de tráfico: uno a uno, uno a muchos o uno a todos.                               |

#### Aplicación de un filtro de captura
Para ello: Hacer clic en el radial de captura en la parte superior de la ventana Wireshark `→` y luego seleccionar filtros de captura en el menú desplegable. Desde aquí podemos modificar los filtros existentes o añadir los nuestros.
![Opciones de captura de Wireshark que muestran interfaces, modo promiscuo habilitado y filtro TCP aplicado.](https://academy.hackthebox.com/storage/modules/81/how-to-add-cap.png)

##### Lista de filtros predefinidos
![Lista de filtros de captura de Wireshark con expresiones para filtrar por Ethernet, IP, TCP, UDP y puertos específicos.](https://academy.hackthebox.com/storage/modules/81/capture-filter-list.png)

### Filtros de visualización
Se utilizan mientras se ejecuta la captura y después de que la captura se haya detenido. Los filtros de pantalla son propiedad de Wireshark, que ofrece muchas opciones diferentes para casi cualquier protocolo.

A continuación se muestra una tabla de filtros de visualización comunes y útiles con una descripción de cada uno:

|     **Filtros de visualización**     | **Resultado**                                                                                           |
| :----------------------------------: | ------------------------------------------------------------------------------------------------------- |
|         `ip.addr == x.x.x.x`         | Captura únicamente el tráfico perteneciente a un host determinado. Esta es una declaración OR.          |
|       `ip.addr == x.x.x.x/24`        | Capturar tráfico perteneciente a una red específica. Esta es una declaración OR.                        |
|     `ip.src / ip.dst == x.x.x.x`     | Capturar tráfico hacia o desde un host específico.                                                      |
| `dns` / `tcp` / `ftp` / `arp` / `ip` | Filtrar el tráfico mediante un protocolo específico. Hay muchas más opciones.                           |
|           `tcp.port == x`            | Filtrar por un puerto tcp específico.                                                                   |
|      `tcp.port / udp.port != x`      | Capturará todo excepto el puerto especificado.                                                          |
|         `and` / `or` / `not`         | `AND` concatenará, `OR` encontrará cualquiera de las dos opciones, `NOT` excluirá su opción de entrada. |

#### Aplicación de un filtro de visualización
Desde la ventana principal de captura de Wireshark, todo lo que necesitamos hacer es: seleccionar el marcador en la barra de herramientas, luego seleccionar una opción del menú desplegable. Alternativamente, se puede colocar el cursor en el texto radial y escribir el filtro que deseamos utilizar. Si el campo se vuelve verde, el filtro es correcto.
![Interfaz Wireshark que muestra el tráfico TCP filtrado entre las IP 162.159.134.234 y 192.168.86.211, con los protocolos TLSv1.2 y TCP.](https://academy.hackthebox.com/storage/modules/81/display-filter.png)