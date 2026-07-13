# El Worker (procesamiento en segundo plano) en el proyecto

> Nota de estudio para la defensa. Todo lo de aquí está verificado contra el código real del backend (última verificación: julio 2026, cruzando cada afirmación con `backend/worker.js`, `backend/src/queues/` y `backend/src/workers/`).
>
> **Cómo leer esta nota:** si no sabes qué es un "worker", lee primero el **Glosario mínimo** (§1). El worker se apoya en Redis, así que ayuda tener a mano la nota de [[Redis]].

---

## 1. Glosario mínimo (para leer el resto sin perderse)

| Término | En una frase |
|---|---|
| **Worker** (proceso trabajador) | Un proceso que hace tareas "de trastienda" en segundo plano, **separado** del que atiende a los usuarios en tiempo real. |
| **Cola** (*queue*) | Una **bandeja de entrada** de tareas pendientes. Alguien deja tareas; el worker las va cogiendo y ejecutando. |
| **Job** (trabajo) | Una tarea concreta dentro de una cola (p. ej. "ejecuta la limpieza de datos de hoy"). |
| **Productor / consumidor** | El **productor** mete tareas en la cola; el **consumidor** (el worker) las ejecuta. |
| **Cron** | Una "alarma con horario". Una expresión como `0 3 * * *` significa "todos los días a las 03:00". Dispara tareas periódicas. |
| **Trabajo repetible / planificado** | Tarea que se vuelve a encolar sola según un cron, sin que nadie la meta a mano cada vez. |
| **Idempotente** | Que ejecutarlo dos veces da el mismo resultado que una sola vez (no duplica efectos). Clave para poder reintentar sin miedo. |
| **BullMQ** | La librería que gestiona las colas de trabajos. Por debajo guarda las colas en **Redis**. |
| **Graceful shutdown** | Apagado **ordenado**: terminar los trabajos en curso antes de cerrar, en vez de cortar de golpe. |
| **Fire-and-forget** | Lanzar una operación "y olvidarse": no se espera a que acabe ni se comprueba si falló. |
| **Drift** (deriva) | Desincronización entre un dato precalculado (p. ej. un ranking en caché) y la fuente de verdad real (Mongo). |

---

## 2. ¿Qué es un worker? (explicación breve)

Imagina una tienda con un **mostrador** y una **trastienda**:
- El **mostrador** atiende a los clientes en tiempo real. Tiene que responder rápido y no puede pararse a hacer tareas largas mientras hay gente esperando. → En nuestro proyecto, el mostrador es el **servidor de la API** (el backend HTTP que responde a la web).
- La **trastienda** hace el trabajo pesado, lento o programado (archivar papeleo viejo, cuadrar las cuentas de la noche, revisar que todo esté en orden) **sin que ningún cliente espere por ello**. → Eso es el **worker**.

Un **worker** es, por tanto, un proceso dedicado a **tareas en segundo plano**: cosas que deben ocurrir, pero que no forman parte de responder a una petición concreta del usuario. Se comunica con el mostrador a través de una **cola** (la bandeja de entrada de tareas).

Ideas para explicarlo en 30 segundos:
- Separa el **trabajo que el usuario espera** (responder a un clic) del **trabajo que puede hacerse por detrás** (limpiar datos, calcular rankings, detectar problemas).
- Las tareas viajan por una **cola** gestionada con **BullMQ**, que usa **Redis** como almacén de esa cola.
- La mayoría de nuestras tareas son **periódicas** (se disparan por un **cron**, a una hora fija o cada X minutos), no a demanda.

**Frase resumen para el tribunal:** *"El worker es un proceso aparte que ejecuta el trabajo de trastienda del sistema (retención de datos RGPD, detección de alertas, cuadre de métricas). Así el servidor de la API nunca se bloquea haciendo tareas pesadas mientras atiende a profesores y alumnos."*

---

## 3. ¿Para qué usamos el worker en el proyecto?

El worker ejecuta **cuatro tareas de fondo**, todas planificadas por cron. Cada una resuelve algo que **no debe cargar al servidor de la API**:

| Tarea (cola) | Cuándo | Para qué sirve |
|---|---|---|
| **Retención de datos** (`data-retention`) | Diario a las **03:00** | Cumplir el RGPD: anonimizar/borrar datos personales de menores pasado su plazo de conservación |
| **Alertas de docente** (`alert-detection`) | Cada **15 min** | Detectar situaciones pedagógicas por alumno (bajón de rendimiento, inactividad, hitos de mejora…) y avisar al profesor |
| **Alertas de sistema** (`system-alert-detection`) | Cada **15 min** | Vigilar la salud operativa (Redis lento, memoria, cuotas del *free-tier*, picos de seguridad…) y avisar al super_admin |
| **Reconciliación de analytics** (`analytics-reconcile`) | Nocturno a las **00:30** | Recalcular los rankings y métricas cacheados en Redis desde Mongo, corrigiendo desviaciones |

