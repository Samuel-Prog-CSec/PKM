# Preguntas TFG — Guión de defensa

> Guión para el turno de preguntas del tribunal. Escrito en primera persona, tal y como lo respondería en la defensa: claro y conciso. No es para memorizar palabra por palabra, sino una guía de qué decir y con qué datos apoyarme.
>
> Varias preguntas parten de una cifra o premisa inexacta; en esas respuestas empiezo corrigiéndola con el dato real (p. ej. el latido del firmware es cada 10 s y no 20; el refresh token dura 7 días; el volcado del contador a EEPROM es por conteo —cada 100 lecturas—, no por tiempo; el bloqueo por rate limit es por identidad de docente, no por IP; el `stop_grace_period` de Docker es 30 s y el watchdog interno de la app 25 s).


---

## Bloque 1: Motivación, Estado del Arte e Innovación

### 1. ¿Por qué elegiste la tecnología RFID en lugar de otras opciones como visión artificial o pantallas táctiles para la interacción tangible?

Elegí RFID porque es la interacción más sencilla imaginable para un niño de cuatro años: un solo gesto, acercar la tarjeta, sin línea de visión ni lectoescritura. La visión artificial la descarté por tres motivos: exige cámara y buena iluminación, es más pesada computacionalmente y, sobre todo, filmar a menores plantea un problema serio de privacidad que quería evitar. Las pantallas táctiles reproducen justo la barrera que combato: requieren motricidad fina y saber dónde tocar. La tarjeta RFID, en cambio, es pasiva, robusta, identifica de forma unívoca y cuesta menos de cincuenta céntimos, con un lector por debajo de cinco euros. Además, es especialmente inclusiva para alumnos con necesidades especiales. Coste marginal despreciable y máxima tangibilidad.

### 2. En tu comparativa, mencionas que plataformas como Kahoot! requieren lectoescritura. ¿Cómo garantiza Eduplay que un niño de 4 años pueda jugar de forma autónoma?

La garantía está en el diseño de roles: el niño no tiene cuenta, ni pantalla, ni menús. Su única interfaz es la tarjeta física. Toda la complejidad la conduce el docente desde la web; el alumno solo acerca la tarjeta al lector. No hay nada que leer ni dónde hacer clic: la tarjeta lleva una imagen o un objeto, no texto, y el niño asocia lo que ve. El sistema responde con retroalimentación visual, sonora y emocional en menos de cincuenta milisegundos, con una mascota que acompaña y un lenguaje no punitivo calibrado por edad. Esa inmediatez hace que el niño perciba que es la propia tarjeta la que provoca la reacción. La autonomía nace de reducir la interacción a un gesto físico.

### 3. ¿Cuál consideras que es la principal innovación técnica de tu proyecto respecto a soluciones como Plickers o BlockMagic?

La principal innovación es leer el hardware directamente en el navegador del docente mediante la Web Serial API, sin que el servidor toque el sensor. Eso invierte la arquitectura IoT clásica: cada aula es un nodo independiente con su lector local, mientras la plataforma vive entera en la nube. Plickers usa la cámara del móvil del docente; BlockMagic emplea RFID pero atado a un PC local y hardware propietario, sin nube ni catálogo de mecánicas. Ninguno combina lo que sí ofrece Eduplay: interacción tangible RFID para cuatro a ocho años, despliegue en la nube, mecánicas intercambiables sobre un mismo motor mediante el patrón Strategy, analítica completa para el docente y protección de datos de menores. Esa celda vacía es el hueco que ocupo.

### 4. Mencionas el paradigma de "Tangible User Interface" (TUI). ¿Cómo afecta este modelo a los requisitos de latencia del sistema?

El modelo tangible sube mucho el listón de la latencia. Cuando el niño manipula un objeto real, espera que el mundo responda como responde la física: al instante. Si el feedback tarda, se rompe la ilusión de que la tarjeta causa la reacción y el objeto vuelve a sentirse desconectado de la pantalla. Por eso fijé un presupuesto perceptivo estricto: la retroalimentación visual y sonora debe aparecer en menos de cincuenta milisegundos, por debajo del umbral clásico de percepción de instantaneidad. La arquitectura lo permite porque el escaneo se lee localmente en el navegador, así que puedo pintar el feedback de inmediato en el cliente mientras la validación de autoría y puntuación viaja por Socket.IO. La tangibilidad convierte la latencia baja en un requisito, no en un lujo.

### 5. ¿Qué carencias específicas de las plataformas educativas actuales para el rango de 4-8 años pretende resolver Eduplay?

Detecté cuatro carencias. La primera, que casi todas las plataformas asumen lectoescritura y manejo de pantallas, competencias que un niño de cuatro a ocho años aún está desarrollando. La segunda, la ausencia de interacción física: los pequeños aprenden tocando y manipulando, y las interfaces de pantalla les son ajenas. La tercera, la carga que soporta el docente para seguir el progreso individual, hoy a base de observación y anotaciones manuales que no escalan en un aula de veinticinco niños. Y la cuarta, la barrera económica y de inclusión. Eduplay ocupa esa celda que ninguna solución cubre a la vez: RFID tangible sin lectoescritura, desplegable en la nube, con analítica automática que devuelve al docente indicadores objetivos y tiempo para atender a los niños.


---

## Bloque 2: Metodología y Planificación

### 6. Has adaptado Scrum para un proyecto individual. ¿Cómo gestionaste los roles de Product Owner y Scrum Master para evitar sesgos?

En un equipo unipersonal asumo todas las responsabilidades, así que el riesgo de sesgo es real: ser tu propio Product Owner tiende a justificar tus propias decisiones. Lo mitigué de dos formas. Primero, situando al tutor como Product Owner externo y stakeholder: validaba el avance en cada revisión de sprint frente a los objetivos comprometidos, lo que introduce una mirada de fuera. Segundo, externalizando el backlog y las prioridades en un tablero público de GitHub, con issues trazables, prioridad y tamaño, en lugar de llevarlo en la cabeza; y con retrospectivas escritas al cerrar cada versión. El rol de Scrum Master no lo mantuve como figura: en solitario era pura sobrecarga ceremonial, y lo sustituí por disciplina personal documentada. La trazabilidad pública es el antídoto contra el autoengaño.

### 7. En el Sprint 2 decidiste priorizar la deuda técnica. ¿Qué indicadores técnicos te llevaron a tomar esa decisión en lugar de avanzar en gameplay?

La retrospectiva del primer sprint dejó tres indicadores que no podía ignorar. Uno, la suite de tests tenía fallos no detectados y zonas del código sin cobertura alguna, apenas un treinta y uno por ciento. Dos, y más grave, el estado vivía en la memoria del proceso: la lista de tokens revocados y las partidas activas se perdían con cada reinicio, lo que permitía reutilizar un token ya revocado. Eso no es deuda estética, es un agujero de seguridad. Y tres, la lectura RFID dependía del puerto USB del servidor, incompatible con el despliegue en la nube. Avanzar en gameplay sobre esos cimientos habría multiplicado el problema. Consolidar primero fue lo correcto: la migración a Redis sentó además las bases del bloqueo distribuido posterior.

### 8. ¿Cómo afectó la migración a una infraestructura autoalojada (VPS) a la planificación original de tus sprints?

Sorprendentemente poco a la planificación en sí, porque la migración llegó después de etiquetar la versión estable, cuando Koyeb retiró su capa gratuita antes del primer despliegue real. No reordenó los seis sprints; cayó en la ventana posterior de estabilización. Y precisamente ahí se vio el valor de haber trabajado con infraestructura como código y observabilidad desde antes: el sistema absorbió el cambio de proveedor sin reescribir una línea de lógica de negocio. El único ajuste técnico de fondo fue convertir MongoDB en un conjunto de réplicas de un nodo con autenticación siempre activa, porque las operaciones atómicas multidocumento que el código ya daba por hechas se degradaban en silencio a escrituras no atómicas sin él. Fue un cambio de infraestructura, no de producto.

### 9. De los 92 requisitos funcionales identificados, ¿hubo alguno que tuviera que ser descartado o modificado sustancialmente por limitaciones técnicas?

Puntualizo el dato: son noventa y dos requisitos funcionales más setenta y ocho no funcionales, ciento setenta en total. Ninguno funcional se descartó por completo en la versión estable, pero dos se remodelaron a fondo. El más claro: eliminé la entidad Tarjeta como objeto con ciclo de vida propio y pasé a tratar las tarjetas como fichas fungibles, mapeando los identificadores directamente en los mazos. La realidad de unas tarjetas baratas e intercambiables no encajaba con obligar al docente a registrarlas. El segundo: el escalado horizontal del gameplay lo reencuadré a una única instancia, porque para un centro no aporta valor; dejé la infraestructura de coordinación lista pero desactivada. Y varias líneas, como integración con Moodle o modo offline, quedaron fuera de alcance como continuidad futura.

### 10. Si hubieras tenido un equipo de tres personas, ¿qué funcionalidades prioritarias habrías incluido que no pudiste abordar solo?

Con tres personas repartiría el trabajo por perfiles y atacaría lo que hoy son mis líneas futuras prioritarias. La primera y más valiosa: una validación pedagógica empírica en un aula real, un estudio cuasi-experimental sobre motivación y detección temprana de dificultades, que exige acuerdo con un centro y una mirada pedagógica. La segunda: integración con los ecosistemas del aula, inicio de sesión federado y conectores con Moodle o Google Classroom, para reducir la fricción de adopción. La tercera: ampliar el hardware, con varios lectores simultáneos y salto a NFC con escritura, más un modo offline como aplicación web progresiva. Yo prioricé el núcleo tangible, el motor y la analítica porque son el corazón del proyecto; lo demás es superficie que un equipo habría cubierto en paralelo.


---

## Bloque 3: Arquitectura y Backend

### 11. Utilizas el patrón Strategy para las mecánicas. ¿Qué pasos exactos daría un desarrollador para añadir una cuarta mecánica sin tocar el núcleo?

Cuatro pasos, ninguno toca el motor. Primero, creo una clase que hereda del contrato base de estrategia e implemento el método que selecciona el reto de cada ronda; opcionalmente el que procesa el escaneo y el que lleva el bookkeeping de métricas. Segundo, la registro en el índice de estrategias por su nombre. Tercero, añado ese nombre al enum de tipo de mecánica y a los validadores, más un constructor de resumen final si tiene métricas propias. Cuarto, la pantalla de juego en el frontend. El GameEngine nunca cambia: resuelve la estrategia por nombre y la usa de forma polimórfica. Solo hay que respetar el contrato de ronda por turnos; una mecánica que encaje ahí entra limpia.

### 12. ¿Por qué elegiste Redis para el estado distribuido en lugar de confiar únicamente en la memoria de Node.js o en MongoDB?

No es "todo en Redis": uso tres capas por motivos distintos. El estado vivo de la ronda (reto actual, temporizadores) vive en la memoria del proceso Node, porque el feedback debe llegar en menos de 50 ms y un salto de red a Redis por cada escaneo se comería ese presupuesto. MongoDB es el sistema de registro duradero: estados terminales, eventos y métricas finales; demasiado lento y pesado en escritura para el estado por escaneo. Redis es la capa de coordinación para lo que debe ser atómico, compartido y con caducidad: locks distribuidos de tarjetas con Lua, blacklist de tokens, rate limiting, colas y caché. Memoria por latencia, Mongo por durabilidad, Redis por atomicidad.

### 13. Explicas el uso de scripts Lua en Redis para el bloqueo de tarjetas. ¿Por qué es crítica la atomicidad en este punto?

Reservar las tarjetas de un mazo es una operación de varios pasos: comprobar que ninguna clave existe y solo entonces escribirlas todas. Si lo hago con comandos sueltos (un GET y luego un SET por tarjeta) hay una ventana de carrera: dos partidas pueden pasar la comprobación a la vez y reservar las mismas tarjetas, dejando un UID físico "doblemente reservado". El script Lua colapsa comprobar-y-escribir en una sola ejecución EVAL, y como Redis es monohilo, esa ejecución es indivisible: o reserva todas o ninguna, sin intercalado posible. Es reserva "todo o nada". Sumo liberación consciente del dueño y un TTL de 90 segundos, para que una caída no deje tarjetas bloqueadas para siempre.

### 14. ¿Cómo gestiona el backend una caída y reinicio repentino del servidor mientras hay 20 partidas en curso?

Con honestidad: el estado vivo de esas 20 partidas está en la memoria del proceso, no en Redis, así que una caída súbita lo pierde. No intento resucitarlas. Lo que mitiga el impacto: un checkpoint periódico a Mongo cada dos minutos o cada cinco respuestas persiste puntuación, ronda y eventos. Al rearrancar, una rutina de recuperación reconcilia: toda partida que siga "en curso" en Mongo se marca como abandonada, se registra un evento de reinicio, se recalcula el estado de la sesión y el cliente recibe un aviso que lo lleva a la pantalla final con la puntuación hasta el último checkpoint. En cierre controlado (un despliegue) sí las finalizo ordenadamente antes de salir. Nada se corrompe; el docente relanza.

### 15. Has implementado Socket.IO. ¿Qué ventajas te aportó sobre el uso de WebSockets nativos para la rehidratación de estado?

Socket.IO me dio reconexión automática con backoff, salas por partida, autenticación en el handshake y, lo clave para rehidratar, un modelo limpio de evento-respuesta. Cuando el cliente reconecta, emite una petición de sincronización (complementaria a unirse a la sala) y el servidor le responde con un snapshot completo del estado en memoria, o con un aviso de interrupción si la partida ya no existe. Con WebSockets nativos habría tenido que escribir a mano la reconexión, los latidos, el reparto por salas, el framing de mensajes y los acuses. Además, su adaptador Redis deja la puerta abierta a varias instancias sin reescribir nada. En la práctica, rehidratar se reduce a "vuelvo a la sala y pido el estado".

### 16. ¿Cómo evitas condiciones de carrera cuando dos alumnos intentan usar la misma tarjeta física en partidas distintas simultáneamente?

Con dos capas. En memoria, un índice UID→partida rechaza el solape localmente; pero la autoridad es la reserva atómica en Redis con Lua. Cada UID físico corresponde a una clave global; la primera partida que la reserva es su dueña durante 90 segundos, y la segunda recibe un conflicto y un error claro de "tarjeta en uso en otra partida": no arranca. Modelo mis tarjetas como fichas fungibles, no como objetos con propietario, así que el mismo UID puede reutilizarse en otra sesión, pero nunca a la vez. Como el EVAL es atómico, ni siquiera una concurrencia real, o una segunda instancia futura, podría doblar la reserva. Además, reclamo tarjetas de partidas muertas para no bloquear un reintento legítimo para siempre.

### 17. El límite de 500 eventos por partida en MongoDB se gestiona con $slice. ¿Por qué elegiste este límite y qué impacto tiene en la analítica de trayectorias?

El $push lleva un $slice negativo de 500, así que conservo los últimos 500 eventos por partida. Elegí acotarlo porque un array sin límite hace crecer el documento sin control, arriesgando el tope de 16 MB de Mongo e hinchando el working set; 500 cubre de sobra una partida real de aula, que son unas pocas decenas de rondas. Sobre la analítica de trayectorias el impacto es nulo en el caso real: todo cabe. Solo una partida patológica de horas descartaría sus eventos más antiguos. Y aun así, los contadores agregados (intentos, aciertos, errores, tiempos, puntuación) se mantienen con $inc de forma independiente al array, así que los KPIs siguen siendo exactos aunque se recorte la cola de eventos crudos.

### 18. ¿Por qué decidiste desnormalizar `mechanicType` en la entidad GameSession en lugar de hacer un JOIN virtual?

Porque está en el camino caliente. Cada escaneo, cada decisión de puntuación y el cálculo del máximo teórico necesitan saber la mecánica; resolver un populate o join virtual en cada operación añade un salto y latencia contra el presupuesto de 50 ms. Guardarlo como campo explícito, además, fija el tipo de juego de forma clara en lugar de inferirlo por la "huella" de los datos. El riesgo clásico de desnormalizar es la copia desactualizada, pero aquí no aplica: la mecánica de una sesión es inmutable, no se cambia a mitad. Y al estar indexado, las consultas de analítica filtran por mecánica muy baratas. Mantengo la referencia real por integridad; el tipo desnormalizado es la lectura rápida.


---

## Bloque 4: Frontend y UX

### 19. Implementas WCAG 2.2 nivel AA. ¿Qué medidas tomaste para que la interfaz sea accesible para docentes con discapacidad visual?

Trabajé el estándar como punto de partida, no como meta, y con foco en el docente, que es quien usa la interfaz administrativa. Para baja visión y ceguera tomé varias medidas: contraste recalculado de forma independiente en cada tema y verificado contra los umbrales AA; un indicador de foco grueso y de alto contraste que nunca se pierde al navegar con teclado; enlaces «ir al contenido» en cada layout; regiones ARIA en vivo que anuncian errores de formulario sin robar el foco; etiquetas semánticas en los selectores que combinan propósito y valor; y tarjetas clicables operables por teclado. Nada de información transmitida solo por color: la gravedad se distingue también por forma y etiqueta. Lo verifico con la suite automática más pasadas manuales con teclado y lector de pantalla.

### 20. El wizard utiliza el principio de revelación progresiva. ¿Cómo mediste que esto reduce la carga cognitiva frente a un formulario único?

Quiero ser honesto: no lo medí con un estudio empírico de carga cognitiva. No hice tests con docentes cronometrando ni comparando ambas versiones en aula; esa validación experimental la dejo explícita como línea futura en las conclusiones. La decisión se apoya en principios de interacción persona-ordenador bien asentados: la revelación progresiva, la ley de Hick (menos opciones por pantalla acortan la decisión) y las heurísticas de Nielsen, sobre todo reconocer antes que recordar y mantener visible el estado del sistema. Un formulario monolítico con mecánica, mazo, contexto y diez parámetros saturaría al maestro. El wizard presenta una decisión por pantalla, deja ir adelante y atrás sin perder contexto y muestra siempre el progreso. Es una decisión fundamentada, no una medición; presentarla como dato empírico sería faltar a la verdad.

### 21. ¿Cómo garantiza el diseño del tablero de Memoria que el alumno trabaje la posición y no marcas accidentales en las tarjetas?

El tablero de Memoria es una matriz de cartas boca abajo con un dorso común y un estilo visual deliberadamente neutro. Esa uniformidad es la clave: si cada dorso tuviera una textura, un desgaste o un artefacto de impresión distinto, el alumno podría reconocer la carta por esa marca en lugar de recordar dónde estaba, y entonces no estaría ejercitando la memoria de trabajo visual, que es exactamente la función cognitiva que la mecánica busca entrenar. Al hacer todos los dorsos indistinguibles, la única pista útil es la posición espacial. Lo complemento con detalles de motricidad: cada carta respeta el área táctil mínima y el tablero limita sus columnas según el ancho, sacrificando densidad antes que precisión, para que un niño impaciente no destape dos por error.

### 22. Has usado el modelo de color OKLCH. ¿Qué beneficios aporta sobre RGB para la mantenibilidad de los temas light/dark?

OKLCH es perceptualmente uniforme y, sobre todo, separa la luminosidad del tono y del croma. Eso me deja derivar los temas y los estados de interacción de forma predecible: fijo una luminosidad objetivo para un token y el contraste se comporta como espero en cualquier tono, algo que RGB o HSL no garantizan (una misma «lightness» de HSL se ve clarísima en amarillo y oscura en azul). En el sprint de deuda técnica migré unos ciento noventa y siete colores crudos de Tailwind a tokens semánticos OKLCH; a partir de ahí, claro y oscuro son dos paletas independientes que comparten el mismo contrato de tokens. Puedo razonar el contraste WCAG desde la diferencia de luminosidad, y ajustar un token (bajé el amarillo de aviso de 85 a 78 de luminosidad) corrige la legibilidad sin retocar cada componente a mano.

### 23. ¿Por qué decidiste incluir un respaldo táctil si el foco es la interacción tangible RFID?

Porque el hardware falla, y en un aula de infantil no puedo permitir que eso pare la clase. El lector se desconecta, el cable USB se afloja, hay interferencias o simplemente no está encendido cuando llega el turno del alumno. La respuesta convencional (mostrar un error y bloquear la actividad) es socialmente inaceptable: el niño no controla el cable, y culparle de un fallo técnico rompe la promesa de tratarlo como participante competente. El respaldo táctil continúa la partida ofreciendo el mismo tablero como botones que el alumno toca con el dedo, con la misma estética y ritmo, sin banner de «modo limitado». El RFID sigue siendo el protagonista pedagógico (acercar un cartón es un gesto que un niño de cuatro años ya domina); el táctil es la red de seguridad para que un fallo de hardware nunca se traduzca en un niño frustrado.

### 24. ¿Qué criterios de severidad seguiste para elegir los trece tipos de alertas inteligentes para el docente?

El catálogo tiene trece tipos con tres niveles de severidad: informativa, aviso y crítica. La severidad sale de dos ejes. Primero, la magnitud contra un umbral: por ejemplo, el rendimiento en descenso es aviso con una caída de diez puntos y crítico con veinte. Segundo, la persistencia temporal: una alerta que sigue activa y reaparece escala de aviso a crítica al cabo de una semana y varias ocurrencias, para que no escale por una lectura aislada. Los patrones positivos (mejora rápida, hito de dominio, recuperación tras un bache) son siempre informativos, porque celebran, no alarman. Los trece: rendimiento en descenso, inactividad, caída repentina de puntuación, timeouts consistentes, alto abandono, estancamiento, caída de implicación, dificultad específica por mecánica, mejora rápida, recuperación tras bache, hito de dominio y dos propias de Secuencia (estancamiento y errores de orden).

