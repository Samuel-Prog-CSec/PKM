---
tags:
  - Go
  - Go/HTTP
  - API
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - El cliente HTTP de Go]]"
Nota siguiente: "[[02 - RPC con Metasploit (MessagePack)]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Un GET suelto sirve para un script de usar y tirar. Para una herramienta que reutilizas, empaquetas el cliente como **librería**: un tipo que guarda la configuración y expone un método por endpoint. El libro lo hace con Shodan (motor de recon pasivo: consulta su base de datos de dispositivos expuestos sin mandar un paquete al objetivo). El patrón que sacas aquí vale para **cualquier** API — Censys, VirusTotal, la API de un WAF.

## La estructura: cliente como librería

La idea es separar la lógica del cliente (reutilizable) del programa que la consume. Un layout típico (recuerda [[01 - Entorno moderno y módulos]]):

```text
shodan-tool/
├── cmd/shodan/main.go   # el programa: parsea flags y usa la librería
└── shodan/              # la librería reutilizable
    ├── shodan.go        # Client, constructor, opciones
    └── host.go          # tipos de respuesta + métodos por endpoint
```

El corazón es un struct `Client` que <mark style="background: #ADCCFFA6;">guarda lo que se repite en cada llamada</mark> — la API key, la URL base y, la mejora clave sobre el libro, **su propio `*http.Client` con timeout** (nota [[00 - El cliente HTTP de Go]]):

```go
type Client struct {
    apiKey  string
    baseURL string
    http    *http.Client
}
```

## El constructor idiomático: functional options

El libro usa `func New(apiKey string) *Client`. Funciona, pero en cuanto quieras configurar el timeout, la URL base (para tests) o inyectar un cliente HTTP con proxy, tendrías que romper la firma. El patrón idiomático de Go es **functional options**: el constructor toma la key y una lista variádica de opciones.

```go
const defaultBaseURL = "https://api.shodan.io"

type Option func(*Client)

func WithHTTPClient(h *http.Client) Option { return func(c *Client) { c.http = h } }
func WithBaseURL(u string) Option          { return func(c *Client) { c.baseURL = u } }

func New(apiKey string, opts ...Option) *Client {
    c := &Client{
        apiKey:  apiKey,
        baseURL: defaultBaseURL,
        http:    &http.Client{Timeout: 15 * time.Second},   // default sensato
    }
    for _, opt := range opts {
        opt(c)
    }
    return c
}
```

<mark style="background: #8000E1A6;">Añadir una opción nueva es añadir una función `WithX`, sin tocar las llamadas existentes</mark> — la API crece sin romper nada. Quien no configura nada recibe defaults razonables; quien lo necesita, ajusta:

```go
c := shodan.New(apiKey)                                  // defaults
c := shodan.New(apiKey, shodan.WithHTTPClient(proxied))  // cliente con proxy Burp
```

## Structs de respuesta: solo lo que te importa

Defines un struct con los campos del JSON que vas a usar y **Go ignora el resto** (nota [[12 - JSON, XML y datos estructurados]]). La respuesta de Shodan trae decenas de campos anidados; te quedas con lo justo:

```go
type HostSearch struct {
    Matches []Host `json:"matches"`
}

type Host struct {
    IPString string `json:"ip_str"`
    Port     int    `json:"port"`
    Org      string `json:"org"`
    // ...solo lo relevante; los campos que no declares se descartan al decodificar
}
```

## Los métodos: `ctx` y URL-encoding

Cada endpoint es un método sobre `*Client`. Toma un `context` (para timeout/cancelación) y construye la petición con `NewRequestWithContext`. Aquí corrijo un **bug del libro**: su `HostSearch` mete la query cruda en la URL con `fmt.Sprintf`, así que una búsqueda con espacios o símbolos (`apache country:ES`) rompe la URL. La forma correcta es `url.Values`, que **encodea** los parámetros:

```go
func (c *Client) HostSearch(ctx context.Context, query string) (*HostSearch, error) {
    params := url.Values{}
    params.Set("key", c.apiKey)
    params.Set("query", query)                      // encodea espacios y símbolos
    endpoint := c.baseURL + "/shodan/host/search?" + params.Encode()

    req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
    if err != nil {
        return nil, err
    }
    resp, err := c.http.Do(req)
    if err != nil {
        return nil, fmt.Errorf("shodan host search: %w", err)   // wrapping, nota 11
    }
    defer resp.Body.Close()

    var out HostSearch
    if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
        return nil, err
    }
    return &out, nil
}
```

<mark style="background: #FFB86CA6;">Encodear no es solo cosmético: la query de Shodan usa filtros con `:` y espacios</mark> (`port:445 country:ES product:samba`), y sin `url.Values` esos caracteres corrompen la petición o inyectan parámetros no deseados.

## API key por variable de entorno

Un detalle que el libro sí hace bien y conviene subrayar: <mark style="background: #FF5582A6;">la API key nunca va hardcodeada</mark> en el código — acabaría en el historial de git, en logs y en cualquier copia del repo. Se lee del entorno:

```go
apiKey := os.Getenv("SHODAN_API_KEY")
if apiKey == "" {
    log.Fatalln("falta SHODAN_API_KEY")
}
c := shodan.New(apiKey)
res, err := c.HostSearch(ctx, "product:samba country:ES")
```

La misma regla aplica a cualquier secreto que maneje tu tooling (tokens, contraseñas de RPC) — lo verás enseguida con la password de Metasploit.

Este cliente REST/JSON es el caso fácil. El siguiente es más retorcido: un RPC binario sobre MessagePack para pilotar Metasploit → [[02 - RPC con Metasploit (MessagePack)]].
