---
tags:
  - Web/Red-Team
  - Command-Injection
  - Introduccion
Fecha de actualización: 2026-06-13
Nota previa:
Nota siguiente: "[[01 - Detección de Command Injection]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Una `command injection` es, junto a la deserialización insegura, la vulnerabilidad web de mayor impacto inmediato: <mark style="background: #ADCCFFA6;">permite ejecutar comandos del sistema operativo directamente en el servidor back-end</mark>. No se trata de leer un fichero ajeno o robar una sesión —se trata de obtener una shell. En la práctica del pentest y del bug bounty, encontrar una command injection equivale a `Remote Code Execution` (RCE): <mark style="background: #FFB86CA6;">el control del servidor, y desde ahí el pivote a la red interna</mark>. Es el hallazgo que convierte un informe de severidad media en un *critical*.

El patrón es siempre el mismo: una aplicación toma entrada controlada por el usuario y la usa —directa o indirectamente— para construir un comando que pasa a una shell del sistema (`/bin/sh`, `bash`, `cmd.exe`, `PowerShell`). Si esa entrada no se sanea ni se escapa, podemos romper los límites del comando previsto e inyectar el nuestro.

# La familia de las inyecciones

Las inyecciones son el **riesgo nº 3** del [[OWASP|OWASP Top 10]] (categoría [`A03:2021-Injection`](https://owasp.org/www-project-top-ten/)), tras años encabezando la lista como nº 1. El descenso no refleja que sean raras, sino que los frameworks modernos las mitigan por defecto mejor que antes. <mark style="background: #FFB8EBA6;">Cuando aparecen hoy, suelen estar en el código que se salió del framework</mark>: una llamada manual a la shell, un binario legacy, un microservicio escrito a mano.

La raíz conceptual la comparten todas: <mark style="background: #8000E1A6;">entrada de usuario que el intérprete malinterpreta como parte de la query o el código a ejecutar</mark>, en lugar de como un simple dato. Cambiar el resultado previsto por otro útil para el atacante es la esencia de toda inyección.

| Inyección | Dónde se interpreta la entrada |
| - | - |
| **OS Command Injection** | Como parte de un comando del SO |
| **Code Injection** | Dentro de una función que evalúa código del propio lenguaje (`eval`) |
| [[00 - Introducción a SQL Injection\|SQL Injection]] | Como parte de una consulta SQL |
| [[00 - Introducción a XSS\|XSS / HTML Injection]] | Como HTML/JS reflejado en la página |
| [[Inyección XPath\|XPath Injection]], `LDAP`, `NoSQL`, `XXE` | En la query del motor correspondiente |

Existen muchas más —`HTTP Header Injection`, `IMAP Injection`, `ORM Injection`, `SSTI`, `XPath`—. La regla general: <mark style="background: #FF5582A6;">cada vez que una entrada llega a un intérprete sin sanear, existe la posibilidad de escapar del contexto de dato y manipular la instrucción padre</mark>. A más tecnologías nuevas en el stack, más tipos de inyección posibles.

> [!important]+ OS Command Injection vs. Code Injection
> Son primos, no gemelos. En **code injection** inyectamos código del lenguaje de la app (PHP, Python, JS) que se ejecuta vía `eval()`, `exec()` de Python, `Function()` de JS, etc. En **OS command injection** inyectamos comandos del sistema que acaban en una shell. La frontera se difumina cuando el código inyectado a su vez invoca la shell (`os.system`, `child_process.exec`). En un informe conviene distinguirlas: el *blast radius* y la remediación difieren.

# La causa raíz: funciones que invocan la shell

Todos los lenguajes ofrecen funciones para ejecutar comandos del SO —algo legítimo (instalar plugins, lanzar `ImageMagick`, convertir un PDF)—. El problema nace cuando el argumento de esas funciones se concatena con entrada del usuario. Conviene memorizar los *sinks* peligrosos por lenguaje, porque son lo primero que se busca en una auditoría white-box:

| Lenguaje | Funciones / *sinks* peligrosos |
| - | - |
| **PHP** | `system`, `exec`, `shell_exec`, `passthru`, `popen`, `proc_open`, `` `backticks` `` |
| **Node.js** | `child_process.exec`, `execSync`, `child_process.spawn` (con `shell:true`) |
| **Python** | `os.system`, `os.popen`, `subprocess.call/run/Popen` con `shell=True`, `eval`, `exec` |
| **Java** | `Runtime.getRuntime().exec()`, `ProcessBuilder` |
| **Ruby** | `system`, `exec`, `` `backticks` ``, `%x[]`, `open("\|...")` |
| **Go** | `os/exec` con `exec.Command("sh", "-c", ...)` |
| **Perl** | `system`, `exec`, `` `backticks` ``, `open` con pipe |

<mark style="background: #FFB8EBA6;">El denominador común peligroso es invocar una shell intermedia</mark> (`sh -c`, `shell:true`). Cuando el lenguaje ejecuta el binario directamente pasándole los argumentos como un array —`execve` sin shell—, los metacaracteres pierden su poder y la inyección clásica deja de funcionar. Esa distinción es el núcleo de la [[09 - Prevención de Command Injection|prevención]].

## Ejemplo vulnerable en PHP

```php
<?php
if (isset($_GET['filename'])) {
    system("touch /tmp/" . $_GET['filename'] . ".pdf");
}
?>
```

La app crea un `.pdf` vacío con el nombre que pasa el usuario en `filename`. Como ese parámetro `GET` se concatena directo en el comando `touch` —sin sanear ni escapar—, basta enviar `filename=x;whoami` para que la shell ejecute dos comandos: el `touch` previsto y nuestro `whoami`.

## El mismo fallo en Node.js

```javascript
app.get("/createfile", function(req, res){
    child_process.exec(`touch /tmp/${req.query.filename}.txt`);
})
```

Idéntico patrón: `req.query.filename` entra crudo en una *template literal* que va a `exec`, que lanza `/bin/sh -c`. <mark style="background: #8000E1A6;">El lenguaje cambia, la técnica de explotación no</mark>: ambos casos se explotan con los mismos operadores de inyección. Y esto no se limita a aplicaciones web —cualquier binario o *thick client* que pase entrada sin sanear a una función de ejecución es vulnerable igual.

# Directa vs. ciega

En una command injection **directa** vemos la salida del comando en la respuesta (la web nos devuelve el resultado de `whoami`). En una **ciega** (`blind`) no hay output visible: la app ejecuta el comando pero no nos muestra nada. <mark style="background: #FF5582A6;">La inyección ciega es hoy el caso más frecuente en aplicaciones reales</mark>, y obliga a técnicas de confirmación indirecta —retardos temporales o conexiones *out-of-band*— que veremos en la [[01 - Detección de Command Injection|detección]].

> [!info]+ Casos reales de alto impacto
> La command injection sigue muy viva en CVEs críticos recientes:
> - **CVE-2024-3400** (Palo Alto PAN-OS GlobalProtect): inyección de comandos no autenticada, explotada como `0-day` para desplegar backdoors en firewalls perimetrales.
> - **CVE-2021-22205** (GitLab vía ExifTool): RCE no autenticado a través de la subida de una imagen manipulada; masivamente explotada por botnets.
> - **Shellshock (CVE-2014-6271)**: inyección en `bash` vía variables de entorno en CGIs; el caso histórico que popularizó la clase.
>
> El patrón común: un parámetro que alimenta una llamada a la shell en un componente legacy o de terceros (un parser, un convertidor, un CGI).

# Por qué importa para el pentest

El impacto de una command injection es máximo por definición: ejecución arbitraria con los privilegios del proceso web (a menudo `www-data`, pero no es raro encontrar `root` en *appliances* y dispositivos IoT). Desde ahí, el camino habitual es <mark style="background: #FFB86CA6;">enumerar el sistema, establecer una reverse shell, escalar privilegios y pivotar a la red interna</mark>. En bug bounty, una RCE confirmada es de las recompensas más altas del programa.

El reto profesional actual no es explotar la inyección en un lab limpio —eso es trivial—, sino **encontrarla** entre las defensas modernas (WAF, *allow-lists*, ejecución sin shell) y **evadir** los filtros cuando existe pero está parcialmente protegida. Ese es el recorrido de este sub-tema: primero la [[01 - Detección de Command Injection|detección]] rigurosa, después los [[02 - Operadores de inyección de comandos|operadores]] de explotación, y por último el bloque de [[03 - Identificación de filtros y defensas|evasión de filtros]] que ocupa la mayor parte del módulo.

Empezamos por detectarla: [[01 - Detección de Command Injection]].
