---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - Fuzzing
Fecha de actualización: 2026-06-02
Nota previa: "[[18 - Fuzzing recursivo]]"
Nota siguiente: "[[20 - Fuzzing de vhosts y subdominios]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Tras descubrir rutas, el siguiente objetivo son los **parámetros**: las variables que transportan información entre el navegador y el servidor. <mark style="background: #ADCCFFA6;">El fuzzing de parámetros y valores manipula esos parámetros para ver cómo procesa la aplicación cada entrada</mark>, y es la puerta directa a vulnerabilidades de lógica e inyección.

# GET vs POST

| | GET | POST |
| - | - | - |
| **Dónde viajan** | En la URL, tras `?`, unidos por `&` | En el **cuerpo** de la petición |
| **Visibilidad** | Visibles (postal abierta) | Ocultos en el body (sobre cerrado) |
| **Uso típico** | Búsquedas, filtros (no cambian estado) | Login, datos sensibles, formularios |
| **Codificación** | URL | `application/x-www-form-urlencoded`, `multipart/form-data`, `application/json` |

```http
GET /search?query=fuzzing&category=security HTTP/1.1

POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=admin&password=secret
```

# Por qué importan

Los parámetros son las pasarelas para interactuar con la lógica de la app. Manipularlos descubre fallos:

- <mark style="background: #FFB86CA6;">Alterar un `id` de producto o de pedido puede dar acceso a datos de otros usuarios</mark> (`IDOR`).
- Un parámetro oculto (`?debug=1`, `?admin=true`) puede desbloquear features o funciones administrativas.
- Inyectar payloads en un parámetro expone [[00 - Introducción a XSS|XSS]], [[💉🩸 SQL Injection|SQLi]], `LFI`, `SSRF` y demás. El fuzzing localiza el parámetro y el punto de inyección; la explotación ya es cosa de cada técnica.

Hay **dos objetivos** distintos: descubrir **nombres** de parámetros que la app acepta pero no documenta, y fuzzear **valores** de un parámetro conocido para dar con el que dispara un comportamiento distinto.

# Fuzzing de valores (GET)

Primero entiende el endpoint manualmente con `curl`:

```shell-session
$ curl http://IP:PORT/get.php
Invalid parameter value
x:
$ curl "http://IP:PORT/get.php?x=1"
Invalid parameter value
x: 1
```

La app valida el valor de `x` y responde distinto según sea válido. Automatizamos la búsqueda del valor correcto con `wenum`:

```shell-session
$ wenum -w /usr/share/seclists/Discovery/Web-Content/common.txt --hc 404 -u "http://IP:PORT/get.php?x=FUZZ"

 Code   Lines   Words   Size   Method   URL
 200    1 L     1 W     25 B   GET      http://IP:PORT/get.php?x=OA...
```

- `--hc 404`: oculta las respuestas `404` (por defecto `wenum` registra **todas**).
- `x=FUZZ`: `wenum` sustituye `FUZZ` por cada palabra.

La línea con `200 OK` destaca entre el ruido de "Invalid parameter value": ese es el valor válido.

# Fuzzing de valores (POST)

Para POST, el payload va en el cuerpo con `-d`. Con `ffuf`:

```shell-session
$ ffuf -u http://IP:PORT/post.php -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "y=FUZZ" -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc 200 -v

[Status: 200, Size: 26] http://IP:PORT/post.php   * FUZZ: SU...
```

- `-X POST` + `-d "y=FUZZ"`: envía el payload en el body como dato POST.
- `-mc 200`: aquí filtramos al revés — solo **mostramos** los `200`.

> [!important]+ En el mundo real no hay un "200" que destaque
> En el lab, el valor correcto salta con un código distinto. En producción la app rara vez te lo pone tan fácil: muchas respuestas devuelven `200` con contenidos casi idénticos. Ahí la clave es filtrar por **tamaño**, **palabras** o **líneas** (`-fs`, `-fw`, `-fl`) en vez de por código — la disciplina de [[21 - Filtrado de la salida de fuzzing]].

# Descubrir nombres de parámetros ocultos

HTB se centra en fuzzear valores, pero en bug bounty lo más rentable suele ser <mark style="background: #FF5582A6;">descubrir parámetros que la app procesa pero no expone en ningún formulario ni enlace</mark>. La técnica: fuzzear el **nombre** del parámetro y detectar cuáles cambian la respuesta.

```shell-session
$ ffuf -u "http://IP:PORT/page?FUZZ=test" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -fs <tamaño_baseline>
```

Herramientas dedicadas, más potentes que el `ffuf` a pelo:

- `arjun`: descubre parámetros GET/POST/JSON probando en lotes y comparando respuestas — el estándar.
- `x8`: muy rápido, detecta parámetros que alteran la respuesta de forma sutil.
- `param-miner` (extensión de Burp): encuentra parámetros y cabeceras ocultas, base de hallazgos como *web cache poisoning*.

Un parámetro oculto que reactive un modo *debug*, permita *mass assignment* (`?role=admin`) o sirva de punto de inyección es un hallazgo de alto impacto.

> [!info]+ Cuerpos JSON
> Las APIs modernas no usan `x-www-form-urlencoded`, sino JSON. Para fuzzear esos parámetros, cambia el `Content-Type` y mete `FUZZ` en el JSON:
> ```shell-session
> $ ffuf -u http://IP:PORT/api -X POST -H "Content-Type: application/json" -d '{"FUZZ":"test"}' -w params.txt
> ```
> Enlaza con el [[23 - APIs web e identificación de endpoints|fuzzing de APIs]].

Hemos fuzzeado rutas y parámetros. Queda fuzzear el propio **host**: descubrir vhosts y subdominios forzando la cabecera `Host`. Eso es [[20 - Fuzzing de vhosts y subdominios]].
