---
tags:
  - Evasion
  - Windows
  - EDR
  - Hooking
Descripción: "Si el hook es un parche de bytes en la copia de ntdll.dll que vive en tu proceso, la respuesta obvia es deshacerlo: unhooking consiste en sobrescribir la sección .text de la…"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Function-hooking DLLs]]"
Nota siguiente: "[[06 - Syscalls directos e indirectos]]"
Area: "[[Hooking userland.base|Hooking userland]]"
---
---

Si el hook es un parche de bytes en la copia de `ntdll.dll` que vive **en tu proceso**, la respuesta obvia es deshacerlo: <mark style="background: #ADCCFFA6;">**unhooking** consiste en sobrescribir la sección `.text` de la `ntdll` mapeada (contaminada con los `jmp` del EDR) con una copia **limpia** del mismo código</mark>. A partir de ahí las `Nt*` vuelven a ser el `syscall stub` original y las llamadas ya no pasan por la DLL del producto. La técnica es de manual y sigue funcionando contra productos de gama baja; contra un EDR puntero de 2026 es **ruidosa** y hay que saber por qué antes de usarla.

Toda la familia comparte el mismo esqueleto — cambia solo **de dónde sale la copia limpia**, y esa elección es la que decide tu huella.

# El esqueleto común

```c
// 1. Base de la ntdll contaminada que ya está mapeada en el proceso
MODULEINFO mi;
GetModuleInformation(GetCurrentProcess(), GetModuleHandleW(L"ntdll.dll"),
                     &mi, sizeof(MODULEINFO));

// 2. Conseguir una copia limpia -> lpClean (las 3 variantes de abajo)

// 3. Parsear cabeceras PE y localizar la sección .text
PIMAGE_DOS_HEADER  dos = (PIMAGE_DOS_HEADER)mi.lpBaseOfDll;
PIMAGE_NT_HEADERS  nt  = (PIMAGE_NT_HEADERS)((ULONG_PTR)mi.lpBaseOfDll + dos->e_lfanew);
// ... iterar secciones hasta encontrar ".text" ...

// 4. RX -> RWX, copiar, restaurar permisos
VirtualProtect(text, size, PAGE_EXECUTE_READWRITE, &oldProt);
RtlCopyMemory(text, cleanText, size);
VirtualProtect(text, size, oldProt, &oldProt);
```

Solo se copia `.text` porque es donde vive el código ejecutable —y por tanto los `stub`—; tocar `.data` o las relocalizaciones rompería el módulo.

> [!warning]+ El paso 4 es el que canta
> <mark style="background: #FF5582A6;">Cambiar los permisos de la `.text` de `ntdll.dll` a `RWX` es un indicador de altísima fidelidad</mark>: ningún programa legítimo reescribe el código de `ntdll` en caliente. Ese `NtProtectVirtualMemory` sobre una región **respaldada por imagen del sistema** es visible desde el kernel vía [[16 - EtwTi y Protected Processes|ETW-TI]] (`PROTECTVM`), da igual lo limpia que sea tu forma de obtener la copia. Es el techo estructural de toda la técnica.

# Variante 1 — leer `ntdll.dll` de disco

La del libro y la de casi todos los PoC: `CreateFileW` sobre `C:\Windows\System32\ntdll.dll`, `CreateFileMappingW` con `SEC_IMAGE`, `MapViewOfFile`, y a copiar. Directa, pero deja **dos** rastros:

1. **Acceso a fichero** a `ntdll.dll` desde un proceso de usuario — telemetría del [[12 - Minifilter drivers de filesystem|minifilter]].
2. **Doble carga de `ntdll`** en el mismo proceso. Aquí Hand aporta el dato que convierte la intuición en métrica: midiendo un entorno empresarial grande, <mark style="background: #FFB86CA6;">solo el **0,04 %** de 37 millones de procesos cargaron `ntdll.dll` más de una vez en un mes</mark>. Es decir: la relación normal es 1:1, y romperla te mete en un percentil que un *threat hunter* puede cazar con una consulta trivial sobre `Sysmon` **Event ID 7** (*ImageLoad*).

# Variante 2 — Perun's Fart (proceso suspendido)

Publicada por **Sektor7** en 2021, explota una ventana de carrera del arranque de procesos: <mark style="background: #ADCCFFA6;">cuando creas un proceso con `CREATE_SUSPENDED`, el *loader* de Windows ya ha mapeado `ntdll.dll` en él, pero el hilo principal aún no ha ejecutado nada — así que el EDR **todavía no ha inyectado** su DLL de hooking</mark>. Esa `ntdll` está limpia y se lee con `ReadProcessMemory`, sin tocar el disco:

```c
CreateProcessW(L"C:\\Windows\\System32\\notepad.exe", NULL, NULL, NULL, TRUE,
               CREATE_SUSPENDED, NULL, NULL, &si, &pi);
ReadProcessMemory(pi.hProcess, mi.lpBaseOfDll, pNtdll, mi.SizeOfImage, NULL);
// ... copiar .text limpia sobre la propia ...
TerminateProcess(pi.hProcess, 0);
```

Elimina el indicador de fichero, pero **paga otro peaje**: crear un proceso suspendido y matarlo acto seguido es igual de anómalo. Lo ven el [[07 - Notificaciones de creación de proceso e hilo|callback de creación de proceso]] del driver, el provider ETW `Microsoft-Windows-Kernel-Process` y —si existe— el hook de `NtCreateUserProcess`. Como dice el propio Hand: *es muy raro ver un programa legítimo creando un proceso suspendido temporal*.

