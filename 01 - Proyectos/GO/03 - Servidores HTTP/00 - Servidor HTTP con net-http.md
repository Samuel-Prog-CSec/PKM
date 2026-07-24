---
tags:
  - Go
  - Go/HTTP
  - HTTP
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - Middleware - el patrón de envoltura]]"
Area: "[[Servidores HTTP.base|Servidores HTTP]]"
---
---

El reverso del Cap. 3: en vez de consumir servicios, **montarlos**. Un servidor HTTP en Go es la base de casi todo el tooling ofensivo de red team con cara web — phishing, keylogging, C2, redirectores, frontends para tus herramientas. `net/http` hace de servidor completo sin librerías externas, y aquí hay una modernización **grande** frente al libro: desde Go 1.22 el `ServeMux` de la stdlib enruta por método y con wildcards, así que `gorilla/mux` —que el libro presenta como imprescindible— ya casi no hace falta.

## El servidor mínimo

Un handler es una función `func(w http.ResponseWriter, r *http.Request)`: lees de `r` (la petición) y escribes en `w` (la respuesta).

```go
func hello(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hola %s\n", r.URL.Query().Get("name"))
}

func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/hello", hello)
    http.ListenAndServe(":8080", mux)
}
```

<mark style="background: #ADCCFFA6;">Todo servidor Go gira en torno a la interfaz `http.Handler`, que exige un solo método: `ServeHTTP(w, r)`</mark> (nota [[10 - Interfaces]]). `HandleFunc` adapta una función a esa interfaz. Como es una interfaz, cualquier tipo con `ServeHTTP` es un servidor — de ahí que el middleware (nota siguiente) sea tan limpio. Usa un `ServeMux` explícito, **no** el `DefaultServeMux` global (pasar `nil` como handler): el global es estado compartido en el que cualquier paquete importado puede registrar rutas.

## Routing moderno: el `ServeMux` de Go 1.22

El libro implementa un router a mano (un `switch` sobre `r.URL.Path`) y luego recurre a `gorilla/mux` para enrutar por método, parámetros y host. <mark style="background: #8000E1A6;">Desde Go 1.22 (feb 2024) el `ServeMux` de la stdlib hace todo eso nativo</mark>:

```go
mux := http.NewServeMux()
mux.HandleFunc("POST /login", handleLogin)              // enruta por MÉTODO
mux.HandleFunc("GET /users/{id}", func(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")                             // wildcard de segmento
    fmt.Fprintf(w, "usuario %s", id)
})
mux.HandleFunc("GET /files/{path...}", serveFile)       // wildcard final: el resto de la ruta
mux.Handle("attacker1.com/", proxy)                      // enruta por HOST (virtual hosting)
```

El patrón es `[MÉTODO ][HOST]/[RUTA]`. `{name}` captura un segmento y se lee con `r.PathValue("name")`; `{name...}` captura el resto de la ruta; `{$}` ancla al final exacto. <mark style="background: #FFB8EBA6;">La precedencia la decide la especificidad del patrón, no el orden de registro</mark>, y dos patrones en conflicto hacen panic al registrarse (fallas rápido, no en producción).

> [!info]+ ¿Cuándo sigues necesitando gorilla/mux?
> Solo para lo que la stdlib aún no cubre: **restricciones con regex** en un parámetro (`{user:[a-z]+}`) o sub-routing complejo. Para method + path params + host —el 90% de los casos— la stdlib 1.22+ basta y te ahorra una dependencia. El propio toolkit gorilla fue archivado en 2022 y luego revivido; sano, pero innecesario para lo básico.

## Hardening: el servidor por defecto no tiene timeouts

El `http.ListenAndServe(":8080", mux)` del libro arranca un servidor **sin ningún timeout**. <mark style="background: #FF5582A6;">Eso es vulnerable a Slowloris</mark>: un cliente que abre conexiones y envía la petición byte a byte, muy despacio, agota los recursos del servidor y lo tumba sin apenas ancho de banda. Para cualquier servidor que expongas, configura `http.Server` explícito con timeouts:

```go
srv := &http.Server{
    Addr:              ":8080",
    Handler:           mux,
    ReadHeaderTimeout: 5 * time.Second,   // clave contra Slowloris: límite para recibir las cabeceras
    ReadTimeout:       10 * time.Second,
    WriteTimeout:      15 * time.Second,
    IdleTimeout:       60 * time.Second,
}
log.Fatal(srv.ListenAndServe())
```

`ReadHeaderTimeout` es el que corta a Slowloris de raíz. Para HTTPS —imprescindible en un servidor de phishing creíble— usas `srv.ListenAndServeTLS(cert, key)` (con un certificado de Let's Encrypt, el navegador de la víctima no chilla).

## Apagado limpio: graceful shutdown

Matar el proceso corta las conexiones en curso a lo bruto. `srv.Shutdown(ctx)` deja terminar las peticiones activas antes de cerrar — útil para no perder credenciales capturadas a medio enviar:

```go
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

go func() {
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatal(err)
    }
}()

<-ctx.Done()   // bloquea hasta SIGINT/SIGTERM
stop()

shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
srv.Shutdown(shutdownCtx)   // drena las conexiones vivas y cierra
```

Con el servidor y el routing dominados, el patrón que envuelve todos los handlers para añadir logging, autenticación o evasión: el middleware → [[01 - Middleware - el patrón de envoltura]].
