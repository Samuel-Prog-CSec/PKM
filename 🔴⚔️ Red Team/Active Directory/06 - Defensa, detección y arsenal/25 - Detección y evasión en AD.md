---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[24 - Auditoría avanzada en AD]]"
Nota siguiente: "[[26 - Arsenal de herramientas AD]]"
Area: "[[AD Defensa y arsenal.base|Defensa y arsenal]]"
---
---

Todas las notas de esta área apuntan aquí. <mark style="background: #ADCCFFA6;">El AD moderno está fuertemente instrumentado</mark>: `Microsoft Defender for Identity` (MDI) analiza el tráfico del DC, el EDR vigila los endpoints y el SIEM correla los eventos de seguridad de Windows. Esta nota consolida <mark style="background: #FFB86CA6;">qué rastro deja cada técnica y cómo reducirlo</mark>.

# El defensor moderno

- **MDI** (antes Azure ATP): sensor en los DCs que detecta reconocimiento LDAP, Kerberoasting, DCSync, PtH/PtT y movimiento lateral casi en tiempo real, correlando comportamiento más que firmas.
- **EDR** (CrowdStrike, SentinelOne, Defender for Endpoint): vigila procesos, inyección y binarios en el endpoint.
- **SIEM**: agrega los eventos de seguridad de todos los DCs y hosts.
- **Honeytokens**: cuentas/SPN/equipos señuelo que solo un atacante tocaría.

# Ataque → telemetría → evasión

| Técnica | Rastro principal | Cómo reducirlo |
| --- | --- | --- |
| LLMNR/NBT-NS poisoning | *honeypot queries*, respuestas anómalas | Relay en vez de crackear; no responder a todo |
| Password spraying | `4625` en volumen desde un origen | Lento, respeta la ventana, usa Kerberos |
| Kerberoasting | `4769` con cifrado `0x17` (RC4) | Solo SPN útiles, en AES, bajo volumen |
| AS-REP roasting | `4768` sin pre-auth | Objetivos concretos, no barrer |
| Recolección BloodHound | recon LDAP masivo (MDI) | `DCOnly`, *throttle* |
| Abuso de ACLs | `5136` (objeto modificado) | Limpieza inmediata del cambio |
| DCSync | `4662` de replicación desde un no-DC | Sin evasión limpia; timing y contexto |
| Golden/Silver Ticket | `4769` anómalos, TGT sin AS-REQ previo | AES, tiempos realistas. **Diamond/Sapphire** (Rubeus `diamond`, impacket `ticketer.py -request -impersonate`) evaden la heurística "TGT sin AS-REQ" al partir de un TGT/PAC legítimo |
| Coacción + relay | autenticación de máquina inesperada | Objetivo puntual, no barridos |
| Acceso RDP/WinRM/MSSQL | `4624` (tipo 10 RDP / tipo 3 WinRM), log operacional de WinRM, activar `xp_cmdshell` | Usa cuentas ya validadas en el grafo; evita `xp_cmdshell` si hay alternativa |
| Snaffling / GPP / SYSVOL | `5145`/`5140` en volumen sobre shares | Apunta a shares conocidos, no barras todos |

# Honeytokens: no muerdas el anzuelo

<mark style="background: #FF5582A6;">Un SPN o una cuenta "jugosa" que aparece sin más puede ser un señuelo</mark>: kerberoastearla o autenticarte con ella dispara una alerta de alta fidelidad. Señales: cuenta con SPN pero `lastLogon` nulo, contraseña antigua sin uso, nombre demasiado apetecible (`svc_backup_admin`). Ante la duda, valida el patrón de uso antes de tocarla.

# Principios de evasión

<mark style="background: #8000E1A6;">No existe "AD sigiloso" absoluto; se trata de reducir superficie y elegir el momento</mark>:

- **Prefiere Kerberos/AES** a NTLM/RC4 (menos vigilado, sin *downgrade* sospechoso).
- **Bajo volumen y ritmo humano**: nada de barrer un /16 ni pedir 500 TGS de golpe.
- **Blend**: herramientas nativas y horarios de administración legítima ([[05 - Living Off the Land]]).
- **Limpia**: revierte SPNs, membresías y `KeyCredentialLink` ([[14 - Tácticas de abuso de ACLs]]).

> [!warning]+ El contexto manda
> Varias técnicas (DCSync, Golden Ticket) no tienen evasión real de la telemetría: en un entorno con MDI se detectan sí o sí. La decisión es entonces *cuándo* y *desde dónde* ejecutarlas, asumiendo el ruido. En un Red Team con objetivo de sigilo eso cambia el plan; en un pentest con ventana acordada, se documenta y se sigue.
