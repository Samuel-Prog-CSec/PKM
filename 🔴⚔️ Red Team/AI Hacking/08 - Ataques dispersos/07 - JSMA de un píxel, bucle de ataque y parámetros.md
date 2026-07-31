---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "La variante voraz de un píxel por iteración, y por qué θ tiene un efecto umbral brutal: con θ<1 el ataque falla siempre y con θ=1 sale en 64 iteraciones"
Fecha de actualización: 2026-07-29
Nota previa: "[[06 - JSMA, el Jacobiano y los mapas de saliencia]]"
Nota siguiente: "[[08 - JSMA por pares, saliencia conjunta y poda]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

La variante más simple de JSMA modifica **una feature por iteración**: la de mayor saliencia. Sirve como línea base y para ver la mecánica sin ruido, pero sus resultados esconden la lección más útil del módulo sobre cómo se comporta realmente un ataque $L_0$.

# Las tres utilidades

```python
def apply_single_pixel_perturbation(x, pixel_idx, theta, increase, clip_min=0.0, clip_max=1.0):
    original_shape = x.shape
    x_flat = x.view(-1).clone()                      # clone: view comparte memoria con x
    perturbation = theta if increase else -theta
    x_flat[pixel_idx] = torch.clamp(x_flat[pixel_idx] + perturbation, clip_min, clip_max)
    return x_flat.view(original_shape)

def check_target_reached(x, target_class, model):
    with torch.no_grad():
        return int(model(x).argmax(dim=1).item()) == target_class

def compute_confidence(x, target_class, model):
    with torch.no_grad():
        return float(F.softmax(model(x), dim=1)[0, target_class].item())
```

<mark style="background: #FF5582A6;">El `.clone()` no es opcional:</mark> `view(-1)` devuelve una **vista** que comparte memoria con el tensor original. Modificar `x_flat[352]` sin clonar corrompería la imagen de entrada `x`, y el error se propagaría a todas las iteraciones siguientes sin que nada avise.

`compute_confidence` aplica `softmax` —a diferencia del cálculo de gradientes, que va sobre logits— porque aquí solo se **observa** la progresión, no se optimiza. Es la métrica que dice si el ataque avanza o está atascado.

# El bucle

```python
for iteration in range(config['max_iter']):
    if check_target_reached(x_adv, target_class, model):      # comprobar ANTES de gastar
        break
    if pixels_modified >= max_pixels:
        break

    jacobian = compute_jacobian_matrix(x_adv, model, 10, config['wrt'])
    alpha = apply_search_mask(extract_target_gradient(jacobian, target_class), search_space)
    beta  = apply_search_mask(extract_other_gradients(jacobian, target_class), search_space)

    inc_scores = score_increase_saliency(alpha, beta)
    dec_scores = score_decrease_saliency(alpha, beta)
    pixel_idx, saliency, increase = select_best_direction(inc_scores, dec_scores)

    if saliency <= 0:                                         # sin candidatos válidos
        break

    x_adv = apply_single_pixel_perturbation(x_adv, pixel_idx, config['theta'], increase,
                                            config['clip_min'], config['clip_max'])
    search_space[pixel_idx] = False
    search_space = remove_saturated_pixels(search_space, x_adv, clip_min, clip_max)
    pixels_modified += 1
```

El orden importa: las comprobaciones de terminación van **antes** del Jacobiano. Verificar el éxito cuesta una pasada hacia delante (milisegundos) y verificar el presupuesto es una comparación de enteros; el Jacobiano cuesta 10 pasadas hacia atrás (10-15 ms). Colocarlas al final desperdiciaría una iteración completa cada vez que el ataque ya ha terminado.

La salida por `saliency <= 0` cubre el caso en que ningún píxel disponible cumple las restricciones de signo en ninguna dirección: el espacio de búsqueda está agotado y seguir iterando no cambiaría nada.

# Los resultados, y el problema que revelan

Con `theta=0.25`, `gamma=0.15`, `max_iter=100`, atacando un 7 hacia la clase 2:

```txt
Iter   Pixels   Confidence   Saliency
0      1        0.0000       0.641185
10     11       0.0000       0.343316
30     31       0.0000       0.071866
60     61       0.0001       0.043980
95     96       0.0002       0.014142

Final result: FAILED    |  Pixels modified: 100/117  |  Iterations: 100
```

Cien píxeles tocados, confianza en la clase objetivo **0,0002**. El ataque no se acercó ni de lejos a la frontera. Y la saliencia cae de 0,641 a 0,014: <mark style="background: #FFB86CA6;">rendimientos decrecientes claros — los píxeles de alto valor se agotan y quedan los mediocres.</mark>

El barrido de $\theta$ sobre la misma muestra explica por qué:

