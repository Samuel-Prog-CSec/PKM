# Evolución de los SI en las empresas
La ==implementación de tecnología sin una adecuada alineación con la estrategia organizativa== puede llevar al **desperdicio de recursos y oportunidades**. De ahí surge la *necesidad de alinear la estrategia de negocio con las TI*.

# Concepto de arquitectura y su aplicación en TI
**Arquitectura (ISO 42010):** **conceptos o propiedades fundamentales de un sistema**, incluyendo sus ==elementos, relaciones entre ellos y principios de diseño y evolución==. Una arquitectura ofrece una *visión integrada de un sistema*. En las TI, la arquitectura se refiere a la estructura física y la lógica.

## Definición de arquitectura empresarial AE
La AE es un **conjunto coherente de principios, métodos y modelos que se utilizan para diseñar y estructurar** los ==elementos organizativos, procesos de negocio, localizaciones, datos, aplicaciones e infraestructura tecnológica de una empresa==. Su objetivo principal es el **alineamiento de las TI con la estrategia de la organización**.

Una arquitectura empresarial de calidad **ayuda a lograr los objetivos del negocio mediante la toma de decisiones fundamentadas en los `SI` y `TI`**. Ofrece una *visión a largo plazo*, para ==ejecutar proyectos con una visión más amplia y no solo pensando en las necesidades inmediatas==. 

Marca la ==separación entre lo que no se puede modificar== (*elementos esenciales*) y ==lo que puede cambiarse con más flexibilidad== en una empresa en función de las necesidades.

## Beneficios de la AE
Los **principales beneficios** de implementar una arquitectura empresarial son:
- **Alineamiento de la estrategia del negocio con las TI** para cumplir los objetivos.
- **Integración** de todos los *componentes de la organización*.
- **Flexibilidad y adaptabilidad** a posibles ==cambios==.
- **Eficiencia y optimización**: ==reutilización de recursos==, *reducción de costes*, interoperabilidad y ==compatibilidad entre procesos y sistemas==.
- **Mínima complejidad y máximo aprovechamiento** de la infraestructura de la organización.
- **Trazabilidad** entre ==procesos, datos, aplicaciones e infraestructura==, generando un *modelo coherente, fiable y útil* para la gestión y administración.
- Uso de **modelos y lenguajes estandarizados** que ==facilitan la comunicación==.

## Visión y comunicación
La arquitectura empresarial proporciona una **visión holística de la empresa**, entendiendo que *el todo es más importante* que las partes por separado. Esta visión debe ser ==comprendida y compartida por todos los interesados== (*stakeholders*), quienes ==no necesariamente se preocupan por la arquitectura en sí==, sino por los resultados que esta ofrece en relación a sus intereses.

## Marcos de referencia o Frameworks
**Técnicas estructuradas de descripción de arquitecturas** basadas en la ==identificación y relación de los diferentes aspectos de una arquitectura== y los *métodos de modelado* asociados. Por ejemplo: `Zachman`, `TOGAF`.

## Metodologías de desarrollo
**Pasos a seguir** para el ==modelado de arquitecturas==. Por ejemplo, `metodologías ágiles`, `ADM`.

## Lenguajes de descripción de arquitecturas
**Lenguajes** para ==modelado de los diferentes dominios que componen una arquitectura==. Por ejemplo: `UML`, `BPMN`, `ArchiMate`, ...

---

# Dominios de la arquitectura empresarial
La AE se compone de **cuatro dominios principales**, cada uno con *sus propios objetivos y elementos*:
1. **Arquitectura de negocio:** ==define el modelo operativo, estrategias y objetivos empresariales==, alineándolos con las TI. ==Intereses de los usuarios del sistema== y flujo de información entre ellos.
    - *Estrategia de negocio*: **objetivos**, modelo de negocio operativo.
    - *Estructura organizativa:* **roles**, toma de decisiones, presupuesto interno.
    - *Procesos clave*: **servicios**, capacidades afectadas por la AE.
2. **Arquitectura de información:** describe la ==estructura física y lógica de la información y sus modelos de gestión== e intercambio en la organización.
    - *Estrategia de información*: **gobernanza de información**, requisitos, **modelos de datos y soporte**, seguridad, intercambio e interoperabilidad.
    - *Activos de información*: **tipos y modelos de datos críticos** para la organización y sus relaciones con servicios y procesos.
