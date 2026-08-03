---
tags:
  - Protocolos
  - Corrupcion-Memoria
  - Command-Injection
  - Pentesting/Explotacion
Descripción: "Format strings como primitiva de lectura y escritura arbitraria, y qué cambia respecto al mundo web cuando la inyección de comandos o SQL ocurre en un servicio binario"
Fecha de actualización: 2026-08-03
Nota previa: "[[05 - Vulnerabilidades de agotamiento de recursos]]"
Nota siguiente: "[[07 - Canonicalización de rutas y errores verbosos]]"
Area: "[[Causas raíz de vulnerabilidades.base|Causas raíz de vulnerabilidades]]"
---
---

Tres fallos de inyección que en el vault ya están cubiertos **desde la perspectiva web**. Aquí va lo que cambia cuando el objetivo es un servicio binario: uno es exclusivo de C (*format strings*), y los otros dos cambian bastante de forma.

## Format strings (CWE-134)

Exclusivo de lenguajes con formateo variádico en tiempo de ejecución. El fallo es tan simple como esto:

```c
printf(usuario);          // ← VULNERABLE: el usuario controla el formato
printf("%s", usuario);    // ← correcto
```

`printf` **cuenta los especificadores del formato para saber cuántos argumentos leer**. Si el atacante escribe el formato, hace que la función lea (o escriba) argumentos que nunca se pasaron, tomándolos de la pila y de los registros.

| Especificador | Qué consigue el atacante |
| - | - |
| `%x`, `%p`, `%lx` | **Volcar la pila** palabra a palabra: punteros, canarios, direcciones de librerías → derrota ASLR |
| `%s` | Desreferenciar una palabra de la pila como puntero a cadena: **lectura arbitraria**, o caída si no es válido |
| `%n` | **Escribe** en memoria el número de caracteres impresos hasta el momento → **escritura arbitraria** |
| `%N$x` | Acceso directo al argumento N: convierte el volcado en algo dirigido en vez de secuencial |
| `%1000000d` | Relleno masivo: DoS, y el mecanismo para controlar qué valor escribe `%n` |

<mark style="background: #FF5582A6;">`%n` es lo que convierte esto de fuga de información en ejecución de código</mark>: combinando `%N$n` con relleno controlado se escribe un valor arbitrario en una dirección arbitraria, y con eso se sobrescribe una entrada de la GOT o un puntero a función ([[06 - Escritura arbitraria y subversión de lógica]]).

**Estado en 2026.** Es un fallo mucho más raro que hace veinte años, por tres razones:

- `-Wformat-security` y `-Wformat-nonliteral` avisan en compilación, y **`-Werror=format-security` es política por defecto** en Debian, Ubuntu y Fedora: un `printf(usuario)` ni siquiera compila.
- **`_FORTIFY_SOURCE` de glibc bloquea `%n`** cuando la cadena de formato está en memoria escribible — que es justo el caso cuando la controla el atacante.
- En el CRT de Microsoft, **`%n` está deshabilitado por defecto desde Visual Studio 2005**: hay que activarlo explícitamente con `_set_printf_count_output(1)`. No es que «nunca se implementara» —existe— pero está apagado salvo que el desarrollador lo encienda a propósito.

Dónde sigue apareciendo: **firmware y dispositivos empotrados**, toolchains antiguos, y funciones de log propias que envuelven `vsnprintf` pasando una cadena controlada. Es el sitio donde hay que buscarlo — y en un protocolo, cualquier campo que acabe en un log es candidato.

**Cómo se prueba**: meter `%x%x%x%x%n` (o solo `%p%p%p%p` si no quieres arriesgar una escritura) en todo campo de texto y ver si la respuesta o el log devuelven basura hexadecimal. Si aparecen valores que parecen punteros, está confirmado.

## Inyección de comandos en servicios de red

```c
void cambiar_clave(const char *usuario, int sock) {
    char *nueva = leer_cadena(sock);       // ← controlado
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "/sbin/update_password -u %s -p %s", usuario, nueva);
    system(cmd);                           // ← el shell interpreta la cadena
}
```

