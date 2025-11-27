---
tags:
  - Pentesting
  - Web/Red-Team
  - Pentesting/Enumeracion
Fecha de actualización: 2025-10-08
Nota previa: "[[Recursivo]]"
Nota siguiente: "[[Subdominios y host virtual]]"
Area: "[[Fuzzing web]]"
---
---

# Parámetros GET: compartir información abiertamente
A menudo se detectan parámetros `GET` directamente en la *URL*, después de un signo de interrogación (`?`). Se unen varios parámetros utilizando *ampersands* (`&`). Por ejemplo:
```http
https://example.com/search?query=fuzzing&category=security
```

En esta URL:
- `query`es un parámetro con el valor "fuzzing"
- `category`es otro parámetro con el valor "seguridad"

Los parámetros `GET` son como postales, su información es visible para cualquiera que mire la *URL*. <mark style="background: #ADCCFFA6;">Se utilizan principalmente para acciones que no cambian el estado del servidor</mark>, como buscar o filtrar.

---

# Parámetros POST: comunicación detrás de escena
Los parámetros `POST` son más como sobres sellados, que <mark style="background: #ADCCFFA6;">llevan su información discretamente dentro del cuerpo de la solicitud *[[HTTP]]*</mark>. <mark style="background: #FFB8EBA6;">No son visibles directamente</mark> en la *URL*, lo que los convierte en el método preferido para transmitir datos confidenciales como credenciales de inicio de sesión, información personal o detalles financieros.

Cuando se envía un formulario o se interactúa con una página web que utiliza solicitudes *POST*, sucede lo siguiente:
1. **Recolección de datos**: la información ingresada en los campos del formulario <mark style="background: #8000E1A6;">se recopila y prepara para su transmisión</mark>.
2. **Encoding**: estos <mark style="background: #FFB86CA6;">datos se codifican en un formato específico</mark>, normalmente `application/x-www-form-urlencoded` o `multipart/form-data`:
    - `application/x-www-form-urlencoded`: este formato codifica los datos como <mark style="background: #8000E1A6;">pares clave-valor</mark> separados por *ampersands* (`&`), similar a los parámetros `GET` pero colocados dentro del cuerpo de la solicitud en lugar de la *URL*.
    - `multipart/form-data`: este formato <mark style="background: #8000E1A6;">se utiliza al enviar archivos junto con otros datos</mark>. Divide el cuerpo de la solicitud en varias partes, cada una de las cuales contiene un dato específico o un archivo.
3. **Solicitud [[HTTP]]**: los datos codificados se colocan dentro del cuerpo de una solicitud `HTTP POST` y se envían al servidor web.
4. **Procesamiento del lado del servidor**: el servidor recibe la solicitud `POST`, decodifica los datos y los procesa según la lógica de la aplicación.

A continuación se muestra un ejemplo simplificado de cómo podría verse una solicitud *POST* al enviar un formulario de inicio de sesión:
```http
POST /login HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded

username=your_username&password=your_password
```
> [!info]+
> - `POST`: indica el método [[HTTP]] (*POST*).
> - `/login`: especifica la ruta *URL* <mark style="background: #CACFD9A6;">donde se envían los datos del formulario</mark>.
> - `Content-Type`: especifica <mark style="background: #FFB8EBA6;">cómo se codifican los datos</mark> en el cuerpo de la solicitud (`application/x-www-form-urlencoded` en este caso).
> - `Request Body`: contiene los <mark style="background: #FFB8EBA6;">datos del formulario codificado como pares clave-valor</mark> (`username` y `password`).

---

# Por qué los parámetros son importantes para el fuzzing
Los parámetros son las <mark style="background: #ADCCFFA6;">puertas de enlace a través de las cuales puedes interactuar con una aplicación web</mark>. Al manipular sus valores, puede <mark style="background: #FFB8EBA6;">probar cómo responde la aplicación a diferentes entradas, descubriendo potencialmente vulnerabilidades</mark>. Por ejemplo:
- Modificar el ID de un producto en la *URL* de un carrito de compras podría revelar errores de precios o acceso no autorizado a los pedidos de otros usuarios.
- Modificar un parámetro oculto en una solicitud podría desbloquear funciones administrativas o características ocultas.
- Inyectar código malicioso en una consulta de búsqueda podría exponer vulnerabilidades como [[Cross-Site Scripting (XSS)]] o [[💉🩸 SQL Injection]].