> **Importante (honestidad para la defensa):** hay **dos colas más registradas pero vacías** (`gdpr-exports` y `notifications`): son **andamiaje sin proceso trabajador**, pendientes de implementar. No las cuentes como funcionales.

**Por qué esto importa en un TFG con datos de menores:** la tarea de retención es la implementación técnica de una **obligación legal** (RGPD Art. 5.1.e, minimización y limitación del plazo de conservación; Art. 17, derecho de supresión). No es una optimización: es cumplimiento normativo automatizado.

---

## 4. ¿Cómo lo usamos? (detalle técnico)

### 4.1 La decisión clave: el worker es un PROCESO SEPARADO

Esto es lo primero que hay que entender y lo que más puede sorprender:

> El worker **no** corre dentro del servidor de la API. Es un **proceso independiente** (`backend/worker.js`), que Docker Compose levanta como un **contenedor propio** ejecutando `node worker.js`, distinto del contenedor del backend (que ejecuta `node src/server.js`).

Reparto de responsabilidades entre los dos procesos:
- **El backend HTTP (mostrador)** solo **planifica** los crons (registra en la cola "esta tarea debe repetirse a tal hora") y consulta la profundidad de las colas para métricas. **Nunca ejecuta un worker.**
- **El worker (trastienda)** es quien **ejecuta** de verdad las tareas cuando llega su hora.

¿Por qué separarlos? Porque una tarea pesada (anonimizar miles de registros, recalcular todos los rankings) **no debe consumir CPU ni memoria del proceso que está atendiendo a los usuarios**. Si el worker se satura, el mostrador sigue respondiendo con normalidad. Es aislamiento de fallos y de recursos.

**Cómo encaja con el invariante `scale=1`** (ver nota de [[Redis]], §5.1): el `scale=1` dice que hay **una sola instancia del backend HTTP** (porque su estado de juego vive en memoria del proceso). El worker es un **segundo proceso** que convive con ese único backend. De hecho, BullMQ es justo la pieza que permite **sacar el trabajo pesado fuera del único proceso de la API sin violar `scale=1`**: no añadimos una segunda instancia de la API, añadimos un trabajador especializado.

### 4.2 La tecnología: BullMQ sobre Redis

- Librería **BullMQ** (v5.x). Es un gestor de colas de trabajos que usa **Redis** como almacén de las colas (las tareas pendientes, en curso y terminadas viven en Redis).
- El worker usa una **conexión Redis dedicada**, distinta del cliente principal del backend. Motivo: BullMQ exige una configuración de conexión concreta (`maxRetriesPerRequest: null`) que sería incompatible con el cliente de caché y locks. Por eso hay dos conexiones a Redis separadas.
- Las claves de BullMQ llevan su propio prefijo (`…:bull`) para no mezclarse con el resto de datos de Redis.

### 4.3 Las tareas por dentro (qué hace cada worker)

**a) Retención de datos RGPD (`data-retention`, 03:00 diario).** Ejecuta tres acciones:
1. **Anonimiza** las partidas (`GamePlay`) de **más de 12 meses**: pone a `null` el identificador del jugador y el UID de la tarjeta. Ojo: **anonimiza, no borra** — se conservan las métricas agregadas, que al perder toda referencia personal ya son dato anónimo (fuera del RGPD, Considerando 26). Se procesa por lotes de 500 para no saturar Mongo.
2. **Borra** (esta vez sí, borrado real y en cascada) los **estudiantes inactivos de más de 24 meses**, junto con sus partidas y sus métricas en Redis. Es el **derecho de supresión** (Art. 17).
3. **Limpia** alertas ya resueltas/descartadas de más de 365 días (mantenimiento operacional, no PII).

**b) Alertas de docente (`alert-detection`, cada 15 min).** Hace un **barrido periódico de todos los docentes activos** (en lotes de 50) y detecta **13 tipos de situación pedagógica** por alumno:
- Negativas: bajón de rendimiento, inactividad, caída brusca de puntuación, *timeouts* repetidos, mucho abandono, estancamiento, caída de participación, dificultad con una mecánica concreta.
- Positivas (informativas): mejora rápida, recuperación tras un bajón, hito de maestría.
- Específicas de la mecánica *Secuencia*: estancamiento y errores de orden.

