Imagina que tu servidor Node.js tiene memoria (RAM) donde guarda variables (como tu mapa `activePlays`). Es rapidísimo, pero tiene dos problemas fatales:
1. **Es volátil:** Si reinicias el servidor (o crashea), todo se borra. Adiós partidas.
2. **Es egoísta:** Si en el futuro escalas y pones 3 servidores, el Servidor A no puede leer la memoria del Servidor B.

**Redis** es una base de datos que vive en la RAM (memoria), pero funciona como un servicio externo.
- **Velocidad:** Es casi tan rápido como una variable de JS (hablamos de microsegundos).
- **Persistencia:** Puede configurarse para guardar datos en disco cada cierto tiempo, así que si reinicias, no pierdes todo.
- **Compartido:** Múltiples instancias de tu servidor pueden leer los mismos datos.

# Estructuras de Datos Clave para tu Tarea
Redis no es solo "Clave-Valor". Para esta tarea usarás:
1. **Strings (Cadenas):** Lo básico. `SET clave valor`.
    - _Uso:_ Guardar un token o un objeto JSON serializado.
2. **TTL (Time To Live - Expiración):** La "killer feature". Puedes decirle a Redis: _"Guarda esto, pero bórralo automáticamente en 7 días"_.
    - _Uso:_ Refresh tokens y Blacklists. Te ahorra crear cron jobs para limpiar basura.
3. **Hashes (Mapas):** Como un objeto JS `{ campo: valor }` dentro de una clave.
    - _Uso:_ Guardar el estado de una partida (`score`, `currentRound`, `playerId`) y modificar solo un campo sin reescribir todo el objeto.

---

# Parte 2: El Arte de la Rotación de Tokens (JWT)
Esta es la parte de seguridad. Tienes dos tipos de tokens:
1. **Access Token (AT):**
    - Vida corta (ej. 15 min).
    - No se guarda en BD (stateless).
    - Sirve para acceder a los recursos (`GET /api/game`).
2. **Refresh Token (RT):**
    - Vida larga (ej. 7 días).
    - **Se guarda en Redis (stateful).**
    - Sirve _únicamente_ para pedir un nuevo Access Token cuando el anterior caduca.

## ¿Qué es la Rotación y por qué la necesitas?
Si un hacker roba un Refresh Token que dura 7 días, tiene acceso a tu cuenta por una semana. La **Rotación** mitiga esto.
**El flujo de Rotación (El baile de seguridad):**
1. **Login:** Usuario entra. Servidor genera `AT_1` y `RT_1`. Guarda `RT_1` en Redis.
2. **Uso Normal:** Usuario usa `AT_1` hasta que expira.
3. **Renovación (Refresh):** Cliente envía `RT_1` al servidor pidiendo acceso.
4. **Rotación (La Magia):**
    - Servidor verifica si `RT_1` es válido y existe en Redis.
    - **¡Cambio!** El servidor invalida (borra) `RT_1` y genera un nuevo par: `AT_2` y `RT_2`.
    - Guarda `RT_2` en Redis.
    - Devuelve los nuevos al cliente.

**¿Por qué es seguro? (Detección de Reuso)** Si el hacker robó el `RT_1` e intenta usarlo _después_ de que el usuario legítimo ya hizo la rotación (y ahora tiene `RT_2`), el servidor verá que alguien está intentando usar un token viejo (`RT_1`) que ya no existe en Redis (o que fue marcado como usado).
- **Acción de seguridad:** El servidor asume robo y **bloquea al usuario** (borra todos sus RTs de Redis), obligando a iniciar sesión de nuevo con contraseña.

---

# Parte 3: Estrategia de Implementación para T-005
Vamos a desglosar tus sub-tareas con la lógica de Redis.

## 1. Configuración (`ioredis`)
Usa `ioredis` en lugar de `redis` (la librería oficial antigua) porque soporta Promesas nativamente y es más robusta.
- _Tip:_ Crea un Singleton. Una sola conexión para toda la app.

