---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Explotacion
Descripción: "LDAP es el protocolo para acceder a servicios de directorio (usuarios, grupos, equipos)"
Fecha de actualización: 2026-07-16
Nota previa: "[[IIS Tilde Enumeration]]"
Nota siguiente: "[[Web Mass Assignment Vulnerabilities]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">LDAP es el protocolo para acceder a servicios de directorio</mark> (usuarios, grupos, equipos). Dos implementaciones: **OpenLDAP** (open-source, multiplataforma) y **Active Directory** (Microsoft; usa LDAP como uno de sus protocolos, más Kerberos y DNS). Puertos 389 (plano) / 636 (LDAPS). Muchas apps corporativas lo usan para **autenticación central** → cuando construyen el *search filter* con entrada sin sanitizar, hay **LDAP injection**.

> [!important]+ El grueso está en el sub-tema LDAP Injection
> Esta sección del módulo se solapa por completo con nuestro sub-tema **[[00 - Introducción a LDAP Injection|LDAP Injection]]** (detección, bypass, exfiltración, evasión, herramientas, prevención). Aquí, el ángulo "app común".

# El bypass del comodín `*`

Un login contra AD/OpenLDAP construye un filtro como:

```php
(&(objectClass=user)(sAMAccountName=$username)(userPassword=$password))
```

<mark style="background: #FF5582A6;">El comodín `*` casa cualquier valor</mark>:

- `*` en `username` → casa cualquier usuario (con la contraseña dada).
- `*` en `password` → casa al usuario con cualquier contraseña.
- <mark style="background: #FFB86CA6;">`*` en **ambos** → bypass de autenticación completo</mark>.

Los caracteres de la inyección: `*`, `(`, `)`, `|` (OR), `&` (AND). Las técnicas avanzadas (bypass sin comodín `)(|(&`, exfiltración carácter a carácter) están en [[02 - Bypass de autenticación con LDAP]] y [[03 - Exfiltración de datos y explotación ciega]].

# Enumeración

```shell-session
$ nmap -p- -sC -sV --open 10.129.204.229
80/tcp   open  http  Apache httpd 2.4.41  |_http-title: Login
389/tcp  open  ldap  OpenLDAP 2.2.X - 2.3.X
```

<mark style="background: #8000E1A6;">Un `389/ldap` abierto + una página de login = casi seguro autenticación contra LDAP</mark> → probar `*`/`*`. Con acceso o credenciales, `ldapsearch` interroga el directorio:

```shell-session
$ ldapsearch -H ldap://host:389 -D "cn=admin,dc=example,dc=com" -w secret123 -b "ou=people,dc=example,dc=com" "(mail=john.doe@example.com)"
```

> [!info]+ Modernización
> El caso **Redash** (`GHSL-2024-009`) del [[05 - Arsenal de herramientas LDAP|arsenal LDAP]] prueba que la LDAP injection en apps corporativas sigue **muy viva** (ojo: el caso Ivanti EPMM de 2025 que a veces se cita junto a él **no** es LDAP injection, sino EL injection — ver la nota del arsenal). Ante cualquier app con login "domain account" o `389`/`636` detrás, `*`/`*` es un test de 30 segundos.

Siguiente vulnerabilidad de lógica: [[Web Mass Assignment Vulnerabilities]].
