---
tags:
  - Go
  - Go/Web
  - Concurrencia
  - Tipo/Introduccion
Descripción: "Ya sabes descubrir la superficie del objetivo (recon: crawler, fingerprinting)"
Fecha de actualización: 2026-07-26
Nota previa: 
Nota siguiente: "[[01 - Content discovery - directorios y ficheros]]"
Area: "[[Enumeración y fuerza bruta web.base|Enumeración y fuerza bruta web]]"
---
---

Ya sabes descubrir la superficie del objetivo (recon: [[04 - Crawler web concurrente|crawler]], [[07 - Fingerprinting web y librerías JS obsoletas|fingerprinting]]). Ahora la **atacas a escala**: content discovery, enumeración de usuarios, fuerza bruta de login, fuzzing. Todas esas herramientas tienen la **misma forma** — una lista grande de candidatos (rutas, usuarios, contraseñas, payloads) → una petición por candidato → filtrar las respuestas interesantes. <mark style="background: #ADCCFFA6;">Este es el patrón reutilizable</mark> que instancian las notas siguientes, y es donde Go entierra al Python secuencial del recetario.

> [!info]+ Por qué esta nota es net-new
> El recetario hace **todos** sus brute-forcers y fuzzers con bucles secuenciales (una petición, esperar, la siguiente). Es lento y no escala. En vez de reescribir esa lentitud cuatro veces, aquí extraemos el motor concurrente **una vez** y lo reusamos. La teoría de goroutines está en [[13 - Goroutines, channels y concurrencia]].

## Los tres requisitos de un motor de barrido serio

1. **Concurrencia acotada.** Miles de peticiones a la vez tumban al objetivo y a tu box. Un pool con tope fijo.
2. **Rate limiting.** Además del tope de concurrencia, un límite de **peticiones por segundo** — para no disparar rate-limiters/WAF, no bloquear cuentas en un brute de login, y poder bajar el ritmo en un objetivo frágil.
3. **Cancelación.** Un `context` que corta todo el barrido (deadline, `Ctrl-C`, o "ya encontré lo que buscaba").

El fan-out aquí es **plano** (una lista, sin recursión), así que `errgroup.SetLimit` es el patrón correcto — a diferencia del [[04 - Crawler web concurrente|crawler]] recursivo. Le sumamos un `rate.Limiter` de `golang.org/x/time/rate`:

```go
// Candidate es un valor a probar: ruta, usuario, contraseña o payload.
type Candidate string

// Result: qué devolvió probar un Candidate.
type Result struct {
    Candidate Candidate
    Status    int
    Length    int64
    Hit       bool   // ¿cumple el criterio de hallazgo?
}

// Probe prueba un Candidate y decide si es un hallazgo. La inyecta cada
// herramienta: content discovery, user enum, login brute… mismo motor.
type Probe func(ctx context.Context, c Candidate) (Result, error)

func Sweep(ctx context.Context, cands []Candidate, probe Probe, workers int, rps float64) []Result {
    limiter := rate.NewLimiter(rate.Limit(rps), workers)   // rps pet/seg, burst = workers

    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(workers)

    var (
        mu   sync.Mutex
        hits []Result
    )
    for _, c := range cands {
        g.Go(func() error {
            if err := limiter.Wait(ctx); err != nil {   // respeta el ritmo y la cancelación
                return err                              // ctx cancelado: para el barrido
            }
            res, err := probe(ctx, c)
            if err != nil {
                log.Printf("[!] %s: %v", c, err)
                return nil                              // un fallo puntual NO aborta el barrido
            }
            if res.Hit {
                mu.Lock()
                hits = append(hits, res)
                mu.Unlock()
            }
            return nil
        })
    }
    _ = g.Wait()
    return hits
}
```

## Las decisiones que importan

- <mark style="background: #FFB8EBA6;">`return nil` ante un error de `probe`</mark>: en un barrido, timeouts y conexiones caídas son **normales**. Si dejaras que el error se propague, `errgroup.WithContext` cancelaría todo el barrido al primer fallo. Loggeas y sigues.
- **`limiter.Wait(ctx)` antes de cada petición**: bloquea hasta que toca el turno según el ritmo, y devuelve error si el `context` se cancela mientras espera. Un solo `Limiter` compartido regula el ritmo **global**, no por-goroutine.
- **`errgroup.SetLimit(workers)`**: tope duro de goroutines vivas. El `Limiter` controla el *ritmo*; `SetLimit` controla la *concurrencia*. Son ejes distintos y quieres los dos.
- **Resultados bajo `sync.Mutex`**: `append` concurrente a un slice es una *race*. Alternativa idiomática: un channel de `Result` y un colector. El mutex es más simple para acumular hallazgos.

> [!important]+ Variante "parar al primer acierto"
> Para content discovery quieres **todos** los hallazgos. Pero en fuerza bruta de login, en cuanto aciertas la contraseña quieres **cortar** el resto. Ahí sí devuelves un error centinela desde la rama `Hit` (`return errFound`): `errgroup.WithContext` cancela a los hermanos, y distingues ese centinela de un fallo real con `errors.Is`. Lo usamos en [[03 - Fuerza bruta de login]].

## Sigilo: ritmo y jitter

`rate.Limiter` da un ritmo **constante**, y un ritmo perfectamente regular es en sí una firma de automatización. Para *blending*, añade **jitter** (un retardo aleatorio pequeño) sobre el rate limit, con `crypto/rand` o `math/rand/v2`. La detección basada en timing y su evasión se ven a fondo en el [[05 - Detección de SQLi y baseline de timing|baseline/jitter de SQLi]]; la metodología anti-bloqueo, en Red Team [[05 - Bypass de protecciones anti-fuerza-bruta]].

Con el motor listo, el primer uso: descubrir rutas y ficheros que no están enlazados → [[01 - Content discovery - directorios y ficheros]].
