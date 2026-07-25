---
tags:
  - Go
  - Go/Windows
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - Process injection clásica]]"
Area: "[[Windows y PE.base|Windows y PE]]"
---
---

Atacar Windows desde Go pasa por hablar con la **Windows API**: las funciones que exportan las DLLs del sistema (`kernel32.dll`, `user32.dll`, `advapi32.dll`). Go no tiene bindings nativos para todo, así que cargas la DLL y llamas la función por su nombre. El reto no es la llamada — es reconciliar los tipos de C/Windows con los de Go y pelearte con el recolector de basura.

## Cargar una DLL y llamar una función

El paquete `syscall` carga la DLL y obtiene un puntero a la función:

```go
var (
    kernel32     = syscall.NewLazyDLL("kernel32.dll")
    procOpenProc = kernel32.NewProc("OpenProcess")
)

handle, _, lastErr := procOpenProc.Call(
    uintptr(rights),         // DWORD dwDesiredAccess
    uintptr(0),              // BOOL  bInheritHandle
    uintptr(pid),            // DWORD dwProcessId
)
if handle == 0 {
    return fmt.Errorf("OpenProcess: %v", lastErr)
}
```

`NewLazyDLL` carga la DLL de forma perezosa (al primer uso); `NewProc` resuelve la función exportada. <mark style="background: #ADCCFFA6;">`.Call` acepta un número variable de `uintptr` y devuelve `(r1, r2 uintptr, lastErr error)`</mark>. Ojo con el error: la Windows API no sigue el patrón `err != nil` de Go — el tercer valor es `GetLastError`, que **solo es válido si la función falló** (compruébalo mirando el valor de retorno, aquí `handle == 0`).

## Reconciliar tipos Windows ↔ Go

Los tipos de Microsoft no coinciden con los de Go. La tabla que usarás una y otra vez:

| Windows | Go | | Windows | Go |
| - | - | - | - | - |
| `BOOL` | `int32` | | `HANDLE` | `uintptr` |
| `BOOLEAN` / `BYTE` | `byte` | | `LPVOID` / `LPCVOID` | `uintptr` |
| `DWORD` / `DWORD32` | `uint32` | | `SIZE_T` | `uintptr` |
| `DWORD64` | `uint64` | | `HMODULE` / `LPCSTR` | `uintptr` |
| `WORD` | `uint16` | | `LPDWORD` | `uintptr` |

Casi todo lo que es un puntero o un handle en Windows se pasa como `uintptr` en Go. Y ahí empieza el peligro.

## El filo afilado: `unsafe.Pointer`, `uintptr` y el GC

Para pasar punteros Go a la API hay que saltarse el *type-safety* con `unsafe` (nota [[08 - Punteros]]). Las cuatro conversiones legales: cualquier `*T` ↔ `unsafe.Pointer`, y `unsafe.Pointer` ↔ `uintptr`.

> [!warning]+ `uintptr` es un entero, no una referencia — el GC no lo respeta
> Este es el error que cuelga programas de forma intermitente. <mark style="background: #FF5582A6;">Un `unsafe.Pointer` mantiene viva la memoria; un `uintptr` **no**</mark> — es solo un número. Si guardas `uintptr(unsafe.Pointer(x))` en una variable y lo usas en otro statement, el recolector puede haber liberado `x` entre medias, y el `uintptr` apunta a basura. Es el mismo filo que en [[03 - Portar exploits de C a Go - Dirty COW|Dirty COW]]. La conversión `uintptr(unsafe.Pointer(p))` es segura solo **inline**, dentro de la propia llamada `.Call(...)`; en cuanto la asignas a una variable para reusarla, hay riesgo.
>
> El fix cuando necesitas conservar la dirección: **`runtime.KeepAlive`**:
> ```go
> addr := uintptr(unsafe.Pointer(success))
> // ...usar addr en varios statements...
> runtime.KeepAlive(success)   // el GC no libera 'success' hasta aquí
> ```
> Una línea que le dice al runtime "mantén esto vivo hasta este punto". El propio `syscall` usa `uintptr(unsafe.Pointer(...))` por todas partes; entiende **por qué** funciona antes de copiarlo.

## Modernización: `golang.org/x/sys/windows`

> [!important]+ `syscall` está congelado — usa `x/sys/windows`
> Igual que en Linux (`x/sys/unix`), el paquete `syscall` para Windows está **congelado** desde Go 1.4. El estándar es <mark style="background: #FFB86CA6;">`golang.org/x/sys/windows`</mark>, con *wrappers* tipados (`windows.OpenProcess`, `windows.VirtualAllocEx`…) que evitan gran parte del baile de `uintptr`. Y para cargar DLLs del sistema, usa **`windows.NewLazySystemDLL`** en vez de `NewLazyDLL("kernel32.dll")`: fuerza la carga desde `System32`, cerrando el **DLL hijacking** del propio loader (plantar una `kernel32.dll` maliciosa en el directorio de trabajo — la técnica de [[15 - DLL hijacking]]). El libro lo menciona de pasada; hazlo por defecto.

Con la API accesible y los punteros bajo control, la primera técnica de peso es inyectar código en otro proceso → [[01 - Process injection clásica]].
