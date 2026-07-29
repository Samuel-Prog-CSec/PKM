---
tags:
  - IA
  - IA/Pipeline
Descripción: "Dos librerías cubren casi todo lo que se hace en ML aplicado: scikit-learn para el ML clásico sobre datos tabulares y PyTorch para deep learning"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Entorno de trabajo para IA]]"
Nota siguiente: "[[02 - Datasets para seguridad]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

Dos librerías cubren casi todo lo que se hace en ML aplicado: <mark style="background: #ADCCFFA6;">`scikit-learn` para el ML clásico sobre datos tabulares y `PyTorch` para deep learning.</mark> No compiten — resuelven problemas distintos, y saber cuál toca es parte del criterio profesional.

| | `scikit-learn` | `PyTorch` |
| - | - | - |
| Dominio | ML clásico: regresión, árboles, SVM, clustering | Redes neuronales profundas |
| Datos típicos | Tabulares, texto vectorizado | Imagen, audio, texto, secuencias |
| GPU | No | Sí, es su razón de ser |
| Nivel de abstracción | Alto: `fit()` / `predict()` | Bajo: se escribe el bucle de entrenamiento |
| Cuándo usarlo | Casi siempre que los datos sean tabulares | Cuando hagan falta representaciones aprendidas |

# scikit-learn

Su gran acierto es una **API uniforme**: todos los modelos exponen la misma interfaz, así que cambiar de algoritmo es cambiar una línea.

```python
from sklearn.linear_model import LogisticRegression

model = LogisticRegression(C=1.0)
model.fit(X_train, y_train)          # entrenar
y_pred = model.predict(X_test)       # predecir
```

Esa consistencia es también lo que hace barato probar cinco modelos distintos antes de elegir — el flujo correcto, frente a comprometerse con uno por intuición.

## Preprocesado

**Escalado.** Imprescindible en todo lo basado en distancias o gradientes:

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
```

| Escalador | Qué hace | Cuándo |
| - | - | - |
| `StandardScaler` | Media 0, varianza 1 | Opción por defecto |
| `MinMaxScaler` | Reescala a un rango fijo, típicamente [0,1] | Cuando se necesita un rango acotado; sensible a outliers |
| `RobustScaler` | Usa mediana y rango intercuartílico | Cuando hay outliers, que en seguridad es siempre |

**Codificación de categóricas.** Los algoritmos operan sobre números:

```python
from sklearn.preprocessing import OneHotEncoder

encoder = OneHotEncoder()
X_encoded = encoder.fit_transform(X)
```

`OneHotEncoder` crea una columna binaria por categoría. `LabelEncoder` asigna un entero a cada una — <mark style="background: #FFB8EBA6;">y con features nominales eso es un error</mark>: introduce un orden inexistente que los modelos lineales y basados en distancia interpretan como magnitud. `LabelEncoder` es para la **variable objetivo**, no para las features.

**Valores ausentes:**

```python
from sklearn.impute import SimpleImputer

imputer = SimpleImputer(strategy='mean')
X_imputed = imputer.fit_transform(X)
```

> [!warning]+ `fit_transform` en train, `transform` en test
> Todos los transformadores tienen `fit` (calcular estadísticas) y `transform` (aplicarlas). <mark style="background: #FF5582A6;">Llamar a `fit_transform` sobre el conjunto completo antes de partir es `data leakage`</mark>: las estadísticas del test se filtran al entrenamiento y las métricas salen infladas. El patrón correcto es `fit_transform` sobre `train` y solo `transform` sobre `test`.
>
> La forma robusta de no equivocarse es encapsular todo en un `Pipeline` de `scikit-learn`, que aplica la disciplina automáticamente también dentro de la validación cruzada:
> ```python
> from sklearn.pipeline import Pipeline
> pipe = Pipeline([('scaler', StandardScaler()), ('clf', LogisticRegression())])
> pipe.fit(X_train, y_train)
> ```

## Selección y evaluación

```python
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import accuracy_score

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y)
scores = cross_val_score(model, X, y, cv=5)
accuracy = accuracy_score(y_test, y_pred)
```

`stratify=y` no está en la documentación introductoria y es crítico en seguridad: garantiza que la proporción de clases se conserve en ambas particiones. <mark style="background: #8000E1A6;">Sin él, con clases muy desbalanceadas, el conjunto de test puede quedarse casi sin ejemplos positivos</mark> y la métrica resultante no significa nada.

# PyTorch

## Tensores y grafo dinámico

Un `tensor` es un array multidimensional que puede vivir en GPU. El grafo de cómputo se construye **dinámicamente** durante el paso hacia delante, lo que permite estructuras condicionales y depuración con herramientas normales de Python.

```python
import torch