### 25. Mencionas Atomic Design en React. ¿Podrías dar un ejemplo de un "átomo" y un "organismo" dentro de tu dashboard?

Adapté el vocabulario de Brad Frost a cuatro capas: primitivos de interfaz, compuestos por dominio, layouts y páginas. Un átomo del dashboard sería una tarjeta de indicador (StatCard): icono, número animado y etiqueta; un primitivo sin conocimiento de dominio, que pruebo en aislamiento. Un organismo sería el panel de alertas del aula: compone muchos átomos (insignias de severidad, botones, iconos) y filas de alerta en una sección de dominio autónoma, con sus propios datos y ciclo de vida. Sobre esas capas hay tres contextos globales que las atraviesan: autenticación, registro de atajos y la conexión en tiempo real compartida. Cada capa tiene una regla de testabilidad explícita, y eso es justo lo que permite que la suite de frontend supere las quinientas pruebas sin tiempos de ejecución insostenibles.


---

## Bloque 5: Hardware e Integración IoT

### 26. La Web Serial API es clave. ¿Qué limitaciones de seguridad imponen los navegadores Chromium para acceder al puerto serie?

Son varias capas, todas para que una web no toque el hardware a escondidas. Primero, solo funciona en contexto seguro: HTTPS o localhost; en HTTP plano la API ni existe. Segundo, exige un gesto explícito del usuario: el puerto se abre tras un diálogo nativo donde el docente elige físicamente qué dispositivo autoriza, como el permiso de cámara. No puedo enumerar ni abrir puertos por mi cuenta; la concesión inicial siempre pasa por ese selector. Tercero, el permiso es por origen y por puerto, y el usuario puede revocarlo. Cuarto, está bloqueada desde iframes cross-origin. Y quinto, solo la implementan navegadores Chromium (Chrome, Edge, Opera); por eso ofrezco un respaldo táctil para quien use Firefox o Safari. Lo detallo en el Anexo D.

### 27. ¿Por qué la lectura del sensor se hace en el navegador del docente y no directamente desde el ESP8266 al servidor vía WiFi/MQTT?

Fue una decisión deliberada, sobre todo por seguridad y despliegue. Si el ESP hablara por WiFi necesitaría credenciales de la red del aula grabadas en el firmware, una IP alcanzable y probablemente un broker MQTT que mantener. Eso mete un dispositivo poco robusto dentro de la red del colegio y multiplica la superficie de ataque. Con Web Serial, el sensor es un periférico USB "tonto": no tiene red ni credenciales, solo escupe líneas por el puerto. El navegador del docente hace de intermediario y añade lo que el ESP no puede: deduplicación, cola offline y reenvío autenticado por Socket.IO. Y lo más importante, el backend queda libre de dependencia física del hardware, así puedo desplegarlo en un servidor remoto sin USB. Es la inversión que hace viable toda la arquitectura.

### 28. El lector MFRC522 es de bajo coste. ¿Qué problemas de precisión de lectura encontraste y cómo los mitigaste por software?

El MFRC522 barato, y sobre todo los clones, dan dos problemas: lecturas que fallan al primer intento y UIDs corruptos en tarjetas no estándar. Lo compensé en dos frentes. En el firmware, cada lectura del UID se reintenta hasta tres veces ante errores del bus, subí la ganancia de antena a 38 dB, y añadí un camino de anticolisión cruda con verificación del byte BCC para clones que no responden a la librería estándar. En el navegador valido que el UID tenga formato hexadecimal correcto —8 o 14 caracteres— y descarto los malformados antes de reenviarlos, precisamente porque ese camino de fallback no garantiza CRC. Así, un lector imperfecto no llega a contaminar las métricas del alumno. Está descrito en el Anexo D.

### 29. Explicas la persistencia diferida en la EEPROM del ESP8266. ¿Cómo alarga esto técnicamente la vida útil del hardware?

La clave es que las celdas de EEPROM del ESP8266 aguantan del orden de cien mil ciclos de escritura, y se degradan con cada escritura, no con las lecturas. El contador anti-replay se incrementa en cada tarjeta; si lo persistiera en cada escaneo, en un aula con uso intensivo agotaría esas celdas en pocas semanas. Lo que hago es persistir un "techo" diferido: solo escribo en EEPROM una vez cada cien escaneos, y en cada reinicio el firmware salta directamente al siguiente bloque de cien para cubrir el peor caso. Eso divide las escrituras por cien y multiplica por cien la vida de la flash, sin perder la monotonicidad estricta del contador, que es justo lo que sostiene la garantía anti-replay.

### 30. ¿Qué sucede si el lector RFID se desconecta físicamente en mitad de una ronda de juego según tu flujo de eventos?

El servicio Web Serial lo detecta de inmediato: el navegador dispara un evento de desconexión del puerto y se corta el bucle de lectura. Ahí marco el dispositivo como desconectado, aviso al docente en la interfaz e intento una reconexión automática con reintentos y backoff exponencial. Lo importante es que la partida no se corrompe: el estado vivo del juego vive en el backend, que es la única fuente de verdad, y el procesamiento de lecturas es idempotente. Si el docente reconecta el sensor, se rehidrata el estado y la ronda continúa donde estaba. Y si prefiere no perder el ritmo, tiene el respaldo táctil para seguir jugando sin lector. En ningún caso una desconexión física tumba la sesión.

### 31. ¿Cómo gestiona el sistema el "rebote" de lecturas cuando un niño deja la tarjeta demasiado tiempo apoyada?

Con dos capas. En el firmware, tras leer una tarjeta la "halteo" —le mando un HALT— y hago una pausa breve, así una tarjeta que se queda apoyada queda dormida y no se vuelve a leer hasta que se retira y se reacerca. En el navegador tengo además una deduplicación: si llega el mismo UID dentro de una ventana de aproximadamente 1,2 segundos, lo filtro localmente y no lo reenvío al servidor. Entre las dos, una tarjeta apoyada genera un único evento, no una ráfaga. Esto cubre el chattering típico del lector cuando el niño deja la carta sobre la antena, que es justo el caso pedagógico habitual con niños de cuatro a ocho años. El backend nunca ve el rebote.


---

## Bloque 6: Seguridad y Protección de Datos

### 32. El sistema aplica k-anonimidad (k=5). ¿Por qué es este umbral crítico para proteger la identidad de menores en aulas pequeñas?

La k-anonimidad garantiza que cualquier combinación de cuasi-identificadores (aula, edad) aparezca en al menos cinco registros; si no, no se puede señalar a un individuo. El problema en un aula pequeña es evidente: si una clase tiene tres o cuatro alumnos, mostrar filas "individuales" —aunque estén seudonimizadas— permite reidentificar al niño concreto, porque cualquiera sabe cuántos hay y quiénes son. Por eso, cuando el grupo consultado tiene menos de cinco alumnos, el sistema devuelve solo métricas agregadas y oculta los datos individuales, avisando de que se aplica esta protección. Adopté k=5 siguiendo la Guía básica de anonimización de la AEPD, que recomienda precisamente ese mínimo para datos sensibles. La pequeñez del aula no exime de anonimizar: la endurece.

### 33. ¿Cómo funciona técnicamente la firma HMAC con contador anti-replay en las lecturas enviadas por el puerto serie?

El firmware del lector comparte con el backend una clave precompartida de 256 bits, incrustada en el binario al compilar y que nunca viaja por el puerto serie. En cada lectura firma un HMAC-SHA256 sobre la concatenación del UID y un contador monótono (uid:counter) y emite ambos, contador y firma, en la trama JSON. El backend recalcula el HMAC con la misma clave y lo compara en tiempo constante para no filtrar información por temporización. Además guarda el último contador visto por cada sensor y rechaza toda lectura cuyo contador no sea estrictamente superior: eso neutraliza la reproducción de una lectura legítima capturada. Ambos rechazos se agrupan bajo un mismo código, RFID_HMAC_INVALID, distinguiendo internamente entre firma inválida y replay del contador. Es el patrón canónico HMAC más nonce monótono.

### 34. Has implementado MFA TOTP para administradores. ¿Por qué decidiste no incluirlo para los docentes estándar?

Fue un balance deliberado entre riesgo y fricción, guiado por la superficie de datos. El administrador —el Jefe de Estudios— tiene las llaves del centro: altas y bajas de alumnos, gestión del consentimiento parental, el borrado en cascada del derecho al olvido y el desbloqueo de cuentas. Es el privilegio máximo, así que ahí exijo TOTP y protejo las operaciones destructivas de RGPD tras un token MFA reciente. El docente, en cambio, solo ve a sus propios alumnos y crea mazos y sesiones; no gestiona el centro ni toca el consentimiento. La superficie que expondría una cuenta docente comprometida se limita a su aula, así que imponer TOTP en cada login diario añadiría una fricción desproporcionada a ese riesgo. Al docente lo protejo con bloqueo por intentos, rate limiting y refresh atado al dispositivo.

### 35. ¿Cómo garantizas técnicamente el borrado efectivo en cascada de los datos de un alumno en cumplimiento con el derecho al olvido?

El borrado se ejecuta de forma transaccional. Dentro de una única transacción atómica de MongoDB elimino el documento del alumno, todas sus partidas, los informes generados y las alertas asociadas; fuera de la transacción purgo su materialización en Redis, revoco sus tokens y desconecto sus sockets. La atomicidad exige un replica set —por eso MongoDB corre siempre como replica set, aunque sea de un solo nodo—; sin él las escrituras degradarían en silencio a no atómicas. La operación está triplemente protegida: solo el Jefe de Estudios, con confirmación explícita y con un token MFA reciente. El resultado es que no quedan datos residuales del alumno en ningún almacén, cumpliendo el Artículo 17. Es una operación distinta del archivado lógico ordinario, que es reversible.

### 36. En caso de brecha de seguridad, ¿qué protocolo de notificación has definido siguiendo el Artículo 33 del RGPD?

Definí un procedimiento de respuesta en cinco fases sobre el reloj de 72 horas. Detección en la hora cero, a través de Sentry, el logger de seguridad o alertas de infraestructura. Contención en las primeras cuatro horas: aislar, revocar credenciales con revocación global de tokens y preservar evidencia. Evaluación de impacto hasta la hora veinticuatro, con una regla dura: si hay datos de menores implicados, el riesgo es al menos alto y la notificación a la AEPD es obligatoria. Notificación a la AEPD entre las 24 y las 72 horas, con todos los campos del Artículo 33.3. Y comunicación a padres o tutores en lenguaje accesible cuando entrañe alto riesgo, conforme al Artículo 34. Tengo plantillas preparadas para ambas y toda brecha se documenta en un registro interno según el Artículo 33.5.

### 37. ¿Qué medidas de minimización de datos aplicaste específicamente al perfil del alumno (playerId)?

Apliqué minimización estricta desde el propio esquema. Del alumno guardo lo mínimo pedagógicamente útil: nombre, aula, un avatar y métricas de juego ya agregadas. Eliminé por completo la fecha de nacimiento del modelo —no almaceno birthdate de nadie— y la sustituí por una edad, que es un dato más grueso. El alumno no tiene credenciales: ni email ni contraseña; de hecho el modelo rechaza activamente que un estudiante los lleve. En la capa de analítica y en los logs no opero sobre el nombre real, sino sobre un identificador seudónimo derivado con HMAC-SHA256 y truncado. El identificador interno con que se referencian sus partidas es un valor opaco, no nominativo. Así separo la identidad del análisis y cumplo el principio de minimización del Artículo 5.1.c de forma demostrable.

### 38. ¿Cómo verificas técnicamente que el docente tiene el consentimiento parental antes de crear el alumno en el sistema?

Aquí quiero ser preciso y honesto. El sistema impone una puerta de consentimiento en tres capas: no se puede crear un alumno sin que el consentimiento esté marcado como otorgado y sin el nombre del tutor, y eso se valida en la frontera con Zod, en el modelo de datos y en el servicio. Ahora bien, esto es una atestación gestionada, no una verificación criptográfica. El sistema registra la metadata de responsabilidad proactiva —quién lo otorgó, cuándo, por qué canal, con IP y user-agent, versión de política y finalidades— para poder demostrarlo bajo el Artículo 7.1. La verificación real del formulario firmado es un control organizativo que custodia el centro, centralizado en el Jefe de Estudios. La plataforma aporta un registro verificable y trazable; no pretende probar técnicamente que un padre real firmó.

### 39. Utilizas cookies httpOnly para el refresh token. ¿Qué ataque específico (como XSS) estás mitigando con esto?

Mitigo el robo del refresh token mediante XSS. El refresh es el token de larga vida y, por tanto, el objetivo de mayor valor. Al guardarlo en una cookie httpOnly, ningún JavaScript que se ejecute en la página —incluido un payload inyectado por un XSS— puede leerlo con document.cookie, de modo que no puede exfiltrarlo. Es una defensa complementaria a la CSP estricta, que reduce la probabilidad de que el XSS llegue a ejecutarse: si la barrera de contención falla, la cookie httpOnly evita que el token salga. Le añado SameSite estricto, que reduce el envío en contextos cross-site, el atributo Secure en producción y una ruta acotada a /api/auth. Contra el flanco de peticiones de estado sigo usando el patrón CSRF de doble cookie. Son capas que se refuerzan entre sí.

### 40. ¿Por qué decidiste anonimizar las partidas a los 12 meses en lugar de borrarlas definitivamente?

Porque el valor pedagógico de una partida no está en saber de qué niño era, sino en el agregado. A los doce meses la utilidad de identificar el detalle granular cae, pero las métricas siguen sirviendo para entender qué mecánicas o contextos funcionan mejor. Así que rompo el vínculo con el alumno —anulo la referencia al jugador y los UID de tarjeta de cada evento— y conservo la métrica agregada, ya anónima. El Considerando 26 del RGPD deja los datos verdaderamente anónimos fuera del reglamento, con lo que puedo mantener ese corpus indefinidamente sin comprometer al menor. Borrarlo todo destruiría la base estadística que alimenta la analítica, y la anonimización además limpia la superficie expuesta ante una hipotética brecha. El borrado definitivo sí ocurre, pero para cuentas inactivas a los veinticuatro meses.


---

## Bloque 7: Infraestructura, Calidad y Resultados

### 41. Tu pipeline incluye OWASP ZAP. ¿Qué tipo de vulnerabilidades (ej. inyección, headers) buscabas detectar?

Uso el perfil *baseline* de ZAP, mensual contra el entorno de *staging*, no por cada commit. El baseline es sobre todo pasivo, así que lo que busca es higiene de exposición: cabeceras de seguridad ausentes o mal configuradas (CSP, HSTS, X-Content-Type-Options, anti-clickjacking), *flags* de las cookies (httpOnly, Secure, SameSite), fugas de información en banners o errores verbosos, CORS permisivo, contenido mixto y librerías JavaScript con CVE conocidos. Es un DAST que complementa al análisis estático del código: uno mira la app corriendo, el otro las fuentes. La inyección propiamente dicha (NoSQL, XSS) la ataco primero de forma defensiva con validación Zod, saneado de Mongoose y CSP de Helmet; ZAP es la red de seguridad. Un hallazgo de severidad alta abre automáticamente una incidencia.

### 42. ¿Cómo monitorizas la salud del sistema en producción (CPU, memoria, latencia) sin usar herramientas externas de pago?

Todo con capas gratuitas o autoalojadas. Sentry captura errores y transacciones de rendimiento en los flujos críticos, con un filtro `beforeSend` que borra datos personales antes de salir. Los logs estructurados de Pino se envían a Grafana Loki. UptimeRobot pincha desde fuera los endpoints de salud, que verifican conectividad real con MongoDB y Redis. Y, sobre todo, tengo detectores internos propios: alertas operativas para dirección que vigilan presión de memoria del heap (por encima del 85 y 95 por ciento), latencia de Redis, desconexión de Mongo y acumulación en las colas, evaluados cada pocos minutos. La latencia de las agregaciones pesadas se registra con un umbral de aviso antes de que MongoDB aborte. La CPU y memoria del host las veo a nivel de VPS directamente. Cero coste recurrente.

### 43. ¿Por qué seleccionaste MongoDB frente a una base de datos relacional para el almacenamiento de `metrics` y `events`?

Porque el dominio encaja en un almacén documental. Cada partida embebe un array de eventos de longitud variable (acotado a 500) y un objeto de métricas anidado que además difiere por mecánica: Asociación, Memoria y Secuencia tienen campos de KPI distintos. Modelar eso en relacional obliga a una tabla de eventos con *joins* en cada lectura y, para las métricas por mecánica, columnas dispersas o un patrón entidad-atributo-valor: rígido y lento para telemetría intensiva en escritura. Con MongoDB añado eventos de forma atómica con `$push`, `$inc` y `$slice` sobre un único documento, leo la partida entera sin *joins*, y evoluciono el esquema (una mecánica nueva son campos nuevos) sin migraciones. La analítica lo deriva todo de esos documentos con *pipelines* de agregación. Esquema flexible, documentos anidados y escritura rápida.

### 44. Si un centro quisiera escalar a 20 aulas, ¿qué costes recurrentes de servicios cloud tendría que asumir según tu estimación?

Matizo la premisa: ya no es cloud gestionado. Cuando Koyeb retiró su capa gratuita migré a una VPS autoalojada (Contabo), así que el coste recurrente es una cuota mensual fija de VPS, no un pago por uso. Y una sola VPS cubre el escenario objetivo: veinte aulas de un centro no juegan veinte partidas simultáneas. El lector RFID va por USB en el portátil del docente, las sesiones se escalonan y la concurrencia real es baja. Los servicios externos que quedan (Sentry, Loki, almacenamiento de assets, UptimeRobot) siguen en capa gratuita. Si de verdad hubiera que escalar más, esos rondarían unos 60 euros al mes en sus planes mínimos de pago, y la VPS pasaría a un plan Contabo mayor o a repartir el stack en una segunda máquina. El gasto se desplaza de lo recurrente a lo puntual del desarrollo.

### 45. ¿Qué métricas de cobertura de tests has alcanzado con Jest y Vitest y qué partes quedaron fuera?

La cobertura real medida en backend ronda el 72 por ciento, reportada con lcov a SonarCloud, sobre más de un centenar de ficheros de test con Jest y Supertest: controladores, servicios, repositorios, middlewares, validadores y utilidades, contra un MongoDB efímero. El umbral configurado es más conservador (65 por ciento en sentencias, funciones y líneas; 50 en ramas). En frontend, con Vitest, el umbral está en torno al 55 por ciento. Y soy honesto sobre lo que quedó fuera: los scripts Lua de los locks de Redis, que se ejecutan dentro de Redis y valido con tests de concurrencia en vez de unitarios; la integración con hardware real, porque el sensor físico está roto desde mayo y el flujo RFID se ejercita con un simulador y firma HMAC, no con el ESP8266; y los flujos E2E de navegador, que hago como QA manual con Playwright, no como dependencia de CI.


---

## Bloque 8: Conclusiones y Líneas Futuras

### 46. Si tuvieras que comercializar Eduplay, ¿cuál sería el mayor desafío técnico para convertirlo en un producto multitenant SaaS?

El mayor reto no es la interfaz ni el modelo de negocio: es que hoy el estado vivo de cada partida reside en la memoria del proceso Node, con la premisa de una única instancia. El motor de juego es stateful en memoria —las partidas activas y el mapeo de tarjetas—, y las sesiones de socket no se comparten entre instancias. Convertirlo en un SaaS multitenant obliga a dos cosas: externalizar ese estado a un almacén compartido, Redis, y garantizar aislamiento estricto de datos entre centros, para que ningún inquilino vea información de otro. Ya dejé cableada la coordinación entre instancias —adaptador de Socket.IO sobre Redis, locks distribuidos, invalidación de caché por pub/sub—, activable con un interruptor; pero migrar el estado del motor, añadir sesiones adherentes y particionar por inquilino es el trabajo de fondo.

### 47. Mencionas la inteligencia adaptativa. ¿Cómo podrías implementarla sin comprometer la privacidad del menor ni realizar perfilado prohibido?

La recojo como línea futura, y precisamente por tratarse de menores la planteo con cautela. La clave es separar adaptación de perfilado. Puedo ajustar la dificultad en tiempo real a partir del rendimiento de la propia sesión —aciertos, tiempos, errores— sin construir un perfil persistente del niño ni inferir rasgos suyos. Si llego a entrenar modelos, sería sobre el corpus agregado y seudonimizado que la plataforma ya acumula, sin reidentificación posible, respetando la minimización y la k-anonimidad. Y nunca una decisión automatizada con efecto sobre el alumno: el sistema aporta señales objetivas, pero el criterio pedagógico lo mantiene el docente, como exige el Reglamento europeo frente a decisiones plenamente automatizadas. Adaptar la experiencia sí; etiquetar o clasificar al menor, no.

### 48. ¿Cuál fue la lección aprendida más importante tras el Sprint 6 y el hardening de seguridad?

La lección más clara: la seguridad no puede ser una fase final. El último sprint concentró el endurecimiento —CSP estricta, MFA para administradores, firma del canal RFID, bloqueo por intentos fallidos—, pero pasó las auditorías formales sin reescribir módulos críticos precisamente porque la defensa en profundidad se había tejido desde el primer commit. La secuencia que aprendí es «instrumentar primero, endurecer después». Y una segunda, específica de trabajar con menores: demostrar el cumplimiento es parte del cumplimiento; la trazabilidad documental del Anexo C valió tanto como las defensas técnicas. Como refuerzo, tener la infraestructura como código y una buena observabilidad me permitió absorber una migración completa de proveedor —el proveedor cloud retiró su capa gratuita justo antes del despliegue real— sin tocar la lógica de negocio.

### 49. ¿Por qué consideras que el sistema está listo para ser validado empíricamente en aulas reales con grupos de control?

