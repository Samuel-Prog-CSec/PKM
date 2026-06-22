---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - File-Inclusion
Fecha de actualización: 2026-06-22
Nota previa: "[[07 - Log Poisoning y envenenamiento de sesiones]]"
Nota siguiente: "[[09 - Evasión de WAF y restricciones del servidor]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

El testing manual es más fiable y encuentra LFI que un escáner pasa por alto, pero en objetivos grandes conviene automatizar la fase de descubrimiento. Esta nota cubre la **metodología de detección**: localizar el parámetro, confirmar la inclusión —incluso **a ciegas**— y fuzzear payloads y ficheros del servidor. El catálogo de herramientas con sus comandos está en el [[11 - Arsenal de herramientas para File Inclusion|arsenal]].

# Descubrir el parámetro

Los formularios visibles suelen estar bien protegidos, pero <mark style="background: #FFB8EBA6;">muchas páginas exponen parámetros que no cuelgan de ningún formulario</mark> —y que por eso nadie endureció—. Fuzzearlos es el primer paso:

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt:FUZZ \
    -u 'http://target/index.php?FUZZ=value' -fs 2287
```

Para apps modernas (SPA, APIs JSON, rutas tipo `/files/[name]`), **Arjun** descubre parámetros en GET/POST/JSON/headers, y **x8** (Rust) afina con valores no aleatorios. Una vez identificado un parámetro no enlazado, se le aplican todas las pruebas de LFI. Para acotar, existe una lista de los [Top-25 parámetros LFI](https://book.hacktricks.wiki/en/pentesting-web/file-inclusion/index.html#top-25-parameters).

# Confirmar la LFI (black-box)

Señales que delatan una inclusión:

- **Errores de PHP**: `include(...): failed to open stream` o `Failed opening '...' for inclusion` revelan que nuestra entrada llega a un sink y, a menudo, la ruta exacta.
- **Diferencial de tamaño**: una respuesta a `?language=../../../../etc/passwd` que pesa varios KB más que la baseline indica que se leyó un fichero real.
- **Contenido canónico de confirmación**:
  - Linux → `/etc/passwd`: buscar `root:x:0:0:`.
  - Windows → `C:\Windows\win.ini`: buscar `[extensions]` o `[fonts]`.

```shell-session
$ curl -s "http://target/index.php?language=en" | wc -c          # baseline
$ curl -s "http://target/index.php?language=../../../../etc/passwd" | wc -c   # diff → LFI
```

<mark style="background: #FFB86CA6;">Los errores ayudan, pero todos los ataques funcionan a ciegas</mark>: la confirmación por diferencial no depende de mensajes verbosos.

# LFI a ciegas: el oracle de filter chains

El caso difícil: el `include()` se ejecuta pero su contenido **no aparece** en la respuesta. Parecía no explotable, hasta el [error-based oracle de Synacktiv](https://www.synacktiv.com/en/publications/php-filter-chains-file-read-from-error-based-oracle). <mark style="background: #ADCCFFA6;">Convierte una LFI sin salida en lectura de ficheros byte a byte</mark>, reutilizando las [[04 - PHP wrappers II - RCE y filter chains|filter chains]] como un oráculo:

1. Una cadena de `convert.iconv` hace crecer el string en memoria hasta provocar un `Allowed memory size exhausted` → respuesta distinguible (error/tamaño distinto).
2. El filtro `dechunk` actúa de test booleano sobre el **primer byte** del fichero: si coincide con cierto valor, el proceso revienta; si no, termina normal.
3. Encodings que reordenan bytes (`UCS-4LE` invierte cuartetos) "rotan" cualquier byte a la primera posición para repetir el test.

<mark style="background: #FF5582A6;">Resultado: se lee cualquier fichero sin que su contenido salga en la respuesta</mark> (a coste de cientos de peticiones por fichero), con `php_filter_chains_oracle_exploit`. Otros oráculos ciegos:

- **OOB para RFI/SSRF**: inyectar una URL hacia `interactsh`/Burp Collaborator; si el servidor hace la petición, la LFI/RFI está confirmada aunque no veamos respuesta.
- **`/proc/self/fd/N` y `/proc/self/environ`**: leer descriptores y entorno del proceso como vía de lectura cuando el sink no refleja contenido.

# Fuzzing de payloads

Para un test rápido sobre un parámetro, una wordlist de payloads LFI prueba decenas de bypasses de una vez. La referencia es [`LFI-Jhaddix.txt`](https://github.com/danielmiessler/SecLists/blob/master/Fuzzing/LFI/LFI-Jhaddix.txt) (incluye traversal, encodings y ficheros comunes):

```shell-session
$ ffuf -w /usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt:FUZZ \
    -u 'http://target/index.php?language=FUZZ' -fs 2287
