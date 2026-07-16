---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Descubrimiento y enumeración de aplicaciones]]"
Nota siguiente: "[[01 - Ataques a WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">WordPress es el CMS más usado de la web (~32-40%)</mark>, en PHP + MySQL sobre Apache. Su naturaleza extensible con **temas y plugins** de terceros es justo lo que lo hace vulnerable: según WPScan, de ~4.000 vulnerabilidades conocidas, el <mark style="background: #FFB86CA6;">54% son de plugins, 31,5% del core y 14,5% de temas</mark>. Lo usan desde The New York Times hasta Sony.

# Fingerprinting

Vías rápidas para confirmar WordPress y sacar la versión:

- **`/robots.txt`** delator: referencia a `/wp-admin/` y `/wp-content/`.
- `/wp-login.php` (portal de login; `/wp-admin` redirige allí).
- **Meta generator** en el código fuente:

```shell-session
$ curl -s http://blog.inlanefreight.local | grep -i wordpress
<meta name="generator" content="WordPress 5.8" />
```

Los plugins viven en `/wp-content/plugins/` y los temas en `/wp-content/themes/` — las dos carpetas que hay que peinar.

# Los 5 roles de usuario

| Rol | Capacidad |
| - | - |
| **Administrator** | control total, **incluye editar código** (→ RCE) |
| Editor | publica/gestiona posts de todos |
| Author | publica/gestiona sus posts |
| Contributor | escribe sus posts pero no publica |
| Subscriber | solo lee y edita su perfil |

<mark style="background: #FF5582A6;">Acceso como Administrator ≈ ejecución de código</mark>; Editors/Authors pueden alcanzar plugins vulnerables que un usuario normal no.

# Enumeración manual (el código fuente)

Peinar el `page source` de varias páginas revela tema, plugins y versiones. `grep` sobre `themes` y `plugins`:

```shell-session
$ curl -s http://blog.inlanefreight.local/ | grep -oE 'themes/[^/]+|plugins/[^/]+'
themes/transport-gravity
plugins/contact-form-7 ... plugins/mail-masta ... plugins/wpdiscuz
```

La **versión del plugin** suele estar en su `readme.txt` (con *directory listing* activo, `/wp-content/plugins/<plugin>/readme.txt`). En el lab: `mail-masta 1.0.0` (LFI), `wpDiscuz 7.0.4` (RCE no auth).

**Enumeración de usuarios**: `/wp-login.php` <mark style="background: #FFB8EBA6;">devuelve mensajes distintos para usuario válido con contraseña mala vs usuario inexistente</mark> → *username enumeration*.

# WPScan (automático)

```shell-session
$ sudo wpscan --url http://blog.inlanefreight.local --enumerate --api-token <TOKEN>
[+] WordPress version 5.8 identified (Insecure)
[+] XML-RPC seems to be enabled: .../xmlrpc.php
[+] Upload directory has listing enabled
[+] Theme in use: transport-gravity
[+] mail-masta ... 2 vulnerabilities (LFI, SQLi)
[i] User(s) Identified: admin, john
```

El `--api-token` (de [WPScan/WPVulnDB](https://wpscan.com/), 25 req/día gratis) añade los datos de vulnerabilidades por versión.

> [!important]+ Manual + automático, no uno u otro
> WPScan confirmó la versión y usuarios, pero <mark style="background: #8000E1A6;">**se le escaparon** los plugins `wpDiscuz` y `Contact Form 7`</mark> que sí vimos a mano. La lección transferible a cualquier app: el escáner no sustituye al ojo humano. Combinar ambos.

> [!info]+ Modernización
> Cuando `/?author=` y `/xmlrpc.php` están bloqueados, la **REST API `/wp-json/wp/v2/users`** suele seguir enumerando usuarios, y las **Application Passwords** son un vector nuevo. Complementos actuales: `nuclei -tags wordpress`, `waybackurls` para plugins retirados pero accesibles. El profundo está en el módulo *Hacking WordPress* de HTB.

Con versión, tema, plugins y usuarios anotados, a la explotación: [[01 - Ataques a WordPress]].
