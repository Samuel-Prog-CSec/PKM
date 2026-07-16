---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/Cache-Poisoning
Fecha de actualización: 2026-07-14
Nota previa: "[[01 - Introducción a Web Cache Poisoning]]"
Nota siguiente: "[[03 - Ataques de Web Cache Poisoning]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

El primer paso de todo cache poisoning es **encontrar una entrada unkeyed** que llegue reflejada a la respuesta. <mark style="background: #ADCCFFA6;">El parámetro que entrega el payload **debe** ser unkeyed</mark>: si fuese keyed, la víctima tendría que enviarlo ella misma para que su cache key coincidiera con la envenenada — y eso ya es un [[02 - XSS Reflejado|XSS reflejado]] normal, sin el multiplicador de la caché.

# La metodología: HIT vs MISS

Un parámetro es **keyed** o **unkeyed** según si cambia la respuesta cacheada. Se prueba variando su valor y observando si llega respuesta fresca (`MISS`) o cacheada (`HIT`):

- Cambio el valor y la respuesta **cambia** / hay `MISS` → el parámetro es **keyed** (entra en la cache key).
- Cambio el valor y recibo **la misma** respuesta cacheada / `HIT` → es **unkeyed**.

Ejemplo de rastreo sobre tres parámetros:

```text
?language=en          → MISS, luego HIT
?language=de          → MISS           → distinto → language es KEYED
?...&content=Hello    → MISS, luego HIT
?...&content=Other    → MISS           → distinto → content es KEYED
?...&ref=test123      → MISS, luego HIT
?...&ref=Hello        → HIT (¡aún!)    → NO cambia la key → ref es UNKEYED ✓
```

`ref` es unkeyed: variar su valor sigue devolviendo el `HIT`, luego no forma parte de la cache key. Si además se **refleja sin sanitizar**, tienes el vector:

```http
GET /index.php?language=unusedvalue&ref="><script>alert(1)</script> HTTP/1.1
Host: webcache.htb
```

Cacheada esa respuesta, <mark style="background: #FFB86CA6;">todo usuario que pida `/index.php?language=unusedvalue` recibe el XSS</mark> sin interacción. Con un payload que haga una petición autenticada en nombre de la víctima se escala a acciones privilegiadas:

```html
<script>var x=new XMLHttpRequest();x.open('GET','/admin.php?reveal_flag=1',true);x.withCredentials=true;x.send();</script>
```

# Cabeceras unkeyed: el vector más jugoso

No solo los parámetros GET: es **muy común** que **cabeceras** unkeyed influyan en la respuesta (cabeceras de debug o de proxy que el backend refleja). Misma metodología, y <mark style="background: #FFB8EBA6;">suelen ser más explotables porque el usuario normal nunca las envía</mark>. La checklist que **siempre** se prueba (lista de PortSwigger):

| Cabecera | Uso típico abusable |
| - | - |
| `X-Forwarded-Host` | El backend construye URLs/enlaces absolutos con ella → [[08 - Password Reset Poisoning]], import de scripts |
| `X-Forwarded-Scheme` / `X-Forwarded-Proto` | Fuerza redirects `http→https→` loops o cambia recursos |
| `X-Host`, `X-Forwarded-Server` | Variantes del anterior |
| `X-Original-URL`, `X-Rewrite-URL` | Reescriben la ruta interna |
| `X-Backend-Server` | Cabecera de debug que apunta de dónde carga un script |
| `User-Agent`, `Cookie` | A veces reflejados o keyed por `Vary` |

```http
GET /index.php?language=de HTTP/1.1
Host: webcache.htb
X-Backend-Server: t.htb"></script><script>...payload...</script>//
```

# Cache Busters: imprescindible en un objetivo real

> [!warning] Sin cache buster, tus resultados son ruido
> En un lab con `X-Cache-Status` es trivial. En producción, con **miles de usuarios** golpeando el sitio a la vez, es imposible saber si un `HIT` viene de tu parámetro unkeyed o de que **otro usuario** cacheó la respuesta un segundo antes. Además, <mark style="background: #FF5582A6;">si envenenas mal, sirves el payload roto a usuarios reales</mark> hasta que expire el TTL — ruidoso y potencialmente dañino.
>
> La solución es el **cache buster**: un parámetro/valor **único y unkeyed** en cada prueba (`?cb=8f3a1`, un `Accept-Encoding` raro, etc.) que te da un "carril" de caché propio, aislado del resto de usuarios. Toda prueba de cache poisoning en real se hace con cache buster.

# Herramienta clave: Param Miner

Probar la checklist a mano es lento. **Param Miner** (extensión de Burp de PortSwigger) automatiza justo esto: prueba miles de cabeceras y parámetros de un diccionario, **añade cache busters automáticamente** y detecta cuáles son unkeyed y se reflejan (`Guess headers`, `Guess GET parameters`). Es el estándar para descubrir entradas unkeyed a escala. Lo detallamos, junto al resto del arsenal, en [[05 - Detección, herramientas y prevención de Cache Poisoning]].

> [!info] Detectar caché cuando no hay `X-Cache`
> Si el servidor no informa, la caché se infiere por: la cabecera `Age` (>0 = cacheada), el **tiempo de respuesta** (un `HIT` es notablemente más rápido), un `Date` que no avanza entre peticiones, o contenido dinámico que se queda "congelado". El descubrimiento del reflejo se apoya en las mismas técnicas que el [[04 - Descubrimiento de XSS|descubrimiento de XSS]].

## Referencias

- [PortSwigger — Identifying cache oracles & unkeyed inputs](https://portswigger.net/web-security/web-cache-poisoning#how-to-identify-web-cache-poisoning-vulnerabilities)
- [Param Miner (Burp extension)](https://github.com/PortSwigger/param-miner)
