# 1. Técnicas de Procesamiento y Análisis de Datos
La elección de las técnicas de procesamiento es clave, ya que ==influye en la potencia, escalabilidad, capacidad de detectar fraudes y en la seguridad== del sistema.
* **Objetivo principal:** *Reducir la latencia en el análisis* de grandes volúmenes de datos (procesar terabytes en segundos).
* **Opciones principales:** Procesamiento Batch, Streaming y arquitecturas Lambda.

## 1.1. Procesamiento Batch
* **Concepto:** Manejo de datos por *lotes de gran volumen*.
* **Tecnología principal:** `Apache Hadoop`.
    * `Hadoop Distributed File System (HDFS)`: Permite ==trabajar eficientemente con un número reducido de archivos muy grandes==.
    * `MapReduce`: Es un ==modelo de programación para procesar estos datos en paralelo==. Sigue estos pasos:
        1. Se *divide un conjunto de archivos en registros*.
        2. Se aplica una función `mapper` para *extraer pares clave-valor de cada registro*.
        3. Se *ordenan los pares clave-valor*.
        4. Se aplica una función `reducer` que *itera sobre los valores de una misma clave* para ==procesar los pares ordenados y generar el resultado==.
    * **Ejemplo práctico:** Correlacionar la actividad de un usuario con su perfil. Se extrae el ID de usuario como *clave* y los eventos (clics, compras, etc.) como *valores*. El `reducer` agrupa todos los eventos de un mismo usuario para analizarlos conjuntamente.

## 1.2. Procesamiento en Stream
Modelo donde los **datos fluyen continuamente** (como un "río") **a través de entidades que los transforman**. *No hay restricciones de tiempo estrictas*, pero es vital tener ==memoria suficiente== y que la ==tasa de procesamiento sea igual o mayor que la tasa de entrada de datos==.
* **Tipos:**
    * *Streaming (ej. Netflix):* Los ==datos (vídeos) ya existen y se van "descargando" o consumiendo en streaming a demanda== del usuario.
    * *Procesamiento en Tiempo Real (ej. un directo de YouTube):* ==La entrada se procesa tan pronto como es posible==, con **latencias muy bajas**. Amazon, por ejemplo, garantiza respuestas en menos de 200 ms.

## 1.3. Arquitectura Lambda
*Combina el procesamiento* **Batch** y el procesamiento en **Tiempo Real** para ==ofrecer una solución genérica, escalable y tolerante a fallos==.
* **Estructura:**
    * **Capa Batch (por lotes):** *Procesa todos los datos* para crear una ==vista completa y precisa== (`Master Dataset`).
    * **Capa de Velocidad (Speed Layer):** *Procesa los datos en tiempo real* para ==compensar la alta latencia de la capa Batch==.
    * **Capa de Servicio (Serving Layer):** *Unifica las salidas de ambas capas* para ==responder a las consultas de los usuarios== con baja latencia.
* **Desafíos:**
    * Esfuerzo alto para *mantener la lógica de negocio sincronizada* entre las dos capas.
    * *Complejidad al fusionar los resultados* de la capa Batch y la capa de Velocidad.
    * *Costo elevado* si se necesita ==reprocesar frecuentemente los datos históricos==.

---

# 2. Integración de Datos
Es el proceso de **combinar datos de diferentes fuentes para obtener una visión unificada**. Esto implica **interoperabilidad**: la *capacidad de diferentes sistemas para compartir y usar datos entre sí*.

## 2.1. Métodos de Integración
* **ETL (Extract, Transform, Load):**
    1. *Extraer:* Obtener ==datos de diversas fuentes==.
    2. *Transformar:* Aplicar reglas de negocio para ==limpiar, validar y formatear los datos==.
    3. *Cargar:* ==Guardar los datos transformados== en el sistema destino (ej. un Data Warehouse).
* **ELT (Extract, Load, Transform):** Variante de ETL donde los *datos se cargan primero en el sistema destino y se transforman después*. Es un enfoque más moderno, ==utilizado en entornos de Big Data==.

## 2.2. Arquitecturas de Interoperabilidad
* **Punto a Punto:** *Conexiones directas entre sistemas*. Es simple para entornos pequeños, pero ==se vuelve inmanejable y caótico a gran escala==.
* **Modelo Canónico, Rueda o Bus de Servicio (ESB):** Todos los *sistemas se comunican a través de un* **"bus" central** que utiliza un ==formato de datos universal (canónico)==. Es más complejo de implementar al inicio, pero ==facilita enormemente la gestión en sistemas grandes==.

---

# 3. Métodos de Integración (APIs y Servicios Web)
* **APIs (Application Programming Interface):** *Permiten la comunicación estandarizada* entre ==diferentes aplicaciones de software==.
* **Servicios Web:** Tecnologías que ==permiten a las aplicaciones interoperar a través de la web==.
    * **SOAP:** *Protocolo estándar del `W3C`* ==basado en `XML`==. Es robusto pero considerado ==más complejo y pesado que REST==.
    * **REST (REpresentational State Transfer):** Un *estilo de arquitectura, no un protocolo*. Es ==más simple, flexible y ligero que `SOAP`==. Utiliza las **operaciones estándar de `HTTP`** (GET, POST, PUT, DELETE) para interactuar con los recursos ==a través de sus URIs==.
    * **GraphQL:** ==Alternativa y complemento a REST==. Permite a los clientes solicitar *exactamente* los datos que necesitan y nada más, evitando el **over-fetching** (==recibir más datos de los necesarios==) y el **under-fetching** (tener que ==hacer múltiples peticiones para obtener todos los datos==).
        * Utiliza un *único* *endpoint* para todas las consultas.
        * Tiene un *sistema de tipado fuerte* que facilita la validación y consistencia.

---

# 4. Almacenamiento Basado en Ficheros de Texto Plano
Se utilizan *formatos legibles e interoperables* para estructurar los datos.
* **CSV (Comma-Separated Values):** Representa ==datos en formato de tabla==, con *valores separados por comas*. **No es un formato estandarizado**, pero es muy común para intercambiar datos.
* **XML (eXtensible Markup Language):** ==Lenguaje de marcado con una estructura jerárquica== (*árbol anidado*). Es la base de estándares como `SOAP` y `WSDL`. Su ==estructura es extensible, permitiendo añadir más "hijos"== (*etiquetas*) fácilmente.
* **JSON (JavaScript Object Notation):** *Formato ligero y flexible* para el intercambio de datos. Es ==más simple y eficiente que XML== en muchas aplicaciones.
    * Una de sus grandes ventajas es que **puede ser interpretado (parseado) directamente por JavaScript**.
    * Su **estructura** se basa en pares `nombre:valor` y listas de valores.