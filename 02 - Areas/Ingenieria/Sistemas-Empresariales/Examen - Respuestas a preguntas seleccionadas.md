---
tags:
  - SIE/Examen
  - SIE
Fecha de actualización: 2026-05-31
Nota previa: ""
Nota siguiente: ""
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Examen — Respuestas a preguntas seleccionadas

> [!info]+
> Respuestas a las **preguntas marcadas en amarillo** en `sie_seleccion_objetivos.pdf`, redactadas como respuestas de examen. Cada respuesta indica la fuente bibliográfica de `sie_biblio+objetivos.pdf`.

---

## Tema 1 — Introducción a los SI Empresariales

### 1. Distinguir los conceptos de dato, información y conocimiento [2]p144-147

Los <mark style="background: #ADCCFFA6;">tres conceptos forman una jerarquía ascendente</mark> (*DIC*) en la que cada nivel se construye sobre el anterior añadiendo contexto y aplicabilidad.

- **Dato**: cantidad matemática, símbolo o combinación que representa un hecho **sin contexto interpretativo**. Es la materia prima del SI. Por sí solo no transmite significado.
- **Información**: dato combinado con **suficiente contexto para que aporte significado a un humano**. 
- **Conocimiento**: información combinada con **experiencia, interpretación y capacidad de aplicación**. 

### 3. Clasificar los tipos de información que maneja una empresa [1]3.2

**Itami** clasifica la <mark style="background: #FFB8EBA6;">información empresarial en tres tipos según el flujo respecto a la organización</mark>:

- <mark style="background: #ADCCFFA6;">Información externa o ambiental</mark>: <mark style="background: #FFB86CA6;">entra desde fuera</mark>. Según el *modelo de Laudon*, se divide en dos capas: **entorno inmediato** (con quienes la empresa interactúa a diario) y **entorno remoto** (factores estructurales). El *modelo de Jakobiak* distingue <mark style="background: #8000E1A6;">siete tipologías de información crítica</mark>.
- <mark style="background: #ADCCFFA6;">Información interna</mark>: <mark style="background: #FFB86CA6;">generada y circulada dentro de la propia empresa</mark> por su funcionamiento. Cornella distingue **información operacional** (rutinaria, sustrato de los TPS) y **conocimiento** (fusión de interna y externa que genera ventajas). Se distingue además por formalidad: formal (informes, BBDD) o informal (conversaciones, correos).
- <mark style="background: #ADCCFFA6;">Información corporativa</mark>: la que la empresa <mark style="background: #FFB86CA6;">lanza al exterior de forma deliberada</mark> para controlar canales y contenidos. *Cornella* contrapone aquí la **imaginería corporativa** a la inteligencia competitiva.

### 5. Niveles de planificación: estratégica, operativa y táctica/gerencial [1]3.3

La planificación se estructura en **tres niveles** <mark style="background: #FFB8EBA6;">según horizonte temporal y nivel jerárquico</mark>, correlacionados con el tipo de decisiones y el SI que las soporta.

- <mark style="background: #ADCCFFA6;">Estratégica</mark>:<mark style="background: #FFB8EBA6;"> largo plazo</mark> (>3 años), la lleva la **alta dirección**. <mark style="background: #FFB86CA6;">Decisiones no estructuradas </mark>con alta incertidumbre. Soportada por **EIS** y BI.
- <mark style="background: #ADCCFFA6;">Táctica o gerencial</mark>: <mark style="background: #FFB8EBA6;">medio plazo</mark> (1-3 años), la llevan los **mandos intermedios** y directores de área. <mark style="background: #8000E1A6;">Enlaza estrategia y operativa</mark>. Soportada por **MIS** y **DSS**.
- <mark style="background: #ADCCFFA6;">Operativa</mark>: <mark style="background: #FFB8EBA6;">corto plazo</mark> (días, semanas), la llevan **directores de operaciones** y supervisores. <mark style="background: #8000E1A6;">Decisiones estructuradas del día a día</mark>. Soportada por **TPS** y MIS.

### 7. Modelos estructurales de empresa (vertical vs horizontal) y flujo de información [1]5.2

La <mark style="background: #8000E1A6;">transición del primero al segundo está ligada a la evolución de los SI</mark>.

- <mark style="background: #ADCCFFA6;">Modelo vertical o tradicional</mark> (*Anthony*, 1965): **pirámide jerárquica**. El <mark style="background: #FFB86CA6;">flujo es unidireccional y rígido</mark>: la **información sube** (de operarios a alta dirección) y las **órdenes bajan**. <mark style="background: #8000E1A6;">Comunicación horizontal débil</mark> entre departamentos. <mark style="background: #FFB8EBA6;">Produce cuellos de botella, demoras y distorsión</mark>. Los SI son **aplicaciones aisladas por departamento** (*silos*): cada área tiene su software, sus datos y sus procesos sin integración.
- <mark style="background: #ADCCFFA6;">Modelo horizontal o por procesos</mark>: estructura en **red**. La información y las órdenes fluyen **multidireccionalmente**. <mark style="background: #FFB8EBA6;">Orientado al cliente y al resultado global</mark>, no a la tarea departamental. Pocos niveles directivos. Los SI están **integrados** (ERP, CRM, SCM) bajo base de datos común.

*Castells* llama al modelo horizontal **empresa-red**, caracterizada por siete tendencias: 1) organización por proceso, no por tarea; 2) jerarquía plana; 3) gestión en equipo; 4) resultados medidos por satisfacción del cliente; 5) recompensas por resultados del equipo; 6) maximización de contactos con proveedores y clientes; 7) información y formación en todos los niveles. La información circula en redes entre empresas, dentro de la empresa y entre personas.

*Drucker* lo resume: introducir información como elemento estructural **elimina muchos niveles de dirección** porque los mandos intermedios dejan de ser necesarios cuando todos comparten la misma «partitura».

### 11. Cuatro componentes de un SI y papel de cada uno [2]p20-22

Watson formaliza el SI como **sistema sociotécnico** con cuatro componentes interdependientes en dos sub-sistemas.

**Sub-sistema técnico**:

- **Tecnología**: hardware (PC, servidores, móviles), software (aplicaciones, BBDD) y telecomunicaciones (redes, internet). Su papel: **dar soporte a la captación, procesamiento, almacenamiento y distribución de información**. Es el componente más visible pero un SI puede existir sin él (banca china del XIX con papel y libros).
- **Procesos**: conjunto estructurado de pasos para llevar a cabo una actividad de negocio. Su papel: **mapear las acciones secuenciales** que un individuo o grupo debe ejecutar para completar una actividad (ej. flujo de aprovisionamiento: revisar stock → cotizar → seleccionar proveedor → pedir → recibir → pagar). Regla de oro: diseñar primero el proceso y después el software.

**Sub-sistema social**:

