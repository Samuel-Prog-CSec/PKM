---
tags:
  - Go
  - Go/Fundamentos
  - Herramientas
Fecha de actualización: 2026-07-22
Nota previa: "[[00 - Por qué Go para el hacking]]"
Nota siguiente: "[[02 - Toolchain y compilación]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

*Black Hat Go* monta el entorno con `GOROOT`, `GOPATH` y un *workspace* de tres carpetas (`bin`, `pkg`, `src`). Eso está **muerto desde Go 1.16**. El Go moderno se organiza con **módulos**, y tu proyecto puede vivir en cualquier carpeta del disco. Esta nota deja un entorno de 2026 listo para compilar tooling.

## Instalar Go

Descarga el binario oficial de [go.dev/dl](https://go.dev/dl/) — la versión estable actual es **Go 1.26** (febrero 2026). En Kali/Debian el `apt` suele ir por detrás; para tooling ofensivo interesa la última, así que baja el tarball oficial en lugar del paquete de la distro.

```shell-session
$ go version
go version go1.26 linux/amd64
$ go env GOROOT GOPATH GOBIN
/usr/local/go
/home/kali/go

```

> [!warning]+ El paso `GOROOT` del libro sobra
> No definas `GOROOT` a mano: el toolchain detecta su propia ubicación. Fijarlo manualmente solo genera builds rotos si algún día actualizas Go y olvidas cambiar la variable. Fuente: [go.dev/doc/install](https://go.dev/doc/install).

## Módulos: el cambio de fondo frente al libro

<mark style="background: #ADCCFFA6;">Un **módulo** es un árbol de paquetes Go versionado, definido por un archivo `go.mod` en su raíz.</mark> Es la unidad de dependencias y versiones desde Go 1.11, y el modo **por defecto** desde Go 1.16. Sustituye por completo al *workspace* `GOPATH/src` del libro.

Arrancar un proyecto nuevo son dos comandos:

```shell-session
$ mkdir miscanner && cd miscanner
$ go mod init github.com/tuusuario/miscanner
go: creating new go.mod: module github.com/tuusuario/miscanner
```

Eso crea el `go.mod`:

```go.mod
module github.com/tuusuario/miscanner

go 1.26
```

<mark style="background: #8000E1A6;">La carpeta del proyecto puede estar donde quieras</mark> — `~/tools/`, `/opt/`, un pendrive — ya no bajo `GOPATH/src`. La ruta del módulo (`github.com/tuusuario/miscanner`) es un **identificador**, no una ubicación en disco; solo tiene que coincidir con la URL del repo si algún día lo publicas.

Cuando importas una dependencia externa y compilas, Go la añade a `go.mod` y escribe su *checksum* en `go.sum`:

```shell-session
$ go get github.com/projectdiscovery/goflags@latest
$ go mod tidy      # añade lo que falta, elimina lo que sobra
```

> [!important]+ `go.sum` se commitea siempre
> `go.sum` guarda el hash criptográfico de cada versión de cada dependencia. `go mod verify` detecta si un proxy comprometido te sirvió código manipulado — es tu defensa de *supply chain*. Sin `go.sum` en el repo, esa verificación no existe. Fuente: [go.dev/ref/mod#go-sum-files](https://go.dev/ref/mod).

## Qué queda de `GOPATH`

`GOPATH` sigue existiendo (por defecto `~/go`), pero <mark style="background: #FFB8EBA6;">ya solo sobrevive como dos cachés, no como *workspace* de código</mark>:

- `$GOPATH/pkg/mod` — caché de módulos descargados (las dependencias de todos tus proyectos).
- `$GOPATH/bin` — donde aterrizan los binarios que instalas con `go install` (o `$GOBIN` si lo defines). Conviene tenerlo en el `PATH`.

No crees `$GOPATH/src` ni metas ahí tu código. <mark style="background: #FF5582A6;">Si una guía te dice "pon tu proyecto en `GOPATH/src`", es de antes de 2020 — ignórala.</mark>

## Estructura de un proyecto ofensivo

Ajusta la estructura al tamaño. Un escáner de 100 líneas es **un solo `main.go` plano**; no le metas capas ni `cmd/internal` porque sí.

Cuando la herramienta crece (varios subcomandos, lógica reutilizable), la convención es:

```text
miscanner/
├── go.mod
├── go.sum
├── main.go              # herramienta pequeña: todo aquí
└── (al crecer)
    ├── cmd/
    │   └── miscanner/
    │       └── main.go  # solo: parsear flags y llamar a Run()
    └── internal/
        └── scan/
            └── scan.go  # lógica privada, no importable desde fuera
```

`internal/` es especial: el compilador **prohíbe** importarlo desde otros módulos, así que es el sitio natural para la lógica de un implante que no quieres exponer como librería. `pkg/` solo si de verdad publicas código reutilizable.

## Instalar herramientas Go (montar el arsenal)

Aquí hay otro cambio grande respecto al libro. `go get` **ya no instala binarios** (desde Go 1.17); ahora solo gestiona dependencias del módulo. Para instalar una herramienta se usa `go install` con versión explícita:

```shell-session
$ go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
$ go install github.com/ffuf/ffuf/v2@latest
$ go install github.com/projectdiscovery/httpx/cmd/httpx@latest
```

El binario cae en `$GOPATH/bin`. Así montas buena parte de tu arsenal (ver [[00 - Arsenal Go ofensivo]]) sin `git clone` ni `make`. El `@latest`/`@v3.x.x` fija exactamente qué versión compilas — reproducible y auditable.

Para **fijar las herramientas que usa tu propio proyecto** (linters, `govulncheck`), Go 1.24+ usa directivas `tool` en el `go.mod` en vez del viejo truco `tools.go`:

```shell-session
$ go get -tool golang.org/x/vuln/cmd/govulncheck@latest
$ go tool govulncheck ./...
```

## Editor y servidor de lenguaje

El libro repasa Vim/Atom/VS Code/GoLand. En 2026 lo que importa es que todos hablan con **`gopls`**, el *language server* oficial de Go: autocompletado, diagnósticos, ir-a-definición y *refactors* seguros. Instálalo una vez (`go install golang.org/x/tools/gopls@latest`) y tu editor —VS Code con la extensión Go, Neovim, GoLand— lo consume. Atom, que el libro recomienda, está **descontinuado desde 2022**; no lo uses.

## El coste OPSEC empieza aquí

Cada binario que compilas lleva incrustada su **información de build**: ruta del módulo, versión de Go, lista de dependencias y datos de VCS. <mark style="background: #FFB86CA6;">Cualquiera con acceso al binario recupera todo eso con un comando</mark>:

```shell-session
$ go version -m nuclei
nuclei: go1.26
        path    github.com/projectdiscovery/nuclei/v3/cmd/nuclei
        mod     github.com/projectdiscovery/nuclei/v3   v3.x.x
        ...
```

Para un implante eso es un regalo al equipo azul: revela tu estructura de proyecto y tu toolchain. Se recorta en compilación (`-trimpath`, `-buildvcs=false`, `-ldflags "-s -w"`), tema que se trata a fondo en [[01 - OPSEC y detección de binarios Go]]. De momento, quédate con que **el entorno moderno también deja rastro** y que el siguiente paso es dominar el toolchain de compilación: [[02 - Toolchain y compilación]].
