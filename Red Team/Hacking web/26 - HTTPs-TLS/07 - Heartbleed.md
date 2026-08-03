---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Descripción: "Heartbleed (CVE-2014-0160) no es un fallo del protocolo TLS sino de su implementación en OpenSSL. Es el arquetipo de cómo un bug de memoria en una librería criptográfica…"
Fecha de actualización: 2026-07-14
Nota previa: "[[06 - Ataques de compresión (CRIME y BREACH)]]"
Nota siguiente: "[[08 - SSL Stripping]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

**Heartbleed** (`CVE-2014-0160`) no es un fallo del protocolo TLS sino de su **implementación** en OpenSSL. Es el arquetipo de cómo <mark style="background: #FFB86CA6;">un bug de memoria en una librería criptográfica compromete a un número gigantesco de servidores a la vez</mark>: al descubrirse en abril de 2014, ~17% de los servidores HTTPS del mundo eran vulnerables. Fue, además, la primera vulnerabilidad "de marca" (con logo y nombre propio).

# La extensión Heartbeat

TLS se extiende con múltiples *extensions*. La **Heartbeat** comprueba si la conexión sigue viva sin renegociar el handshake: el cliente envía un `Heartbeat Request` con un **payload arbitrario** y su **longitud**, y el servidor <mark style="background: #ADCCFFA6;">copia ese payload en memoria y lo devuelve tal cual</mark>. Uso normal:

```text
Cliente → ("HackTheBox", 10)   # payload + longitud declarada
Servidor → "HackTheBox"         # devuelve 10 bytes
```

# El bug: no validar la longitud

Las versiones vulnerables de OpenSSL (**1.0.1 a 1.0.1f**) <mark style="background: #ADCCFFA6;">no comprobaban que la longitud declarada coincidiese con el tamaño real del payload</mark>. Un cliente malicioso envía un payload pequeño pero declara una longitud enorme:

```text
Cliente → ("HackTheBox", 65535)          # 10 bytes reales, 64 KB declarados
Servidor → "HackTheBox" + 65525 bytes de memoria adyacente
```

```text
 Búfer del servidor en memoria (heap):
 ┌────────────┬──────────────────────────────────────────┐
 │ HackTheBox │ …clave privada… cookies… POSTs… claves…  │
 └────────────┴──────────────────────────────────────────┘
   ▲ payload    ▲ el servidor lee HASTA AQUÍ por la longitud mentida
   (10 bytes)   └───────────── over-read de ~64 KB ─────────────┘
```

Es un **buffer over-read**: el servidor devuelve memoria contigua al búfer. Esa memoria puede contener <mark style="background: #FFB86CA6;">la **clave privada** del servidor, cookies de sesión, credenciales o cuerpos de peticiones de otros usuarios</mark>. Con la clave privada, el compromiso es total: el atacante puede descifrar tráfico e impersonar el servidor. Como la extensión venía **activada por defecto**, el impacto fue masivo. Cada heartbeat filtra hasta 64 KB y es **repetible** indefinidamente.

# Detección y explotación

HTB usa **TLS-Breaker**, que detecta y además **reconstruye la clave privada** parseando la memoria filtrada (localiza los primos `p` y `q` de RSA y recompone la clave):

```shell-session
$ java -jar heartbleed-1.0.1.jar -connect target.htb:443
# ... Vulnerability status: VULNERABLE

$ java -jar heartbleed-1.0.1.jar -connect target.htb:443 -executeAttack -heartbeats 10
# ... "Prime found!" → -----BEGIN RSA PRIVATE KEY-----
```

El ataque **no es determinista** (depende de qué haya en memoria en ese instante), así que suele hacer falta repetirlo. En un pentest real las herramientas de referencia son más directas:

```shell-session
$ nmap -p 443 --script ssl-heartbleed target.htb          # detección estándar
$ testssl.sh --heartbleed target.htb                       # rápido y fiable
# Metasploit: auxiliary/scanner/ssl/openssl_heartbleed (con action DUMP para volcar memoria)
```

> [!success] Detección trivial, hallazgo de peso
> Heartbleed es un caso raro en este módulo: la **detección es simple y 100% fiable**, y el hallazgo es crítico. Si un escáner lo marca, es real — no hay `false positive`. Cualquier `nuclei`/`nmap`/`testssl.sh` lo confirma en segundos.

# Contexto profesional y estado en 2026

- **Impacto real**: robo de claves privadas demostrado (el *Cloudflare Heartbleed Challenge* probó que extraer la clave era factible), la brecha de la Agencia Tributaria canadiense, y una oleada mundial de **reemisión y revocación de certificados**.
- **Estado hoy**: parcheado en toda infraestructura mantenida desde 2014-2015. Pero <mark style="background: #FF5582A6;">sigue apareciendo en dispositivos **legacy, embebidos e IoT**</mark> que nadie actualiza. Shodan aún lista hosts vulnerables. Es un hallazgo plausible en infraestructura olvidada durante un engagement.
- **La lección de fondo**: Heartbleed fue un bug de **memory-safety en C**. Impulsó forks endurecidos como **LibreSSL** y **BoringSSL**, y es uno de los argumentos que empujan la criptografía moderna hacia lenguajes memory-safe como **Rust** (`rustls`). La prevención es simplemente **no ejecutar OpenSSL 1.0.1–1.0.1f**; mantener la librería al día basta.

> [!info] Relación con el resto del módulo
> Heartbleed **roba** la clave privada por un bug de implementación; [[05 - Bleichenbacher y DROWN|Bleichenbacher/DROWN]] descifran la sesión **sin** disponer de la clave privada, mediante un oráculo de padding; y con una clave robada, si el suite **no** tiene [[02 - Handshake TLS 1.2 y 1.3|PFS]], se descifra también el tráfico pasado capturado. Son piezas del mismo puzle: proteger la clave privada y garantizar `forward secrecy`.

## Referencias

- [Heartbleed.com](https://heartbleed.com/)
- [XKCD 1354 — How Heartbleed works](https://xkcd.com/1354/)
- [CVE-2014-0160](https://nvd.nist.gov/vuln/detail/CVE-2014-0160)
