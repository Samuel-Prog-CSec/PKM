---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-19
Nota previa: "[[01 - Wordlists, keywords y modos de ffuf]]"
Nota siguiente: "[[03 - Fuzzing de dominios con ffuf]]"
Area: "[[Ffuf.base|Ffuf]]"
---
---

El caso más común: descubrir **directorios y archivos** que la aplicación no enlaza. La mecánica en `ffuf` es directa; el arte está en las extensiones, la recursión y el filtrado.

# Directorios

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
       -u https://target/FUZZ
```

Un `301`/`302` hacia `/algo/` suele indicar un directorio real. <mark style="background: #FFB8EBA6;">No sigas las redirecciones por defecto</mark>: el `3xx` es justo la señal que buscas; `-r` (follow) las oculta.

# Archivos (con extensiones)

`-e` prueba cada palabra con varios sufijos. Ajusta las extensiones a la **tecnología detectada** ([[09 - Fingerprinting web|fingerprinting]]): `.php` en PHP, `.aspx` en IIS, y siempre los de backup:

```shell-session
$ ffuf -w raft-medium-files.txt -u https://target/FUZZ \
       -e .php,.bak,.old,.txt,.zip,.tar.gz,~
```

<mark style="background: #FFB86CA6;">Los sufijos de backup (`.bak`, `.old`, `.swp`, `~`, `.save`) son oro</mark>: un `config.php.bak` sirve el código fuente en claro en vez de ejecutarlo.

# Recursión

`-recursion` re-lanza el fuzz automáticamente sobre cada directorio que encuentra, hasta `-recursion-depth`:

```shell-session
$ ffuf -w raft-medium-directories.txt -u https://target/FUZZ \
       -recursion -recursion-depth 2 -e .php -recursion-strategy default
# -recursion-strategy: 'default' solo recursa dirs confirmados por redirect (dirigido); 'greedy' en todos los matches
```

> [!warning]+ La recursión explota el número de peticiones
> Cada directorio nuevo dispara una wordlist entera. Con `-recursion-depth 2` y una lista mediana, pasas de miles a **cientos de miles** de peticiones — ruidoso y lento. Empieza sin recursión con una lista corta (`common.txt`), identifica los directorios interesantes y **recursa dirigido** sobre ellos con `-recursion-depth 1`. Para forced browsing recursivo serio, [[16 - Herramientas de fuzzing|feroxbuster]] lo hace mejor de fábrica.

# El problema del soft-404

<mark style="background: #FF5582A6;">Muchas apps devuelven `200 OK` para rutas inexistentes</mark> (una página de error "bonita"), inundando la salida de falsos positivos. Se detecta porque **todos** comparten `Size`/`Words`, y se elimina filtrando por esa métrica o con autocalibración (`-ac`) — el tema central de [[05 - Matching y filtrado de resultados]].

# Receta práctica

1. Barrido rápido: `common.txt`, sin recursión, para ver el terreno.
2. Pasada profunda: `raft-medium-*` sobre los directorios prometedores.
3. Extensiones según tecnología + sufijos de backup.
4. Filtrar el soft-404 desde el primer comando.

Tras rutas y archivos, la otra gran superficie: [[03 - Fuzzing de dominios con ffuf|subdominios y vhosts]].
