---
tags:
  - Web/Red-Team
  - Jenkins
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a Tomcat]]"
Nota siguiente: "[[01 - Ataques a Jenkins]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Jenkins es un servidor de automatización CI/CD escrito en Java</mark> que corre dentro de servlet containers como [[00 - Descubrimiento y enumeración de Tomcat|Tomcat]]. Lo usan Netflix, Facebook o LinkedIn. <mark style="background: #FFB86CA6;">Su valor para el atacante es enorme</mark>: a menudo se ejecuta en Windows como la cuenta `SYSTEM`, así que un RCE en Jenkins es un `foothold` directo —y potente— hacia Active Directory. Comprometer el CI/CD es, además, pivotar a toda la cadena de suministro.

# Fingerprinting

- **Puerto 8080** por defecto (Tomcat); **puerto 5000** para la comunicación master ↔ agentes (*slaves*).
- La **página de login** es inconfundible: `http://jenkins:8080/login?from=%2F`.
- La configuración de seguridad vive en `/configureSecurity/`.

```shell-session
$ curl -s http://jenkins.inlanefreight.local:8000/login | grep -i jenkins
```

# Autenticación (y su ausencia)

Jenkins puede usar su base de datos local, LDAP, la base de usuarios Unix, delegar en el servlet container, o **ninguna autenticación**. Los administradores pueden permitir o no el registro de cuentas. <mark style="background: #FF5582A6;">No es raro encontrar en interno instancias sin autenticación o con `admin:admin`</mark> — el primer test siempre son credenciales por defecto y comprobar si `/script` es accesible sin login.

> [!info]+ Versión → CVE (modernización)
> Jenkins acumula CVEs críticas; fijar la versión (visible en la cabecera `X-Jenkins` de la respuesta) es clave:
> - <mark style="background: #FFB86CA6;">**CVE-2024-23897**</mark> (2024): argument injection en el **CLI** de Jenkins → **lectura de ficheros arbitrarios** (incluidos secrets/claves) → cadena a RCE. Muy explotada, afecta a instancias sin parchear hoy.
> - **CVE-2018-1000861**: RCE **no autenticada** vía `workflow-cps`.
> - **CVE-2019-1003000** y familia: *sandbox bypass* del Script Security que convierte un usuario con acceso al pipeline en RCE.
>
> En 2026: `nuclei -tags jenkins` para versión↔CVE, y la cabecera `X-Jenkins` para la versión exacta.

El vector estrella —y el más durable— es la **Script Console** (`/script`), que ejecuta Groovy con privilegios del servicio: [[01 - Ataques a Jenkins]].
