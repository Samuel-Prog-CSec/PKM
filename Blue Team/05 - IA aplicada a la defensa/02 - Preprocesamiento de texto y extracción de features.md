---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
Descripción: "Un modelo no procesa texto: procesa vectores de números"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Clasificación de spam con Naive Bayes]]"
Nota siguiente: "[[03 - Entrenamiento y evaluación del clasificador de spam]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

Un modelo no procesa texto: procesa vectores de números. <mark style="background: #ADCCFFA6;">El preprocesado normaliza el texto y la extracción de features lo convierte en una matriz numérica.</mark> Cada paso reduce ruido — y, como se verá al final, cada paso también borra información que podría delatar a un atacante.

# Pipeline de preprocesado

```python
import nltk
nltk.download("punkt")
nltk.download("punkt_tab")
nltk.download("stopwords")
```

## Minúsculas

```python
df["message"] = df["message"].str.lower()
```

Hace que `Free` y `free` sean el mismo token, reduciendo el vocabulario y evitando que el modelo reparta el peso entre variantes de la misma palabra.

## Eliminar puntuación y números

```python
import re
df["message"] = df["message"].apply(lambda x: re.sub(r"[^a-z\s$!]", "", x))
```

<mark style="background: #FFB8EBA6;">Se conservan deliberadamente `$` y `!`</mark>: en spam llevan señal real —importes y énfasis— y descartarlos perdería capacidad discriminante. Es un ejemplo claro de que el preprocesado debe decidirse con conocimiento del dominio, no aplicando una receta genérica.

## Tokenización

```python
from nltk.tokenize import word_tokenize
df["message"] = df["message"].apply(word_tokenize)
```

Convierte cada mensaje en una lista de palabras, la unidad sobre la que operan los pasos siguientes.

## Eliminar stop words

```python
from nltk.corpus import stopwords
stop_words = set(stopwords.words("english"))
df["message"] = df["message"].apply(lambda x: [w for w in x if w not in stop_words])
```

Palabras como `and`, `the` o `is` aparecen en todos los mensajes y no ayudan a distinguir clases. Quitarlas reduce dimensionalidad y concentra la señal.

## Stemming

```python
from nltk.stem import PorterStemmer
stemmer = PorterStemmer()
df["message"] = df["message"].apply(lambda x: [stemmer.stem(w) for w in x])
```

Reduce las palabras a su raíz (`running` → `run`), consolidando variantes flexivas. El `stemming` es un recorte heurístico de sufijos y puede producir raíces que no son palabras (`business` → `busi`); la **lematización** hace lo mismo con análisis morfológico real, es más precisa y más lenta.

## Reunir los tokens

```python
df["message"] = df["message"].apply(lambda x: " ".join(x))
```

Los vectorizadores de `scikit-learn` esperan cadenas, no listas.

> [!info]+ Este pipeline es NLP clásico, no el estado del arte
> Minúsculas, *stop words* y *stemming* eran imprescindibles cuando cada palabra era una dimensión independiente. <mark style="background: #FFB8EBA6;">Los modelos basados en `transformers` no necesitan nada de esto</mark>: la tokenización por subpalabras maneja las variantes morfológicas de forma nativa, y la mayúscula y la puntuación son señal aprovechable, no ruido.
>
> El pipeline clásico sigue teniendo sentido cuando se busca un modelo ligero, interpretable y entrenable con pocos datos — que es exactamente el caso de un clasificador interno hecho a medida. Pero conviene saber que se está eligiendo un compromiso, no la mejor opción disponible.

# Extracción de features: bag-of-words

`CountVectorizer` construye un vocabulario con los términos del corpus y representa cada mensaje como un vector de frecuencias.

```python
from sklearn.feature_extraction.text import CountVectorizer

vectorizer = CountVectorizer(min_df=1, max_df=0.9, ngram_range=(1, 2))
X = vectorizer.fit_transform(df["message"])
y = df["label"].apply(lambda x: 1 if x == "spam" else 0)
```

| Parámetro | Efecto |
| - | - |
| `min_df=1` | Un término debe aparecer al menos en un documento. Valores mayores descartan términos raros |
| `max_df=0.9` | Descarta términos presentes en más del 90% de los documentos — demasiado comunes para discriminar |
| `ngram_range=(1,2)` | Incluye palabras sueltas (unigramas) y pares consecutivos (bigramas) |

Los **bigramas** aportan un poco de orden local: `free prize` distingue una promesa de premio de una aparición aislada de `free`. Fuera de esas ventanas cortas, <mark style="background: #8000E1A6;">el `bag-of-words` pierde por completo el orden de las palabras</mark>: para el modelo, un mensaje es un recuento de términos, no una frase.

Una alternativa muy habitual es `TfidfVectorizer`, que pondera cada término por su frecuencia en el documento dividida por su frecuencia en el corpus. Reduce el peso de lo ubicuo y lo sube en lo distintivo; suele rendir algo mejor que el conteo puro con el mismo coste.

