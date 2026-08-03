---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/LLM
  - Tipo/Defensa
Descripción: "Aplicar el principio del entrenamiento adversarial al texto: SFT con LoRA sobre jailbreaks y ataques de priming para que el modelo aprenda a rechazar, sin perder utilidad"
Fecha de actualización: 2026-07-29
Nota previa: "[[07 - Epsilon spread y evaluación de robustez]]"
Nota siguiente: "[[09 - Evaluar el safety tuning y el over-refusal]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Los modelos comerciales llegan con alineamiento de seguridad —`SFT` sobre datasets curados, `RLHF`, IA constitucional— y rechazan peticiones dañinas en circunstancias normales. Aun así, los atacantes encuentran la vuelta constantemente. <mark style="background: #ADCCFFA6;">El hueco está entre la seguridad de tiempo de entrenamiento y la presión adversarial de tiempo de inferencia:</mark> el alineamiento cubre lo que un diseñador razonable anticipó, y el atacante opera fuera de esa distribución, probando casos límite, combinando técnicas e iterando sobre las respuestas.

El *adversarial tuning* ataca ese hueco directamente: en vez de confiar en que la seguridad general transfiera a contextos adversariales, se **entrena al modelo sobre los ataques** y se le enseña el rechazo correcto. Es el mismo principio del [[06 - Entrenamiento adversarial y el problema min-max|entrenamiento adversarial]] aplicado al texto.

# Los dos vectores del modelo de amenaza

**Jailbreak prompts.** Entradas diseñadas para que el modelo ignore su entrenamiento de seguridad: roleplay, apelación a autoridad, encuadre hipotético, codificación. El catálogo completo está en Red Team ([[09 - Jailbreaks clásicos (DAN, roleplay y ficción)|clásicos]], [[10 - Jailbreaks por obfuscación|obfuscación]], [[11 - Jailbreaks multi-turno y de contexto|multi-turno]]).

**Ataques de *priming*.** Más sofisticados y menos conocidos. En vez de convencer al modelo de generar contenido dañino desde cero, se **inyecta el principio de la respuesta dañina en el turno del asistente** como si el modelo ya hubiera empezado a generarla, y se le pide continuar.

