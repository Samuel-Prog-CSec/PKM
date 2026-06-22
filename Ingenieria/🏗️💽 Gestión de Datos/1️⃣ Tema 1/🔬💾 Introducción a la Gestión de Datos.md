# 1. Introducción a la Gestión de datos
## 1.1. Diferencia entre Dato, Información y Conocimiento
Es crucial ==no confundir estos tres conceptos==, que forman una jerarquía:
* **Dato:** Es un *valor en bruto*, ==sin contexto==.
    * *Ejemplo:* "195".
* **Información:** Son *datos puestos en un contexto*, que ==les da significado==.
    * *Ejemplo:* "Luis mide 195 cm".
* **Conocimiento:** Es la *información procesada y aplicada* de forma útil para un fin específico, ==permitiendo tomar decisiones==.
    * *Ejemplo:* "Luis es una persona alta porque mide 195 cm" (esto permite decidir si jugará de pívot en el equipo de baloncesto).

## 1.2. Consideraciones sobre los datos en las empresas
* **Romper Silos:** Los *datos suelen estar separados por departamentos* (marketing, finanzas, etc.). Es fundamental ==liberarlos de estos "silos" para integrarlos y transformarlos en información útil== para toda la organización.
* **Data-Driven Business:** Las empresas modernas desarrollan nuevos *modelos de negocio basados en datos* para la toma de decisiones. En estos modelos, los ==datos se convierten en el activo más importante== de la empresa. Para que esto funcione, es fundamental **entender el negocio** para poder ==entender el papel y el valor de los datos==.

---

# 2. DAMA y el DMBOK
* **DAMA:** Es la *asociación internacional* de ==profesionales en gestión de datos==.
* **DMBOK (Data Management Body of Knowledge):** Es el "cuerpo de conocimiento" o *estándar de referencia publicado por `DAMA`*. Agrupa las mejores prácticas de la gestión de datos en **11 áreas de conocimiento**:
    1. **Gobierno del Dato:** Dirección y supervisión. Establece los derechos de decisión sobre los datos.
    2. **Arquitectura de Datos:** Define el plan de gestión de los activos de datos.
    3. **Modelado y Diseño de Datos:** Proceso de analizar y representar los requisitos de datos.
    4. **Almacenamiento y Operaciones:** Diseño e implementación de las bases de datos.
    5. **Seguridad de los Datos:** Garantiza la privacidad y confidencialidad.
    6. **Integración e Interoperabilidad:** Movimiento y consolidación de datos entre sistemas.
    7. **Gestión de Documentos y Contenidos:** Gestión del ciclo de vida de los datos no estructurados.
    8. **Datos de Referencia y Maestros:** Gestión de los datos críticos y compartidos de la organización.
    9. **Data Warehousing y Business Intelligence:** Gestión de datos para la toma de decisiones.
    10. **Metadatos:** Gestión de los "datos sobre los datos".
    11. **Calidad de los Datos:** Técnicas para medir y mejorar la idoneidad de los datos.

---

# 3. Introducción al Big Data
Se refiere a un *conjunto de datos masivos y heterogéneos* que ==superan la capacidad del software tradicional para ser capturados, gestionados y procesados== en un tiempo razonable.

## 3.1. Las "V" del Big Data
* **Volumen:** *Cantidad masiva* de datos generados.
* **Variedad:** *Diversidad de tipos* de datos (estructurados, no estructurados, etc.).
* **Velocidad:** *Rapidez* a la que los ==datos se generan y procesan==, a menudo en tiempo real.
*   **Otras V's importantes:** 
	* *Veracidad*: ==calidad== del dato.
	* *Valor*: ==aporte== a la sociedad/empresa.
	* *Viabilidad*: ==capacidad para generar un uso eficaz==.
	* *Visualización*: ==Modo== en el que los ==datos son presentados==.

## 3.2. Valor de los datos para el negocio
La **Infonomía** ==estudia del valor de los datos (o de la información)== (conceptos de Información + Economía). 6 *tipos diferentes de valores*, agrupados en *2 bloques*:
* **Valor Fundacional:** Relacionado con la ==calidad de los datos y su impacto== en el negocio.
    * *Valor intrínseco:* La ==calidad inherente de un dato==, independientemente de su uso.
    * *Valor de negocio:* La ==utilidad y relevancia de un dato para un proceso de negocio== específico.
    * *Valor de rendimiento:* El ==impacto positivo de usar los datos en los indicadores clave== (`KPIs`).
