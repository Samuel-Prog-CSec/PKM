# Protección de datos en el proyecto

> Nota de estudio para la defensa. Todo lo de aquí está verificado contra el código real del backend (última verificación: julio 2026, cruzando cada afirmación con `backend/src/utils/pseudonymize.js`, `backend/src/config/dataRetention.js`, `backend/src/services/dataRetentionService.js`, `backend/src/controllers/analyticsController.js` y el documento maestro `documentation/Proteccion_Datos_Menores.md`).
>
> **Cómo leer esta nota:** si no manejas la jerga legal, lee primero el **Glosario mínimo** (§1). Las **tres piezas estrella** que más te pueden preguntar (seudonimización de la analítica, k-anonimidad y retención) están en §4, explicadas desde cero. La retención la ejecuta el proceso worker, así que ayuda tener a mano [[Worker]]; la seudonimización y los TTL se apoyan en [[Redis]].

---

## 1. Glosario mínimo (para leer el resto sin perderse)

| Término | En una frase |
|---|---|
| **Dato personal / PII** | Cualquier dato que identifique o pueda identificar a una persona. Aquí: nombre, edad, aula, rendimiento de un menor. |
| **Menor vulnerable** | Los alumnos tienen **4-8 años**. El RGPD (Considerando 38) los reconoce como colectivo que merece **protección reforzada**. Es el eje que justifica todo lo demás. |
| **Quasi-identificador** | Un dato que por sí solo no identifica, pero **combinado** con otros sí (edad + aula + patrón de rendimiento → un alumno concreto). |
| **Anonimización** | Romper **para siempre** el vínculo dato↔persona. Es **irreversible**. Un dato anónimo ya **no es dato personal** → sale del RGPD (Considerando 26). |
| **Seudonimización** | Sustituir el identificador por un **seudónimo** (un código). Es **reversible** con "información adicional" guardada aparte. Sigue siendo **dato personal** (RGPD Art. 4.5). |
| **k-anonimidad** | Propiedad: cada individuo es **indistinguible de al menos otros k-1**. Con k=5, no puedes señalar a uno entre menos de 5. |
| **HMAC** | Un hash **con clave secreta**. Como un SHA-256, pero solo quien tiene la clave puede recalcularlo. Clave para que el seudónimo no sea reversible por fuerza bruta. |
| **Minimización** | Recoger **solo** los datos estrictamente necesarios. Lo que no se recoge, no se puede filtrar. |
| **Retención** | Cuánto tiempo se guardan los datos. Pasado el plazo → se anonimizan o se borran **automáticamente**. |
| **Hard delete / soft delete** | *Hard* = borrado real e irreversible. *Soft* = marcar como "inactivo" sin borrar (reversible). Son operaciones distintas. |
| **Consentimiento parental** | Como los alumnos son menores de 14, la base legal para tratar sus datos es el **permiso del padre/tutor** (Art. 8 RGPD + Art. 7 LOPDGDD). |
| **RAT / EIPD** | Documentos legales obligatorios: **RAT** = registro de qué datos tratas y por qué (Art. 30); **EIPD** = evaluación de riesgos del tratamiento (Art. 35). |
| **DTO** | *Data Transfer Object*: el objeto que la API devuelve. Decide **qué campos se exponen** y cuáles no (nunca el documento crudo de Mongo). |
| **RGPD / LOPDGDD** | La ley europea (Reglamento 2016/679) y su desarrollo español (Ley Orgánica 3/2018). El marco normativo que hay que cumplir. |

---

## 2. ¿Qué hacemos? (explicación breve)

La plataforma trata datos de **niños de 4 a 8 años**: nombre, edad, aula y, sobre todo, su **rendimiento en el juego** (puntuaciones, aciertos, errores, tiempos de respuesta). Ese último bloque es delicado: los tiempos de respuesta y los patrones de error, mal interpretados, podrían leerse como indicios de capacidades o dificultades cognitivas de un menor. No son datos de categoría especial (Art. 9), pero **exigen protección reforzada** por ser de menores.

