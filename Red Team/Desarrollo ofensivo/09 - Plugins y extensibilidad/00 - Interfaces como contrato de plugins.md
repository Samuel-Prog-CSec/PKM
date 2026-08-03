---
tags:
  - Go
  - Go/Plugins
  - Tipo/Introduccion
Descripción: "Muchas herramientas de seguridad se construyen como frameworks: un núcleo estable y una capa de plugins que crece sin reescribir el core"
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - El sistema de plugins nativo de Go]]"
Area: "[[Plugins y extensibilidad.base|Plugins y extensibilidad]]"
---
---

Muchas herramientas de seguridad se construyen como **frameworks**: un núcleo estable y una capa de plugins que crece sin reescribir el core. Es lo que ha mantenido vivo a Metasploit ([[00 - Introducción a Metasploit]]) y lo que hace Nessus con sus *signature checks* ([[00 - Introducción a Nessus]]). En Go, el mecanismo que hace esto posible no es el paquete `plugin` — es la **interfaz**. Entender el contrato antes que el mecanismo de carga es lo que separa un framework limpio de un amasijo de `if`.

## El contrato: una interfaz pequeña

Diseñas un escáner de vulnerabilidades donde cada check es un plugin. El core define **qué** debe cumplir un plugin, sin saber **cómo** lo hace, con una interfaz de un solo método:

```go
package scanner

// Checker: contrato que todo plugin de vulnerabilidad debe cumplir.
type Checker interface {
    Check(host string, port uint64) *Result
}

// Result: salida de un check.
type Result struct {
    Vulnerable bool
    Details    string
}
```

<mark style="background: #ADCCFFA6;">La interfaz es el *blueprint*</mark>: un plugin implementa `Check` como quiera —peticiones HTTP para un check de deserialización, fuerza bruta para uno de credenciales SSH— mientras devuelva un `*Result`. Un método, cero acoplamiento entre plugins.

> [!important]+ "The bigger the interface, the weaker the abstraction"
> `Checker` tiene **un** método a propósito. Las interfaces Go idiomáticas son de 1-3 métodos (como `io.Reader`, `io.Writer`): <mark style="background: #FFB8EBA6;">cuanto más pequeña la interfaz, más fácil de implementar y más plugins encajan</mark>. Una interfaz de 8 métodos ahuyenta a los autores de plugins y acopla el core a detalles que no necesita. Si un plugin necesitara más superficie, se compone de interfaces pequeñas — no se engorda una grande.

## Dos principios que sostienen el diseño

**Accept interfaces, return structs.** El core (consumidor) define y **acepta** la interfaz `Checker`; cada plugin **devuelve** su tipo concreto. Es la regla idiomática de Go (nota [[10 - Interfaces]]): el que consume manda el contrato, el que implementa aporta el struct.

**La interfaz se define donde se consume.** `Checker` vive en el paquete `scanner` (el core), no en cada plugin. Los plugins **importan** el core para conocer el contrato; el core no sabe nada de ningún plugin concreto. <mark style="background: #8000E1A6;">La dependencia va del plugin al core, nunca al revés</mark> — por eso puedes añadir plugins sin tocar una línea del escáner.

## El punto de entrada: una factory `New()`

El core necesita instanciar cada plugin de forma uniforme. La convención: cada plugin exporta una función `New()` que devuelve un `Checker`:

```go
// En el plugin:
type TomcatChecker struct{}

func (c *TomcatChecker) Check(host string, port uint64) *scanner.Result {
    // ...lógica de check específica...
}

// Compile-time check: si TomcatChecker deja de cumplir Checker, no compila.
var _ scanner.Checker = (*TomcatChecker)(nil)

func New() scanner.Checker { return &TomcatChecker{} }
```

Esa `New() scanner.Checker` es el **API publicado** entre core y plugins: el core sabe que, sea cual sea el plugin, tendrá un `New` que devuelve algo con `Check`. La línea `var _ scanner.Checker = (*TomcatChecker)(nil)` es un patrón Go clave: <mark style="background: #FF5582A6;">verifica en tiempo de compilación</mark> que el tipo cumple la interfaz, sin coste en runtime — si mañana cambias la firma de `Check`, el build falla en el acto en vez de petar al cargar el plugin.

## El diseño no necesita carga dinámica

Lo más importante de todo: <mark style="background: #FFB86CA6;">este patrón funciona compilando todo junto</mark>. Registras los plugins en un slice y listo:

```go
var registry = []scanner.Checker{
    tomcat.New(),
    ssh.New(),
    // ...añadir un check = una línea aquí...
}
for _, chk := range registry {
    res := chk.Check(host, port)
    // ...
}
```

Ni `.so`, ni `plugin.Open`, ni reflexión. La interfaz **ya** te da extensibilidad. Cargar plugins de ficheros externos en runtime —para no recompilar el binario al añadir un check— es lo que aporta el paquete `plugin` de Go, con un coste en fragilidad que veremos a fondo → [[01 - El sistema de plugins nativo de Go]].
