---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Enumeracion
Descripción: "Con credenciales de dominio en la mano —aunque sean de un usuario sin privilegios— la enumeración cambia de marcha: ahora preguntas al dominio, autenticado, por usuarios…"
Fecha de actualización: 2026-07-21
Nota previa: "[[03 - Enumeración de controles de seguridad]]"
Nota siguiente: "[[05 - Living Off the Land]]"
Area: "[[AD Enumeración.base|Enumeración]]"
---
---

Con credenciales de dominio en la mano —aunque sean de un usuario sin privilegios— la enumeración cambia de marcha: ahora preguntas al dominio, **autenticado**, por <mark style="background: #ADCCFFA6;">usuarios, grupos, equipos, sesiones, ACLs y las rutas que llevan hasta `Domain Admin`</mark>. El host de ataque marca el toolset; la meta es la misma. Aquí van ambos.

# Desde Linux

**NetExec (`nxc`)** —el sustituto de `CrackMapExec`— es el punto de entrada:

```shell-session
$ nxc smb 172.16.5.5 -u forend -p Klmcargo2 --users
$ nxc smb 172.16.5.5 -u forend -p Klmcargo2 --groups
$ nxc smb 172.16.5.0/23 -u forend -p Klmcargo2 --loggedon-users
```

<mark style="background: #FF5582A6;">`--loggedon-users` es oro para el movimiento lateral</mark>: revela en qué equipo tiene sesión un administrador. Se complementa con `smbmap`/`smbclient` para *shares* y `rpcclient` para sesiones nulas y *RID cycling*:

```shell-session
$ rpcclient -U "" -N 172.16.5.5
rpcclient $> enumdomusers
```

Para LDAP a bajo nivel, `ldapsearch`, `windapsearch` o `ldeep` extraen usuarios, admins y —clásico— <mark style="background: #FFB8EBA6;">descripciones de cuenta con contraseñas dentro</mark>. Y el recolector del grafo desde Linux:

```shell-session
$ bloodhound-ce-python -u forend -p Klmcargo2 -d inlanefreight.local -ns 172.16.5.5 -c All   # paquete bloodhound-ce (CE), NO bloodhound-python (legacy)
```

# Desde Windows

Si tu host es un Windows unido al dominio, lo más sigiloso es el **módulo `ActiveDirectory` de PowerShell** —firmado por Microsoft, <mark style="background: #FFB8EBA6;">no dispara el AV</mark>—:

```powershell
Get-ADUser -Filter * -Properties * | select samaccountname,description
Get-ADGroupMember -Identity "Domain Admins" -Recursive
Get-ADTrust -Filter *
```

**PowerView** es más ofensivo y expresivo:

```powershell
Get-DomainUser -SPN | select samaccountname     # candidatos a Kerberoasting → [[11 - Kerberoasting]]
Get-DomainGroupMember "Domain Admins" -Recurse
Find-LocalAdminAccess                             # dónde soy admin local
```

`SharpView` es su versión compilada (útil bajo CLM), y **Snaffler** caza credenciales por los *shares* automáticamente.

# BloodHound: la pieza central

<mark style="background: #ADCCFFA6;">`BloodHound` modela AD como un grafo y calcula la ruta más corta desde donde estás hasta Domain Admin</mark>, incluyendo aristas invisibles a mano (ACLs abusables, sesiones, delegaciones). Recolectas con `SharpHound` (Windows) o `bloodhound-ce-python`/`rusthound-ce` (Linux) y cargas el resultado en la GUI.

> [!info]+ BloodHound CE, no el legacy
> Desde 2023 la versión viva es **BloodHound Community Edition** (backend en contenedores, API REST, nuevas *queries*). Los ingestores antiguos y las *custom queries* legacy ya no aplican. Ojo con el ingestor de Linux: `bloodhound-python` (paquete `bloodhound`) es **solo legacy 4.2/4.3**; para CE usa `bloodhound-ce-python` (`pip install bloodhound-ce`) o `rusthound-ce`. `SharpHound` sirve para ambos. El análisis de sus rutas es la base de [[12 - Primer de abuso de ACLs]] y de los ataques que siguen.

<mark style="background: #FFB86CA6;">El grafo convierte "tengo un usuario cualquiera" en "sigue estos 3 saltos hasta DA"</mark> — por eso es la primera herramienta que corres tras conseguir credenciales.

> [!warning]+ La recolección hace ruido
> `SharpHound -c All` (con `Session`/`LoggedOn`) golpea todos los equipos y es muy visible; `Microsoft Defender for Identity` detecta el reconocimiento LDAP masivo. Para sigilo, `--collectionmethod DCOnly` consulta solo al DC a cambio de perder datos de sesión. Detalle en [[25 - Detección y evasión en AD]].
