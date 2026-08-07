---
tags:
  - Pentesting/Enumeracion
  - Recon
  - Web/Red-Team
  - Tipo/Deteccion
Descripción: "Los defaults de la suite son agresivos, el User-Agent aleatorio te delata más que ayuda, y los filtros te esconden que te están bloqueando"
Fecha de actualización: 2026-08-04
Nota previa: "[[08 - notify y automatización del pipeline]]"
Nota siguiente:
Area: "[[ProjectDiscovery.base|ProjectDiscovery]]"
---
---

La suite de ProjectDiscovery opera sobre HTTP y TLS, así que la defensa que tiene enfrente no es un IDS de red sino un **WAF, un CDN y un sistema antibot**. Las reglas del juego son distintas a las de [[05 - Evasión de firewalls e IDS con masscan|masscan]] o [[04 - Evasión, detección y ética del escaneo a escala|ZMap]], y las palancas también.

# Los defaults son de "ir rápido"

| Herramienta | Ritmo por defecto |
| --- | --- |
| `httpx` | **150 req/s**, 50 hilos |
| `naabu` | **1.000 pps**, 25 workers |
| `dnsx` | **sin límite**, 100 hilos |
| `tlsx` | **300** conexiones concurrentes |
| `subfinder` | pasivo (límite por proveedor) |

<mark style="background: #FF5582A6;">Ninguno de esos valores es apropiado para un programa de bug bounty ni para un cliente que no espera un simulacro de DDoS</mark>. Son valores pensados para barrer rangos grandes deprisa, y en un objetivo pequeño equivalen a un ataque de agotamiento de recursos — especialmente `tlsx`, porque cada handshake TLS cuesta mucho más al servidor que a ti.

```shell-session
$ cat hosts.txt | httpx -silent -rl 10 -t 5 -delay 500ms
$ naabu -l hosts.txt -rate 100 -c 10 -silent
$ dnsx -l nombres.txt -rl 50 -t 25 -silent
$ tlsx -l hosts.txt -c 20 -delay 200ms -silent
```

# El User-Agent aleatorio te delata

Este es el punto contraintuitivo y el más importante de la nota.

`httpx` trae **`-random-agent` activado por defecto**: cada petición sale con un `User-Agent` de navegador distinto. La intención es evitar el filtrado por UA. El efecto real, contra defensas modernas, es el contrario.

<mark style="background: #8000E1A6;">Un sistema antibot no mira solo el `User-Agent`: mira la **huella TLS del cliente** (JA3/JA4)</mark>, que viene determinada por la librería que negocia la conexión. `httpx` usa la pila TLS de Go, cuyo JA3 no se parece al de ningún navegador. El resultado:

```
User-Agent  →  "Mozilla/5.0 (Windows NT 10.0) ... Chrome/126"
JA3         →  huella de la librería crypto/tls de Go
                        ↑
        contradicción evidente = señal de bot de alta confianza
```

Un cliente que **dice** ser Chrome pero **negocia** como Go es más sospechoso que uno que no miente. Cloudflare, Akamai Bot Manager y similares detectan exactamente esa discrepancia.

`httpx` tiene un flag experimental para atacarlo:

```shell-session
$ cat hosts.txt | httpx -silent -tlsi          # -tls-impersonate: aleatoriza JA3
```

> [!important]+ Qué hacer en la práctica
> - **En bug bounty**: no intentes esconderte. <mark style="background: #FFB8EBA6;">Identifícate con `-H "X-Bug-Bounty: <tu-handle>"` y un UA propio</mark> — muchos programas lo exigen, y es lo que evita que te confundan con un atacante real ([[01 - Reglas, legalidad y conducta]]).
> - **En un pentest con evasión en scope**: `-tlsi` es un parche; si necesitas parecer un navegador de verdad, la vía es un navegador de verdad (`-ss/-system-chrome`, [[Burp Suite|Burp]], o [[10 - Crawling web|katana en modo headless]]).
> - **Nunca**: UA de navegador + pila Go + 150 req/s. Es la combinación que garantiza el bloqueo.

# Las palancas que sí funcionan

## 1. Pasivo primero

```shell-session
$ uncover -q 'org:"ACME Inc."' -silent -o pasivo.txt
$ naabu -l hosts.txt -passive -silent
$ subfinder -d objetivo.com -all -silent
```

Cero paquetes al objetivo. Llegar a la fase activa sabiendo qué buscar reduce el volumen a confirmación dirigida ([[07 - uncover - recon pasivo vía motores de búsqueda]]).

## 2. Proxy y rotación de origen

```shell-session
$ cat hosts.txt | httpx -silent -proxy http://127.0.0.1:8080     # Burp
$ naabu -l hosts.txt -s connect -proxy socks5://127.0.0.1:1080   # pivote
```

