---
tags:
  - Web/Red-Team
  - Race-Condition
  - Pentesting/Explotacion
Descripción: "El libro (2019) enmarca las race conditions casi solo como *limit-overrun* (canjear dos veces, exceder un límite)"
Fecha de actualización: 2026-07-27
Nota previa: "[[00 - Fundamentos de Race Conditions (TOCTOU)]]"
Nota siguiente: "[[02 - El single-packet attack (modernización 2023)]]"
Area: "[[Race Conditions.base|Race Conditions]]"
---
---

El libro (2019) enmarca las race conditions casi solo como *limit-overrun* (canjear dos veces, exceder un límite). La investigación de James Kettle *"[Smashing the state machine](https://portswigger.net/research/smashing-the-state-machine)"* (PortSwigger, 2023 — #1 técnica del año) las reorganizó en un mapa de categorías que <mark style="background: #FFB86CA6;">multiplica la superficie a testear</mark>. Conviene conocerlo antes de ver los casos.

# Las categorías principales (PortSwigger 2023)

| Categoría | Mecánica | Ejemplo |
| - | - | - |
| **Limit-overrun** (single-endpoint clásico) | N peticiones en paralelo al **mismo** endpoint antes de que el contador/flag se actualice | Canjear un cupón de un solo uso 20 veces; retirar más saldo del que tienes |
| **Multi-endpoint** | Carrera entre **dos** endpoints que tocan el mismo recurso; la escritura de uno cae en la ventana check-act del otro | Aplicar un cupón mientras se hace el checkout (el pago valida un carrito que otra petición ya modificó) |
| **Single-endpoint** (multihilo interno) | Peticiones paralelas al **mismo** endpoint con **valores distintos**; el handler reparte trabajo entre hilos que se solapan | Dos "cambiar mi email" con destinos distintos → secuestro de la verificación |
| **Sub-estados** (secuencia multi-paso oculta) | Una **sola** petición pasa por estados intermedios transitorios; se ataca ese estado que "no existe" a nivel de API | **Bypass de MFA**: golpear un endpoint autenticado en el ~1ms en que hay sesión válida pero aún no se exige el 2FA |
| **Partial-construction** | Un objeto se construye en pasos (fila → token → commit) y es referenciable a medias | Confirmar una cuenta con `token=` vacío en el instante en que la fila existe pero la columna token es `NULL` |
| **Bypass de rate-limit** | Inundar el endpoint con basura fuerza un backlog que reabre la ventana del contador de rate-limit | Colar intentos de login extra más allá del bloqueo por lockout |

<mark style="background: #ADCCFFA6;">La clave conceptual de Kettle: "con las race conditions, todo es multi-paso"</mark> — incluso una sola petición se descompone en el servidor (auth → lógica → persistencia → side-effects), y esa secuencia interna también es *raceable*.

**Metodología (predict → probe → prove)**: (1) *predecir* qué estado con un chequeo de seguridad se lee/escribe más de una vez; (2) *probar* comparando el comportamiento secuencial con el envío en paralelo (diff de status, longitud, timing, side-effects como emails); (3) *probar el impacto* reduciendo al par mínimo de peticiones y escalando (¿bypass de auth?, ¿pérdida financiera?).

# Los casos del libro

> [!example]+ Aceptar una invitación de HackerOne varias veces — Swag · [H1 #119354](https://hackerone.com/reports/119354)
> Enlace de invitación de un solo uso. Yaworski alineó **dos navegadores** con el botón *Accept* casi superpuesto y pulsó ambos lo más rápido posible; al segundo intento añadió dos usuarios con una sola invitación. *Limit-overrun* explotado **a mano** — cuando los pasos son simples, basta alinear los botones.

> [!example]+ Exceder límites de invitación de Keybase — $350 · [H1 #115007](https://hackerone.com/reports/115007)
> Límite de 3 invitaciones. Josip Franjković envió varias **simultáneamente** con Burp Intruder (payloads = varios emails, envío paralelo) y coló 7. Keybase lo arregló con un *lock*. Cuando los pasos son complejos, la carrera se automatiza.

> [!example]+ HackerOne Payments — $1.000
> Los pagos van por un *background job* (petición a PayPal en cola), que **ensancha** la ventana entre *time of check* (combinar bounties por email) y *time of use* (enviar a PayPal). Jigar Thakkar cambió su email de PayPal **después** de que se combinaran los pagos pero **antes** de que el job los enviara → el pago fue a las **dos** direcciones. Los background jobs son un multiplicador de ventanas.

> [!example]+ Shopify Partners — $15.250 · [H1 #300305](https://hackerone.com/reports/300305)
> El hacker **@cache-money** leyó un reporte previo (@uzsunny, $20.000) y lo re-testeó. Cambió el email de su cuenta partner a `cache@hackerone.com` (que no poseía), interceptó en Burp la petición de cambio **y** la de verificación, y las envió casi a la vez → Shopify validó `cache@hackerone.com` como suyo → acceso a cualquier tienda con un empleado en ese dominio. *Single-endpoint race* sobre la verificación de email. <mark style="background: #FF5582A6;">Lección: arreglar una vuln no arregla todas — lee los reportes divulgados y re-testea</mark>.

# Añadidos modernos

Categorías que 2019 no contempla, hoy de caza habitual: <mark style="background: #FFB86CA6;">bypass de MFA</mark> vía sub-estado, `CVE-2024-58248` (nopCommerce, doble canje de gift card por falta de *lock*), y las carreras **multi-endpoint** de carrito/cupón que pagan miles. El *cómo* técnico para ganar estas carreras —el **single-packet attack**— en la [[02 - El single-packet attack (modernización 2023)|nota siguiente]].
