---
tags:
  - Go
  - Go/HTTP
  - HTTP
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - Servidor HTTP con net-http]]"
Nota siguiente: "[[02 - Plantillas HTML y credential harvesting]]"
Area: "[[Servidores HTTP.base|Servidores HTTP]]"
---
---

Un **middleware** es una función que envuelve un handler para ejecutar lógica en **cada** petición: logging, autenticación, cabeceras de seguridad y —en ofensiva— filtrar quién recibe tu payload. El libro lo monta a mano y luego mete la librería Negroni; la buena noticia es que <mark style="background: #ADCCFFA6;">el patrón hand-rolled del libro **es** el idiom moderno</mark>, y Negroni sobra.

## El patrón: un handler que envuelve a otro

Como un `http.Handler` es cualquier cosa con `ServeHTTP` (nota [[10 - Interfaces]]), un middleware es simplemente una función que **recibe** un handler y **devuelve** otro que lo envuelve:

```go
func withLogging(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)                 // llama al handler envuelto
        slog.Info("request",
            "method", r.Method, "path", r.URL.Path,
            "remote", r.RemoteAddr, "dur", time.Since(start))
    })
}
```

Haces tu trabajo antes y/o después de llamar a `next.ServeHTTP`. Aquí ya hay una modernización: el libro loguea con `log.Println` (y más adelante con `logrus`); <mark style="background: #FFB8EBA6;">en 2026 se usa `log/slog`</mark> —structured logging en la stdlib desde Go 1.21— que emite pares clave/valor filtrables en vez de texto plano.

## Encadenar middleware

Como cada middleware toma y devuelve un `http.Handler`, se **anidan**. Se ejecutan de fuera adentro:

```go
mux := http.NewServeMux()
mux.HandleFunc("POST /login", handleLogin)

handler := withLogging(withRecovery(mux))   // logging -> recovery -> mux
srv := &http.Server{Addr: ":8080", Handler: handler /* + timeouts, nota 00 */}
```

<mark style="background: #FFB86CA6;">El orden importa</mark>: la autenticación debe ir **antes** del handler que protege. Para cadenas largas, `justinas/alice` da una sintaxis más legible (`alice.New(withLogging, withAuth).Then(mux)`), pero para dos o tres middlewares el anidado directo basta y no añade dependencias.

## Middleware de autenticación y el contexto

El middleware de auth valida credenciales y, si son buenas, pasa datos al handler a través del `context` de la petición. El libro tiene aquí **dos fallos** que conviene corregir:

```go
type ctxKey int
const userKey ctxKey = 0     // clave de contexto de tipo NO exportado

func withAuth(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        user, pass, ok := r.BasicAuth()          // cabecera Authorization, NO la query string
        if !ok || !validCreds(user, pass) {
            http.Error(w, "no autorizado", http.StatusUnauthorized)
            return                                // cortar la cadena: NO llamar a next
        }
        ctx := context.WithValue(r.Context(), userKey, user)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

// en el handler protegido:
user, _ := r.Context().Value(userKey).(string)
```

- El libro pasa las credenciales en la **query string** (`?username=...&password=...`), que se filtran en logs de proxy, historial y referers. `r.BasicAuth()` las lee de la cabecera `Authorization`.
- El libro usa la string `"username"` como clave de contexto. <mark style="background: #FF5582A6;">Dos paquetes que usen la misma string se pisan el valor</mark>; la regla (nota [[13 - Goroutines, channels y concurrencia]] / `context`) es usar un **tipo no exportado** como clave, imposible de colisionar desde fuera.
- El `return` **antes** de `next` corta la cadena: sin él, un fallo de auth seguiría ejecutando el handler protegido.

## Negroni ya no hace falta

El libro introduce Negroni para encadenar middleware, con su propia interfaz `ServeHTTP` de **tres** parámetros (`w, r, next`), incompatible con el `http.Handler` estándar. Ese acoplamiento es justo el problema: un middleware Negroni no sirve en un stack no-Negroni y viceversa. <mark style="background: #8000E1A6;">El patrón `func(http.Handler) http.Handler` que ya viste es compatible con toda la stdlib y con cualquier router</mark>; un middleware Negroni, en cambio, solo encaja en un stack Negroni. Negroni sigue mantenido (urfave/negroni v3), pero **ha dejado de ser el patrón por defecto** de la comunidad, que hoy prioriza la compatibilidad directa con `http.Handler`. Para tooling nuevo, stdlib — con `justinas/alice` si quieres azúcar para encadenar.

## Uso ofensivo: servir el payload solo al objetivo

En red team el middleware es donde metes la lógica de **redirector**: entregar el payload únicamente a quien te interesa y un señuelo al resto (escáneres del equipo azul, sandboxes de análisis, crawlers).

```go
func targetOnly(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if !looksLikeTarget(r) {          // filtra por User-Agent, IP, geolocalización, cabeceras
            http.NotFound(w, r)           // o una página benigna creíble
            return
        }
        next.ServeHTTP(w, r)              // solo el objetivo real llega al payload
    })
}
```

<mark style="background: #FFB86CA6;">Este filtrado reduce muchísimo la exposición</mark>: si tu infraestructura solo responde con lo malicioso al objetivo previsto, el equipo azul y las sandboxes automáticas ven una web inocua. Es una técnica central de los redirectores de C2; la metodología a fondo vive en Red Team. Y un apunte OPSEC sobre el logging de antes: en tooling ofensivo quieres `slog` a un **fichero local**, nunca exportadores tipo OpenTelemetry que manden telemetría de tu C2 a un tercero.

Con el servidor, el routing y el middleware, toca generar contenido dinámico de forma segura y aplicarlo al primer ataque real: plantillas HTML y un servidor de captura de credenciales → [[02 - Plantillas HTML y credential harvesting]].
