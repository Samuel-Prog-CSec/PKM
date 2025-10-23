El **footprinting mediante diversos escáneres de red** también es un método muy útil y extendido. Estas herramientas ==nos permiten identificar con mayor facilidad diferentes servicios==, incluso si no son accesibles en los puertos estándar. 

Una de las herramientas más utilizadas para este fin es [[💻 Nmap1]]. Nmap también incorpora el [[⚙️ Scripting Engine]], un **conjunto de muchos scripts diferentes escritos para servicios específicos**. 

Como ya sabemos, el servidor FTP normalmente se ejecuta en el **puerto TCP** estándar `21`, que podemos escanear con Nmap. También utilizamos el **escaneo de versiones** (`-sV`), el **escaneo agresivo** (`-A`) y el **escaneo de script predeterminado** (`-sC`) contra nuestro objetivo `10.129.14.136`.

```shell
sudo nmap -sV -p21 -sC -A 10.129.14.136

Starting Nmap 7.80 ( https://nmap.org ) at 2021-09-16 18:12 CEST
Nmap scan report for 10.129.14.136
Host is up (0.00013s latency).

PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.0.8 or later
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| -rwxrwxrwx    1 ftp      ftp       8138592 Sep 16 17:24 Calendar.pptx [NSE: writeable]
| drwxrwxrwx    4 ftp      ftp          4096 Sep 16 17:57 Clients [NSE: writeable]
| drwxrwxrwx    2 ftp      ftp          4096 Sep 16 18:05 Documents [NSE: writeable]
| drwxrwxrwx    2 ftp      ftp          4096 Sep 16 17:24 Employees [NSE: writeable]
| -rwxrwxrwx    1 ftp      ftp            41 Sep 16 17:24 Important Notes.txt [NSE: writeable]
|_-rwxrwxrwx    1 ftp      ftp             0 Sep 15 14:57 testupload.txt [NSE: writeable]
| ftp-syst: 
|   STAT: 
| FTP server status:
|      Connected to 10.10.14.4
|      Logged in as ftp
|      TYPE: ASCII
|      No session bandwidth limit
|      Session timeout in seconds is 300
|      Control connection is plain text
|      Data connections will be plain text
|      At session startup, client count was 2
|      vsFTPd 3.0.3 - secure, fast, stable
|_End of status
```

Una vez que Nmap ha detectado el servicio, ejecuta los scripts marcados uno tras otro, proporcionando información diferente. Por ejemplo, el script `NSE ftp-anon` comprueba **si el servidor FTP permite el acceso anónimo**. Si es así, se muestran los contenidos del directorio raíz del FTP para el usuario anónimo.

El `ftp-syst`, por ejemplo, ==ejecuta el comando== `STAT`, que **muestra información sobre el estado del servidor FTP**. Esto incluye las configuraciones, así como la versión del servidor FTP. 


# Nmap Script Trace
Nmap también ==proporciona la capacidad de rastrear el progreso de los scripts NSE a nivel de red== si utilizamos la opción `--script-trace` en nuestros análisis. Esto nos permite ver qué comandos envía Nmap, qué puertos se utilizan y qué respuestas recibimos del servidor analizado.

