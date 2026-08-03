---
tags:
  - Web/Red-Team
  - Race-Condition
  - Pentesting/Explotacion
Descripción: "Ganar una race condition remota es un problema de sincronización: las peticiones tienen que llegar al servidor dentro de una ventana que suele ser de menos de un milisegundo"
Fecha de actualización: 2026-07-27
Nota previa: "[[01 - Explotación clásica de Race Conditions]]"
Nota siguiente: "[[03 - Detección, prevención y arsenal de Race Conditions]]"
Area: "[[Race Conditions.base|Race Conditions]]"
---
---

Ganar una race condition remota es un problema de **sincronización**: las peticiones tienen que llegar al servidor dentro de una ventana que suele ser de <mark style="background: #ADCCFFA6;">menos de un milisegundo</mark>. Lo que separa un intento fiable de uno a ciegas es cómo envías los paquetes. Esta es la modernización que vuelve obsoleto el enfoque de 2019.

# Antes: last-byte sync (HTTP/1.1)

La técnica clásica sobre HTTP/1.1 (que no multiplexa: una petición = una conexión):
1. Abrir N conexiones TCP/TLS, una por petición.
2. Enviar cada petición **entera menos el último byte**.
3. Con todas "cebadas" y esperando, soltar el último byte de todas casi a la vez.

Problema: <mark style="background: #FFB86CA6;">cada último byte es su propio paquete, sujeto al *jitter* de red independiente de N conexiones distintas</mark>. Kettle midió una dispersión mediana de **~4ms** para 20 peticiones a larga distancia — a menudo demasiado para una ventana de microsegundos.

# Ahora: el single-packet attack (HTTP/2+)

Kettle (*"[The single-packet attack](https://portswigger.net/research/the-single-packet-attack-making-remote-race-conditions-local)"*, 2023) aprovecha que **HTTP/2 multiplexa** muchas peticiones sobre una sola conexión TCP:

1. Abrir **una sola** conexión HTTP/2.
2. Encolar 20-30 peticiones, cada una reteniendo un **fragmento final** (sin cuerpo: cabeceras sin el flag `END_STREAM` + retener el frame `DATA` vacío; con cuerpo: retener el último byte).
3. Esperar ~100ms a que todo lo demás llegue y se bufferice en el servidor, sin procesar.
4. Soltar todos los fragmentos retenidos juntos (con `TCP_NODELAY` desactivado, Nagle los agrupa) → **un único paquete TCP**.

Como todas las peticiones se completan en **ese** paquete, el orden y el timing dejan de depender del jitter de red: <mark style="background: #8000E1A6;">la carrera pasa de ser un problema de red a uno de *scheduling* local del servidor</mark>. Dispersión mediana: **~1ms** (mejora de 4-10×). Kettle lo resume como *"hacer locales las race conditions remotas"*.

<mark style="background: #FFB8EBA6;">Techo práctico: ~1 MTU de Ethernet (~1.500 bytes)</mark> — suficiente para 20-30 peticiones típicas, no más.

> [!warning]+ Session-based locking: el obstáculo que arruina intentos
> Algunos frameworks (el handler de sesión nativo de **PHP**, p. ej.) **serializan** todas las peticiones que comparten la misma cookie de sesión — matan la carrera en silencio. Workaround: usar **sesiones/tokens distintos** por petición paralela, o **quitar la cookie** de sesión donde la operación no la exija.

> [!info]+ Connection warming
> Los proxies/balanceadores reparten peticiones entre conexiones de backend, y la primera de una conexión nueva sufre latencia extra (setup TLS). Enviar antes una petición inocua (`GET /`) "calienta" la conexión para que las de ataque salgan sobre algo ya establecido — clave en carreras **multi-endpoint** que reparten peticiones entre conexiones.

# Después: la técnica sigue viva (2024-2025)

- **First Sequence Sync** (RyotaK / Flatt Security, *"[Beyond the Limit](https://flatt.tech/research/posts/beyond-the-limit-expanding-single-packet-race-condition-with-first-sequence-sync/)"*, 2024): rompe el techo de la MTU con **fragmentación IP**, reteniendo el fragmento con el número de secuencia TCP inicial → el servidor no puede reensamblar **nada** hasta soltarlo. Demostró **10.000 peticiones en ~166ms** (limitado por `SETTINGS_MAX_CONCURRENT_STREAMS`). Para ataques que necesitan miles de intentos en una ventana (brute-force de un token de un solo uso).
- **WebSocket Turbo Intruder** (PortSwigger, 2025): lleva la carrera al protocolo **WebSocket**, superficie que ni 2019 ni 2023 cubrían.

La herramienta que implementa todo esto (Turbo Intruder, Burp Repeater paralelo), cómo lo detecta un defensor y cómo se previene, en la [[03 - Detección, prevención y arsenal de Race Conditions|nota siguiente]].
