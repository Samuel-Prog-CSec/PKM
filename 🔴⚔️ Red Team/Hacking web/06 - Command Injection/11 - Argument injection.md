---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[10 - Arsenal de herramientas para Command Injection]]"
Nota siguiente:
Area: "[[Command Injection.base|Command Injection]]"
---
---

Todo el módulo asume que controlas el comando o puedes encadenar el tuyo con [[02 - Operadores de inyección de comandos|operadores]] (`;`, `|`, `&&`). La `argument injection` es el caso en que **no** controlas el comando ni puedes inyectar operadores —porque la app ejecuta el binario sin shell, o filtra los metacaracteres—, pero sí controlas **uno de los argumentos**. <mark style="background: #ADCCFFA6;">Inyectando opciones (`-flags`) cambias el comportamiento del binario hasta convertirlo en lectura de ficheros, escritura o RCE</mark>. Es la "command injection de segunda generación", y HTB no la cubre: en bug bounty 2026 es de las más rentables porque sobrevive justo donde los desarrolladores creen estar a salvo.

# Por qué evade las defensas del módulo

Recuerda la [[09 - Prevención de Command Injection|prevención]]: ejecutar el binario **sin shell**, pasando los argumentos como array (`execve`), neutraliza la inyección de comandos clásica —`; whoami` se trata como un argumento literal—. <mark style="background: #FFB86CA6;">La argument injection rompe esa defensa</mark>: no necesita shell ni metacaracteres. Si la app hace

```python
subprocess.run(["git", "log", user_input], shell=False)   # "seguro" contra command injection
```

y `user_input` empieza por `-`, el binario `git` lo interpreta como una **opción**, no como un operando. La ejecución sin shell evitaba el `;`; no evita que metas un flag.

# El patrón: opciones que el binario no esperaba

La clave es que <mark style="background: #8000E1A6;">muchos binarios tienen flags que ejecutan código, leen o escriben ficheros</mark>. Si tu entrada se coloca antes del operando real (o es el operando) y empieza por `-`, puedes activarlos. Los clásicos:

| Binario | Flag inyectado | Efecto |
| - | - | - |
| `tar` | `--checkpoint=1 --checkpoint-action=exec=sh script` | RCE |
| `git` | `-c core.pager='sh -c ...'` · `--output=/path` · `--upload-pack` | RCE / escritura |
| `curl` | `-o /var/www/shell.php` · `-K archivo_config` | escritura / leer config |
| `find` | `-exec sh -c '...' \;` | RCE |
| `zip` | `archivo.zip fichero -T -TT 'sh -c ...'` (`-T` testea el zip recién creado, `-TT` = comando de test) | RCE |
| `rsync` | `-e 'sh -c ...'` | RCE |
| `wget` | `--use-askpass=script` · `-O /path` | RCE / escritura |
| `awk` | `-e 'BEGIN{system("id")}'` · `-f script` | RCE / leer ficheros |
| `sed` (GNU) | `-e '1e id'` · `s/re/x/e` (flag `e`) | RCE / leer ficheros |

Ejemplo concreto con `tar`, el más célebre —una app que comprime un fichero con nombre controlado:

```shell-session
$ tar czf archive.tar.gz --checkpoint=1 --checkpoint-action=exec=sh\ shell.sh *
```

Si controlas un argumento del `tar`, ese `--checkpoint-action=exec` ejecuta tu comando sin un solo metacarácter de shell.

# Detección

- **White-box**: localiza dónde se construye el `exec`/`subprocess`/`ProcessBuilder` y comprueba <mark style="background: #FF5582A6;">si la entrada del usuario puede acabar como un argumento que empieza por `-`</mark>, y si falta el separador `--`. Es rápido y definitivo.
- **Black-box**: en cualquier funcionalidad que pase tu entrada a un binario conocido (un nombre de fichero, un host, un repo), prueba valores que empiecen por `-` (`-h`, `--version`, `--output=...`) y observa si cambian el comportamiento o devuelven la ayuda del binario —síntoma inequívoco de que tu entrada se interpreta como opción—.

> [!important]+ `GTFOArgs`: el catálogo de la técnica
> Igual que [[10 - Arsenal de herramientas para Command Injection|`GTFOBins`]] cataloga binarios para escalar privilegios, <mark style="background: #FF5582A6;">`GTFOArgs` cataloga binarios explotables vía argument injection</mark> y qué flags usar en cada uno. Es la referencia para saber, dado el binario que ejecuta la app, qué opción inyectar para leer, escribir o ejecutar.

# Prevención

La defensa es distinta de la del resto del módulo. Parametrizar/escapar no aplica (no hay shell). Lo correcto:

- <mark style="background: #8000E1A6;">Usar el separador `--`</mark> (*end of options*) entre las opciones y los operandos: `git log -- <user_input>` hace que `git` trate la entrada como ruta, nunca como flag. Es la defensa nº1 y la más olvidada.
- Validar que la entrada **no empiece por `-`** (o anteponer `./` a las rutas).
- *Allowlist* de valores cuando el dominio es acotado.

> [!info]+ Fuentes
> - [GTFOArgs](https://gtfoargs.github.io/) — binarios explotables por argument injection.
> - [PayloadsAllTheThings — Argument/Parameter injection](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md)
> - [Sonar — Argument injection research](https://www.sonarsource.com/blog/) · [PortSwigger — OS command injection](https://portswigger.net/web-security/os-command-injection)

Con la argument injection se completa el sub-tema: desde la [[00 - Introducción a Command Injection|inyección clásica]] y su [[03 - Identificación de filtros y defensas|evasión de filtros]] hasta el vector que esquiva incluso la ejecución sin shell. Comparte raíz con la [[11 - Inyección en ORMs|inyección en ORMs]] de SQLi: la vulnerabilidad sobrevive donde la defensa "obvia" deja un hueco que nadie revisó.
