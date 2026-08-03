---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Tipo/Defensa
Descripción: "Contra la evasión no hay parche perfecto: el entrenamiento adversarial cuesta precisión, la robustez certificada solo cubre un radio, y ninguna defensa se hereda entre normas"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - GoodWords en caja negra con bandits]]"
Nota siguiente: "[[05 - Arsenal para la evasión de modelos]]"
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

<mark style="background: #ADCCFFA6;">Contra la evasión no existe un parche perfecto, porque la vulnerabilidad está en cómo aprenden los modelos, no en un bug concreto.</mark> Lo que hay es un abanico de defensas con compromisos claros: endurecer el modelo cuesta precisión, garantizar robustez cuesta cobertura, y detectar el ataque en curso es lo único que aplica a los modelos ya desplegados. Esta nota cubre las defensas para las tres carpetas de evasión —clasificadores clásicos ([[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords]]), redes neuronales ([[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]]) y perturbaciones dispersas ([[00 - Fundamentos de los ataques dispersos y la norma L0|ataques $L_0$]])— porque el problema y buena parte de las soluciones son comunes.

# Por qué las defensas obvias fallan

Antes de las que funcionan, las que no:

- **Ocultar el modelo** (seguridad por oscuridad). Ya visto: el ataque de [[03 - GoodWords en caja negra con bandits|caja negra]] logra el 85-95% del de caja blanca. La vulnerabilidad es arquitectónica, no de fuga.
- **Filtrar entradas sospechosas por reglas.** Un `GoodWords` bien hecho mantiene coherencia lingüística; una perturbación de primer orden es imperceptible. No hay regla simple que las distinga de entrada legítima.
- **Ofuscar el gradiente** (*gradient masking*). Rompe los ataques que dependen del gradiente exacto, pero se evade con ataques de transferencia o de estimación del gradiente. La comunidad lo considera un antipatrón: da falsa sensación de robustez.

# Defensa 1: entrenamiento adversarial

<mark style="background: #FFB86CA6;">La defensa empírica más efectiva: entrenar el modelo con ejemplos adversariales incluidos en el conjunto de entrenamiento.</mark> Se generan ataques (FGSM, [[03 - I-FGSM, PGD y el refinamiento iterativo|PGD]]) sobre cada lote y se añaden con la etiqueta correcta, forzando al modelo a aprender fronteras de decisión que resisten la perturbación.

- **Fortaleza**: es lo que encabeza los `leaderboards` de robustez. Un modelo con entrenamiento adversarial PGD resiste la mayoría de ataques de primer orden dentro del presupuesto para el que se entrenó.
- **Coste**: <mark style="background: #FF5582A6;">sacrifica precisión en entradas limpias</mark> (el *trade-off* robustez/precisión) y multiplica el coste de entrenamiento (generar ataques en cada iteración). Además, es **específico de la norma** para la que se entrenó — ver el hueco $L_0$ más abajo, que es el fallo de cobertura más explotable de esta defensa.

> [!info]+ Cómo se implementa, en Blue Team
> Esta nota da el panorama de defensas desde el lado del atacante. La **construcción** del entrenamiento adversarial —bucle min-max, generación de ejemplos frescos por lote, `epsilon spread`, hiperparámetros y evaluación con tabla de robustez por $\epsilon$— está en [[06 - Entrenamiento adversarial y el problema min-max|Defensa de sistemas de IA]] y [[07 - Epsilon spread y evaluación de robustez|su nota de evaluación]].