```shell
sudo nmap -sV -p21 -sC -A 10.129.14.136 --script-trace

Starting Nmap 7.80 ( https://nmap.org ) at 2021-09-19 13:54 CEST                                                                                                                                                   
NSOCK INFO [11.4640s] nsock_trace_handler_callback(): Callback: CONNECT SUCCESS for EID 8 [10.129.14.136:21]                                   
NSOCK INFO [11.4640s] nsock_trace_handler_callback(): Callback: CONNECT SUCCESS for EID 16 [10.129.14.136:21]             
NSOCK INFO [11.4640s] nsock_trace_handler_callback(): Callback: CONNECT SUCCESS for EID 24 [10.129.14.136:21]
NSOCK INFO [11.4640s] nsock_trace_handler_callback(): Callback: CONNECT SUCCESS for EID 32 [10.129.14.136:21]
NSOCK INFO [11.4640s] nsock_read(): Read request from IOD #1 [10.129.14.136:21] (timeout: 7000ms) EID 42
NSOCK INFO [11.4640s] nsock_read(): Read request from IOD #2 [10.129.14.136:21] (timeout: 9000ms) EID 50
NSOCK INFO [11.4640s] nsock_read(): Read request from IOD #3 [10.129.14.136:21] (timeout: 7000ms) EID 58
NSOCK INFO [11.4640s] nsock_read(): Read request from IOD #4 [10.129.14.136:21] (timeout: 11000ms) EID 66
NSE: TCP 10.10.14.4:54226 > 10.129.14.136:21 | CONNECT
NSE: TCP 10.10.14.4:54228 > 10.129.14.136:21 | CONNECT
NSE: TCP 10.10.14.4:54230 > 10.129.14.136:21 | CONNECT
NSE: TCP 10.10.14.4:54232 > 10.129.14.136:21 | CONNECT
NSOCK INFO [11.4660s] nsock_trace_handler_callback(): Callback: READ SUCCESS for EID 50 [10.129.14.136:21] (41 bytes): 220 Welcome to HTB-Academy FTP service...
NSOCK INFO [11.4660s] nsock_trace_handler_callback(): Callback: READ SUCCESS for EID 58 [10.129.14.136:21] (41 bytes): 220 Welcome to HTB-Academy FTP service...
NSE: TCP 10.10.14.4:54228 < 10.129.14.136:21 | 220 Welcome to HTB-Academy FTP service.
```

El historial de escaneos muestra que se están ejecutando ==cuatro escaneos paralelos diferentes contra el servicio==, con distintos tiempos de espera. Para los scripts NSE, vemos que nuestra máquina local usa otros puertos de salida (`54226, 54228, 54230, 54232`) y primero inicia la conexión con el comando `CONNECT`. A partir de la primera respuesta del servidor, podemos ver que **estamos recibiendo el banner del servidor a nuestro segundo script NSE** (`54228`) desde el servidor FTP de destino. 

Si es necesario, podemos, por supuesto, usar otras aplicaciones como **netcat** o **telnet** para interactuar con el servidor FTP.


# Interacción con el servicio
```shell
nc -nv 10.129.14.136 21
```
```shell
telnet 10.129.14.136 21
```

El resultado es un poco diferente si el servidor FTP se ejecuta con **cifrado TLS/SSL**, ya que en ese caso ==necesitamos un cliente que pueda manejar TLS/SSL==. Para ello, podemos utilizar el **cliente openssl** y comunicarnos con el servidor FTP. Lo bueno de utilizar openssl es que podemos ver el certificado SSL, lo que también puede resultar útil.

```shell
openssl s_client -connect 10.129.14.136:21 -starttls ftp

CONNECTED(00000003)                                                                                      
Can't use SSL_get_servername                        
depth=0 C = US, ST = California, L = Sacramento, O = Inlanefreight, OU = Dev, CN = master.inlanefreight.htb, emailAddress = admin@inlanefreight.htb
verify error:num=18:self signed certificate
verify return:1

depth=0 C = US, ST = California, L = Sacramento, O = Inlanefreight, OU = Dev, CN = master.inlanefreight.htb, emailAddress = admin@inlanefreight.htb
verify return:1
---                                                 
Certificate chain
 0 s:C = US, ST = California, L = Sacramento, O = Inlanefreight, OU = Dev, CN = master.inlanefreight.htb, emailAddress = admin@inlanefreight.htb
 
 i:C = US, ST = California, L = Sacramento, O = Inlanefreight, OU = Dev, CN = master.inlanefreight.htb, emailAddress = admin@inlanefreight.htb
---
 
Server certificate

-----BEGIN CERTIFICATE-----

MIIENTCCAx2gAwIBAgIUD+SlFZAWzX5yLs2q3ZcfdsRQqMYwDQYJKoZIhvcNAQEL
...SNIP...
```
Esto se debe a que el ==certificado SSL nos permite reconocer==, por ejemplo, el **nombre del host** y, en la mayoría de los casos, también una **dirección de correo electrónico de la organización o empresa**. Además, si la empresa tiene varias sedes en todo el mundo, también ==se pueden crear certificados para ubicaciones específicas==, que también se pueden identificar mediante el certificado SSL. 