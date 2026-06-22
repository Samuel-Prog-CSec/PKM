# 1. Arquitectura de Datos Empresarial
Es una **disciplina fundamental para la gestión y representación de los datos de una organización**. Actúa como un ==puente entre la estrategia empresarial y la ejecución tecnológica==. Su objetivo es *conectar los objetivos de negocio con la tecnología*, estableciendo ==estándares para la recopilación, almacenamiento, uso y eliminación de datos==.
* **Actividades del Arquitecto/a de Datos:**
    1. **Evaluar el estado actual de los datos:** Detectar duplicados, inconsistencias, etc.
    2. **Definir un vocabulario de negocio estándar:** Asegurar que *todos usen los mismos términos* (ej. "cliente", "lead").
    3. **Alinear la arquitectura de datos con la estrategia empresarial:** Diseñar la *arquitectura para soportar objetivos* como la personalización en e-commerce.
    4. **Diseñar arquitecturas integradas:** Facilitar la *interoperabilidad entre sistemas* (ej. sistemas de salud).
    5. **Definir flujos de datos y su valor:** Entender *cómo se mueven los datos y qué aportan* (ej. sensores IoT para gestionar inventarios).
    6. **Determinar el linaje de datos:** Trazar el *origen y las transformaciones de los datos para garantizar su fiabilidad* (ej. en decisiones bancarias).

## 1.1. Tendencias en Arquitectura de Datos: Data Fabric vs. Data Mesh
Son dos *enfoques modernos* para ==organizar los ecosistemas de datos==. No son opuestos, sino que **pueden ser complementarios**.
* **Data Fabric:** Es un enfoque que busca **unificar y automatizar** la *integración*, la *ingeniería* y el *gobierno de datos*, a menudo usando `IA` y `machine learning`. El objetivo es ==crear una capa de acceso a los datos unificada, sin importar dónde residan==.
    * *¿Cuándo usarlo?* Si la **empresa tiene muchas fuentes de datos dispersas y quiere integrarlas** *sin alterar los sistemas existentes.* Necesita automatización para catalogar y acceder a los datos de forma unificada.
* **Data Mesh:** Es un *enfoque organizativo y arquitectónico* **descentralizado**. Trata los datos como un **producto**, donde ==cada "dominio" de negocio== (marketing, ventas...) ==es dueño de sus propios datos==, los gestiona y los ofrece a través de APIs a otros equipos.
    * *¿Cuándo usarlo?* Si la **empresa tiene múltiples equipos con autonomía, se busca empoderarlos** para que creen y consuman sus propios productos de datos y la cultura organizacional soporta un gobierno federado.

---

# 2. Metadatos: Los "Datos sobre los Datos"
Los metadatos son **información** que ==describe, explica, localiza o facilita la gestión y el uso== de los datos. 

> **No están ocultos** y no tienen por qué estar contenidos dentro de otros.

Son *esenciales*: ==sin metadatos fiables, una organización no sabe qué datos tiene==, qué significan o cómo se mueven.
* **Tipos de Metadatos:**
    * *De negocio:* Definiciones, ==reglas, lógica de negocio==.
    * *Técnicos:* Detalles del ==almacenamiento, formato==, esquemas de tablas.
    * *Operacionales:* ==Información sobre el procesamiento==, accesibilidad, frecuencia de actualización.
    * *Descriptivos:* ==Título, autor, tema== para identificar un recurso.
    * *Estructurales:* ==Relaciones== entre los datos.
    * *Administrativos:* ==Fechas de creación, versiones==, permisos de acceso.
* **Artefactos para la gestión de metadatos:**
    * *Glosario de Negocio (Business Glossary):* Documenta y define la **terminología comercial de la empresa.** La responsabilidad del glosario empresarial recae en la empresa
    * *Catálogo de Datos (Data Catalog o Data Marketplace):*  activo de toda la empresa que proporciona una **única fuente de referencia para la localización de cualquier conjunto de datos** necesarios para diversas necesidades. Proporciona el ==mapeo entre el glosario de negocios y los diccionarios de datos==.
    * *Diccionario de Datos (Data Dictionary):* Contiene las ==descripciones técnicas y detalladas de los datos== (nombres de columnas, tipos de datos, restricciones) que están ligados a los metadatos. Ayudan a entender ==cómo unir, consultar y reportar los datos==.
* **Linaje de datos (Data Lineage):** Permite *rastrear el origen, las transformaciones y el movimiento* de los datos a través de los sistemas. Su alcance define cuántos metadatos se necesitan para documentarlo. Es como una "pista de auditoría" que ==aumenta el valor y la confianza en los datos==.

---

# 3. Modelado de datos
Es el **proceso de crear una representación visual de un sistema de información y sus datos**.
* **Tres niveles del modelo:**
    1. *Conceptual:* Visión de **alto nivel**. Define las ==entidades y sus relaciones sin detalles técnicos==. Es clave para *validar los requisitos del negocio*.
    2. *Lógico:* Más **detallado**. Define ==atributos, claves primarias y foráneas, y las relaciones entre entidades==.
    3. *Físico:* Representación de **cómo se implementará el modelo** en una base de datos específica. Define ==tipos de datos, índices y optimizaciones==.
* **Enfoques de modelado:**
    * *Modelado prescriptivo:* Se define el esquema *antes* ==de almacenar los datos== (típico en bases de datos relacionales).
    * *Modelado descriptivo:* El esquema se genera *dinámicamente* ==al consultar los datos== (típico en NoSQL, **es más ágil**).

---

# 4. Modelado de Bases de Datos Relacionales (SQL)
Se basa en el **modelo entidad-relación**. Los ==datos se organizan en tablas== (*relaciones*) que ==contienen filas== (*tuplas*) y ==columnas== (*atributos*).
*   **Conceptos Clave:**
    * *Entidad:* Representa un ==objeto del mundo real== (ej. Cliente, Producto).
    * *Dominio:* Define los ==posibles valores que puede tomar un atributo== (ej. un tipo de dato como `INTEGER`, una lista de valores `('Hombre', 'Mujer')`).
    * *Clave:* Un atributo o conjunto de ellos que ==identifica de forma única a cada fila de una tabla==.
        * `Clave Primaria`: ==No puede ser nula== (**Integridad de entidad**).
        * `Clave Foránea`: Debe ==coincidir con una clave primaria existente en otra tabla o ser nula== (**Integridad referencial**).

---

# 5. Datos Maestros y de Referencia
* **Datos Maestros (Master Data):** Es la *información central y crítica de una organización*, compartida por múltiples sistemas. Son los ==datos esenciales sobre las entidades de negocio== (Clientes, Productos, Empleados, etc.).
    * La **Gestión de Datos Maestros (MDM)** es la ==disciplina== que garantiza la *consistencia, precisión y disponibilidad* de estos datos.
* **Datos de Referencia:** Son un *tipo de dato maestro* que se utiliza ==para clasificar o categorizar otros datos==. Suelen ser tablas de códigos, jerarquías o clasificaciones.
    * *Ejemplos:* listas de países, códigos postales, tipos de productos, clasificaciones geográficas.