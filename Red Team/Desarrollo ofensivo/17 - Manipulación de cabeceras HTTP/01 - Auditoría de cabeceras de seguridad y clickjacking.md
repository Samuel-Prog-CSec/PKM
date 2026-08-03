---
tags:
  - Go
  - Go/Web
  - HTTP
Descripción: "Las cabeceras de respuesta que faltan son hallazgos"
Fecha de actualización: 2026-07-26
Nota previa: "[[00 - Testing de métodos HTTP y fingerprinting]]"
Nota siguiente: "[[02 - Cookies inseguras y session fixation]]"
Area: "[[Manipulación de cabeceras HTTP.base|Manipulación de cabeceras HTTP]]"
---
---

Las cabeceras de respuesta que **faltan** son hallazgos. Sin `Content-Security-Policy` el XSS no tiene freno; sin `Strict-Transport-Security` cabe el downgrade a HTTP; sin control de framing, la página se embebe en un iframe atacante → clickjacking. La teoría de cada defensa vive en Red Team ([[08 - Clickjacking]], [[04 - Content Security Policy (CSP)]]); aquí el auditor en Go.

> [!info]+ Fuente
> Recetas "Testing for insecure headers" y "Testing for clickjacking vulnerabilities" de *Python Web Penetration Testing Cookbook* (2015), con el set de cabeceras actualizado a 2026.

## Auditar el set de seguridad

Recorres las cabeceras esperadas y marcas ausencias y valores débiles:

```go
type Audit struct {
    Header  string
    Value   string
    Issue   string   // vacío = OK
}

func auditSecurityHeaders(h http.Header) []Audit {
    var out []Audit
    add := func(name, whenMissing string, eval func(string) string) {
        v := h.Get(name)
        switch {
        case v == "":
            out = append(out, Audit{name, "", whenMissing})
        case eval != nil:
            if issue := eval(v); issue != "" {
                out = append(out, Audit{name, v, issue})
            }
        }
    }
    add("Strict-Transport-Security", "ausente: permite downgrade a HTTP / SSL stripping", nil)
    add("Content-Security-Policy", "ausente: XSS sin mitigación de defensa en profundidad", nil)
    add("X-Content-Type-Options", "ausente: MIME sniffing posible", func(v string) string {
        if !strings.EqualFold(v, "nosniff") {
            return "valor inesperado (debería ser nosniff)"
        }
        return ""
    })
    add("Referrer-Policy", "ausente: fuga de URLs en el Referer", nil)
    return out
}
```

## Clickjacking: dos controles, uno moderno

El framing se bloquea de dos formas y basta con **una**. La clásica `X-Frame-Options` y la moderna `Content-Security-Policy: frame-ancestors`. <mark style="background: #ADCCFFA6;">Si no hay ninguna, la página es embebible</mark> → clickjacking:

```go
func framable(h http.Header) bool {
    switch strings.ToUpper(strings.TrimSpace(h.Get("X-Frame-Options"))) {
    case "DENY", "SAMEORIGIN":
        return false
    }
    // frame-ancestors (más moderno que XFO) también protege, si no es permisivo
    csp := strings.ToLower(h.Get("Content-Security-Policy"))
    if strings.Contains(csp, "frame-ancestors") && !strings.Contains(csp, "frame-ancestors *") {
        return false
    }
    return true   // ni XFO ni frame-ancestors efectivo → embebible
}
```

`framable(h) == true` significa que puedes montar un iframe transparente sobre la víctima y secuestrar sus clics. El PoC (iframe + overlay) está en Red Team [[08 - Clickjacking]].

## Modernizaciones sobre el recetario

- <mark style="background: #FFB86CA6;">Set de cabeceras de 2026</mark>: el original comprueba `X-Frame-Options` y poco más. Hoy manda `CSP frame-ancestors` (XFO está en desuso), `Permissions-Policy` sustituyó a `Feature-Policy`, y `X-XSS-Protection` está **deprecada** (debería estar ausente o a `0`, no a `1` — el filtro XSS de los navegadores viejos introducía bugs).
- **Doble control de framing** (XFO **y** `frame-ancestors`), no solo XFO — un objetivo moderno puede confiar solo en CSP.
- **Chequeo de `frame-ancestors` permisivo** (`*`): estar presente no basta si es abierta.
- **Evaluación de valor**, no solo presencia (`nosniff`, `max-age` de HSTS suficiente).

> [!info]+ Arsenal
> `securityheaders.com`, `nuclei` (plantillas de missing-headers), y para HSTS/TLS el testeo profundo en Red Team [[11 - Detección, testeo y hardening de TLS]]. Tu auditor Go entra en un pipeline propio o cuando quieres el resultado en tu formato.

De las cabeceras de respuesta pasamos a un caso especial y jugoso: las cookies y la fijación de sesión → [[02 - Cookies inseguras y session fixation]].
