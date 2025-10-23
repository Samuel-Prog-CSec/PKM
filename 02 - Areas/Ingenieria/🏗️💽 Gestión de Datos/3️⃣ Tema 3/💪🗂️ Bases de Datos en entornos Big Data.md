# 1. Sistemas Gestores de Bases de Datos (SGBD)
Un `SGBD` es el conjunto de **programas que permiten almacenar y acceder a los datos** de forma *concurrente y segura*.
* **Componentes principales de un SGBD:**
    * *Motor de la BD:* ==Traduce las peticiones lógicas a acciones físicas== sobre los datos.
    * *Subsistema de definición:* Define la ==estructura de los datos==.
    * *Subsistema de manipulación:* ==Permite consultar, agregar y modificar== datos.
    * *Subsistema de administración:* Gestiona la ==seguridad, concurrencia y rendimiento==.
* **Evolución:**
    * *Pre-relacionales:* (ej. `IMS`, ==sistemas de archivos==).
    * *Relacionales:* (ej. `Oracle`, `MySQL`). Son el **estándar** durante décadas.
    * *Post-relacionales (`NoSQL`):* (ej. `MongoDB`, `Cassandra`). Surgen para dar respuesta a las **necesidades del `Big Data`**.

---

# 2. Bases de Datos Distribuidas y el Teorema CAP
Una base de datos distribuida consiste en un **conjunto de datos lógicamente interrelacionados** que están *repartidos en diferentes nodos de una red*.
* **¿Por qué surgen?** Por la ==globalización==, el crecimiento de la capacidad computacional y la ==necesidad de compartir datos== de manera eficiente.
* **Diseño:**
    * *Esquema conceptual global:* ==Define la BD completa== como si no estuviera distribuida.
    * *Esquema de fragmentación:* Decide ==cómo se van a partir== los datos.
    * *Esquemas locales:* Describen la ==porción de la BD que hay en cada nodo==.

## 2.1 El Teorema CAP
Este teorema fundamental establece que en un sistema de datos distribuido es *imposible garantizar simultáneamente* las tres siguientes propiedades. **Solo se pueden elegir dos de tres**:
1. **Consistencia (C - Consistency):** Todos los nodos ==ven la misma versión de los datos== al mismo tiempo. *Cualquier lectura devuelve el dato de la escritura más reciente*.
2. **Disponibilidad (A - Availability):** ==Todas las peticiones reciben siempre una respuesta==, aunque no se garantice que contenga la versión más actualizada de los datos. El *sistema siempre está operativo*.
3. **Tolerancia a particiones (P - Partition Tolerance):** El *sistema sigue funcionando incluso si hay fallos en la red* que provocan que los nodos no puedan comunicarse entre sí (una "`partición`" de la red).
*  **La elección:**
    * Las bases de datos **relacionales tradicionales (`SQL`)** suelen priorizar la **Consistencia** y la **Disponibilidad** (`CA`), pero *no son tolerantes a particiones*.
    * Las bases de datos **NoSQL** están *diseñadas para entornos distribuidos*, por lo que asumen la **Tolerancia a particiones** (`P`) como obligatoria. Por tanto, ==deben elegir entre ser más consistentes== (`CP`) ==o más disponibles== (`AP`).

---

# 3. Bases de datos NoSQL
Surgen por la **necesidad de manejar Big Data**, ya que las *nuevas aplicaciones requieren*:
* **Alta velocidad** y **escalabilidad** sin degradar el rendimiento.
* **Disponibilidad** continua.
* **Soporte** ==para datos estructurados y no estructurados== (texto, streaming, etc.).

## 3.3 Caracteristricas BD NoSQL
- **No relacional** 
- **Distribuida** 
- **Código abierto** 
- **Escalable horizontalmente** 
- **Libre de esquemas -> fácil replicación** 
- **API sencilla** 
- **Gran cantidad de datos** 
- ¡ **no cumple principios `ACID`** !

## 3.2 De ACID al Teorema CAP
* Las bases de datos **SQL** cumplen con los principios **ACID**:
    * **Atomicidad:** Las transacciones se realizan *por completo o no se realizan* en absoluto.
    * **Consistencia:** La transacción *lleva la BD de un estado válido a otro*.
    * **Aislamiento (Isolation):** Las transacciones *concurrentes no interfieren entre sí*.
    * **Durabilidad:** Una vez que una transacción se confirma, los *cambios son permanentes*.
* Las bases de datos **NoSQL no cumplen estrictamente ACID** para ==poder ofrecer la flexibilidad y escalabilidad que las caracteriza==. Esta es la *razón por la que se rigen por el teorema `CAP`*, donde a menudo se debe =="renunciar" a la consistencia estricta a cambio de una mayor disponibilidad y tolerancia a fallos==.

## 3.3 Limitaciones de NoSQL
- **Limitaciones técnicas** 
	- Cómo modelar correctamente los datos para maximizar las capacidades
	- Nivel bajo de seguridad
	- No soporta transacciones
	- Falta de madurez en Business Intelligence
	- Problemas de compatibilidad ya resueltos en los modelos relacionales 