```

<mark style="background: #8000E1A6;">Cada *hit* hay que verificarlo a mano</mark>: que devuelva realmente el contenido del fichero y no un falso positivo por tamaño.

# Fuzzing de ficheros del servidor

Más allá de los payloads, ciertos ficheros del servidor habilitan o completan la explotación:

- **Webroot**: para localizar un upload por ruta absoluta cuando los `../` relativos no llegan. Se fuzzea `index.php` contra rutas raíz comunes:

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/default-web-root-directory-linux.txt:FUZZ \
    -u 'http://target/index.php?language=../../../../FUZZ/index.php' -fs 2287
```

- **Logs y configuración**: para el [[07 - Log Poisoning y envenenamiento de sesiones|log poisoning]] hay que conocer la ruta de los logs. La wordlist [`LFI-WordList-Linux` (DragonJAR)](https://github.com/DragonJAR/Security-Wordlist) es más precisa que Jhaddix para esto. Leyendo `/etc/apache2/apache2.conf` se obtienen `DocumentRoot` y `APACHE_LOG_DIR`; esta última es una variable que se resuelve en `/etc/apache2/envvars`. Encadenar lecturas (config → variables → rutas reales) replica la metodología de los [[03 - PHP wrappers I - php filter y disclosure de código|php filters]].

# Detección white-box (code review)

En caja blanca (clave para CWEE), se buscan los **sinks** que reciben entrada de usuario sin sanear. Por lenguaje:

| Lenguaje | Sinks a auditar |
| - | - |
| **PHP** | `include` · `require` · `include_once` · `require_once` · `file_get_contents` · `fopen` · `readfile` · `file` · `show_source` · `highlight_file` |
| **Node.js** | `fs.readFile` · `fs.readFileSync` · `res.sendFile` · `res.render` · `require()` |
| **Java** | `new FileInputStream` · `getResourceAsStream` · `RequestDispatcher.include` |
| **Python** | `open` · `flask.send_file` (sin `safe_join`) · `render_template` |
| **.NET** | `Response.WriteFile` · `Server.Execute` · `@Html.Partial` · `File.ReadAllText` |

El *taint* se rastrea desde las fuentes (`$_GET`/`$_POST`/`$_REQUEST`, `req.query`, `request.getParameter`, `Request[...]`) hasta esos sinks. Reglas listas: `semgrep scan --config "p/php" .` cubre taint intra-función; las queries públicas de **CodeQL** (`github/codeql`) cubren path traversal en Java y JS.

> [!warning]+ Límite de los escáneres
> El taint **cross-file** (entre funciones/módulos, como en una [[01 - Local File Inclusion (LFI)|LFI second-order]]) requiere Semgrep Pro Rules de pago. Las reglas de comunidad solo ven el flujo dentro de una función — un sink alimentado desde la BD o desde otra capa se les escapa.

# Herramientas

Para automatizar el ciclo completo (traversal, wrappers, log poisoning, `/proc`), **LFImap** (Python 3, mantenida) es el todo-en-uno actual. Los escáneres clásicos —`LFISuite`, `fimap`, `liffy`— están en **Python 2 y abandonados**: no merecen la pena hoy. El detalle de comandos y el estado de cada herramienta, en el [[11 - Arsenal de herramientas para File Inclusion|arsenal]].

> [!info]+ Fuentes
> - [Synacktiv — PHP filter chains: file read from error-based oracle](https://www.synacktiv.com/en/publications/php-filter-chains-file-read-from-error-based-oracle)
> - [SecLists — Fuzzing/LFI](https://github.com/danielmiessler/SecLists/tree/master/Fuzzing/LFI) · [HackTricks — LFI top-25 params](https://book.hacktricks.wiki/en/pentesting-web/file-inclusion/index.html#top-25-parameters)
> - [Semgrep registry — p/php](https://semgrep.dev/p/php) · [CodeQL queries](https://github.com/github/codeql)

Cuando un WAF o las restricciones del servidor bloquean los payloads, hay que afinar la evasión: [[09 - Evasión de WAF y restricciones del servidor]].
