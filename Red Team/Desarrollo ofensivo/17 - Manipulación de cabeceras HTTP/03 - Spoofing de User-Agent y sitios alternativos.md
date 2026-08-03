---
tags:
  - Go
  - Go/Web
  - Evasion
Descripción: "El servidor te sirve contenido distinto según quién dices ser: el User-Agent decide móvil vs escritorio vs bot, y cabeceras como X-Forwarded-For deciden si te ve como interno"
Fecha de actualización: 2026-07-26
Nota previa: "[[02 - Cookies inseguras y session fixation]]"
Nota siguiente: 
Area: "[[Manipulación de cabeceras HTTP.base|Manipulación de cabeceras HTTP]]"
---
---

El servidor te sirve contenido distinto según **quién dices ser**: el `User-Agent` decide móvil vs escritorio vs bot, y cabeceras como `X-Forwarded-For` deciden si te ve como interno. Cambiando esa identidad descubres **sitios alternativos** (una versión móvil con seguridad más floja, endpoints legacy) o saltas control de acceso por IP. La metodología de evasión vive en Red Team [[27 - Evasión en recon y fuzzing]]; aquí el detector en Go.

> [!info]+ Fuente
> Receta "Identifying alternative sites by spoofing user agents" de *Python Web Penetration Testing Cookbook* (2015), ampliada con bypass de acceso por cabeceras.

## Diferencias por User-Agent

Pides la misma URL con varios `User-Agent` y comparas las respuestas por hash. Si el móvil difiere del escritorio, hay dos aplicaciones que auditar; si Googlebot ve algo distinto, hay *cloaking* o render SSR privilegiado:

```go
var userAgents = map[string]string{
    "desktop":   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "mobile":    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
    "googlebot": "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
}

type snapshot struct {
    Status int
    Length int64
    Hash   [32]byte
}

func fetchAs(ctx context.Context, client *http.Client, target, ua string) (snapshot, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
    if err != nil {
        return snapshot{}, err
    }
    req.Header.Set("User-Agent", ua)
    resp, err := client.Do(req)
    if err != nil {
        return snapshot{}, err
    }
    defer resp.Body.Close()
    body, _ := io.ReadAll(resp.Body)
    return snapshot{resp.StatusCode, int64(len(body)), sha256.Sum256(body)}, nil
}
```

<mark style="background: #ADCCFFA6;">Hashes distintos entre `desktop` y `mobile`</mark> = versiones separadas del sitio. La móvil suele arrastrar endpoints viejos o menos hardening — vale la pena auditar las dos.

## El ángulo moderno: bypass de acceso por cabeceras

Lo que el libro de 2015 no explota: muchas apps confían en cabeceras de proxy para decidir el acceso. Un endpoint que da `403` desde fuera puede abrirse si **declaras** ser interno:

```go
var bypassHeaders = []map[string]string{
    {"X-Forwarded-For": "127.0.0.1"},
    {"X-Real-IP": "127.0.0.1"},
    {"X-Forwarded-Host": "localhost"},
    {"X-Original-URL": "/admin"},     // algunos reverse proxies reenrutan por esto
    {"X-Rewrite-URL": "/admin"},
}
```

Pruebas cada set contra el endpoint protegido y comparas el status contra el baseline `403`. <mark style="background: #FF5582A6;">Si uno devuelve `200`, la autorización se apoya en una cabecera que tú controlas</mark> — bypass. Es primo de los Host Header Attacks (Red Team [[07 - Bypass de autenticación por Host Header]]).

## Modernizaciones sobre el recetario

- **Diffing por hash SHA-256** del body para detectar versiones alternativas objetivamente, no a ojo.
- <mark style="background: #FFB86CA6;">Bypass de acceso por `X-Forwarded-For` / `X-Original-URL`</mark>, el vector real de 2026 que el original no cubre.
- **`context` + cliente reutilizado**, y trivial de paralelizar con el [[00 - Patrón worker pool y rate limiting|motor de barrido]] si pruebas muchos UAs/cabeceras.

> [!warning]+ No confíes en cabeceras del cliente (el otro lado)
> Todo esto funciona porque el servidor **confía** en cabeceras que el cliente controla — el anti-patrón de seguridad de fondo. Cuando reportes, el fix es que el servidor **nunca** derive identidad, IP real o autorización de `X-Forwarded-For`, `User-Agent` ni `Host` sin validar en el borde. Es la misma lección de [[00 - Servidor HTTP con net-http|montar servidores]] con cabeza.

---

Con esto cierras el **arco de tooling web en Go**: recon (crawler, screenshots, fingerprinting), enumeración y fuerza bruta, escáner de vulnerabilidades, SQL Injection ciega y manipulación de cabeceras — todo reconvertido y modernizado desde el recetario de Python, con la técnica explicada en Red Team y la implementación aquí. El índice del proyecto está en [[GO.base|GO]].
