---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Dos pasos, ambos geométricos: elegir la víctima y calcular el empujón"
Fecha de actualización: 2026-07-28
Nota previa: "[[05 - Clean label attacks]]"
Nota siguiente: "[[07 - Evaluación del clean label attack]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

Dos pasos, ambos geométricos: **elegir la víctima** y **calcular el empujón**. Toda la matemática del ataque cabe en esta nota.

# Paso 1 — Elegir el objetivo

El objetivo debe ser un punto que **realmente pertenezca a la clase 1** y que el modelo base clasifique **correctamente**, pero que esté **lo más cerca posible de la frontera** con la clase 0. La razón es directa: un punto pegado a la frontera necesita un desplazamiento mínimo para cambiar de lado, y un desplazamiento mínimo requiere perturbar menos vecinos.

## La función de decisión entre dos clases

En un `OneVsRest`, cada clase $k$ tiene sus propios parámetros $(\mathbf{w}_k, b_k)$ y produce una puntuación $z_k = \mathbf{w}_k^T\mathbf{x} + b_k$. La frontera entre las clases 0 y 1 está donde ambas puntuaciones se igualan, así que se define la **diferencia**:

$$f_{01}(\mathbf{x}) = z_0 - z_1 = (\mathbf{w}_0 - \mathbf{w}_1)^T \mathbf{x} + (b_0 - b_1)$$

Lectura de esa función, que es lo único que hay que retener:

- $f_{01}(\mathbf{x}) < 0$ → el punto está del lado de la **clase 1**.
- $f_{01}(\mathbf{x}) > 0$ → del lado de la **clase 0**.
- $f_{01}(\mathbf{x}) = 0$ → **exactamente en la frontera**.

<mark style="background: #ADCCFFA6;">Buscamos, entre los puntos de clase 1, el que tenga el valor negativo **más cercano a cero**</mark> — correctamente clasificado, pero al borde.

```python
# Vector e intercepto de la frontera 0-vs-1, del modelo base
w_diff_01_base = w0_base - w1_base
b_diff_01_base = b0_base - b1_base

# Solo los puntos de clase 1
class1_indices_train = np.where(y_train_3c == 1)[0]
X_class1_train = X_train_3c[class1_indices_train]

# f_01 para cada uno
decision_values_01 = X_class1_train @ w_diff_01_base + b_diff_01_base

# De los que están del lado correcto (f_01 < 0), el más cercano a 0
correct_side = np.where(decision_values_01 < 0)[0]
target_rel = correct_side[np.argmax(decision_values_01[correct_side])]
target_point_index_absolute = class1_indices_train[target_rel]

X_target = X_train_3c[target_point_index_absolute]
y_target = y_train_3c[target_point_index_absolute]
```

El `np.argmax` sobre valores negativos es el detalle que suele confundir: el máximo de un conjunto de números negativos es **el menos negativo**, es decir, el más próximo a cero. Exactamente el punto que queremos.

```text
--- Selecting Target Point ---
Boundary vector (w0-w1):    [-5.78792514  6.32142485]
Intercept difference (b0-b1): -0.9207223376477074
Found 350 Class 1 points in the training set.

Selected Target Point Index (absolute): 373
Target Point Features:                  [-0.55111155 -0.36675028]
Target Point True Label (y_target):     1
Target Point Baseline Prediction:       1
Target Point Baseline 0-vs-1 Decision Value (f_01): -0.0493
```

Un $f_{01}$ de **-0,0493** confirma la elección: bien clasificado, y a un pelo de la frontera.

> [!warning]+ En un ataque real el objetivo no se elige así
> Aquí se busca el punto más fácil de mover. En un escenario real el objetivo viene dado —*ese lote concreto de piezas*, *ese usuario concreto*, *esa transacción concreta*— y puede estar lejos de la frontera. <mark style="background: #FFB8EBA6;">Cuanto más lejos, más vecinos hay que perturbar y más agresivamente, y antes empiezan a parecer sospechosos.</mark> La distancia del objetivo a la frontera es, en la práctica, la métrica que decide si el ataque es viable con un presupuesto discreto.

# Paso 2 — Localizar los vecinos a perturbar

Los puntos que anclan la posición local de la frontera son los de la **clase contraria** más cercanos al objetivo. Se localizan con `NearestNeighbors` sobre el subconjunto de clase 0:

```python
from sklearn.neighbors import NearestNeighbors

n_neighbors_to_perturb = 5          # hiperparámetro del ataque

class0_indices_train = np.where(y_train_3c == 0)[0]
X_class0_train = X_train_3c[class0_indices_train]

nn_finder = NearestNeighbors(n_neighbors=n_neighbors_to_perturb, algorithm="auto")
nn_finder.fit(X_class0_train)
distances, indices_relative = nn_finder.kneighbors(X_target.reshape(1, -1))

neighbor_indices_absolute = class0_indices_train[indices_relative.flatten()]
X_neighbors = X_train_3c[neighbor_indices_absolute]
```