- **Limitaciones No técnicas** 
	- Falta de expertos 
	- Resistencia al cambio 
	- Disponibilidad del vendedor 
	- El código abierto puede implicar problema de soporte para las empresa

---

# 4. Tipos de Almacenamiento NoSQL
* **Clave-Valor:** Almacenan datos en un **simple par de clave** (*única*) **y valor**. Son ==muy rápidas y escalables==, pero de *baja funcionalidad*.
    * *Ejemplos:* `Redis`, `DynamoDB` (Amazon).
* **Documental:** Almacenan datos en **documentos flexibles**, normalmente en formato `JSON` o `XML`. Son ideales para *datos complejos y jerárquicos*.
    * *Ejemplos:* `MongoDB`, `CouchDB`.
* **Orientado a Columnas:** ==Almacenan los datos por columnas en lugar de por filas==. Son *extremadamente eficientes para consultas analíticas* sobre ==grandes volúmenes de datos==, ya que **solo leen las columnas necesarias para la consulta**.
    * *Ejemplos:* `Cassandra` (usada por Facebook/Twitter), `BigTable` (Google).
* **Basado en Grafos:** Diseñadas para datos donde las **relaciones son lo más importante**. Utilizan ==nodos para representar entidades y aristas para representar las relaciones== entre ellas.
    * *Ejemplos:* `Neo4j` (usada en redes sociales y sistemas de recomendación).
* **Multi-modelo:** ==Combinan varios de los modelos anteriores== en una única base de datos.
    * *Ejemplo:* `ArangoDB`.

---

# 5. Tecnologías de rastreo
Permiten **acceso eficiente a contenidos multimodales** (texto, web, imágenes, video). 
Los *objetivos de la indexación* son: 
- **Búsqueda rápida** en ==grandes volúmenes de datos==. 
- **Consultas eficientes** en múltiples variables. 
- **Indexación paralela** para *procesamiento rápido*.
## 5.1 Estructuras de Indexación
Los datos se almacenan en unidades de acceso fijo ==DEBEN tener claves asociadas== al dato correspondiente.
**Los datos tienen que estar obligatoriamente identificados unívocamente**.
Estructuras básicas:
* **Tablas Hash:** ==Asocian claves== (*hasheadas*) ==con valores==. Búsqueda muy eficiente.
* **Índices basados en Árboles:** ==Preservan el orden de las claves==. Útiles para *búsquedas por rangos*.
* **Archivos Invertidos:** ==Indexan por palabras clave==. Son la base de los *motores de búsqueda*.
* **Join Índices:** ==Optimizan las operaciones de unión== (`join`) en bases de datos distribuidas *pre-calculando las relaciones*.

---

# 6. Escalabilidad
Es la capacidad de un sistema para **mantener su rendimiento a medida que aumenta el número de usuarios** o la carga de trabajo.
La escalabilidad está *íntimamente ligada al diseño del sistema*. **Influye en el rendimiento de forma significativa**. ==No es un atributo del sistema configurable==. 
La escalabilidad supone un *factor crítico en el crecimiento de un sistema*.
* **Tipos de Escalabilidad:**
    * *En carga*: Un ==sistema distribuido nos hace fácil ampliar y reducir sus recursos== para acomodar (a conveniencia) cargas.
    * *Geográfica*: Un sistema geográficamente escalable, es aquel que ==mantiene su utilidad y usabilidad, sin importar que tan lejos estén sus usuarios== o recursos. 
    * *Administrativa*: ==No importa qué tantas organizaciones diferentes necesiten compartir un solo sistema== distribuido, debe ser *fácil de usar y manejar*.
    * Según la **forma técnica** de acometer la escalabilidad, esta puede ser:
	    * *Vertical (Scale-Up):* ==Mejorar el hardware existente== (más `CPU`, `RAM`). Tiene un **límite físico y es costoso**.
	    * *Horizontal (Scale-Out):* ==Añadir más servidores== (**nodos**) para **distribuir la carga**. Es la ==base de la escalabilidad en Big Data==.

## 6.1 Balance de carga
Distribuye las **peticiones entre múltiples servidores para evitar cuellos de botella**. Opciones: 
- *Replicación:* Crear ==copias de los datos en múltiples nodos para mejorar la disponibilidad y la velocidad== de lectura. Puede ser **síncrona o asíncrona**.
- *Particionamiento (Sharding):* ==Dividir los datos en fragmentos y distribuirlos== entre diferentes nodos. **Cada dato reside en una única partición**. Hay *tres tipos*:
	1. La primera es que el ==cliente siempre apunte a un nodo y si ese no tiene la información se le redirija al que sí==. Es útil cuando hay pocos nodos. 
	2. El segundo y **más usado** es que el ==cliente apunte a una tabla de enrutamiento y se consulte ahí donde esta el dato== y se vaya a ese nodo. 
	3. La última es que ==puedes decidir a que nodo apunta el cliente== y puede ser *útil cuando tienes varios clientes que operan siempre con datos conocidos*.

### 6.1.1 Desafíos de la replicación
- **Lectura inconsistente**: *Evitar datos desactualizados*. Para ello se usan `timestamps`.
- **Velocidad de replicación**: Hay que *mantener orden en lecturas concurrentes*.
