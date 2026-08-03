---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Descripción: "Las aplicaciones web tienen directorios y archivos que no se enlazan en ninguna parte del interfaz"
Fecha de actualización: 2026-06-02
Nota previa: "[[16 - Herramientas de fuzzing]]"
Nota siguiente: "[[18 - Fuzzing recursivo]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Las aplicaciones web tienen directorios y archivos que no se enlazan en ninguna parte del interfaz. <mark style="background: #ADCCFFA6;">El fuzzing de directorios y archivos descubre esos recursos ocultos probando nombres candidatos de una `wordlist` y analizando la respuesta del servidor</mark>. Es la técnica de descubrimiento de contenido más usada.

# Qué se esconde ahí

- **Datos sensibles**: backups, ficheros de configuración o logs con credenciales.
- **Contenido obsoleto**: versiones viejas de scripts vulnerables a exploits conocidos.
- **Recursos de desarrollo**: entornos de test, *staging* o paneles de administración.
- **Funcionalidad oculta**: features o endpoints sin documentar que exponen comportamientos inesperados.

<mark style="background: #FFB86CA6;">Estas zonas ocultas suelen carecer de las medidas de seguridad de la parte pública</mark> — son objetivos primarios. Y aunque un hallazgo no sea explotable de inmediato, alimenta el resto del pentest: revela el stack, rutas internas o datos para fases posteriores.

# Directory fuzzing con `ffuf`

`ffuf` recorre la `wordlist`, sustituye el marcador [[16 - Herramientas de fuzzing|`FUZZ`]] en la URL por cada entrada y analiza la respuesta:

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -u http://IP:PORT/FUZZ -ic

w2ksvrus                [Status: 301, Size: 0, Words: 1, Lines: 1, Duration: 0ms]
:: Progress: [220559/220559] :: 100000 req/sec :: Duration: [0:00:03]
```

- `-w`: ruta de la `wordlist`.
- `-u`: URL base; `FUZZ` marca dónde se inserta cada palabra.

Aquí `ffuf` descubrió el directorio `w2ksvrus` (código `301`, *Moved Permanently*) — un punto de entrada para seguir investigando.

> [!important]+ Interpretar los códigos de estado
> El código de respuesta es la primera señal de qué encontraste. No descartes los errores:
>
> | Código | Significado | Para ti |
> | - | - | - |
> | `200` | OK | El recurso existe y es accesible |
> | `301`/`302` | Redirección | Suele indicar un directorio; sigue el `Location` |
> | `403` | Forbidden | <mark style="background: #FF5582A6;">El recurso **existe** pero está bloqueado — muy interesante</mark>: hay algo que ocultan |
> | `401` | Unauthorized | Existe y pide autenticación |
> | `405` | Method Not Allowed | Existe, pero ese método HTTP no se permite — prueba otros verbos |
> | `500` | Error interno | El recurso rompe algo — posible bug |
>
> Un `403` o un `401` confirman que la ruta existe aunque no puedas verla: candidatos a *bypass* (`/admin/` vs `/admin/.`, cabeceras `X-Original-URL`, etc.).

# File fuzzing

El fuzzing de archivos busca ficheros concretos, dentro de directorios o en la raíz. La clave es el flag `-e`, que prueba cada palabra con varias extensiones:

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -u http://IP:PORT/w2ksvrus/FUZZ -e .php,.html,.txt,.bak,.js -v

[Status: 200, Size: 111] http://IP:PORT/w2ksvrus/dblclk.html
[Status: 200, Size: 112] http://IP:PORT/w2ksvrus/index.html
```

Extensiones que más interesan según el stack: `.php`, `.asp`/`.aspx`, `.jsp` (código servidor), `.bak`, `.old`, `.swp`, `.txt`, `.zip`, `.tar.gz` (backups), `.js` (lógica front), `.json`/`.xml`/`.config` (configuración).

> [!warning]+ Los backups son oro
> <mark style="background: #FF5582A6;">Encontrar `config.php.bak`, `.env`, `index.php~` o `database.sql` puede entregar credenciales, claves de API o código fuente directamente</mark>. Prueba siempre variantes de backup sobre los archivos que ya conoces: si existe `config.php`, busca `config.php.bak`, `config.php.old`, `config.php~`, `.config.php.swp`. El `.git/` expuesto es otro clásico: si responde, puedes reconstruir todo el repositorio.

# Rutas conocidas de alto valor

No todo es fuerza bruta: hay rutas concretas que casi siempre merece comprobar directamente, porque su solo hallazgo entrega código o estructura sin adivinar nada.

- <mark style="background: #FF5582A6;">**Sourcemaps `.js.map`**</mark>: si un bundle JS minificado conserva su *source map*, recuperas el **código fuente original** —nombres de variables, comentarios, endpoints internos y a veces secretos *hardcodeados*—. Prueba `main.js.map`/`app.js.map`, o ábrelos desde las DevTools del navegador. Para reconstruir el árbol completo: `unwebpack-sourcemap` o `sourcemapper`.
- **`.git/` expuesto** → con `git-dumper` reconstruyes el repositorio entero (código, historial y secretos en *commits* viejos). `.svn/` y `.hg/` tienen equivalentes.
- **`.DS_Store`** (servidores que sirven ficheros de macOS): lista los nombres del directorio, mapeando su estructura <mark style="background: #8000E1A6;">sin fuerza bruta</mark> (`ds_store_exp`).
- **`.well-known/`**: `security.txt` (canal de contacto del programa), `change-password`, `openid-configuration` (revela endpoints OAuth/OIDC).
- **CI/CD y entorno**: `.env`, `docker-compose.yml`, `.gitlab-ci.yml`, `.github/workflows/` — credenciales y arquitectura.

Estas rutas se verifican mejor con plantillas que adivinando: la categoría `exposures/` de [[26 - Escaneo dirigido con nuclei|nuclei]] las cubre de forma sistemática.

# Flags útiles

```shell-session
-recursion -recursion-depth 2   # baja automáticamente a los directorios encontrados (nota 18)
-mc 200,301,403  /  -fc 404     # match/filter por código de estado (nota 21)
-t 40                           # hilos (velocidad)
-p 0.1                          # retardo entre peticiones (evasión de rate-limit/WAF)
-o out.json -of json            # exportar resultados
-ic                             # ignora comentarios de la wordlist
-c -v                           # color y salida verbosa (muestra la URL completa)
```

> [!warning]+ Ruido, rate-limiting y WAF
> El fuzzing de contenido genera **miles** de peticiones por segundo. Contra un objetivo real eso dispara WAFs y *rate-limiters*, que te banearán la IP o empezarán a devolver `429`/`403` a todo. Baja los hilos (`-t`), añade retardo (`-p`), y recuerda el [[09 - Fingerprinting web|fingerprinting de WAF]] previo. Un fuzzing a 100k req/s solo vale en un lab.

Cuando `ffuf` encuentra un directorio, casi siempre quieres fuzzearlo también por dentro. Hacerlo a mano es tedioso; el fuzzing **recursivo** lo automatiza: [[18 - Fuzzing recursivo]].