Quiero ser preciso: la validación empírica no está hecha, es una línea futura y así la recojo. Cuando digo que está «listo para» validarse me refiero a dos condiciones que sí se cumplen. Primera, estabilidad: la versión 1.0.0 cierra el alcance comprometido y es un sistema estable, no un prototipo. Segunda, y más importante, está instrumentado para capturar exactamente las métricas que un estudio con grupo de control necesitaría —participación, retención de aprendizajes, trayectorias individuales seudonimizadas y detección temprana de dificultades—, más un modo de demostración sin hardware que facilita entrar en el aula. Lo que falta es el estudio en sí: un diseño cuasi-experimental que exige un acuerdo con un centro y su marco de consentimiento. Esa parte queda como trabajo futuro.

### 50. De todos los ODS vinculados, ¿en cuál crees que Eduplay tiene un impacto técnico más directo y medible?

Sin duda el ODS 4, educación de calidad. Vinculo también el 9, el 10 y el 12 —innovación tecnológica, reducción de desigualdades por el bajo coste y reutilización de las tarjetas—, pero el 4 es el más directo y, sobre todo, el más medible. Y es medible por una razón técnica concreta: la plataforma ya instrumenta la analítica que cuantifica su propio impacto educativo. Registro participación, evolución del rendimiento, trayectorias por alumno y alertas tempranas de dificultad; son exactamente las señales con las que un centro podría demostrar mejora en los procesos de enseñanza y aprendizaje. Los otros ODS se sostienen de forma más cualitativa —una arquitectura novedosa, un coste asequible—; el 4 se puede defender con datos que el sistema captura de serie.


---

## Bloque 9: Detalles Técnicos de Bajo Nivel y Firmware

### 51. El sensor MFRC522 utiliza bus SPI. ¿Qué ganancia de antena (`RxGain`) configuraste para optimizar la lectura?

Configuré la ganancia de recepción de la antena en 38 dB. Y matizo un detalle que a veces se da por hecho: no es el máximo del registro. El MFRC522 llega hasta 48 dB; elegí 38 a propósito. Es un escalón por encima del valor por defecto del chip, sobre los 33 dB: suficiente para leer con fiabilidad tarjetas MIFARE baratas y clones, pero sin irme al tope, porque maximizar la ganancia ensancha el campo y dispara lecturas espurias. En Eduplay el alcance es corto a propósito, de uno a tres centímetros, para que el gesto del niño sea intencional. Un apunte: los 13,56 megahercios que aparecen son la frecuencia de la antena RFID; el bus SPI en sí lo dejé a 4 megahercios, conservador, por estabilidad con el RC522.

### 52. Implementas una deduplicación local de 1.200 ms. ¿Por qué ese valor y no uno dinámico basado en el ciclo de juego?

Por simplicidad y determinismo. Los 1.200 milisegundos viven en la capa Web Serial del navegador, que por diseño no sabe nada del juego: solo lee el puerto, normaliza y deduplica. Atar esa ventana al ciclo de la partida obligaría a acoplar esa capa con el motor de juego, romper esa separación limpia y meter estado compartido que hoy no existe. El valor fijo cubre el peor caso pedagógico: un niño de cuatro a ocho años que deja la tarjeta apoyada sobre la antena un segundo largo. Con una ventana fija sé exactamente cómo se comporta el sistema en cualquier mecánica, y eso lo hace fácil de razonar y de testear. Un umbral dinámico añadiría complejidad sin un beneficio real medible para el usuario.

### 53. El watchdog de heartbeat del firmware emite cada 20 segundos. ¿Cómo lo procesa el frontend para alertar al docente?

Puntualizo la cifra: el latido del firmware es cada 10 segundos, no cada 20. El que quizá se confunde con 20 es otro distinto: hay un latido a nivel de socket, del cliente al servidor, que va cada 60 segundos para mantener vivo el modo RFID. Volviendo al del firmware: cada 10 segundos el lector emite por el puerto un evento de estado con su uptime, tarjetas leídas y memoria libre. En el navegador tengo un watchdog que, con cada latido, refresca el dispositivo a "ready". Si no llega ninguno en 20 segundos —dos ciclos— asumo que el lector ha dejado de dar señales de vida, lo paso a estado "stale" y aviso al docente en la interfaz. Es recuperable solo: en cuanto vuelve un latido, regresa a "ready".

### 54. Usas IndexedDB para colas offline. ¿Cómo evitas la pérdida de datos si el docente cierra el navegador antes de sincronizar?

Tengo una cola en dos niveles. La primaria está en memoria, hasta doscientos escaneos; y en paralelo los replico best-effort en IndexedDB, que sobrevive a un F5 o al cierre del navegador. Al reconectar, rehidrato desde IndexedDB y vuelco los pendientes en orden. Ahora, seré honesto sobre el alcance: no es un modo offline completo. El backend rechaza lecturas con más de treinta segundos de antigüedad por la propia protección anti-replay, así que un escaneo que se quedó demasiado tiempo en la cola se descarta a propósito al sincronizar, porque reenviarlo sería un rechazo garantizado. La cola cubre cortes transitorios y recargas de página, no cerrar el portátil media ronda. Y como el backend es la fuente de verdad, esa ronda siempre se puede repetir sin datos inconsistentes.

### 55. ¿Cuál es el umbral de tiempo que esperas antes de volcar el contador a la EEPROM para optimizar ciclos de escritura?

Aquí matizo la premisa: el umbral no es temporal, es por número de escaneos. Concretamente, vuelco el contador a EEPROM una vez cada cien lecturas, no cada cierto tiempo. Persisto un "techo": cuando el contador alcanza el techo guardado, escribo el siguiente bloque de cien y sigo. La razón de que sea por conteo y no por tiempo es que lo que desgasta la EEPROM es el número de escrituras, y ese número va ligado al número de escaneos, no al reloj. Un umbral temporal escribiría aunque no hubiera actividad, o escribiría de más en ráfagas intensas. Contar escaneos ata el desgaste exactamente a lo que lo provoca. En cada reinicio salto al siguiente bloque de cien para no reutilizar contadores. Lo recojo en el Anexo D.

### 56. ¿Cómo gestionas en el firmware el "chattering" en el límite del rango de detección del sensor?

En el borde del alcance, la tarjeta entra y sale del campo y el lector puede parpadear entre "presente" y "ausente". Lo controlo con un debounce en el firmware: no declaro la tarjeta retirada al primer ciclo sin lectura, sino que exijo diez ciclos consecutivos sin detección —del orden de un segundo— antes de emitir el evento de retirada. Así, un parpadeo suelto en el límite no genera un evento espurio. Además, tras cada lectura válida "halteo" la tarjeta y hago una pausa breve, de modo que no se relee mientras siga en el campo. Entre el debounce de retirada y el halt, el firmware entrega transiciones limpias: una detección y, cuando de verdad se va, una retirada, sin la metralla de eventos del borde.

### 57. Si cambias la clave HMAC en el backend, ¿cómo se actualiza de forma segura en los dispositivos ya desplegados?

Con honestidad: no hay actualización remota. La clave se incrusta en el binario del firmware al compilar y nunca viaja por el puerto serie, que es parte de lo que la hace segura. Como contrapartida, rotarla es un procedimiento manual y coordinado: recompilo el firmware con la clave nueva, reflasheo por USB cada lector y, en la misma ventana, actualizo el secreto en el backend para que ambos lados coincidan. No tengo canal OTA ni verificación con dos claves en paralelo, así que lo hago en una ventana de mantenimiento sin uso. Es asumible porque el parque de lectores es cerrado y pequeño, y esta rotación está prevista para cuando se actualiza el firmware, no de forma rutinaria. Lo recojo en la política de rotación de secretos.

### 58. ¿Qué protocolo de comunicación serie utilizas (JSON, binario, delimitado)?

Líneas de texto JSON delimitadas por salto de línea, a 115.200 baudios. Cada evento del firmware es un objeto JSON plano en una sola línea terminada en `\n`: detección de tarjeta, retirada, estado, inicialización y error. En el navegador acumulo bytes hasta ver el salto de línea, parseo esa línea con JSON y descarto las malformadas. Elegí texto plano y no binario por dos motivos. El primero, diagnóstico: cualquiera puede abrir un monitor serie y leer lo que envía el sensor sin decodificar nada. El segundo, desacoplamiento: no hay dependencia binaria entre versiones del firmware y del navegador, algo frágil de mantener. El coste en ancho de banda es irrelevante porque las tramas son pequeñas y el enlace serie va sobrado. Lo detallo en el Anexo D.

### 59. El ESP8266 tiene 80 KB de RAM. ¿Tuviste problemas de fragmentación al manejar objetos JSON de eventos grandes?

Matizo la premisa: no manejo objetos JSON grandes. Cada evento es una línea corta y plana, del orden de cien o ciento cincuenta bytes, así que no hay estructuras que fragmenten la memoria. Dicho esto, el riesgo teórico existe porque el firmware usa el tipo String de Arduino, que reserva en heap y en el ESP8266 puede fragmentar si se abusa. Lo tuve en cuenta: reservo por adelantado la capacidad de la cadena hexadecimal, mantengo los literales en flash con la macro F para no gastar RAM, y sobre todo las tramas son minúsculas. Y para no ir a ciegas, cada latido del firmware reporta la memoria libre, que monitorizo desde la interfaz; si hubiera una fuga, la vería caer. En la práctica no tuve problemas de fragmentación.


---

## Bloque 10: Comunicación en Tiempo Real y Sockets

### 60. Has definido un backoff exponencial de 5s. ¿Cómo evitas que el alumno pierda el contexto visual durante la reconexión?

Matizo: los cinco segundos son el techo del backoff, no el paso. El cliente empieza reintentando el handshake al segundo, va duplicando la espera y la topa en cinco; con hasta quince intentos cubro cerca de un minuto de caída. Durante ese rato no desmonto la pantalla: la partida sigue pintada y solo superpongo un indicador "Reconectando…", con aviso para lectores de pantalla, congelando el estado visible. La clave es que el estado vivo es del servidor, no del navegador. Al recuperar la conexión pido una resincronización y el backend responde con un snapshot completo: puntuación, ronda y tiempo restante vuelven exactos. El niño no percibe pérdida; a lo sumo, un parpadeo del rótulo.

### 61. El evento `play_state_sync` tras reconexión: ¿envía la partida completa o un delta de cambios?

Envía la partida completa, un snapshot, no un delta. Lo verifiqué en el código: `play_state_sync` responde con el mismo estado que emito al unirse a la partida. Incluye estado, ronda actual, puntuación, rondas totales, si está en pausa, el tiempo restante recalculado en el instante y el reto vigente; en Memoria añade el tablero, los intentos y las parejas encontradas, y en Secuencia la fase intra-ronda. Elegí snapshot y no delta a propósito: tras una caída de red no sé cuántos eventos perdió el cliente, así que un delta exigiría un registro de eventos por partida y reconciliación. Un estado completo es idempotente: lo aplico y el cliente queda consistente, sin importar qué se perdiera. Es más simple y más robusto.

### 62. El rate limit de escaneos es de 120 por minuto. ¿Por qué un límite tan alto frente al ritmo pedagógico?

Porque ese techo no dimensiona el ritmo del RFID, sino el peor caso del respaldo táctil. Con el sensor, el niño acerca una tarjeta cada varios segundos: voy sobradísimo. Pero cuando no hay lector, el tablero de Memoria o Asociación se juega tocando la pantalla, y un niño de cuatro a ocho años "machaca" las cartas: hasta cuatro toques por segundo. Con el límite anterior, sesenta por minuto, perdía respuestas legítimas. La protección real contra rebotes no es este número, sino la deduplicación por fuente: mil doscientos milisegundos para el sensor físico, doscientos cincuenta para el toque. Además lo tengo como límite "blando": si se supera, descarto la lectura sobrante en silencio, pero nunca bloqueo los controles del docente. Filtra abuso sin castigar el juego normal.

### 63. ¿Qué sucede si el evento `card_removed` se pierde por interferencia? ¿Se bloquea el sistema esperando la retirada?

No, el sistema nunca espera la retirada. La lógica de juego avanza con `card_detected`; `card_removed` es solo una señal local del navegador, ni siquiera viaja al backend. Cumple dos papeles menores: apagar el indicador de "tarjeta presente" en el panel del lector e invalidar el enfriamiento de deduplicación de ese identificador, para que si el niño levanta y reacerca la misma carta enseguida, el segundo acercamiento cuente. Si ese evento se pierde, lo único que ocurre es que ese enfriamiento de un segundo largo sigue vivo un momento; en cuanto expira, todo vuelve a la normalidad. No hay ninguna máquina de estados que quede colgada a la espera de un "removed". El diseño es idempotente respecto a esa señal.

### 64. ¿Cómo evitas que un docente "escuche" eventos de otra aula conociendo el ID de sesión del socket?

Conocer el identificador no basta, porque unirse a la sala exige demostrar propiedad. El identificador de partida es un ObjectId que aparece en URLs y respuestas: es un identificador, no un secreto. Por eso, cuando alguien emite `join_play` o pide una resincronización, el backend no se fía del ID: carga la partida, mira qué sesión la originó y comprueba que fue creada por ese docente, o que quien pide es Jefe de Estudios. Si no es su partida, respondo "prohibido" y registro el intento como evento de seguridad. Antes de todo eso, el handshake ya ha validado el token JWT y el rol. Así, aunque un docente adivine el identificador del aula vecina, jamás entra en su sala ni recibe sus eventos.

### 65. ¿Por qué decidiste emitir el `rfid_mode_heartbeat` como evento volátil en Socket.IO?

Primero un matiz: ese latido va cada sesenta segundos, no es de alta frecuencia. Su único fin es refrescar en el servidor un watchdog que, si no recibe señal, libera el modo RFID abandonado a los cinco minutos; así evito que se suelte durante una pausa legítima, por ejemplo mientras el docente explica algo. Lo emito como "volatile" precisamente porque es telemetría periódica: si en ese instante el socket está saturado o caído, prefiero que ese latido se descarte, no que se encole. Reenviar más tarde un latido viejo no aporta nada, solo confundiría el reloj del watchdog. Además, cualquier escaneo válido también lo refresca, y al reconectar el cliente reanuda los latidos. Solo importa el último, y "volatile" expresa justo eso.

### 66. En Memoria, si el socket se desconecta entre la primera y segunda tarjeta de la pareja, ¿cómo se recupera el estado?

Sin problema, porque la primera carta volteada es estado del servidor, no del navegador. El motor guarda en la memoria del proceso qué cartas están reveladas y cuál está seleccionada en el turno en curso. El cliente es solo una vista. Cuando el socket cae entre la primera y la segunda tarjeta y luego reconecta, pido la resincronización y recibo el snapshot completo; para Memoria incluye el tablero reconstruido a partir de ese estado, con la primera carta aún destapada, los intentos y las parejas ya resueltas. El niño lo ve exactamente donde lo dejó y solo tiene que acercar la segunda. No hay que recordar nada en el cliente ni reproducir eventos: reconstruyo la vista desde la verdad que vive en el servidor.

### 67. ¿Cómo manejas la latencia de red en los timeouts de las rondas para que sea justa para el alumno?

El reloj es del servidor, que es la única fuente de verdad, pero lo diseñé con dos concesiones a favor del alumno. Primera: el temporizador no arranca al generar el reto, sino cuando el cliente confirma que el tablero ya está pintado; así la latencia de carga no le come tiempo. Segunda: cuando expira el límite, el servidor no cierra en seco. Mantiene una ventana de gracia breve, de unos ciento cincuenta milisegundos, en la que sigue aceptando el escaneo. El niño ve el reloj llegar a cero, pero un acercamiento que salió en el último fotograma y viaja por la red todavía cuenta como válido, en vez de descartarse como fuera de tiempo. El límite por ronda, además, lo fija el docente al crear la sesión.


---

## Bloque 11: Seguridad Avanzada y HMAC

### 68. Si el ESP8266 se reinicia y el contador vuelve a cero, ¿cómo permite el backend que siga funcionando el anti-replay?

Corrijo la premisa: el contador no vuelve a cero tras un reinicio, y eso es justo lo que preserva el anti-replay. Se persiste en la EEPROM, pero de forma diferida: escribir en cada lectura agotaría las celdas en semanas, así que el firmware guarda un "techo" y solo lo actualiza cada cien escaneos. Al reiniciar, carga ese techo y salta hacia adelante al siguiente bloque de cien, cubriendo el peor caso. Nunca retrocede: la monotonicidad estricta sobrevive al reinicio. Por eso el backend no necesita ninguna ventana de resincronización: mantiene su regla de "estrictamente mayor que el último visto". Un reinicio legítimo se traduce en un salto hacia delante que pasa con naturalidad, mientras que un contador igual o inferior se rechaza como replay. La seguridad de ese salto descansa en que falsificar el HMAC exige la clave.

### 69. ¿Dónde reside físicamente la clave secreta HMAC en el servidor y cómo se protege de fugas en logs?

La clave HMAC del RFID vive como variable de entorno, inyectada desde ficheros de secretos protegidos en la propia máquina, bajo /opt/eduplay/secrets, con permisos restringidos y fuera del checkout de Git y de la imagen Docker. Nunca está en el código ni en el historial de shell. Por diseño tampoco viaja por el puerto serie: por el cable solo circula la firma, no la clave. Y no aparece en los logs: el logger estructurado redacta un amplio conjunto de rutas sensibles —contraseñas, tokens, secretos MFA, cabeceras de autorización y cookies— sustituyéndolas por un marcador, y los secretos jamás se pasan al logger. El mismo criterio aplica a las claves JWT y de cifrado. Es la misma filosofía que sigo con el filtro de Sentry: minimizar y redactar antes de que cualquier dato sensible salga del proceso.

### 70. El sistema valida la entropía de `JWT_SECRET` al arrancar. ¿Qué criterios de longitud y variedad aplicas?

Al arrancar, un validador de entorno exige dos condiciones sobre JWT_SECRET: una longitud mínima de 64 caracteres y una entropía de Shannon de al menos 3,5 bits por carácter. La longitud garantiza tamaño de clave suficiente —64 caracteres hexadecimales son 256 bits— y la entropía descarta cadenas largas pero pobres, como una letra repetida, que pasarían el filtro de longitud pero serían débiles. Además rechazo una lista de valores por defecto conocidos ("secret", "changeme" y similares) y obligo a que el secreto de refresh sea distinto del de acceso, aplicándole las mismas comprobaciones. Si algo no cumple, el proceso aborta el arranque: prefiero un fallo ruidoso e inmediato a levantar producción con un secreto adivinable. Es fallo seguro por defecto.

### 71. Has implementado `beforeSend` en Sentry. ¿Cómo garantizas que no se filtren nuevos campos identificativos futuros?

Seré transparente sobre la implementación real: el hook beforeSend funciona como lista de denegación, borrando campos conocidos —nombre de alumno, nombre de jugador, aula, email, tokens, secretos MFA— de cuerpo, cabeceras, breadcrumbs, extras y tags. Una lista de denegación, por sí sola, no cubriría automáticamente un campo nuevo. Lo que realmente me protege ante campos futuros es la minimización en el origen: al contexto de usuario de Sentry solo adjunto identificador y rol, nunca el documento completo del alumno, de modo que un campo nuevo en el modelo no fluye a Sentry por defecto. A eso sumo la redacción en el logger aguas arriba, los DTOs que nunca exponen documentos crudos y el Session Replay desactivado. Reconozco que una lista de permitidos sería estrictamente más robusta; hoy el riesgo lo neutraliza no adjuntar el dato de entrada.

### 72. El bloqueo educativo de 15s tras violar el rate limit: ¿es por IP, por docente o por socket?

Corrijo el matiz: no es por IP. Ese bloqueo de quince segundos vive en la capa de WebSocket y su clave es la identidad del docente —el userId—; solo cae al identificador de socket si la conexión aún no está autenticada. Se dispara tras cinco violaciones consecutivas sobre los eventos "duros" de control de la partida y bloquea quince segundos. Y hay una decisión de diseño importante: los escaneos RFID están limitados en modo suave y nunca provocan el bloqueo, precisamente para que un niño pulsando tarjetas rápido no congele los controles del profesor durante la clase. En la capa HTTP uso, aparte, una clave compuesta de usuario o IP que responde con un 429. Pero el bloqueo educativo concreto es por docente, y el mensaje que ve es amable y no punitivo, con una cuenta atrás.

### 73. ¿Cómo proteges el endpoint de renovación de tokens contra ataques de fijación de sesión?

Con rotación obligatoria y varios anclajes. En cada renovación emito un par de tokens nuevo y dejo inservible el anterior: lo retiro del conjunto activo y lo marco como usado, de modo que un token fijado o conocido de antemano no puede reutilizarse. La cookie es httpOnly, SameSite estricto, Secure y acotada a /api/auth. Además, el refresh está atado a una huella del dispositivo —un hash del user-agent y las cabeceras de idioma— que verifico al renovar, y a un identificador de sesión que se regenera en cada login e invalida el anterior. Si detecto la reutilización de un token ya consumido fuera de una breve ventana de gracia, lo interpreto como robo y revoco todas las sesiones del usuario. Así la fijación no prospera: el token del atacante o no encaja con la huella y la sesión de la víctima, o muere en la primera rotación. El refresh vive siete días.


---

## Bloque 12: Modelo de Datos y Analítica Avanzada

### 74. ¿Qué problema de sincronización te hizo descartar el modelo de "tarjetas con propietario" por el de "tokens fungibles"?

