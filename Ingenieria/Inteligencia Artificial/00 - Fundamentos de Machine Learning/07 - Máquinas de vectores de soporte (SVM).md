---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Una Support Vector Machine busca el hiperplano que separa las clases dejando el mayor margen posible a ambos lados"
Fecha de actualización: 2026-07-28
Nota previa: "[[06 - Naive Bayes]]"
Nota siguiente: "[[08 - Aprendizaje no supervisado]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">Una `Support Vector Machine` busca el hiperplano que separa las clases dejando el mayor margen posible a ambos lados.</mark> No le basta con encontrar *una* frontera que funcione —eso ya lo hace la [[04 - Regresión logística]]— sino la que queda más alejada de los datos de las dos clases. Esa idea, maximizar el margen, es lo que le da su capacidad de generalización y lo que la convirtió en el algoritmo dominante antes de la irrupción del deep learning.

![Frontera de decisión de una SVM con márgenes y vectores de soporte marcados](https://academy.hackthebox.com/storage/modules/290/svm.png)

# Margen y vectores de soporte

El `margin` es la distancia entre el hiperplano y los puntos más cercanos de cada clase. Esos puntos son los `support vectors`, y son los únicos que definen el modelo: <mark style="background: #FFB8EBA6;">si borras cualquier otro ejemplo del conjunto de entrenamiento, el hiperplano no se mueve</mark>. Toda la información del modelo está concentrada en un puñado de ejemplos frontera.

El hiperplano se define como:

```text
w · x + b = 0
```

Donde `w` es el vector de pesos (perpendicular al hiperplano), `x` el vector de features y `b` el sesgo que lo desplaza del origen. El entrenamiento resuelve un problema de optimización con restricciones:

```text
Minimizar:  ½ ‖w‖²
Sujeto a:   yᵢ(w · xᵢ + b) ≥ 1   para todo i
```

Minimizar la norma de `w` equivale a maximizar el margen, y la restricción obliga a que todos los puntos queden bien clasificados y fuera del margen.

## El margen blando: lo que falta en la formulación anterior

Esa formulación es de **margen duro** y exige que los datos sean perfectamente separables. Con datos reales —ruido, solapamiento entre clases, etiquetas erróneas— no tiene solución. Toda SVM utilizable en la práctica usa el **margen blando**, que introduce variables de holgura y un hiperparámetro `C`:

| Valor de `C` | Comportamiento |
| - | - |
| `C` alto | Penaliza mucho los errores: margen estrecho, se ajusta a los datos, riesgo de sobreajuste |
| `C` bajo | Tolera errores: margen ancho, modelo más general, riesgo de subajuste |

`C` es el hiperparámetro que de verdad se tunea en una SVM. Presentar solo la versión de margen duro deja fuera la única variante que se despliega.

# SVM no lineal y el truco del kernel

![Frontera de decisión no lineal producida por una SVM con kernel](https://academy.hackthebox.com/storage/modules/290/svm_non_linear.png)

Cuando las clases no son separables por un hiperplano, se recurre al `kernel trick`: proyectar los datos a un espacio de dimensión mayor donde sí lo sean. La clave es que **no se calcula esa proyección explícitamente**; el kernel computa directamente el producto escalar en el espacio destino, que es lo único que la optimización necesita. Por eso proyectar a un espacio de dimensión infinita sale barato.

| Kernel | Cuándo usarlo |
| - | - |
| `Linear` | Muchísimas features respecto a ejemplos — texto vectorizado, por ejemplo. Rápido e interpretable |
| `RBF` (gaussiano) | Opción por defecto. Captura fronteras complejas; se controla con `gamma` |
| `Polynomial` | Cuando se sabe que hay interacciones de grado concreto entre features |
| `Sigmoid` | Poco usado en la práctica; equivale a una red neuronal de una capa |

`gamma` regula cuánto influye cada ejemplo individual: valores altos producen fronteras muy contorneadas alrededor de cada punto —sobreajuste—; valores bajos, fronteras casi lineales. <mark style="background: #FFB8EBA6;">`C` y `gamma` no se ajustan por separado</mark>: interactúan, y un `gamma` alto puede compensar un `C` bajo y viceversa, así que se buscan juntos en rejilla.

> [!info]+ La SVM no devuelve probabilidades
> Su salida natural es la **distancia con signo al hiperplano**, no una probabilidad. Para obtener uno hay que activar `probability=True`, que ajusta por detrás una regresión logística sobre esas distancias (escalado de Platt) mediante validación cruzada interna: encarece el entrenamiento notablemente y, al usar una partición distinta, puede producir una probabilidad **incoherente con la etiqueta** que devuelve `predict()` en casos límite.
>
> Encaja con lo visto en [[04 - Regresión logística]] y [[06 - Naive Bayes]]: de los modelos clásicos, solo la regresión logística da probabilidades fiables de fábrica. Si el sistema necesita un umbral bien calibrado —y en detección casi siempre lo necesita—, eso condiciona la elección de algoritmo.

> [!warning]+ Escalar las features no es opcional
> La SVM opera sobre distancias. Si una feature va de 0 a 1 y otra de 0 a 100.000, la segunda domina por completo el cálculo del margen y la primera se vuelve irrelevante. <mark style="background: #FF5582A6;">Entrenar una SVM sin normalizar es un error silencioso</mark>: el modelo entrena, da métricas, y está ignorando la mitad de la información. Lo mismo aplica a [[09 - K-Means y clustering]] y a cualquier método basado en distancia. Los árboles, en cambio, son inmunes.

# Por qué dejó de ser la opción por defecto

Las SVM tienen un problema de escala: el entrenamiento cuesta entre `O(n²)` y `O(n³)` según implementación, con `n` el número de ejemplos. A partir de decenas de miles de muestras se vuelve inviable, mientras que los ensembles de árboles y las redes neuronales escalan linealmente. Siguen siendo excelentes en el régimen contrario —pocos ejemplos, muchísimas features— que es justo el caso de clasificación de texto y de algunos problemas de bioinformática.

# Lectura ofensiva

<mark style="background: #FFB86CA6;">Los vectores de soporte **son** ejemplos reales del conjunto de entrenamiento, almacenados literalmente dentro del modelo.</mark> Un modelo SVM entrenado sobre datos sensibles no contiene una abstracción de esos datos: contiene una copia de un subconjunto de ellos. <mark style="background: #8000E1A6;">Filtrar el fichero del modelo equivale a filtrar parte del dataset</mark> — un riesgo de privacidad que no existe con una red neuronal, donde los datos quedan disueltos en los pesos. Si en un engagement encuentras un `.pkl` de una SVM en un bucket expuesto, tienes datos de entrenamiento, no solo un modelo.

Dos consecuencias más:

- **Superficie de evasión concentrada.** Como solo los vectores de soporte definen la frontera, un envenenamiento dirigido a convertir puntos elegidos por el atacante en vectores de soporte desplaza el hiperplano con muy pocas muestras. Es el escenario del trabajo fundacional de [Biggio, Nelson & Laskov, *Poisoning Attacks against Support Vector Machines* (ICML 2012)](https://arxiv.org/abs/1206.6389), anterior a todo el trabajo sobre ejemplos adversariales en redes profundas.
- **Diferenciable, luego atacable con gradientes.** A diferencia de los árboles, la función de decisión de una SVM es diferenciable respecto a la entrada, así que los ataques de primer orden aplican directamente. Fue el modelo sobre el que Biggio et al. demostraron en 2013 la evasión en tiempo de test, meses antes de que el mismo fenómeno se popularizara en redes neuronales.

Una variante que conviene tener presente: la **`One-Class SVM`**, que aprende la frontera que envuelve a los datos "normales" y marca como anómalo todo lo que quede fuera. Es uno de los detectores de anomalías clásicos — ver [[11 - Detección de anomalías]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con el margen blando y el hiperparámetro `C`, los costes de escalado y la lectura de privacidad de los vectores de soporte, ausentes en el original.
- [Biggio, Nelson & Laskov, *Poisoning Attacks against Support Vector Machines*, ICML 2012](https://arxiv.org/abs/1206.6389) — envenenamiento dirigido a los vectores de soporte (consultado 2026-07-28).
- Imágenes de margen y frontera no lineal: HTB Academy, módulo 290.
