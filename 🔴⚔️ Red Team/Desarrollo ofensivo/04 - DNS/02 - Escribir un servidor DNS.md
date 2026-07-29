---
tags:
  - Go
  - Go/DNS
  - DNS
Descripción: "Del cliente al servidor: escribir tu propio servidor DNS. Es la base de varias técnicas ofensivas — spoofing (responder mentiras a las consultas), rogue access points con portal…"
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Enumeración concurrente de subdominios]]"
Nota siguiente: "[[03 - DNS tunneling y multiplexado de C2]]"
Area: "[[DNS.base|DNS]]"
---
---

Del cliente al servidor: escribir tu propio servidor DNS. Es la base de varias técnicas ofensivas — **spoofing** (responder mentiras a las consultas), **rogue access points** con portal cautivo, y el **proxy de tunneling C2** de la nota siguiente. `miekg/dns` lo hace casi tan sencillo como montar un servidor HTTP (nota [[00 - Servidor HTTP con net-http]]): registras un handler y escuchas.

## El handler: responder consultas

El patrón calca al de `net/http`: `dns.HandleFunc(patrón, handler)`, donde el patrón `"."` captura **todas** las consultas. El handler recibe un `dns.ResponseWriter` y la petición, construye una respuesta y la escribe.

```go
func handler(w dns.ResponseWriter, req *dns.Msg) {
    var resp dns.Msg
    resp.SetReply(req)                    // ata la respuesta a la pregunta (IDs, flags)
    for _, q := range req.Question {
        rr := &dns.A{
            Hdr: dns.RR_Header{
                Name:   q.Name,
                Rrtype: dns.TypeA,
                Class:  dns.ClassINET,
                Ttl:    0,
            },
            A: net.ParseIP("127.0.0.1").To4(),   // TODA consulta -> 127.0.0.1
        }
        resp.Answer = append(resp.Answer, rr)
    }
    w.WriteMsg(&resp)
}
```

<mark style="background: #ADCCFFA6;">`SetReply` prepara la respuesta copiando el ID y las flags de la pregunta</mark>; tú solo añades los registros al `Answer`. Este servidor responde `127.0.0.1` a cualquier cosa — la base de un ataque de spoofing donde rediriges nombres a tu propia IP.

## Construir registros: a mano vs `dns.NewRR`

Montar el `dns.A` con su `RR_Header` a mano (como el libro) es verboso. `miekg/dns` permite **parsear un registro desde sintaxis de fichero de zona**, mucho más legible:

```go
rr, err := dns.NewRR(q.Name + " 3600 IN A 127.0.0.1")   // "nombre TTL clase tipo dato"
if err == nil {
    resp.Answer = append(resp.Answer, rr)
}
```

<mark style="background: #FFB8EBA6;">`dns.NewRR` acepta cualquier tipo</mark> (`"ejemplo.com 300 IN TXT \"datos\""`, `MX`, `CNAME`…), así que un servidor que responde varios tipos no necesita un struct distinto por cada uno.

## Arrancar: `dns.Server` sobre `ListenAndServe`

El libro arranca con `dns.ListenAndServe(":53", "udp", nil)`. Funciona, pero <mark style="background: #FFB86CA6;">el puerto 53 es privilegiado</mark>, así que el servidor necesita `root` (o `CAP_NET_BIND_SERVICE`). Para control fino —timeouts, apagado limpio, TCP **y** UDP a la vez— usa el struct `dns.Server`:

```go
srv := &dns.Server{Addr: ":53", Net: "udp"}
log.Fatal(srv.ListenAndServe())   // srv.Shutdown(ctx) para apagado ordenado
```

> [!warning]+ Choca con el resolver del sistema
> En Linux, un `systemd-resolved` o `dnsmasq` local ya ocupa el 53 y tu servidor no arrancará. Hay que pararlo antes (el libro mata `dnsmasq`; en 2026 suele ser `systemd-resolved`). En un engagement real, esto es relevante en un host que controlas y usas como servidor DNS malicioso.

## Para qué sirve un servidor DNS propio

- **Spoofing**: responder IPs falsas para redirigir tráfico (combínalo con envenenamiento LLMNR/NBNS o un rogue AP). La técnica vive en Red Team.
- **Rogue AP / portal cautivo**: un DNS que resuelve todo a tu IP fuerza a los clientes a tu página de captura.
- **Servidor autoritativo para tunneling**: el extremo que recibe las consultas codificadas de un canal C2 por DNS — justo lo que monta la nota [[03 - DNS tunneling y multiplexado de C2]].

Y ese es el siguiente paso: convertir el servidor en un **proxy** que multiplexa consultas de C2 hacia distintos backends, y usar DNS como canal de mando fuera de una red restringida → [[03 - DNS tunneling y multiplexado de C2]].