- **Personas**: gestores que definen los objetivos y usuarios que operan el sistema. Su papel: **aportar habilidades, actitudes y juicio**. Un SI fracasa con frecuencia porque los usuarios carecen de habilidades o tienen actitud negativa; por eso son indispensables formación y comunicación de beneficios.
- **Estructura**: relaciones organizativas — jerarquía, líneas de reporte, sistema de incentivos. Su papel: **crear los incentivos** que aseguran la adopción del sistema. Sin recompensas alineadas, el sistema queda infrautilizado.

**Interdependencia**: un cambio en un componente arrastra a los demás. El caso clásico es el de la nómina automática que fracasa pese a tener tecnología impecable porque las personas no confiaban (no daban su número de cuenta) y los procesos no contemplaban la corrección de errores. La mayoría de los fracasos se concentra en el componente «personas».

### 13. Características de los TPS [3]3.2

Los **TPS** (*Transaction Processing Systems*) son los **pilares del SI empresarial**. Recogen las operaciones diarias —ventas, compras, pagos, facturación, nóminas— que sostienen el negocio.

**Características**:

- Cubren los procesos **más definidos y estructurados** de la organización, los del nivel operativo.
- Tratan **operaciones que se repiten muchas veces** con gran similitud entre todas.
- Las actividades se separan en **etapas (procedimientos) bien comprendidas** y descriptibles en detalle.
- Existen **muy pocas excepciones** a los procedimientos normales.
- **Gran volumen** de transacciones, **intensivos en E/S**.
- **Cálculos y procesos simples**.
- **Mayor velocidad y exactitud** que los procedimientos manuales.

**Salidas**: producen dos tipos de output:

- **Documentos de transacciones**, que pueden ser **de acción** (billete de avión, cheque) o **de información** (justificante, lista de cargos de tarjeta).
- **Consultas sobre la base de datos** mediante SGBD y lenguajes 4GL.

Ejemplos: facturación, contabilidad, nóminas, recepción de pedidos. Sin TPS sólidos, los SI superiores (MIS, DSS, EIS) no tienen datos sobre los que trabajar.

### 14. Características de los MIS [3]3.3

Los **MIS** (*Management Information Systems*) son **sistemas basados en ordenador que proporcionan información a usuarios con necesidades similares**, principalmente directivos, para que tomen decisiones y resuelvan problemas.

**Características**:

- Se apoyan en las **bases de datos corporativas** alimentadas por los TPS.
- Sirven de apoyo a las **decisiones estructuradas** (los directivos conocen de antemano los factores a considerar).
- Generan **informes periódicos** en formato predefinido (semanal, mensual, trimestral).
- Pueden incorporar la **administración por excepción**: comparar desempeño real con estándares y avisar cuando se sale del intervalo aceptable. Se aplica de cuatro formas: informe solo cuando hay excepción, secuencia que destaca excepciones, agrupación por área, o mostrando variación respecto a la norma.
- Estructuran la información en función de **decisiones definidas a priori**, lo que es su fortaleza y su limitación.

**Niveles**: cubren los tres (estratégico, táctico, operativo) pero resultan **más adecuados para el táctico-operativo**. Para la alta dirección y decisiones no estructuradas no sirven, porque su estructura se define a priori. Esta limitación motivó el desarrollo posterior de DSS y EIS.

### 16. Características de los EIS [3]3.5

Los **EIS** (*Executive Information Systems*) son **sistemas computerizados específicamente diseñados para la alta dirección**. Mientras los DSS apoyan principalmente planificación, los EIS soportan **actividades de control**: detectar problemas y oportunidades.

**Características esenciales**:

- **Capacidad de acceso y gestión de información**: tanto interna como externa, **estructurada y no estructurada**, **cuantitativa y cualitativa**, sin intermediarios.
- **Presentación**: combina datos de fuentes diversas en un mismo informe, con capacidad de **filtrar, comprimir y agregar** información, y de **profundizar (drill-down)** bajo demanda. Adaptada al usuario.
- **Orientación a los factores críticos de éxito (CSF)**: información sobre las **variables clave del negocio**. Diseñado para evolución constante.
- **Capacidad de comunicación y organización del tiempo**: correo, agenda, calendario integrados.
- **Facilidad de uso**: curva de aprendizaje mínima (los ejecutivos no son técnicos); uso directo sin intermediarios.

**Modos de uso**: a) **acceso de lectura** a la situación actual y tendencias; b) **herramienta de análisis personalizado** (ratios, extrapolaciones, modelos simulados).

---

## Tema 2 — Soluciones de negocio (ERP, SCM, CRM)

### 1 (ERP). Por qué y cómo surgieron los ERP [5]1.1

Los **ERP** <mark style="background: #ADCCFFA6;">surgen como respuesta a la fragmentación de los SI departamentales del modelo vertical (o de pirámide)</mark>: cada área tenía su software incomunicado, lo que <mark style="background: #FFB8EBA6;">producía duplicación de datos</mark>, errores por <mark style="background: #FFB8EBA6;">desincronización</mark>, altos costes de mantenimiento y <mark style="background: #FFB8EBA6;">visión parcial del negocio</mark>.

**Tres factores** impulsaron su aparición en *los 90*:

1. **Demanda creciente y solvente** de empresas que <mark style="background: #8000E1A6;">necesitaban sistemas integrados</mark> en un entorno competitivo.
2. **Nuevas técnicas de ingeniería del software** y madurez de las `BBDD relacionales`.
3. **Modelos de negocio rentables** basados en <mark style="background: #8000E1A6;">paquetes estándar comercializables</mark>.

**Detonante final**: la <mark style="background: #FFB86CA6;">adaptación al año 2000</mark> y la <mark style="background: #FFB86CA6;">introducción del euro</mark> dispararon la adopción masiva.

### 3 (ERP). Características del ERP: modularidad, integración y adaptabilidad [5]1.3

Tres <mark style="background: #ADCCFFA6;">rasgos básicos que aparecen juntos sólo en los ERP</mark>:

- **Modularidad**: el sistema se divide en <mark style="background: #FFB86CA6;">módulos por funcionalidad</mark>. Cada <mark style="background: #FFB8EBA6;">módulo realiza una tarea concreta y se comunica con los demás</mark>. La empresa **no tiene que instalar todos los módulos**, sólo los que necesite.
- **Integración**: el sistema técnicamente se sustenta en una <mark style="background: #FFB86CA6;">base de datos centralizada única compartida</mark> por todos los módulos. Los datos se introducen una sola vez, la información está disponible en tiempo real para todos los departamentos, y se <mark style="background: #FFB8EBA6;">evita duplicidad y redundancia</mark>.
- **Adaptabilidad**: el ERP <mark style="background: #FFB86CA6;">puede configurarse mediante parametrización para ajustarse a la estructura</mark> de cada empresa.

### 4 (ERP). Beneficios de la implantación de un ERP [5]1.4