3. **Arquitectura de aplicaciones:** detalla la ==funcionalidad de los SI, sus interacciones y sus relaciones== con los procesos.
    -   *Estrategia de aplicaciones*: "`In house`" vs `Comprados`, "`Hosted`" vs `Interno`.
    -   *Inventario de servicios de aplicación*.
    -   *Aplicaciones específicas para procesos de negocio*.
    -   *Componentes lógicos*: **aplicaciones importantes** para los objetivos.
    -   *Componentes físicos*: **soporte para las aplicaciones relevantes** y relación con los servicios relevantes de información de la AE.
4. **Arquitectura de tecnología:** se centra en la ==infraestructura técnica== (*hardware, software, comunicaciones*) necesaria para soportar las aplicaciones y el flujo de información.
    - *Estrategia tecnológica*: **gobernanza de activos tecnológicos**, estándares y **soluciones tecnológicas** específicas.
    - *Inventario de servicios tecnológicos*: relación con los servicios de negocio, aplicaciones e información.
    - *Hardware, software y comunicaciones*.

## Personas
**Equipos o individuos con responsabilidades** en cualquier nivel de arquitectura empresarial: ==desarrollo, mantenimiento, implementación y gobernabilidad==.

## Procesos
**Actividades** que *garantizan el funcionamiento de la AE* maximizando posibilidades de éxito y minimizando costes.

## Herramientas
**Tecnologías** para el ==desarrollo y administración de la AE==.

## Portafolio de proyectos
Grupo de **programas y proyectos independientes y no necesariamente relacionados** destinados a ==cumplir los objetivos estratégicos== de la organización. Se priorizan, seleccionan e implementan en función de las necesidades. 

Dentro de un portafolio: ==estructuras de sub-portafolios, programas, proyectos y otros trabajos operativos.==

## Gobierno de implementación
**Estructura y procesos para implementar la estrategia de negocio** de la organización *a través de la AE*. ==Guía los proyectos y garantiza su alineación con la AE==. Gestiona personas, procesos, políticas, tecnología y finanzas.

> 🔔
> **Otra definición de AE:** **metodología de mejora continua** basada en una ==visión integral de la organización==, y que permite mantener actualizada la estructura de información organizacional *alineando negocios, información, aplicaciones y tecnología*.

---
# Proceso de desarrollo de la AE
## Integración de los dominios
La creación de una arquitectura empresarial consiste en la **relación e integración de los cuatro dominios principales**. Estas relaciones se establecen de *forma gradual*, obteniéndose diferentes ==niveles de madurez de la arquitectura empresarial==.

## Niveles de madurez de la arquitectura empresarial
1. **Nivel 0 - No existe arquitectura:** la empresa opera sin AE, y ==no hay conexión entre departamentos ni objetivos claros==.
2. **Nivel 1 - Nivel inicial:** se definen *conceptos básicos y estándares iniciales*, la AE está poco integrada en la empresa.
3. **Nivel 2 - En desarrollo:** ==integración entre principios de la AE, la estrategia de negocio y las TI==, hay más participación de los especialistas, se definen algunos entregables del modelo de AE y la *comunicación entre las partes es incompleta*.
4. **Nivel 3 - Arquitectura implementada:** la ==AE está plenamente desarrollada==, soportando la *integración de procesos con estándares*, reconociendo los beneficios, aparecen *estrategias de adquisición de SI y TI*.
5. **Nivel 4 (Y) - Integración consolidada:** la ==AE es administrada y revisada periódicamente==, y se encuentra *consolidada en la estrategia de negocio*.
6. **Nivel 5 - Arquitectura optimizada:** todos los procesos y decisiones TI están completamente integrados con la estrategia empresarial, facilitando la *adaptación y optimización continua*. Las ==inversiones en SI y TI se ven como una parte más del conjunto de la empresa.==

# Proceso de actualización de la AE
La AE **no es estática**, debe actualizarse regularmente para ==adaptarse a los cambios en el entorno y a las necesidades de la empresa==. Este proceso de actualización se lleva a cabo a través de una **Hoja de Ruta**, que es un *plan estratégico que detalla los procesos necesarios* para alcanzar una nueva versión de la AE.