* **Valor Financiero:** Mide el valor de los datos en ==términos puramente económicos.==
    * *Valor del coste:* El ==coste de adquirir y mantener== los datos.
    * *Valor de mercado:* El ==potencial de venta o licencia== de los datos.
    * *Valor económico:* La ==contribución de los datos a la cuenta de resultados== de la empresa.

---

# 4. Tipos y Fuentes de Datos
* **Datos Estructurados:** Tienen una ==longitud y formato definidos==. Se pueden *almacenar fácilmente en tablas*. Pueden ser: 
    * *Creados*: ==datos generados por nuestros sistemas== de una manera predefinida (registros en tablas, ficheros XML asociados a un esquema). 
    * *Provocados*: datos ==creados de manera indirecta a partir de una acción== previa (valoraciones de restaurantes, películas, empresas, TripAdvisor, …). 
    * *Dirigido por transacciones*: datos que ==resultan al finalizar una acción previa de manera correcta== (facturas autogeneradas al realizar una compra, recibo de un cajero automático, etc.). 
    * *Compilados*: ==resúmenes de datos== de empresa, servicios públicos de ==interés grupal==. Entre ellos nos encontramos con el censo electoral, vehículos matriculados, viviendas públicas, entre otros.
    * *Experimentales*: datos ==generados como parte de pruebas o simulaciones== que permitirán validar si existe una oportunidad de negocio.
* **Datos No Estructurados:** *Carecen de un formato determinado* y ==no pueden almacenarse en tablas tradicionales==. Pueden ser capturados o generados.
    *   *Ejemplos:* Redes sociales, audios, vídeos, documentos de texto.
* **Datos Semiestructurados:** *No residen en una base de datos relacional* pero ==tienen marcadores u organización interna que facilita su tratamiento==. Se puede considerar también: **multi-estructurados o híbridos**.
    *   *Ejemplo:* Un documento `XML` o `JSON`.

---

# 5. Áreas y Definiciones Clave en Big Data
El **ciclo de vida del Big Data** se puede dividir en varias áreas: `Infraestructura`, `Preservación`, `Análisis`, `Explotación`, `Visualización`, `Integración`.
- **Preservación digital**: una serie de ==actividades necesarias y muy bien administradas para asegurar el acceso continuo a los materiales digitales==, por el periodo que sea necesario. Hay que garantizar que la información almacenada, gestionada y procesada *perdure en el tiempo*, ==garantizando disponibilidad y seguridad== y *evitando la obsolescencia*.
* **Análisis:** *Examinar los datos* para ==obtener conclusiones==.
    * *Descriptivo:* ¿Qué ha pasado? -> Para saber **qué caracteriza a cosas que suceden**
    * *Diagnóstico:* ¿Por qué ha pasado? -> Para saber **por qué ha sucedido**
    * *Predictivo:* ¿Qué sucederá? -> Para saber **qué sucederá**
    * *Prescriptivo:* ¿Cómo podemos hacer que suceda? -> Para **saber cómo actuar**
- **Explotación**: 
	- Los datos sirven ==para realizar acciones, tomar decisiones y aprender== de ellas. 
	- Hay que *entender los datos y saber para que sirven*. 
- **Visualización**: *Como se muestran* los datos.

## 5.2. Definiciones relacionadas
* **Data Science vs. Ingeniería de Datos:** *Son inseparables*. La **Ingeniería** ==crea los sistemas== para almacenar y procesar los datos que la **Ciencia** ==utiliza para obtener conocimiento==.
* **Data Analytics:** Proceso de ==examinar datos para extraer conclusiones==.
* **Data Mining (KDD):** *Descubrimiento de patrones y conocimiento* a ==partir de grandes volúmenes de datos==.
* **Machine Learning:** Especialidad de ==IA== que *permite a las máquinas aprender y tomar decisiones*.
* **Business Intelligence (BI):** *Proceso y tecnologías* para transformar ==datos en información y conocimiento de valor para el negocio==.

---

 # 6. Profesionales relacionados con Big Data
* **Chief Data Officer (CDO):** *Responsable de los datos* de la organización y ==su estrategia==.
* **Científico/a de Datos:** *Procesa y analiza datos* para ==descubrir conocimiento y crear modelos predictivos==.
* **Ingeniero/a de Datos:** ==Construye y mantiene la infraestructura y las tuberías== (pipelines) de datos.
* **Business Data Analyst (Analista de datos):** Recoge las *necesidades del negocio* y las =="traduce" para los científicos de datos==.
* **Administrador/a de Datos:** ==Entiende, gestiona y custodia los datos==.