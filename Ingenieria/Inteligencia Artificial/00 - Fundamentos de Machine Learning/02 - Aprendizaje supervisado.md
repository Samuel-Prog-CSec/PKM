---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "En supervised learning cada ejemplo de entrenamiento viene con su respuesta correcta"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Matemáticas para machine learning]]"
Nota siguiente: "[[03 - Regresión lineal]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">En `supervised learning` cada ejemplo de entrenamiento viene con su respuesta correcta.</mark> El algoritmo recibe pares (entrada, etiqueta) y aprende una función que mapea una a otra, ajustando sus parámetros hasta minimizar la diferencia entre lo que predice y lo que debería predecir. Es el paradigma detrás de prácticamente todo el ML que se despliega en seguridad: clasificadores de spam, detectores de malware, motores de scoring de fraude.

Se divide en dos problemas según qué tipo de valor se predice:

- **`Classification`** — la salida es una categoría discreta. ¿Es spam o no? ¿Este binario es benigno, ransomware o troyano?
- **`Regression`** — la salida es un valor continuo. ¿Cuánto va a costar esta casa? ¿Cuántas peticiones va a recibir el servicio la próxima hora?

# Vocabulario que hay que tener claro

| Término | Qué es |
| - | - |
| `Training data` | El dataset etiquetado del que aprende el modelo. Su calidad y cantidad determinan el techo de rendimiento |
| `Features` | Las variables medibles que se le pasan al modelo como entrada |
| `Labels` | La respuesta correcta asociada a cada ejemplo — el objetivo a predecir |
| `Model` | La función matemática aprendida que transforma features en predicción |
| `Training` | El proceso iterativo de ajustar parámetros para reducir el error |
| `Prediction` | Aplicar el modelo entrenado a un dato nuevo y obtener una salida accionable |
| `Inference` | Concepto más amplio: usar el modelo para extraer conocimiento — qué features pesan, qué relaciones existen |
| `Generalization` | La capacidad de acertar sobre datos que **no** se vieron durante el entrenamiento |

La distinción entre `prediction` e `inference` no es cosmética. <mark style="background: #FF5582A6;">La capacidad de hacer inferencia sobre un modelo ajeno es en sí misma un ataque</mark>: determinar qué features pesan más permite construir evasiones dirigidas —el sondeo demostrado en [[02 - Manipulación del modelo]]— y determinar si un registro concreto estuvo en el entrenamiento es una violación de privacidad (`membership inference`, el `ML04` de [[01 - OWASP Machine Learning Security Top 10]]).

# El problema central: generalizar, no memorizar

Todo el aprendizaje supervisado se juega entre dos fallos simétricos.

- **`Underfitting`** — el modelo es demasiado simple para capturar el patrón. Falla en entrenamiento y en producción por igual. Se detecta rápido y se corrige con más capacidad o mejores features.
- **`Overfitting`** — el modelo aprende el ruido y las particularidades del conjunto de entrenamiento en vez del patrón subyacente. <mark style="background: #FFB8EBA6;">Rinde de forma excelente en los datos que ya vio y se hunde con datos nuevos.</mark>

Son los dos extremos de la descomposición sesgo-varianza descrita en [[01 - Matemáticas para machine learning]]: subajuste es sesgo alto, sobreajuste es varianza alta.

> [!important]+ El sobreajuste es un problema de privacidad, no solo de precisión
> Un modelo sobreajustado ha **memorizado** parte de su conjunto de entrenamiento. Eso lo hace vulnerable a `membership inference` —determinar si un registro concreto estuvo en el entrenamiento— y, en modelos generativos, a extracción literal de datos de entrenamiento, como se detalla en [[05 - IA generativa]]. <mark style="background: #8000E1A6;">La medida más eficaz contra ambos ataques es la misma que contra el sobreajuste</mark>: regularización, más datos y menos épocas.
>
> <mark style="background: #FFB8EBA6;">Con un matiz importante que suele omitirse</mark>: "generalizar bien" y "no memorizar" **no** son equivalentes. Sobre distribuciones con cola larga —y las de seguridad lo son: familias de malware raras, ataques poco frecuentes— hay evidencia de que memorizar los ejemplos atípicos es **necesario** para acertar en ellos. Un modelo que no memoriza nada falla justamente en los casos raros, que son los que importan.
>
> La consecuencia operativa es que reducir el sobreajuste mitiga la fuga pero **no la elimina**, y que existe una tensión real entre rendimiento en la cola y privacidad. Cuando el requisito de privacidad es duro, la respuesta no es tunear la regularización sino usar privacidad diferencial y aceptar el coste en precisión.

## Cómo se combate

