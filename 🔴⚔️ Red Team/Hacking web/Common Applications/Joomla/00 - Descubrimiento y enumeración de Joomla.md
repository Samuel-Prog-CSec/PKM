---
tags:
  - Web/Red-Team
  - Joomla
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a WordPress]]"
Nota siguiente: "[[01 - Ataques a Joomla]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Joomla es un CMS open-source en PHP + MySQL</mark> (~3,5% del mercado CMS, ~2,5M de sitios). Como [[00 - Descubrimiento y enumeración de WordPress|WordPress]], se extiende con plantillas y extensiones. Lo usan eBay, Harvard o el gobierno del Reino Unido.

# Fingerprinting

- **Meta generator** en el código: `<meta name="generator" content="Joomla! - Open Source Content Management" />`.
- **`robots.txt`** con la lista delatora: `Disallow: /administrator/ /components/ /modules/ /plugins/ /libraries/ ...`.
- El backend en **`/administrator/`**.

```shell-session
$ curl -s http://dev.inlanefreight.local/ | grep -i joomla
<meta name="generator" content="Joomla! - Open Source Content Management" />
```

# Enumeración de versión

De menos a más preciso:

```shell-session
# README.txt → serie (3.x)
$ curl -s http://dev.inlanefreight.local/README.txt | head -n 5

# joomla.xml → versión EXACTA
$ curl -s http://dev.inlanefreight.local/administrator/manifests/files/joomla.xml | grep '<version>'
<version>3.9.4</version>

# cache.xml → versión aproximada
$ curl -s http://dev.inlanefreight.local/plugins/system/cache/cache.xml | grep version
```

# Escáneres

```shell-session
# droopescan (soporte Joomla limitado): versión + URLs interesantes
$ droopescan scan joomla --url http://dev.inlanefreight.local/
[+] Possible version(s): 3.8.x ...
[+] Login page - .../administrator/  |  Detailed version - .../joomla.xml

# JoomlaScan (Python2, inspirado en joomscan): enumera componentes/extensiones
$ python2 joomlascan.py -u http://dev.inlanefreight.local
Component found: com_actionlogs, com_admin, com_ajax, com_banners ...
```

# Acceso al backend

El login `/administrator/index.php` da un **error genérico** (no permite *user enumeration*). El usuario por defecto es `admin` pero la contraseña se fija al instalar → solo entra con brute force ligero si es débil:

```shell-session
$ sudo python3 joomla-brute.py -u http://dev.inlanefreight.local -w /usr/share/metasploit-framework/data/wordlists/http_default_pass.txt -usr admin
admin:admin        # ← alguien no siguió las buenas prácticas
```

> [!info]+ Modernización
> Fijar la versión importa por [[01 - Ataques a Joomla|CVE-2023-23752]] (info disclosure **no autenticada** que filtra las credenciales de BD en 4.0.0–4.2.7) — la vulnerabilidad Joomla más relevante hoy y ausente del HTB de 2021. Herramientas actuales: [`joomscan`](https://github.com/OWASP/joomscan) (el OWASP, revivido), `droopescan`, `nuclei -tags joomla`, y el manifest `joomla.xml` para la versión exacta.

Con la versión y el panel localizados, a la explotación: [[01 - Ataques a Joomla]].