La misma tarjeta MIFARE física se reutiliza en mazos distintos, incluso de otros docentes, y se reserva por partida con un lock en Redis (Lua, con expiración) mientras dura esa partida. Si la tarjeta fuera una entidad global con dueño y un estado único (activa, reservada, extraviada), dos aulas jugando a la vez mazos que comparten ese UID competirían por ese único registro: ¿de quién es el lock, cuál es su estado? Es un conflicto de sincronización sin solución limpia para una etiqueta barata, anónima e intercambiable. Tratarlas como tokens fungibles (solo un UID embebido en el mazo, sin registro global, sin propietario ni ciclo de vida) mueve el único estado mutable de "reserva" al lock por partida en Redis. Los conflictos de concurrencia desaparecen y el hardware deja de contaminar el modelo de dominio.

### 75. En el array de 500 eventos con `$slice`: ¿qué eventos priorizas mantener si la partida se alarga, los primeros o los últimos?

Los últimos 500. Uso `$push` con `$slice: -500`, que conserva los eventos más recientes y descarta los más antiguos según crece el array. La razón es analítica: el final de la partida concentra la señal que importa (la fatiga como ralentización en la segunda mitad, la frustración con errores consecutivos al final, el abandono cerca del cierre). Las primeras rondas son lo menos diagnóstico. Además, 500 es un tope generoso: una partida real de niños de cuatro a ocho años rara vez pasa de unas pocas decenas de rondas, así que el límite es una salvaguarda frente a un cliente patológico o manipulado que inunde de eventos, no algo que el juego normal roce. Protege el límite de 16 MB del documento y mantiene las escrituras acotadas sin perder la cola pedagógicamente relevante.

### 76. k-anonimidad: si un docente aplica un filtro y quedan 3 alumnos en pantalla, ¿se ocultan los datos individuales?

Sí. Mi umbral es k igual a cinco. Con menos de cinco alumnos en el grupo filtrado (tres, en tu ejemplo) el sistema oculta el desglose por alumno y muestra solo un agregado numérico del grupo, más un aviso explícito de que la protección de k-anonimidad está activa. El fundamento es normativo: la LOPDGDD y la guía de la AEPD para centros educativos son explícitas en que la pequeñez del aula no exime de anonimizar, sino que facilita la re-identificación y por tanto endurece la exigencia. Y algo importante: la comprobación se aplica al subconjunto filtrado, no solo al tamaño bruto del aula, así que una clase de veinte reducida por filtro a tres lo dispara igual. Es una limitación asumida y documentada: aulas muy pequeñas ven agregados en lugar de detalle individual, deliberadamente, priorizando al menor sobre la comodidad.

### 77. ¿Cómo calculas técnicamente la línea de tendencia del alumno en el dashboard (regresión, media móvil)?

Regresión lineal por mínimos cuadrados. Construyo puntos (x, el índice ordinal del periodo; y, la puntuación media de ese periodo), calculo la pendiente y clasifico: mejora si la pendiente supera +0,5, declina si baja de -0,5, y estable en medio, porque medio punto por periodo en una escala de 0 a 100 es ruido estadístico, no tendencia. La confianza la doy por el número de puntos (no uso R cuadrado, poco práctico con menos de diez datos): alta con siete o más puntos y pendiente en valor absoluto mayor que uno, hasta baja con pocos puntos. Esa misma pendiente alimenta la narrativa automática ("tendencia positiva de +N puntos por periodo"). Sí uso ventanas móviles para una métrica aparte de velocidad y aceleración (regresión sobre promedios de ventana), pero la línea de tendencia principal es una regresión lineal simple, no una media móvil.

### 78. En la matriz cruzada mecánica/contexto, ¿cómo evitas conclusiones sesgadas con muy pocas partidas?

Con varias salvaguardas. Las celdas sin partidas no se muestran por defecto (solo aparecen si pido ver el espacio completo). Por debajo de una muestra significativa, los bloques renderizan un estado vacío honesto ("aún no hay suficientes partidas para construir la matriz cruzada") en vez de un gráfico con escala degenerada; las curvas de aprendizaje derivadas exigen al menos dos alumnos por punto. Cada celda muestra un semáforo RAG y una media, pero son lecturas heurísticas, no afirmaciones estadísticas, y al pulsar una celda se abren las sesiones exactas que la alimentan para que el docente juzgue la base. El principio de diseño aquí es el de Few: fabricar conclusiones con una muestra ínfima es peor que admitir que aún no se sabe. Con honestidad, una única partida brillante todavía puede teñir una celda: por eso prefiero estados de "faltan datos" a una falsa precisión.

### 79. Detección de "tarjetas problemáticas": ¿qué métrica distingue si el fallo es físico o de contenido pedagógico?

La métrica central es un índice de dificultad por UID de tarjeta: (errores más *timeouts*) dividido entre intentos totales, de 0 a 1, agregado sobre el aula y acompañado del número de alumnos distintos que la intentaron. El discriminante principal no es tanto físico frente a pedagógico como individual frente a contenido: si una tarjeta concentra errores en muchos alumnos distintos, el problema es el material, no un niño concreto. Soy honesto: el sistema no separa limpiamente una etiqueta físicamente defectuosa de un concepto difícil, porque ambos elevan la tasa de fallo. La única pista es el desglose entre errores (se escaneó la carta equivocada, un fallo genuino de asociación) y *timeouts* (nunca se respondió, que apunta más a lectura o atención): una etiqueta que no lee tiende a aflorar como *timeout* o como no-evento, no como respuesta errónea. Más allá de esa heurística, confirmar un fallo físico exige sustituir la tarjeta.

### 80. Los informes se borran al mes. ¿Usas un proceso `cron` independiente o el TTL nativo de MongoDB?

Para los informes generados, TTL nativo de MongoDB: un índice TTL sobre la fecha de generación con expiración a 30 días, más un tope de 100 por docente que descarta el más antiguo en un hook previo al guardado. Ningún cron los toca; los expira el hilo de fondo de Mongo. Merece la pena distinguirlo, porque las dos mecánicas coexisten a propósito: el TTL solo borra, así que todo lo que requiere transformar usa un job. La anonimización de partidas a los 12 meses y el borrado de cuentas inactivas a los 24 se ejecutan como cron programado de BullMQ a las 03:00 (invocable también como tarea de retención con modo simulación), porque anonimizar es reescribir campos, no eliminar documentos, y el TTL no sabe hacer eso. Las alertas resueltas también van por ese cron, no por TTL. En resumen: informes y notificaciones con TTL nativo; anonimización y purga de cuentas con el job de retención.


---

## Bloque 13: UI/UX y Accesibilidad Detallada

### 81. ¿Cómo evitas conflictos entre tus atajos de teclado y los nativos de los lectores de pantalla (JAWS/NVDA)?

Con dos mecanismos. El primero y principal: el escuchador de atajos se desactiva dentro de cualquier campo de texto. Comprueba si el foco está en un input, textarea, select, contenteditable o un elemento con rol de textbox, y en ese caso no dispara ningún atajo (solo dejo pasar Escape, para poder cerrar un modal siempre). Así, cuando el lector está en modo formulario escribiendo, no le secuestro ninguna tecla. El segundo: uso acordes «g» más letra y combinaciones con Shift, no letras sueltas, así que no colisionan con la semántica de una sola tecla de la propia app, y nunca sobrescribo la tecla modificadora del lector (Insert o Bloq Mayús) ni las teclas estándar de navegación, que dejo a la tecnología asistiva. El overlay de ayuda es un diálogo con rol y modalidad correctos, y lo validé con pasadas manuales de teclado y lector.

### 82. ¿Cómo aseguras que el área táctil de 44px se mantiene físicamente en tablets de muy alta densidad de píxeles?

La clave es que esos 44 píxeles son píxeles CSS lógicos, no píxeles físicos del dispositivo. El píxel CSS es independiente de la densidad: el navegador lo mapea a través del devicePixelRatio, de modo que 44 píxeles CSS se renderizan como 44 por la densidad en píxeles físicos y conservan el mismo tamaño físico, alrededor de nueve milímetros, tanto en una pantalla de densidad uno como de tres. Yo expreso el objetivo táctil como un tamaño mínimo en CSS (una altura mínima de 2,75 rem, que son 44 píxeles) y el tablero limita sus columnas según el ancho disponible, encogiendo densidad antes que el objetivo. Por eso una tablet de alta resolución no achica el botón físicamente; solo lo dibuja más nítido. Es el suelo de tamaño de objetivo que pide WCAG 2.2, respetado en píxeles lógicos.

### 83. "Respaldo táctil": ¿estos datos se marcan de forma distinta en la analítica para saber que el RFID falló?

Honestamente, hay que matizar. En la capa de transporte sí se distingue: un toque táctil viaja con una etiqueta de origen y un identificador de sensor con prefijo propio, que el servidor usa para eximirlo de la firma criptográfica del RFID y para afinar la deduplicación. Pero en la analítica persistida, es decir, en el registro de eventos por respuesta y en las métricas del alumno, no se marca distinto: un acierto cuenta igual venga por tarjeta o por dedo. Es una decisión deliberada, coherente con tratar el respaldo como una vía de primera clase y no un modo degradado: la evidencia de aprendizaje del niño es la misma. La consecuencia sincera es que, desde los datos guardados, no puedo saber a posteriori que «aquí falló el RFID»; si quisiera ese dato como métrica, persistir el método de entrada por evento sería una ampliación futura pequeña.

### 84. La mascota usa lenguaje no punitivo. ¿Detecta el sistema la frustración (muchos errores) para sugerir pausa?

En parte, y quiero ser preciso. La mascota sí reacciona a un patrón de error sostenido: tras unos cinco errores sin recuperar racha, pasa a un tono preocupado pero alentador, con una frase de reenganche y un enfriamiento de ocho segundos para no agobiar; también hay un toque suave si el alumno lleva un rato inactivo. Pero nunca recrimina y, esto es lo importante, no sugiere automáticamente hacer una pausa ni la fuerza. Pausar siempre lo inicia el docente o el alumno con el botón explícito. Una detección afectiva real de frustración que recomiende parar es línea futura; hoy la señal es un simple aproximado por acumulación de errores que solo cambia el tono de la mascota. El docente, que está presente en el aula, sigue siendo quien decide cuándo conviene parar.

### 85. ¿Por qué elegiste ilustraciones SVG inline en lugar de imágenes externas para los empty states?

Por varias razones. El SVG en línea no supone ninguna petición de red extra: no hay nada que cargar, que falle en caché o que devuelva un 404, así que el estado vacío se pinta al instante, incluso sin conexión. Hereda los tokens del tema (currentColor, variables CSS), de modo que la ilustración se recolorea sola con el tema claro u oscuro y conserva la firma visual; una imagen rasterizada externa no puede seguir el tema. Es vectorial, así que se mantiene nítida desde 1366×768 hasta 4K. Y sustituyó a los emojis genéricos, que se renderizan distinto en cada sistema operativo y rompen la identidad. Además, cada estado vacío lleva un título humano, como «Todo al día», y un párrafo que orienta, en lugar de un «No hay datos» muerto: el vacío es una oportunidad de guía, no un callejón.

### 86. En el wizard, si el docente vuelve atrás y cambia de mazo, ¿qué pasa con los parámetros ya configurados?

Los parámetros pedagógicos genéricos (rondas, tiempo por ronda, puntos, penalización, dificultad) se conservan, porque no dependen del mazo: el docente no pierde el ajuste que ya había hecho. Lo que sí depende del mazo se actualiza solo, de forma reactiva. El número de tarjetas se deriva siempre del mazo seleccionado en el momento de crear, nunca es un valor manual que quede obsoleto. Y el plan de retos por ronda de Asociación se reconstruye contra las cartas del mazo nuevo, descartando cualquier carta que ya no exista; en Memoria, la validación de parejas se recalcula sobre el mazo nuevo. Así, cambiar de mazo no puede dejar una ronda apuntando a una carta que no está, pero tampoco borra la configuración numérica. Es una invalidación reactiva del estado dependiente, no un reinicio completo.

### 87. ¿Cómo garantizas que los colores de los tiers de rendimiento son distinguibles para daltónicos?

Con dos garantías. Primera: el color nunca es la única señal. Cada tramo de rendimiento lleva siempre una etiqueta de texto que lo nombra (Excelente, Bueno, Promedio, Necesita apoyo), así que el significado sobrevive a cualquier tipo de daltonismo; y en el caso de las alertas, la severidad añade además un icono de forma distinta. Segunda: los colores de los tramos son tokens semánticos elegidos sobre la escala de luminosidad de OKLCH con suficiente separación de luminancia, no solo de tono, de modo que se ordenan también en escala de grises, y cada uno pasa el umbral de contraste WCAG contra su fondo en ambos temas. Eso lo verifica de forma automática la suite de accesibilidad sobre las insignias de tramo. Un docente con daltonismo rojo-verde lee el tramo por la etiqueta y la jerarquía de luminancia sigue comunicando el orden.


---

## Bloque 14: Arquitectura de Software (Backend)

### 88. ¿Qué estrategia sigues para capturar errores en middleware de Socket.IO, dado que no son rutas Express?

No tengo el middleware de error de Express en los sockets, así que construí una frontera central en el despachador de comandos. Cada evento pasa por una única función que primero valida el payload con Zod, devolviendo un error uniforme si es inválido, y luego envuelve la ejecución del comando en un try/catch: ante fallo, lo reporta a Sentry con etiquetas (evento, socket, usuario), lo registra con Pino y emite al cliente un evento de error con forma predecible. La autenticación del handshake es aparte, un middleware que rechaza vía next con un error tipado. Encima hay un envoltorio de rate limiting y un guard contra payloads peligrosos. Y hago await dentro de cada handler para que una promesa rechazada no escape como unhandledRejection.

### 89. ¿Qué tipos de tareas delegaste a BullMQ para no bloquear el hilo principal de Node.js?

BullMQ corre en un proceso worker aparte, con su propia conexión Redis, y lleva trabajos pesados o periódicos deliberadamente fuera del camino del juego. Cuatro reales: la retención de datos nocturna a las tres, que anonimiza partidas de más de doce meses y borra alumnos inactivos de más de veinticuatro; la detección de alertas inteligentes del docente, cada quince minutos; la detección de alertas de sistema, cada cinco; y una reconciliación nocturna que reconstruye los leaderboards y métricas materializadas en Redis desde Mongo y reporta desviaciones. Todos son cron idempotentes con jobId fijo. Los dejo en el worker precisamente para que nunca bloqueen el bucle de eventos que atiende el tiempo real del RFID. Hay andamiaje para exportaciones y notificaciones, aún sin implementar.

### 90. ¿En qué caso concreto te salvó la triple validación (Zod, Mongoose, Env) de un error crítico?

Cada capa atrapa una clase distinta. La de entorno, al arrancar, se niega a levantar el servidor si el secreto JWT tiene menos de 64 caracteres, poca entropía, es un valor por defecto conocido o coincide con el de refresco: ese guard evita desplegar un bypass de autenticación por token falsificable, el fallo más grave. Mongoose, en persistencia, capturó una puntuación que se volvía negativa por acumular penalizaciones, con un clamp en la validación previa, y un índice único parcial impide dos partidas activas del mismo alumno, una carrera que la comprobación de aplicación sola no cerraba. Zod, en la frontera, rechaza payloads malformados de forma uniforme y bloquea rutas de contaminación de prototipo. El titular es el secreto débil frenado antes de producción.

### 91. ¿Cómo gestionas las transacciones en MongoDB para que el borrado de un alumno sea atómico en todas las colecciones?

El borrado por derecho al olvido envuelve los deletes cross-colección (partidas, informes generados, alertas y el usuario) en una utilidad de transacción, así que es todo o nada: un fallo a mitad no puede dejar datos personales re-identificables huérfanos en unas colecciones y borrados en otras, que sería una supresión parcial y una violación del artículo 17. Dentro de la sesión los borrados van secuenciales, porque Mongo no admite operaciones concurrentes sobre una misma sesión transaccional. Reintenta ante conflictos de escritura transitorios, porque los deletes son idempotentes, y requiere un replica set: por eso despliego Mongo como replica set de un nodo con autenticación, incluso autoalojado. Con franqueza: la purga de la materialización en Redis va después del commit, como mejor esfuerzo, porque Redis no entra en la transacción de Mongo.

### 92. Con 72% de cobertura, ¿qué lógica (ej. scripts Lua) decidiste no testear y cómo la validaste manualmente?

La cobertura ronda el 72%, con umbral del 65% en sentencias y 50% en ramas, reportado a SonarCloud. Dejé fuera deliberadamente dos cosas. Los scripts Lua: la suite mockea Redis con una librería que no soporta EVAL, así que los tests ejercitan una ruta de reserva secuencial en JavaScript, semánticamente equivalente, pero la atomicidad real es una propiedad del runtime de Redis que un mock no puede demostrar. Validé los scripts contra un Redis real en Docker, y el camino de respaldo queda cubierto con la misma lógica. Y el camino de hardware con el firmware: como el sensor físico está roto desde mayo, lo validé con un simulador que reproduce escaneos firmados con HMAC de extremo a extremo. Son justo lo que un CI sin EVAL ni hardware no puede tocar.

### 93. ¿Qué política de desalojo (`maxmemory-policy`) configuraste en Redis para evitar pérdida de claves de BullMQ?

`noeviction`, en desarrollo y en producción. La razón es crítica: los trabajos de BullMQ, la blacklist de tokens, las claves de idempotencia del arranque de partida y los locks distribuidos de tarjetas no pueden desalojarse en silencio. Con la política por defecto, `allkeys-lru`, bajo presión de memoria Redis expulsaría un token revocado de la blacklist, que reaparecería como válido, o tiraría un job de retención encolado. Todo lo prescindible, los cachés de analítica, contextos y usuarios, ya lleva su TTL explícito y caduca solo; el resto debe persistir hasta su vencimiento natural. Con `noeviction`, ante presión Redis rechaza escrituras nuevas en vez de descartar claves calladamente: un fallo ruidoso que puedo alertar, frente a pérdida silenciosa. De hecho lo corregí, venía como `allkeys-lru`.


---

## Bloque 15: Escenarios de Fallo y Futuro

### 94. Si un centro obliga a usar Firefox, donde Web Serial no funciona, ¿cuál es tu alternativa técnica viable?

Es una premisa correcta: Web Serial solo existe en navegadores basados en Chromium —Chrome, Edge, Opera—, no en Firefox ni Safari. Por eso el navegador Chromium es un requisito documentado, y en el parque escolar es el dominante, así que en la práctica rara vez es un bloqueo. Pero si un centro impusiera Firefox, tengo una salida real que ya funciona hoy: el respaldo táctil. Cuando no hay lector —da igual el motivo, un navegador sin Web Serial o un cable suelto—, la partida continúa como un tablero de botones que el niño toca, con la misma estética y ritmo, sin ningún banner de «modo limitado». A más largo plazo, un puente nativo o un pequeño agente local podría reintroducir el sensor físico en esos navegadores. Lo importante es que el juego nunca se bloquea.

### 95. ¿Cómo afecta la "persistencia de atmósfera" temática a la carga de assets en conexiones móviles lentas?

Primero un matiz de alcance: Eduplay es desktop-first porque el sensor va por USB al portátil del docente; el móvil queda fuera del alcance de diseño, así que la conexión móvil lenta no es un escenario objetivo. Dicho esto, la atmósfera temática está pensada para ser barata. Cada contexto guarda un color dominante extraído de la imagen, y con él tiño la interfaz al instante: el aula percibe una atmósfera coherente antes incluso de que cargue ninguna imagen, que actúa de placeholder. Los binarios se convierten a WebP y se sirven desde CDN, no desde mi servidor. Y la aplicación divide el código por ruta con carga diferida, de modo que solo se descarga lo necesario. La atmósfera, por tanto, no depende de haber descargado los assets pesados.

### 96. ¿Cuál es el cuello de botella principal de tu arquitectura si intentáramos escalar a 500 aulas simultáneas?

El mismo punto que hace difícil el multitenant: el estado vivo de las partidas reside en la memoria de un único proceso Node, con la premisa de una sola instancia. Quinientas aulas concurrentes son quinientas partidas con estado en ese proceso, más sus sockets, todo sobre un único bucle de eventos; ahí está el techo, no en la base de datos. Escalar de verdad no es solo levantar más instancias: el motor de juego es stateful, así que necesito externalizar ese estado a Redis, activar el adaptador de Socket.IO sobre Redis —que ya dejé cableado—, usar sesiones adherentes para que cada aula caiga siempre en su instancia y, a gran escala, particionar por centro. La coordinación distribuida está preparada; migrar el estado del motor es el trabajo pendiente que reconozco explícitamente.

### 97. Si implementas internacionalización (i18n), ¿cómo manejarías múltiples archivos de audio por asset?

Hoy no hay capa de internacionalización: el texto vive embebido en los componentes, y el primer paso sería extraerlo a un recurso de localización. Para el audio, el modelo actual ya ayuda: cada recurso de un contexto guarda por separado sus URLs de imagen, miniatura y audio. La imagen y su color dominante son neutros al idioma, así que no los duplico; lo que se localiza es el audio y la etiqueta visible. La forma natural es indexar el audio por código de idioma —un mapa «es», «en», «fr» apuntando a cada pista— y que el reproductor pida solo la del idioma activo, con carga diferida. Así una misma tarjeta física, que trato como token intercambiable, dice «perro» o «dog» según el idioma sin tocar ni la imagen ni el mapeo de la tarjeta.

### 98. ¿Has evaluado la durabilidad física de los tags RFID frente al uso intensivo de niños de 4 años?

Voy a ser honesto: no hice un ensayo de fatiga física formal, con ciclos de flexión o abrasión medidos. No lo tengo, y presentarlo como evaluado sería faltar a la verdad; lo dejo como trabajo futuro. Lo que sí puedo argumentar es que las tarjetas PVC son razonablemente robustas para el uso de aula y, sobre todo, muy baratas de reemplazar, como detallo en el anexo de costes. Y el diseño las trata como consumibles: son tokens intercambiables, no tarjetas con dueño, así que una dañada se remapea a un UID nuevo en segundos. Además, si una tarjeta falla en mitad de la partida, el respaldo táctil permite seguir jugando sin ella. La durabilidad medida queda pendiente; la resiliencia ante el fallo, no.

