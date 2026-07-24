---
tags:
  - Go
  - Go/HTTP
  - API
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Diseñar un cliente de API - el caso Shodan]]"
Nota siguiente: "[[03 - Scraping HTML - metadatos con goquery]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Metasploit expone una **API RPC** para pilotarlo en remoto: listar sesiones Meterpreter, lanzar módulos, gestionar el workspace. El patrón de cliente es el mismo que el de Shodan ([[01 - Diseñar un cliente de API - el caso Shodan]]), pero con un giro: en vez de JSON habla **MessagePack**, un formato binario compacto. Es un buen ejemplo de que, en Go, cambiar de formato de serialización apenas cambia el código. La herramienta a fondo está en [[Metasploit.base|Metasploit]]; aquí, cómo hablar con ella desde Go.

## MessagePack y el truco de `as_array`

Go no trae MessagePack en la stdlib. El libro instala `gopkg.in/vmihailenco/msgpack.v2`; <mark style="background: #FF5582A6;">ese módulo está muerto — usa `github.com/vmihailenco/msgpack/v5`</mark>, la versión mantenida:

```shell-session
$ go get github.com/vmihailenco/msgpack/v5
```

El RPC de Metasploit espera cada petición como un **array posicional** (`["auth.login", "user", "pass"]`), no como un mapa clave/valor. Por defecto, msgpack serializa un struct como mapa; para forzar el array se añade un campo especial `_msgpack` con el descriptor `,as_array`:

```go
type loginReq struct {
    _msgpack struct{} `msgpack:",as_array"`   // fuerza ["auth.login", user, pass]
    Method   string
    Username string
    Password string
}

type loginRes struct {
    Result       string `msgpack:"result"`
    Token        string `msgpack:"token"`
    Error        bool   `msgpack:"error"`
    ErrorMessage string `msgpack:"error_message"`
}
```

<mark style="background: #ADCCFFA6;">Los struct tags de msgpack funcionan igual que los de JSON</mark> (nota [[12 - JSON, XML y datos estructurados]]): mismo mecanismo, distinto encoder. La respuesta sí es un mapa, así que sus campos llevan nombre.

## El método `send()` genérico

Para no repetir la fontanería de serializar/enviar/deserializar en cada llamada, se centraliza en un método `send` que acepta cualquier request y response con `any`:

```go
type Metasploit struct {
    host  string
    user  string
    pass  string
    token string
    http  *http.Client   // reutilizado, con timeout (mejora sobre el libro)
}

func (m *Metasploit) send(ctx context.Context, req, res any) error {
    var buf bytes.Buffer
    if err := msgpack.NewEncoder(&buf).Encode(req); err != nil {
        return err
    }
    url := fmt.Sprintf("http://%s/api", m.host)
    httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, &buf)
    if err != nil {
        return err
    }
    httpReq.Header.Set("Content-Type", "binary/message-pack")

    resp, err := m.http.Do(httpReq)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    return msgpack.NewDecoder(resp.Body).Decode(res)   // escribe en *res
}
```

<mark style="background: #8000E1A6;">`res any` recibe un puntero y `send` lo rellena decodificando</mark>, así que la misma función sirve para cualquier método RPC sin conocer los tipos concretos. El libro usa `interface{}`; en 2026 es `any`, y el cliente HTTP lleva timeout (nota [[00 - El cliente HTTP de Go]]).

## Autenticación: login → token → logout

Casi todos los métodos RPC exigen un **token** que se obtiene con `auth.login`. El token se guarda en el struct y viaja en las llamadas siguientes; `auth.logout` lo expira.

```go
func (m *Metasploit) Login(ctx context.Context) error {
    req := &loginReq{Method: "auth.login", Username: m.user, Password: m.pass}
    var res loginRes
    if err := m.send(ctx, req, &res); err != nil {
        return err
    }
    if res.Error {
        return fmt.Errorf("login rechazado: %s", res.ErrorMessage)   // el libro NO comprueba esto
    }
    m.token = res.Token
    return nil
}
```

> [!warning]+ El `Login` del libro traga los fallos lógicos
> El `Login()` del libro guarda `res.Token` sin mirar el campo `Error` de la respuesta. Si la password es incorrecta, Metasploit responde con `error: true` y **sin token**, pero el código sigue como si nada y guarda un token vacío — el fallo estalla más tarde, lejos de su causa. <mark style="background: #FF5582A6;">Comprueba el error lógico de la API, no solo el error de transporte.</mark>

El constructor hace el login como parte del *bootstrapping*, así cualquier método autenticado ya tiene token:

```go
func New(ctx context.Context, host, user, pass string) (*Metasploit, error) {
    m := &Metasploit{
        host: host, user: user, pass: pass,
        http: &http.Client{Timeout: 30 * time.Second},
    }
    if err := m.Login(ctx); err != nil {
        return nil, err
    }
    return m, nil
}
```

## Un método de negocio: `SessionList`

Con el token en su sitio, un método real. `session.list` devuelve un mapa `id → detalles`; se aplana metiendo el ID dentro de cada valor:

```go
func (m *Metasploit) SessionList(ctx context.Context) (map[uint32]SessionListRes, error) {
    req := &sessionListReq{Method: "session.list", Token: m.token}
    res := make(map[uint32]SessionListRes)
    if err := m.send(ctx, req, &res); err != nil {
        return nil, err
    }
    for id, s := range res {   // la clave es el ID de sesión -> lo incrustamos en el valor
        s.ID = id
        res[id] = s
    }
    return res, nil
}
```

Añadir otro método RPC es solo definir sus structs de request/response y una función de tres líneas que llame a `send`.

## Secretos por entorno y limpieza

Igual que la API key de Shodan, el host y la password del RPC van por **variable de entorno**, nunca hardcodeados. Y `defer m.Logout(ctx)` expira el token al salir:

```go
host, pass := os.Getenv("MSFHOST"), os.Getenv("MSFPASS")
m, err := rpc.New(ctx, host, "msf", pass)
if err != nil {
    log.Fatalln(err)
}
defer m.Logout(ctx)
```

> [!info]+ Metasploit moderno
> El plugin `msgrpc` con MessagePack sigue funcionando, pero Metasploit ofrece hoy también un demonio RPC con **JSON-RPC** (`msfrpcd`), más cómodo de consumir. El patrón que aprendes aquí —token de auth, `send` genérico, un método por operación— transfiere igual; solo cambiarías el encoder de msgpack a JSON.

El último caso del capítulo abandona las APIs estructuradas: cuando no hay API, toca **scraping** de HTML → [[03 - Scraping HTML - metadatos con goquery]].