La respuesta del proyecto es aplicar **protección de datos desde el diseño** (*privacy by design*, Art. 25): en vez de añadir privacidad al final, está integrada en el modelo de datos y en la arquitectura. En una frase, hacemos cinco cosas:

1. **Minimizar** — no recogemos lo que no necesitamos (ni email, ni contraseña, ni fecha de nacimiento completa del alumno).
2. **Seudonimizar** — en logs y analítica, el alumno aparece como un código, no con su identidad real.
3. **k-anonimizar** — en aulas muy pequeñas, la analítica devuelve solo datos agregados, nunca fila por fila.
4. **Retener con plazos** — un proceso nocturno anonimiza o borra automáticamente los datos que superan su plazo legal.
5. **Dar control al tutor** — consentimiento parental obligatorio y verificable, con derecho de oposición, exportación y borrado.

**Frase resumen para el tribunal:** *"Tratamos datos de un colectivo vulnerable —menores de 4 a 8 años—, así que la protección de datos no es un añadido: es un requisito de diseño. Minimizamos lo que recogemos, seudonimizamos lo que procesamos, aplicamos k-anonimidad en grupos pequeños, retenemos con plazos automáticos y damos al tutor control real sobre los datos de su hijo. Y todo está implementado y verificable en código, no solo documentado."*

---

## 3. ¿Qué datos protegemos? (y por qué importa tanto)

**Lo que SÍ recogemos del alumno** (y por qué):
- **Nombre, edad, aula** → para que el profesor identifique y organice a sus alumnos.
- **Rendimiento** (puntuación, métricas de partida, eventos de interacción, tiempos de respuesta) → seguimiento pedagógico.

**Lo que deliberadamente NO recogemos** (minimización por diseño — esto luce mucho):
- **Email y contraseña del alumno** → los niños no inician sesión; su interacción va a través del profesor. El modelo **valida activamente** que un estudiante no tenga contraseña.
- **Fecha de nacimiento completa** → guardamos solo la **edad como entero**. Una fecha exacta ("5 años nacido el 15-03-2021") identifica en un aula; "5 años" no. Se eliminó el campo y hay una validación que impide reintroducirlo.
- Nada de dirección, teléfono, biometría, salud, geolocalización ni fotos.

**Por qué es crítico:** el UID de la tarjeta RFID **no es un dato biométrico** — identifica al objeto (la tarjeta), no al niño; las tarjetas son intercambiables. Pero los tiempos de respuesta y los patrones de error sí son **potencialmente sensibles**. La plataforma **no infiere** capacidades cognitivas ni facilita esa interpretación: la lectura pedagógica es siempre responsabilidad del profesor humano.

**Base legal:** al ser menores muy por debajo de los 14 años (umbral español, Art. 7 LOPDGDD), la base es el **consentimiento del padre/tutor** (Art. 6.1.a + Art. 8 RGPD). Se descartó el "interés legítimo" porque el propio RGPD (Considerando 47) dice que los derechos del menor prevalecen.

---

## 4. ¿Cómo lo hacemos? Las tres piezas estrella

Primero, **el concepto que más te van a preguntar** y que hay que tener cristalino; luego las tres piezas.

### 4.0 ⭐ La distinción clave: anonimizar ≠ seudonimizar

Es el error conceptual más típico y donde el tribunal puede pinchar. La diferencia es **la reversibilidad**:

| | **Seudonimización** | **Anonimización** |
|---|---|---|
| Qué hace | Cambia el identificador por un **código** | **Rompe** el vínculo con la persona |
| ¿Reversible? | **Sí**, con información adicional guardada aparte | **No**, es definitiva |
| ¿Sigue siendo dato personal? | **Sí** → sigue bajo el RGPD | **No** → sale del RGPD (Cons. 26) |
| Dónde la usamos | **Logs y analítica** (el profesor necesita volver al nombre real) | **Retención**: partidas de +12 meses |

