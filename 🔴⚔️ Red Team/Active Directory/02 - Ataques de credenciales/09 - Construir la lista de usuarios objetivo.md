---
tags:
  - Active-Directory
  - Windows
  - Linux
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[08 - Enumerar políticas de contraseñas]]"
Nota siguiente: "[[10 - Password Spraying interno]]"
Area: "[[AD Ataques de credenciales.base|Ataques de credenciales]]"
---
---

El spraying necesita combustible: <mark style="background: #ADCCFFA6;">una lista de usuarios válidos del dominio</mark>. Cuanto más completa y depurada, más probable el acierto. Se construye combinando lo que ya sabes hacer, con un objetivo distinto: no explorar, sino **producir un `valid_users.txt`**.

# De dónde salen los nombres

- **OSINT** (formato de email de [[01 - Reconocimiento y enumeración externa]]): de <mark style="background: #FFB86CA6;">"John Smith" derivas `jsmith`, `j.smith`, `john.smith`, `smithj`…</mark>; `username-anarchy` genera todas las permutaciones de golpe.
- **Sin credenciales**: sesión SMB nula (`enum4linux-ng`, `rpcclient -c enumdomusers`), *bind* LDAP anónimo (`ldapsearch`, `windapsearch`) o validación Kerberos con `Kerbrute` (ver [[02 - Enumeración inicial del dominio]]).
- **Con credenciales**: lo más completo, ya autenticado:

```shell-session
$ nxc smb 172.16.5.5 -u forend -p Klmcargo2 --users
```

# Validar y depurar

Las permutaciones de OSINT son candidatas, no usuarios reales. <mark style="background: #ADCCFFA6;">`Kerbrute` las valida contra el KDC sin gastar intentos de login</mark>:

```shell-session
$ kerbrute userenum -d inlanefreight.local --dc 172.16.5.5 candidates.txt -o valid_users.txt
```

<mark style="background: #FFB8EBA6;">Quédate solo con las cuentas habilitadas</mark>: rociar contra cuentas deshabilitadas no da nada y ensucia los logs. Con credenciales, `nxc --users` marca el flag `disabled`.

> [!success]+ El producto
> El resultado es un `valid_users.txt` limpio: la entrada directa de [[10 - Password Spraying interno]]. Un buen fichero de usuarios vale más que diez contraseñas de más.
