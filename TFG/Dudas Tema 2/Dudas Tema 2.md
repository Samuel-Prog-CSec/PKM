# ¿Qué es RFID y cómo funciona?
**RFID = Radio Frequency Identification** (identificación por radiofrecuencia). Es una tecnología para identificar un objeto a distancia, sin contacto y sin cables, usando ondas de radio.

Hay dos piezas:

- La etiqueta (tag/tarjeta): en vuestro caso, las tarjetas MIFARE. Dentro tienen un chip diminuto y una antena (una espiral de cobre). Lo clave: son pasivas, no tienen pila.
- El lector: vuestro módulo RC522. Está siempre emitiendo un campo de radio a 13,56 MHz.

Cómo funciona el "truco de la magia" (sin pila):
1. El lector emite un campo electromagnético constante.
2. Cuando acercas la tarjeta (a 1-3 cm, según vuestra doc), ese campo induce corriente en la antena de la tarjeta —igual que una carga inalámbrica de móvil, pero en miniatura—. Esa energía "despierta" el chip.
3. El chip, ya alimentado, responde por radio enviando su UID (su número de identificación único).
4. El lector capta esa respuesta y ya sabe qué tarjeta es.

En vuestro proyecto solo interesa el UID (el "DNI" de la tarjeta), no lo que hay guardado dentro. Cada concepto educativo (ej: "España", "un triángulo") se asocia a un UID, y cuando el alumno acerca esa tarjeta, el sistema sabe qué respuesta ha dado. Lo ves en el firmware real (main.cpp), que lee el UID y lo manda en JSON:

`{"event":"card_detected","uid":"32B8FA05","type":"MIFARE 1KB","size":4,"counter":1287,"hmac":"..."}`



---


# ¿Qué es NFC y cómo funciona?
**NFC = Near Field Communication** (comunicación de campo cercano). Y aquí viene el matiz importantísimo para tu defensa:

▎ NFC no es algo totalmente distinto de RFID: **NFC es un caso particular** (una "rama" moderna) de RFID. Concretamente, NFC funciona en la misma frecuencia que usáis vosotros: 13,56 MHz.

O sea, técnicamente tus tarjetas MIFARE a 13,56 MHz caen dentro de la banda de NFC. Por eso en tu propia memoria (índice §2.2) se agrupan juntos: "Fundamentos de RFID (HF 13,56 MHz, MIFARE, NFC)".

**¿Qué añade NFC sobre el RFID "clásico"?** Dos cosas:

1. Distancia muy corta (unos ~4 cm, de ahí lo de "campo cercano"), pensada como medida de seguridad (para pagar con el móvil, por ejemplo).
2. **Comunicación en dos sentidos** (peer-to-peer): dos dispositivos NFC pueden hablar entre ellos e intercambiar datos, no solo "leer un número". Por eso funciona el pago con móvil, emparejar auriculares, etc. Un lector RFID clásico solo "lee"; NFC además puede "conversar".

Resumiendo el matiz que debes tener claro:

- RFID clásico = un lector fijo lee la identidad de una etiqueta pasiva. Relación "amo-esclavo".
- NFC = evolución de ese mismo RFID de 13,56 MHz, con alcance más corto y capacidad de diálogo bidireccional, típicamente entre móviles/dispositivos.

---

# ¿Qué es gamificación?
Gamificación = coger una actividad que no es un juego (aprender geografía, matemáticas...) y aplicarle mecánicas de videojuego para que sea más motivadora y divertida.

No es "convertir el temario en un videojuego" literalmente, sino añadir los ingredientes que enganchan de los juegos:

- Puntos: en tu proyecto, +10 por acierto, -2 por error (lo tienes en el RFID\_Protocol.md).
- Rondas y desafíos: la partida va lanzando retos (new\_round) uno tras otro.
- Retroalimentación inmediata: aciertas/fallas y lo ves al instante (validation\_result), con feedback visual (confetti, la mascota, etc.).
- Puntuación final y récord: al acabar (game\_over), hay marcador.
- Interacción física: el gesto de "coger la tarjeta correcta y acercarla" es más lúdico y tangible que marcar una casilla con el ratón.

