---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
Descripción: "Pipeline encadena vectorización y clasificación en un único objeto, garantizando que la misma transformación se aplique siempre antes del modelo — y, crucialmente, que dentro de…"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Preprocesamiento de texto y extracción de features]]"
Nota siguiente: "[[04 - Detección de anomalías de red con Random Forest]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

# Pipeline y búsqueda de hiperparámetros

`Pipeline` encadena vectorización y clasificación en un único objeto, garantizando que la misma transformación se aplique siempre antes del modelo — y, crucialmente, que dentro de la validación cruzada el vectorizador **se reajuste en cada partición** en vez de haber visto todos los datos.

```python
from sklearn.model_selection import GridSearchCV
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

pipeline = Pipeline([
    ("vectorizer", vectorizer),
    ("classifier", MultinomialNB())
])

param_grid = {
    "classifier__alpha": [0.01, 0.1, 0.15, 0.2, 0.25, 0.5, 0.75, 1.0]
}

grid_search = GridSearchCV(pipeline, param_grid, cv=5, scoring="f1")
grid_search.fit(df["message"], y)

best_model = grid_search.best_estimator_
print("Mejores parámetros:", grid_search.best_params_)
```

<mark style="background: #ADCCFFA6;">`alpha` es el suavizado de Laplace descrito en [[06 - Naive Bayes]]</mark>: la constante que se suma a todos los conteos para que una palabra nunca vista no anule la probabilidad de una clase entera. Valores bajos hacen al modelo más sensible a términos raros; valores altos lo suavizan y lo hacen más conservador.

Es el hiperparámetro principal, pero **no el único que importa**: `fit_prior` decide si el modelo aprende los priors de clase de los datos (`True`, por defecto) o asume clases equiprobables (`False`). <mark style="background: #FFB8EBA6;">Con un corpus desbalanceado esa elección desplaza todas las decisiones del clasificador</mark> — es literalmente el `P(Spam)` del cálculo de [[01 - Clasificación de spam con Naive Bayes]], y ponerlo uniforme equivale a afirmar que la mitad del correo es spam. La rejilla de búsqueda debería incluirlo junto a `alpha`.

Se optimiza sobre `F1` y no sobre `accuracy`, por el desbalance del corpus — la razón está en [[05 - Métricas de evaluación de modelos]].

> [!warning]+ Fallo metodológico del código original: no hay conjunto de test
> `grid_search.fit(df["message"], y)` ajusta sobre **el dataset completo**. La única estimación de rendimiento disponible es la de la validación cruzada, y esa validación se usó para **elegir** `alpha` — así que está optimizada, no es ciega.
>
> <mark style="background: #FF5582A6;">No queda ningún conjunto que el proceso de selección no haya visto</mark>, y por tanto no hay estimación honesta de generalización. La corrección es separar un test antes de nada:
> ```python
> X_tr, X_te, y_tr, y_te = train_test_split(
>     df["message"], y, test_size=0.2, stratify=y, random_state=1337)
> grid_search.fit(X_tr, y_tr)
> print(classification_report(y_te, grid_search.predict(X_te)))
> ```
> Que el resultado siga siendo bueno no valida el método: lo valida el método, no el resultado.

# Evaluación sobre mensajes nuevos

El preprocesado en inferencia debe replicar **exactamente** el de entrenamiento. Cualquier divergencia produce vectores que no significan lo mismo:

```python
def preprocess_message(message):
    message = message.lower()
    message = re.sub(r"[^a-z\s$!]", "", message)
    tokens = word_tokenize(message)
    tokens = [w for w in tokens if w not in stop_words]
    tokens = [stemmer.stem(w) for w in tokens]
    return " ".join(tokens)

processed = [preprocess_message(m) for m in new_messages]
X_new = best_model.named_steps["vectorizer"].transform(processed)

predictions  = best_model.named_steps["classifier"].predict(X_new)
probabilities = best_model.named_steps["classifier"].predict_proba(X_new)
```

<mark style="background: #FFB8EBA6;">Duplicar la lógica de preprocesado entre entrenamiento e inferencia es una fuente clásica de `training-serving skew`.</mark> Lo robusto es meter el preprocesado dentro del propio `Pipeline` con un `FunctionTransformer`, de forma que exista en un solo sitio y viaje con el modelo.

`predict_proba` devuelve la probabilidad de cada clase, no solo la etiqueta. Es lo que permite ajustar el umbral en función del coste operativo en vez de aceptar el 0,5 por defecto.

Matriz de confusión reportada por el módulo sobre el corpus:

| | Predicho ham | Predicho spam |
| - | - | - |
| **Real ham** | 889 | 5 |
| **Real spam** | 0 | 140 |

Cero falsos negativos y cinco falsos positivos. <mark style="background: #8000E1A6;">Sobre un corpus de 2011, con mensajes de 2011, y sin conjunto de test independiente</mark> — es el resultado esperable y no dice nada sobre el comportamiento frente a spam actual, y mucho menos frente a spam diseñado para evadirlo.

# Serialización del modelo

```python
import joblib

joblib.dump(best_model, "spam_detection_model.joblib")

# ⚠ joblib.load() deserializa con pickle -> ejecuta código arbitrario.
# Solo sobre artefactos propios y verificados; NUNCA sobre ficheros de terceros.
loaded_model = joblib.load("spam_detection_model.joblib")
```

`joblib` serializa el pipeline completo —vectorizador, vocabulario y parámetros aprendidos— y evita reentrenar en cada arranque.

> [!important]+ `joblib` es `pickle`, y eso convierte la carga de modelos en un sumidero de RCE
> <mark style="background: #FFB86CA6;">`joblib.load()` deserializa con `pickle`, que ejecuta código durante la carga por diseño.</mark> Cargar un `.joblib` de origen no confiable es ejecución de código arbitrario, exactamente igual que los `.pt` descritos en [[01 - Redes neuronales]] — con el agravante de que `joblib` **no tiene** un equivalente a `weights_only=True`.
>
> El módulo propone subir el modelo a un portal de evaluación:
> ```python
> with open("spam_detection_model.joblib", "rb") as f:
>     response = requests.post(url, files={"model": f})
> ```
> Ese patrón —un endpoint que recibe un fichero de modelo y lo deserializa para evaluarlo— es una **vulnerabilidad crítica** cuando aparece en una aplicación real, y aparece: plataformas de MLOps, servicios de *model registry*, portales de competición y funcionalidades de "sube tu modelo". El servidor deserializa un artefacto que controla íntegramente un usuario.
>
> <mark style="background: #FF5582A6;">En un engagement, un endpoint de subida de modelos es un objetivo de máxima prioridad</mark>, y debe reportarse como deserialización insegura con impacto de RCE, no como un problema de "validación de ficheros".
>
> Mitigaciones: no deserializar artefactos no confiables; usar formatos sin capacidad de ejecución (`safetensors` para pesos, ONNX con validación); si hay que cargar, hacerlo en un sandbox aislado sin red ni credenciales; y firmar y verificar los modelos internos.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, con corrección del método de evaluación (ausencia de conjunto de test), y ampliado con `training-serving skew` y el análisis de `joblib`/`pickle` como sumidero de deserialización, ausentes en el original.
- Relación `alpha` ↔ suavizado de Laplace y umbral ↔ coste operativo desarrolladas en [[06 - Naive Bayes]] y [[05 - Métricas de evaluación de modelos]].
