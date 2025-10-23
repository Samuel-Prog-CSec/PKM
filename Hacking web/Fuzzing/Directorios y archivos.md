---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
Fecha de actualización: 2025-10-08
Nota previa: "[[Herramientas]]"
Nota siguiente: "[[Recursivo]]"
Area: "[[Fuzzing web]]"
---
---

Las aplicaciones web suelen tener <mark style="background: #ADCCFFA6;">directorios y archivos que no están directamente vinculados ni son visibles para los usuarios</mark>. Estos recursos ocultos pueden contener información confidencial, archivos de respaldo, archivos de configuración o incluso versiones de aplicaciones antiguas y vulnerables. El **fuzzing de directorios y archivos** tiene como <mark style="background: #FFB8EBA6;">objetivo descubrir estos activos ocultos, proporcionando a los atacantes posibles puntos de entrada o información valiosa para su posterior explotación</mark>.

# Descubriendo activos ocultos
Estas áreas ocultas podrían contener información valiosa para los atacantes, entre ellas:
- **Datos sensibles**: copia de seguridad de archivos, ajustes de configuración o registros que contengan credenciales de usuario u otra información confidencial.
- **Contenido desactualizado**: versiones anteriores de archivos o scripts que <mark style="background: #FFB86CA6;">pueden ser vulnerables a exploits conocidos</mark>.
- **Recursos de desarrollo**: entornos de prueba, sitios de preparación o paneles administrativos que podrían aprovecharse para futuros ataques.
- **Funcionalidades ocultas**: funciones o puntos finales <mark style="background: #8000E1A6;">no documentados que podrían exponer vulnerabilidades inesperadas</mark>.

## La importancia de encontrar activos ocultos
<mark style="background: #ADCCFFA6;">Cada descubrimiento contribuye a obtener una imagen completa de la estructura y funcionalidad de la aplicación web</mark>, esencial para una evaluación de seguridad exhaustiva. <mark style="background: #FFB8EBA6;">Estas áreas ocultas a menudo carecen de las medidas de seguridad sólidas</mark> que se encuentran en los componentes públicos, lo que las convierte en objetivos principales de explotación.

Incluso si un activo oculto no revela inmediatamente una vulnerabilidad,<mark style="background: #FF5582A6;"> la información obtenida puede resultar invaluable en las últimas etapas de una prueba de penetración</mark>. Esto podría incluir cualquier cosa, desde comprender la pila de tecnología subyacente hasta descubrir datos confidenciales que puedan usarse para futuros ataques.

## Listas de palabras
Las listas de palabras son **el elemento vital del fuzzing de directorios y archivos**. Proporcionan los posibles nombres de directorios y archivos que la herramienta elegida utilizará para sondear la aplicación web. <mark style="background: #ADCCFFA6;">Las listas de palabras efectivas pueden aumentar significativamente sus posibilidades de descubrir activos ocultos</mark>.

Las listas de palabras generalmente se compilan a partir de varias fuentes. Esto a menudo incluye extraer de la web nombres de archivos y directorios comunes, analizar violaciones de datos disponibles públicamente y extraer información de directorios de vulnerabilidades conocidas. Luego, estas <mark style="background: #8000E1A6;">listas de palabras se seleccionan meticulosamente</mark>, eliminando duplicados y entradas irrelevantes para garantizar una eficiencia y eficacia óptimas durante las operaciones de fuzzing. El objetivo es crear una lista completa de posibles directorios y nombres de archivos que probablemente se encontrarán en servidores web, lo que le permitirá investigar exhaustivamente una aplicación de destino en busca de activos ocultos.

Las [[Herramientas]] para fuzzing tienen listas de palabras integradas, pero están diseñadas para funcionar perfectamente con archivos de listas de palabras externos. Esta flexibilidad le permite utilizar listas de palabras preexistentes o crear las suyas propias para adaptar sus esfuerzos de fuzzing a objetivos y escenarios específicos.