## 2. Migrar Blacklist (Logout)
Cuando un usuario hace Logout, su Access Token sigue siendo válido matemáticamente hasta que expire. Debemos "prohibirlo".
- **Lógica:** Al hacer logout, tomas el `jti` (ID único del JWT) y el tiempo que le queda de vida.
- **En Redis:** `SET blacklist:token_uid "true" EX tiempo_restante`.
- **Middleware:** En cada petición, verificas: `¿Existe blacklist:token_uid en Redis?` Si sí -> 401 Unauthorized.

## 3. Implementar Refresh Tokens en Redis
Aquí es donde la estructura de datos importa.
- **Clave:** Recomiendo usar el ID del usuario para facilitar borrar todas sus sesiones si es necesario.
    - Opción A (Simple): `refresh_token:userId` -> `valor_del_token`. (Permite solo 1 sesión por usuario).
    - Opción B (Multidispositivo): Un **Set** o múltiples claves `refresh_token:userId:deviceId`.
- **Valor:** El token mismo (o un hash del token).
- **TTL:** 7 días (`60 * 60 * 24 * 7`).

## 4. Migrar `activePlays` (GameEngine)
Actualmente tienes `this.activePlays = new Map()`. Vamos a moverlo a Redis.
**El Desafío:** Redis guarda strings o binarios, no objetos JS vivos. **La Solución:** Serialización.
- **Al iniciar partida (`startPlay`):**
    - Creas el objeto del estado inicial.
    - Lo conviertes a string: `JSON.stringify(gameState)`.
    - Lo guardas en Redis: `SET game:playId "string_json"`.
- **Al recibir evento (RFID scan):**
    - Recuperas: `GET game:playId`.
    - Parseas: `JSON.parse(string)`.
    - Modificas el estado (sumas puntos).
    - Guardas de nuevo: `SET game:playId JSON.stringify(nuevoEstado)`.

**Optimización Pro (Hashes):** Si el objeto es muy grande y solo quieres cambiar el `score`:
- Usa `HSET game:playId score 100`.
- Usa `HINCRBY game:playId score 10` (Redis suma atómicamente, ideal para evitar condiciones de carrera si llegan dos peticiones a la vez).

_Recomendación para tu TFG:_ Empieza con `JSON.stringify/parse` (Strings). Es más fácil de implementar ahora. Si ves problemas de rendimiento, pasas a Hashes.

---

# Workflow
1. **Instala Redis Localmente:** No intentes programar sin tener Redis corriendo en tu máquina (usa Docker es lo más fácil: `docker run -p 6379:6379 -d redis`).
2. **Hello World Redis:** Crea un script pequeño aparte (`test-redis.js`). Conéctate, guarda un valor con TTL de 5 segundos, espera 6 segundos e intenta leerlo. Si te devuelve `null`, has entendido el TTL.
3. **El Servicio:** Crea `redisService.js`.
    - Métodos clave: `set(key, value, ttl)`, `get(key)`, `del(key)`. Encapsula `ioredis` aquí.
4. **Auth primero:** Implementa la rotación.
    - Login -> Guarda en Redis.
    - Endpoint `/refresh-token` -> Lee de Redis, valida, borra el viejo, guarda el nuevo.
5. **GameEngine al final:** Es lo más complejo.
    - Sustituye `this.activePlays.set(...)` por `await redisService.set(...)`.
    - Recuerda que ahora todas tus funciones en GameEngine serán `async` porque Redis es asíncrono (Red -> Espera).

## Consejos de Profesional (Best Practices)
- **Nombres de Claves (Namespacing):** Usa dos puntos para organizar.
    - Mal: `user123`, `partida55`.
    - Bien: `auth:refresh:user123`, `game:play:55`, `blacklist:token:xyz`.
