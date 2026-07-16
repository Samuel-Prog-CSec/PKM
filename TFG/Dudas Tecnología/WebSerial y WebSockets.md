# Web Serial API + WebSockets

> Nota de estudio para la defensa. Verificado contra el código real del frontend, el backend y el firmware.

Estas dos tecnologías forman **la cadena completa del RFID**: el sensor físico → el navegador (Web Serial) → el servidor (WebSocket) → la lógica de juego. Conviene entenderlas juntas porque son los dos eslabones del mismo puente.

---

## 1. ¿Qué son? (breve)

### Web Serial API
Es una **API del navegador** (estándar web, disponible en Chromium: Chrome/Edge) que permite a una página web **comunicarse con un dispositivo conectado por puerto serie (USB)**. Históricamente, leer un puerto serie era algo exclusivo de aplicaciones de escritorio; la Web Serial API lo lleva al navegador de forma segura.

Puntos clave:
- Requiere un **gesto explícito del usuario** (un clic) para pedir acceso a un puerto — no se puede espiar el USB en segundo plano.
- Requiere **HTTPS** (o localhost).
- Solo en **navegadores Chromium**.

### WebSockets (Socket.IO)
Un **WebSocket** es un canal de comunicación **bidireccional y persistente** entre navegador y servidor sobre una única conexión TCP. A diferencia de HTTP (petición → respuesta, el cliente siempre inicia), el WebSocket permite que **el servidor empuje datos al cliente en cualquier momento** (*push*). Es lo que hace posible el "tiempo real".

Usamos **Socket.IO**, una biblioteca sobre WebSockets que añade reconexión automática, *rooms* (salas), *namespaces*, *fallback* a *long-polling* si el WebSocket falla, y ACKs.

**Frase resumen:** *"La Web Serial API lleva la lectura del sensor USB al navegador del profesor; el WebSocket transmite esos escaneos al servidor en tiempo real y devuelve el estado del juego al instante."*

---

## 2. ¿Para qué y dónde los usamos?

### El problema que resuelven juntos
El sensor RFID (ESP8266 + RC522) se conecta por **USB al portátil del profesor**. La arquitectura **original** leía el puerto serie **en el servidor**, pero eso tenía un defecto fatal: **en un servidor cloud no hay puerto USB**. Esto bloqueaba cualquier despliegue en la nube y limitaba el escalado por aula.

**Solución:** mover la lectura del sensor **al navegador del profesor** (Web Serial) y enviar los escaneos al servidor por **WebSocket**. Así el backend deja de depender del hardware y se convierte en un **procesador de eventos en tiempo real**. El sensor se conecta solo al PC del profesor, nunca al servidor.

### Flujo completo (la cadena RFID)
```
Tarjeta RFID → RC522 → ESP8266 (firma HMAC) → USB serie
   → Navegador (Web Serial API lee y parsea)
   → Socket.IO emite 'rfid_scan_from_client'
   → Backend valida (Zod + HMAC + anti-replay + permisos)
   → GameEngine procesa el escaneo
   → Backend emite el resultado al navegador por WebSocket
   → La UI del alumno reacciona en tiempo real
```

### Dónde vive cada cosa
- **Web Serial**: servicio singleton en `frontend/src/services/webSerialService.js`. El botón "Conectar" está en `RFIDConnector.jsx`.
- **WebSocket cliente**: `frontend/src/services/socket.js` + el hook `useGameSocket.js`.
- **WebSocket servidor**: `backend/src/server.js` (inicialización), `backend/src/realtime/socketHandlers.js` (handlers), `backend/src/commands/socket/` (comandos).

---

## 3. ¿Cómo los usamos? (decisiones importantes)

### 3.1 Web Serial — cómo leemos el sensor

- **El profesor elige el sensor una sola vez.** `connect()` primero intenta **reutilizar un puerto ya autorizado** (`navigator.serial.getPorts()`) y solo abre el selector nativo (`requestPort()`) si no hay ninguno. Así no se pide el sensor en cada mazo/partida.
- **Formato del mensaje del ESP8266**: JSON, **una línea por evento** terminada en `\n`, a 115200 baudios. El firmware emite eventos `init`, `card_detected`, `card_removed`, `status` (latido cada 10 s) y `error`.
- **Parseo robusto**: se lee el stream con `TextDecoderStream` (tolerante a bytes corruptos), se acumula en un buffer y se parte por líneas; se descartan líneas vacías o mal formadas; hay protección **anti-overflow** (si el buffer supera 4 KB se vacía).

### 3.2 La firma HMAC (decisión de seguridad clave)

