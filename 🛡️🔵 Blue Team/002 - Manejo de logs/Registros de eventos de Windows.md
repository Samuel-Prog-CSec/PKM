# Registros de eventos de Windows
**Windows Event Logs** son una parte intrínseca del sistema operativo Windows y <mark style="background: #ADCCFFA6;">almacenan registros de diferentes componentes del sistema</mark>, incluido el propio sistema, las aplicaciones que se ejecutan en él, los proveedores de ETW, los servicios y otros.

El registro de eventos de Windows ofrece capacidades de registro integrales para errores de aplicaciones, eventos de seguridad e información de diagnóstico. Como profesionales de la ciberseguridad, aprovechamos ampliamente estos registros para el análisis y la detección de intrusiones.

Los registros se clasifican en diferentes registros de eventos, como "Aplicación", "Sistema", "Seguridad" y otros, para organizar eventos según su origen o propósito.

Se puede acceder a los registros de eventos utilizando el `Event Viewer` aplicación o mediante programación utilizando API como la API de registro de eventos de Windows.

Accediendo al `Windows Event Viewer` Como usuario administrativo nos permite explorar los distintos registros disponibles.

Los registros de eventos predeterminados de Windows constan de `Application`, `Security`, `Setup`, `System`, y `Forwarded Events`. Si bien los primeros cuatro registros cubren errores de aplicaciones, eventos de seguridad, actividades de configuración del sistema e información general del sistema, la sección "Eventos reenviados" es única y muestra datos de registro de eventos reenviados desde otras máquinas. Esta función de registro central resulta valiosa para los administradores de sistemas que desean una vista consolidada. En nuestro análisis actual, nos centramos en los registros de eventos de una sola máquina.

Cabe señalar que el Visor de eventos de Windows tiene la capacidad de abrir y mostrar los eventos guardados previamente `.evtx` archivos, que luego se pueden encontrar en la sección "Registros guardados".

