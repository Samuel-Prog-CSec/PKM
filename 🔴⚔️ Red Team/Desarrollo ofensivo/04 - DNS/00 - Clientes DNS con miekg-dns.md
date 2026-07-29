---
tags:
  - Go
  - Go/DNS
  - DNS
  - Tipo/Introduccion
Descripción: "DNS es un arma de recon, C2 y exfiltración en un protocolo que casi todas las redes dejan salir y pocas vigilan de verdad"
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - Enumeración concurrente de subdominios]]"
Area: "[[DNS.base|DNS]]"
---
---

DNS es un arma de recon, C2 y exfiltración en un protocolo que casi todas las redes dejan salir y pocas vigilan de verdad. Este bloque construye clientes, servidores y un canal de tunneling en Go. Empezamos por el cliente: resolver nombres y registros con control total sobre qué servidor consultas y qué respuestas inspeccionas.

## Por qué `miekg/dns` y no la stdlib

Go trae resolución DNS en `net` (`net.Resolver`, `net.LookupHost`), pero <mark style="background: #FFB8EBA6;">tiene dos límites que matan su uso ofensivo</mark>: usa el resolver configurado en el SO (apuntar a un servidor concreto solo es posible, de forma incómoda, vía `Resolver.Dial`) y no te deja inspeccionar los registros crudos (solo te devuelve IPs o strings ya masticados).

Para tooling necesitas `github.com/miekg/dns`, la librería DNS de referencia en Go (madura, muy probada, la base de herramientas como CoreDNS). Te deja **elegir el servidor**, construir **cualquier tipo de query** e inspeccionar **cada registro** de la respuesta. Es una de las pocas veces que la regla "stdlib primero" (nota [[00 - El cliente HTTP de Go]]) cede ante una librería externa, con razón.

## Una consulta: `Msg`, `SetQuestion`, `Exchange`

El flujo básico: creas un `dns.Msg`, le pones la pregunta y lo intercambias con un servidor.

```go
var m dns.Msg
m.SetQuestion(dns.Fqdn("stacktitan.com"), dns.TypeA)   // A record de un FQDN
in, err := dns.Exchange(&m, "8.8.8.8:53")               // consulta a 8.8.8.8
```

`dns.Fqdn` añade el punto final que exige el protocolo (`stacktitan.com.`). <mark style="background: #ADCCFFA6;">El `dns.Msg` es la estructura central: contiene tanto la pregunta como la respuesta</mark>. Sus campos clave son `Question`, `Answer` (los registros de respuesta), `Ns` (autoridad) y `Extra` (adicionales).

## Procesar respuestas: `RR` y type assertions

`Answer` es un `[]dns.RR`, y `RR` es una **interfaz** (nota [[10 - Interfaces]]) que no expone los datos del registro directamente. Para leer una IP tienes que hacer un **type assertion** al tipo concreto:

```go
for _, rr := range in.Answer {
    if a, ok := rr.(*dns.A); ok {   // ¿es un registro A? -> accede a sus campos
        fmt.Println(a.A)            // a.A es un net.IP
    }
}
```

Cada tipo de registro tiene su struct (`*dns.A`, `*dns.CNAME`, `*dns.MX`, `*dns.TXT`…), y el type switch (nota [[10 - Interfaces]]) es la forma limpia de manejar varios a la vez.

## Modernizar: `dns.Client` con timeout

El libro usa `dns.Exchange`, que <mark style="background: #FF5582A6;">no tiene timeout</mark> — el mismo footgun que el cliente HTTP por defecto (nota [[00 - El cliente HTTP de Go]]). Un servidor DNS que no responde te cuelga la herramienta. La versión con control usa `dns.Client`:

```go
func lookupA(fqdn, server string) ([]string, error) {
    var m dns.Msg
    m.SetQuestion(dns.Fqdn(fqdn), dns.TypeA)

    c := &dns.Client{Timeout: 3 * time.Second}   // timeout de verdad
    in, _, err := c.Exchange(&m, server)          // devuelve (resp, rtt, err)
    if err != nil {
        return nil, err
    }
    var ips []string
    for _, rr := range in.Answer {
        if a, ok := rr.(*dns.A); ok {
            ips = append(ips, a.A.String())
        }
    }
    return ips, nil
}
```

`dns.Client` te da además el campo `Net`: `"tcp"` fuerza TCP (necesario para respuestas grandes que no caben en UDP), y `"tcp-tls"` habla **DNS-over-TLS (DoT)** cifrado:

```go
c := &dns.Client{Net: "tcp-tls", Timeout: 3 * time.Second}
in, _, err := c.Exchange(&m, "1.1.1.1:853")   // DoT contra Cloudflare
```

> [!info]+ DoT/DoH en tooling
> `miekg/dns` soporta DoT nativo (`Net: "tcp-tls"`) y hay helpers para DNS-over-HTTPS (DoH). Para un cliente que quiere pasar desapercibido, salir por DoH (puerto 443, indistinguible de HTTPS normal) evita la inspección de DNS en claro — algo que retomamos en el tunneling ([[03 - DNS tunneling y multiplexado de C2]]).

## Tipos de registro

| Tipo | Constante | Qué devuelve |
| - | - | - |
| A / AAAA | `dns.TypeA` / `dns.TypeAAAA` | IPv4 / IPv6 |
| CNAME | `dns.TypeCNAME` | Alias (otro FQDN) |
| MX | `dns.TypeMX` | Servidores de correo |
| TXT | `dns.TypeTXT` | Texto arbitrario (SPF, DKIM… y **datos exfiltrados**) |
| NS | `dns.TypeNS` | Servidores autoritativos |
| PTR | `dns.TypePTR` | Resolución inversa (IP → nombre) |

Con el cliente dominado, el primer tool real: una utilidad que enumera subdominios de forma masivamente concurrente → [[01 - Enumeración concurrente de subdominios]].
