# 1. Introducción 
**Event Tracing for Windows (ETW)** es un mecanismo de trazado de alto rendimiento integrado en Windows, que captura eventos tanto de modo usuario como de `kernel`. A diferencia de los [[Registros de eventos de Windows]] convencionales, ETW ofrece telemetría en tiempo real sobre llamadas al sistema, creación/terminación de procesos, actividad de red, cambios en ficheros y registro, y mucho más.

---

# 2. Arquitectura y componentes  
1. **Modelo Publish–Subscribe**  
   - **Controllers**: Inician/detienen sesiones de trazado y habilitan providers.  
     - _Herramienta típica_: `logman.exe`  
   - **Providers**: Generan eventos. Tipos principales:  

| **Tipo**       | **Descripcion**                                 |
| -------------- | ----------------------------------------------- |
| MOF            | Basados en Managed Object Format (esquemas MOF) |
| WPP            | Windows Software Trace Preprocessor             |
| Manifest‑based | Definidos por manifiestos XML                   |
| TraceLogging   | API simplificada, bajo coste de código          |

   - **Sessions**: Subscripciones de controllers a uno/múltiples providers, volcados a ETL.  
   - **Consumers**: Procesan eventos (a ETL, WinAPI, herramientas GUI).  
   - **Channels**: Contenedores lógicos para filtrar eventos por criticidad o uso.  
   - **ETL files**: Archivos de traza para análisis offline y archivo forense.

Ver modelo de Microsoft:
[ETW Architecture](https://docs.microsoft.com/sysinternals/media/sysmon/etw-architecture.png)  

---

# 3. Interacción con ETW  
## 3.1 Listar sesiones activas  
```powershell
logman.exe query -ets
```

## 3.2 Detalles de una sesión
```powershell
logman.exe query "EventLog-System" -ets
```
- Muestra: tamaño, ruta de logs, proveedores suscritos, niveles y keywords.

## 3.3 Listar providers disponibles
```owershell
logman.exe query providers
```
- Filtra con `| findstr "Winlogon"` para centrarte en uno concreto.
- Para un provider:
```powershell
logman.exe query providers Microsoft-Windows-Winlogon
```

## 3.4 Alternativas GUI
- **Performance Monitor**: pestaña “Data Collector Sets” → “Trace Sessions”.
- **EtwExplorer**: GUIs para explorar metadata de providers y eventos.

---

# 4. Telemetría clave y casos de uso

|Provider|Evento clave|Detección / Caso de uso|
|---|---|---|
|Kernel-Process|Creación/terminación de proc|Inyección, hollowing, persistencia|
|Kernel-File|Operaciones de fichero|Exfiltración, ransomware, accesos no autoriz.|
|Kernel-Network|Actividad de red|C2, exfiltración, conexiones sospechosas|
|SMBClient / SMBServer|Tráfico SMB|Movimiento lateral, exfiltración|
|DotNETRuntime|Eventos .NET|Inyección en CLR, abuso de PowerShell|
|PowerShell|Ejecución de comandos|Scripts maliciosos, bypasss de ejecución|
|Kernel-Registry|Modificaciones de registro|Persistencia, instalación de malware|
|CodeIntegrity|Integridad de drivers|Drivers no firmados o maliciosos|
|Antimalware-Service / Protection|Estado del AV/EDR|Desactivación, evasión de antimalware|
|WinRM|Gestión remota|Lateral movement, RCE|
|DNS-Client|Consultas DNS|DNS tunneling, detección de C2|
|VPN-Client|Conexiones VPN|Conexiones no autorizadas|
|Security-Mitigations|Controles mitigaciones|Bypasses de mitigaciones|

> **Tip**: muchos providers nativos generan alto volumen y vienen deshabilitados por defecto. Actívalos sólo para tus sesiones de interés.

---

# 5. Buenas prácticas
1. **Sesiones dedicadas**: define Data Collector Sets por caso de uso (por ejemplo, `ETW-Sysmon-Extended`).
2. **Configuración en XML**: automatiza despliegues con Git + Ansible / DSC.
3. **Monitoreo continuo**: integra outputs ETL en tu SIEM.
4. **Versionado**: almacena configuraciones y scripts en `1_Projects/Sysmon‑Deploy/`.
5. **Análisis guiado**: utiliza PowerShell
```powershell
Get-WinEvent -Path .\trace.etl -FilterHashtable @{ProviderName='Microsoft-Windows-Kernel-Process'; Id=1} 
```

---

# 6. Enlaces y profundizaciones
- **ZK Deep‑dives**
    - [[20250723‑1x2y Proveedores ETW avanzados]]
    - [[20250724‑3z4w Uso de Get-WinEvent y herramientas GUI]]
- **Proyectos relacionados**
    - `1_Projects/Sysmon-Deploy/README.md`
    - `1_Projects/ETW-Capture-Lab/README.md`

---

> **Siguiente paso:**
> 
> 1. Mueve esta nota a `5_Log_Management/ETW_Analysis.md`.
>     
> 2. Enlázala desde tu índice de **Log Management** y desde
>     
>     - `1_SOC_Operations/Dashboards.md`
>         
>     - `6_Tools/SIEM.md`
>         
> 3. Crea notas ZK atómicas para:
>     
>     - Configuración XML de ETW
>         
>     - Casos de filtrado `Get-WinEvent`
>         
>     - Automatización de despliegue
>         
