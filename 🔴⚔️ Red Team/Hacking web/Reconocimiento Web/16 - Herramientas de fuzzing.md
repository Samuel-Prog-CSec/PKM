---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Fecha de actualización: 2026-06-02
Nota previa: "[[15 - Introducción al web fuzzing]]"
Nota siguiente: "[[17 - Fuzzing de directorios y archivos]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El fuzzing web se apoya en un puñado de herramientas especializadas. La estrella del tema es <mark style="background: #ADCCFFA6;">`ffuf` (Fuzz Faster U Fool), un fuzzer web rápido escrito en Go</mark>, pero conviene conocer las alternativas y cuándo usar cada una.

# Preparar el entorno

La mayoría son binarios de Go o aplicaciones de Python; `pipx` instala estas últimas en entornos aislados para evitar conflictos de dependencias:

```shell-session
$ sudo apt update
$ sudo apt install -y golang python3 python3-pip pipx
$ pipx ensurepath
```

# Las cuatro herramientas

```shell-session
# ffuf — fuzzer flexible (directorios, archivos, parámetros, vhosts)
$ go install github.com/ffuf/ffuf/v2@latest

# gobuster — content discovery rápido y simple (modos dir, dns, vhost)
$ go install github.com/OJ/gobuster/v3@latest

# feroxbuster — forced browsing recursivo en Rust
$ curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | sudo bash -s $HOME/.local/bin

# wenum — fork mantenido de wfuzz, especializado en fuzzing de parámetros
$ pipx install git+https://github.com/WebFuzzForge/wenum
```

# Cuál usar para qué

| Herramienta | Fuerte en | Carácter |
| - | - | - |
| `ffuf` | Todo: dirs, archivos, parámetros, vhosts; la palabra `FUZZ` va donde quieras | Fuzzer flexible y rápido |
| `gobuster` | Content discovery directo, con modos `dir`/`dns`/`vhost` | Simple y veloz, ideal para empezar |
| `feroxbuster` | *Forced browsing* **recursivo** de contenido no enlazado | Rust, muy rápido; más "navegador forzado" que fuzzer |
| `wfuzz`/`wenum` | Fuzzing de **parámetros**, múltiples posiciones `FUZZ` a la vez | Muy configurable |

<mark style="background: #FFB8EBA6;">No hay una "mejor": `ffuf` cubre el 90 % de los casos por su flexibilidad</mark>, `feroxbuster` brilla cuando quieres recursión automática, y `wfuzz`/`wenum` cuando necesitas fuzzear varias posiciones simultáneamente. En bug bounty también verás `dirsearch` (Python) y el veterano `dirb`.

> [!info]+ Las wordlists son media herramienta
> Ninguna de estas tools sirve sin una buena `wordlist`. El estándar es `SecLists`, bajo `/usr/share/seclists/Discovery/Web-Content/`:
> - `common.txt` — barrido rápido inicial.
> - `raft-*-directories.txt` / `raft-*-files.txt` — generadas de datos reales, excelente relación señal/ruido.
> - `directory-list-2.3-medium.txt` — exhaustiva (220k+), para pasadas profundas.
> Para tecnologías concretas hay listas dedicadas (`CMS/`, `Web-Content/IIS.txt`, etc.). Elegir la lista adecuada al objetivo importa más que la velocidad de la herramienta.

# El concepto `FUZZ`

La idea central de `ffuf` es la palabra clave <mark style="background: #FFB86CA6;">`FUZZ`: un marcador que colocas en cualquier punto de la petición, y que `ffuf` sustituye por cada entrada de la `wordlist`</mark>:

```shell-session
$ ffuf -u https://target/FUZZ -w wordlist.txt          # fuzz de ruta
$ ffuf -u https://target/?FUZZ=test -w params.txt      # fuzz de nombre de parámetro
$ ffuf -u https://target/ -H "Host: FUZZ.target" -w subs.txt   # fuzz de vhost
```

Mover el marcador `FUZZ` de sitio es lo que convierte a `ffuf` en una sola herramienta para todas las técnicas del tema. Con `-w lista:KEYWORD` puedes incluso definir varias posiciones con nombres propios.

Con el entorno listo, la primera técnica —y la más usada— es descubrir directorios y archivos ocultos: [[17 - Fuzzing de directorios y archivos]].
