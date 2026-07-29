---
tags:
  - Go
  - Go/Fundamentos
  - Introduccion
  - Tipo/Introduccion
Descripción: "Go es el lenguaje que vas a aprender para construir tu propio arsenal ofensivo"
Fecha de actualización: 2026-07-21
Nota previa: 
Nota siguiente: "[[01 - Entorno moderno y módulos]]"
Area: "[[Fundamentos de Go.base|Fundamentos de Go]]"
---
---

Go es el lenguaje que vas a aprender para construir tu propio arsenal ofensivo. Este primer bloque enseña **Go moderno (2026) desde cero**; los bloques siguientes lo aplican a proyectos reales de red team siguiendo *Black Hat Go*. No necesitas saber Go previamente, pero sí manejar la terminal y conceptos básicos de programación.

## Qué es Go

<mark style="background: #ADCCFFA6;">Go (o Golang) es un lenguaje compilado, de tipado estático y con recolección de basura, creado en Google (Griesemer, Pike, Thompson) para escribir software de red concurrente y desplegable como un único binario.</mark> Junta la velocidad de un compilado tipo C con una ergonomía cercana a la de Python: sintaxis pequeña, herramientas integradas y una librería estándar enorme.

## Por qué Go para tooling ofensivo

No es casualidad que tanto tooling moderno esté en Go. Cinco razones que importan a un pentester:

- **Binario único y estático.** `go build` produce un ejecutable autocontenido: sin intérprete, sin runtime que instalar, sin dependencias en el objetivo. <mark style="background: #FFB86CA6;">Copias un solo archivo a la máquina víctima y corre</mark> — nada de "instala Python y estas 12 librerías". Para un implante o una herramienta que dejas en un host comprometido, esto es decisivo.
- **Cross-compilation trivial.** Con las variables `GOOS`/`GOARCH` compilas desde tu Kali un `.exe` para Windows x64, un binario para ARM o para macOS, <mark style="background: #FFB86CA6;">sin instalar ningún toolchain cruzado</mark> (detalle en [[02 - Toolchain y compilación]]).
- **Librería estándar rica y orientada a red.** `net`, `net/http`, `crypto/*`, `encoding/*` (JSON, XML, base64, hex), `os/exec`… vienen de serie. Escribes un escáner TCP, un cliente HTTP o cifras con AES-GCM sin una sola dependencia externa. Menos dependencias = menos fricción y menos superficie que falle.
- **Concurrencia nativa.** Las *goroutines* y los *channels* (ver [[13 - Goroutines, channels y concurrencia]]) hacen que un escáner concurrente de miles de puertos quepa en 20 líneas. El modelo se diseñó para multicore desde el principio.
- **Compilado y con tipado estático.** Los errores de tipo saltan al compilar, no en mitad de un engagement. Y el binario corre a velocidad nativa: un fuzzer o un brute-forcer en Go vuela frente a su equivalente en Python.

## El ecosistema ofensivo ya es Go

<mark style="background: #FFB8EBA6;">Buena parte del tooling ofensivo moderno está escrito en Go.</mark> La suite de ProjectDiscovery (`nuclei`, `httpx`, `naabu`, `subfinder`), `gobuster`, `ffuf`, el framework C2 `Sliver`, y herramientas de pivoting que ya usas — [[09 - SOCKS tunneling con Chisel|Chisel]] y [[13 - Pivoting moderno con Ligolo-ng|Ligolo-ng]]. Aprender Go no es solo escribir lo tuyo: es poder **leer, modificar y extender** ese arsenal. El mapa completo de herramientas está en [[00 - Arsenal Go ofensivo]].

## El coste: OPSEC

No es gratis. <mark style="background: #FF5582A6;">Los binarios Go son grandes (varios MB) y muy fingerprintables</mark>: el runtime, el `Go build ID` y la tabla de símbolos dejan una firma que EDR y reglas YARA detectan con facilidad. En un engagement real hay que reducir y ofuscar el binario (`-ldflags "-s -w"`, `garble`), algo que se trata a fondo en [[01 - OPSEC y detección de binarios Go]]. El otro coste es la verbosidad: un one-liner de Python puede convertirse en tres líneas de Go — a cambio de claridad y rendimiento.

> [!info]+ Fuente y filosofía de este curso
> Basado en *Black Hat Go* (Steele, Patten, Kottmann; No Starch Press, 2020) y su repo oficial [github.com/blackhat-go/bhg](https://github.com/blackhat-go/bhg). El libro prioriza explícitamente "function over elegance" y usa **Go 1.11**. Este curso hace lo contrario: enseña **Go idiomático y moderno** (módulos, `any`, `errors.Is`, `log/slog`, `context`, genéricos) y **moderniza cada herramienta**. Cuando el libro use algo obsoleto (`GOPATH`, `golint`, `google/gopacket`…), lo verás señalado con un aviso y la alternativa actual.

El siguiente paso es montar el entorno: [[01 - Entorno moderno y módulos]].
