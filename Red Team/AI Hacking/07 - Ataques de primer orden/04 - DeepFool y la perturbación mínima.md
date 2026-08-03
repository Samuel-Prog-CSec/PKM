---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "DeepFool no fija un presupuesto: busca la perturbación mínima proyectando la entrada sobre la frontera más cercana, lo que lo convierte en un instrumento de medida de robustez"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - I-FGSM, PGD y el refinamiento iterativo]]"
Nota siguiente: 
Area: "[[Ataques de primer orden.base|Ataques de primer orden]]"
---
---

<mark style="background: #ADCCFFA6;">DeepFool no fija un presupuesto: busca la perturbación **mínima** que cruza la frontera de decisión más cercana.</mark> Donde [[02 - FGSM, el ataque de un solo paso|FGSM]] pregunta "con un martillo de tamaño $\epsilon$, ¿dónde golpeo?", DeepFool pregunta "¿cuál es el martillo más pequeño que rompe esto?". Esa diferencia lo convierte en algo más que un ataque: en un **instrumento de medida** de la robustez de cada entrada. Lo introdujeron Moosavi-Dezfooli et al. en CVPR 2016.

# El problema del ε de FGSM

Fijar $\epsilon$ de antemano tiene un defecto profundo como métrica de robustez: <mark style="background: #FFB86CA6;">confunde el método de ataque con la robustez real del modelo.</mark> Demasiado pequeño y el ataque falla; demasiado grande y la perturbación es detectable o destruye el significado. Peor: dos modelos pueden parecer igual de robustos con un $\epsilon$ y muy distintos con otro. La robustez medida depende más de la elección del parámetro que del modelo.

DeepFool elimina esa arbitrariedad. Al encontrar la **perturbación mínima suficiente** para cada entrada individual, la magnitud resultante es una medida directa de la robustez de esa entrada — no un reflejo de la elección de $\epsilon$. <mark style="background: #8000E1A6;">Transforma el ataque de herramienta de destrucción en instrumento de medición.</mark>

# La geometría: proyección ortogonal

DeepFool trata la evasión como un problema geométrico: encontrar el camino más corto de un punto a la frontera de decisión más cercana. La intuición se ve limpia en un **clasificador lineal binario** $f(x) = w^\top x + b$, cuya frontera es el hiperplano $f(x) = 0$.

La distancia mínima de un punto $x_0$ a ese hiperplano y la perturbación que lo alcanza son fórmulas cerradas de geometría:

$$d = \frac{|f(x_0)|}{\|w\|_2}, \qquad r^* = -\frac{f(x_0)}{\|w\|_2^2} \, w$$

Se **proyecta el punto ortogonalmente** sobre la frontera. Dos lecturas importantes:

- <mark style="background: #FFB8EBA6;">A diferencia del `sign` de FGSM, que iguala todos los cambios, DeepFool preserva las magnitudes del gradiente:</mark> un píxel con peso 10 cambia diez veces más que uno con peso 1, porque tiene diez veces más influencia. Es óptimo en $L_2$ (el camino más corto a un hiperplano es perpendicular a él).
- El numerador $|f(x_0)|$ es la **confianza** del modelo en el punto. Puntos con alta confianza necesitan perturbaciones grandes; puntos cerca de la frontera, empujones diminutos. La intuición sugiere que confianza = robustez, pero <mark style="background: #FF5582A6;">las redes profundas violan esto a menudo: muestran altísima confianza en puntos extremadamente cercanos a la frontera.</mark>

# De lineal a profundo: linealización iterativa

Las fronteras de una red profunda no son hiperplanos planos, sino superficies curvas que se pliegan y retuercen a través de miles de dimensiones (*manifolds*). La fórmula cerrada solo vale localmente. DeepFool lo resuelve **iterando**:

> Imagina navegar una montaña curva entre niebla densa. Solo ves el terreno inmediato. En cada posición, calcula la mejor dirección local con lo que ves, da un paso pequeño, reevalúa desde el nuevo punto, y repite hasta llegar a la frontera.

Cada iteración linealiza el clasificador alrededor del punto actual con Taylor de primer orden ("hacer zoom hasta que la curva parezca recta"), calcula la perturbación mínima para esa aproximación lineal, da el paso, y reevalúa. En regiones casi lineales llega en una iteración; en regiones de alta curvatura toma más, ajustándose a los contornos. <mark style="background: #8000E1A6;">La perturbación se adapta automáticamente a la geometría local, garantizando que sea casi mínima sin importar la complejidad.</mark>

# La formulación multi-clase: la frontera más cercana

Un clasificador real tiene muchas clases (MNIST: 10, ImageNet: 1000), y desde cualquier punto hay **múltiples fronteras**, cada una separando la clase actual de una alternativa. ¿Cuál atacar? **La más cercana.**

Para una entrada clasificada como $\hat{k}(x)$, en cada iteración y para cada clase alternativa $k$ se define la diferencia de gradientes y el hueco de score:

$$w_k = \nabla f_k(x_i) - \nabla f_{\hat{k}}(x_i), \qquad f'_k = f_k(x_i) - f_{\hat{k}}(x_i)$$

La frontera más cercana es la que minimiza distancia = hueco / sensibilidad, y el paso mínimo es su proyección ortogonal:

$$l = \arg\min_{k \neq \hat{k}} \frac{|f'_k|}{\|w_k\|_2}, \qquad r_i = \frac{|f'_l|}{\|w_l\|_2^2} \, w_l$$

Se acumula $x_{i+1} = x_i + r_i$ y se re-linealiza hasta que la clasificación cambia. <mark style="background: #FFB86CA6;">Es la generalización natural del caso binario: evaluar todas las clases alternativas, medir la distancia a cada frontera, y dar el paso mínimo hacia la más cercana.</mark>

## El parámetro overshoot

DeepFool multiplica cada paso por $(1 + \text{overshoot})$, típicamente 1,02. Sirve para dos cosas: garantizar que **realmente** se cruza la frontera no lineal (no solo tocarla en la aproximación lineal, que por precisión numérica dejaría el punto infinitesimalmente cerca pero sin cruzar), y acelerar la convergencia. El 2% típico mantiene la perturbación extra despreciable.

# DeepFool vs. I-FGSM

Ambos iteran y calculan gradientes, pero usan la información de forma opuesta:

| | [[03 - I-FGSM, PGD y el refinamiento iterativo\|I-FGSM]] | DeepFool |
| - | - | - |
| Uso del gradiente | Solo el **signo** (descarta magnitud) | Preserva **magnitudes** |
| Paso | Uniforme en todos los píxeles | Proporcional a la influencia de cada píxel |
| Objetivo | Maximizar daño en presupuesto fijo | Alcanzar la frontera con mínimo cambio |
| Norma nativa | $L_\infty$ | $L_2$ |
| Resultado | Perturbación acotada, no mínima | Perturbación casi mínima |

# La medida de robustez: ρ_adv

El producto de DeepFool no es solo el ejemplo adversarial, sino una **métrica cuantitativa de robustez** del modelo: la perturbación relativa media sobre un dataset $D$:

$$\rho_{adv} = \frac{1}{|D|} \sum_{x \in D} \frac{\|r(x)\|_2}{\|x\|_2}$$

<mark style="background: #FF5582A6;">Un modelo con $\rho_{adv} = 0{,}02$ necesita perturbaciones del 2% del tamaño de la entrada para ser engañado; uno con $\rho_{adv} = 0{,}10$ necesita el 10% — cinco veces más robusto.</mark> A diferencia de medir con un $\epsilon$ arbitrario, $\rho_{adv}$ mide directamente la distancia a las fronteras, normalizada por el tamaño de la entrada, y se calcula eficientemente. Es la razón por la que DeepFool es la herramienta de elección para **comparar** la robustez de modelos, arquitecturas o entradas.

# Extensiones

- **DeepFool $L_\infty$** — cambia $\|w_k\|_2$ por $\|w_k\|_1$ en el denominador y usa el signo del gradiente para la dirección, distribuyendo la perturbación uniformemente entre píxeles.
- **Perturbaciones universales** — aplicando DeepFool iterativamente a distintos ejemplos y acumulando las perturbaciones (con una cota de magnitud), se obtiene **una sola perturbación que engaña al modelo en la mayoría de las entradas**. Su existencia demuestra que las redes profundas tienen vulnerabilidades **sistemáticas**, consistentes entre entradas distintas — no fallos aislados por imagen.

# Cierre del tema

DeepFool cierra la familia de ataques de primer orden y conecta con la [[04 - Detección y defensa contra la evasión|defensa]]: $\rho_{adv}$ es precisamente la métrica que evalúa si el entrenamiento adversarial funciona (un modelo endurecido tiene $\rho_{adv}$ mayor). El [[05 - Arsenal para la evasión de modelos|arsenal]] —ART, Foolbox, AutoAttack, que implementan FGSM, PGD y DeepFool con una API común— y las defensas completas están en la carpeta de [[00 - Fundamentos de la evasión de modelos|fundamentos]], porque son comunes a toda la evasión.

El siguiente escalón cambia la pregunta: en lugar de *cuánto* puede cambiar cada feature, *cuántas* pueden cambiar. Esa es la familia de los [[00 - Fundamentos de los ataques dispersos y la norma L0|ataques dispersos ($L_0$)]] — [[01 - ElasticNet (EAD) y la mezcla L1 + L2|EAD]] extiende la lógica de C&W con una penalización $L_1$, y [[06 - JSMA, el Jacobiano y los mapas de saliencia|JSMA]] la abandona por completo a favor de selección combinatoria sobre el Jacobiano. La geometría de DeepFool reaparece allí en [[09 - EAD frente a JSMA y el estado del arte en ataques L0|SparseFool]], que es literalmente su versión dispersa.
