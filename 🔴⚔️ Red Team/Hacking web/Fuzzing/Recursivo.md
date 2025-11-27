---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
Fecha de actualización: 2025-10-08
Nota previa: "[[Directorios y archivos]]"
Nota siguiente: "[[Parámetros y valores]]"
Area: "[[Fuzzing web]]"
---
---

El fuzzing recursivo es una <mark style="background: #ADCCFFA6;">forma automatizada de explorar las profundidades de la estructura de directorios de una aplicación web</mark>. Es un proceso bastante básico de 3 pasos:
1. `Initial Fuzzing`:
    - El <mark style="background: #FFB86CA6;">proceso de fuzzing comienza con el directorio de nivel superior, normalmente la raíz web</mark> (`/`).
    - El fuzzer comienza a enviar solicitudes basadas en la lista de palabras proporcionada que contiene el directorio potencial y los nombres de los archivos.
    - El fuzzer <mark style="background: #8000E1A6;">analiza las respuestas del servidor, buscando resultados exitosos</mark> (por ejemplo, HTTP 200 OK) que indiquen la existencia de un directorio.
2. `Directory Discovery and Expansion`:
    - Cuando se encuentra un directorio válido, el fuzzer no se limita a anotarlo. <mark style="background: #FFB8EBA6;">Crea una nueva rama para ese directorio</mark>, esencialmente agregando el nombre del directorio a la *URL* base.
    - Por ejemplo, si el fuzzer encuentra un directorio llamado `admin` en el nivel raíz, creará una nueva rama como `http://localhost/admin/`.
    - <mark style="background: #FFB86CA6;">Esta nueva rama se convierte en el punto de partida de un nuevo proceso de fuzzing</mark>. El fuzzer iterará nuevamente a través de la lista de palabras, agregando cada entrada a la *URL* de la nueva rama (por ejemplo, `http://localhost/admin/FUZZ`).
3. `Iterative Depth`:
    - <mark style="background: #FFB8EBA6;">El proceso se repite para cada directorio descubierto</mark>, creando más ramas y ampliando el alcance de fuzzing más profundamente en la estructura de la aplicación web.
    - Esto <mark style="background: #FF5582A6;">continúa hasta que se alcanza un límite de profundidad específico</mark> (por ejemplo, un máximo de tres niveles de profundidad) o no se encuentran más directorios válidos.

# ¿Por qué utilizar fuzzing recursivo?
El fuzzing recursivo es una necesidad práctica cuando se trabaja con aplicaciones web complejas:
- **Eficiencia**: <mark style="background: #8000E1A6;">automatizar el descubrimiento de directorios anidados ahorra mucho tiempo en comparación con la exploración manual.</mark>
- **Minuciosidad**: explora sistemáticamente cada rama de la estructura del directorio, <mark style="background: #FFB8EBA6;">reduciendo el riesgo de que falten activos ocultos</mark>.
- **Esfuerzo manual reducido**: no es necesario ingresar cada nuevo directorio en fuzz manualmente; la herramienta maneja todo el proceso.
- **Escalabilidad**: es <mark style="background: #FFB86CA6;">particularmente valioso para aplicaciones web a gran escala</mark> donde la exploración manual no sería práctica.

---

