# 1. Configuración Windows 11 Pro (SO)
https://www.youtube.com/watch?v=Ntkc6PeImhU&t=2s

Si tenemos +16 GB de RAM, es interesante desactivar la compresión de memoria en RAM: `sudo Disable-MMAgent -MemoryCompression`

## 1.1 Servicios
`Win + r` -> `services.msc` -> *Experiencia del usuario y telemetría asociada* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos impresora en Windows</mark>: `Win + r` -> `services.msc` -> *Cola de impresión* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos impresora en Windows</mark>: `Win + r` -> `services.msc` -> *Extensiones y notificaciones de impresora* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Control parental* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos Microsoft Edge</mark>: `Win + r` -> `services.msc` -> *Microsoft Edge Update Service (edgeupdate)* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

<mark style="background: #FFB86CA6;">Si no usamos Microsoft Edge</mark>: `Win + r` -> `services.msc` -> *Microsoft Edge Update Service (edgeupdatem)* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de administración de radio* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Hora de la red de telefonía móvil* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de geolocalización* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de Windows Insider* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio biométrico de Windows* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Telefonía* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Windows Search* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de enumeración de dispositivos de tarjeta inteligente* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Partida guardada en Xbox Live* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio de historial de archivos* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio Asistente para la compatibilidad de programas* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Tarjeta inteligente* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Detección SSDP* -> `Doble click` -> Tipo de inicio -> **Manual**

`Win + r` -> `services.msc` -> *WalletService* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Carpetas de trabajo* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servidor* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio FrameServer de la Cámara de Windows* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Adquisición de imágenes de Windows (WIA)* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Filtro de teclado de Microsoft* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

`Win + r` -> `services.msc` -> *Servicio informe errores de Windows* -> `Doble click` -> Tipo de inicio -> **Deshabilitado**

## 1.2 Editor del registro
Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control` -> *SvcHostSplitThresholdInKB* -> **67108864** (64 GB de RAM instalada * 1024 * 1024)

<mark style="background: #ADCCFFA6;">Eliminar más servicios ocultos de telemetría</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Ndu` -> *Start* -> **4 (Hexadecimal)** (APAGADO)