# Variante 3 — `\KnownDlls\ntdll.dll` (la buena en 2026)

Windows cachea las DLL de sistema más usadas como **objetos sección** ya mapeados en el *object namespace*, bajo `\KnownDlls`. Ese objeto lo crea el kernel al arrancar, es **inmutable** y —crucialmente— <mark style="background: #8000E1A6;">ningún EDR lo puede hookear, porque no pertenece a ningún proceso: es la copia canónica del sistema</mark>. Mapearla es abrir una sección y proyectarla:

```c
UNICODE_STRING  us;   OBJECT_ATTRIBUTES oa;   HANDLE hSection = NULL;
RtlInitUnicodeString(&us, L"\\KnownDlls\\ntdll.dll");
InitializeObjectAttributes(&oa, &us, OBJ_CASE_INSENSITIVE, NULL, NULL);
NtOpenSection(&hSection, SECTION_MAP_READ, &oa);
PVOID clean = MapViewOfFile(hSection, FILE_MAP_READ, 0, 0, 0);
```

Sin `CreateFile`, sin proceso nuevo, sin evento de filesystem. Es la variante que montan hoy los *loaders* maduros y la que deberías preferir si vas a unhookear. Ojo: `OpenFileMapping` falla siempre con `ERROR_BAD_PATHNAME` sobre esta ruta — hay que ir por `NtOpenSection`.

# Unhooking selectivo: menos superficie

Restaurar la `.text` entera (≈1 MB) es innecesario y llamativo. El *unhooking selectivo* parchea **solo los `stub` de las funciones que vas a usar**: 16 bytes por función, una decena de funciones. Reduce el tamaño de la escritura y, sobre todo, permite dejar intactos hooks que el EDR podría verificar periódicamente. Sigue necesitando el `RWX` sobre `ntdll`, así que no resuelve el problema de fondo — solo lo hace más pequeño.

# La alternativa: que la DLL no llegue a entrar

En vez de deshacer el hook, impedirlo. Windows expone una política de mitigación por proceso que <mark style="background: #ADCCFFA6;">bloquea la carga de cualquier binario **no firmado por Microsoft** en el proceso hijo</mark>:

```c
// PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY en el STARTUPINFOEX del hijo
DWORD64 policy = PROCESS_CREATION_MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_ON;
UpdateProcThreadAttribute(si.lpAttributeList, 0,
                          PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
                          &policy, sizeof(policy), NULL, NULL);
```

Es el `blockdlls start` de Cobalt Strike. Contra un EDR que inyecta una DLL firmada por el vendor, funciona: la DLL no carga y **no hay hook que evadir**. Limitaciones reales: (1) no impide la [[11 - Image-load y registro - KAPC injection|inyección por KAPC]] de todo lo firmado por Microsoft; (2) no toca el driver de kernel ni ETW-TI; (3) el atributo de mitigación es **visible** en el proceso creado y varios EDR (Elastic incluido) tienen regla para el patrón *proceso hijo con `BlockNonMicrosoftBinaries` activado*. Sirve, pero no es gratis.

# Cómo te cazan hoy

- **`Sysmon` EID 7** — segunda carga de `ntdll.dll` en el mismo GUID de proceso (variante 1).
- **`Sysmon` EID 1 + EID 5** — creación y muerte inmediata de un proceso suspendido (variante 2).
- **ETW-TI `PROTECTVM`** — el `RX→RWX` sobre imagen del sistema (las tres variantes).
- **Escáneres de integridad de módulo** — `PE-sieve` y `Moneta` comparan la `.text` en memoria contra la de disco. Se diseñaron para pillar *hooks*, pero detectan igual de bien un módulo **restaurado** cuando el EDR esperaba encontrar los suyos.
- **Firmas del propio unhooker** — CrowdStrike y SentinelOne llevan firmas de las secuencias de bytes de los PoC públicos. Copiar código de un repo tal cual es la forma más rápida de quemar la operación.
- **Verificación periódica del hook** — un agente puede recomprobar sus `detour` cada N segundos; si han desaparecido, el propio *unhooking* es la alerta.

> [!important]+ Veredicto 2026
> El *unhooking* es una técnica **de gama baja**: resuelve un sensor que los EDR punteros ya casi no usan ([[04 - Function-hooking DLLs|nota anterior]]) y a cambio genera indicadores de alta fidelidad. <mark style="background: #FFB8EBA6;">Hoy el camino por defecto no es "limpiar `ntdll`", sino **no depender de ella**</mark>: [[06 - Syscalls directos e indirectos|syscalls indirectos]] con SSN resuelto en runtime, que no escriben en memoria de imagen. Reserva el *unhooking* para cuando necesites que una API concreta funcione sin reimplementarla, y hazlo por `\KnownDlls` y de forma selectiva.

Fuentes: Matt Hand, *Evading EDR* cap. 2 (dato del 0,04 % y listados 2-11/2-12) · [Sektor7 — Perun's Fart](https://blog.sektor7.net) · [MDSec — Bypassing User-Mode Hooks](https://www.mdsec.co.uk/2020/12/bypassing-user-mode-hooks-and-direct-invocation-of-system-calls-for-red-teams/) · [ired.team — Full DLL unhooking](https://www.ired.team/offensive-security/defense-evasion/how-to-unhook-a-dll-using-c++) · [Microsoft — `UpdateProcThreadAttribute` / mitigation policies](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute) · [PE-sieve / Moneta](https://github.com/hasherezade/pe-sieve).
