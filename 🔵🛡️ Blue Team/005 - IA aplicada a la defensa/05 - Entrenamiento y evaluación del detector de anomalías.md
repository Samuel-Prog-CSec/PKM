---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
Descripción: "Dos ausencias notables frente al clasificador de spam: aquí no hay búsqueda de hiperparámetros —se usan los valores por defecto— y no se trata el desbalance de clases"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Detección de anomalías de red con Random Forest]]"
Nota siguiente: "[[06 - Clasificación de malware por byteplots]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

# Entrenamiento

```python
from sklearn.ensemble import RandomForestClassifier

rf_model_multi = RandomForestClassifier(random_state=1337)
rf_model_multi.fit(multi_train_X, multi_train_y)
```

Dos ausencias notables frente al clasificador de spam: aquí **no hay búsqueda de hiperparámetros** —se usan los valores por defecto— y **no se trata el desbalance de clases**. Ambas cosas se corrigen sin esfuerzo:

```python
rf_model_multi = RandomForestClassifier(
    n_estimators=300,
    class_weight='balanced_subsample',   # compensa el desbalance entre familias
    n_jobs=-1,
    random_state=1337,
)
```

<mark style="background: #FFB8EBA6;">`class_weight='balanced_subsample'` pondera cada clase inversamente a su frecuencia</mark>, evitando que las clases con decenas de muestras (`Privilege`) sean sacrificadas para acertar en las que tienen decenas de miles (`Normal`, `DoS`).

# Evaluación

```python
from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                             f1_score, confusion_matrix, classification_report)

multi_predictions = rf_model_multi.predict(multi_val_X)

accuracy  = accuracy_score(multi_val_y, multi_predictions)
precision = precision_score(multi_val_y, multi_predictions, average='weighted')
recall    = recall_score(multi_val_y, multi_predictions, average='weighted')
f1        = f1_score(multi_val_y, multi_predictions, average='weighted')

conf_matrix = confusion_matrix(multi_val_y, multi_predictions)
class_labels = ['Normal', 'DoS', 'Probe', 'Privilege', 'Access']

print(classification_report(multi_val_y, multi_predictions, target_names=class_labels))
```

> [!warning]+ `average='weighted'` esconde exactamente lo que hay que mirar
> Es la corrección más importante de esta nota. El promedio **ponderado** pesa la métrica de cada clase por su número de muestras, así que <mark style="background: #FF5582A6;">las clases mayoritarias dominan el resultado y las minoritarias son invisibles</mark>.
>
> En `NSL-KDD`, `Normal` y `DoS` suman la inmensa mayoría del dataset, mientras que `Privilege` tiene unas pocas decenas de muestras. Un `F1` ponderado de 0,99 es perfectamente compatible con un recall del 30% en escalada de privilegios — que es, con diferencia, **la categoría más grave de las cinco**.
>
> Lo que hay que reportar:
> - **`average='macro'`** — promedia las clases sin ponderar, así que una clase que se detecta mal hunde la cifra. Es la métrica honesta con clases desiguales.
> - **El `classification_report` completo**, con precisión, recall y soporte **por clase**. Es la única vista que revela qué se detecta y qué no.
>
> La matriz de confusión de este modelo cumple lo esperado en las clases grandes (≈15.300 `Normal`, ≈10.700 `DoS`, ≈2.800 `Probe`, ≈700 `Access`) y `Privilege` casi no aparece — no porque el modelo la resuelva, sino porque apenas existen muestras.

## Cómo se lee el informe por clase

Es la salida que hay que pedir siempre, y donde se ve el problema de un vistazo. Estructura típica (valores ilustrativos del orden de magnitud que produce este dataset, no una ejecución concreta):

