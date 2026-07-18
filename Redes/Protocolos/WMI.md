---
tags:
  - Redes
  - Protocolos
  - Windows
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`WMI` (*Windows Management Instrumentation*) es la implementación de Microsoft de los estándares WBEM/CIM</mark>: expone datos de gestión y operaciones sobre casi cualquier componente de Windows (procesos, servicios, hardware, red, registro) de forma programática.

# Transporte y puertos

WMI viaja sobre **DCOM/RPC**:

- **`TCP 135`** — el *RPC Endpoint Mapper*, que indica en qué puerto alto dinámico atender.
- **Puertos altos dinámicos** — la comunicación real tras la negociación con el 135.

# Qué permite

Consultar información del sistema (`Win32_*` classes) y **ejecutar procesos en remoto**. Esta última capacidad lo convierte en un método clásico de **movimiento lateral** en Windows/AD.

# Relevancia ofensiva

Con credenciales válidas, WMI ejecuta comandos en el host remoto (la herramienta de referencia es `wmiexec.py` de impacket), a menudo de forma más sigilosa que otros métodos porque abusa de un mecanismo legítimo de administración. La enumeración y explotación se tratan en [[16 - Gestión remota Windows]].
