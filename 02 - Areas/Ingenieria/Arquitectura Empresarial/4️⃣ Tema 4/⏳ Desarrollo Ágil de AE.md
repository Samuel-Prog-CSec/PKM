# ¿Qué es la agilidad empresarial?
Aunque no existe una definición exacta, la **agilidad empresarial** es la capacidad de una organización para ==adaptarse rápidamente a los cambios del mercado y responder a las demandas de los clientes con flexibilidad==, manteniendo una *ventaja competitiva* en un entorno dinámico. Habilita a la empresa a **reaccionar mejor a los cambios y ser más eficiente**, con un pensamiento centrado en el producto y el cliente.

El término `Ágil` (*Agile*) se asocia al **Proceso de Desarrollo de Software Ágil**. Sin embargo, la agilidad empresarial es un contexto más amplio que incluye los principios y técnicas de Agile, además de otras técnicas.

# Características de la agilidad empresarial
* **Respuesta a cambios:** *flexibilidad y anticipación*, re-priorizando actividades.
* **División del trabajo complejo:** se divide el trabajo en ==subtareas sencillas== con *iteraciones cortas*.
* **Impulsada por el valor:** se da ==prioridad a la entrega de elementos de alto valor==, minimizando el trabajo en tareas intermedias y documentación.
* **Experimentación práctica:** fomenta el principio de "**equivócate rápido**", *aprendiendo de la experiencia* en lugar de depender únicamente de análisis teóricos.
* **Equipos autónomos:** *equipos multidisciplinares* responsables de sus propias decisiones.
* **Colaboración y comunicación:** ==contacto continuo con el cliente== para adaptar el producto a sus necesidades.
* **Mejora continua:** se busca constantemente ==mejorar el funcionamiento de la empresa==.
* **Respeto a las personas:** se ==prioriza a las personas sobre los procesos y herramientas==, fomentando la *flexibilidad*, la *transferencia de conocimiento* y el *desarrollo personal*.

## Relación con TOGAF ADM
El **ADM** (*Architecture Development Method*) de `TOGAF` es en sí mismo una ==metodología que puede ser considerada ágil para el desarrollo de AE== por sus características:
-   Método **iterativo**
-   Fomenta la **mejora continua**
-   **Trabajo dividido** en distintas fases
-   **Incrementa** el *valor en cada iteración*
-   Fomenta el contacto entre *stakeholders*
-   Es **adaptable** a cambios

---

# Desarrollo Ágil y niveles de detalle
El desarrollo ágil implica la **partición del trabajo de arquitectura en múltiples tareas**, considerando las siguientes ==dimensiones en cada iteración==:
* **Extensión (Breadth):** el *alcance completo de la empresa* y hasta qué grado debe llegar la arquitectura.
* **Profundidad (Depth):** el *nivel de detalle* de la arquitectura.
* **Tiempo (Time):** el periodo de tiempo que contempla la *visión de la arquitectura*.

## Niveles de detalle en arquitectura Ágil
Los ==cuatro dominios de la arquitectura== (`Negocio`, `Datos`, `Aplicaciones`, `Tecnología`) están *presentes en todas estas dimensiones*.
1.  **Arquitectura estratégica de la empresa:**
    * Proporciona una ==vista a alto nivel del área de la empresa a la que afecta el cambio== (corresponde a la Fase A del ADM).
    * Permite la **comprensión de la dirección estratégica** y establece el *contexto para los segmentos y capacidades* implicados.
    * Es necesario ==planificarla para evitar consecuencias imprevistas==, pero no es estática; **evoluciona** junto con la estrategia de la empresa.
2.  **Arquitectura de segmento:**
    * Define la ==especificación de un producto o solución de negocio== basándose en la estrategia.
    * Se desarrolla la "**arquitectura justa**" para *identificar las características principales*, usando solo las fases de ADM que sean necesarias.
    * Las ==iteraciones se realizan de forma concurrente== por distintos equipos de trabajo ágil, quienes definen conjuntamente estas arquitecturas para mejorar la colaboración.
3.  **Arquitectura de capacidad:**
    * Ofrece **descripciones detalladas de *(incrementos de)* capacidades de negocio**.
    * Detalla la `Arquitectura de segmento` a un nivel suficiente para que los ==equipos de implementación puedan usarla directamente==.
    * Puede alinearse con los *sprints* de entrega. A veces, un incremento de capacidad requiere varios *sprints*.

