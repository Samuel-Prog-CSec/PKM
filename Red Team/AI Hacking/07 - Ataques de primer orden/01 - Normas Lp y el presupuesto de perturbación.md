---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Las normas Lp son la regla con la que se mide una perturbación adversarial, y cada elección (L0, L1, L2, L∞) define un tipo de ataque distinto con su propio compromiso"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Ataques de primer orden y el papel del gradiente]]"
Nota siguiente: "[[02 - FGSM, el ataque de un solo paso]]"
Area: "[[Ataques de primer orden.base|Ataques de primer orden]]"
---
---

<mark style="background: #ADCCFFA6;">Una norma es la regla con la que se mide cuánto ha cambiado una perturbación una entrada.</mark> Parece un detalle matemático, pero es lo que define el tipo de ataque: limitar la perturbación en norma $L_0$, $L_1$, $L_2$ o $L_\infty$ produce ataques con aspecto, coste y detectabilidad completamente distintos. Sin fijar la norma, "perturbación mínima" no significa nada — por eso este concepto va antes que los ataques.

# La metáfora de la ciudad

Para ir de Times Square a Central Park, "la distancia" depende de cómo se mida:

- **Contar cuántas intersecciones cruzas** (sin importar cuánto andas en cada una) → $L_0$.
- **Andar por las calles siguiendo la cuadrícula** → $L_1$ (distancia Manhattan).
- **Volar en línea recta** como un pájaro → $L_2$ (distancia euclídea).
- **Solo el tramo individual más largo** que recorres → $L_\infty$.

Cada forma de medir es una norma distinta, y aplicada a una perturbación adversarial cambia qué se considera "pequeño".

# La familia de las p-normas

Todas se unifican en una fórmula con un parámetro $p$:

$$\|x\|_p = \left(\sum_{i=1}^{n} |x_i|^p\right)^{1/p}$$

"Eleva cada cambio a la potencia $p$, súmalos, y saca la raíz $p$-ésima." Distintos valores de $p$ dan distintas herramientas de medida. Para ser una norma válida debe cumplir tres reglas de sentido común: cero longitud solo lo tiene el vector nulo; doblar el cambio dobla la medida; y la desigualdad triangular (el camino directo nunca es más largo que el rodeo).

# Las cuatro normas y su ataque

| Norma | Qué mide | Aspecto de la perturbación | Ataque típico |
| - | - | - | - |
| $L_0$ | **Cuántos** píxeles cambian (no cuánto) | Pocos píxeles muy alterados | *One-pixel*, parches |
| $L_1$ | Suma de los cambios absolutos | Cambios dispersos, moteados | Ataques dispersos |
| $L_2$ | Energía total (distancia euclídea) | Niebla fina uniforme | DeepFool, C&W |
| $L_\infty$ | El **mayor** cambio individual | Ruido uniforme acotado | FGSM, PGD |

## $L_0$ — cuántos, no cuánto

Cuenta el número de componentes que cambian, ignorando la magnitud. Con presupuesto de "100 unidades" puedes cambiar 100 píxeles un 1%, 10 píxeles un 10%, o 1 píxel un 100%. Es el modelo de amenaza de los ataques de **parche** y *one-pixel*. Computacionalmente es el "modo experto": discontinua y no convexa, exige búsqueda combinatoria o algoritmos *greedy*.

## $L_2$ — la niebla uniforme

La distancia euclídea de siempre. Al elevar al cuadrado, **penaliza mucho los cambios individuales grandes**, así que reparte la perturbación uniformemente entre todos los píxeles. <mark style="background: #FFB86CA6;">Produce las perturbaciones más imperceptibles</mark> —como una capa de niebla fina sobre toda la imagen— y es matemáticamente cómoda (suave y diferenciable). Es la norma nativa de [[04 - DeepFool y la perturbación mínima|DeepFool]] y Carlini-Wagner. Su desventaja: cambia todo un poco, y es menos interpretable (no señala qué features importan).

## $L_\infty$ — el techo por píxel

Limita el **mayor** cambio de cualquier píxel. Con $L_\infty = 0{,}1$, cada píxel puede cambiar hasta un 10%, ninguno más. <mark style="background: #8000E1A6;">Es la restricción más intuitiva —"ningún píxel cambia más de X"— y la dominante en el entrenamiento adversarial y en [[02 - FGSM, el ataque de un solo paso|FGSM]]/[[03 - I-FGSM, PGD y el refinamiento iterativo|PGD]].</mark> Produce perturbaciones de aspecto uniforme. Su desventaja: puede cambiar muchos píxeles innecesariamente, y el máximo duro restringe la optimización.

# La relación entre normas: dualidad

Las normas no son independientes. Limitar una acota las otras, y hay una relación clave para los ataques: la **dualidad**. Cada norma $L_p$ tiene una norma *dual* $L_q$ con $\frac{1}{p} + \frac{1}{q} = 1$. Los pares que importan:

- $L_\infty$ y $L_1$ son duales ($\frac{1}{\infty} + \frac{1}{1} = 1$).
- $L_2$ es dual de sí misma.

<mark style="background: #FF5582A6;">La dualidad es lo que conecta la restricción sobre la perturbación con la magnitud del gradiente:</mark> si acotas la perturbación en una norma, el peor caso del producto escalar (el daño máximo) lo controla la norma **complementaria** del gradiente. Esto es exactamente lo que resuelve [[02 - FGSM, el ataque de un solo paso|FGSM]] vía la desigualdad de Hölder — la razón matemática de por qué FGSM usa el signo del gradiente bajo $L_\infty$.

# Propiedades computacionales

Cada norma se optimiza distinto, lo que determina qué ataque es viable:

| Norma | Propiedad | Método de optimización |
| - | - | - |
| $L_0$ | Discontinua, no convexa | *Greedy* / combinatoria |
| $L_1$ | Tiene un "pico" en cero | Soft-thresholding, gradiente proximal |
| $L_2$ | Suave, diferenciable en todas partes | Descenso de gradiente directo — "vainilla" |
| $L_\infty$ | Gradiente disperso (solo el máximo cuenta) | Descenso de gradiente proyectado |

# Por qué importa para el atacante y el defensor

La elección de norma no es cosmética:

- **Ataque específico de norma.** Un ataque diseñado para $L_\infty$ (FGSM) no es óptimo bajo $L_2$. La [[02 - FGSM, el ataque de un solo paso#Presupuestos alternativos: otras normas|variante $L_2$ de FGSM]] normaliza el gradiente en vez de tomar su signo.
- **Defensa específica de norma.** <mark style="background: #FFB8EBA6;">El entrenamiento adversarial contra ataques $L_\infty$ **no protege bien** contra ataques $L_0$ dispersos.</mark> Un modelo "robusto" solo lo es frente a la norma para la que se entrenó — un matiz crítico al reportar robustez ([[04 - Detección y defensa contra la evasión|detección y defensa]]).
- **Evaluación honesta.** Comparar la robustez de dos modelos exige fijar la norma **y** el presupuesto; cambiar cualquiera puede invertir el ranking.

Las normas clásicas siguen siendo el lenguaje central del ML adversarial porque dan un marco preciso para razonar sobre ataques y defensas, aunque se investiguen métricas más sofisticadas que capturen mejor la percepción humana. Con la métrica fijada, el primer ataque es [[02 - FGSM, el ataque de un solo paso|FGSM]].
