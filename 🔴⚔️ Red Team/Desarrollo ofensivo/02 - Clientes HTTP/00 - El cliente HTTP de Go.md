---
tags:
  - Go
  - Go/HTTP
  - HTTP
  - Tipo/Introduccion
Descripción: "HTTP es el protocolo con el que hablan casi todas las APIs y servicios que te interesan como pentester"
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - Diseñar un cliente de API - el caso Shodan]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

HTTP es el protocolo con el que hablan casi todas las APIs y servicios que te interesan como pentester: Shodan, el RPC de Metasploit, la API de un WAF, un panel de administración. Go trae un cliente HTTP completo en la stdlib (`net/http`) — no necesitas `requests` ni librerías externas. Pero el libro usa varios patrones que en 2026 son footguns; esta nota es el cliente HTTP **hecho bien**.

## Peticiones simples

Para un GET rápido, las funciones de conveniencia bastan:

```go
resp, err := http.Get("https://api.target.com/status")
resp, err := http.Head("https://api.target.com/")
resp, err := http.Post(url, "application/json", body)   // body es un io.Reader
```

Son cómodas para un script de usar y tirar, pero <mark style="background: #FF5582A6;">usan el cliente HTTP por defecto, que **no tiene timeout**</mark> (lo vemos abajo). Y no hay funciones de conveniencia para `PUT`, `PATCH` o `DELETE` — para esos, y para cualquier tool serio, construyes la petición a mano.

## Peticiones a medida: `NewRequestWithContext`

El patrón general es crear una `*http.Request` y enviarla con `client.Do(req)`. El libro usa `http.NewRequest(method, url, body)`; <mark style="background: #FFB8EBA6;">la versión moderna es `http.NewRequestWithContext`</mark>, que ata la petición a un `context` para poder cancelarla o ponerle deadline (nota [[13 - Goroutines, channels y concurrencia]]):

```go
req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
if err != nil {
    return err
}
req.Header.Set("User-Agent", "Mozilla/5.0 (compatible)")   // cabeceras a medida
req.Header.Set("Authorization", "Bearer "+token)
```

El tercer parámetro es el body como `io.Reader` (nota [[10 - Interfaces]]): `nil` si no hay, o `strings.NewReader(...)` / `bytes.NewBuffer(...)` para enviarlo. Usa las constantes `http.MethodGet`, `http.MethodPost`… en vez de strings sueltos.

## El footgun del cliente sin timeout

Aquí está el error más peligroso del código del libro. `http.Get` y `var client http.Client` usan un cliente **sin timeout**: si el servidor acepta la conexión pero no responde, <mark style="background: #FF5582A6;">tu herramienta se queda colgada para siempre</mark>. En un escáner que golpea miles de hosts, uno solo malicioso o caído te congela. **Siempre** pon timeout:

```go
client := &http.Client{
    Timeout: 10 * time.Second,   // límite total: conexión + envío + respuesta
}
```

Y <mark style="background: #8000E1A6;">reutiliza un único `http.Client`</mark> en toda la herramienta: mantiene un pool de conexiones (keep-alive) y reaprovecha sockets. Crear un cliente por petición desperdicia conexiones. El `context` da control fino por-petición **además** del timeout global del cliente.

## Procesar la respuesta

Tres reglas que el libro cumple a medias:

```go
resp, err := client.Do(req)
if err != nil {
    return err
}
defer resp.Body.Close()   // 1. cerrar el body SIEMPRE, justo tras comprobar err

if resp.StatusCode != http.StatusOK {   // 2. Do() no falla por un 404/500
    return fmt.Errorf("status inesperado: %s", resp.Status)
}

var data Result           // 3. decodificar en streaming desde el body
if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
    return err
}
```

- <mark style="background: #FFB86CA6;">`defer resp.Body.Close()` va inmediatamente tras el `if err`</mark>: si no cierras el body, la conexión no se reutiliza y filtras descriptores.
- **`Do()` solo devuelve error por fallos de transporte** (DNS, conexión, timeout), no por códigos HTTP de error. Un `404` o `500` llega con `err == nil` — comprueba `resp.StatusCode` a mano.
- Para leer el body crudo, `io.ReadAll(resp.Body)` — **no** `ioutil.ReadAll`, que está deprecado desde Go 1.16. Para JSON/XML, `json.NewDecoder(resp.Body).Decode(...)` decodifica directo del stream sin buffer intermedio (nota [[12 - JSON, XML y datos estructurados]]).

## OPSEC del cliente HTTP

Dos ajustes que importan en un engagement:

- **User-Agent**: por defecto Go envía `Go-http-client/1.1`, una firma que cualquier WAF o log marca al instante como tráfico automatizado. Fija un `User-Agent` creíble (o el que exija tu tapadera).
- **Verificación TLS**: por defecto Go **valida** el certificado, lo correcto para hablar con una API real. Solo desactívala **a propósito** cuando ataques un objetivo con certificado autofirmado, y consciente del riesgo:

```go
// Solo para objetivos con cert autofirmado en un engagement autorizado:
tr := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}
client := &http.Client{Transport: tr, Timeout: 10 * time.Second}
```

> [!warning]+ `InsecureSkipVerify` no es el default por algo
> Desactivar la validación TLS te expone a *man-in-the-middle*. Actívalo solo contra objetivos concretos donde sabes que el cert es autofirmado, nunca "por comodidad" en un cliente que habla con APIs de terceros.

Con el cliente HTTP dominado, el siguiente paso es empaquetarlo en algo reutilizable: un cliente de API bien diseñado, con el caso de Shodan → [[01 - Diseñar un cliente de API - el caso Shodan]].