---

# Necesidad de agilidad y estilos de entrega
## Relación con la necesidad de agilidad
La tendencia en entornos ágiles es *minimizar el tamaño y tiempo de los segmentos e incrementos*. Sin embargo, un desarrollo deficiente de la `Arquitectura Estratégica y de Segmento` ==puede llevar a fallos por consecuencias inesperadas==.

`TOGAF` reconoce la ==necesidad de dividir la arquitectura en partes más pequeñas== (segmentos y capacidades) que *cubren un área específica y se pueden implementar fácilmente* con técnicas ágiles. La **Arquitectura Mínima Viable (AMV)** es clave aquí, asegurando el ==equilibrio entre dar suficientes detalles para mantener la alineación y explorar demasiados detalles== antes de tiempo.

### Pasos a seguir
1. **Identificar segmentos** para *cubrir una necesidad concreta*, en línea con la `Arquitectura Estratégica`.
2. **Refinar los segmentos** con las `Arquitecturas de Capacidad`, modeladas con métodos ágiles.
3. **Entregar** las `Arquitecturas de Capacidad` en incrementos y **usarlas de forma iterativa** para construir la *salida final* (producto, servicio o solución).

> 📝
> Las fases de `TOGAF` **no necesitan ejecutarse en orden estricto**. Las actividades de un nivel pueden comenzar en cuanto se definan las áreas relevantes del nivel superior, permitiendo *trabajar en paralelo*.

## Estilos de entrega
La agilidad no consiste solo en usar *sprints*. Se debe buscar un equilibrio de métodos según las necesidades. Existen **tres estilos de entrega** para controlar el proceso de cambio:

* **Rápido:** ==implementaciones inmediatas== de *componentes sencillos*.
* **Ágil:** ==ciclos rápidos de entrega de componentes== con una funcionalidad específica y acotada. Corresponde a la mayoría de los *sprints*.
* **Robusto:** ==entrega a largo plazo de componentes complejos y a gran escala==. Implica un **riesgo más alto y requiere interoperabilidad** a lo largo de un segmento completo o incluso de toda la empresa.

>🤝
> Normalmente, una secuencia de *sprints* presenta una **combinación anidada de estos tres estilos**, según la complejidad del cambio.

---

# Arquitectura Ágil y desarrollo de producto (TOGAF ADM)
En un entorno ágil, el desarrollo es un proceso continuamente controlado con tareas en paralelo. No es necesario completar una fase para empezar la siguiente, solo se requieren los **elementos mínimos necesarios**.

## Aplicación ágil en las fases de ADM
*   **Define Problem (Fase A):**
    * Entender los objetivos estratégicos mínimos.
    * Desarrollar una Arquitectura Estratégica a alto nivel y rápida, con los detalles justos para definir una **Arquitectura Suficiente (Producto Mínimo Viable)** y programar las siguientes actividades.
*   **Define Baseline (Fases B, C, D):**
    * El desarrollo sin un claro entendimiento de la base supone un alto riesgo.
    * La clave es definir la **Arquitectura Mínima Viable** de la base (cubriendo prioridades principales) para gestionar riesgos.
*   **Define Target (Fases B, C, D, E, F):**
    * Focalizar en el **Producto Mínimo Viable** y la **Arquitectura Mínima Viable** objetivo.
    * Segmentar el problema (en Segmentos y Capacidades) para definir la arquitectura objetivo de forma progresiva, añadiendo detalles solo cuando son necesarios.
*   **Deploy Target (Fases F, G):**
    * Asegurar que las personas tienen los conocimientos necesarios.
    * Garantizar un *feedback*, colaboración y gobernanza adecuados para entregar valor.
*   **Govern and Manage Change (Fase H):**
    * La gobernanza debe integrarse con los *sprints* (mediante retrospectivas, planificación, análisis de impacto, etc.) para asegurar que se está aportando valor de negocio.

## Arquitecturas de transición
Son definiciones del estado de la arquitectura en un momento concreto, alineadas con los objetivos de negocio. Se logran mediante la colaboración continua entre arquitectos y expertos de negocio.
* Cada transición **incrementa el valor de negocio**, entregando valor a los *stakeholders*.
* Se basan en una hoja de ruta que asegura la estabilidad del sistema una vez implementado.

> 👍
> En resumen, en entornos ágiles la **prioridad es el resultado** y la arquitectura es el vehículo para la entrega de un producto de valor.