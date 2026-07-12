# Redis en el proyecto

> Nota de estudio para la defensa. Todo lo de aquí está verificado contra el código real del backend.

---

## 1. ¿Qué es Redis? (explicación breve)

Redis (**RE**mote **DI**ctionary **S**erver) es una **base de datos en memoria** de tipo clave-valor. La diferencia clave con MongoDB o cualquier BD tradicional es que **guarda los datos en la RAM**, no en disco, por lo que las lecturas y escrituras son extremadamente rápidas (microsegundos en lugar de milisegundos).

Ideas para explicarlo en 30 segundos:
- Es un **almacén clave → valor**, como un diccionario gigante compartido por todo el backend.
- No solo guarda strings: soporta **estructuras de datos** (listas, conjuntos, hashes, conjuntos ordenados/*sorted sets*, contadores...). Esto lo diferencia de un simple caché.
- Cada clave puede tener un **TTL** (*time to live*): se autodestruye pasado un tiempo. Esto es perfecto para cosas temporales (tokens, bloqueos, cachés).
- Puede persistir a disco (nosotros usamos AOF, *append-only file*), pero su fortaleza es que es **efímero y rápido**.
- Muchas operaciones son **atómicas** (un `INCR` o un script Lua se ejecutan sin que nadie se cuele en medio), lo que lo hace ideal para coordinar concurrencia.

**Frase resumen para el tribunal:** *"Redis es nuestra capa de estado rápido y efímero: todo lo que necesita ser veloz, temporal o coordinado entre peticiones (tokens, límites de peticiones, bloqueos, caché) vive en Redis, no en MongoDB."*

---

## 2. ¿Para qué usamos Redis en el proyecto?

Redis es la **columna vertebral de seguridad, rendimiento y coordinación** del backend. Usos reales:

| Área | Qué resuelve Redis |
|---|---|
| **Seguridad — sesiones/JWT** | Lista negra de tokens revocados, refresh tokens, detección de robo de tokens, revocación masiva |
| **Seguridad — fuerza bruta** | Bloqueo de cuentas tras fallos de login, bloqueo de MFA, anti-replay de códigos TOTP |
| **Rate limiting** | Límites de peticiones HTTP y de eventos WebSocket |
| **Juego (RFID)** | Bloqueos distribuidos de tarjetas, *snapshot* de partidas para recuperación, anti-replay del contador RFID |
| **Rendimiento** | Caché de mecánicas, contextos y analytics (patrón *cache-aside*) |
| **Analytics** | *Leaderboards* (rankings) con *sorted sets*, métricas materializadas de alumnos |
| **Colas de trabajo** | BullMQ (retención de datos RGPD, exportaciones, notificaciones, detección de alertas) |

La biblioteca cliente es **`ioredis`** (elegida frente a `node-redis` por su API de *pipelines* más limpia). Toda la conexión se centraliza en un cliente **singleton** en `config/redis.js`.

---

## 3. ¿Cómo lo usamos? (detalle técnico)

### 3.1 Namespaces y estructuras de datos

Cada dato tiene un **prefijo de espacio de nombres** para no colisionar. Formato de clave: `rfid-games:<namespace>:<id>` (el prefijo `rfid-games:` lo añade automáticamente ioredis). Elegimos la **estructura de datos Redis según el uso**, no siempre strings:

| Uso | Estructura | TTL | Por qué esa estructura |
|---|---|---|---|
| Lista negra de JWT | String (`'1'`) | lo que le queda al token | Solo importa si la clave existe → búsqueda O(1) |
| Refresh tokens | **Hash** | 7 días | Objeto con varios campos, actualización parcial |
| Snapshot de partida | **Hash** | 90 s + latido cada 30 s | `HINCRBY` atómico sobre campos |
| Bloqueo de tarjeta RFID | String (`playId`) | 90 s | Marca "esta tarjeta está en uso por esta partida" |
| Rankings | **Sorted Set (ZSET)** | 8 días | Ordena por puntuación automáticamente |
| Métricas de alumno | **Hash** | 90 días | `HINCRBY` para acumular sin leer-modificar-escribir |
| Contador fallos login | String (`INCR`) | ventana 15 min | Incremento atómico |
| Rate limit WebSocket | **ZSET** (ventana deslizante) | ventana | *Sliding window* con marcas de tiempo |

### 3.2 Los tres usos "estrella" que conviene dominar

**a) Seguridad de tokens JWT.** El JWT es *stateless* (auto-verificable sin BD), lo cual es rápido pero tiene un problema: **no se puede "cerrar sesión" de verdad** porque el token sigue siendo válido hasta que caduca. Lo resolvemos con Redis:
- Al hacer logout o revocar, metemos el `jti` (identificador del token) en una **lista negra** con TTL = tiempo que le queda al token. Cuando caduca el token, la entrada se autodestruye (no crece infinitamente).
- Cada petición comprueba en O(1) si el `jti` está en la lista negra.
- Para "cerrar todas las sesiones de un usuario" usamos una *flag* de seguridad con marca de tiempo: cualquier token emitido antes de ese instante queda invalidado.
- **Rotación de refresh tokens con detección de robo**: cada refresh token pertenece a una "familia". Si alguien intenta reutilizar un token ya usado (señal de robo), se revoca **toda la familia**.

**b) Rate limiting (limitación de peticiones).** Protege login, registro, subidas, etc.
- HTTP con la librería `rate-limit-redis`; WebSocket con un **script Lua** que implementa una ventana deslizante atómica sobre un *sorted set*.
- Login limitado a **5 intentos / 15 min** en producción; registro a **3 / hora**.
- Decisión importante de robustez: los rate-limiters de login son **fail-closed** (si Redis cae, *rechazan* en vez de dejar pasar) para no abrir la puerta a fuerza bruta; los límites de disponibilidad son **fail-open** (dejan pasar).

**c) Coordinación del juego RFID.** Cuando un alumno escanea una tarjeta:
- Redis guarda un **bloqueo distribuido** de esa tarjeta (`card:<uid>` → `playId`) para que dos partidas no usen la misma tarjeta a la vez.
- Un **contador anti-replay** (comparación-y-set atómica vía Lua) rechaza escaneos repetidos o reordenados (parte del esquema HMAC del sensor).
- Se guarda un **snapshot** de la partida por si el proceso se reinicia (para poder marcar la partida como abandonada de forma limpia).

### 3.3 Tolerancia a fallos (multicapa)

Esto es un buen punto para la defensa porque demuestra madurez de ingeniería. Si Redis cae, **el sistema degrada, no se cae**:
1. **Reconexión resiliente** con reintentos indefinidos y *backoff*.
2. **Circuit breaker** en la capa de servicio: tras 5 fallos abre el circuito y cada operación degrada en silencio (un `get` devuelve `null`, un `set` devuelve `false`).
3. Los usos que toleran la ausencia de Redis lo hacen (la caché ejecuta la consulta directa a Mongo); los que no la toleran por seguridad (login) fallan de forma visible.

---

## 4. Cosas interesantes / decisiones que lucen en la defensa

**El invariante `scale=1`: por qué gran parte del estado NO está en Redis.**
Podrían preguntarte: *"si tienes Redis, ¿por qué el estado de las partidas está en memoria del proceso Node y no en Redis?"*. Respuesta honesta y correcta:
- El **estado vivo de una partida** (ronda actual, puntuación, desafío, temporizadores) vive en `Map`s **en la memoria del proceso** (`activePlays`, `cardUidToPlayId`, `playLocks` en el `GameEngine`).
- Redis solo guarda lo **complementario**: bloqueos de tarjetas, un snapshot para recuperación y un lock de idempotencia.
- ¿Por qué? Porque el proyecto asume una **única instancia del backend** (`scale=1`, formalizado en `config/scaling.js`). A esa escala, meter todo el estado en Redis no aporta nada y **sí añade coste y latencia**. Los temporizadores además no son serializables. Es una decisión **deliberada y documentada**, no una carencia.
- La arquitectura está *preparada* para multi-instancia (hay locks distribuidos, un adaptador de Socket.IO por Redis, pub/sub), pero todo eso está **apagado por defecto** precisamente porque a una sola instancia solo generaría coste sin beneficio.

**Optimización agresiva del número de comandos.** El diseño está muy optimizado para minimizar el tráfico a Redis:
- **Scripts Lua** que agrupan operaciones: reservar 20 tarjetas pasa de 20 comandos a **1**; el latido de renovación de 61 a 1. Se cargan al arrancar con `SCRIPT LOAD` y se invocan por su hash (`EVALSHA`) para no reenviar el código cada vez.
- **Caché L1 en memoria** (LRU) delante de Redis para mecánicas y contextos: muchas lecturas ni siquiera llegan a Redis.
- **Pipelines** para agrupar comandos y una única ida-y-vuelta en la autenticación (comprueba lista negra + flag de seguridad + caché de usuario en un solo *round-trip*).
- *Single-flight* + *jitter* en los TTL de caché contra el *cache stampede*.

> **Origen histórico del ahorro:** estas optimizaciones nacieron cuando el plan era desplegar en cloud con **Upstash** (Redis serverless con un free-tier de ~10.000 comandos/día). Aunque **la producción real acabó siendo un VPS autoalojado con Redis en contenedor** (donde ya no hay ese límite estricto), las optimizaciones se mantuvieron porque igualmente reducen latencia y carga. Si te preguntan, el código todavía conserva soporte para `rediss://`/TLS de Upstash: es un **residuo del diseño cloud anterior**, no la infraestructura actual.

**Política de memoria `noeviction` (elección poco intuitiva).** Redis, cuando se queda sin memoria, puede expulsar claves viejas (`allkeys-lru`) o rechazar escrituras (`noeviction`). Elegimos **`noeviction`** a propósito: hay datos que **no toleran desaparecer en silencio** (lista negra de tokens, refresh tokens, bloqueos, colas). Preferimos un **fallo visible** (error de memoria en los logs, que investigamos) antes que un **fallo silencioso** (un token revocado que "resucita" porque Redis lo expulsó). Los datos descartables (caché) ya llevan su propio TTL.

**Telemetría del uso de Redis.** Hay un rastreador que cuenta cada comando por categoría funcional, expuesto en `/api/metrics`, pensado originalmente para vigilar el presupuesto de comandos del free-tier.

---

## 5. Preguntas típicas y respuesta rápida

- **"¿Por qué Redis y no guardar los tokens revocados en Mongo?"** → Porque es una comprobación que se hace en **cada petición autenticada**: necesita ser O(1) y en memoria. Mongo sería un cuello de botella. Además el TTL automático de Redis limpia solo la lista negra.
- **"¿Qué pasa si Redis se cae?"** → El sistema degrada de forma controlada (circuit breaker + reconexión). La caché va directa a Mongo; el login falla de forma segura (fail-closed) para no abrir fuerza bruta.
- **"¿El estado del juego está en Redis?"** → No, está en memoria del proceso bajo el invariante `scale=1`. Redis solo tiene bloqueos de tarjetas y un snapshot de recuperación. Fue una decisión deliberada de simplicidad y coste.
- **"¿Cómo evitas que la lista negra crezca sin límite?"** → Cada entrada lleva TTL igual al tiempo que le queda al token; se autodestruye sola.