x = torch.tensor([1.0, 2.0, 3.0])
if torch.cuda.is_available():
    x = x.to('cuda')
```

`autograd` registra las operaciones y calcula los gradientes automáticamente. Es el mecanismo que hace posible `backpropagation`... <mark style="background: #FFB86CA6;">y también el que permite generar ejemplos adversariales</mark>: basta pedir el gradiente respecto a la entrada en vez de respecto a los parámetros, como se explica en [[00 - Deep learning y el perceptrón]].

## Definir un modelo

```python
import torch.nn as nn

model = nn.Sequential(
    nn.Linear(784, 128),
    nn.ReLU(),
    nn.Linear(128, 10),
)
```

Para arquitecturas no lineales, capas compartidas o múltiples entradas, se hereda de `nn.Module`:

```python
class CustomModel(nn.Module):
    def __init__(self):
        super().__init__()
        self.layer1 = nn.Linear(784, 128)
        self.relu = nn.ReLU()
        self.layer2 = nn.Linear(128, 10)

    def forward(self, x):
        return self.layer2(self.relu(self.layer1(x)))

model = CustomModel()
```

> [!info]+ No pongas `Softmax` en la última capa
> Es un error muy extendido y aparece en muchos tutoriales. `nn.CrossEntropyLoss` **ya aplica** `log_softmax` internamente sobre los `logits`. Añadir una capa `Softmax` explícita aplica la operación dos veces, lo que aplana los gradientes y degrada el entrenamiento de forma silenciosa — el modelo entrena, converge peor, y nada avisa. La regla: la red devuelve `logits` crudos y la función de pérdida se encarga del resto.

## Bucle de entrenamiento

```python
import torch.optim as optim

optimizer = optim.AdamW(model.parameters(), lr=0.001)
loss_fn = nn.CrossEntropyLoss()

for epoch in range(epochs):
    for x_batch, y_batch in dataloader:
        y_pred = model(x_batch)
        loss = loss_fn(y_pred, y_batch)

        optimizer.zero_grad()   # limpiar gradientes del paso anterior
        loss.backward()         # calcular gradientes
        optimizer.step()        # actualizar pesos
```

Olvidar `zero_grad()` hace que los gradientes se **acumulen** entre iteraciones — otro fallo silencioso clásico. Funciones de pérdida según tarea: `CrossEntropyLoss` (multiclase), `BCEWithLogitsLoss` (binaria), `MSELoss` (regresión).

## Datos

```python
from torch.utils.data import Dataset, DataLoader

class CustomDataset(Dataset):
    def __init__(self, data, labels):
        self.data, self.labels = data, labels

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        return self.data[idx], self.labels[idx]

dataloader = DataLoader(CustomDataset(data, labels), batch_size=32, shuffle=True)
```

## Guardar y cargar

```python
torch.save(model.state_dict(), 'model.pth')

model = CustomModel()
model.load_state_dict(torch.load('model.pth', weights_only=True))
model.eval()   # desactiva dropout y fija batch norm
```

Guardar el `state_dict` y no el objeto completo es la buena práctica, y además la segura: serializar el modelo entero con `pickle` arrastra el problema de deserialización descrito en [[01 - Redes neuronales]]. Olvidar `model.eval()` antes de evaluar deja `dropout` activo y produce predicciones aleatorias entre ejecuciones.

<mark style="background: #FF5582A6;">`weights_only=True` es explícito a propósito.</mark> Es el valor por defecto desde PyTorch 2.6, pero escribirlo documenta la intención y protege si el código se ejecuta con una versión anterior — donde `torch.load` deserializa con `pickle` y **ejecuta código arbitrario** contenido en el fichero. Para formatos de distribución, `safetensors` elimina el problema de raíz.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con `Pipeline` frente a `data leakage`, `stratify`, el error de `Softmax` duplicado y las advertencias de `zero_grad`/`eval`, ausentes en el original.
- Documentación oficial de [scikit-learn](https://scikit-learn.org/stable/) y [PyTorch](https://pytorch.org/docs/stable/index.html) (consultada 2026-07-28).
