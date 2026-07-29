---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Descripción: "Entre bosques distintos, el truco del SID History suele estar bloqueado: el SID filtering está activo por defecto en los trusts de bosque y descarta el ExtraSid"
Fecha de actualización: 2026-07-21
Nota previa: "[[21 - Ataque a trust hijo a padre]]"
Nota siguiente: "[[23 - Hardening de Active Directory]]"
Area: "[[AD Trusts de dominio.base|Trusts de dominio]]"
---
---

Entre bosques distintos, el truco del SID History suele estar bloqueado: <mark style="background: #ADCCFFA6;">el `SID filtering` está activo por defecto en los trusts de bosque</mark> y descarta el ExtraSid. Pero un trust cross-forest sigue filtrando acceso por otras vías.

# Cross-forest Kerberoasting

Un trust permite pedir tickets de servicio a través de él: <mark style="background: #FFB86CA6;">puedes kerberoastear cuentas con SPN del bosque en el que confías</mark>, aunque estén al otro lado, y crackearlas offline:

```powershell
Get-DomainUser -SPN -Domain trusted-forest.local
```

```shell-session
$ GetUserSPNs.py -target-domain trusted-forest.local inlanefreight.local/forend:pass -request
```

Es [[11 - Kerberoasting]] apuntando al otro lado del trust.

# Membresías foráneas

Usuarios o grupos de tu bosque pueden estar añadidos a grupos del bosque de confianza (*foreign members*). <mark style="background: #FF5582A6;">Encontrar dónde tus principals ya tienen acceso al otro lado es acceso gratis</mark>:

```powershell
Get-DomainForeignGroupMember -Domain trusted-forest.local
```

# Reutilización de credenciales

Los administradores que gestionan dos bosques suelen reutilizar contraseñas. Un hash de admin de un bosque, probado con `--local-auth`/PtH contra el otro, cruza la frontera sin explotar nada ([[10 - Password Spraying interno]]).

> [!info]+ El vector cambia entre bosques
> Dentro del bosque, la vía es el SID History ([[21 - Ataque a trust hijo a padre]]). Entre bosques, con SID filtering activo, el vector son <mark style="background: #FFB8EBA6;">kerberoasting a través del trust, membresías foráneas y reutilización de credenciales</mark>. Si el trust tiene `EnableSidHistory` activo (por defecto `No`; se olvida desactivar tras migraciones con ADMT), el ExtraSid también funcionaría cross-forest. Y ojo con **Selective Authentication** (`netdom trust /selectiveauth:yes` en trusts salientes/externos): con ella activa, cada principal necesita una ACE *"Allowed to Authenticate"* explícita sobre el recurso — sin esa ACE, un kerberoasting o una membresía foránea cross-forest devuelve **vacío** sin que sea fallo tuyo; comprueba `Get-ADTrust → SelectiveAuthentication` antes de descartar la vía. BloodHound marca las aristas entre bosques que llevan a acceso.