### 99. ¿Qué aprendiste sobre la precisión de los timers de JavaScript (`setTimeout`) al manejar latencias de 50ms?

Aprendí a no confiar en setTimeout para nada que deba ser exacto. En el navegador no es un reloj de precisión: depende del bucle de eventos, tiene un mínimo por debajo del cual no baja y se ralentiza agresivamente si la pestaña queda en segundo plano. La lección fue separar dos cosas que se confunden. Una es la percepción: el feedback visual y sonoro que llega al niño en menos de 50 milisegundos; ahí setTimeout y las animaciones del cliente sirven de sobra, porque un pequeño desvío nadie lo nota. Otra es la corrección: si una ronda fue válida o expiró no lo decide el reloj del navegador, sino el temporizador que el servidor mantiene como autoridad. Por eso el estado del tiempo vive en el servidor y el cliente solo lo refleja.

### 100. Si un padre retira el consentimiento para analítica a mitad de curso, ¿cómo procesa el sistema los datos históricos?

El sistema contempla exactamente ese caso con oposición granular. Distingo dos finalidades del consentimiento: el seguimiento básico, necesario para jugar, y la analítica de rendimiento. El padre puede retirar solo la segunda. En cuanto lo hace, las métricas de ese alumno dejan de actualizarse y queda excluido de todas las consultas de analítica —un servicio central verifica el consentimiento de forma consistente en cada endpoint—, pero el niño sigue jugando con normalidad, sin penalización. Sobre lo histórico: no lo borro automáticamente, porque retirar el consentimiento no equivale a ejercer el derecho de supresión. Cesa el tratamiento analítico y esos eventos detallados siguen su política de retención hasta anonimizarse a los doce meses; lo ya anonimizado y agregado deja de ser dato personal. Si además pidieran el borrado, hay una cascada transaccional específica para ejercerlo.


---

## Bloque 16: Docker y Orquestación

### 101. ¿Qué directivas de `docker-compose.prod.yml` garantizan que un contenedor no consuma toda la RAM de la VPS?

La clave es `deploy.resources.limits.memory` por servicio: es un techo duro, si el contenedor lo supera lo mata el OOM-killer del kernel, nunca se lleva por delante la máquina. En el overlay de producción asigno frontend 128M, backend 1G, worker 256M, MongoDB 2G y Redis 512M, cada uno con su límite de CPU (`cpus`). Los subí desde los valores heredados del free-tier antiguo porque en la VPS hay margen. Además pongo un doble cinturón: Redis tiene su propio `--maxmemory 512mb` con `noeviction`, y el logging usa driver `json-file` con `max-size`/`max-file` para que los logs tampoco llenen el disco. Como red de seguridad extra, la VPS tiene una partición swap ante picos.

### 102. ¿Cómo gestionas los permisos de archivos entre el host y el contenedor para escribir logs de Pino sin errores?

En realidad no gestiono permisos de ficheros de log, porque Pino no escribe a disco: emite JSON estructurado a stdout. Ese stream lo captura Docker con el driver `json-file` (con rotación configurada) y, opcionalmente, lo envío a Grafana Loki con `pino-loki`. Es el enfoque de los doce factores, tratar los logs como flujos, no como archivos. Esto me evita justamente el problema que planteas: no hay bind-mount de logs entre host y contenedor, así que no hay choque de UID/GID. De hecho el contenedor del backend corre como usuario no-root (`USER node`) y con el sistema de ficheros en `read_only`, con solo `/tmp` como tmpfs, de modo que ni siquiera podría escribir un fichero de log aunque quisiera. Los permisos dejan de ser un problema por diseño.

### 103. ¿Por qué es técnicamente obligatorio desplegar MongoDB como *replica set* de un solo nodo en Docker?

Porque las transacciones multidocumento de MongoDB solo funcionan sobre un replica set: necesitan el oplog. En un `mongod` autónomo, en cuanto abres una sesión con `startTransaction` MongoDB no puede garantizar atomicidad y, lo peligroso, las escrituras degradan de forma silenciosa a no atómicas, sin lanzar error. Mi capa de datos usa un helper `withTransaction` para operaciones que tocan varias colecciones a la vez (por ejemplo el borrado en cascada del derecho al olvido, o cerrar una partida y volcar su histórico). Sin replica set esas garantías se romperían sin avisar. Por eso lo despliego como replica set de un único nodo, `rs0`. Y como combino replica set con autenticación activa, MongoDB exige además un `keyFile`, que genero una sola vez de forma idempotente.

### 104. ¿Cómo evitas que los puertos de Redis o MongoDB sean accesibles desde fuera de la VPS mediante redes Docker?

Sencillamente no publico esos puertos. MongoDB, Redis y el propio backend tienen en el overlay de producción `ports: !override []`, es decir, cero puertos publicados al host. Solo existen dentro de la red bridge interna de Docker (`rfid-games-network`), donde se resuelven por nombre de servicio: el backend llega a `mongo:27017` y `redis:6379` sin exponer nada al exterior. El único contenedor que publica puerto es el frontend, y encima lo ata a loopback (`127.0.0.1:8080`), no a `0.0.0.0`. El Nginx del host es quien hace de proxy hacia ese loopback. Así, aunque el cortafuegos fallara, Docker jamás ha bindeado los puertos de las bases de datos a una interfaz pública. Es aislamiento por defecto, reforzado luego con ufw y fail2ban.

### 105. ¿Cómo aseguras que el backend y el worker de BullMQ compartan exactamente la misma versión del código?

Porque son literalmente la misma imagen. Backend y worker declaran `build: ./backend`: el mismo contexto y el mismo Dockerfile. En cada despliegue, el runner hace checkout del tag o commit exacto y ejecuta un único `docker compose up -d --build`, que construye esa imagen a partir del mismo árbol de fuentes. Lo único que difiere es el punto de entrada: el backend arranca `node src/server.js` y el worker `node worker.js`, pero ambos parten del mismo `src/` copiado. No hay dos pipelines ni dos artefactos que puedan desincronizarse: comparten `package-lock.json`, el mismo `npm ci` y el mismo commit. Es imposible que el worker corra un detector o un servicio de una versión distinta a la del backend, que es justo el fallo que se evita al separarlos en dos procesos pero desde una fuente única.

### 106. ¿Utilizas imágenes *multi-stage*? ¿Cuánto lograste reducir el tamaño de la imagen final de producción?

Sí, los dos Dockerfiles son multietapa. El backend tiene etapas de dependencias, desarrollo y producción; la imagen final es `node:26-alpine`, instala solo dependencias de producción (`npm ci --only=production`) y corre como usuario no-root. La final ronda los 180 MB. El caso más llamativo es el frontend: una etapa `builder` con Node compila el bundle de Vite, y la imagen final es `nginx:alpine` que solo copia la carpeta `dist`, sin Node, sin npm, sin `node_modules` ni código fuente. Queda en torno a 25 MB. Ahí está la gran reducción: una imagen ingenua de una sola etapa con Node arrastraría cientos de MB; al quedarme solo con Nginx y los estáticos, bajo a unas decenas de MB. Prefiero dar las cifras finales verificadas antes que un porcentaje que no medí formalmente.


---

## Bloque 17: VPS y Despliegue en Producción

### 107. Al migrar de Koyeb a Contabo, ¿qué cambios hiciste en tu infraestructura para manejar el TLS manualmente?

Con Koyeb, el TLS lo terminaba la plataforma en su borde de forma automática, yo no tocaba certificados. Al pasar a la VPS asumí esa responsabilidad. Monté un Nginx a nivel de sistema operativo, fuera de los contenedores, que termina TLS con certificados de Let's Encrypt emitidos y renovados por Certbot automáticamente, y hace de proxy inverso hacia el Nginx de cada frontend contenedorizado. Para los nombres uso subdominios gratuitos de DuckDNS, una decisión reversible el día que compre un dominio. El contenedor del frontend volvió a servir HTTP plano en el puerto 80 interno. Y como ya no hay un borde gestionado tipo Cloudflare por delante, moví toda la protección de tráfico a Nginx más Express. La memoria refleja este despliegue autoalojado en el Anexo F.

### 108. ¿Por qué centralizar TLS en el Nginx del host en lugar de hacerlo directamente en el contenedor frontend?

Por varias razones prácticas. Una sola máquina aloja dos entornos, staging y producción, cada uno con su stack; con un único Nginx en el host resuelvo ambos por `server_name` sobre el mismo 443 y con un solo juego de certificados gestionados por Certbot. Renovar certificados es una tarea del host que corre una vez, no algo que haya que meter en cada imagen. Además me interesa que los contenedores sean inmutables y sin estado: el frontend corre con el sistema de ficheros en `read_only`, y meterle material criptográfico rompería esa propiedad y me obligaría a reconstruir la imagen en cada renovación. Separando responsabilidades, puedo reconstruir o reemplazar el contenedor del frontend cuantas veces quiera sin tocar los certificados, y el ciclo de vida del TLS queda desacoplado del ciclo de despliegue de la aplicación.

### 109. ¿Cómo le comunicas al contenedor de Docker que espere 25s antes de forzar el apagado (Graceful Shutdown)?

Matizo el dato: a nivel de contenedor la espera real es de 30 segundos, no 25. Se lo indico a Docker con la directiva `stop_grace_period: 30s` en backend y worker: tras enviar SIGTERM, Docker espera 30 segundos antes del SIGKILL. Los 25 segundos son otra cosa, son el vigía interno de la propia aplicación: si el apagado ordenado no termina en 25 segundos (`SHUTDOWN_TIMEOUT_MS`), el proceso se autotermina. Y está deliberadamente por debajo de los 30 de Docker, para que dé tiempo a persistir el log y hacer flush de Sentry antes de que Docker lo mate a lo bruto. La secuencia ordenada es: marcar readiness en 503, drenar 5 segundos las peticiones en vuelo, cerrar HTTP y sockets, cerrar BullMQ y desconectar Mongo y Redis. Docker espera 30; yo apunto a terminar en menos de 25.

### 110. ¿Cómo coordinas el `limit_req` de Nginx con el `express-rate-limit` del backend para un bloqueo coherente?

Los concibo como dos capas complementarias. En el borde, Nginx aplica `limit_req_zone` por IP: 20 req/s para `/api/` con ráfaga de 40, y 10 req/s para `/socket.io/` con ráfaga de 20, devolviendo 429. Esta capa absorbe barato las inundaciones volumétricas antes de que toquen a Node. En la aplicación, express-rate-limit trabaja con ventanas largas (15 minutos), por identidad y por endpoint, respaldado por un store en Redis compartido, así que el límite sobrevive a reinicios y es coherente entre procesos; responde 429 con mensaje en español y cabeceras `Retry-After`. La coherencia viene de dos detalles: ambos emiten 429, y el backend lee la IP real vía `trust proxy` sobre `X-Forwarded-For`, así que no agrupa a todos bajo la IP de Nginx. Borde para el abuso bruto, aplicación para los límites de negocio y el bloqueo de cuenta.

### 111. ¿Cómo inyectas secretos desde `/opt/eduplay/secrets/` en Docker Compose sin exponerlos en el historial?

El paso de despliegue copia el fichero de entorno persistente de ese directorio al del proyecto: `cp /opt/eduplay/secrets/prod.env .env`, y Compose lo consume con `env_file: .env`. Esa carpeta vive solo en el disco de la VPS, es propiedad del usuario `deploy` sin privilegios y con permisos restringidos (`chmod 600`), fuera del repositorio. La ventaja clave es que los secretos nunca aparecen en la línea de comandos, así que no quedan en el historial de shell ni en los argumentos del proceso; tampoco se hornean en la imagen ni se commitean. Compose los lee como variables de entorno en tiempo de arranque. Rotar un secreto es editar ese fichero y relanzar el despliegue; nada más se toca. Es exactamente lo contrario a pasarlos inline en el comando, que sí quedaría registrado.

### 112. Si escalas el backend a `scale=2` en la misma VPS, ¿qué problemas de estado en memoria tendrías con los sockets?

El motor de juego es stateful en la memoria del proceso: `activePlays` y el mapa de UID a partida viven ahí, no en Redis. Y cada conexión Socket.IO vive en la instancia que aceptó su handshake. Con `scale=2` y sin sesiones sticky, la reconexión o el polling de un cliente podría caer en la otra instancia, que no tiene ni su sala ni su partida en memoria: el juego se rompe. Sí incluyo en el código el adaptador Redis de Socket.IO, pero desactivado tras el interruptor `SOCKET_ADAPTER_ENABLED`. Y aquí el matiz importante: ese adaptador solo resuelve el fan-out de los broadcasts entre instancias; no externaliza el estado del motor ni da stickiness al handshake. Un escalado horizontal real del gameplay exigiría además sesiones sticky y migrar el estado del motor a Redis. Por eso `scale=1` es hoy un invariante deliberado.


---

## Bloque 18: Integración y Despliegue Continuo (CI/CD)

### 113. ¿Qué criterios exactos debe cumplir el endpoint de `/api/health/ready` para que el CD no haga rollback?

`/api/health/ready` devuelve 200 solo si se cumplen a la vez cuatro condiciones: MongoDB conectado (`readyState === 1`), Redis conectado y con su circuit breaker no abierto (Redis es crítico solo en producción; en desarrollo se tolera caído porque hay fallback en memoria), el servidor no está en apagado (`isShuttingDown` falso) y ha terminado su arranque (`isReady` verdadero). Cualquier fallo devuelve 503. El despliegue lo sondea por loopback, ocho intentos de quince segundos: en producción hace rollback si cinco o más fallan, en staging si menos de tres pasan, y en ese caso reconstruye el tag o commit anterior marcado como bueno. Es a propósito un endpoint barato, solo booleanos y `readyState`, sin queries pesadas, para poder consultarlo con frecuencia sin generar carga ni tráfico de red extra.

### 114. ¿Qué medidas de seguridad tomaste al usar un *runner* autoalojado de GitHub Actions para evitar accesos externos?

El repositorio es público y un runner autoalojado en la VPS de producción es un riesgo conocido: una PR desde un fork podría ejecutar código arbitrario con acceso a los secretos reales. Mi regla no negociable es que la etiqueta de ese runner (`contabo-vps`) solo se usa en workflows disparados por push, tags, `workflow_run` o `workflow_dispatch`, nunca por `pull_request`. Así, ninguna contribución externa se ejecuta en la máquina sin que un colaborador la haya fusionado o lanzado antes. Toda la CI no confiable (build, CodeQL, Gitleaks, ZAP) corre en runners gestionados por GitHub, sin acceso a la VPS. Además, el runner se ejecuta como el usuario `deploy` sin privilegios de root (solo en los grupos `sudo` y `docker`, y ningún workflow invoca `sudo`), y la máquina tiene ufw y fail2ban. Los checkouts van con `persist-credentials: false`.

### 115. El pipeline aplica un "bundle budget". ¿Qué acciones tomaste (ej. lazy loading) al superar ese umbral?

El pipeline impone dos umbrales: el `dist` total por debajo de 6 MB y el JS comprimido en gzip por debajo de 900 KB, hoy en torno a 600. Si se superan, el build falla. Para mantenerme por debajo, aplico dos técnicas. Primero, división en chunks manuales por librería en Vite (react-core, framer-motion, recharts, socket.io, sentry, qrcode...), combinada con carga diferida de las páginas mediante `React.lazy` y `Suspense`: así, dependencias pesadas que solo usa la analítica, como Recharts, o el QR que solo aparece en el alta de MFA, no entran en el bundle inicial. Sentry se inicializa diferido en tiempo ocioso. Y Vite genera variantes Brotli y gzip precomprimidas más source maps ocultos. Cuando una dependencia pesada justifica superar el presupuesto, la norma es documentarlo en la PR y subir el umbral conscientemente, no en silencio.

### 116. Si subes un secreto accidentalmente al repo, ¿por qué borrarlo en el siguiente commit no basta para Gitleaks?

Porque Git conserva todo el historial. El secreto sigue vivo en el commit anterior, y en cualquier rama, tag o reflog que apunte a él; borrarlo en un commit posterior no lo elimina, cualquiera puede hacer `git log` o checkout de ese commit viejo y leerlo. Por eso Gitleaks hace checkout con `fetch-depth: 0` y escanea el historial completo, no solo el diff, y además tengo un cron semanal que rebarre todo el árbol por si algo se coló por una rama que no pasó por PR. La remediación real es doble: primero rotar de inmediato la credencial filtrada, dándola por comprometida, y después reescribir el historial (con filter-repo o BFG y force-push) para purgar ese blob. Borrarlo en el siguiente commit es puramente cosmético; el valor ya está expuesto.

### 117. ¿Por qué no incluir el escaneo de OWASP ZAP en cada commit en lugar de hacerlo mensualmente?

Porque el baseline de ZAP rastrea y sondea de forma dinámica una aplicación en marcha: necesita el stack completo levantado (la URL de staging) y tarda varios minutos, tengo el spider y el escaneo activo limitados a cinco minutos cada uno. Ejecutarlo en cada commit sería lento, propenso a fallos intermitentes y casi siempre redundante: la superficie expuesta rara vez cambia de un commit a otro, y es una comprobación dinámica, no una puerta de código. En cada commit ya corro las puertas rápidas y estáticas: lint, `npm audit`, CodeQL como SAST, Gitleaks, tests y el presupuesto de bundle. ZAP lo lanzo mensual contra staging, más bajo demanda cuando quiero, como barrido dinámico periódico. Es suficiente para cazar desviaciones de configuración o regresiones sin atascar el pipeline ni gastar minutos de la capa gratuita.

### 118. Usas `release-please`. Si necesitas un hotfix urgente en producción, ¿cómo altera esto tu flujo de etiquetas?

En el flujo normal, release-please mantiene una PR de release rodante; al fusionarla, calcula la versión desde los Conventional Commits y crea el tag `v*`, que dispara el despliegue a producción. Para un hotfix urgente no espero a esa PR: llevo el arreglo a `main` con un commit `fix:`, y tengo dos caminos. Puedo dejar que release-please genere el parche (un `fix:` produce un incremento de PATCH, por ejemplo de 1.0.0 a 1.0.1) y fusionar su PR; o, si lo necesito fuera ya, corto el tag SemVer manualmente o lanzo `deploy-production` con `workflow_dispatch` indicando el tag. En ambos casos el arreglo pasa por la misma cadena: tag, despliegue, smoke test y rollback automático si falla. Después, release-please reconcilia su changelog y su manifiesto a partir de ese tag, de modo que el flujo automatizado no se queda desincronizado.


---

## Bloque 19: Planificación y Gestión de Proyecto

### 119. ¿Cómo gestionaste la Definición de Hecho (DoD) para no sacrificar calidad ante la presión de la entrega?

La Definición de Hecho la dejé con cinco criterios y, sobre todo, la hice mecánica para que la presión no pudiera saltársela. Una tarea no está hecha hasta que el código funciona, los tests están en verde, la documentación está actualizada, los criterios de aceptación verificados y el pipeline de integración pasa. La clave es que esos criterios no dependen de mi juicio en un mal día: la integración continua los verifica sola. Tengo puertas de cobertura mínima, un presupuesto de tamaño de bundle y el lint como bloqueantes; si algo baja del umbral, el pipeline falla y no se integra. Y las ventanas de mantenimiento absorbían la estabilización, así que las fechas no se comían la calidad. La disciplina la sostiene la máquina, no la fuerza de voluntad.

### 120. Los últimos sprints tienen hasta 150h. ¿Fue planificación deliberada o subestimación inicial de complejidad?

Fue mayoritariamente deliberado, con una pizca honesta de subestimación al principio. La rampa creciente, de sesenta horas al inicio hasta ciento cincuenta en el último, refleja que los primeros sprints construyen infraestructura y fundamentos, más acotados, y los últimos abordan funcionalidades más complejas: la tercera mecánica de extremo a extremo, el despliegue real y el endurecimiento de seguridad, que tocan muchas capas a la vez. Dicho eso, reconozco que el primer sprint lo estimé optimista: su retrospectiva destapó tests rotos, estado volátil y acoplamiento al USB, deuda que pagué después. Por eso las ventanas de mantenimiento suman unas noventa horas: son, en parte, esa corrección honesta. Así que planifiqué la rampa a propósito, pero el calendario también aprendió de mis primeras estimaciones.

### 121. ¿Por qué sacar las ventanas de mantenimiento fuera de los sprints en lugar de integrarlas como tareas?

Porque es un tipo de trabajo distinto y quería que el cronograma lo dijera con honestidad. El sprint produce un incremento de funcionalidad que termina en una versión etiquetada. La ventana de mantenimiento hace otra cosa: preparar esa release, ejecutar la QA sobre la entrega recién cerrada, corregir defectos de estabilización, refinar el backlog siguiente y escribir la retrospectiva. Si lo metiera como tareas dentro del sprint, difuminaría la frontera del incremento y ya no sabría cuánto esfuerzo fue construir y cuánto consolidar. Separarlas mantiene limpia la trazabilidad y da un Gantt veraz: las barras grises no son huecos muertos, son tiempo de proyecto. En un TFG donde el proceso se evalúa, esa transparencia vale tanto como el código.

### 122. El Sprint 2 se dedicó a deuda técnica. ¿Qué funcionalidades pedagógicas tuviste que retrasar por ello?

