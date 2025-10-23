# Alineamiento TI/Negocio
Es el proceso de **sincronizar tecnologías de información con los objetivos estratégicos y operativos del negocio** para:
-   ==Mejorar== la *eficiencia* y *competitividad*.
-   ==Facilitar la innovación== de productos y servicios.
-   ==Garantizar el cumplimiento== de los *objetivos empresariales*.

> ⚠️
> **IMPORTANTE:** el ==alineamiento perfecto no existe==, pero es posible **optimizarlo** como un proceso de *regulación continua*.

# Marco de alineamiento GRAAL (Guidelines Regarding Architecture Alignment)
Es un **marco conceptual para describir el fenómeno del alineamiento**, estructurado en ==4 dimensiones==:
1. **Aspecto de sistemas:**
    - **Servicios ofrecidos al entorno:**
        - *Comportamiento*
        - *Comunicación*
        - *Semántica*
    - **Calidad:** ==valor que ofrecen los servicios== a los stakeholders.
        - Para el *usuario* (usabilidad...)
        - Para el *desarrollador* (mantenibilidad...)
2. **Agregación de sistemas:** ==relación entre mundos físico, simbólico y social== (los mundos o jerarquías son independientes).
3. **Procesos de sistemas:** ==coordinación de versiones y ciclos de vida== de los sistemas TI.
4. **Niveles de descripción:** ==clasifica el nivel de detalle== con el que se describe un sistema.

# Capa de aprovisionamiento de servicios 
Organización de la **arquitectura en capas**
- **Capas inferiores:** forman ==plataformas de soporte== para las superiores.
- **Capas superiores:** se ==adaptan a las necesidades== del negocio.
- **Relaciones entre capas:**
	- *Primaria:* un sistema provee un ==servicio a cualquier capa superior==.
	- *Secundaria:* ==servicios de gestión== entre capas.

# Arquitectura de infraestructura
La **infraestructura TI debe estar disponible y ser escalable según las necesidades** del negocio.

Cambios lentos en servicios de un componente de infraestructura ↔ Mayor conjunto de usuarios.

>👉 La **nueva tecnología se añade a la vieja**, ==nunca llega a sustituirla completamente==.

---
# Arquitectura de sistemas de negocio
Sistemas diseñados para ==soportar algunos procesos de negocio específicos==.
- **Sistemas de información:** ==almacenan== datos.
    -   Agrupados en *áreas temáticas*.
- **Aplicaciones:** ==usan== datos.
    -   Agrupadas en *áreas de aplicación*.
- **Mapas de entorno:** ==representan comunicación== entre sistemas.
    - **Diagramas de comunicación:** los *sistemas se comunican a través de aplicaciones*.

> **Mayor cantidad de procesos soportados** → *Mayor complejidad* y *menos manejable*.

- **Desalineamiento estratégico entre infraestructura y sistemas de negocio** por ==desfases en sus ciclos de actualización==.

# Ley de Conway
> 👨‍⚖️
> La ==estructura de un sistema diseñado== debe ser **isomorfa** ==a la estructura de comunicación del sistema diseñador==.

Cualquier *cambio en la arquitectura de infraestructura debe ir acompañado de un cambio en la estructura de gestión de infraestructura*. Esto implica el ==alineamiento entre equipos de diseño y procesos de negocio== para evitar descoordinación.

# Proceso de arquitectura
El alineamiento TI/Negocio no solo implica conectar sistemas, sino **gestionar y desarrollar procesos de manera eficiente**. Para lograrlo, se necesitan ==modelos más simples y flexibles que permitan controlar sistemas sin la complejidad innecesaria== de métodos tradicionales, adaptándose mejor al entorno empresarial actual.

# Gobernanza TI
Actividad que **regula la adquisición, cambio, eliminación y monitorización de las TI** en una organización.
- **Equilibrio** entre ==criterios globales== (reducción de costes, reutilización) ==y locales== (requisitos específicos de proyectos).
- **Desafíos** en la *coordinación* entre ==arquitectos de sistemas y responsables de proyectos==.