> [!info]+ Fuente: RobustBench
> [RobustBench](https://robustbench.github.io/) es el `leaderboard` estándar de robustez adversarial (60+ modelos, CIFAR-10 e ImageNet). La regla de oro que impone: **una defensa vale lo que vale el protocolo que la evalúa.** Muchas defensas publicadas se rompieron al re-evaluarse con ataques adaptativos. Para afirmar que un modelo es robusto, se evalúa con `AutoAttack`, no con un FGSM suave.

# Defensa 2: robustez certificada

Frente al entrenamiento adversarial —que es empírico y puede romperse con un ataque nuevo—, la robustez **certificada** ofrece una garantía matemática: *para esta entrada, ninguna perturbación dentro de un radio $r$ cambia la predicción*.

- **`Randomized smoothing`** ([Cohen et al., 2019](https://arxiv.org/abs/1902.02918)) es la técnica dominante: se clasifica promediando predicciones sobre versiones ruidosas de la entrada, lo que produce un clasificador "suavizado" con un radio certificado en norma $L_2$. Escala a ImageNet, cosa rara en defensas certificadas.
- **Coste**: la garantía cubre solo un radio pequeño; fuera de él, no dice nada. Y añade sobrecoste de inferencia (múltiples pasadas con ruido). Es minoría en el corpus pero la única línea con *garantías*, no solo resultados empíricos.
- **Para $L_0$ no sirve el ruido aditivo**: la técnica equivalente es la **ablación aleatoria** de Levine y Feizi ([arXiv:1911.09272](https://arxiv.org/abs/1911.09272), AAAI 2020), que en vez de añadir ruido **borra** features al azar y clasifica por mayoría. Sobre MNIST certifica más del 50 % de las imágenes frente a cualquier alteración de hasta **8 píxeles**, con una caída de precisión limpia de ~2,3 %, y resiste empíricamente hasta ~31 píxeles en mediana. Los certificados que obtiene doblan a los del ruido aleatorio (8 frente a 4 píxeles en MNIST; 16 frente a 1 en ImageNet).

# Defensa 3: específicas de clasificadores clásicos

Para el caso [[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords]] hay defensas más directas que atacan la asunción de independencia:

- **Modelar contexto y relaciones entre palabras** — n-gramas, o directamente un modelo que capture dependencias (un transformer pequeño). Rompe la premisa aditiva: si el modelo penaliza "premio de £900" junto a "nos vemos mañana", añadir good words deja de funcionar.
- **Límite al desajuste longitud/contenido** — detectar mensajes cortos y spam-like inflados con muchas palabras conversacionales sin relación.
- **Pesado de features robusto** — reducir la influencia de palabras individuales para que acumular muchas no baste, a costa de sensibilidad.
- **Reentrenamiento periódico** — las distribuciones estáticas son lo que el atacante estudia; moverlas encarece el ataque (aunque no lo cierra).

# Defensa 4: detección del ataque en curso

Es la única que aplica a un **modelo ya desplegado** que no se puede reentrenar, y la más relevante en un pentest defensivo:

- **Monitorización del patrón de consultas.** El ataque de [[03 - GoodWords en caja negra con bandits|caja negra]] —y todo ataque de evasión de caja negra— genera un patrón de sondeo anómalo: muchas variaciones sistemáticas del mismo input base, cobertura inusual del espacio. Es la misma señal que la [[01 - Model reverse engineering y robo de modelos#Detección y mitigación|detección de model extraction]], porque descubrir la superficie del modelo *es* una forma de extracción.
- **Detección de ejemplos adversariales** — clasificadores auxiliares entrenados para distinguir entradas naturales de perturbadas, o comprobar la consistencia de la predicción bajo pequeñas transformaciones (una entrada adversarial suele ser inestable). Útil, pero también sujeto a ataques adaptativos que evaden el detector.
- **`Rate limiting` por identidad** — encarece el sondeo de caja negra, que necesita muchas consultas. No para al atacante distribuido, pero eleva el coste.

# El hueco $L_0$: la defensa no se hereda entre normas

<mark style="background: #FF5582A6;">Es el fallo de cobertura más explotable de todo el panorama defensivo, y el que más veces se pasa por alto en un informe.</mark> Un modelo endurecido con entrenamiento adversarial $L_\infty$ —PGD-AT, el estándar de facto— **no queda protegido** frente a perturbaciones dispersas.

> [!info]+ La evidencia
> [*Attacking the Madry Defense Model with $L_1$-based Adversarial Examples*, arXiv:1710.10733](https://arxiv.org/abs/1710.10733) — Sharma y Chen, ICLR 2018 Workshops. Los ejemplos de [[01 - ElasticNet (EAD) y la mezcla L1 + L2|EAD]] derrotan al modelo de Madry, la referencia de robustez $L_\infty$, y con distorsión visual mínima pese a tener $L_\infty$ media alta. Conclusión de los autores: **$L_\infty$ es una medida insuficiente de la distorsión perceptual**.

Las razones son estructurales: el entrenamiento adversarial aprende a resistir el *tipo* de perturbación que vio (ruido acotado repartido por toda la entrada), no un puñado de features saturadas. Y `AutoAttack`, que es la vara de medir estándar, **solo cubre $L_\infty$ y $L_2$**: un modelo puede encabezar [RobustBench](https://robustbench.github.io/) y caer con 40 píxeles.

Lo que sí funciona contra $L_0$:

- **Filtrado de mediana / *feature squeezing*.** Una perturbación $L_0$ es, estadísticamente, ruido *sal y pimienta*: valores extremos aislados rodeados de vecinos coherentes. Un filtro de mediana los elimina casi por completo sin tocar los bordes reales. Es la defensa más barata que existe contra JSMA y familia, y opera **en preproceso**, sin reentrenar — lo que la hace aplicable a modelos ya desplegados. Su límite: es evadible con ataques adaptativos que optimicen *a través* del filtro, y degrada la precisión limpia en imágenes de textura fina.
- **Ablación aleatoria** (arriba) — la única línea con certificados frente a $L_0$.
- **Entrenamiento adversarial disperso.** [Sparse-PGD (arXiv:2405.05075)](https://arxiv.org/html/2405.05075v4) propone variantes de entrenamiento adversarial específicas de $L_0$ (`sAT`/`sTRADES`) generando ejemplos dispersos durante el entrenamiento. Es la respuesta directa al hueco, y sigue siendo minoritaria en producción.
- **Consistencia bajo transformación.** Comparar la predicción de la entrada original con la de su versión filtrada por mediana: en una entrada limpia coinciden; en una adversarial dispersa, cambian. Es detección barata, aunque también evadible de forma adaptativa.

## Qué señal deja un ataque disperso

Vale la pena separarlo de la detección genérica, porque el perfil es distinto:

- **La salida del modelo no avisa.** En [[08 - JSMA por pares, saliencia conjunta y poda|JSMA por pares]] la confianza en la clase objetivo se mantiene en ~0 durante el 70 % del ataque y se dispara al final. Monitorizar la confianza de salida detecta el ataque cuando ya ha terminado.
- **El patrón de consulta sí.** En caja negra el coste es alto —Sparse-RS necesita miles de consultas— y produce el mismo sondeo sistemático de variantes que delata la [[03 - GoodWords en caja negra con bandits|evasión de caja negra]] y el [[01 - Model reverse engineering y robo de modelos#Detección y mitigación|robo de modelos]].
- **La perturbación es visualmente evidente** si alguien la mira: puntos o trazos saturados. Un pipeline con revisión humana de muestras aleatorias detecta JSMA trivialmente; uno totalmente automático, no.

# El marco de decisión

<mark style="background: #8000E1A6;">Ninguna defensa es completa; se combinan según el modelo de amenaza y lo que se puede tocar.</mark>

| Situación | Defensa aplicable |
| - | - |
| Modelo en desarrollo, robustez crítica | Entrenamiento adversarial + evaluación con AutoAttack |
| Se necesita **garantía**, no solo resistencia | Robustez certificada (randomized smoothing) |
| Clasificador clásico vulnerable a GoodWords | Modelar contexto, reentrenar, pesado robusto |
| Modelo desplegado que no se puede reentrenar | Detección de patrón de consulta + rate limiting |
| Amenaza **dispersa** ($L_0$): malware, texto, parche físico | Filtrado de mediana en preproceso + ablación aleatoria si hace falta certificar; `sAT`/`sTRADES` si se entrena |

> [!warning]+ Lo que se reporta en un engagement
> El hallazgo no suele ser "el modelo es evadible" —casi todos lo son en algún grado—. El hallazgo es **cuánto cuesta evadirlo y si el defensor lo vería**: número de consultas para lograr X% de evasión, si hay monitorización del patrón de sondeo, si el modelo tiene entrenamiento adversarial, y **contra qué norma y con qué protocolo** se evaluó su robustez (si es que se evaluó). Un modelo sin ninguna defensa ni detección es un hallazgo mayor que la evasión en sí — y "robusto contra $L_\infty$" presentado como "robusto" a secas es un hallazgo por derecho propio.
