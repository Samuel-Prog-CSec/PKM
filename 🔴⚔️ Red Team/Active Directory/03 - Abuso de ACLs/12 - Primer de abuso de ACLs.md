---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[11 - Kerberoasting]]"
Nota siguiente: "[[13 - Enumeración de ACLs]]"
Area: "[[AD Abuso de ACLs.base|Abuso de ACLs]]"
---
---

<mark style="background: #ADCCFFA6;">Las ACLs son el modelo de permisos de Active Directory</mark>: cada objeto del directorio —usuario, grupo, equipo, unidad organizativa, incluso el propio dominio— lleva una lista que define quién puede leerlo y, sobre todo, **quién puede modificarlo**. Cuando esos permisos están mal puestos, un usuario sin privilegios puede tener —sin saberlo— derecho a resetear la contraseña de otro, meterse en un grupo o volcar todos los hashes del dominio. <mark style="background: #FFB86CA6;">Son las autopistas de escalada que BloodHound dibuja.</mark>

# ACL, ACE, DACL y SACL

- **ACL** (Access Control List): la lista de permisos de un objeto. Se divide en:
  - **DACL** (Discretionary ACL): quién tiene acceso y con qué derechos. Es la que se abusa.
  - **SACL** (System ACL): qué accesos se auditan (genera los eventos de seguridad).
- **ACE** (Access Control Entry): cada entrada de la DACL. Un ACE = <mark style="background: #FFB8EBA6;">un *principal* + un derecho + sobre qué objeto</mark> (p. ej. "el grupo Help Desk puede `ForceChangePassword` sobre el usuario adunn").

# Los derechos que importan

No todos los ACE son peligrosos. Los que convierten un permiso en escalada:

| Derecho | Qué permite |
| --- | --- |
| `GenericAll` | Control total del objeto. |
| `GenericWrite` | Escribir cualquier atributo (→ SPN falso, *logon script*, *shadow credentials*). |
| `WriteDACL` | Reescribir la propia ACL → auto-concederse `GenericAll` o DCSync. |
| `WriteOwner` | Hacerse dueño del objeto → luego darse permisos. |
| `ForceChangePassword` | Resetear la contraseña sin conocer la actual. |
| `AddMember` / `Self` | Añadirse a un grupo. |
| `DS-Replication-Get-Changes*` | Replicar el directorio → [[15 - DCSync]]. |

# Por qué importan: las cadenas

El peligro no es un ACE suelto, sino <mark style="background: #8000E1A6;">encadenarlos</mark>: un usuario cualquiera tiene `AddMember` sobre "Help Desk"; "Help Desk" tiene `ForceChangePassword` sobre un admin de TI; ese admin es admin local del servidor donde hay una sesión de Domain Admin. Tres saltos de ACL y estás en DA. Estas rutas son <mark style="background: #FF5582A6;">invisibles a mano</mark> pero triviales para el grafo.

> [!info]+ BloodHound hace el trabajo pesado
> Encadenar ACLs a mano con PowerView es tedioso y propenso a error. `BloodHound` modela cada ACE como una arista del grafo (`ForceChangePassword`, `GenericWrite`, `AddSelf`…) y te da la ruta directa. La enumeración se ve en [[13 - Enumeración de ACLs]] y el abuso concreto en [[14 - Tácticas de abuso de ACLs]].
