---
tags:
  - Go
  - Go/Arsenal
  - Evasion
  - OPSEC
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - Herramientas del ecosistema Go ofensivo]]"
Nota siguiente: ""
Area: "[[Arsenal y OPSEC.base|Arsenal y OPSEC]]"
---
---

El binario estático que hace a Go cómodo para tooling tiene una contrapartida: <mark style="background: #ADCCFFA6;">es grande y deja una huella muy reconocible</mark>. Un ejecutable Go se identifica como tal casi de un vistazo, y arrastra metadata que puede llevar de vuelta a quien lo compiló. Reducir esa huella —sin pretender hacerlo invisible— es la parte de OPSEC transversal a todo el proyecto.

## Compilar más pequeño y más limpio

Dos flags que deberían ser el estándar al compilar cualquier implante o tool que vaya a un objetivo:

```shell-session
$ go build -ldflags="-s -w" -trimpath -o tool implant.go
```

- **`-ldflags="-s -w"`** — `-s` quita la tabla de símbolos y `-w` la info de depuración DWARF. <mark style="background: #FFB86CA6;">Reduce el tamaño ~25% y dificulta el *disassembly* y el *debugging*</mark> del binario.
- **`-trimpath`** — elimina las rutas absolutas del sistema de compilación embebidas en el binario. Sin esto, tu `/home/tu-usuario/proyectos/implante-malo/...` queda dentro del ejecutable — atribución directa a ti. El libro avisa de esto en su sección de OPSEC.

Y para el binario **verdaderamente** estático y portable:

```shell-session
$ CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -trimpath
```

`CGO_ENABLED=0` fuerza un binario sin dependencia de `libc` (nada de enlace dinámico), y `GOOS`/`GOARCH` **cross-compilan** para cualquier objetivo desde tu máquina. El precio: sin CGO pierdes lo que necesita C (la WinAPI vía C de [[03 - CGO - mezclar C y Go]], por ejemplo) — para eso hay que compilar con CGO en la plataforma destino.

## La huella que queda (y por qué)

> [!warning]+ Un binario Go grita "soy Go"
> Aunque hagas *strip*, el binario sigue siendo identificable. Los defensores lo saben:
> - **`gopclntab`**: la tabla de líneas/funciones que el runtime de Go necesita. Es una firma inconfundible de binario Go y, peor aún, <mark style="background: #FF5582A6;">permite reconstruir nombres de función incluso después de un *strip*</mark> — herramientas como `GoReSym` la explotan para des-anonimizar.
> - **Build info embebida**: `go version -m <binario>` extrae la versión de Go, los módulos y hasta los *build settings*. `-ldflags` no lo borra todo.
> - **Tamaño y secciones**: ~2 MB de base (el runtime va dentro), strings del scheduler/GC, layout de secciones reconocible.
>
> Los EDR y los analistas perfilan binarios Go precisamente por estas marcas.

## Ofuscar más allá del strip

Para reducir las firmas de strings y símbolos que quedan tras el *strip*, la herramienta del ecosistema es **`garble`** (`mvdan.cc/garble`):

```shell-session
$ garble -literals -tiny build -o tool implant.go
```

`garble` renombra paquetes y símbolos a basura, ofusca los literales de string (`-literals`) y elimina metadata (`-tiny`). <mark style="background: #8000E1A6;">Sube bastante el listón del análisis estático</mark> — pero no borra `gopclntab` del todo ni convierte el binario en "no-Go". Es una capa, no una solución.

> [!important]+ El límite honesto
> *Strip*, `-trimpath`, `CGO_ENABLED=0` y `garble` son higiene de compilación: menos atribución, menos firmas triviales, análisis más costoso. **No** hacen que un implante Go evada un EDR moderno — eso es un problema distinto (cifrado de payloads, ejecución en memoria, *unhooking*) cuya metodología operativa vive en Red Team, no aquí. La lección de este proyecto es la contraria y más útil: entender **qué** deja cada binario (la huella de [[01 - Process injection clásica]], el shellcode plano de [[04 - Shellcode Go-friendly con msfvenom]], el tráfico en claro de [[02 - Implante, admin y endurecer el RAT]]) para saber exactamente qué estás exponiendo.

Con esto cierras el proyecto de Go ofensivo: de los fundamentos del lenguaje a un C2 completo, con las herramientas para construir, las que ya existen, y la conciencia de la huella que todo ello deja. El siguiente paso ya no es leer — es escribir tu propia tool para un problema que ninguna resuelve.
