# Patrones de diseño

> Nota de estudio para la defensa. Verificado contra el código real (backend Node/Express y frontend React). Incluye solo los patrones **más importantes** y realmente implementados; al final de cada bloque hay un resumen compacto del resto.

Un patrón de diseño es una **solución reutilizable y probada a un problema recurrente** de diseño de software. No es código copiable, sino una plantilla de organización. Los clásicos (GoF, *Gang of Four*) se agrupan en tres familias: **creacionales** (cómo se crean los objetos), **estructurales** (cómo se componen) y **de comportamiento** (cómo interactúan y reparten responsabilidades).

En este proyecto conviene distinguir dos mundos:
- **Backend** → patrones GoF clásicos + patrones arquitectónicos (Repository, DTO, Circuit Breaker...).
- **Frontend** → patrones idiomáticos de React, que son variantes modernas de patrones clásicos (Context = Inyección de Dependencias, custom hooks = extracción de lógica, etc.).

---

# PARTE A — BACKEND

## A.1 Strategy (Estrategia) — de comportamiento ⭐

**1. Qué es (general).** Define una familia de algoritmos intercambiables bajo una **interfaz común** y permite elegir cuál usar en tiempo de ejecución, sin llenar el código de `if/switch`. Cumple el principio Abierto/Cerrado: añadir un algoritmo nuevo no obliga a tocar el existente.

**2. Por qué en nuestro proyecto.** El juego tiene **varias mecánicas** (Asociación, Secuencia, Memoria) con reglas distintas para elegir el desafío de cada ronda y para puntuar. Sin Strategy, el motor de juego sería un `switch(mecánica)` gigante e imposible de mantener. Con Strategy, **el motor no conoce las reglas de ninguna mecánica**: delega. Ventaja principal: **añadir una mecánica nueva no toca el core**, solo se crea una subclase y se registra.

**3. Cómo y dónde.** Contrato común en `strategies/mechanics/BaseMechanicStrategy.js` (método abstracto `selectChallenge()`, hooks con valor por defecto como `recordScanResult()`). Estrategias concretas: `AssociationStrategy`, `SequenceStrategy`, `MemoryStrategy` y `FallbackStrategy` (para mecánicas sin lógica dedicada). El `GameEngine` obtiene la estrategia activa (`getMechanicStrategy(...)`) y le pide el desafío. Detalle elegante: las estrategias son **sin estado** (*stateless*); todo el estado mutable de la partida se guarda aparte (`playState.strategyState`), así se comparte una única instancia por mecánica.
> Aviso honesto: la doc menciona una carpeta `gameMechanics/`, pero **está vacía**. La implementación real vive en `strategies/mechanics/`. No cites `gameMechanics/` en la defensa.

---

## A.2 State (Estado) — de comportamiento ⭐

**1. Qué es (general).** Permite que un objeto **cambie su comportamiento según su estado interno**, encapsulando cada modo en su propia clase. El objeto delega en el "estado actual" en lugar de tener condicionales por modo repartidos.

**2. Por qué en nuestro proyecto.** El lector RFID funciona en **modos distintos** (inactivo, en partida, asignando tarjetas) y en cada uno las **reglas de validación de una lectura cambian**: en partida se permiten lecturas, en asignación hay que validar una sala concreta, en inactivo no se permite nada. En vez de `if (modo === ...)` esparcidos por el handler de sockets, cada modo es una clase que sabe qué permite. Ventaja: la lógica de cada modo está **aislada y es fácil de razonar**.

**3. Cómo y dónde.** Contrato en `states/rfid/BaseRfidState.js` (`allowsReads()` → `false` por defecto, `validateRoom()` → `true` por defecto). Estados concretos: `IdleState`, `GameplayState` (sobrescribe `allowsReads()` → `true`), `CardAssignmentState` (sobrescribe ambos para exigir la sala de asignación). El handler de sockets pide el estado según el modo y pregunta `state.allowsReads()` / `state.validateRoom(...)` para autorizar cada lectura (`realtime/socketHandlers.js`). Los estados también son *stateless*: el modo actual (la fuente de verdad) vive en el store de tiempo real.

---

## A.3 Command (Comando) — de comportamiento ⭐

