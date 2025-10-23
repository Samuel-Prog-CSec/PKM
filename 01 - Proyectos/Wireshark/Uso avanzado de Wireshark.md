---
tags:
  - Windows
  - Linux
  - Escaneo/Redes
Fecha de actualización: 2025-08-27
Nota previa: "[[Wireshark]]"
Nota siguiente: "[[Desencriptar conexiones]]"
Area: "[[Wireshark]]"
---
---
# Complementos
## Las estadísticas y las pestañas de análisis
Las pestañas `Estadísticas` y `Análisis` pueden proporcionarnos una gran visión de los datos que estamos examinando. A partir de estos puntos, podemos utilizar muchos de los complementos integrados que [[Wireshark]] tiene para ofrecer. Los complementos aquí pueden brindarnos informes detallados sobre el [[Análisis del tráfico de red |tráfico de red]] que se utiliza. 

### Pestaña de estadísticas
![Interfaz Wireshark que muestra estadísticas de direcciones, jerarquía de protocolos y detalles de conversaciones para el análisis del tráfico de red, incluidas direcciones IP, recuentos de paquetes y fallas de protocolo.](https://academy.hackthebox.com/storage/modules/81/wireshark-statistics.png)

### Analizar
Desde la pestaña `Analizar`, podemos utilizar complementos que nos **permiten hacer cosas como seguir flujos TCP**, filtrar tipos de conversación, preparar nuevos filtros de paquetes y examinar la información experta que Wireshark genera sobre el tráfico. A continuación se muestran algunos ejemplos de cómo utilizar estos complementos.
![Menú Análisis de Wireshark que muestra opciones para mostrar filtros, aplicar filtros, protocolos habilitados e información de expertos.](https://academy.hackthebox.com/storage/modules/81/analyze.png)

#### 1. Siguiendo los flujos TCP
Wireshark puede **volver a unir paquetes TCP para recrear toda la transmisión en un formato legible**. Esta capacidad también nos permite extraer datos (`images, files, etc.`) fuera de la captura. Esto funciona para casi cualquier [[Protocolos de red]] que utilice TCP como mecanismo de transporte.

Para *utilizar esta función*:
- Hacer clic derecho en un paquete de la transmisión que deseamos recrear.
- Seleccionar seguir → TCP
- Esto abrirá una nueva ventana con el **flujo cosido nuevamente**. <mark style="background: #ADCCFFA6;">Desde aquí podemos ver la conversación completa</mark>.
![GIF que muestra la funcionalidad 'Seguir una transmisión'.](https://academy.hackthebox.com/storage/modules/81/follow-tcp.gif)
> [!info]
>Alternativamente, podemos utilizar el filtro `tcp.stream eq #` para **encontrar y rastrear conversaciones capturadas** en el archivo `pcap`.
![Captura de Wireshark que muestra paquetes TCP y Telnet entre IP 10.100.18.5 y 10.100.16.1, con números de secuencia y reconocimiento.](https://academy.hackthebox.com/storage/modules/81/tcp-stream.gif)

#### 2. Extracción de datos y archivos de una captura
Wireshark puede recuperar muchos tipos diferentes de datos de flujos. Requiere que hayas capturado toda la conversación. De lo contrario, <mark style="background: #FF5582A6;">esta capacidad no podrá volver a armar un datagrama incompleto</mark>.

Para *extraer archivos de una transmisión*:
- Detén la captura.
- Seleccionar `Archivo` → `Exportar` → , luego seleccionar el formato de protocolo del cual extraer.
- (DICOM, [[HTTP]], [[📂🔗 SMB]], etc.)
![GIF que muestra la extracción de archivos de una transmisión HTTP.](https://academy.hackthebox.com/storage/modules/81/extract-http.gif)

##### 2.1 Disector FTP
Otra forma interesante de obtener datos del archivo `pcap` proviene de [[📂🔄 FTP]]. El protocolo de transferencia de archivos <mark style="background: #ADCCFFA6;">mueve datos entre un servidor y un host para extraerlos de los bytes sin procesar y reconstruir el archivo</mark> (imagen, documentos de texto, etc.) `FTP` utiliza `TCP` como protocolo de transporte y utiliza puertos `20 & 21` funcionar. El <mark style="background: #FFB86CA6;">puerto TCP 20 se utiliza para transferir datos entre el servidor y el host</mark>, mientras que el <mark style="background: #FFB86CA6;">puerto 21 se utiliza como puerto de control FTP</mark>. Cualquier comando como iniciar sesión, enumerar archivos y emitir descargas o cargas se realiza a través de este puerto. Para ello, debemos observar los diferentes filtros de `FTP` en Wireshark. Se puede encontrar una lista completa de estos [aquí](https://www.wireshark.org/docs/dfref/f/ftp.html). Por ahora, veremos tres:
- `ftp`: mostrará **cualquier cosa sobre el protocolo FTP**.
    - Podemos utilizar esto para <mark style="background: #FFB8EBA6;">tener una idea de qué hosts/servidores están transfiriendo datos</mark> a través de `FTP`.
![Captura de Wireshark que muestra solicitudes y respuestas FTP entre las IP 172.16.146.1 y 172.16.146.2, incluidos cambios anónimos de inicio de sesión y directorio.](https://academy.hackthebox.com/storage/modules/81/ftp-disector.png)

- `ftp.request.command`: mostrará **cualquier comando enviado a través del canal de control FTP (puerto 21)**.
    - Podemos buscar <mark style="background: #FFB8EBA6;">información como nombres de usuario y contraseñas con este filtro</mark>. También puede mostrarnos nombres de archivos para cualquier cosa solicitada.
![Captura de Wireshark que muestra solicitudes FTP entre las IP 172.16.146.1 y 172.16.146.2, incluidos comandos anónimos de inicio de sesión y directorio.](https://academy.hackthebox.com/storage/modules/81/ftp-request-command.png)

- `ftp-data`: mostrará **cualquier dato transferido a través del canal de datos (puerto 20)**.
    - Si filtramos una conversación y la utilizamos `ftp-data`, podemos <mark style="background: #FFB8EBA6;">capturar cualquier cosa enviada durante la conversación</mark>. Podemos<mark style="background: #8000E1A6;"> reconstruir cualquier cosa transferida colocando los datos sin procesar nuevamente en un nuevo archivo</mark> y nombrándolos apropiadamente.
![Captura de Wireshark que muestra la transferencia de datos FTP entre las IP 172.16.146.2 y 172.16.146.1, incluida la recuperación de los archivos 'secrets.txt' y 'Shield-prototype-plans'.](https://academy.hackthebox.com/storage/modules/81/ftp-data.png)

---

Dado que `FTP` utiliza `TCP` como mecanismo de transporte, podemos utilizar el `follow tcp stream` <mark style="background: #ADCCFFA6;">para agrupar cualquier conversación que deseemos explorar.</mark> Los pasos básicos para analizar datos `FTP` de un `pcap` son los siguientes:
1. Identificar cualquier tráfico **FTP** **utilizando filtro de visualización** `ftp`.
2. **Mirar los controles de comando enviados entre el servidor y los hosts** para determinar si se transfirió algo y quién lo hizo con el `ftp.request.command` filtro.
3. Elegir un archivo y luego filtrar por `ftp-data`. **Seleccionar un paquete que corresponda con el archivo de interés y seguir el flujo TCP** que se correlaciona con él.
4. Una vez hecho esto, cambiar "`Show and save data as`" a "`Raw`" y **guardar el contenido como el nombre del archivo original**.
5. <mark style="background: #FF5582A6;">Validar la extracción</mark> comprobando el tipo de archivo.