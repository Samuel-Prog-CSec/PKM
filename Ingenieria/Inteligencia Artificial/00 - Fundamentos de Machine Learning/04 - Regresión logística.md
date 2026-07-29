---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Pese al nombre, la logistic regression es un algoritmo de clasificación, no de regresión"
Fecha de actualización: 2026-07-28
Nota previa: "[[03 - Regresión lineal]]"
Nota siguiente: "[[05 - Árboles de decisión y ensembles]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">Pese al nombre, la `logistic regression` es un algoritmo de **clasificación**, no de regresión.</mark> Predice la probabilidad de que una entrada pertenezca a una clase, y esa probabilidad se convierte en decisión aplicando un umbral. Es el clasificador base de la industria: rápido, interpretable, y con probabilidades **bien calibradas** — un 0,8 suyo significa de verdad que acierta ~8 de cada 10 veces que dice 0,8, propiedad que ni [[06 - Naive Bayes]], ni las [[07 - Máquinas de vectores de soporte (SVM)]], ni los [[05 - Árboles de decisión y ensembles]] tienen. Sale así porque se entrena minimizando `log-loss`, que es una regla de puntuación propia: el óptimo se alcanza justo cuando las probabilidades predichas son las reales.

Con una advertencia: esa calibración se pierde si se remuestrea el conjunto para equilibrar clases, algo muy habitual en seguridad. Reequilibrar cambia el prior y desplaza las probabilidades, así que después hay que recalibrar o corregir el sesgo del intercepto.

En seguridad aparece por todas partes: filtros de spam, scoring de fraude, clasificación binaria de tráfico. Y es el punto de partida obligado para entender por qué cualquier clasificador tiene una frontera y qué significa cruzarla.

# De la recta a la probabilidad

La regresión lineal produce cualquier valor real, y una probabilidad tiene que estar entre 0 y 1. La `logistic regression` resuelve esto pasando la combinación lineal de features por una **función sigmoide**:

![Curva sigmoide en forma de S que mapea cualquier entrada real al intervalo 0-1](https://academy.hackthebox.com/storage/modules/290/sigmoid.png)

```text
P(x) = 1 / (1 + e^(−z))     donde     z = m₁x₁ + m₂x₂ + … + mₙxₙ + c
```

La sigmoide aplasta el rango `(−∞, +∞)` en `(0, 1)`: valores muy negativos tienden a 0, muy positivos a 1, y la transición ocurre en torno a `z = 0`. <mark style="background: #FFB8EBA6;">El interior (`z`) sigue siendo estrictamente lineal</mark> — el modelo solo es no lineal en la última transformación. Esa es la razón de que herede las virtudes de interpretabilidad de la regresión lineal.

## Log-odds

La sigmoide invertida da la lectura correcta del modelo: los coeficientes no operan sobre la probabilidad, sino sobre el **logaritmo de la razón de probabilidades**.

```text
ln( P / (1 − P) ) = z
```

Un coeficiente de `0,7` significa que aumentar esa feature en una unidad multiplica las *odds* por `e^0,7 ≈ 2`. Leer los coeficientes como si fueran incrementos de probabilidad directa es el error de interpretación más común con este modelo.

# Frontera de decisión y umbral

![Hiperplano separando dos clases de puntos en un espacio bidimensional](https://academy.hackthebox.com/storage/modules/290/hyperplane.png)

El conjunto de puntos donde `z = 0` —probabilidad exactamente 0,5— forma la `decision boundary`. Con dos features es una recta; con tres, un plano; con `n`, un **hiperplano**: un subespacio de dimensión `n−1` que parte el espacio en dos regiones.

El umbral por defecto es 0,5, pero es un parámetro libre y ahí es donde el modelo se convierte en un control de seguridad configurable:

| Umbral | Consecuencia | Cuándo interesa |
| - | - | - |
| Bajo (p. ej. 0,2) | Más detecciones, más falsos positivos | Cuando dejar pasar un ataque cuesta más que revisar alertas de más |
| 0,5 | Punto neutro | Rara vez es el óptimo en seguridad |
| Alto (p. ej. 0,8) | Menos falsos positivos, más falsos negativos | Bloqueo automático, donde un FP interrumpe a un usuario legítimo |

> [!important]+ El umbral es una decisión de negocio disfrazada de parámetro técnico
> En un antispam, subir el umbral reduce las quejas por correo legítimo bloqueado y **abre hueco al atacante**. <mark style="background: #FF5582A6;">El objetivo de un ataque de evasión no es "engañar al modelo" en abstracto: es conseguir que la puntuación caiga por debajo del umbral de bloqueo.</mark> Conocer o inferir ese umbral —enviando sondas y observando qué pasa— es reconocimiento previo a la evasión, y suele ser barato porque el sistema devuelve el resultado.

# Clasificación multiclase

HTB presenta la regresión logística como estrictamente binaria. Es cierto en su formulación original, pero en la práctica se extiende a varias clases de dos formas, ambas disponibles de serie en `scikit-learn`:

- **`One-vs-Rest`** — se entrena un clasificador binario por clase y gana el de mayor probabilidad. Simple, pero las probabilidades no suman 1.
- **`Softmax` (regresión logística multinomial)** — generaliza la sigmoide a `k` clases produciendo una distribución que sí suma 1. Es la capa de salida estándar de **cualquier** red neuronal clasificadora, incluidos los LLM sobre el vocabulario de tokens.

Entender `softmax` aquí paga después: el muestreo de un LLM opera exactamente sobre esa distribución, y parámetros como la `temperature` la modifican antes de muestrear.

# Supuestos

Menos estrictos que los de la regresión lineal, pero no inexistentes:

- **Salida binaria** — la variable objetivo tiene dos categorías (o se extiende con las técnicas de arriba).
- **Linealidad de los log-odds** — la relación lineal se exige entre las features y el logaritmo de las odds, no con la probabilidad.
- **Poca multicolinealidad** — features muy correlacionadas hacen que los coeficientes individuales dejen de ser interpretables, aunque la predicción global aguante.
- **Muestra suficiente** — con pocos datos y muchas features, los coeficientes se vuelven inestables.

# La evasión más simple posible

<mark style="background: #8000E1A6;">Si la frontera es un hiperplano, la perturbación mínima que cambia la clasificación es la distancia perpendicular del punto a ese hiperplano.</mark> Tiene fórmula cerrada, se calcula en una operación y no requiere iteración alguna.

<mark style="background: #FFB86CA6;">Esa observación es el germen de `DeepFool`</mark>, uno de los ataques de evasión de referencia: aproxima localmente un modelo no lineal por su hiperplano tangente, proyecta el punto sobre él, e itera. Un clasificador profundo se ataca, en esencia, tratándolo como una regresión logística en un entorno suficientemente pequeño.

De ahí también un matiz operativo importante: <mark style="background: #FFB8EBA6;">la distancia a la frontera es una medida directa de fragilidad</mark>. Un modelo cuyos ejemplos legítimos quedan pegados al hiperplano puede tener una `accuracy` excelente y ser trivial de evadir. La precisión no mide robustez; son propiedades independientes.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con `log-odds`, extensión multiclase (`One-vs-Rest`/`softmax`) y la relación frontera↔`DeepFool`, ausentes en el original.
- Imágenes de la sigmoide y del hiperplano: HTB Academy, módulo 290.