La regla mental: **seudonimizamos lo que aún necesitamos poder "des-seudonimizar"** (el profesor debe poder ver qué alumno es para intervenir), y **anonimizamos lo que ya no debe volver a vincularse a nadie** (partidas viejas cuyo valor ya es solo estadístico). No las confundas: llamar "anónimos" a los pseudoIds de los logs sería un error.

---

### 4.1 🎭 Seudonimización de la analítica y los logs

**Qué es.** En cualquier sitio donde el sistema menciona a un alumno pero **no necesita su identidad real** (líneas de log, DTOs de analítica, alertas al profesor), no ponemos su identificador ni su nombre: ponemos un **pseudoId**, un código corto y estable.

**Cómo lo hacemos (y aquí está el detalle bueno).** El pseudoId **no es un hash normal**: es un **HMAC-SHA256 con una clave secreta del servidor** (`PSEUDONYMIZE_SECRET`), truncado a **16 caracteres hexadecimales (64 bits)**.

¿Por qué con clave y no un SHA-256 normal? Porque los identificadores de Mongo (ObjectIds) son **enumerables** (tienen estructura, se pueden generar todos). Si usáramos un SHA-256 **sin clave**, un atacante con acceso a los logs podría **recalcular el hash de cada id candidato** hasta encontrar el que coincide → re-identificación trivial. Con **HMAC con clave**, sin conocer el secreto del servidor **es imposible recomputar** el pseudoId. La clave es lo que convierte la seudonimización en algo criptográficamente serio.

Otras dos propiedades importantes:
- **Determinista:** el mismo alumno da **siempre el mismo pseudoId** (con la misma clave). Eso permite **correlacionar** eventos de un alumno entre distintos logs sin saber quién es.
- **Reversibilidad operativa, sin invertir el hash:** el profesor **sí** puede volver al nombre real, pero **no** deshaciendo el hash (eso es imposible) — lo hace a través de un **endpoint que consulta la base de datos**. Es decir, la "información adicional" para revertir (la tabla alumno↔id en Mongo) se mantiene **separada** y bajo control de acceso, justo como pide el Art. 4.5 del RGPD.

**Dónde se aplica:**
- **Logs de seguridad y operativos:** nunca aparece el nombre ni el id crudo de un menor, solo el pseudoId.
- **DTOs de analítica:** los datos de rendimiento viajan con el pseudoId; la traducción a nombre real ocurre solo en el dashboard del profesor autorizado.
- **Alertas inteligentes (`SmartAlert`):** cada alerta guarda `studentPseudoId = pseudonymize(studentId|teacherId)`. Al meter también el `teacherId` en la entrada, el pseudoId queda **acotado por profesor** (dos profesores no comparten el mismo pseudoId para un alumno). El `teacherId` sí se registra en claro porque los profesores **no son menores** y hace falta para correlación operativa.

> **Fallback honesto:** si no está configurada la clave (`PSEUDONYMIZE_SECRET`), la función degrada a SHA-256 sin clave para no romper respuestas. En **producción la clave es obligatoria** (lo fuerza el validador de entorno), así que ese fallback solo aplica en desarrollo.

**Frase para la defensa:** *"Seudonimizamos con HMAC, no con un hash a secas. Como los ObjectIds son enumerables, un hash sin clave sería reversible por fuerza bruta desde los logs; la clave secreta lo impide. El profesor sigue pudiendo llegar al nombre real, pero consultando la base de datos, no invirtiendo el hash — la información para revertir se guarda separada, como exige el Art. 4.5."*

---

### 4.2 👥 k-anonimidad en aulas pequeñas

**El problema que resuelve.** Aunque la analítica vaya seudonimizada, en un grupo **muy pequeño** los quasi-identificadores delatan. Si un profesor comparte pantalla y el aula tiene 3 alumnos, cualquiera que vea las 3 filas puede deducir cuál es cuál, aunque no aparezca el nombre. La seudonimización no basta cuando el grupo es diminuto.