Con `nueva = "x; id > /tmp/pwned"`, el `;` separa comandos y `system()` ejecuta ambos. El repertorio de metacaracteres y de *bypass* es el mismo que en web y está en [[00 - Introducción a Command Injection]] — no lo repito.

**Lo que cambia en un servicio binario:**

- **Ocurre en el mismo proceso, no tras un intérprete.** No hay capa PHP ni Node en medio; el `system()` lo hace el propio servicio.
- **Los privilegios suelen ser más altos.** Un demonio de sistema corre como `root` o como una cuenta de servicio; un servidor web moderno corre como `www-data`. El impacto de una inyección aquí es directamente compromiso total del host.
- **Los filtros suelen ser peores o inexistentes**, porque el desarrollador no piensa que un protocolo binario tenga «entrada de usuario».
- **La causa raíz favorita**: `system()`, `popen()`, `ShellExecute()`, `CreateProcess()` con la línea de comandos construida por concatenación. La corrección es `execve()`/`posix_spawn()` con un **array de argumentos**, que no pasa por ningún shell.

**Y una variante propia del mundo binario**: la inyección de argumentos (*argument injection*, [CWE-88](https://cwe.mitre.org/data/definitions/88.html)). Aunque no haya shell, si tu cadena empieza por `-` puede interpretarse como una opción del programa invocado. `--output=/etc/cron.d/x` en una utilidad que escribe ficheros es RCE sin un solo metacarácter de shell.

## Inyección SQL desde un protocolo binario

```c
snprintf(q, sizeof(q), "SELECT pass FROM usuarios WHERE user = '%s'", usuario);
```

La técnica es idéntica a la web ([[SQL Injection.base|SQL Injection]]) y no la repito. Las diferencias operativas:

- **Sin errores en pantalla.** No hay página de error que devuelva el mensaje del motor. Casi siempre acabas en **blind** —booleana o por tiempo— usando la respuesta del protocolo como oráculo ([[SQLi Blind.base|SQLi Blind]]).
- **La conexión a la base de datos suele ser de alto privilegio.** Los servicios de infraestructura conectan con `sa` o `postgres` porque nadie separó permisos. Eso pone `xp_cmdshell` (MSSQL), `COPY ... PROGRAM` (PostgreSQL) o `INTO OUTFILE` (MySQL) directamente sobre la mesa.
- **`sqlmap` no vale tal cual.** Habla HTTP. Para un protocolo binario hay dos vías: escribir un *tamper* propio, o —lo que funciona mejor— montar un **puente HTTP**: un pequeño servidor local que recibe la petición de `sqlmap`, la envuelve en el *framing* del protocolo, la manda y devuelve la respuesta. Con la capa de parseo de [[07 - Modificar el protocolo en vuelo]] ya hecha, son 40 líneas.

## Qué probar, en resumen

Sobre cada campo de texto del protocolo, en una sola pasada:

```text
%p%p%p%p%p%p%p%p        ← format string (lectura, sin riesgo)
'                       ← SQLi: buscar cambio de comportamiento o error
"; id; #                ← inyección de comandos
$(id)  `id`  |id        ← variantes de shell
../../../etc/passwd     ← canonicalización → nota siguiente
-v --help               ← inyección de argumentos
```

Y observar **todo** lo que devuelve el protocolo: código de error distinto, retardo, tamaño de respuesta, o simplemente que el servicio se caiga.

> [!info]+ Fuentes
> - [CWE-134](https://cwe.mitre.org/data/definitions/134.html) (format string), [CWE-78](https://cwe.mitre.org/data/definitions/78.html) (inyección de comandos), [CWE-88](https://cwe.mitre.org/data/definitions/88.html) (inyección de argumentos), [CWE-89](https://cwe.mitre.org/data/definitions/89.html) (SQLi).
> - [`_FORTIFY_SOURCE` en glibc](https://www.gnu.org/software/libc/manual/html_node/Source-Fortification.html) — bloqueo de `%n` en formatos escribibles.
> - Forshaw, *Attacking Network Protocols*, cap. 9.
