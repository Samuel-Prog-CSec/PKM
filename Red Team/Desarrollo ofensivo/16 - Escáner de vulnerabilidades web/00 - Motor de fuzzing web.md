---
tags:
  - Go
  - Go/Web
  - Fuzzing
  - Tipo/Introduccion
Descripción: "El motor de barrido probaba candidatos como valores completos (rutas, usuarios)"
Fecha de actualización: 2026-07-26
Nota previa: 
Nota siguiente: "[[01 - Escáner de path traversal]]"
Area: "[[Escáner de vulnerabilidades web.base|Escáner de vulnerabilidades web]]"
---
---

El [[00 - Patrón worker pool y rate limiting|motor de barrido]] probaba candidatos como valores completos (rutas, usuarios). Un fuzzer de vulnerabilidades hace algo distinto: <mark style="background: #ADCCFFA6;">inyecta payloads en un punto marcado de una petición-plantilla</mark> y analiza la respuesta buscando síntomas de vulnerabilidad — el modelo `FUZZ` de ffuf. Este motor lo reusan los escáneres de path traversal, XSS y Shellshock de esta carpeta. La metodología de fuzzing y validación vive en Red Team [[15 - Introducción al web fuzzing]] y [[22 - Validación de hallazgos]].

> [!info]+ Fuente
> Receta "Automated fuzzing" de *Python Web Penetration Testing Cookbook* (2015). El original inyecta en un parámetro y grepea; aquí generalizamos el punto de inyección (URL, cabecera, body) y el criterio de detección (reflejo, error, timing).

## La plantilla y el punto de inyección

Marcas dónde va el payload con un centinela y lo sustituyes por cada valor de la lista. Así fuzzeas un parámetro de URL, una cabecera o el body con el mismo motor:

```go
const Marker = "§FUZZ§"

type Target struct {
    Method  string
    URL     string            // puede contener Marker
    Headers map[string]string // los valores pueden contener Marker
    Body    string            // puede contener Marker
}

func (t Target) render(ctx context.Context, payload string) (*http.Request, error) {
    sub := func(s string) string { return strings.ReplaceAll(s, Marker, payload) }

    req, err := http.NewRequestWithContext(ctx, t.Method, sub(t.URL), strings.NewReader(sub(t.Body)))
    if err != nil {
        return nil, err
    }
    for k, v := range t.Headers {
        req.Header.Set(k, sub(v))
    }
    return req, nil
}
```

## El matcher: qué cuenta como hallazgo

La diferencia entre un fuzzer tonto y uno útil es el **criterio de detección**. Lo abstraemos en un `Matcher` que cada escáner especializa — reflejo del payload, firma de error, o desviación de timing:

```go
type Finding struct {
    Payload  string
    Status   int
    Length   int64
    Elapsed  time.Duration
    Evidence string   // qué disparó el hallazgo
}

// Decide si (payload, respuesta) es un hallazgo. Lo inyecta cada escáner.
type Matcher func(payload string, resp *http.Response, body []byte, elapsed time.Duration) (Finding, bool)
```

El bucle reúne plantilla + payloads + matcher sobre la concurrencia acotada de la nota [[00 - Patrón worker pool y rate limiting]]:

```go
func Fuzz(ctx context.Context, t Target, payloads []string, m Matcher,
    client *http.Client, workers int, rps float64) []Finding {

    limiter := rate.NewLimiter(rate.Limit(rps), workers)
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(workers)

    var (
        mu       sync.Mutex
        findings []Finding
    )
    for _, p := range payloads {
        g.Go(func() error {
            if err := limiter.Wait(ctx); err != nil {
                return err
            }
            req, err := t.render(ctx, p)
            if err != nil {
                return nil
            }
            start := time.Now()
            resp, err := client.Do(req)
            if err != nil {
                return nil
            }
            body, _ := io.ReadAll(resp.Body)
            resp.Body.Close()

            if f, ok := m(p, resp, body, time.Since(start)); ok {
                mu.Lock()
                findings = append(findings, f)
                mu.Unlock()
            }
            return nil
        })
    }
    _ = g.Wait()
    return findings
}
```

## El baseline, otra vez

<mark style="background: #FFB8EBA6;">Casi todos los matchers necesitan una referencia</mark>: ¿el error de BBDD ya estaba antes de inyectar? ¿la respuesta tarda siempre 2 s o solo con mi payload? Antes de fuzzear, envías un payload **inocuo** y guardas su `(status, longitud, tiempo)`. El matcher compara contra ese baseline, no contra valores absolutos. Es el mismo principio del soft-404 y del jitter, aplicado a cada tipo de vuln.

## Modernizaciones sobre el recetario

- **Punto de inyección genérico** (URL / cabecera / body con `§FUZZ§`), no solo un parámetro fijo.
- **Matcher desacoplado**: el motor no sabe de traversal ni de XSS; cada escáner aporta sus payloads y su criterio. Es la misma idea de `Probe` del motor de barrido, llevada a la detección de vulns.
- **Concurrente con rate limit y `context`**, frente al bucle secuencial del original.
- <mark style="background: #FF5582A6;">Reflejo ≠ ejecución</mark>: que un payload aparezca en la respuesta no prueba que sea explotable. El matcher marca *candidatos*; la confirmación (¿ejecuta?, ¿lee el fichero?) es un segundo paso — a veces con navegador headless. Lo vemos en el escáner de XSS.

> [!info]+ Arsenal
> `ffuf` (fuzzing genérico con `FUZZ`), `nuclei` (plantillas YAML por vuln) y escáneres dedicados (`dalfox`, `sqlmap`) son el estándar. Tu motor Go entra para lógica a medida o un objetivo que no encaja en esas herramientas. Filtrado y validación de salida en Red Team [[21 - Filtrado de la salida de fuzzing]].

El primer escáner concreto sobre este motor: leer ficheros del servidor con path traversal → [[01 - Escáner de path traversal]].