**1. Qué es (general).** Encapsula una acción/petición como un **objeto con una interfaz uniforme** (`execute()`), desacoplando quién invoca de quién ejecuta. Permite registrar, validar, auditar y tratar todas las acciones de forma homogénea.

**2. Por qué en nuestro proyecto.** Cada evento sensible de WebSocket del juego (`join_play`, `start_play`, `next_round`, `rfid_scan_from_client`...) es una acción. Sin Command, el servidor tendría un `switch` enorme por tipo de evento, con la validación y el manejo de errores duplicados en cada rama. Con Command, **todos los eventos comparten el mismo flujo**: buscar comando → validar payload → re-autenticar → ejecutar → capturar errores. Ventaja: **validación y seguridad centralizadas**, y añadir un evento nuevo es crear una clase.

**3. Cómo y dónde.** Contrato en `commands/socket/BaseSocketCommand.js` (`execute()` abstracto + `schema` Zod opcional). 13 comandos concretos en `commands/socket/` (`JoinPlayCommand`, `RfidScanFromClientCommand`, etc.). El despachador central (`executeSocketCommand` en `socketHandlers.js`) resuelve el comando por nombre de evento, aplica la validación Zod si el comando declara esquema, y lo ejecuta **inyectándole el contexto** (`socket`, `gameEngine`, `rfidService`, `helpers`). El registro es masivo: `getCommandNames().forEach(...)`.

---

## A.4 Repository (Repositorio) — arquitectónico (acceso a datos)

**1. Qué es (general).** Aísla la lógica de persistencia tras una interfaz orientada a la colección, de modo que el resto del código **no depende directamente del ORM/ODM** (aquí Mongoose). La lógica de negocio pide "dame el usuario X" sin saber cómo se consulta.

**2. Por qué en nuestro proyecto.** Tenemos **dos consumidores de datos** (la API HTTP y la capa de tiempo real WebSocket) que deben acceder a los mismos datos con las mismas reglas (`lean`, `populate`, `select`, sesiones de transacción). Centralizar eso evita duplicación y "*drift*" entre ambos caminos. Ventaja: **un único punto** donde están las opciones de consulta y la política de acceso.

**3. Cómo y dónde.** `repositories/baseRepository.js` reúne los helpers compartidos (`applyQueryOptions`, `updateById`, `deleteMany`, `bulkWrite`...). 10 repositorios especializados (`userRepository`, `gamePlayRepository`, `gameSessionRepository`...) que le pasan su `Model` concreto. Nota: no es una clase base heredada, sino helpers a los que cada repo enchufa su modelo (`baseRepo.updateById(User, ...)`), lo que evita duplicar la configuración de consultas.

---

## A.5 DTO (Data Transfer Object) — arquitectónico (contrato de datos)

**1. Qué es (general).** Un objeto de transporte que transforma la **entidad interna** en una forma **estable y segura** para enviar al cliente, evitando exponer campos internos o sensibles.

**2. Por qué en nuestro proyecto.** Nunca se debe devolver un documento Mongoose crudo: expondría campos internos (`__v`), la contraseña *hasheada*, o **datos personales de menores** (email, etc.). Además, el proyecto maneja datos de menores bajo RGPD, así que el control de la superficie de respuesta es **una obligación legal**, no una preferencia. Ventaja: contrato de API **versionado** (`...DTOV1`) y protección de datos por diseño (Art. 25 RGPD).

**3. Cómo y dónde.** `utils/dtos.js` con un DTO por entidad: `toUserDTOV1` (excluye `password`/`__v`), `toStudentDTOV1`, `toGamePlayDTOV1`, `toGameSessionDTOV1`... Normaliza `_id` → `id`, aplana subdocumentos, oculta el email salvo para roles con login, y **pseudonimiza** los datos en analytics (`toStudentAnalyticsDTOV1`). Es **obligatorio** para toda respuesta de dominio (regla del proyecto).

---

## A.6 Circuit Breaker (Cortacircuitos) — de resiliencia ⭐

**1. Qué es (general).** Un mecanismo que **corta temporalmente las llamadas a una dependencia externa que falla repetidamente**, para no propagar el fallo ni saturar con reintentos. Tiene tres estados: **cerrado** (todo pasa), **abierto** (todo se rechaza al instante), **semiabierto** (deja pasar alguna prueba para ver si ya se recuperó).

