---
tags:
  - Go
  - Go/HTTP
  - Recon
Descripción: "Para mapear un objetivo necesitas descubrir sus URLs, formularios y parámetros — la superficie de entrada"
Fecha de actualización: 2026-07-26
Nota previa: "[[03 - Scraping HTML - metadatos con goquery]]"
Nota siguiente: "[[05 - Screenshots con headless Chrome (chromedp)]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Para mapear un objetivo necesitas descubrir sus URLs, formularios y parámetros — la superficie de entrada. Eso es *crawling* / *spidering*: pides una página, extraes sus enlaces, sigues los que están en scope y repites. <mark style="background: #ADCCFFA6;">Un crawler es un problema de concurrencia de manual</mark>, y es donde Go aplasta al Python secuencial del recetario. La metodología (qué crawlear, cómo delimitar el scope, por qué) vive en Red Team [[10 - Crawling web]] y [[11 - Spidering con Scrapy]]; aquí construimos el motor en Go.

> [!info]+ Fuente
> Técnica de *Python Web Penetration Testing Cookbook* (Packt, 2015), receta "Spidering websites". El original es una recursión secuencial con `urllib2`; aquí la reimplementamos concurrente y moderna.

## El diseño concurrente (y por qué **no** `errgroup.SetLimit` aquí)

Un crawler tiene dos problemas de estado compartido: **deduplicar** (no visitar dos veces la misma URL, o entras en bucle infinito) y **acotar la concurrencia** (no lanzar 10.000 goroutines martilleando el objetivo).

La tentación es `errgroup.SetLimit`, el pool que usamos para el fan-out plano. Pero el crawling es **recursivo**: cada página envía sus hijos al pool. Con `SetLimit`, una goroutine que se bloquea en `g.Go()` esperando un slot para sus hijos —mientras todos los slots están ocupados por goroutines haciendo lo mismo— <mark style="background: #FF5582A6;">produce un deadlock</mark>: todas esperan para encolar, ninguna termina. Por eso, para fan-out **recursivo** se usa el patrón clásico: un **semáforo** (channel con buffer) que acota la concurrencia, un `sync.WaitGroup` que detecta cuándo se drena la frontera, y un `map` de vistos protegido por `sync.Mutex`.

```go
type Crawler struct {
    client   *http.Client
    root     *url.URL
    maxDepth int
    sem      chan struct{}   // acota goroutines simultáneas

    mu   sync.Mutex
    seen map[string]bool
}

func NewCrawler(root string, workers, maxDepth int) (*Crawler, error) {
    u, err := url.Parse(root)
    if err != nil {
        return nil, fmt.Errorf("url raíz inválida: %w", err)
    }
    return &Crawler{
        client:   &http.Client{Timeout: 10 * time.Second},
        root:     u,
        maxDepth: maxDepth,
        sem:      make(chan struct{}, workers),
        seen:     map[string]bool{},
    }, nil
}

// markSeen devuelve true si la URL es nueva (y la marca).
func (c *Crawler) markSeen(u string) bool {
    c.mu.Lock()
    defer c.mu.Unlock()
    if c.seen[u] {
        return false
    }
    c.seen[u] = true
    return true
}
```

El corazón es `visit`: adquiere un slot del semáforo (o aborta si el `context` se cancela), descarga y parsea, y **lanza una goroutine por cada hijo nuevo en scope** sin esperarlos en línea — el `WaitGroup` los rastrea:

```go
func (c *Crawler) visit(ctx context.Context, wg *sync.WaitGroup, rawURL string, depth int) {
    defer wg.Done()

    select {
    case c.sem <- struct{}{}:          // adquiere slot (bloquea si el pool está lleno)
    case <-ctx.Done():
        return
    }
    defer func() { <-c.sem }()         // libéralo al salir

    links, err := c.fetchLinks(ctx, rawURL)
    if err != nil {
        log.Printf("[!] %s: %v", rawURL, err)
        return
    }
    fmt.Printf("[+] %s (%d enlaces)\n", rawURL, len(links))
    if depth >= c.maxDepth {
        return
    }
    for _, link := range links {
        if !c.inScope(link) || !c.markSeen(link) {
            continue
        }
        wg.Add(1)
        go c.visit(ctx, wg, link, depth+1)
    }
}
```