```text
Identified 5 closest Class 0 neighbors to perturb:
  Indices in X_train_3c: [ 761   82 1035  919  491]
  Distances to target:   [0.1031 0.1227 0.1491 0.2508 0.3016]
```

<mark style="background: #FF5582A6;">Cinco puntos sobre 1050 de entrenamiento: un **0,48 %** del dataset.</mark> Ese es el presupuesto de veneno de todo el ataque, y conviene compararlo con el 40 % que necesitaba el [[04 - Ataques dirigidos a una clase|ataque dirigido de etiquetas]].

`n_neighbors_to_perturb` es el parámetro que hay que calibrar: pocos vecinos hacen el ataque más sigiloso pero pueden no mover suficiente la frontera; muchos garantizan el efecto a costa de visibilidad y de daño colateral.

# Paso 3 — Calcular la perturbación

Hay que empujar cada vecino desde su lado ($f_{01} > 0$) hasta el otro ($f_{01} < 0$), y el camino más corto es **perpendicular a la frontera**.

El vector $\mathbf{v}_{01} = (\mathbf{w}_0 - \mathbf{w}_1)$ es precisamente el **vector normal** al hiperplano. Para ir del lado de la clase 0 al de la clase 1 hay que moverse en dirección **opuesta** a ese normal, normalizada a longitud unidad:

$$\mathbf{u}_{push} = \frac{-(\mathbf{w}_0 - \mathbf{w}_1)}{\|\mathbf{w}_0 - \mathbf{w}_1\|}$$

Y la perturbación es esa dirección escalada por una magnitud pequeña $\epsilon_{cross}$:

$$\delta_i = \epsilon_{\text{cross}} \times \mathbf{u}_{push} \qquad \mathbf{x}'_i = \mathbf{x}_i + \delta_i$$

```python
push_direction = -w_diff_01_base
unit_push_direction = push_direction / np.linalg.norm(push_direction)

epsilon_cross = 0.25
perturbation_vector = epsilon_cross * unit_push_direction
```

```text
Calculated unit push direction vector: [ 0.67529883 -0.73754423]
Perturbation magnitude (epsilon_cross): 0.25
Final perturbation vector (delta):      [ 0.16882471 -0.18438606]
```

> [!important]+ `epsilon_cross` es el compromiso central del ataque
> <mark style="background: #8000E1A6;">Demasiado pequeño y los vecinos no cruzan la frontera: no hay presión para que el modelo la mueva y el ataque falla. Demasiado grande y los puntos acaban en pleno territorio de la clase 1, donde la etiqueta 0 deja de ser plausible</mark> — y se pierde la propiedad "clean label" que da nombre a la técnica. Un revisor que vea una pieza de "defecto grave" con medidas idénticas a una aceptable, sospecha.
> El valor correcto es **el mínimo que cruce la frontera**, y por eso el código lo verifica muestra a muestra.

# Paso 4 — Aplicar y verificar

```python
X_train_poisoned = X_train_3c.copy()
y_train_poisoned = y_train_3c.copy()        # las etiquetas NO se tocan

for i, neighbor_idx in enumerate(neighbor_indices_absolute):
    X_perturbed = X_neighbors[i] + perturbation_vector
    X_train_poisoned[neighbor_idx] = X_perturbed
    # y_train_poisoned[neighbor_idx] sigue siendo 0

    # verificación: ¿cruzó la frontera?
    f01_orig = X_neighbors[i]  @ w_diff_01_base + b_diff_01_base   # esperado > 0
    f01_pert = X_perturbed     @ w_diff_01_base + b_diff_01_base   # esperado < 0
    if f01_pert >= 0:
        print("Warning: el punto no cruzó la frontera. epsilon demasiado pequeño.")
```

Tres comprobaciones que el código hace y que conviene replicar en cualquier implementación propia:

1. **El signo de $f_{01}$ cambia** para cada vecino perturbado. Si no, `epsilon` es insuficiente.
2. **El tamaño del dataset no cambia.** No se añaden ni se quitan muestras — solo se editan valores. Es lo que hace el ataque invisible a cualquier control de volumen.
3. **El objetivo no está entre los perturbados.** Si se modificara el propio objetivo, el resultado no demostraría nada.

![Conjunto de entrenamiento envenenado: el punto objetivo sigue en la clase 1 y los cinco vecinos de clase 0, con borde morado, han sido desplazados hacia la región de la clase 1](https://academy.hackthebox.com/storage/modules/302/feature_attack_perturbed.png)

Esa imagen es el ataque entero: cinco puntos azules dentro de la zona amarilla, conservando su etiqueta azul. Esa discrepancia visual es exactamente la presión que forzará al modelo a mover la frontera.
