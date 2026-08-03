---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Descripción: "Aun habiendo resuelto los caracteres, la petición puede seguir bloqueada: hay un filtro distinto que inspecciona el nombre del comando"
Fecha de actualización: 2026-06-13
Nota previa: "[[05 - Bypass de caracteres en blacklist]]"
Nota siguiente: "[[07 - Ofuscación avanzada de comandos]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Aun habiendo resuelto los caracteres, la petición puede seguir bloqueada: hay un filtro distinto que inspecciona el **nombre del comando**. Una blacklist de comandos es una lista de palabras (`whoami`, `cat`, `nc`, `bash`…), y la clave para evadirla es entender cómo compara: <mark style="background: #ADCCFFA6;">busca una coincidencia textual exacta</mark>. Si la shell ejecuta `whoami` pero el filtro no "ve" esa cadena literal, pasamos.

# Cómo compara el filtro

Un filtro de comandos típico en `PHP` recorre la entrada buscando cada palabra prohibida:

```php
$blacklist = ['whoami', 'cat', ...SNIP...];
foreach ($blacklist as $word) {
    if (strpos($_POST['ip'], $word) !== false) {
        echo "Invalid input";
    }
}
```

`strpos` busca la subcadena exacta `whoami`. <mark style="background: #8000E1A6;">Si rompemos esa secuencia de caracteres —sin cambiar lo que la shell acaba ejecutando— el `strpos` no encuentra nada y el comando corre igual</mark>. Todas las técnicas siguientes explotan la misma idea: insertar caracteres que la shell descarta durante el *parsing*, antes de resolver el nombre del binario.

# Caracteres que la shell ignora

## Comillas (Linux y Windows)

Lo más simple y portable: intercalar comillas simples o dobles entre los caracteres del comando. `bash` y `PowerShell` las eliminan al procesar la línea (*quote removal*) y ejecutan el comando intacto:

```shell-session
$ w'h'o'am'i
21y4d

$ w"h"o"am"i
21y4d
```

> [!warning]+ Dos reglas con las comillas
> <mark style="background: #FFB8EBA6;">No se pueden mezclar tipos</mark> (`w'h"o'ami` rompe) y <mark style="background: #FFB8EBA6;">el número de comillas debe ser par</mark> —cada apertura necesita su cierre—. Si el payload falla, cuenta las comillas antes de descartar la técnica.

## Backslash y `$@` (solo Linux)

`bash` también ignora la contrabarra `\` y el parámetro posicional `$@` insertados dentro de una palabra. A diferencia de las comillas, aquí <mark style="background: #FFB8EBA6;">el número no tiene por qué ser par</mark>: puede ir uno solo:

```bash
who$@ami
w\ho\am\i
```

## Caret `^` (solo Windows)

En `cmd.exe`, el caret es el carácter de escape y se ignora dentro de una palabra:

```cmd-session
C:\htb> who^ami
21y4d
```

# Por qué funciona (y por qué es robusto)

Merece entenderlo para no aplicarlo de memoria. `bash` procesa cada línea en una secuencia fija de fases: expansión de llaves, de tilde, de parámetros y variables, sustitución de comandos, expansión aritmética, *word splitting* y, casi al final, *quote removal* —la eliminación de las comillas y backslashes que hayan sobrevivido—. <mark style="background: #8000E1A6;">El nombre del comando se resuelve después de todo eso</mark>, sobre una cadena ya limpia de comillas. El filtro, en cambio, inspecciona la cadena **cruda** tal como entró por HTTP, antes de cualquier fase. Atacante y filtro miran representaciones distintas del mismo comando, y esa brecha entre lo que el filtro ve y lo que la shell ejecuta es justo lo que explotamos —y la razón de que la [[07 - Ofuscación avanzada de comandos|codificación de la nota siguiente]] sea tan efectiva: el texto que viaja no se parece en nada al comando final—. Es el mismo principio que sostiene la [[07 - Ofuscación avanzada de comandos|ofuscación avanzada]]: separar lo que el filtro ve de lo que la shell ejecuta.

# Más allá de HTB: dos técnicas que conviene dominar

## Concatenación con variables

Trocear el comando en variables de shell y reensamblarlo. El filtro nunca ve la palabra completa:

```bash
a=who;b=ami;$a$b      # ejecuta whoami
```

## Wildcards / globbing

<mark style="background: #FF5582A6;">Se puede ejecutar un binario sin teclear su nombre</mark>, dejando que el *globbing* lo resuelva por su ruta. Útil cuando el propio nombre del binario está filtrado:

```bash
/???/c?t /etc/passwd      # /bin/cat /etc/passwd
/usr/bin/wh*              # ejecuta whoami si es el único match
```

Los comodines `?` (un carácter) y `*` (varios) hacen que la shell expanda la ruta al binario real, evitando por completo su nombre en la blacklist. Es una de las técnicas más potentes y menos catalogadas.

| Técnica | Ejemplo | Plataforma | Nº par |
| - | - | - | - |
| Comillas | `w'h'o'am'i` | Linux + Windows | Sí |
| Backslash / `$@` | `w\ho\am\i`, `who$@ami` | Linux | No |
| Caret | `who^ami` | Windows | No |
| Variables | `a=who;b=ami;$a$b` | Linux | — |
| Wildcards | `/???/c?t /etc/passwd` | Linux | — |

# Realidad frente a un WAF

> [!warning]+ Lo más detectado del módulo
> Las comillas y backslashes intercalados son de los patrones que **mejor** detecta un WAF moderno —ven `w'h'o'am'i` y saltan—. Contra una blacklist casera de aplicación siguen funcionando de maravilla; contra `Cloudflare` o el `OWASP CRS`, recurre a wildcards, concatenación de variables o directamente a la [[07 - Ofuscación avanzada de comandos|ofuscación con codificación]] de la siguiente nota, que no deja una firma reconocible.

> [!info]+ Fuentes
> - [PayloadsAllTheThings — Bypass blacklisted commands](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md#bypass-blacklisted-commands)
> - [GTFOBins](https://gtfobins.github.io/) — binarios alternativos para la misma acción cuando el habitual está vetado.

Estas inserciones cambian el aspecto del comando, pero un WAF las reconoce. El siguiente paso es la ofuscación que transforma el comando hasta hacerlo irreconocible: [[07 - Ofuscación avanzada de comandos]].
