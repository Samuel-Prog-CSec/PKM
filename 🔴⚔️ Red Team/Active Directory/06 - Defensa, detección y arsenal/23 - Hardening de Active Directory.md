---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Reporting
Fecha de actualización: 2026-07-21
Nota previa: "[[22 - Abuso de trust cross-forest]]"
Nota siguiente: "[[24 - Auditoría avanzada en AD]]"
Area: "[[AD Defensa y arsenal.base|Defensa y arsenal]]"
---
---

La otra cara del módulo: cómo se defiende AD. Para el pentester no es relleno — <mark style="background: #ADCCFFA6;">saber qué controles esperar te dice qué ataques van a fallar, y recomendar la remediación es parte del trabajo</mark>.

# Documentar y auditar

No se protege lo que no se conoce. La base es un inventario vivo: cuentas privilegiadas, `SPNs`, trusts, GPOs, delegaciones y ACLs sensibles. <mark style="background: #FFB8EBA6;">La mayoría de las rutas que explota este módulo existen porque nadie las auditó</mark>. Herramientas de medición en [[24 - Auditoría avanzada en AD]].

# Los controles que rompen las cadenas

| Control | Ataque que mitiga |
| --- | --- |
| `Protected Users` + Authentication Silos | PtH, delegación, robo de credenciales (bloqueo total); PtT (parcial — TGT máx. 4h no renovable, no lo impide) |
| `gMSA` (cuentas de servicio gestionadas) | [[11 - Kerberoasting]] (contraseñas de 120+ chars, rotadas solas) |
| `LAPS` / LAPS v2 | Reutilización de admin local ([[10 - Password Spraying interno]]) |
| Deshabilitar `LLMNR`/`NBT-NS` | [[06 - Envenenamiento LLMNR y NBT-NS]] |
| `SMB signing` + LDAP signing/channel binding | NTLM relay |
| Administración por niveles (tier 0/1/2) | Movimiento lateral, sesiones de DA en estaciones |
| Rotar `krbtgt` (2×) | Golden Ticket ([[21 - Ataque a trust hijo a padre]]) |
| Selective Authentication en trusts salientes | Kerberoasting cross-forest y foreign membership ([[22 - Abuso de trust cross-forest]]) |
| SID filtering/quarantine + auditar `sIDHistory` + `EnableSidHistory` off tras migraciones | ExtraSids / SID History ([[21 - Ataque a trust hijo a padre]]) |

<mark style="background: #FFB86CA6;">Casi cada ataque de esta área tiene un control que lo neutraliza</mark>; el problema es que rara vez están todos puestos.

# El modelo por niveles (tiering)

El control estructural más potente es <mark style="background: #8000E1A6;">separar las credenciales por niveles</mark>: los admins de dominio (tier 0) nunca inician sesión en estaciones (tier 2), así comprometer un endpoint no expone credenciales de DA. Rompe la premisa de casi todo el movimiento lateral.

> [!info]+ Material de informe
> Esta nota es tu chuleta de remediación: por cada hallazgo del engagement, aquí está el control que lo cierra. Mapea cada uno a MITRE ATT&CK en el informe para dar contexto al cliente.