| $\theta$ | Iteraciones | Píxeles | Resultado |
| - | - | - | - |
| 0,10 | 100 | 100 | FALLO |
| 0,25 | 100 | 100 | FALLO |
| 0,50 | 100 | 100 | FALLO |
| **1,00** | **64** | **63** | **ÉXITO** |

<mark style="background: #8000E1A6;">No es una curva suave: es un efecto umbral.</mark> Tres valores fallan por completo y el cuarto resuelve en 64 iteraciones.

## Por qué: el detalle que HTB no conecta

La explicación habitual —"$\theta = 1{,}0$ satura el píxel de golpe y acumula magnitud más rápido"— es correcta pero incompleta. La razón estructural está en esta línea del bucle:

```python
search_space[pixel_idx] = False     # el píxel queda fuera para siempre
```

**Cada píxel puede seleccionarse una sola vez.** Con $\theta = 0{,}25$, un píxel que arranca en 0,0 llega como mucho a 0,25 y nunca vuelve a tocarse. Con $\theta = 1{,}0$, la primera selección lo satura. Es decir: <mark style="background: #FF5582A6;">en esta implementación, $\theta$ no es "cuánto cambia por iteración" sino **"cuánto cambia ese píxel, definitivamente"**.</mark> Los valores pequeños no producen perturbaciones sutiles: producen perturbaciones **débiles e irrecuperables**, y con 117 píxeles de presupuesto a 0,25 cada uno no hay magnitud acumulada suficiente para cruzar ninguna frontera.

La correspondencia uno a uno entre iteraciones y píxeles (63 píxeles en 64 iteraciones) lo confirma numéricamente.

> [!warning]+ Contradicción interna del módulo
> La sección de fundamentos de HTB afirma que con `theta=0.25` "un píxel negro pasa a 0,25, luego a 0,50 si se selecciona otra vez, y necesita cuatro selecciones para saturar en 1,0". El código que muestran **impide esas reselecciones**. Ambas cosas no pueden ser ciertas a la vez, y es el código el que manda: por eso los $\theta$ pequeños fallan. La variante canónica del paper de Papernot usa directamente $\theta = \pm 1$ (saturación completa) sobre **pares** de features; la versión de un píxel con $\theta$ fraccionario es una simplificación didáctica, no el algoritmo original.

Corolario operativo: <mark style="background: #FFB8EBA6;">JSMA no es un ataque "disperso y sutil", es un ataque "disperso y extremo".</mark> Si el objetivo real es sutileza, la herramienta es [[01 - ElasticNet (EAD) y la mezcla L1 + L2|EAD]] o un ataque $L_2$; JSMA existe precisamente para cuando la restricción es el **número** de features y la magnitud da igual — que es justo el modelo de amenaza de un binario, un texto o un paquete de red.

# El presupuesto $\gamma$

$\gamma$ traduce a número de píxeles: $\gamma \times 784$.

| $\gamma$ | Píxeles máximos | % de la imagen |
| - | - | - |
| 0,10 | 78 | 10 % |
| 0,15 | 117 | 15 % |
| 0,20 | 157 | 20 % |
| 0,30 | 235 | 30 % |

Sobre 10 muestras con $\theta = 0{,}25$: **70 % de éxito** (7/10), media de 73,6 píxeles (~63 % del presupuesto), rango de los exitosos 33-92 píxeles; los 3 fallos agotaron las 100 iteraciones.

De ahí sale la lectura de $\gamma$: apretarlo a 0,10 (78 píxeles) recortaría los ataques que necesitaron 86-92, bajando la tasa de éxito. Aflojarlo a 0,30 (235 píxeles) no mejora nada, porque casi todos los éxitos terminan muy por debajo del límite actual. <mark style="background: #ADCCFFA6;">El presupuesto solo es vinculante en la cola de casos difíciles;</mark> ampliarlo no compra éxito, solo permite perturbaciones más burdas en los pocos casos que ya iban mal.

> [!important]+ Qué mirar al evaluar un ataque disperso
> El número que importa **no** es la tasa de éxito con presupuesto generoso, sino la **distribución de $L_0$ de los ataques exitosos**. Un modelo que cede con 33 píxeles en el mejor caso y 92 en el peor tiene un perfil de riesgo muy distinto al de uno que necesita 90 siempre: el primero es vulnerable a atacantes con acceso muy limitado a features. Reportar media y rango, no solo el porcentaje.

La variante voraz de un píxel es una línea base débil: no modela la interacción entre features, que es precisamente donde vive la no linealidad de una red. El algoritmo canónico modifica **pares**, y los números cambian mucho: [[08 - JSMA por pares, saliencia conjunta y poda|JSMA por pares]].
