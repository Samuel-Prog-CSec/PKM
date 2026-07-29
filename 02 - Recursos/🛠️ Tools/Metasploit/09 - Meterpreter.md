---
tags:
  - Pentesting/Explotacion
  - Pentesting/Post-Explotacion
  - Metasploit
Descripción: "Meterpreter es el payload avanzado de Metasploit: un agente que corre enteramente en memoria y ofrece una API completa de post-explotación — enumerar, escalar, robar…"
Fecha de actualización: 2026-07-18
Nota previa: "[[08 - Sesiones y Jobs]]"
Nota siguiente: "[[10 - Escritura e importación de módulos]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

<mark style="background: #ADCCFFA6;">`Meterpreter` es el payload avanzado de Metasploit: un agente que corre **enteramente en memoria** y ofrece una API completa de post-explotación</mark> — enumerar, escalar, robar credenciales, pivotar y manipular el host, todo desde una sola sesión cifrada. Es la joya del framework y, a la vez, su mayor riesgo de detección.

# Cómo funciona: in-memory y cifrado

Meterpreter no se escribe en disco: se inyecta reflexivamente (`Reflective DLL Injection`) en la memoria de un proceso y se ejecuta desde ahí. <mark style="background: #FFB86CA6;">Al no tocar disco, evade los antivirus basados en ficheros</mark>. La comunicación con el handler va cifrada (TLS con `reverse_https`), así que el contenido no es inspeccionable en la red.

> [!warning]+ In-memory ≠ invisible
> Que no toque disco **no** significa que sea indetectable. <mark style="background: #FF5582A6;">Meterpreter es de los payloads más fichados de la industria</mark>: el EDR detecta el patrón de *reflective injection*, la migración de procesos y las firmas del stub en memoria; el análisis de red identifica el *staging* y los keep-alives aunque el tráfico esté cifrado (`JA3/JA4`). Todo el detalle y las alternativas, en [[12 - Detección y evasión]].

# Comandos esenciales

| Comando | Función |
| --- | --- |
| `sysinfo` | SO, arquitectura, dominio del host |
| `getuid` | Con qué usuario corremos |
| `getpid` / `ps` | PID actual / listado de procesos |
| `migrate <pid>` | Mover Meterpreter a otro proceso |
| `getsystem` | Intento de escalada a `SYSTEM` |
| `hashdump` | Volcar hashes de la SAM |
| `load kiwi` | Cargar Mimikatz integrado |
| `upload` / `download` | Transferir ficheros |
| `shell` | Caer a una shell nativa (`cmd`/`bash`) |
| `portfwd` | Reenvío de puertos a través de la sesión |
| `screenshot` / `keyscan_start` | Captura de pantalla / keylogger |

# Migración de proceso

`migrate` mueve el agente de un proceso a otro. Se hace por dos motivos:

- **Estabilidad**: si Meterpreter vive en el proceso que explotamos (p. ej. un servicio que puede reiniciarse o que el usuario cierra), perder ese proceso mata la sesión. Migrar a un proceso estable (`explorer.exe`, `winlogon.exe`) la protege.
- **Sigilo**: <mark style="background: #8000E1A6;">migrar a un proceso legítimo y esperado dificulta que destaque</mark> — aunque los EDR modernos vigilan precisamente la *creación de hilos remotos* que implica la migración, así que es un arma de doble filo.

```shell-session
meterpreter > ps                  # localizar un proceso objetivo
meterpreter > migrate 1420        # migrar por PID
```

# Post-explotación

Meterpreter es la plataforma desde la que se lanza el robo de credenciales y la escalada:

```shell-session
meterpreter > getsystem                    # escalada a SYSTEM (si se puede)
meterpreter > hashdump                     # hashes de la SAM
meterpreter > load kiwi                     # Mimikatz
meterpreter > creds_all                     # credenciales en memoria (LSASS)
meterpreter > run post/windows/gather/...  # módulos post
```

<mark style="background: #FFB86CA6;">`hashdump`, `kiwi`/Mimikatz y el volcado de `LSASS` son la puerta al robo de credenciales</mark> — que se trata a fondo en el sub-tema de *Password Attacks* (ataque a SAM, LSASS, NTDS.dit). Meterpreter es solo el vehículo para ejecutarlo.

# Extensiones

Meterpreter carga capacidades bajo demanda:

```shell-session
meterpreter > load stdapi     # API estándar (normalmente ya cargada)
meterpreter > load priv       # funciones de privilegio (hashdump, timestomp)
meterpreter > load kiwi       # Mimikatz
meterpreter > load python     # ejecutar Python en el host
```

> [!info]+ Cuándo NO usar Meterpreter
> Frente a un cliente con EDR maduro, Meterpreter cae rápido. La decisión profesional suele ser: usarlo en objetivos sin defensas (labs, hosts legacy), y para lo demás migrar a un payload `shell/...` discreto o a un C2 sigiloso ([[13 - Arsenal - automatización y alternativas|Sliver, Havoc]]). La potencia de Meterpreter no compensa si te quema el acceso.

Vista la explotación y post-explotación, el siguiente nivel es crear tus propias piezas: [[10 - Escritura e importación de módulos|escribir e importar módulos]].