La idea de fondo de tu TFG: un niño aprende mejor jugando. En lugar de un test aburrido en pantalla, el profe monta una "partida" donde los alumnos responden con tarjetas físicas de verdad. Eso es gamificación: el aprendizaje disfrazado de juego, con la motivación de un juego real.

---

# ¿Cómo funiona la Web Serial API en nuetro proyecto?
El sensor RFID se conecta por USB. Al principio el que leía el USB era el servidor. Pero vuestro servidor vive en la nube (VPS), y en la nube no hay un puerto USB donde enchufar el sensor. Callejón sin salida.

**La solución elegante**: que el navegador del profesor lea el USB directamente, usando la Web Serial API (una capacidad moderna de Chrome/Edge que **permite a una página web hablar con dispositivos conectados por puerto serie/USB, con permiso del usuario**).

Concretamente, lo que hace el código del navegador (webSerialService.js):

1. Abre el puerto USB (el profe pulsa "Conectar" y da permiso — el navegador siempre pide permiso, es una medida de seguridad).
2. Lee las líneas JSON que escupe el ESP8266 y las va juntando en un buffer hasta el salto de línea \\n.
3. Normaliza cada evento a un formato estable (por ejemplo, "MIFARE Classic 1K" del firmware lo convierte a MIFARE\_1KB; valida que el UID sea hex de 8 o 14 caracteres).
4. Deduplica: si acercas la misma tarjeta dos veces en menos de 1,2 segundos, ignora la repetición (evita lecturas fantasma).
5. Reenvía al backend por Socket.IO con el evento rfid\_scan\_from\_client. Y si en ese momento no hay conexión, encola el escaneo (hasta 200, con caducidad de 30s) y lo manda al reconectar.

Detalles finos que suman puntos si te preguntan:
- **Reconexión automática con reintentos** (1s, 2s, 4s) si el puerto se cae.
- **El navegador NO valida la firma HMAC ni conoce el secreto**: solo reenvía el counter y el hmac que ya vienen del firmware. La verificación la hace solo el backend (buen diseño de seguridad: el secreto nunca pisa el navegador).
- Requiere HTTPS (salvo en localhost) y solo funciona en Chrome/Edge. Es la limitación conocida, y la asumís conscientemente.

La frase de venta para el tribunal: "Movimos la lectura del USB del servidor al navegador del profesor. Así el backend puede vivir en la nube y escalar por aula, sin depender de hardware físico enchufado al servidor."

---

# ¿Cómo funcionan las tarjetas MIFARE (las que usáis)?
MIFARE es una familia de tarjetas RFID sin contacto de 13,56 MHz, fabricadas por NXP. Son las tarjetas del transporte público, hoteles, etc. Vosotros usáis principalmente MIFARE Classic 1K.

Físicamente, ya lo dijimos: chip + antena de cobre, sin pila, se alimentan del campo del lector.

Por dentro tienen dos cosas relevantes:

1. El UID (Unique Identifier): un número de fábrica que identifica la tarjeta. En las Classic 1K es de 4 bytes → 8 caracteres hexadecimales (ej: 32B8FA05). Otras (NTAG/Ultralight) tienen 7 bytes → 14 caracteres. Esto es lo único que vuestro proyecto usa.
2. Una memoria (1 KB en la Classic 1K) dividida en sectores, donde se podrían guardar datos cifrados. Vosotros NO la usáis.

Y aquí hay un punto que tu memoria menciona y que es oro para la defensa (la parte de seguridad, §6): la MIFARE Classic usa un cifrado propio llamado Crypto-1 que está roto desde hace años (se puede clonar/crackear). ¿Por qué a vosotros no os afecta demasiado? Porque:

- No confiáis en la memoria cifrada de la tarjeta. Solo leéis el UID, que es como leer un número escrito en la tarjeta.
- Un UID se puede clonar (alguien podría fabricar una tarjeta con el mismo número). Por eso no os quedáis solo con eso: añadisteis vuestra propia capa de seguridad en el lector, la firma HMAC (main.cpp): 
	- `hmac = HMAC-SHA256(secreto, UID\_EN\_MAYÚSCULAS + ":" + counter)`
- Es decir: el firmware firma cada lectura con un secreto que solo conocen el sensor y el backend, más un contador que siempre sube (counter, guardado en la EEPROM del chip). Así el backend puede comprobar dos cosas:
	- Autenticidad: la lectura viene de un sensor real que tiene el secreto (no de alguien inventándose UIDs).
	- Anti-replay: como el contador siempre crece, nadie puede "grabar" una lectura buena y reproducirla después (el backend rechaza un contador repetido o menor → COUNTER_REPLAY).

Cómo lee la tarjeta el firmware (resumido de main.cpp):

1. El RC522 detecta que hay una tarjeta nueva en el campo (PICC\_IsNewCardPresent).
2. Lee su UID (PICC\_ReadCardSerial), con hasta 3 reintentos porque vuestro módulo es un clon barato (HW-126) algo caprichoso.
3. Pasa el UID a mayúsculas, le suma 1 al contador, calcula la firma HMAC y lo manda todo por USB en JSON.
4. Si la tarjeta es un clon raro que la librería estándar no entiende, hay un fallback de "anticolisión cruda" (reconstruye el UID a mano y verifica el byte de control BCC). Detalle muy bueno de ingeniería defensiva, porque el firmware es del tutor y no lo podéis cambiar libremente.

---

# ¿Por qué usáis RFID y no NFC?
Esta es la pregunta con más trampa, porque —como vimos en el punto 2— vuestras tarjetas a 13,56 MHz están técnicamente dentro de la banda de NFC. Así que la respuesta honesta y elegante NO es "RFID es mejor que NFC", sino:

▎ Usamos el enfoque RFID clásico (lector dedicado que lee la identidad de tarjetas pasivas) en lugar del enfoque NFC (tocar con el móvil e intercambiar datos), aunque ambos compartan la misma frecuencia física.

Las razones concretas, aterrizadas a tu proyecto:

1. No necesitáis móviles. El enfoque NFC "de verdad" (tap con el móvil) obligaría a que cada alumno tenga un smartphone con NFC. En un aula de primaria eso es inviable (y poco deseable: niños + móviles en clase = problema). Con RFID basta un lector barato (RC522, \~1-2 €) y tarjetas baratas para todos.
2. Solo os hace falta identidad, no diálogo. NFC brilla cuando dos dispositivos intercambian datos (pagar, emparejar). Vosotros solo necesitáis saber "¿qué tarjeta ha tocado el alumno?" → el UID. Para eso, el RFID clásico es más simple y robusto: menos cosas que puedan fallar.
3. Encaja con la Web Serial API y los portátiles del tribunal. Vuestro lector se conecta por USB al PC del profesor y el navegador lo lee con Web Serial. Es la pieza que hace todo el sistema desplegable en la nube. NFC-por-móvil rompería ese modelo (necesitarías apps móviles, permisos NFC del sistema operativo, etc.).
4. El gesto físico es parte de la gamificación. "Coge la tarjeta correcta de la mesa y acércala al lector" es una interacción táctil y lúdica ideal para niños. Es el corazón del juego, no un simple login.
5. Coste y disponibilidad. RC522 + MIFARE Classic es el estándar de facto en proyectos educativos/maker: baratísimo, documentadísimo y compatible con el ESP8266 que os dio el tutor.

Frase de cierre para la defensa: "En realidad trabajamos en la frecuencia de NFC (13,56 MHz), pero adoptamos el paradigma RFID de lector fijo + tarjeta pasiva porque solo necesitamos identificar la tarjeta, queremos coste mínimo, no depender de smartphones, y que el gesto físico de acercar la tarjeta sea la mecánica del juego."