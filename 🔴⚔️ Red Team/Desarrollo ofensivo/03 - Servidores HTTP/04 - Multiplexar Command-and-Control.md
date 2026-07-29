---
tags:
  - Go
  - Go/HTTP
  - C2
Descripción: "El último tema del capítulo monta infraestructura de Command and Control (C2): un servidor que multiplexa varias conexiones de mando y control hacia distintos *listeners* de…"
Fecha de actualización: 2026-07-24
Nota previa: "[[03 - Keylogging con WebSockets]]"
Nota siguiente: 
Area: "[[Servidores HTTP.base|Servidores HTTP]]"
---
---

El último tema del capítulo monta infraestructura de **Command and Control (C2)**: un servidor que multiplexa varias conexiones de mando y control hacia distintos *listeners* de backend. En la práctica es un **reverse proxy** que enruta por la cabecera `Host` — la misma idea del *virtual hosting* — actuando de **redirector** delante de tus listeners reales. Es la base de la infraestructura de C2, que se desarrolla a fondo en [[Command and Control.base|Command and Control]] (Cap. 14).

## El redirector: por qué

En vez de exponer tu servidor de C2 directo a internet, pones delante un redirector que reenvía el tráfico. <mark style="background: #ADCCFFA6;">Solo el redirector es visible; tus listeners de Metasploit/Sliver quedan ocultos</mark>. Tres ventajas:

- **Si el redirector se quema** (lo meten en una blocklist), lo mueves sin tocar el C2 — no pierdes las sesiones.
- **Un solo host/puerto para un equipo**: varios operadores atacando distintos objetivos comparten el redirector en 80/443, y este enruta cada implante a su listener.
- **Egress**: 80 y 443 son los puertos que casi siempre salen, así que el redirector escucha ahí y multiplexa por dentro.

El implante se genera apuntando al redirector (con un `Host` header concreto), no al C2 real; el proxy usa ese `Host` para decidir el backend.

## Reverse proxy en Go: `httputil.ReverseProxy`

Go trae el reverse proxy hecho en `net/http/httputil`, así que no lo montas a mano. El libro usa `httputil.NewSingleHostReverseProxy(url)`, que sigue funcionando; pero por dentro configura el campo `Director`, <mark style="background: #FF5582A6;">deprecado en Go 1.26 en favor de `Rewrite`</mark>. La versión moderna usa `Rewrite`, que además evita una clase de fugas de cabeceras (`X-Forwarded-*`):

```go
backends := map[string]string{
    "cdn.attacker1.com": "http://10.0.1.20:10080",   // listener real 1, oculto
    "cdn.attacker2.com": "http://10.0.1.20:20080",   // listener real 2, oculto
}

mux := http.NewServeMux()
for host, target := range backends {
    remote, err := url.Parse(target)
    if err != nil {
        log.Fatal(err)
    }
    proxy := &httputil.ReverseProxy{
        Rewrite: func(pr *httputil.ProxyRequest) {   // Go 1.26: reemplaza a Director
            pr.SetURL(remote)
            pr.SetXForwarded()
        },
    }
    mux.Handle(host+"/", proxy)   // enruta por Host header
}
```

## Routing por `Host` header sin gorilla

El libro necesita `gorilla/mux` para enrutar por host (`r.Host(host).Handler(proxy)`). Con la stdlib de Go 1.22 (nota [[00 - Servidor HTTP con net-http]]) el propio patrón lleva el host: <mark style="background: #8000E1A6;">`mux.Handle("cdn.attacker1.com/", proxy)` enruta por `Host` de forma nativa</mark>. El `ReverseProxy` satisface `http.Handler`, así que encaja directo como handler de cada host. Y como los backends se declaran dentro del bucle, la captura en la closure `Rewrite` es segura (loopvar de Go 1.22, nota [[04 - Estructuras de control]]).

## Domain fronting está muerto

Aquí el libro necesita una actualización importante. Recomienda usar este montaje para **domain fronting** — abusar de un dominio de confianza de un CDN para saltar controles de egress. <mark style="background: #FF5582A6;">El domain fronting está esencialmente muerto desde 2018-2020</mark>: AWS CloudFront, Google Cloud y Azure lo desactivaron obligando a que el SNI del TLS coincida con la cabecera `Host`. Lo que sigue vivo:

- **Redirectores en CDN** (sin fronting): un CloudFront/Cloudflare legítimo delante de tu C2, que aporta reputación e IPs compartidas.
- **Domain borrowing** y redirección por **categoría de dominio** (dominios con buena reputación en los proxies corporativos).
- **Perfiles de tráfico maleables** (malleable C2) que imitan servicios legítimos.

> [!info]+ El patrón, no la técnica concreta
> El multiplexado por `Host` que aprendes aquí sigue siendo la pieza central de un redirector de C2 en 2026 — lo que cambia es la técnica de evasión que montas encima. Esa metodología (redirectores, malleable C2, elección de dominios) vive en Red Team: la evasión de C2 a fondo —incluida la muerte del domain fronting con fechas por CDN— está en [[11 - Detección, prevención y evasión|detección y evasión de C2]]. Aquí tienes el motor en Go.

---

Con esto cierras el Cap. 4 y todo el ciclo HTTP (cliente + servidor). Sabes montar servidores endurecidos, enrutar y encadenar middleware, servir contenido seguro con plantillas, y construir las tres piezas ofensivas —harvester, keylogger, redirector de C2— que sostienen una campaña. El siguiente protocolo es tan abusado como el HTTP y aún menos vigilado: **DNS**, donde replicarás este mismo truco de C2 pero sobre resolución de nombres → [[DNS.base|DNS]] (Cap. 5).
