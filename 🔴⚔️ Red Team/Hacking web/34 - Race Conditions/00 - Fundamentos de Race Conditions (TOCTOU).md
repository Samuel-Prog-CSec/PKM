---
tags:
  - Web/Red-Team
  - Race-Condition
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "Una *race condition* ocurre cuando dos o más procesos compiten por completarse a partir de una condición inicial que deja de ser válida mientras se ejecutan"
Fecha de actualización: 2026-07-27
Nota previa: ""
Nota siguiente: "[[01 - Explotación clásica de Race Conditions]]"
Area: "[[Race Conditions.base|Race Conditions]]"
---
---

<mark style="background: #ADCCFFA6;">Una *race condition* ocurre cuando dos o más procesos compiten por completarse a partir de una condición inicial que deja de ser válida mientras se ejecutan</mark>. El caso de manual — transferir dinero:

1. Tienes $500 y quieres transferirlos.
2. Desde el móvil pides transferir $500.
3. A los 10s sigue procesando; desde el portátil ves saldo $500 y **repites** la transferencia.
4. Ambas peticiones terminan casi a la vez.
5. Tu saldo queda a $0… pero tu amigo recibió $1.000.

El fallo: <mark style="background: #8000E1A6;">el saldo se valida al **inicio** de cada transferencia (*time of check*), pero cuando se ejecutan (*time of use*) la condición ya no es cierta y ambas completan igual</mark>. Es el patrón **TOCTOU** (*time-of-check to time-of-use*): una ventana entre comprobar y usar una condición sobre estado compartido.

# La ventana de carrera

Una petición HTTP parece instantánea, pero **tarda**: reautenticar, cargar datos, aplicar lógica, escribir en la BBDD. <mark style="background: #FFB86CA6;">En ese intervalo, dos peticiones casi simultáneas pueden pasar ambas la comprobación antes de que ninguna actualice el estado</mark> — y ejecutarse las dos. Cuanto más lento el backend (búsquedas en BBDD, lógica compleja, *background jobs*), más ancha la ventana.

Dos disparadores clásicos:
- **Límites**: cualquier acción con un tope (invitaciones, cupones, retiradas, votos, códigos de un solo uso). Si el chequeo del límite y su decremento no son atómicos, se supera.
- **Background jobs**: acciones que no ocurren de inmediato sino en cola (pagos, procesamiento por lotes). Separan aún más el *time of check* del *time of use*.

# Por qué es oro en bug bounty

<mark style="background: #FF5582A6;">Las race conditions tocan lógica de negocio con dinero de por medio</mark>: duplicar pagos, canjear un cupón N veces, exceder límites de invitación, transferir más saldo del que tienes, reutilizar un token de un solo uso, o bypassear anti-brute-force y MFA. Son de las peor cubiertas por escáneres —requieren *timing*— y por eso menos disputadas.

> [!info]+ El marker en el [[03 - Metodología de caza - mapear y atacar la aplicación|mapeo]]
> "Repetir la misma acción en paralelo" o "procesamiento diferido / acción con límite" es la señal. Cuando la veas, la pregunta es: ¿el chequeo y la actualización son atómicos? Si hay una ventana, hay carrera.

Los **casos reales** del libro (invitaciones, límites, pagos, verificación de email) en la [[01 - Explotación clásica de Race Conditions|nota siguiente]]; la **modernización** decisiva —el *single-packet attack* de PortSwigger (2023), que elimina el *jitter* de red y hace explotables ventanas de microsegundos— en [[02 - El single-packet attack (modernización 2023)]].
