---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "La pérdida de margen de C&W convierte 'clasifica mal' en algo diferenciable, y la búsqueda binaria sobre c descubre el umbral de vulnerabilidad de cada entrada"
Fecha de actualización: 2026-07-29
Nota previa: "[[02 - Operadores proximales, soft thresholding y FISTA]]"
Nota siguiente: "[[04 - Implementación de EAD paso a paso]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

Las distancias de [[01 - ElasticNet (EAD) y la mezcla L1 + L2|la nota del objetivo]] miden la perturbación, pero no empujan hacia el error de clasificación. Hace falta una pérdida que sí lo haga y que además sea derivable. <mark style="background: #ADCCFFA6;">El enfoque ingenuo —pérdida 1 si acierta, 0 si falla— es inservible: una función indicadora tiene gradiente cero en todas partes, así que no dice hacia dónde moverse.</mark> La solución estándar es la formulación de margen de Carlini & Wagner.

# La pérdida de margen

Para un ataque no dirigido sobre la clase verdadera $y$, se mide **cuánto le saca el logit de la clase correcta al mejor competidor**:

$$f(x', y) = \max\Big(Z_y(x') - \max_{j \ne y} Z_j(x') + \kappa,\; 0\Big)$$

$Z_j$ son los **logits** (salidas antes del `softmax`). Un recorrido concreto sobre un clasificador MNIST:

1. **Estado inicial.** Clase verdadera 7 con $Z_7 = 2{,}8$; mejor competidor, clase 4 con $Z_4 = 1{,}2$. Con $\kappa = 0$: $2{,}8 - 1{,}2 + 0 = 1{,}6$. Positivo, así que la pérdida vale 1,6. El gradiente empujará a bajar $Z_7$ y subir $Z_4$.
2. **Tras perturbar.** Ahora $Z_7 = 1{,}0$ y el mejor competidor es la clase 2 con $Z_2 = 1{,}5$. El margen es $1{,}0 - 1{,}5 + 0 = -0{,}5$; la bisagra lo recorta a $\max(-0{,}5, 0) = 0$.

<mark style="background: #8000E1A6;">Ese cero es una transición de fase automática.</mark> Con pérdida adversarial nula, su gradiente desaparece y la optimización se reduce a minimizar $L_2$ con soft thresholding: el ataque deja de perseguir el error —ya lo tiene— y pasa a **limpiar** la perturbación. No hace falta lógica de cambio de modo; la bisagra lo produce sola.

## El parámetro $\kappa$

$\kappa$ exige que el competidor supere a la clase verdadera por un margen mínimo. Con $\kappa = 0$ basta con ganar por $0{,}001$. Con $\kappa > 0$ el ejemplo adversarial queda **más adentro** del territorio de la clase equivocada, y eso importa mucho más de lo que HTB sugiere:

> [!important]+ $\kappa$ es el mando de supervivencia del ataque
> Un ejemplo adversarial con margen $0{,}001$ muere con cualquier transformación por el camino: recompresión JPEG, reescalado, resize del navegador, cuantización a 8 bits, el resize del preprocesado del propio modelo. <mark style="background: #FFB86CA6;">Subir $\kappa$ cuesta distorsión pero compra supervivencia frente al pipeline real.</mark> Carlini y Wagner explotaron exactamente esto en [*Adversarial Examples Are Not Easily Detected: Bypassing Ten Detection Methods*, arXiv:1705.07263](https://arxiv.org/abs/1705.07263) (AISec 2017): los ejemplos de **alta confianza** atraviesan detectores que sí paran los de margen mínimo. En un engagement contra un sistema con detector, $\kappa$ es el primer parámetro que hay que subir.

# La implementación y sus trucos

```python
def compute_adversarial_loss(logits, labels_onehot, confidence, targeted=False):
    real  = torch.sum(labels_onehot * logits, dim=1)
    other = torch.max((1 - labels_onehot) * logits - labels_onehot * 10000, dim=1)[0]

    if targeted:
        loss = torch.clamp(other - real + confidence, min=0)
    else:
        loss = torch.clamp(real - other + confidence, min=0)
    return loss
```

Dos maniobras merecen explicación:

- **Extraer el logit verdadero sin indexar.** Multiplicar los logits por el vector *one-hot* anula todas las clases menos la correcta; sumar colapsa a un escalar por ejemplo. Es más rápido que `gather` dentro del bucle interno. Siguiendo el mismo ejemplo del dígito 7:

```python
logits  = [0.1, -0.3, 0.5, 0.9, 1.2, 0.7, -0.5, 2.8, 0.3, 0.4]   # índice 7 -> 2.8
onehot  = [0,    0,    0,   0,   0,   0,   0,   1,   0,   0]      # etiqueta = 7

real  = sum(o * z for o, z in zip(onehot, logits))                # 1 * 2.8      -> 2.8
# other: se anula la clase verdadera y se toma el máximo del resto
masked = [(1 - o) * z - o * 10000 for o, z in zip(onehot, logits)]
#        [0.1, -0.3, 0.5, 0.9, 1.2, 0.7, -0.5, -9997.2, 0.3, 0.4]
other = max(masked)                                               # 1.2 (clase 4)
# margen no dirigido = real - other + kappa = 2.8 - 1.2 + 0 = 1.6
```

> [!warning]+ El ejemplo de HTB no cuadra consigo mismo
> El módulo usa los logits `[0.1, -0.3, 0.5, 2.8, 1.2, 0.7, -0.5, 0.3, 0.9, 0.4]` con etiqueta 7 y afirma que el *one-hot* extrae `real = 2.8`. <mark style="background: #FF5582A6;">En ese vector, el índice 7 vale **0,3**; el 2,8 está en el índice 3.</mark> El bloque de arriba reordena el vector para que sea coherente con el recorrido del margen ($Z_7 = 2{,}8$, competidor $Z_4 = 1{,}2$). Vale la pena tenerlo presente al reproducir el laboratorio: si se copia el array tal cual y se comprueban los valores intermedios, no salen los del texto.

- **El `- labels_onehot * 10000`.** Resta 10 000 a la posición de la clase verdadera para que **nunca** pueda salir elegida como competidor máximo. Es un cinturón de seguridad sobre la máscara `(1 - labels_onehot)`, que ya debería bastar — pero cubre el caso real en que la clase verdadera tenga logit negativo y **todos** los demás también: sin la resta, `(1 - onehot) * logits` deja un 0 en esa posición que podría ser el máximo del vector. Barato y evita un fallo silencioso difícil de diagnosticar.

La variante **dirigida** invierte los papeles: se quiere que la clase objetivo supere al resto, así que la pérdida es $\max(\text{other} - \text{real} + \kappa,\, 0)$. Si el objetivo va en 2,0 y el mejor rival en 2,6, la pérdida es 0,6; cuando el objetivo pasa a 2,7 frente a 2,6, cae a 0. <mark style="background: #FFB8EBA6;">El ataque dirigido es sistemáticamente más caro:</mark> no basta con salirse de una clase, hay que llegar a una concreta, y eso exige perturbaciones mayores.

## Por qué logits y no probabilidades

FGSM usa entropía cruzada y solo le importa la **dirección** del gradiente; el valor de la pérdida es irrelevante porque se aplica un `sign`. EAD necesita la **magnitud** de la pérdida para pesarla contra la distorsión, y por eso trabaja sobre logits. Aplicar `softmax` antes introduce la restricción de que las probabilidades suman 1, lo que acopla artificialmente las clases y satura los gradientes cuando el modelo está muy seguro. Es el mismo argumento que reaparece —con otras consecuencias— en [[06 - JSMA, el Jacobiano y los mapas de saliencia|JSMA]].

# La pérdida total y el papel de $c$

$$\mathcal{L}_{\text{total}} = c \cdot f(x', y) + \lVert x' - x \rVert_2^2$$

El término $L_1$ **no aparece**: lo aplica el operador proximal, no el gradiente. Con margen $f = 0{,}6$ y $L_2^2 = 2{,}25$: si $c = 0{,}1$, la pérdida total es $2{,}31$; si $c = 1{,}0$, es $2{,}85$. Subir $c$ da más peso al error de clasificación frente a la distorsión.

El efecto es más claro a nivel de un solo píxel. Con perturbación $\delta = 0{,}15$, el gradiente $L_2$ vale $2 \times 0{,}15 = 0{,}30$ tirando **hacia el original**. Si el gradiente adversarial en ese píxel es $-2{,}5$:

- Con $c = 0{,}1$: $0{,}30 - 0{,}25 = 0{,}05$ — tirón neto hacia el original, avance mínimo.
- Con $c = 1{,}0$: $0{,}30 - 2{,}5 = -2{,}20$ — el signo se invierte y el píxel se lanza hacia el error de clasificación.

<mark style="background: #FF5582A6;">$c$ demasiado pequeño y el ataque falla; demasiado grande y produce perturbaciones innecesariamente enormes.</mark> El valor útil en MNIST vive entre 0,01 y 1,0, pero **varía por ejemplo**, y ahí está la clave.

# La búsqueda binaria sobre $c$

En lugar de fijar $c$ a mano, EAD mantiene cotas por ejemplo y las estrecha:

```python
if success_mask[i]:                                  # funcionó: probar c menor
    upper_bound[i] = min(upper_bound[i], const[i])
    if upper_bound[i] < 1e10:
        const[i] = (lower_bound[i] + upper_bound[i]) / 2
else:                                                 # falló: hace falta c mayor
    lower_bound[i] = max(lower_bound[i], const[i])
    if upper_bound[i] < 1e10:
        const[i] = (lower_bound[i] + upper_bound[i]) / 2
    else:
        const[i] *= 10                                # aún sin techo: crecer por escalas
```

La lógica es bisección clásica con un matiz: mientras **no se haya encontrado ningún éxito**, no hay cota superior finita, y bisecar no tiene sentido. Se multiplica $c$ por 10 para recorrer escalas ($0{,}001 \to 0{,}01 \to 0{,}1 \to 1 \to 10$) hasta el primer éxito; a partir de ahí toma el relevo la bisección.

> [!example]+ Traza de la búsqueda
> Arranque: $\text{lower}=0$, $\text{upper}=10^{10}$, $c=0{,}001$. Éxito → $\text{upper}=0{,}001$, biseca a $c=0{,}0005$. Fallo → $\text{lower}=0{,}0005$, biseca a $c=0{,}00075$. Tras cinco pasos el intervalo se ha estrechado $2^5 = 32$ veces.

**Cada ejemplo lleva sus propias cotas.** Uno pegado a la frontera converge a $c$ pequeño con distorsión mínima; uno resistente necesita $c$ grande y acepta más distorsión. <mark style="background: #8000E1A6;">Eso es lo que convierte a EAD en un ataque que descubre el umbral de vulnerabilidad de cada entrada, en vez de imponer un $\epsilon$ universal como FGSM.</mark> Conceptualmente se parece a lo que hace [[04 - DeepFool y la perturbación mínima|DeepFool]] con $\rho_{adv}$, pero por optimización en lugar de por geometría.

El precio es cómputo: cada paso de búsqueda binaria ejecuta un ciclo FISTA completo. Bajar de 9 a 5 pasos recorta el 45 % del cómputo a cambio de un 5-15 % más de distorsión final; subir a 9 reduce la distorsión un 3-8 % y cuesta un 80 % más. La regla práctica: **3-5 pasos** si los ejemplos son insumo de entrenamiento adversarial (importa el volumen), **7-9** si se está midiendo robustez para un informe (importa la precisión).

# Cómo evolucionan los gradientes

Saber qué esperar sirve para diagnosticar un ataque que no converge:

| Fase | Gradiente adversarial | Gradiente $L_2$ | Qué ocurre |
| - | - | - | - |
| Iteraciones 1-100 | 5-20 por píxel | 0,1-0,5 | Exploración agresiva hacia el error |
| Iteraciones 100-500 | 1-5 | 1-5 | Equilibrio; $L_2$ empieza a recortar excesos |
| Iteraciones 500-1000 | ~0 (bisagra saturada) | 0,1-1,0 | Solo refinamiento de distorsión |

Fuera de rango hay diagnóstico: gradientes por encima de 100 en las primeras iteraciones indican inestabilidad (el paso se pasa de largo y oscila; bajar la tasa de aprendizaje). Gradientes por debajo de 0,001 **antes** de la iteración 100 no son convergencia sino **estancamiento** en un mínimo local pobre.

Con objetivo y calibración definidos, queda ensamblar la iteración completa: [[04 - Implementación de EAD paso a paso|implementación de EAD]].
