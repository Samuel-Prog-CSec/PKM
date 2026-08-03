---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "El label flipping invierte la etiqueta de una fracción de las muestras de entrenamiento, dejando las características intactas"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Taxonomía de los ataques a los datos]]"
Nota siguiente: "[[03 - Evaluación del label flipping]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

<mark style="background: #ADCCFFA6;">El `label flipping` invierte la etiqueta de una fracción de las muestras de entrenamiento, dejando las características intactas.</mark> Es el ataque de envenenamiento más simple que existe y sirve de base conceptual para todos los demás: el modelo aprende a asociar unos valores de entrada con la clase equivocada, y ajusta su frontera de decisión para acomodar esa contradicción.

No requiere entender el modelo, ni calcular gradientes, ni acceso a los pesos. Solo capacidad de escribir etiquetas — que en la práctica significa control sobre la anotación, sobre el almacenamiento, o sobre el código de procesado que las asigna ([[01 - Taxonomía de los ataques a los datos|el vector del sentiment analysis comprometido]]).

# El escenario

Análisis de sentimiento binario: `Class 0` = negativo, `Class 1` = positivo. Dataset sintético de dos cúmulos bien separados y una regresión logística encima.

```python
import numpy as np
from sklearn.datasets import make_blobs
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

SEED = 1337
np.random.seed(SEED)

X, y = make_blobs(
    n_samples=1000,
    centers=[(0, 5), (5, 0)],
    n_features=2,
    cluster_std=1.25,
    random_state=SEED,
)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=SEED)
```

> [!important]+ Lo que este dataset representa y lo que oculta
> Dos cúmulos separados en dos dimensiones es el caso más favorable posible para el clasificador: hay una recta que los separa casi perfectamente. <mark style="background: #FFB8EBA6;">Esa comodidad hace que el ataque parezca menos efectivo de lo que es en datos reales</mark>, y es la advertencia que hay que llevarse antes de leer los resultados de [[03 - Evaluación del label flipping]]. Los datos de producción son ruidosos, se solapan y viven en cientos de dimensiones — ahí, el mismo desplazamiento de frontera sí cuesta precisión.

# La línea base

```python
baseline_model = LogisticRegression(random_state=SEED)
baseline_model.fit(X_train, y_train)

y_pred = baseline_model.predict(X_test)
baseline_accuracy = accuracy_score(y_test, y_pred)
print(f"Baseline Model Accuracy: {baseline_accuracy:.4f}")   # 0.9933
```

**Precisión de referencia: 0,9933.** Todo lo que venga después se mide contra ese número, y siempre sobre el **conjunto de test limpio** — nunca sobre datos envenenados. Es el detalle metodológico que hace que la evaluación signifique algo: queremos saber cómo se comporta el modelo corrompido frente a datos legítimos que verá en producción.

# La implementación del ataque

```python
def flip_labels(y, poison_percentage):
    if not 0 <= poison_percentage <= 1:
        raise ValueError("poison_percentage must be between 0 and 1.")

    n_samples = len(y)
    n_to_flip = int(n_samples * poison_percentage)
    if n_to_flip == 0:
        return y.copy(), np.array([], dtype=int)

    rng = np.random.default_rng(SEED)
    flipped_indices = rng.choice(n_samples, size=n_to_flip, replace=False)

    y_poisoned = y.copy()
    original = y_poisoned[flipped_indices]
    y_poisoned[flipped_indices] = np.where(original == 0, 1, 0)

    return y_poisoned, flipped_indices
```

Quince líneas. Tres detalles que merecen atención:

- **`replace=False`** — se eligen índices únicos. Sin esto, un mismo índice podría salir dos veces y el presupuesto de envenenamiento real sería menor que el declarado.
- **`y.copy()`** — no se toca el array original, para poder comparar después qué se cambió.
- **La semilla fija** — imprescindible para reproducir el experimento. En un ataque real es lo contrario de lo que quieres: la selección debe parecer aleatoria y no correlacionar entre lotes.

