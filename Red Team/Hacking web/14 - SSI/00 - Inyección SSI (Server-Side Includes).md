---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSI
  - Tipo/Introduccion
Descripción: "Los Server-Side Includes (SSI) son una tecnología que generan contenido dinámico en páginas HTML mediante directivas que el servidor interpreta antes de servir la página"
Fecha de actualización: 2026-06-22
Nota previa: ""
Nota siguiente: "[[01 - Prevención de SSI]]"
Area: "[[SSI.base|SSI]]"
---
---

Los `Server-Side Includes` (SSI) son una tecnología que generan contenido dinámico en páginas HTML mediante **directivas** que el servidor interpreta antes de servir la página. La soportan servidores como [Apache](https://httpd.apache.org/docs/current/howto/ssi.html) e [IIS](https://learn.microsoft.com/en-us/iis/configuration/system.webserver/serversideinclude). <mark style="background: #ADCCFFA6;">La `SSI Injection` ocurre cuando un atacante inyecta directivas SSI en un fichero que el servidor procesa</mark> — y, como una de esas directivas ejecuta comandos, suele acabar en RCE. Es un sub-tema dentro de los [[00 - Introducción a los ataques server-side|ataques server-side]].

# Las directivas SSI

Sintaxis: `<!--#nombre param="valor" -->`. Embebidas en el HTML, el servidor las resuelve al servir el fichero. Las relevantes:

| Directiva | Qué hace | Ejemplo |
| - | - | - |
| `printenv` | Imprime las variables de entorno | `<!--#printenv -->` |
| `config` | Cambia config SSI (p. ej. el mensaje de error) | `<!--#config errmsg="Error!" -->` |
| `echo` | Imprime una variable (`DOCUMENT_NAME`, `DATE_LOCAL`…) | `<!--#echo var="DOCUMENT_NAME" -->` |
| `exec` | <mark style="background: #FFB86CA6;">`cmd` ejecuta un comando del sistema</mark> (RCE); `cgi` ejecuta un script CGI | `<!--#exec cmd="whoami" -->` |
| `include` | Incluye un fichero del webroot | `<!--#include virtual="index.html" -->` |

`exec` es la que da RCE; `include` permite leer ficheros del webroot (parecido a una [[00 - Introducción a File Inclusion|LFI]] acotada).

# Cómo surge la inyección

El servidor solo procesa SSI en ficheros que su configuración marca como "SSI-enabled". <mark style="background: #FF5582A6;">La inyección requiere que nuestro input acabe en uno de esos ficheros</mark>. Dos vectores típicos:

- **File upload** que deja subir un fichero con directivas al webroot (un `.shtml` con `<!--#exec ...-->`) — se combina con el módulo [[00 - Introducción a los File Upload Attacks|File Upload]].
- **La app escribe input del usuario en un fichero** del webroot que luego se sirve y procesa (p. ej. guarda tu "nombre" en una página `.shtml`).

# Detección y explotación

La extensión da una **pista** —`.shtml`, `.shtm`, `.stm`—, pero no es concluyente: el servidor puede habilitar SSI en cualquier extensión. La confirmación es inyectar una directiva inocua y ver si se ejecuta. Con un campo reflejado (p. ej. un nombre que aparece en `/page.shtml`), enviamos:

```ssi
<!--#printenv -->
```

Si la respuesta vuelca las variables de entorno, la inyección está confirmada. De ahí a RCE, la directiva `exec`:

```ssi
<!--#exec cmd="id" -->
```

<mark style="background: #8000E1A6;">El servidor ejecuta el comando como el usuario del servicio web</mark> (`www-data`) → control del servidor. Para una shell estable, sustituye `id` por un one-liner de [[01 - Explotación básica - web shells y reverse shells|reverse shell]]. Igual que en [[00 - Introducción a Command Injection|command injection]], el `exec` te da ejecución directa.

> [!info]+ Sin herramienta dedicada
> El conjunto de directivas SSI es pequeño y la explotación es **manual** —no hay un *scanner* estándar como en SQLi—. Se prueba a mano con Burp/Caido inyectando directivas en cada campo reflejado o en cada upload que aterrice en el webroot. Lo que importa es **dónde** acaba tu input y si ese fichero se procesa como SSI.

> [!info]+ Fuentes
> - [Apache — SSI howto](https://httpd.apache.org/docs/current/howto/ssi.html) · [OWASP — SSI Injection](https://owasp.org/www-community/attacks/Server-Side_Includes_(SSI)_Injection)
> - [PayloadsAllTheThings — SSI Injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Includes%20Injection)

El reverso defensivo —cómo se evita que una directiva inyectada se ejecute— es la [[01 - Prevención de SSI]].
