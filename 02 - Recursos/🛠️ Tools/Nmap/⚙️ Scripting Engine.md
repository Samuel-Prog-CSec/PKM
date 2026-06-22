--**Nmap Scripting Engine (NSE)** es otra característica muy útil de Nmap. Nos brinda la posibilidad de crear **scripts en Lua** para interactuar con determinados servicios. Existen un total de ==14 categorías== en las que se pueden dividir estos scripts:

| Categoría   | Descripción                                                                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `auth`      | Determinación de **credenciales de autenticación**                                                                                             |
| `broadcast` | **Descubrimiento de host mediante difusión** y los hosts descubiertos se pueden agregar automáticamente a los análisis restantes               |
| `brute`     | Intentan iniciar sesión en el servicio respectivo mediante **fuerza bruta**                                                                    |
| `default`   | **Scripts predeterminados** que se ejecutan utilizando la opción `-sC`                                                                         |
| `discovery` | **Evaluación de servicios accesibles**                                                                                                         |
| `dos`       | Comprobar si los servicios tienen **vulnerabilidades de denegación de servicio** y se usan menos porque dañan los servicios                    |
| `exploit`   | **Intenta explotar vulnerabilidades conocidas** del puerto escaneado                                                                           |
| `external`  | **Utilizan servicios externos** para un procesamiento posterior                                                                                |
| `fuzzer`    | **Identificar vulnerabilidades** **y manejo de paquetes inesperados** mediante el envío de diferentes campos, lo que puede llevar mucho tiempo |
| `intrusive` | Scripts intrusivos que **podrían afectar negativamente al sistema de destino**                                                                 |
| `malware`   | Comprueba si algún **malware infecta el sistema de destino**                                                                                   |
| `safe`      | Scripts defensivos que **no realizan acceso intrusivo y destructivo**                                                                          |
| `version`   | **Extensión para detección de servicios**                                                                                                      |
| `vuln`      | **Identificación de vulnerabilidades específicas**                                                                                             |


# Formas de definir los scripts que se lanzarán
- **Scripts por defecto**:  `sudo nmap <target> -sC`
- **Scripts específicos de una categoría**: `sudo nmap <target> --script <category>`
- **Scripts concretos**: `sudo nmap <target> --script <script-name>,<script-name>,...

Por ejemplo, vamos a trabajar con el ==puerto **SMTP** y dos scripts definidos==:

```shell
sudo nmap 10.129.2.28 -p 25 --script banner,smtp-commands

Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-16 23:21 CEST
Nmap scan report for 10.129.2.28
Host is up (0.050s latency).