- **Manejo de Errores:** ¿Qué pasa si Redis se cae? Tu `redisService` debería tener un `try/catch` y decidir si el juego se detiene o si (en un caso extremo) usas memoria local como fallback (aunque esto último es complejo, mejor solo lanza error 500).
- **Variables de Entorno:**
    - `REDIS_HOST=localhost`
    - `REDIS_PORT=6379`
    - `REDIS_PASSWORD=` (En local suele ser vacío, en producción no).
    - `JWT_REFRESH_EXPIRATION=604800` (7 días en segundos).

---

# Referencias
## 1. Redis: Fundamentos y Estructura de Datos
Para justificar por qué usas Redis (velocidad, persistencia, tipos de datos), estas son las fuentes obligatorias:
- **Redis Documentation (Official):** Es la fuente primaria. Para tu TFG, te interesan especialmente las secciones de _Data types_ y _Persistence_.
    - **Referencia:** [Redis.io Documentation](https://redis.io/docs/latest/)
- **Redis University:** Ofrece cursos gratuitos muy técnicos. El curso "Redis for JavaScript Developers" es la referencia ideal para tu stack.
    - **Referencia:** [Redis University - RU102JS](https://university.redis.com/courses/ru102js/)
- **ioredis (GitHub & Readme):** Al ser la librería que vas a usar, su documentación es la referencia técnica para la implementación del servicio en Node.js.
    - **Referencia:** [ioredis Documentation](https://github.com/redis/ioredis)

---

## 2. JWT y Seguridad (Token Rotation)
Para la parte de seguridad y rotación de tokens, necesitas citar estándares y líderes en identidad digital:
- **RFC 7519 (JSON Web Token):** Es el estándar oficial de la IETF. Citar un RFC en un TFG de ingeniería es señal de rigor académico. Define qué es un JWT y su estructura.
    - **Referencia:** [IETF - RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
- **Auth0 - Refresh Token Rotation:** Auth0 es el líder mundial en autenticación. Su artículo sobre rotación de tokens explica perfectamente el problema de la interceptación y cómo la rotación lo soluciona. Es la mejor fuente para explicar el "por qué" de esta tarea.
    - **Referencia:** [Auth0: Refresh Token Rotation](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation)
- **OWASP - JSON Web Token Cheat Sheet:** OWASP es la autoridad máxima en seguridad web. Su "guía de supervivencia" para JWT es vital para justificar las medidas de seguridad que implementes (como la blacklist en Redis).
    - **Referencia:** [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html) _(Nota: Aunque diga Java, los principios de seguridad son universales para cualquier lenguaje)_.

---

## 3. Arquitectura y Patrones de Diseño
Para explicar cómo Redis ayuda a gestionar el estado de las partidas y las sesiones:
- **DigitalOcean Community:** Tienen tutoriales de una calidad técnica excepcional, revisados por pares. Son ideales para ver ejemplos de implementación de "Node.js + Redis + JWT".
    - **Referencia:** [DigitalOcean: How to use Redis with Node.js](https://www.google.com/search?q=https://www.digitalocean.com/community/tutorials/how-to-use-redis-with-node-js)
- **MDN Web Docs (Mozilla):** Para conceptos generales sobre almacenamiento de sesiones y seguridad en el lado del cliente (Cookies vs LocalStorage).
    - **Referencia:** [MDN - Web Security](https://developer.mozilla.org/en-US/docs/Web/Security)

---

# Tips para la documentación del TFG:
1. **Cita el estándar (RFC):** En el capítulo de "Fundamentos Tecnológicos", cuando hables de JWT, pon una nota al pie o referencia al RFC 7519.
2. **Justifica la "Rotación":** Cuando escribas sobre la seguridad de tu app, usa la fuente de **Auth0** para explicar que la rotación de tokens no es un capricho, sino una técnica para mitigar el robo de tokens en aplicaciones SPA (Single Page Applications).
3. **Usa diagramas de secuencia:** Redis es perfecto para explicarlo con diagramas de flujo de datos. Muestra cómo el dato viaja del `GameEngine` a Redis y sobrevive a un reinicio.