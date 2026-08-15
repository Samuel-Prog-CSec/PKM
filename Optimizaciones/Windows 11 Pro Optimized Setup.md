# 1. Configuración Windows 11 Pro (SO)
https://www.youtube.com/watch?v=Ntkc6PeImhU&t=2s

<mark style="background: #FF5582A6;">DEJAR EL PLAN DE ENERGÍA EN EQUILIBRADO</mark>: si se tiene un **procesador X3D de AMD**, mejor dejarlo en equilibrado. Mejor mirarlo siempre el perfecto para cada CPU.

<mark style="background: #ADCCFFA6;">Si no se usa WSL</mark>: Terminal modo admin ->  `Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart`

<mark style="background: #ADCCFFA6;">Desactivar servicio</mark>: terminal admin -> 
`Stop-Service SSDPSRV -Force` 
`Set-Service SSDPSRV -StartupType Disabled`

## 1.1 Servicios
`Win + r` -> `services.msc` -> *Experiencia del usuario y telemetría asociada* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos impresora en Windows</mark>: `Win + r` -> `services.msc` -> *Cola de impresión* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos impresora en Windows</mark>: `Win + r` -> `services.msc` -> *Extensiones y notificaciones de impresora* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Control parental* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos Microsoft Edge</mark>: `Win + r` -> `services.msc` -> *Microsoft Edge Update Service (edgeupdate)* -> `Doble click` -> Tipo de inicio -> **Manual**

<mark style="background: #FFB86CA6;">Si no usamos Microsoft Edge</mark>: `Win + r` -> `services.msc` -> *Microsoft Edge Update Service (edgeupdatem)* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de administración de radio* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Hora de la red de telefonía móvil* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de geolocalización* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de Windows Insider* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio biométrico de Windows* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Telefonía* -> `Doble click` -> Tipo de inicio -> **Manual**

`Win + r` -> `services.msc` -> *Servicio de enumeración de dispositivos de tarjeta inteligente* -> `Doble click` -> Tipo de inicio -> **Manual**

`Win + r` -> `services.msc` -> *Partida guardada en Xbox Live* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de historial de archivos* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio Asistente para la compatibilidad de programas* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Tarjeta inteligente* -> `Doble click` -> Tipo de inicio -> **Manual**

`Win + r` -> `services.msc` -> *Detección SSDP* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Host de dispositivo UPnP* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *WalletService* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Carpetas de trabajo* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servidor* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio FrameServer de la Cámara de Windows* (**SI NO USA WEB CAM O CÁMARA**) -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Adquisición de imágenes de Windows (WIA)* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Filtro de teclado de Microsoft* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio informe errores de Windows* -> `Doble click` -> Tipo de inicio -> **Manual**

`Win + r` -> `services.msc` -> *Fax* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Administrador de autenticación de Xbox Live* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de red de Xbox Live* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de administración de accesorios de Xbox* (**SI NO SE USA MANDO**) -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de zona con cobertura inalámbrica móvil* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Registro remoto* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de compatibilidad con Bluetooth* + *puerta enlace audio BT* (**SI NO SE USA BT**) -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de sensores* / *datos* / *supervisión* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Plataforma de dispositivos conectados* (**SI NO SE CONECTA CON EL TELÉFONO**) -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Administrador de pagos y NFC/SE* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de demostración de tienda* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de enrutador de AllJoyn* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Uso compartido de red del Reprod. Windows Media* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Administrador de mapas descargados* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicios de Escritorio remoto* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Redirector de puerto UM de Escritorio remoto* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

## 1.2 Editor del registro
Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Ndu` -> *Start* -> **2 (Hexadecimal)**

<mark style="background: #ADCCFFA6;">Eliminar servicios ocultos de recolección de datos</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog` -> *Start* -> **0 (Hexadecimal)** (APAGADO)

<mark style="background: #ADCCFFA6;">Eliminar servicios ocultos de recolección de datos</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger` -> *Start* -> **0 (Hexadecimal)** (APAGADO)

<mark style="background: #ADCCFFA6;">Eliminar servicios ocultos de telemetría de red</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\WMI\Autologger\TCPIPLOGGER` -> *Start* -> **0 (Hexadecimal)** (APAGADO)