**Qué es la k-anonimidad.** Es garantizar que cada individuo es **indistinguible de al menos otros k-1**. Con **k=5**, ningún alumno puede aislarse dentro de un grupo de menos de 5.

**Cómo lo hacemos.** Hay una constante de configuración `MIN_ANALYTICS_GROUP_SIZE = 5`. El endpoint de analítica por aula se comporta así:
- **Grupo de 5 alumnos o más** → devuelve datos **individuales** (con pseudoIds).
- **Grupo de 1 a 4 alumnos** → **no** devuelve filas individuales; devuelve solo **métricas agregadas del grupo** (nº de alumnos, media de puntuación, total de partidas) y un campo `reason` que explica que se ha activado la protección de k-anonimidad.
- **Grupo de 0 alumnos** → respuesta vacía normal (no se activa nada).

Y algo importante: el umbral se aplica al **grupo ya filtrado**. Un profesor con 20 alumnos que filtra por un aula concreta con solo 3 → recibe la respuesta agregada. Protege al subgrupo pequeño, no solo al total.

**Por qué k=5** (y no otro): lo recomienda la **Guía de Anonimización de la AEPD (2019)** para datos sensibles, y se apoya en el trabajo académico de **Sweeney (2002)**. Se descartó k=3 (insuficiente según la AEPD) y k=10 (dejaría sin analítica a aulas reales españolas, que rondan los 15-25 alumnos).

**Frase para la defensa:** *"En aulas pequeñas, ni la seudonimización protege: con 3 filas de datos y 3 niños, la re-identificación es trivial. Por eso, por debajo de 5 alumnos el endpoint deja de dar datos individuales y solo devuelve agregados del grupo. El umbral k=5 sale de la guía de la AEPD."*

---

### 4.3 🗓️ Retención de datos (el worker nocturno)

**Qué es.** El principio de **limitación del plazo de conservación** (Art. 5.1.e) obliga a **no guardar los datos para siempre**. No basta con escribirlo en una política: lo implementamos como **código que corre solo cada noche**. Es la conexión directa entre una obligación legal y la ingeniería.

**Quién lo ejecuta.** El **proceso worker** (ver [[Worker]]), separado del servidor de la API, mediante una tarea programada por cron a las **03:00 cada día** (cola `data-retention` en BullMQ). También se puede lanzar a mano con `npm run data:retention`, y en modo simulación con `--dry-run` (dice qué haría sin tocar nada).

**Qué hace, en tres acciones:**

1. **Anonimiza** las partidas (`GamePlay`) de **más de 12 meses**. Ojo — **anonimiza, no borra**: pone a `null` el identificador del jugador (`playerId`) y el UID de la tarjeta en cada evento (`events[].cardUid`). Se **conservan las métricas agregadas** (puntuación, precisión, tiempos), que al perder toda referencia personal ya son **dato anónimo** → fuera del RGPD (Considerando 26). El profesor puede seguir viendo tendencias históricas de su aula sin identificar a nadie. Se procesa **por lotes de 500** para no saturar Mongo, y es **idempotente** (re-anonimizar algo ya anónimo no hace nada).

2. **Borra** (esto sí, *hard delete* real y en cascada) los **estudiantes inactivos de más de 24 meses**: elimina el usuario, sus partidas y sus métricas materializadas en Redis. Es el ejercicio del **derecho de supresión** (Art. 17).

3. **Limpia** las alertas ya resueltas/descartadas de más de un año. Es mantenimiento operativo, **no** afecta a PII.

**Auto-vigilancia:** además, un detector de sistema (`data_retention_lag`) comprueba que ese cron **no se retrase**. Si la retención lleva demasiado sin ejecutarse, salta una alerta al super_admin. Es cumplimiento **auto-monitorizado**.

**Frase para la defensa:** *"La retención no es una promesa escrita: es un cron nocturno que anonimiza las partidas de más de 12 meses y borra a los alumnos inactivos de más de 24. Y no me limito a confiar en que corra: hay un detector que vigila que ese trabajo no se retrase."*