- **Control sobre la actividad de los departamentos**: la integración <mark style="background: #ADCCFFA6;">aporta una visión global del funcionamiento</mark>, permitiendo análisis local (por área) y global (toda la organización).
- **Mejora de los procesos**.
- **Reducción de inventario**: <mark style="background: #ADCCFFA6;">mejor planificación de la cadena de producción</mark>, evitando acumulación en almacén.
- **Bases para el comercio electrónico**: facilita la ampliación hacia transacciones B2B/B2C.
- **Explicitar el conocimiento**: documenta procesos críticos, reglas de decisión y estructura de información antes implícita en empleados.
- **Reducción del tiempo de ciclo**: en producción, entrega, transacciones y cierre financiero.
- **Toma de decisiones más rápida** al reducir el tiempo de análisis.
- **Mejora del servicio al cliente** y respuesta más rápida a cambios.
- **Ventaja competitiva** o, en su defecto, alineamiento con la competencia.

### 5 (ERP). Riesgos de la implantación de un ERP [5]1.5

- <mark style="background: #ADCCFFA6;">Inflexibilidad</mark>: los procesos quedan estrechamente ligados al sistema; <mark style="background: #FFB8EBA6;">cualquier cambio en un proceso implica modificar el ERP</mark>.
- <mark style="background: #ADCCFFA6;">Periodos largos de implementación</mark> frente a un mercado cambiante. Los <mark style="background: #FFB86CA6;">vendedores ofrecen versiones preconfiguradas</mark> para acortar plazos.
- <mark style="background: #ADCCFFA6;">Pérdida de beneficios estratégicos</mark>: al adoptar los procesos estándar, la empresa abandona los propios que podrían darle ventaja competitiva. <mark style="background: #FFB86CA6;">Saber distinguir procesos</mark> *commodity*, de procesos *core*, <mark style="background: #FFB8EBA6;">es clave</mark>.
- <mark style="background: #ADCCFFA6;">Estructura jerárquica</mark>: la <mark style="background: #FFB8EBA6;">centralización puede chocar con culturas descentralizadas</mark>.
- <mark style="background: #ADCCFFA6;">Costes indirectos altos</mark>: los costes de cambio son muy elevados <mark style="background: #FFB8EBA6;">una vez implantado</mark> (efecto *lock-in*).
- <mark style="background: #ADCCFFA6;">Resistencia al cambio de los usuarios</mark> y a compartir información entre departamentos.
- <mark style="background: #ADCCFFA6;">Dificultad para integrar información de otros SI</mark> independientes.

> [!warning]+
> La <mark style="background: #FF5582A6;">mayoría de fracasos están vinculados a riesgos «blandos»</mark> (gestión del cambio, resistencia de usuarios), <mark style="background: #8000E1A6;">no a problemas técnicos</mark>.

---

### 11 (SCM). Definir cadena de suministro [6]2.1.1

La cadena de suministro es una <mark style="background: #ADCCFFA6;">serie de procesos de intercambio o flujo de materiales e información</mark> que se establece tanto <mark style="background: #FFB86CA6;">dentro de la organización como fuera, con sus proveedores y clientes</mark>. Empieza con la compra de materias primas, hasta la entrega al cliente final.

Existe también un **flujo en dirección inversa**, del comprador al vendedor (*devoluciones*).

### 12 (SCM). Elementos de la cadena de suministro tradicional [6]2.1.1

Cinco conexiones principales ordenadas secuencialmente:

1. **Proveedores**: <mark style="background: #ADCCFFA6;">cómo y dónde se obtienen las materias primas</mark> para la fabricación.
2. **Producción**: <mark style="background: #ADCCFFA6;">conversión de la materia prima en productos finales dentro de la empresa</mark>. Incluye <mark style="background: #FFB8EBA6;">procesos productivos, control de calidad y gestión de planta</mark>.
3. **Distribución**: <mark style="background: #FFB86CA6;">hacer llegar los productos finales al consumidor a través de</mark> la <mark style="background: #FFB8EBA6;">red de almacenes, distribuidores y comercios minoristas</mark>. También se llama **logística** y abarca transporte, almacenaje y reposición.
4. **Vendedores** (*canal*): <mark style="background: #ADCCFFA6;">ponen el producto a disposición del cliente</mark>.
5. **Clientes**: <mark style="background: #ADCCFFA6;">final</mark> de la cadena.

### 14 (SCM). Funcionalidades que una solución SCM proporciona a la empresa [6]2.5

Una solución SCM <mark style="background: #ADCCFFA6;">da soporte a los cinco procesos principales (control, planificación, suministro, ejecución, entrega)</mark> ofreciendo:

- **Generar previsiones de demanda** y desarrollar **planes de abastecimiento y fabricación**.
- Ayudar a tomar **mejores decisiones operativas**.
- **Determinar dónde almacenar** los productos terminados.
- **Identificar el transporte óptimo**.
- **Planificación de la demanda**.
- **Gestión del flujo de productos** a través de centros de distribución y almacenes, <mark style="background: #FFB8EBA6;">asegurando entregas eficientes en los lugares adecuados</mark>.

---

### 16 (CRM). Definir CRM desde el punto de vista empresarial y tecnológico [6]3.1,3.2

CRM tiene **dos significados complementarios**:

**Desde el punto de vista empresarial**: CRM es una **estrategia de negocio construida para mejorar el servicio de atención al cliente**, cuyo objetivo es **aprender más sobre las necesidades y comportamientos de los clientes para desarrollar fuertes relaciones de colaboración**. Es una actitud, una **cultura de centralización en el cliente** por parte de toda la organización. La AEMR lo define como «conjunto de estrategias de negocio, marketing, comunicación e infraestructuras tecnológicas, diseñadas con el objetivo de construir una relación duradera con los clientes, identificando, comprendiendo y satisfaciendo sus necesidades». Kotler: «proceso de construcción y conservación de relaciones rentables con los clientes mediante la entrega de un valor superior y mayor satisfacción».

**Desde el punto de vista tecnológico**: los sistemas CRM aportan **la tecnología para implantar un modelo organizativo de gestión empresarial que integre las funciones administrativas/financieras, logística, producción y RRHH, situando al cliente en posición central**. Permiten un aprendizaje constante de preferencias y comportamientos y dan soporte operativo a la estrategia.

**Las dos dimensiones son inseparables**: sin la estrategia, la tecnología CRM es una agenda glorificada; sin la tecnología, la estrategia es inejecutable a escala. La implantación exige cambio cultural y tecnológico simultáneos.

### 18 (CRM). Objetivos principales del CRM [6]3.2

1. **Satisfacción del cliente**: que el cliente perciba que es **valorado de forma especial y tratado de forma individualizada**, con los productos y servicios que requiere. Es el objetivo más inmediato.
2. **Fidelización**: convertir clientes ocasionales en **fieles a largo plazo** que prefieran nuestros productos frente a la competencia. Se construye con tiempo y sensibilidad hacia el cliente.
3. **Incremento de los ingresos**: una base de clientes fieles compra más, más a menudo y atrae nuevos. El CRM identifica oportunidades de *upselling* y *cross-selling*.
4. **Incremento del margen de beneficio**: la mejor segmentación, fidelización y optimización **incrementan el margen por cliente**; un cliente fiel cuesta menos de mantener que uno nuevo de captar.

