---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Reporting
Descripción: "Se reentrena con la misma arquitectura y los mismos hiperparámetros que la línea base — cualquier otra cosa invalidaría la comparación — y se mide contra el conjunto de test limpio"
Fecha de actualización: 2026-07-28
Nota previa: "[[06 - Identificación del objetivo y perturbación]]"
Nota siguiente: "[[08 - Backdoors y trojans en modelos]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

Se reentrena con la **misma arquitectura y los mismos hiperparámetros** que la línea base — cualquier otra cosa invalidaría la comparación — y se mide contra el conjunto de test limpio.

```python
poisoned_model_cl = OneVsRestClassifier(
    LogisticRegression(random_state=SEED, C=1.0, solver="liblinear")
)
poisoned_model_cl.fit(X_train_poisoned, y_train_poisoned)
```

# El resultado

```text
Target Point Evaluation:
  Original True Label (y_target):  1
  Baseline Model Prediction:       1
  Poisoned Model Prediction:       0
  Success: The poisoned model misclassified the target point as Class 0.

Overall Performance on Clean Test Set:
  Baseline Accuracy:  0.9600
  Poisoned Accuracy:  0.9578
  Accuracy Drop:      0.0022
```

<mark style="background: #FF5582A6;">El punto objetivo pasa de clasificarse correctamente como `Acceptable` a clasificarse como `Major Defect`, y la precisión global cae **0,22 puntos porcentuales**.</mark>

Puesto en contexto:

| | Valor |
| - | - |
| Muestras modificadas | **5 de 1050** — 0,48 % del conjunto de entrenamiento |
| Etiquetas modificadas | **0** |
| Caída de precisión global | **0,0022** |
| Objetivo comprometido | **Sí** |

Y el informe de clasificación no muestra nada llamativo:

```text
              precision    recall  f1-score   support
     Class 0       0.98      0.99      0.98       150
     Class 1       0.94      0.93      0.94       150
     Class 2       0.95      0.95      0.95       150
    accuracy                           0.96       450
```

<mark style="background: #8000E1A6;">Ese es el punto entero de esta familia de ataques: no hay ninguna métrica agregada, ni por clase, que delate lo ocurrido.</mark> Una caída de 0,22 puntos está muy por debajo de la variación normal entre reentrenamientos con semillas distintas. Un equipo que compara métricas entre versiones del modelo vería ruido.

![Fronteras de decisión del modelo envenenado frente a la base: el punto objetivo queda ahora del lado de la clase 0](https://academy.hackthebox.com/storage/modules/302/feature_attack_final.png)

# Los 0,22 puntos que sí importan

Esa caída mínima no es cero, y merece atención: es **daño colateral**. La deformación de la frontera provocada por los cinco puntos perturbados no afecta solo al objetivo — también cambia la clasificación de otros puntos que estaban cerca.

Tiene lectura para ambos lados:

- **Para el atacante**, es la penalización por ser agresivo. Cuanto mayor `epsilon_cross` o más vecinos perturbados, mayor el daño colateral y más probable que alguien lo note. El ataque óptimo es el mínimo que consigue el objetivo.
- **Para el defensor**, es la única señal que queda en las métricas — y es demasiado pequeña para servir de detección. Lo que sí sirve es comparar las **predicciones** entre versiones del modelo, no las métricas: un conjunto fijo de muestras cuya clasificación cambia entre dos versiones, sin que haya cambiado su naturaleza, es una anomalía concreta.

# Comparativa final de los ataques de envenenamiento

| | [[03 - Evaluación del label flipping\|Flipping aleatorio]] | [[04 - Ataques dirigidos a una clase\|Flipping dirigido]] | **Clean label** |
| - | - | - | - |
| Veneno | 40 % del dataset | ~20 % del dataset | **0,48 %** |
| Etiquetas alteradas | Sí | Sí | **No** |
| Caída de precisión | ~0 | 0,99 → 0,81 | **0,96 → 0,9578** |
| Efecto conseguido | Ninguno | Clase entera degradada | **Una instancia concreta** |
| Visible en revisión humana | Sí | Sí | **No** |
| Requiere conocer el modelo | No | No | **Sí** |

<mark style="background: #FFB86CA6;">La progresión es clara: cada ataque necesita menos veneno, deja menos rastro y exige más conocimiento del objetivo.</mark> Es la curva habitual en seguridad ofensiva, y sirve para calibrar qué esperar de un adversario según sus capacidades: un atacante externo sin acceso hará flipping por los canales de ingesta; un insider o alguien con el repositorio de modelos comprometido hará clean label.

# Detección

Las técnicas que sí funcionan contra esta familia, que son distintas de las de los ataques de etiqueta:

- **Análisis de la distribución de características por clase.** Los puntos perturbados son, por construcción, *atípicos dentro de su propia clase*: piezas etiquetadas como defecto grave con medidas anormalmente cercanas a las aceptables. Un test de outliers **dentro de cada clase** los señala; uno global sobre todo el dataset, no.
- **Comparación con datos históricos.** Si las mismas piezas o registros existen en versiones anteriores del dataset, un diff de valores revela las ediciones directamente. Requiere versionar los datos, que es la recomendación de fondo.
- **Activaciones espectrales** (`spectral signatures`) y agrupamiento de representaciones internas: las muestras envenenadas tienden a formar un subgrupo separable dentro de su clase en el espacio de activaciones. Es la técnica estándar contra clean label y backdoors — ver [[14 - Detección y evasión en ataques a los datos]].
- **Comparación de predicciones entre versiones** sobre un conjunto canario fijo, como se decía arriba.

# Al reportar

> [!important]+ El hallazgo sin métrica que enseñar
> Este es el hallazgo más difícil de comunicar de la carpeta, porque **no hay una métrica que enseñar**. La forma que funciona es demostrar la cadena completa: *"con acceso de escritura a X y modificando 5 registros de 1050, conseguimos que la pieza Y se rechace sistemáticamente, y ninguna de las métricas que ustedes monitorizan cambia de forma detectable"*. <mark style="background: #FFB8EBA6;">El hallazgo no es el ataque: es la **ausencia de capacidad de detección**</mark>, y de ahí salen las recomendaciones — versionado de datasets, control de integridad, detección de outliers intra-clase y conjunto canario.
