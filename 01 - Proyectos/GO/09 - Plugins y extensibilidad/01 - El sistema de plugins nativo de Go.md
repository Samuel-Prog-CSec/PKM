---
tags:
  - Go
  - Go/Plugins
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - Interfaces como contrato de plugins]]"
Nota siguiente: "[[02 - Plugins con Lua embebido]]"
Area: "[[Plugins y extensibilidad.base|Plugins y extensibilidad]]"
---
---

El contrato de interfaz de [[00 - Interfaces como contrato de plugins]] ya te da extensibilidad compilando todo junto. El paquete `plugin` de Go añade una cosa más: cargar plugins de ficheros `.so` **en runtime**, sin recompilar el binario. Suena ideal para un framework — y es donde el libro (2020) se queda corto: en 2026 el `plugin` nativo casi no se usa en producción, y conviene saber por qué.

## El mecanismo

Compilas el plugin como *shared object* con un `buildmode` especial:

```shell-session
$ go build -buildmode=plugin -o /ruta/plugins/tomcat.so
```

El core carga cada `.so`, busca el símbolo `New`, lo convierte al tipo esperado y lo ejecuta:

```go
func main() {
    files, err := os.ReadDir(pluginsDir)          // os.ReadDir, no ioutil (deprecado)
    if err != nil {
        log.Fatal(err)
    }
    for _, f := range files {
        p, err := plugin.Open(filepath.Join(pluginsDir, f.Name()))   // 1: abre el .so
        if err != nil {
            log.Printf("no se pudo abrir %s: %v", f.Name(), err)
            continue
        }
        sym, err := p.Lookup("New")               // 2: busca el símbolo exportado
        if err != nil {
            log.Printf("%s no exporta New: %v", f.Name(), err)
            continue
        }
        newFunc, ok := sym.(func() scanner.Checker)   // 3: type assertion al contrato
        if !ok {
            log.Printf("%s: New tiene firma inesperada", f.Name())
            continue
        }
        res := newFunc().Check("10.0.1.20", 8080)     // 4: instancia y ejecuta
        if res.Vulnerable {
            log.Printf("[+] vulnerable: %s", res.Details)
        }
    }
}
```

Los cuatro pasos —`Open`, `Lookup`, *type assertion*, invocar— son toda la API. <mark style="background: #ADCCFFA6;">El `Lookup("New")` exige un nombre de símbolo acordado</mark>: por eso la convención de [[00 - Interfaces como contrato de plugins|la nota anterior]] (todos exportan `New`). La *type assertion* con `, ok` es obligatoria — sin ella, un plugin con firma equivocada haría *panic* en vez de saltarse limpiamente (nota [[10 - Interfaces]]).

> [!warning]+ Modernización: `ioutil.ReadDir` → `os.ReadDir`
> El libro usa `ioutil.ReadDir`, deprecado desde Go 1.16. `os.ReadDir` lo sustituye y devuelve `[]os.DirEntry` (más eficiente, no hace `stat` de cada fichero). Y maneja el error de cada plugin con `continue`, no `log.Fatalln`: <mark style="background: #FFB8EBA6;">un plugin roto no debe abortar la carga de los demás</mark>.

El plugin en sí implementa `Check`. El ejemplo del libro es un `TomcatChecker` que hace *password guessing* contra el Tomcat Manager (la técnica a fondo → [[01 - Ataques a Tomcat]] y [[00 - Introducción al brute forcing]]) — pero recuerda cerrar el `resp.Body` en cada intento (`defer` por iteración) para no filtrar conexiones, algo que el código original olvida.

## Por qué casi nadie usa esto en producción

> [!fail]+ El paquete `plugin` es notoriamente frágil
> Sus restricciones lo hacen inviable para la mayoría de frameworks reales:
> - <mark style="background: #FF5582A6;">El plugin y el host deben compilarse con **exactamente** la misma versión de Go, las mismas versiones de todas las dependencias comunes y los mismos flags de build.</mark> Un desajuste y `plugin.Open` falla en runtime. Distribuir plugins compilados por terceros es casi imposible.
> - Solo funciona en **Linux y macOS**. En Windows no hay plugins nativos (el `-buildmode=c-shared` genera una DLL C, que es otra cosa — se carga como se ve en el bloque de Windows).
> - **No se pueden descargar** (*unload*) una vez cargados.
>
> El resultado: el `plugin` nativo sirve para un tool propio donde tú controlas toda la cadena de build, y poco más.

## Las alternativas modernas (2026)

Lo que se usa hoy para tooling extensible en Go:

- **`hashicorp/go-plugin`** — plugins como **subprocesos** que hablan por gRPC/RPC. Es el estándar de facto: lo usan Terraform, Vault, Nomad y Consul sobre millones de máquinas. <mark style="background: #FFB86CA6;">Aísla cada plugin en su propio proceso</mark>, así que un plugin que crashea (o es malicioso) no tumba el host, y funciona en cualquier OS y con cualquier versión de Go. Es el modelo RPC que ya viste en [[02 - RPC con Metasploit (MessagePack)]]. Contra: solo red local fiable.
- **WASM con `wazero`** — plugins compilados a WebAssembly, ejecutados en un runtime Go puro y **sandboxed** (sin acceso a disco ni red por defecto). Portables, *cross-compilan* sin dolor y son *memory-safe*. Es la tendencia 2026: `wazero` mueve los plugins de Trivy, Cilium, k6 y Tetragon. Contra: WASI sigue en borrador — para dar red al plugin expones *host functions* controladas.

Para un framework de seguridad nuevo hoy, la elección real es **go-plugin** (aislamiento por proceso, RPC) o **WASM** (sandbox fuerte, portabilidad), no `buildmode=plugin`.

> [!info]+ Fuentes
> Estado del ecosistema verificado en [pkg.go.dev/github.com/hashicorp/go-plugin](https://pkg.go.dev/github.com/hashicorp/go-plugin) y [github.com/knqyf263/go-plugin](https://github.com/knqyf263/go-plugin) (WASM sobre wazero), julio 2026.

Hay una tercera vía que sí *cross-compila* y existía antes que el `plugin` nativo: embeber un intérprete de scripting → [[02 - Plugins con Lua embebido]].
