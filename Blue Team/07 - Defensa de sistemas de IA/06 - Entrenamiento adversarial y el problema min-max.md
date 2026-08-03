---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/Adversarial
  - Tipo/Defensa
Descripción: "Entrenar con ejemplos adversariales frescos resuelve un problema min-max; por qué funciona, qué cuesta y por qué usar solo FGSM en el bucle interno es un error"
Fecha de actualización: 2026-07-29
Nota previa: "[[05 - Servicios gestionados de guardrails]]"
Nota siguiente: "[[07 - Epsilon spread y evaluación de robustez]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Los guardrails filtran **alrededor** del modelo. Contra [[00 - Fundamentos de la evasión de modelos|perturbaciones adversariales]] eso no sirve: la entrada maliciosa es indistinguible de una legítima. La defensa tiene que venir de dentro — **entrenar el modelo para que sea robusto**.

# Por qué falla el entrenamiento estándar

El optimizador minimiza la pérdida sobre la distribución de entrenamiento y encuentra fronteras que separan bien las clases **sobre los datos que ha visto**. Funciona en test porque la variación natural del test se parece a la del entrenamiento.

<mark style="background: #ADCCFFA6;">Las perturbaciones adversariales explotan el hueco: el optimizador **nunca encuentra** entradas que caen ligeramente fuera de la variedad de datos.</mark> Las imágenes naturales se concentran en una variedad de baja dimensión dentro de un espacio enorme; cuando [[02 - FGSM, el ataque de un solo paso|FGSM]] empuja una imagen en la dirección que maximiza la pérdida, la mueve a territorio inexplorado donde la frontera puede curvarse de forma impredecible. Un 3 perturbado cruza a la región del 8 no porque se parezca a un 8, sino porque **el modelo nunca aprendió** que esa combinación concreta de píxeles sigue siendo un 3.

La causa raíz es de cobertura: el entrenamiento estándar muestrea una fracción minúscula de un espacio de entrada de altísima dimensión.

# La solución: vacunar el modelo

<mark style="background: #8000E1A6;">Exponer al modelo a versiones debilitadas del ataque durante el entrenamiento para que desarrolle inmunidad antes del despliegue.</mark> Cada lote pasa por dos fases: generar perturbaciones con los gradientes del modelo **actual**, y entrenar sobre las imágenes limpias y las adversariales a la vez.

```pseudocode
para cada lote (imagenes, etiquetas):
    1. adv = FGSM(modelo, imagenes, etiquetas, epsilon)     # ataque con el modelo actual
    2. combinadas  = concat(imagenes, adv)
    3. etiquetas_c = concat(etiquetas, etiquetas)           # MISMA etiqueta para ambas
    4. salidas = modelo(combinadas)
    5. perdida = cross_entropy(salidas, etiquetas_c)
    6. perdida.backward(); optimizer.step()
```

Dos detalles decisivos:

- **Los ejemplos adversariales se generan frescos en cada lote**, no una vez al principio. El ataque se adapta según el modelo se adapta: al principio el modelo es débil y genera ataques débiles; al final genera ataques que reflejan las vulnerabilidades de un modelo fuerte, que son las que importan en despliegue. Esa **coevolución** es lo que hace que la defensa siga a la amenaza.
- **La etiqueta del ejemplo adversarial es la original**, no la que provoca el ataque. Se le está enseñando al modelo que ese 3 perturbado sigue siendo un 3.

Y la razón de que esto funcione donde el ruido aleatorio no: el ruido explora el espacio de forma uniforme y gasta capacidad en regiones que ningún atacante visitaría. FGSM apunta exactamente a las direcciones donde la pérdida crece más rápido. <mark style="background: #FFB86CA6;">La defensa se ajusta a la amenaza en vez de confiar en que la regularización general baste.</mark>

# La formulación min-max

$$\min_\theta \; \mathbb{E}_{(x,y) \sim D}\left[\; \max_{x' \in \mathcal{B}_\epsilon(x)} L(f_\theta(x'), y) \;\right]$$

Frente al entrenamiento estándar, que minimiza $\mathbb{E}[L(f_\theta(x), y)]$, aquí se minimiza la **peor pérdida dentro de la bola de radio $\epsilon$**. La maximización interna busca la peor perturbación para el modelo actual; la minimización externa ajusta los pesos para reducir ese peor caso. FGSM es una aproximación eficiente al máximo interno: en vez de buscar exhaustivamente en $\mathcal{B}_\epsilon(x)$, da un solo paso de gradiente.

Geométricamente explica por qué produce fronteras robustas: minimizar la pérdida del peor caso dentro de la bola **empuja las fronteras al menos $\epsilon$ lejos de cada punto de entrenamiento**. Los puntos que estaban pegados a una frontera quedan dentro del margen, y la frontera tiene que acomodar ese margen ampliado sin clasificar mal el resto.

