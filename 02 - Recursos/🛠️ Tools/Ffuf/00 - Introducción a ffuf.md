---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
  - Introduccion
Fecha de actualización: 2026-07-19
Nota previa: 
Nota siguiente: "[[01 - Wordlists, keywords y modos de ffuf]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

<mark style="background: #ADCCFFA6;">`ffuf` (*Fuzz Faster U Fool*) es un fuzzer web escrito en Go: rápido, y sobre todo **flexible**</mark>. La *metodología* del web fuzzing —cuándo, por qué y qué fuzzear, y cómo analizar respuestas— vive en [[15 - Introducción al web fuzzing|Reconocimiento Web]]; este sub-tema es la **referencia profunda de la herramienta**: cada modo, cada matcher/filtro, rendimiento y evasión.

# La idea: la palabra `FUZZ`

<mark style="background: #FFB86CA6;">`ffuf` sustituye la palabra clave `FUZZ` por cada línea de la `wordlist`, allá donde la coloques en la petición</mark>. Ese único mecanismo cubre todas las técnicas del tema:

```shell-session
$ ffuf -w wl.txt -u https://target/FUZZ                    # ruta/directorio
$ ffuf -w wl.txt -u https://target/?FUZZ=x                 # nombre de parámetro
$ ffuf -w wl.txt -u https://target/ -H "Host: FUZZ.tgt"    # vhost
```

Mover `FUZZ` de sitio es lo que hace de `ffuf` una sola herramienta para directorios, archivos, parámetros y `vhosts`. La comparación con `gobuster`/`feroxbuster`/`wfuzz` está en [[16 - Herramientas de fuzzing]].

# Instalación

```shell-session
# La forma recomendada (v2, la rama actual)
$ go install github.com/ffuf/ffuf/v2@latest
# Paquete de la distro (puede ir por detrás de versión)
$ sudo apt install ffuf
# Contenedor
$ docker run --rm -it secsi/ffuf -h        # imagen community (ffuf no publica una oficial)
```

> [!warning]+ ffuf v1 vs v2
> `ffuf` v2 (2023+) cambió algunas cosas respecto a tutoriales viejos: el modo `sniper` es nuevo, `-recursion` mejoró, y ciertos flags de filtrado se ampliaron. Si un comando de un writeup antiguo falla, comprueba tu versión con `ffuf -V` — buena parte del material de HTB y blogs asume v1.

# Anatomía de un comando

Los dos flags que nunca faltan: `-w` (wordlist) y `-u` (URL con `FUZZ`).

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u https://target/FUZZ
```

# Leer la salida (la mitad del trabajo)

`ffuf` imprime, por cada acierto, un puñado de métricas — y <mark style="background: #FF5582A6;">esas métricas son justo lo que luego usarás para filtrar el ruido</mark>:

```shell-session
admin      [Status: 200, Size: 1234, Words: 56, Lines: 12, Duration: 45ms]
login.php  [Status: 200, Size: 4096, Words: 210, Lines: 88, Duration: 51ms]
backup     [Status: 301, Size: 0,    Words: 1,  Lines: 1,  Duration: 40ms]
```

| Campo | Qué es | Para qué sirve |
| --- | --- | --- |
| `Status` | Código HTTP | Filtrar por `-mc`/`-fc` |
| `Size` | Bytes del cuerpo | Detectar *soft-404* (todos igual tamaño) |
| `Words` / `Lines` | Palabras / líneas | Afinar cuando el `Size` varía por poco |
| `Duration` | Latencia | Pistas de comportamiento distinto |

<mark style="background: #8000E1A6;">Si cientos de resultados comparten exactamente el mismo `Size`, casi seguro son la misma página de "no encontrado"</mark> (un *soft-404*) y hay que filtrarlos — el arte que desarrolla [[05 - Matching y filtrado de resultados]].

# Flags globales útiles

```shell-session
-c        # salida con color
-v        # verbose: muestra la URL completa y redirecciones
-s        # silent: solo el resultado, sin banner (ideal para pipes/scripts)
-of json  # formato de salida (json/ejson/html/md/csv/ecsv/all) con -o fichero
```

`ffuf` lee config de `~/.config/ffuf/ffufrc` (o `~/.ffufrc` como *fallback*) o de `-config fichero.ffufrc` para no repetir flags. El siguiente paso es cómo alimentarlo: [[01 - Wordlists, keywords y modos de ffuf|wordlists, keywords y modos]].
