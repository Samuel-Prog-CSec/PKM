---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "El JSMA canónico modifica pares y aplica las restricciones de signo sobre la suma, admitiendo combinaciones que ningún píxel pasaría solo: 90% con 42,8 píxeles"
Fecha de actualización: 2026-07-29
Nota previa: "[[07 - JSMA de un píxel, bucle de ataque y parámetros]]"
Nota siguiente: "[[09 - EAD frente a JSMA y el estado del arte en ataques L0]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

El JSMA del paper original no modifica un píxel por iteración, sino **dos**. <mark style="background: #ADCCFFA6;">Para un par $(p,q)$ se suman los gradientes antes de puntuar: $\alpha_{pq} = \alpha_p + \alpha_q$ y $\beta_{pq} = \beta_p + \beta_q$, y las restricciones de signo se aplican sobre **las sumas**, no sobre cada píxel.</mark>

$$S_t^{+}[p,q] = \alpha_{pq} \times |\beta_{pq}| \quad \text{si } \alpha_{pq} > 0 \text{ y } \beta_{pq} < 0$$

Ese cambio de dónde se aplican las restricciones es lo que da el salto de rendimiento, y merece pararse en él.

# Por qué las restricciones sobre la suma cambian el juego

En la [[07 - JSMA de un píxel, bucle de ataque y parámetros|variante de un píxel]], un candidato debe cumplir $\alpha_j > 0$ **y** $\beta_j < 0$ por sí solo. De 784 píxeles, solo 330 pasaban el filtro en la dirección "subir" y 349 en "bajar".

Con pares, un píxel con $\beta_p$ ligeramente positivo (ayuda algo a los competidores) puede formar equipo con otro cuyo $\beta_q$ muy negativo compense de sobra, y el par entero pasa el filtro. <mark style="background: #8000E1A6;">Se descubren combinaciones que ninguno de los dos miembros habría superado en solitario.</mark> El espacio de candidatos deja de ser una lista filtrada de píxeles y pasa a ser un espacio de emparejamientos.

# El coste combinatorio y la poda

Evaluar todos los pares es $\binom{n}{2} = n(n-1)/2$. Con 784 píxeles disponibles: **306 936 pares** por dirección y por iteración. Inviable.

La solución es podar antes de emparejar, quedándose con los `top_k` píxeles de mayor producto de magnitudes individuales:

```python
def prune_candidates(alpha, beta, search_space, top_k):
    alpha_masked = alpha * search_space
    beta_masked  = beta * search_space
    valid = np.where(search_space)[0]

    if valid.size < 2 or top_k is None or valid.size <= top_k:
        return valid

    prelim_scores = np.abs(alpha_masked[valid]) * np.abs(beta_masked[valid])
    idx = np.argsort(-prelim_scores)[:top_k]
    return valid[idx]
```

Con `top_k=128` quedan $\binom{128}{2} = 8128$ pares: **una reducción del 97 %**. La heurística asume que los píxeles con gradientes individuales fuertes forman los mejores pares — <mark style="background: #FFB8EBA6;">supuesto que se cumple empíricamente pero no está garantizado</mark>, y que entra en tensión directa con la ventaja recién descrita (los pares interesantes pueden incluir un píxel de gradiente individual mediocre). Se cambia optimalidad por velocidad, conscientemente.

Nótese además que la puntuación preliminar usa $|\alpha_j| \times |\beta_j|$ **sin** restricción de signo: la poda no descarta por dirección, solo por magnitud, lo que preserva parte de la capacidad de encontrar pares complementarios.

```python
def evaluate_pairs(alpha, beta, valid, direction):
    best_p, best_q, best_score = -1, -1, 0.0
    for i in range(valid.size):
        p = valid[i]
        for j in range(i + 1, valid.size):        # i+1: ni auto-pares ni duplicados
            q = valid[j]
            a_pq, b_pq = alpha[p] + alpha[q], beta[p] + beta[q]
            if direction == 'increase':
                if a_pq <= 0 or b_pq >= 0: continue
                score = a_pq * abs(b_pq)
            else:
                if a_pq >= 0 or b_pq <= 0: continue
                score = abs(a_pq) * b_pq
            if score > best_score:
                best_score, best_p, best_q = float(score), int(p), int(q)
    return best_p, best_q, best_score
```

