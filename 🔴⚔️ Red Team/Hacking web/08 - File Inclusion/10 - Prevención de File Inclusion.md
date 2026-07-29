---
tags:
  - Web/Red-Team
  - Seguridad/Prevencion-Vulnerabilidad
  - File-Inclusion
  - Tipo/Defensa
Descripción: "Saber explotar una file inclusion es saber dónde falla la defensa"
Fecha de actualización: 2026-06-22
Nota previa: "[[09 - Evasión de WAF y restricciones del servidor]]"
Nota siguiente: "[[11 - Arsenal de herramientas para File Inclusion]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Saber explotar una file inclusion es saber dónde falla la defensa. Esta nota cierra el ciclo desde el otro lado: cómo se **parchea** y se **endurece** una app para que la vulnerabilidad no ocurra y, si ocurre, su impacto sea mínimo. La defensa es por capas: código, configuración y perímetro.

# La regla de oro: no metas input de usuario en funciones de inclusión

<mark style="background: #ADCCFFA6;">Lo más efectivo es no pasar **ninguna** entrada controlable por el usuario a una función que lee o incluye ficheros</mark>. La página debería cargar sus assets en el back-end sin intervención del usuario. Cualquier uso de `include`/`require`/`file_get_contents`/`fopen`/`readfile` (y equivalentes en otros lenguajes — la lista del [[00 - Introducción a File Inclusion|primer apartado]] no es exhaustiva) debe revisarse para garantizar que no recibe input directo.

# Si es inevitable: allowlist por mapeo, nunca blacklist

A veces no se puede eliminar la carga dinámica sin rehacer la arquitectura. La solución correcta es un **mapeo**: una lista blanca que asocia cada entrada permitida a un fichero concreto, con un valor por defecto para todo lo demás.

```php
$pages = ['home' => 'home.php', 'about' => 'about.php', 'es' => 'es.php'];
$page  = $pages[$_GET['language']] ?? 'home.php';
include('/var/www/html/languages/' . $page);
```

<mark style="background: #FF5582A6;">La clave: la entrada del usuario **no llega** a la función; lo que llega es el fichero ya emparejado</mark>. El mapa puede ser una tabla en BD (ID→fichero), un `switch`/`case-match`, o un JSON estático. Cualquiera de ellos cierra la vulnerabilidad de raíz, a diferencia de filtrar caracteres.

# Prevenir el directory traversal

Si por diseño hay que aceptar un nombre de fichero, lo robusto es **canonicalizar y verificar el prefijo**: resolver la ruta real y comprobar que sigue dentro del directorio permitido.

```php
$base = '/var/www/html/languages/';
$path = realpath($base . $_GET['language']);
if ($path === false || strncmp($path, $base, strlen($base)) !== 0) {
    http_response_code(403); exit;          // intentó salir del directorio base
}
include($path);
```

`realpath()` resuelve los `../` y los symlinks; si el resultado no empieza por `$base`, hubo traversal. El equivalente existe en cada stack: `path.resolve` + chequeo de prefijo en Node, `os.path.realpath` / `werkzeug.utils.safe_join` en Python, `Path.GetFullPath` en .NET.

La alternativa más simple, `basename()` (devuelve solo el nombre del fichero), sirve cuando no hacen falta subdirectorios — su límite es justo ese. <mark style="background: #FFB8EBA6;">Evita escribir tu propia función de saneo</mark>: siempre se escapa algún *edge case*. HTB ilustra uno —los comodines `?`/`*` de Bash actúan como `.` (`cat .?/.*/.?/etc/passwd`)—; usar las funciones nativas del framework hace que otros ya hayan cazado esas rarezas. Si aun así se sanea, que sea **recursivamente**, aunque siga siendo inferior al allowlist:

```php
while (substr_count($input, '../')) {
    $input = str_replace('../', '', $input);
}
```

> [!warning]+ El blacklist recursivo no es defensa de producción
> Ni así basta: no detiene rutas **absolutas** (`/etc/passwd`, sin `../`), el **encoding** (`%2e%2e%2f`) ni los **backslash** de Windows. Ilustra la fragilidad del blacklist; el fix real es el allowlist por mapeo o `realpath()` + verificación de prefijo.

# Hardening de configuración

Varias directivas reducen el impacto aunque exista el fallo:

- **Matar la RFI**: `allow_url_include = Off` (lo quirúrgico; ya viene Off por defecto). `allow_url_fopen = Off` ayuda pero rompe librerías que cargan recursos por URL —sopésalo—.
- **Encerrar en el webroot**: `open_basedir = /var/www` impide leer fuera del directorio de la app. Hoy lo habitual es ejecutar en **Docker**, que aísla por diseño. Recuerda que `open_basedir` es [[09 - Evasión de WAF y restricciones del servidor|defense-in-depth]], no una garantía.
- **Desactivar wrappers/módulos peligrosos**: la extensión `expect`, `mod_userdir`, y mediante `disable_functions` las funciones de ejecución (`system`, `exec`…) si la app no las necesita — esto corta el salto LFI→RCE.
- <mark style="background: #FFB86CA6;">**Least privilege**: que el proceso PHP (`www-data`) no pueda leer logs, `/etc/shadow`, claves SSH ni secrets</mark>. Limita a la vez el [[07 - Log Poisoning y envenenamiento de sesiones|log poisoning]] y el alcance de la lectura.

> [!info]+ Efecto colateral del logging moderno
> Loggear a `journald` (binario) o a un sink cloud (CloudWatch, ELK) en vez de a ficheros de texto planos **elimina** el [[07 - Log Poisoning y envenenamiento de sesiones|log poisoning]] como vector: no hay `access.log` plano que incluir. Y en contenedores, montar secrets como variables de entorno los expone vía `/proc/self/environ` — preferir *secrets* montados con permisos estrictos.

# El WAF: capa, no parche

Un WAF como `ModSecurity` endurece el exterior, pero no arregla el código. Su modo **permisivo** (solo reporta, no bloquea) permite afinar reglas sin romper peticiones legítimas y sirve de alerta temprana: aunque nunca se active el bloqueo, ver intentos de `/etc/passwd` avisa de que te están atacando.

<mark style="background: #8000E1A6;">El objetivo del hardening no es ser inhackeable, sino dar tiempo a los defensores</mark>: que un ataque deje más huellas y se detecte antes. La cifra que citaba el módulo original (FireEye M-Trends 2020: 30 días de media para detectar una intrusión) se ha **reducido drásticamente** — los informes recientes de Mandiant M-Trends sitúan la mediana global de *dwell time* en torno a **~10 días**. El principio se mantiene: un sistema endurecido genera señales que acortan ese tiempo. Y nada sustituye al testing continuo, sobre todo tras un *zero-day* de un componente que uses (Apache Struts, Rails, Django…).

> [!info]+ Fuentes
> - [OWASP — Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html) · [OWASP WSTG — LFI](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/07-Input_Validation_Testing/11.1-Testing_for_Local_File_Inclusion)
> - [PHP — `realpath()`](https://www.php.net/manual/en/function.realpath.php) · [`basename()`](https://www.php.net/manual/en/function.basename.php)
> - [Mandiant M-Trends](https://www.mandiant.com/m-trends) (dwell time) · [OWASP CRS](https://coreruleset.org/)

Para terminar el sub-tema, el inventario de herramientas que automatizan detección, explotación y evasión: [[11 - Arsenal de herramientas para File Inclusion]].
