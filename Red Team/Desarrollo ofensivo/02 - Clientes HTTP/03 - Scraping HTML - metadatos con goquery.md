---
tags:
  - Go
  - Go/HTTP
  - Scraping
Descripción: "Cuando el servicio no tiene API, extraes los datos del HTML: *scraping*"
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - RPC con Metasploit (MessagePack)]]"
Nota siguiente: "[[04 - Crawler web concurrente]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Cuando el servicio **no** tiene API, extraes los datos del HTML: *scraping*. El libro busca en Bing los documentos de office publicados de un dominio objetivo y les saca los metadatos — la técnica que popularizó **FOCA**: un `.docx` o `.xlsx` filtra nombres de usuario, versión del software y hasta la empresa. Hay dos partes bien distintas: el scraping del buscador (frágil, envejece rápido) y la extracción de metadatos (oro OSINT, duradera).

## `goquery`: jQuery para Go

`goquery` recorre y selecciona nodos de un HTML con una sintaxis tipo jQuery. Aquí hay una **modernización importante**: el libro usa `goquery.NewDocument(url)`, que hacía la petición HTTP por dentro y <mark style="background: #FF5582A6;">fue eliminado de goquery</mark>. La forma actual separa la descarga (con tu cliente HTTP de la nota [[00 - El cliente HTTP de Go]], con timeout y User-Agent) del parseo:

```go
req, _ := http.NewRequestWithContext(ctx, http.MethodGet, searchURL, nil)
req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")   // sin UA creíble te bloquean
resp, err := client.Do(req)
if err != nil {
    return err
}
defer resp.Body.Close()

doc, err := goquery.NewDocumentFromReader(resp.Body)   // <- reemplaza a NewDocument
if err != nil {
    return err
}
doc.Find("li.b_algo h2 a").Each(func(i int, s *goquery.Selection) {
    href, ok := s.Attr("href")   // el enlace directo al documento
    if !ok {
        return
    }
    // ...descargar href y extraer metadatos
})
```

Separar la descarga del parseo es además mejor diseño: reutilizas tu cliente con timeout en vez de que la librería abra conexiones sin control.

## El scraping es frágil (dilo claro)

<mark style="background: #FFB86CA6;">El selector CSS que apunta a los resultados es el punto débil</mark>: en cuanto Bing cambia su HTML —y lo hace— el `li.b_algo h2 a` deja de encontrar nada y el tool devuelve cero sin error. Además, los buscadores **bloquean scrapers** (CAPTCHA, rate-limiting, respuestas falsas). Y en 2026 hay un problema extra: Microsoft **retiró la Bing Search API en agosto de 2025**, así que ni siquiera la vía "oficial" está disponible.

> [!warning]+ El scraping de buscadores es mantenimiento perpetuo
> Cualquier tool que dependa del HTML de un buscador se rompe solo con el tiempo. Trátalo como código de vida corta: selectores fáciles de tocar, y verificación de que sigues recibiendo resultados. Para OSINT serio hoy se combinan fuentes dedicadas y dorks contra varios motores, no un scraper de un solo buscador. La metodología de recon vive en Red Team.

## La parte que perdura: metadatos de office

Lo valioso y estable es la extracción de metadatos. <mark style="background: #ADCCFFA6;">Un documento Office Open XML (`.docx`, `.xlsx`, `.pptx`) es en realidad un archivo ZIP</mark> con XML dentro. Dos ficheros interesan, ambos en `docProps/`:

- `core.xml` → `creator` y `lastModifiedBy`: <mark style="background: #FFB86CA6;">nombres de usuario reales</mark>, munición para password spraying o ingeniería social.
- `app.xml` → `Application`, `Company` y `AppVersion`: qué software y versión usa la organización, útil para elegir exploits.

Los mapeas a structs con tags XML (nota [[12 - JSON, XML y datos estructurados]]):

```go
type OfficeCoreProperty struct {
    XMLName        xml.Name `xml:"coreProperties"`
    Creator        string   `xml:"creator"`
    LastModifiedBy string   `xml:"lastModifiedBy"`
}

type OfficeAppProperty struct {
    XMLName     xml.Name `xml:"Properties"`
    Application string   `xml:"Application"`
    Company     string   `xml:"Company"`
    Version     string   `xml:"AppVersion"`   // "16.x" -> Office 2016, etc.
}
```

## Extraer el ZIP y parsear

Descargas el documento a memoria y lo lees como ZIP con `archive/zip`, recorriendo sus ficheros:

```go
buf, err := io.ReadAll(resp.Body)   // io.ReadAll, NO el ioutil.ReadAll del libro
if err != nil {
    return err
}
zr, err := zip.NewReader(bytes.NewReader(buf), int64(len(buf)))
if err != nil {
    return err   // no era un office válido (o Bing devolvió una página de bloqueo)
}

for _, f := range zr.File {
    switch f.Name {
    case "docProps/core.xml":
        rc, _ := f.Open()
        var core OfficeCoreProperty
        xml.NewDecoder(rc).Decode(&core)
        rc.Close()
        fmt.Printf("autor: %s / modificado por: %s\n", core.Creator, core.LastModifiedBy)
    case "docProps/app.xml":
        // ...igual, decodificando en OfficeAppProperty
    }
}
```

Esta parte —office como ZIP, `docProps/*.xml`— no ha cambiado en años y seguirá funcionando cuando el scraper de Bing haya muerto tres veces.

## Escalarlo: descargas concurrentes

El libro deja como ejercicio descargar los documentos en paralelo. Con lo de la nota [[13 - Goroutines, channels y concurrencia]] es directo: un `errgroup.SetLimit(n)` que baje y procese cada enlace, acotando la concurrencia para no martillear (ni al buscador ni al hosting de los documentos, que puede alertar).

---

Con esto dominas el consumo de servicios: clientes HTTP robustos (timeouts, context), clientes de API idiomáticos (functional options), formatos binarios (MessagePack) y extracción de datos donde no hay API (scraping + metadatos). El mismo cliente HTTP es la base del **recon activo**: mapear un objetivo web con un crawler concurrente → [[04 - Crawler web concurrente]].
