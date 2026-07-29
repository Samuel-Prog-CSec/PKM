---
tags:
  - Web/Red-Team
  - Race-Condition
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "Entendida la carrera y cómo ganarla, faltan las herramientas para lanzarla, cómo la ve un defensor y cómo se cierra"
Fecha de actualización: 2026-07-27
Nota previa: "[[02 - El single-packet attack (modernización 2023)]]"
Nota siguiente: ""
Area: "[[Race Conditions.base|Race Conditions]]"
---
---

Entendida la carrera y cómo ganarla, faltan las herramientas para lanzarla, cómo la ve un defensor y cómo se cierra.

# Arsenal

**[Turbo Intruder](https://github.com/PortSwigger/turbo-intruder)** (extensión de Burp, scriptable en Python/Jython) — la herramienta de referencia:
- Motores: `Engine.THREADED` (hilos, fallback HTTP/1.1), `Engine.BURP2` (**HTTP/2, necesario para el single-packet attack**).
- *Gate*: `engine.queue(req, gate='race1')` retiene el fragmento final de cada petición; `engine.openGate('race1')` las suelta todas juntas.

```python
def queueRequests(target, wordlists):
    engine = RequestEngine(endpoint=target.endpoint,
                           concurrentConnections=1,
                           engine=Engine.BURP2)          # single-packet attack
    for i in range(20):
        engine.queue(target.req, gate='race1')
    engine.openGate('race1')                             # dispara las 20 a la vez

def handleResponse(req, interesting):
    table.add(req)
```

`RequestEngine` y `table` los inyecta el runtime de Turbo Intruder — no hay que importarlos ni definirlos. <mark style="background: #FFB8EBA6;">Un *timestamp negativo* en la salida de Turbo Intruder</mark> (el servidor empezó a responder antes de terminar de recibir la petición) es señal fuerte de que has pegado en la ventana.

**Burp Repeater** (nativo desde v2023.9): agrupa varias pestañas en un *tab group* y usa **"Send group in parallel"** — elige solo last-byte-sync (HTTP/1.1) o single-packet attack (HTTP/2) automáticamente. Suficiente para la mayoría de casos sin scripting; salta a Turbo Intruder para >30 peticiones o *diffing* a medida.

Otras: **`race-the-web`** (CLI en Go, basado en hilos — opción legacy/gruesa), **PacketSprinter** (extensión Burp que unifica el single-packet sobre muchas pestañas) y **WebSocket Turbo Intruder** para carreras sobre WS.

# Detección (lado defensor)

El abuso de carreras deja firma si se registra lo correcto:
- <mark style="background: #FF5582A6;">Ráfagas de peticiones casi idénticas</mark> (mismo usuario/sesión/recurso) en pocos milisegundos.
- IDs de transacción/pedido/canje **duplicados** para una acción que debería ser única.
- Descuadre entre un saldo/contador y la suma de su histórico de transacciones.
- El patrón **"muchos perdedores, un ganador"**: una ráfaga de `Already redeemed`/`Invalid token` agrupada en torno a un único éxito — delata el intento aunque falle.
- Anomalías de *rate por recurso* (no solo por IP): "20 peticiones contra un mismo order ID en <1s" es lo que el rate-limit por IP no ve.

# Prevención

El tema común (OWASP, PortSwigger): <mark style="background: #FFB86CA6;">empujar la atomicidad a la base de datos, no confiar en el check-then-act de la capa de aplicación</mark>.

- **Update condicional atómico**: fusionar chequeo y escritura — `UPDATE inventory SET qty = qty - 1 WHERE id = ? AND qty > 0` comprobando las filas afectadas, en vez de `SELECT` + `UPDATE`.
- **Locking de fila**: `SELECT ... FOR UPDATE` (o `FOR UPDATE SKIP LOCKED` para colas) serializa el acceso concurrente a la misma fila.
- **Niveles de aislamiento** más fuertes (`REPEATABLE READ` / `SERIALIZABLE`) donde `READ COMMITTED` no baste.
- **Claves de idempotencia** con **`UNIQUE` en BBDD** (no solo chequeo en app): intenta el `INSERT` primero y deja que la violación de constraint sea la señal ("act-first-then-check").
- **Locking optimista** (columna de versión, reintento en conflicto) cuando la contención es rara.
- **Mutexes / locks distribuidos** (Redis/etcd) para estado fuera de BBDD — menos fiable entre instancias que la atomicidad en BBDD.
- **Serialización por cola**: encaminar las mutaciones de un recurso por un consumidor único, con idempotencia para replays.
- **Una sola fuente de verdad**: la causa raíz de GitLab `CVE-2022-4037` fue leer el email a notificar de dos sitios distintos en la misma operación.

> [!info]+ Fuentes
> PortSwigger Research — "[Smashing the state machine](https://portswigger.net/research/smashing-the-state-machine)" y "[The single-packet attack](https://portswigger.net/research/the-single-packet-attack-making-remote-race-conditions-local)" (James Kettle, 2023); [Web Security Academy — Race conditions](https://portswigger.net/web-security/race-conditions); [OWASP — Race Conditions](https://owasp.org/www-community/pages/vulnerabilities/race_conditions); RyotaK/Flatt Security — "[Beyond the Limit](https://flatt.tech/research/posts/beyond-the-limit-expanding-single-packet-race-condition-with-first-sequence-sync/)" (2024).