El `range(i + 1, ...)` evita a la vez emparejar un píxel consigo mismo y evaluar $(p,q)$ y $(q,p)$ como pares distintos. El centinela `-1` señala "ningún par válido", distinguiéndolo de "el mejor par es el índice 0".

# La perturbación conjunta

```python
def apply_pair_perturbation(x, p, q, theta, increase, clip_min=0.0, clip_max=1.0):
    x_flat = x.view(-1).clone()
    step = theta if increase else -theta
    x_flat[p] = torch.clamp(x_flat[p] + step, clip_min, clip_max)
    x_flat[q] = torch.clamp(x_flat[q] + step, clip_min, clip_max)
    return x_flat.view(x.shape)
```

<mark style="background: #FF5582A6;">Los dos píxeles se mueven en la **misma** dirección, obligatoriamente.</mark> La puntuación del par se calculó sobre $\alpha_p + \alpha_q$ y $\beta_p + \beta_q$, y esas sumas solo describen el efecto real si ambos se desplazan igual. Subir uno y bajar el otro invalidaría la matemática que justificó la selección. El `clamp` se aplica por separado a cada uno: uno puede saturar y el otro no.

En el bucle principal se puntúan **ambas direcciones** por separado (`'increase'` y `'decrease'`), se elige la de mayor puntuación, y tras aplicar se enmascaran los dos píxeles y se retiran los saturados. El contador de $L_0$ avanza de dos en dos.

# Resultados

Con `theta=1.0`, `gamma=0.15`, `top_k=128`, `max_iter=90`, mismo 7 → 2 que falló con un píxel:

```txt
Iter   Pixels   Confidence   Score
0      2        0.0000       2.44320202
9      20       0.0000       0.70596105
21     44       0.0037       0.61113876
24     50       0.0185       0.37239930
27     56       0.2927       0.55573213
33     68       0.7262       0.41797119

✓ Target reached at iteration 34!   |  Pixels modified: 68  |  SUCCESS
```

Dos cosas destacan. Primera: **68 píxeles, un 8,7 % de la imagen**, frente a los 100 que gastó el ataque de un píxel sin éxito. Segunda, y más interesante: la confianza no crece de forma lineal. Se queda pegada a cero durante 20 iteraciones, arranca sobre la 24 (0,0185), y luego se dispara — 0,29 en la 27, 0,73 en la 33. <mark style="background: #FFB86CA6;">Las primeras modificaciones no parecen hacer nada porque están construyendo el terreno: desplazan la representación interna sin llegar a mover el `argmax`, hasta que el acumulado cruza la frontera y todo se derrumba de golpe.</mark>

Esto tiene una implicación defensiva concreta: **monitorizar la confianza de salida no detecta este ataque hasta que ya es tarde**. Durante el 70 % del ataque la salida del modelo es indistinguible de la normal. Lo que sí sería detectable es el patrón de consulta (docenas de variantes sistemáticas de la misma entrada base), que es la línea de detección que recoge [[04 - Detección y defensa contra la evasión|detección y defensa]].

## Un píxel frente a pares, sobre lote

| | Un píxel ($\theta=0{,}25$) | Por pares ($\theta=1{,}0$) |
| - | - | - |
| Tasa de éxito | 70 % | **90 %** |
| Píxeles medios | 73,6 | **42,8** |
| Iteraciones medias | 74,3 | **22,4** |
| Coste por iteración | 15,0 ms | 17,1 ms (+14 %) |

