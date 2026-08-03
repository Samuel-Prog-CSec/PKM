---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Reporting
Descripción: "El experimento consiste en envenenar fracciones crecientes del conjunto de entrenamiento —10 %, 20 %, 30 %, 40 %, 50 %— entrenar un modelo con cada una y evaluarlo siempre…"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Label flipping]]"
Nota siguiente: "[[04 - Ataques dirigidos a una clase]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

El experimento consiste en envenenar fracciones crecientes del conjunto de entrenamiento —10 %, 20 %, 30 %, 40 %, 50 %— entrenar un modelo con cada una y evaluarlo **siempre contra el conjunto de test limpio**. El resultado es más interesante por lo que *no* pasa que por lo que pasa.

# El bucle

```python
for pp in [0.10, 0.20, 0.30, 0.40, 0.50]:
    y_train_poisoned, flipped_idx = flip_labels(y_train, pp)

    poisoned_model = LogisticRegression(random_state=SEED)
    poisoned_model.fit(X_train, y_train_poisoned)   # X limpia, y envenenada

    y_pred = poisoned_model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)       # siempre contra y_test REAL
    print(f"{pp*100:.0f}% envenenado -> accuracy {accuracy:.4f}")
```

# El resultado que sorprende

<mark style="background: #FF5582A6;">Con el 10 % de las etiquetas invertidas, la precisión sobre datos limpios **no cambia**: sigue en 0,9933, idéntica a la línea base.</mark> Y se mantiene alta hasta que el envenenamiento se acerca al 50 %, punto en el que el modelo colapsa.

![Gráfica de precisión del modelo frente al porcentaje de etiquetas invertidas: se mantiene alta hasta caer bruscamente al 50 %](https://academy.hackthebox.com/storage/modules/302/label_flipping_consolidated_accuracy.png)

La explicación es geométrica. Con dos cúmulos claramente separados, la regresión logística busca la recta que mejor separa las dos nubes. Invertir etiquetas **al azar** reparte el ruido de forma aproximadamente uniforme entre ambos lados: por cada punto de la clase 0 que se marca como 1, hay estadísticamente otro de la clase 1 marcado como 0. <mark style="background: #8000E1A6;">Los errores se compensan entre sí y la posición óptima de la recta apenas se mueve.</mark>

Al 50 % la señal desaparece por completo: las etiquetas son ruido puro y no queda nada que aprender.

# Lo que sí cambia — la frontera

Aunque la precisión no se mueva, **la frontera de decisión sí lo hace**, y de forma creciente con el porcentaje de veneno:

![Superposición de las fronteras de decisión para 0 %, 10 %, 20 %, 30 %, 40 % y 50 % de envenenamiento, mostrando el desplazamiento progresivo](https://academy.hackthebox.com/storage/modules/302/label_flipping_consolidated.png)

Cada nivel de envenenamiento produce una recta distinta. Con datos tan limpios ese desplazamiento cae en la zona vacía entre cúmulos y no cambia ninguna clasificación. **En datos reales esa zona vacía no existe**: las clases se solapan, hay puntos ambiguos justo en la frontera, y cualquier desplazamiento cambia la predicción de muchos de ellos.

Es la advertencia explícita que hace el propio módulo y que conviene subrayar: <mark style="background: #FFB8EBA6;">estos números son del caso más favorable posible.</mark> Extrapolarlos a producción ("hace falta envenenar el 50 % para que pase algo") sería un error grave.

# Tres lecciones operativas

## 1 · La precisión global es un pésimo detector de envenenamiento

Es la conclusión más importante del experimento y la que se lleva a un informe.

Un equipo que vigila solo la métrica agregada del modelo **no habría detectado nada** con hasta el 40 % de las etiquetas corrompidas. Y el 40 % es un ataque brutal, ruidoso, que en un dataset real dejaría rastro por todas partes.

<mark style="background: #FFB86CA6;">Ningún ataque competente opera a ese volumen.</mark> Un envenenamiento realista mueve unidades de porcentaje, se dirige a una clase concreta, y es **invisible** para la única métrica que la mayoría de los equipos vigila. La recomendación que se deriva: monitorizar métricas **por clase** (precisión, recall, F1) y no solo la agregada, más un conjunto de pruebas canario fijo verificado tras cada reentrenamiento.

## 2 · La frontera se mueve antes de que la métrica lo note

Existe una ventana en la que el modelo ya está corrompido y ninguna métrica lo refleja. Para el atacante es margen de maniobra; para el defensor es el argumento para vigilar **la deriva de los parámetros del modelo entre versiones**, no solo su rendimiento. Un cambio significativo en los pesos sin cambio correspondiente en las métricas es una anomalía que merece investigación.

## 3 · El azar es un mal uso del presupuesto

El experimento muestra el ataque más ineficiente posible: elegir muestras al azar. Como se vio en [[02 - Label flipping#Por qué el modelo se deja|la nota anterior]], solo las muestras que el modelo clasificaría con alta confianza mueven la frontera de verdad, y elegir al azar significa gastar buena parte del esfuerzo en puntos irrelevantes que además se cancelan entre sí.

Todo lo que sigue en esta carpeta son formas de gastar mejor el mismo presupuesto:

| Ataque | Mejora sobre el aleatorio |
| - | - |
| [[04 - Ataques dirigidos a una clase\|Label flipping dirigido]] | Concentra el veneno en una clase → los errores dejan de cancelarse |
| [[05 - Clean label attacks\|Clean label]] | No toca etiquetas: sobrevive a la revisión humana |
| [[08 - Backdoors y trojans en modelos\|Trojan / backdoor]] | Rendimiento intacto en datos limpios, control total ante el disparador |

# Cómo medirlo en un engagement

Si el alcance incluye evaluar la robustez del pipeline del cliente frente a envenenamiento, el procedimiento es este mismo, con tres exigencias añadidas:

1. **Reproducir con los datos reales del cliente**, no con sintéticos. Es la única forma de obtener el porcentaje de envenenamiento que de verdad hace daño en ese sistema.
2. **Medir por clase, no en agregado.** Reportar el nivel de veneno a partir del cual cada clase se degrada, y señalar la más frágil.
3. **Reportar la ventana ciega**: el rango de envenenamiento en el que el modelo está afectado y la monitorización del cliente no lo detectaría. <mark style="background: #FF5582A6;">Ese número —"hasta un X % de sus etiquetas pueden estar corrompidas sin que sus alertas salten"— es el hallazgo</mark>, mucho más que el hecho de que envenenar funcione.