El coste fue retrasar el gameplay jugable de las mecánicas. Tras el primer sprint solo tenía un motor de juego esquelético, un ciclo elemental de asociación. Las mecánicas de Asociación y Memoria completas, de extremo a extremo y en tiempo real, no llegaron hasta el cuarto sprint, y la tercera, Secuencia, hasta el sexto. Al dedicar el segundo sprint a estabilizar, esas piezas pedagógicas visibles se corrieron en el calendario. Ahora bien, lo asumo como la decisión correcta: construir las mecánicas sobre un estado que se perdía al reiniciar y una lectura RFID atada al servidor habría significado rehacerlas después. Preferí que el juego llegara algo más tarde pero sobre cimientos sólidos, que es lo que permitió luego añadir mecánicas sin tocar el núcleo.

### 123. ¿Hubo algún punto donde una decisión técnica te obligara a un salto de versión mayor (v1.0.0)?

El salto a la versión uno punto cero no lo forzó una sola decisión que rompiera compatibilidad; fue una declaración deliberada de estabilidad. Bajo versionado semántico, las versiones cero indican una interfaz que todavía evoluciona, y la uno punto cero es el compromiso de que el contrato es estable y lo mantengo. Lo justifiqué por la suma de tres cosas al cerrar el último sprint: completar las tres mecánicas previstas, llevar el sistema a producción real y aplicar el endurecimiento de seguridad y la observabilidad. Es decir, completitud funcional más robustez. Más tarde, la migración a la VPS obligó al conjunto de réplicas para las transacciones atómicas, que reforzó esa robustez, pero la etiqueta en sí marcó que el producto ya era estable y defendible, no una reacción a un cambio puntual.

### 124. En tu estimación de costes, ¿por qué incluiste la Seguridad Social y el IVA siendo un proyecto académico?

Porque el objetivo de esa estimación no es lo que yo cobro, que es cero, sino contextualizar cuánto costaría este trabajo como encargo profesional equivalente en el mercado español. Y un coste realista no es solo las horas por la tarifa: un empleador paga además la cotización a la Seguridad Social, un treinta coma sesenta y cinco por ciento del régimen general, y una factura de servicios lleva su IVA al veintiuno por ciento. Omitirlos daría una cifra engañosamente baja. Con ochocientas cuarenta horas a dieciocho euros salen quince mil ciento veinte de personal; sumando cotización e indirectos, veintiún mil doscientos ochenta y uno; con el IVA, unos veinticinco mil setecientos cincuenta euros. Lo presento como una valoración honesta del esfuerzo a precio de mercado, no como un precio comercial.


---

## Bloque 20: Lecciones y Puntos Ciegos del Proceso

### 125. Cuando Koyeb quitó su capa gratuita, ¿tuviste que degradar algún requisito funcional por la nueva VPS?

Ningún requisito funcional se degradó: la lógica de negocio quedó intacta y la migración fue puramente de infraestructura. Lo que cambió fueron aspectos operativos y no funcionales. Perdí la capa gestionada de red de distribución y cortafuegos de aplicación en el borde, que compensé con limitación de tráfico en profundidad, encadenada entre Nginx, Express y Socket.IO. Las copias de seguridad pasaron de servicio gestionado a responsabilidad mía. Y MongoDB tuvo que convertirse en un conjunto de réplicas de un nodo para preservar las transacciones atómicas. Es decir, el usuario final no perdió ninguna capacidad; lo que asumí fue una carga operativa mayor. Fue, de hecho, la lección más valiosa: un sistema bien instrumentado y con infraestructura como código absorbe un cambio de proveedor sin reescribir producto.

### 126. Tienes 72% de cobertura. ¿Cómo validaste módulos críticos que decidiste no testear automáticamente?

Ese setenta y dos por ciento concentra las pruebas automáticas en la lógica de negocio, donde son deterministas y rentables. Los módulos más críticos, el tiempo real y el camino del hardware RFID, son los más difíciles de cubrir con tests unitarios fiables, así que los validé de otra forma. Primero, con QA de extremo a extremo dirigida por mí, recreando partidas completas con un simulador de sensor, porque el lector físico se averió; el simulador reproduce el protocolo real, incluida la firma criptográfica. Segundo, con Sentry en producción, que afloró en las primeras horas de uso errores que las pruebas manuales no veían. Y tercero, con auditorías de calidad exhaustivas al cerrar cada versión, que destapan puntos ciegos que la automatización no detecta. Es cobertura en capas, no solo un número.

### 127. En el despliegue autoalojado, ¿has automatizado backups de MongoDB fuera de la VPS para evitar desastres?

Voy a ser transparente: todavía no está automatizado, y es mi principal tarea operativa pendiente. El diseño está definido: un volcado nocturno de MongoDB con rotación local de catorce días y una copia semanal fuera de la máquina a un bucket privado de Supabase, separado de los assets del juego. El directorio de copias y el almacén de secretos ya están aprovisionados en la VPS, pero el trabajo programado y el script de la copia externa están pendientes de instalar. Ahora mismo, por tanto, un fallo total de disco o de proveedor es un punto único de fallo real, y no lo voy a maquillar. En el plan original en la nube esto lo cubrían las copias gestionadas de Atlas; al autoalojar, la responsabilidad pasó a mí y la copia externa es lo primero que cerraría.

### 128. Si la conexión a Internet de la VPS falla, ¿se pierden los logs de Grafana Loki o hay buffer en Docker?

No se pierden, porque hay dos flujos. El primario es el driver de logging de Docker, que escribe cada línea, el JSON estructurado de Pino, a disco local en la VPS con rotación. Eso es independiente de la red: una caída de Internet nunca borra el log local. El envío a Grafana Cloud Loki es un flujo secundario, mediante el transporte pino-loki, que agrupa en lotes cada pocos segundos. Durante un corte, ese envío se pausa con un búfer en memoria acotado, así que un corte largo o un reinicio podrían dejar un hueco en Loki. Pero nada se pierde de verdad: la fuente en disco está intacta y es rellenable. El límite honesto: no corro un agente con cola durable que reproduzca el histórico solo, y sería un endurecimiento futuro razonable.

### 129. ¿Cómo evitas que el CI se ejecute para todas las capas (HW/FW/Web) si solo cambias el README?

Con filtros de rutas en el propio workflow. La pipeline principal ignora explícitamente los cambios que no afectan al código desplegable: todos los ficheros Markdown, las carpetas de documentación, las notas de desarrollo, la licencia y, muy relevante para tu pregunta, la carpeta del firmware del lector. Así, un cambio solo en el README, o solo en documentación, o solo en el firmware, no dispara la pipeline web de lint, tests y build: sería quemar minutos de cómputo sin sentido. Y añado un mecanismo de concurrencia que cancela ejecuciones anteriores de la misma rama cuando llega un empuje nuevo, para no acumular trabajos redundantes. La capa de hardware y firmware tiene sus propias preocupaciones y no la valida esta pipeline de Node, precisamente por eso queda excluida de sus rutas.

### 130. ¿Podrías dar un ejemplo de una decisión del Sprint 1 que quisieras cambiar en el Sprint 6 pero no pudiste?

La más honesta es haber fijado todo el stack en JavaScript puro, sin tipado estático, en el primer sprint. Para arrancar rápido y explorar el hardware fue lo ágil, pero al llegar al último sprint el código ya era grande y un sistema de tipos habría atrapado clases enteras de errores antes de ejecutar. El problema es que reconvertir ochocientas horas de JavaScript a mitad de proyecto no compensaba el riesgo, así que no pude cambiarlo y lo compensé con validación en tiempo de ejecución mediante Zod, con DTOs y con tests. Es interesante el contraste: otros errores de aquel primer sprint, como guardar el estado en memoria o leer el RFID en el servidor, sí eran reversibles y los revertí en los sprints siguientes. La elección de lenguaje, en cambio, es la que de verdad se queda anclada.


---

## Bloque 21: Diseño Pedagógico y Mecánicas de Juego

### 131. ¿Por qué precisamente estas tres mecánicas (Asociación, Memoria y Secuencia) y no otras?

Porque cada una entrena una función cognitiva distinta del rango de cuatro a ocho años y, juntas, cubren una progresión. Asociación trabaja la relación concepto-imagen: categorización y vocabulario, con un acierto por ronda. Memoria trabaja la memoria de trabajo visual y la localización espacial, con un tablero de parejas boca abajo. Secuencia trabaja la memoria secuencial y el orden, que tocan funciones ejecutivas de planificación, reproduciendo una serie en el orden correcto. No pretendo que sean exhaustivas; son representativas. Y hay un segundo motivo, de ingeniería: son estructuralmente muy diferentes —turno simple, emparejamiento en tablero y secuencia ordenada multipaso—, así que si un mismo motor las sostiene las tres mediante el patrón Strategy, queda demostrado que añadir una cuarta no tocará el núcleo.

### 132. ¿Cómo se calcula la puntuación de una partida y qué es el "techo teórico" de puntos?

El alumno suma unos puntos por acierto configurables por el docente, con penalización opcional por error, y sobre eso calculo un techo teórico: la puntuación máxima alcanzable en una partida perfecta. La fórmula depende de la mecánica: en Asociación es rondas por puntos; en Memoria es número de parejas —cartas entre el tamaño de grupo— por puntos; en Secuencia es la suma de la longitud de cada ronda por puntos. Ese techo importa por dos razones. Una, el modelo lo usa como límite absoluto: cualquier incremento que lo supere se recorta, y la puntuación tampoco baja de cero. Y dos, el porcentaje de dominio que ve el docente es puntuación entre techo; calcularlo bien por mecánica corrigió un fallo real en que una partida de Asociación mostraba treinta sobre treinta, un cien por cien falso.

### 133. ¿No es contraproducente puntuar y clasificar a niños de cuatro a ocho años? ¿No fomenta una competición dañina?

Corrijo la premisa, porque es importante: no clasifico a unos niños frente a otros. No hay ranking de alumnos ni podio comparativo que el niño vea. Lo que sí existen son leaderboards, pero rankean contenido —qué contextos y qué mecánicas funcionan mejor— y son una herramienta de analítica para el docente, nunca una tabla de niños. El alumno solo ve su propio resultado, como refuerzo positivo inmediato, nunca en comparación con un compañero. La puntuación es intrínseca, "cómo lo he hecho yo", no social. Y la mascota usa lenguaje no punitivo: celebra el acierto y anima tras el error, sin recriminar. Fue una decisión deliberada: la competición entre iguales a estas edades desmotiva precisamente al niño que va más rezagado, que es justo a quien la plataforma quiere detectar y apoyar.

### 134. La mascota usa un tono emocional. ¿Por qué un acompañante afectivo y no una retroalimentación neutra?

Porque a estas edades el andamiaje afectivo es parte del aprendizaje. Un niño de cuatro años responde a una presencia que celebra, anima y acompaña mucho mejor que a un número o un tic verde. La mascota es el canal de retroalimentación emocional que sustituye al texto que el niño aún no lee: reacciona con un estado de ánimo y una frase calibrados a cada disparador —acierto, racha, error sostenido, inactividad—, con enfriamientos para no agobiar y sin ningún mensaje negativo. Cumple además una función que el sistema entero persigue: sostener la ilusión de que la tarjeta física provoca la reacción, manteniendo al niño enganchado sin nada que leer. No es decoración; es el canal por el que el sistema le habla al alumno.

### 135. Sin un sistema adaptativo, ¿cómo ajustas la dificultad a distintas edades dentro del rango de cuatro a ocho años?

La ajusta el docente, que es quien conoce al niño. Al crear la sesión configura número de rondas, tiempo por ronda, puntos, penalización, nivel de dificultad y tamaño del mazo o del tablero; con el mismo asistente, un grupo de cuatro años y otro de ocho reciben sesiones distintas. La adaptación automática de la dificultad en tiempo real la dejo explícita como línea futura. Y es una decisión, no solo una limitación: prefiero mantener el criterio en manos del docente, que está presente en el aula, antes que construir un sistema que infiera el nivel del menor, porque eso rozaría el perfilado que quiero evitar con datos de niños. La flexibilidad la da la configuración; el juicio pedagógico lo pone la persona.


---

## Bloque 22: Seguridad — Fundamentos y Modelo de Amenazas

### 136. ¿Con qué algoritmo y coste almacenas las contraseñas, y por qué?

Con bcrypt y un factor de coste diez, aplicado en un hook previo al guardado que solo re-hashea si la contraseña ha cambiado; nunca guardo nada en claro. Bcrypt es un algoritmo adaptativo y deliberadamente lento, con una sal única por usuario, así que anula las tablas precalculadas y encarece mucho la fuerza bruta; el coste diez equilibra latencia de login y resistencia, y es subible si hiciera falta. La comparación va con la función propia de bcrypt, no con una igualdad ingenua. Un matiz importante de minimización: solo los docentes y administradores tienen contraseña; los alumnos no tienen credenciales, y el modelo rechaza activamente que un estudiante lleve email o contraseña. Y el hash nunca sale en las respuestas, porque los DTOs no exponen el documento crudo. Los códigos de respaldo del MFA también se guardan hasheados con bcrypt.

### 137. Las tarjetas MIFARE se pueden clonar con facilidad. ¿No compromete eso la integridad del juego?

Matizo: es cierto que el UID de una MIFARE se puede copiar, pero en mi modelo de amenazas eso no importa, porque el UID no es un secreto ni es la frontera de seguridad. La tarjeta es un token fungible: identifica qué imagen o concepto se ha acercado, no a una persona ni un derecho. Lo que protege la integridad no es la tarjeta, es el canal: el lector firma cada lectura con HMAC-SHA256 y un contador monótono, así que el backend solo confía en lecturas que vengan del lector legítimo, y clonar una tarjeta no falsifica esa firma. Además, el "atacante" aquí es un niño de cuatro a ocho años en un aula supervisada, no un adversario: clonar la tarjeta del perro para volver a escanear "perro" no le da absolutamente nada. Por eso el clonado de tarjetas queda, por diseño, fuera de alcance.

### 138. Explicaste la cookie httpOnly para el refresh. ¿Cómo protege el CSRF de doble cookie las operaciones de escritura y por qué no basta SameSite?

La cookie httpOnly evita que roben el refresh, pero una petición que cambia estado —POST, PUT, DELETE, PATCH— todavía necesita demostrar que sale de mi aplicación y no de un formulario falso en otra web. Ahí entra el doble envío: el servidor emite una cookie csrfToken que sí es legible por JavaScript; mi cliente la lee y la reenvía en la cabecera x-csrf-token; el servidor comprueba que cabecera y cookie coinciden. Una página atacante puede lograr que el navegador envíe la cookie, pero no puede leerla para construir la cabecera, por la política del mismo origen, así que la comprobación falla y rechazo la petición. Además verifico Origin y Referer. ¿Por qué no solo SameSite? SameSite estricto ayuda, pero su comportamiento no es uniforme en todos los navegadores y casos límite, ni cubre sub-orígenes del mismo sitio; el doble envío es defensa en profundidad. Login y registro quedan exentos, porque aún no hay sesión.

### 139. ¿Por qué el token de acceso dura solo quince minutos frente a los del refresh, y qué gana esa asimetría?

Es una asimetría deliberada por radio de impacto. El token de acceso viaja en cada petición y vive en memoria del cliente: al durar quince minutos, uno robado o filtrado caduca enseguida, y encima lo contrasto contra una blacklist en Redis que permite revocarlo al instante. El refresh es lo contrario: dura siete días, va en una cookie httpOnly, solo viaja a la ruta de autenticación, se rota en cada uso y está atado a una huella del dispositivo. Es decir, la credencial que más se expone es barata y efímera, y la de vida larga apenas se expone y está muy protegida. Como la renovación es silenciosa a través del refresh, el usuario no nota que su acceso caduca cada cuarto de hora. Minimizo el daño de una fuga sin castigar la experiencia.

### 140. ¿Cómo evitas la inyección NoSQL en las consultas a MongoDB, teniendo en cuenta que Mongoose no es inmune por sí solo?

Por capas, y la principal es la validación en la frontera con Zod. Cada cuerpo, query y parámetro se tipa antes de tocar la lógica: donde espero una cadena, obtengo una cadena, así que un atacante no puede colar un objeto como un `$ne: null` en un filtro, que es la inyección NoSQL clásica. Después, Mongoose castea a los tipos del esquema y rechaza operadores malformados. Las consultas se construyen desde una lista blanca con un generador de filtros, de modo que la entrada del usuario nunca se convierte en claves crudas de la query, y no uso `$where` ni ningún operador tipo evaluación con datos del usuario. Los esquemas de Zod además bloquean formas de contaminación de prototipo. En resumen, la inyección se frena en la frontera de tipos, antes de llegar al driver.


---

## Bloque 23: Cumplimiento Normativo (RGPD) en Profundidad

### 141. ¿Cuál es la base jurídica del tratamiento de los datos del menor y por qué el consentimiento y no el interés legítimo?

El consentimiento del titular de la patria potestad o tutela: Artículo 6.1.a más Artículo 8 del RGPD, y Artículo 7 de la LOPDGDD. Elegí el consentimiento y no el interés legítimo por la naturaleza del sujeto. España fija en catorce años la edad para consentir uno mismo; mis usuarios tienen de cuatro a ocho, así que el consentimiento procede siempre de los padres. Para datos de menores, especialmente vulnerables, y donde los tiempos de respuesta y los patrones de error podrían insinuar dificultades de aprendizaje, apoyarse en el interés legítimo exigiría superar un juicio de ponderación muy difícil de ganar; el consentimiento es la base más clara y defendible. Con los docentes es distinto: sus propios datos se tratan por Artículo 6.1.b, ejecución de contrato, y 6.1.f, interés legítimo en la seguridad. Todo ello queda registrado en el Registro de Actividades de Tratamiento.

### 142. ¿Realizaste una Evaluación de Impacto (EIPD)? ¿Cuál es el riesgo residual más alto que identificaste?

Sí, y aquí era obligatoria: la lista de la AEPD conforme al Artículo 35.4 incluye expresamente el tratamiento de datos de menores de catorce años como criterio que obliga a una EIPD, y seguí la metodología de las directrices WP248. El riesgo residual más alto que identifiqué fue el que numero como R-14. Originalmente lo planteé como fuga de datos entre centros en un escenario multiinquilino; tras migrar a la VPS lo redefiní como acceso no autorizado a los datos de un tutor y aislamiento dentro del mismo host, con un riesgo residual más bajo, porque ahora hay un único responsable por instancia. Las mitigaciones son el control de acceso por roles con las operaciones RGPD centralizadas en el administrador, la seudonimización con HMAC, la k-anonimidad, el cifrado en tránsito y la minimización. Está documentado en el anexo de protección de datos.

### 143. ¿Dónde está el Registro de Actividades de Tratamiento y quién es el responsable frente al encargado?

Existe un RAT conforme al Artículo 30, y lo importante es que fija los papeles. El responsable del tratamiento es el centro educativo que usa la plataforma; Eduplay, mi TFG, es el encargado del tratamiento. Esa distinción es capital: el centro decide los fines y los medios y es quien custodia los consentimientos firmados de las familias; mi plataforma aporta la herramienta y las garantías técnicas y organizativas. El registro documenta, para cada actividad —el seguimiento básico de juego y la analítica de rendimiento—, los fines, las categorías de interesados y de datos, los destinatarios, los plazos de supresión y las medidas de seguridad. Es la materialización del principio de responsabilidad proactiva del Artículo 5.2: no basta con cumplir, hay que poder demostrarlo.

### 144. Has hablado mucho del borrado. ¿Cómo garantizas el derecho de acceso y el de portabilidad?

No solo cubro la supresión. El acceso lo resuelve la propia aplicación: el docente y el administrador consultan el expediente completo de su alumno, y toda respuesta de dominio pasa por DTOs, así que la exposición está controlada. La portabilidad, el Artículo 20, se atiende exportando los datos que el interesado proporcionó en un formato estructurado y de lectura mecánica, JSON, y generando informes que además se pueden imprimir. La oposición, el Artículo 21, es granular: un padre puede retirar solo la finalidad de analítica de rendimiento y el niño sigue jugando. Es decir, el conjunto completo de derechos —acceso, portabilidad, oposición y supresión— está implementado, no únicamente el borrado, que es el que suele acaparar la atención.

### 145. Si el tribunal pregunta quién responde legalmente ante la AEPD por una brecha, ¿el centro o tú?

El centro, como responsable del tratamiento. Es quien decide los fines y los medios y quien mantiene la relación con las familias y con la Agencia; mi plataforma es el encargado, que actúa según las instrucciones del centro y está obligado a asistirle: notificarle sin dilación indebida cualquier brecha, aportarle los campos del Artículo 33.3 y facilitarle la evidencia técnica. Por eso la responsabilidad en primera línea ante la AEPD es del centro, y mi deber es habilitar y documentar el cumplimiento —el procedimiento de brecha, los registros, las plantillas— para que el centro pueda responder en las setenta y dos horas. Esa división de papeles es exactamente lo que recoge el RAT.


---

## Bloque 24: Decisiones de Stack Tecnológico

### 146. ¿Por qué Node.js para un sistema con requisitos de tiempo real, y no un lenguaje compilado?

Porque la carga es de entrada/salida en tiempo real, no de cálculo intensivo. El bucle de eventos monohilo y no bloqueante de Node es ideal para sostener muchas conexiones de socket a la vez y reenviar mensajes pequeños con poco coste, que es justo el reparto de escaneos RFID. Un lenguaje compilado me daría potencia de CPU que aquí no necesito, a cambio de perder la consistencia de tener JavaScript de punta a punta, con el mismo lenguaje en navegador y servidor y formas de validación compartidas. Y aclaro un malentendido frecuente: el presupuesto de cincuenta milisegundos es el del feedback que se pinta localmente en el navegador, no depende del cálculo del servidor. Lo poco que sí es intensivo —criptografía, procesado de imágenes— lo delego en enlaces nativos, como bcrypt o sharp, o en el worker. Es la herramienta adecuada para un sistema de E/S en tiempo real.

