---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "FGSM genera un ejemplo adversarial en un solo paso: sigue el signo del gradiente respecto a la entrada, cambiando cada píxel en ε la dirección que más aumenta la pérdida"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - Normas Lp y el presupuesto de perturbación]]"
Nota siguiente: "[[03 - I-FGSM, PGD y el refinamiento iterativo]]"
Area: "[[Ataques de primer orden.base|Ataques de primer orden]]"
---
---

<mark style="background: #ADCCFFA6;">FGSM genera un ejemplo adversarial en **un solo paso**: calcula el gradiente respecto a la entrada y mueve cada píxel una cantidad fija $\epsilon$ en la dirección que más aumenta la pérdida.</mark> Es el ataque fundacional del ML adversarial moderno, y su simplicidad —una pasada, un paso, listo— lo convirtió en la línea base para medir robustez. Lo introdujeron Goodfellow et al. en 2014 ([*Explaining and Harnessing Adversarial Examples*](https://arxiv.org/abs/1412.6572)).

# La fórmula

Con entrada $x$, etiqueta $y$, parámetros $\theta$ y pérdida $\mathcal{L}(\theta, x, y)$, el ejemplo adversarial es:

$$x_{\text{adv}} = x + \epsilon \, \operatorname{sign}\big(\nabla_x \, \mathcal{L}(\theta, x, y)\big)$$

Tres piezas:

- $\nabla_x \mathcal{L}$ — el [[00 - Ataques de primer orden y el papel del gradiente|gradiente respecto a la entrada]], el mapa de sensibilidad de cada píxel.
- $\operatorname{sign}(\cdot)$ — se queda **solo con la dirección** (+ o −) de cada componente, descartando la magnitud. Así cada píxel cambia exactamente $\epsilon$.
- $\epsilon$ — el **presupuesto** de perturbación: el compromiso entre imperceptibilidad (pequeño) y fuerza del ataque (grande).

<mark style="background: #FFB86CA6;">El `sign` es la clave: iguala el tamaño del paso en todos los píxeles, lo que hace que la perturbación respete exactamente la restricción $L_\infty$</mark> — el cambio máximo en cualquier píxel es $\epsilon$, ni más ni menos.

# Untargeted vs. targeted

FGSM tiene dos objetivos, que solo difieren en el signo del paso y la etiqueta usada:

| Variante | Objetivo | Fórmula |
| - | - | - |
| **Untargeted** | Alejarse de la clase verdadera $y$ | $x + \epsilon \operatorname{sign}(\nabla_x \mathcal{L}(\theta, x, y))$ |
| **Targeted** | Acercarse a una clase objetivo $y_t$ | $x - \epsilon \operatorname{sign}(\nabla_x \mathcal{L}(\theta, x, y_t))$ |

El *untargeted* **aumenta** la pérdida de la clase verdadera (asciende el gradiente); el *targeted* **reduce** la pérdida de la clase deseada (desciende el gradiente con $y_t$). <mark style="background: #FFB8EBA6;">El `targeted` suele necesitar un $\epsilon$ mayor</mark>, porque no basta con confundir: hay que dirigir la predicción a una clase concreta. En un `1 → 7` sobre MNIST, $\epsilon = 0{,}5$ falla y $\epsilon = 0{,}8$ funciona.

# Por qué funciona: la desigualdad de Hölder

FGSM no es una heurística: es la **solución exacta** de un problema de optimización. Se quiere la perturbación dentro de una bola $L_\infty$ de radio $\epsilon$ que maximiza la pérdida:

$$\max_{\|\delta\|_\infty \leq \epsilon} \mathcal{L}(\theta, x+\delta, y)$$

Aproximando la pérdida con Taylor de primer orden alrededor de $x$, el término constante no afecta al máximo y el problema se reduce a maximizar $g^\top \delta$ con $g = \nabla_x \mathcal{L}$. Aquí entra la **desigualdad de Hölder** con la dualidad $L_\infty$–$L_1$ ([[01 - Normas Lp y el presupuesto de perturbación|vista en la nota anterior]]):

$$g^\top \delta \leq \|\delta\|_\infty \, \|g\|_1 = \epsilon \, \|g\|_1$$

La igualdad —el máximo— se alcanza **exactamente** cuando $\delta$ se alinea componente a componente con el signo de $g$:

$$\delta^* = \epsilon \, \operatorname{sign}(g)$$

<mark style="background: #8000E1A6;">Eso *es* FGSM: el signo del gradiente es el maximizador óptimo del problema linealizado bajo $L_\infty$.</mark> Geométricamente, se sustituye la superficie de pérdida curva por un plano tangente en $x$, y maximizar un plano sobre una caja (la bola $L_\infty$) empuja cada coordenada a su borde con el signo del gradiente.

# Por qué basta con tan poco: dimensionalidad

La [[00 - Ataques de primer orden y el papel del gradiente#Por qué funcionan: linealidad local y alta dimensionalidad|acumulación en alta dimensión]] se ve explícita en un modelo lineal $f(x) = w^\top x$. El cambio en el logit por una perturbación con $\|\delta\|_\infty \leq \epsilon$ está acotado por:

$$|f(x+\delta) - f(x)| = |w^\top \delta| \leq \epsilon \, \|w\|_1$$

> [!example]+ El cálculo que asusta
> Una imagen MNIST tiene 784 píxeles. Si cada peso tiene magnitud 0,01, entonces $\|w\|_1 = 784 \times 0{,}01 = 7{,}84$. Con $\epsilon = 0{,}1$, el cambio máximo del logit es $0{,}1 \times 7{,}84 = 0{,}784$ — suficiente para voltear una decisión. **Cada píxel cambia como mucho 0,1, pero 784 cambios alineados suman 0,784.** En una imagen de ImageNet (150.000+ píxeles) el efecto es mucho mayor.

Esto convierte la vaga idea de "sensibilidad en alta dimensión" en una cota concreta: aunque cada píxel cambie poco, el efecto agregado crece con el número de dimensiones y con cuánto se alinean con el gradiente.

# Presupuestos alternativos: otras normas

El paso con `sign` es específico de $L_\infty$. Para otras normas, la dualidad da otro maximizador:

- **$L_2$**: dirección del gradiente **normalizada**, no su signo: $\delta^*_2 = \epsilon \frac{g}{\|g\|_2}$. Preserva las magnitudes relativas.
- **$L_1$**: concentra el presupuesto en las coordenadas de mayor gradiente absoluto (perturbación dispersa).

# Cálculo en la práctica

El gradiente respecto a la entrada sale de un `backward pass` con los pesos congelados:

```python
def fgsm_attack(model, x, y, epsilon, targeted=False):
    x = x.clone().detach().requires_grad_(True)
    loss = F.cross_entropy(model(x), y)
    loss.backward()                          # ∇_x L en x.grad
    sign = x.grad.sign()
    x_adv = x - epsilon*sign if targeted else x + epsilon*sign
    return x_adv.clamp(x_min, x_max).detach()  # recortar al dominio válido
```

Con entropía cruzada, el gradiente tiene una forma reveladora: los coeficientes son $p_i(x) - \mathbb{1}[i=y]$. Para la clase verdadera, el coeficiente es $-(1-p_y)$: <mark style="background: #FFB86CA6;">cuanta más confianza tiene el modelo ($p_y \to 1$), **menor** es el gradiente</mark> — un modelo muy seguro da un gradiente pequeño (coeficiente −0,05 con $p_y = 0{,}95$), uno dudoso da uno grande (−0,80 con $p_y = 0{,}20$). El ataque empuja a bajar el logit verdadero y subir los competidores.

# El límite de FGSM

FGSM es rápido y efectivo como línea base, pero un solo paso **aproxima una superficie curva con un plano**. Cuando la geometría local no es lineal, el paso único se queda corto. Ahí es donde [[03 - I-FGSM, PGD y el refinamiento iterativo|iterar]] mejora radicalmente el resultado con el mismo presupuesto, y donde [[04 - DeepFool y la perturbación mínima|DeepFool]] cambia la pregunta a "¿cuál es la perturbación mínima?". Las [[04 - Detección y defensa contra la evasión|defensas]] contra FGSM —empezando por el entrenamiento adversarial, que usa el propio FGSM para endurecer el modelo— están en la carpeta de fundamentos.
