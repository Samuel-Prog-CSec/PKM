---
tags:
  - IA
  - IA/Pipeline
Descripción: "El preprocesado convierte datos crudos en algo que un algoritmo pueda digerir"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Datasets para seguridad]]"
Nota siguiente: "[[04 - Transformación de datos]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

<mark style="background: #ADCCFFA6;">El preprocesado convierte datos crudos en algo que un algoritmo pueda digerir.</mark> Cubre cuatro tipos de trabajo: **limpieza** (ausentes, duplicados, ruido), **transformación** (normalizar, codificar, escalar), **integración** (fusionar fuentes) y **formateo** (tipos y estructura).

Es la fase que más tiempo consume de un proyecto de ML y la que más determina el resultado. También es donde se cometen los errores que producen métricas espectaculares y modelos inservibles.

# Detectar valores inválidos

Los ausentes se localizan con `isnull()`. Lo que no detecta ninguna función genérica son los valores **presentes pero imposibles**, y esos requieren conocimiento del dominio.

**Direcciones IP:**

```python
import re

def is_valid_ip(ip):
    pattern = re.compile(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$')
    return bool(pattern.match(ip))

invalid_ips = data[~data['source_ip'].astype(str).apply(is_valid_ip)]
```

**Puertos** — rango 0-65535:

```python
def is_valid_port(port):
    try:
        return 0 <= int(port) <= 65535
    except ValueError:
        return False

invalid_ports = data[~data['destination_port'].apply(is_valid_port)]
```

**Protocolos** — contra una lista blanca:

```python
valid_protocols = ['TCP', 'TLS', 'SSH', 'POP3', 'DNS', 'HTTPS', 'SMTP', 'FTP', 'UDP', 'HTTP']
invalid_protocols = data[~data['protocol'].isin(valid_protocols)]
```

Y de forma análoga, `bytes_transferred` debe ser numérico y no negativo, y `threat_level` debe caer en el rango de clases definido.

> [!info]+ La validación de datos es validación de entrada
> Estas comprobaciones son exactamente las mismas que se aplican a cualquier entrada no confiable en una aplicación: lista blanca de valores permitidos, rangos, tipos, formato. <mark style="background: #FFB8EBA6;">La diferencia es que aquí la entrada acaba en un modelo en vez de en una consulta SQL</mark>, y una entrada maliciosa no produce inyección sino sesgo. La mentalidad es idéntica: **nunca confíes en el formato de lo que llega**.

# Qué hacer con lo inválido

## Descartar

La opción directa: eliminar las filas problemáticas.

```python
for bad in (invalid_ips, invalid_ports, invalid_protocols, invalid_bytes, invalid_threat_levels):
    data = data.drop(bad.index, errors='ignore')

print(data.describe(include='all'))
```

<mark style="background: #FF5582A6;">Es una decisión con coste oculto.</mark> En el dataset de ejemplo, descartar todo lo inválido deja **77 entradas** de las originales. Y el descarte rara vez es aleatorio: si los registros corruptos provienen de un tipo concreto de dispositivo o de una condición concreta, eliminarlos introduce un sesgo sistemático. En seguridad esto es especialmente peligroso, porque **el tráfico malformado puede ser precisamente el ataque**: paquetes truncados, cabeceras inválidas y campos fuera de rango son indicadores, no ruido.

## Imputar

Sustituir lo ausente por una estimación. Primero se normaliza todo lo inválido a `NaN`:

```python
import numpy as np

df.replace(['INVALID_IP', 'MISSING_IP', 'STRING_PORT', 'UNUSED_PORT',
            'NON_NUMERIC', 'NEGATIVE', '?'], np.nan, inplace=True)

df['destination_port']  = pd.to_numeric(df['destination_port'],  errors='coerce')
df['bytes_transferred'] = pd.to_numeric(df['bytes_transferred'], errors='coerce')
df['threat_level']      = pd.to_numeric(df['threat_level'],      errors='coerce')
```

`errors='coerce'` convierte a `NaN` lo que no pueda parsearse, unificando el tratamiento de todo lo inválido.

Después, imputación por tipo de columna:

```python
from sklearn.impute import SimpleImputer

numeric_cols     = ['destination_port', 'bytes_transferred', 'threat_level']
categorical_cols = ['protocol']

df[numeric_cols]     = SimpleImputer(strategy='median').fit_transform(df[numeric_cols])
df[categorical_cols] = SimpleImputer(strategy='most_frequent').fit_transform(df[categorical_cols])
```

**Mediana antes que media** en columnas numéricas: es robusta a outliers, y en datos de red los outliers son la norma. Para columnas categóricas, el valor más frecuente.

Métodos que consideran las relaciones entre features:

```python
from sklearn.impute import KNNImputer

df[numeric_cols] = KNNImputer(n_neighbors=5).fit_transform(df[numeric_cols])
```

`KNNImputer` estima a partir de los vecinos más parecidos; `IterativeImputer` modela cada columna en función de las demás. Producen imputaciones más coherentes a cambio de coste y de un riesgo mayor de fuga si se aplican mal.

## Reglas de dominio

El paso final es el que ninguna librería puede hacer sola:

```python
df.loc[~df['protocol'].isin(valid_protocols), 'protocol'] = df['protocol'].mode()[0]
df['source_ip'] = df['source_ip'].fillna('0.0.0.0')
df['destination_port'] = df['destination_port'].clip(lower=0, upper=65535)
```

> [!warning]+ La imputación fabrica datos, y eso tiene consecuencias
> <mark style="background: #8000E1A6;">Un valor imputado es una invención plausible, no una observación.</mark> Tres efectos que hay que tener presentes:
> - **Reduce artificialmente la varianza.** Imputar con la mediana concentra masa en el centro de la distribución y hace que el modelo parezca más seguro de lo que está.
> - **Puede borrar la señal.** Si los ausentes se concentran en la clase minoritaria —y en seguridad los registros de ataques son a menudo los que llegan incompletos— imputarlos con la mediana de la clase mayoritaria empuja los ataques hacia el perfil de lo normal.
> - **La propia ausencia es información.** Un campo vacío en un log puede indicar un fallo, una evasión o una manipulación. Una alternativa útil es <mark style="background: #FFB8EBA6;">añadir una columna binaria `feature_missing` antes de imputar</mark>, preservando esa señal en vez de destruirla.
>
> Y, como siempre: el imputador se ajusta **solo con el conjunto de entrenamiento**. Calcular la mediana sobre todo el dataset antes de partir es `data leakage`.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con el sesgo del descarte, los efectos secundarios de la imputación y la señal contenida en la ausencia, ausentes en el original.
