---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[01 - Detección de Command Injection]]"
Nota siguiente: "[[03 - Identificación de filtros y defensas]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Confirmada la inyección, el **operador** que elijamos determina cómo se encadena nuestro comando con el original y qué salida recibimos. No es un detalle menor: el operador correcto convierte un payload que rompe la aplicación en uno que devuelve un resultado limpio. <mark style="background: #ADCCFFA6;">Un operador de inyección es el metacarácter del shell que separa o combina comandos</mark>, y la shell lo interpreta antes de ejecutar.

# La tabla de operadores

Estos son los operadores que sirven para inyectar un comando adicional sobre el previsto. La columna *URL-encoded* es la que de verdad importa en web: casi siempre hay que enviarlos codificados.

| Operador | Carácter | URL-encoded | Qué ejecuta |
| - | - | - | - |
| Punto y coma | `;` | `%3b` | Ambos comandos |
| Nueva línea | `\n` | `%0a` | Ambos |
| Background | `&` | `%26` | Ambos (suele mostrar primero la 2ª salida) |
| Pipe | `\|` | `%7c` | Ambos (solo se ve la salida del 2º) |
| AND | `&&` | `%26%26` | Ambos (el 2º solo si el 1º tiene éxito) |
| OR | `\|\|` | `%7c%7c` | El 2º solo si el 1º falla |
| Sub-shell | `` `` `` | `%60%60` | Solo Linux/bash (en PowerShell el backtick es escape, no abre sub-shell) |
| Sub-shell | `$()` | `%24%28%29` | Linux/bash **y** Windows/PowerShell (subexpression operator; no en `cmd.exe`) |

La forma de uso es siempre: *entrada esperada* (p. ej. una IP) + *operador* + *nuestro comando*. Sobre el `Host Checker`, el payload `127.0.0.1; whoami` produce en el back-end:

```bash
ping -c 1 127.0.0.1; whoami
```

<mark style="background: #FFB8EBA6;">Una buena costumbre antes de inyectar: probar el comando completo en una shell local</mark> para confirmar que la sintaxis es válida y que no rompe por una razón ajena a la aplicación.

> [!info]+ Casi independientes del stack
> Para command injection básica, estos operadores funcionan **sin importar** el lenguaje, framework o sistema (`PHP`+Linux, `.NET`+Windows, `NodeJS`+macOS…), porque actúan a nivel de la shell que ejecuta el comando, no de la aplicación. La excepción notable: el punto y coma `;` **no** funciona en `cmd.exe` de Windows, aunque **sí** en `PowerShell`.

# Por qué `&&` y `||` se comportan distinto: exit codes

El comportamiento condicional de `&&` y `||` se entiende con los códigos de salida de la shell. Todo comando devuelve un *exit code*: <mark style="background: #8000E1A6;">`0` significa éxito y cualquier valor distinto de cero significa fallo</mark>.

- `&&` (AND) ejecuta el segundo comando **solo si el primero devolvió `0`**. `ping -c 1 127.0.0.1 && whoami` corre `whoami` porque el ping tuvo éxito.
- `||` (OR) ejecuta el segundo comando **solo si el primero falló** (exit code distinto de `0`).

# El operador OR para payloads limpios

`||` tiene un uso táctico que conviene interiorizar. Si en lugar de anteponer una IP válida **rompemos a propósito** el comando original, el `ping` falla y solo se ejecuta nuestro comando:

```shell-session
$ ping -c 1 || whoami
ping: usage error: Destination address required
21y4d
```

Sin IP, `ping -c 1` da error → exit code ≠ 0 → `whoami` se ejecuta. En la aplicación, el payload `|| whoami` (con el campo IP vacío) devuelve <mark style="background: #FF5582A6;">solo la salida de nuestro comando, sin el ruido del `ping`</mark> — un resultado mucho más limpio para leer y para automatizar la extracción. Es el primer ejemplo de algo recurrente: elegir el operador no por costumbre, sino por el resultado que produce.

