---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "En unsupervised learning no hay etiquetas: el algoritmo solo ve los datos y tiene que encontrar estructura por su cuenta"
Fecha de actualización: 2026-07-28
Nota previa: "[[07 - Máquinas de vectores de soporte (SVM)]]"
Nota siguiente: "[[09 - K-Means y clustering]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">En `unsupervised learning` no hay etiquetas: el algoritmo solo ve los datos y tiene que encontrar estructura por su cuenta.</mark> No predice un resultado conocido — descubre agrupaciones, reduce variables o señala lo que se sale de la norma.

Esto no es una curiosidad académica: <mark style="background: #FF5582A6;">es el escenario por defecto en detección de seguridad</mark>. Nadie tiene un dataset etiquetado de los ataques que va a recibir mañana. Se tiene tráfico, logs y telemetría sin etiquetar, y hay que decidir qué es raro. De ahí que casi todo detector de comportamiento —UEBA, NDR, la mitad de un EDR— sea, por dentro, aprendizaje no supervisado.

Se divide en tres problemas:

1. **`Clustering`** — agrupar elementos parecidos. Segmentar usuarios por comportamiento, agrupar muestras de malware en familias.
2. **`Dimensionality reduction`** — reducir el número de variables conservando la información esencial. Comprimir cientos de features de un flujo de red a unas pocas manejables.
3. **`Anomaly detection`** — señalar lo que se desvía del patrón. La base de la detección sin firmas.

# Conceptos que sostienen todo lo demás

## Medidas de similitud

Sin etiquetas, la única guía es cuánto se parecen los datos entre sí. La elección de la métrica **cambia el resultado**, no es un detalle de implementación.

| Métrica | Qué mide | Cuándo usarla |
| - | - | - |
| `Euclidean distance` | Distancia en línea recta | Features numéricas comparables y pocas dimensiones |
| `Cosine similarity` | Ángulo entre vectores, ignora la magnitud | Texto y embeddings, donde importa la dirección y no la longitud |
| `Manhattan distance` | Suma de diferencias absolutas | Datos de alta dimensión, donde se degrada menos que la euclídea |

Son las mismas normas de [[01 - Matemáticas para machine learning]] usadas ahora como medida de parecido entre puntos en vez de como presupuesto de perturbación.

## Escalado de features: obligatorio

Todo lo anterior son distancias, y una distancia mezcla unidades. Si una feature es "bytes transferidos" (0 a 10⁹) y otra es "número de puertos" (0 a 65535), la primera aplasta a la segunda. Dos técnicas:

- **`Min-Max scaling`** — reescala a un rango fijo, típicamente [0, 1]. Conserva la forma de la distribución pero es **muy sensible a outliers**: un solo valor extremo comprime todo lo demás.
- **`Standardization`** (z-score) — resta la media y divide por la desviación típica; deja media 0 y varianza 1. Es la opción por defecto y aguanta mejor los valores extremos.

> [!warning]+ Escalar con estadísticas del dataset completo es fuga de datos
> Calcular media y desviación sobre todo el conjunto **antes** de partir en train/test contamina el entrenamiento con información del test. Hay que ajustar el escalador solo con `train` y aplicarlo después a `test`. Es uno de los errores de `data leakage` más frecuentes y produce métricas infladas — ver [[02 - Aprendizaje supervisado]].

## Validez de los clusters

Sin etiquetas no existe "acierto", así que la calidad se mide por la geometría del resultado:

- **Cohesión** — cuánto se parecen los puntos dentro de un mismo cluster. Alta es mejor.
- **Separación** — cuánto se diferencian los clusters entre sí. Alta es mejor.

El `silhouette score` y el índice de Davies-Bouldin combinan ambas en un número. Antes incluso de eso conviene comprobar la **tendencia al clustering**: si los datos están distribuidos uniformemente, no hay grupos que encontrar y el algoritmo devolverá particiones arbitrarias con aspecto perfectamente convincente.

## Dimensionalidad y su maldición

La `curse of dimensionality` es el fenómeno que rompe todo lo basado en distancias cuando hay muchas features. <mark style="background: #8000E1A6;">Al crecer las dimensiones, el volumen del espacio crece exponencialmente y los datos se vuelven dispersos: todos los puntos acaban aproximadamente a la misma distancia unos de otros.</mark> La distancia deja de discriminar, y con ella se van el clustering, el k-vecinos y la detección de anomalías por distancia.

La `intrinsic dimensionality` es la dimensión real que hace falta para describir los datos, casi siempre mucho menor que el número de features. Las técnicas de reducción buscan exactamente eso: quitar dimensiones redundantes sin perder la estructura — ver [[10 - Análisis de componentes principales (PCA)]].

> [!info]+ La misma maldición explica los ejemplos adversariales
> En dimensión alta, cada punto está cerca de la frontera de decisión en *alguna* dirección, simplemente porque hay muchísimas direcciones disponibles. Es una de las explicaciones de por qué basta una perturbación diminuta bajo `L∞` para cambiar la clasificación: el espacio es tan vasto que la clase correcta ocupa una fracción minúscula del entorno de cada punto.

## Anomalía y outlier

Se usan como sinónimos y no lo son del todo. Un **outlier** es un punto lejos del resto — puede ser un error de medición o un caso legítimo raro. Una **anomalía** es un punto que se desvía del comportamiento esperado y **significa algo**: un fraude, un fallo, una intrusión.

<mark style="background: #FFB86CA6;">La distancia entre ambos conceptos es el problema central de la detección basada en ML.</mark> El algoritmo encuentra outliers; el analista necesita anomalías. Traducir uno en otro es trabajo humano, y es donde la mayoría de despliegues fracasan.

# Más allá de k-means

El temario introductorio se queda en `K-means`, que asume clusters esféricos y de tamaño similar. Conviene conocer al menos otras dos familias porque los datos de seguridad rara vez cumplen esa forma:

- **`DBSCAN`** — agrupa por densidad. No hay que decirle cuántos clusters hay, encuentra formas arbitrarias y **marca explícitamente el ruido como tal**, lo que lo hace naturalmente apto para detección de anomalías.
- **Clustering jerárquico** — construye un árbol de agrupaciones anidadas. Permite decidir el nivel de granularidad *después* de entrenar, y su dendrograma es muy útil para agrupar familias de malware.
- **`Gaussian Mixture Models`** — asignación blanda: cada punto tiene una probabilidad de pertenecer a cada cluster, y admite clusters elípticos de distinto tamaño.

# El vector de ataque específico del no supervisado

Un modelo supervisado se entrena una vez con datos que alguien curó. <mark style="background: #FFB8EBA6;">Un detector no supervisado aprende qué es "normal" a partir del tráfico en vivo, y lo reaprende continuamente.</mark>

Eso significa que **el atacante escribe en el conjunto de entrenamiento con solo generar tráfico**. No necesita acceso al pipeline de datos, ni comprometer un repositorio, ni envenenar un dataset público: le basta con estar en la red. Es el ataque de la rana hervida — introducir actividad ligeramente anómala de forma sostenida hasta que el modelo la absorbe como normal, y solo entonces ejecutar la acción real. Se desarrolla en [[09 - K-Means y clustering]] y en [[11 - Detección de anomalías]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la explicación de la maldición de la dimensionalidad, alternativas a k-means (`DBSCAN`, jerárquico, `GMM`) y el encuadre del envenenamiento de línea base, ausentes en el original.
