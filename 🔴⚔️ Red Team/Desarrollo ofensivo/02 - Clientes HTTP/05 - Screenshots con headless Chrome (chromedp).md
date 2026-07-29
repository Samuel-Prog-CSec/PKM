---
tags:
  - Go
  - Go/HTTP
  - Recon
Descripción: "Cuando el scope tiene cientos de hosts, no los abres uno a uno en el navegador: los capturas en lote y los trias visualmente"
Fecha de actualización: 2026-07-26
Nota previa: "[[04 - Crawler web concurrente]]"
Nota siguiente: "[[06 - Harvesting de correos y comentarios del código fuente]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Cuando el scope tiene cientos de hosts, no los abres uno a uno en el navegador: los **capturas en lote** y los trias visualmente. Una rejilla de screenshots te dice de un vistazo cuáles son paneles de login, instalaciones por defecto, páginas de error o apps jugosas. Es la técnica de `EyeWitness` / `Aquatone` / `gowitness`. La metodología de triaje visual vive en Red Team [[09 - Fingerprinting web]]; aquí montamos el capturador en Go.

> [!info]+ Fuente y modernización
> Recetas "Getting screenshots of websites with QtWebKit" y "Screenshots based on a port list" de *Python Web Penetration Testing Cookbook* (2015). <mark style="background: #FF5582A6;">QtWebKit está muerto</mark>: el binding de WebKit en Qt lleva años sin mantenerse y no renderiza la web moderna (JS pesado, TLS actual). Hoy se conduce **Chromium headless** por el Chrome DevTools Protocol (CDP). En Go eso es `chromedp`.

## Capturar una URL

`chromedp` habla CDP con un Chrome/Chromium instalado — sin dependencias CGO, solo el navegador. El patrón es crear un contexto, encadenar acciones y volcar el PNG/JPEG a un `[]byte`:

```go
ctx, cancel := chromedp.NewContext(context.Background())
defer cancel()
ctx, cancel = context.WithTimeout(ctx, 20*time.Second)   // un host colgado no te bloquea
defer cancel()

var buf []byte
err := chromedp.Run(ctx,
    chromedp.Navigate("https://target.tld"),
    chromedp.FullScreenshot(&buf, 90),   // calidad 100 = PNG; <100 = JPEG a esa calidad
)
if err != nil {
    log.Fatal(err)
}
os.WriteFile("target.jpeg", buf, 0o644)
```

<mark style="background: #ADCCFFA6;">`FullScreenshot` captura la página entera</mark> (incluido lo que queda bajo el *fold*); `CaptureScreenshot` solo el viewport y `Screenshot(sel, &buf, chromedp.ByID)` un elemento concreto. Para recon casi siempre quieres la página completa.

## En lote y concurrente — aquí `errgroup.SetLimit` **sí** es correcto

A diferencia del [[04 - Crawler web concurrente|crawler]], que es recursivo, capturar una **lista** de hosts es fan-out **plano**: N tareas independientes, sin hijos. <mark style="background: #8000E1A6;">Este es el caso ideal de `errgroup.SetLimit`</mark>. La clave de `chromedp`: <mark style="background: #FFB8EBA6;">el primer `Run` sobre un contexto arranca el navegador; los contextos hijos son **pestañas** de ese mismo navegador</mark>. Así que arrancas Chrome una vez y abres una pestaña por objetivo:

```go
func screenshotAll(ctx context.Context, urls []string, workers int) error {
    allocCtx, cancelAlloc := chromedp.NewExecAllocator(ctx, chromedp.DefaultExecAllocatorOptions[:]...)
    defer cancelAlloc()

    // Arranca UN navegador. Los objetivos serán pestañas suyas, no navegadores nuevos.
    browserCtx, cancelBrowser := chromedp.NewContext(allocCtx)
    defer cancelBrowser()
    if err := chromedp.Run(browserCtx); err != nil {   // primer Run = lanza Chrome
        return err
    }

    g, gctx := errgroup.WithContext(browserCtx)
    g.SetLimit(workers)              // como mucho `workers` pestañas a la vez
    for _, target := range urls {    // Go 1.22+: sin `target := target`
        g.Go(func() error {
            return shoot(gctx, target)
        })
    }
    return g.Wait()
}

func shoot(browserCtx context.Context, target string) error {
    tabCtx, cancel := chromedp.NewContext(browserCtx)   // pestaña nueva en el navegador compartido
    defer cancel()
    tabCtx, cancel = context.WithTimeout(tabCtx, 20*time.Second)
    defer cancel()

    var buf []byte
    if err := chromedp.Run(tabCtx,
        chromedp.Navigate(target),
        chromedp.FullScreenshot(&buf, 90),
    ); err != nil {
        return fmt.Errorf("%s: %w", target, err)   // no aborta al resto: SetLimit sigue
    }
    return os.WriteFile(safeName(target)+".jpeg", buf, 0o644)
}
```

> [!warning]+ Pestañas comparten navegador (ligero) vs navegador por objetivo (aislado)
> Todas las pestañas viven en el **mismo** proceso de Chrome: es ligero y rápido, pero una página que cuelgue o crashee el navegador afecta a las hermanas. Para aislar objetivos inestables, usa un navegador por objetivo — `NewContext(allocCtx)` + `Run` dentro de `shoot` (más pesado, N procesos, pero robusto). Para recon normal, pestañas.

La receta "por lista de puertos" del libro es exactamente esto: alimentas `urls` con cada `host:puerto` web que escupió tu escaneo (`http://h:80`, `https://h:443`, `https://h:8443`…) y capturas todo el estate de golpe.

## Modernizaciones sobre el recetario

- **QtWebKit → chromedp (Chromium/CDP)**: renderiza la web de 2026 tal cual la ve un usuario; QtWebKit ni siquiera negocia TLS moderno.
- **Concurrencia con `errgroup.SetLimit`** frente a la captura secuencial del original: un navegador compartido y N pestañas acotadas.
- **`context.WithTimeout` por objetivo**: un host que cuelga el `Navigate` no congela el barrido — muere a los 20 s y sigue.
- **Sin captura de variable de bucle**: en Go 1.22+ cada iteración tiene su propia `target`; el clásico `target := target` sobra (ver [[13 - Goroutines, channels y concurrencia]]).

> [!warning]+ Chrome headless deja huella
> El navegador headless se detecta: `User-Agent` con `HeadlessChrome`, `navigator.webdriver === true`, ausencia de plugins. Un objetivo con anti-bot te sirve una página distinta o te bloquea. Si necesitas sigilo, ajusta el UA (`chromedp.UserAgent(...)`), añade *flags* de evasión o usa un `headless-shell` parcheado. Para OPSEC de recon → Red Team [[27 - Evasión en recon y fuzzing]].

> [!info]+ Arsenal: no reinventes gowitness
> Para un engagement real, **`gowitness`** (Go, sobre chromedp) ya hace esto con base de datos, reporte HTML y detección de tecnologías. Escribe el tuyo cuando necesites lógica a medida (capturar tras autenticarte, esperar un selector concreto, interceptar respuestas). El `chromedp.Run` acepta acciones arbitrarias antes del screenshot: `SetCookies`, `WaitVisible`, `SendKeys`.

Del aspecto visual pasamos al **código fuente**: minar el HTML por correos y comentarios que filtran información → [[06 - Harvesting de correos y comentarios del código fuente]].
