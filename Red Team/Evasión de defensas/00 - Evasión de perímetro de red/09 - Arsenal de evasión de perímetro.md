---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
  - Tipo/Arsenal
Descripción: "El set de herramientas para cruzar el perímetro sin que te bloqueen ni te cacen, organizado por la capa que evades — no por velocidad de escaneo"
Fecha de actualización: 2026-08-04
Nota previa: "[[08 - Cómo te ve el defensor]]"
Nota siguiente:
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Este arsenal es para **cruzar el perímetro sin que te bloqueen ni te cacen**, no para escanear rápido. La velocidad y la profundidad —el pipeline `masscan`/`naabu` → `nmap` → `httpx`— viven en [[09 - Arsenal de herramientas de escaneo|el arsenal de escaneo]]; aquí las herramientas se ordenan por la **capa que evades**, que es como se eligen en un engagement real.

# 1 · Perfilar el perímetro y su política

Saber qué tienes delante antes de decidir la evasión:

- **`wafw00f`** — identifica el WAF/CDN mandando peticiones benignas y comparando firmas. Primer paso barato contra un objetivo web.
- **[[06 - tlsx - inteligencia desde TLS|tlsx]]** (JARM) — agrupa hosts por pila TLS; delata balanceadores, terminadores y servidores de C2 por su fingerprint.
- **[[03 - asnmap y cdncheck - superficie por ASN y detección de CDN|cdncheck]]** — resuelve si hay CDN/WAF delante y de qué proveedor (decide si el *fronting* siquiera aplica).
- **[[00 - Firewalking - mapear ACLs con TTL|Firewalk]]** — mapea qué bloquea cada salto del camino con juegos de TTL.
- **[[02 - Evasión de firewalls y detección con sx|sx]]** / `nping` / `hping3` — sondas de flags para distinguir filtro con estado de filtro sin estado, y `--badsum` para detectar inspectores.

# 2 · Crafting de paquete (diagnóstico y nicho)

- **[[🔨📦 Scapy|Scapy]]** — control total del paquete byte a byte: solapamientos a medida, secuencias de flags no estándar, campos manipulados. La herramienta cuando los flags de Nmap no llegan.
- **`nping`** (suite Nmap) — genera paquetes a medida sin escribir código; útil para pruebas de TTL, source-port y respuesta del perímetro.
- `fragroute`/`fragrouter` — la referencia clásica del paper de Ptacek; **archivada**, su función la hace hoy Scapy. Ver [[04 - Fragmentación y evasión a nivel IP y TCP|fragmentación]].

# 3 · Rotación de origen y redirectores

Que no haya un "el origen" al que correlacionar o bloquear ([[06 - Rotación de origen e infraestructura sacrificable|rotación de origen]]):

- **`fireprox`** (Black Hills) — AWS API Gateway como proxy: **una IP distinta por petición**. Anula el *rate-limiting* por IP en logins, APIs y recon HTTP.
- **`ProxyCannon-NG`** — levanta instancias EC2 como nodos de salida rotativos para todo el tráfico.
- **`proxychains-ng`** — encadena tu tráfico por una lista de proxies SOCKS/HTTP propios.
- **Redirectores** con [[05 - Redirección de tráfico con Socat|`socat`]], `nginx`/Apache `mod_rewrite` (filtrando por User-Agent y URI) o **Cloudflare Workers** (que además prestan reputación). Quemas el redirector, no el backend.
- **Tor** — último recurso: gratis pero catalogado, lento y a menudo bloqueado.

# 4 · Cruzar el egress: túneles

Cuando la salida está filtrada, se tuneliza por lo que sí sale ([[03 - Egress filtering - por dónde se sale|egress]]). El detalle de cada uno, en el [[16 - Arsenal de herramientas de pivoting|arsenal de pivoting]]:

- **[[09 - SOCKS tunneling con Chisel|Chisel]]** — SOCKS sobre HTTP/WebSocket; cruza egress que solo deja HTTP/S.
- **[[13 - Pivoting moderno con Ligolo-ng|Ligolo-ng]]** — túnel con interfaz TUN, el estándar moderno de pivoting.
- **[[10 - DNS tunneling con dnscat2|dnscat2]]** / `iodine` — salida por DNS cuando no sale nada más.
- **[[11 - ICMP tunneling|túnel ICMP]]** — cuando el ICMP saliente está abierto y el resto no.
- **`gost`**, **`cloudflared`**, **`ngrok`** — túneles que se apoyan en infraestructura de terceros con buena reputación para atravesar y fundirse.

