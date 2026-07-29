---
tags:
  - Redes
  - Protocolos
  - Windows
Descripción: "WinRM (*Windows Remote Management*) es la implementación de Microsoft del protocolo WS-Management: administración remota de Windows mediante mensajes SOAP sobre HTTP(S)"
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`WinRM` (*Windows Remote Management*) es la implementación de Microsoft del protocolo **WS-Management**</mark>: administración remota de Windows mediante mensajes SOAP sobre HTTP(S). Es el motor que hay debajo de **PowerShell Remoting** (`Enter-PSSession`, `Invoke-Command`).

# Puertos

- **`TCP 5985`** — WinRM sobre HTTP.
- **`TCP 5986`** — WinRM sobre HTTPS.

Está **habilitado por defecto desde Windows Server 2012** (en Windows cliente —10/11— sigue **desactivado** por defecto).

# Autenticación y autorización

- Negocia `NTLM`/`Kerberos` (Negotiate).
- <mark style="background: #FFB8EBA6;">Para obtener shell hace falta ser miembro del grupo `Remote Management Users` o administrador local</mark>. Por eso WinRM es un vector **post-credencial**: primero consigues las credenciales, luego lo usas para ejecutar.

# Relevancia ofensiva

Con credenciales válidas, WinRM da una **shell PowerShell completa** en el host remoto — la vía de ejecución preferida en pentest de Windows/AD (la herramienta estrella es `evil-winrm`). La enumeración y explotación se tratan en [[16 - Gestión remota Windows]].
