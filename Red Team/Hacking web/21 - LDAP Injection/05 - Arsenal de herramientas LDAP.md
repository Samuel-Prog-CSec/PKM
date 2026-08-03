---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "A diferencia de la SQLi (sqlmap) o la XPath (XCat), la LDAP injection no tiene un explotador estándar de facto"
Fecha de actualización: 2026-07-16
Nota previa: "[[04 - Evasión de filtros en LDAP Injection]]"
Nota siguiente: "[[06 - Prevención de LDAP Injection]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

<mark style="background: #FFB8EBA6;">A diferencia de la SQLi (`sqlmap`) o la XPath (`XCat`), la LDAP injection no tiene un explotador estándar de facto</mark>. La explotación —sobre todo la ciega— se apoya en Burp y en scripts a medida. Por eso el conocimiento manual de las notas anteriores pesa aquí aún más.

# Burp Suite / Caido

El caballo de batalla. **Repeater** para confirmar el contexto y ajustar el `payload`; **Intruder** para el brute-force carácter a carácter de la [[03 - Exfiltración de datos y explotación ciega|extracción ciega]] (posición × charset) y para probar variantes de estructura de filtro. Burp Pro incluye checks de LDAP injection en su scanner activo.

# Scripting (Python)

Para la extracción blind, un script propio es lo más eficiente: un bucle que construye el filtro de subcadena (`(uid=htb-stdnt)(password=<prefijo>*)`), envía la petición y lee el oráculo. Las librerías `python-ldap` (`ldap.filter.escape_filter_chars`) y `ldap3` ayudan tanto a atacar como, una vez dentro, a consultar el directorio.

# ldapsearch (post-explotación)

Conseguido acceso o credenciales, `ldapsearch` interroga el directorio directamente para enumerar entradas y atributos — el paso natural tras el bypass:

```shell-session
$ ldapsearch -x -H ldap://target:389 -b "dc=example,dc=htb" "(objectClass=*)"
```

# Librerías de payloads y detección masiva

[PayloadsAllTheThings — LDAP Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/LDAP%20Injection/) mantiene el catálogo de `payloads` para alimentar Intruder. Para barridos en bug bounty, `nuclei` tiene alguna plantilla de detección (no de explotación).

> [!important]+ Sin herramienta dominante = el manual manda
> No hay un botón "dump" como en SQLi. <mark style="background: #8000E1A6;">Saber construir el comodín, el `)(|(&` y el brute-force por rangos a mano es lo que permite explotar</mark>, porque no hay automatización que lo haga por ti de forma fiable. Es la excepción a la regla de que "la herramienta acelera": aquí, muchas veces, la herramienta eres tú + un script.

> [!info]+ LDAP injection sigue muy viva en 2026
> Lejos de ser teórica, sigue apareciendo en incidentes reales: GitHub Security Lab documentó (aviso `GHSL-2024-009`, 2024) que el campo *email* de la autenticación LDAP de **Redash** formateaba el filtro sin escapar, <mark style="background: #FFB86CA6;">permitiendo fuerza-brutear las contraseñas de todos los usuarios con una sola petición</mark>. Prueba de que el escaping ausente (ver [[06 - Prevención de LDAP Injection|prevención]]) sigue siendo un fallo real y explotado.
>
> *(Ojo con un ejemplo que a veces se cita mal: el caso **Ivanti EPMM** de 2025 —CISA KEV, 19/05/2025— **no** es LDAP injection. Su vector es `CVE-2025-4428`, una inyección de expresiones (EL) encadenada con un bypass de auth (`CVE-2025-4427`); las credenciales LDAP se volcaron como botín tras el RCE, no explotando un filtro LDAP.)*