Este es probablemente **el punto más fuerte** de esta parte para la defensa. El problema: el navegador es un **puente poco fiable** (cualquiera podría abrir la consola y emitir un `rfid_scan_from_client` falso). ¿Cómo garantizamos que un escaneo viene de verdad del sensor físico?

**Con un HMAC (firma criptográfica) calculado en el propio firmware:**
`HMAC = hash( clave + hash( clave + mensaje ) )` | `Mensaje = UID + contador`
*HMAC = Hash-based Message Authentication Code*
- Se le llama "firma" de forma coloquial, pero **técnicamente HMAC es un MAC simétrico**: las dos partes comparten la misma clave, así que **cualquiera que la tenga puede tanto crear como verificar un HMAC**.
- El ESP8266 firma cada escaneo: `HMAC-SHA256(secreto, UID + ":" + contador)`. El **secreto solo está en el firmware y en el servidor**, nunca en el navegador.
- El navegador **solo reenvía la firma**, no la calcula ni conoce el secreto. Es un mero transportista.
- El backend **recalcula la firma** y la compara con `timingSafeEqual` (comparación en tiempo constante, contra *timing attacks*).
- **Anti-replay**: cada escaneo lleva un **contador monotónico** persistido en la EEPROM del ESP8266. El backend rechaza cualquier contador menor o igual al último visto (comparación-y-set atómica en Redis). Así, aunque alguien capture un escaneo válido, no puede **reproducirlo**.

Resultado: **autenticidad y frescura end-to-end**, incluso con el navegador de intermediario no confiable. El *enforcement* es consciente del origen: solo la fuente `web_serial` está obligada a firmar; los modos táctiles de respaldo están exentos.

### 3.3 Robustez de la conexión del lector (endurecimiento reciente)

El sensor es un **RC522 clon barato con firmware inmutable** (lo aporta el tutor, no se puede modificar), así que **toda la robustez se resuelve en la app**. Decisiones:
- **Máquina de estados del dispositivo**: `desconocido → inicializando → listo/error → obsoleto`, comunicada a la UI.
- **Watchdogs**: si pasan 20 s sin latido → estado "obsoleto"; si el buffer lleva 2 s sin recibir bytes → se vacía por corrupción.
- **Reconexión automática** con *backoff* exponencial (hasta 3 intentos) al detectar desconexión física.
- **Estado gobernado por actividad, no solo por el `init`**: el mensaje de arranque (`init`) es de un solo disparo y se pierde si el ESP ya estaba encendido, así que **una lectura válida o un latido también promueven el estado a "listo"**. Esto arregló el clásico bug de la UI clavada en "esperando sensor".
- **`read_failure` tratado como pista transitoria, no como error rojo**: el RC522 clon genera ruido; solo tras 3 fallos consecutivos se avisa en ámbar. El rojo se reserva a fallos reales de inicialización.
- **Cola offline de escaneos**: si el WebSocket está caído, los escaneos se **encolan** (con persistencia en IndexedDB, TTL de frescura) y se reenvían al reconectar, descartando los que ya habrían caducado.

### 3.4 WebSocket — cómo transmitimos y protegemos el tiempo real

- **Dos namespaces**: `/` (sistema) y `/game` (gameplay/RFID). Son conexiones independientes. Son canales que el **cliente elige conectar explícitamente**.
- **Autenticación con JWT en el handshake**: el token viaja en `handshake.auth` y se valida antes de aceptar el socket. Crucial: en el cliente el token se pasa como **función**, no como valor fijo, para que se resuelva **de nuevo en cada reconexión** (si no, tras un *refresh* el socket se quedaría anclado a un token caducado).
- **Rate limiting por evento**: cada handler está envuelto en un limitador. `rfid_scan_from_client` admite 120/min. Detalle de UX importante: es un **soft-limit** — si un niño "machaca" el tablero, los escaneos sobrantes se **descartan sin contar como violación**, para no bloquear los controles del profesor.
- **Deduplicación diferenciada por origen**: escaneos del sensor físico se de-duplican en ~1,2 s; los táctiles en ~250 ms.
- **Validación en cadena en el servidor** para cada escaneo: rol correcto → esquema Zod → **HMAC + anti-replay** → propiedad del modo RFID → sensor autorizado para esa sesión → *binding* anti-robo. El escaneo se ancla al `playId` del profesor emisor para impedir inyección entre profesores.
- **Rooms**: cada partida es un *room* `play_<playId>`; el resultado de cada escaneo se emite solo a los participantes de esa partida. Existen **dentro de un namespace**. A diferencia de los namespaces, el cliente no tiene el control directo de las rooms; es el servidor quien decide quién entra o sale.

### 3.5 Los eventos del juego

