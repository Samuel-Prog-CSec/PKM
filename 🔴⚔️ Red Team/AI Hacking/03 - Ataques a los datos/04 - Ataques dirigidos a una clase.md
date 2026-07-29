---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "El label flipping aleatorio busca degradación general y la consigue mal"
Fecha de actualización: 2026-07-28
Nota previa: "[[03 - Evaluación del label flipping]]"
Nota siguiente: "[[05 - Clean label attacks]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

El [[03 - Evaluación del label flipping|label flipping aleatorio]] busca degradación general y la consigue mal. <mark style="background: #ADCCFFA6;">El `targeted label attack` persigue algo más útil: que el modelo clasifique mal **instancias concretas o una clase concreta**, de forma predecible.</mark>

Mismo escenario de análisis de sentimiento, objetivo distinto: en lugar de hacer el modelo peor en general, conseguir que clasifique como **negativas** las reseñas genuinamente **positivas** de un producto.

# La estrategia

En vez de elegir muestras al azar de todo el dataset, se eligen **solo dentro de la clase objetivo** y se invierten todas en la misma dirección.

Ese cambio elimina precisamente el mecanismo que hacía inofensivo el ataque aleatorio. Antes, cada punto de la clase 0 marcado como 1 se compensaba estadísticamente con uno de la clase 1 marcado como 0, y la frontera se quedaba donde estaba. <mark style="background: #8000E1A6;">Al concentrar todo el veneno en una dirección, los errores dejan de cancelarse y se **suman**.</mark>

## Lo que ocurre en la función de pérdida

