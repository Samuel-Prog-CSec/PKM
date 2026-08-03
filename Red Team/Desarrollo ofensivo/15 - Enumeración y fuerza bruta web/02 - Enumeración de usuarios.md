---
tags:
  - Go
  - Go/Web
  - Pentesting/Enumeracion
Descripción: "Antes de forzar contraseñas, reduces el espacio: averiguas qué usuarios existen"
Fecha de actualización: 2026-07-26
Nota previa: "[[01 - Content discovery - directorios y ficheros]]"
Nota siguiente: "[[03 - Fuerza bruta de login]]"
Area: "[[Enumeración y fuerza bruta web.base|Enumeración y fuerza bruta web]]"
---
---

Antes de forzar contraseñas, reduces el espacio: averiguas **qué usuarios existen**. Una app que responde distinto ante un usuario válido que ante uno inexistente filtra su lista de cuentas. Es la base del brute force dirigido y del phishing. El *porqué* y dónde ocurre (login, registro, reset de contraseña) vive en Red Team [[01 - Enumeración de usuarios]]; aquí el detector en Go sobre el [[00 - Patrón worker pool y rate limiting|motor de barrido]].

> [!info]+ Fuente
> Recetas "Checking username validity" y "Brute forcing usernames" de *Python Web Penetration Testing Cookbook* (2015), unificadas y con detección diferencial calibrada + análisis de timing.

## Señal 1: diferencia en la respuesta

Envías cada usuario candidato con una contraseña basura. Si la app distingue "usuario no existe" de "contraseña incorrecta", el **marcador textual** delata las cuentas reales. El `Probe`:

```go
func userEnumProbe(client *http.Client, loginURL, invalidMarker string) Probe {
    return func(ctx context.Context, c Candidate) (Result, error) {
        form := url.Values{
            "username": {string(c)},
            "password": {"Wrong-Password-Never-Valid-123!"},
        }
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

        // Hit: la respuesta NO trae el marcador de "usuario inválido"
        // (p. ej. "Unknown user") → la cuenta existe.
        return Result{
            Candidate: c,
            Status:    resp.StatusCode,
            Length:    int64(len(body)),
            Hit:       !strings.Contains(string(body), invalidMarker),
        }, nil
    }
}
```

<mark style="background: #FFB8EBA6;">El marcador no lo adivinas: lo calibras</mark>. Envías un usuario que seguro no existe (`zzz-nope-<rand>`), lees su respuesta, y ese texto ("Unknown user", "No such account") es tu `invalidMarker`. Igual que el soft-404 del content discovery, la referencia la fija el propio objetivo.

## Señal 2: timing (cuando no hay diferencia textual)

Apps más cuidadas devuelven el **mismo** mensaje siempre. Pero a menudo filtran por **tiempo**: con un usuario válido calculan el hash de la contraseña (bcrypt/argon2, lento); con uno inexistente, <mark style="background: #FFB86CA6;">cortan antes y responden más rápido</mark>. Mides la latencia y comparas contra el baseline:

```go
func timedProbe(inner Probe) func(context.Context, Candidate) (time.Duration, Result, error) {
    return func(ctx context.Context, c Candidate) (time.Duration, Result, error) {
        start := time.Now()
        res, err := inner(ctx, c)
        return time.Since(start), res, err
    }
}
```

La diferencia por petición es ruidosa (red, GC, jitter del servidor). Para que sea fiable necesitas **varias muestras por candidato** y comparar **medianas**, no una lectura suelta — por eso el timing no encaja en el `Sweep` de una-petición-por-candidato, sino en un bucle propio que mide cada candidato N veces y se queda con la mediana. La metodología estadística de timing —y por qué la mediana aguanta el ruido mejor que la media— está en el [[05 - Detección de SQLi y baseline de timing|baseline/jitter de SQLi]].

## Modernizaciones sobre el recetario

- **Detección diferencial calibrada** contra el objetivo, no un marcador hardcodeado.
- **Análisis de timing** como segunda señal, que el original no explota — clave contra apps que uniforman el mensaje.
- **Concurrente con rate limit**: pero ojo, en enum de usuarios el rate limit importa doble (abajo).
- **`url.Values.Encode()`** para construir el form, que escapa correctamente usuarios con caracteres raros — el original concatena a mano.

> [!warning]+ Enumerar puede bloquear cuentas
> Si el objetivo cuenta intentos fallidos **por usuario**, tu barrido con una password basura puede **bloquear cuentas reales** — ruido y daño colateral en un engagement. Baja el ritmo, usa la señal de timing (que no necesita enviar logins fallidos si atacas el endpoint de registro/reset) y coordina con el cliente. El bypass de estas protecciones está en Red Team [[05 - Bypass de protecciones anti-fuerza-bruta]].

Con la lista de usuarios válidos, el siguiente paso es la contraseña → [[03 - Fuerza bruta de login]].