> [!info]+ Fuente primaria
> La formulación min-max y el entrenamiento adversarial con PGD son de [*Towards Deep Learning Models Resistant to Adversarial Attacks*, arXiv:1706.06083](https://arxiv.org/abs/1706.06083) — Madry, Makelov, Schmidt, Tsipras y Vladu, ICLR 2018. Es el paper que HTB no cita y que define el estándar de esta defensa.

# El error de usar solo FGSM en el bucle interno

<mark style="background: #FF5582A6;">Aquí está la corrección más importante de esta sección.</mark> El laboratorio genera los ejemplos adversariales con **FGSM**, un solo paso. El estándar es [[03 - I-FGSM, PGD y el refinamiento iterativo|PGD]], que aproxima mucho mejor la maximización interna. La diferencia no es de matiz:

- **Catastrophic overfitting.** El entrenamiento adversarial solo con FGSM es conocido por colapsar de golpe a mitad del entrenamiento: el modelo aprende a **enmascarar el gradiente** en lugar de a ser robusto. El resultado parece excelente frente a FGSM y cae frente a PGD o [[03 - GoodWords en caja negra con bandits|ataques de estimación de gradiente]]. Es un modo de fallo silencioso — no hay error, solo una métrica que miente.
- **La mitigación conocida** es o bien PGD-AT directamente (más caro), o bien FGSM con **inicialización aleatoria uniforme** dentro de la bola $\epsilon$ antes del paso de gradiente, que es lo que hace viable el "FGSM rápido" sin colapso.
- **El gradient masking es un antipatrón reconocido** por la comunidad de robustez: da falsa sensación de seguridad y se evade con transferencia o estimación del gradiente ([[04 - Detección y defensa contra la evasión|detección y defensa contra la evasión]]).

Que el modelo del módulo aguante también I-FGSM (97,6 %) sugiere que en este caso no colapsó — MNIST es benévolo. **No hay que generalizar ese resultado**: en CIFAR-10 y arquitecturas mayores, FGSM-AT sin inicialización aleatoria falla con frecuencia.

# El compromiso robustez / precisión limpia

Hacer el modelo robusto **cuesta precisión sobre entradas limpias**. El modelo dedica capacidad a manejar variaciones que no encontraría de forma natural, y le queda menos para distinciones finas. Con la misma arquitectura sobre MNIST: ~99 % limpia y colapso bajo ataque sin defensa; ~98 % limpia y ~95 % robusta con entrenamiento adversarial. **Un punto de precisión limpia a cambio de decenas de puntos de robustez** — sobre MNIST, un cambio claramente favorable; sobre tareas difíciles, la caída es mucho mayor.

La palanca de ajuste es la **proporción limpio/adversarial** en el lote: 50/50 por defecto (favorece robustez), 70/30 preserva más precisión limpia. La elección depende del despliegue: un sistema bajo sondeo adversarial constante prioriza robustez; uno que espera tráfico mayoritariamente limpio, precisión.

> [!important]+ TRADES: el compromiso como objetivo explícito
> En lugar de mezclar lotes a ojo, existe una formulación que **parametriza** el compromiso directamente en la función de pérdida: `TRADES` ([Zhang et al., ICML 2019, arXiv:1901.08573](https://arxiv.org/abs/1901.08573)) descompone el error robusto en error natural más error de frontera, y expone un coeficiente que interpola entre ambos. Es lo que usan la mayoría de las entradas altas de [RobustBench](https://robustbench.github.io/), y da un control más principiado que el ratio de mezcla.

# Hiperparámetros y coste

| Parámetro | Valor típico | Por qué difiere del estándar |
| - | - | - |
| Tasa de aprendizaje | 0,001 (vs 0,01) | El paisaje de pérdida combinado es más complejo |
| `weight decay` | Activo | Evita sobreajustar a patrones adversariales concretos |
| Recorte de gradiente | Activo | Las pérdidas adversariales son enormes en las primeras épocas |
| Épocas | 20-30 (vs 10) | Hay que aprender clasificación limpia **y** robustez |
| Planificador | Cosine annealing o step decay | Ayuda a asentarse en mínimos robustos en vez de oscilar |

El patrón de convergencia también cambia: las primeras épocas mejoran rápido la precisión limpia mientras la robustez va por detrás; las últimas refinan las fronteras para ganar robustez sin perder rendimiento limpio.

**Coste: 2-3× por época.** Cada lote necesita una pasada adelante y atrás extra para generar el ataque, más el doble de tamaño efectivo de lote. Un MNIST robusto son 5-10 minutos en GPU; una ResNet sobre CIFAR-10, varias horas frente a una. <mark style="background: #FFB8EBA6;">El coste escala linealmente, así que sigue siendo viable en producción</mark>, y se puede recortar con precisión mixta (FP16, ~mitad de tiempo y memoria) o con *free adversarial training*, que reutiliza los gradientes del paso de entrenamiento para calcular la perturbación y ahorra el par extra.

# Límites

- **Robustez específica del ataque entrenado.** Un modelo entrenado contra FGSM puede seguir siendo vulnerable a ataques que optimizan mejor, como [[06 - JSMA, el Jacobiano y los mapas de saliencia|JSMA]] — y **específica de la norma**: entrenar en $L_\infty$ no protege frente a [[00 - Fundamentos de los ataques dispersos y la norma L0|ataques dispersos $L_0$]].
- **Ataques de transferencia.** El adversario entrena su propio modelo, genera ejemplos contra él y los aplica al objetivo. Si su arquitectura o sus datos difieren, puede explotar vulnerabilidades que el objetivo nunca entrenó. El *ensemble adversarial training* (generar ataques contra varios modelos) es una defensa parcial.
- **Defensas certificadas** como alternativa: en vez de entrenar contra ataques concretos, dan garantía matemática de que ninguno dentro de la bola $\epsilon$ cambia la predicción (*randomized smoothing*, propagación de intervalos). Consiguen menos precisión robusta, pero **garantizada**.

Cómo se mide todo esto —y las trampas de medirlo mal— es [[07 - Epsilon spread y evaluación de robustez|la nota siguiente]].