PORT   STATE SERVICE
25/tcp open  smtp
|_banner: 220 inlane ESMTP Postfix (Ubuntu)
|_smtp-commands: inlane, PIPELINING, SIZE 10240000, VRFY, ETRN, STARTTLS, ENHANCEDSTATUSCODES, 8BITMIME, DSN, SMTPUTF8,
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)
```
Vemos que **podemos reconocer la distribución** Ubuntu de Linux mediante el script `banner`. El script `smtp-commands` nos muestra **qué comandos podemos utilizar al interactuar con el servidor SMTP** de destino. En este ejemplo, dicha información puede ayudarnos a encontrar usuarios existentes en el destino. Nmap también ==nos da la posibilidad de escanear nuestro destino con la opción agresiva== (`-A`). Esto escanea el destino con múltiples opciones como **detección de servicio** (`-sV`), **detección de SO** (`-O`), **traceroute** (`--traceroute`) y con los **scripts NSE predeterminados** (`-sC`).

```shell
sudo nmap 10.129.2.28 -p 80 -A
Starting Nmap 7.80 ( https://nmap.org ) at 2020-06-17 01:38 CEST
Nmap scan report for 10.129.2.28
Host is up (0.012s latency).

PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
|_http-generator: WordPress 5.3.4
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: blog.inlanefreight.com
MAC Address: DE:AD:00:00:BE:EF (Intel Corporate)
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Aggressive OS guesses: Linux 2.6.32 (96%), Linux 3.2 - 4.9 (96%), Linux 2.6.32 - 3.10 (96%), Linux 3.4 - 3.10 (95%), Linux 3.1 (95%), Linux 3.2 (95%), 
AXIS 210A or 211 Network Camera (Linux 2.6.17) (94%), Synology DiskStation Manager 5.2-5644 (94%), Netgear RAIDiator 4.2.28 (94%), 
Linux 2.6.32 - 2.6.35 (94%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 1 hop

TRACEROUTE
HOP RTT      ADDRESS
1   11.91 ms 10.129.2.28

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 11.36 seconds
```
Descubrimos qué **tipo de servidor web** (==Apache 2.4.29==) se está ejecutando en el sistema, qué **aplicación web** (==WordPress 5.3.4==) se utiliza y el **título de la página web** (==blog.inlanefreight.com==). Además, Nmap muestra que es probable que se trate de un **sistema operativo Linux** (==96%==).


# Evaluación de vulnerabilidades
Pasemos ahora al ==puerto HTTP 80== y veamos **qué información y vulnerabilidades podemos encontrar** utilizando la categoría `vuln` de NSE:

```shell
sudo nmap 10.129.2.28 -p 80 -sV --script vuln 

Nmap scan report for 10.129.2.28
Host is up (0.036s latency).

PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.29 ((Ubuntu))
| http-enum:
|   /wp-login.php: Possible admin folder
|   /readme.html: Wordpress version: 2
|   /: WordPress version: 5.3.4
|   /wp-includes/images/rss.png: Wordpress version 2.2 found.
|   /wp-includes/js/jquery/suggest.js: Wordpress version 2.5 found.
|   /wp-includes/images/blank.gif: Wordpress version 2.6 found.
|   /wp-includes/js/comment-reply.js: Wordpress version 2.7 found.
|   /wp-login.php: Wordpress login page.
|   /wp-admin/upgrade.php: Wordpress login page.
|_  /readme.html: Interesting, a readme.
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-stored-xss: Couldn't find any stored XSS vulnerabilities.
| http-wordpress-users:
| Username found: admin
|_Search stopped at ID #25. Increase the upper limit if necessary with 'http-wordpress-users.limit'
| vulners:
|   cpe:/a:apache:http_server:2.4.29:
|     	CVE-2019-0211	7.2	https://vulners.com/cve/CVE-2019-0211
|     	CVE-2018-1312	6.8	https://vulners.com/cve/CVE-2018-1312
|     	CVE-2017-15715	6.8	https://vulners.com/cve/CVE-2017-15715
<SNIP>
```
Los scripts utilizados para el último escaneo **interactúan con el servidor web** **y su aplicación web** para obtener más información sobre sus versiones y consultar varias bases de datos para ver si existen vulnerabilidades conocidas. Más información sobre los scripts de NSE y las categorías correspondientes la podemos encontrar en: https://nmap.org/nsedoc/index.html


# Actualizar base de datos de scripts
Podemos actualizar la base de datos de scripts NSE con el comando que se muestra:

```shell
sudo nmap --script-updatedb

Starting Nmap 7.80 ( https://nmap.org ) at 2021-09-19 13:49 CEST
NSE: Updating rule database.
NSE: Script Database updated successfully.
Nmap done: 0 IP addresses (0 hosts up) scanned in 0.28 seconds
```


# Buscar nombres de scripts
Todos los scripts de NSE se encuentran en `Pwnbox` en `/usr/share/nmap/scripts/` podemos encontrarlos usando un comando simple. En este caso buscamos aquellos relacionados con FTP:

```shell
find / -type f -name ftp* 2>/dev/null | grep scripts

/usr/share/nmap/scripts/ftp-syst.nse
/usr/share/nmap/scripts/ftp-vsftpd-backdoor.nse
/usr/share/nmap/scripts/ftp-vuln-cve2010-4221.nse
/usr/share/nmap/scripts/ftp-proftpd-backdoor.nse
/usr/share/nmap/scripts/ftp-bounce.nse
/usr/share/nmap/scripts/ftp-libopie.nse
/usr/share/nmap/scripts/ftp-anon.nse
/usr/share/nmap/scripts/ftp-brute.nse
```


# Scripts importantes
| ==Nombre del script==           | ==Descripción==                                                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `http-vuln-cve2017-5638`        | Detecta la vulnerabilidad CVE-2017-5638 en servidores Apache Struts, que permite ejecución remota de código.                                                       |
| `http-slowloris-check`          | Comprueba si un servidor web es vulnerable al ataque de tipo Slowloris, que agota los recursos del servidor al mantener conexiones abiertas.                       |
| `smb-vuln-ms17-010`             | Detecta si el objetivo es vulnerable al exploit EternalBlue (CVE-2017-0144), utilizado en ataques de ransomware como WannaCry.                                     |
| `ftp-anon`                      | Detecta si un servidor FTP permite acceso anónimo.                                                                                                                 |
| `ftp-vsftpd-backdoor`           | Comprueba si el servidor FTP tiene una puerta trasera conocida en versiones vulnerables de vsftpd 2.3.4.                                                           |
| `smtp-open-relay`               | Comprueba si el servidor SMTP está configurado como un open relay, lo que permitiría enviar correos desde el servidor sin autenticación.                           |
| `ssl-enum-ciphers`              | Enumera los cifrados SSL/TLS soportados por un servidor, clasificándolos por nivel de seguridad.                                                                   |
| `ssl-cert`                      | Obtiene información detallada sobre el certificado SSL del servidor, como la fecha de expiración, el emisor y el sujeto.                                           |
| `dns-nsid`                      | Detecta el soporte para DNS NSID (Name Server Identifier) y extrae información del servidor DNS, útil para obtener información de configuración de servidores DNS. |
| `dns-brute`                     | Realiza un ataque de fuerza bruta para descubrir subdominios de un dominio.                                                                                        |
| `dns-zone-transfer`             | Intenta realizar una transferencia de zona DNS (AXFR) para obtener un listado de todos los registros DNS de un dominio.                                            |
| `ssh-brute`                     | Intenta realizar un ataque de fuerza bruta sobre el servicio SSH para identificar credenciales válidas.                                                            |
| `sshv1`                         | Comprueba si el servicio SSH está utilizando el protocolo vulnerable SSHv1.                                                                                        |
| `mysql-brute`                   | Realiza un ataque de fuerza bruta para identificar credenciales válidas en servidores MySQL.                                                                       |
| `mysql-enum`                    | Enumera bases de datos y usuarios en servidores MySQL.                                                                                                             |
| `ms-sql-brute`                  | Realiza un ataque de fuerza bruta contra un servidor Microsoft SQL para descubrir credenciales válidas.                                                            |
| `http-enum`                     | Enumera rutas y archivos comunes en servidores web, como archivos de configuración o páginas de administración.                                                    |
| `http-phpmyadmin-dir-traversal` | Detecta vulnerabilidades de traversing en phpMyAdmin que permiten acceder a archivos fuera del directorio web.                                                     |
| `http-shellshock`               | Comprueba si el servidor web es vulnerable a la vulnerabilidad Shellshock (CVE-2014-6271).                                                                         |
| `http-title`                    | Recupera el título de las páginas web encontradas, útil para obtener una vista rápida de los sitios en un dominio.                                                 |
| `http-sql-injection`            | Detecta posibles puntos de inyección SQL en aplicaciones web.                                                                                                      |
| `http-stored-xss`               | Intenta detectar vulnerabilidades de tipo cross-site scripting (XSS) almacenado en formularios web.                                                                |
| `http-methods`                  | Enumera los métodos HTTP soportados por el servidor (GET, POST, PUT, DELETE, etc.), útil para detectar métodos inseguros.                                          |
| `http-robots.txt`               | Descarga y analiza el archivo `robots.txt` para descubrir rutas web potencialmente interesantes o restringidas.                                                    |
| `firewalk`                      | Descubre dispositivos y reglas de filtrado en un firewall, revelando saltos entre redes.                                                                           |
| `vulscan`                       | Realiza un escaneo de vulnerabilidades cruzando resultados con una base de datos externa como CVE o OSVDB.                                                         |
| `rdp-enum-encryption`           | Enumera los métodos de cifrado disponibles en servidores de Remote Desktop Protocol (RDP).                                                                         |
| `rdp-vuln-ms12-020`             | Detecta vulnerabilidad en RDP para ataques de denegación de servicio o ejecución de código (CVE-2012-0002).                                                        |
| `telnet-brute`                  | Realiza un ataque de fuerza bruta sobre el servicio Telnet para descubrir credenciales válidas.                                                                    |
| `snmp-brute`                    | Intenta descubrir las cadenas de comunidad SNMP mediante un ataque de fuerza bruta.                                                                                |
| `snmp-info`                     | Extrae información detallada del sistema usando SNMP, como la versión del sistema operativo, hardware y otros datos.                                               |
| `rpcinfo`                       | Enumera los servicios RPC disponibles en un servidor.                                                                                                              |
| `nfs-ls`                        | Enumera los archivos compartidos a través de NFS (Network File System).                                                                                            |
| `nfs-showmount`                 | Lista los sistemas de archivos exportados por un servidor NFS.                                                                                                     |
| `smb-enum-shares`               | Enumera los recursos compartidos en servidores SMB, incluyendo carpetas abiertas y accesibles.                                                                     |
| `smb-enum-users`                | Enumera los usuarios en un servidor SMB.                                                                                                                           |
| `smb-vuln-cve-2020-0796`        | Comprueba si un servidor SMB es vulnerable al ataque SMBGhost (CVE-2020-0796), que permite ejecución remota de código.                                             |
| `ldap-search`                   | Realiza una búsqueda en el servicio LDAP y extrae información útil como usuarios, grupos y configuraciones.                                                        |
| `rdp-ntlm-info`                 | Extrae información NTLM de servidores RDP, como el nombre de dominio, versiones del sistema y otros detalles.                                                      |
| `http-wordpress-brute`          | Realiza un ataque de fuerza bruta contra la página de login de WordPress.                                                                                          |
| `wordpress-enum`                | Enumera usuarios y plugins instalados en un sitio WordPress.                                                                                                       |
