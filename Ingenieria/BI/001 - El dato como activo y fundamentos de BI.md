---
tags:
  - "#Ingenieria"
  - "#Datos"
  - Introduccion
Fecha de actualización: 2025-09-24
Nota previa:
Nota siguiente: "[[002 - Implantación de sistemas BI]]"
Area: "[[Inteligencia del negocio.base]]"
---
---

# 1. El dato como activo
## 1.1. Definición y contexto
- **Dato:** Secuencia de símbolos a la que se le asigna significado por interpretación.
- **Enfoque de la asignatura:** Nos centramos en datos digitales relevantes para la actividad de negocio.
- **Data-Driven Business:** Organización que basa sus decisiones estratégicas en el análisis de datos e interpretación, no solo en la intuición.
    - _Beneficios:_ Lenguaje común, ruptura de silos y ahorro de costes.

## 1.2. Valor del dato (Ecuaciones Conceptuales)
El dato se gestiona para maximizar su valor. La fórmula conceptual clave es:
$$Valor\_Datos = MAX(Valor\_Mercado, Valor\_Interno)$$
$$Valor\_Añadido = Valor\_Interno - Valor\_Mercado$$

> **Interpretación:** Si el valor añadido es positivo, la gestión interna está creando riqueza sobre el dato crudo.

## 1.3. Factores que aumentan el Valor Interno
Para subir el valor interno se actúa sobre:
1. **Volumen:** Foco en relevancia, no solo cantidad.
2. **Calidad:** Completitud, vigencia, exactitud, precisión y consistencia.
3. **Uso y utilidad:** Número de usuarios y alcance en procesos.
4. **Relevancia estratégica:** Conexión directa con KPIs (Indicadores Clave de Desempeño).

## 1.4. El problema de los Silos de Datos
- **Definición:** Datos departamentados/aislados que dificultan la colaboración.
- **Consecuencia:** La información está dispersa, generando inconsistencias y bloqueando la "versión única de la verdad".

---

# 2. Gobierno y Gestión de Datos
## 2.1. Concepto
Enfoque riguroso que define políticas, estándares, roles y responsabilidades para gestionar el dato durante todo su ciclo de vida (adquisición, uso, eliminación).
- **Objetivo:** Asegurar que los datos sean seguros, privados, precisos y disponibles.

## 2.2. Pilares de la Gobernanza
1. **Calidad de datos:** Garantizar precisión, completitud y fiabilidad.
2. **Administración (Stewardship):** Asignación de responsabilidades y rendición de cuentas.
3. **Protección y cumplimiento:** Seguridad, acceso y privacidad.
4. **Gestión de datos:** Procesos técnicos de recolección y almacenamiento.

## 2.3. Normativa Española (Serie UNE)
AENOR ha definido normas específicas que suelen caer en examen:
- **UNE 0077 (Gobierno):** Especificación para dirigir y controlar el uso de datos.
- **UNE 0078 (Gestión):** Cubre el ciclo de vida y procesos (arquitectura, seguridad, etc.).
- **UNE 0079 (Calidad):** Gestión de la calidad del dato.
- **Guías de evaluación:** UNE 0080 (evaluación de gobierno/gestión) y UNE 0081 (evaluación de calidad).

## 2.4. Marcos Internacionales
- **COBIT 2019 (ISACA):** Marco para gobierno de TI, orientado a objetivos y procesos de mejora continua.
- **DAMA-DMBOK:** La "biblia" de la gestión de datos. Identifica 11 áreas de conocimiento (rueda de DAMA).
- **ISO/IEC 38505-1:** Aplicación de la norma ISO 38500 al gobierno de datos.

## 2.5. Niveles de Madurez
Según la norma UNE 0080, se evalúa la madurez en niveles del 0 al 5:
- Nivel 0: Incompleto.
- Nivel 1: Realizado.
- Nivel 2: Gestionado (aquí ya hay planificación y control).
- Nivel 3: Establecido.
- Nivel 4: Predecible (análisis cuantitativo).
- Nivel 5: Innovado (mejora continua).

---

# 3. Paradigmas: Ciencia, Ingeniería y Análisis
## 3.1. Ciencia de Datos (Data Science)
Definido en [[005 - Análisis de datos]]

### 3.1.1. Proceso de la ciencia de datos
1. **Obtener datos** `->`
2. **Depurar datos**: normalizarlos según un formato predeterminado `->`
3. **Explorar datos**: análisis preliminar, para planificar otras estrategias para su modelado `->`
4. **Modelar datos**: estructurar los datos de la manera óptima para su análisis `->`
5. **Interpretar los resultados**: convertir la información de datos en acción (representar tendencias y predicciones)

## 3.2. Ingeniería de Datos
Responsable de la infraestructura y de que los datos estén "listos para usar". **Tareas:** 
- Elaborar estrategias y crear "diccionarios de datos" que pueden convertirse en una referencia sobre el significado de los datos
- "Limpieza" de datos para que puedan estandarizarse en todas las fuentes de datos y ser confiables
- Transformación (Data Lake -> DW)
- Importar datos de fuentes no estructuradas y transformar los datos
- Crear "canalizaciones de datos" que consolidan datos de múltiples fuentes y los ponen a disposición para el análisis
> [!info]+
> El **ingeniero de datos** (data engineer) se encarga de construir y mantener las estructuras de datos y las arquitecturas tecnológicas necesarias para la ingestión, procesamiento e implementación a gran escala de aplicaciones que usan datos de forma intensiva. Sabe implementar las tecnologías adecuadas para garantizar que los datos estén en un estado utilizable para estos dos profesionales.