Y el ataque se ejecuta con los **valores originales** y solo las etiquetas corrompidas:

```python
poisoned_model = LogisticRegression(random_state=SEED)
poisoned_model.fit(X_train, y_train_poisoned)   # X original, y envenenada
```

# Por qué el modelo se deja

La regresión logística minimiza la **entropía cruzada binaria** (`log-loss`):

$$L(\mathbf{w}, b) = -\frac{1}{N} \sum_{i=1}^{N} \left[ y_i \log(p_i) + (1 - y_i) \log(1 - p_i) \right]$$

donde $p_i = \sigma(\mathbf{w}^T \mathbf{x}_i + b)$ es la probabilidad predicha de que la muestra pertenezca a la clase 1.

<mark style="background: #8000E1A6;">La clave está en cómo se comporta esa función cuando la etiqueta miente.</mark> Tomemos una muestra que claramente pertenece a la clase 1 y a la que hemos puesto etiqueta 0:

- El modelo, mirando las características, calcula un $p_i$ **alto** (cerca de 1).
- Con la etiqueta original ($y_i = 1$), la pérdida sería $-\log(p_i)$ — un valor **pequeño**, porque acierta.
- Con la etiqueta invertida ($y_i = 0$), la pérdida es $-\log(1 - p_i)$. Como $p_i$ está cerca de 1, el término $(1 - p_i)$ está cerca de 0, y su logaritmo negativo es **un valor enorme**.

Ese error artificialmente grande produce **gradientes grandes** durante la optimización. El modelo se ve obligado a ajustar $\mathbf{w}$ y $b$ para reducirlo, y ese ajuste empuja la frontera de decisión $\mathbf{w}^T\mathbf{x} + b = 0$.

<mark style="background: #FF5582A6;">La consecuencia ofensiva es contraintuitiva y es la más importante de esta nota: las muestras que más daño hacen son las que el modelo clasificaría con **más confianza**.</mark> Una muestra ambigua, cerca de la frontera, produce un gradiente pequeño y casi no mueve nada. Una muestra inequívoca, en el centro de su cúmulo, con la etiqueta invertida, es la que arrastra la frontera.

Eso tiene dos implicaciones prácticas:

1. **El envenenamiento aleatorio desperdicia presupuesto.** Elegir muestras al azar significa gastar buena parte del esfuerzo en puntos que apenas mueven la frontera. Es el argumento directo para el [[04 - Ataques dirigidos a una clase|ataque dirigido]].
2. **Para el defensor, esas mismas muestras son las más fáciles de encontrar.** Un punto con etiqueta muy improbable dada su posición es exactamente lo que detecta un análisis de pérdida por muestra — ver [[14 - Detección y evasión en ataques a los datos]].

# De dónde sale la capacidad de invertir etiquetas

En un sistema real el atacante rara vez edita un array de NumPy. Las vías reales, en orden de accesibilidad:

| Vía | Requiere | Detectabilidad |
| - | - | - |
| **Etiquetado por feedback de usuario** (valoraciones, "útil / no útil", reportes) | Solo ser usuario | Muy baja — es el uso previsto |
| **Etiquetado por heurística** (un script asigna sentimiento a partir de la puntuación de la reseña) | Manipular la señal de la que depende la heurística | Baja |
| **Comprometer el código de procesado** | Acceso al repositorio o a la configuración de trabajos | Baja — los datos crudos siguen limpios |
| **Escritura en el dataset almacenado** | Acceso al almacenamiento | Media — hay logs de acceso |
| **Anotación humana externalizada** | Acceso al proveedor de anotación | Media |

<mark style="background: #FFB86CA6;">La primera fila es la que hay que buscar primero en un engagement</mark>: cualquier sistema que aprenda de las correcciones o valoraciones de sus usuarios está aceptando etiquetas de un canal no confiable por diseño, y suele ser la superficie que nadie clasificó como tal.