Con cada detección crea o actualiza un documento `SmartAlert` en Mongo y gestiona su ciclo de vida (se **auto-resuelve** si deja de aparecer en 2 barridos; se **reabre** si una alerta crítica descartada reaparece pasados 60 días). Solo **notifica** al docente cuando una alerta crítica es nueva o acaba de escalar, para no generar ruido.
> No se dispara al terminar cada partida: es un barrido periódico, no un evento en tiempo real.

**c) Alertas de sistema (`system-alert-detection`, cada 15 min).** Vigila la salud del sistema completo para el super_admin con **18 detectores**, entre ellos:
- Operación: Redis con latencia alta, Mongo desconectado, presión de memoria (RSS >85%/95%), colas atascadas.
- Presupuesto *free-tier*: **cuota de comandos de Upstash** (avisa al **80%** y al **95%** del presupuesto diario), cuota de almacenamiento de Atlas…
- Seguridad: picos de bloqueos de cuenta, de logins fallidos, detección de robo de token, picos de fallos HMAC del sensor RFID.
- Cumplimiento: retraso en la retención de datos, picos de retirada de consentimiento.

Deduplica globalmente (una sola alerta activa por tipo) y notifica a todos los super_admins ante una alerta crítica.

**d) Reconciliación de analytics (`analytics-reconcile`, 00:30 nocturno).** Recalcula **desde Mongo (la fuente de verdad)** los datos que en Redis están precalculados: los *leaderboards* (ZSET) y las métricas de alumno (Hash `student:metrics`).
- **Por qué hace falta:** durante el juego, esas métricas se escriben en Redis en modo **fire-and-forget** — si Redis está caído o el *circuit breaker* abierto (ver [[Redis]] §4.4), la escritura se pierde **sin bloquear la partida**. Eso provoca **drift** (deriva): el ranking cacheado se desvía poco a poco del real. El job nocturno lo **cuadra**.
- Reporta cuántas entradas se habían desviado más de un 5% y avisa por Sentry si hubo deriva significativa.

### 4.4 Planificación: todo por cron, e idempotente

Las cuatro tareas se planifican como **trabajos repetibles por cron**, registrados **al arrancar el backend HTTP** (para garantizar que existen mientras la API esté viva), pero **ejecutados en el proceso worker**:

| Cola | Cron | Significado |
|---|---|---|
| `data-retention` | `0 3 * * *` | Todos los días a las 03:00 |
| `analytics-reconcile` | `30 0 * * *` | Todos los días a las 00:30 |
| `alert-detection` | `*/15 * * * *` | Cada 15 minutos |
| `system-alert-detection` | `*/15 * * * *` | Cada 15 minutos |

> *Cómo leer un cron:* son cinco campos `minuto hora día-del-mes mes día-de-semana`. `0 3 * * *` = minuto 0 de la hora 3, cualquier día → las 03:00. `*/15 * * * *` = cada 15 minutos.

Cada cron se registra con un **`jobId` fijo**, lo que lo hace **idempotente**: si el proceso reinicia, no se duplica la tarea (BullMQ reconoce que ya existe ese trabajo repetible). Las propias tareas también están diseñadas para poder reejecutarse sin efectos dobles (re-anonimizar un registro ya anónimo no hace nada; las alertas se deduplican por índice único; la reconciliación reescribe siempre desde Mongo).

### 4.5 Robustez y apagado ordenado

- **Concurrencia 1** por worker (procesa un trabajo a la vez; configurable por variable de entorno). Suficiente para tareas nocturnas/periódicas y suave con la BD.
- **Apagado ordenado (graceful shutdown):** el proceso worker escucha las señales `SIGTERM`/`SIGINT` (las que envía Docker al parar el contenedor) y, en vez de cortar de golpe, **espera a que terminen los trabajos en curso** (`worker.close()`), luego cierra colas y conexiones (Redis, Mongo) y envía lo pendiente a Sentry. Hay un **límite duro de 25 s** por si algo se atasca, para salir antes del *kill* forzado.
- **Limpieza automática de historial:** los trabajos completados se borran a las 24 h (o al superar 1000), y los fallidos a los 7 días (o al superar 5000), para que el historial en Redis no crezca sin límite.
- **Errores por trabajo:** cada worker registra los fallos con Pino (`jobId`, intento, *stack*) y envía cada trabajo envuelto en un *span* de Sentry, que captura la excepción con etiquetas de cola y de trabajo. Así un fallo nocturno queda trazado y correlacionado en Grafana Loki / Sentry.

---

## 5. Cosas interesantes / decisiones que lucen en la defensa

