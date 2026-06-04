---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Fecha de actualización: 2026-06-04
Nota previa: "[[02 - Búsqueda de strings en el código]]"
Nota siguiente: "[[04 - Búsqueda de errores SQL en los logs]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La [[02 - Búsqueda de strings en el código|búsqueda estática]] localiza las consultas sospechosas, pero a veces hay que ver **en tiempo real** cómo se transforma nuestra entrada antes de llegar a la query —especialmente cuando hay filtros, normalización o concatenaciones complejas de por medio—. El *live-debugging* remoto permite pausar la ejecución, inspeccionar variables y seguir el flujo paso a paso.

# Debugging remoto con JDWP

La JVM soporta depuración remota mediante el protocolo `JDWP` (Java Debug Wire Protocol). Se lanza la aplicación con los flags de debug, que abren un puerto (8000) a la espera de un depurador:

```shell-session
$ java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:8000 -jar BlueBird-0.0.1-SNAPSHOT.jar   # JDK 9+; legacy: -Xdebug -Xrunjdwp:...
Listening for transport dt_socket at address: 8000
```

<mark style="background: #FFB8EBA6;">`suspend=y` hace que la app espere a que el depurador se conecte antes de arrancar</mark>. Como el puerto suele estar en `localhost`, se reenvía por SSH:

```shell-session
$ ssh -L 8000:127.0.0.1:8000 student@10.10.10.x
```

# Conectar el IDE

Cualquier IDE Java sirve, ya que JDWP es estándar:

- **VS Code**: instalar el *Extension Pack for Java*, abrir la carpeta `BOOT-INF/classes`, añadir los JAR de `BOOT-INF/lib` como *Referenced Libraries* (resuelve los imports), y crear un `launch.json` de tipo `attach` al puerto 8000.
- **Eclipse**: importar el código decompilado en un proyecto, añadir los JAR de `lib/` al Build Path, y crear una *Remote Java Application* (Socket Attach, host `localhost`, puerto 8000).

Con un breakpoint en la línea de la consulta, la ejecución se detiene al alcanzarla y <mark style="background: #ADCCFFA6;">se puede inspeccionar el valor exacto de la variable `sql` justo antes de ejecutarse</mark> —viendo cómo quedó tras los filtros y concatenaciones—.

```json
{
  "type": "java",
  "name": "Remote Debugging",
  "request": "attach",
  "hostName": "127.0.0.1",
  "port": 8000
}
```

# Estrategia de breakpoints

La clave es interceptar el **momento exacto** en que el dato del usuario se convierte en query:

- Pon el breakpoint donde se **construye** la cadena `sql` (la concatenación), no donde se ejecuta: así ves el valor final antes de que llegue al motor.
- Usa **breakpoints condicionales** (p. ej. solo cuando `u` contiene `'`) para detenerte únicamente en tu petición y no en cada visita —imprescindible en una app con tráfico—.
- Inspecciona en el panel de variables cómo el filtro transforma tu entrada paso a paso (`u` → `u2` → la condición del `RegEx`); con la consola *evaluate expression* puedes probar payloads contra el `Matcher` en vivo, sin recompilar.
- `Step Into`/`Step Over` para seguir el flujo de validación y descubrir saneamientos que el código decompilado no deja ver con claridad.

> [!warning]+
> El debugging sobre **código decompilado** no siempre es 100% fiable: el bytecode reconstruido no coincide línea a línea con el fuente original, así que los breakpoints pueden caer en sitios ligeramente distintos. Es una ayuda, no una verdad absoluta —combínalo con la lectura estática y los [[04 - Búsqueda de errores SQL en los logs|logs]]—.

> [!important]+
> <mark style="background: #FF5582A6;">Desde el lado defensivo, un puerto JDWP expuesto es RCE directo</mark>: cualquiera que alcance el `dt_socket` puede ejecutar código arbitrario en la JVM (Metasploit tiene el módulo `exploit/multi/misc/java_jdwp_debugger`). Encontrar un `address=*:8000` accesible en un pentest es un hallazgo crítico por sí mismo. Nunca debe quedar expuesto en producción.

> [!info]+
> El live-debugging es especialmente útil para entender filtros de entrada antes de diseñar un [[05 - Bypass de caracteres comunes|bypass]]: ver exactamente qué `RegEx` se aplica y cómo, en lugar de inferirlo del código decompilado, que puede ser confuso.

La tercera técnica para confirmar qué consultas se ejecutan —sin tocar el IDE— es leer directamente los logs del motor: [[04 - Búsqueda de errores SQL en los logs]].
