# Redis en el proyecto

> Nota de estudio para la defensa. Todo lo de aquí está verificado contra el código real del backend (última verificación: julio 2026, cruzando cada afirmación con `backend/src/`).
>
> **Cómo leer esta nota:** si no sabes nada de Redis, lee primero el **Glosario mínimo** (§1). Con eso, el resto se entiende sin saltos.

---

## 1. Glosario mínimo (para leer el resto sin perderse)

Estos son todos los términos que aparecen después. Con entenderlos "por encima" basta.

| Término | En una frase |
|---|---|
| **Clave → valor** | Como un diccionario gigante: guardas un valor bajo una clave (un nombre) y lo recuperas por ese nombre. |
| **En memoria (RAM)** | Los datos viven en la memoria rápida del servidor, no en el disco. Por eso leer/escribir tarda microsegundos en vez de milisegundos. |
| **TTL** (*time to live*) | Tiempo de vida de una clave. Le dices "guarda esto durante N segundos" y, pasado ese tiempo, Redis la borra **solo**. |
| **Atómico** | Una operación que ocurre "de golpe", sin que otra se cuele en medio. Evita las *condiciones de carrera* (dos cosas pisándose). |
| **O(1)** | Coste constante: tarda lo mismo tenga Redis 10 claves o 10 millones. Comprobar "¿existe esta clave?" es O(1). |
| **Hash** (en Redis) | Un valor que a su vez es un mini-objeto con campos, como un registro con columnas (`userId`, `familyId`, …). |
| **Sorted Set / ZSET** | Un conjunto donde cada elemento lleva una puntuación y Redis lo mantiene **ordenado él solo**. Ideal para rankings. |
| **Lock distribuido** | Un "cartel de OCUPADO" puesto en un sitio central que varios procesos consultan para no pisarse. |
| **Script Lua** | Un mini-programa que Redis ejecuta **entero y sin interrupción** (atómico) para agrupar varias operaciones en una. |
| **Stateless** (JWT) | Un token que se valida **solo**, sin consultar una BD de sesiones. Es rápido, pero no se puede "revocar" sin ayuda extra (de ahí la lista negra). |
| **Pipeline** | Enviar varios comandos en **un solo viaje de red** en lugar de uno a uno. |
| **cache-aside** | Patrón de caché: mira la caché primero; si no está, calcula el dato, lo guarda en caché y lo devuelve. |

---

## 2. ¿Qué es Redis? (explicación breve)

Redis (**RE**mote **DI**ctionary **S**erver) es una **base de datos en memoria** de tipo clave-valor. La diferencia clave con MongoDB (o cualquier BD tradicional) es que **guarda los datos en la RAM**, no en disco, por lo que las lecturas y escrituras son extremadamente rápidas (microsegundos en lugar de milisegundos).