**El worker es lo que hace que el `scale=1` sea sostenible.** Podrían objetarte: *"con una sola instancia de backend, ¿cómo haces trabajo pesado sin degradar la experiencia?"*. Respuesta: sacándolo a un **segundo proceso especializado**. No escalamos la API horizontalmente (no hace falta), pero sí **separamos responsabilidades por proceso**: mostrador y trastienda. Es una arquitectura de dos procesos, simple y honesta a la escala objetivo.

**Cumplimiento RGPD como código, no como promesa.** La retención de datos de menores no es una política escrita en un documento: es un **cron que corre cada noche** y anonimiza/borra según plazos concretos (12 meses para anonimizar partidas, 24 para borrar alumnos inactivos). Además, se registra en Redis la marca de la última ejecución, y un **detector de sistema vigila que ese cron no se retrase** (`data_retention_lag`). Es cumplimiento verificable y auto-monitorizado.

**Auto-vigilancia del propio sistema.** El worker no solo hace tareas: una de ellas es **mirarse a sí mismo y a la infraestructura** (18 detectores de salud), incluido vigilar el consumo de las cuotas gratuitas (Upstash, Atlas) antes de que revienten. El sistema se avisa solo cuando algo va mal, en lugar de esperar a que un usuario lo reporte.

**Protección de datos también dentro del segundo plano.** El subsistema de alertas de docente **nunca escribe el identificador real del alumno en los logs**: usa un pseudónimo (HMAC de `studentId|teacherId`). Y solo procesa a alumnos con **consentimiento activo** para analítica de rendimiento, con defensa en profundidad (filtro en la consulta a BD + filtro en código). La protección de menores no se queda en el mostrador; llega hasta la trastienda.

---

## 6. Preguntas típicas y respuesta rápida

- **"¿El worker corre dentro del servidor?"** → No. Es un **proceso separado** (`node worker.js`), en su propio contenedor Docker. El backend HTTP solo planifica los crons; el worker los ejecuta.
- **"¿Por qué no meter estas tareas en la API directamente?"** → Porque son pesadas o periódicas y bloquearían el proceso que atiende a los usuarios. Separarlas mantiene la API siempre ágil y aísla los fallos.
- **"¿Cómo garantizas la retención de datos del RGPD?"** → Con un cron nocturno (03:00) que anonimiza partidas de +12 meses y borra alumnos inactivos de +24 meses, más un detector que vigila que ese cron no se atrase.
- **"¿Qué pasa si el worker se cae a media tarea?"** → Al reiniciar, el trabajo repetible sigue existiendo (idempotente por `jobId`) y las tareas están diseñadas para reejecutarse sin duplicar efectos. El apagado, además, es ordenado: espera a terminar lo que está haciendo.
- **"¿Las alertas son en tiempo real?"** → No exactamente: son barridos **cada 15 minutos**, no eventos por partida. Es un compromiso deliberado entre frescura y coste (comandos de Redis).
- **"¿Por qué hace falta reconciliar analytics de noche?"** → Porque las métricas se escriben en vivo en modo *fire-and-forget*; si Redis falla, se pierden sin romper la partida. El job nocturno recalcula desde Mongo y corrige esa deriva.

---

## 7. ⚠️ Para no exagerar en la defensa (los "por si acaso")

Seis afirmaciones donde conviene ser preciso si el tribunal pincha:

1. **El worker es un proceso/contenedor separado**, no código dentro de la API. El backend HTTP solo *planifica*; el worker *ejecuta*.
2. **No hay reintentos automáticos con *backoff*.** Por defecto BullMQ da 1 intento (no está configurado `attempts`/`backoff`). Lo único que se re-ejecuta solo es un trabajo que quede a medias porque el proceso murió (mecanismo de *stalled jobs*). No afirmes "reintentos con backoff exponencial".
3. **Hoy todo se dispara por cron, no a demanda.** Los workers están *preparados* para recibir trabajos ad-hoc (por `job.data`), pero **nada los encola** on-demand todavía. La detección de alertas es periódica, no por evento de usuario.
4. **Las alertas de sistema corren cada 15 minutos**, no cada 5 (hay comentarios en el código desactualizados que dicen 5; el valor real por defecto es 15, subido para no reventar la cuota de Upstash).
5. **`gdpr-exports` y `notifications` son colas vacías sin worker** (andamiaje). Las tareas reales son 4: retención, alertas de docente, alertas de sistema y reconciliación.
6. **La retención anonimiza las partidas (no las borra):** pone a `null` jugador y UID de tarjeta a los 12 meses. El **borrado** real es solo para alumnos inactivos de +24 meses (con sus datos en cascada).
