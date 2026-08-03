---
tags:
  - Web/Red-Team
  - Thick-Clients
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "Las *thick client applications* se instalan localmente (Java, C++, .NET, Silverlight), típicas de entornos corporativos (ERPs, CRMs, gestión de inventario)"
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Shellshock]]"
Nota siguiente: "[[01 - Vulnerabilidades web en thick clients]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Las *thick client applications* se instalan localmente</mark> (Java, C++, .NET, Silverlight), típicas de entornos corporativos (ERPs, CRMs, gestión de inventario). Se consideran **menos seguras** que las web: procesan y almacenan datos en el cliente, que está en manos del atacante.

**Arquitectura**: *two-tier* (cliente ↔ BD directamente — menos seguro) vs *three-tier* (cliente ↔ servidor de aplicación ↔ BD, normalmente por HTTP/S — más seguro, el atacante no habla directo con la BD).

# Vulnerabilidades típicas

Las web puras (XSS, CSRF) no aplican, pero sí muchas otras: <mark style="background: #FF5582A6;">credenciales/datos sensibles *hardcodeados*</mark>, **DLL hijacking**, *buffer overflow*, [[00 - Introducción a SQL Injection|SQL injection]], *insecure storage*, mala gestión de sesión y de errores.

# Fases y herramientas

| Fase | Herramientas |
| - | - |
| **Info gathering** (framework, arquitectura) | CFF Explorer, Detect It Easy, Process Monitor, Strings |
| **Análisis estático** (decompilación) | dnSpy (.NET), JADX (Java), Ghidra, IDA, Radare2, de4dot |
| **Análisis dinámico** (runtime) | x64dbg, OllyDbg, Frida, ProcMon |
| **Red** (tráfico) | Wireshark, tcpdump, TCPView, Burp Suite |

# Workflow real: extraer credenciales hardcodeadas

Un ejecutable sospechoso (`Restart-OracleService.exe`, hallado en un share SMB `NETLOGON`) parece no hacer nada al ejecutarlo:

1. **ProcMon** revela que crea un fichero temporal en `...\AppData\Local\Temp` y lo **borra** de inmediato.
2. Para capturarlo: cambiar los permisos de la carpeta `Temp` para **impedir el borrado** (Properties → Security → Advanced → deseleccionar *Delete* / *Delete subfolders and files*) → re-ejecutar → aparece un `.bat` (nombre aleatorio).
3. El `.bat` reconstruye desde **base64** un `.exe` y también lo borra. Editar el `.bat` quitando los `del` → obtener el `restart-service.exe`.
4. El `.exe` está ofuscado. Con **x64dbg** → *Memory Map* → localizar la región `MAP` (bytes mágicos `MZ`) → *Dump Memory to File* → `strings` confirma que es un **.NET**.
5. <mark style="background: #8000E1A6;">**de4dot** desofusca → **dnSpy** muestra el código fuente</mark> → un `runas.exe` a medida con **credenciales hardcodeadas** para reiniciar el servicio Oracle.

> [!important]+ La lección
> El cliente es código no confiable: <mark style="background: #FFB86CA6;">todo secreto que viva en él (credenciales, tokens, connection strings) está comprometido</mark>. La combinación ProcMon (dinámico) + volcado de memoria + de4dot/dnSpy (estático) es el flujo canónico para .NET; para Java, JADX/JD-GUI; para nativos, Ghidra/IDA + Frida.

Muchos thick clients son, por dentro, clientes de una API web — y ahí aplican las vulnerabilidades web: [[01 - Vulnerabilidades web en thick clients]].