# 5 · Blending TLS y DPI

Parecerse a lo legítimo cuando el perímetro mira el contenido ([[05 - DPI, inspección TLS y blending de tráfico|DPI e inspección TLS]]):

- **`uTLS`** — `ClientHello` idéntico al de un navegador real; convierte tu JA3/JA4 en el de Chrome.
- **[[00 - Introducción a mitmproxy|mitmproxy]]** / **[[00 - bettercap - suite de MITM|bettercap]]** — montar un MITM de laboratorio para **ver qué expone tu propio tráfico** (SNI en claro, JA4 que emites) antes de operar.
- **Perfiles de C2 maleables** — ajustar tamaños, cabeceras y ritmo para imitar SaaS permitido, y **no** dejar el fingerprint TLS por defecto de la herramienta.

# 6 · Capa web y WAF

- **`wafw00f`** para detectar, **`nuclei`** (plantillas `waf`/`misconfig`) para probar, y las técnicas de codificación/cabeceras de [[27 - Evasión en recon y fuzzing|evasión en recon y fuzzing]].
- **`fireprox`** de nuevo: rotar IP derrota el bloqueo por reputación y el *rate-limiting* del WAF.

# 7 · La vía infrafiltrada: IPv6

<mark style="background: #FF5582A6;">En redes *dual-stack*, la política IPv6 casi nunca replica la de IPv4</mark>. Es de lo más rentable que queda:

- **`nmap -6`**, **[[04 - naabu - descubrimiento de puertos|naabu]] `-iv 6`**, **[[02 - alterx y dnsx - permutación y resolución masiva|dnsx]] `-aaaa`** — descubrir la superficie IPv6 que el filtrado olvidó.

# Elegir por capa

<mark style="background: #ADCCFFA6;">La herramienta se elige por la capa que estorba, no por costumbre</mark>:

| Capa que evades | Herramienta | Nota |
| --- | --- | --- |
| Identificar el perímetro | `wafw00f`, tlsx, cdncheck, Firewalk, sx | [[01 - Perfilar el perímetro antes de escanear\|01]] · [[02 - Descubrir la política de filtrado\|02]] |
| Filtro sin estado (nicho) | Scapy, nping | [[04 - Fragmentación y evasión a nivel IP y TCP\|04]] |
| Bloqueo/rate-limit por IP | fireprox, ProxyCannon, proxychains | [[06 - Rotación de origen e infraestructura sacrificable\|06]] |
| Egress filtrado | Chisel, Ligolo-ng, dnscat2, gost | [[03 - Egress filtering - por dónde se sale\|03]] |
| DPI / fingerprint TLS | uTLS, mitmproxy, perfiles maleables | [[05 - DPI, inspección TLS y blending de tráfico\|05]] |
| Umbral del IDS | timing de Nmap, jitter | [[07 - Low-and-slow y evasión de umbrales\|07]] |
| Filtrado IPv4 | `nmap -6`, naabu `-iv 6`, dnsx | [[02 - Descubrir la política de filtrado\|02]] |

> [!info]+ Fuentes
> Rotación de IP: [fireprox](https://github.com/ustayready/fireprox) (Black Hills), [ProxyCannon-NG](https://github.com/proxycannon/proxycannon-ng), [proxychains-ng](https://github.com/rofl0r/proxychains-ng). Detección de WAF: [wafw00f](https://github.com/EnableSecurity/wafw00f). Túneles: [chisel](https://github.com/jpillora/chisel), [Ligolo-ng](https://github.com/nicocha30/ligolo-ng), [dnscat2](https://github.com/iagox86/dnscat2), [iodine](https://github.com/yarrick/iodine), [gost](https://github.com/go-gost/gost). Blending TLS: [uTLS](https://github.com/refraction-networking/utls). El arsenal de **velocidad** de escaneo (complementario a este), en [[09 - Arsenal de herramientas de escaneo]]; los túneles a fondo, en [[16 - Arsenal de herramientas de pivoting]].