# Cada paso de limpieza es un hueco de evasión

Aquí está la lectura que importa para el lado ofensivo, y que ninguna guía de preprocesado plantea.

<mark style="background: #FFB86CA6;">Todo paso que "reduce ruido" elimina información — incluidas las huellas que deja la ofuscación de un atacante.</mark>

| Paso | Qué borra | Evasión que habilita |
| - | - | - |
| Minúsculas | Diferencias de caja | `FrEe MoNeY` se normaliza al token limpio y el filtro deja de ver la anomalía |
| Quitar puntuación | Separadores insertados | `f.r.e.e` y `f-r-e-e` colapsan... o se rompen en tokens sin sentido, según el orden de operaciones |
| Stop words | Palabras comunes | Facilita diluir el mensaje con relleno benigno sin coste en features |
| Stemming | Variantes morfológicas | Reduce el vocabulario y con ello la resolución del modelo |
| `max_df` | Términos muy frecuentes | Un término que el atacante logre hacer ubicuo queda excluido del vocabulario |

> [!warning]+ Fallo concreto de este pipeline: Unicode
> `re.sub(r"[^a-z\s$!]", "", x)` conserva **solo** letras ASCII minúsculas, espacios, `$` y `!`. Todo lo demás desaparece.
>
> <mark style="background: #FF5582A6;">Un mensaje escrito con homoglifos o variantes tipográficas Unicode —caracteres matemáticos, cirílicos de aspecto latino, letras de ancho completo— no sobrevive a ese filtro: se queda en una cadena vacía.</mark> El vector de features resultante es todo ceros, y el clasificador decide únicamente por el prior — que es `ham`, porque es la clase mayoritaria.
>
> El resultado es una evasión completa sin tocar el modelo: el destinatario ve un mensaje perfectamente legible y el filtro no ve nada.
>
> Comprobable y reproducible (el texto se construye desde ASCII para no depender de pegar codepoints):
> ```python
> import re, unicodedata
>
> def styled(s):
>     """Mapea ASCII a 'Mathematical Sans-Serif Bold': se lee igual, no es ASCII."""
>     out = []
>     for ch in s:
>         if 'a' <= ch <= 'z':   out.append(chr(0x1D5EE + ord(ch) - ord('a')))
>         elif 'A' <= ch <= 'Z': out.append(chr(0x1D5D4 + ord(ch) - ord('A')))
>         else:                  out.append(ch)
>     return ''.join(out)
>
> clean = lambda t: re.sub(r"[^a-z\s$!]", "", t.lower())   # el filtro del pipeline
> msg = styled("FREE entry! Click now")
>
> print(ascii(clean(msg)))
> print(ascii(clean(unicodedata.normalize("NFKC", msg))))
> ```
> ```text
> ' !  '                      <- sin NFKC: el texto ha desaparecido
> 'free entry! click now'     <- con NFKC previo, el filtro sí lo ve
> ```
>
> El vector de features del primer caso es todo ceros, y `MultinomialNB` con entrada nula decide por el `class_log_prior_`: gana `ham`, que es la clase mayoritaria del corpus.

> [!success]+ Mitigación, con el matiz que casi siempre falta
> **`NFKC` no basta.** Normaliza las variantes *tipográficas* del alfabeto latino —matemáticas, de ancho completo, con serifa— porque tienen descomposición de compatibilidad a ASCII. <mark style="background: #FF5582A6;">Pero **no** toca los homoglifos de otros alfabetos</mark>: la `а` cirílica (U+0430) y la `ο` griega (U+03BF) sobreviven intactas a `NFKC` y siguen siendo eliminadas por el filtro. Verificado:
> ```python
> unicodedata.normalize("NFKC", "арре") == "арре"   # True: NFKC no la toca
> clean(unicodedata.normalize("NFKC", "арре"))      # ''  el filtro la borra igual
> ```
>
> Las tres capas que sí cierran el hueco:
> 1. **`NFKC`** antes de cualquier limpieza — resuelve el caso tipográfico.
> 2. **Detección de confundibles y de mezcla de alfabetos** — mapear caracteres visualmente equivalentes a su forma latina (los datos `confusables` de Unicode), y puntuar como sospechoso cualquier token que mezcle sistemas de escritura.
> 3. **Tratar como anómalo el mensaje que queda vacío o casi vacío tras la limpieza**, en lugar de clasificarlo como uno más. Es la regla más barata y la que atrapa cualquier variante futura de este mismo truco.

A esto se suma el clásico `good word attack` descrito en [[06 - Naive Bayes]]: añadir términos fuertemente asociados a `ham` para arrastrar el posterior. El `bag-of-words` es especialmente vulnerable porque **no tiene noción de estructura**: da igual dónde se inserte el relleno, solo cuenta cuántas veces aparece cada término.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con la comparación frente a NLP moderno, `TF-IDF` y el análisis de cada paso de limpieza como superficie de evasión (incluido el fallo con Unicode), ausentes en el original.
