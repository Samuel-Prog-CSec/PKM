---
tags:
  - IA
  - IA/Machine-Learning
  - Pentesting/Enumeracion
  - Tipo/Deteccion
Descripción: "La detección de anomalías identifica puntos que se desvían significativamente del comportamiento normal de un conjunto de datos"
Fecha de actualización: 2026-07-28
Nota previa: "[[10 - Análisis de componentes principales (PCA)]]"
Nota siguiente: "[[12 - Aprendizaje por refuerzo]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">La detección de anomalías identifica puntos que se desvían significativamente del comportamiento normal de un conjunto de datos.</mark> Es el mecanismo detrás de la detección sin firmas: en vez de describir el ataque, se describe la normalidad y se alerta sobre todo lo demás. Fraude, fallos de sistema, intrusiones — cualquier evento raro y relevante.

Es también la técnica de ML con la peor relación entre expectativa y resultado en seguridad, y merece la pena entender por qué antes de estudiar los algoritmos.

# Tres tipos de anomalía

| Tipo | Definición | Ejemplo en seguridad |
| - | - | - |
| **Puntual** | Un dato individual muy distinto del resto | Un pico súbito de tráfico saliente; una transferencia de 40 GB a las 3 AM |
| **Contextual** | Normal en abstracto, anómalo en su contexto | Un login válido de un administrador... desde una IP de otro país a las 4 AM |
| **Colectiva** | Ningún dato es raro por sí solo, el conjunto sí | 200 intentos de login fallidos repartidos entre 200 IPs distintas, uno cada uno |

<mark style="background: #FF5582A6;">Las contextuales y las colectivas son donde vive el atacante competente</mark>, y también donde la mayoría de detectores fallan: un modelo entrenado sobre eventos individuales no ve la estructura. El `password spraying` es literalmente un ataque diseñado para ser invisible a la detección puntual.

# Familias de técnicas

## Estadísticas

Asumen que los datos normales siguen una distribución conocida y marcan lo que se aleja. `Z-score` (cuántas desviaciones típicas separa un punto de la media), z-score modificado (basado en mediana, más robusto) y diagramas de caja. Baratas, interpretables y sorprendentemente competitivas cuando la distribución es estable.

## Basadas en clustering

Agrupan los datos y marcan como anómalo lo que no cae en ningún cluster o cae en clusters minúsculos. `DBSCAN` lo hace nativamente porque etiqueta el ruido. Sobre `K-means` se implementa como distancia al centroide más cercano — con la vulnerabilidad de envenenamiento descrita en [[09 - K-Means y clustering]].

## Basadas en ML

### One-Class SVM

