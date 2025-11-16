# Conceptos básicos de Sysmon
`System Monitor (Sysmon)`es un servicio del sistema Windows y un controlador de dispositivo que permanece residente durante los reinicios del sistema **para monitorear y registrar la actividad del sistema en el registro de eventos de Windows**. Sysmon proporciona <mark style="background: #ADCCFFA6;">información detallada sobre la creación de procesos, conexiones de red, cambios en el tiempo de creación de archivos y más</mark>.

Los *componentes principales de Sysmon* incluyen:
- Un servicio de Windows <mark style="background: #FFB86CA6;">para monitorear la actividad del sistema</mark>.
- Un controlador de dispositivo que <mark style="background: #FFB86CA6;">ayuda a capturar los datos de actividad del sistema</mark>.
- Un registro de eventos <mark style="background: #FFB86CA6;">para mostrar los datos de actividad capturados</mark>.

La capacidad única de Sysmon radica en su capacidad de<mark style="background: #FFB8EBA6;"> registrar información que normalmente no aparece</mark> en los [[Registros de eventos de Windows]], y esto lo convierte en una herramienta poderosa para el monitoreo profundo del sistema y el análisis forense de ciberseguridad. Se puede encontrar la *lista completa de identificadores de eventos de Sysmon* [aquí](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon).

