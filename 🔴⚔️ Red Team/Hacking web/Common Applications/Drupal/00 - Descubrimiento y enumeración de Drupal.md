---
tags:
  - Web/Red-Team
  - Drupal
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Ataques a Joomla]]"
Nota siguiente: "[[01 - Ataques a Drupal]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Drupal es un CMS open-source en PHP</mark> (backend MySQL, PostgreSQL o SQLite), extensible con temas y módulos, y el tercer CMS más usado tras WordPress y Joomla. Lo usan desde Tesla hasta el 56% de webs gubernamentales — un objetivo frecuente en externos.

# Fingerprinting

Un Drupal se identifica por varias señales:

- Cabecera/pie **`Powered by Drupal`** y el `<meta name="Generator" content="Drupal 8 ...">`.
- Ficheros `CHANGELOG.txt` / `README.txt` (bloqueados en instalaciones nuevas).
- URIs de tipo **`/node/<id>`** (Drupal indexa el contenido en *nodes*) — útil cuando hay un tema custom.
- Referencias a `/node` en `robots.txt`.

```shell-session
$ curl -s http://drupal.inlanefreight.local | grep -i drupal
<meta name="Generator" content="Drupal 8 (https://www.drupal.org)" />
<span>Powered by <a href="https://www.drupal.org">Drupal</a></span>
```

# Enumeración de versión

La versión decide el exploit. Vías:

```shell-session
# CHANGELOG.txt (si no está bloqueado)
$ curl -s http://drupal-acc.inlanefreight.local/CHANGELOG.txt | grep -m2 ""
Drupal 7.57, 2018-02-21

# droopescan — versión, módulos y URL de login
$ droopescan scan drupal -u http://drupal.inlanefreight.local
[+] Possible version(s): 8.9.0, 8.9.1
[+] Possible interesting urls found: Default admin - .../user/login
```

<mark style="background: #FFB8EBA6;">Las instalaciones modernas bloquean `CHANGELOG.txt`/`README.txt`</mark>, así que a veces hay que combinar `droopescan`, rutas de módulos (`/modules/<x>/LICENSE.txt`) y el hash de recursos estáticos para acotar la versión.

Drupal define tres roles por defecto: **Administrator** (control total), **Authenticated User** (según permisos) y **Anonymous** (solo lectura).

> [!info]+ Versión → CVE (modernización)
> El interés de fijar la versión son las RCEs históricas de Drupal, aún muy explotadas en instancias sin parchear: <mark style="background: #FFB86CA6;">**Drupalgeddon2** (CVE-2018-7600, RCE **no autenticada** en 7.x/8.x)</mark>, **Drupalgeddon3** (CVE-2018-7602, RCE **autenticada** — requiere permiso de borrar nodos) y **CVE-2019-6340** (RCE vía REST en 8.x). En 2026, tras `droopescan`, lo más rápido es <mark style="background: #ADCCFFA6;">`nuclei -t http/cves/ -tags drupal`</mark> para cruzar versión ↔ CVE, y `metasploit` (`exploit/unix/webapp/drupal_drupalgeddon2`) tiene módulos listos. Ver [[01 - Ataques a Drupal]].

Confirmada la versión y sin CVE de *core* aplicable, el camino es enumerar módulos instalados o abusar de funcionalidad: [[01 - Ataques a Drupal]]. Comparte metodología con [[01 - Enumeración de WordPress|WordPress]] y [[00 - Descubrimiento y enumeración de Joomla|Joomla]].
