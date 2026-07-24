---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[02 - Enumeración inicial del dominio]]"
Nota siguiente: "[[04 - Enumeración con credenciales]]"
Area: "[[AD Enumeración.base|Enumeración]]"
---
---

Antes de lanzar payloads o herramientas ruidosas conviene saber **contra qué defensas** juegas en el host donde tienes ejecución. <mark style="background: #ADCCFFA6;">Enumerar los controles de seguridad no los desactiva; te dice qué técnicas son viables y cuáles te van a quemar</mark>. Es reconocimiento defensivo del propio terreno.

# Antivirus y EDR

`Windows Defender` se consulta con PowerShell:

```powershell
Get-MpComputerStatus | Select RealTimeProtectionEnabled, AntivirusEnabled, IsTamperProtected
```

Pero en 2026 <mark style="background: #FFB8EBA6;">lo relevante rara vez es solo el AV nativo</mark>: la mayoría de organizaciones corre un `EDR` (CrowdStrike Falcon, SentinelOne, Microsoft Defender for Endpoint). No se apagan con un comando; se identifican por sus servicios/drivers para elegir un vector que no los despierte:

```powershell
Get-Service | ? { $_.DisplayName -match "defender|crowdstrike|sentinel|cylance|carbon|cortex" }
```

# AppLocker y WDAC

`AppLocker` restringe qué binarios y scripts pueden ejecutarse (por ruta, editor o hash):

```powershell
Get-AppLockerPolicy -Effective | select -ExpandProperty RuleCollections
```

<mark style="background: #FFB86CA6;">Su punto débil clásico son los `LOLBAS`</mark> —binarios firmados por Microsoft en rutas permitidas (`rundll32`, `msbuild`, `installutil`…)— y las carpetas *writable* dentro de rutas en lista blanca. `WDAC` (Windows Defender Application Control) es el sucesor moderno, bastante más difícil de evadir.

# PowerShell Constrained Language Mode

```powershell
$ExecutionContext.SessionState.LanguageMode
```

Si devuelve `ConstrainedLanguage`, <mark style="background: #FF5582A6;">PowerShell está capado</mark>: bloquea .NET arbitrario, COM y buena parte del tooling ofensivo. Suele ir de la mano de AppLocker. Vías de evasión: *downgrade* a PowerShell v2 (`powershell -v 2`) —que además evita el *Script Block Logging* moderno— o *bypasses* de CLM conocidos. Ojo: la v2 requiere `.NET Framework 3.5` (no instalado por defecto) y la *feature* opcional `PowerShell 2.0 Engine`; en un dominio con mínima higiene de parcheo esta vía ya casi no está disponible en 2026.

# LAPS

`LAPS` (Local Administrator Password Solution) aleatoriza la contraseña del administrador local de cada equipo y la guarda en AD. Importa por dos motivos:

- Si está desplegado, <mark style="background: #FFB8EBA6;">reutilizar el hash del admin local (Pass-the-Hash) entre equipos deja de funcionar</mark> — cada máquina tiene una distinta.
- **Quién puede leerla** es en sí una vía de escalada: los *principals* con permiso de lectura sobre `ms-Mcs-AdmPwd` (LAPS legacy) o `msLAPS-EncryptedPassword` (Windows LAPS v2, 2023) extraen credenciales de admin local.

```powershell
Find-LAPSDelegatedGroups   # LAPSToolkit
```

> [!info]+ Enumerar para elegir, no para relajarse
> Conocer las defensas guía la selección de técnica (qué cargar, desde dónde, con qué sigilo); muchas de estas comprobaciones se automatizan en [[05 - Living Off the Land]]. Pero la telemetría moderna va más allá del host: `Microsoft Defender for Identity` observa el tráfico del propio DC. La contrapartida de detección de cada ataque se trata en [[25 - Detección y evasión en AD]].
