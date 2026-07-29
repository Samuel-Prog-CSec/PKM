---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "La linear regression predice un valor continuo asumiendo una relación lineal entre las variables predictoras y el objetivo"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Aprendizaje supervisado]]"
Nota siguiente: "[[04 - Regresión logística]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">La `linear regression` predice un valor continuo asumiendo una relación lineal entre las variables predictoras y el objetivo.</mark> Es el algoritmo supervisado más simple que existe y sigue siendo relevante por dos motivos muy concretos: es completamente interpretable —cada coeficiente dice exactamente cuánto pesa cada feature— y es el caso base contra el que se compara cualquier modelo más complejo. Si una red neuronal no bate a una regresión lineal, el problema no necesitaba una red neuronal.

# Regresión simple y múltiple

Con una sola variable predictora, el modelo es la ecuación de una recta:

```text
y = m·x + c
```

Donde `m` es la pendiente —cuánto cambia `y` por cada unidad de `x`— y `c` la ordenada en el origen. Con varias predictoras se convierte en `multiple linear regression`:

```text
y = b₀ + b₁x₁ + b₂x₂ + … + bₙxₙ
```

Cada `bᵢ` cuantifica la contribución de su feature manteniendo las demás constantes. <mark style="background: #FFB8EBA6;">Esa lectura directa de los coeficientes es la razón de que la regresión lineal siga siendo obligatoria en dominios regulados</mark> —scoring crediticio, seguros, ensayos clínicos— donde la normativa exige poder explicar por qué el modelo decidió lo que decidió.

# Mínimos cuadrados ordinarios

![Diagrama de regresión lineal mostrando los residuos entre cada punto y la recta ajustada](https://academy.hackthebox.com/storage/modules/290/ols.png)

`Ordinary Least Squares` (OLS) es el método estándar para encontrar los coeficientes. El procedimiento:

1. **Calcular residuos** — para cada punto, la diferencia entre el valor real y el predicho.
2. **Elevarlos al cuadrado** — así todos son positivos y los errores grandes pesan desproporcionadamente más.
3. **Sumarlos** — se obtiene el `Residual Sum of Squares` (RSS), el error total del modelo.
4. **Minimizar el RSS** — ajustar coeficientes hasta que la suma sea mínima.

A diferencia de casi todo el resto del ML, OLS tiene **solución cerrada**: no hace falta iterar, se resuelve con álgebra lineal en un paso. Solo se recurre a `gradient descent` cuando el número de features es tan grande que invertir la matriz sale caro.

> [!warning]+ Elevar al cuadrado es una decisión, y tiene consecuencias
> Penalizar el error al cuadrado hace que **un único outlier arrastre toda la recta**. En datos de seguridad —donde los valores extremos son justo lo interesante— eso es un problema serio, y también un vector de manipulación: <mark style="background: #FF5582A6;">inyectar unos pocos puntos extremos en el conjunto de entrenamiento basta para desplazar el modelo entero</mark>. Es el ataque de envenenamiento más elemental que existe y funciona precisamente por esta propiedad. Alternativas robustas: regresión de Huber, RANSAC, o regresión cuantílica.

# Supuestos del modelo

La regresión lineal solo es válida si los datos cumplen cuatro condiciones. Violarlas no impide que el modelo se entrene — impide que sus resultados signifiquen algo.

| Supuesto | Qué exige | Qué pasa si falla |
| - | - | - |
| `Linearity` | La relación entre predictoras y objetivo es lineal | El modelo captura mal el patrón; sesgo sistemático |
| `Independence` | Las observaciones son independientes entre sí | Errores correlacionados; intervalos de confianza inválidos |
| `Homoscedasticity` | La varianza del error es constante en todo el rango | Coeficientes ineficientes; predicciones poco fiables en los extremos |
| `Normality` | Los errores siguen una distribución normal | Los tests de significancia sobre los coeficientes dejan de ser válidos |

La independencia es la que más se incumple en seguridad sin que nadie se dé cuenta: los datos de red y de logs son series temporales con autocorrelación fuerte, no muestras independientes.

# Variantes regularizadas

La formulación clásica de OLS no incluye regularización, y sin ella un modelo con muchas features sobreajusta y sufre de `multicollinearity`. En la práctica se usan casi siempre estas tres variantes, que HTB no menciona pero son el estándar en `scikit-learn`:

| Variante | Penalización | Efecto |
| - | - | - |
| `Ridge` | `L2` sobre los coeficientes | Encoge todos los coeficientes; estabiliza ante features correlacionadas |
| `Lasso` | `L1` sobre los coeficientes | Lleva coeficientes a cero exacto: selección automática de features |
| `Elastic Net` | Combinación de `L1` y `L2` | Compromiso entre ambas; el más usado cuando hay muchas features correlacionadas |

`Lasso` tiene una utilidad ofensiva directa: al anular coeficientes, revela **qué features son realmente irrelevantes** para el modelo. Sobre un modelo del que se ha obtenido una copia por extracción, es una forma rápida de saber dónde no merece la pena esforzarse.

# Evaluación

Las métricas de regresión no son las de clasificación:

- **`RMSE`** (raíz del error cuadrático medio) — error medio en las unidades de la variable objetivo. Penaliza mucho los errores grandes.
- **`MAE`** (error absoluto medio) — error medio sin elevar al cuadrado. Más robusto ante outliers y más fácil de comunicar.
- **`R²`** — proporción de la varianza explicada por el modelo, de 0 a 1. <mark style="background: #FFB8EBA6;">Sube automáticamente al añadir features aunque sean ruido</mark>, así que para comparar modelos con distinto número de variables hay que usar el `R²` ajustado.

# Por qué le interesa a un atacante

Los modelos lineales son el caso degenerado del ML adversarial, y estudiarlos aquí ahorra trabajo después:

<mark style="background: #8000E1A6;">Como el modelo es una función lineal, su gradiente respecto a la entrada es constante e igual al vector de coeficientes.</mark> No hay que calcular nada: los propios pesos indican en qué dirección mover cada feature para alterar la predicción todo lo posible, y cuánto. <mark style="background: #FFB86CA6;">La perturbación adversarial óptima tiene forma cerrada</mark> — no hace falta iterar como en `PGD` ni estimar gradientes como en un ataque `black-box`.

Eso convierte cualquier sistema de scoring lineal en un objetivo trivial **si consigues los coeficientes**, que es exactamente lo que persiguen los ataques de extracción de modelo. Y aunque el modelo de producción sea una red neuronal, el intuir el mecanismo aquí es lo que hace comprensible el resto: los ataques de primer orden son esta misma idea aplicada localmente a un modelo no lineal.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con variantes regularizadas (`Ridge`/`Lasso`/`Elastic Net`), métricas de evaluación y la lectura adversarial, ausentes en el original.
- Imagen de residuos: HTB Academy, módulo 290.