![Rejilla comparando JSMA de un píxel y por pares sobre 10 muestras: originales, perturbaciones y resultados](https://academy.hackthebox.com/storage/modules/320/jsma_attack_comparison.png)

El desglose del coste explica por qué el $O(n^2)$ no duele: la saliencia por pares tarda **2,13 ms**, la de un píxel es demasiado rápida para medirla (<0,01 ms), pero **el Jacobiano cuesta 15 ms y domina la iteración entera**. Un 14 % más por iteración a cambio de un 70 % menos de iteraciones es un cambio trivialmente favorable.

> [!warning]+ El ratio "644×" del módulo es engañoso
> HTB reporta que la saliencia por pares es 644 veces más lenta que la de un píxel. Ese número sale de dividir 2,13 ms entre un tiempo que **no se pudo medir** (por debajo de la resolución del reloj). Dividir por un valor en el suelo de medición infla el ratio arbitrariamente; el propio módulo lo admite. El dato honesto es el de la tabla: **+14 % por iteración**. Al citar benchmarks ajenos, comprobar siempre si el denominador está en el límite de resolución del instrumento.

## Guía de `top_k`

| `top_k` | Pares evaluados | Coste | Cuándo |
| - | - | - | - |
| 64 | 2016 | ~1 ms | Prioridad a la velocidad; algo menos de éxito |
| **128** | **8128** | **~3 ms** | Por defecto: rara vez se pierde el par óptimo |
| `None` | Todos | 10-20 ms | Búsqueda exhaustiva; la mejora casi nunca compensa |

# La sinergia: lo que el módulo intenta demostrar y no demuestra

HTB dedica una sección a probar que los pares tienen **sinergia** —que su efecto conjunto supera la suma de los individuales—, midiendo el impacto de cada píxel por separado y comparándolo con el del par. El resultado que publica es `0.000000` en los tres casos, con lo que la sinergia calculada es cero y el porcentaje ni siquiera es definible. Además el texto dice analizar el par `(352, 389)` mientras la salida corresponde a `(327, 538)`. La sección **no sostiene** su propia conclusión (ver la [[05 - Resultados de EAD y análisis de dispersión#Erratas de HTB en este módulo|lista de erratas]]).

La explicación no requiere invocar sinergia. La ventaja de la variante por pares se explica con dos factores medibles:

1. **Más candidatos admisibles.** Las restricciones sobre las sumas dejan pasar combinaciones que el filtro individual rechazaba, lo que amplía enormemente el espacio de búsqueda efectivo.
2. **El doble de magnitud por iteración.** Con $\theta = 1{,}0$ y dos píxeles saturados por paso, el presupuesto de perturbación se acumula al doble de velocidad — y, como demostró el barrido de $\theta$, la magnitud acumulada es exactamente lo que decide el éxito en este ataque.

<mark style="background: #FFB8EBA6;">La comparación limpia sería un píxel con $\theta = 1{,}0$ contra pares con $\theta = 1{,}0$;</mark> el módulo compara un píxel con $\theta = 0{,}25$ contra pares con $\theta = 1{,}0$, mezclando dos variables. Los datos disponibles apuntan a que la contribución de $\theta$ es al menos tan grande como la del emparejamiento: recuérdese que un píxel con $\theta = 1{,}0$ **sí** tuvo éxito, en 64 iteraciones y 63 píxeles.

# La distribución de $L_0$

![Histograma de L0 (píxeles modificados) con marcadores de media y mediana](https://academy.hackthebox.com/storage/modules/320/jsma_l0_distribution.png)

Sobre el conjunto de ataques de ambas variantes: **media 58,2, mediana 55,0, mínimo 12, máximo 118**. La media por encima de la mediana indica cola a la derecha — unos pocos casos caros arrastran el promedio.

El mínimo es el dato con más valor operativo: <mark style="background: #FF5582A6;">**12 píxeles**, un 1,5 % de la imagen, bastaron para forzar una clase concreta.</mark> Para un modelo de amenaza donde el atacante controla pocas features (unos bytes de una cabecera, un puñado de tokens, unas entradas de un vector de features), ese es el número que decide si el ataque es viable, no la media.

La comparación completa entre ambas familias y lo que se usa hoy en día está en [[09 - EAD frente a JSMA y el estado del arte en ataques L0|la nota de cierre]].
