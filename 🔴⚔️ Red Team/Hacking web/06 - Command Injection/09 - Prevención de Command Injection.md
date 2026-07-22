---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[08 - Herramientas de evasión y ofuscación]]"
Nota siguiente: "[[10 - Arsenal de herramientas para Command Injection]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Entender la prevención no es material defensivo "de relleno" para un pentester: <mark style="background: #ADCCFFA6;">conocer la defensa correcta es saber exactamente dónde busca su grieta</mark>. Y la lección central de este módulo, vista desde el lado azul, es que casi todo lo que la gente despliega —blacklists, escaping, WAFs— ya lo hemos roto. La única defensa de verdad sólida ataca la causa raíz.

# La defensa raíz: no invocar la shell

La causa de toda command injection es construir una cadena que se pasa a una shell (`/bin/sh -c`, `cmd.exe`). <mark style="background: #FFB86CA6;">Si nunca se invoca una shell, los metacaracteres pierden todo su poder</mark>. Dos formas:

**1. Usar la función nativa en vez del comando.** Si lo que necesitas es comprobar si un host responde, no llames a `ping`: usa la API del lenguaje. En `PHP`, `fsockopen()` abre un socket sin tocar la shell. La mayoría de lenguajes tienen equivalente nativo para red, ficheros, imágenes, etc. — casi nunca hace falta una shell.

**2. Si hay que ejecutar un binario, hacerlo sin shell**, pasando los argumentos como un **array** (`execve` directo), no como una cadena que una shell interpreta:

| Lenguaje | ❌ Inseguro (invoca shell) | ✅ Seguro (sin shell) |
| - | - | - |
| Node.js | `child_process.exec("ping " + ip)` | `execFile("ping", ["-c1", ip])` |
| Python | `os.system("ping " + ip)` | `subprocess.run(["ping","-c1",ip], shell=False)` |
| PHP | `system("ping " . $ip)` | `escapeshellarg()` + arg único, o evitar |
| Java | `Runtime.exec("ping " + ip)` | `ProcessBuilder("ping","-c1",ip)` |
| Go | `exec.Command("sh","-c","ping "+ip)` | `exec.Command("ping","-c1",ip)` |

<mark style="background: #8000E1A6;">Pasar argumentos como array significa que `; whoami` se trata como un único argumento literal de `ping`</mark> —un nombre de host inválido—, no como un comando nuevo. La inyección clásica deja de existir.

> [!important]+ `escapeshellcmd` no es suficiente; `escapeshellarg` por argumento
> HTB menciona `escapeshellcmd` y `escape()`, pero el escaping es la defensa más débil: <mark style="background: #FF5582A6;">lo hemos bypasseado durante todo el módulo</mark>. `escapeshellcmd` escapa la línea entera y deja huecos (no acota argumentos). Si hay que escapar, `escapeshellarg()` —que envuelve **cada argumento** en comillas seguras— es correcto, pero sigue siendo inferior a no usar la shell. El escaping es el último recurso, no el primero.

# Validación de entrada: allow-list, no blacklist

La validación comprueba que la entrada tiene el **formato esperado** y rechaza lo que no encaje. La regla de oro: <mark style="background: #8000E1A6;">define lo permitido (allow-list), no lo prohibido (blacklist)</mark> — porque enumerar todo lo malo es imposible, justo lo que explotamos en las notas de evasión.

Para formatos estándar, usar el validador del lenguaje en lugar de regex caseras:

```php
if (filter_var($_GET['ip'], FILTER_VALIDATE_IP)) {
    // formato IP válido
} else {
    // denegar
}
```

Para formatos no estándar, una regex anclada (`^...$`); en `NodeJS`, librerías como `is-ip` (`isIp(ip)`). Y siempre <mark style="background: #FFB8EBA6;">en el back-end</mark>: la validación de front-end mejora la UX pero [[02 - Operadores de inyección de comandos|se salta con un proxy]], como vimos.

# Sanitización: depurar tras validar

La sanitización elimina los caracteres especiales innecesarios, **después** de validar (por si la validación falla, p. ej. una regex mal escrita). Mejor con allow-list de caracteres permitidos:

```php
$ip = preg_replace('/[^A-Za-z0-9.]/', '', $_GET['ip']);
```

Solo sobreviven alfanuméricos y el punto, lo justo para una IP. Cualquier metacarácter de shell desaparece antes de tocar nada. En `JavaScript`, el `.replace(/[^A-Za-z0-9.]/g, '')` equivalente.

# Configuración del servidor: defensa en profundidad

Aunque el código sea perfecto, el servidor debe limitar el daño si algo falla:

- **Principio de mínimo privilegio (PoLP)**: el proceso web corre como usuario sin privilegios (`www-data`), nunca `root`. <mark style="background: #FFB86CA6;">Reduce una RCE de "control total" a "control del usuario web"</mark>.
- **PHP `disable_functions=system,exec,shell_exec,passthru,popen`**: desactiva los *sinks* peligrosos a nivel de intérprete.
- **PHP `open_basedir='/var/www/html'`**: confina el acceso de la app a su directorio.
- **WAF**: `mod_security` (con el [[03 - Identificación de filtros y defensas|OWASP CRS]]) más un WAF externo (Cloudflare, Imperva). Es una capa, no la defensa.
- **Contenedores y `seccomp`/`AppArmor`** (adición moderna): aislar el proceso y restringir las syscalls que puede emitir; aunque haya RCE, el atacante queda encajonado.
- **Rechazar peticiones double-encoded** y caracteres no-ASCII en la URL; evitar librerías obsoletas (`PHP CGI` → Shellshock).

> [!warning]+ Ninguna capa basta sola
> La blacklist se bypassea, el escaping se bypassea, el WAF se evade con [[07 - Ofuscación avanzada de comandos|ofuscación]]. La seguridad real es **ejecución sin shell + allow-list + PoLP + aislamiento**, todo a la vez. Si en una auditoría ves que el equipo confía en una sola capa (típicamente "tenemos un WAF"), ahí está tu hallazgo.

# Lo que esto significa para el pentest

Para nosotros, esta nota es un mapa de debilidades. <mark style="background: #FF5582A6;">Cada defensa que falta o está mal implementada es un vector</mark>: ¿corre como `root`? escalada trivial tras la RCE. ¿`disable_functions` incompleto? queda un sink. ¿confían solo en el WAF? ofuscación. Aplicaciones con millones de líneas tienen siempre una llamada a la shell olvidada — la metodología de [[01 - Detección de Command Injection|detección]] del módulo existe precisamente para encontrarla.

> [!info]+ Fuentes
> - [OWASP — OS Command Injection Defense Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/OS_Command_Injection_Defense_Cheat_Sheet.html)
> - [OWASP — Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
> - [PortSwigger — Preventing OS command injection](https://portswigger.net/web-security/os-command-injection#how-to-prevent-os-command-injection-attacks)

Para cerrar el módulo, el complemento operativo: el set de herramientas profesionales para detectar, evadir, explotar y registrar command injection en un engagement real. [[10 - Arsenal de herramientas para Command Injection]].
