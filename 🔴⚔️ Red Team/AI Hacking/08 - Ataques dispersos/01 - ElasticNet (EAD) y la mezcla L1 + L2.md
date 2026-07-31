---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "EAD combina una penalización L1 (que produce ceros exactos) con L2 (que da gradientes estables), y usa un parámetro β para moverse entre dispersión extrema y suavidad distribuida"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Fundamentos de los ataques dispersos y la norma L0]]"
Nota siguiente: "[[02 - Operadores proximales, soft thresholding y FISTA]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

Los ataques de primer orden se casan con una sola norma: [[02 - FGSM, el ataque de un solo paso|FGSM]] limita $L_\infty$, [[04 - DeepFool y la perturbación mínima|DeepFool]] minimiza $L_2$. <mark style="background: #ADCCFFA6;">`ElasticNet Attacks to Deep neural networks` (`EAD`) rompe con eso: mezcla $L_1$ y $L_2$ en un único objetivo, produciendo perturbaciones **a la vez dispersas y suaves**.</mark> El nombre viene de la regresión *elastic net* de la estadística clásica (Zou y Hastie, 2005), donde la misma combinación resuelve el mismo dilema: seleccionar variables sin que la optimización se vuelva inestable.

> [!info]+ Fuente primaria
> [*EAD: Elastic-Net Attacks to Deep Neural Networks via Adversarial Examples*, arXiv:1709.04114](https://arxiv.org/abs/1709.04114) — Chen, Sharma, Zhang, Yi y Hsieh, **AAAI 2018**. (HTB atribuye el paper con los autores en otro orden; el orden correcto de la publicación es Pin-Yu Chen, Yash Sharma, Huan Zhang, Jinfeng Yi, Cho-Jui Hsieh.)

# Por qué una sola norma se queda corta

Cada norma impone una geometría distinta sobre la perturbación, y ninguna cubre lo que un ataque disperso necesita:

- **$L_\infty$ (FGSM/PGD)** permite mover *todos* los píxeles hasta $\epsilon$. El resultado es ruido uniforme sobre la imagen entera: $L_0$ máximo por construcción.
- **$L_2$ (DeepFool, Carlini & Wagner)** reparte la energía. Al elevar al cuadrado penaliza fuerte los cambios individuales grandes, así que prefiere muchos cambios diminutos: perturbación **densa**, suave, y sin ninguna garantía de dispersión. Una perturbación $L_2$-óptima puede tocar los 784 píxeles.
- **$L_1$** sí produce dispersión —su bola es un rombo con vértices sobre los ejes, y la optimización cae naturalmente en esos vértices, donde la mayoría de coordenadas valen cero exacto—, pero <mark style="background: #FFB8EBA6;">$|x|$ no es diferenciable en el origen, justo donde nace la dispersión.</mark> El descenso de gradiente ingenuo sobre $\lVert \delta \rVert_1$ deja valores rondando cero sin llegar nunca: *pseudo-dispersión* (muchos valores pequeños) en lugar de dispersión real (muchos ceros exactos).

EAD resuelve la tensión sumando las dos: <mark style="background: #8000E1A6;">$L_2$ aporta gradientes suaves para que la optimización sea estable; $L_1$ aporta los ceros exactos.</mark>

# El objetivo

$$\min_{x'} \; c \cdot f(x') + \lVert x' - x \rVert_2^2 + \beta \lVert x' - x \rVert_1 \quad \text{s.a.} \quad x' \in [0,1]$$

Tres piezas y dos mandos:

- $f(x')$ — la pérdida que fuerza la clasificación errónea (el margen de Carlini & Wagner, detallado en [[03 - El objetivo de EAD, margen C&W y binary search|la nota del objetivo]]).
- $\lVert x' - x \rVert_2^2$ — la energía de la perturbación. Se usa **al cuadrado** por dos razones concretas: su gradiente es $2(x'-x)$, lineal y trivial, y mantiene la convexidad estricta. La versión sin cuadrado obligaría a normalizar por $\lVert \cdot \rVert_2$ en cada paso sin cambiar el óptimo.
- $\beta \lVert x' - x \rVert_1$ — el término que induce dispersión.
- $c$ — cuánta presión adversarial se ejerce frente a cuánta distorsión se tolera. No se fija a mano: lo encuentra una **búsqueda binaria** por ejemplo.
- $\beta$ — el mando de dispersión. Con $\beta = 0$ se recupera un ataque $L_2$ puro estilo C&W.

Fijarse en un detalle que se pasa por alto: <mark style="background: #FFB86CA6;">las penalizaciones se aplican sobre $x' - x$, la **perturbación**, no sobre $x'$.</mark> Se quieren perturbaciones dispersas (muchos píxeles intactos), no imágenes dispersas (muchos píxeles a cero).

# El ejemplo que explica $\beta$

Dos perturbaciones sobre una imagen MNIST de 784 píxeles:

| | Píxeles tocados | Cambio por píxel | $L_2^2$ | $L_1$ |
| - | - | - | - | - |
| **Caso A** (densa) | 100 | 0,10 | $100 \times 0{,}10^2 = 1{,}00$ | $100 \times 0{,}10 = 10{,}0$ |
| **Caso B** (dispersa) | 10 | 0,316 | $10 \times 0{,}316^2 \approx 1{,}00$ | $10 \times 0{,}316 \approx 3{,}16$ |

Para el término $L_2^2$ **las dos son idénticas**: un ataque $L_2$ puro no tiene forma de preferir B. Es el término $L_1$ el que las separa, y por un factor de 3. Subir $\beta$ inclina el objetivo hacia B; bajarlo lo devuelve al comportamiento $L_2$ denso.

Valores de referencia sobre MNIST, del propio módulo:

- $\beta = 0{,}001$–$0{,}005$ → prácticamente denso, se comporta como C&W.
- $\beta = 0{,}01$ → sesgo moderado hacia la dispersión sin sacrificar eficacia. Es el valor por defecto.
- $\beta = 0{,}05$–$0{,}1$ → dispersión agresiva; doblar $\beta$ de 0,01 a 0,02 sube la dispersión 10-15 puntos porcentuales y baja la tasa de éxito 5-10 % en los ejemplos difíciles.

# Las tres distancias, y por qué se calculan por ejemplo

El ataque necesita medir tres cosas en cada iteración:

```python
def compute_distances(adv_images, original_images, beta):
    l1_dist = torch.sum(torch.abs(adv_images - original_images), dim=(1, 2, 3))
    l2_dist = torch.sum((adv_images - original_images) ** 2, dim=(1, 2, 3))
    elastic_dist = l2_dist + beta * l1_dist
    return l1_dist, l2_dist, elastic_dist
```

El `dim=(1, 2, 3)` colapsa canal, alto y ancho pero **preserva la dimensión de lote**: un batch de 20 imágenes devuelve 20 escalares, no uno. No es un capricho de estilo. <mark style="background: #FF5582A6;">La búsqueda binaria ajusta $c$ **por ejemplo**</mark> — uno fácil, pegado a la frontera, converge con $c = 0{,}01$; uno resistente necesita $c = 10$. Con una sola distancia agregada habría que usar la misma constante para todos, sobre-perturbando los fáciles y sub-perturbando los difíciles.

Conviene tener clara la diferencia semántica entre las tres, porque se confunden constantemente al leer resultados:

- $L_1$ pondera cada píxel por **cuánto** cambió. 100 píxeles a 0,15 y 50 píxeles a 0,30 dan el mismo $L_1 = 15{,}0$.
- $L_2^2$ penaliza la **concentración**: esas mismas dos perturbaciones dan 2,25 y 4,50 respectivamente. La concentrada cuesta el doble.
- $L_0$ —lo que de verdad interesa— no aparece en el objetivo: se **infiere** contando coordenadas no nulas al final.

> [!warning]+ Ni $L_1$ ni $L_2$ son $L_0$
> Un error habitual al reportar es dar el $L_1$ medio como si midiera dispersión. No la mide: mide magnitud acumulada. Bajo el supuesto de que los $k$ píxeles tocados cambian una magnitud parecida $a$, se tiene $L_1 = ka$ y $L_2^2 = ka^2$, de donde $k \approx L_1^2 / L_2^2$. Con $L_1 = 60$ y $L_2^2 = 9$ salen $k \approx 400$ píxeles sobre 784, ~49 % de dispersión.
>
> <mark style="background: #FF5582A6;">Ese número es una **cota inferior** de $k$, no superior</mark> — y la dirección importa, porque equivocarla hace que un ataque parezca más disperso de lo que es. Sale de Cauchy-Schwarz: $\left(\sum_{i \in \text{supp}} |\delta_i| \cdot 1\right)^2 \le \left(\sum \delta_i^2\right)\left(\sum_{i \in \text{supp}} 1\right)$, es decir $L_1^2 \le k \cdot L_2^2$, luego
>
> $$k \;\ge\; \frac{L_1^2}{L_2^2}$$
>
> con igualdad **solo** si todas las magnitudes no nulas son iguales. En cuanto unos pocos píxeles cargan con la mayor parte del cambio, el estimador se hunde: una perturbación de 400 píxeles con 20 fuertes y 380 débiles da $L_1^2/L_2^2 \approx 60$, quince veces menos que el $k$ real. Para un número honesto, contar directamente `(|δ| > 1e-6).sum()`.
>
> *(El módulo de HTB afirma lo contrario —"upper bound on $k$… actual $k$ is often smaller"— y con ello sobreestima la dispersión de sus propios resultados.)*

# Dónde encaja EAD frente a los ataques anteriores

| | [[02 - FGSM, el ataque de un solo paso\|FGSM]] | [[04 - DeepFool y la perturbación mínima\|DeepFool]] | EAD |
| - | - | - | - |
| Norma | $L_\infty$ | $L_2$ | $L_1 + L_2$ mixta |
| Iteraciones | 1 | 5-20 proyecciones cerradas | 100-1000 con descenso proximal |
| Adaptación por ejemplo | Ninguna ($\epsilon$ fijo) | Vía nº de iteraciones | Doble: FISTA **y** búsqueda binaria de $c$ |
| Producto | Perturbación acotada | Perturbación casi mínima en $L_2$ | Perturbación dispersa y de distorsión mínima |
| Uso típico | Generar datos para entrenamiento adversarial | Medir robustez ($\rho_{adv}$) | Evadir detección, transferir entre modelos, ver qué features pesan |

La adaptación doble es lo que distingue a EAD: FISTA refina la perturbación y la búsqueda binaria calibra la presión, así que el ataque **descubre el umbral de vulnerabilidad de cada entrada** en vez de imponer un $\epsilon$ universal.

# Lo que el paper aporta y HTB no menciona

HTB presenta EAD como "un ataque disperso más". La contribución real, según el paper original, es doble y tiene consecuencias directas en un engagement:

1. **Transferibilidad mejorada.** Los ejemplos con distorsión $L_1$ pequeña transfieren mejor entre modelos que los $L_2$/$L_\infty$ equivalentes. Es lo que convierte a EAD en una opción seria de **caja negra por transferencia** cuando no hay acceso al modelo objetivo.
2. **Complementa el entrenamiento adversarial.** Un modelo endurecido solo con ejemplos $L_\infty$ deja hueco en la dirección $L_1$ — el argumento que sostiene la advertencia de [[00 - Fundamentos de los ataques dispersos y la norma L0|la nota anterior]] sobre robustez específica de norma.

La mecánica de optimización —cómo se consigue que $L_1$ produzca ceros exactos sin gradiente— es el contenido de [[02 - Operadores proximales, soft thresholding y FISTA|la siguiente nota]].
