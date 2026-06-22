Los **sistemas transaccionales no están diseñados para responder a necesidades analíticas**, lo que ==genera un crecimiento exponencial de informes manuales==, muchas veces *inconsistentes entre sí*. 

Los **silos de información dificultan encontrar el dato apropiado**, lo que frena oportunidades de negocio y afecta el "time to market". Los ==primeros intentos de obtener datos para la toma de decisiones presentan problemas== de: 
- **Credibilidad**: *Diferentes tiempos de extracción, algoritmos de análisis*, niveles de extracción y ==falta de una fuente común==. 
- **Productividad**: *Dificultades para localizar y analizar datos*, escribir y probar programas, y ==conseguir recursos humanos para generar informes==. 
- **Información**: *Falta de integración y homogeneización de datos*, además de una insuficiente cantidad de datos históricos.

# 1. Business Intelligence (BI)
El BI agrupa **estrategias y tecnologías que usan las empresas para analizar datos históricos** y así obtener una *visión pasada, presente y futura del negocio*. Esto permite descubrir ==nuevas oportunidades y obtener una ventaja competitiva==.
* **Problemas que resuelve:** El BI nace para ==solucionar los problemas de los silos de información== (*datos aislados en diferentes departamentos*), que dificultan la toma de decisiones por ==falta de integración, credibilidad y datos históricos consistentes==.
* **BI Tradicional vs. Moderno:** El *BI tradicional* se centraba en ==describir tendencias pasadas== ("espejo retrovisor"). El *BI moderno* busca también ==predecir comportamientos futuros==.

---

# 2. Data Warehouse (DW)
Un **Data Warehouse es el núcleo del BI**. Es un *sistema centralizado* que **recopila, integra y administra datos** de diversas fuentes heterogéneas para que puedan ser ==conectados y analizados de forma significativa==.

> Los **datos pasan por procesos de formateo e importación antes** de almacenarse en el DW, lo que permite la toma de decisiones.

* **Características Principales:**
    * **Orientado al tema:** La información ==se organiza por temas de negocio== (ej. Ventas, Marketing), *no por procesos operativos*.
    * **Integrado:** Combina datos de múltiples fuentes ==en un formato homogéneo==.
    * **Historización:** ==Almacena datos a lo largo del tiempo==, permitiendo *analizar tendencias*.
    * **No volátil:** Una vez cargados, ==los datos no se modifican ni eliminan==, solo se añaden nuevos.
* **Modelado del DW: Hechos y Dimensiones**
    * **Tabla de Hechos:** Es la *tabla central y contiene las métricas numéricas* que se quieren analizar (ej. `cantidad_vendida`, `importe_total`). ==Representan los eventos de negocio==.
    * **Tablas de Dimensiones:** Rodean a la tabla de hechos y *proporcionan el contexto descriptivo* de los mismos (ej. `Tiempo`, `Producto`, `Cliente`). Permiten ==filtrar, agrupar y explorar los datos desde diferentes perspectivas== o visiones de negocio.

## 2.1. Tecnologías y Estructura del DW
* **OLTP (On-Line Transaction Processing):** Son los *sistemas que capturan y mantienen los datos del día a día* (ej. un sistema de ventas, un CRM). Suelen ser la ==fuente principal del DW==. Están ==optimizados para transacciones rápidas== (lecturas y escrituras).
* **OLAP (On-Line Analytical Processing):** Es el *enfoque analítico usado en los DW*. Permite ==realizar consultas complejas sobre grandes volúmenes de datos==. Está optimizado para ==lecturas y agregaciones masivas==.
    * **Comparación OLTP vs. OLAP**: `OLTP` maneja ==transacciones pequeñas en tiempo real==, mientras que `OLAP` procesa *grandes volúmenes de datos* con ==consultas complejas y análisis multidimensionales==.
    * **Diferencia clave OLAP vs. Data Mining:** `OLAP` *resume datos y permite hacer pronósticos*. `Data Mining` va un paso más allá y *descubre patrones ocultos y relaciones complejas* en los datos a un ==nivel detallado==.

