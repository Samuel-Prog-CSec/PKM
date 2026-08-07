---
tags:
  - Proyectos
  - Go
  - Web/Red-Team
  - Race-Condition
  - Tipo/Proyecto
Descripción: "Saca el single-packet attack de Burp a un CLI en Go y le antepone la detección sistemática de ventanas explotables, para descubrir la carrera antes de dispararla"
Fecha de actualización: 2026-08-04
Nota previa: "[[12 - Fuzzer adversarial de clasificadores]]"
Nota siguiente: "[[14 - Orquestador de operación]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 5
Esfuerzo: 5 semanas
---
---

**Nombre propuesto**: `photofinish`

Una race condition web se gana o se pierde en una ventana que suele durar <mark style="background: #FFB86CA6;">menos de un milisegundo</mark>. El *single-packet attack* de James Kettle (DEF CON 31, 2023) resolvió el problema de sincronización que lo hacía inviable de forma remota —lograr que veinte peticiones lleguen al servidor a la vez sin importar el *jitter* de la red— y lo empaquetó en Turbo Intruder. Pero Turbo Intruder vive dentro de Burp, es explotación manual, y asume que ya sabes dónde disparar. Este proyecto saca esa precisión a un CLI independiente y, antes de explotar, se ocupa del paso que nadie automatiza: <mark style="background: #ADCCFFA6;">descubrir dónde hay una carrera que ganar</mark>.

# El problema que resuelve

Hay dos huecos, y son distintos:

- **La técnica está atada a Burp.** Turbo Intruder es excelente, pero es una extensión de Burp Suite con motor Jython: no encaja en un pipeline, no se orquesta desde fuera y no corre en un *runner* de CI. Un CLI que implemente el *single-packet attack* de forma *standalone* no existe maduro.
- **Es explotación, no detección.** Turbo Intruder dispara la carrera donde el operador le dice. Nadie sistematiza el paso previo: <mark style="background: #8000E1A6;">qué endpoints de la aplicación exhiben comportamiento de carrera</mark>. Los de semántica de límite —canjear un cupón, retirar saldo, aplicar un descuento, votar, confirmar un pago— son los candidatos naturales, y hoy se prueban de uno en uno a mano.

# Alcance del proyecto

Un CLI que implementa el *single-packet attack* en Go y le antepone una capa de detección. Dos modos:

- **Detección.** Dado un conjunto de endpoints candidatos —entregados por el operador o propuestos por una heurística de semántica de límite—, envía ráfagas sincronizadas y mide si el objetivo entra en estado inconsistente: dos respuestas de éxito donde debería haber una, un saldo que no cuadra, un contador que se pasa del tope. Y **puntúa la ventana**: si es explotable y cuánto vale.
- **Explotación.** Sobre un endpoint confirmado, dispara el *single-packet attack* con el número de peticiones y el payload que el operador defina, ganando la carrera de forma reproducible.

<mark style="background: #FF5582A6;">El reto técnico —y lo que lo hace un proyecto difícil— es el control de bajo nivel de HTTP/2</mark>: el *single-packet attack* consiste en enviar *N* peticiones por una sola conexión reteniendo el *frame* final de cada una, y liberar todos esos fragmentos en un único paquete TCP para que el servidor las procese a la vez. El `net/http` de Go no expone eso; hay que bajar al *framer* de HTTP/2 y gobernar el *flush* del socket. Contra un objetivo que solo habla HTTP/1.1, el *fallback* es el *last-byte sync*, con menos precisión.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| *Single-packet attack* nativo | La sincronización sub-milisegundo de Kettle, fuera de Burp y scriptable |
| Detección de ventana explotable | Descubre la carrera en vez de exigir que ya sepas dónde está |
| Heurística de semántica de límite | Prioriza los endpoints con lógica de "una sola vez": canjear, retirar, aplicar, votar |
| Puntuación de la ventana | Distingue una race explotable de una idempotencia mal hecha; propone, no afirma |
| *Fallback* a *last-byte sync* | Degrada con honestidad cuando el objetivo no da HTTP/2, y lo dice |
| Salida reproducible | El disparo ganador se puede repetir y documentar como evidencia |

