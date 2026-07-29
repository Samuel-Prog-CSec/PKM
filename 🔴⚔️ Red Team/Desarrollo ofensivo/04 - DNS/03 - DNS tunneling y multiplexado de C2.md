---
tags:
  - Go
  - Go/DNS
  - C2
Descripción: "El clímax del bloque de red: usar DNS como canal de C2 y exfiltración para salir de una red restringida"
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Escribir un servidor DNS]]"
Nota siguiente: 
Area: "[[DNS.base|DNS]]"
---
---

El clímax del bloque de red: usar DNS como **canal de C2 y exfiltración** para salir de una red restringida. La idea es la misma que el multiplexado HTTP del Cap. 4 ([[04 - Multiplexar Command-and-Control]]), pero sobre DNS — y con una ventaja: casi ninguna red bloquea el DNS saliente. Eso sí, hay una actualización importante frente al libro (2020): en 2026 el DNS tunneling está **muy vigilado**.

## Por qué DNS para C2

<mark style="background: #ADCCFFA6;">Aunque una red filtre todo el tráfico saliente, casi siempre deja resolver DNS</mark> — sin DNS no funciona nada. El truco: el implante codifica datos en las **consultas** (en los subdominios: `ZGF0YQ.tu-c2.com`) o los recibe en las **respuestas** (registros `TXT`). Esas consultas viajan al resolver interno de la organización, que las **reenvía** hacia el servidor autoritativo de tu dominio — tu C2. No hay conexión directa del implante a tu servidor; todo pasa por la infraestructura DNS de la víctima. Es lento (poco ancho de banda por query) pero difícil de bloquear sin romper el DNS.

## El proxy multiplexor

El proxy del libro es un servidor DNS (nota [[02 - Escribir un servidor DNS]]) que **reenvía** cada consulta a un backend distinto según el dominio — así un solo host en el puerto 53 sirve a varios teamservers (Cobalt Strike, Sliver…). La config es un fichero `dominio,servidor`:

```go
func handler(w dns.ResponseWriter, req *dns.Msg) {
    if len(req.Question) == 0 {
        dns.HandleFailed(w, req)              // responde SERVFAIL
        return
    }
    // dominio registrable = últimas dos labels de la pregunta
    parts := strings.Split(req.Question[0].Name, ".")
    domain := req.Question[0].Name
    if len(parts) >= 2 {
        domain = strings.Join(parts[len(parts)-2:], ".")
    }

    recordLock.RLock()
    upstream := records[domain]               // ¿a qué backend va este dominio?
    recordLock.RUnlock()
    if upstream == "" {
        dns.HandleFailed(w, req)
        return
    }
    resp, err := dns.Exchange(req, upstream)  // reenvía la consulta al backend
    if err != nil {
        dns.HandleFailed(w, req)
        return
    }
    w.WriteMsg(resp)                          // devuelve la respuesta al cliente
}
```

<mark style="background: #8000E1A6;">Es exactamente el multiplexor HTTP del Cap. 4, pero sobre DNS</mark>: `attacker1.com` va a un teamserver, `attacker2.com` a otro, y tu servidor de cara a internet solo expone un dominio/IP mientras oculta los C2 reales (redirector).

## Protegido y recargable en caliente

Dos detalles que el libro hace bien y conviene subrayar:

- **`sync.RWMutex`** sobre el map: el servidor DNS atiende cada consulta en su propia goroutine (nota [[13 - Goroutines, channels y concurrencia]]), así que el `records` es estado compartido. `RLock` para leer, `Lock` para recargar. Un map sin proteger revienta con acceso concurrente. (El propio libro apunta que desde Go 1.9 `sync.Map` es una alternativa concurrente sin candado explícito.)
- **Recarga en caliente por señal**: en vez de reiniciar el proxy para añadir un dominio —lo que tiraría los beacons vivos—, escucha `SIGUSR1` y recarga la config (truco tomado del servidor Caddy):

```go
sigs := make(chan os.Signal, 1)
signal.Notify(sigs, syscall.SIGUSR1)
go func() {
    for range sigs {
        recordLock.Lock()
        records, _ = parse("proxy.config")   // recarga sin reiniciar
        recordLock.Unlock()
    }
}()
```

Una alternativa moderna a la señal es vigilar el fichero con `fsnotify` y recargar al detectar cambios — más cómodo que mandar `kill -USR1` a mano.

## DNS tunneling en 2026: muy detectado

Aquí está la actualización más importante frente al libro. <mark style="background: #FF5582A6;">El DNS tunneling funciona, pero en 2026 es de los canales de C2 más ruidosos y detectados.</mark> El equipo azul lo caza por patrones estadísticos que el tráfico DNS legítimo no tiene:

- **Alto volumen** de consultas a un mismo dominio (un beacon genera cientos/miles).
- **Labels largas y de alta entropía**: los datos codificados (base32/base64) parecen aleatorios, muy distintos de `www` o `mail`.
- **Abuso de `TXT`/`NULL`** y tipos poco comunes para canal de datos.
- **Dominios de baja reputación** o recién registrados.
- Consultas que **nunca aciertan en caché** (siempre nombres únicos).

Los DNS de seguridad y NDR modernos (Cisco Umbrella, Quad9, Infoblox, filtrado DNS corporativo) tienen reglas específicas para esto.

> [!warning]+ Lo que cambia el juego hoy
> **DoH (DNS-over-HTTPS)** cifra las consultas dentro de HTTPS (puerto 443), evadiendo la inspección DNS en claro on-path — pero centraliza el tráfico en pocos proveedores que a su vez detectan patrones, y muchas organizaciones ya bloquean o monitorizan DoH. Herramientas clásicas como `iodine` y `dnscat2` son **muy** detectables; los C2 modernos (Sliver, Cobalt Strike) intentan mimetizarse bajando volumen y usando labels realistas, pero sigue siendo un canal de último recurso. La detección y evasión de C2 a fondo está en Red Team: [[11 - Detección, prevención y evasión|detección y evasión de C2]].

---

Con esto cierras el Cap. 5 y todo el recorrido por protocolos de red (TCP, HTTP cliente/servidor, DNS): sabes construir clientes, servidores, proxies y canales encubiertos en Go. El siguiente capítulo entra en el protocolo más enrevesado del libro y el más útil en post-explotación Windows: **SMB y NTLM** (pass-the-hash, password spraying) → [[SMB y NTLM.base|SMB y NTLM]] (Cap. 6).
