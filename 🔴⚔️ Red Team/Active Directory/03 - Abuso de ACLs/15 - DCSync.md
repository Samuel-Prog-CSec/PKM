---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[14 - Tácticas de abuso de ACLs]]"
Nota siguiente: "[[16 - Acceso privilegiado]]"
Area: "[[AD Abuso de ACLs.base|Abuso de ACLs]]"
---
---

<mark style="background: #ADCCFFA6;">DCSync abusa del servicio de replicación de AD para pedirle a un DC los secretos del dominio —los hashes de todas las cuentas— haciéndote pasar por otro Domain Controller</mark>. Como usa la replicación legítima (`DRSUAPI`), <mark style="background: #FFB86CA6;">no toca LSASS ni el disco del DC</mark>: no hay volcado de memoria que un EDR detecte en el endpoint.

# El derecho que lo habilita

DCSync requiere dos derechos extendidos sobre el objeto del dominio: `DS-Replication-Get-Changes` y `DS-Replication-Get-Changes-All`. Los tienen Domain Admins, Enterprise Admins y los propios DCs… <mark style="background: #FF5582A6;">pero también cualquiera a quien se los hayan concedido</mark>, a menudo vía un `WriteDACL` abusado, o directamente por `AllExtendedRights` sobre el objeto dominio ([[14 - Tácticas de abuso de ACLs]]).

# Ejecutar el ataque

```shell-session
$ impacket-secretsdump -just-dc-user krbtgt inlanefreight.local/adunn@172.16.5.5
$ impacket-secretsdump -just-dc inlanefreight.local/adunn@172.16.5.5     # todo el dominio
```

```powershell
lsadump::dcsync /domain:inlanefreight.local /user:krbtgt    # mimikatz
```

# El botín

- El hash de **`krbtgt`** → <mark style="background: #8000E1A6;">Golden Ticket</mark>: forjar TGT arbitrarios y persistir como cualquiera (ver [[14 - Pass the Ticket (PtT)]]).
- El hash de **`administrator`** → Pass-the-Hash inmediato ([[13 - Pass the Hash (PtH)]]).
- **Todos** los hashes → compromiso total y material para *cracking* offline.

Es, en la práctica, el equivalente "en caliente" de volcar el [[09 - Ataque a Active Directory y NTDS.dit|NTDS.dit]] — mismo botín, sin apagar el DC ni copiar el fichero.

> [!warning]+ Detección
> DCSync genera el evento `4662` (operación sobre un objeto) con el GUID de replicación —si la SACL de auditoría del objeto dominio está activa—, <mark style="background: #FFB86CA6;">y lo delator es el origen</mark>: una petición de replicación desde algo que **no es un DC** es anómala por definición. `Microsoft Defender for Identity` la detecta con alta fiabilidad. No hay "DCSync sigiloso"; se compensa con el momento y el contexto. Detalle en [[25 - Detección y evasión en AD]].
