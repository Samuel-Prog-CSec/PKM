---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Inclusion
Descripción: "Cuando la app aplica filtros contra la inclusión, los payloads básicos de LFI dejan de funcionar"
Fecha de actualización: 2026-06-21
Nota previa: "[[01 - Local File Inclusion (LFI)]]"
Nota siguiente: "[[03 - PHP wrappers I - php filter y disclosure de código]]"
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Cuando la app aplica filtros contra la inclusión, los payloads básicos de [[01 - Local File Inclusion (LFI)|LFI]] dejan de funcionar. Pero <mark style="background: #FFB8EBA6;">la mayoría de esos filtros están mal implementados</mark> y se sortean con pequeñas variaciones. Esta nota cubre los bypasses de filtros de **ruta**; la restricción más dura —la extensión `.php` añadida— se resuelve de verdad con los [[03 - PHP wrappers I - php filter y disclosure de código|PHP filters]].

# Filtros no recursivos de `../`

El filtro más básico: buscar y borrar `../`.

```php
$language = str_replace('../', '', $_GET['language']);
```

Su fallo es que <mark style="background: #FF5582A6;">se ejecuta una sola vez y no de forma recursiva</mark>. Si construimos el payload de modo que, **tras** borrar los `../`, queden otros `../`, la traversal sobrevive. El clásico `....//`:

```
?language=....//....//....//....//etc/passwd
```

El filtro elimina el `../` del centro de cada `....//` y deja `../`. Variantes equivalentes según el filtro: `..././`, `....\/`, o añadir barras de más `....////`. Es la misma idea de [[03 - Identificación de filtros y defensas|bypass de blacklists no recursivas]] que en command injection.

# Encoding

Si el filtro bloquea caracteres concretos (`.` o `/`), el **URL-encoding** los oculta y, al decodificarse antes de llegar al `include()`, recupera la ruta. `../` se convierte en `%2e%2e%2f`:

```
?language=%2e%2e%2f%2e%2e%2f%2e%2e%2f%65%74%63%2f%70%61%73%73%77%64
```

> [!warning]+ Codifica también los puntos
> Para que funcione hay que codificar **todos** los caracteres, incluidos los `.`. Algunos codificadores online no tocan los puntos (los consideran parte del esquema de URL). Usa el **Decoder de Burp/Caido** y verifica. El **doble encoding** (`%252e%252e%252f`) sortea filtros que decodifican una sola vez antes de validar.

# Rutas aprobadas (regex de directorio)

Algunas apps exigen con un regex que la ruta empiece por un directorio concreto:

```php
if(preg_match('/^\.\/languages\/.+$/', $_GET['language'])) {
    include($_GET['language']);
}
```

Como solo comprueban el **principio**, satisfacemos el prefijo aprobado y desde ahí hacemos traversal:

```
?language=./languages/../../../../etc/passwd
```

Si la app combina este filtro con uno de los anteriores, se encadenan las técnicas: empezar por la ruta aprobada **y** usar `....//` o URL-encoding en el resto.

# La extensión añadida: bypasses obsoletos

Cuando el código añade `.php` (`include($_GET['language'] . ".php")`), <mark style="background: #FFB86CA6;">en PHP moderno no hay forma de quitar esa extensión</mark> y quedamos restringidos a incluir ficheros `.php` —lo cual sigue sirviendo para leer código fuente, ver [[03 - PHP wrappers I - php filter y disclosure de código|PHP filters]]—. Dos técnicas clásicas la sorteaban, pero **solo funcionan en PHP antiguo (previo a 5.3.4)**; las documentamos porque aún hay servidores legacy:

- **Path truncation**: en PHP antiguo, las cadenas se truncaban a 4096 caracteres y se eliminaban `/.` finales y barras múltiples. Anteponiendo un directorio inexistente y rellenando con `/./././...` hasta superar los 4096, la `.php` final quedaba truncada:

```shell-session
$ echo -n "noexiste/../../../etc/passwd/" && for i in {1..2048}; do echo -n "./"; done
```

- **Null byte (`%00`)**: en PHP **< 5.3.4** (`CVE-2006-7243`), un null byte terminaba la cadena. `/etc/passwd%00` producía `/etc/passwd%00.php`, pero el intérprete cortaba en el nulo y abría `/etc/passwd`. <mark style="background: #8000E1A6;">Es el mismo principio de truncado por null byte que en los [[04 - Bypass de whitelist y doble extensión|file uploads]]</mark>: depende de que una capa en C interprete el `\0` como fin de cadena.

> [!important]+ Qué usar hoy
> Path truncation y null byte están **parcheados** desde PHP 5.3.4 (el null byte por `CVE-2006-7243`; el path truncation en la misma rama 5.3.x). Contra una extensión añadida en un servidor moderno, el camino real no es quitar la `.php` sino **leer el código fuente** con `php://filter` (siguiente nota) o lograr **RCE** con [[04 - PHP wrappers II - RCE y filter chains|filter chains]]. Reserva los bypasses obsoletos para objetivos genuinamente antiguos.

> [!info]+ Fuentes
> - [PortSwigger — File path traversal (filter bypass labs)](https://portswigger.net/web-security/file-path-traversal)
> - [HackTricks — Path Traversal](https://book.hacktricks.xyz/pentesting-web/file-inclusion#lfi-rfi-bypasses)
> - [PayloadsAllTheThings — Directory Traversal](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Directory%20Traversal)

Superados los filtros de ruta, los **PHP wrappers** abren la puerta a leer código fuente y, después, a ejecutar comandos: [[03 - PHP wrappers I - php filter y disclosure de código]].
