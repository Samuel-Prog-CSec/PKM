---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[03 - Identificación de filtros y defensas]]"
Nota siguiente: "[[05 - Bypass de caracteres en blacklist]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

El espacio es uno de los caracteres más filtrados, y con lógica: un campo que espera una IP, un nombre de host o un número **no debería** contener espacios, así que bloquearlo no rompe la funcionalidad legítima y corta de raíz el `127.0.0.1; whoami` ingenuo. La buena noticia para el atacante es que <mark style="background: #ADCCFFA6;">la shell ofrece media docena de formas de separar argumentos sin teclear un espacio literal</mark>. Esta nota recorre las fiables en Linux y su equivalente en Windows.

# Primero, un operador que sobreviva

Antes del espacio hay que colocar el comando, y para eso necesitamos un operador que el filtro no bloquee. <mark style="background: #FF5582A6;">El salto de línea (`\n`, URL-encoded `%0a`) raramente está en la blacklist</mark>, porque muchos campos legítimos lo necesitan (un `textarea`, una lista de IPs). Y funciona como separador de comandos tanto en Linux como en Windows:

```text
127.0.0.1%0a whoami
```

Si esto pasa el filtro de operadores pero aún devuelve `invalid input`, el problema ya no es el operador sino el **espacio** que va antes de `whoami`. Vamos a eliminarlo.

# Sustitutos del espacio en Linux

## Tabulador (`%09`)

Linux y Windows aceptan un tabulador entre argumentos exactamente igual que un espacio. URL-encoded es `%09`:

```text
127.0.0.1%0a%09whoami
```

## La variable `$IFS`

`IFS` (`Internal Field Separator`) es <mark style="background: #ADCCFFA6;">la variable de entorno que la shell usa para separar palabras; su valor por defecto incluye el espacio y el tabulador</mark>. Sustituir el espacio por `${IFS}` hace que la shell lo expanda a un separador real:

```text
127.0.0.1%0a${IFS}whoami
```

Hay una variante muy útil cuando las llaves `{}` también están filtradas: `$IFS$9`. <mark style="background: #8000E1A6;">`$9` es un parámetro posicional que normalmente está vacío</mark>, y sirve para marcar dónde termina el nombre de la variable `$IFS` sin necesitar llaves ni espacios:

```text
127.0.0.1%0a$IFS$9whoami
```

## Brace expansion (`{cmd,arg}`)

`bash` inserta un espacio automáticamente entre los elementos de una lista entre llaves separados por comas. Es *brace expansion*, y permite escribir un comando con argumentos sin un solo espacio:

```shell-session
$ {ls,-la}
total 0
drwxr-xr-x 1 21y4d 21y4d   0 Jul 13 07:37 .
```

Aplicado al payload:

```text
127.0.0.1%0a{ls,-la}
```

## Redirecciones (`<`)

Otra vía elegante: los operadores de redirección `<` y `<>` también separan tokens, así que `cat</etc/passwd` se ejecuta sin espacios. Útil sobre todo para leer ficheros:

```text
127.0.0.1%0acat</etc/passwd
```

| Técnica | Payload (tras `%0a`) | Notas |
| - | - | - |
| Tabulador | `%09whoami` | Linux y Windows |
| `${IFS}` | `${IFS}whoami` | Necesita `{}` |
| `$IFS$9` | `$IFS$9whoami` | Sin llaves; útil si `{}` filtrado |
| Brace expansion | `{cat,/etc/passwd}` | Mete el espacio entre args |
| Redirección | `cat</etc/passwd` | Solo donde encaja un `<` |

# Por qué la shell permite omitir el espacio

Entender el mecanismo evita probar a ciegas. `bash` procesa la línea en fases, y una de ellas es el *word splitting*: tras expandir variables y sustituciones, la shell **vuelve a trocear** el resultado en palabras usando los caracteres de `IFS` como frontera. Por eso `${IFS}` colocado donde iría un espacio termina generando una separación real —no es un espacio literal en la entrada, sino uno que la shell <mark style="background: #8000E1A6;">fabrica al expandir la variable</mark>—. El tabulador y el salto de línea funcionan por idéntico motivo: ambos forman parte del `IFS` por defecto. El *brace expansion*, en cambio, es anterior al word splitting y produce los espacios él mismo. Conocer este orden permite anticipar qué técnica encaja en cada contexto en lugar de ir a tientas.

> [!important]+ El `+` que se decodifica a espacio
> En un cuerpo `application/x-www-form-urlencoded`, el `+` se decodifica a espacio **en el servidor**. Si el filtro inspecciona la entrada *antes* de esa decodificación, a veces basta enviar un `+` literal donde iría el espacio: el filtro ve un `+` inofensivo y el back-end recibe un espacio. Conviene probarlo siempre que el espacio esté bloqueado.

# En Windows

El espacio también se evade en `cmd.exe` y `PowerShell`. El sustituto clásico es la sub-cadena de una variable de entorno cuyo contenido tenga un espacio, o `%IFS%` no aplica (es de bash). En `PowerShell`, `${env:...}` y el tabulador funcionan; en `cmd`, técnicas como `ping%CommonProgramFiles:~10,-18%127.0.0.1` extraen un espacio del valor de una variable. En la práctica, en Windows es más cómodo recurrir a la [[07 - Ofuscación avanzada de comandos|ofuscación de PowerShell]].

> [!warning]+ Lo que funciona en el lab puede no funcionar tras un WAF
> `${IFS}`, `{ls,-la}` y `$IFS$9` son técnicas **muy conocidas**: el `OWASP CRS` y los WAFs comerciales las detectan con reglas específicas. <mark style="background: #FFB86CA6;">Contra un filtro casero de aplicación (una blacklist en PHP) siguen siendo oro</mark>; contra un WAF moderno actualizado, espera que algunas estén ya cubiertas. La estrategia real es combinarlas con la [[07 - Ofuscación avanzada de comandos|ofuscación avanzada]] de la nota 07, que rompe la firma estática del payload.

> [!info]+ Fuentes
> - [PayloadsAllTheThings — Bypass without space](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Command%20Injection/README.md#filter-bypasses) — colección de referencia de payloads sin espacios.
> - [GTFOBins](https://gtfobins.github.io/) — qué binarios leen ficheros o dan shell, útil para elegir el comando una vez resuelto el espacio.

El espacio era solo el primer carácter filtrado. A continuación, qué hacer cuando bloquean otros caracteres imprescindibles como `/` o `\`: [[05 - Bypass de caracteres en blacklist]].
