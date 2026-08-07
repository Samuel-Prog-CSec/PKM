---
tags:
  - Proyectos
  - Go
  - Windows
  - Evasion
  - Tipo/Proyecto
Descripción: "Mide qué ve el EDR —hooks de userland, callbacks de kernel, providers ETW— y produce un mapa de visibilidad sin desactivar nada; el análogo de sistema del espejo de huella de red"
Fecha de actualización: 2026-08-04
Nota previa: "[[10 - Cazador de SSRF moderno]]"
Nota siguiente: "[[12 - Fuzzer adversarial de clasificadores]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 4-5 semanas
---
---

**Nombre propuesto**: `blindspot`

Un red teamer autorizado que va a operar sobre un host con EDR trabaja a ciegas respecto a lo único que de verdad importa: <mark style="background: #FFB86CA6;">qué de lo que va a hacer deja rastro</mark>. ¿Están enganchadas las funciones de `ntdll` que va a tocar? ¿Registra el producto el *callback* de creación de proceso? ¿Consume ETW-Ti? Hoy eso se averigua por prueba y error —haces algo, salta una alerta, aprendes—, y cada iteración es una detección más en el SIEM del cliente. Igual que el `mirror` (02) te dice cómo te ve la red antes de que te bloqueen, `blindspot` te dice qué ve el EDR **antes** de tocarlo.

La distinción es el proyecto entero: <mark style="background: #FF5582A6;">esto mide, no evade</mark>. Lee la telemetría y la reporta; nunca la modifica.

# El problema que resuelve

El EDR moderno no es una fuente de datos, son varias e independientes: hooks *inline* en espacio de usuario (las primeras instrucciones de funciones críticas de `ntdll`), *callbacks* de kernel (aviso privilegiado de que un proceso arranca, una imagen carga o se pide un *handle*), ETW y su variante de kernel ETW-Ti, AMSI para contenido de *scripts*, y los *minifilters* de sistema de ficheros. <mark style="background: #ADCCFFA6;">Cada fuente ve una cosa distinta, y cada despliegue las activa en distinto grado</mark>.

Nadie tiene la foto consolidada de qué está realmente activo en **este** host. El red teamer la reconstruye disparando alertas. Y el defensor sufre el problema simétrico: <mark style="background: #8000E1A6;">asume que su EDR lo ve todo porque está instalado, sin verificar que los callbacks están registrados y que ETW-Ti se está consumiendo de verdad</mark>. Un producto que no consume ETW-Ti tiene un punto ciego enorme y su panel no lo dice.

# Alcance del proyecto

Una herramienta de auditoría que enumera las fuentes de telemetría activas y produce un mapa de visibilidad. **No desactiva nada, por diseño.** Enumera:

- **Hooks de espacio de usuario.** Compara el `.text` de `ntdll`/`kernel32` cargado en memoria contra la copia limpia en disco y lista qué funciones están modificadas —es decir, qué llamadas está observando el EDR desde user-land—.
- **Callbacks de kernel.** Qué notificaciones (proceso, hilo, carga de imagen, *handle*) tienen un consumidor registrado. Requiere visibilidad de kernel, y ese requisito se declara.
- **Sesiones y providers ETW.** Qué se está consumiendo, con foco en **ETW-Ti**, que se genera desde el kernel y sigue viendo lo que un desenganche de user-land no evita.
- **AMSI.** Qué *providers* están registrados para inspeccionar contenido de *scripts*.
- **Correlación.** Cruza cada fuente activa con la clase de técnica que cazaría, para que el resultado no sea una lista de hooks sino un **mapa de qué se ve y qué no**.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Diff de `.text` memoria vs disco | Identifica los hooks de user-land sin depender de una lista precargada de firmas del EDR |
| Inventario de callbacks de kernel | La capa que el desenganche de user-land no afecta; sin ella, el mapa miente por optimista |
| Enumeración de ETW-Ti | Detecta el punto ciego más caro: un EDR que no consume ETW-Ti ve mucho menos de lo que su panel sugiere |
| Telemetría en capas, no binaria | Muestra qué fuente ve cada acción; "sin hook" no es "invisible" si el callback de kernel sigue mirando |
| Informe legible por el equipo azul | La salida vale para un purple: dice dónde el despliegue tiene huecos, con lenguaje de defensor |
| Cero escritura sobre la telemetría | Solo lee; es lo que lo separa de una herramienta de evasión y lo que lo hace presentable |

# Qué existe ya y dónde se queda corto