**2. Por qué en nuestro proyecto.** Redis es una dependencia crítica (tokens, rate limiting, caché). Si Redis se degrada, **sin cortacircuitos cada petición esperaría el timeout completo** y el sistema se arrastraría o caería en cascada. Con el breaker, tras unos pocos fallos Redis se marca como "caído" y las operaciones **degradan al instante** (la caché va directa a Mongo, etc.), manteniendo el servicio vivo. Ventaja: **degradación elegante** en lugar de caída total. *(Es un patrón menos común de ver en un TFG → buen punto para destacar madurez de ingeniería.)*

**3. Cómo y dónde.** Clase genérica en `utils/circuitBreaker.js` (`canRequest()`, `recordSuccess()`, `recordFailure()`, transición de estados con umbrales configurables). Se instancia como `redisBreaker` en `services/redisService.js`: **cada operación Redis consulta el breaker antes de ejecutar** y registra el resultado. Cuando abre, `cacheHelper` ejecuta la consulta directa a la BD. Combina con la reconexión resiliente de ioredis (ver nota de Redis).

---

### Otros patrones de backend (resumen compacto)

| Patrón | Categoría | Dónde / para qué |
|---|---|---|
| **Singleton** | Creacional | `rfidService`, `redisService`, `gameEngine`, `io` (Socket.IO), `authEventBus`. Recursos con conexión/estado que deben ser únicos. Se logran vía caché de módulos CommonJS. |
| **Facade** | Estructural | `realtime/index.js` expone solo `registerSocketHandlers/...` ocultando ~2000 líneas; `responseHelper` (`sendSuccess`, `sendPaginated`) oculta el formato `{success, data}` a los controllers. |
| **Decorator / Wrapper** | Estructural | `asyncHandler(fn)` (try/catch a controllers), `socketRateLimiter.wrap(...)` (payload+dedupe+rate-limit alrededor de cada handler), `withTransaction(cb)` (ciclo sesión/commit/abort/retry de Mongo). Añaden comportamiento transversal sin tocar la lógica. |
| **Observer / Pub-Sub** | Comportamiento | `rfidService` extiende `EventEmitter` y emite `rfid_event`; `authEventBus` invalida cachés al revocar tokens; Pub/Sub Redis (`rfidModeSubscriber`, `cacheInvalidateSubscriber`) para propagar entre instancias. |
| **Cache-Aside** | Arquitectónico | `cacheHelper.cacheGet()`: mira caché → miss → lee BD → guarda. Con L1 en memoria, *single-flight* y *jitter* de TTL. |
| **Factory (registry)** | Creacional | `getMechanicStrategy`, `getRfidState`, `getSocketCommand`: mapa tipo→instancia con normalización + fallback. (Más *registry* que Factory Method GoF puro; nómbralo con precisión.) |
| **Middleware / Chain of Responsibility** | Comportamiento | Cadena ordenada de `app.use(...)` en `server.js` (helmet → CORS → rate-limit → CSRF → auth → rutas → errorHandler). El orden es crítico. |
| **Validator (Zod)** | Arquitectónico | Middleware `validation.js` + 19 validadores en `validators/`. Valida y coacciona la entrada en la frontera. |

---

# PARTE B — FRONTEND (React)

## B.1 Provider Pattern / Context API — Inyección de Dependencias ⭐

**1. Qué es (general).** En React, el patrón *Provider* usa la Context API para **inyectar estado o servicios a todo un subárbol de componentes** sin pasarlos manualmente por props en cada nivel (evita el *prop drilling*). Es la variante React de la **Inyección de Dependencias**: un `Provider` publica un valor y cualquier descendiente lo consume con un hook.

**2. Por qué en nuestro proyecto.** Hay estado **global transversal** que muchísimos componentes necesitan: quién es el usuario y su rol (auth), el tema claro/oscuro, el modo del sensor RFID, las notificaciones, los atajos de teclado. Pasar eso por props sería inmanejable. Ventaja: **una única fuente de verdad** por dominio, accesible desde cualquier parte.