`fetchLinks` es donde entra tu cliente HTTP de [[00 - El cliente HTTP de Go]] y `goquery`. Lo clave es resolver los enlaces **relativos** contra la URL final (tras redirecciones, `resp.Request.URL`) y quitar el `#fragment`, que no cambia el recurso:

```go
func (c *Crawler) fetchLinks(ctx context.Context, rawURL string) ([]string, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
    if err != nil {
        return nil, err
    }
    req.Header.Set("User-Agent", "Mozilla/5.0 (compatible)")
    resp, err := c.client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK ||
        !strings.Contains(resp.Header.Get("Content-Type"), "text/html") {
        return nil, nil   // sin errores: simplemente no hay nada que crawlear
    }

    doc, err := goquery.NewDocumentFromReader(resp.Body)
    if err != nil {
        return nil, err
    }
    base := resp.Request.URL

    var links []string
    doc.Find("a[href]").Each(func(_ int, s *goquery.Selection) {
        href, _ := s.Attr("href")
        if u, err := base.Parse(href); err == nil {   // resuelve relativas
            u.Fragment = ""
            links = append(links, u.String())
        }
    })
    return links, nil
}
```

Con `inScope` comprobando `u.Host == c.root.Host`, arrancas seedeando la raíz y esperas a que la frontera se drene:

```go
func (c *Crawler) Crawl(ctx context.Context) {
    var wg sync.WaitGroup
    c.markSeen(c.root.String())
    wg.Add(1)
    go c.visit(ctx, &wg, c.root.String(), 0)
    wg.Wait()
}
```

> [!info]+ El semáforo acota las peticiones, no las goroutines
> Matiz importante: `sem` limita cuántas goroutines **descargan a la vez** (la carga sobre el objetivo), pero se sigue creando una goroutine por enlace nuevo, la mayoría bloqueadas esperando slot. Son baratas, pero en un crawl gigante su número crece con la frontera. Si eso importa, el patrón canónico es un **pool fijo de N workers** leyendo de una cola (channel), que acota goroutines *y* peticiones. Aquí prima la claridad; para escala masiva, la cola.

## Modernizaciones sobre el recetario

- <mark style="background: #FFB86CA6;">Concurrencia acotada</mark> frente a la recursión de-uno-en-uno del original: `workers` páginas descargándose en paralelo como tope, no una detrás de otra.
- **`goquery.NewDocumentFromReader`** separando descarga y parseo (misma corrección que en [[03 - Scraping HTML - metadatos con goquery|la nota de scraping]]): reutilizas tu cliente con `Timeout` en vez de que la librería abra conexiones sin control.
- **Resolución de URLs con `net/url`**: `base.Parse(href)` maneja rutas relativas, `//host` sin esquema y `../` correctamente. La concatenación de strings del original se rompe con cualquier enlace relativo.
- **`context` en el `select` del semáforo**: un `Ctrl-C` o un deadline detienen el crawl <mark style="background: #8000E1A6;">limpiamente, sin dejar goroutines colgadas</mark>.
- **Scope por host**: el check `u.Host == root.Host` evita que el crawler se vaya a internet siguiendo enlaces externos.

> [!warning]+ Un crawler concurrente es ruidoso
> A toda velocidad, N goroutines golpeando el objetivo se marcan al instante en un WAF o rate-limiter. En un engagement con sigilo: añade un `rate.Limiter` (`golang.org/x/time/rate`), un `User-Agent` creíble y, si procede, respeta `robots.txt`. El patrón reutilizable de pool acotado + rate limiting está en [[00 - Patrón worker pool y rate limiting]]; la metodología de evasión en recon vive en Red Team [[27 - Evasión en recon y fuzzing]].

El siguiente paso del recon: capturar cómo **se ve** cada host descubierto, con un navegador headless → [[05 - Screenshots con headless Chrome (chromedp)]].