Para un control más granular sobre qué eventos se registran, <mark style="background: #FFB8EBA6;">Sysmon utiliza un archivo de configuración basado en XML</mark>. El archivo de configuración le <mark style="background: #D2B3FFA6;">permite incluir o excluir ciertos tipos de eventos en función de diferentes atributos</mark>, como nombres de procesos, direcciones IP, etc. Podemos consultar ejemplos populares de archivos de configuración útiles de Sysmon:
- Para una **configuración completa**, podemos visitar: [https://github.com/SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config).
- Otra opción es: [https://github.com/olafhartong/sysmon-modular](https://github.com/olafhartong/sysmon-modular), que proporciona un **enfoque modular**.

## Descarga e instalación
```powershell
sysmon.exe -i -accepteula -h md5,sha256,imphash -l -n
```

Para utilizar una configuración personalizada de `Sysmon`, ejecute lo siguiente:
```powershell
sysmon.exe -c filename.xml
```

> [!info]
>Cabe señalar que [Sysmon para Linux](https://github.com/Sysinternals/SysmonForLinux) también existe.

> [!important]
> Para <mark style="background: #ADCCFFA6;">acceder a los logs de Sysmon</mark>, nos desplazamos al `Event Viewer` y seguiremos el siguiente camino: "*Applications and Services*" -> "*Microsoft*" -> "*Windows*" -> "*Sysmon*".

---

# Ejemplo de detección 1: Detección de secuestro de DLL
Los ID de registro de eventos de Sysmon relevantes para los secuestros de DLL se pueden encontrar en la documentación de Sysmon ([https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon](https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon)). Para detectar un secuestro de DLL, debemos centrarnos en `Event Type 7`, que **corresponde a eventos de carga del módulo**. Para lograrlo,<mark style="background: #FFB8EBA6;"> necesitamos modificar el</mark> `sysmonconfig-export.xml` Archivo de configuración de Sysmon que descargamos desde [https://github.com/SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config).

Al examinar la configuración modificada, podemos observar que el comentario "*include*" significa eventos que deben incluirse.
![Fragmento XML que muestra RuleGroup con ImageLoad configurado en 'include' y una nota sobre que no hay reglas, lo que significa que no se registrará nada.](https://academy.hackthebox.com/storage/modules/216/image14.png)

En el caso de detectar secuestros de DLL, cambiamos "*include*" por "*exclude*" para <mark style="background: #FFB8EBA6;">asegurarnos de que no se excluya nada</mark>, lo que nos permite capturar los datos necesarios.
![Fragmento XML con RuleGroup, ImageLoad configurado en 'excluir' y una nota sobre el uso de 'incluir' sin reglas.](https://academy.hackthebox.com/storage/modules/216/image15.png)

Para utilizar la configuración actualizada de Sysmon, ejecutamos:
```powershell
sysmon.exe -c sysmonconfig-export.xml
```

Veamos ahora <mark style="background: #FFB86CA6;">cómo se ve un evento de ID 7</mark>:
![Entrada de registro de Sysmon: Imagen cargada, ProcessID 8060, Imagen mmc.exe, Imagen cargada psapi.dll, Firmado verdadero, Usuario DESKTOP-N33HELB\Waldo.](https://academy.hackthebox.com/storage/modules/216/image18.png)

> [!done]
> **Contiene el estado de firma de la DLL**, el proceso o <mark style="background: #ABF7F7A6;">imagen responsable de cargar la DLL</mark> y la <mark style="background: #FFB8EBA6;">DLL específica que se cargó</mark>. En nuestro ejemplo, observamos que "`MMC.exe`" cargó "`psapi.dll`", que <mark style="background: #FFB8EBA6;">también está firmado por Microsoft</mark>.

Ahora, **procedamos a construir un mecanismo de detección**. Disponemos de una pieza de información [entrada de blog](https://www.wietzebeukema.nl/blog/hijacking-dlls-in-windows) que proporciona una <mark style="background: #ABF7F7A6;">lista exhaustiva de varias técnicas de secuestro de DLL</mark>. Para nuestra detección, nos centraremos en un secuestro específico que<mark style="background: #D2B3FFA6;"> involucra el ejecutable vulnerable `calc.exe` y una lista de DLL que pueden ser secuestradas</mark>.
![Tabla que muestra calc.exe con DLL asociadas: CRYPTBASE.DLL, edputil.dll, MLANG.dll, PROPSYS.dll, Secur32.dll, SSPICLI.DLL, WININET.dll y sus funciones.](https://academy.hackthebox.com/storage/modules/216/image19.png)

Para simplificar el proceso, podemos utilizar el "hola mundo" de *Stephen Fewer* [DLL reflectante](https://github.com/stephenfewer/ReflectiveDLLInjection/tree/master/bin). Cabe señalar que el secuestro de DLL no requiere DLL reflectantes.

Siguiendo los pasos requeridos, que implican cambiar el nombre `reflective_dll.x64.dll` a `WININET.dll`, cambiando de directorio `calc.exe` desde `C:\Windows\System32` junto con `WININET.dll` a un directorio escribible (como el `Desktop`), y ejecutando `calc.exe`, logramos el objetivo. <mark style="background: #FFB86CA6;">En lugar de la aplicación Calculadora, a se muestra</mark>:
![Mensaje de comando que ejecuta calc.exe, escritorio que muestra WININET.dll e íconos de calc, con un mensaje emergente '¡Hola desde DllMain!' indicando inyección DLL reflectante.](https://academy.hackthebox.com/storage/modules/216/image20.png)

A continuación, <mark style="background: #FFB8EBA6;">analizamos el impacto del secuestro</mark>. Primero, filtramos los registros de eventos para centrarnos en `Event ID 7`, que representa los eventos de carga del módulo, haciendo clic en "*Filtrar registro actual...*".
![Filtre la ventana Registro actual con opciones para el nivel de evento, registros de eventos configurados en Microsoft-Windows-Sysmon/Operational e ID de evento 7.](https://academy.hackthebox.com/storage/modules/216/image21.png)

Posteriormente, buscamos instancias de "`calc.exe`", haciendo clic en "*Buscar...*", para identificar la carga de DLL asociada con nuestro secuestro.
![Entrada de registro de Sysmon: Imagen cargada, ProcessID 6212, Imagen calc.exe, ImageLoaded WININET.dll, Firmado falso, Usuario DESKTOP-N33HELB\Waldo. Busque el cuadro de diálogo abierto para 'calc.exe'.](https://academy.hackthebox.com/storage/modules/216/image43.png)

Ahora, <mark style="background: #D2B3FFA6;">podemos observar varios indicadores de compromiso (IOC) para crear reglas de detección efectivas</mark>. Sin embargo, antes de seguir adelante, comparemos esto con una carga de autenticación de "wininet.dll" por "calc.exe".
![Entrada de registro de Sysmon: Imagen cargada, ProcessID 5464, Imagen calc.exe, ImageLoaded wininet.dll, Firmado verdadero, Usuario DESKTOP-N33HELB\Waldo. Busque el cuadro de diálogo abierto para 'calc.exe'.](https://academy.hackthebox.com/storage/modules/216/image23.png)

<mark style="background: #ADCCFFA6;">Exploremos estos IOC</mark>:
1. "`calc.exe`", originalmente ubicado en `System32`, **no debe encontrarse en un directorio escribible**. Por lo tanto, una copia de "`calc.exe`" en un directorio escribible sirve como IOC, ya que <mark style="background: #FF5582A6;">siempre debería residir en `System32` o potencialmente en `Syswow64`</mark>.
2. "`WININET.dll`", originalmente ubicado en `System32`, **no debe cargarse fuera de `System32` mediante `calc.exe`**. Si se producen instancias de carga de "`WININET.dll`" fuera de `System32` con "`calc.exe`" como proceso principal, indica un secuestro de DLL dentro de calc.exe. Si bien es necesario tener precaución al alertar sobre todas las instancias de carga de "WININET.dll" fuera de System32 (ya que <mark style="background: #FFB8EBA6;">algunas aplicaciones pueden empaquetar versiones específicas de DLL para mayor estabilidad</mark>), en el caso de "`calc.exe`", podemos <mark style="background: #FF5582A6;">afirmar con confianza un secuestro debido al nombre inmutable de la DLL, que los atacantes no pueden modificar para evadir la detección</mark>.
3. El "`WININET.dll`" original está firmado por Microsoft, mientras que <mark style="background: #D2B3FFA6;">nuestra DLL inyectada permanece sin firmar</mark>.

> [!danger]
> Estos tres potentes IOC <mark style="background: #ADCCFFA6;">proporcionan un medio eficaz para detectar un secuestro de DLL</mark> que involucra calc.exe.

---

# Ejemplo de detección 2: Detección de inyección no administrada de PowerShell/C-Sharp
`C#` se considera un lenguaje "*administrado*", lo que significa que **requiere un entorno de ejecución backend para ejecutar su código**. El [Tiempo de ejecución en lenguaje común (CLR)](https://docs.microsoft.com/en-us/dotnet/standard/clr) sirve como este entorno de ejecución. El [Código administrado](https://docs.microsoft.com/en-us/dotnet/standard/managed-code) **no se ejecuta directamente como ensamblaje**; en cambio, <mark style="background: #ADCCFFA6;">se compila en un formato de código de bytes que el entorno de ejecución procesa y ejecuta</mark>. En consecuencia, un *proceso administrado depende del CLR para ejecutar código C#*.

Como defensores, podemos aprovechar este conocimiento para detectar inyecciones o ejecuciones inusuales de `C#` dentro de nuestro entorno. Para lograr esto, podemos utilizar una utilidad llamada [Hacker de procesos](https://processhacker.sourceforge.io/).
![Administrador de tareas que muestra procesos como Microsoft.Photos.exe, msedge.exe, powershell.exe, ProcessHacker.exe, con detalles de uso de CPU y memoria.](https://academy.hackthebox.com/storage/modules/216/image24.png)

Al utilizar `Process Hacker`, podemos observar una variedad de procesos dentro de nuestro entorno. Al ordenar los procesos por nombre, podemos identificar distinciones interesantes codificadas por colores. Cabe destacar que "`powershell.exe`", un <mark style="background: #FFB8EBA6;">proceso administrado, está resaltado en verde en comparación con otros procesos</mark>. Al pasar el cursor sobre `powershell.exe` se revela la etiqueta "*El proceso está administrado (.NET)*", confirmando su estado administrado.
![Información sobre herramientas del Administrador de tareas para powershell.exe, que muestra la ruta del archivo, versión 10.0.19041.546, firmada por Microsoft, host de consola conhost.exe (5092).](https://academy.hackthebox.com/storage/modules/216/image25.png)

Vamos a examinar las cargas del módulo para `powershell.exe`, haciendo clic derecho en `powershell.exe`, haciendo clic en "*Propiedades*" y navegando a "*Módulos*", podemos encontrar información relevante.
![Imagen que muestra clr.dll y drjit.dll con direcciones de memoria, tamaños y descripciones para Microsoft.Componentes de NET Runtime.](https://academy.hackthebox.com/storage/modules/216/image26.png)

> [!info]
> La presencia de `clr.dll` y `clrjit.dll` deberían atraer nuestra atención. Estas 2 DLL se utilizan cuando se ejecuta código `C#` como <mark style="background: #D2B3FFA6;">parte del tiempo de ejecución para ejecutar el código de bytes</mark>. Si observamos **estas DLL cargadas en procesos que normalmente no las requieren**, sugiere un potencial [ejecutar-ensamblaje](https://www.cobaltstrike.com/blog/cobalt-strike-3-11-the-snake-that-eats-its-tail/) o un ataque de [inyección de PowerShell no administrada](https://www.youtube.com/watch?v=7tvfb9poTKg&ab_channel=RaphaelMudge).

Para mostrar la inyección de PowerShell no administrada, podemos inyectar un [DLL no administrada similar a PowerShell](https://github.com/leechristensen/UnmanagedPowerShell) en un proceso aleatorio, como `spoolsv.exe`. Podemos hacerlo utilizando el [Proyecto PSInject](https://github.com/EmpireProject/PSInject) de la siguiente manera.
```powershell
 powershell -ep bypass
 Import-Module .\Invoke-PSInject.ps1
 Invoke-PSInject -ProcId [Process ID of spoolsv.exe] -PoshCode "V3JpdGUtSG9zdCAiSGVsbG8sIEd1cnU5OSEi"
```
![Información sobre herramientas para spoolsv.exe que muestra la ruta del archivo, versión 10.0.19041.1288, firmada por Microsoft y asociada con el servicio Print Spooler.](https://academy.hackthebox.com/storage/modules/216/image27.png)

Después de la inyección, observamos que "`spoolsv.exe`" <mark style="background: #FF5582A6;">pasa de un estado no administrado a uno administrado</mark>.
![Información sobre herramientas para spoolsv.exe que muestra la ruta del archivo, versión 10.0.19041.1288, firmada por Microsoft, asociada con el servicio Print Spooler y administrada por .NETO.](https://academy.hackthebox.com/storage/modules/216/image28.png)

Además, haciendo referencia a la pestaña "*Módulos*" relacionada de `Process Hacker` y `Sysmon Event ID 7`, podemos <mark style="background: #FFB86CA6;">examinar la información de carga de las DLL para validar la presencia de las DLL mencionadas anteriormente</mark>.
![Ventana de propiedades para spoolsv.exe que muestra módulos como advapi32.dll, amsi.dll, APMon.dll, con direcciones base, tamaños y descripciones.](https://academy.hackthebox.com/storage/modules/216/image29.png) ![Evento Sysmon 7: Imagen cargada, ProcessID 2792, Image spoolsv.exe, ImageLoaded clr.dll, Microsoft .NET Runtime, firmado por Microsoft, Usuario NT AUTHORITY\SYSTEM.](https://academy.hackthebox.com/storage/modules/216/image30.png)

---

# Ejemplo de detección 3: Detección de dumping de credenciales
Una **herramienta ampliamente utilizada para el dumping de credenciales** es [Mimikatz](https://github.com/gentilkiwi/mimikatz), ofreciendo varios <mark style="background: #FFB8EBA6;">métodos para extraer credenciales de Windows</mark>. Un comando específico, "`sekurlsa::logonpasswords`", permite volcar hashes de contraseñas o, contraseñas de texto sin formato accediendo al [Servicio del Subsistema de la Autoridad de Seguridad Local (LSASS)](https://en.wikipedia.org/wiki/Local_Security_Authority_Subsystem_Service). `LSASS` es **responsable de administrar las credenciales de los usuarios y es un objetivo principal para herramientas de eliminación de credenciales** como *Mimikatz*.
```powershell
mimikatz.exe

  .#####.   mimikatz 2.2.0 (x64) #18362 Feb 29 2020 11:13:36
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )
 ## \ / ##       > http://blog.gentilkiwi.com/mimikatz
 '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )
  '#####'        > http://pingcastle.com / http://mysmartlogon.com   ***/

mimikatz # privilege::debug
Privilege '20' OK

mimikatz # sekurlsa::logonpasswords

Authentication Id : 0 ; 1128191 (00000000:001136ff)
Session           : RemoteInteractive from 2
User Name         : Administrator
Domain            : DESKTOP-NU10MTO
Logon Server      : DESKTOP-NU10MTO
Logon Time        : 5/31/2023 4:14:41 PM
SID               : S-1-5-21-2712802632-2324259492-1677155984-500
        msv :
         [00000003] Primary
         * Username : Administrator
         * Domain   : DESKTOP-NU10MTO
         * NTLM     : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
         * SHA1     : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0812156b
        tspkg :
        wdigest :
         * Username : Administrator
         * Domain   : DESKTOP-NU10MTO
         * Password : (null)
        kerberos :
         * Username : Administrator
         * Domain   : DESKTOP-NU10MTO
         * Password : (null)
        ssp :   KO
        credman :
```

Para detectar esta actividad, en lugar de centrarnos en las cargas de DLL, centramos nuestra atención en los **eventos de acceso al proceso**. Comprobando `Sysmon event ID 10`, que representa eventos "*ProcessAccess*", podemos <mark style="background: #FFB86CA6;">identificar cualquier intento sospechoso de acceder a `LSASS`</mark>.
 ![Evento Sysmon 10: Proceso accedido, SourceImage AgentEXE.exe, TargetImage lsass.exe, SourceUser DESKTOP-R4PEEIF\waldo, TargetUser NT AUTHORITY\SYSTEM.](https://academy.hackthebox.com/storage/modules/216/image33.png)

> [!attention]
> Si observamos un <mark style="background: #D2B3FFA6;">archivo aleatorio</mark> ("`AgentEXE`" en este caso) de una <mark style="background: #D2B3FFA6;">carpeta aleatoria</mark> ("`Descargas`" en este caso) que<mark style="background: #D2B3FFA6;"> intenta acceder a LSASS</mark>, **indica un comportamiento inusual**. Además, si el `SourceUser` <mark style="background: #FFB8EBA6;">es diferente del</mark> `TargetUser` (por ejemplo, "waldo" como el `SourceUser` y "SISTEMA" como el `TargetUser`) **enfatiza aún más la anormalidad**. También vale la pena señalar que, como parte del proceso de eliminación de credenciales basado en mimikatz, el usuario debe solicitar [SeDebugPrivilegios](https://devblogs.microsoft.com/oldnewthing/20080314-00/?p=23113). Como sugiere el nombre, se utiliza principalmente para depuración. Este *puede ser otro indicador de compromiso (IOC)*.