**Separación de conjuntos.** El dataset se parte en tres: `train` para ajustar parámetros, `validation` para elegir hiperparámetros y arquitectura, `test` para la estimación final — y el conjunto de test **se toca una sola vez**. Reutilizarlo para tomar decisiones lo convierte de facto en un conjunto de validación y la métrica final deja de ser honesta.

**`Cross-validation`.** En vez de una única partición, se divide el dataset en `k` particiones y se entrena `k` veces, dejando cada vez una fuera como validación. Da una estimación de rendimiento mucho más estable y aprovecha todo el dato, a coste de `k` veces más cómputo. En seguridad, siempre en su variante **estratificada** —que conserva la proporción de clases en cada partición— y **nunca** con datos temporales, donde hay que usar validación cruzada con ventana deslizante hacia delante. Ambos matices, en [[04 - Transformación de datos]].

**`Regularization`.** Añadir a la función de pérdida un término que penaliza la complejidad del modelo:

- `L1` (Lasso) — penaliza la suma de los valores absolutos de los coeficientes. Empuja coeficientes **exactamente a cero**, haciendo selección de features de forma implícita.
- `L2` (Ridge) — penaliza la suma de los cuadrados. Encoge todos los coeficientes hacia cero sin anularlos, repartiendo el peso entre features correlacionadas.

Son las mismas normas de [[01 - Matemáticas para machine learning]] aplicadas a los parámetros en vez de a la perturbación.

# Fallos que las guías introductorias no cuentan

Estos dos son la causa real de la mayoría de modelos que lucen espectaculares en el informe y decepcionan en producción. Cualquier evaluación de un producto de seguridad basado en ML debería empezar por descartarlos.

## Fuga de datos (`data leakage`)

Ocurre cuando información que no estará disponible en el momento de la predicción se cuela en el entrenamiento. <mark style="background: #FFB86CA6;">Produce métricas casi perfectas que se desploman en cuanto el modelo toca datos reales.</mark> Formas típicas en datasets de seguridad:

- Normalizar o escalar **antes** de partir en train/test, con lo que las estadísticas del test contaminan el entrenamiento.
- Datos duplicados o casi idénticos repartidos entre train y test — endémico en datasets de malware, donde variantes de la misma familia comparten casi todo el binario.
- Particiones aleatorias sobre datos temporales, que dejan al modelo entrenar con el futuro y predecir el pasado.
- Features derivadas de la etiqueta: un campo `alert_id` que solo existe cuando ya se detectó el ataque.

> [!warning]+ Señal de alarma en un informe de producto
> Un `accuracy` del 99,9% sobre un problema de seguridad rara vez significa que el modelo sea bueno. Casi siempre significa fuga de datos, desbalanceo mal medido, o ambas. Pide siempre la matriz de confusión y la partición usada.

## Desbalanceo de clases

En seguridad las clases positivas son raras: el tráfico malicioso es una fracción mínima del total. <mark style="background: #FF5582A6;">Un modelo que responda siempre "benigno" sobre un dataset con 0,1% de ataques acierta el 99,9% de las veces y no detecta absolutamente nada.</mark> Por eso `accuracy` es una métrica inútil en este dominio y hay que trabajar con precisión, recall y las curvas PR — detalle en [[05 - Métricas de evaluación de modelos]].

# El ángulo ofensivo del pipeline supervisado

Cada elemento del vocabulario de arriba es un punto de entrada:

- <mark style="background: #FFB86CA6;">Las **etiquetas** suelen provenir de usuarios.</mark> Cuando alguien marca un correo como spam o reporta un fichero como malicioso, está escribiendo en el conjunto de entrenamiento del siguiente ciclo de reentrenamiento. Es el vector de `label poisoning` más barato que existe y no requiere ningún acceso privilegiado — demostrado sobre un clasificador real en [[02 - Manipulación del modelo]].
- Los **datos de entrenamiento** de modelos públicos se recolectan a escala web, sin curación viable. Envenenar una fracción muy pequeña basta para implantar un `backdoor`, con los mecanismos de [[02 - Datasets para seguridad]].
- El **modelo** entrenado, si es accesible por API, puede reconstruirse consultándolo de forma sistemática (`model extraction`), convirtiendo un objetivo `black-box` en `white-box`. Ver [[07 - Ataques a los componentes del modelo]].
- La **evaluación** define qué se considera aceptable. Un umbral de decisión mal calibrado es, en la práctica, un control de seguridad mal configurado — el argumento de [[04 - Regresión logística]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con los modos de fallo (`data leakage`, desbalanceo) y el encuadre ofensivo, ausentes en el original.
- Relación sobreajuste ↔ `membership inference` según la taxonomía de ataques de privacidad del [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final) (consultado 2026-07-28).