---

### 4.4 El resto del panorama (más breve)

Además de las tres estrellas, el eje de protección de datos incluye:

- **Consentimiento parental verificable** (Art. 8): cada alumno tiene un objeto `consent` con quién lo otorgó, cuándo, para qué finalidades, IP y user-agent, más un **historial** completo de otorgamientos/revocaciones. Sin consentimiento, **la API no deja crear al alumno**.
- **Derecho de oposición granular** (Art. 21): el consentimiento distingue `educational_tracking` (jugar) de `performance_analytics` (perfilado). El tutor puede **oponerse a la analítica sin impedir que el niño juegue**. Un alumno con el consentimiento de analítica retirado **se excluye** de todas las consultas y de las alertas (con defensa en profundidad: se filtra en la consulta y otra vez en código).
- **Borrado efectivo bajo demanda** (Art. 17): endpoint `DELETE /api/users/:id/data`, solo super_admin, con confirmación explícita y cascada completa. Se envuelve en una **transacción** (ADR-224) para que un fallo a medias no deje PII huérfana re-identificable.
- **Portabilidad** (Art. 20): endpoint de exportación que devuelve todos los datos del alumno en **JSON estructurado**.
- **Filtrado de PII hacia fuera:** en los **logs** (Pino redacta contraseñas, tokens, cookies… y trata `classroom` como sensible) y hacia **Sentry** (un filtro `beforeSend` borra nombre, aula y demás antes de enviar el error a un servicio externo en EE.UU.).
- **RBAC y ownership:** cada profesor solo accede a **sus** alumnos; las operaciones RGPD están **centralizadas en super_admin** (imita a la dirección del centro como responsable del tratamiento).
- **Documentación legal:** hay **RAT** (7 actividades de tratamiento, Art. 30) y **EIPD** (12 riesgos identificados y mitigados, Art. 35), más un protocolo de **notificación de brechas** en 72 horas.
- **Auditoría automatizada:** `npm run data:audit` revisa el estado de la PII (que no queden fechas de nacimiento, que todos tengan consentimiento…) y sirve de red contra regresiones.

---

## 5. Cosas interesantes / decisiones que lucen en la defensa

**Privacy by design de verdad, no de boquilla.** La protección no se añadió al final: moldeó el modelo de datos (sin contraseña ni fecha de nacimiento para alumnos), la capa de analítica (pseudoIds + k-anonimidad) y hasta la configuración de servicios externos (filtro de Sentry). Es un **requisito de primera clase**, no un parche.

**Cumplimiento como código, verificable.** Casi todo tiene su contraparte ejecutable: la retención es un cron, el consentimiento es una validación que bloquea la creación, la k-anonimidad es un umbral en el endpoint, y hay **scripts de auditoría** (`data:audit`, `data:retention:dry-run`) que lo comprueban. Un tribunal puede pedir "enséñame dónde" y hay un archivo que enseñar.

**Defensa en profundidad.** El consentimiento se comprueba al **crear** al alumno y otra vez al **crear cada partida**. La exclusión de la analítica se aplica en la **consulta a BD** y de nuevo en **código**. La seudonimización va acompañada de **k-anonimidad** para el caso en que el seudónimo no basta. Ninguna medida va sola.

**HMAC en lugar de hash simple.** Es un detalle pequeño pero revelador: entender que un hash sin clave de un ObjectId enumerable es reversible, y elegir HMAC con clave, demuestra que la seudonimización se pensó como **medida de seguridad**, no como un maquillaje.

**Honestidad sobre los límites.** El propio análisis reconoce que "la anonimización absoluta no existe" (AEPD) y que la k-anonimidad **no protege frente al profesor** (que conoce a sus alumnos de vista), sino frente a terceros. Reconocer el riesgo residual es más sólido que fingir que es cero.

---

