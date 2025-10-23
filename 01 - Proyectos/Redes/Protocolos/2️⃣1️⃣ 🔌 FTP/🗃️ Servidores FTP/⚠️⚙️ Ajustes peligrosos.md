Existen muchas ==configuraciones diferentes relacionadas con la seguridad== que podemos realizar en cada servidor FTP. Estas pueden tener varios propósitos, como probar conexiones a través de los firewalls, probar rutas y mecanismos de autenticación. Uno de estos mecanismos de autenticación es el **usuario anónimo**. Esto se usa a menudo para permitir que todos en la red interna compartan archivos y datos sin acceder a las computadoras de los demás. 

Con [[📂🖥️🌐 vsFTPd]], las [configuraciones opcionales](http://vsftpd.beasts.org/vsftpd_conf.html) que se pueden agregar al archivo de configuración para el inicio de sesión anónimo se ven así:

| ==Ajustes==                        | ==Descripción==                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| `anonymous_enable=YES`         | ¿Se permite **inicio de sesión anónimo**?                                             |
| `anon_upload_enable=YES`       | ¿Se permite a usuarios anónimos **subir archivos**?                                   |
| `anon_mkdir_write_enable=YES`  | ¿Se permite a usuario anónimos **crear nuevos directorios**?                          |
| `no_anon_password=YES`         | ¿**No preguntar por la contraseña** a usuarios anónimos?                              |
| `anon_root=/home/username/ftp` | **Directorio para usuarios anónimos**                                                 |
| `write_enable=YES`             | ¿Permitir el **uso de comandos FTP**? (STOR, DELE, RNFR, RNTO, MKD, RMD, APPE y SITE) |

El uso de la cuenta anónima puede darse en ==entornos internos e infraestructuras donde se conocen todos los participantes==. En cuanto nos conectamos al servidor vsFTPd, se **muestra el código de respuesta `220` con el banner del servidor FTP**. A menudo, este banner contiene la descripción del servicio e incluso la versión del mismo. También nos indica **qué tipo de sistema es el servidor FTP**.

```shell
ftp 10.129.14.136

Connected to 10.129.14.136.
220 "Welcome to the HTB Academy vsFTP service."
Name (10.129.14.136:cry0l1t3): anonymous

230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.


ftp> ls

200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rw-rw-r--    1 1002     1002      8138592 Sep 14 16:54 Calender.pptx
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Clients
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Documents
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Employees
-rw-rw-r--    1 1002     1002           41 Sep 14 16:45 Important Notes.txt
226 Directory send OK.
```
Una de las configuraciones más habituales de los servidores FTP es permitir el acceso anónimo, lo que no requiere credenciales legítimas pero ==permite acceder a algunos archivos==. Incluso si no podemos descargarlos, **a veces basta con enumerar el contenido para generar más ideas y anotar información** que nos ayudará en otro enfoque.

La siguiente lista de ajustes afecta a la ==información que se muestra== acerca del servidor ftp:

| ==Ajustes==               | ==Descripción==                                                                  |
| ------------------------- | -------------------------------------------------------------------------------- |
| `dirmessage_enable=YES`   | Show a message when they first enter a new directory?                            |
| `chown_uploads=YES`       | Change ownership of anonymously uploaded files?                                  |
| `chown_username=username` | User who is given ownership of anonymously uploaded files.                       |
| `local_enable=YES`        | Enable local users to login?                                                     |
| `chroot_local_user=YES`   | Place local users into their home directory?                                     |
| `chroot_list_enable=YES`  | Use a list of local users that will be placed in their home directory?           |
| `hide_ids=YES`            | All user and group information in directory listings will be displayed as "ftp". |
| `ls_recurse_enable=YES`   | Allows the use of recurse listings.                                              |


# vsFTPd Status
Para obtener una **primera descripción general de la configuración del servidor**, podemos usar el siguiente comando:

```shell
ftp> status

Connected to 10.129.14.136.
No proxy connection.
Connecting using address family: any.
Mode: stream; Type: binary; Form: non-print; Structure: file
Verbose: on; Bell: off; Prompting: on; Globbing: on
Store unique: off; Receive unique: off
Case: off; CR stripping: on
Quote control characters: on
Ntrans: off
Nmap: off
Hash mark printing: off; Use of PORT cmds: on
Tick counter printing: off
```

Algunos comandos se deben utilizar ocasionalmente, ya que ==harán que el servidor nos muestre más información== que podemos usar para nuestros fines. Estos comandos incluyen `debug` y `trace`:

```shell
ftp> debug

Debugging on (debug=1).


ftp> trace

Packet tracing on.


ftp> ls

---> PORT 10,10,14,4,188,195
200 PORT command successful. Consider using PASV.
---> LIST
150 Here comes the directory listing.
-rw-rw-r--    1 1002     1002      8138592 Sep 14 16:54 Calender.pptx
drwxrwxr-x    2 1002     1002         4096 Sep 14 17:03 Clients
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Documents
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Employees
-rw-rw-r--    1 1002     1002           41 Sep 14 16:45 Important Notes.txt
226 Directory send OK.
```


# Hiding IDs - YES
En el siguiente ejemplo, podemos ver que si la configuración `hide_ids=YES` está presente, ==la representación UID y GUID del servicio se sobrescribirá==, lo que **hará más difícil para nosotros identificar con qué derechos** se escriben y cargan estos archivos.

```shell
ftp> ls

---> TYPE A
200 Switching to ASCII mode.
ftp: setsockopt (ignored): Permission denied
---> PORT 10,10,14,4,223,101
200 PORT command successful. Consider using PASV.
---> LIST
150 Here comes the directory listing.
-rw-rw-r--    1 ftp     ftp      8138592 Sep 14 16:54 Calender.pptx
drwxrwxr-x    2 ftp     ftp         4096 Sep 14 17:03 Clients
drwxrwxr-x    2 ftp     ftp         4096 Sep 14 16:50 Documents
drwxrwxr-x    2 ftp     ftp         4096 Sep 14 16:50 Employees
-rw-rw-r--    1 ftp     ftp           41 Sep 14 16:45 Important Notes.txt
-rw-------    1 ftp     ftp            0 Sep 15 14:57 testupload.txt
226 Directory send OK.
```
Esta configuración es una **función de seguridad para evitar que se revelen los nombres de usuario locales**. ==Con los nombres de usuario, podríamos atacar servicios como FTP y SSH y muchos otros con un ataque de fuerza bruta== en teoría. Sin embargo, en la realidad, las soluciones [fail2ban](https://en.wikipedia.org/wiki/Fail2ban) son ahora una implementación estándar de cualquier infraestructura que registre la dirección IP y bloquee todo acceso a la infraestructura después de una cierta cantidad de intentos de inicio de sesión fallidos.


# Recursive Listing
Otra configuración útil que podemos usar para nuestros propósitos es `ls_recurse_enable=YES`. Esto se suele configurar en el servidor vsFTPd **para tener una mejor visión general de la estructura del directorio FTP**, ya que nos ==permite ver todo el contenido visible a la vez==.

```shell
ftp> ls -R

---> PORT 10,10,14,4,222,149
200 PORT command successful. Consider using PASV.
---> LIST -R
150 Here comes the directory listing.
.:
-rw-rw-r--    1 ftp      ftp      8138592 Sep 14 16:54 Calender.pptx
drwxrwxr-x    2 ftp      ftp         4096 Sep 14 17:03 Clients
drwxrwxr-x    2 ftp      ftp         4096 Sep 14 16:50 Documents
drwxrwxr-x    2 ftp      ftp         4096 Sep 14 16:50 Employees
-rw-rw-r--    1 ftp      ftp           41 Sep 14 16:45 Important Notes.txt
-rw-------    1 ftp      ftp            0 Sep 15 14:57 testupload.txt

./Clients:
drwx------    2 ftp      ftp          4096 Sep 16 18:04 HackTheBox
drwxrwxrwx    2 ftp      ftp          4096 Sep 16 18:00 Inlanefreight

./Clients/HackTheBox:
-rw-r--r--    1 ftp      ftp         34872 Sep 16 18:04 appointments.xlsx
-rw-r--r--    1 ftp      ftp        498123 Sep 16 18:04 contract.docx
-rw-r--r--    1 ftp      ftp        478237 Sep 16 18:04 contract.pdf
-rw-r--r--    1 ftp      ftp           348 Sep 16 18:04 meetings.txt

./Clients/Inlanefreight:
-rw-r--r--    1 ftp      ftp         14211 Sep 16 18:00 appointments.xlsx
-rw-r--r--    1 ftp      ftp         37882 Sep 16 17:58 contract.docx
-rw-r--r--    1 ftp      ftp            89 Sep 16 17:58 meetings.txt
-rw-r--r--    1 ftp      ftp        483293 Sep 16 17:59 proposal.pptx

./Documents:
-rw-r--r--    1 ftp      ftp         23211 Sep 16 18:05 appointments-template.xlsx
-rw-r--r--    1 ftp      ftp         32521 Sep 16 18:05 contract-template.docx
-rw-r--r--    1 ftp      ftp        453312 Sep 16 18:05 contract-template.pdf

./Employees:
226 Directory send OK.
```


# Download a File
La descarga de archivos desde un servidor FTP es una de las principales funciones, así como la subida de archivos creados por nosotros. Esto nos permite, por ejemplo, ==utilizar vulnerabilidades LFI para hacer que el host ejecute comandos del sistema==. Además de los archivos, podemos ver, descargar e inspeccionar. También son posibles los ataques con los **logs FTP**, lo que da lugar a la **ejecución remota de comandos (RCE)**. Esto se aplica a los servicios FTP y a todos aquellos que podamos detectar durante nuestra fase de enumeración.

```shell
ftp> ls

200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
-rwxrwxrwx    1 ftp      ftp             0 Sep 16 17:24 Calendar.pptx
drwxrwxrwx    4 ftp      ftp          4096 Sep 16 17:57 Clients
drwxrwxrwx    2 ftp      ftp          4096 Sep 16 18:05 Documents
drwxrwxrwx    2 ftp      ftp          4096 Sep 16 17:24 Employees
-rwxrwxrwx    1 ftp      ftp            41 Sep 18 15:58 Important Notes.txt
226 Directory send OK.


ftp> get Important\ Notes.txt

local: Important Notes.txt remote: Important Notes.txt
200 PORT command successful. Consider using PASV.
150 Opening BINARY mode data connection for Important Notes.txt (41 bytes).
226 Transfer complete.
41 bytes received in 0.00 secs (606.6525 kB/s)


ftp> exit

221 Goodbye.
```
```shell
ls | grep Notes.txt

'Important Notes.txt'
```

También **podemos descargar todos los archivos y carpetas a los que tengamos acceso de una sola vez**. Esto es especialmente útil si el servidor FTP tiene muchos archivos diferentes en una estructura de carpetas más grande. Sin embargo, ==esto puede generar alarmas== porque nadie en la empresa suele querer descargar todos los archivos y contenidos a la vez.

```shell
wget -m --no-passive ftp://anonymous:anonymous@10.129.14.136

--2021-09-19 14:45:58--  ftp://anonymous:*password*@10.129.14.136/                                         
           => ‘10.129.14.136/.listing’                                                                     
Connecting to 10.129.14.136:21... connected.                                                               
Logging in as anonymous ... Logged in!
==> SYST ... done.    ==> PWD ... done.
==> TYPE I ... done.  ==> CWD not needed.
==> PORT ... done.    ==> LIST ... done.                                                                 
12.12.1.136/.listing           [ <=>                                  ]     466  --.-KB/s    in 0s       
                                                                                                         
2021-09-19 14:45:58 (65,8 MB/s) - ‘10.129.14.136/.listing’ saved [466]                                     
--2021-09-19 14:45:58--  ftp://anonymous:*password*@10.129.14.136/Calendar.pptx   
           => ‘10.129.14.136/Calendar.pptx’                                       
==> CWD not required.                                                           
==> SIZE Calendar.pptx ... done.                                                                                                                            
==> PORT ... done.    ==> RETR Calendar.pptx ... done.       

...SNIP...

2021-09-19 14:45:58 (48,3 MB/s) - ‘10.129.14.136/Employees/.listing’ saved [119]

FINISHED --2021-09-19 14:45:58--
Total wall clock time: 0,03s
Downloaded: 15 files, 1,7K in 0,001s (3,02 MB/s)
```

Una vez que hayamos descargado todos los archivos, `wget` ==creará un directorio con el nombre de la dirección IP de nuestro objetivo==. Allí se **almacenarán todos los archivos descargados**, que luego podremos inspeccionar localmente.

```shell
tree .

.
└── 10.129.14.136
    ├── Calendar.pptx
    ├── Clients
    │   └── Inlanefreight
    │       ├── appointments.xlsx
    │       ├── contract.docx
    │       ├── meetings.txt
    │       └── proposal.pptx
    ├── Documents
    │   ├── appointments-template.xlsx
    │   ├── contract-template.docx
    │   └── contract-template.pdf
    ├── Employees
    └── Important Notes.txt

5 directories, 9 files
```


# Upload a File
Podemos **comprobar si tenemos los permisos para subir archivos al servidor FTP**. Especialmente con los servidores web, es habitual que los archivos estén sincronizados y los desarrolladores tengan acceso rápido a los archivos. El FTP se utiliza a menudo para este fin y, ==la mayoría de las veces, se encuentran errores de configuración en servidores que los administradores creen que no son detectables==. La actitud de que no se puede acceder a los componentes de la red interna desde el exterior significa que a menudo se descuida el endurecimiento de los sistemas internos y **conduce a configuraciones erróneas**.

La capacidad de subir archivos al servidor FTP conectado a un servidor web **aumenta la probabilidad de obtener acceso directo al servidor web** e incluso un `reverse shell` que nos permita ejecutar comandos internos del sistema y tal vez incluso escalar nuestros privilegios.

```shell
touch testupload.txt
```
```shell
ftp> put testupload.txt 

local: testupload.txt remote: testupload.txt
---> PORT 10,10,14,4,184,33
200 PORT command successful. Consider using PASV.
---> STOR testupload.txt
150 Ok to send data.
226 Transfer complete.


ftp> ls

---> TYPE A
200 Switching to ASCII mode.
---> PORT 10,10,14,4,223,101
200 PORT command successful. Consider using PASV.
---> LIST
150 Here comes the directory listing.
-rw-rw-r--    1 1002     1002      8138592 Sep 14 16:54 Calender.pptx
drwxrwxr-x    2 1002     1002         4096 Sep 14 17:03 Clients
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Documents
drwxrwxr-x    2 1002     1002         4096 Sep 14 16:50 Employees
-rw-rw-r--    1 1002     1002           41 Sep 14 16:45 Important Notes.txt
-rw-------    1 1002     133             0 Sep 15 14:57 testupload.txt
226 Directory send OK.
```

