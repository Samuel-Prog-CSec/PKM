---
tags:
  - Go
  - Go/Plugins
Descripción: "El talón de Aquiles del plugin nativo es la portabilidad: no *cross-compila* y exige alinear versiones de Go y dependencias"
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - El sistema de plugins nativo de Go]]"
Nota siguiente: ""
Area: "[[Plugins y extensibilidad.base|Plugins y extensibilidad]]"
---
---

El talón de Aquiles del [[01 - El sistema de plugins nativo de Go|plugin nativo]] es la portabilidad: no *cross-compila* y exige alinear versiones de Go y dependencias. Un plugin que es un **script de texto** esquiva todo eso. Es el enfoque de Nmap (NSE) y Wireshark, ambos extensibles con **Lua**. En Go se embebe con `gopher-lua`, un intérprete Lua en Go puro.

```shell-session
$ go get github.com/yuin/gopher-lua
```

## El problema: Lua no conoce tus tipos Go

Un script Lua no puede llamar a `net/http` ni conoce tus structs. Hay dos formas de salvar ese hueco:

1. **El plugin llama a paquetes Lua externos** para lo que necesite (HTTP, etc.). Simple en el core, pero <mark style="background: #FFB8EBA6;">mata la portabilidad</mark>: cada plugin arrastra dependencias Lua que quizá no estén en la máquina destino, y dos plugins pueden pedir versiones distintas.
2. **El *façade*** — envuelves funciones Go y las expones a Lua. Escribes más código en el core, pero los plugins reusan una API consistente y sin dependencias externas. Es la opción sensata.

## El façade: envolver Go para Lua

Cada función Go expuesta a Lua tiene la firma `func(*lua.LState) int`. Lee los parámetros del `LState`, hace su trabajo, empuja los resultados de vuelta y devuelve **cuántos** valores empujó:

```go
func head(l *lua.LState) int {
    host := l.CheckString(1)          // Lua es 1-indexed, no 0-indexed
    port := uint64(l.CheckInt64(2))
    path := l.CheckString(3)

    url := fmt.Sprintf("http://%s:%d/%s", host, port, path)
    resp, err := http.Head(url)
    if err != nil {
        l.Push(lua.LNumber(0))                    // status 0 = error
        l.Push(lua.LBool(false))
        l.Push(lua.LString(err.Error()))
        return 3                                  // 3 valores devueltos a Lua
    }
    defer resp.Body.Close()
    l.Push(lua.LNumber(resp.StatusCode))
    l.Push(lua.LBool(resp.Header.Get("WWW-Authenticate") != ""))
    l.Push(lua.LString(""))
    return 3
}
```

<mark style="background: #ADCCFFA6;">`LState` es la VM: contiene los parámetros de entrada y los valores de retorno</mark>. Lees con `l.CheckString(n)` / `l.CheckInt64(n)` (ojo: **Lua indexa desde 1**), y devuelves empujando con `l.Push` valores que cumplen `lua.LValue` (`LNumber`, `LBool`, `LString`). El `int` de retorno es el número de valores que el script Lua podrá leer.

## Registrar el façade y ejecutar el script

Expones las funciones bajo un *namespace* con una metatable, y luego ejecutas el `.lua`:

```go
func register(l *lua.LState) {
    mt := l.NewTypeMetatable("http")
    l.SetGlobal("http", mt)
    l.SetField(mt, "head", l.NewFunction(head))   // http.head(...)
    l.SetField(mt, "get", l.NewFunction(get))     // http.get(...)
}

func main() {
    l := lua.NewState()
    defer l.Close()
    register(l)

    files, err := os.ReadDir(pluginsDir)          // os.ReadDir, no ioutil
    if err != nil {
        log.Fatal(err)
    }
    for _, f := range files {
        if err := l.DoFile(filepath.Join(pluginsDir, f.Name())); err != nil {
            log.Printf("plugin %s falló: %v", f.Name(), err)
        }
    }
}
```

`DoFile` ejecuta el script entero dentro de la VM ya cargada con tu façade. El plugin Lua entonces llama a `http.head(...)` y `http.get(...)` como si fueran nativas:

```lua
status, basic, err = http.head("10.0.1.20", 8080, "/manager/html")
if status ~= 401 or not basic then return end
for _, user in ipairs(usernames) do
    for _, pass in ipairs(passwords) do
        status = http.get("10.0.1.20", 8080, user, pass, "/manager/html")
        if status == 200 then print("[+] creds: "..user..":"..pass); return end
    end
end
```

## El trade-off y el contexto 2026

> [!important]+ Portabilidad a cambio de complejidad
> <mark style="background: #8000E1A6;">El precio de que el plugin sea un script portable es escribir el façade</mark>: exponer cada función Go que el plugin necesite, pasando tipos primitivos de ida y vuelta. El ejemplo devuelve `(status, basic, err)` como tres primitivos; un façade serio expondría *user-defined types* que envuelvan `http.Request`/`http.Response` — más trabajo, pero API más limpia. Esa fricción (traducir cada tipo Go al mundo Lua) es inherente al *embedding*.

> [!warning]+ Ejecutar plugins de terceros es superficie de ataque
> Un plugin Lua corre con **los permisos de tu proceso** y gopher-lua no *sandboxea* por defecto: un plugin malicioso puede llamar a cualquier función que hayas expuesto. Si cargas plugins que no controlas, limita el façade al mínimo y considera **WASM** (`wazero`), que sí aísla el plugin sin acceso a disco/red por defecto — el enfoque moderno para plugins no confiables (ver [[01 - El sistema de plugins nativo de Go|la nota anterior]]). Para plugins propios, Lua sigue siendo pragmático: es exactamente lo que usa el motor de scripts NSE de [[00 - Introducción a Nmap|Nmap]].

Con esto cierras el bloque de extensibilidad: interfaces como contrato, el plugin nativo y sus límites, y el scripting embebido. El siguiente tema baja al detalle de la criptografía en Go → carpeta `10 - Criptografía`.
