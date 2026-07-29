---
tags:
  - Evasion
  - Windows
  - EDR
  - Kernel
Descripción: "El spoofing de argumentos y padre miente sobre el *contexto*"
Fecha de actualización: 2026-07-28
Nota previa: "[[08 - Command-line y PPID spoofing]]"
Nota siguiente: "[[10 - Object callbacks y robo de handles]]"
Area: "[[Callbacks de kernel.base|Callbacks de kernel]]"
---
---

El [[08 - Command-line y PPID spoofing|spoofing de argumentos y padre]] miente sobre el *contexto*. Esta familia miente sobre algo más gordo: **qué código se está ejecutando realmente**. El objetivo es evadir las detecciones *basadas en imagen* (nombre de fichero, hash, firma, escaneo del binario) y, de paso, saltarse *application whitelisting*, reglas de firewall por aplicación y comprobaciones de "quién me está llamando" del lado servidor.

Todas las variantes explotan **la misma decisión de diseño de Microsoft**, y entenderla vale más que memorizar las cuatro técnicas.

# La grieta: la notificación llega tarde

Crear un proceso en Windows son doce pasos. La notificación a los drivers registrados es el **séptimo**:

```text
 1. Validar parámetros de la API de creación
 2. Abrir un handle a la imagen objetivo
 3. Crear un OBJETO SECCIÓN a partir de la imagen        <-- la grieta
 4. Crear e inicializar el objeto proceso
 5. Reservar el PEB
 6. Crear e inicializar el objeto hilo
 7. NOTIFICAR A LOS CALLBACKS REGISTRADOS                <-- aquí mira el EDR
 8. Operaciones específicas del subsistema Windows
 9. Iniciar la ejecución del hilo primario
10. Finalizar la inicialización del proceso
11. Comenzar la ejecución en el entry point de la imagen
12. Devolver el control al llamante
```

<mark style="background: #ADCCFFA6;">En el paso 3 el gestor de memoria **cachea** la sección de imagen, y a partir de ahí la sección puede **divergir** del fichero que la originó</mark>. Cuando en el paso 7 el driver recibe su `PS_CREATE_NOTIFY_INFO`, el `FileObject` que trae puede apuntar a un fichero que ya no contiene el código que se va a ejecutar — o que directamente ya no existe. <mark style="background: #FFB86CA6;">El EDR escanea el fichero equivocado y devuelve un falso negativo con total confianza</mark>.

# Las cuatro variantes

| Técnica | Año / autor | Truco central | Qué ve el EDR al escanear |
| --- | --- | --- | --- |
| **Hollowing** | ~2011 | Proceso suspendido → `NtUnmapViewOfSection` de su imagen → mapear la propia → `ResumeThread` | El fichero legítimo (`svchost.exe`), pero en memoria hay otra cosa |
| **Doppelgänging** | 2017 · Liberman & Kogan | Transacción **TxF**: sobrescribir el fichero dentro de la transacción, crear la sección, **hacer rollback** | El fichero original restaurado; la sección conserva el código malicioso |
| **Herpaderping** | 2020 · Johnny Shaw | Crear sección desde el payload, crear el proceso, y **luego** machacar el fichero en disco con el handle aún abierto | Basura (el fichero ya no es el payload) |
| **Ghosting** | 2021 · Gabriel Landau | Fichero en estado *delete-pending* → escribir payload → crear sección → cerrar handle (se borra) | `STATUS_FILE_DELETED` — no hay nada que escanear |

Las tres últimas comparten un segundo ingrediente: la **API legacy** `ntdll!NtCreateProcessEx()`, que acepta un *handle de sección* en lugar de un fichero. A cambio de esa flexibilidad, el desarrollador debe reconstruir a mano lo que `NtCreateUserProcess` hace solo (escribir los parámetros de proceso, crear el hilo principal), lo que explica por qué estos PoC son largos.

> [!info]+ Por qué Ghosting es tan elegante
> Windows impide **borrar** un fichero *después* de mapearlo como sección de imagen, pero **no comprueba** si existe una sección asociada durante el borrado. Si marcas el fichero para borrado (`NtSetInformationFile` + `FILE_DELETE_ON_CLOSE`) **antes** de crear la sección, al cerrar el handle el fichero desaparece y la sección sobrevive. Mientras está en *delete-pending*, cualquier intento externo de abrirlo falla con `ERROR_DELETE_PENDING` — así que ni siquiera hay ventana para escanearlo.

# Cómo se detecta: los campos que no puedes falsear

Aquí está el valor real de este capítulo para un pentester: saber **qué mira el defensor** te dice qué indicadores dejas. El PEB lo controla el usuario, así que el kernel prefiere `EPROCESS`:

| Fuente | Campo | Lectura |
| --- | --- | --- |
| `EPROCESS` | `ImageFileName` | Solo el nombre — en un proceso *ghosted* aparece algo como `THFA8.tmp` |
| `EPROCESS` | `SeAuditProcessCreationInfo.ImageFileName` | Ruta NT completa — **vacía** en un proceso manipulado |
| `EPROCESS` | `ImageFilePointer` | `NULL` si se creó desde sección con la API legacy |
| `EPROCESS` | `Minimal` / `PicoCreated` | Ambos `FALSE` → no era un proceso mínimo legítimo (WSL, *Pico*) |
| `PEB` | `ProcessParameters.ImagePathName` | Sigue diciendo `C:\Windows\System32\notepad.exe` |
| **VAD tree** | Primera asignación `Mapped Exe EXECUTE_WRITECOPY` | Revela la ruta **real**: `\Users\dev\AppData\Local\Temp\THF53.tmp` |

