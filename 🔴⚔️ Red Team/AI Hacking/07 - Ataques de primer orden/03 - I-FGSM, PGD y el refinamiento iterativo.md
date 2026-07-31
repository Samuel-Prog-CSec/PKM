---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "En vez de un paso grande, I-FGSM da muchos pequeños reevaluando el gradiente y proyectando al presupuesto: mismo ε, mucha más efectividad, y es la base de PGD"
Fecha de actualización: 2026-07-29
Nota previa: "[[02 - FGSM, el ataque de un solo paso]]"
Nota siguiente: "[[04 - DeepFool y la perturbación mínima]]"
Area: "[[Ataques de primer orden.base|Ataques de primer orden]]"
---
---

<mark style="background: #ADCCFFA6;">En vez de un paso grande, I-FGSM da varios pequeños: cada uno sigue el signo del gradiente y proyecta de vuelta al presupuesto $\epsilon$.</mark> Con el mismo presupuesto que [[02 - FGSM, el ataque de un solo paso|FGSM]], pasa de un 57,8% a un 95,3% de éxito. El motivo es geométrico: un solo paso aproxima una superficie curva con un plano; reevaluar el gradiente tras cada paso sigue la curvatura real. Lo introdujeron Kurakin et al. en 2016 ([*Adversarial Examples in the Physical World*](https://arxiv.org/abs/1607.02533)), y es también conocido como `BIM` (*Basic Iterative Method*).

# La actualización con proyección

Partiendo de $x^{(0)} = x$, cada iteración da un paso de tamaño $\alpha$ y **proyecta** de vuelta a la bola $L_\infty$ de radio $\epsilon$ alrededor de la imagen original:

$$x^{(t+1)} = \Pi_{\mathcal{B}_\infty(x,\epsilon)}\big(x^{(t)} + \alpha \, \operatorname{sign}(\nabla_{x^{(t)}} \mathcal{L}(\theta, x^{(t)}, y))\big)$$

- $\alpha$ — el tamaño del paso, típicamente $\alpha = \epsilon / T$ para $T$ iteraciones.
- $\Pi_{\mathcal{B}_\infty(x,\epsilon)}$ — la **proyección**: recorta la perturbación acumulada para que ningún píxel se aleje más de $\epsilon$ del original.

<mark style="background: #FFB86CA6;">La proyección no es un regularizador extra: es la forma matemática de decir "quédate dentro del mismo presupuesto por píxel después de cada paso".</mark> En coordenadas es simplemente recorte (`clip`) por píxel:

$$\Pi_{\mathcal{B}_\infty(x,\epsilon)}(x') = x + \operatorname{clip}(x' - x, -\epsilon, \epsilon)$$

Así, las mejoras vienen de **direcciones mejores**, no de un presupuesto mayor.

# Por qué iterar ayuda

El primer paso desde $x$ sigue el gradiente en $x$, que es el maximizador exacto del problema linealizado ([[02 - FGSM, el ataque de un solo paso#Por qué funciona: la desigualdad de Hölder|Hölder bajo $L_\infty$]]). Pero tras ese paso, la superficie de pérdida ya **no** está bien aproximada por el plano tangente original. Recalcular el gradiente en $x^{(t)}$ y dar otro paso proyectado se ajusta a la nueva geometría local.

> [!example]+ La ganancia de iterar, en números
> FGSM con $\epsilon = 0{,}8$ mueve la pérdida de 0,3 a 1,2 (cambio de 0,9). I-FGSM con 10 iteraciones y $\alpha = 0{,}08$ la lleva de 0,3 a **1,68** (cambio de 1,38) recorriendo la superficie curva paso a paso: 0,3 → 0,45 → 0,62 → ... → 1,68. Un **53% más** de aumento de pérdida con el mismo presupuesto $L_\infty$.

La comparación directa sobre el mismo lote lo confirma:

| Método | Tasa de éxito ($\epsilon = 0{,}7$) |
| - | - |
| FGSM (un paso) | 57,8 % |
| **I-FGSM (10 iteraciones)** | **95,3 %** |

<mark style="background: #FFB86CA6;">Una mejora relativa del 64,9%, sin tocar el presupuesto.</mark> El refinamiento iterativo explota mejor la superficie de pérdida dentro de la misma restricción por píxel.

# Los hiperparámetros: α, T y arranque aleatorio

Elegir $\alpha$ y $T$ equilibra velocidad y fuerza:

- **$\alpha$ grande, pocas iteraciones** ($\alpha = 0{,}1$, $T = 2$): rápido pero puede sobrepasar el óptimo. Saltos bruscos: 0,3 → 0,9 → 1,1.
- **$\alpha$ pequeño, muchas iteraciones** ($\alpha = 0{,}01$, $T = 20$): refina gradualmente, sigue mejor la curvatura y suele encontrar adversariales más fuertes.

El **arranque aleatorio** (*random start*) añade otra dimensión: iniciar con ruido uniforme $\delta \in [-\epsilon, \epsilon]$ antes de iterar explora caminos distintos por el paisaje de pérdida. <mark style="background: #8000E1A6;">Sube el éxito del 85% al 92% con el mismo presupuesto</mark>, convirtiendo casi-fallos en éxitos al escapar de vecindarios donde el gradiente no apunta a ningún sitio útil.

```python
def iterative_fgsm(model, x, y, epsilon, num_iter, alpha, random_start=True):
    x_adv = x.clone().detach()
    if random_start:
        x_adv += torch.empty_like(x_adv).uniform_(-epsilon, epsilon)
    for _ in range(num_iter):
        x_adv.requires_grad_(True)
        loss = F.cross_entropy(model(x_adv), y)
        grad = torch.autograd.grad(loss, x_adv)[0]
        x_adv = x_adv.detach() + alpha*grad.sign()
        # proyeccion a la bola L∞ + recorte al dominio
        x_adv = x + (x_adv - x).clamp(-epsilon, epsilon)
        x_adv = x_adv.clamp(x_min, x_max)
    return x_adv.detach()
```

# La relación con PGD

<mark style="background: #FF5582A6;">I-FGSM con arranque aleatorio **es** PGD.</mark> El `Projected Gradient Descent`, formalizado por Madry et al. en 2017 ([*Towards Deep Learning Models Resistant to Adversarial Attacks*](https://arxiv.org/abs/1706.06083)), es la forma general de los ataques iterativos con restricción. La equivalencia:

| Método | Definición |
| - | - |
| **BIM** | I-FGSM sin inicialización aleatoria |
| **I-FGSM** | Pasos de signo proyectados, $\alpha = \epsilon/T$ |
| **PGD** | I-FGSM + arranque aleatorio + (opcional) múltiples reinicios |

Los **reinicios múltiples** de PGD prueban varias inicializaciones y se quedan con el adversarial más fuerte encontrado, aumentando la fiabilidad al escapar de óptimos locales pobres. Conceptualmente, **PGD = I-FGSM + aleatorización + varios intentos**.

Esta equivalencia es la razón de que PGD sea el estándar de facto: es el ataque con el que se hace [[04 - Detección y defensa contra la evasión|entrenamiento adversarial]] (el más efectivo) y con el que se **evalúa** la robustez (junto a AutoAttack). Un modelo "robusto a FGSM" que cae ante PGD no es robusto — solo tenía [[04 - Detección y defensa contra la evasión|gradient masking]].

# La variante targeted

Como en FGSM, la versión dirigida cambia la etiqueta a la objetivo $y_t$ e invierte el signo, repitiendo con proyección:

$$x^{(t+1)} = \Pi_{\mathcal{B}_\infty(x,\epsilon)}\big(x^{(t)} - \alpha \, \operatorname{sign}(\nabla_{x^{(t)}} \mathcal{L}(\theta, x^{(t)}, y_t))\big)$$

El objetivo dirigido necesita más iteraciones o $\epsilon$ mayor, y se beneficia de $\alpha$ pequeño con muchos pasos, arranque aleatorio y *early stopping* al predecir $y_t$. Un detalle práctico: <mark style="background: #FFB8EBA6;">I-FGSM logra el `1 → 7` con $\epsilon = 0{,}8$ donde FGSM necesitaba $\epsilon = 1{,}0$</mark> — el refinamiento iterativo también reduce el presupuesto necesario en ataques dirigidos.

I-FGSM y PGD siguen imponiendo un presupuesto de antemano. El siguiente ataque, [[04 - DeepFool y la perturbación mínima|DeepFool]], invierte la pregunta: busca la perturbación mínima sin fijar $\epsilon$.
