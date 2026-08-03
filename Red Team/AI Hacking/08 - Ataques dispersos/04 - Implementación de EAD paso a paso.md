---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "La iteración FISTA completa y los dos bucles anidados de EAD, con los detalles de PyTorch que rompen el ataque en silencio si se hacen mal"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - El objetivo de EAD, margen C&W y binary search]]"
Nota siguiente: "[[05 - Resultados de EAD y análisis de dispersión]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

Todas las piezas juntas: gradiente sobre la parte suave, operador proximal sobre la no suave, momento para acelerar, y por encima la búsqueda binaria que calibra la presión. <mark style="background: #ADCCFFA6;">EAD son dos bucles anidados que resuelven dos subproblemas distintos: FISTA minimiza la distorsión con $c$ fijo; la búsqueda binaria ajusta $c$.</mark>

# La iteración FISTA

```python
def fista_step(adv_images, y_momentum, original_images, labels_onehot, const,
               model, beta, learning_rate, confidence, iteration,
               targeted=False, clip_min=0.0, clip_max=1.0):
    # 1. Grafo limpio para esta iteración
    y_momentum = y_momentum.detach().requires_grad_(True)

    # 2. Pérdida evaluada en el punto de momento, NO en la solución actual
    total_loss, adversarial_loss, distances = compute_total_loss(
        y_momentum, original_images, labels_onehot, const,
        model, beta, confidence, targeted)

    # 3. Gradiente respecto a la ENTRADA
    total_loss_summed = total_loss.sum()
    total_loss_summed.backward()
    grad = y_momentum.grad

    # 4. Paso de gradiente sobre la parte suave
    y_new = y_momentum - learning_rate * grad

    # 5. Operador proximal: umbral = learning_rate * beta
    adv_new = apply_shrinkage_thresholding(
        y_new, original_images, learning_rate * beta, clip_min, clip_max)

    # 6. Extrapolación de Nesterov
    momentum_coef = compute_fista_momentum(iteration)
    y_new_momentum = adv_new + momentum_coef * (adv_new - adv_images)

    return adv_new, y_new_momentum, total_loss_summed.item(), distances
```

Cuatro detalles que deciden si el ataque funciona:

- **`detach()` seguido de `requires_grad_(True)`** (línea 1). El `detach()` corta el grafo que PyTorch construyó en la iteración anterior. Sin él los gradientes se acumularían entre iteraciones y el consumo de memoria crecería sin límite, además de producir valores incorrectos. El `requires_grad_(True)` reabre el seguimiento solo para esta iteración.
- **Gradiente respecto a la entrada, no a los pesos.** El modelo está congelado; lo que se optimiza es la imagen. Es la diferencia estructural entre entrenar y atacar, y la razón de que `backward()` sea la operación cara del bucle.
- **El umbral es $\eta\beta$, no $\beta$** (línea 5). Confundirlo es un error clásico: el operador proximal se aplica tras un paso de tamaño $\eta$, así que el umbral tiene que escalar igual. Con `learning_rate=0.01` y `beta=0.01`, el umbral efectivo es $10^{-4}$ — mucho más pequeño de lo que sugiere leer `beta` a secas.
- **La pérdida se evalúa en `y_momentum`** (línea 2), el punto extrapolado, no en `adv_images`. Es literalmente lo que separa FISTA del gradiente proximal básico.

## El operador proximal, con restricciones de caja

```python
def apply_shrinkage_thresholding(y, original_images, threshold, clip_min=0.0, clip_max=1.0):
    diff = y - original_images

    shrink_positive = torch.clamp(y - threshold, min=clip_min, max=clip_max)
    shrink_negative = torch.clamp(y + threshold, min=clip_min, max=clip_max)

    cond_positive = (diff >  threshold).float()
    cond_zero     = (torch.abs(diff) <= threshold).float()
    cond_negative = (diff < -threshold).float()

    return (cond_positive * shrink_positive
            + cond_zero   * original_images
            + cond_negative * shrink_negative)
```

Las tres condiciones son mutuamente excluyentes y cubren el dominio, así que la suma ponderada equivale a un `if/elif/else` vectorizado. <mark style="background: #FFB8EBA6;">La rama del medio devuelve `original_images`, no cero:</mark> se anula la **perturbación**, restaurando el píxel original. El `clamp` integra las restricciones de caja dentro del operador proximal en lugar de aplicarlas después, lo que evita que un paso de gradiente saque el píxel del dominio y luego el thresholding calcule sobre un valor imposible.

# Los dos bucles

```python
for binary_step in range(config["binary_search_steps"]):
    # Reinicio desde la imagen original en CADA paso de búsqueda binaria
    adv_images = original_images.clone().detach()
    y_momentum = adv_images.clone()

    for iteration in range(config["max_iterations"]):
        adv_images, y_momentum, loss, distances = fista_step(...)

    success_mask = check_attack_success(adv_images, attack_targets, model)
    l1_dist, l2_dist, elastic_dist = compute_distances(adv_images, original_images, config["beta"])

    for i in range(batch_size):
        if success_mask[i] and l2_dist[i] < best_l2[i]:
            best_adv[i] = adv_images[i]
            best_l2[i]  = l2_dist[i]

    lower_bound, upper_bound, const = update_binary_search_bounds(
        lower_bound, upper_bound, const, success_mask)
```