<mark style="background: #ADCCFFA6;">Liberar RAM porque obliga a borrar DLLs al cerrar una app</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer` -> Crear nuevo valor `DWORD (32 bits)` -> Nombrarlo `AlwaysUnloadDll` -> **Establecer valor a 1** (*Hexadecimal*)

## 1.3 Configuración de red
<mark style="background: #ADCCFFA6;">Configuración de Ethernet</mark>: Configuración (Sistema) -> Red e Internet -> Configuración de red avanzada -> Ethernet -> Más opciones de adaptador (Editar) -> *Configurar...* -> Administración de energía -> **Desactivar todo** | Opciones avanzadas -> Ethernet de consumo eficiente de energía -> **Desactivado** | Ethernet ecológico -> **Desactivado** |  Gigabit Lite -> **Desactivado** | Power Saving Mode -> **Desactivado** | Velocidad de enlace WOL y Apagado -> **Sin reducción de velocidad** | Velocidad y Dúplex -> **2.5 Gbps Full Dúplex**

<mark style="background: #ADCCFFA6;">Liberar uso de CPU de temas de paquetes de red</mark>: `sudo netsh int ip set global taskoffload=enabled`

## 1.4 Arranque y disco
<mark style="background: #ADCCFFA6;">Configuración de arranque</mark>: *msconfig* -> Arranque -> **Todo desactivado en opciones de arranque** -> Click en la unidad de disco principal -> Opciones avanzadas... -> Número de procesadores -> **Desactivado y puesto a 1** | Cantidad máxima de memoria -> **Desactivado y puesto a la mitad de la cantidad que tenga instalada el equipo**

<mark style="background: #ADCCFFA6;">Limpieza automática de disco</mark>: Configuración -> Sistema -> Almacenamiento -> Sensor de almacenamiento (*Activado*) -> Limpieza automática de contenido de usuario (*Activado*) -> **Ejecutar sensor de almacenamiento (Mensualmente)** -> **Eliminar archivos de la papelera de reciclaje si llevan en esta más de: (14 días)** -> **Eliminar archivos de carpeta de Descargas si no se han abierto durante más de: (14 días)**

### 1.4.1 Usar drivers SSD en Windows 11
Windows 11 "traduce" comunicación del SSD a formato para discos más viejos, ralentizando velocidad de los discos más rápidos. Para desbloquear el driver oculto:
1. El primer comando **activa la anulación de la gestión de funciones**: 
	- `reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides /v 735209102 /t REG_DWORD /d 1 /f`
2. El segundo comando **habilita la siguiente clave necesaria**:
	- `reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides /v 1853569164 /t REG_DWORD /d 1 /f`
3. Y el tercero **completa la configuración**:
	- `reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides /v 156965516 /t REG_DWORD /d 1 /f`

#### ¿Cómo sabemos si ha funcionado? 
Para verificarlo, `clic derecho` en el botón de Inicio -> Administrador de dispositivos. El disco SSD ya no aparece bajo la categoría habitual de *Unidades de disco*, sino que ahora se muestra bajo **Discos de almacenamiento**.
> [!important]+
> Doble clic sobre el SSD en esa nueva ubicación. Controlador -> Detalles del controlador, debería aparrecer el nombre del archivo: `nvmedisk.sys`. <mark style="background: #FF5582A6;">Si está eso, ya está corriendo con el motor de Windows Server</mark>. Si sigue estando `disk.sys` o `stornvme.sys`, el *cambio no se ha aplicado*.

## 1.5 Windows 11 Privacidad
[Herramienta para eliminar app de IA y telemetría](https://hixec.com/winzard/)

---

# 2. Terminal
## Estética
[Dibujos ASCII](https://steamcommunity.com/groups/asciiartamalgamation/discussions/8/3008934419468905029/)

## Herramientas
[Herramientas terminal de Windows útiles](https://www.youtube.com/watch?v=6vuEzC3FfdY)

## Fuentes
Instalar [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip).

## YASB
Instalar [YABS](https://github.com/amnweb/yasb?tab=readme-ov-file) e importar configuración y CSS de GitHub.
- [Cava](https://github.com/karlstav/cava.git) puede dar problemas para usarlo, se necesita usar la configuración de GitHub y pegarlo en `C:\Usuarios\Samuel\.config\cava\config.yaml`. También hay que instalar Cava. El antivirus puede que pida permisos para usarlo (audio y micro).

## GlaveVM
Instalar [GlaveVM](https://github.com/glzr-io/glazewm/tree/main) e importar la configuración de GitHub.

---

# 3. Customización de Brave Browser
https://www.youtube.com/watch?v=xrUKHbf7LLw
https://www.youtube.com/watch?v=tSfDZiK3eHk
https://youtu.be/W6cKFliWW6Q

---

# 4. Optimizar GPU (PC Sobremesa)
Controlar la configuración 3D -> Configuración global -> Modo de control de energía -> **Máximo rendimiento preferido**
Controlar la configuración 3D -> Configuración global -> Frecuencia de actualización preferida -> **La más alta disponible**
Controlar la configuración 3D -> Configuración global -> Sincronización vertical -> **Desactivado**

## Configuración para maximizar calidad (panel de control NVIDIA)
- Escalado de imagen ->  **Activar (`85%`)**
- AA muestreado de fotogramas múltiples -> **Activado**
- Antialiasing - FXAA -> **Activado**
- Antialiasing - Modo -> **Mejorar la configuración de la aplicación**
- Antialiasing - Corrección gama -> **Activado**
- Antialiasing - Transparencia -> **8x (Supermuestreo)**
- CUDA - Política de uso de memoria de la GPU -> **Usar la memoria del sistema como respaldo**
- Compatibilidad con OpenGL GDI -> **Preferir compatibilidad**
- Factores de DSR -> *Escalado DL* -> **Poner resolución del monitor (o un poco más)**
- Filtrado anisotrópico -> **x16** u **x8**
- Filtrado de texturas - Calidad -> **Alta calidad**
- Filtrado de texturas - Diferencia de LOD -> **Fijación**
- Frecuencia de actualización preferida (monitor) -> **La más alta disponible**
- Modo baja latencia -> **Ultra**
- Modo de control de energia -> **Máximo rendimiento preferido**
- Método actual Vulkan/OpenGL -> **Preferir nativo**
- Oclusión ambiental -> **Calidad**
- Optimización enlazada -> **Activado**
- Sincronización vertical -> **Desactivado**
- Suavidad de DSR -> **60% (puede variar dependiendo del monitor)**
- Tamaño de la cache del sombreador -> **10 GB**
- Tecnologia del monitor -> **Actualización fija**
- Triple búfer -> *si está sincronización vertical desactivada* -> **Desactivado**

## NVIDIA APP
- RTX Dynamic Vibrance -> **Activado**
- Anulación de DLSS -> **Recomendado**
- Anulación de DLSS - Modo Super Resolución -> **DLAA (100%)**
- Factores de DSR -> **2.25 DL y 60-80% (suavidad)**
- Escalado en imagen -> *Si esta activo DLSS Super resolution* -> **Desactivado**

---

# 5. Optimizar BIOS
- Find CPU settings and enable **Intel VT-x/EPT** (or AMD-V/RVI) and **VT-d**, if available.

---

# 6. Optimizar Teclado / Ratón
- **Reducir input lag del teclado**: ajustes de teclado (`Teclado`) -> Retraso de la repetición y Velocidad de la repetición -> **al máximo** (*Corto* y *Rápida*).
- **Reducir input lag ratón**: ajustes de ratón (`Ratón`) -> Opciones de puntero -> Establecer velocidad de puntero en el **tick número 6**/11 && **Desactivar precisión de puntero**.