## 6. Preguntas típicas y respuesta rápida

- **"¿Diferencia entre anonimizar y seudonimizar?"** → La reversibilidad. Seudonimizar = cambiar el id por un código reversible con info aparte (sigue siendo dato personal); usado en logs y analítica. Anonimizar = romper el vínculo para siempre (deja de ser dato personal, Cons. 26); usado en la retención de partidas viejas.
- **"¿Por qué HMAC y no un hash normal para el pseudoId?"** → Porque los ObjectIds son enumerables: un hash sin clave se rompe por fuerza bruta desde los logs. El HMAC con clave secreta lo impide.
- **"¿Cómo vuelve el profesor del pseudoId al nombre?"** → No invierte el hash (imposible): consulta la base de datos por un endpoint autorizado. La info para revertir está separada, como pide el Art. 4.5.
- **"¿Qué es la k-anonimidad y qué k usáis?"** → k=5. Por debajo de 5 alumnos en un grupo, la analítica solo devuelve agregados, nunca datos individuales. El umbral sale de la guía de la AEPD (2019).
- **"¿La k-anonimidad protege del profesor?"** → No, y es a propósito: el profesor ya conoce a sus alumnos. Protege frente a terceros (pantalla compartida, robo de token).
- **"¿Cómo cumplís la retención del RGPD?"** → Un cron nocturno (03:00) en el worker: anonimiza partidas de +12 meses y borra alumnos inactivos de +24. Más un detector que vigila que no se retrase.
- **"¿Borráis o anonimizáis las partidas viejas?"** → Anonimizamos (playerId y UID a null, métricas agregadas se quedan). El borrado real es solo para alumnos inactivos de +24 meses.
- **"¿Y si un padre retira el consentimiento?"** → Puede retirar solo la analítica (el niño sigue jugando) o todo. El alumno se excluye de analítica y alertas, y se puede pedir el borrado efectivo.

---

## 7. ⚠️ Para no exagerar en la defensa (los "por si acaso")

Seis precisiones donde conviene ser exacto si el tribunal pincha:

1. **La seudonimización es HMAC-SHA256 con clave, truncado a 16 hex (64 bits)** — no un "SHA-256 truncado a 8 caracteres" (eso lo dice documentación antigua; el código evolucionó). Si citas la cifra, di 16 hex / HMAC con clave.
2. **Logs y analítica van seudonimizados, no anonimizados.** Son reversibles y **siguen siendo datos personales** bajo el RGPD. No los llames "anónimos".
3. **La k-anonimidad aquí es un umbral de agregación en el endpoint**, no un algoritmo formal de generalización/supresión sobre todo el dataset (no es Sweeney completo). Es una salvaguarda pragmática y honesta: por debajo de k, agrega; por encima, individualiza.
4. **Dos borrados distintos:** el borrado bajo demanda del super_admin (endpoint) **sí** va en una transacción atómica (ADR-224). El borrado automático de inactivos en la retención hace `deleteMany` secuencial (partidas, luego usuarios) **sin** transacción, y la purga de Redis es *best-effort* (si falla, no bloquea; se limpia en la reconciliación nocturna). No afirmes que "todo el borrado es transaccional".
5. **La retención anonimiza las partidas, no las borra.** Solo se borran de verdad los alumnos inactivos de +24 meses (con su cascada).
6. **Riesgo residual reconocido:** la k-anonimidad no protege frente al profesor, y "la anonimización absoluta no existe" (AEPD). La postura correcta es que el riesgo está **mitigado a nivel bajo**, no eliminado. En la EIPD, 11 de 12 riesgos quedan en "Bajo" y 1 (perfilado inadvertido) en "Medio", inherente a cualquier seguimiento pedagógico.

---

## Enlaces relacionados

- [[Worker]] — el proceso que **ejecuta** la retención nocturna y las alertas seudonimizadas.
- [[Redis]] — los TTL que limpian tokens/bloqueos solos, y dónde viven las métricas materializadas que la retención purga.
