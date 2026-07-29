---
tags:
  - IA
  - IA/Pipeline
Descripción: "La transformación cambia la representación de las features para que el modelo pueda aprovecharlas"
Fecha de actualización: 2026-07-28
Nota previa: "[[03 - Preprocesamiento de datos]]"
Nota siguiente: "[[05 - Métricas de evaluación de modelos]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

<mark style="background: #ADCCFFA6;">La transformación cambia la **representación** de las features para que el modelo pueda aprovecharlas.</mark> Cubre tres tareas: convertir categorías en números, corregir distribuciones asimétricas y separar los datos en conjuntos de entrenamiento, validación y test.

# Codificar variables categóricas

Los algoritmos operan sobre números, y `TCP` no es un número.

## One-hot encoding

Convierte una feature categórica en una columna binaria por categoría. Con `color` ∈ {`red`, `green`, `blue`} se obtienen tres columnas `color_red`, `color_green`, `color_blue`, y cada fila tiene un `1` en la que corresponde y `0` en las demás.

![Tabla mostrando la codificación one-hot de la variable color en tres columnas binarias](https://academy.hackthebox.com/storage/modules/292/data_encoding.png)

```python
from sklearn.preprocessing import OneHotEncoder

encoder = OneHotEncoder(handle_unknown='ignore', sparse_output=False)
encoded = encoder.fit_transform(df[['protocol']])

encoded_df = pd.DataFrame(encoded, columns=encoder.get_feature_names_out(['protocol']))
df = pd.concat([df.drop('protocol', axis=1), encoded_df], axis=1)
```

<mark style="background: #FFB8EBA6;">`handle_unknown='ignore'` es imprescindible en producción</mark>: garantiza que una categoría que no apareció durante el entrenamiento no reviente la inferencia, sino que se codifique como todo ceros. Sin él, el primer protocolo nuevo que aparezca en la red tumba el pipeline.

| Codificador | Cuándo | Riesgo |
| - | - | - |
| `OneHotEncoder` | Pocas categorías, sin orden natural | Explosión de dimensionalidad con alta cardinalidad |
| `LabelEncoder` | **Solo** para la variable objetivo | Introduce un orden falso si se usa en features |
| `OrdinalEncoder` | Categorías con orden real (bajo/medio/alto) | Aplicado a nominales, mismo problema que `LabelEncoder` |
| `HashingEncoder` / frecuencia | Alta cardinalidad (IPs, dominios, user-agents) | Colisiones; menos interpretable |

La alta cardinalidad es el caso habitual en seguridad: direcciones IP, nombres de dominio, hashes, cadenas de `User-Agent`. `One-hot` sobre un campo con 50.000 valores distintos genera 50.000 columnas y hace inviable el modelo. Ahí se usan `hashing`, codificación por frecuencia, o —mejor— se sustituye el identificador por features derivadas con significado: ¿es IP interna o externa?, ¿el dominio es reciente?, ¿cuál es la entropía del nombre?

# Distribuciones asimétricas

Una feature `skewed` concentra casi todas sus observaciones en un extremo con unos pocos valores extremos estirando la cola. `bytes_transferred` es el ejemplo canónico: miles de conexiones pequeñas y unas pocas transferencias enormes.

```python
import numpy as np

df["bytes_transferred"] = np.log1p(df["bytes_transferred"])
```

![Histogramas comparando la distribución original de bytes transferidos y su versión log-transformada](https://academy.hackthebox.com/storage/modules/292/log_histogram.png)

`log1p` calcula `log(1 + x)`, definido también en cero. La transformación comprime los valores grandes más que los pequeños, equilibrando la distribución. <mark style="background: #8000E1A6;">No se pierde información —la transformación es monótona y reversible— pero el modelo deja de estar dominado por unos pocos extremos.</mark>

> [!warning]+ En seguridad, el extremo puede ser el ataque
> Aplanar la cola es útil para que el modelo capte el patrón general, y a la vez <mark style="background: #FF5582A6;">reduce la distancia entre una exfiltración de 40 GB y una descarga normal de 40 MB</mark>. Si el objetivo es detectar el evento raro, comprimir la escala donde vive el evento raro juega en contra.
>
> Alternativas según el objetivo: conservar la feature original **junto** a la transformada, usar `RobustScaler` en vez de logaritmo, o transformaciones que preserven el orden con menos compresión (raíz cuadrada, `Yeo-Johnson`). La decisión debe ser explícita, no heredada del tutorial.

# Partición de los datos

Tres conjuntos con tres funciones distintas:

| Conjunto | Uso | Proporción típica |
| - | - | - |
| `Training` | Ajustar los parámetros del modelo | 60-80% |
| `Validation` | Elegir hiperparámetros y comparar modelos | 10-20% |
| `Test` | Estimación final del rendimiento. **Se usa una vez** | 10-20% |

```python
from sklearn.model_selection import train_test_split

X = df.drop("threat_level", axis=1)
y = df["threat_level"]

# 80% train+val, 20% test
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=1337, stratify=y)

# del 80% anterior: 25% para validación -> 60/20/20 sobre el total
X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, test_size=0.25, random_state=1337, stratify=y_train)
```

`test_size=0.25` en la segunda llamada se aplica sobre el 80% ya separado: `0,8 × 0,25 = 0,2`, es decir el 20% del total. `random_state` fija la semilla y hace reproducible la partición.

> [!important]+ Dos correcciones necesarias para datos de seguridad
> **`stratify` casi siempre.** Sin él, con clases muy desbalanceadas, la partición aleatoria puede dejar el conjunto de test con muy pocos ejemplos positivos —o ninguno— y la métrica resultante no mide nada. `stratify=y` conserva la proporción de clases en ambos lados.
>
> **Partición temporal cuando los datos lo son.** <mark style="background: #FFB86CA6;">Los logs, los flujos de red y las muestras de malware tienen fecha. Partirlos al azar entrena el modelo con el futuro y lo evalúa sobre el pasado</mark> — una forma de `data leakage` que infla las métricas de forma espectacular y silenciosa. La partición correcta es cronológica: entrenar con lo anterior a una fecha, evaluar con lo posterior. Es más dura y es la única que estima el rendimiento real, porque además captura el `concept drift`: en clasificación de malware la degradación con el tiempo es enorme, y una partición aleatoria la esconde por completo.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con el manejo de alta cardinalidad, el conflicto entre transformación logarítmica y detección de extremos, y la necesidad de partición temporal y estratificada, ausentes en el original.
- Imágenes de codificación e histogramas: HTB Academy, módulo 292.