# Fuzzing recursivo con ffuf
Vamos a usar `ffuf` para demostrar el fuzzing recursivo:
```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -ic -v -u http://IP:PORT/FUZZ -e .html -recursion 

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://IP:PORT/FUZZ
 :: Wordlist         : FUZZ: /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
 :: Extensions       : .html 
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

[Status: 301, Size: 0, Words: 1, Lines: 1, Duration: 0ms]
| URL | http://IP:PORT/level1
| --> | /level1/
    * FUZZ: level1

[INFO] Adding a new job to the queue: http://IP:PORT/level1/FUZZ

[INFO] Starting queued job on target: http://IP:PORT/level1/FUZZ

[Status: 200, Size: 96, Words: 6, Lines: 2, Duration: 0ms]
| URL | http://IP:PORT/level1/index.html
    * FUZZ: index.html

[Status: 301, Size: 0, Words: 1, Lines: 1, Duration: 0ms]
| URL | http://IP:PORT/level1/level2
| --> | /level1/level2/
    * FUZZ: level2

[INFO] Adding a new job to the queue: http://IP:PORT/level1/level2/FUZZ

[Status: 301, Size: 0, Words: 1, Lines: 1, Duration: 0ms]
| URL | http://IP:PORT/level1/level3
| --> | /level1/level3/
    * FUZZ: level3

[INFO] Adding a new job to the queue: http://IP:PORT/level1/level3/FUZZ

[INFO] Starting queued job on target: http://IP:PORT/level1/level2/FUZZ

[Status: 200, Size: 96, Words: 6, Lines: 2, Duration: 0ms]
| URL | http://IP:PORT/level1/level2/index.html
    * FUZZ: index.html

[INFO] Starting queued job on target: http://IP:PORT/level1/level3/FUZZ

[Status: 200, Size: 126, Words: 8, Lines: 2, Duration: 0ms]
| URL | http://IP:PORT/level1/level3/index.html
    * FUZZ: index.html

:: Progress: [441088/441088] :: Job [4/4] :: 100000 req/sec :: Duration: [0:00:06] :: Errors: 0 ::
```

La adición del flag `-recursion` dice a  `ffuf` que fuzee cualquier directorio que encuentre de forma recursiva. En escenarios de fuzzing donde las listas de palabras contienen comentarios (*líneas que comienzan con `#`*), la opción `ffuf -ic` resulta invaluable. Al habilitar esta opción, `ffuf` <mark style="background: #FFB8EBA6;">ignora inteligentemente las líneas comentadas durante el fuzzing</mark>, impidiendo que sean tratadas como entradas válidas.

El fuzzing comienza en la raíz web (`http://IP:PORT/FUZZ`). Inicialmente, `ffuf` identifica un directorio llamado `level1`, indicado por la respuesta `301 (Moved Permanently)`. Esto significa una redirección y solicita a la herramienta que inicie un nuevo proceso de fuzzing dentro de este directorio, ramificando efectivamente su búsqueda.

Como `ffuf` explora recursivamente `level1`, descubre dos directorios adicionales: `level2` y `level3`. Cada uno se agrega a la cola de fuzzing, ampliando la profundidad de búsqueda. Además, un `index.html` El archivo se descubre dentro de `level1`.

El fuzzer trabaja sistemáticamente a través de su cola, identificando archivos `index.html` en los directorios `level2` y `level3`. En particular, el archivo `index.html` dentro del directorio `level3` destaca por su mayor tamaño de archivo que los demás.

Un análisis más detallado revela que este archivo contiene la bandera `HTB{r3curs1v3_fuzz1ng_w1ns}`, lo que significa una exploración exitosa de la estructura del directorio anidado.

## Ser responsable
Si bien el fuzzing recursivo es una técnica poderosa, <mark style="background: #ADCCFFA6;">también puede consumir muchos recursos</mark>, especialmente en aplicaciones web grandes. Las <mark style="background: #FFB86CA6;">solicitudes excesivas pueden saturar el servidor de destino</mark>, lo que podría causar problemas de rendimiento o activar mecanismos de seguridad.

Para **mitigar estos riesgos**, `ffuf` proporciona opciones para ajustar el proceso de fuzzing recursivo:
- `-recursion-depth`: esta flag permite <mark style="background: #FFB8EBA6;">establecer una profundidad máxima para la exploración recursiva</mark>. Por ejemplo, `-recursion-depth 2` limita el fuzzing a dos niveles de profundidad (el directorio inicial y sus subdirectorios inmediatos).
- `-rate`: controlar la velocidad a la que `ffuf` envía <mark style="background: #FFB8EBA6;">solicitudes por segundo</mark>, evitando que el servidor se sobrecargue.
- `-timeout`: esta opción <mark style="background: #FFB8EBA6;">establece el tiempo de espera para solicitudes individuales</mark>, lo que <mark style="background: #FF5582A6;">ayuda a evitar que el fuzzer se cuelgue en objetivos que no responden</mark>.
```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -ic -u http://IP:PORT/FUZZ -e .html -recursion -recursion-depth 2 -rate 500
```