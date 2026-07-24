---
tags:
  - Go
  - Go/Fundamentos
  - Compilacion
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Entorno moderno y módulos]]"
Nota siguiente: "[[03 - Tipos, variables y constantes]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

El comando `go` **es** todo el toolchain en un solo binario: compilador, gestor de dependencias, formateador, tester y analizador. La nota anterior cubrió los módulos y cómo instalar herramientas; esta cubre lo que de verdad convierte a Go en un lenguaje de tooling ofensivo: <mark style="background: #ADCCFFA6;">un solo `go build` produce un binario estático para cualquier sistema operativo y arquitectura</mark>, y los *flags* de compilación deciden la huella que ese binario deja.

## El ciclo de desarrollo

Cuatro comandos cubren el 90% del día a día:

```shell-session
$ go run main.go        # compila a un binario temporal y lo ejecuta (solo dev)
$ go build -o scan ./cmd/scan   # compila el módulo -> binario nombrado, no lo instala
$ go test ./...         # ejecuta los tests de todo el módulo
$ go vet ./...          # análisis estático: detecta construcciones sospechosas
```

`go run` compila a un binario temporal y lo lanza — cómodo para iterar, pero <mark style="background: #FFB8EBA6;">en el objetivo tú despliegas el binario de `go build`</mark>, no ejecutas `go run`. `gofmt` (o `go fmt ./...`) formatea el código a un estilo canónico único: en Go no se discute sobre llaves ni indentación, lo decide la herramienta.

> [!info]+ El libro delata su edad
> El libro muestra `go doc fmt.Println` devolviendo `func Println(a ...interface{})`. Desde Go 1.18 esa firma se lee `func Println(a ...any)`. `interface{}` y `any` son idénticos, pero `any` es el idiom moderno (ver [[10 - Interfaces]]). Detalles como este marcan que el material es de 2019.

## `go build`: del código al binario

`go build` compila tu módulo y todas sus dependencias en **un único ejecutable**, sin instalarlo. La clave para tooling: <mark style="background: #8000E1A6;">un binario Go puro es estático por defecto</mark> — no depende de `libc` ni de ningún runtime en el objetivo. Por eso copias un archivo y corre en un host recién comprometido sin instalar nada (idea de [[00 - Por qué Go para el hacking]]).

La excepción es **cgo**: si importas C, o paquetes que en ciertos SO usan el *resolver* de `libc` (`os/user`, a veces `net`), el binario se enlaza dinámicamente. `CGO_ENABLED=0` fuerza un build 100% Go, estático y portable:

```shell-session
$ CGO_ENABLED=0 go build -o scan ./cmd/scan
$ file scan
scan: ELF 64-bit LSB executable, x86-64, statically linked, not stripped
```

## Cross-compilation: compila para el objetivo, no para tu Kali

Aquí está la ventaja que "ningún otro lenguaje hace tan fácil" (palabras del propio libro, y sigue siendo verdad). Defines dos variables de entorno y compilas para cualquier plataforma **sin instalar un toolchain cruzado**:

```shell-session
$ GOOS=windows GOARCH=amd64 go build -o svc.exe ./cmd/implant   # .exe Windows x64 desde Linux
$ GOOS=linux   GOARCH=arm64 go build -o agent    ./cmd/implant  # Linux ARM64 (routers, IoT, cloud)
$ GOOS=darwin  GOARCH=arm64 go build -o agent    ./cmd/implant  # macOS Apple Silicon
$ go tool dist list                                             # todas las combinaciones válidas
```

| `GOOS` | `GOARCH` | Objetivo típico |
| - | - | - |
| `windows` | `amd64` | Workstations/servidores Windows x64 |
| `windows` | `386` | Windows x86 legacy |
| `linux` | `amd64` | Servidores Linux |
| `linux` | `arm64` | Routers, dispositivos IoT, instancias cloud ARM |
| `darwin` | `arm64` | macOS Apple Silicon |

> [!warning]+ El único "gotcha" de cross-compilar sigue siendo cgo
> Si tu herramienta usa cgo, la cross-compilation deja de ser trivial: necesitas un toolchain de C cruzado (`mingw-w64` para Windows, `zig cc` como atajo moderno). <mark style="background: #FF5582A6;">Mantén tu tooling libre de cgo (`CGO_ENABLED=0`) siempre que puedas</mark> y conservarás la cross-compilation de un solo comando. Fuente: [go.dev/wiki/cgo](https://go.dev/wiki/cgo).

## Flags de compilación que importan en un engagement

Los mismos `-ldflags "-w -s"` que el libro presenta solo para "reducir tamaño" son, en realidad, la base de tu higiene OPSEC. Lo que embebe el compilador por defecto es un regalo para el equipo azul:

| Flag | Qué hace | Por qué importa |
| - | - | - |
| `-ldflags "-s -w"` | Elimina tabla de símbolos (`-s`) y debug DWARF (`-w`) | ~25-30% menos tamaño y bastante más difícil de reversear |
| `-trimpath` | Borra rutas absolutas del disco del binario | Si no, tu `/home/kali/tools/implant/...` viaja dentro del `.exe` |
| `-buildvcs=false` | Quita commit, rama y estado de git (embebidos desde Go 1.18) | Evita filtrar tu repo y tu flujo de trabajo |
| `-ldflags "-H windowsgui"` | Marca el binario como subsistema GUI en Windows | <mark style="background: #FFB86CA6;">No abre ventana de consola al ejecutarse</mark> — clave en un implante |

Todo junto, un build de implante Windows con higiene mínima:

```shell-session
$ GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build \
    -trimpath -buildvcs=false \
    -ldflags "-s -w -H windowsgui" \
    -o svc.exe ./cmd/implant
```

> [!important]+ Esto es higiene, no evasión
> Un binario Go sigue siendo grande y muy *fingerprintable* aunque lo strippes: el `Go build ID`, la `moduledata` y las cadenas del runtime dejan firma que YARA y EDR reconocen. El recorte y ofuscación de verdad (`garble` para símbolos y strings; por qué **no** usar UPX) es el tema de [[01 - OPSEC y detección de binarios Go]]. Aquí solo dejas de sangrar información gratis.

## Linting moderno: `golint` ha muerto

El libro recomienda `golint`. <mark style="background: #FF5582A6;">El equipo de Go lo deprecó y archivó el repositorio en 2020</mark> — está congelado, no lo instales. El stack de análisis estático de 2026:

- **`go vet`** — integrado en el toolchain, caza bugs reales (verbos de `Printf` incorrectos, copia de mutexes, etc.).
- **`staticcheck`** — el estándar de facto, cientos de checks. `go install honnef.co/go/tools/cmd/staticcheck@latest`.
- **`golangci-lint` v2** — *meta-runner* que agrupa `go vet`, `staticcheck`, `modernize` y más; el estándar en CI.
- **`gopls`** — el language server (nota [[01 - Entorno moderno y módulos]]) ejecuta muchos de estos checks en vivo en tu editor.
- **`go fix`** — reescrito en Go 1.26 para aplicar automáticamente modernizaciones del lenguaje.

```shell-session
$ go vet ./...
$ staticcheck ./...
$ golangci-lint run
```

Con el toolchain dominado, toca el lenguaje en sí. Empezamos por lo más básico: los tipos y cómo se declaran las variables → [[03 - Tipos, variables y constantes]].