La detección se reduce a una comparación:

```c
// Lógica del driver, en el callback de creación
if (!pNotifyInfo->FileObject && !pNotifyInfo->IsSubsystemProcess)   // creado con la API legacy
{
    GetPebImagePath(pProcess, &pPebImage);                          // lo que dice el PEB
    ConvertPathToNt(pNotifyInfo->ImageFileName, &pProcImage);       // lo que dice EPROCESS
    if (RtlCompareUnicodeString(pPebImage, pProcImage, TRUE))       // ¿no coinciden?
        { /* image tampering */ }
}
```

<mark style="background: #8000E1A6;">Traducido: **cualquier** técnica de esta familia produce la misma pareja de indicadores</mark> — una sección de imagen que no cuadra con el ejecutable reportado, más el uso de la API legacy para crear un proceso no-mínimo. Por eso el defensor no necesita una regla por técnica: una regla genérica las cubre todas, incluidas las variantes que aún no se han publicado.

# Estado en 2026: la familia está quemada

El libro es de 2023 y presenta estas técnicas como vigentes. Hay que matizarlo con dureza:

- **Doppelgänging está muerto**. TxF lleva años **deprecado** por Microsoft (se desaconseja su uso y hay planes de retirarlo), y Defender detecta el patrón desde hace tiempo.
- **Herpaderping y Ghosting están cubiertos**. Microsoft publicó en 2022 (*«Using process creation properties to catch evasion techniques»*) el trabajo que llevó a Defender for Endpoint a alertar específicamente sobre estas variantes **y sobre el flujo genérico** — cualquier abuso de la API legacy de creación de procesos, incluidas variantes no publicadas.
- **Hollowing clásico** es de los patrones con **mayor señal comportamental** que existe: `CREATE_SUSPENDED` + `NtUnmapViewOfSection` + `WriteProcessMemory` + `ResumeThread` sobre un proceso propio. Cualquier producto decente lo caza.

> [!warning]+ Trampa clásica del PoC de GitHub
> Que un PoC de *ghosting* "funcione" en tu VM con Defender no significa que evada. Comprueba si el binario **ejecutó** y si además **no generó alerta**: son dos cosas distintas ([[03 - Tipos de bypass y la cadena de evasión|el error del script kiddie de EDR]]). En la práctica, estas técnicas hoy suelen *ejecutar* y *alertar* a la vez — el peor de los mundos.

# A dónde se movió el tradecraft

La idea de fondo sigue viva, pero cambió de sitio: en vez de **crear un proceso falso**, se ejecuta **dentro de uno real y ya validado**, manteniendo la memoria respaldada por imagen para no aparecer como *unbacked*:

- **Module stomping** (*DLL hollowing*) — cargar una DLL benigna en el proceso y sobrescribir su `.text`/entry point con el shellcode. La región sigue clasificándose como `Mapped Exe`, no como `Private`, lo que **desactiva de golpe** el indicador de memoria no respaldada que buscan los [[21 - Sleep obfuscation y escáneres de memoria|escáneres de memoria]].
- **Phantom DLL hollowing** — variante con sección transaccionada: el fichero de respaldo es una DLL firmada legítima, pero los bytes en memoria divergen. Es doppelgänging aplicado a una DLL en lugar de a un proceso.
- **Mockingjay** (2023) — buscar una DLL que ya exponga una sección **RWX por defecto** (el caso publicado fue `msys-2.0.dll` de Visual Studio 2022) y escribir ahí. Sin `VirtualAlloc`, sin `VirtualProtect`, sin hilo nuevo: se eliminan las tres llamadas que más se vigilan.

Todas comparten filosofía con los BOF de la [[07 - Notificaciones de creación de proceso e hilo|nota anterior]]: **no generar el evento** en vez de falsearlo. El desarrollo continúa en [[24 - Inyección moderna y EDR blinding]].

Fuentes: Matt Hand, *Evading EDR* cap. 3 · [Microsoft Security Blog — Using process creation properties to catch evasion techniques](https://www.microsoft.com/en-us/security/blog/2022/06/30/using-process-creation-properties-to-catch-evasion-techniques/) · [Elastic — Process Ghosting: a new executable image tampering attack](https://www.elastic.co/blog/process-ghosting-a-new-executable-image-tampering-attack) · [Johnny Shaw — Process Herpaderping](https://jxy-s.github.io/herpaderping/) · [hasherezade — process_ghosting PoC](https://github.com/hasherezade/process_ghosting) · [ired.team — Module stomping](https://www.ired.team/offensive-security/code-injection-process-injection/modulestomping-dll-hollowing-shellcode-injection) · [Security Joes — Mockingjay](https://www.securityjoes.com/post/process-mockingjay-echoing-rwx-in-userland-to-achieve-code-execution).