# La lección que de verdad importa: front-end ≠ back-end

Al probar `127.0.0.1; whoami` en el `Host Checker`, la aplicación lo rechaza con un *"Match the requested format"*: solo acepta formato IP. Pero al abrir las DevTools (pestaña *Network*) y pulsar *Check*, <mark style="background: #FFB86CA6;">no se dispara ninguna petición</mark>: la validación ocurre **en el front-end**, en JavaScript, antes de salir del navegador.

> [!warning]+ La validación de cliente no es una defensa
> Es habitual que los desarrolladores validen solo en el front-end —por reparto de equipos, por confiar en el navegador, por pereza— y dejen el back-end sin sanear. <mark style="background: #FFB86CA6;">La validación de cliente solo mejora la UX; no protege nada</mark>, porque se salta enviando la petición HTTP directamente al servidor con un proxy. Si en un pentest ves un rechazo "instantáneo" sin tráfico de red, sospecha de validación únicamente cliente y ve directo al proxy.

## Saltar la validación con un proxy

El procedimiento estándar: interceptar con [[02 - Interceptación de peticiones|Burp o Caido]] una petición legítima (con una IP válida), enviarla a *Repeater* (`CTRL+R`), sustituir el valor por el payload `127.0.0.1; whoami`, **URL-encodearlo** (`CTRL+U` en Burp) y enviarla. La respuesta ahora trae la salida de `ping` **y** de `whoami`: inyección confirmada en el back-end, saltándonos por completo el filtro de cliente.

> [!important]+ URL-encoding no es opcional
> Caracteres como `&`, `;` o `+` tienen significado propio dentro de una query string o un cuerpo `x-www-form-urlencoded`. Si no los codificas, el payload se parte o se interpreta mal **antes** de llegar a la aplicación. Codifica siempre los metacaracteres del operador (`;`→`%3b`, `&&`→`%26%26`); el espacio a `+` o `%20`.

# Operadores en otras inyecciones

La idea de "metacarácter que rompe el contexto" es transversal a toda la familia de inyecciones, y por eso el mismo reflejo sirve para [[00 - Introducción a SQL Injection|SQLi]], [[00 - Introducción a XPath Injection|XPath Injection]] o `LDAP`. Una referencia rápida de qué caracteres prueban cada clase:

| Tipo de inyección | Operadores típicos |
| - | - |
| OS Command Injection | `;` `&` `\|` `&&` `\|\|` |
| [[00 - Introducción a SQL Injection\|SQL Injection]] | `'` `;` `--` `/* */` |
| [[00 - Introducción a XPath Injection\|XPath Injection]] | `'` `or` `and` `not` `substring` |
| LDAP Injection | `*` `(` `)` `&` `\|` |
| Code Injection | `'` `;` `$()` `${}` `#{}` `%{}` |
| Header Injection (`CRLF`) | `\n` `\r\n` `%0d` `%0a` `%09` |

La tabla es orientativa e incompleta —el entorno concreto manda—, pero entrena el ojo: ante un parámetro sospechoso, sabes qué carácter probar según dónde creas que termina la entrada.

> [!info]+ Más allá de la inyección directa
> Este módulo trata **inyección directa** (nuestra entrada va directa al comando y vemos la salida). Para inyecciones **indirectas** y totalmente **ciegas** —donde la entrada llega al comando por un camino lateral y sin output—, el módulo HTB de referencia es `Whitebox Pentesting 101: Command Injection`, que las aborda desde código. La metodología de confirmación ciega está en la [[01 - Detección de Command Injection|nota de detección]].

> [!info]+ Fuentes
> - [PayloadsAllTheThings — Command Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Command%20Injection)
> - [PortSwigger — OS command injection](https://portswigger.net/web-security/os-command-injection)

Cuando la aplicación **sí** filtra en el back-end, el siguiente paso es averiguar qué está bloqueando para poder evadirlo: [[03 - Identificación de filtros y defensas]].