```text
              precision    recall  f1-score   support

      Normal       0.99      1.00      0.99     15349
         DoS       1.00      1.00      1.00     10708
       Probe       0.99      0.98      0.98      2788
   Privilege       0.55      0.28      0.37        18   <-- aquí está el problema
      Access       0.96      0.92      0.94       703

    accuracy                           0.99     29566
   macro avg       0.90      0.84      0.86     29566   <-- métrica honesta
weighted avg       0.99      0.99      0.99     29566   <-- la que engaña
```

Tres columnas y una fila que hay que mirar siempre:

- **`support`** — cuántas muestras reales de esa clase hay en el conjunto. Con 18, cualquier métrica de esa fila tiene un margen de error enorme: acertar una muestra más mueve el recall casi seis puntos. <mark style="background: #FFB8EBA6;">Un `support` bajo no significa que el modelo vaya bien o mal: significa que **no se sabe**.</mark>
- **`recall` de `Privilege`** — la fracción de escaladas de privilegios que el detector encuentra. Es la clase más grave de las cinco y la peor detectada.
- **`macro avg` frente a `weighted avg`** — 0,86 frente a 0,99 sobre exactamente las mismas predicciones. <mark style="background: #FF5582A6;">Trece puntos de diferencia que dependen solo de cuál se decida reportar.</mark>

Por eso, en un informe: **`macro` y la tabla por clase**. Si un proveedor solo enseña el `weighted avg` o la `accuracy`, la pregunta correcta es cuál es el recall de la clase minoritaria y cuánto `support` tiene.

# Evaluación final sobre el test

```python
test_multi_predictions = rf_model_multi.predict(test_X)
print(classification_report(test_y, test_multi_predictions, target_names=class_labels))
```

Aquí sí hay un conjunto de test independiente, a diferencia del clasificador de spam. Es lo correcto: la validación se usó para decisiones, el test solo para la estimación final.

## La importancia de features, en ambas direcciones

`Random Forest` expone qué features pesan más en sus decisiones, y ese dato tiene doble uso:

```python
import pandas as pd

importancias = pd.Series(
    rf_model_multi.feature_importances_, index=train_set.columns
).sort_values(ascending=False)
print(importancias.head(15))
```

- **Para el defensor** — valida que el modelo aprende lo que debe. Si la feature más importante para detectar DoS resulta ser un artefacto de la generación del dataset y no una propiedad del ataque, el modelo no funcionará fuera del laboratorio.
- **Para el atacante** — <mark style="background: #FFB86CA6;">es el mapa de qué modificar.</mark> Si `serror_rate` y `count` dominan la detección de escaneos, la evasión consiste en reducir la tasa de errores y espaciar las conexiones: escaneo lento, con conexiones completas en vez de SYN a medias, y repartido entre orígenes.

> [!important]+ Las features del modelo definen la evasión
> Ese es el vínculo conceptual entre esta nota y el lado ofensivo. Un detector construido sobre estadísticas de ventana (`count`, `srv_count`, `serror_rate`, `same_srv_rate`) es evadible **manipulando la temporización y la distribución**, no el contenido. <mark style="background: #8000E1A6;">El escaneo `-T0`/`-T1` de Nmap, la fragmentación y los señuelos no son trucos folclóricos: atacan directamente las features sobre las que se calcula la detección.</mark>
>
> Se desarrolla en [[08 - Límites y evasión de los detectores ML]].

# Guardado

```python
import joblib

# ⚠ El fichero resultante se deserializa con pickle al cargarlo -> RCE si es de terceros.
joblib.dump(rf_model_multi, 'network_anomaly_detection_model.joblib')
```

Aplica exactamente la misma advertencia que en [[03 - Entrenamiento y evaluación del clasificador de spam]]: el artefacto `.joblib` es `pickle`, y cualquier endpoint que reciba y cargue uno de estos ficheros es un sumidero de deserialización insegura.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, con corrección del promediado de métricas (`weighted` → `macro` + informe por clase) y ampliado con el tratamiento del desbalance, la importancia de features y su lectura ofensiva, ausentes en el original.