![Frontera de One-Class SVM encerrando los datos normales y dejando las anomalías fuera](https://academy.hackthebox.com/storage/modules/290/one_class_svm.png)

Aprende una frontera que **envuelve** los datos normales; todo lo que quede fuera es anómalo. Al ser una SVM, admite kernels y por tanto fronteras no lineales. Su punto débil es el coste computacional y la sensibilidad al parámetro `nu`, que fija qué fracción de los datos de entrenamiento se acepta como outlier.

### Isolation Forest

Parte de una observación elegante: las anomalías son "pocas y diferentes", así que **son fáciles de aislar**. Se construyen árboles partiendo el espacio con features y umbrales aleatorios hasta aislar cada punto; los anómalos quedan aislados con muy pocas particiones.

```text
score(x) = 2^( −E(h(x)) / c(n) )
```

Donde `E(h(x))` es la longitud media del camino para aislar `x` y `c(n)` el factor de normalización. Puntuaciones cerca de 1 indican anomalía; cerca de 0,5, normalidad.

<mark style="background: #FFB8EBA6;">Es el detector por defecto razonable para datos tabulares</mark>: no calcula distancias (inmune a la maldición de la dimensionalidad) y es lineal en el número de muestras.

> [!warning]+ Dos trampas al implementarlo
> **El signo está invertido en `scikit-learn`.** La fórmula de arriba es la del paper original, donde alto = anómalo. `IsolationForest` sigue el convenio de la librería para detectores de outliers: `decision_function()` devuelve valores **negativos para las anomalías** y positivos para lo normal, y `predict()` devuelve `-1` / `+1`. Invertir el signo por error produce un detector que marca exactamente lo contrario de lo que debe, y como las métricas globales pueden seguir pareciendo razonables, es un fallo que sobrevive a una revisión superficial.
>
> **`contamination` no es un detalle.** Decir que "apenas tiene hiperparámetros" es engañoso: `contamination` fija **qué fracción del conjunto se asume anómala**, y de ahí sale el umbral de decisión. <mark style="background: #FF5582A6;">Es una suposición sobre la respuesta que se está buscando</mark>, no un parámetro técnico: ponerlo al 0,1 por defecto significa afirmar que el 10% del tráfico es anómalo, lo que en una red real es absurdo y dispara los falsos positivos. Conviene fijarlo desde la tasa base esperada, o dejarlo en `'auto'` y elegir el umbral sobre las puntuaciones con el criterio operativo de [[05 - Métricas de evaluación de modelos]].

### Local Outlier Factor

Compara la densidad local de un punto con la de sus `k` vecinos. Un punto en una zona mucho menos densa que su entorno es un outlier.

```text
LOF(p) = ( Σ lrd(o) / k ) / lrd(p)
```

Su ventaja es detectar anomalías **locales**: un punto que es normal en términos globales pero raro dentro de su vecindario. Es el caso de un servidor cuyo tráfico sería normal para un servidor web pero es anómalo para un controlador de dominio.

# Por qué decepciona en producción

Esta es la parte que los materiales introductorios omiten y la que determina si un despliegue funciona.

> [!important]+ El paper que hay que haber leído
> [Sommer & Paxson, *Outside the Closed World: On Using Machine Learning for Network Intrusion Detection* (IEEE S&P 2010)](https://www.icir.org/robin/papers/oakland10-ml.pdf) sigue siendo la crítica de referencia, y quince años después ninguno de sus argumentos ha caducado:
>
> - **El ML es bueno encontrando parecidos, no diferencias.** Está diseñado para generalizar sobre lo que ha visto, no para caracterizar lo que nunca vio.
> - **El coste del error es asimétrico y alto.** Un falso positivo consume tiempo de analista; un falso negativo es una brecha. Ningún otro dominio del ML tolera tan mal los errores.
> - **El "hueco semántico".** El modelo produce outliers; el analista necesita saber *qué hacer*. <mark style="background: #FFB86CA6;">Una alerta que dice "esta conexión es estadísticamente rara" sin explicar por qué es operativamente inútil.</mark>
> - **No existe un "normal" estable.** El tráfico de red es enormemente variable a todas las escalas temporales. La línea base es un blanco móvil.
> - **La evaluación es defectuosa.** Los datasets públicos son antiguos, sintéticos o poco representativos, y las métricas de laboratorio no se trasladan.

A eso se suma el **`concept drift`**: la normalidad cambia sola —despliegues nuevos, cambios de horario, migraciones— y el modelo se degrada. La respuesta habitual es reentrenar de forma continua, lo que <mark style="background: #8000E1A6;">reabre exactamente la ventana de envenenamiento</mark>: el sistema que se adapta rápido a los cambios legítimos se adapta igual de rápido a los que introduce el atacante.

# Evasión desde el lado ofensivo

Si la detección se basa en salirse de la norma, la evasión consiste en no salirse. Las técnicas son las de siempre, con nombre nuevo:

- **Ataques de mimetismo** — envolver la acción maliciosa en un patrón que reproduce el comportamiento legítimo. Ejecutar la exfiltración sobre HTTPS al puerto 443 durante horario de oficina, con volúmenes comparables al uso normal de la nube corporativa.
- **`Low and slow`** — repartir la actividad por debajo de cualquier umbral, aceptando semanas de duración. Ataca directamente el supuesto de que un ataque es un pico.
- **`Living off the land`** — usar binarios y protocolos ya presentes y habituales en el entorno, para que no exista feature que distinga la actividad. Ver [[03 - Tipos de bypass y la cadena de evasión]].
- **Envenenamiento de la línea base** — el ataque de la rana hervida descrito arriba: desplazar la normalidad antes de actuar.

Conviene tener presente el otro lado: los detectores de anomalías conviven con detección basada en firmas y reglas, y en un entorno real las señales se correlacionan. Evadir el modelo estadístico no equivale a ser invisible — ver [[02 - Cómo se construye una detección]] y [[IDS-IPS]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la crítica operativa, el `concept drift` y las técnicas de evasión, ausentes en el original.
- [Sommer & Paxson, *Outside the Closed World: On Using Machine Learning for Network Intrusion Detection*, IEEE S&P 2010](https://www.icir.org/robin/papers/oakland10-ml.pdf) — límites del ML en detección de intrusiones (consultado 2026-07-28).
- Imagen de One-Class SVM: HTB Academy, módulo 290.
