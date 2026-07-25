---
tags:
  - Go
  - Go/Windows
  - Post-Explotacion
  - Evasion
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - Llamar a la Windows API desde Go]]"
Nota siguiente: "[[02 - Parsear ficheros PE con debug-pe]]"
Area: "[[Windows y PE.base|Windows y PE]]"
---
---

<mark style="background: #ADCCFFA6;">Process injection es escribir código propio en la memoria de otro proceso y ejecutarlo ahí</mark> — para una shell, código residente en memoria, o *hooking* de funciones. La variante clásica (DLL injection vía `LoadLibraryA`) es una cadena de llamadas a la Windows API desde Go. Es didáctica y **la más conocida por los defensores**: la entiendes aquí como ejercicio de Go+WinAPI, y ves por qué su huella es tan visible. La metodología ofensiva a fondo es Red Team ([[00 - Introducción a la escalada de privilegios en Windows|post-explotación Windows]]).

## La cadena de cuatro pasos

Sobre un `struct Inject` que arrastra el PID, la ruta del DLL y los handles, se encadenan las llamadas de [[00 - Llamar a la Windows API desde Go|la nota anterior]]:

```go
// 1. Handle al proceso víctima con los derechos justos
rights := PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION |
    PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ
hProc, _, err := procOpenProcess.Call(uintptr(rights), 0, uintptr(pid))

// 2. Reservar memoria en la víctima
addr, _, err := procVirtualAllocEx.Call(
    hProc, 0, uintptr(dllSize),
    MEM_COMMIT|MEM_RESERVE, PAGE_EXECUTE_READWRITE)      // <- permisos RWX: mira el aviso

// 3. Escribir el payload (aquí, la RUTA del DLL en disco)
pathBytes, _ := syscall.BytePtrFromString(dllPath)
procWriteProcessMemory.Call(hProc, addr,
    uintptr(unsafe.Pointer(pathBytes)), uintptr(dllSize), 0)

// 4. Localizar LoadLibraryA y lanzar un hilo remoto que lo ejecute
llib, _ := syscall.BytePtrFromString("LoadLibraryA")
loadLib, _, _ := procGetProcAddress.Call(kernel32.Handle(), uintptr(unsafe.Pointer(llib)))
procCreateRemoteThread.Call(hProc, 0, 0, loadLib, addr, 0, 0)   // ejecuta LoadLibraryA(dllPath)
```

<mark style="background: #FFB86CA6;">El truco está en el paso 4</mark>: `CreateRemoteThread` arranca un hilo en el proceso víctima cuya función de inicio es `LoadLibraryA` y cuyo parámetro es la dirección donde escribiste la ruta del DLL. El proceso víctima carga y ejecuta tu DLL como si fuera suyo. Se cierra con `WaitForSingleObject` (esperar al hilo), `GetExitCodeThread`, `CloseHandle` y `VirtualFreeEx` (liberar la memoria reservada).

Nota Go: `syscall.BytePtrFromString` convierte un string Go a un `*byte` terminado en null (lo que espera C). El `uintptr(unsafe.Pointer(pathBytes))` aquí es **seguro** porque va *inline* en el `.Call` — no se asigna a variable (regla de [[00 - Llamar a la Windows API desde Go]]).

## Por qué esta versión es tan visible

> [!warning]+ La cadena de manual deja una huella enorme
> El libro (2020) la presenta como *la* técnica. Para 2026 conviene entenderla como <mark style="background: #FF5582A6;">el caso de estudio de detección</mark> (MITRE ATT&CK **T1055.001**): un EDR la reconoce por la telemetría que deja. Las tres señales, desde el lado del defensor:
> - **Memoria RWX**: reservar una región `PAGE_EXECUTE_READWRITE` (escribible *y* ejecutable a la vez) casi no ocurre en software legítimo, que separa permisos (W^X). Es un IOC de primer orden.
> - **Hilo remoto entre procesos**: `CreateRemoteThread` de un proceso hacia otro es un evento que los EDR instrumentan directamente.
> - **DLL desde disco**: `LoadLibraryA` carga un fichero que **tocó el disco** — firma estática para el AV, más un evento de carga de módulo.
>
> Las familias de técnicas que reducen esta huella (permisos de memoria menos llamativos, ejecución sin un hilo remoto explícito, carga en memoria sin escribir en disco) son <mark style="background: #8000E1A6;">metodología de evasión de EDR</mark>: su desarrollo operativo vive en Red Team, no en esta nota de Go. Aquí basta el mensaje clave: **la cadena tal cual no sobrevive a un endpoint monitorizado**, y para eso hay que salir del patrón de manual. El ángulo Go relevante es que `x/sys/windows` y el `syscall` dan acceso a las mismas primitivas — la diferencia la marca *qué* APIs llamas y *cómo*, no el lenguaje.

> [!info]+ Un límite de Go que importa aquí
> Go **no compila a DLL de forma nativa**, así que la variante *reflective* (cargar un DLL desde memoria) no se arma solo con Go — necesita el puente CGO/C-archive que se ve en [[03 - CGO - mezclar C y Go]]. El payload que inyectas, cuando es shellcode en vez de un DLL, se genera y empaqueta como en [[04 - Shellcode Go-friendly con msfvenom]].

De inyectar en un proceso pasamos a **entender** el binario en sí: la estructura del ejecutable de Windows y cómo parsearla → [[02 - Parsear ficheros PE con debug-pe]].