# Qué existe ya y dónde se queda corto

**Turbo Intruder** es la referencia y no se discute: implementa *single-packet attack* y *last-byte sync*, y su motor Jython lo hace muy adaptable. `PayloadsAllTheThings` y HackTricks documentan la técnica. Pero todo ese ecosistema es <mark style="background: #FFB8EBA6;">explotación manual dentro de Burp</mark>. `photofinish` no reinventa el *single-packet attack* —lo cita y lo respeta— sino que lo saca a un binario Go automatizable y le pone delante la fase de descubrimiento, exactamente el mismo movimiento que hace el `dyetrace` (03): descubrir el flujo antes de atacar el sumidero, en lugar de asumir que ya lo conoces.

# Cosas a tener en cuenta

> [!warning]+ Ganar una carrera modifica el estado del cliente
> Disparar veinte "retirar saldo" simultáneos que ganan la carrera mueve dinero, duplica pedidos y gasta cupones reales. <mark style="background: #FF5582A6;">Esto no es una prueba pasiva</mark>: en detección hay que operar sobre acciones reversibles o en *staging*, y en producción solo con autorización explícita y sobre operaciones sin efecto económico. La herramienta debe hacer esa distinción evidente, no enterrarla en la documentación.

- **Necesita HTTP/2 (o HTTP/3) para la precisión buena.** Contra un objetivo solo-HTTP/1.1 hay que degradar a *last-byte sync* y reconocer que la ventana efectiva se ensancha.
- **El jitter del servidor no lo arregla la red.** Si el backend introduce su propia variabilidad —colas, *workers*, bloqueos—, la ventana se difumina por mucho que las peticiones lleguen juntas. Hay que medir esa dispersión, no asumir que la sincronización de red basta.
- **Falsos positivos de detección.** Una respuesta duplicada puede ser idempotencia mal implementada, no una race explotable. La detección propone candidatos; la confirmación con el disparo real la hace el operador.
- **La anti-automatización puede matar la ráfaga.** *Rate-limiting* o defensas de bot pueden cortar la ráfaga antes de que la carrera ocurra. La herramienta tiene que distinguir "no hay race" de "no llegué a probar" —confundirlos es reportar un falso negativo con confianza—.

# Fuera de alcance

No es un *crawler* ni un escáner web generalista: se le entregan los candidatos o una heurística acotada. No reimplementa Burp. Y termina en "esta carrera es explotable y vale esto", no en un exploit de lógica de negocio completo —eso lo construye el operador con la ventana ya confirmada—.

# Criterio de terminado

Cuando, sobre un laboratorio con una race explotable (aplicar el mismo cupón varias veces, o retirar un saldo dos veces), la detecta partiendo solo de la lista de endpoints, la confirma con el *single-packet attack* ganando la carrera de forma reproducible, y **no** reporta falso positivo sobre un endpoint idempotente puesto ahí como control.

# Conexiones en el vault

La base teórica está en [[00 - Fundamentos de Race Conditions (TOCTOU)]] y [[01 - Explotación clásica de Race Conditions]]; la técnica que `photofinish` implementa es literalmente [[02 - El single-packet attack (modernización 2023)]], y su cara defensiva, [[03 - Detección, prevención y arsenal de Race Conditions]]. La filosofía de descubrir la ventana antes de dispararla es la misma del [[03 - Rastreador de flujo de datos de caja negra]].

> [!info]+ Fuentes
> - James Kettle, [*Smashing the state machine — the true potential of web race conditions*](https://portswigger.net/research/smashing-the-state-machine), PortSwigger Research / DEF CON 31, 2023 — la investigación que introduce el *single-packet attack* (consultado 2026-08-04).
> - James Kettle, [*The single-packet attack — making remote race-conditions 'local'*](https://portswigger.net/research/the-single-packet-attack-making-remote-race-conditions-local) — el detalle de la sincronización sobre HTTP/2 que hay que reimplementar.
> - PortSwigger, [`Turbo Intruder`](https://github.com/PortSwigger/turbo-intruder) — la implementación de referencia dentro de Burp, de la que `photofinish` se diferencia por ser *standalone* y por detectar además de explotar.