<mark style="background: #FF5582A6;">El reinicio desde la imagen original en cada paso de búsqueda binaria no es opcional.</mark> Sin él, la perturbación optimizada para $c = 0{,}001$ persistiría al evaluar $c = 0{,}01$, contaminando el resultado: no se estaría midiendo qué hace $c=0{,}01$ desde cero, sino qué hace sobre un punto ya perturbado. Los resultados dejarían de ser interpretables y la búsqueda binaria convergería a constantes falsas.

El seguimiento del mejor ataque guarda **solo** los éxitos con menor $L_2$ que el récord previo, así que al final `best_adv` contiene, por ejemplo, la perturbación más pequeña que consiguió engañar al modelo en todo el proceso.

> [!warning]+ Dos cosas mejorables de este código
> **El bucle `for i in range(batch_size)` en Python** recorre el lote elemento a elemento — con lotes grandes se nota. Se vectoriza limpiamente:
> ```python
> improved = success_mask & (l2_dist < best_l2)
> best_adv = torch.where(improved.view(-1, 1, 1, 1), adv_images, best_adv)
> best_l2  = torch.where(improved, l2_dist, best_l2)
> ```
> **La prosa de HTB dice que hay comprobaciones periódicas de éxito dentro del bucle FISTA** que permiten salir antes si todo el lote ya engaña al modelo. El código que muestra **no las tiene**: comprobando la indentación del original, `check_attack_success` queda al mismo nivel que `for iteration`, es decir **fuera** del bucle interno, así que se ejecuta una vez por paso de búsqueda binaria y no una vez por iteración.
>
> Tiene dos consecuencias, y la segunda importa más que la primera: se pierde la salida temprana —cientos de iteraciones inútiles sobre ejemplos fáciles—, pero sobre todo <mark style="background: #FFB86CA6;">`best_adv` solo puede capturar el estado de la perturbación **al final** de cada ciclo FISTA</mark>. Si en la iteración 300 el ataque tenía éxito con distorsión mínima y en la 1000 sigue teniendo éxito con más distorsión, se guarda la peor de las dos. Mover la comprobación dentro del bucle mejora la calidad del resultado, no solo el tiempo.

# Configuración y selección de muestras

```python
config = {
    "beta": 0.01,               # L1 vs L2 (mayor = más disperso)
    "confidence": 0,            # kappa
    "learning_rate": 0.01,      # paso de FISTA
    "max_iterations": 1000,     # iteraciones FISTA por paso de búsqueda binaria
    "binary_search_steps": 5,
    "initial_const": 0.001,
    "clip_min": 0.0,
    "clip_max": 1.0,
}
```

Sensibilidad de cada parámetro, de mayor a menor:

| Parámetro | Efecto de desviarse |
| - | - |
| `learning_rate` | **El más sensible.** Por encima de 0,05 en MNIST la optimización diverge y oscila; por debajo de 0,001 hacen falta 2000-5000 iteraciones en vez de 1000 |
| `beta` | Sensibilidad media. De 0,01 a 0,02 sube la dispersión 10-15 puntos y baja el éxito 5-10 % en los casos difíciles |
| `binary_search_steps` | Compensación pura cómputo/precisión (ver [[03 - El objetivo de EAD, margen C&W y binary search\|nota anterior]]) |
| `confidence` | No afecta a la convergencia, sí a la robustez del ejemplo frente al preprocesado |

Un detalle metodológico que se salta con demasiada frecuencia: **solo se atacan ejemplos que el modelo ya clasifica bien**.

```python
correct_mask   = predictions.eq(targets)
attack_data    = data[correct_mask][:num_samples]
attack_targets = targets[correct_mask][:num_samples]
```

Atacar una entrada ya mal clasificada infla la tasa de éxito con casos que no demuestran nada. <mark style="background: #FFB86CA6;">Al leer una evaluación de robustez ajena, comprobar si filtró por predicción correcta es la primera pregunta:</mark> sin ese filtro, la "tasa de éxito del ataque" incluye los errores propios del modelo.

# Coste y perfil computacional

Para 20 ejemplos de MNIST con 5 pasos de búsqueda binaria y 1000 iteraciones FISTA cada uno: unas 5000 pasadas hacia delante y 5000 hacia atrás sobre el lote (≈100 000 evaluaciones por imagen individual). En una GPU moderna (RTX 3090 o superior), **2-3 minutos**; en CPU, **30-60 minutos**. Memoria: ~400 MB para lote de 20; ~1 GB para 50, con un 15-25 % más de rendimiento por amortización.

<mark style="background: #8000E1A6;">El orden de magnitud es lo relevante para planificar: EAD es entre dos y tres órdenes más caro que FGSM por ejemplo generado.</mark> No es un ataque para barrer un dataset entero en un engagement con reloj; es un ataque para casos concretos donde la dispersión o la transferibilidad justifican el gasto. Cuando hacen falta volúmenes, la vía es [[03 - I-FGSM, PGD y el refinamiento iterativo|PGD]] o una implementación de biblioteca sobre GPU.

> [!info]+ En la práctica, no se implementa a mano
> Escribir EAD desde cero es el ejercicio didáctico; en un engagement se usa `ElasticNet` de **ART** o el `EADAttack` de otras suites, que ya traen el batching, las restricciones y las variantes `EN`/`L1` de la regla de decisión del paper. Ver [[05 - Arsenal para la evasión de modelos|el arsenal de evasión]]. Implementarlo a mano tiene un uso legítimo: cuando el objetivo no es una imagen y hay que redefinir las restricciones de caja y la métrica de distancia sobre el dominio real (features de malware, campos de un log).

Los [[05 - Resultados de EAD y análisis de dispersión|resultados]] muestran qué dispersión se consigue realmente y dónde se concentran los píxeles elegidos.