**TelemetrySourcerer** (jthuraisamy) enumera hooks de user-mode y sesiones ETW **y los deshabilita** —resalta precisamente los *providers* "relevantes para desactivar"—. La familia de herramientas de evasión (EDRSandblast y compañía) hace lo mismo: <mark style="background: #FFB8EBA6;">enumeran la telemetría como paso previo a cegarla</mark>. Del otro lado, Moneta o PE-sieve detectan anomalías de memoria con óptica forense de caza de malware.

`blindspot` toma la capacidad de enumeración de las primeras y se detiene ahí, dándole la vuelta al propósito: de *"qué desactivo"* a *"qué ve el EDR, y qué no"*. Es la mitad que a un auditor o a un equipo *purple* le falta: la foto de la vigilancia, sin la palanca para apagarla.

# Cosas a tener en cuenta

> [!warning]+ El valor depende de que NO sea una herramienta de evasión
> En el momento en que se le añade la capacidad de deshabilitar la telemetría, deja de ser un auditor y se convierte en `TelemetrySourcerer`. <mark style="background: #FF5582A6;">La línea es el propósito: `blindspot` lee y reporta, jamás escribe sobre la telemetría</mark>. Mantener esa línea es lo que lo hace usable por el equipo azul, presentable en un informe y defendible en un portfolio. Cruzarla lo convierte en otra cosa que ya existe.

- **Auditar también tiene huella.** Leer el `.text` de otro proceso o abrir *handles* para inventariar callbacks es actividad que algunos EDR alertan. La propia auditoría no es invisible, y eso hay que documentarlo, no esconderlo.
- **Requiere privilegios y hay que ser honesto sobre ello.** El inventario de callbacks de kernel necesita visibilidad de kernel; sin ella, la herramienta debe degradar a lo observable desde user-land y **decir** que su mapa es parcial, no fingir una foto completa.
- **El mapa es información sensible.** Le dice a un atacante exactamente dónde el cliente no tiene ojos. Se custodia y se destruye como el registro de operación (01) y el grafo de red (06).
- **Ausencia de hook no es vía libre.** Es el error de razonamiento clásico: se desengancha `ntdll` y se cree uno invisible, ignorando que ETW-Ti y los callbacks siguen reportando. El mapa por capas existe precisamente para no cometerlo.

# Fuera de alcance

No desactiva, no desengancha, no evade, no manipula la telemetría de ninguna forma. No es un EDR ni un producto de detección. Enumera la superficie de visibilidad, la reporta y se detiene —esa frontera es el diseño, no una limitación temporal—.

# Criterio de terminado

Cuando, sobre un host con un EDR conocido, lista correctamente las funciones enganchadas, los callbacks registrados y las sesiones ETW-Ti activas, y produce un informe con el que un defensor detecta un punto ciego real (por ejemplo, que ETW-Ti no se está consumiendo) sin que la herramienta haya modificado un solo byte de la telemetría.

# Conexiones en el vault

El marco es [[00 - Anatomía de un EDR]] y, sobre todo, [[01 - Mapa de telemetría de Windows]] —la herramienta es, en esencia, ese mapa hecho instrumento—; el porqué de cada fuente, en [[02 - Cómo se construye una detección]]. Las capas que enumera están en [[04 - Function-hooking DLLs]], [[06 - Syscalls directos e indirectos]] y [[07 - Notificaciones de creación de proceso e hilo]]; y [[05 - Unhooking y remapping de ntdll]] es la contraparte exacta —`blindspot` detecta lo que esa técnica quita—. Filosóficamente es el [[02 - Espejo de huella del atacante]] trasladado de la red al sistema.

> [!info]+ Fuentes
> - Vaadata, [*EDR — How It Works and Detection Mechanisms*](https://www.vaadata.com/en/blog/edr-endpoint-detection-and-response-how-it-works-and-detection-mechanisms/) — hooking de user-land y callbacks de kernel como fuentes de telemetría (consultado 2026-08-04).
> - Praetorian, [*ETW Threat Intelligence and Hardware Breakpoints*](https://www.praetorian.com/blog/etw-threat-intelligence-and-hardware-breakpoints/) — por qué ETW-Ti ve lo que el desenganche de user-land no evita.
> - Jackson Thuraisamy, [`TelemetrySourcerer`](https://github.com/jthuraisamy/TelemetrySourcerer) — la capacidad de enumeración de la que `blindspot` se queda solo con la mitad de lectura.