### 20 (CRM). Tareas del CRM operacional [6]3.3.1

El CRM operacional es la **parte más técnica**: abarca desde la identificación de clientes potenciales hasta el servicio posventa. Tareas:

- **Automatización de la fuerza de ventas** (núcleo más importante): información del mercado y competencia a los agentes, coordinación del equipo comercial, información de productos y clientes, informes actualizados del estado de operaciones, evaluación del rendimiento (ofertas, campañas, productos, zonas, agentes), automatización de tareas de rutina.
- **Automatización de marketing**: planificar, ejecutar y mejorar en tiempo real campañas. Construcción/gestión de campañas, medición de operaciones ganadas/perdidas, gestión de oportunidades, información de la competencia, distribución de publicaciones.
- **Help desk y gestión de áreas de soporte**: aplicaciones para resolver incidencias técnicas sobre el producto.
- **Gestión del servicio al cliente**: funciones técnicas con más contacto directo con el cliente.
- **Call center**: centralización de llamadas con integración a la ficha del cliente.
- **Gestión de incentivos** al equipo comercial (comisiones, premios).
- **Gestión de relaciones con socios**: contratos, niveles de servicio (SLA), gestión de casos.
- **Gestión de calidad** de procesos comerciales y de atención.
- **Métricas CRM**: variables de negocio como **satisfacción de clientes** y **tiempo de entrega**.

### 21 (CRM). Tareas del CRM analítico [6]3.3.2

El CRM analítico **analiza la información proporcionada por el CRM operacional para comprender mejor el comportamiento de los clientes**. Tareas:

- **Análisis del comportamiento del cliente**: identificar patrones de compra, frecuencia, canales preferidos, momentos del ciclo de vida.
- **Diseño de estrategias de marketing**: campañas dirigidas, personalizadas, optimizadas por segmento y canal.
- **Predicción de ventas**: estimación de demanda futura por producto, región o cliente.
- **Segmentación de clientes**: agrupación por comportamiento, valor económico o riesgo de abandono.
- **Scoring** de clientes y *leads*: puntuaciones para priorizar actividad comercial.
- **Análisis de campañas**: evaluar qué funcionó, en qué segmento y con qué canal.
- **Predicción de *churn***: identificar clientes con riesgo elevado de abandono para anticipar acciones de retención.

**Tecnologías de soporte**: usa **minería de datos** (clustering para segmentar, clasificación para predecir churn, reglas de asociación para productos complementarios) y se apoya en **BI** (cuadros de mando, OLAP). Requiere integración del CRM con telefonía avanzada, correo, web, reconocimiento de voz.

Convierte los datos operativos en **conocimiento accionable**: es el puente entre la cantidad de interacciones diarias y la calidad de las decisiones estratégicas.

---

## Tema 3 — Implantación de ERPs

### 1. Enumerar los 6 componentes del ciclo de vida de implantación de un ERP así como las fases posteriores [7]2