Ideas para explicarlo en 30 segundos:
- Es un **almacén clave → valor**, como un diccionario gigante compartido por todo el backend.
- No solo guarda *strings*: soporta **estructuras de datos** (listas, conjuntos, *hashes*, conjuntos ordenados/*sorted sets*, contadores…). Esto lo diferencia de un simple caché.
- Cada clave puede tener un **TTL**: se autodestruye pasado un tiempo. Perfecto para cosas temporales (tokens, bloqueos, cachés).
- Puede persistir a disco (nosotros usamos **AOF**, *append-only file*), pero su fortaleza es que es **efímero y rápido**.
- Muchas operaciones son **atómicas** (un `INCR` o un script Lua se ejecutan sin que nadie se cuele en medio), lo que lo hace ideal para coordinar concurrencia.

**Frase resumen para el tribunal:** *"Redis es nuestra capa de estado rápido y efímero: todo lo que necesita ser veloz, temporal o coordinado entre peticiones (tokens, límites de peticiones, bloqueos, caché) vive en Redis, no en MongoDB."*

---

## 3. ¿Para qué usamos Redis en el proyecto?

Redis es la **columna vertebral de seguridad, rendimiento y coordinación** del backend. Usos reales:

| Área | Qué resuelve Redis |
|---|---|
| **Seguridad — sesiones/JWT** | Lista negra de tokens revocados, refresh tokens, detección de robo de tokens, revocación masiva de sesiones |
| **Seguridad — fuerza bruta** | Bloqueo de cuentas tras fallos de login, bloqueo de MFA, anti-replay de códigos TOTP |
| **Rate limiting** | Límite de eventos WebSocket (Lua sobre ZSET). El HTTP también puede ir por Redis, pero hoy va en memoria — ver el matiz en §5.2 |
| **Juego (RFID)** | Bloqueos distribuidos de tarjetas, *snapshot* de partidas para recuperación, anti-replay del contador RFID |
| **Rendimiento** | Caché de mecánicas, contextos y analytics (patrón *cache-aside*) |
| **Analytics** | *Leaderboards* (rankings) con *sorted sets*, métricas materializadas de alumnos |
| **Colas de trabajo** | BullMQ: retención de datos RGPD, detección de alertas (de docente y de sistema) y reconciliación nocturna de analytics |

La biblioteca cliente es **`ioredis`** (elegida frente a `node-redis` por su API de *pipelines* más limpia). Toda la conexión se centraliza en un cliente **singleton** en `config/redis.js`.

> Las colas de **exportaciones** y **notificaciones** existen como andamiaje (registradas en BullMQ) pero **todavía sin proceso trabajador**: no las cuentes como funcionales en la defensa. Las notificaciones reales del sistema van por *pub/sub*, no por esa cola.

---

## 4. ¿Cómo lo usamos? (detalle técnico)

### 4.1 Namespaces y estructuras de datos

Cada dato lleva un **prefijo de espacio de nombres** para no colisionar. Formato de clave: `<prefijo>:<namespace>:<id>`. El prefijo lo añade automáticamente ioredis (opción `keyPrefix`); por defecto es `rfid-games:`, y es **configurable por entorno** (en producción suele ser algo como `eduplay:prod:` para no mezclar claves si se comparte instancia).

Elegimos la **estructura de datos Redis según el uso**, no siempre *strings*:

| Uso | Estructura | TTL | Por qué esa estructura |
|---|---|---|---|
| Lista negra de JWT | String (`'1'`) | lo que le queda al token | Solo importa si la clave existe → `EXISTS` es O(1) |
| Refresh token (activo) | **Hash** | 7 días | Objeto con varios campos (`userId`, `familyId`, `createdAt`) |
| Flag "cerrar todas las sesiones" | String (marca de tiempo) | 7 días | Invalida cualquier token emitido antes de ese instante |
| Snapshot de partida | **Hash** | 90 s (+ latido cada 30 s) | Estado de la partida serializado y reescrito con `HSET` completo |
| Lock de idempotencia (arranque de partida) | String | 60 s | Evita que una misma partida arranque dos veces |
| Bloqueo de tarjeta RFID | String (`playId`) | 90 s | Marca "esta tarjeta está en uso por esta partida" |
| Rankings / *leaderboards* | **Sorted Set (ZSET)** | 8 días | Ordena por puntuación automáticamente (`ZINCRBY`/`ZREVRANGE`) |
| Métricas de alumno | **Hash** | 90 días | `HINCRBY` para acumular sin leer-modificar-escribir |
| Contador de fallos de login | String (`INCR`) | ventana 15 min (fija) | Incremento atómico |
| Anti-replay de código TOTP (MFA) | String (`'1'`) | ≈ 90 s (ventana del código) | `SET NX`: si la clave ya existía, el código se está reutilizando |
| Rate limit de WebSocket | **ZSET** (ventana deslizante) | ventana | *Sliding window* con marcas de tiempo, vía Lua |
| Cachés (mecánicas/contextos/analytics) | String (JSON) | segundos–minutos (+ *jitter*) | Datos descartables; se recalculan si faltan |

> **Corrección importante que conviene tener clara:** el `HINCRBY` (incremento atómico de un campo) es de las **métricas de alumno**, no del snapshot de partida. El snapshot se guarda con `HSET` reescribiendo el estado entero cada vez. Son dos Hashes distintos con propósitos distintos.

### 4.2 Los tres conceptos "estrella" (explicados desde cero)

Estos tres son los que más lucen y los que más te pueden preguntar. Van explicados primero **qué son en general** y luego **cómo los usamos**.

---

#### 🔑 TTL (tiempo de vida): la pieza que hace que "se limpie solo"

**Qué es.** Un TTL es una fecha de caducidad que le pones a una clave: "guarda esto durante 90 segundos". Cuando ese tiempo pasa, Redis borra la clave **por su cuenta**, sin que nadie tenga que ejecutar una limpieza. Es la diferencia entre *"tengo que acordarme de borrar esto"* y *"se borra solo"*.

**Por qué es tan importante en este proyecto** (tres ejemplos que valen para el tribunal):
- **La lista negra de tokens no crece infinitamente.** Cada token revocado se guarda con un TTL igual al tiempo que le quedaba de vida al propio token. Cuando el token habría caducado de todas formas, su entrada en la lista negra desaparece sola. Sin TTL, esa lista crecería para siempre.
- **Los bloqueos no se quedan "colgados".** Si el proceso que bloqueó una tarjeta se cae sin liberarla, el TTL de 90 s la libera solo. Es un **auto-desbloqueo de seguridad**: nunca una tarjeta queda bloqueada para siempre por un fallo.
- **Las cachés se refrescan solas** y los contadores de fuerza bruta se reinician al terminar su ventana de 15 minutos.

**Frase para la defensa:** *"El TTL convierte a Redis en un sistema que se limpia a sí mismo. En una capa de seguridad, olvidarse de limpiar es una fuga de memoria o, peor, datos obsoletos que 'resucitan'; el TTL elimina ese riesgo por diseño."*

---

#### 🔒 Locks distribuidos: el "cartel de OCUPADO" de las tarjetas

**Qué es.** Un *lock* (bloqueo) es un cartel de OCUPADO. Cuando un recurso solo puede usarlo uno a la vez, pones el cartel antes de usarlo y lo quitas al terminar; los demás, si ven el cartel, esperan o se van a otro sitio. Se llama **distribuido** porque el cartel no está en la memoria de un proceso concreto, sino en un **sitio central (Redis)** que todos consultan. Así el bloqueo funcionaría incluso si hubiera varios servidores.

**Cómo lo usamos.** Cada tarjeta RFID física solo puede estar en una partida a la vez. Al arrancar una partida:
- Ponemos en Redis una clave `card:<uid>` con el `playId` (el id de la partida). Ese es el cartel de OCUPADO de esa tarjeta.
- La reserva es **todo-o-nada**: o se reservan todas las tarjetas de la partida, o ninguna (se hace con un script Lua atómico, ver el siguiente bloque). Si otra partida intenta usar una tarjeta ya reservada, la reserva falla y se avisa: *"la tarjeta ya está en uso en otra partida"*.
- El **TTL de 90 s es la red de seguridad**: si el proceso muere, el cartel se retira solo. Mientras la partida sigue viva, un **latido cada 30 s** renueva el cartel para que no expire antes de tiempo (margen 3×: caduca a los 90, se renueva cada 30).

**Frase para la defensa:** *"Es un candado con temporizador: garantiza exclusión mutua sobre la tarjeta física y, a la vez, se libera solo si el dueño desaparece, así que un fallo nunca deja tarjetas bloqueadas indefinidamente."*

---

#### ⚙️ Scripts Lua atómicos: varias operaciones "todas juntas o ninguna"

**El problema que resuelven.** A veces necesitas hacer **varias operaciones sobre Redis que tienen que ocurrir sin que nadie se cuele en medio**. Ejemplo: comprobar que 20 tarjetas están libres y reservarlas. Si entre el "comprobar" y el "reservar" otra partida reserva una de esas tarjetas, tendrías un conflicto: es una **condición de carrera**.

**La solución.** Redis deja enviar un pequeño programa escrito en **Lua** (un lenguaje de scripting ligero) que Redis ejecuta **de principio a fin sin interrupciones**. Eso es ser **atómico**: o se ejecuta entero, o no se ejecuta. Nadie puede colarse en mitad del script.

**Qué ganamos con ellos (dos cosas):**
1. **Corrección.** Reservar / renovar / liberar tarjetas se vuelve una operación indivisible, imposible de corromper por concurrencia.
2. **Rendimiento (muy menos comandos).** Agrupar operaciones reduce drásticamente los viajes de red a Redis:
   - Reservar 20 tarjetas: de **20 comandos a 1**.
   - El latido de renovación de una partida con 20 tarjetas: de **61 comandos a 1** (por cada tarjeta hacía leer + comparar + renovar).

**Detalle técnico que suena bien:** los scripts se cargan una sola vez al arrancar con `SCRIPT LOAD`, que devuelve un *hash* identificador. Luego se invocan por ese hash con `EVALSHA`, sin reenviar el código cada vez. Si Redis reinicia y no reconoce el hash (`NOSCRIPT`), el código reintenta con `EVAL` mandando el script completo.

**Scripts Lua reales del proyecto (5):**
- `reserveCards.lua` — reservar N tarjetas (todo-o-nada).
- `renewLease.lua` — el latido que renueva los bloqueos de una partida viva.
- `releaseCards.lua` — liberar tarjetas al terminar.
- `rfidCounterCas.lua` — el contador anti-replay del sensor (ver §4.3c).
- `checkSocketRateLimit.lua` — el rate limit de WebSocket (ventana deslizante sobre ZSET).

**Frase para la defensa:** *"Los scripts Lua nos dan atomicidad y, de paso, un ahorro brutal de comandos: convertimos decenas de idas y vueltas a la red en una sola, ejecutada sin condiciones de carrera."*

### 4.3 Los tres usos de seguridad y juego, en detalle

**a) Seguridad de tokens JWT.** El JWT es *stateless* (auto-verificable sin BD), lo cual es rápido pero tiene un problema: **no se puede "cerrar sesión" de verdad**, porque el token sigue siendo válido hasta que caduca. Lo resolvemos con Redis:
- Al hacer *logout* o revocar, metemos el `jti` (identificador del token) en una **lista negra** con TTL = tiempo que le queda al token. Cuando el token caduca, la entrada se autodestruye (no crece infinitamente).
- Cada petición autenticada comprueba en **O(1)** si el `jti` está en la lista negra (comando `EXISTS`).
- Para **"cerrar todas las sesiones de un usuario"** usamos una *flag* de seguridad con marca de tiempo (`security:<userId>`): cualquier token emitido antes de ese instante queda invalidado.
- **Rotación de refresh tokens con detección de robo:** cada refresh token pertenece a una "familia". Si alguien intenta **reutilizar un token ya rotado** (señal de robo), se dispara el kill switch: **se revocan TODAS las sesiones de ese usuario** (no solo la familia). Es decir, ante sospecha de robo somos conservadores y cerramos todo. La familia es la *señal de detección*; el flag por usuario es la *respuesta*.

**b) Rate limiting (limitación de peticiones).** Protege login, registro, subidas, eventos de socket, etc.
- **WebSocket → sí usa Redis**: un **script Lua** implementa una **ventana deslizante** atómica sobre un *sorted set* (con un limiter en memoria de "seguro" por si Redis/Lua no responden).
- **HTTP → hoy va en memoria del proceso** (ver el matiz honesto en §5.2). El código soporta almacenar los contadores en Redis (librería `rate-limit-redis`), pero solo se activa en modo multi-instancia.
- Valores reales: login limitado a **5 intentos / 15 min** en producción (400 en desarrollo); registro a **3 / hora** (50 en desarrollo). Solo se cuentan los intentos **fallidos**.
- Además del límite por IP, hay un **bloqueo de cuenta por email** (contador `INCR`: 5 fallos en 15 min → bloqueo de 15 min) y un **bloqueo de MFA por usuario** equivalentes, ambos en Redis.

**c) Coordinación del juego RFID.** Cuando un alumno escanea una tarjeta:
- Redis guarda el **bloqueo distribuido** de esa tarjeta (`card:<uid>` → `playId`) para que dos partidas no usen la misma tarjeta a la vez (§4.2, "locks distribuidos").
- Un **contador anti-replay** (comparación-y-set atómica vía el Lua `rfidCounterCas.lua`) rechaza escaneos repetidos o reordenados: es parte del esquema HMAC del sensor. Guarda el último contador visto por sensor y solo acepta si el nuevo es estrictamente mayor.
- Se guarda un **snapshot** de la partida (Hash con `HSET`) por si el proceso se reinicia, para poder marcar la partida como abandonada de forma limpia.

### 4.4 Tolerancia a fallos (multicapa)

Esto es un buen punto para la defensa porque demuestra madurez de ingeniería. Si Redis cae, **el sistema degrada, no se cae**:
1. **Reconexión resiliente** con reintentos **indefinidos** y *backoff* (espera creciente hasta un tope de 3 s entre intentos). Antes abandonaba tras 10 intentos, lo que dejaba el backend sin Redis y bloqueaba todos los logins; ahora nunca se rinde.
2. **Circuit breaker** en la capa de servicio: tras **5 fallos** abre el circuito (deja de intentar durante 15 s y luego prueba con cautela). Con el circuito abierto, las lecturas/escrituras básicas degradan en silencio: un `get` devuelve `null`, un `set` devuelve `false`.
3. **Degradación diferenciada por criticidad:**
   - Lo que **tolera** la ausencia de Redis lo hace (**fail-open**): la caché va directa a Mongo; ciertas operaciones del juego (reservar tarjeta, anti-replay) siguen adelante para no romper la partida en curso.
   - Lo que **no la tolera** por seguridad falla de forma **visible** (**fail-closed**): el rate limiter de login/registro rechaza en vez de dejar pasar (ver matiz en §5.2).

---

## 5. Cosas interesantes / decisiones que lucen en la defensa

### 5.1 El invariante `scale=1`: por qué gran parte del estado NO está en Redis

Podrían preguntarte: *"si tienes Redis, ¿por qué el estado de las partidas está en memoria del proceso Node y no en Redis?"*. Respuesta honesta y correcta:
- El **estado vivo de una partida** (ronda actual, puntuación, desafío, temporizadores) vive en `Map`s **en la memoria del proceso** (`activePlays`, `cardUidToPlayId`, `playLocks` en el `GameEngine`, que es un *singleton* instanciado una vez en `server.js`).
- Redis solo guarda lo **complementario del juego**: los bloqueos de tarjetas, un *snapshot* para recuperación y un *lock* de idempotencia del arranque.
- ¿Por qué? Porque el proyecto asume una **única instancia del backend** (`scale=1`, formalizado en `config/scaling.js`). A esa escala, meter todo el estado en Redis no aporta nada y **sí añade coste y latencia**. Además, **los temporizadores no son serializables** (son objetos `Timeout` de Node). Es una decisión **deliberada y documentada**, no una carencia.
- La arquitectura está **preparada** para multi-instancia (hay locks distribuidos, un adaptador de Socket.IO por Redis, *pub/sub*), pero todo eso está **apagado por defecto** (se activa con `SOCKET_ADAPTER_ENABLED=true`) precisamente porque a una sola instancia solo generaría coste sin beneficio.

### 5.2 (Honestidad) El rate limiting HTTP hoy va en memoria, no en Redis

Consecuencia directa del `scale=1`: con una sola instancia, los contadores de rate limit HTTP no necesitan estar en Redis (no hay que sincronizarlos entre servidores), así que usan un **almacén en memoria del propio proceso** — decisión deliberada para ahorrar comandos. El soporte `rate-limit-redis` (contadores en Redis, compartidos entre instancias) **está cableado pero inactivo** hasta que se despliegue en multi-instancia.

Por tanto, matiz honesto sobre el **fail-closed** del login: la configuración marca el rate limiter de login/registro como fail-closed (si su almacén Redis fallara, rechazaría), pero **eso solo tiene efecto cuando el almacén es Redis, es decir en multi-instancia**. En la instancia única actual, las defensas de fuerza bruta **que sí usan Redis siempre** son el **bloqueo de cuenta por email** y el de **MFA**, y esas son **fail-open** (si Redis cae, no bloquean, para no dejar fuera a todos los usuarios legítimos durante una caída). Es un equilibrio consciente entre seguridad y disponibilidad.

### 5.3 Optimización agresiva del número de comandos

El diseño está muy optimizado para minimizar el tráfico a Redis:
- **Scripts Lua** que agrupan operaciones: reservar 20 tarjetas pasa de 20 comandos a **1**; el latido de renovación, de 61 a 1 (§4.2).
- **Caché L1 en memoria** (LRU real) delante de Redis para mecánicas y contextos: muchas lecturas ni siquiera llegan a Redis.
- **Pipelines** para agrupar comandos: la autenticación comprueba lista negra + *flag* de seguridad + caché de usuario en un **único *round-trip*** (y en 0 si la caché L1 local acierta).
- ***Single-flight*** + ***jitter* (±10%)** en los TTL de caché para evitar el *cache stampede* (que muchas peticiones recalculen el mismo dato a la vez, o que muchas claves caduquen en el mismo instante).

> **Origen histórico del ahorro:** estas optimizaciones nacieron cuando el plan era desplegar en cloud con **Upstash** (Redis *serverless* con un *free-tier* de ~10.000 comandos/día). Aunque **la producción real acabó siendo un VPS autoalojado con Redis en contenedor** (donde ya no hay ese límite estricto), las optimizaciones se mantuvieron porque igualmente reducen latencia y carga. El código todavía conserva soporte para `rediss://`/TLS de Upstash: es un **residuo del diseño cloud anterior**, no la infraestructura actual.

### 5.4 Política de memoria `noeviction` (elección poco intuitiva)

Cuando Redis se queda sin memoria, puede **expulsar** claves viejas (`allkeys-lru`) o **rechazar** escrituras (`noeviction`). Elegimos **`noeviction`** a propósito, porque hay datos que **no toleran desaparecer en silencio** (lista negra de tokens, refresh tokens, bloqueos, colas). Preferimos un **fallo visible** (error de memoria en los logs, que investigamos) antes que un **fallo silencioso** (un token revocado que "resucita" porque Redis lo expulsó). Los datos descartables (caché) ya llevan su propio TTL, así que se limpian solos sin necesidad de expulsión. Configurado en el arranque del contenedor (256 MB en dev, 512 MB en prod), no en un `redis.conf`.

### 5.5 Persistencia y telemetría

- **Persistencia AOF** (`appendonly yes`, `appendfsync everysec`): Redis registra cada escritura en un fichero, sincronizado a disco cada segundo. Así, un reinicio del contenedor no pierde el estado (tokens revocados, bloqueos, colas) más allá del último segundo.
- **Telemetría del uso de Redis:** un rastreador cuenta cada comando **por categoría funcional** (`auth`, `blacklist`, `cache-*`, `play`, `card`, `ratelimit`, `lua`…), expuesto en `/api/metrics`. Pensado originalmente para vigilar el presupuesto de comandos del *free-tier*; incluso extrapola el consumo diario y alerta al 80%/95%.

---

## 6. Preguntas típicas y respuesta rápida

- **"¿Por qué Redis y no guardar los tokens revocados en Mongo?"** → Porque es una comprobación que se hace en **cada petición autenticada**: necesita ser O(1) y en memoria. Mongo sería un cuello de botella. Además el TTL automático de Redis limpia sola la lista negra.
- **"¿Qué pasa si Redis se cae?"** → El sistema degrada de forma controlada (reconexión indefinida + circuit breaker). La caché va directa a Mongo; las defensas de fuerza bruta priorizan disponibilidad (fail-open) para no dejar fuera a usuarios legítimos durante la caída.
- **"¿El estado del juego está en Redis?"** → No, está en memoria del proceso bajo el invariante `scale=1`. Redis solo tiene los bloqueos de tarjetas, un snapshot de recuperación y un lock de idempotencia. Fue una decisión deliberada de simplicidad y coste.
- **"¿Cómo evitas que la lista negra crezca sin límite?"** → Cada entrada lleva TTL igual al tiempo que le queda al token; se autodestruye sola.
- **"¿Qué es un script Lua atómico y por qué lo usas?"** → Un mini-programa que Redis ejecuta entero sin que nadie se cuele en medio. Lo uso para operaciones todo-o-nada (reservar/renovar tarjetas, anti-replay, rate limit de socket) y, de paso, para convertir decenas de comandos en uno solo.
- **"¿El rate limiting va por Redis?"** → El de WebSocket sí (Lua sobre ZSET). El HTTP, en la instancia única actual, va en memoria del proceso; el soporte para llevarlo a Redis está listo pero solo se activa en multi-instancia.

---

## 7. ⚠️ Para no exagerar en la defensa (los "por si acaso")

Cuatro afirmaciones donde conviene ser preciso si el tribunal pincha:

1. **El refresh token dura 7 días**, no 30. La clave Redis de 7 días es la que manda de verdad sobre su validez.
2. **El rate limiting HTTP hoy usa memoria del proceso, no Redis** (decisión por `scale=1`). Redis como almacén distribuido de rate limit solo se activa en multi-instancia. Lo que sí usa Redis es el rate limit de **WebSocket** (Lua) y los **bloqueos de cuenta/MFA**.
3. **La detección de robo revoca TODAS las sesiones del usuario** (flag `security:<userId>`), no "solo la familia". La familia es la señal que detecta el robo; la respuesta es cerrar todo.
4. **El snapshot de partida usa `HSET` (reescritura completa), no `HINCRBY`.** El `HINCRBY` atómico es de las métricas de alumno (`student:metrics`, 90 días). Y las colas BullMQ de **exportaciones y notificaciones son andamiaje sin worker**: no las presentes como funcionales.
