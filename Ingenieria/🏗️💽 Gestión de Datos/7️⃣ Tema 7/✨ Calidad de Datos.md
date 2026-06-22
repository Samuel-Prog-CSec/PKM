# 1. Introducción a la calidad de datos
La calidad de los datos es fundamental en la gestión de la información, ya que **influye directamente en la toma de decisiones y en el correcto funcionamiento** de los sistemas. Datos de baja calidad pueden llevar a conclusiones erróneas y a pérdidas económicas.

*Definiciones* de calidad: 
- **Fitness for use**: ==Adecuación== (del producto) al uso.
- **Deming**: ==Conformidad con requisitos y confiabilidad== en el funcionamiento. 
- **Meeting Requirements**: ==Cero defectos== (*Crosby*). 
- **Taguchi**: *Pérdida económica* que un ==producto supone para la sociedad== desde el momento de su expedición. 
- **ISO 9000**: *Grado* en el que un conjunto de ==características inherentes cumple con los requisitos==.

> 🔬
> La calidad de datos es el conjunto de *procesos, técnicas y algoritmos* para conseguir que los datos sean **útiles para el fin que se les quiera dar en el negocio**. Esto implica que los datos deben ser exactos, completos, consistentes, creíbles y cumplir con las normativas.

---

# 2. Programa de gestión de la calidad
La gestión de la calidad es un **programa continuo** dentro de la organización, no un proyecto con inicio y fin. Su *objetivo es asegurar y controlar los datos para evitar problemas*, siendo siempre ==mejor prevenir que curar==.
* **Operaciones clave:**
    * *Medición:* Acciones para ==obtener medidas de la "cantidad" de calidad==.
    * *Evaluación:* Juicio para ==determinar si el nivel de calidad es adecuado==.
    * *Control y Mejora:* Acciones para que los ==datos sean más adecuados== para su uso.
* **Ciclo de Mejora Continua (PDCA de Deming):**
    * *Plan (Planificar):* Identificar ==problemas de calidad== y evaluar alternativas.
    * *Do (Hacer):* Abordar las causas del problema e ==implementar soluciones==.
    * *Check (Verificar):* Monitorizar y ==verificar que se cumplen los niveles de calidad==.
    * *Act (Actuar):* Si la calidad es baja, ==actuar para corregir y estandarizar== la mejora.
* **Motivaciones y Elementos Clave:**
    * *Motivaciones del negocio:* ==Aumentar el valor== de los datos, ==reducir riesgos y costes==, proteger la reputación y ==mejorar la eficiencia==.
    * *Elementos del programa:* Se apoya en el **gobierno de datos** (alinear con el negocio), la definición de **estándares y especificaciones** (controles de calidad), la **medición y monitorización** continua de la calidad y **mejora continua**.

---

# 3. Modelo de Calidad ISO/IEC 25012
Este ==estándar== define las *características de la calidad de datos en dos dimensiones*:
1. **Calidad Inherente:** Se refiere a la ==calidad de los datos por sí mismos==, *independientemente del sistema* en que se encuentren.
2. **Calidad Dependiente del Sistema:** Se refiere a la ==calidad que se alcanza gracias a las capacidades del sistema== informático (*hardware* y *software*).

## 3.1. Dimensiones de la calidad de datos inherente
* **Exactitud:** *Grado* en que los ==datos representan correctamente el valor verdadero==. Se divide en:
    * **Sintáctica:** Los ==valores se ajustan al formato== definido (ej. una fecha en formato `AAAA-MM-DD`).
    * **Semántica:** Los ==valores son correctos en su significado== (ej. que la fecha de nacimiento de un cliente no sea en el futuro).
* **Completitud:** *Grado* en que *todos* los ==atributos esperados tienen un valor==.
* **Consistencia:** *Grado* en que los datos ==no se contradicen entre sí o con otros datos en un contexto== de uso.
* **Credibilidad:** *Grado* en que los datos ==se consideran ciertos y creíbles== (proceden de una fuente fiable).
* **Actualidad:** *Grado* en que los datos ==tienen la antigüedad correcta para su uso==.

## 3.2. ISO 25024 –> Visión global 
**Define las medidas de calidad de los datos para la medición cuantitativa** de los mismos en términos de características definidas en `ISO/IEC 25012`. 
*`ISO 25024` contiene* lo siguiente: 
- Un ==conjunto básico de medidas de calidad== de datos ==para cada característica==. 
- Un conjunto básico de *entidades objetivo* ==a las que se aplican las medidas== de calidad. 
- Un *método de medición* que indica ==cómo aplicar las medidas de calidad== de los datos. 
- Una ==orientación para las organizaciones que definen sus propias medidas== de los requisitos de calidad.

---

# 4. Limpieza y Perfilado de Datos
## 4.1. Limpieza de Datos (Data Cleansing)
Es el *proceso* de **detección y corrección (o eliminación)** de ==registros corruptos, incompletos o inexactos== en un conjunto de datos. Para realizar acciones como sustitución, modificación o eliminación de datos sucios.
- **Flujos de Limpieza de Datos** 
	- *Flujo básico*: `Detección de errores` -> `Reparación` -> `Transformación`  -> `Datos limpios`. 
	- *Flujo dirigido por calidad*: `Análisis de calidad` -> `Reglas/patrones` -> `Detección` -> `Reparación`. 
	- *Inclusión de fuentes externas*: Conocimiento externo y ==datos externos enriquecen el proceso==.
