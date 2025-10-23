Comprender las **diferentes formas de realizar transferencias de archivos** y cómo funcionan las redes puede ayudarnos a lograr nuestros objetivos durante una evaluación. Debemos ==conocer los controles del host== que pueden impedir nuestras acciones, como la inclusión de aplicaciones en listas blancas o el bloqueo de aplicaciones o actividades específicas por parte de **AV/EDR**. Las transferencias de archivos también se ven afectadas por dispositivos de red como **firewalls, IDS o IPS** que ==pueden monitorear o bloquear puertos particulares u operaciones== poco comunes.


# Índice



# Preparando el escenario 

Durante una interacción, obtenemos una ejecución de código remoto (RCE) en un servidor web IIS a través de una vulnerabilidad de carga de archivos sin restricciones. Inicialmente, cargamos un shell web y luego nos enviamos un shell inverso para enumerar el sistema más a fondo en un intento de escalar privilegios. Intentamos usar PowerShell para transferir [PowerUp.ps1](https://github.com/PowerShellMafia/PowerSploit/blob/master/Privesc/PowerUp.ps1) (un script de PowerShell para enumerar vectores de escalada de privilegios), pero PowerShell está bloqueado por la [Política de control de aplicaciones](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/windows-defender-application-control). 

Realizamos nuestra enumeración local manualmente y descubrimos que tenemos [SeImpersonatePrivilege](https://docs.microsoft.com/en-us/troubleshoot/windows-server/windows-security/seimpersonateprivilege-secreateglobalprivilege). Necesitamos transferir un binario a nuestra máquina de destino para escalar privilegios utilizando la herramienta [PrintSpoofer](https://github.com/itm4n/PrintSpoofer). Luego, intentamos usar [Certutil](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certutil) para descargar el archivo que compilamos nosotros mismos directamente desde nuestro propio GitHub, pero la organización tiene un fuerte filtrado de contenido web implementado. No podemos acceder a sitios web como GitHub, Dropbox, Google Drive, etc., que se pueden usar para transferir archivos. A continuación, configuramos un servidor FTP e intentamos utilizar el cliente FTP de Windows para transferir archivos, pero el firewall de red bloqueó el tráfico saliente hacia el puerto 21 (TCP). Intentamos utilizar la herramienta [Impacket smbserver](https://github.com/SecureAuthCorp/impacket/blob/master/examples/smbserver.py) para crear una carpeta y descubrimos que se permitía el tráfico saliente hacia el puerto TCP 445 (SMB). 

Utilizamos este método de transferencia de archivos para copiar correctamente el binario en nuestra máquina de destino y lograr nuestro objetivo de aumentar los privilegios a un usuario de nivel de administrador.