### 147. ¿Por qué Zod para la validación en lugar de Joi o de confiar solo en Mongoose?

Zod define la forma una sola vez y la usa a la vez para validar en ejecución y para documentar el contrato, aplicada como middleware en la frontera. Frente a Joi, mejor ergonomía e inferencia de tipos, y es el estándar actual del ecosistema que verifiqué antes de adoptarlo. Frente a validar solo con Mongoose, la diferencia es dónde ocurre: Mongoose valida al persistir, demasiado tarde y demasiado adentro; yo quiero rechazar una petición malformada en el borde, antes de que toque la lógica de negocio o la base de datos, y también en lecturas y consultas que nunca llegan a un guardado de Mongoose. Al final es defensa en profundidad: Zod en la frontera, Mongoose en la persistencia y un validador de entorno en el arranque. Cada capa atrapa una clase distinta de error.

### 148. ¿Por qué usar Mongoose (un ODM) sobre el driver nativo de MongoDB?

El ODM me da tres cosas que el driver crudo no trae de serie. Primero, esquema y validación, una segunda red después de Zod. Segundo, y para mí lo más valioso, los hooks de ciclo de vida: el hasheo con bcrypt cuando cambia la contraseña, el recorte de la puntuación en el gameplay, la derivación de la dificultad, las comprobaciones de consentimiento. Esos invariantes viven centralizados en el modelo, no dispersos por los controladores. Y tercero, un sitio limpio donde colgar los métodos DTO para no devolver nunca documentos crudos. Además ofrece populate para los pocos joins que necesito y un casteo tipado que ayuda a frenar la inyección. El coste es una capa fina sobre el driver, que asumo de sobra por la seguridad y la consistencia que impone en toda la base de código.

### 149. ¿Por qué un monorepo con backend, frontend y firmware juntos y no repositorios separados?

Porque las tres capas evolucionan juntas y un historial único sirve mejor a un TFG. Un cambio que toca el protocolo RFID a menudo abarca a la vez firmware, navegador y backend; un monorepo permite que un solo commit atómico los mantenga coherentes y que una única integración continua razone sobre el conjunto. Además mantiene la documentación técnica, los ADRs y los cuatro subsistemas bajo una misma raíz versionada, que es exactamente lo que un proyecto académico necesita para la trazabilidad. Y no me cuesta cómputo desperdiciado: la integración continua usa filtros de rutas, así que un cambio solo en el firmware o solo en documentación no dispara la pipeline web. La atomicidad y la trazabilidad ganan; el coste típico del monorepo, los builds de más, lo evito con esos filtros.

### 150. ¿Por qué React con Vite y no un framework con renderizado en servidor como Next.js?

Porque es una SPA autenticada sin necesidad de SEO: cada pantalla vive detrás del login, así que el renderizado en servidor no aporta nada aquí, y las ventajas de indexación de Next no aplican. Y hay dos restricciones que empujan hacia cliente puro. Una, la Web Serial API solo funciona en el navegador, así que la lectura del RFID tiene que ejecutarse en cliente de todos modos. Dos, el juego en tiempo real es un cliente de socket con estado. Vite me da un ciclo de desarrollo rápido y un bundle estático optimizado que Nginx sirve como ficheros planos, mucho más sencillo de contenedorizar y desplegar que un servidor con renderizado. Stack más ligero, menos piezas móviles y ningún beneficio sacrificado.


---

## Bloque 25: Selección de Hardware RFID

### 151. ¿Por qué elegiste el ESP8266 y no un ESP32 o un Arduino con lector directo?

Por coste y suficiencia. La tarea es trivial para el microcontrolador —leer un UID por SPI, firmarlo y escupir una línea JSON por el puerto USB—, así que un ESP8266, de un par de euros, va sobrado; un ESP32 añadiría doble núcleo, Bluetooth y más RAM que no uso, y un Arduino pelado se quedaría corto de margen para el cálculo del HMAC. Un punto importante: no uso su WiFi. El sensor es, por diseño, un periférico USB tonto, así que la radio no fue un criterio de selección. Y el firmware del lector es una contribución de mi tutor sobre esta plataforma, de modo que mantenerme en la placa a la que apunta conservó limpia esa frontera. Es la placa más barata que hace el trabajo con holgura.

### 152. ¿Por qué RFID de 13,56 MHz (MIFARE) y no de baja frecuencia u otra tecnología?

Los 13,56 megahercios de alta frecuencia con MIFARE son el punto dulce para esto. Traen anticolisión estandarizada y un UID bien definido que leo con fiabilidad, un ecosistema enorme de tarjetas baratas —por debajo de cincuenta céntimos— y un alcance corto que encaja con la pedagogía: quiero un gesto intencional de uno a tres centímetros, no leer una tarjeta desde el bolsillo. Las etiquetas de 125 kilohercios de baja frecuencia son más simples pero más limitadas y con peor anticolisión para un aula llena de tarjetas a la vez. Y el módulo que gobierna los 13,56, el RC522, es el más barato y con mejor soporte. La frecuencia la elegí por el UID estándar, las tarjetas baratas y ese alcance corto deliberado.

### 153. El firmware del lector es una contribución de tu tutor. ¿Cómo delimitaste esa frontera y qué asumiste tú?

Con una división de responsabilidad honesta. El hardware del lector y su firmware son la aportación de mi tutor a la plataforma, y operativamente ese firmware es inmutable en campo: no hay actualización remota, se graba una vez por USB. Así que diseñé todo lo que sí es mío —la capa Web Serial del navegador y el backend— para no depender de poder parchear el sensor en tiempo de ejecución. La verificación del HMAC, el anti-replay, la deduplicación, el watchdog y la reconexión viven del lado de la aplicación y compensan defensivamente cualquier cosa que el sensor no pueda garantizar por sí solo. Por eso mismo rotar la clave HMAC es un reflasheo manual, como comenté. La frontera queda clara: el sensor es un componente fijo; la resiliencia la pongo yo alrededor, donde tengo control.


---

## Bloque 26: Funcionalidades, Roles y Multiusuario

### 154. ¿Cómo funcionan pausar y reanudar una partida sin perder el estado ni falsear los tiempos?

La partida tiene un estado de pausa con dos campos: el instante en que se pausó y el tiempo restante de la ronda actual en milisegundos. Al pausar, congelo la ronda: guardo exactamente el tiempo que quedaba, para que el reloj no siga corriendo mientras la clase está interrumpida, y el estado pasa a "en pausa". Un índice único parcial garantiza a nivel de base de datos que un alumno tenga como mucho una partida activa —en curso o en pausa— por sesión, así que no puedo arrancar un duplicado sin querer. Al reanudar, restauro ese tiempo restante y la ronda continúa. Como el temporizador autoritativo es el del servidor, la pausa es honesta: el niño recupera exactamente el tiempo que tenía, no se le penaliza porque el docente parase a explicar algo.

### 155. La impresión de un mazo a PDF: ¿por qué generarla en el servidor y qué problema resuelve?

Resuelve una necesidad física real: el juego necesita tarjetas impresas, y genero un PDF listo para imprimir de un mazo componiendo la imagen de cada carta —procesada con sharp— sobre una hoja imprimible, con la librería pdf-lib. Lo hago en el servidor, no en el navegador, por tres motivos: una salida consistente y de calidad independientemente del equipo del docente; el acceso a los assets originales y al mismo procesado de imagen que la plataforma ya usa; y quitarle ese trabajo pesado al cliente. Así, un docente construye un mazo en digital e imprime las cartas físicas correspondientes desde la misma fuente de verdad, sin diseñar nada a mano y sin riesgo de que la imagen impresa no case con el mapeo de la tarjeta. Está recogido en un ADR propio.

### 156. ¿Cómo se pone en marcha a un docente nuevo sin manual de usuario?

Con un tour guiado por rol, no con un manual. En el primer uso, la aplicación lanza un recorrido paso a paso que resalta elementos reales de la interfaz mediante anclas colocadas en el propio DOM, con un itinerario distinto según el rol —administrador o docente—, de modo que cada uno ve solo lo relevante para su trabajo. Está atado a la cuenta, así que no reaparece una vez completado, y sobrevive a la navegación entre pantallas. La filosofía es la misma que la del producto entero: la interfaz debe enseñarse sola. Para un docente que solo quiere lanzar una sesión, el tour más la revelación progresiva del asistente hacen que no necesite documentación para llegar a su primera partida.

### 157. ¿Por qué separaste los roles de administrador (Jefe de Estudios) y docente en vez de un único rol de gestión?

Por separación de funciones, guiada por la protección de datos. El administrador —el Jefe de Estudios— es el operador del lado del responsable: altas y bajas de alumnos, consentimiento parental, el borrado en cascada del derecho al olvido, el desbloqueo de cuentas. El docente es el usuario pedagógico: mazos, sesiones, jugar y ver a sus propios alumnos. Fundir ambos en un solo rol daría a cada docente las llaves de todos los datos de menores del centro, lo que viola la minimización y el mínimo privilegio. Separarlos reduce la superficie que expondría una cuenta docente comprometida a su propia aula, y concentra las operaciones peligrosas del RGPD tras un rol protegido con MFA. Refleja además la organización real: una persona gobierna el centro, muchas enseñan.

### 158. ¿Cómo garantizas que un docente solo ve a SUS alumnos y no a los de otro compañero?

La propiedad se impone en la capa de datos, no se da por supuesta. Cada alumno y cada sesión guardan quién los creó, y los servicios de analítica y de consulta filtran por la identidad del docente que pregunta: sus endpoints solo devuelven a sus propios alumnos, no existe una vista de "todos los alumnos" para un docente. El único rol que ve a través de todo el centro es el administrador. Es la contraparte, en HTTP y datos, de la comprobación de propiedad de sala que describí para el tiempo real: conocer un identificador nunca basta, el servidor siempre verifica que quien pide es el dueño del recurso o el Jefe de Estudios, y en caso contrario registra el intento como evento de seguridad. Aislamiento por docente, por defecto.


---

## Bloque 27: Defensa, Límites Honestos y Aportación

### 159. Si tuvieras que señalar la mayor debilidad o limitación honesta de tu proyecto hoy, ¿cuál sería?

La más honesta es operativa, no del producto: las copias de seguridad de MongoDB fuera de la VPS todavía no están automatizadas. El diseño está definido —un volcado nocturno con rotación local y una copia semanal a un bucket externo—, pero el trabajo programado no está instalado, así que un fallo total de disco o de proveedor es hoy un punto único de fallo real. En el plan en la nube esto lo cubría Atlas; al autoalojar, la responsabilidad pasó a mí y es mi primera tarea pendiente. Añado otras dos que asumo: no hay aún validación empírica en aula, que dejo como trabajo futuro, y el estado en una única instancia habría que externalizar para escalar. Prefiero nombrar estas cosas con claridad antes que afirmar que el sistema está terminado; el tribunal valora más la conciencia de los límites que fingir que no existen.

### 160. Más allá de integrar tecnologías conocidas, ¿cuál es la aportación original de tu trabajo?

Es una crítica justa: las piezas son conocidas —RFID, sockets, React—. La originalidad está en la composición y en el hueco que llena. En concreto, invertir la topología clásica del IoT: el sensor es un periférico USB tonto que se lee en el navegador con Web Serial, mientras la plataforma entera vive en la nube. Eso permite que un sistema con hardware tangible se despliegue sin que ningún servidor toque el sensor, algo que la matriz comparativa muestra que ninguna solución ofrece para el rango de cuatro a ocho años. Sobre eso, dos cosas que trato como ingeniería de primera clase y no como añadidos: un motor basado en el patrón Strategy donde las mecánicas nuevas no tocan el núcleo, y la protección de datos de menores tejida desde el diseño. La aportación es la arquitectura y la celda vacía que ocupa, no ninguna librería concreta.


---

## Bloque 28: Rate Limiting — Visión Global

### 161. Has citado límites concretos en varias respuestas. Visto en conjunto, ¿cómo está diseñado el rate limiting de toda la aplicación?

Lo pienso como defensa en profundidad en tres planos, cada uno atajando un tipo de abuso distinto. En el borde, Nginx corta por IP las inundaciones volumétricas antes de que toquen a Node. En la capa HTTP no tengo un único límite global, sino una familia de limitadores por propósito, cada uno con su ventana y su tope, y —esto es lo importante— la clave es la identidad del docente o, si la petición no está autenticada, su IP. Así el coste se ajusta a la sensibilidad de cada acción: el login es muy estricto, pocos intentos cada quince minutos para frenar la fuerza bruta; el registro son unos pocos por hora; las creaciones de recursos, unas decenas por hora; las subidas de assets, veinte por hora; la analítica, treinta por minuto; y la exportación de datos, sensible por RGPD, una por minuto. Todos responden con un 429, un mensaje amable en español y la cabecera Retry-After. Detrás, un almacén en Redis compartido mantiene esos contadores coherentes entre reinicios y procesos; si Redis cayera, degrada a un contador en memoria y me avisa por Sentry, porque prefiero saberlo a que el límite deje de aplicarse en silencio. Y por encima está el plano de WebSocket, con límites por evento y el bloqueo educativo por identidad de docente que ya comenté. La filosofía es una sola: ajustar cada límite al riesgo y al coste de su acción, y frenar el abuso sin bloquear jamás el juego legítimo del aula.


---

## Bloque 29: Redis, el Worker y el Estado Distribuido

### 162. En la memoria describes Redis como almacenamiento "transitorio con TTL". Si es transitorio, ¿qué pasa con la blacklist de tokens y los locks cuando Redis se reinicia?

Matizo la premisa, porque es importante: "transitorio con TTL" no significa "volátil en RAM". Redis sí persiste a disco. Lo configuro con el registro de operaciones activado (AOF, `appendonly yes`) y volcado cada segundo, sobre un volumen de Docker dedicado. Así, un reinicio de Redis recupera la blacklist, los locks de tarjetas y las colas de BullMQ desde ese registro, perdiendo como mucho un segundo de escrituras. "Transitorio con TTL" describe la semántica de negocio —cada clave caduca sola cuando le toca—, no la durabilidad física. Y aunque en el peor caso se perdiera algo, el diseño degrada con seguridad: una entrada de blacklist perdida solo acorta la vida de un token que ya era efímero, y un lock perdido se vuelve a reclamar. La durabilidad la da el AOF; la robustez, que nada crítico dependa de que una clave concreta sobreviva.

### 163. ¿Qué le ocurre a la aplicación si Redis se cae del todo en mitad de una clase?

Depende del entorno, y es deliberado. En producción Redis es crítico: si cae, el endpoint de disponibilidad pasa a 503 y me entero al instante, pero el proceso no muere. Delante de Redis tengo un cortacircuitos: tras cinco fallos seguidos se abre y deja de intentar operaciones durante quince segundos, para no castigar cada petición con un timeout; luego prueba en modo semiabierto y, con dos éxitos, se cierra y vuelve a la normalidad. Mientras, el cliente reintenta reconectar sin rendirse nunca. En desarrollo, en cambio, tolero Redis caído con un respaldo en memoria, para no bloquear el trabajo local. Lo esencial es que la partida en curso no depende de Redis para su estado vivo —eso vive en la memoria del proceso—, así que el juego continúa; lo que se degrada es la coordinación (rate limit, blacklist), y lo hace de forma ruidosa y observable, nunca en silencio.

### 164. Añades cada token revocado a una blacklist en Redis con política `noeviction`. ¿No crece eso sin límite hasta llenar la memoria?

No, porque cada entrada se autoexpira. Cuando revoco un token lo guardo en la blacklist con un TTL igual a su vida restante: la diferencia entre su instante de caducidad y ahora. Un token de acceso vive como mucho quince minutos, así que su entrada desaparece sola en ese plazo; el flag de revocación global de un usuario dura lo que el refresh, siete días. La blacklist nunca acumula tokens ya caducados, porque revocar uno expirado no escribe nada. Por eso `noeviction` es seguro: no confío en que Redis desaloje claves bajo presión, sino en que todo lo crítico —blacklist, locks, idempotencia— lleva su propio TTL acotado y caduca por sí mismo, y lo prescindible —los cachés— también. `noeviction` solo actúa de red: si algo fuera mal, Redis rechaza escrituras de forma ruidosa en vez de tirar una clave crítica en silencio.

### 165. ¿Por qué el worker es un proceso separado y no simplemente un cron dentro del backend o unos hilos de trabajo?

Por aislamiento del bucle de eventos. Node es monohilo: si ejecutara la retención nocturna —que puede anonimizar miles de documentos— dentro del backend, ese trabajo pesado bloquearía el mismo bucle que atiende el tiempo real del RFID, y una clase notaría el tirón. Un proceso separado tiene su propio bucle de eventos y su propio límite de memoria, 256 MB, así que su carga jamás compite con el gameplay. Descarté los hilos de trabajo porque comparten proceso y memoria con el servidor: no dan ese aislamiento de recursos ni de fallo. Con un proceso aparte, si un job se descontrola o el worker cae, el backend sigue sirviendo partidas, y al revés. Y no duplico artefactos: es la misma imagen de Docker, solo cambia el punto de entrada —`node worker.js` en lugar del servidor—. Aislamiento real por el coste de arrancar un proceso más.

### 166. Dices que los cron de BullMQ son idempotentes con `jobId` fijo. ¿Qué pasa si el job de retención se ejecuta dos veces o el worker muere a mitad?

El `jobId` fijo cubre la programación: aunque el backend reinicie y vuelva a encolar el cron, BullMQ no lo duplica porque ya existe uno con ese identificador. Y el job en sí es idempotente por diseño: volver a anonimizar una partida ya anonimizada, o mirar una que aún no cumple la antigüedad, es una operación nula, porque filtra por edad y por "aún no tratada". Ejecutarlo dos veces da el mismo resultado que una. Si el worker muere a mitad, BullMQ conserva el job y, cuando expira su lock, lo reintenta —en ese mismo worker al reiniciar—, retomando desde los documentos que quedaban por procesar. No hay corrupción ni doble anonimización posibles. Además acoto el histórico de jobs en Redis: los completados se limpian a las veinticuatro horas y los fallidos a los siete días, para que la propia cola no crezca sin fin.

### 167. Los leaderboards viven en Redis como sorted sets. Si MongoDB es la fuente de verdad, ¿por qué materializarlos ahí y cómo evitas que se desincronicen?

Los materializo por rendimiento de lectura. Un leaderboard es un ranking, y un sorted set de Redis me da inserción y consulta ordenada en tiempo logarítmico; calcularlo desde Mongo en cada carga del dashboard exigiría repetir una agregación pesada una y otra vez. Al cerrar cada partida actualizo el sorted set correspondiente, y el docente lee el ranking al instante. El riesgo que señalas es real: Redis y Mongo pueden divergir si una escritura falla o Redis parpadea. Lo cubro con un reconciliador nocturno, un job a las 00:30 que recalcula los sorted sets y las métricas materializadas desde Mongo —la fuente de verdad— y reporta cualquier desviación. Además los acoto: cada leaderboard tiene pocos miembros, porque rankean contenido —contextos y mecánicas—, nunca niños. Redis da la velocidad, Mongo la verdad y el reconciliador la coherencia entre ambos.

### 168. El worker es un proceso separado del backend. Si no comparten memoria, ¿cómo se coordinan?

No comparten nada de memoria; se coordinan a través de Redis, que hace de intermediario. Uso BullMQ, que implementa colas sobre Redis: el backend es el productor —programa los cron y encola trabajos— y el worker es el consumidor que los ejecuta. Ninguno llama al otro directamente; el backend deja el trabajo en una cola de Redis y el worker lo recoge cuando puede. Ese desacople es justo lo que buscaba: puedo reiniciar o desplegar uno sin tumbar al otro, y un trabajo encolado sobrevive en Redis a que el worker esté momentáneamente caído. Un detalle de implementación: el worker abre una conexión Redis dedicada para las colas, con parámetros de reintento y bloqueo distintos a los del cliente de caché y locks, porque BullMQ necesita un comportamiento que chocaría con el del cliente general. Misma Redis, dos conexiones con propósitos distintos.

### 169. ¿Por qué Redis y no Memcached u otra caché en memoria?

Porque necesito bastante más que una caché clave-valor, y ahí Memcached se queda corto. De Redis aprovecho cuatro capacidades que Memcached no tiene. Primera, estructuras de datos: sorted sets para los leaderboards, hashes para las métricas materializadas, no solo cadenas. Segunda, atomicidad programable con scripts Lua, que es lo que hace la reserva de tarjetas "todo o nada" a prueba de carreras. Tercera, persistencia a disco con AOF, que deja sobrevivir la blacklist y los locks a un reinicio. Y cuarta, que BullMQ —mi cola de trabajos— se construye precisamente sobre Redis; Memcached ni siquiera podría ser el intermediario del worker. Para lo que sí es caché pura, Redis me sirve igual de bien con un TTL por clave. Es decir, una sola pieza me cubre caché, coordinación atómica, estado con caducidad y cola de trabajos; añadir Memcached solo sería otra dependencia para hacer menos.


---

## Bloque 30: Docker, Contenedores y Orquestación

### 170. ¿Cómo garantizas que MongoDB y Redis estén listos —y el replica set inicializado— antes de que el backend arranque y falle al conectar?

Con dependencias por condición y una cadena de inicialización idempotente. En Compose, el backend declara `depends_on` con `condition: service_healthy` para Mongo y Redis, así que no arranca hasta que sus healthchecks pasan: un ping a Mongo, un PING autenticado a Redis. Pero Mongo necesita algo más que estar vivo: necesita el replica set y el usuario root creados. Eso lo resuelve una secuencia de tres trabajos de un solo uso, encadenados también por condición: primero se genera el keyfile de autenticación interna, luego se crea el usuario root aprovechando la excepción de localhost de Mongo, y por último se inicializa el replica set `rs0`. El backend depende de que ese último termine con éxito. Los tres son idempotentes: si el replica set ya existe, no hacen nada, así que sobreviven a reinicios sin romper nada. Arranque ordenado y reproducible, sin esperas a ciegas.

