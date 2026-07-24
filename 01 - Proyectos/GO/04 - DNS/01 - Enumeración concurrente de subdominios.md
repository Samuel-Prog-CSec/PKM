---
tags:
  - Go
  - Go/DNS
  - Enumeracion
Fecha de actualización: 2026-07-24
Nota previa: "[[00 - Clientes DNS con miekg-dns]]"
Nota siguiente: "[[02 - Escribir un servidor DNS]]"
Area: "[[DNS.base|DNS]]"
---
---

La utilidad estrella del capítulo: adivinar los subdominios de un objetivo a partir de un diccionario. <mark style="background: #FFB86CA6;">Cuantos más subdominios conozcas, más superficie de ataque tienes</mark> — un `vpn.`, `dev.`, `jenkins.` o `mail.` puede ser la puerta de entrada. El libro hace fuerza bruta pura; aquí la modernizamos con `errgroup`, tapamos dos agujeros que el libro deja (wildcard y metodología) y la situamos en el enfoque de recon de 2026.

## El núcleo: resolver siguiendo el rastro de CNAME

Un subdominio suele apuntar a un `CNAME` (alias) que a su vez apunta a otro, hasta llegar a un registro `A`. La resolución sigue ese rastro:

```go
func resolve(fqdn, server string) []string {
    cfqdn := fqdn
    for {
        cnames, err := lookupCNAME(cfqdn, server)
        if err == nil && len(cnames) > 0 {
            cfqdn = cnames[0]
            continue                 // sigue el CNAME
        }
        ips, err := lookupA(cfqdn, server)
        if err != nil {
            return nil               // fin del rastro sin A -> no resuelve
        }
        return ips                   // A encontrado
    }
}
```

`lookupA` y `lookupCNAME` son las funciones de la nota [[00 - Clientes DNS con miekg-dns]] con `dns.TypeA` y `dns.TypeCNAME`.

## Concurrencia: del worker-pool a `errgroup`

El libro monta un pool de goroutines con **tres canales** (`fqdns`, `gather`, `tracker`) y un `type empty struct{}` para señalizar el final — la misma fontanería que el port scanner del Cap. 2. Y la misma modernización aplica: `errgroup` con `SetLimit` (nota [[01 - Escáner TCP - de secuencial a concurrente]]) hace lo mismo en una fracción del código.

```go
func enumerate(ctx context.Context, domain, server string, words []string) []result {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(100)                    // nº de resoluciones simultáneas

    var mu sync.Mutex
    var found []result
    for _, w := range words {
        fqdn := w + "." + domain
        g.Go(func() error {
            ips := resolve(fqdn, server)
            if len(ips) == 0 {
                return nil
            }
            mu.Lock()
            for _, ip := range ips {
                found = append(found, result{Hostname: fqdn, IPAddress: ip})
            }
            mu.Unlock()
            return nil
        })
    }
    g.Wait()
    return found
}
```

<mark style="background: #8000E1A6;">El `SetLimit` es velocidad **y** sigilo</mark>: el propio libro avisa de que "ir demasiado rápido da resultados inconsistentes" — resolver miles de nombres a la vez satura el resolver y provoca timeouts que parecen "no existe". Acotar da resultados fiables y no dispara alertas de volumen en el DNS del objetivo.

## El agujero del libro: detección de wildcard

<mark style="background: #FF5582A6;">La fuerza bruta del libro da falsos positivos si el dominio tiene un registro *wildcard*.</mark> Un `*.example.com` hace que **cualquier** subdominio resuelva —`xyzzy123.example.com` incluido—, así que tu diccionario "encuentra" miles de subdominios inexistentes. La enumeración seria detecta el wildcard **antes**:

```go
// Consulta un nombre que seguro NO existe. Si resuelve, hay wildcard:
// guarda esas IPs y descarta luego cualquier resultado que coincida con ellas.
func wildcardIPs(domain, server string) map[string]bool {
    probe := "zzz-wildcard-probe-9f3a." + domain
    ips := resolve(probe, server)
    set := map[string]bool{}
    for _, ip := range ips {
        set[ip] = true
    }
    return set
}
```

Con ese conjunto, filtras: si un subdominio "encontrado" resuelve **solo** a las IPs del wildcard, es un falso positivo. Sin este paso, contra un dominio con wildcard tu tool es inútil.

## La metodología moderna: passive-first

Aquí está el mayor salto respecto al libro. La fuerza bruta activa (mandar miles de queries) es **ruidosa** y solo encuentra lo que está en tu diccionario. El enum de subdominios de 2026 es **passive-first**, en capas:

1. **Pasivo (sin tocar al objetivo)**: consultar **Certificate Transparency logs** (`crt.sh`), que registran todos los certificados TLS emitidos y filtran subdominios reales sin mandar un solo paquete al objetivo (recon puramente pasivo). Más APIs OSINT (VirusTotal, SecurityTrails, Shodan de la nota [[01 - Diseñar un cliente de API - el caso Shodan]]).
2. **Fuerza bruta** con resolvers masivos (para lo que no está en fuentes pasivas), ya con detección de wildcard.
3. **Permutaciones/alteraciones**: generar variantes de los subdominios ya encontrados (`dev` → `dev1`, `dev-staging`…).

> [!info]+ El estado del arte en herramientas
> `subfinder` y `amass` orquestan las fuentes pasivas; `puredns`/`massdns`/`shuffledns` hacen la fuerza bruta a gran velocidad con validación de wildcard integrada. Tu tool en Go es excelente para la **capa 2** (brute-force a medida, con tu lógica); para un recon completo, combínalo con las fuentes pasivas. La metodología de recon a fondo vive en Red Team. Fuentes: [github.com/projectdiscovery/subfinder](https://github.com/projectdiscovery/subfinder), [crt.sh](https://crt.sh), CT logs (RFC 6962).

Del lado cliente pasamos al servidor: escribir tu propio servidor DNS, la base del spoofing y del tunneling → [[02 - Escribir un servidor DNS]].