> [!important]+ El *priming* es el ataque de *prefill*, y funciona por una razón concreta
> Muchas APIs permiten **prellenar el turno del asistente** (`prefill`), y los formatos de chat locales lo permiten trivialmente editando la plantilla. <mark style="background: #FFB86CA6;">Funciona porque el alineamiento de seguridad es **superficial**: se concentra en los primeros tokens de la respuesta.</mark> Si el modelo "ya ha dicho" *"Claro, aquí tienes los pasos: 1."*, el rechazo —que vive en la distribución de los primeros tokens— ya no puede activarse, y la continuación más probable es seguir la lista.
>
> Es la tesis de [*Safety Alignment Should Be Made More Than Just a Few Tokens Deep*, arXiv:2406.05946](https://arxiv.org/abs/2406.05946) (Qi et al.), que además explica por qué estos ataques son tan universales entre modelos y por qué el alineamiento estándar apenas los cubre. Los datos del laboratorio lo confirman: el modelo base rechaza el **83,3 %** de los jailbreaks pero solo defiende el **7,1 %** de los ataques de *priming*.

# La mecánica: SFT

Un modelo de lenguaje genera texto prediciendo el siguiente token. El entrenamiento minimiza la log-verosimilitud negativa de la secuencia correcta:

$$\mathcal{L} = -\sum_{i=1}^{n} \log P(x_i \mid x_1, \ldots, x_{i-1};\, \theta)$$

Para *safety tuning*, los ejemplos son **prompt de ataque → respuesta de rechazo**. El modelo aprende a asignar alta probabilidad a los tokens de rechazo cuando el contexto se parece a un jailbreak. Tras suficiente entrenamiento, esa distribución generaliza más allá de los ejemplos vistos.

# LoRA: hacerlo con 8 millones de parámetros

El *fine-tuning* completo exige actualizar miles de millones de parámetros. `LoRA` (*Low-Rank Adaptation*) parte de la observación de que las actualizaciones de peso durante el *fine-tuning* viven en un subespacio de baja dimensión. En lugar de actualizar $W \in \mathbb{R}^{d\times k}$, se añade una descomposición de rango bajo:

$$W' = W + BA, \qquad B \in \mathbb{R}^{d\times r},\; A \in \mathbb{R}^{r\times k},\; r \ll \min(d,k)$$

$W$ queda **congelada**; solo $A$ y $B$ reciben gradientes. Con rango $r = 16$ sobre las capas de atención, los parámetros entrenables bajan de ~1200 millones a ~8 millones: <mark style="background: #8000E1A6;">una reducción del 99,3 %, y memoria proporcional — entrenable en una GPU de consumo con 16 GB o menos.</mark>

## Los dos recuentos del módulo, reconciliados

> [!important]+ 8 M frente a 11 M: no es contradicción, es qué capas se adaptan
> HTB cita **8 M** de parámetros entrenables en esta sección y **11 M** en la de evaluación, sin explicar la diferencia. No es una contradicción: los 8 M corresponden a adaptar **solo la atención** (`q_proj`, `k_proj`, `v_proj`, `o_proj`), que es lo que dice literalmente el texto; la configuración real añade además las capas *feed-forward* (`gate_proj`, `up_proj`, `down_proj`), y esas suman los ~3 M restantes. Tenerlo claro importa porque **es la palanca de ajuste**: si hay que recortar memoria o tiempo, lo primero que se quita del `target_modules` son las FFN, no el rango.
>
> Lo que sí es un error del módulo es el porcentaje: presenta los 11 M como "≈1,4 % del modelo", cuando sobre un Llama-3.2-1B (~1,24 B de parámetros) son <mark style="background: #FF5582A6;">**≈0,9 %**</mark>.

¿Por qué no destroza la calidad? Porque no se está enseñando una capacidad nueva, sino **ajustando la frontera de decisión de una capacidad que ya existe** (el rechazo de seguridad). Ese tipo de ajuste sí ocupa un subespacio de rango bajo.

## Dónde se enganchan los adaptadores

Los módulos objetivo son las proyecciones de atención (`q_proj`, `k_proj`, `v_proj`, `o_proj`) más las capas *feed-forward* (`gate_proj`, `up_proj`, `down_proj`).

La atención es la elección natural porque controla **cómo el modelo pondera las distintas partes del contexto** al generar. Un prompt de jailbreak contiene a la vez el encuadre de manipulación y la petición dañina; hace falta que el modelo trate los patrones de manipulación (roleplay, apelación a autoridad) como **señal de rechazo** en lugar de como instrucciones a seguir. Adaptar las proyecciones de atención influye directamente en cómo se procesa ese contexto adversarial; las *feed-forward* aprenden luego a producir representaciones acordes con el rechazo.

# La composición de los datos

Tres categorías, y el equilibrio entre ellas es lo que decide si el resultado sirve:

| Categoría | Contenido | Cantidad (lab) |
| - | - | - |
| Rechazos de jailbreak | Prompts de ataque (roleplay, autoridad, hipotético, codificación) con su rechazo | \~ |
| Defensa de *priming* | Contenido dañino ya inyectado en el prefijo del asistente, con lenguaje de parada | \~ |
| Conversaciones benignas | Consultas legítimas con respuestas útiles, temas diversos | **86** |
| | **Total seguridad** | **138** |

<mark style="background: #FFB8EBA6;">La proporción importa tanto como el contenido:</mark> los ejemplos de seguridad deben superar ligeramente a los benignos, pero no por mucho. Pocos ejemplos de seguridad y el modelo sigue siendo vulnerable; demasiados y se vuelve excesivamente cauto. En el laboratorio: 138 de seguridad frente a 86 benignos, ~62/38.

Los ejemplos de defensa de *priming* tienen un formato específico: el prefijo dañino aparece **dentro** de la sección del asistente, seguido de lenguaje de parada (`I must stop`, `I need to stop`, `I was about to`). Se le está enseñando al modelo a interrumpirse a sí mismo a mitad de respuesta — una capacidad que el alineamiento estándar no tiene.

# Por qué generaliza a ataques nuevos

La pregunta obvia: el dataset contiene jailbreaks concretos, pero el atacante puede construir variaciones que nadie anticipó.

La respuesta es **aprendizaje de features**. Las redes no memorizan ejemplos como ítems discretos, sino que aprenden representaciones distribuidas que capturan patrones. Entrenando sobre jailbreaks de roleplay, el modelo no memoriza el texto exacto: aprende las features asociadas al **patrón de manipulación** — construcciones como `you are now`, `pretend to be`, `in this game`, `without restrictions`.

Esas features se activan ante jailbreaks nuevos que compartan la estructura funcional aunque la redacción difiera. Los estudios empíricos lo confirman: modelos entrenados sobre un subconjunto de categorías rechazan jailbreaks de categorías retenidas. <mark style="background: #FF5582A6;">La generalización no es perfecta —un patrón suficientemente novedoso escapa—, pero sube el listón: el atacante ya no necesita cualquier jailbreak, sino uno que evada la detección aprendida en varias dimensiones de feature a la vez.</mark>

# El fallo opuesto: over-refusal

Un modelo que rechaza demasiado también está roto. Rechazar toda la química porque algunas preguntas de química son peligrosas, o toda la seguridad porque algunas preguntas son reconocimiento, hace el producto inservible.

Tres causas y sus correcciones:

| Causa | Corrección |
| - | - |
| Desequilibrio de datos (seguridad ≫ benignos) | Mantener los benignos en al menos el 30 % del total |
| Rechazos demasiado amplios (rechazar áreas temáticas enteras) | Redactar rechazos que apunten a la **petición dañina concreta**, no al tema |
| Poca diversidad benigna en temas adyacentes a los dañinos | Incluir ejemplos benignos **de seguridad, química y temas sensibles**, para demostrar que tienen usos legítimos |

La tercera es la más importante y la que más se olvida: si los ejemplos benignos son todos de cocina y viajes, el modelo no tiene forma de aprender que "explícame cómo funciona un desbordamiento de búfer" es legítimo.

> [!warning]+ Dos límites de LoRA que HTB no menciona
> **El adaptador se puede quitar.** Si se distribuyen los pesos del modelo con el adaptador de seguridad por separado, cualquiera puede simplemente **no cargarlo** y recuperar el modelo sin *safety tuning*. La defensa solo vale si el adaptador está fusionado en los pesos distribuidos o si el modelo se sirve por API bajo control propio.
> **El fine-tuning posterior lo deshace.** Afinar un modelo alineado **degrada su alineamiento incluso con datos completamente benignos** ([arXiv:2310.03693](https://arxiv.org/abs/2310.03693), Qi et al., ICLR 2024) — el detalle está en [[13 - Defensas modernas contra prompt injection|defensas modernas contra prompt injection]]. Consecuencia operativa: <mark style="background: #FFB86CA6;">el *safety tuning* debe ser el **último** paso de entrenamiento, y hay que **revalidarlo después de cualquier ajuste posterior**.</mark>

Cómo se mide si el ajuste funcionó, y con qué métricas, es [[09 - Evaluar el safety tuning y el over-refusal|la nota siguiente]].
