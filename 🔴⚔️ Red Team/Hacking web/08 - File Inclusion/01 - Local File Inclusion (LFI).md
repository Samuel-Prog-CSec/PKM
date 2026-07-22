---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Fecha de actualización: 2026-06-21
Nota previa: "[[00 - Introducción a File Inclusion]]"
Nota siguiente: "[[02 - Bypasses básicos - traversal, null byte y encoding]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

La explotación más directa de una File Inclusion es leer ficheros locales del servidor. <mark style="background: #ADCCFFA6;">El objetivo es desviar el parámetro de inclusión hacia un fichero distinto del previsto</mark>. Cómo de fácil sea depende de cómo el código construye la ruta: si usa nuestra entrada tal cual, si le antepone un directorio, un prefijo, o le añade una extensión. Cada caso tiene su técnica.

# LFI básica con ruta absoluta

El caso ideal: el parámetro va directo al `include()`.

```php
include($_GET['language']);
```

Aquí basta con pedir el fichero por su **ruta absoluta**. Dos ficheros legibles casi siempre presentes confirman la vulnerabilidad: `/etc/passwd` en Linux y `C:\Windows\win.ini` en Windows.

```
/index.php?language=/etc/passwd
```

Si la respuesta muestra el contenido de `passwd` (la lista de usuarios del sistema), la LFI está confirmada.

> [!tip]+ Ficheros que merece la pena leer
> - **Linux**: `/etc/passwd`, `/etc/hosts`, `/etc/os-release`, los ficheros de config de la app (`config.php`, `.env`), claves SSH (`/home/<user>/.ssh/id_rsa`), `/proc/self/environ` y `/proc/self/cmdline` (variables y línea de comandos del proceso).
> - **Windows**: `C:\Windows\win.ini`, `C:\Windows\System32\drivers\etc\hosts`, `web.config`, ficheros de IIS.
> - **Contenedores/cloud**: secrets montados (`/run/secrets/`), `/proc/self/environ` (suele filtrar credenciales y tokens inyectados por variables de entorno).

# Path traversal (con directorio antepuesto)

Lo habitual es que el código añada un directorio antes de nuestra entrada:

```php
include("./languages/" . $_GET['language']);
```

Pedir `/etc/passwd` produce `./languages//etc/passwd`, que no existe. <mark style="background: #8000E1A6;">La solución es subir directorios con `../` (path traversal) hasta la raíz y desde ahí dar la ruta absoluta</mark>:

```
/index.php?language=../../../../etc/passwd
```

Cada `../` sube un nivel. Como `../` desde la raíz (`/`) sigue siendo la raíz, **sobra con poner muchos**: aunque no sepas la profundidad, `../` repetido de más no rompe nada. En un informe o exploit, eso sí, conviene calcular el mínimo (con `/var/www/html/` son 3 niveles → `../../../`).

> [!info]+ Traversal a nivel de Nginx: el *off-by-slash* del `alias`
> Una traversal puede vivir en la **config del servidor**, no en el código. Un `location /files { alias /var/www/uploads/; }` sin barra final permite `GET /files../etc/passwd`: Nginx concatena `alias` + resto sin normalizar y se sale del directorio. Es *arbitrary file read* (solo lectura, sin ejecución), pero muy común —pruébalo siempre que veas rutas servidas por `alias`—.

# Cuando hay un prefijo

A veces nuestra entrada se concatena tras un prefijo de nombre:

```php
include("lang_" . $_GET['language']);
```

Un `../../../etc/passwd` daría `lang_../../../etc/passwd` (inválido). El truco: <mark style="background: #FFB8EBA6;">anteponer un `/` para que el prefijo cuente como directorio</mark>:

```
/index.php?language=/../../../etc/passwd
```

Esto convierte el prefijo en `lang_/`, que se trata como carpeta, y la traversal vuelve a funcionar. (No siempre: si `lang_/` no es un directorio válido, falla; y el prefijo puede romper otras técnicas como wrappers o RFI.)

# Cuando se añade una extensión

El caso más común y restrictivo: el código añade `.php` a nuestra entrada para forzar que solo se incluyan ficheros PHP.

```php
include($_GET['language'] . ".php");
```

Pedir `/etc/passwd` produce `/etc/passwd.php`, que no existe. <mark style="background: #FFB86CA6;">Esta extensión añadida es el filtro que más cuesta superar</mark>: las técnicas para sortearla (null byte, truncación —ya obsoletas— y, sobre todo, leer código fuente con `php://filter`) se tratan en las [[02 - Bypasses básicos - traversal, null byte y encoding|bypasses básicos]] y los [[03 - PHP wrappers I - php filter y disclosure de código|PHP filters]].

# Second-order: la LFI que no ves

Un vector que los desarrolladores suelen pasar por alto. Muchas funciones cargan ficheros del servidor a partir de un valor que **no introducimos directamente**, sino que viene de la base de datos. Ejemplo: descargar el avatar desde `/profile/<username>/avatar.png`.

<mark style="background: #FF5582A6;">Si durante el registro envenenamos nuestro `username` con un payload LFI</mark> (p. ej. `../../../etc/passwd`), cuando otra funcionalidad use ese username almacenado para construir la ruta del avatar, ejecutará nuestra inclusión. Se llama **second-order** porque el payload se guarda en un sitio (registro) y se dispara en otro (descarga de avatar). Los devs protegen la entrada directa (`?page=`) pero confían en los valores de su propia base de datos —ahí está el fallo—. La metodología: localizar una función que cargue un fichero según un valor que controlamos indirectamente, y envenenar ese valor.

> [!warning]+ Errores verbosos solo en el lab
> Los ejemplos muestran mensajes de error de PHP (`include(): failed to open...`) que revelan la ruta exacta. En producción nunca deberían verse. <mark style="background: #FFB8EBA6;">Todos los ataques funcionan también a ciegas</mark>: no dependen de los errores, solo ayudan a entender cómo se construye la ruta.

> [!info]+ Fuentes
> - [PortSwigger — File path traversal](https://portswigger.net/web-security/file-path-traversal) (incluye laboratorios por tipo de filtro)
> - [HackTricks — LFI/RFI](https://book.hacktricks.xyz/pentesting-web/file-inclusion)
> - [PayloadsAllTheThings — File Inclusion](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/File%20Inclusion)

> [!important]+ LFI vía API
> La LFI afecta a APIs igual que a webs. Patrón típico: un endpoint que recibe una ruta/fichero (`/api/download/<file>`) y la pasa a `include`/`fopen`/`readFile` sin canonicalizar. Se descubre con **fuzzing de endpoints** (`ffuf` + `common-api-endpoints`) y se explota con *path traversal* **URL-encodeado** para colarse por los filtros: `/api/download/..%2f..%2f..%2fetc%2fpasswd`. Escala igual con [[04 - PHP wrappers II - RCE y filter chains|filter chains]] y `phar://`. Defensa real: allowlist `id→ruta` + canonicalización contra el directorio base.

Cuando la app filtra los `../` o ciertos caracteres, hay que recurrir a los [[02 - Bypasses básicos - traversal, null byte y encoding|bypasses de filtros]].
