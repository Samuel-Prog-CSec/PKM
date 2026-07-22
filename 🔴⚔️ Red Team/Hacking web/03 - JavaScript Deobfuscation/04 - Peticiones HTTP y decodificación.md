---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - JavaScript
Fecha de actualización: 2026-06-02
Nota previa: "[[03 - Desofuscación y análisis de código]]"
Nota siguiente:
Area: "[[JavaScript Deobfuscation.base|JavaScript Deobfuscation]]"
---
---

El [[03 - Desofuscación y análisis de código|análisis]] reveló que `secret.js` envía un `POST` vacío a `/serial.php`. Ahora replicamos esa funcionalidad oculta a mano con `curl` para ver qué responde el servidor.

# Replicar la petición con `curl`

`curl` pide cualquier URL desde la terminal. Una petición simple (GET) devuelve el HTML:

```shell-session
$ curl http://SERVER_IP:PORT/
```

Para un `POST`, añadimos `-X POST`; para enviar datos, `-d "param=valor"`; y `-s` reduce el ruido de la salida:

```shell-session
$ curl -s http://SERVER_IP:PORT/serial.php -X POST -d "param1=sample"

ZG8gdGhlIGV4ZXJjaXNlLCBkb24ndCBjb3B5IGFuZCBwYXN0ZSA7KQo=
```

> [!info]+ `curl` a fondo está en otro sitio
> Aquí usamos `curl` solo para replicar la petición descubierta. El dominio completo de `curl` y las peticiones HTTP (cabeceras, cookies, métodos, autenticación) es material de herramienta — su tratamiento exhaustivo corresponde al módulo *Web Requests*, no a esta nota.

El servidor responde con un bloque que claramente está **codificado**. Decodificarlo es el último paso.

# Decodificación

<mark style="background: #FFB86CA6;">El código ofuscado contiene muy a menudo bloques de texto codificados que se decodifican en ejecución</mark>. Reconocer y revertir las codificaciones comunes es esencial. Las tres más frecuentes:

## Base64

<mark style="background: #ADCCFFA6;">`base64` representa cualquier dato usando solo caracteres alfanuméricos más `+` y `/`</mark>. Se reconoce por ese alfabeto y, **cuando lo lleva**, por el relleno final con `=` (aparece solo si la longitud de entrada no es múltiplo de 3). Con padding estándar la longitud es múltiplo de 4; las variantes sin relleno (`base64url`, la de los `JWT`) no cumplen ninguna de las dos.

```shell-session
$ echo https://www.hackthebox.eu/ | base64
aHR0cHM6Ly93d3cuaGFja3RoZWJveC5ldS8K

$ echo aHR0cHM6Ly93d3cuaGFja3RoZWJveC5ldS8K | base64 -d
https://www.hackthebox.eu/
```

## Hex

Codifica cada carácter por su valor `hex` en la tabla `ASCII` (`a`=`61`, `b`=`62`…). Se reconoce porque solo usa `0-9` y `a-f` (`man ascii` para la tabla completa).

```shell-session
$ echo https://www.hackthebox.eu/ | xxd -p
68747470733a2f2f7777772e6861636b746865626f782e65752f0a

$ echo 68747470733a2f2f7777772e6861636b746865626f782e65752f0a | xxd -p -r
https://www.hackthebox.eu/
```

## Caesar / ROT13

Desplaza cada letra un número fijo de posiciones; `rot13` desplaza 13. Aunque parezca aleatorio, <mark style="background: #FFB8EBA6;">se reconoce porque conserva la estructura</mark>: `http://www` se convierte en `uggc://jjj`.

```shell-session
$ echo https://www.hackthebox.eu/ | tr 'A-Za-z' 'N-ZA-Mn-za-m'
uggcf://jjj.unpxgurobk.rh/
# el mismo comando decodifica (rot13 es simétrico)
```

> [!important]+ CyberChef: la navaja suiza del decoding
> HTB sugiere [Cipher Identifier](https://www.boxentriq.com/code-breaking/cipher-identifier), pero la herramienta de referencia real es <mark style="background: #FF5582A6;">[CyberChef](https://gchq.github.io/CyberChef/)</mark>: encadena operaciones (base64 → hex → rot13 → gunzip…) en una "receta" visual, ideal porque el código ofuscado suele **anidar varias codificaciones**. Su operación **Magic** detecta automáticamente la codificación y propone la receta de decodificación. Para cadenas codificadas en cualquier reto o payload, es la primera parada.

> [!warning]+ Codificación ≠ cifrado
> Decodificar no requiere clave; **revertir** una codificación es trivial. Pero muchos ofuscadores usan **cifrado** (codificar con una clave), lo que complica enormemente el *reversing* —imposible sin la clave—. La buena noticia para el atacante: <mark style="background: #8000E1A6;">si el script debe ejecutarse en el cliente, la clave de descifrado suele estar dentro del propio script</mark>, así que casi siempre acaba siendo recuperable.

---

Con esto cerramos el flujo completo: <mark style="background: #8000E1A6;">localizar el JS → reconocer la ofuscación → desofuscar → analizar la función → replicarla → decodificar su salida</mark>. La misma metodología que aplicas a un *stager* de malware sirve para destapar endpoints ocultos y lógica del lado cliente en un pentest web — y enlaza directamente con el análisis de `js_files` del [[11 - Spidering con Scrapy|recon]] y con la lectura de payloads ofuscados en [[04 - Descubrimiento de XSS|XSS]].
