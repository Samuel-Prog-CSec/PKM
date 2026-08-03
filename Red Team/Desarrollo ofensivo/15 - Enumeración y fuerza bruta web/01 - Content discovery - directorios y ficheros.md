---
tags:
  - Go
  - Go/Web
  - Fuzzing
Descripción: "El crawler solo ve lo enlazado. Lo jugoso suele estar sin enlazar: paneles de admin, backups (.bak, .zip, .old), .git/, ficheros de config, endpoints olvidados"
Fecha de actualización: 2026-07-26
Nota previa: "[[00 - Patrón worker pool y rate limiting]]"
Nota siguiente: "[[02 - Enumeración de usuarios]]"
Area: "[[Enumeración y fuerza bruta web.base|Enumeración y fuerza bruta web]]"
---
---

El crawler solo ve lo **enlazado**. Lo jugoso suele estar **sin enlazar**: paneles de admin, backups (`.bak`, `.zip`, `.old`), `.git/`, ficheros de config, endpoints olvidados. El *content discovery* los encuentra probando una wordlist de rutas contra el objetivo. La metodología (wordlists, recursión, extensiones) vive en Red Team [[17 - Fuzzing de directorios y archivos]] y en el arsenal [[00 - Introducción a ffuf|ffuf]]; aquí lo montamos sobre el [[00 - Patrón worker pool y rate limiting|motor de barrido]].

> [!info]+ Fuente
> Receta "Enumerating files" de *Python Web Penetration Testing Cookbook* (2015), reimplementada concurrente y con calibración de falsos 200.

## La descarga

Un helper que hace el `GET` y devuelve status + longitud, **sin decidir aún** si es hallazgo (esa lógica va aparte, con el baseline). Descartamos el cuerpo con `io.Copy(io.Discard, ...)` pero contamos su **longitud** — la necesitamos para filtrar:

```go
// fetch descarga y devuelve status + longitud; el criterio de hallazgo se decide aparte.
func fetch(ctx context.Context, client *http.Client, rawURL string) (Result, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
    if err != nil {
        return Result{}, err
    }
    resp, err := client.Do(req)
    if err != nil {
        return Result{}, err
    }
    defer resp.Body.Close()

    n, _ := io.Copy(io.Discard, resp.Body)   // longitud sin retener el cuerpo
    return Result{Status: resp.StatusCode, Length: n}, nil
}
```

## El problema de verdad: los *soft 404*

<mark style="background: #FF5582A6;">Muchas apps devuelven `200 OK` para rutas inexistentes</mark> — una página de error "bonita" con status 200. Filtrar por `!= 404` te llena de basura. La solución profesional (lo que `ffuf -ac` llama *autocalibrate*): pides primero una ruta **aleatoria que seguro no existe**, guardas su `(status, longitud)` como referencia, y el `Probe` marca hallazgo solo lo que **se desvía** de ella:

```go
func calibrate(ctx context.Context, client *http.Client, base string) (Result, error) {
    return fetch(ctx, client, base+"/nope-"+randToken()+".html")   // ruta imposible → baseline
}

func isHit(res, baseline Result) bool {
    if res.Status == http.StatusNotFound {
        return false
    }
    if res.Status != baseline.Status {
        return true                              // status distinto al de "no existe"
    }
    return abs(res.Length-baseline.Length) > 64  // mismo status, tamaño claramente distinto
}

// pathProbe cierra sobre el baseline y decide el hallazgo con isHit.
func pathProbe(client *http.Client, base string, baseline Result) Probe {
    return func(ctx context.Context, c Candidate) (Result, error) {
        res, err := fetch(ctx, client, base+"/"+string(c))
        if err != nil {
            return Result{}, err
        }
        res.Candidate = c
        res.Hit = isHit(res, baseline)
        return res, nil
    }
}
```

<mark style="background: #8000E1A6;">Con el baseline, un `200` de página-error deja de ser un falso positivo</mark>: coincide con la referencia y se descarta. Calibras una vez, construyes el probe con ese baseline y lo pasas al [[00 - Patrón worker pool y rate limiting|motor]]:

```go
baseline, _ := calibrate(ctx, client, base)
hits := Sweep(ctx, wordlist, pathProbe(client, base, baseline), 20, 50)   // wordlist con extensiones ya expandidas
```

## Modernizaciones sobre el recetario

- **Concurrente y con rate limit** (motor de la nota [[00 - Patrón worker pool y rate limiting]]) frente al bucle secuencial del original.
- **Calibración de soft-404**, que el libro ignora: sin ella, cualquier app con página de error custom hace inútil el barrido.
- **`io.Copy(io.Discard, resp.Body)`** para medir longitud sin retener el cuerpo en memoria — importa cuando barres decenas de miles de rutas.
- **Sin recursión aquí**, pero es la extensión natural: cada directorio encontrado (`301`/`200` a un dir) se re-encola como nueva raíz. Ahí vuelve el patrón del [[04 - Crawler web concurrente|crawler]].

> [!info]+ Arsenal
> Para trabajo real: **`ffuf`**, **`feroxbuster`** (recursivo, en Rust) o **`gobuster`** — con calibración, filtros por código/tamaño/regex/palabras y wordlists de SecLists. Tu herramienta Go entra cuando necesitas lógica a medida (autenticación previa, un patrón de hallazgo raro, encadenar con otra fase). Comparativa en Red Team [[16 - Herramientas de fuzzing]].

De adivinar rutas pasamos a adivinar **usuarios**: detectar cuentas válidas por las diferencias en la respuesta → [[02 - Enumeración de usuarios]].