**3. Cómo y dónde.** 6 contexts en `context/`: **AuthContext** (usuario, `login/logout`, `isTeacher/isSuperAdmin`), **ThemeContext**, **AtmosphereContext**, **RfidModeContext**, **NotificationsContext**, **ShortcutRegistryContext**. Se componen anidados en la raíz (`App.jsx`) en un orden deliberado (Theme fuera del Router; Auth dentro). Cada hook consumidor (`useAuth`, `useTheme`...) **lanza un error si se usa fuera de su Provider** (salvo `useAtmosphere`, que degrada a un *no-op* para que el Login funcione fuera). El `value` va **memoizado** (`useMemo`) para evitar re-renders en cascada.

---

## B.2 Custom Hooks (extracción de lógica reutilizable) ⭐

**1. Qué es (general).** Un *custom hook* es una función `useXxx` que **encapsula lógica con estado y efectos** para reutilizarla entre componentes, separando la lógica de la presentación. Es el mecanismo idiomático de React para el principio de responsabilidad única.

**2. Por qué en nuestro proyecto.** Lógica compleja como "gestionar toda la conexión de socket del juego" o "saber si el lector RFID está listo" no debe vivir dentro de un componente de UI: sería imposible de testear y de reutilizar. Ventaja: la lógica queda **aislada, testeable y reutilizable**, y los componentes quedan limpios.

**3. Cómo y dónde.** ~37 hooks en `hooks/`. Los importantes: **`useGameSocket`** (orquesta toda la conexión Socket.IO del juego: listeners, reconexión, mapeo de códigos de error a mensajes), **`useWebSerialDeviceState`** (fuente única de "¿lector listo?", suscrito al singleton Web Serial), **`useGameSessionState`** (el `useReducer` del juego), **`useNotifications`**, **`useFetch`** (fetch genérico con `AbortController`). Detalle elegante: un hook puede **promoverse a Context** sin cambiar su API — es lo que hace `NotificationsContext` envolviendo `useNotifications()`.

---

## B.3 Singleton — servicios de comunicación ⭐

**1. Qué es (general).** Garantiza que exista **una única instancia** de un recurso global compartido por toda la aplicación.

**2. Por qué en nuestro proyecto.** Solo puede haber **una** conexión WebSocket y **un** puerto serie abiertos por usuario. Si cada componente creara su propia instancia, habría conexiones duplicadas y conflictos de lectura del sensor. Además, el estado del sensor (estado del dispositivo, cola de escaneos offline) debe **sobrevivir a la navegación** entre páginas de la SPA. Ventaja: **una sola conexión/puerto** y estado persistente entre vistas.

**3. Cómo y dónde.** Instancias únicas exportadas: **`socketService`** (`services/socket.js`), **`webSerialService`** (`services/webSerialService.js`), **`soundEffectsService`**. Y singletons de módulo: el cliente **axios** único (`services/api.js`) y el `Map` de peticiones en vuelo (`services/inFlight.js`). Como el singleton persiste entre navegaciones, los hooks re-leen su valor actual al montar (por eso `useWebSerialDeviceState` inicializa desde el estado vivo del singleton, no desde cero).

---

## B.4 Observer / Pub-Sub — bus de eventos ⭐

**1. Qué es (general).** Desacopla emisores y receptores mediante **suscripción a eventos**: el emisor publica un evento sin conocer quién lo escucha. Es el patrón GoF *Observer*.

**2. Por qué en nuestro proyecto.** Hay módulos que deben reaccionar a cosas que ocurren en otros módulos **sin acoplarse** a ellos. Ejemplo real: cuando el socket **se reconecta**, el servicio Web Serial debe **vaciar su cola de escaneos pendientes** — pero el socket no debería conocer al Web Serial ni viceversa. Ventaja: **desacoplamiento** entre subsistemas que igualmente deben coordinarse.

**3. Cómo y dónde.** Aparece en tres capas: (a) **emisores propios** — `socketService` y `webSerialService` tienen su propio `on/off/emit`; (b) **bus global vía `window` CustomEvent** — `socketService` publica `socket_reconnected`/`game_socket_reconnected` en `window`, y `useGameSocket` los escucha para lanzar `webSerialService.flushPendingScans()`; eventos de auth y MFA viajan igual; (c) **registro observable de atajos** — las fuentes se registran/desregistran en `ShortcutRegistryContext` y un único listener global resuelve cualquier atajo.

