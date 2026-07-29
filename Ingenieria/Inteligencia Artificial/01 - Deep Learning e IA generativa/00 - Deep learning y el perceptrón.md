---
tags:
  - IA
  - IA/Deep-Learning
  - Introduccion
  - Tipo/Introduccion
Descripción: "El deep learning es el subcampo del ML que usa redes neuronales con muchas capas para aprender representaciones directamente de los datos crudos"
Fecha de actualización: 2026-07-28
Nota previa: "[[14 - SARSA y el aprendizaje on-policy]]"
Nota siguiente: "[[01 - Redes neuronales]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">El `deep learning` es el subcampo del ML que usa redes neuronales con muchas capas para aprender representaciones directamente de los datos crudos.</mark> Su diferencia operativa con el ML clásico es una sola: **elimina el `feature engineering` manual**. Donde un `Random Forest` exige que un humano decida qué medir de un binario o de un flujo de red, una red profunda descubre esas representaciones durante el entrenamiento.

> [!warning]+ La analogía con el cerebro es marketing, no arquitectura
> Es habitual justificar el deep learning diciendo que "imita el cerebro humano". La inspiración biológica es real pero histórica y muy laxa: <mark style="background: #FFB8EBA6;">una red neuronal artificial no se parece a una red de neuronas biológicas más de lo que un avión se parece a un pájaro</mark>. No hay potenciales de acción, ni neurotransmisores, ni plasticidad local — hay multiplicaciones de matrices y una regla de derivación en cadena.
>
> La explicación real de por qué funciona no es neurológica sino material: `backpropagation` (1986) permitió entrenar redes multicapa, y a partir de 2012 la conjunción de datasets masivos y GPUs hizo viable entrenarlas a escala. `AlexNet` ganando ImageNet en 2012 es el hito habitual. Confundir la metáfora con el mecanismo lleva a razonar mal sobre qué puede y qué no puede hacer un modelo.

# Conceptos que estructuran cualquier red

| Concepto | Qué es |
| - | - |
| `Neurona` | Unidad de cómputo: suma ponderada de entradas + sesgo, pasada por una activación |
| `Capas` | Entrada, ocultas (donde ocurre el aprendizaje) y salida |
| `Pesos` y `sesgos` | Los parámetros que se aprenden. Un modelo "es" su conjunto de pesos |
| `Función de activación` | Introduce la no linealidad. Sin ella, apilar capas no aporta nada |
| `Función de pérdida` | Mide el error entre predicción y objetivo. `MSE` en regresión, `cross-entropy` en clasificación |
| `Backpropagation` | Calcula el gradiente de la pérdida respecto a cada parámetro, propagando el error hacia atrás |
| `Optimizador` | Decide cómo aplicar ese gradiente para actualizar los pesos |
| `Hiperparámetros` | Lo que se fija antes de entrenar: tasa de aprendizaje, número de capas, tamaño de lote |

Sobre optimizadores conviene actualizar la lista habitual: `SGD` y `Adam` siguen siendo la referencia conceptual, pero <mark style="background: #FFB8EBA6;">el estándar de facto para entrenar redes grandes es `AdamW`</mark>, que corrige cómo `Adam` aplica la regularización por decaimiento de pesos. Ver un `SGD` puro en código nuevo suele indicar o un caso muy específico o un tutorial antiguo.

# El perceptrón

Es la unidad mínima y el mejor sitio para ver la mecánica sin ruido.

![Diagrama de un perceptrón: entradas x1..xn con pesos, sumatorio, sesgo y función de activación](https://academy.hackthebox.com/storage/modules/290/02%20-%20Perceptrons_0.png)

- **Entradas** `x₁ … xₙ` — las features.
- **Pesos** `w₁ … wₙ` — la importancia de cada entrada. Pueden ser negativos.
- **Sumatorio** — `Σ(wᵢ · xᵢ)`.
- **Sesgo** `b` — desplaza el umbral; permite que la neurona se active aunque todas las entradas sean cero.
- **Activación** `f` — aplica no linealidad al resultado.
- **Salida** `y`.

## Ejemplo trabajado

Decidir si jugar al tenis con cuatro features (`Outlook`, `Temperature`, `Humidity`, `Wind`), pesos `0,3 / 0,2 / −0,4 / −0,2` y sesgo `0,1`, usando una activación escalón:

```python
def step_activation(x):
    """Devuelve 1 si la entrada es positiva, 0 en caso contrario."""
    return 1 if x > 0 else 0

# Día: Sunny(0), Mild(1), High(0), Weak(0)
outlook, temperature, humidity, wind = 0, 1, 0, 0
w1, w2, w3, w4, b = 0.3, 0.2, -0.4, -0.2, 0.1

weighted_sum = (w1 * outlook) + (w2 * temperature) + (w3 * humidity) + (w4 * wind)
output = step_activation(weighted_sum + b)   # 0.2 + 0.1 = 0.3 -> 1

print(f"Salida: {output}")   # 1 -> jugar al tenis
```

<mark style="background: #8000E1A6;">Ese cálculo es idéntico a la [[04 - Regresión logística]] salvo por la función de activación.</mark> Un perceptrón con activación sigmoide **es** una regresión logística. Toda la potencia del deep learning sale de apilar y componer esta operación, no de que la unidad sea sofisticada.

## Su límite: XOR

Un perceptrón de una sola capa solo puede aprender fronteras **lineales**. El caso canónico que no puede resolver es la función `XOR`, que devuelve 1 cuando exactamente una de sus dos entradas es 1: no existe ninguna recta que separe los casos verdaderos de los falsos.

Esa limitación, señalada por Minsky y Papert en 1969, congeló la investigación en redes neuronales durante más de una década. La solución —apilar capas con activaciones no lineales— es el contenido de [[01 - Redes neuronales]].

# Funciones de activación

| Función | Rango | Estado en 2026 |
| - | - | - |
| `Sigmoid` | (0, 1) | Legado en capas ocultas por el gradiente evanescente. Vive en la salida binaria |
| `Tanh` | (−1, 1) | Como sigmoide pero centrada en 0. Sobrevive en algunas RNN |
| `ReLU` | [0, ∞) | El caballo de batalla: barata y sin saturación en positivos |
| `GELU` / `SiLU` | ≈ ReLU suavizada | <mark style="background: #FFB8EBA6;">Lo que usan realmente los `transformers` modernos</mark>. Rinden algo mejor que ReLU |
| `Softmax` | Distribución | Capa de salida en clasificación multiclase |

# Por qué todo esto importa desde el lado ofensivo

<mark style="background: #FFB86CA6;">La propiedad que hace entrenable a una red —que sea diferenciable de extremo a extremo— es exactamente la que la hace atacable.</mark> `Backpropagation` calcula el gradiente de la pérdida respecto a los **pesos**; cambiando una línea, el mismo grafo de derivación automática calcula el gradiente respecto a la **entrada**, que es la receta directa de un ejemplo adversarial.

No hay forma de tener una sin la otra. <mark style="background: #FF5582A6;">La vulnerabilidad a ataques de gradiente no es un defecto de implementación que se pueda parchear: es una consecuencia estructural de cómo se entrenan estos modelos.</mark> Las defensas realistas mitigan (entrenamiento adversarial, detección, limitación de consultas), no eliminan.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la corrección de la analogía cerebral, activaciones modernas (`GELU`/`SiLU`), `AdamW` y la dualidad entrenamiento↔ataque, ausentes en el original.
- Imagen del perceptrón: HTB Academy, módulo 290.
