---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Cache-Poisoning
Fecha de actualización: 2026-07-14
Nota previa: "[[02 - Identificación de parámetros unkeyed]]"
Nota siguiente: "[[04 - Técnicas avanzadas de Cache Poisoning]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

El cache poisoning casi nunca es el bug final: es el **multiplicador** que distribuye otra vulnerabilidad de la aplicación a muchos usuarios. Por eso su explotación depende del bug subyacente. Aquí vemos los vectores más comunes y —lo más difícil— **cómo lograr que la respuesta maliciosa se cachee**.

# Vectores de explotación

| Vector | Mecánica | Impacto |
| - | - | - |
| **XSS** (el más común) | Parámetro o cabecera unkeyed reflejado sin sanitizar | XSS servido a todos, sin interacción; arma un XSS-por-cabecera que solo no era explotable |
| **Cookies unkeyed** | Cookie que fija preferencias (`consent=1`, `color=blue`, `language=en`) y es unkeyed | Fuerza esa preferencia a todos los usuarios |
| **DoS** | Caché que normaliza mal la key + `Host` usado en un redirect | Redirige a todos a un puerto/host muerto → sitio inaccesible |

**XSS** ya lo vimos: `ref` o `X-Backend-Server` reflejados → payload cacheado → ejecución en cada visitante.

**Cookies unkeyed**: si `consent` es unkeyed, `Cookie: consent=1` cacheado hace que todos vean el contenido como si hubieran consentido. <mark style="background: #FFB8EBA6;">Pero estos casos se detectan rápido</mark>: al envenenarse la caché en el uso cotidiano (un usuario elige `color=blue` y a los demás les sale azul), los responsables notan que "algo va raro".

**DoS por Host**: una caché defectuosa incluye `Host` en la key pero **normaliza quitando el puerto**, mientras la app usa `Host` para construir un redirect absoluto:

```http
GET / HTTP/1.1
Host: webcache.htb:1337
→
HTTP/1.1 302 Found
Location: http://webcache.htb:1337/index.php   ← cacheado sin el puerto en la key
```

Cacheada esa respuesta, <mark style="background: #FFB86CA6;">todos los usuarios son redirigidos al puerto 1337</mark> (donde no hay servicio) y no pueden acceder. Es la puerta a los [[06 - Introducción a los Host Header Attacks|Host Header Attacks]].

> [!info] CPDoS: la formalización moderna del DoS por caché
> El DoS por caché tiene nombre propio desde 2019: **CPDoS** (*Cache Poisoned Denial of Service*, Nguyen et al.). La idea general: enviar una petición que provoque una **respuesta de error** y conseguir que la caché guarde ese error. Variantes:
> - **HHO** (*HTTP Header Oversize*): una cabecera enorme que el backend rechaza con error, pero la caché cachea el `400`.
> - **HMC** (*HTTP Meta Character*): un carácter de control (`\n`, `\a`) que rompe el backend.
> - **HMO** (*HTTP Method Override*): `X-HTTP-Method-Override` que confunde a intermediarios.
> Un `400/404` cacheado en la home = sitio caído para todos.

# El reto real: que se cachee TU respuesta

Poner el payload en la petición es fácil; **lograr que la caché lo almacene** no. En un sitio con tráfico, cuando pides el recurso lo más probable es que ya esté cacheado y solo recibas la copia. Herramientas:

- **`Cache-Control: no-cache` en la petición**: la mayoría de cachés lo respetan y **revalidan** con el backend en vez de servir la copia — así tu petición llega al servidor. (`Pragma: no-cache` es la variante deprecada.)
- Pero eso **no fuerza a refrescar** la copia guardada. Para que tu respuesta envenenada se cachee hay que **esperar a que expire** el TTL y **acertar el momento** de reenviarla. Mucho ensayo y error.
- Atajo: leer el `Cache-Control` / `Age` de la respuesta para saber cuántos segundos queda fresca y cronometrar.

# Cache Busters como medida de seguridad (no solo de precisión)

> [!warning] Ética: nunca envenenes la caché real
> En bug bounty, envenenar la caché de producción con un payload roto <mark style="background: #FF5582A6;">**DoSea a usuarios reales**</mark> hasta que expire el TTL. Es un daño real y puede sacarte del programa. La regla profesional: **todo PoC de cache poisoning se hace con cache buster**.
>
> Un **cache buster** es un valor único que solo tú usas (en un parámetro unkeyed o en `language=valor-irrepetible`), garantizando una cache key **exclusiva tuya**. Así solo tú recibes la respuesta envenenada y demuestras el bug sin tocar a nadie. Cada petición de seguimiento necesita un buster **nuevo** (la key anterior ya existe cacheada).

```http
GET /index.php?language=cb-9f3a1&ref="><script>alert(document.domain)</script> HTTP/1.1
Host: webcache.htb
# language=cb-9f3a1 = cache buster: aísla tu prueba del resto de usuarios
```

En el informe, se demuestra el poison sobre tu propia key y se explica que un atacante real usaría la key legítima de la víctima (p. ej. `language=de` para un admin alemán).

# Impacto

Depende del bug distribuido, de la **fiabilidad** del poison, del **TTL** y de cuántas víctimas visiten en esa ventana. Si la caché incluye `User-Agent` u otra cabecera en la key, hay que <mark style="background: #FFB8EBA6;">envenenar cada grupo por separado</mark> (una key por navegador). El siguiente paso, [[04 - Técnicas avanzadas de Cache Poisoning]], ataca precisamente la **normalización** de la cache key para ampliar el alcance.

## Referencias

- [PortSwigger — Exploiting web cache poisoning](https://portswigger.net/web-security/web-cache-poisoning/exploiting)
- [CPDoS — Cache Poisoned Denial of Service (2019)](https://cpdos.org/)