## 3.3. Análisis de Datos (Data Analytics)
Proceso que permite examinar datos ya estructurados para encontrar tendencias y apoyar decisiones. **Técnicas clave:**
- **Business Intelligence** (haciendo uso de [[#4.5. OLAP (Online Analytical Processing)|OLAP]] como herramienta en la fase de análisis): extraer conocimiento mediante técnicas de sumarización y operadores multidimensionales.
- **Data Mining**: permite explorar grandes bases de datos, de manera automática o semiautomática, con el objetivo de encontrar patrones repetitivos que expliquen el comportamiento de estos datos.

---

# 4. Fundamentos de Business Intelligence (BI)
## 4.1. Definición y Objetivo
Procesos y herramientas para consolidar, analizar y dar acceso a extensas cantidades de datos para extraer conocimiento y ayudar a la toma de decisiones.
> [!attention]+
> Las organizaciones necesitan entender QUÉ está pasando, CUÁNDO, DÓNDE, CÓMO, QUIÉN Y POR QUÉ a tiempo y en forma adecuada.

### 4.1.1. FASE 1: Dirigir y planear
Recolectar los requerimientos de información específicos de los diferentes usuarios, así como entender sus diversas necesidades, para que luego en conjunto con ellos se generen las preguntas que les ayudaron a alcanzar sus objetivos. 

### 4.1.2. FASE 2: Recolección de información
Se realiza el proceso de extraer desde las diferentes fuentes de información de la empresa los datos que serán necesarios para encontrar las respuestas a las preguntas planteadas. 

### 4.1.3. FASE 3: Procesamiento de datos
Se integran y cargan los datos en crudo en un formato utilizable para el análisis (**proceso ETL**).

### 4.1.4. FASE 4: Análisis y producción
Trabajar sobre los datos extraídos e integrados, para crear conocimiento.

### 4.1.5. FASE 5: Difusión
Se entrega a los usuarios que lo requieran las herramientas necesarias que les permitirán explorar los datos de manera sencilla e intuitiva.

## 4.2. Data Warehouse (DW)
Conjunto de procesos encargados de extraer, transformar, consolidar, integrar y centralizar los datos que una organización genera en todos los ámbitos de su actividad diaria (compras, ventas, producción, etc.) y/o información externa relacionada.
- **Data Mart:** Un subconjunto del DW enfocado a un área específica (ej. Marketing, Ventas).

### 4.2.1. Características del DW
- **Orientado a negocio**: la información se clasifica en base a los aspectos que son de interés para la organización.
- **Integrado**: todos los datos de diversas fuentes son producidos por distintos departamentos.
- **Variante en el tiempo**: los datos son almacenados junto a sus respectivos históricos.
- **No volátil**.

### 4.2.2. Componentes del DW
1. **Load Manager:** Carga de datos (*ETL*).
2. **Data Warehouse Manager:** Almacena datos y metadatos.
3. **Query Manager:** Gestiona las consultas de usuario y operaciones (joins, agregaciones).

## 4.4. Modelo Dimensional
Diseño desnormalizado optimizado para consultas rápidas. Las dimensiones nos permiten contextualizar los hechos agregando diferentes perspectivas de análisis a ellos. Se compone de:
- **Tablas de Hechos (Facts):** Medidas numéricas (ventas, costes).
- **Tablas de Dimensiones:** Contexto (tiempo, producto, cliente).

## 4.5. OLAP (Online Analytical Processing)
Tecnología para análisis, administración y ejecución de consultas, que permiten inferir información del comportamiento del negocio. Permite "navegar" por los datos.
- **Cubo OLAP (Hipercubo):** representa o convierte los datos planos que se encuentran en filas y columnas, en una matriz de N dimensiones.
- **Operadores clave:**
    - **Drill-down:** Bajar al detalle (ej. de Año a Mes).
    - **Drill-up:** Subir a un nivel agregado (ej. de Tienda a Región).

>Diferencia Crítica OLAP vs Data Mining:
> - **OLAP:** Responde "¿Qué pasó?". Ej: Tasa de accidentes de fumadores vs no fumadores (agregación).
> - **Data Mining:** Responde "¿Por qué? / ¿Qué pasará?". Ej: ¿Cuáles son los mejores predictores de un accidente? (Patrones).

---

# 5. Herramientas
## 5.1. Tipos de herramientas
- **Genéricas**: provén funcionalidad para todas o casi todas las etapas y actividades de un proyecto BI.
- **Especializadas**: Data Warehouse / Data martes, herramientas específicas de ETL, consulta y generación de informes...

## 5.2. Herramientas Open Source
- **Soluciones completas**
	- Pentaho, JasperReports
- **Herramientas ETL**
	- Clover, Enhyda Octopus
- **Desarrollo OLAP**
	- Mondrian, JPivot

## 5.3. Herramientas propietarias
- IBM Cognos
- Microsoft Power BI
- Tableu
- SAP Business Intelligence