---
# Caso de uso con wenum
En este caso podemos usar [[Herramientas#wfuzz/wenum|wenum]] explorar los parámetros `GET` y `POST` dentro de nuestra aplicación web de destino, con el <mark style="background: #ADCCFFA6;">objetivo final de descubrir valores ocultos que desencadenan respuestas únicas, revelando potencialmente vulnerabilidades</mark>.
> [!help]+
> Podemos instalar las herramientas como `wenum` en nuestro host de ataque:
> - `$ pipx install git+https://github.com/WebFuzzForge/wenum`
> - `$ pipx runpip wenum install setuptools`

Para comenzar, usaremos `curl` para interactuar manualmente con el punto final y comprender mejor su comportamiento:
```shell-session
$ curl http://IP:PORT/get.php

Invalid parameter value
x: 
```

La respuesta nos dice que el parámetro `x` falta. Podemos intentar agregar un valor:
```shell-session
$ curl http://IP:PORT/get.php?x=1

Invalid parameter value
x: 1
```
> [!fail]+
> El servidor reconoce el parámetro `x` esta vez pero indica que el valor proporcionado (`1`) no es válido. Esto sugiere que la aplicación efectivamente está verificando el valor de este parámetro y produciendo diferentes respuestas basadas en su validez. **Nuestro objetivo es encontrar el valor específico para desencadenar una respuesta diferente** y, con suerte, más reveladora.

Vamos a usar `wenum` para fuzear el valor del parámetro "`x`", comenzando con la lista de palabras de SecLists `common.txt`:
```shell-session
$ wenum -w /usr/share/seclists/Discovery/Web-Content/common.txt --hc 404 -u "http://IP:PORT/get.php?x=FUZZ"

...
 Code    Lines     Words        Size  Method   URL 
...
 200       1 L       1 W        25 B  GET      http://IP:PORT/get.php?x=OA... 

Total time: 0:00:02
Processed Requests: 4731
Filtered Requests: 4730
Requests/s: 1681
```
> [!important]+
> - `-w`: ruta a tu lista de palabras.
> - `--hc 404`:<mark style="background: #8000E1A6;"> oculta respuestas</mark> con el código de estado *404* (no encontrado), ya que `wenum` De forma predeterminada, registrará cada solicitud que realice.
> - `http://IP:PORT/get.php?x=FUZZ`: esta es la *URL* de destino. `wenum` reemplazará el valor del parámetro `FUZZ` con palabras de la lista de palabras.

Hay una línea que destaca en la respuesta:
```bash
 200       1 L       1 W        25 B  GET      http://IP:PORT/get.php?x=OA...
```
> [!done]
> Esto indica que cuando el parámetro `x` se estableció en el valor "`OA...`" el <mark style="background: #FF5582A6;">servidor respondió con un código de estado `200 OK`, que sugiere una entrada válida</mark>.

## Caso de uso con POST
Fuzear los parámetros `POST` requiere un enfoque ligeramente diferente al difuminar los parámetros `GET`. En lugar de agregar valores directamente a la *URL*, usaremos [[Herramientas#FFUF|ffuf]] para <mark style="background: #FFB86CA6;">enviar los payloads dentro del cuerpo de la solicitud</mark>. Esto nos permite probar cómo la aplicación maneja los datos enviados a través de formularios u otros mecanismos `POST`.

Nuestra aplicación de destino también cuenta con un parámetro POST llamado "`y`" dentro del `post.php` guion. Vamos a investigarlo con `curl` para ver su comportamiento predeterminado:
```shell-session
$ curl -d "" http://IP:PORT/post.php

Invalid parameter value
y: 
```
> [!missing]+
> La flag `-d` ordena a `curl` a realizar una solicitud `POST` con el cuerpo vacío. La respuesta nos dice que el parámetro `y` se espera pero **no se proporciona**.

Al igual que con los parámetros `GET`, probar manualmente los valores de los parámetros `POST` sería ineficiente. Usaremos `ffuf` para automatizar este proceso:
```shell-session
$ ffuf -u http://IP:PORT/post.php -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "y=FUZZ" -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200 -v

        /'___\  /'___\           /'___\       
       /\ \__/ /\ \__/  __  __  /\ \__/       
       \ \ ,__\\ \ ,__\/\ \/\ \ \ \ ,__\      
        \ \ \_/ \ \ \_/\ \ \_\ \ \ \ \_/      
         \ \_\   \ \_\  \ \____/  \ \_\       
          \/_/    \/_/   \/___/    \/_/       

       v2.1.0-dev
________________________________________________

 :: Method           : POST
 :: URL              : http://IP:PORT/post.php
 :: Wordlist         : FUZZ: /usr/share/seclists/Discovery/Web-Content/common.txt
 :: Header           : Content-Type: application/x-www-form-urlencoded
 :: Data             : y=FUZZ
 :: Follow redirects : false
 :: Calibration      : false
 :: Timeout          : 10
 :: Threads          : 40
 :: Matcher          : Response status: 200
________________________________________________

[Status: 200, Size: 26, Words: 1, Lines: 2, Duration: 7ms]
| URL | http://IP:PORT/post.php
    * FUZZ: SU...

:: Progress: [4730/4730] :: Job [1/1] :: 5555 req/sec :: Duration: [0:00:01] :: Errors: 0 ::
```

Nuevamente, verá respuestas de parámetros en su mayoría no válidas. El valor correcto ("`SU...`") se destacará con su `200 OK`
```bash
000000326:  200     1 L      1 W     26 Ch     "SU..."
```

De manera similar, después de identificar "`SU...`" como valor correcto, podemos validarlo después con `curl`:
```shell-session
$ curl -d "y=SU..." http://IP:PORT/post.php

HTB{...}
```