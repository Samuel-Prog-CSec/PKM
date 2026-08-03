---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Descripción: "El fuzzing de directorios descubre carpetas en un nivel"
Fecha de actualización: 2026-06-02
Nota previa: "[[17 - Fuzzing de directorios y archivos]]"
Nota siguiente: "[[19 - Fuzzing de parámetros y valores]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El [[17 - Fuzzing de directorios y archivos|fuzzing de directorios]] descubre carpetas en un nivel. Pero si el objetivo tiene una estructura anidada profunda, fuzzear cada nivel a mano es tedioso. <mark style="background: #ADCCFFA6;">El fuzzing recursivo automatiza el descenso: cada directorio que encuentra se convierte en un nuevo objetivo de fuzzing</mark>.

# Cómo funciona

Tres pasos que se repiten:

1. **Fuzzing inicial**: empieza en la raíz (`/FUZZ`), envía la `wordlist` y busca respuestas válidas (un `301`/`200` que indique un directorio).
2. **Descubrir y expandir**: al encontrar un directorio (`/admin`), crea una nueva rama (`/admin/FUZZ`) y vuelve a recorrer la `wordlist` dentro de ella.
3. **Profundidad iterativa**: repite por cada directorio nuevo, ramificando más y más hasta alcanzar un límite de profundidad o quedarse sin directorios.

Visualízalo como un árbol: la raíz es el tronco, cada directorio una rama, y la recursión explora cada rama hasta las hojas (archivos) o hasta el límite fijado.

# `ffuf -recursion` en acción

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
  -ic -v -u http://IP:PORT/FUZZ -e .html -recursion

[Status: 301] http://IP:PORT/level1   --> /level1/
[INFO] Adding a new job to the queue: http://IP:PORT/level1/FUZZ
[Status: 301] http://IP:PORT/level1/level2
[INFO] Adding a new job to the queue: http://IP:PORT/level1/level2/FUZZ
[Status: 200] http://IP:PORT/level1/level3/index.html
:: Progress: [441088/441088] :: Job [4/4] :: Duration: [0:00:06]
```

- `-recursion`: fuzzea recursivamente cada directorio encontrado. Al hallar `level1` (código `301`) encola un nuevo *job* sobre `level1/FUZZ`, y así sucesivamente.
- `-ic`: ignora las líneas comentadas (`#`) de la `wordlist` para que no se traten como entradas válidas.

Fíjate en el contador `Job [4/4]`: cada directorio descubierto añadió un trabajo a la cola.

# Controlar la explosión

> [!warning]+ La recursión explota de forma combinatoria
> Cada directorio descubierto lanza la `wordlist` **completa** de nuevo. Con una lista de 220k entradas y varios niveles, las peticiones se multiplican: 220k × (nº de directorios encontrados) por nivel. <mark style="background: #FF5582A6;">Sin límite de profundidad, un fuzzing recursivo puede generar millones de peticiones y tumbar el servidor</mark> (o tu paciencia). El `-recursion-depth` no es opcional en objetivos reales.

`ffuf` ofrece controles para acotarlo:

- `-recursion-depth N`: profundidad máxima. `-recursion-depth 2` limita a la raíz y sus subdirectorios inmediatos.
- `-rate N`: peticiones por segundo, para no saturar el servidor.
- `-timeout N`: tiempo máximo por petición, evita que se cuelgue en hosts no responsivos.

```shell-session
$ ffuf -w directory-list-2.3-medium.txt -ic -u http://IP:PORT/FUZZ \
  -e .html -recursion -recursion-depth 2 -rate 500
```

> [!info]+ Alternativa: `feroxbuster`
> `feroxbuster` hace *forced browsing* **recursivo por defecto**, con control de profundidad (`-d`) y filtros integrados — para descubrimiento recursivo profundo suele ser más cómodo que `ffuf`. Su carácter de "navegador forzado" lo hace ideal cuando lo único que quieres es mapear toda la estructura.

> [!warning]+ Soft-404 y la recursión descontrolada
> Si el servidor responde `200` a **cualquier** ruta (un *soft-404* o un *wildcard*), la recursión creerá que cada palabra es un directorio válido y ramificará hasta el infinito. Establecer una *baseline* y filtrar la respuesta por defecto (ver [[21 - Filtrado de la salida de fuzzing]] y [[22 - Validación de hallazgos]]) es lo que evita ese descontrol.

Hasta aquí hemos fuzzeado **rutas**. El siguiente objetivo son los **parámetros** que la aplicación procesa por debajo: [[19 - Fuzzing de parámetros y valores]].