### 2.1.1. Arquitecturas OLAP:
* **MOLAP (Multidimensional OLAP):** Utiliza ==bases de datos multidimensionales== especializadas con *cubos pre-calculados para una respuesta más rápida*, pero no tiene integración real en un único modelo ya que **crea silos**. 
* **ROLAP (Relational OLAP):** *Modela los "cubos" de datos* sobre ==bases de datos relacionales tradicionales==. Tiene tres posibles arquitecturas:
	* **Star Schema**: el mas común. *Tabla de hechos central rodeada de sus tablas de dimensiones*. Es simple y fácil de entender, pero son ==necesarias tantas estrellas como necesidades de analisis== -> se **mantienen los silos**.
	* **Snowflake Schema**: Una extensión del anterior donde *las tablas de dimensiones se normalizan en subdimensiones*, creando una estructura más compleja pero ==mejorando el almacenamiento y el rendimiento de consultas==. Los tiempos de respuesta inicialmente pueden no ser óptimos.
	* **Starflake Schema**: ==Combina Star y Snowflake para equilibrar simplicidad y eficiencia==. Cualquier cambio de un concepto en una dimensión fuerza a su regeneración integral (*por estar todo en una sola tabla*).
* **HOLAP (Hybrid OLAP):** *Mezcla* lo mejor de ROLAP y MOLAP.

## 2.2. Estructura de un Almacén de Datos
La estructura tradicional de *tres niveles*: 
1. **Nivel inferior**: *contiene el servidor de base de datos* que se utiliza para ==extraer datos de muchas fuentes diferentes==, así como las *bases de datos transaccionales* que se utilizan para ==aplicaciones de front-end==. 
2. **Nivel medio**: *alberga un servidor OLAP*, que ==transforma los datos en una estructura más adecuada para análisis== y consultas complejas. El servidor OLAP puede funcionar con `ROLAP` o `MOLAP`. 
3. **Nivel superior**: es la *capa del cliente* y contiene las ==herramientas utilizadas para el análisis de datos de alto nivel==, la consulta de informes y la minería de datos.

## 2.3. Tipos de almacenes de datos 
- **Enterprise Data Warehouse (EDW)**: ==Base de datos central para toda la empresa==. 
- **Operational Data Store (ODS)**: ==Almacena datos en tiempo real== y alimenta el EDW. Actúa como un *área de preparación para la integración de datos.* 
- **Data Mart**: *Subconjunto de un DW* enfocado en ==departamentos específicos==.

---

# 3. Data Lakes
Un Data Lake es un *repositorio centralizado* que almacena **cantidades masivas de datos en su formato nativo, sin procesar**. A diferencia de un DW, donde los datos se estructuran antes de cargarlos (`schema-on-write`), en un Data Lake la estructura se aplica al momento de la consulta (`schema-on-read`).
* **Características:**
    * Almacena ==datos estructurados, semi-estructurados y no estructurados== (JSON, logs, imágenes, vídeos).
    * ==Facilita el análisis de datos== de IoT y la *minería de datos*.
    * Es ==más flexible y económico== que un DW.

## 3.1. Desafíos: Los Pantanos de Datos (Data Swamps)
Un **Data Lake mal gestionado y sin gobierno** se puede convertir rápidamente en un "pantano de datos": un ==repositorio caótico donde nadie sabe de dónde vienen los datos, si son fiables o cómo se deben usar==.
* **Causas:**
    * *Contaminación:* La tentación de "==meter ahí cualquier cosa==".
    * *Podredumbre:* ==Datos que fueron útiles pero que han quedado olvidados== o ya no encajan en el negocio.
* **¿Cómo prevenirlo?**
    * Establecer *políticas claras de gobierno* y *limpieza de datos*.
    * Desarrollar una **política de documentación**. 
    * Crear un **Catálogo de Datos**:
		1. **Recogida** de *metadatos*. 
		2. Construcción de un **diccionario de datos** (alineado con el Business Glossary). 
		3. **Perfilar** los datos. 
		4. Marcar la **relación entre los datos**.
		5. ==Construcción== del **linaje**.
		6. **Organizar** los datos.
		7. Asegurar y **trazar el acceso**.

---

# 4. Comparativa: Data Warehouse vs. Data Lake

| Característica | Data Warehouse (DW) | Data Lake |
| :--- | :--- | :--- |
| **Datos** | Relacionales, estructurados y procesados. | Todo tipo de datos (estructurados, no estructurados) en formato crudo (raw). |
| **Esquema** | Esquema definido *antes* de la escritura (Schema-on-Write). | Esquema aplicado en el momento de la *lectura* (Schema-on-Read). |
| **Calidad** | Datos altamente curados y fiables. "La única fuente de la verdad". | Datos en bruto, cuya calidad puede variar. |
| **Usuarios** | Analistas de negocio. | Científicos de datos, desarrolladores. |
| **Analítica** | Informes, BI y visualizaciones. | Machine Learning, análisis predictivo y descubrimiento de perfiles. |