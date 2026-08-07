---
tags:
  - Proyectos
  - Go
  - Web/Red-Team
  - Evasion
  - Tipo/Proyecto
Descripción: "Mide tu propia huella cross-layer (JA4, JA4H, HTTP/2, timing) y detecta las incoherencias que te delatan aunque hayas suplantado el fingerprint TLS"
Fecha de actualización: 2026-08-04
Nota previa: "[[01 - Registro de operación a prueba de manipulación]]"
Nota siguiente: "[[03 - Rastreador de flujo de datos de caja negra]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 2
Esfuerzo: 2-3 semanas
---
---

**Nombre propuesto**: `mirror`

Suplantar el fingerprint TLS de Chrome es un problema resuelto: `uTLS` lleva años permitiéndolo y `curl-impersonate` lo empaqueta. El problema que **no** está resuelto es saber si tu suplantación es coherente. <mark style="background: #ADCCFFA6;">Un `JA4` perfecto de Chrome 130 combinado con un orden de cabeceras que no es el de Chrome, o con una ventana HTTP/2 que no coincide, es más sospechoso que no haber suplantado nada</mark>: los sistemas que importan ya no miran una sola capa, miran la coherencia entre todas.

Este proyecto no suplanta nada. Te dice **cómo te ven**, y en qué capa se rompe tu disfraz.

# El problema que resuelve

En 2026, `JA4+` está desplegado en Cloudflare, AWS y VirusTotal, y la recomendación explícita de los defensores es la **detección cruzada**: contrastar `JA4` (TLS) con `JA4H` (cabeceras HTTP), `JA4T` (parámetros TCP) y las `SETTINGS` de HTTP/2 para cazar inconsistencias. Un cliente que dice ser Chrome en el `ClientHello` pero negocia HTTP/1.1, o que envía `Accept-Language` antes que `User-Agent` cuando Chrome hace lo contrario, se marca solo.

El pentester y el bug hunter operan a ciegas frente a esto. Sabes que te han bloqueado; no sabes **por qué capa**. Y el ciclo de prueba y error contra un WAF de producción es caro: cada iteración es un baneo de IP.

# Alcance del proyecto

Una herramienta con dos modos que comparten el mismo motor.

**Modo espejo.** Levanta un servidor propio que actúa de superficie de medición: recibe la conexión de tu herramienta y devuelve un informe completo de todo lo observable. El `ClientHello` crudo y su `JA4`; el orden literal de las extensiones y de los grupos soportados; los parámetros TCP de la SYN (`JA4T`); el orden exacto de las cabeceras HTTP y su capitalización (`JA4H`); las `SETTINGS`, la tabla de prioridades y el tamaño de ventana de HTTP/2; y el perfil temporal entre peticiones.

**Modo veredicto.** Compara ese perfil contra una **base de referencia** de clientes reales —Chrome, Firefox, Safari, Edge, y también `curl`, `python-requests` y `Go net/http`— y señala qué campos no cuadran:

```shell-session
$ mirror check --profile chrome-142 --target http://localhost:8443
[ok]    JA4    t13d1516h2_8daaf6152771_b1ff8ab2d16f   coincide con chrome-142
[ok]    ALPN   h2,http/1.1
[FALLO] JA4H   orden de cabeceras difiere en posición 3
        esperado: sec-ch-ua, sec-ch-ua-mobile, sec-ch-ua-platform, upgrade-insecure-requests
        recibido: sec-ch-ua, upgrade-insecure-requests, sec-ch-ua-mobile
[FALLO] H2     SETTINGS_INITIAL_WINDOW_SIZE=65535 (chrome-142 usa 6291456)
[AVISO] TIMING intervalo constante de 200 ms ± 3 ms — ningún navegador es tan regular
```

<mark style="background: #FF5582A6;">Esa salida es exactamente lo que un pentester no tiene hoy</mark> y lo que convierte "me bloquean y no sé por qué" en una lista de tres cosas que arreglar.

# Funcionalidades principales

| Funcionalidad | Detalle |
| --- | --- |
| Cálculo de `JA4`, `JA4H`, `JA4T` y `JA4S` | Implementación propia sobre la especificación de FoxIO, no una dependencia opaca |
| Base de referencia versionada | Perfiles de navegador con número de versión y fecha de captura. **Caducan**: un perfil de Chrome de hace seis meses ya no coincide con el Chrome de hoy |
| Diferencial campo a campo | No un "coincide / no coincide", sino qué extensión sobra, cuál falta y en qué posición |
| Análisis de temporización | Distribución de intervalos entre peticiones frente a la de navegación humana; detecta la regularidad de máquina |
| Modo pasivo sobre `pcap` | Calcular los mismos fingerprints sobre una captura, para auditar el tráfico que generó otra herramienta |

