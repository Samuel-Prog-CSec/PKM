---
tags:
  - Web/Red-Team
  - Fuzzing
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-19
Nota previa: "[[06 - Opciones avanzadas y rendimiento]]"
Nota siguiente: 
Area: "[[Ffuf.base|Ffuf]]"
---
---

HTB enseña `ffuf` como si el objetivo no tuviera defensas. En producción hay WAF, *rate-limiting* y logging que detectan un fuzz a la primera. Esta nota cubre cómo te ven, cómo seguir operando, y qué herramientas complementan a `ffuf` en 2026.

# Cómo te ve el defensor

<mark style="background: #FF5582A6;">Un fuzz con `ffuf` es obvio</mark>: ráfaga de cientos de peticiones/segundo desde una IP, tormenta de `404`, el `User-Agent` por defecto `Fuzz Faster U Fool v2.x` (que grita "esto es ffuf"), y rutas que ningún humano pediría. Un WAF o un rate-limiter lo marca en segundos (respuestas `429`/`403`, o *tarpit*).

# Evasión práctica

- **Cambia el `User-Agent`** a uno de navegador real (el defecto delata la herramienta):
  ```shell-session
  $ ffuf -w wl.txt -u https://target/FUZZ -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
  ```
- **Baja el ritmo bajo el umbral**: `-rate 20 -t 5 -p 0.1-0.5`. Más lento, pero no dispara el rate-limiter ([[06 - Opciones avanzadas y rendimiento|nota 06]]).
- **Rota la IP de origen**: <mark style="background: #FFB86CA6;">`fireprox` levanta un proxy en AWS API Gateway que rota la IP de salida en cada petición</mark>, derrotando el rate-limiting por IP — técnica estándar en bug bounty. Combínalo con `-x`.
- **Detecta y esquiva la página de bloqueo**: filtra la respuesta del WAF (`-fr "Access Denied"`, `-fc 403,429`) para no confundirla con hallazgos, y si aparece `429`, baja el `-rate`.
- **Auto-stop ante bloqueo**: `-sf` detiene el escaneo si >95% de las respuestas son `403` (el WAF ya bloquea; seguir es ruido inútil), `-se` para ante errores espurios, y `-sa` combina ambos.
- **Rota cabeceras**: algunos WAF perfilan combinaciones de cabeceras; varía `User-Agent`/`Accept` o usa `-request` con una petición legítima de base.
- **Codifica el payload al vuelo**: `-enc 'FUZZ:urlencode'` (o `b64encode`) —ffuf ≥2.1.0, vía la librería `pencode`— evade firmas de WAF que buscan el patrón en claro; encadenable para *double-encoding*.

> [!warning]+ Sigilo real vs. autorización
> En un pentest con alcance, avisa antes de fuzzear producción (puedes tumbar un servicio) y respeta el rate del cliente. En bug bounty, muchos programas **prohíben** el fuzzing agresivo o el uso de rotación de IP — léete las reglas. La evasión aquí es para no romper cosas y no generar falsos incidentes, no para saltarte un alcance.

# Arsenal complementario (cuándo cambiar de herramienta)

`ffuf` cubre el 90 %, pero hay tareas donde otra herramienta gana:

| Herramienta | Gana en | Por qué |
| --- | --- | --- |
| [feroxbuster](https://github.com/epi052/feroxbuster) | *Forced browsing* recursivo | Recursión automática e inteligente, Rust, rapidísimo |
| [x8](https://github.com/Sh1Yo/x8) / [Arjun](https://github.com/s0md3v/Arjun) | Parámetros ocultos | Detectan params que cambian el comportamiento sutilmente |
| [kiterunner](https://github.com/assetnote/kiterunner) | **Rutas de API** | Usa specs (Swagger) y wordlists de API; supera a ffuf en REST. *Sin commits desde 2021* — sus wordlists (`routes-large.kite`) siguen útiles reproducidas con `ffuf` si el binario da guerra |
| [param-miner](https://github.com/PortSwigger/param-miner) | Cabeceras / *cache poisoning* | Extensión de Burp, imbatible para params de cabecera |
| Burp Intruder / Caido | Sesiones complejas, macros | Cuando hace falta re-login o encadenar tokens |

<mark style="background: #8000E1A6;">Regla: `ffuf` para todo lo flexible y rápido; `feroxbuster` cuando quieras recursión sin pensar; `kiterunner` para APIs; `param-miner` para cabeceras y `cache`.</mark> Y las `wordlists` importan más que la herramienta: además de `SecLists`, las [listas de Assetnote](https://wordlists.assetnote.io/) (generadas de datos reales, actualizadas) marcan la diferencia en objetivos serios.

> [!info]+ Fuentes
> [ffuf (GitHub + wiki)](https://github.com/ffuf/ffuf) · [fireprox](https://github.com/ustayready/fireprox) · [Assetnote Wordlists](https://wordlists.assetnote.io/) · [HackTricks — Web Fuzzing](https://book.hacktricks.xyz/). La metodología que envuelve todo esto está en [[15 - Introducción al web fuzzing|Reconocimiento Web]], y la evasión a nivel metodología en [[27 - Evasión en recon y fuzzing]].

Con esto se cierra la referencia de `ffuf`: de la palabra `FUZZ` a la evasión de WAF y el arsenal que lo rodea.