Una de las colecciones de listas de palabras más completas y utilizadas es [SecLists](https://github.com/danielmiessler/SecLists),<mark style="background: #FFB8EBA6;"> proporciona un vasto repositorio de listas de palabras para diversos fines de pruebas de seguridad, incluido el fuzzing de directorios y archivos</mark>.

`SecLists`contiene listas de palabras para:
- Nombres comunes de directorios y archivos
- Archivos de copia de seguridad
- Archivos de configuración
- Scripts vulnerables
- Y mucho más...

Las listas de palabras más utilizadas para fuzear directorios y archivos web en `SecLists` son:
- `Discovery/Web-Content/common.txt`: esta lista de palabras de propósito general contiene una amplia gama de nombres de archivos y directorios comunes en servidores web. Es un <mark style="background: #FFB86CA6;">excelente punto de partida</mark> para el fuzzing y a menudo produce resultados valiosos.
- `Discovery/Web-Content/directory-list-2.3-medium.txt`: esta es una lista de palabras más extensa <mark style="background: #FFB86CA6;">centrada específicamente en los nombres de directorios</mark>. Es una buena opción cuando necesitas profundizar en directorios potenciales.
- `Discovery/Web-Content/raft-large-directories.txt`: esta lista de palabras cuenta con una <mark style="background: #FFB86CA6;">enorme colección de nombres de directorios compilados a partir de diversas fuentes</mark>. Es un recurso valioso para realizar campañas de fuzzing exhaustivas.
- `Discovery/Web-Content/big.txt`: como sugiere el nombre, esta es una<mark style="background: #FFB8EBA6;"> lista de palabras masiva que contiene nombres de directorios y archivos</mark>. Es útil cuando quieres lanzar una red amplia y explorar todas las posibilidades.

---
# Caso de uso con ffuf
Usaremos `ffuf` para este ejemplo de fuzzing. Como funciona:
1. `Wordlist`: proporcionar a `ffuf` una lista de palabras que contiene posibles nombres de directorios o archivos.
2. `URL with FUZZ keyword`: construir una *URL* con la palabra clave `FUZZ` como marcador de posición donde se insertarán las entradas de la lista de palabras.
3. `Requests`: `ffuf` itera a través de la lista de palabras, reemplazando el `FUZZ` en la *URL* con cada entrada y envío de solicitudes [[HTTP]] al servidor web de destino.
4. `Response Analysis`: `ffuf` analiza las respuestas del servidor (códigos de estado, longitud del contenido, etc.) y filtra los resultados según sus criterios.

Por ejemplo, si se desea buscar directorios, se puede utilizar una URL como esta:
```http
http://localhost/FUZZ
```

## Fuzzing de directorio
El <mark style="background: #ADCCFFA6;">primer paso es realizar fuzzing de directorios</mark>, lo que nos ayuda a descubrir directorios ocultos en el servidor web:
```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -u http://IP:PORT/FUZZ


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
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-399
________________________________________________

[...]

w2ksvrus                [Status: 301, Size: 0, Words: 1, Lines: 1, Duration: 0ms]
:: Progress: [220559/220559] :: Job [1/1] :: 100000 req/sec :: Duration: [0:00:03] :: Errors: 0 ::
```
> [!info]+
> - `-w`(**lista de palabras**): especifica la <mark style="background: #FFB8EBA6;">ruta a la lista de palabras que queremos usar</mark>. En este caso, utilizamos una lista de directorios de tamaño mediano de `SecLists`.
> - `-u` (**URL**): <mark style="background: #FFB8EBA6;">especifica la URL base para fuzz</mark>. El `FUZZ` actúa como un marcador de posición donde el fuzzer insertará palabras de la lista de palabras.
> 
> El resultado anterior muestra que `ffuf` ha descubierto un directorio llamado `w2ksvrus` en el servidor web de destino, como lo indica el código de estado 301 (*Movido permanentemente*).<mark style="background: #FF5582A6;"> Este podría ser un posible punto de entrada para futuras investigaciones</mark>.

## Fuzzing de archivos
Mientras que el fuzzing de directorios se centra en encontrar carpetas, el fuzzing de archivos <mark style="background: #ADCCFFA6;">profundiza en el descubrimiento de archivos específicos dentro de esos directorios o incluso en la raíz de la aplicación web</mark>. Las aplicaciones web utilizan varios tipos de archivos para servir contenido y realizar diferentes funciones. Algunas extensiones de archivo comunes incluyen:
- `.php`: archivos que contienen código *PHP*, un popular lenguaje de programación del lado del servidor.
- `.html`: archivos que definen la estructura y contenido de las páginas web.
- `.txt`: archivos de texto sin formato, que <mark style="background: #8000E1A6;">a menudo almacenan información o registros simples</mark>.
- `.bak`: los <mark style="background: #FFB86CA6;">archivos de respaldo</mark> se crean para preservar versiones anteriores de los archivos en caso de errores o modificaciones.
- `.js`: los archivos que contienen código *JavaScript* agregan interactividad y funcionalidad dinámica a las páginas web.

Al buscar estas extensiones comunes con una lista de palabras de nombres de archivos comunes, aumentamos nuestras posibilidades de descubrir archivos que podrían estar expuestos involuntariamente o mal configurados, lo que podría conducir a la divulgación de información u otras vulnerabilidades.

Utilizar `ffuf` y una lista de palabras de nombres de archivos comunes para buscar archivos ocultos con extensiones específicas:
```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u http://IP:PORT/w2ksvrus/FUZZ -e .html,.php,.html,.txt,.bak,.js -v 


        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : GET
 :: URL              : http://IP:PORT/w2ksvrus/FUZZ.html
 :: Wordlist         : FUZZ: /usr/share/seclists/Discovery/Web-Content/common.txt
 :: Extensions       : .php .html .txt .bak .js 
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200-299,301,302,307,401,403,405,500
________________________________________________

[Status: 200, Size: 111, Words: 2, Lines: 2, Duration: 0ms]
| URL | http://IP:PORT/w2ksvrus/dblclk.html
    * FUZZ: dblclk

[Status: 200, Size: 112, Words: 6, Lines: 2, Duration: 0ms]
| URL | http://IP:PORT/w2ksvrus/index.html
    * FUZZ: index

:: Progress: [28362/28362] :: Job [1/1] :: 0 req/sec :: Duration: [0:00:00] :: Errors: 0 ::
```

> [!success]+
> El `ffuf` muestra que <mark style="background: #FF5582A6;">descubrió dos archivos</mark> dentro del directorio `/w2ksvrus`:
> - `dblclk.html`: este archivo tiene un tamaño de 111 bytes y consta de 2 palabras y 2 líneas. Puede que su propósito no sea evidente de inmediato, pero <mark style="background: #FFB8EBA6;">es un posible punto de interés para futuras investigaciones</mark>. Quizás contenga contenido o funcionalidad oculta.
> - `index.html`: este archivo es un poco más grande, 112 bytes, y contiene 6 palabras y 2 líneas. Es <mark style="background: #FFB8EBA6;">probable que sea la página de índice predeterminada</mark> para `w2ksvrus`.