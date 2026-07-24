---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Post-Explotacion
Fecha de actualización: 2026-07-21
Nota previa: "[[18 - Vulnerabilidades bleeding-edge]]"
Nota siguiente: "[[20 - Primer de trusts de dominio]]"
Area: "[[AD Escalada y movimiento.base|Escalada y movimiento]]"
---
---

No todo son exploits; muchos compromisos salen de <mark style="background: #ADCCFFA6;">configuraciones erróneas que se repiten en casi todos los dominios</mark>. Un repaso de las más rentables.

# Contraseñas en GPP (Group Policy Preferences)

El clásico infalible en dominios con años: las GPP guardaban contraseñas en `SYSVOL` (`Groups.xml`) cifradas con una clave AES que <mark style="background: #FFB86CA6;">Microsoft publicó en su propia documentación</mark> (MS14-025). Cualquiera con acceso al dominio las lee:

```shell-session
$ nxc smb 172.16.5.5 -u forend -p Klmcargo2 -M gpp_password
$ gpp-decrypt <cadena cpassword>
```

# Credenciales a la vista

- **Campo `description`/`info`** de los usuarios: administradores que apuntan la contraseña ahí. `Get-DomainUser | select samaccountname,description`.
- **`PASSWD_NOTREQD`**: cuentas que admiten contraseña vacía.
- **Scripts en SYSVOL y *shares***: credenciales *hardcodeadas* en `.bat`/`.ps1`. <mark style="background: #FF5582A6;">`Snaffler` las caza automáticamente</mark> por todos los *shares* legibles.
- **Sniffing de LDAP**: las aplicaciones que autentican por *simple bind* mandan las credenciales en claro; capturarlas en red (o con un servidor LDAP falso) las expone.
- **gMSA mal permisionadas**: si tu principal está en `msDS-GroupMSAMembership` (sobre-permiso frecuente conforme crece su adopción), `Get-ADServiceAccount -Identity <gmsa> -Properties msDS-ManagedPassword` o `gMSADumper.py` devuelve su contraseña actual en claro.

# Abusos de grupos y coacción

- **Grupos de Exchange** (`Exchange Windows Permissions`): históricamente con `WriteDACL` sobre el dominio → DCSync (**PrivExchange**, corregido en el ciclo de parches de Exchange de febrero 2019). Revisa siempre su membresía.
- **Printer Bug** (`MS-PRN`/`SpoolSample`): otra coacción de autenticación, hermana de PetitPotam → relay ([[18 - Vulnerabilidades bleeding-edge]]).

# DNS y reliquias

`adidnsdump` vuelca las zonas DNS integradas en AD, revelando hosts internos que no aparecían en la enumeración normal (incluidos registros "ocultos"). Y antiguallas como `MS14-068` (falsificación del PAC de Kerberos) solo sirven ya en dominios sin parchear desde 2014.

> [!success]+ El orden de rentabilidad
> En un dominio real, antes de exploits complejos revisa lo barato y fiable: <mark style="background: #FFB8EBA6;">GPP, descripciones, `PASSWD_NOTREQD` y `Snaffler` sobre los *shares*</mark> resuelven más engagements de los que parece. La enumeración con credenciales ([[04 - Enumeración con credenciales]]) ya deja muchos de estos a la vista.

> [!warning]+ Huella
> GPP, la lectura masiva de `description` y sobre todo `Snaffler` sobre shares dejan rastro (accesos a SYSVOL/shares en volumen, `5145`). Apunta a shares/objetos conocidos en vez de barrer todo. Telemetría en [[25 - Detección y evasión en AD]].