<mark style="background: #ADCCFFA6;">Liberar RAM porque obliga a borrar DLLs al cerrar una app</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer` -> Crear nuevo valor `DWORD (32 bits)` -> Nombrarlo `AlwaysUnloadDll` -> **Establecer valor a 1** (*Hexadecimal*).

`Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile` -> `SystemResponsiveness` -> **Valor a 0** (*Hexadedcimal*).

`Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile` -> `NetworkThrottlingIndex` -> **Valor a ffffffff** (*Hexadecimal*).

<mark style="background: #ADCCFFA6;">Para desbloquear los 6 perfiles de aceleración del PC</mark>: `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7` -> `Atributtes` -> **Valor a 2** (*Hexadecimal*).

## 1.3 Configuración de red
<mark style="background: #ADCCFFA6;">Configuración de Ethernet</mark>: Configuración (Sistema) -> Red e Internet -> Configuración de red avanzada -> Ethernet -> Más opciones de adaptador (Editar) -> *Configurar...* -> Administración de energía -> **Desactivar todo**
Opciones avanzadas -> Ethernet de consumo eficiente de energía -> **Desactivado**
Ethernet ecológico -> **Desactivado**
Gigabit Lite -> **Desactivado**
Power Saving Mode -> **Desactivado**
Velocidad de enlace WOL y Apagado -> **Sin reducción de velocidad**
Velocidad y Dúplex -> **Autonegociación**

<mark style="background: #ADCCFFA6;">Liberar uso de CPU de temas de paquetes de red</mark>: `sudo netsh int ip set global taskoffload=enabled`

## 1.4 Arranque y disco
<mark style="background: #ADCCFFA6;">Configuración de arranque</mark>: *msconfig* -> Arranque -> **Todo desactivado en opciones de arranque** -> Click en la unidad de disco principal -> Opciones avanzadas... -> Número de procesadores -> **Desactivado y puesto a 1** | Cantidad máxima de memoria -> **Desactivado y puesto a la mitad de la cantidad que tenga instalada el equipo**

<mark style="background: #ADCCFFA6;">Limpieza automática de disco</mark>: Configuración -> Sistema -> Almacenamiento -> Sensor de almacenamiento (*Activado*) -> Limpieza automática de contenido de usuario (*Activado*) -> **Ejecutar sensor de almacenamiento (Mensualmente)** -> **Eliminar archivos de la papelera de reciclaje si llevan en esta más de: (14 días)** -> **Eliminar archivos de carpeta de Descargas si no se han abierto durante más de: (14 días)**

Configuración del sistema -> Arranque -> Opciones avanzadas -> 
![[arranque.png]]

## 1.5 Windows 11 Privacidad
[Herramienta para eliminar app de IA y telemetría](https://hixec.com/winzard/)

## 1.6 Modos de aceleración del procesador
Editar la configuración del plan de energía -> Cambiar la configuración avanzada de energía -> Administración de energía del procesador -> Modo de mejora del rendimiento del procesador -> **Agresiva** | **Eficiencia agresiva** (*en el caso de portátil, únicamente*)

## 1.7 Vaciar caché de la memoria RAM
<mark style="background: #FF5582A6;">NO EJECUTAR CÍCLICAMENTE</mark>, <mark style="background: #FF5582A6;">HARÁ EL SISTEMA MÁS LENTO</mark>. <mark style="background: #ADCCFFA6;">Ejecutar para benchmarking</mark> con caché fría.
1. Descargar [RAMMap](https://learn.microsoft.com/es-es/sysinternals/downloads/rammap)
2. Abrir `RAMMap64.exe`.
3. Click en `Empty` -> Click en `Empty StandBy List`.

## 1.8 Configuración del plan energía
Una vez establecido el plan de energía en `Equilibrado` (o el que corresponda). Configuraremos el plan de energía. `Editar plan de energía` -> `Cambiar la configuración avanzada de energía`.
- Disco duro -> Apagar disco duro tras -> Configuración (Minutos): **0**.
- Configuración de adaptador inalámbrico -> Modo de ahorro de energía -> Configuración: **Rendimiento máximo**.
- Configuración de USB -> Configuración de suspensión selectica de USB -> Configuración: **Deshabilitado**.
- PCI Express -> Administración de energía del estado de vínculos -> Configuración: **Desactivar**.
- Configuración multimedia -> Al compartir multimedia -> Configuración: **Prevenir la suspensión debida a inactividad**.
- Configuración multimedia -> Compensar la calidad de reproducción de video -> Configuración: **Compensación de rendimiento de reproducción de video**.
- Configuración multimedia -> Al reproducir video -> Configuración: **Optimizar calidad de video**.
- AMD Powe Slider -> Overlay -> Configuración: **Mejor desempeño**.
- Gráficos dinámicos intercambiables -> Configuración global -> Configuración: **Maximizar rendimiento**.

## 1.9 Liberar RAM y cuidar el NVMe: Adiós a la Hibernación
Teniendo unos masivos 64GB de RAM DDR5, la función de hibernación de Windows es tu peor enemiga. Por defecto, Windows reserva un espacio equivalente a un gran porcentaje de tu RAM en el disco duro (el archivo `hiberfil.sys`) para volcar los datos cuando el PC se suspende profundamente. **Esto te roba decenas de gigabytes en tu NVMe de 2TB y genera escrituras masivas e innecesarias que degradan la vida útil del SSD**.
- Abre la terminal (`CMD`) como Administrador.
- Escribe el siguiente comando y pulsa Enter: `powercfg.exe /hibernate off`
- Esto borrará el archivo de inmediato, recuperará el espacio para tus repositorios, proyectos y vídeos, y evitará ciclos de escritura inútiles.

---

# 2. Customización de Brave Browser
https://www.youtube.com/watch?v=xrUKHbf7LLw
https://www.youtube.com/watch?v=tSfDZiK3eHk
https://youtu.be/W6cKFliWW6Q

---

# 3. Optimizar GPU (PC Sobremesa)
## Configuración para maximizar calidad (panel de control NVIDIA)
- Escalado de imagen ->  **Desactivado** _(renderiza por debajo de la resolución nativa y upscalea; pierde calidad real)_
- AA muestreado de fotogramas múltiples -> **Desactivado** _(aproxima AA con menos muestras; redundante con DLAA y puede generar artefactos)_
- Antialiasing - FXAA -> **Desactivado** _(difumina la imagen globalmente; contraproducente a 164 PPI y con DLAA activo)_
- Antialiasing - Modo -> **Controlado por la aplicación** _(DLAA se encarga del AA vía driver; "Mejorar" puede generar conflictos con DLAA)_
- Antialiasing - Corrección gama -> **Activado**
- Antialiasing - Transparencia -> **Desactivado**
- CUDA - Política de uso de memoria de la GPU -> **Usar la memoria del sistema como respaldo**
- Compatibilidad con OpenGL GDI -> **Preferir Rendimiento**
- Factores de DSR -> *Escalado DL* -> **Desactivado**
- Filtrado anisotrópico -> **x16**
- Filtrado de texturas - Calidad -> **Alta calidad**
- Filtrado de texturas - Diferencia de LOD -> **Fijación**
- Frecuencia de actualización preferida (monitor) -> **La más alta disponible**
- Modo baja latencia -> **Activado (On)** _(Ultra causa micro-stuttering a 60Hz; On es el equilibrio correcto)_ | **Ultra** _(si el monitor es de más Hz)_
- Modo de control de energia -> **Máximo rendimiento preferido**
- Método actual Vulkan/OpenGL -> **Preferir nativo**
- Oclusión ambiental -> **Desactivado**
- Optimización enlazada -> **Automático**
- Sincronización vertical -> **Activado** _(obligatorio sin adaptive sync para evitar tearing)_ | **Desactivado** _(en monitores gaming de muchos Hz)_ -> Mejor desactivado en general (*y activarlo en el juego*)
- Suavidad de DSR -> **60% (puede variar dependiendo del monitor)**
- Tamaño de la cache del sombreador -> **10 GB** _(la mejor opción en general)_ | **Desactivado** _(algunos juegos pueden dar problemas con esta opción, si se da el caso, valorar desactivar)_
- Tecnologia del monitor -> **Actualización fija**
- Triple búfer -> **Desactivado** -> Mejor desactivado en general
- Frecuencia máxima fotograma -> **58-60**

## NVIDIA APP
- RTX Dynamic Vibrance -> **Desactivado para trabajo / Activado (moderado) para gaming** _(altera la precisión de color; no recomendable para uso profesional)_
- Anulación de DLSS -> **Recomendado**
- Anulación de DLSS - Modo Super Resolución -> **DLAA (100%)** _(AA por IA a resolución nativa completa; máxima calidad)_
- Anulación de DLSS - Modo generación de fotogramas -> **Utilizar la configuración de la aplicación 3D**
- Escalado en imagen -> *Si esta activo DLSS Super resolution* -> **Desactivado**
- RTX Video HDR -> **Activado solo con HDR habilitado en Windows** _(convierte vídeo SDR a HDR10 con IA)_

---

# 4. Optimizar Teclado / Ratón
- **Reducir input lag del teclado**: ajustes de teclado (`Teclado`) -> Retraso de la repetición y Velocidad de la repetición -> **al máximo** (*Corto* y *Rápida*).
- **Reducir input lag ratón**: ajustes de ratón (`Ratón`) -> Opciones de puntero -> Establecer velocidad de puntero en el **tick número 6**/11 && **Desactivar precisión de puntero**.
- **USB Ultra-rápido**: Administrador de dispositivos -> Controladoras de bus serie universal. En todas las entradas que haya: Doble click -> Administrador de energía -> Permitir que el equipo apague este dispositivo para ahorrar energía -> **Desactivado**.
- Administrador de dispositivos -> Dispositivos de interfaz de usuario (HID) -> Dispositivos de periféricos y los "Dispositivo de entrada USB": Doble click -> Administrador de energía -> Permitir que el equipo apague este dispositivo para ahorrar energía -> **Desactivado**.

# 5. Configuración de ventiladores
Usando el software para manejar ventiladores (Armoury Crate o cualquier otro), ajustar lo correpondiente. **Modo inteligente** activado.

## 5.1 Disipador de CPU
**Aceleración y desaceleración**: 1 punto.
- **Punto 1**: 35% | 50ºC
- **Punto 2**: 50% | 65ºC
- **Punto 3**: 70% | 75ºC
- **Punto 4**: 100% | 85ºC

## 5.2 Resto de ventiladores
**Aceleración y desaceleración**: 1 punto.
- **Punto 1**: 35% | 40ºC
- **Punto 2**: 50% | 60ºC
- **Punto 3**: 70% | 75ºC
- **Punto 4**: 100% | 85ºC