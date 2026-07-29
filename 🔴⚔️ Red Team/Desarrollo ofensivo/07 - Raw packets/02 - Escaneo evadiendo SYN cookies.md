---
tags:
  - Go
  - Go/Redes
  - Escaneo/Redes
Descripción: "El escáner concurrente de 01 - Escáner TCP - de secuencial a concurrente tiene un punto ciego: contra objetivos con protección anti-SYN-flood, todos los puertos parecen abiertos"
Fecha de actualización: 2026-07-25
Nota previa: "[[01 - Sniffer de credenciales en claro]]"
Nota siguiente: ""
Area: "[[Raw packets.base|Raw packets]]"
---
---

El escáner concurrente de [[01 - Escáner TCP - de secuencial a concurrente]] tiene un punto ciego: contra objetivos con protección anti-SYN-flood, **todos** los puertos parecen abiertos. Leer los flags TCP en crudo con gopacket resuelve ese falso positivo — el caso donde el stack normal del SO no te basta y necesitas *raw packets*.

## Por qué falla el escáner normal

Las **SYN cookies** son la defensa estándar contra SYN-flood: el servidor responde a cada `SYN` con un `SYN/ACK` válido **sin reservar estado**, exista o no un servicio detrás. <mark style="background: #FFB86CA6;">El three-way handshake se completa igual en un puerto abierto que en uno cerrado o filtrado</mark>. Como Nmap y casi todos los scanners deciden "abierto" a partir de ese handshake, un objetivo con SYN cookies los engaña: reportan **todos** los puertos abiertos.

La observación que rompe el engaño: <mark style="background: #ADCCFFA6;">un servicio real intercambia datos **después** del handshake</mark> (un banner, una respuesta), y esas tramas llevan flags distintos a `SYN/ACK`. Un puerto falso-abierto no manda nada más. Detectar ese tráfico posterior te dice qué puerto tiene un servicio de verdad.

## Los flags TCP y el byte 13

Los flags viven en un solo byte de la cabecera TCP — offset **13** (0-based). Cada bit es un flag:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|---|---|---|---|---|---|---|---|
| Flag | CWR | ECE | URG | ACK | PSH | RST | SYN | FIN |

Las combinaciones que delatan un servicio activo tras el handshake:

- **ACK+FIN** = `0x11` — el servicio cierra ordenadamente.
- **ACK** = `0x10` — reconocimiento con datos.
- **ACK+PSH** = `0x18` — empuja datos a la aplicación (un banner).

El `SYN/ACK` de las SYN cookies (`0x12`) queda fuera de la lista, así que filtrando por esos tres valores capturas solo respuestas de servicios reales.

## El filtro BPF

El libro filtra por el valor crudo del byte:

```text
tcp[13] == 0x11 or tcp[13] == 0x10 or tcp[13] == 0x18
```

Funciona, pero es críptico. libpcap moderno acepta **flags simbólicos**, mucho más legibles y menos frágiles:

```text
tcp[tcpflags] & (tcp-ack|tcp-fin|tcp-push) != 0 and tcp[tcpflags] & tcp-syn == 0
```

<mark style="background: #8000E1A6;">"paquetes con ACK, FIN o PSH pero sin SYN"</mark> — la misma intención sin memorizar máscaras hexadecimales. Para tooling que mantendrás, prefiere la forma simbólica.

## El scanner de confianza

La idea: una goroutine sniffea las respuestas mientras `main` intenta conectar a cada puerto. Cada paquete que casa el filtro **suma confianza** a ese puerto.

```go
var (
    snaplen = int32(320)
    promisc = true
    filter  = "tcp[tcpflags] & (tcp-ack|tcp-fin|tcp-push) != 0 and tcp[tcpflags] & tcp-syn == 0"
    results = make(map[string]int)
    mu      sync.Mutex
)

func capture(iface, target string) {
    handle, err := pcap.OpenLive(iface, snaplen, promisc, pcap.BlockForever)
    if err != nil {
        log.Fatalf("OpenLive(%s): %v", iface, err)
    }
    defer handle.Close()
    if err := handle.SetBPFFilter(filter); err != nil {
        log.Fatalf("SetBPFFilter: %v", err)
    }

    source := gopacket.NewPacketSource(handle, handle.LinkType())
    for packet := range source.Packets() {
        netLayer, tr := packet.NetworkLayer(), packet.TransportLayer()   // no llamar 'net': tapa el paquete
        if netLayer == nil || tr == nil {
            continue
        }
        if netLayer.NetworkFlow().Src().String() != target {   // solo respuestas del objetivo
            continue
        }
        mu.Lock()
        results[tr.TransportFlow().Src().String()]++       // clave = puerto de origen
        mu.Unlock()
    }
}
```

En `main`, lanzas la captura en una goroutine y disparas las conexiones:

```go
go capture(iface, ip)
time.Sleep(time.Second)                     // deja arrancar el sniffer

for _, port := range ports {
    c, err := net.DialTimeout("tcp", net.JoinHostPort(ip, port), time.Second)
    if err == nil {
        c.Close()
    }
}
time.Sleep(2 * time.Second)                 // deja llegar las respuestas

mu.Lock()
for port, confidence := range results {
    if confidence >= 1 {
        fmt.Printf("Puerto %s abierto (confianza: %d)\n", port, confidence)
    }
}
mu.Unlock()
```

El `Mutex` protege el `map` compartido entre la goroutine sniffer y `main` (nota [[06 - Slices, arrays y maps]]: escribir un map concurrentemente sin protección revienta). Los `time.Sleep` dan margen a montar el sniffer y a que lleguen las respuestas — burdo pero suficiente para el PoC.

> [!warning]+ Los `Sleep` son el punto débil
> Sincronizar con `time.Sleep` es frágil: en una red lenta pierdes respuestas tardías; en una rápida, esperas de más. Un tool serio cierra la captura con un `context` cancelable tras un plazo, o cuenta respuestas hasta un *quiescence timeout*. El libro deja como ejercicio migrar el `Dial` secuencial a concurrente con [[01 - Escáner TCP - de secuencial a concurrente|errgroup + SetLimit]] y meter el `target` y los puertos en el propio filtro BPF para no comprobarlos a mano.

> [!important]+ OPSEC y encaje con Nmap
> Esto es una conexión TCP **completa** por puerto — mucho más ruidosa y logueada que un SYN scan a medias. Vas a aparecer en los logs del servicio. La técnica no sustituye a Nmap: lo **complementa** cuando sospechas SYN cookies (todos los puertos "abiertos" es la señal). Nmap resuelve lo mismo con `--defeat-rst-ratelimit` y detección de servicio (`-sV`), que confirma el puerto exigiendo un banner real. El escaneo sigiloso a fondo — *timing templates*, decoys, fragmentación — vive en [[00 - Introducción a Nmap|Nmap]] y en Red Team.

Con esto cierras el capítulo de captura de paquetes: interfaces, filtros BPF, sniffing L7 y lectura de flags en crudo. El siguiente bloque cambia de tercio — de leer la red a escribir exploits → carpeta `08 - Exploits y shellcode`.
