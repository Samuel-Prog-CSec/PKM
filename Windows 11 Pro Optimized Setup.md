https://www.youtube.com/watch?v=Ntkc6PeImhU&t=2s

`Win + r` -> `services.msc` -> Experiencia del usuario y telemetría asociada -> `Click derecho` -> Propiedades -> Tipo de inicio -> **Deshabilitado**

Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control` -> *SvcHostSplitThresholdInKB* -> **67108864** (64 GB de RAM instalada * 1024 * 1024)

<mark style="background: #ADCCFFA6;">Liberar RAM porque obliga a borrar DLLs al cerrar una app</mark>: Editor del registro -> `Equipo\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer` -> Crear nuevo valor `DWORD (32 bits)` -> Nombrarlo `AlwaysUnloadDll` -> **Establecer valor a 1** (*Hexadecimal*)

<mark style="background: #ADCCFFA6;">Configuración de Ethernet</mark>: Configuración (Sistema) -> Red e Internet -> Configuración de red avanzada -> Ethernet -> Más opciones de adaptador (Editar) -> *Configurar...* -> Administración de energía -> **Desactivar todo** | Opciones avanzadas -> Ethernet de consumo eficiente de energía -> **Desactivado** | Ethernet ecológico -> **Desactivado** |  Gigabit Lite -> **Desactivado** | Power Saving Mode -> **Desactivado** | Velocidad de enlace WOL y Apagado -> **Sin reducción de velocidad** | Velocidad y Dúplex -> **2.5 Gbps Full Dúplex**

<mark style="background: #ADCCFFA6;">Configuración de arranque</mark>: *msconfig* -> Arranque -> **Todo desactivado en opciones de arranque** -> Click en la unidad de disco principal -> Opciones avanzadas... -> Número de procesadores -> **Desactivado y puesto a 1** | Cantidad máxima de memoria -> **Desactivado y puesto a la mitad de la cantidad que tenga instalada el equipo**

---

# Windows 11 limpio (nueva versión - AtlasOS)
https://www.youtube.com/watch?v=wmFD2EhMNpE&t=114s
https://www.youtube.com/watch?v=xrUKHbf7LLw

---

# Terminal
[Customize Your Windows Terminal with Themes, Fonts & Oh My Posh (2025 Guide)](https://www.youtube.com/watch?v=9zodIcv_7-M)

---

# Customización de Brave Browser
https://www.youtube.com/watch?v=xrUKHbf7LLw
https://www.youtube.com/watch?v=tSfDZiK3eHk
https://youtu.be/W6cKFliWW6Q

---

# Optimizar GPU (PC Sobremesa)
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
- RTX Dynamic Vibrance -> Activado
- Anulación de DLSS -> Recomendado
- Anulación de DLSS - Modo Super Resolución -> DLAA (100%)
- Factores de DSR -> 2.25 DL y 60-80% (suavidad)
- Escalado en imagen -> Si esta activo DLSS SUper resolution -> Desactivado

---

# Optimizar BIOS
- Find CPU settings and enable **Intel VT-x/EPT** (or AMD-V/RVI) and **VT-d**, if available.

---

# Optimizar Teclado / Ratón
- **Reducir input lag del teclado**: ajustes de teclado (`Teclado`) -> Retraso de la repetición y Velocidad de la repetición -> **al máximo** (*Corto* y *Rápida*).
- **Reducir input lag ratón**: ajustes de ratón (`Ratón`) -> Opciones de puntero -> Establecer velocidad de puntero en el **tick número 6**/11 && **Desactivar precisión de puntero**.