Según *Rodríguez*/*Joana*, el ciclo se compone de <mark style="background: #ADCCFFA6;">cuatro fases básicas más dos procesos continuos</mark>.

**Cuatro fases básicas**:

1. <mark style="background: #FFB8EBA6;">Adopción</mark>: decisión de comprar un sistema integrado paquetizado frente a alternativas (desarrollo a medida).
2. <mark style="background: #FFB8EBA6;">Selección</mark>: elegir qué ERP concreto, qué módulos y qué partes requieren adaptación.
3. <mark style="background: #FFB8EBA6;">Implantación</mark>: parametrización del sistema, desarrollos específicos e integración con sistemas heredados.
4. <mark style="background: #FFB8EBA6;">Puesta en marcha</mark>: arranque, estabilización, corrección de errores y adopción efectiva.

**Dos procesos transversales** (continuos durante todo el ciclo):

5. **Gestión del cambio**: adaptación de organización, procesos y personas a la nueva tecnología.
6. **Gestión del proyecto**: planificar, organizar, dirigir y administrar para asegurar los objetivos.

**Fases posteriores** (Pastor y Esteves, 1999): <mark style="background: #FFB86CA6;">mantenimiento</mark> (correctivo y evolutivo), <mark style="background: #FFB86CA6;">evolución</mark> (*patches* y *releases*), <mark style="background: #FFB86CA6;">migración</mark> a nueva versión y <mark style="background: #FFB86CA6;">adquisición de nuevos módulos</mark> para cubrir nuevas áreas.

### 2. Enumerar las principales razones que tienen los directivos para adoptar un ERP [7]p17

Según las encuestas entre directivos, **tres razones principales**:

- <mark style="background: #FFB8EBA6;">Mejorar la exactitud y disponibilidad de la información</mark> (que toda la empresa hable el mismo idioma y use los mismos datos).
- <mark style="background: #FFB8EBA6;">Mejorar la información para la toma de decisiones directivas</mark> (acceso ágil a información agregada y consistente).
- <mark style="background: #FFB8EBA6;">Reducir costes y mejorar la eficiencia</mark> (eliminar tareas duplicadas, automatizar rutinas).

Desde IT, el ERP debería **eliminar silos de información** y **reducir costes de mantenimiento**, repartiendo los costes de desarrollo y actualización entre muchos clientes a través del paquete estándar.

### 7. Describir qué aspectos debe cubrir la fase de análisis de la situación actual en la implantación de un ERP [7]5.3

Esta fase debe permitir <mark style="background: #ADCCFFA6;">saber de dónde se parte</mark> y qué aspectos tener en cuenta para el sistema objetivo. Debe cubrir **ocho aspectos**:

- <mark style="background: #FFB8EBA6;">Estructura organizativa</mark>: cómo está organizada la empresa hoy.
- <mark style="background: #FFB8EBA6;">Procesos</mark>: cómo se hacen las cosas actualmente.
- <mark style="background: #FFB8EBA6;">Datos maestros</mark>: información clave (clientes, productos, proveedores) y su estructura.
- <mark style="background: #FFB8EBA6;">Mapa de interfases</mark>: qué sistemas existen y cómo se conectan entre sí.
- <mark style="background: #FFB8EBA6;">Estrategia de conversión de datos</mark>: cómo se trasladan los datos del sistema actual al nuevo.
- <mark style="background: #FFB8EBA6;">Información de gestión crítica</mark>: la que permite la toma de decisiones y la medida del rendimiento.
- <mark style="background: #FFB8EBA6;">Predisposición al cambio de cada directivo afectado</mark>: identificar aliados y resistencias.
- <mark style="background: #FFB8EBA6;">Infraestructura tecnológica disponible</mark>: hardware, software de base, gestor de BBDD.

A diferencia de los proyectos clásicos, en ERP el análisis del «*as-is*» es <mark style="background: #FFB86CA6;">ligero</mark>: sirve para identificar prácticas o usuarios críticos y fijar el punto de partida frente al cual medir los beneficios al final del proyecto.

### 9. Conocer los factores de éxito en la etapa de puesta en marcha del ERP [7]p45-46

Según el estudio de **Esteves y Pastor (2004)**, los factores de éxito en la puesta en marcha (preparación final + *go live*) son:

- <mark style="background: #ADCCFFA6;">El papel del jefe de proyecto</mark>: liderazgo, anticipación, dirección firme bajo presión.
- <mark style="background: #ADCCFFA6;">La comunicación efectiva</mark>: hacia dentro del equipo y hacia toda la organización afectada.
- <mark style="background: #ADCCFFA6;">La anticipación preventiva de problemas</mark>: detectar y mitigar riesgos antes de que se materialicen.
- <mark style="background: #ADCCFFA6;">El apoyo continuado de la alta dirección</mark>: respaldo visible y constante del *sponsor*, no sólo en el discurso inicial.

Complemento desde el lado del usuario: <mark style="background: #FFB86CA6;">buen soporte cercano</mark> con escalado claro, <mark style="background: #FFB86CA6;">procedimiento ágil de resolución de incidencias</mark> y <mark style="background: #FFB86CA6;">monitorización del arranque</mark> con comunicación objetiva de éxitos y problemas.

---

## Tema 5 (I) — Inteligencia de negocio (BI + Data Mining)

### 4. Componentes básicos de BI [8]p41

Cano identifica los **seis componentes** que aparecen en todo proyecto de BI:

1. **Problemática empresarial** a la que se quiere dar respuesta (punto de partida; sin problema claro, BI es ejercicio académico).
2. **Equipo de personas o una persona** que lleve a cabo el análisis (con criterio de negocio para formular preguntas e interpretar resultados).
3. **Información de los sistemas internos** (operacionales/transaccionales): base interna del análisis.
4. **Información externa**: contexto que lo interno por sí solo no puede aportar.
5. **Datawarehouse**: base de datos analítica donde se integra la información.
6. **Aplicación de Business Intelligence**: herramientas de análisis y visualización (cuadros de mando, OLAP, *query & reporting*, minería de datos).

La ausencia de cualquiera de ellos compromete los resultados.

### 5. Características del esquema estrella [8]p79

Modelo de datos analítico estándar en BI. Recibe su nombre porque visualmente se asemeja a una estrella: una tabla central rodeada de tablas radiales.

**Características**:

- **Una tabla de hechos central** (*fact table*): contiene las métricas cuantitativas del negocio (importes, cantidades, márgenes) y las claves foráneas hacia las dimensiones. Cada fila es una observación.
- **Una sola tabla por dimensión**: las tablas de dimensiones rodean a la tabla de hechos y aportan el **contexto descriptivo** (cliente, producto, tiempo, tienda). Responden al «quién, dónde, cuándo, qué».
- **La clave de la tabla de hechos se forma por concatenación** de las claves de las distintas dimensiones.
- **Relación 1:N** entre cada dimensión y la tabla de hechos.
- **Desnormalización**: acepta cierta **redundancia en las dimensiones** para minimizar *joins* y acelerar consultas.

**Variantes**: cuando se unen distintos esquemas estrella que comparten dimensiones se forma un **esquema galaxia**. Si se normalizan las dimensiones rompiéndolas en sub-tablas se obtiene un **esquema copo de nieve** (más eficiente en espacio, más lento en consultas). La estrella es el **estándar de oro** en BI moderno porque el almacenamiento es barato y lo que importa es la velocidad de consulta.

### 8. Concepto de jerarquía en una dimensión, facilidades y ejemplo [8]p83

**Concepto**: estructura lógica que **organiza los datos de una dimensión en niveles sucesivos de detalle**, del más general al más específico. Cada nivel está contenido dentro del superior, como una matrioshka.

**Facilidades**:

- **Navegación intuitiva** mediante **drill-down** (profundizar) y **roll-up** (agregar) sin generar nuevos informes.
- **Uso de un solo informe para distintos niveles** de análisis.
- **Análisis de causa-raíz**: si las ventas en España caen, drill-down para ver qué comunidad falla, qué ciudad y qué tienda.
- **Orden visual**: arriba lo agregado, abajo el detalle bajo demanda.

**Ejemplo — dimensión Geografía**:

```
Nivel 1 (Top):    Continente (Europa)
Nivel 2:          País (España)
Nivel 3:          Ciudad (Madrid)
Nivel 4 (Base):   Tienda específica
```

En el dashboard se ve una sola barra «Europa: 1.000.000 €». Doble clic → países; clic en España → ciudades; clic en Madrid → tiendas. Como un telescopio que permite ver desde el planeta entero hasta una hormiga.

Otra jerarquía típica: **temporal** (Año → Trimestre → Mes → Día).

### 10. Componentes de BI y relacionarlos gráficamente [8]p93-94

Flujo arquitectónico de los componentes técnicos:

```
       FUENTES
   (operacionales / departamentales / externas)
            │
            ▼
          ETL
   (Extract → Transform → Load)
            │
            ▼
   DATAWAREHOUSE + Datamarts + Metadata
            │
            ▼
   HERRAMIENTAS ANALÍTICAS
   (OLAP, Query & Reporting,
    Minería de datos, Dashboards)
            │
            ▼
       USUARIO FINAL
```

**Recorrido**: las fuentes aportan datos brutos; el ETL los extrae, limpia, transforma y carga (60-80% del esfuerzo del proyecto); el datawarehouse (con datamarts y metadata) los almacena de forma orientada al análisis; las herramientas analíticas los explotan para entregar información elaborada al usuario final. La metadata acompaña al DW haciendo todo el flujo trazable y auditable.

### 11. Fuentes de información de BI [8]p95-96

Tres tipos:

- **Sistemas operacionales** (transaccionales internos): **ERP, CRM, SCM**. Aportan la mayor parte de los datos del DW: cada pedido, venta o movimiento de almacén alimenta el repositorio. Son la base estructurada del BI.
- **Sistemas de información departamentales**: aplicaciones específicas de cada área no integradas en el ERP corporativo. Ejemplos: **previsiones** de ventas (hojas de cálculo del departamento comercial), **presupuestos** financieros, planes de producción. Suelen estar dispersos en aplicaciones heterogéneas.
- **Información externa**: datos que vienen de fuera para contextualizar lo interno. Ejemplos: **estudios de mercado**, **datos poblacionales**, indicadores macroeconómicos, datos meteorológicos, índices sectoriales, datos de competidores. Se compran a proveedores especializados (Nielsen, INE) o se extraen de fuentes públicas.

La combinación de las tres fuentes permite responder preguntas que ninguna por separado podría resolver.

### 16. Características de las herramientas ETL [8]p110

Una herramienta ETL profesional debe ofrecer **siete características**:

- **Interfaz gráfica**: entorno visual para diseñar flujos sin programar todo a mano.
- **Gestión de metadatos** integrada: documenta qué datos se mueven, con qué transformaciones.
- **Soporte para extracción**: desde múltiples fuentes (BBDD, ficheros, APIs, SAP, mainframes).
- **Soporte para transformación**: funciones de limpieza, agregación, derivación de campos, aplicación de reglas de negocio.
- **Soporte para carga** en el DW: carga incremental y masiva, gestión de claves subrogadas.
- **Acceso remoto a datos**: conexión a fuentes distribuidas geográficamente.
- **Administración**: monitorización, gestión de errores, *logs*, alertas, planificación de trabajos.

Estas características diferencian una herramienta profesional (Informatica, Talend, IBM DataStage, Microsoft SSIS) de un conjunto de scripts hechos a mano.

### 18. Características de un datawarehouse [8]p114-115

**Bill Inmon** definió las **cuatro características esenciales** que diferencian un DW de una BD transaccional:

- **Orientado a un área (problemas de negocio)**: cada parte del DW está construida para **resolver un problema definido por los decisores** (hábitos de compra, calidad de productos, productividad de fabricación). La información se organiza en torno a **áreas** (ventas, clientes, transporte). Provee visión completa y concisa, obviando lo irrelevante.
- **Integrado**: la información se transforma en **medidas, códigos y formatos comunes**. Permite estandarización: misma moneda, código único de cliente, formatos de fecha homogéneos. Sin integración el DW sería una colección heterogénea imposible de cruzar.
- **Indexado en el tiempo**: **mantiene información histórica** referida a unidades temporales (horas, días, semanas, meses, años). El DW conserva la evolución completa con sello temporal, permitiendo analizar tendencias y estacionalidad.
- **No volátil**: los usuarios **no mantienen la información** como en un entorno transaccional. Se almacena para la toma de decisiones y se **actualiza periódicamente** (cargas nocturnas/semanales), no continuamente. Los datos se acumulan, no se sobrescriben: las cifras de un trimestre cerrado no cambian.

Adicionalmente, **soporta la toma de decisiones**: éste es su propósito esencial. Kimball complementa señalando que la información del DW debe ser consistente, separable y combinable.

### 21. Qué es el metadata en un datawarehouse [8]p120

El metadata es el **repositorio de información sobre la información** almacenada en el DW: datos que describen otros datos. Es lo que hace que el DW sea **explorable, comprensible y auditable**.

Para cada elemento del DW, la metadata contiene:

- **Significado y atributos**: qué representa el dato (¿«importe de venta» incluye IVA?), unidades de medida, valores válidos, reglas de negocio.
- **Origen**: de qué sistema procede (ERP, CRM, hoja de cálculo), qué transformaciones ha sufrido en el ETL, relaciones con otros datos.
- **Responsables**: propietario (qué área de negocio lo gobierna), custodio técnico (qué equipo de IT lo mantiene), política de calidad y actualización.

Sin metadata, un DW se convierte rápidamente en un **cementerio de datos sin contexto**: los analistas no saben qué significa cada campo, los auditores no pueden trazar de dónde viene cada cifra. La metadata es lo que permite que el DW sea un **activo gestionable a largo plazo**.

### 23. Funcionalidades de las herramientas OLAP [8]p126

Las herramientas **OLAP** (*Online Analytical Processing*) permiten **analizar la información a distintos niveles de agregación y sobre múltiples dimensiones** de forma rápida e interactiva.

**Funcionalidades principales**:

- **Análisis multidimensional**: cruzar varias dimensiones simultáneamente (tiempo × producto × geografía × cliente × canal).
- **Distintos niveles de agregación**: navegación entre niveles aprovechando las **jerarquías** de cada dimensión.
- **Consultas ad-hoc rápidas**: el usuario formula consultas sobre la marcha sin pedir nuevos informes a IT.
- **Rotación de dimensiones** (*slicing & dicing*): reorganizar los ejes para distintas perspectivas.
- **Profundización y agregación** (*drill-down*, *roll-up*) a través de jerarquías.
- **Cálculos derivados**: ratios, porcentajes, comparaciones, varianzas.

Cumplen la regla **FASMI** (*Fast Analysis of Shared Multidimensional Information*). Tipos: **ROLAP** (acceso a BD relacional, sin límite de tamaño, más lento), **MOLAP** (almacén multidimensional propio, más rápido pero limitado) y **HOLAP** (híbrido).

### 24. Cubo OLAP y operaciones [8]p127-129

**Definición**: estructura multidimensional donde **cada eje del cubo es una dimensión** (tiempo, producto, geografía, cliente) y el **interior contiene los hechos** o medidas (unidades vendidas, importe). Cada celda es la intersección de un valor concreto de cada dimensión. Aunque se llama «cubo», puede tener más de tres dimensiones (un hipercubo).

**Operaciones sobre el cubo**:

- **Pivoting / slicing (rotación)**: **cambiar el orden de las dimensiones** en los ejes para verlo desde otro ángulo (pasar de «ventas por cliente» a «ventas por libro»).
- **Dicing (selección)**: **seleccionar sólo algunas celdas** del cubo, filtrar un subconjunto («ventas al Cliente 2, de Libros 1 y 2, en el Año 1»).
- **Roll-up**: **agregar a un nivel superior** de la jerarquía, eliminando detalle (ver el total por cliente en todos los años).
- **Drill-down**: **bajar a más detalle** dentro de una jerarquía (de materia → libros individuales dentro de la materia). Operación inversa al roll-up.

Estas operaciones permiten al usuario **explorar libremente desde cualquier ángulo y a cualquier nivel** sin generar informes nuevos.

### 26. Las 2 características de la minería de datos interesantes para la empresa [9]

Kurt Thearling identifica dos capacidades fundamentales:

**1. Predicción automatizada de tendencias y comportamientos** (*automated prediction of trends and behaviors*). Automatiza el proceso de encontrar **información predictiva** en grandes BBDD. Preguntas que antes requerían análisis manual extenso se responden directamente de los datos. Ejemplos: **targeted marketing** (identificar los clientes más propensos a responder a una campaña), **predicción de bancarrota**, identificación de segmentos de población que responderán similarmente. Algoritmos típicos: redes neuronales, árboles de decisión, regresión.

**2. Descubrimiento automatizado de patrones previamente desconocidos** (*automated discovery of previously unknown patterns*). Las herramientas barren las BBDD identificando **patrones ocultos** en un solo paso. La clave es que son patrones que los expertos podrían no detectar porque están **fuera de sus expectativas**. Ejemplos: análisis de ventas retail para identificar productos no relacionados que se compran juntos (pañales y cerveza los viernes), **detección de fraude** en tarjetas, identificación de datos anómalos. Algoritmos típicos: reglas de asociación, clustering, detección de anomalías.

Ambas convierten **grandes volúmenes de datos en ventaja competitiva** sin equipos enormes de analistas manuales, libres de los sesgos cognitivos de los expertos humanos.

### 27. Técnica de modelización en minería de datos + ejemplo [9]

**Concepto**: modelizar consiste en **construir un modelo en una situación donde se conoce la respuesta y aplicarlo después a otra donde no se conoce**. Thearling lo ilustra con el buscador de galeones hundidos: estudia dónde se encontraron galeones en el pasado, qué características compartían esas zonas (corrientes, rutas, eventos), construye un modelo y navega a las zonas con mayor probabilidad.

En la minería automatizada el principio es el mismo: los ordenadores cargan información de situaciones con respuestas conocidas y el software **destila las características que van al modelo**. Una vez construido, se aplica a situaciones donde la respuesta no se conoce.

**Ejemplo — captación de clientes en una telco**:

| | Clientes actuales | Prospectos |
| - | - | - |
| Información general (demográficos: edad, sexo, crédito) | **Conocida** | **Conocida** |
| Información propietaria (consumo de larga distancia) | **Conocida** | **Objetivo a predecir** |

La telco conoce todo de sus clientes actuales (incluido cuánto gastan), y solo conoce demografía de prospectos. El objetivo es **inferir el consumo probable de los prospectos a partir de su demografía**, usando como puente el modelo aprendido de los actuales.

Un modelo simple: «El 98 % de mis clientes que ganan más de 60.000 $/año gastan más de 80 $/mes en larga distancia». Se aplica a la demografía de los prospectos y se identifican los más valiosos para concentrar la inversión en marketing.

**Validación**: se reserva una parte de los datos conocidos (*holdout*) sin usarla en construcción, y se comprueba que el modelo predice correctamente sobre esa parte aislada.

### 29. Clasificación y clustering [9]

Ambas dividen un conjunto en grupos mutuamente exclusivos, pero parten de premisas distintas según el algoritmo conozca o no las categorías de antemano.

**Clasificación (aprendizaje supervisado)**. Usa **datos etiquetados** para **entrenar un modelo que asigne nuevos datos a categorías ya definidas**.

- **Objetivo**: predecir a qué categoría pertenece un nuevo registro.
- **Conocimiento previo**: clases conocidas («spam»/«no spam», «solvente»/«insolvente»).
- **Variables**: concretas predefinidas por el experto.
- **Algoritmos**: árboles de decisión (CART, CHAID), regresión logística, SVM, redes neuronales.
- **Ejemplo**: detección de spam.

**Clustering (aprendizaje no supervisado)**. Trabaja con **datos no etiquetados** para encontrar **agrupaciones naturales basadas en la similitud**.

- **Objetivo**: agrupar objetos similares en clusters sin etiquetas previas.
- **Conocimiento previo**: ninguno; el algoritmo descubre los grupos.
- **Variables**: todas las disponibles, sin preselección del experto.
- **Algoritmos**: K-means, agrupamiento jerárquico, DBSCAN.
- **Ejemplo**: segmentación de clientes.

| Característica | **Clasificación** | **Clustering** |
| - | - | - |
| Tipo de aprendizaje | Supervisado | No supervisado |
| Datos | Etiquetados | Sin etiquetas |
| Conocimiento previo | Clases conocidas | Grupos por descubrir |
| Variables | Concretas predefinidas | Todas las disponibles |
| Finalidad | Predecir clase | Descubrir patrones |
| Ejemplo | Detección de spam | Segmentación de clientes |

---

## Tema 5 (II) — Gestión de procesos de negocio (BPM)

### 2. Definir el concepto de proceso de negocio [10]p6

Un **proceso de negocio** es un <mark style="background: #ADCCFFA6;">conjunto de tareas coordinadas, realizadas por personas o sistemas</mark>, cuyo fin, es <mark style="background: #FFB86CA6;">alcanzar un objetivo concreto del negocio</mark>. Tres atributos esenciales: 
1. Tareas **coordinadas** (<mark style="background: #FFB8EBA6;">no aleatorias</mark>).
2. Actores **heterogéneos** (<mark style="background: #FFB8EBA6;">personas y sistemas</mark> indistintamente).
3. **Orientación a un objetivo** del negocio. 
> [!attention]+
> Es además, **modelable y medible**.

*Ejemplos*: gestión de pedidos, gestión de recursos, aprovisionamiento interno, gestión de vacaciones.

**Proceso de negocio ejecutable**: <mark style="background: #ADCCFFA6;">proceso cuyas tareas pueden orquestarse en una plataforma software</mark>, combinando <mark style="background: #8000E1A6;">tareas automatizadas y tareas de personas</mark>.

### 4. Ciclo de vida de un proceso de negocio y perfil de usuario por fase [10]p7

Las fases y el perfil de usuario adecuado:

| Fase                           | Descripción                                                                                       | Perfil de usuario                                                                                                  |
| ------------------------------ | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **Modelar**                    | Definir el <mark style="background: #ADCCFFA6;">modelo del proceso y sus objetivos</mark>         | *Técnico + Empresarial* (negocio aporta conocimiento del proceso real y objetivos \| IT aporta viabilidad técnica) |
| **Implementar**                | <mark style="background: #ADCCFFA6;">Construir/configurar el proceso</mark> en *BPMS* y testearlo | *Técnico*                                                                                                          |
| **Desplegar**                  | Pasar a <mark style="background: #ADCCFFA6;">producción</mark>                                    | *Técnico + Empresarial* (ambos validan que funciona en producción)                                                 |
| **Ejecutar + Medir + Mejorar** | <mark style="background: #ADCCFFA6;">Operación, medición con KPI y mejora</mark> continua         | *Técnico + Empresarial* (negocio interpreta KPI e IT implementa las mejoras)                                       |

En el <mark style="background: #FFB86CA6;">centro del ciclo</mark> están los **KPI** (*Key Performance Indicators*), que se <mark style="background: #FFB8EBA6;">miden durante la ejecución y alimentan la siguiente iteración</mark>.

**Causa fundamental de fracaso**: <mark style="background: #ADCCFFA6;">diferencia cultural entre negocio e IT</mark>. Aunque comparten objetivos, <mark style="background: #FFB8EBA6;">manipulan conceptos diferentes y no hablan el mismo idioma</mark>. **BPM cierra esa brecha** proporcionando un <mark style="background: #FFB86CA6;">marco compartido</mark>.

### 7. Estándares BPM de diseño, intercambio y ejecución [10]p10-12

Tres estándares principales, uno para cada fase del ciclo:

| Estándar                                         | Función                                                                                                                                   |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **BPMN** (*Business Process Modeling Notation*)  | **Diseño** — <mark style="background: #ADCCFFA6;">notación gráfica estándar</mark> para representar procesos                              |
| **XPDL** (*XML Process Definition Language*)     | **Intercambio entre herramientas** — formato *XML* <mark style="background: #ADCCFFA6;">para mover modelos BPMN entre herramientas</mark> |
| **BPEL** (*Business Process Execution Language*) | **Ejecución** — <mark style="background: #ADCCFFA6;">representación XML ejecutable</mark>, interpretada por motor *BPEL*                  |

### 12. Qué permite BPEL [10]p16

**BPEL** (*Business Process Execution Language*) es un <mark style="background: #ADCCFFA6;">lenguaje basado en XML diseñado para describir la lógica de ejecución de un proceso de negocio</mark>. <mark style="background: #FF5582A6;">No es de propósito general</mark>, <mark style="background: #FFB86CA6;">es específico de dominio</mark> para **orquestar la ejecución de procesos sobre servicios web**. <mark style="background: #FF5582A6;">No implementa lógica de negocio</mark>, sino que decide el <mark style="background: #FFB8EBA6;">orden de las tareas, quién las hace y qué pasa si algo falla</mark>.

**Capacidades clave**:

- <mark style="background: #ADCCFFA6;">Control de flujo</mark>: define <mark style="background: #FFB8EBA6;">secuencias</mark>, <mark style="background: #FFB8EBA6;">bucles</mark> (`while`), <mark style="background: #FFB8EBA6;">ramificaciones condicionales</mark> (`if-then`) y <mark style="background: #FFB8EBA6;">ejecuciones en paralelo</mark>.
- <mark style="background: #ADCCFFA6;">Gestión del estado</mark>: el <mark style="background: #FFB86CA6;">proceso recuerda en qué punto está</mark> aunque dure días o semanas.
- <mark style="background: #ADCCFFA6;">Tratamiento de excepciones</mark>: define <mark style="background: #FFB86CA6;">qué hacer si un servicio falla</mark>; permite <mark style="background: #FFB8EBA6;">deshacer pasos</mark> previos (mecanismo de **compensación**), <mark style="background: #FFB8EBA6;">reintentar</mark>, <mark style="background: #FFB8EBA6;">escalar</mark>.

> [!danger]+
> Requiere un **motor de ejecución** que interprete el *XML* del proceso.

### 13. Cómo BPEL usa y crea servicios web [10]p17

*BPEL* **vive por y para los servicios web**: <mark style="background: #FFB86CA6;">son a la vez su entrada</mark> (lo que invoca) <mark style="background: #FFB86CA6;">y su salida</mark> (lo que expone).

- <mark style="background: #ADCCFFA6;">Cómo los usa</mark> **(invocación)**: <mark style="background: #FFB8EBA6;">cada paso del proceso es una llamada a un servicio externo</mark>. *BPEL* <mark style="background: #FFB86CA6;">solo conoce la interfaz</mark>, <mark style="background: #FF5582A6;">no la implementación interna</mark>.
	- `<invoke>`: actividad que <mark style="background: #FFB8EBA6;">invoca un servicio</mark>.
	- `partnerLink`: conector que <mark style="background: #FFB8EBA6;">apunta al servicio</mark>.
	- `operation`: método específico a <mark style="background: #FFB8EBA6;">ejecutar</mark>.
	- `inputVariable`/`outputVariable`: <mark style="background: #FFB8EBA6;">variables XML</mark> enviada y de respuesta.
- <mark style="background: #ADCCFFA6;">Cómo los crea</mark> (**exposición**): una vez definido un proceso *BPEL*, **se convierte automáticamente en un nuevo servicio web** <mark style="background: #FFB86CA6;">reutilizable</mark>. Ejemplo: un proceso que coordina los servicios *X*, *Y* y *Z*, <mark style="background: #FFB8EBA6;">se expone como un único servicio web que otros sistemas invocan sin saber que detrás</mark> hay tres sistemas coordinándose.

### 22. Cómo BPM y SOA pueden complementarse [10]p29-30

**BPM y SOA no son alternativas rivales sino enfoques complementarios** que cubren dos lados del mismo problema.

**Desde dónde aborda cada uno el problema**:

- <mark style="background: #ADCCFFA6;">BPM (top-down, perspectiva empresarial)</mark>: define **qué procesos** necesita la empresa y, derivado, **qué servicios técnicos** son necesarios.
- <mark style="background: #ADCCFFA6;">SOA (bottom-up, perspectiva técnica)</mark>: estilo de diseño que divide las funciones del negocio en **unidades pequeñas, independientes y reutilizables**, llamadas <mark style="background: #FFB86CA6;">servicios</mark>.

**Sinergias concretas**:

1. <mark style="background: #ADCCFFA6;">Agilidad</mark>: si el negocio cambia una regla, **solo se cambia el modelo BPM**. <mark style="background: #FFB8EBA6;">No se reprograma nada</mark>, <mark style="background: #FFB86CA6;">solo se reconfigura cómo se llaman los servicios SOA existentes</mark>.
2. <mark style="background: #ADCCFFA6;">Reutilización</mark>: un <mark style="background: #FFB86CA6;">servicio SOA puede ser usado por procesos BPM distintos</mark> .
3. <mark style="background: #ADCCFFA6;">Abstracción</mark>: los <mark style="background: #FFB86CA6;">analistas de negocio diseñan procesos</mark> **sin preocuparse de la complejidad técnica**, confiando en que <mark style="background: #FFB8EBA6;">SOA expone las funciones como servicios fáciles de invocar</mark>.

---

## Referencias

- [[Tema 1 - Introducción a los SI Empresariales]]
- [[Tema 2 - Soluciones de negocio]]
- [[Tema 3 - Implantación de ERPs]]
- [[Tema 5 - Parte I - Inteligencia de negocio]]
- [[Tema 5 - Parte II - Gestión de procesos de negocio]]
- MOC del curso: [[Sistemas-Empresariales.base]]

**Fuentes bibliográficas** (`sie_biblio+objetivos.pdf`):

- **[1]** Antonio Muñoz Cañavate (2003). *Sistemas de información en las empresas*. Hipertext.net.
- **[2]** Richard T. Watson (2007). *Information Systems*. The Global Text Project.
- **[3]** Rafael Lapiedra, Carlos Devece, Joaquín Guiral (2011). *Introducción a la gestión de sistemas de información en la empresa*. UJI.
- **[5]** Isabel Guitart Hormigo (2011). *Fundamentos de SI. Módulo 1: Sistema de información empresarial*. UOC.
- **[6]** Humi Guill Fuster (2011). *Fundamentos de SI. Módulo 2: Sistemas de cooperación empresarial*. UOC.
- **[7]** J. R. Rodríguez, J. M. Joana (2011). *Fundamentos de SI. Módulo 3: Implantación de SI de empresas*. UOC.
- **[8]** Josep Lluís Cano (2008). *Business Intelligence: competir con información*.
- **[9]** Kurt Thearling (1999). *An Introduction to Data Mining*. White paper.
- **[10]** Tanguy Crusson (2006). *Business Process Management Essentials*. Glintech.