*   **Fases del proceso:**
    1. *Detección / Perfilado:* Encontrar *valores anómalos, duplicados* y ==definir reglas de negocio==.
    2. *Reparación / Corrección:* ==Aplicar transformaciones==, consolidar datos y *corregir errores según las reglas*.

## 4.2. Perfilado de Datos (Data Profiling)
Es el conjunto de **actividades para desentrañar los metadatos y comprender las características generales de los datos** mediante *descriptores estadísticos*. Entre las *técnicas* que se usan destacan: `Exploración de datos`, `gestión de BD`, `ingeniería inversa`, `integración`.
* **Perfilado vs. Detección de errores:**
    * *Perfilado:* Es un ==enfoque exploratorio== y **global**. Su objetivo es *comprender* *las características* de los datos.
    * *Detección de errores:* Es un ==enfoque de identificación precisa== y **local**. Su objetivo es *identificar valores específicos* que están mal.

> 🔎
> Se usa **para el conteo de nulos, distribuciones de frecuencias, duplicados** y para establecer ==correlaciones o claves foráneas==.

### 4.2.1. Observabilidad de datos
**Monitoreo proactivo de salud de datos**. Se ==evalúa la calidad, completitud, exactitud y disponibilidad de métricas clave==. Ayuda en la *prevención de errores*, mejora continua y *decisiones confiables*. 

Se sigue un **ciclo**: `Monitorización` -> `Detección` -> `Soluciones` -> `Optimización`.

### 4.2.2. Detección de Valores Atípicos (Outliers)
Son **observaciones que se desvían significativamente del resto** y ==generan sospechas==.
* **Enfoques para detectarlos:**
    1. *Basados en estadísticos:* Utilizan ==tests de hipótesis== (ej. `Test de Grubbs`, calcula la desviación máxima respecto a la media) o ==ajustes de distribución== (`paramétricos`, asumen que los datos siguen una distribución específica | `no paramétricos`, estiman la distribución a partir de los datos, el más común es KDE).
    2. *Basados en distancia:* Definen una ==medida de distancia para identificar puntos que están "lejos" de los demás==. Algoritmos como `KNN` o `LOF`.
    3. *Basados en modelos:* ==Entrenan modelos de clasificación== para aprender qué es un dato "normal" (a partir de un conjunto de datos etiquetados) y detectar lo que no lo es. 2 tipos: 
        - `Clase Simple`: Asumen que ==todos los datos de entrenamiento pertenecen a una sola clase==. 
        - `Multi-Clase`: Los datos de entrenamiento ==incluyen varias clases normales etiquetadas==.

### 4.2.3.  Eliminación de datos duplicados
**Tarea de limpieza de datos enfocada en identificar y manejar registros duplicados**. *Proceso*: 
- ==Detectar las tuplas (registros) que representan la misma entidad== del mundo real en una o varias relaciones. 
- ==Consolidar las entidades==, encontrando una *representación unificada de los registros duplicados* que refleje con precisión la entidad real.

Suelen producirse por errores manuales, fusiones de bases de datos, uso de formatos inconsistentes ("C/ Mayor 12" vs "Calle Mayor, 12"), etc.
* **Funciones de Similitud** (trabajan con *incertidumbre* y requieren de la ==definición de un umbral==):
    * *Basadas en caracteres:* Detectan ==errores tipográficos== (ej. "Ana Gracia" vs "Ana García").
    * *Basadas en fonética:* Detectan ==similitudes en cómo suenan== los nombres (ej. "Smith" vs "Smyth").
    * *Basadas en Tokens*: Tratan ==errores relacionados con reordenamientos o diferencias en tokens==.
* **Técnicas de Consolidación** (hay que ==escoger y transformar==):
    * *Fusión de registros:* Cuando hay contradicciones, ==se resuelven eligiendo el valor más frecuente==, el más reciente o el de mayor calidad.
    * *Clustering:* **Agrupar registros** que ==probablemente representan la misma entidad== del mundo real.
    * *Resolución de conflictos Probabilística*: Modela **múltiples posibles reparaciones** en lugar de generar un único registro consolidado

> 🤖 **Uso de Machine Learning para detectar duplicados**
>  **Modelo supervisado**: ==Clasifica pares de registros como duplicados o no duplicados==, entrenado *con ejemplos etiquetados*. Es de alta precisión.

### 4.2.4. Transformación de datos
Implica **ejecutar programas para convertir datos de un formato a otro**. ==Transforma datos erróneos o duplicados==. Puede ser **Sintáctica** (*automática*) o **Semántica** (*requiere conocimiento externo*). 

**Ventajas e inconvenientes de la semántica**: 
- Las ventajas de la semántica es ==mejorar la interoperabilidad, incrementar la precisión del análisis de datos y facilitar la adaptación== de los mismos a distintos dominios. 
- Los inconvenientes son la *complejidad en la definición de reglas semánticas*, la ==dependencia de modelos de conocimiento actualizados y el procesamiento computacional== intensivo

---

# 5. Conclusiones finales
* La calidad de los datos es **crucial** para la toma de decisiones.
* La responsabilidad sobre la calidad es de **toda la organización**, no solo de los administradores de bases de datos.
* La limpieza de datos debe ser un **proceso continuo** y no un proyecto aislado.
* Más importante que limpiar es **atacar el problema raíz**: asegurar que los datos que entren al sistema ya sean de calidad.