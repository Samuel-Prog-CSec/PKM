---
tags:
  - Evasion
  - Windows
  - EDR
  - Kernel
Descripción: "Aquí empieza la parte que no puedes tocar desde tu proceso"
Fecha de actualización: 2026-07-28
Nota previa: "[[06 - Syscalls directos e indirectos]]"
Nota siguiente: "[[08 - Command-line y PPID spoofing]]"
Area: "[[Callbacks de kernel.base|Callbacks de kernel]]"
---
---

Aquí empieza la parte que **no** puedes tocar desde tu proceso. [[04 - Function-hooking DLLs|PatchGuard]] cerró el parcheo de la SSDT, pero Microsoft dejó abierta una puerta legítima y documentada para que los productos de seguridad vean el kernel: <mark style="background: #ADCCFFA6;">las **notification callback routines** — rutinas que el driver registra para que el kernel le avise cuando ocurre un evento del sistema</mark> (crear un proceso, crear un hilo, cargar una imagen, tocar el registro, abrir un handle). Son el sensor sobre el que se apoya la mayoría de EDR modernos, y esta nota cubre las dos más rentables para el defensor: proceso e hilo.

# Cómo funciona una notificación

El driver le dice al kernel «avísame cuando pase X». Cuando pasa, el kernel **llama a su función** pasándole una estructura con los datos del evento. Hay dos momentos posibles:

- **Pre-operation** — antes de que la operación se complete. Es la que usan los EDR: permite **interferir** (bloquear, degradar el resultado, [[00 - Anatomía de un EDR|devolver datos falsos]]).
- **Post-operation** — después. Da el resultado, pero se ejecuta en un **contexto de hilo arbitrario**, lo que complica atribuir el evento a quien lo originó.

La notificación no es un añadido opcional: está **dentro** del camino de creación del proceso. Poniendo un *breakpoint* en `nt!PspCallProcessNotifyRoutines` con WinDbg se ve la pila completa desde `cmd.exe` hasta el kernel:

```text
00  nt!PspCallProcessNotifyRoutines        <-- se avisa a TODOS los drivers registrados
01  nt!PspInsertThread+0x68e
02  nt!NtCreateUserProcess+0xddd
03  nt!KiSystemServiceCopyEnd+0x25
04  ntdll!NtCreateUserProcess+0x14
05  KERNELBASE!CreateProcessInternalW+0xfe3
07  KERNEL32!CreateProcessWStub+0x54
08  cmd!ExecPgm+0x262
```

<mark style="background: #8000E1A6;">No hay forma de crear un proceso en Windows sin pasar por ahí</mark> — ni con [[06 - Syscalls directos e indirectos|syscalls indirectos]], porque el `syscall` acaba igualmente en `nt!NtCreateUserProcess`. Cambiar *cómo* llamas no cambia *qué* pides: esa es la asimetría de todo este bloque.

# Notificaciones de proceso

El driver se registra con `PsSetCreateProcessNotifyRoutineEx()` o su variante `Ex2` (que además cubre subsistemas no-Win32, como WSL):

```c
PsSetCreateProcessNotifyRoutineEx2(
    PsCreateProcessNotifySubsystems,        // tipo de notificación
    (PVOID)ProcessNotifyCallbackRoutine,    // entry point del callback
    FALSE);                                 // FALSE = registrar, TRUE = quitar
```

Cuando se crea un proceso, el callback recibe un puntero a `PS_CREATE_NOTIFY_INFO`. Esto es **exactamente** lo que el EDR sabe de ti en el instante en que arrancas:

| Campo | Qué contiene | Por qué te importa |
| --- | --- | --- |
| `ImageFileName` | Ruta al ejecutable del proceso nuevo | Base de las detecciones por imagen; lo ataca el [[09 - Manipulación de la imagen de proceso\|image tampering]] |
| `CommandLine` | Argumentos de invocación | Blanco nº 1 de reglas frágiles; lo ataca el [[08 - Command-line y PPID spoofing\|argument spoofing]] |
| `ParentProcessId` | PID del padre **declarado** | Lo ataca el [[08 - Command-line y PPID spoofing\|PPID spoofing]] |
| `CreatingThreadId` | PID/TID del hilo que **realmente** llamó a la API | <mark style="background: #FF5582A6;">El delator: no se puede falsear y desenmascara el PPID spoofing</mark> |
| `FileObject` | Puntero al objeto fichero de la imagen en disco | Permite escanear el binario; lo ataca *ghosting*/*herpaderping* |
| `CreationStatus` | Resultado de la creación | Permite **bloquear** el proceso escribiendo aquí un `NTSTATUS` de error |

`Sysmon` **Event ID 1** es la materialización pública de esta estructura: `Image`, `CommandLine` y `ParentProcessId` salen literalmente de ella. Los campos extra (`ParentImage`, hashes, `IntegrityLevel`) los deriva el driver consultando el contexto — el kernel no se los da masticados.

> [!info]+ Ver qué drivers te vigilan
> Los punteros a los callbacks registrados viven en un array de `EX_FAST_REF` en `nt!PspCreateProcessNotifyRoutine`. Con un kernel debugger:
> ```text
> kd> dx ((void**[0x40])&nt!PspCreateProcessNotifyRoutine)
>       .Where(a => a != 0)
>       .Select(a => @$getsym(@$getCallbackRoutine(a).Function))
>   [2] : WdFilter+0x45e00     <-- Microsoft Defender
>   [6] : CI!I_PEProcessNotify <-- Code Integrity
> ```
> Es la forma más rápida de **identificar el driver del EDR sin hacer ingeniería inversa** — el punto de partida del [[23 - Reconocimiento de defensas y perfilado del EDR|perfilado de defensas]] y el prerrequisito de [[22 - BYOVD y kill del EDR|cualquier ataque al propio driver]].

# Notificaciones de hilo

Se registran con `PsSetCreateThreadNotifyRoutine()` (o `…Ex()`) y reciben **mucho menos**: PID del proceso dueño, TID, y un booleano crear/terminar. Aun así entregan algo que ningún otro callback ve: <mark style="background: #FFB86CA6;">la **creación de hilos remotos**, es decir, un proceso creando un hilo dentro de otro — el corazón de casi toda la inyección clásica</mark>. Y la detección cabe en una línea:

```c
void ThreadNotifyCallbackRoutine(HANDLE hProcess, HANDLE hThread, BOOLEAN bCreate)
{
    if (bCreate && PsGetCurrentProcessId() != hProcess) {
        // el hilo se creó DESDE otro proceso -> inyección remota
    }
}
```

Como el callback corre en el contexto del proceso **creador**, basta comparar. Eso es `Sysmon` **Event ID 8** (`SourceProcessId` ≠ `TargetProcessId`). Coste de implementación: dos líneas. Coste de evasión para ti: mucho más alto.

Hay ruido legítimo que el EDR debe filtrar y que tú puedes estudiar: el **primer hilo** de un proceso hijo siempre se crea desde el padre (muchos EDR lo ignoran por defecto), y `werfault.exe` (*Windows Error Reporting*) inyecta legítimamente en el proceso que ha fallado. Ninguna de las dos es una vía de evasión por sí sola, pero definen los huecos donde vive la tuya.

# El cambio de tradecraft: de fork&run a in-process

La razón por la que los EDR escrutan tanto la creación de procesos es histórica. Los agentes de C2 clásicos usan **fork&run**: <mark style="background: #ADCCFFA6;">lanzar un proceso *sacrificial* e inyectar en él la tarea de post-explotación</mark>, para que un fallo no tumbe el agente y para simplificar la limpieza. Es el modelo de `execute-assembly` de Cobalt Strike y de casi todo lo escrito en C#.

El problema operativo es evidente con lo visto arriba: cada tarea genera **una creación de proceso + una inyección remota**, o sea EID 1 + EID 8 + telemetría de memoria. Por eso el tradecraft se movió a ejecutar **dentro del propio agente**: los **BOF** (*Beacon Object Files*, Cobalt Strike 4.1) son objetos COFF en C que corren en el proceso del agente y eliminan por completo esos dos eventos.

> [!warning]+ Los BOF no son una bala de plata
> Quitan la telemetría del proceso sacrificial, **no la del trabajo en sí**: el tráfico de red, las escrituras en disco, los handles a `lsass.exe` y las llamadas a API siguen ocurriendo igual — y ahora dentro de tu agente, que pasa a acumular todos los indicadores en un único proceso de larga vida. Si el BOF revienta, te llevas el agente por delante. Es un intercambio de riesgo, no una eliminación. Ver [[24 - Inyección moderna y EDR blinding]].

# Qué se puede hacer contra estos callbacks

Poco de forma frontal, y conviene decirlo claro: <mark style="background: #FFB8EBA6;">estos callbacks no tienen un fallo estructural que explotar</mark>; se evaden aprovechando **puntos ciegos y decisiones de diseño**, no rompiéndolos. Las tres vías reales son las tres notas siguientes:

1. **Mentir en los datos que el callback recibe** — argumentos y padre → [[08 - Command-line y PPID spoofing]].
2. **Mentir sobre la imagen ejecutada** — explotando que la notificación llega en el paso 7 de 12 del arranque → [[09 - Manipulación de la imagen de proceso]].
3. **No generar el evento** — no crear procesos ni hilos remotos (BOF, ejecución in-process) → [[24 - Inyección moderna y EDR blinding]].

Queda una cuarta, cara y ruidosa: **quitar el callback del array** con un driver propio ([[22 - BYOVD y kill del EDR|BYOVD]]). Funciona, pero requiere kernel y deja su propio rastro.

Fuentes: Matt Hand, *Evading EDR* cap. 3 · [Microsoft — `PsSetCreateProcessNotifyRoutineEx2`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddk/nf-ntddk-pssetcreateprocessnotifyroutineex2) · [Microsoft — `PS_CREATE_NOTIFY_INFO`](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddk/ns-ntddk-_ps_create_notify_info) · [Sysmon — Event ID 1 y 8](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) · [Cobalt Strike — Beacon Object Files](https://hstechdocs.helpsystems.com/manuals/cobaltstrike/current/userguide/content/topics/beacon-object-files_main.htm).
