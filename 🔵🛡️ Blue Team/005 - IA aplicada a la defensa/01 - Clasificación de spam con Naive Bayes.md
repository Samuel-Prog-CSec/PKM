---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
Descripción: "El filtrado de spam es el caso de uso más antiguo del ML en seguridad y sigue siendo el mejor punto de entrada: el problema está bien definido, hay datos etiquetados disponibles…"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Machine learning aplicado a la defensa]]"
Nota siguiente: "[[02 - Preprocesamiento de texto y extracción de features]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

El filtrado de spam es el caso de uso más antiguo del ML en seguridad y sigue siendo el mejor punto de entrada: el problema está bien definido, hay datos etiquetados disponibles y el algoritmo —[[06 - Naive Bayes]]— es lo bastante simple como para poder razonar sobre cada decisión que toma.

# Bayes aplicado a spam

Se busca la probabilidad de que un mensaje sea spam dadas sus características:

```text
P(Spam|Features) = [ P(Features|Spam) · P(Spam) ] / P(Features)
```

| Término | Significado en este problema |
| - | - |
| `P(Spam\|Features)` | **Posterior**: lo que se quiere calcular |
| `P(Features\|Spam)` | **Verosimilitud**: probabilidad de ver esas palabras en un spam |
| `P(Spam)` | **Prior**: proporción de spam en el conjunto de entrenamiento |
| `P(Features)` | **Evidencia**: probabilidad total de observar esas palabras |

La asunción "naive" descompone la verosimilitud en un producto de probabilidades independientes:

```text
P(Features|Spam) = P(f₁|Spam) · P(f₂|Spam) · … · P(fₙ|Spam)
```

<mark style="background: #ADCCFFA6;">Sin esa simplificación habría que estimar la probabilidad conjunta de todas las combinaciones posibles de palabras, que es computacionalmente imposible.</mark> Con ella basta contar frecuencias individuales.

## Ejemplo numérico

Un mensaje con características `F1` y `F2`, siendo `P(Spam) = 0,3` y `P(No Spam) = 0,7`:

```text
P(F1|Spam)=0,4   P(F2|Spam)=0,5    →  P(F1,F2|Spam)    = 0,4 · 0,5 = 0,20
P(F1|Ham) =0,2   P(F2|Ham) =0,3    →  P(F1,F2|No Spam) = 0,2 · 0,3 = 0,06
```

Evidencia por la ley de probabilidad total:

```text
P(F1,F2) = (0,20 · 0,3) + (0,06 · 0,7) = 0,06 + 0,042 = 0,102
```

Posteriores:

```text
P(Spam|F1,F2)    = (0,20 · 0,3) / 0,102 ≈ 0,588
P(No Spam|F1,F2) = (0,06 · 0,7) / 0,102 ≈ 0,412
```

Gana spam. <mark style="background: #FFB8EBA6;">El prior mueve el resultado tanto como las verosimilitudes</mark>: si el prior de spam fuese 0,05 en vez de 0,3, las mismas características darían un posterior muy inferior. El prior codifica la tasa base, y ahí es donde el desbalance de clases entra directamente en el cálculo.

# El dataset

Se usa la **SMS Spam Collection** de la UCI: 5.574 mensajes SMS etiquetados como `ham` (legítimo) o `spam`, recopilados por Almeida, Gómez Hidalgo y Yamakami y presentados en el *ACM Symposium on Document Engineering* (2011). Se construyó a partir del sitio Grumbletext, el NUS SMS Corpus y la tesis de Caroline Tag.

> [!warning]+ Es un corpus de 2011 y eso condiciona lo que se aprende
> <mark style="background: #FF5582A6;">Quince años de distancia se notan.</mark> El spam por SMS de entonces era texto plano con premios y números de tarificación especial; el actual usa acortadores de URL, marcas suplantadas, contenido embebido en imagen, y llega mayoritariamente por aplicaciones de mensajería, con `smishing` orientado a robo de credenciales y fraude de criptomoneda.
>
> Sirve perfectamente para aprender el mecanismo — y **no** sirve como referencia de rendimiento para un filtro moderno. Un modelo entrenado y evaluado aquí dará métricas excelentes que no se trasladan a producción. Es el problema de representatividad descrito en [[02 - Datasets para seguridad]].

## Descarga y carga

```python
import requests, zipfile, io, os
import pandas as pd

url = "https://archive.ics.uci.edu/static/public/228/sms+spam+collection.zip"
response = requests.get(url)
print("Descarga correcta" if response.status_code == 200 else "Fallo en la descarga")

with zipfile.ZipFile(io.BytesIO(response.content)) as z:
    z.extractall("sms_spam_collection")

print("Ficheros extraídos:", os.listdir("sms_spam_collection"))
```

El fichero es TSV sin cabecera, así que hay que declararlo al cargarlo:

```python
df = pd.read_csv(
    "sms_spam_collection/SMSSpamCollection",
    sep="\t",
    header=None,
    names=["label", "message"],
)
```

## Inspección y limpieza

```python
print(df.head())      # estructura general
print(df.describe())  # resumen estadístico
print(df.info())      # tipos y conteo de no-nulos

print("Valores ausentes:\n", df.isnull().sum())

print("Entradas duplicadas:", df.duplicated().sum())
df = df.drop_duplicates()
```

<mark style="background: #8000E1A6;">Eliminar duplicados no es cosmético: es prevención de `data leakage`.</mark> Si el mismo mensaje cae en entrenamiento y en test, el modelo lo "acierta" por memorización y la métrica queda inflada. Este corpus contiene varios cientos de duplicados, así que el efecto es perfectamente medible.

> [!info]+ Descargar un dataset es depositar confianza en una URL
> El código de arriba descarga un ZIP y lo extrae sin verificar nada. Es lo normal en un tutorial y una mala práctica en un pipeline real: no hay comprobación de integridad, y `extractall` sobre un archivo no confiable es susceptible de *path traversal* (`zip slip`) si contiene rutas con `../`.
>
> En entorno profesional: verificar sumas de comprobación, alojar una copia propia del dataset y validar las rutas antes de extraer. Encaja con el vector de cadena de suministro descrito en [[02 - Datasets para seguridad]].

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con la advertencia sobre la antigüedad del corpus, el papel del prior y los riesgos de la descarga sin verificación, ausentes en el original.
- Almeida, Gómez Hidalgo & Yamakami, *Contributions to the Study of SMS Spam Filtering: New Collection and Results*, ACM DocEng 2011 — origen del dataset.
- [UCI Machine Learning Repository — SMS Spam Collection](https://archive.ics.uci.edu/dataset/228/sms+spam+collection) (consultado 2026-07-28).
