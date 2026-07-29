---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Descripción: "Tras el espacio, los caracteres que más se filtran son la barra / y la contrabarra \ —imprescindibles para rutas en Linux y Windows— y los propios operadores de inyección como ;"
Fecha de actualización: 2026-06-13
Nota previa: "[[04 - Bypass de filtros de espacios]]"
Nota siguiente: "[[06 - Bypass de comandos en blacklist]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Tras el espacio, los caracteres que más se filtran son la barra `/` y la contrabarra `\` —imprescindibles para rutas en Linux y Windows— y los propios operadores de inyección como `;`. La técnica general es la misma para todos: <mark style="background: #ADCCFFA6;">producir el carácter que necesitamos sin teclearlo</mark>, dejando que la shell lo genere por nosotros. Hay dos familias fiables: extraerlo de una variable de entorno, o desplazarlo en la tabla ASCII.

# Linux: substring de variables de entorno

A diferencia de `${IFS}` —que se expande directamente a un espacio—, no existe una variable cuyo valor sea solo `/` o `;`. Pero esos caracteres **aparecen dentro** de variables comunes, y `bash` permite recortar una variable a un único carácter con la sintaxis `${variable:offset:length}`.

El `$PATH` casi siempre empieza por `/`:

```shell-session
$ echo ${PATH}
/usr/local/bin:/usr/bin:/bin:/usr/games

$ echo ${PATH:0:1}
/
```

`${PATH:0:1}` toma desde la posición `0` un solo carácter → `/`. La barra ya es nuestra sin haberla escrito. El mismo recorte sobre otras variables produce otros caracteres; el punto y coma, por ejemplo, vive dentro de `$LS_COLORS`:

```shell-session
$ echo ${LS_COLORS:10:1}
;
```

> [!important]+ En el payload va sin `echo`
> El `echo` de los ejemplos solo sirve para **ver** el carácter en la terminal. <mark style="background: #FF5582A6;">Dentro del payload se usa la expansión a secas</mark>: la shell la sustituye antes de ejecutar el comando. Así, para inyectar un `;` y un espacio sin teclear ninguno de los dos:
> ```text
> 127.0.0.1${LS_COLORS:10:1}${IFS}
> ```

Para cazar qué variable contiene el carácter que te falta, vuelca el entorno y búscalo:

```shell-session
$ printenv          # o 'env' — lista todas las variables y sus valores
```

Localiza tu carácter en algún valor, cuenta su posición, y recórtalo con `${VAR:pos:1}`. `$HOME` y `$PWD` también empiezan por `/` y sirven igual que `$PATH`.

## Generar caracteres con `printf`

Una alternativa que HTB no menciona y conviene tener: `printf` interpreta secuencias octales, lo que produce **cualquier** byte sin teclearlo. `/` es `057` en octal, `;` es `073`:

```shell-session
$ echo $(printf '\57')
/
```

Es útil cuando ni las variables ni el shifting encajan, porque cubre todo el rango ASCII de forma sistemática.

# Windows: CMD y PowerShell

El mismo concepto funciona en Windows con su propia sintaxis de substring.

En `cmd.exe`, se recorta una variable indicando posición de inicio y un final negativo (longitud a descartar desde el final):

```cmd-session
C:\htb> echo %HOMEPATH:~6,-11%
\
```

En `PowerShell`, una cadena es un array de caracteres, así que basta el índice —sin necesidad de inicio y fin:

```powershell-session
PS C:\htb> $env:HOMEPATH[0]
\
```

`Get-ChildItem Env:` (o su alias `gci env:`) lista todas las variables de entorno para localizar la que contiene el carácter buscado.

# Character shifting: desplazar en ASCII

Cuando el carácter no aparece cómodamente en ninguna variable, se puede **generar desplazándolo** desde su vecino en la tabla ASCII. `tr` traduce un rango de caracteres a otro desplazado una posición. <mark style="background: #8000E1A6;">Basta encontrar el carácter justo anterior al que queremos</mark> (con `man ascii`) y pasarlo:

```shell-session
$ man ascii     # \ está en 92; el anterior, [ , en 91
$ echo $(tr '!-}' '"-~'<<<[)
\
```

`tr '!-}' '"-~'` mapea cada carácter del rango `!`–`}` al siguiente, así que `[` (91) sale como `\` (92). En Windows se logra lo mismo con `PowerShell`, aunque las construcciones son más largas.

# Vivir de la tierra: solo lo que ofrece el sistema

Todas estas técnicas comparten una virtud que las hace valiosas más allá de este módulo: <mark style="background: #FFB86CA6;">no suben ni un solo byte al objetivo</mark>. Generan los caracteres prohibidos a partir de lo que ya existe —variables de entorno, `printf`, `tr`—, sin descargar herramientas ni escribir ficheros. Es el principio *Living off the Land* (LOTL): operar exclusivamente con los binarios y recursos nativos del sistema. Para nosotros en command injection eso tiene dos ventajas concretas: el bypass funciona aunque el objetivo no tenga salida a internet ni permisos de escritura, y deja <mark style="background: #FF5582A6;">muchos menos artefactos</mark> que un EDR pueda correlacionar. Cuanto más se apoye el payload en primitivas del propio shell, más se confunde con actividad legítima.

# Realidad frente a un WAF

| Técnica | Linux | Windows |
| - | - | - |
| Substring de variable | `${PATH:0:1}` → `/` | `%HOMEPATH:~6,-11%` / `$env:HOMEPATH[0]` |
| `printf` octal | `$(printf '\57')` → `/` | — |
| Character shifting | `$(tr '!-}' '"-~'<<<[)` → `\` | (más verboso) |

> [!warning]+ Estas firmas también son conocidas
> `${PATH:0:1}` y `${LS_COLORS:10:1}` aparecen en cualquier hoja de trucos, así que un WAF actualizado puede detectarlas. <mark style="background: #FFB86CA6;">Su fuerza real está contra blacklists caseras</mark>, que rara vez contemplan la expansión de variables. Contra un WAF, combínalas con la [[07 - Ofuscación avanzada de comandos|ofuscación]] para romper la firma estática, o busca el carácter por una vía menos catalogada (`printf`, shifting).

> [!info]+ Fuentes
> - [PayloadsAllTheThings — Bypass blacklisted characters](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md)
> - `man ascii` y `man bash` (sección *Parameter Expansion*) — la referencia local, siempre disponible en el objetivo.

Resueltos los caracteres, queda el último filtro frecuente: el que bloquea el **nombre del comando** (`whoami`, `cat`, `nc`). [[06 - Bypass de comandos en blacklist]].