- El servidor **empuja cada nuevo desafío** al alumno con el evento **`new_round`** (número de ronda, desafío, tiempo, puntuación).
- Otros eventos: `validation_result` (resultado de un escaneo), `game_over`, `play_paused`/`play_resumed`, `scan_ignored`, y los específicos de la mecánica de Secuencia.
- **Matiz honesto**: existe también un evento `play_state` que **no** es el push de ronda, sino un **snapshot completo de rehidratación** que se envía al unirse a la partida, al sincronizar o al reconectar. Es decir: la ronda se comunica con `new_round`; el estado completo para "ponerse al día" tras una reconexión viaja en `play_state`.

---

## 4. Cosas interesantes / offtopic

**a) ¿Por qué Web Serial y no otra cosa?**
La disyuntiva real documentada fue **Web Serial (en el navegador)** frente a **leer el serie en el servidor** (descartado por la imposibilidad de USB en cloud). La alternativa de futuro contemplada es **MQTT/WiFi**: que varios ESP8266 hablen por WiFi directamente, sin cable USB, publicando en *topics*. Eso permitiría varios lectores por aula sin depender del PC del profesor.
> Cuidado en la defensa: en el código/documentación **no** hay una comparación explícita con **WebUSB** ni **Web Bluetooth**. Si la memoria las menciona, verifícalo antes de afirmarlo; lo que el proyecto respalda es Web Serial (elegida) vs. serie-en-servidor (descartada) vs. MQTT (futuro).

**b) La limitación de Web Serial es también una decisión de arquitectura.**
Que solo funcione en Chromium, con HTTPS y con gesto de usuario, encaja perfectamente con el contexto: es una herramienta de aula para el **profesor** en un portátil (no un móvil), y el requisito de HTTPS refuerza la seguridad. Por eso el proyecto es **desktop-first** (el sensor va por USB; móvil queda fuera de alcance).

**c) El sistema es jugable SIN sensor físico.**
Como el sensor es hardware frágil, existe:
- Un **modo simulación** (`window.__rfidSim`) que **solo se monta en builds de desarrollo** (nunca en el bundle de producción). Inyecta escaneos en el **mismo punto** que el firmware real, así que recorren todo el pipeline (validación, dedupe, HMAC). Incluso puede **firmar** los escaneos con el secreto cargado en runtime, para poder probar el enforcement HMAC sin sensor.
- **Modos táctiles** de respaldo (`touch_fallback`) que permiten jugar tocando la pantalla. Esto demuestra un diseño resiliente: el juego no se cae si falla el hardware.

**d) La separación de responsabilidades es la clave del diseño.**
El navegador hace **solo una cosa**: leer el sensor y reenviar. **Toda la autoridad está en el servidor**: validación de esquema, HMAC, anti-replay, permisos, propiedad de la sesión, rate limiting. Esto es un principio de seguridad importante — *"nunca confíes en el cliente"* — aplicado a un puente que, por diseño, es no confiable.

**e) Detalle fino de reconexión (React StrictMode + orden de eventos).**
Hay varios *guards* contra el doble-montaje de React 19 StrictMode para no abrir dos sockets. Y un detalle sutil: al reconectar, el cliente **re-emite `JOIN_PLAY`** y **espera al primer `play_state`** antes de vaciar la cola de escaneos pendientes, porque el backend restaura el modo RFID **dentro** del handler de `JOIN_PLAY` de forma asíncrona. Sin esa espera, los escaneos encolados llegarían antes de que el servidor supiera a qué partida pertenecen.

---

## 5. Preguntas típicas y respuesta rápida

- **"¿Cómo evitas que alguien falsifique un escaneo desde la consola del navegador?"** → Con HMAC + contador anti-replay. El navegador no conoce el secreto; solo el firmware y el servidor. Sin firma válida y contador creciente, el backend rechaza el escaneo.
- **"¿Por qué el navegador y no el ESP8266 hablando directo con el backend?"** → Para eliminar la dependencia de USB en el servidor (imposible en cloud) y centralizar toda la validación server-side. El ESP por WiFi/MQTT queda como mejora futura.
- **"¿Qué pasa si se cae la conexión a mitad de partida?"** → El WebSocket reconecta solo; los escaneos se encolan offline y se reenvían; al reconectar se re-sincroniza el estado completo con `play_state` antes de vaciar la cola.
- **"¿Web Serial funciona en cualquier navegador?"** → No, solo en Chromium (Chrome/Edge) y con HTTPS. Es una limitación asumida: es una herramienta de escritorio para el profesor.
- **"¿HTTP normal no bastaba para el tiempo real?"** → No: HTTP es petición-respuesta iniciada por el cliente. Necesitamos que el **servidor empuje** cada nueva ronda y cada resultado al instante, y eso lo da el WebSocket (canal bidireccional persistente).
