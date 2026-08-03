---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "JSMA ataca L0 de frente: construye el Jacobiano completo entrada-salida y puntúa cada feature por cuánto sube la clase objetivo mientras hunde a las competidoras"
Fecha de actualización: 2026-07-29
Nota previa: "[[05 - Resultados de EAD y análisis de dispersión]]"
Nota siguiente: "[[07 - JSMA de un píxel, bucle de ataque y parámetros]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

<mark style="background: #ADCCFFA6;">`Jacobian-based Saliency Map Attack` (`JSMA`) identifica qué píxeles concretos mandan sobre la decisión del modelo y modifica solo esos.</mark> Donde [[01 - ElasticNet (EAD) y la mezcla L1 + L2|EAD]] empuja hacia el cero con una penalización, JSMA **cuenta** las features tocadas y se detiene al llegar al presupuesto. Es control $L_0$ explícito y duro, a cambio de una heurística voraz sin garantía de optimalidad.

> [!info]+ Fuente primaria
> [*The Limitations of Deep Learning in Adversarial Settings*, arXiv:1511.07528](https://arxiv.org/abs/1511.07528) — Papernot, McDaniel, Jha, Fredrikson, Celik y Swami, **IEEE EuroS&P 2016**. Demostraron que seleccionando bien se puede engañar a un clasificador MNIST cambiando entre 20 y 40 píxeles de 784.

# Otra filosofía de perturbación

| Ataque | Norma | Qué hace sobre una imagen MNIST |
| - | - | - |
| [[02 - FGSM, el ataque de un solo paso\|FGSM]] | $L_\infty$ | Toca los 784 píxeles, cada uno $\le \epsilon = 0{,}03$: ruido invisible pero global |
| [[04 - DeepFool y la perturbación mínima\|DeepFool]] | $L_2$ | Toca casi todos, con magnitudes variables, buscando distancia mínima |
| [[01 - ElasticNet (EAD) y la mezcla L1 + L2\|EAD]] | $L_1{+}L_2$ | 100-370 píxeles con cambios controlados |
| **JSMA** | $L_0$ | **20-70 píxeles**, cada uno pudiendo saltar de negro (0,0) a blanco (1,0) |

<mark style="background: #FFB86CA6;">JSMA acepta cambios enormes por píxel a cambio de que haya poquísimos píxeles.</mark> El resultado visual no es ruido: son puntos y trazos claramente visibles si se mira de cerca. Se cambia sigilo frente al ojo humano por sigilo frente a defensas que buscan alteración global coordinada — y por interpretabilidad, porque los píxeles elegidos son exactamente aquellos de los que depende la decisión.

# El Jacobiano de entrada-salida

La matriz que da toda la información es el **Jacobiano del modelo respecto a la entrada**: para $m$ clases y $n$ features, una matriz $(m, n)$ donde la fila $i$ contiene $\partial F_i / \partial x_j$ para todos los píxeles $j$. Sobre MNIST, $(10, 784) = 7840$ valores.

```python
def compute_class_gradient(x, model, class_idx, wrt='logits'):
    x_grad = x.detach().requires_grad_(True)
    logits = model(x_grad)
    scalar = logits[0, class_idx] if wrt == 'logits' else F.softmax(logits, dim=1)[0, class_idx]
    scalar.backward()
    return x_grad.grad.detach().cpu().numpy().flatten().copy()

def compute_jacobian_matrix(x, model, num_classes=10, wrt='logits'):
    if x.shape[0] != 1:
        raise ValueError("compute_jacobian_matrix expects batch size 1")
    return np.asarray([compute_class_gradient(x, model, c, wrt) for c in range(num_classes)])
```

Tres detalles que no son cosméticos:

- **Autograd necesita un escalar.** `backward()` arranca desde un valor de rango 0, no desde un tensor. Indexar `logits[0, class_idx]` es lo que convierte el vector de logits en el punto de partida de la retropropagación.
- **`.copy()` tras `.flatten()`.** El gradiente llega como vista sobre memoria de PyTorch; sin copiar, la siguiente pasada hacia atrás puede sobrescribirla y se acaban puntuando gradientes contaminados.
- **`batch_size=1` obligatorio.** PyTorch promedia gradientes sobre el lote por defecto. Pasar un batch de 4 imágenes devolvería el gradiente **medio**, inservible para un ataque por muestra. Validar explícitamente ahorra horas de depuración con mapas de saliencia que "parecen raros".

<mark style="background: #FF5582A6;">Una pasada hacia atrás **por clase** es el cuello de botella de JSMA.</mark> MNIST con 10 clases cuesta 10-15 ms por iteración: asumible. ImageNet con 1000 clases y entradas $224\times224\times3$ necesita $1000 \times 150\,528 = 150$ millones de valores, ~600 MB solo de Jacobiano, sobre una ResNet-50 que ya ocupa 2-3 GB. Toca trocear (gradientes de 100 clases, acumular en CPU, repetir), cambiando memoria por tiempo. **El coste de JSMA escala linealmente con el número de clases**, y eso lo descarta de facto para clasificadores de vocabulario grande.

# El mapa de saliencia

Para forzar la clase objetivo $t$, cada feature $j$ se describe con dos números extraídos del Jacobiano:

$$\alpha_j = \frac{\partial F_t}{\partial x_j} \qquad\qquad \beta_j = \sum_{i \ne t} \frac{\partial F_i}{\partial x_j}$$

$\alpha$ es cuánto sube la clase objetivo al subir ese píxel; $\beta$, cuánto suben **todas las demás juntas**. Se busca lo obvio: píxeles que suban el objetivo y hundan a los competidores.

> [!warning]+ Colisión de notación
> El $\beta$ de JSMA (suma de gradientes de las clases no objetivo) **no tiene nada que ver** con el $\beta$ de [[01 - ElasticNet (EAD) y la mezcla L1 + L2|EAD]] (peso del término $L_1$). Los dos ataques vienen de literaturas distintas y coinciden en la letra. Al leer código que implemente ambos, comprobar siempre qué $\beta$ es cuál.

Calcular $\beta$ sin bucles aprovecha que la suma total menos el objetivo es exactamente el resto:

```python
def extract_other_gradients(jacobian, target_class):
    return jacobian.sum(axis=0) - jacobian[target_class]
```

## Las restricciones de signo

La puntuación solo cuenta cuando ambos gradientes cooperan:

- **Dirección "subir"**: válida si $\alpha_j > 0$ **y** $\beta_j < 0$. Puntuación $= \alpha_j \times |\beta_j|$.
- **Dirección "bajar"**: válida si $\alpha_j < 0$ **y** $\beta_j > 0$. Puntuación $= |\alpha_j| \times \beta_j$.
- Cualquier otra combinación puntúa **cero**: el píxel ayuda al objetivo pero también a los rivales, o al revés.

<mark style="background: #8000E1A6;">Que la puntuación sea un **producto** y no una suma es deliberado:</mark> exige que las dos condiciones se cumplan con fuerza. Un píxel que sube mucho el objetivo pero apenas toca a los competidores puntúa poco, porque el segundo factor es pequeño. Se premia el efecto de tenaza.

Y una consecuencia que confunde a quien viene de FGSM: **un gradiente negativo no descarta el píxel**. Significa que hay que *bajarlo*. Por eso JSMA puede "borrar" trazos (poner un píxel blanco a negro) con la misma eficacia con la que los "dibuja".

> [!example]+ El caso de juguete
> Modelo con 2 features y 3 clases; objetivo, la clase 2 (que va perdiendo con 0,3 frente a 0,6 y 0,5).
> - **Feature 1**: $\alpha = 0{,}6$ (sube el objetivo), $\beta = -0{,}4$ (hunde a los rivales). Cumple los signos → puntuación $0{,}6 \times 0{,}4 = 0{,}24$. Al subirla, el objetivo llega a 0,9 y adelanta a ambos.
> - **Feature 2**: $\alpha = 0{,}3$, $\beta = 0{,}5$. Ayuda al objetivo, pero ayuda **más** a los competidores: viola la restricción de signo, puntuación 0. Subirla dejaría la clase 0 en 0,9, reforzando la predicción original.
>
> ![Ejemplo MNIST: los píxeles estratégicos que convierten un 3 en un 8](https://academy.hackthebox.com/storage/modules/320/jacobian_step4_mnist.png)
>
> Sobre un dígito real la lógica es idéntica: partiendo de un "3", el mapa de saliencia marca los píxeles que distinguen "3" de "8" —rellenar el lado izquierdo, reforzar el trazo central— y modificar solo esos basta para la transformación.

## Logits, nunca `softmax`

Este punto es la mejora técnica más relevante del módulo sobre implementaciones ingenuas de JSMA. <mark style="background: #FFB8EBA6;">Si se calculan los gradientes sobre las **probabilidades** post-`softmax`, la restricción $\sum_j p_j = 1$ obliga por construcción a que $\beta = -\alpha$.</mark> Sustituyendo en la fórmula, la puntuación colapsa a $|\alpha| \times |{-\alpha}| = \alpha^2$: el término de supresión de competidores **desaparece**, y con él la lógica del ataque. Lo que queda es un ranking por pendiente al cuadrado del objetivo, que no es JSMA.

# El ciclo iterativo

![Diagrama de flujo del ciclo JSMA: calcular Jacobiano, construir mapa de saliencia, seleccionar feature, modificar, actualizar espacio de búsqueda](https://academy.hackthebox.com/storage/modules/320/jacobian_iterative_cycle.png)

Cada vuelta: Jacobiano → mapa de saliencia → seleccionar la mejor feature (o par) → modificar → actualizar el espacio de búsqueda. Se repite hasta lograr la clase objetivo o agotar el presupuesto. Dos parámetros lo gobiernan: el paso $\theta$ (magnitud por modificación) y el presupuesto $\gamma$ (fracción máxima de features tocables), detallados en [[07 - JSMA de un píxel, bucle de ataque y parámetros|la nota siguiente]].

El **espacio de búsqueda** es una máscara booleana que arranca toda a `True` y va perdiendo píxeles por dos vías: los ya modificados y los **saturados** en 0,0 o 1,0. Retirar los saturados es obligatorio, no una optimización: un píxel en el límite no admite más cambio en esa dirección y seguir seleccionándolo quema iteraciones sin efecto.

```python
def apply_search_mask(gradient, search_space):
    return gradient * search_space      # True→1.0, False→0.0
```

Multiplicar por la máscara —en vez de indexar— **preserva la correspondencia de índices**: el píxel 352 sigue en la posición 352, solo que con gradiente 0. Indexar produciría un array más corto y desalinearía todo respecto a la imagen.

> [!warning]+ El bug silencioso: orden de aplanado
> El Jacobiano trabaja sobre vectores de 784 posiciones; la imagen es $(1,1,28,28)$. La conversión debe usar **siempre** el mismo orden C-H-W: el índice 352 es $0\times784 + 12\times28 + 16$, es decir canal 0, fila 12, columna 16. <mark style="background: #FF5582A6;">Aplanar en C-H-W y remodelar asumiendo H-W-C no lanza ningún error:</mark> el ataque corre, las saliencias parecen razonables, y los píxeles se modifican en posiciones sin sentido semántico. Síntoma: 0 % de éxito sin ninguna excepción. Es el fallo más caro de depurar de este ataque.

> [!important]+ JSMA está pensado para redes poco profundas
> El módulo usa una LeNet a propósito, y lo justifica: en una red superficial cada píxel tiene mucha influencia sobre la salida. En arquitecturas modernas —ResNet con conexiones residuales y `batch normalization`— la decisión se reparte entre muchas capas, el [[02 - Redes neuronales convolucionales (CNN)#Jerarquía de características|campo receptivo]] de cada neurona de salida cubre casi toda la imagen, la influencia individual de cada píxel cae y **las tasas de éxito de JSMA bajan sustancialmente**. Es la razón de que los ataques dispersos actuales ([[09 - EAD frente a JSMA y el estado del arte en ataques L0|Sparse-RS, σ-zero]]) hayan sustituido a JSMA en la práctica sobre modelos complejos. JSMA se mantiene por valor didáctico y como línea base reproducible, no como el ataque $L_0$ que se lanzaría hoy contra un modelo de producción.
