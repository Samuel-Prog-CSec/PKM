---
tags:
  - Go
  - Go/Redes
  - Sniffing
  - Tipo/Introduccion
Descripción: "Hasta ahora todo el tráfico pasaba por el stack del SO: net.Dial te da un socket ya montado (00 - El paquete net y el modelo de conexión)"
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - Sniffer de credenciales en claro]]"
Area: "[[Raw packets.base|Raw packets]]"
---
---

Hasta ahora todo el tráfico pasaba por el stack del SO: `net.Dial` te da un socket ya montado ([[00 - El paquete net y el modelo de conexión]]). <mark style="background: #ADCCFFA6;">Procesar *raw packets* es saltarse ese stack y leer las tramas directamente de la interfaz</mark> — capa por capa, con acceso a cabeceras que un socket normal esconde. Con eso capturas credenciales en claro, detectas puertos tras protecciones anti-SYN-flood, o falseas y envenenas tráfico. La librería estándar de facto para esto es **gopacket**.

## Modernización obligatoria: el fork, no el original

> [!warning]+ `google/gopacket` está muerto — usa el fork mantenido
> El libro importa `github.com/google/gopacket`. Google **archivó** ese repo: sin bugfixes ni protocolos nuevos desde hace años, pese a que lo usan Cilium, DataDog o Elastic. El fork vivo de la comunidad es <mark style="background: #FF5582A6;">`github.com/gopacket/gopacket`</mark> (v1.7.0, julio 2026, requiere Go 1.24+). Es *drop-in*: cambia la ruta de import y compila igual. Todo el código de estas notas usa el fork.

```shell-session
$ go get github.com/gopacket/gopacket
```

gopacket es un *wrapper* CGO sobre **libpcap**, así que necesitas la librería nativa. En Linux/macOS:

```shell-session
$ sudo apt install libpcap-dev     # Debian/Ubuntu; brew install libpcap en macOS
```

> [!warning]+ En Windows, Npcap — no WinPcap
> El libro manda instalar WinPcap. <mark style="background: #FFB8EBA6;">WinPcap lleva descontinuado desde 2013</mark>. El reemplazo moderno es **Npcap** (de los autores de Nmap, [npcap.com](https://npcap.com)), instalado en "WinPcap API-compatible mode". Es lo que usa Wireshark y Nmap hoy.

## Identificar interfaces

Antes de capturar hay que saber por dónde escuchar. El subpaquete `pcap` lista las interfaces disponibles con `pcap.FindAllDevs()`:

```go
package main

import (
    "fmt"
    "log"

    "github.com/gopacket/gopacket/pcap"
)

func main() {
    devices, err := pcap.FindAllDevs()
    if err != nil {
        log.Fatal(err)
    }
    for _, device := range devices {
        fmt.Println(device.Name)
        for _, address := range device.Addresses {
            fmt.Printf("    IP: %s  Netmask: %s\n", address.IP, address.Netmask)
        }
    }
}
```

Cada `device` trae su `Name` (`eth0`, `en0`, `\Device\NPF_{...}` en Windows) y un slice de direcciones. <mark style="background: #FFB86CA6;">El nombre de interfaz es el primer dato que necesita cualquier sniffer</mark>; el resto del capítulo lo pasarás por parámetro o flag.

## Captura en vivo + filtro BPF

El flujo de captura tiene cuatro piezas: abrir un *handle* sobre la interfaz, aplicarle un filtro, crear una fuente de paquetes y leer del canal.

```go
var (
    iface   = "eth0"
    snaplen = int32(1600)          // bytes capturados por trama
    promisc = false                // modo promiscuo
    timeout = pcap.BlockForever
    filter  = "tcp and port 80"    // sintaxis BPF / tcpdump
)

handle, err := pcap.OpenLive(iface, snaplen, promisc, timeout)
if err != nil {
    log.Fatal(err)
}
defer handle.Close()

if err := handle.SetBPFFilter(filter); err != nil {
    log.Fatal(err)
}

source := gopacket.NewPacketSource(handle, handle.LinkType())
for packet := range source.Packets() {   // canal: bloquea hasta que llega tráfico
    fmt.Println(packet)
}
```

Las cuatro decisiones que importan:

- **`snaplen`** — cuántos bytes capturas por trama. 1600 cubre una trama Ethernet entera (MTU 1500 + cabeceras); si solo miras cabeceras, bájalo para capturar menos y más rápido.
- **`promisc`** — en modo promiscuo la NIC entrega **todas** las tramas del segmento, no solo las tuyas. Imprescindible para MITM/ARP poisoning; innecesario (y más ruidoso) si solo sniffeas tu propio host.
- **BPF** — <mark style="background: #8000E1A6;">el filtro se aplica **en kernel**, antes de copiar la trama a tu programa</mark>. Filtrar `tcp and port 80` descarta el resto sin coste en user-space. Es la misma sintaxis de `tcpdump`; la referencia canónica es la [man page de pcap-filter](https://www.tcpdump.org/manpages/pcap-filter.7.html).
- **`LinkType()`** — le dice al decodificador qué hay en la capa de enlace (normalmente Ethernet) para parsear bien las capas superiores.

`source.Packets()` devuelve un `channel` — el mismo patrón de [[13 - Goroutines, channels y concurrencia]]: el `range` bloquea sin tráfico y despierta con cada paquete.

## El modelo de capas

Cada `packet` es una pila de capas ya decodificada. En vez de parsear bytes a mano, pides la capa que te interesa:

```go
if netLayer := packet.NetworkLayer(); netLayer != nil {   // IPv4/IPv6 (no llamarlo 'net': tapa el paquete)
    fmt.Println(netLayer.NetworkFlow().Src(), "->", netLayer.NetworkFlow().Dst())
}
if app := packet.ApplicationLayer(); app != nil {   // payload L7
    fmt.Println(hex.Dump(app.Payload()))
}
```

`NetworkLayer()`, `TransportLayer()` y `ApplicationLayer()` devuelven `nil` si la capa no existe — **siempre comprobar** antes de usar (nota [[11 - Manejo de errores]]). Combinar `Payload()` con `hex.Dump` te da el volcado legible que usarás en las siguientes notas.

> [!info]+ Alternativa sin CGO: `pcapgo`
> El CGO de libpcap complica la compilación estática y el *cross-compiling* (un dolor recurrente del tooling ofensivo). gopacket trae `pcapgo`, que en Linux usa **AF_PACKET nativo** sin libpcap ni CGO — binario estático que dropeas en un target sin dependencias. A cambio pierdes `SetBPFFilter` de alto nivel (filtras a mano o con BPF compilado). Para un implante portable, merece la pena.

Capturar tráfico exige privilegios (`root`/`CAP_NET_RAW` en Linux, admin en Windows) porque tocas la interfaz en crudo. El sniffing pasivo es **sigiloso** por naturaleza: no emites un solo paquete, solo escuchas — la parte detectable es cómo llegaste a esa posición en la red. Con el handle montado, el primer uso real: pescar credenciales → [[01 - Sniffer de credenciales en claro]].