---

### Otros patrones de frontend (resumen compacto)

| Patrón | Dónde / para qué |
|---|---|
| **Facade** | `services/api.js` es una fachada sobre **axios** (interceptores, refresh de token, retry, 429, MFA; expone `authAPI`, `decksAPI`...). `services/socket.js` es una fachada sobre **socket.io-client** (oculta dos namespaces, reconexión, heartbeat). El consumidor nunca ve axios ni socket.io directamente. |
| **HOC / Wrapper (guards)** | `ProtectedRoute` (exige sesión), `RequireRole` (guard por rol), `GuestRoute` (bloquea Login si ya hay sesión), `SuspenseWrapper` (ErrorBoundary + Suspense). Se componen: `<ProtectedRoute><RequireRole roles="super_admin"><AppLayout/></RequireRole></ProtectedRoute>`. |
| **Strategy (por mecánica)** | El render del juego elige el panel según la mecánica (`memory`/`sequence`/`association`), con paneles *lazy* y un mapa de *prefetchers* indexado por mecánica (`GameSession.jsx`). |
| **State Machine** | El estado del sensor en `webSerialService`: `desconocido → inicializando → listo → obsoleto/error`, con *watchdogs* que fuerzan transiciones. También el `gameState` del reducer: `esperando → jugando → pausado → terminado`. |
| **Context + Reducer** | `AuthContext` (con `authReducer`) y `useGameSessionState` (`gameReducer` con acciones `NEW_ROUND`, `PAUSE`, `FINISH`...). Alternativa ligera a Redux. |
| **Error Boundary** | `components/common/ErrorBoundary.jsx` (componente de clase que captura errores de render y reporta a Sentry). Envuelve cada página *lazy*. |
| **Adapter / DTO** | `lib/entityId.js` (`getId/sameId`) normaliza la ambigüedad `id`/`_id` del backend; `extractData` desempaqueta el envelope `{success, data}`. |
| **Lazy Loading / Code Splitting** | Casi todas las rutas con `lazy()` + `Suspense`; paneles de juego con *prefetch* en *idle*; `LazyMotion` para tree-shaking de Framer Motion. |

> Avisos honestos para la defensa (la doc del frontend menciona cosas que **no** están implementadas): **Compound Components** aparece como "ejemplo futuro" — **no existe** en el código (no hay `Form.Field`, `Card.Header`...). Y el reducer del juego vive en un **custom hook** (`useGameSessionState`), **no** en un `GameContext.jsx` (ese fichero no existe). No los cites como hechos.

---

## Preguntas típicas y respuesta rápida

- **"¿Qué patrón de diseño destacarías del proyecto?"** → El trío **Strategy + State + Command** en el backend: Strategy para las mecánicas de juego, State para los modos del lector RFID, y Command para los eventos de WebSocket. Son los tres patrones de comportamiento que estructuran el núcleo del sistema y permiten extenderlo sin tocar el core.
- **"¿Cómo añadirías una mecánica de juego nueva?"** → Creando una subclase de `BaseMechanicStrategy` y registrándola en el mapa de estrategias. El motor de juego no se toca (principio Abierto/Cerrado).
- **"¿Usas patrones también en el frontend?"** → Sí, los idiomáticos de React: Context/Provider como inyección de dependencias, custom hooks para extraer lógica, servicios singleton para socket y sensor, y un bus de eventos (Observer) para coordinar subsistemas desacoplados.
- **"¿Por qué DTOs si ya tienes los modelos?"** → Para no exponer campos internos ni datos personales de menores (RGPD), y para tener un contrato de API estable y versionado. Devolver un documento Mongoose crudo sería un fallo de seguridad.
- **"¿Qué es el Circuit Breaker y por qué lo usas?"** → Corta las llamadas a Redis cuando falla repetidamente, para que el sistema degrade al instante (caché → BD directa) en vez de arrastrarse esperando timeouts. Es resiliencia frente a fallos de dependencias externas.