Para el problema real de bug bounty —que te bloqueen la IP por rate-limiting— la herramienta es **Fireprox**: levanta un API Gateway de AWS que reenvía las peticiones, de forma que <mark style="background: #FFB86CA6;">cada petición sale desde una IP distinta del rango de AWS</mark>. El objetivo no puede limitar por IP porque no hay una IP que limitar. Se apunta `httpx` al endpoint generado y el rate-limiting deja de existir ([[27 - Evasión en recon y fuzzing]]).

> [!warning]+ Fireprox lleva sin tocarse desde 2023
> Verificado el 2026-08-04: último *push* en **abril de 2023**, sin *releases*. Sigue funcionando porque es un envoltorio fino sobre la API de AWS, pero es deuda: si AWS cambia el API Gateway, se rompe. Y ojo con lo obvio — **estás pagando tú** el tráfico de ese API Gateway.

## 3. Evitar lo que grita

- **`-exclude-cdn`** en `naabu`: no aporreas el WAF, que es quien te va a bloquear.
- **`-x all`, `-path`, `-vhost`, `-http2`, `-pipeline`** en `httpx`: el propio proyecto avisa de que **no deben usarse por defecto** junto al resto de sondas. Multiplican peticiones por host.
- **`-s syn`** en `naabu` (con `root`) en vez de `connect`: menos huella en logs de aplicación.
- **Menos puertos**: `-top-ports 100` antes que `-p -`. Menos puertos también significa menos probabilidad de pisar un canario.

# Cómo se detecta

## Lo que ve el defensor

- **Ritmo perfecto.** 150 req/s exactos, sin variación. Ningún humano ni navegador produce eso; `-delay` con jitter lo mitiga a medias.
- **Peticiones huérfanas.** El pipeline pide **solo el HTML**: no carga CSS, ni JS, ni imágenes, ni ejecuta JavaScript. Una sesión que pide una página y ninguno de sus recursos es un patrón de bot inmediato en cualquier analítica.
- **Huella TLS.** JA3/JA4 de Go, constante en todas las peticiones.
- **Barrido de vhosts.** Cientos de `Host:` distintos hacia la misma IP en segundos.
- **Logs de aplicación.** `httpx` hace peticiones HTTP reales: quedan en `access.log` con tu IP, tu UA y la hora.

## El fallo de medida que te oculta el bloqueo

Este merece atención propia porque produce informes falsos.

> [!warning]+ Cuando "no vulnerable" significa "me han bloqueado"
> Varios defaults de la suite **enmascaran activamente** que te están cortando:
> - **`httpx -maxhr 30`** salta un host tras 30 errores. Si el WAF te bloquea, `httpx` lo descarta en silencio y ese host **no aparece en la salida**. Lo lees como "no responde".
> - **Filtrar `-fc 403,429`** es lo primero que hace todo el mundo para limpiar ruido. Pero <mark style="background: #FF5582A6;">`403` y `429` son exactamente las respuestas de un WAF bloqueándote</mark>: al filtrarlas, borras la evidencia de que el recon dejó de funcionar.
> - **`dnsx` sin `-rl`** satura resolutores y los `SERVFAIL` se leen como "no existe".
>
> **Contramedida**: en la primera pasada **no filtres nada**, mira la distribución de códigos y comprueba si hay un muro de `403`/`429`. Y verifica a mano un par de hosts que la herramienta dio por muertos. Un recon que devuelve poco puede significar poca superficie o que te cortaron a los dos minutos: son conclusiones opuestas.

# Regla operativa

```
1. Pasivo:   subfinder / uncover / naabu -passive        (invisible)
2. Filtra:   scope + cdncheck                            (antes de tocar)
3. Activo:   -rl bajo, -delay, -H identificativa         (visible pero educado)
4. Verifica: primera pasada SIN filtros, mira los 403/429
5. Escala:   sube el ritmo solo si el objetivo lo aguanta y el programa lo permite
```

<mark style="background: #ADCCFFA6;">Contra un WAF, la evasión que funciona no es disfrazarse: es pedir menos y parecer consistente</mark>. Un cliente que dice ser Go, va a 10 req/s y trae una cabecera identificativa pasa desapercibido mucho mejor que uno que finge ser Chrome a 150 req/s.

> [!info]+ Fuentes
> - READMEs de [httpx](https://github.com/projectdiscovery/httpx) (`-random-agent` y `-cdn` activos por defecto, `-tls-impersonate` experimental, `-maxhr 30`, aviso sobre flags que no deben ser default), [naabu](https://github.com/projectdiscovery/naabu), [dnsx](https://github.com/projectdiscovery/dnsx) y [tlsx](https://github.com/projectdiscovery/tlsx).
> - [Fireprox](https://github.com/ustayready/fireprox) — rotación de IP vía AWS API Gateway (estado verificado 2026-08-04).
> - Detección por comportamiento y huella en [[08 - Detección de escaneos y evasión moderna]] y [[27 - Evasión en recon y fuzzing]].