### 171. ¿Dónde viven físicamente los datos de Mongo y Redis en los contenedores, y qué pasa si haces `docker compose down`?

Viven en volúmenes de Docker con nombre, no dentro de los contenedores: uno para la base, otro para el registro AOF de Redis y un tercero para el keyfile del replica set. Esa separación es la clave: el contenedor es desechable y sin estado, el volumen guarda el estado. Un `docker compose down` para y elimina los contenedores, pero los volúmenes con nombre sobreviven, así que los datos siguen ahí al volver a levantar. Solo un `down -v` explícito los borraría, y eso no forma parte de ningún despliegue. Por eso un despliegue, que recrea los contenedores con la imagen nueva, nunca toca los datos. La contrapartida honesta es que esos volúmenes viven en el disco de la VPS: si el disco falla es un punto único de fallo, y precisamente por eso la copia de seguridad externa automatizada es mi principal tarea operativa pendiente.

### 172. Tienes tres ficheros de Compose (base, desarrollo y producción). ¿Qué cambia entre ellos y por qué esa separación?

Un fichero base define la topología común —los servicios, la red, los volúmenes— y dos overlays lo especializan sin duplicarlo. El de desarrollo monta el código fuente como volumen y arranca con nodemon y el servidor de Vite, para tener recarga en caliente sin reconstruir la imagen a cada cambio; usa la etapa de desarrollo del Dockerfile, que sí trae las dependencias de desarrollo, y sube el límite de memoria porque Vite lo necesita. El de producción va justo al revés: contenedores inmutables con el sistema de ficheros de solo lectura, sin código montado, límites de memoria y CPU ajustados, los puertos de las bases de datos retirados para no exponerlos, y rotación de logs. La misma definición base sirve para los dos mundos; el overlay elige entre "editable y cómodo" para desarrollar y "cerrado e inmutable" para producir. Es infraestructura como código, sin dos configuraciones divergentes que mantener.

### 173. Los contenedores corren con el sistema de ficheros en solo lectura y sin root. ¿Qué ganas realmente con eso si el backend se viera comprometido?

Reduzco el radio de daño. Con el sistema de ficheros en solo lectura, un atacante que lograra ejecución de código no puede escribir una webshell, dejar un binario persistente ni modificar el código en caliente, porque no hay dónde escribir; solo monto un `/tmp` efímero en memoria que se borra al reiniciar. Además el proceso corre como usuario sin privilegios, no como root, así que aunque algo escapara, no tiene poder dentro del contenedor. Y en producción los puertos de Mongo y Redis no están publicados, de modo que desde un backend comprometido tampoco hay un salto trivial hacia las bases de datos. Son capas de contención: no evitan la intrusión inicial, pero hacen que una ejecución de código no se convierta en persistencia ni en movimiento lateral. Es defensa en profundidad aplicada al propio contenedor, no solo a la aplicación que corre dentro.

### 174. Un despliegue recrea el contenedor del backend, y el estado vivo de las partidas está en su memoria. ¿No tumba eso las clases en curso?

Sí, y soy honesto: un despliegue implica una breve interrupción, porque corro una sola instancia y no hay despliegue rodante. Lo que hago es que esa interrupción sea ordenada, no brusca. Cuando Docker va a recrear el contenedor envía SIGTERM y espera treinta segundos antes de matarlo; mi apagado ordenado aprovecha ese margen apuntando a terminar en menos de veinticinco: deja de aceptar peticiones, drena las que están en vuelo, finaliza las partidas de forma controlada persistiendo su estado, y cierra sockets, colas y conexiones. Así nada se corrompe. Aun así, para no cortar una clase a media partida, los despliegues se programan en ventanas de bajo uso, no en horario lectivo. Un despliegue sin caída con varias instancias exigiría externalizar el estado del motor a Redis, que es trabajo futuro que reconozco. Hoy: apagado limpio y ventana adecuada.

### 175. El worker no expone un servidor HTTP. ¿Cómo sabe Docker si está sano y qué pasa si muere en silencio?

Buena observación, porque ahí hubo un detalle real. El worker hereda la imagen del backend, cuyo healthcheck consulta un endpoint HTTP; pero el worker no levanta HTTP, solo procesa colas, así que ese healthcheck heredado daba siempre "no sano". Lo resolví sobrescribiéndolo con uno propio: un PING a Redis, que es su dependencia crítica —sin Redis no hay colas que procesar—. Si el worker o su Redis fallan, Docker lo marca no sano y, con la política de reinicio `always`, lo levanta de nuevo. Y si muriera en silencio entre ciclos, el diseño lo perdona: sus trabajos son cron idempotentes, así que un ciclo perdido se recupera solo en la siguiente ejecución programada, sin intervención. Además el propio worker aloja los detectores de alertas de sistema, así que su salud también aflora en la observabilidad. No corre a ciegas por no tener HTTP.

### 176. ¿Por qué orquestar todo con Docker Compose en una sola VPS y no con Kubernetes o servicios gestionados?

Por proporción al problema. El escenario objetivo es un centro con una única instancia; Compose me da infraestructura como código reproducible —levanto todo el stack con un comando, versionado en el repositorio—, que es justo lo que un centro y un TFG necesitan. Kubernetes sería sobredimensionar: resuelve orquestación multinodo, autoescalado y despliegue rodante, y yo tengo la instancia única como invariante deliberado, así que solo añadiría una complejidad operativa enorme sin beneficio. Los servicios gestionados eran, de hecho, el plan original —base y caché en la nube—, pero cuando el proveedor retiró su capa gratuita migré a autoalojar. Y ahí se vio la ventaja de Compose: cambié de proveedor sin tocar una línea de lógica de negocio, solo reconstruyendo los mismos contenedores en otra máquina. Compose es el punto justo entre un despliegue manual frágil y una orquestación industrial que aquí no hace falta.


---

## Bloque 31: Proceso, Demostración y Decisiones Transversales

### 177. ¿Has usado inteligencia artificial para desarrollar el proyecto? Y si es así, ¿qué parte es realmente tuya?

Sí, con transparencia: usé asistentes de IA como herramienta de productividad, igual que uso el IDE, el depurador o la documentación, pero más potente. Me sirvió para acelerar código repetitivo, contrastar alternativas, revisar en busca de errores y hacer de segundo par de ojos. Lo que no delegué —y es lo que un TFG evalúa— es la ingeniería: entender el problema y a los usuarios, elegir la arquitectura, sopesar cada compromiso, decidir qué es correcto, integrar las piezas y depurar cuando algo falla. Esas decisiones son mías y puedo defender por qué invertí la topología IoT, por qué tres capas de estado, por qué el patrón Strategy o por qué el consentimiento como base jurídica. La prueba es esta misma defensa: si no comprendiera cada decisión, no podría razonarla ni sostenerla ante una pregunta. La herramienta acelera; el criterio y la responsabilidad son míos.

### 178. Tráza qué ocurre exactamente desde que el niño acerca la tarjeta hasta que ve el feedback y se guarda el resultado.

El lector lee el UID por SPI y el firmware lo firma con HMAC más un contador monótono y lo escupe como una línea JSON por USB. En el navegador del docente, la capa Web Serial acumula la línea, valida el formato del UID, deduplica —si el mismo UID llega en 1,2 segundos lo descarta— y reenvía el escaneo autenticado por Socket.IO. El backend recibe el evento, verifica la firma HMAC en tiempo constante y que el contador sea estrictamente mayor que el último visto, y comprueba que la partida sea de ese docente. Entonces el motor de juego, que tiene el estado vivo en memoria, resuelve la mecánica de forma polimórfica, decide si es acierto y actualiza la puntuación. El feedback visual y sonoro se pinta en el cliente en menos de cincuenta milisegundos, y en paralelo un checkpoint persiste el estado en Mongo cada dos minutos o cada cinco respuestas. Cinco capas —firmware, navegador, socket, motor, base de datos— en una fracción de segundo.

### 179. El sensor físico está averiado. ¿Cómo vas a demostrar el sistema funcionando ante el tribunal?

Con un simulador que es fiel precisamente por cómo está diseñada la arquitectura. El sensor se rompió en mayo, pero como el navegador es el intermediario que lee el hardware, puedo inyectar los escaneos en exactamente el mismo punto del flujo donde entrarían los del lector real. Tengo un simulador, activo solo en la compilación de desarrollo, que emula el arranque del sensor, la detección de tarjeta, el latido y la retirada, y —esto es lo importante— firma cada escaneo con la misma clave HMAC, cargada en tiempo de ejecución, nunca en el paquete. Así, todo el resto del sistema corre idéntico: la deduplicación, la verificación de firma y contador, el motor de juego, la puntuación, el feedback y la persistencia. Lo único que sustituyo es la lectura por USB; de la frontera del navegador hacia dentro, la demostración es real, no un maqueta. Y si prefiriera, el respaldo táctil también permite jugar sin lector.

### 180. En una aplicación intensiva en analítica, ¿cómo diseñaste los índices de MongoDB sin penalizar la escritura?

Con índices compuestos pensados por patrón de consulta y podados de forma consciente. Sigo el orden igualdad-ordenación-rango: por ejemplo, para el historial de un alumno indexo jugador, estado y fecha de fin, de modo que la consulta filtra, ordena y acota usando el mismo índice sin ordenar en memoria. Tengo también índices por creador para el aislamiento por docente —sus consultas solo tocan sus propios datos— y un índice único parcial que garantiza a nivel de base de datos que un alumno tenga como mucho una partida activa por sesión. Para la caducidad automática uso índices TTL. Y aquí está la clave del equilibrio: la colección de partidas se escribe en cada evento RFID, así que cada índice de más cuesta latencia de escritura y almacenamiento. Por eso eliminé índices de un solo campo que ya eran prefijo de uno compuesto: no aportaban lectura y sí encarecían cada escaneo. Optimizo lectura sin castigar la escritura del camino caliente.

### 181. ¿Por qué gestionas el estado del frontend con contextos de React y no con Redux u otra librería de estado global?

Porque el estado global que manejo es pequeño y está segmentado por dominio, y una librería como Redux sería ceremonia sin problema que resolver. Uso media docena de contextos enfocados —autenticación, tema, atmósfera visual, modo RFID en tiempo real, notificaciones y registro de atajos—, cada uno dueño de su parcela, en lugar de un único almacén monolítico con su reductor y su plantillería. La razón de fondo es arquitectónica: el estado pesado y que cambia rápido, el de la partida en vivo, no vive en el cliente sino en el servidor, y llega al navegador como snapshots por socket; el cliente es una vista, no la fuente de verdad. Así no necesito orquestar estado complejo en el frontend ni sincronizarlo, que es justo el problema para el que Redux brilla. Con React y contextos me sobra, y me ahorro una dependencia y su acoplamiento. Menos piezas para el mismo resultado.


---

## Bloque 32: Alertas Inteligentes

### 182. Describes las alertas como "reglas heurísticas explícitas". ¿Por qué no un modelo de machine learning o de IA para detectar los patrones?

Fue una decisión deliberada, y en un sistema que analiza a menores creo que la correcta. Un modelo de aprendizaje automático necesitaría un corpus etiquetado de "dificultad de aprendizaje" que no existe: nadie ha marcado qué partidas son señal real de un problema, así que no tengo verdad de referencia con la que entrenar, y un centro medio tiene veinte o veinticinco alumnos por aula, muy lejos del volumen que un modelo necesita para no sobreajustar. Pero la razón de fondo es otra: una alerta que el docente va a tomar en serio tiene que ser explicable y auditable. Con una regla heurística puedo decir exactamente por qué saltó —"su rendimiento cayó un veinte por ciento period a period"— y cada umbral está validado pedagógicamente y trazado a una decisión docente concreta; una caja negra que perfila a un niño sin poder justificarse es justo lo que quería evitar por el Reglamento. Además el juicio final lo mantiene el docente, no hay decisión automatizada con efecto sobre el alumno. Y la arquitectura de detectores enchufables deja la puerta abierta a sustituir una regla por un modelo el día que tenga datos y validación para ello.

### 183. ¿En qué momento se generan las alertas: en tiempo real al terminar cada partida, o con qué frecuencia?

Matizo la premisa porque es una confusión habitual: la detección no es en tiempo real al cerrar una partida. Corre en un proceso trabajador separado, un cron que se ejecuta cada quince minutos y recorre a todos los docentes; en cada pasada lanza los trece detectores, y reconcilia lo que encuentra con las alertas que ya existían —crea las nuevas, refresca las que siguen y resuelve solas las que han dejado de aparecer—. Lo hago por lotes y no al terminar cada partida por tres motivos: casi ningún patrón se ve en una sola partida (una caída sostenida o un abandono recurrente necesitan cruzar varias sesiones y dos periodos de tiempo), recalcular todo eso en el hilo caliente del juego se comería el presupuesto de cincuenta milisegundos del feedback, y al vivir en un trabajador aparte una pasada pesada nunca bloquea las peticiones normales del backend. Lo único que sí es instantáneo es el empujón: cuando una pasada crea o escala una alerta crítica, el docente recibe una notificación por socket en el momento. Detección diferida y por lotes; aviso de lo crítico, inmediato.

### 184. ¿Cómo evitas los falsos positivos que harían que el docente dejara de confiar en las alertas por fatiga?

La fatiga de alertas es el mayor riesgo de un sistema así, y lo ataco por varios frentes. Primero, exijo muestra mínima antes de afirmar nada: no genero una alerta de caída con menos de dos partidas por periodo, ni un hito de dominio o un estancamiento con menos de cinco, ni comparo una mecánica con menos de tres partidas; y corregí un fallo por el que una media previa de cero fabricaba una crítica falsa. Segundo, no hago ruido: solo empujo en tiempo real las alertas críticas, nunca los avisos ni las informativas. Tercero, no escalo a la ligera: un aviso solo sube a crítico si persiste más de una semana y con al menos tres ocurrencias, para que una lectura aislada no dispare la alarma. Cuarto, el sistema se autolimpia: si el patrón desaparece dos pasadas seguidas, la alerta se resuelve sola. Y quinto, doy control y me mido: el docente puede descartar con un motivo —falso positivo, ya atendido— o posponer, y el propio sistema calcula su tasa de falsos positivos y su tiempo medio a resolución para que yo pueda recalibrar umbrales. La confianza se gana con precisión, no con volumen.

### 185. Una alerta, ¿desaparece sola cuando el alumno mejora o tiene el docente que cerrarla? ¿Qué ciclo de vida tiene?

En su mayoría se gestiona sola; el docente solo actúa si quiere. Una alerta tiene cuatro estados: activa, resuelta, descartada y pospuesta. Lo normal es que se resuelva automáticamente: cuando el detector deja de emitirla dos pasadas seguidas —el alumno ha mejorado—, pasa a resuelta sin que nadie la toque. Sobre eso, el docente tiene acciones: resolverla a mano, descartarla indicando un motivo, posponerla unos días para silenciarla sin perderla, o fijarla arriba (máximo tres). Hay dos automatismos más que cuidan los extremos: una alerta de aviso que sigue viva más de una semana con varias ocurrencias escala sola a crítica, para que un problema que se enquista no se quede en segundo plano; y una alerta crítica que el docente descartó pero que reaparece pasados dos meses se reabre sola, para que "lo descarté hace tiempo y me olvidé" no deje a un niño sin atención. Y todo queda trazado: cada alerta guarda su historial —creada, vista de nuevo, escalada, pospuesta, descartada, resuelta— como registro de auditoría. Al cabo de un año, las cerradas se borran definitivamente.

### 186. Detectas la caída de rendimiento comparando al alumno con su propio histórico y no con la media del aula. ¿Por qué esa elección?

Por equidad y por sentido pedagógico. Comparar contra la media del aula penalizaría sistemáticamente al alumno que va por detrás aunque esté progresando de forma estupenda, y a la vez no vería venir a un alumno bueno que empieza a decaer pero sigue por encima de la media. Ninguno de los dos casos es el que un docente necesita cazar. Lo que de verdad pide intervención es el cambio respecto a la línea base del propio niño: una caída sostenida de un periodo al siguiente, o una partida muy por debajo de su media habitual. Cada alumno es su propio control, y así la alerta detecta el problema real —"algo ha cambiado en este niño"— sin etiquetarlo por comparación con sus compañeros. Técnicamente lo sostengo normalizando las puntuaciones a porcentaje del techo teórico, porque las tres mecánicas tienen máximos de puntos muy distintos; sin eso, un simple cambio en la mezcla de mecánicas que juega fabricaría una caída falsa. La media del aula sí la uso, pero para la mirada de dirección sobre el centro, nunca para señalar a un alumno concreto.

### 187. Dices que "cada regla heurística reclama validación pedagógica". ¿Cómo validaste que una caída del 10 % es un aviso? ¿Quién validó esos umbrales?

Quiero ser honesto con lo que significa ahí "validación pedagógica", porque no es un estudio clínico. Los umbrales no están calibrados empíricamente con niños y docentes reales; esa validación en aula la dejo explícita como línea futura, la misma que reconozco para el wizard y para el sistema entero. Lo que sí hay es un criterio de diseño doble: primero, solo formalizo un patrón como alerta cuando la decisión docente que habilita es clara —si detectar algo no cambia lo que el maestro haría, no es una alerta, es ruido—; y segundo, los valores concretos salen de razonamiento apoyado en literatura de interacción y aprendizaje, no de una cifra caprichosa. Y precisamente porque no están validados en campo, los mantengo conservadores: umbrales altos, mínimos de muestra, pocas reglas, prefiriendo avisar de menos antes que dar falsas alarmas. Hay un detalle de ingeniería que lo respalda: todos los umbrales viven centralizados en un único punto de configuración, sobreescribibles sin tocar código, así que el día que tenga datos reales de un aula, recalibrar es cambiar un valor, no reescribir el motor. La honestidad es esa: es un sistema fundamentado y listo para validarse, no validado aún.

### 188. El motor analiza automáticamente a menores para marcarlos "en riesgo". ¿No es eso perfilado prohibido? ¿Cómo lo concilias con el RGPD?

Lo diseñé precisamente para no cruzar esa línea. Primero, en el consentimiento: el motor solo procesa a los alumnos cuyos padres han otorgado el propósito de analítica de rendimiento, y excluye de inmediato a quien lo haya retirado; usa la misma fuente de verdad que el resto de la analítica, así que las alertas nunca analizan a un niño que el sistema ya excluye. Segundo, en los datos: los registros del motor nunca llevan el nombre real ni el identificador plano del alumno, solo un seudónimo derivado con una función hash, de modo que la traza operativa no reidentifica. Y tercero, y más importante jurídicamente, no es perfilado prohibido porque no infiero un rasgo persistente ni una etiqueta del niño: produzco una señal pedagógica transitoria ligada a su rendimiento en el juego, sin ninguna decisión automatizada con efecto sobre él —el Artículo 22 lo veta y yo lo respeto dejando el juicio siempre en el docente—. El sistema dice "mira esto", no "este niño es así". Es apoyo a la decisión de un profesional, con lenguaje sugerente ("en riesgo", no "con bajo rendimiento"), no una clasificación del menor.


---

## Bloque 33: Puntuación y Score

### 189. La puntuación de una partida, ¿la calcula el cliente o el servidor? ¿Podría el navegador o el alumno falsearla?

La calcula íntegramente el servidor; el navegador no puntúa. El cliente solo reenvía el escaneo de la tarjeta —el identificador, su firma y su contador—, y es el motor de juego en el backend, que tiene el estado vivo de la partida, quien decide si es acierto y suma los puntos aplicando las reglas de la sesión: puntos por acierto y la penalización opcional por error. La pantalla de fin de partida del cliente se limita a pintar el número que el servidor le manda; no lo genera. Y encima hay una salvaguarda de integridad: al crear la partida persisto el techo teórico, y el servidor acota la puntuación a ese rango, entre cero y el techo, así que ni un evento duplicado ni uno fuera de orden pueden inflarla, y tampoco baja de cero. Aclaro que esto no va de un niño de cinco años haciendo trampas: es el principio de que el cliente no es de fiar. Un fallo, un mensaje de socket manipulado o un escaneo reproducido no deben poder corromper unas métricas que luego alimentan las alertas y la analítica del docente. Por eso la puntuación vive en el backend y no en el navegador.

### 190. ¿Por qué la puntuación no premia la velocidad ni las rachas con multiplicadores, como haría un videojuego?

Es una decisión deliberada. La puntuación es plana: puntos por acierto, una penalización opcional por error, y el tiempo no cambia el número. Descarté a propósito el bonus por velocidad y los multiplicadores por racha por dos razones. La primera, de equidad: un premio por rapidez penaliza al niño más pequeño o más lento, y ese es justo el alumno que la plataforma quiere detectar y apoyar, no al que quiere poner en desventaja. La segunda, de legibilidad: un multiplicador por combo vuelve la puntuación opaca y la convierte en un marcador de recreativa, cuando el número tiene que seguir siendo un reflejo limpio del aprendizaje —del acierto—, no de los reflejos. Ojo, las rachas sí existen, pero en la capa de retroalimentación, no en la aritmética: la mascota celebra una racha y el resumen final muestra la racha máxima, como enganche emocional, no como puntos. El número responde a "cómo de bien lo ha entendido el niño", no a "cómo de rápido ha reaccionado". Y esa misma coherencia es la que permite que el porcentaje de dominio y las alertas razonen sobre el acierto, no sobre la destreza.
