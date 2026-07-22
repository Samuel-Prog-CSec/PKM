---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[07 - Password Spraying - visión general]]"
Nota siguiente: "[[09 - Construir la lista de usuarios objetivo]]"
Area: "[[AD Ataques de credenciales.base|Ataques de credenciales]]"
---
---

Antes de rociar necesitas la política de contraseñas del dominio: sobre todo <mark style="background: #ADCCFFA6;">el umbral de bloqueo (`lockout threshold`) y la ventana de observación (`observation window`)</mark>, que marcan cuántos intentos y cada cuánto puedes probar sin bloquear cuentas.

# Con credenciales

Lo más rápido, ya autenticado:

```shell-session
$ nxc smb 172.16.5.5 -u forend -p Klmcargo2 --pass-pol
```

# Sin credenciales (sesión nula / bind anónimo)

Si el dominio permite sesiones SMB nulas o *bind* LDAP anónimo (frecuente en dominios antiguos), sacas la política sin autenticarte:

```shell-session
$ rpcclient -U "" -N 172.16.5.5 -c "getdompwinfo"
$ enum4linux-ng -P 172.16.5.5 -oA ilfreight
$ ldapsearch -H ldap://172.16.5.5 -x -b "DC=inlanefreight,DC=local" | grep -i lockout
```

<mark style="background: #FFB8EBA6;">`enum4linux-ng` es la reescritura mantenida</mark> del viejo `enum4linux` (Python, salida JSON/YAML, más fiable).

# Desde Windows

```powershell
net accounts /domain
Get-DomainPolicy | select -ExpandProperty SystemAccess   # PowerView
```

# Interpretar la política

| Campo | Ejemplo | Qué implica |
| --- | --- | --- |
| `Lockout threshold` | 5 | Máx. 4 intentos por cuenta antes de bloquear. |
| `Observation window` | 30 min | El contador de fallos se resetea cada 30 min. |
| `Minimum password length` | 8 | Filtra tus candidatas (`Welcome1` no vale si el mínimo es 10). |

<mark style="background: #FF5582A6;">Regla operativa: (umbral − 1) intentos por cuenta y por ventana</mark>. Con umbral 5 y ventana 30 min → como mucho 4 pruebas cada media hora. Si el umbral es `0` (sin bloqueo) puedes rociar sin freno, pero <mark style="background: #FFB86CA6;">cada fallo sigue generando un evento `4625` en el DC</mark>.

> [!info]+ Sesiones nulas: cada vez menos
> El *bind* anónimo y las sesiones nulas están deshabilitados por defecto en dominios modernos. Donde funcionan, son un regalo (política + usuarios sin credenciales). Su ausencia no bloquea el spraying: basta un usuario de bajo privilegio.