# Qué existe ya y dónde se queda corto

- **`uTLS`** (Go) da control total sobre el `ClientHello` y trae presets de navegador. Es la pieza con la que se *construye* el disfraz, no con la que se *verifica*.
- **`curl-impersonate`** replica el conjunto TLS + HTTP/2 de navegadores concretos. Resuelve el caso "quiero que mi `curl` parezca Chrome", pero no dice nada sobre una herramienta arbitraria.
- Los **servicios web de fingerprinting** (los `tls.peet.ws` y similares) muestran tu `JA3`/`JA4` y poco más: no comparan contra una referencia, no cubren TCP ni el perfil temporal, y obligan a mandar tu tráfico a un tercero — inaceptable durante un engagement.

El hueco es la **verificación cruzada local y offline**. Nadie te da hoy un veredicto de coherencia.

# Cosas a tener en cuenta

> [!warning]+ La base de referencia es el proyecto, no un accesorio
> Un perfil de navegador se queda obsoleto en semanas. <mark style="background: #FFB8EBA6;">Si la base no se puede regenerar de forma trivial, la herramienta miente con confianza a los tres meses</mark>. Diseña desde el principio el flujo de captura (un navegador real contra tu propio servidor espejo, exportando el perfil) y trátalo como parte del producto.

- **Go tiene una limitación real aquí**: su `crypto/tls` no te da el `ClientHello` crudo con las extensiones en orden si actúas como cliente estándar. Como servidor, `tls.Config.GetConfigForClient` te entrega un `ClientHelloInfo` que **ya está parseado y normalizado** — pierdes precisamente el orden que necesitas. La solución es leer los bytes del handshake antes de entregárselos a la librería, o construir el servidor de medición sobre una implementación que exponga el registro crudo.
- **Suplantar mejor no siempre es lo correcto.** Contra un objetivo con detección madura, un `Go net/http` honesto con un `User-Agent` que te identifica como el pentester autorizado puede ser la decisión acertada — y el equipo azul lo agradece. La herramienta debe servir igual para *parecerse* que para *comprobar que eres reconocible*, que es lo que pide un ejercicio no evasivo.
- **HTTP/3 y QUIC ya no son un extra.** Si el objetivo negocia `h3`, tu perfil de HTTP/2 es irrelevante y el fingerprint cambia de superficie por completo. Vale dejarlo fuera de la primera versión, pero no de la arquitectura.
- **Cuidado con el efecto rebote.** Un fingerprint idéntico al de un navegador es indistinguible por definición, y algunas defensas responden a eso puntuando el *comportamiento* (secuencia de recursos cargados, ausencia de peticiones a favicon y fuentes). Medir la huella no te hace invisible; te quita las señales groseras.

# Fuera de alcance

No es un cliente HTTP evasivo ni un sustituto de `uTLS`. No hace la suplantación: la audita. Fusionar ambas cosas duplica un proyecto excelente que ya existe.

# Criterio de terminado

Cuando `curl`, `python-requests` y un `Go net/http` desnudo se distinguen entre sí y de un Chrome real solo con la salida de la herramienta; y cuando un cliente construido con `uTLS` que suplanta Chrome pasa el `JA4` pero la herramienta caza al menos una incoherencia de capa superior.

# Conexiones en el vault

Los fundamentos del handshake que se está midiendo están en [[02 - Handshake TLS 1.2 y 1.3]]; el contexto de PKI y ALPN, en [[00 - Introducción a HTTPS y TLS]]. La huella es el peldaño más bajo de la Pyramid of Pain y conviene leerlo con [[01 - Frameworks de threat intelligence y la Pyramid of Pain]] delante: cambiar un `JA4` es barato para ti y por eso los defensores no se quedan ahí.

> [!info]+ Fuentes
> - FoxIO, [especificación de JA4+](https://github.com/FoxIO-LLC/ja4) — definición de `JA4`, `JA4S`, `JA4H`, `JA4T` y su formato (consultado 2026-08-04).
> - `refraction-networking/utls`, [documentación](https://pkg.go.dev/github.com/refraction-networking/utls) — control del `ClientHello` en Go.
> - Devesh Shetty, [JA4 in the Wild — Signal, Drift, and Evasion](https://deveshshetty.com/blog/ja4-client-fingerprinting/) — deriva de perfiles entre versiones de navegador y detección cruzada de capas.
