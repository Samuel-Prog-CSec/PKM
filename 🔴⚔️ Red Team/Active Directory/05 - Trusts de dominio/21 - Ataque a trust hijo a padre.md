---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[20 - Primer de trusts de dominio]]"
Nota siguiente: "[[22 - Abuso de trust cross-forest]]"
Area: "[[AD Trusts de dominio.base|Trusts de dominio]]"
---
---

Dentro de un bosque, <mark style="background: #FFB86CA6;">comprometer un dominio hijo te entrega el dominio raíz</mark> —y con él `Enterprise Admins`, el control de todo el bosque—. La técnica es el **abuso de SID History** (ataque *ExtraSids*), y funciona porque <mark style="background: #ADCCFFA6;">el filtrado de SIDs no se aplica entre dominios del mismo bosque</mark>: confían por completo unos en otros.

# La idea: SID History y ExtraSids

`SID History` es un atributo pensado para migraciones: permite que una cuenta conserve los SIDs de un dominio anterior. El abuso: <mark style="background: #8000E1A6;">forjas un Golden Ticket para el dominio hijo y le añades, vía SID History, el SID del grupo `Enterprise Admins` del dominio raíz</mark>. El DC raíz confía en ese SID y te trata como admin del bosque.

# El ataque

Necesitas, del dominio hijo ya comprometido: el hash NT de su `krbtgt` (vía [[15 - DCSync]]), el SID del dominio hijo y el SID de `Enterprise Admins` del padre (`…-519`).

Desde **Windows**, con mimikatz o Rubeus:

```powershell
kerberos::golden /user:Administrator /domain:CHILD.inlanefreight.local /sid:<SID-hijo> /krbtgt:<hash> /sids:<SID-EnterpriseAdmins-519> /ptt
```

Desde **Linux**, impacket lo automatiza de punta a punta:

```shell-session
$ raiseChild.py -target-exec <dc-raíz> CHILD.inlanefreight.local/administrator:Password123   # tu resolver DNS debe alcanzar todo el camino hijo→raíz del bosque
```

O manual: `ticketer.py -extra-sid <EA-519> …` + `secretsdump.py` contra el DC raíz. <mark style="background: #FF5582A6;">Con el ticket en memoria, un DCSync contra el DC raíz cierra el bosque.</mark>

> [!info]+ OPSEC: usa AES y considera un Diamond Ticket
> Forjar con el hash NTLM (`/krbtgt:<hash>`) fuerza **RC4**, justo lo que la [[25 - Detección y evasión en AD|detección]] marca. Usa la clave AES: `/aes256:<clave>` (mimikatz) o `-aesKey` (impacket `raiseChild`/`ticketer`). Para más sigilo, un **Diamond Ticket** (`Rubeus diamond /sids:<EA-519>`) parte de un TGT pedido legítimamente (hay `AS-REQ` real) y evade la heurística "TGT sin AS-REQ previo".

> [!info]+ Por qué no lo para el filtrado de SIDs
> El `SID filtering` descarta SIDs "extraños" en autenticaciones que cruzan un trust. Dentro de un mismo bosque **está deshabilitado por defecto** (los dominios se consideran de igual confianza), así que el ExtraSid pasa — se puede poner en cuarentena (`netdom trust /quarantine:yes`), pero casi nadie lo hace porque rompe los grupos universales del bosque. Entre bosques suele estar activo — de ahí que [[22 - Abuso de trust cross-forest]] use otras vías.

> [!warning]+ Es también persistencia
> Un Golden Ticket forjado con el hash de `krbtgt` sobrevive a cambios de contraseña de usuario y dura hasta que se rota `krbtgt` (dos veces). Es Pass-the-Ticket en su forma más potente ([[14 - Pass the Ticket (PtT)]]); su detección, en [[25 - Detección y evasión en AD]].
