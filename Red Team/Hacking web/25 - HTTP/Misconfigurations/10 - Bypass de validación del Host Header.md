---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Host-Header
Descripción: "Cuando la app valida el Host, la partida es la de siempre en seguridad web: romper una validación mal hecha"
Fecha de actualización: 2026-07-14
Nota previa: "[[09 - Web Cache Poisoning por Host Header]]"
Nota siguiente: "[[11 - Detección, herramientas y prevención de Host Header Attacks]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Cuando la app valida el `Host`, la partida es la de siempre en seguridad web: **romper una validación mal hecha**. Lo valioso de esta nota es que **sus técnicas son las mismas que en [[05 - Evasión de defensas SSRF|SSRF]], CORS y open redirect**: validar un dominio/URL de forma robusta es difícil, y los mismos bypasses se reciclan en todos esos vectores.

# Bypass de whitelist (validación por comparación)

La app suele comparar el `Host` contra un dominio configurado. Fallos típicos:

**El puerto no se valida.** Si la función que parsea el `Host` ignora el puerto:

```http
GET / HTTP/1.1
Host: bypassingchecks.htb:1337
```

Se acepta y los enlaces absolutos se construyen con el puerto inyectado. Combinado con [[09 - Web Cache Poisoning por Host Header|cache poisoning]] rompe los recursos (CSS/JS con puerto muerto) → **defacement**. Impacto menor (no ataca a usuarios directamente), pero es una grieta confirmada.

**Solo se comprueba el sufijo (o el prefijo).** Si la validación hace `host.endsWith("target.htb")` sin verificar que sea un **subdominio** real, registras un dominio que **contiene** al legítimo como sufijo:

```http
Host: evilbypassingchecks.htb     ← contiene "bypassingchecks.htb" como sufijo
```

`evilbypassingchecks.htb` es un dominio **tuyo**, independiente, que pasa el filtro → <mark style="background: #FFB86CA6;">reintroduces password reset poisoning, cache poisoning</mark>, etc.

## Patrones generales de bypass de validación de dominio

La misma tabla sirve para Host header, [[05 - Evasión de defensas SSRF|SSRF]], CORS y `redirect_uri` de OAuth. Si el filtro busca `target.com` como subcadena:

| Técnica | Payload |
| - | - |
| Sufijo | `eviltarget.com` |
| Prefijo (subdominio falso) | `target.com.evil.com` |
| Credenciales en URL | `evil.com` con `Host: target.com@evil.com` |
| Fragmento / query | `evil.com#target.com`, `evil.com?target.com` |
| Separadores raros | `target.com\.evil.com`, `target.com%2eevil.com` |
| Regex sin anclar | un `.` que casa cualquier char, sin `^`/`$` |

# Bypass de blacklist (localhost y equivalentes)

Un enfoque aún más débil es la **blacklist**: bloquear `localhost` y `127.0.0.1`. Solo cubre lo que el dev imaginó, y `127.0.0.1` tiene <mark style="background: #FFB8EBA6;">decenas de representaciones equivalentes</mark>:

| Representación | Valor |
| - | - |
| Decimal | `2130706433` |
| Hex | `0x7f000001` |
| Octal | `0177.0000.0000.0001` |
| Cero | `0` |
| Forma corta | `127.1` |
| IPv6 | `::1` |
| IPv4 en IPv6 | `[::ffff:127.0.0.1]` |
| Dominio que resuelve a loopback | `localtest.me`, `127.0.0.1.nip.io` |

```shell-session
$ ping 0x7f000001 -c 1
PING 0x7f000001 (127.0.0.1) 56(84) bytes of data.   ← confirma que es 127.0.0.1
```

<mark style="background: #FF5582A6;">Todas resuelven a loopback</mark> y saltan una blacklist ingenua. Servicios como `nip.io`, `sslip.io` o `localtest.me` permiten forjar cualquier IP en un hostname aparentemente externo (`10.0.0.1.nip.io` → `10.0.0.1`), útil para pasar filtros que exigen "un dominio, no una IP".

> [!important] El principio transferible
> <mark style="background: #FF5582A6;">Whitelist estricta > blacklist, **siempre**</mark>. Y "validar un dominio" bien exige **parsear** la URL/host con una librería robusta y comparar el host **exacto** (no subcadenas, no regex sin anclar). Este mismo conocimiento es el que rompe filtros de [[05 - Evasión de defensas SSRF|SSRF]] (mismas representaciones de localhost), de CORS ([[03 - CORS Misconfigurations|reflejo/validación de `Origin`]]) y de `redirect_uri`. Guárdalo como un módulo mental reutilizable.

La prevención completa y las herramientas para descubrir estos bypasses, en [[11 - Detección, herramientas y prevención de Host Header Attacks]].

## Referencias

- [PortSwigger — Bypassing Host header validation](https://portswigger.net/web-security/host-header/exploiting#bypassing-flawed-request-parsing)
- [HackTricks — SSRF localhost bypasses](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery)
