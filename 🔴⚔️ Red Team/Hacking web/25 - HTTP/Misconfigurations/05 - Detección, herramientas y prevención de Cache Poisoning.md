---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/Cache-Poisoning
  - Tipo/Deteccion
Descripción: "Probar a mano miles de cabeceras y parámetros para hallar cuáles son unkeyed es inviable en un objetivo real"
Fecha de actualización: 2026-07-14
Nota previa: "[[04 - Técnicas avanzadas de Cache Poisoning]]"
Nota siguiente: "[[06 - Introducción a los Host Header Attacks]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Probar a mano miles de cabeceras y parámetros para hallar cuáles son unkeyed es inviable en un objetivo real. Esta nota reúne el **arsenal** que automatiza la [[02 - Identificación de parámetros unkeyed|detección]] con cache busters y la [[04 - Técnicas avanzadas de Cache Poisoning|discrepancia]] caché↔servidor, más cómo **prevenir** el ataque.

# Arsenal

| Herramienta | Tipo | Qué cubre |
| - | - | - |
| **WCVS** (Web-Cache-Vulnerability-Scanner) | CLI Go (Hackmanit) | Keyed/unkeyed de params y cabeceras, **fat GET**, parameter cloaking; cache buster automático; informe JSON |
| **Param Miner** | Extensión Burp (PortSwigger) | *Guess headers/params* con diccionario, detecta unkeyed reflejados, cache busters; integrado en el flujo Burp |
| **toxicache** | CLI Go | Escáner rápido de cache poisoning sobre listas de URLs (masivo, bug bounty) |
| **nuclei** | Templates | Triage automatizado (`http-cache-poisoning`, cache-deception) |

## WCVS — el de HTB

<mark style="background: #ADCCFFA6;">WCVS prueba diccionarios de cabeceras y parámetros y **añade un cache buster a cada petición automáticamente**</mark>, así que no envenenas a usuarios reales durante el escaneo:

```shell-session
# -u URL · -sp fija el parámetro que la app espera · -gr genera informe JSON
$ ./wcvs -u http://simple.wcp.htb/ -sp language=en -gr
# ...
[+] Query Parameter ref was successfully poisoned! cb: 829054... poison: 793369...
[+] URL: http://simple.wcp.htb/?language=en&ref=793369015723&cb=829054467467
```

Detecta también los vectores avanzados. Contra el lab de fat GET encuentra tanto un **header poisoning** (`X-Forwarded-For` reflejado) como el **fat GET**:

```shell-session
$ ./wcvs -u http://fatget.wcp.htb/ -sp language=en -gr
# | Header Poisoning  → X-Forwarded-For poisoned
# | Fat GET Poisoning → ref / language poisoned via simple Fat GET
```

El informe JSON incluye la petición PoC exacta (con su `cb`), lista para pegar en el reporte.

## Param Miner — el estándar en Burp

Complementa a WCVS dentro del flujo manual: botón derecho sobre una petición → *Guess headers* / *Guess GET parameters*. Prueba la [[02 - Identificación de parámetros unkeyed|checklist de cabeceras]] (`X-Forwarded-Host`, `X-Original-URL`…), gestiona cache busters y marca las entradas unkeyed que se reflejan. Para cache poisoning avanzado tiene opciones específicas de *fat GET* y detección de discrepancias.

```shell-session
# toxicache — barrido masivo sobre URLs recolectadas (recon bug bounty)
$ cat urls.txt | toxicache -o results.txt
# nuclei — triage rápido
$ nuclei -tags cache -u https://target.htb
```

# Prevención

El cache poisoning es difícil de prevenir porque <mark style="background: #FFB8EBA6;">suele haber **desconexión** entre quien programa el backend y quien configura la caché</mark>: el dev puede ignorar que hay una caché delante, y el admin de la caché puede no saber qué parámetros alteran la respuesta. Medidas:

- **No usar la configuración por defecto** de la caché: ajústala a la app concreta.
- <mark style="background: #FF5582A6;">Que **todo** parámetro/cabecera que influya en la respuesta sea **keyed**</mark> — es la regla de oro. Si algo cambia la salida, tiene que estar en la cache key.
- **Desactivar fat GET** en el servidor y **mantener caché y servidor actualizados** (los parseos divergentes causan parameter cloaking).
- **Parchear todo XSS del lado cliente** aunque no sea explotable de forma clásica (por requerir una cabecera custom): el cache poisoning lo weaponiza.
- **Cachear solo lo verdaderamente estático** (CSS, JS, imágenes) y **nunca** respuestas con `Set-Cookie`, `Authorization` o contenido por-usuario. Marcar lo dinámico con `Cache-Control: no-store`.
- Usar `Vary` correctamente para declarar qué cabeceras entran en la key, y en CDN activar protecciones como la *Cache Deception Armor* de Cloudflare.

> [!warning] Recordatorio operativo y ético
> Todo lo de este bloque se prueba **siempre con cache buster**. Un escáner sin él (o un PoC descuidado) envenena la caché real y <mark style="background: #FFB86CA6;">DoSea a usuarios legítimos</mark> hasta expirar el TTL. WCVS y Param Miner lo gestionan solos; si automatizas con scripts propios, añade tú el buster único por petición.

Con esto cierra el bloque de Web Cache Poisoning. El siguiente vector, los [[06 - Introducción a los Host Header Attacks|Host Header Attacks]], comparte terreno: la cabecera `Host` es a menudo la entrada unkeyed que envenena la caché.

## Referencias

- [WCVS — Web Cache Vulnerability Scanner (Hackmanit)](https://github.com/Hackmanit/Web-Cache-Vulnerability-Scanner)
- [Param Miner](https://github.com/PortSwigger/param-miner) · [toxicache](https://github.com/xhzeem/toxicache)
- [PortSwigger — Preventing web cache poisoning](https://portswigger.net/web-security/web-cache-poisoning#how-to-prevent-web-cache-poisoning-vulnerabilities)