![Visor de eventos que muestra registros de DLLHijack con detalles de los eventos de Sysmon, incluidos cambios en los valores del registro e información del proceso.](https://academy.hackthebox.com/storage/modules/216/image89.png)

---

# La anatomía de un registro de eventos
Al examinar `Application` registros, encontramos dos niveles distintos de eventos: `information` y `error`.

![Iconos de información y error con recuentos.](https://academy.hackthebox.com/storage/modules/216/image2.png)

Los eventos de información proporcionan detalles generales de uso de la aplicación, como sus eventos de inicio o parada. Por el contrario, los eventos de error resaltan errores específicos y a menudo ofrecen información detallada sobre los problemas encontrados.

![Error del visor de eventos para SideBySide, ID de evento 35, que detalla una falla en la generación del contexto de activación para Visual Studio con una discrepancia en la arquitectura del procesador.](https://academy.hackthebox.com/storage/modules/216/image3.png)

Cada entrada en el Registro de eventos de Windows es un "Evento" y contiene los siguientes componentes principales:

1. `Log Name`: El nombre del registro de eventos (por ejemplo, Aplicación, Sistema, Seguridad, etc.).
2. `Source`: El software que registró el evento.
3. `Event ID`: Un identificador único para el evento.
4. `Task Category`: A menudo contiene un valor o nombre que puede ayudarnos a comprender el propósito o el uso del evento.
5. `Level`: La gravedad del evento (Información, Advertencia, Error, Crítico y Verboso).
6. `Keywords`: Las palabras clave son banderas que nos permiten categorizar eventos de maneras que van más allá de las otras opciones de clasificación. Generalmente se trata de categorías amplias, como "Éxito de auditoría" o "Fallo de auditoría" en el registro de seguridad.
7. `User`: La cuenta de usuario que se inició sesión cuando ocurrió el evento.
8. `OpCode`: Este campo puede identificar la operación específica que informa el evento.
9. `Logged`: La fecha y hora en que se registró el evento.
10. `Computer`: El nombre de la computadora donde ocurrió el evento.
11. `XML Data`: Toda la información anterior también se incluye en formato XML junto con datos de eventos adicionales.

El `Keywords` El campo es particularmente útil al filtrar registros de eventos para tipos específicos de eventos. Puede mejorar significativamente la precisión de las consultas de búsqueda al permitirnos especificar eventos de interés, haciendo así que la gestión de registros sea más eficiente y efectiva.

Al observar más de cerca el registro de eventos anterior, observamos varios elementos cruciales. El `Event ID` En la esquina superior izquierda sirve como un identificador único, que puede investigarse más a fondo en el sitio web de Microsoft para recopilar información adicional. La etiqueta "SideBySide" junto al ID del evento representa la fuente del evento. A continuación encontramos la descripción general del error, que a menudo contiene detalles enriquecidos. Al hacer clic en los detalles, podemos analizar más a fondo el impacto del evento utilizando XML o una vista bien formateada.

![Detalles del visor de eventos para SideBySide, ID de evento 35, que muestra el proveedor, la versión, el nivel y el tiempo de creación.](https://academy.hackthebox.com/storage/modules/216/image4.png)

Además, podemos extraer información complementaria del registro de eventos, como el ID del proceso donde ocurrió el error, lo que permite un análisis más preciso.

![Detalles del visor de eventos que muestran SystemTime, EventRecordID 1773, ProcessID 636, ThreadID 0, en la computadora ARASHPARSA2BB9.](https://academy.hackthebox.com/storage/modules/216/image5.png)

Cambiando nuestro enfoque a los registros de seguridad, consideremos el ID de evento 4624, un evento que ocurre comúnmente (detallado en [https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4624](https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4624)).

![Registro del Visor de eventos para el Evento 4624, auditoría de seguridad de Microsoft Windows, que muestra el inicio de sesión exitoso de la cuenta con Security ID SYSTEM, nombre de cuenta ARASHPARSA2BB9$ y tipo de inicio de sesión 5.](https://academy.hackthebox.com/storage/modules/216/image6.png)

Según la documentación de Microsoft, este evento significa la creación de una sesión de inicio de sesión en la máquina de destino, originada desde la computadora a la que se accedió donde se estableció la sesión. Dentro de este registro, encontramos detalles cruciales, incluido el "ID de inicio de sesión", que nos permite correlacionar este inicio de sesión con otros eventos que comparten el mismo "ID de inicio de sesión". Otro detalle importante es el “Tipo de inicio de sesión”, que indica el tipo de inicio de sesión. En este caso, especifica un tipo de inicio de sesión de servicio, lo que sugiere que "SISTEMA" inició un nuevo servicio. Sin embargo, se requiere más investigación para determinar el servicio específico involucrado, utilizando técnicas de correlación con datos adicionales como el "ID de inicio de sesión".

---

## Aprovechamiento de consultas XML personalizadas

Para agilizar nuestro análisis, podemos crear consultas XML personalizadas para identificar eventos relacionados utilizando el "ID de inicio de sesión" como punto de partida. Al navegar a "Filtrar registro actual" -> "XML" -> "Editar consulta manualmente", obtenemos acceso a un lenguaje de consulta XML personalizado que permite búsquedas de registros más granulares.

![Configuración del filtro del visor de eventos con consulta XML para registro de seguridad, filtrado por SubjectLogonId 0x3E7.](https://academy.hackthebox.com/storage/modules/216/image7.png)

En la consulta de ejemplo, nos centramos en eventos que contienen el campo "SubjectLogonId" con un valor de "0x3E7". La selección de este valor surge de la necesidad de correlacionar eventos asociados con un "ID de inicio de sesión" específico y comprender los detalles relevantes dentro de esos eventos.

![Detalles del evento 4624: SubjectUserName ARASHPARSA2BB9$, SubjectDomainName WORKGROUP, TargetUserName SYSTEM, LogonType 5, LogonProcessName Advapi.](https://academy.hackthebox.com/storage/modules/216/image8.png)

Vale la pena señalar que si se requiere ayuda para elaborar la consulta, se pueden habilitar filtros automáticos, lo que permite explorar su impacto en la representación XML. Para obtener más orientación, Microsoft ofrece artículos informativos sobre [Filtrado XML avanzado en el Visor de eventos de Windows](https://techcommunity.microsoft.com/t5/ask-the-directory-services-team/advanced-xml-filtering-in-the-windows-event-viewer/ba-p/399761).

Al crear dichas consultas, podemos limitar nuestro enfoque a la cuenta responsable de iniciar el servicio y eliminar detalles innecesarios. Este enfoque ayuda a revelar una imagen más clara de las actividades de inicio de sesión recientes asociadas con el ID de inicio de sesión especificado. Sin embargo, incluso con este refinamiento, la cantidad de datos sigue siendo significativa.

Profundizar en los detalles del registro revela progresivamente una narrativa. Por ejemplo, el análisis comienza con [ID de evento 4907](https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4907), lo que significa un cambio en la política de auditoría.

![Visor de eventos que muestra el Evento 4907, auditoría de seguridad de Microsoft Windows, con detalles de cambio de política de auditoría para la cuenta ARASHPARSA2BB9$, ruta del objeto e ID de inicio de sesión 0x3E7.](https://academy.hackthebox.com/storage/modules/216/image9.png)

Dentro del [descripción del evento](https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/event-4907), encontramos información valiosa, como "Este evento se genera cuando se cambia el SACL de un objeto (por ejemplo, una clave de registro o un archivo)"

En caso de no estar familiarizado con SACL, consulte el enlace proporcionado ([https://docs.microsoft.com/en-us/windows/win32/secauthz/access-control-lists](https://docs.microsoft.com/en-us/windows/win32/secauthz/access-control-lists)) arroja luz sobre las listas de control de acceso (ACL). La "S" en SACL denota una lista de control de acceso al sistema, que permite a los administradores registrar intentos de acceso a objetos seguros. Cada entrada de control de acceso (ACE) dentro de un SACL especifica los tipos de intentos de acceso por parte de un fideicomisario designado que desencadenan la generación de registros en el registro de eventos de seguridad. Los ACE en un SACL pueden generar registros de auditoría en caso de intentos de acceso fallidos, exitosos o de ambos tipos. Para obtener más información sobre los SACL, consulte [Generación de auditoría](https://learn.microsoft.com/en-us/windows/win32/secauthz/audit-generation) y [Acceso SACL derecho](https://learn.microsoft.com/en-us/windows/win32/secauthz/sacl-access-right)."

Con base en esta información, se hace evidente que los permisos de un archivo fueron alterados para modificar el registro o auditoría de los intentos de acceso. Una exploración más profunda de los detalles del evento revela aspectos intrigantes adicionales.

![Detalles del evento 4907: SubjectUserName ARASHPARSA2BB9$, SubjectDomainName WORKGROUP, ObjectType File, ruta ObjectName, ProcessName SetupHost.exe.](https://academy.hackthebox.com/storage/modules/216/image10.png)

Por ejemplo, el proceso responsable del cambio se identifica como "SetupHost.exe", lo que indica un posible proceso de configuración (aunque vale la pena señalar que el malware a veces puede hacerse pasar por nombres legítimos). El nombre del objeto afectado parece ser "bootmanager", y podemos examinar los descriptores de seguridad nuevos y antiguos ("NewSd" y "OldSd") para identificar los cambios. La comprensión del significado de cada campo en el descriptor de seguridad se puede lograr a través de referencias como el artículo [Cuerdas ACE](https://docs.microsoft.com/en-us/windows/win32/secauthz/ace-strings?redirectedfrom=MSDN) y [Comprender la sintaxis SDDL](https://itconnect.uw.edu/wares/msinf/other-help/understanding-sddl-syntax/).

De los eventos observados, podemos inferir que ocurrió un proceso de configuración, que implicó la creación de un nuevo archivo y la configuración inicial de permisos de seguridad para fines de auditoría. Posteriormente, nos encontramos con el evento de inicio de sesión, seguido de un evento de "inicio de sesión especial".

![ID de evento 4624 Inicio de sesión y 4672 Inicio de sesión especial.](https://academy.hackthebox.com/storage/modules/216/image11.png)

Al analizar el evento de inicio de sesión especial, obtenemos información sobre los permisos de token otorgados al usuario tras un inicio de sesión exitoso.

![Evento 4672, auditoría de seguridad de Microsoft Windows, que muestra una cuenta SYSTEM con privilegios especiales como SeAssignPrimaryTokenPrivilege y SeDebugPrivilege.](https://academy.hackthebox.com/storage/modules/216/image12.png)

Puede encontrar una lista completa de privilegios en la documentación sobre [constantes de privilegio](https://docs.microsoft.com/en-us/windows/win32/secauthz/privilege-constants). Por ejemplo, el privilegio "SeDebugPrivilege" indica que el usuario posee la capacidad de alterar memoria que no le pertenece.

---

## Registros de eventos útiles de Windows

Encuentre a continuación una lista indicativa (no exhaustiva) de registros de eventos útiles de Windows.

1. **Registros del sistema Windows**
    
    - [ID de evento 1074](https://serverfault.com/questions/885601/windows-event-codes-for-startup-shutdown-lock-unlock) `(System Shutdown/Restart)`: Este registro de eventos indica cuándo y por qué se apagó o reinició el sistema. Al monitorear estos eventos, puede determinar si hay apagados o reinicios inesperados, que potencialmente revelan actividad maliciosa, como infección de malware o acceso no autorizado del usuario.
    - [ID de evento 6005](https://superuser.com/questions/1137371/how-to-find-out-if-windows-was-running-at-a-given-time) `(The Event log service was started)`: Este registro de eventos marca el momento en que se inició el Servicio de registro de eventos. Este es un registro importante, ya que puede significar un arranque del sistema, proporcionando un punto de partida para investigar el rendimiento del sistema o posibles incidentes de seguridad durante ese período. También se puede utilizar para detectar reinicios no autorizados del sistema.
    - [ID de evento 6006](https://learn.microsoft.com/en-us/answers/questions/235563/server-issue) `(The Event log service was stopped)`: Este registro de eventos significa el momento en que se detuvo el Servicio de registro de eventos. Generalmente se ve cuando el sistema se apaga. Los sucesos anormales o inesperados de este evento podrían indicar una interrupción intencional del servicio para cubrir actividades ilícitas.
    - [ID de evento 6013](https://serverfault.com/questions/885601/windows-event-codes-for-startup-shutdown-lock-unlock) `(Windows uptime)`: Este evento ocurre una vez al día y muestra el tiempo de actividad del sistema en segundos. Un tiempo de actividad más corto de lo esperado podría significar que el sistema se haya reiniciado, lo que podría significar una posible intrusión o actividades no autorizadas en el sistema.
    - [ID de evento 7040](https://www.slideshare.net/Hackerhurricane/finding-attacks-with-these-6-events) `(Service status change)`: Este evento indica un cambio en el tipo de inicio del servicio, que podría ser de manual a automático o viceversa. Si se cambia el tipo de inicio de un servicio crucial, podría ser una señal de manipulación del sistema.
2. **Registros de seguridad de Windows**
    
    - [ID de evento 1102](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=1102) `(The audit log was cleared)`: Borrar el registro de auditoría suele ser una señal de un intento de eliminar evidencia de una intrusión o actividad maliciosa.
    - [ID del evento 1116](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide) `(Antivirus malware detection)`: Este evento es particularmente importante porque registra cuándo Defender detecta un malware. Un aumento en estos eventos podría indicar un ataque dirigido o una infección generalizada de malware.
    - [ID del evento 1118](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide) `(Antivirus remediation activity has started)`: Este evento significa que Defender ha comenzado el proceso de eliminar o poner en cuarentena el malware detectado. Es importante monitorear estos eventos para garantizar que las actividades de remediación tengan éxito.
    - [ID del evento 1119](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide) `(Antivirus remediation activity has succeeded)`: Este evento significa que el proceso de remediación del malware detectado ha sido exitoso. El seguimiento periódico de estos acontecimientos ayudará a garantizar que las amenazas identificadas se neutralicen eficazmente.
    - [ID del evento 1120](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide) `(Antivirus remediation activity has failed)`: Este evento es la contraparte de 1119 e indica que el proceso de remediación ha fallado. Estos eventos deben ser monitoreados de cerca y abordados de inmediato para garantizar que las amenazas sean neutralizadas de manera efectiva.
    - [ID de evento 4624](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4624) `(Successful Logon)`: Este evento registra eventos de inicio de sesión exitosos. Esta información es vital para establecer el comportamiento normal del usuario. Un comportamiento anormal, como intentos de inicio de sesión en horarios extraños o desde diferentes ubicaciones, podría significar una posible amenaza a la seguridad.
    - [ID de evento 4625](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4625) `(Failed Logon)`: Este evento registra intentos fallidos de inicio de sesión. Múltiples intentos fallidos de inicio de sesión podrían significar un ataque de fuerza bruta en curso.
    - [ID de evento 4648](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4648) `(A logon was attempted using explicit credentials)`: Este evento se activa cuando un usuario inicia sesión con credenciales explícitas para ejecutar un programa. Las anomalías en estos eventos de inicio de sesión podrían indicar un movimiento lateral dentro de una red, que es una técnica común utilizada por los atacantes.
    - [ID de evento 4656](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4656) `(A handle to an object was requested)`: Este evento se activa cuando se solicita un identificador de un objeto (como un archivo, una clave de registro o un proceso). Este puede ser un evento útil para detectar intentos de acceder a recursos confidenciales.
    - [ID de evento 4672](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4672) `(Special Privileges Assigned to a New Logon)`: Este evento se registra cada vez que una cuenta inicia sesión con privilegios de superusuario. El seguimiento de estos eventos ayuda a garantizar que los privilegios de los superusuarios no se abusen ni se utilicen de forma maliciosa.
    - [ID de evento 4698](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4698) `(A scheduled task was created)`: Este evento se activa cuando se crea una tarea programada. Monitorear este evento puede ayudarle a detectar mecanismos de persistencia, ya que los atacantes a menudo utilizan tareas programadas para mantener el acceso y ejecutar código malicioso.
    - [ID de evento 4700](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4700) & [ID de evento 4701](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4701) `(A scheduled task was enabled/disabled)`: Esto registra la habilitación o deshabilitación de una tarea programada. Las tareas programadas a menudo son manipuladas por atacantes para lograr persistencia o ejecutar código malicioso, por lo que estos registros pueden proporcionar información valiosa sobre actividades sospechosas.
    - [ID de evento 4702](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4702) `(A scheduled task was updated)`: Al igual que 4698, este evento se activa cuando se actualiza una tarea programada. Monitorear estas actualizaciones puede ayudar a detectar cambios que puedan significar intenciones maliciosas.
    - [ID de evento 4719](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4719) `(System audit policy was changed)`: Este evento registra cambios en la política de auditoría en una computadora. Podría ser una señal de que alguien está tratando de cubrir sus huellas desactivando la auditoría o cambiando qué eventos son auditados.
    - [ID del evento 4738](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4738) `(A user account was changed)`: Este evento registra cualquier cambio realizado en las cuentas de usuario, incluidos cambios en privilegios, membresías de grupos y configuraciones de cuentas. Los cambios inesperados en la cuenta pueden ser una señal de toma de control de la cuenta o de amenazas internas.
    - [ID de evento 4771](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4771) `(Kerberos pre-authentication failed)`: Este evento es similar a 4625 (inicio de sesión fallido) pero específicamente para la autenticación Kerberos. Una cantidad inusual de estos registros podría indicar que un atacante intenta forzar su servicio Kerberos.
    - [ID del evento 4776](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=4776) `(The domain controller attempted to validate the credentials for an account)`: Este evento ayuda a rastrear los intentos exitosos y fallidos de validación de credenciales por parte del controlador de dominio. Múltiples fallas podrían sugerir un ataque de fuerza bruta.
    - [ID de evento 5001](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/troubleshoot-microsoft-defender-antivirus?view=o365-worldwide) `(Antivirus real-time protection configuration has changed)`: Este evento indica que se han modificado las configuraciones de protección en tiempo real de Defender. Los cambios no autorizados podrían indicar un intento de deshabilitar o socavar la funcionalidad de Defender.
    - [ID de evento 5140](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=5140) `(A network share object was accessed)`: Este evento se registra cada vez que se accede a un recurso compartido de red. Esto puede ser fundamental para identificar el acceso no autorizado a recursos compartidos de red.
    - [ID de evento 5142](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=5142) `(A network share object was added)`: Este evento significa la creación de un nuevo recurso compartido de red. Los recursos compartidos de red no autorizados podrían usarse para exfiltrar datos o propagar malware a través de una red.
    - [ID de evento 5145](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=5145) `(A network share object was checked to see whether client can be granted desired access)`: Este evento indica que alguien intentó acceder a un recurso compartido de red. Comprobaciones frecuentes de este tipo podrían indicar que un usuario o un malware está intentando mapear los recursos compartidos de red para futuros exploits.
    - [ID de evento 5157](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=5157) `(The Windows Filtering Platform has blocked a connection)`: Esto se registra cuando la plataforma de filtrado de Windows bloquea un intento de conexión. Esto puede resultar útil para identificar tráfico malicioso en su red.
    - [ID de evento 7045](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/event.aspx?eventid=7045) `(A service was installed in the system)`: Una aparición repentina de servicios desconocidos podría sugerir la instalación de malware, ya que muchos tipos de malware se instalan a sí mismos como servicios.

Recuerde, uno de los aspectos clave de la detección de amenazas es tener una buena comprensión de lo que es "normal" en nuestro entorno. Las anomalías que podrían indicar una amenaza en un entorno podrían ser un comportamiento normal en otro. Es fundamental ajustar nuestros sistemas de monitoreo y alerta a nuestro entorno para minimizar los falsos positivos y hacer que las amenazas reales sean más fáciles de detectar. Además, es esencial contar con una solución de gestión de registros centralizada que pueda recopilar, analizar y alertar sobre estos eventos en tiempo real. Monitorear y revisar periódicamente estos registros puede ayudar en la detección temprana y la mitigación de amenazas. Por último, debemos asegurarnos de correlacionar estos registros con otros registros del sistema y de seguridad para obtener una visión más holística de los eventos de seguridad en nuestro entorno.