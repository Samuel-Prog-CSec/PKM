---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Fecha de actualización: 2026-06-02
Nota previa: "[[20 - Fuzzing de vhosts y subdominios]]"
Nota siguiente: "[[22 - Validación de hallazgos]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Los fuzzers generan **muchísima** salida. <mark style="background: #FFB86CA6;">Distinguir el hallazgo que importa del ruido de miles de respuestas inútiles es la habilidad que separa un fuzzing productivo de una lista inservible</mark>. Todas las herramientas ofrecen filtros potentes para ello.

# Match vs filter: el modelo mental

Todo el filtrado se reduce a dos operaciones opuestas:

- <mark style="background: #ADCCFFA6;">**Match** (`-m*`, *whitelist*): muestra **solo** lo que cumple el criterio</mark>.
- <mark style="background: #ADCCFFA6;">**Filter** (`-f*`, *blacklist*): oculta lo que cumple el criterio</mark>.

Y se aplican sobre las mismas dimensiones de la respuesta: **código** de estado, **tamaño** (bytes), **palabras**, **líneas**, **tiempo** de respuesta y, en algunas tools, **regex** del cuerpo.

# `ffuf`: el sistema de filtros

| Flag | Acción |
| - | - |
| `-mc` / `-fc` | Match / filter por **código** (`-mc 200`, `-fc 404`). Rangos: `400-499` |
| `-ms` / `-fs` | Match / filter por **tamaño** en bytes (`-fs 0`, `-ms 3456`, rangos `100-200`) |
| `-mw` / `-fw` | Match / filter por número de **palabras** |
| `-ml` / `-fl` | Match / filter por número de **líneas** |
| `-mt` | Match por **tiempo** hasta el primer byte (`-mt >500` → respuestas lentas) |
| `-mr` / `-fr` | Match / filter por **regex** sobre el cuerpo de la respuesta |

```shell-session
# Solo 200, con un word-count distinto al ruido y tamaño > 500 bytes
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -mc 200 -fw 427 -ms 500-999999

# Ocultar errores comunes
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -fc 404,401,302

# Endpoints lentos (posible procesamiento pesado / inyección)
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -mt >500
```

# Equivalentes en otras herramientas

| Dimensión | `gobuster` | `wenum` | `feroxbuster` |
| - | - | - | - |
| Mostrar códigos | `-s 200,301` *(solo dir)* | `--sc 200` | `-s 200,301` |
| Ocultar códigos | `-b 404` *(solo dir)* | `--hc 404` | `-C 404,500` |
| Filtrar por tamaño | `--exclude-length 0,404` | `--hs` / `--ss` | `-S 1024` |
| Filtrar por palabras | — | `--hw` / `--sw` | `-W 0-10` |
| Filtrar por líneas | — | `--hl` / `--sl` | `-N 50-` |
| Filtrar por regex | — | `--hr` / `--sr` | `-X "Access Denied"` |

`feroxbuster` trabaja sobre todo por **exclusión** (`-C`/`-S`/`-W`/`-N`/`-X`); su `-s` lista los códigos a considerar, pero no es un *match* estricto que oculte el resto como el `-mc` de `ffuf`. Añade además `--filter-similar-to error.html` (descarta páginas casi idénticas a una de referencia) y `--dont-scan` (excluye rutas de la recursión).

# El matcher por defecto

`ffuf` **ya filtra por ti** aunque no lo pidas. Su línea de configuración lo revela:

```text
:: Matcher : Response status: 200-299,301,302,307,401,403,405,500
```

<mark style="background: #FFB8EBA6;">Por defecto muestra esos códigos y descarta el resto (sobre todo `404`)</mark> para minimizar ruido. Si lo desactivas con `-mc all`, la salida se inunda:

```shell-session
$ ffuf -u http://IP:PORT/post.php -X POST -d "y=FUZZ" -w common.txt -mc all
[Status: 404, Size: 36] FUZZ: .cache
[Status: 404, Size: 43] FUZZ: .bash_history
[Status: 404, Size: 34] FUZZ: .cvs
[...]   # cientos de 404 enterrando lo útil
```

# La pieza clave: auto-calibración

> [!important]+ `-ac` / `-acc`: el filtro automático del baseline
> El problema recurrente de las notas anteriores —el servidor que responde `200` a **todo** (soft-404, *wildcard*, vhost por defecto)— se resuelve con la **auto-calibración** de `ffuf`, que HTB apenas menciona:
> - `-ac`: antes de empezar, `ffuf` lanza unas peticiones a rutas aleatorias inexistentes, aprende cómo es la respuesta "falsa" (tamaño, palabras, líneas) y <mark style="background: #FF5582A6;">filtra automáticamente todo lo que se le parezca</mark>.
> - `-acc "<valor>"`: calibración personalizada con cadenas concretas.
> ```shell-session
> $ ffuf -u http://IP/FUZZ -w wordlist.txt -ac
> $ ffuf -u http://IP/ -H "Host: FUZZ.target.htb" -w subs.txt -ac
> ```
> Es lo que convierte un vhost o un soft-404 imposibles de filtrar a mano en un escaneo limpio sin calcular el `-fs` manualmente.
> El detalle de `-ac`/`-acc`/`-ach` y el flujo anti-ruido completo, en la [[05 - Matching y filtrado de resultados|referencia de ffuf en Tools]].

# El flujo de trabajo

En la práctica el filtrado es iterativo: <mark style="background: #8000E1A6;">primero corres amplio para ver la distribución del ruido, identificas el patrón de la respuesta "vacía" (todas miden 36 bytes, o tienen 4 palabras) y añades el filtro para eliminarla</mark>. Con `-ac` te ahorras ese primer paso en la mayoría de casos.

Filtrar reduce el ruido, pero no garantiza que lo que queda sea real. Un resultado que pasa los filtros puede seguir siendo un falso positivo. Separar hallazgos reales del ruido residual es [[22 - Validación de hallazgos]].