Retomando la [[02 - Label flipping#Por qué el modelo se deja|entropía cruzada]]: el adversario toma muestras $(\mathbf{x}_j, y_j)$ cuya etiqueta real es $y_j = 1$ y las cambia a $y'_j = 0$.

Durante el entrenamiento, el modelo mira las características de $\mathbf{x}_j$ —que apuntan claramente a la clase 1— y calcula una probabilidad $p_j$ alta:

- Con la etiqueta original, la pérdida sería $-\log(p_j)$, **pequeña**.
- Con la etiqueta invertida, es $-\log(1 - p_j)$. Como $p_j$ está cerca de 1, $(1-p_j)$ está cerca de 0 y el término se dispara a **un valor muy grande**.

Ese error grande genera gradientes grandes que fuerzan a ajustar $\mathbf{w}$ y $b$. Y como **todas** las muestras envenenadas empujan en la misma dirección, la frontera $\mathbf{w}^T\mathbf{x} + b = 0$ se desplaza sistemáticamente hacia el territorio de la clase 1, haciendo que más región de la clase 1 se clasifique como clase 0.

<mark style="background: #FFB86CA6;">El sesgo resultante es exactamente el que el atacante quería, y es reproducible.</mark>

# La implementación

```python
def targeted_flip_labels(y, poison_percentage, target_class, new_class, seed=1337):
    if not 0 <= poison_percentage <= 1:
        raise ValueError("poison_percentage must be between 0 and 1.")
    if target_class == new_class:
        raise ValueError("target_class and new_class cannot be the same.")

    # Solo los índices de la clase objetivo
    target_indices = np.where(y == target_class)[0]
    n_target_samples = len(target_indices)
    if n_target_samples == 0:
        return y.copy(), np.array([], dtype=int)

    # El porcentaje se aplica al tamaño de la CLASE, no del dataset
    n_to_flip = int(n_target_samples * poison_percentage)
    if n_to_flip == 0:
        return y.copy(), np.array([], dtype=int)

    rng = np.random.default_rng(seed)
    sel = rng.choice(n_target_samples, size=n_to_flip, replace=False)
    flipped_indices = target_indices[sel]          # mapear al índice global

    y_poisoned = y.copy()
    y_poisoned[flipped_indices] = new_class        # todas a la MISMA clase
    return y_poisoned, flipped_indices
```

Dos diferencias respecto a `flip_labels`, y ambas importan:

- **El porcentaje se calcula sobre el tamaño de la clase objetivo**, no del dataset. Un 40 % dirigido sobre una clase que es la mitad del dataset es un 20 % del total — la mitad de veneno que en el experimento aleatorio.
- **La asignación es fija** (`= new_class`), no una inversión condicional. Todas las muestras van en la misma dirección; ahí está todo el efecto.

Ejecución:

```python
y_train_targeted_poisoned, targeted_flipped_indices = targeted_flip_labels(
    y_train,
    poison_percentage=0.40,   # 40 % de la clase 1
    target_class=1,           # positivo
    new_class=0,              # marcado como negativo
    seed=SEED,
)

targeted_poisoned_model = LogisticRegression(random_state=SEED)
targeted_poisoned_model.fit(X_train, y_train_targeted_poisoned)
```

# El resultado

```text
Accuracy on clean test set:  0.8100
Baseline accuracy was:       0.9933

Classification Report on Clean Test Set:
              precision    recall  f1-score   support
     Class 0       0.73      1.00      0.84       153
     Class 1       1.00      0.61      0.76       147
    accuracy                           0.81       300
```

Los tres números que cuentan la historia:

| Métrica | Valor | Lectura |
| - | - | - |
| Precisión global | 0,9933 → **0,8100** | Caída clara, a diferencia del ataque aleatorio |
| **Recall de la clase 1** | **0,61** | El modelo solo reconoce el 61 % de las reseñas positivas reales |
| Precisión de la clase 1 | **1,00** | Cuando dice "positivo", **acierta siempre** |

<mark style="background: #FF5582A6;">Esa combinación —recall hundido, precisión perfecta— es la firma característica de un ataque dirigido, y es la señal que hay que buscar como defensor.</mark> El modelo se ha vuelto extremadamente conservador para la clase 1: solo la predice cuando la evidencia es abrumadora, y en la duda dice clase 0. Exactamente el sesgo que el atacante pidió.

La matriz de confusión lo confirma: **57 falsos negativos** (positivos reales clasificados como negativos) de 147, y **cero falsos positivos**.

![Comparación de la frontera de decisión base frente a la del modelo envenenado dirigido, mostrando el desplazamiento hacia el territorio de la clase 1](https://academy.hackthebox.com/storage/modules/302/targeted_flip_baseline_vs_poisoned_boundary.png)

Y sobre datos **nuevos** generados con la misma distribución, el efecto persiste: los puntos de la clase 1 que caen en el lado desplazado de la frontera se clasifican mal. <mark style="background: #8000E1A6;">El sesgo no está en el conjunto de entrenamiento: está en el modelo, y lo aplica a todo lo que ve a partir de ahora.</mark>

# Dirigido frente a aleatorio

| | Aleatorio | Dirigido |
| - | - | - |
| Veneno usado | 40 % del **dataset** | 40 % de **una clase** ≈ 20 % del dataset |
| Precisión resultante | ~0,99 (sin cambio) | **0,81** |
| Efecto | Ninguno observable | Recall de la clase objetivo a 0,61 |
| Predecibilidad | Ninguna | Total — el atacante elige la dirección del fallo |

Con **la mitad de veneno**, un efecto que el otro no consigue ni de lejos. Esa es la lección transferible: <mark style="background: #FFB8EBA6;">en envenenamiento, la dirección importa mucho más que el volumen.</mark>

# Qué se consigue en el mundo real

El escenario del lab suena académico; sus equivalentes no lo son:

- **Moderación de contenido** — hacer que el clasificador etiquete como benigno cierto tipo de contenido abusivo. Recall hundido en la clase "abusivo" = contenido que pasa.
- **Detección de fraude** — que las transacciones con determinado patrón se clasifiquen como legítimas.
- **Filtrado de spam / phishing** — que los correos con cierta firma pasen el filtro. Es el mismo objetivo que el [[08 - Límites y evasión de los detectores ML|clasificador de spam]], atacado en entrenamiento en vez de en inferencia.
- **Cribado de currículums o proveedores** — sesgar sistemáticamente contra un perfil. Con impacto legal directo, además: en la UE es un sistema de **alto riesgo** bajo el [[14 - Marco regulatorio del contenido generado por IA|AI Act]].
- **Detección de intrusiones** — que el tráfico de una herramienta concreta se clasifique como normal, que es el ejemplo del propio path COAE en [[04 - Detección de anomalías de red con Random Forest]].

# Cómo se detecta

La recomendación defensiva que sale de aquí, y que es distinta de la del ataque aleatorio:

- **Métricas por clase en cada reentrenamiento**, comparadas contra la versión anterior. Una caída de recall en una sola clase con precisión estable es el indicador directo.
- **Matriz de confusión versionada.** Un patrón asimétrico de errores —muchos falsos negativos en una clase, ninguno en la otra— no ocurre por deriva natural de los datos.
- **Conjunto canario por clase**: muestras fijas y verificadas de cada clase, evaluadas automáticamente tras cada entrenamiento. Es lo único que detecta el ataque antes de que llegue a producción.
- **Análisis de pérdida por muestra** sobre el conjunto de entrenamiento: las muestras envenenadas son, por construcción, las que más pérdida generan. Detalle en [[14 - Detección y evasión en ataques a los datos]].