## Las fases de una hoja de ruta incluyen:
-   **AE futura deseada (TO BE):** definición de los ==objetivos a alcanzar==.
-   **Estado actual (AS IS):** ==análisis de la situación== y recursos actuales.
-   **Análisis de diferencias:** identificación de los ==cambios necesarios==.
-   **Priorización:** determinación de ==qué cambios son más urgentes==.
-   **Plan de ejecución:** ==implementación de los cambios== priorizados.
-   **Ejecución:** ==nueva AE==.
-   **Revisión:** ==evaluación de la efectividad== de la nueva AE.

---

# Principios de la arquitectura empresarial
Los principios son **reglas y directrices generales que orientan la forma en que la organización usa su arquitectura** para cumplir los objetivos. Existen distintos *tipos de principios*:
- **Principios empresariales:** ==guían la toma de decisiones en toda la empresa== y determina la forma de cumplir los objetivos.
- **Principios de arquitectura:** ==gobiernan el proceso de arquitectura== y afectan al *desarrollo, mantenimiento y uso en el ámbito TI* y decisiones asociadas.

Es útil utilizar una ==forma estándar para el establecimiento de los principios de arquitectura==. Además de una **declaración de definición**, cada principio debe tener **declaraciones de fundamentos e implicaciones asociadas**:
- *Promueve la comprensión y aceptación* de los principios.
- Apoya el uso de principios para *justificar por qué se toman decisiones* específicas.

## Componentes de los principios de arquitectura
- **Nombre:** debe capturar la *esencia del principio*, ser fácil de recordar y ==evitar nombres de tecnologías y palabras ambiguas== como "apoyar", "considerar" o "evitar".
- **Declaración:** expresa el *principio de manera breve y clara*. Los principios de gestión de información suelen ser similares entre organizaciones.
- **Razonamiento o justificación:** destaca los *beneficios de seguir el principio*, muestra su ==relación con otros principios empresariales y de TI== y explica ==cuándo puede ser prioritario en la toma de decisiones==.
- **Implicaciones:** describe los *requisitos para implementar el principio y sus efectos* en la empresa, sin simplificar ni juzgar el impacto. Expone ==posibles conflictos con sistemas o prácticas actuales tras su adopción==.

## Influencias sobre los principios
Los principios de arquitectura de una empresa están influenciados por diversos factores internos y externos que permiten alinearlos con su estrategia y entorno.

La **misión, los planes y la infraestructura organizativa de la empresa actúan como guía en su definición**. También influyen las *iniciativas estratégicas*, sus características y los procesos internos actuales, que reflejan tanto las fortalezas y debilidades como las áreas de mejora de la organización.

Factores externos como las **condiciones del mercado** y la **legislación existente o potencial** deben ser considerados, ya que afectan directamente a la viabilidad y aplicabilidad de los principios. Además, los **sistemas y tecnologías que la empresa tiene en funcionamiento**, junto con la documentación, inventario de equipos, configuración de red, políticas y procedimientos, son elementos clave en su desarrollo.

Finalmente, las ==predicciones sobre el entorno económico, político, técnico y de mercado ayudan a anticipar ajustes necesarios==, garantizando que los principios se mantengan relevantes y efectivos en un contexto en constante cambio.

## Calidad de los principios
Tener una declaración escrita de un principio y que la gente esté de acuerdo con él no significa que el principio sea bueno. **Un buen conjunto de principios debe basarse en las creencias y valores de la organización** y ==expresarse en un lenguaje que la empresa entienda y utilice==. Los principios deben ser *pocos*, estar *orientados a futuro* y ser respaldados y *defendidos por la alta dirección*. Un conjunto de principios deficiente caerá en desuso, las normas y políticas resultantes parecerán arbitrarias y perderán credibilidad.

>"LOS PRINCIPIOS IMPULSAN EL COMPORTAMIENTO"

### Criterios de calidad de los principios
- **Comprensibles:** rápidamente comprendidos y con intención clara e inequívoca.
- **Sólidos:** suficientemente definitivos y precisos como para apoyar la toma de decisiones de calidad de forma coherente en situaciones complejas.
- **Completos:** cubren todas las situaciones percibidas y potencialmente importantes para la organización.
- **Coherentes:** no deben ser contradictorios, se deben interpretar con flexibilidad, la interpretación estricta de uno puede requerir una interpretación poco estricta de otro.
- **Estables:** duraderos pero capaces de adaptarse a cambios mediante procesos de enmienda y actualización de los principios iniciales.