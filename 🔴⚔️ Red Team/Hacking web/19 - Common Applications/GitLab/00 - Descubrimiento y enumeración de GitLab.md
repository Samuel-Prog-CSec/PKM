---
tags:
  - Web/Red-Team
  - GitLab
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Enumeración y ataques a osTicket]]"
Nota siguiente: "[[01 - Ataques a GitLab]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">GitLab es una plataforma de repositorios Git con wiki, issue tracking y CI/CD</mark> (Ruby on Rails + Go + Vue). Un GitLab comprometido es acceso al **código fuente, secretos y pipelines** — de los objetivos más rentables. Lo usan Goldman Sachs, Nvidia o Siemens. Repos en tres niveles: **público** (sin auth), **interno** (usuarios autenticados) y **privado** (usuarios concretos).

# Fingerprinting

- Página de login en **`/users/sign_in`** con el logo de GitLab (puerto 80/443, en el lab 8081).
- <mark style="background: #FFB8EBA6;">La versión **solo** se ve en `/help` estando autenticado</mark>. Sin poder registrarse ni deducirla, mejor no lanzar exploits a ciegas — dedicarse a cazar secretos.

# Enumeración

**1. Repos públicos** — `/explore` lista proyectos accesibles sin login:

```text
http://gitlab.inlanefreight.local:8081/explore
```

Merece la pena peinarlos: código de producción, credenciales hardcodeadas, claves SSH, API keys.

**2. Registro abierto** — muchas instancias exigen email corporativo + aprobación de admin, pero algunas <mark style="background: #FFB86CA6;">permiten registrarse a cualquiera</mark>; tras registrarse, aparecen los proyectos **internos**.

**3. Enumeración de usuarios/emails** vía `/users/sign_up`:

```text
# usuario ya existente
"root" → Username has already been taken
# email ya existente
Email has already been taken
```

<mark style="background: #FF5582A6;">Funciona incluso con el registro deshabilitado</mark> (la página `/users/sign_up` sigue accesible aunque no puedas completar el registro). Con la lista de usuarios → [[04 - Password spraying, stuffing y defaults|password spraying]] o reutilización de credenciales de leaks (Dehashed). El **2FA está desactivado por defecto**.

> [!info]+ Herramientas y modernización
> Para secretos en repos e historial: <mark style="background: #ADCCFFA6;">`gitleaks` y `trufflehog`</mark>. Para vulns: `nuclei -tags gitlab`. GitLab arrastra CVEs serias —p. ej. **CVE-2020-10977** (lectura de ficheros → RCE encadenada en < 12.9.1)—, pero la de referencia es **CVE-2021-22205** (RCE no autenticada vía ExifTool, parcheada en 13.8.8 / 13.9.6 / 13.10.3), en [[01 - Ataques a GitLab]]. Defensa: 2FA obligatorio, `Fail2Ban`, y restringir IPs de acceso.

Con la versión o el acceso, a la explotación: [[01 - Ataques a GitLab]].
