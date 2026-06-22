**Operaciones:** ==mantienen un sistema funcionando según los parámetros establecidos==, no desarrollan funcionalidades nuevas pero las nuevas funcionalidades suelen tener impacto operativo. Son **sistemáticas y orientadas a interrupciones** (*interrupt* - *driven*).
* **Ciclo continuo:** ==desarrollo y operaciones están interconectados==, puede generar confusión en sus roles.
* **Acuerdo a nivel de servicio (SLA):** **contrato entre proveedor y consumidor** que ==define disponibilidad, tiempos de respuesta y recuperación==. Guían las prioridades operativas y definen *penalizaciones por incumplimiento*.

# Monitorización
**Observar información sobre el estado de los elementos** para utilizarla en la toma de ==decisiones a corto y largo plazo==.
* **Técnicas:**
    *   **Monitorización simple:** observa la ==infraestructura informática básica==.
    *   **Monitorización extensa:** analiza ==procesos, métricas y eventos complejos==.
    *   **Basada en usuario:** ==simula la experiencia final== para validar SLAs.
* **Herramientas:** gestionan *estado, rendimiento y dependencias*.
* **Gestores de elementos:** herramientas que ==gestionan infraestructuras TI o digitales==, pueden cambiar su configuración e informar sobre su estado.

Las herramientas de monitoreo **ofrecen visibilidad continua del rendimiento del sistema** pero los *productos* deben ==proporcionar su propia telemetría personalizada==.
	↳ Utiliza **sensores** para medir y transmitir datos.

## Agregadores de monitorización
Proveen una **visión integrada del sistema**, centrándose en eventos de estado o rendimiento. Ayudan a ==simplificar la complejidad del entorno TI==.

# Gestión de la capacidad
**Garantizar que todos los recursos soporten la demanda**, evaluando datos históricos para predecir futuras necesidades.
	↳ Mide cuánto puede conseguir, producir o vender en un periodo de tiempo.

# Gestión de rendimiento
Se centra en la **capacidad de respuesta, optimiza la velocidad y eficiencia** del sistema detectando ==problemas antes de que impacten==.

---

# Respuesta operacional
## Canales de comunicación
Los componentes digitales envían eventos que son procesados por herramientas de monitores, que **generan alertas** (para los operadores del sistema) ==o tickets para gestionar problemas==.

La gestión estructurada de incidentes ==asegura una atención rápida y precisa==.

## ChatOps
**Integra comunicación y operación en tiempo real con bots** y comandos automatizados, fomentando colaboración y auditoría.

## Emergencia del proceso operativo
### 1.- Dos roles
**Oncall:** ==personal de guardia== para emergencias.
**Onduty:** ==personal de servicio== para incidentes *no críticos*.

### 2.- Preocupación por la previsibilidad.

### 3.- Procesos operativos
- **Gestión de solicitudes:** responder a ==peticiones rutinarias.==
- **Gestión de incidentes:** restablecer servicios ==afectados por interrupciones==.
- **Gestión de problemas:** identificar ==causas de incidentes y mitigarlas==.
- **Gestión de cambios:** ==documentar y evaluar modificaciones== en sistemas críticos.

## Análisis post-mortems (causa-raíz)
**Revisar incidentes tras su resolución** para entender las causas y ==evitar que vuelva a ocurrir==.

## Nueva visión del error humano
**Los errores no son la causa**, sino un síntoma de problemas más profundos en sistemas y entornos. ==Fomentar una cultura sin culpabilización mejora la seguridad operativa==.

# Diseño de operaciones para su escalabilidad
La **escalabilidad no ocurre por accidente**, requiere enfocarse en cómo funciona el sistema bajo una carga real.

==Insistir en escalabilidad avanzada sin un producto validado puede ser un desperdicio==.
Generalmente, tras varios prototipos y aumento de uso, se optimiza para escalar.
* **Principio CAP:** un sistema distribuido ==no puede garantizar a la vez consistencia, disponibilidad y tolerancia a particiones==; **deben priorizarse** según el caso de uso.
    * **Diagrama CAP**
        * *CA*: Consistency, Availability
        * *CP*: Consistency, Partition Tolerance
        * *AP*: Availability, Partition Tolerance
*   **Cubo AFK:**
    * **Replicación (eje x):** ==clonar sistemas== para manejar más tráfico. (Horizontal duplication)
    * **Separación funcional (eje y):** dividir en ==servicios especializados==. (Functional partitioning)
    * **Segmentación geográfica (eje z):** dividir ==datos por regiones==. (Data partitioning)