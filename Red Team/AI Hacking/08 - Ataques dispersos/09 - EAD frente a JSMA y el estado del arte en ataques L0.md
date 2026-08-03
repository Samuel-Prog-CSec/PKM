---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Cuándo usar cada uno de los dos ataques clásicos y qué se usa realmente hoy: Sparse-RS, σ-zero, SparseFool y la evidencia de que la robustez L∞ no cubre L1 ni L0"
Fecha de actualización: 2026-07-29
Nota previa: "[[08 - JSMA por pares, saliencia conjunta y poda]]"
Nota siguiente: 
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

Los dos ataques del tema atacan el mismo problema por flancos opuestos. Puestos uno al lado del otro con los números del módulo:

| | [[01 - ElasticNet (EAD) y la mezcla L1 + L2\|EAD]] | [[08 - JSMA por pares, saliencia conjunta y poda\|JSMA por pares]] |
| - | - | - |
| Control de $L_0$ | Indirecto, vía penalización $\beta$ | **Explícito**, contador duro con presupuesto $\gamma$ |
| Optimización | Continua (gradiente proximal + momento) | Combinatoria voraz |
| Éxito (MNIST) | 100 % | 90 % |
| Features tocadas | ~371 (52,6 % dispersión) | **42,8 de media**, mínimo 12 |
| Magnitud por feature | Pequeña y controlada | Saturación completa (0 → 1) |
| Aspecto | Perturbación tenue en bordes | Puntos y trazos visibles |
| Coste | 100-1000 iteraciones × 5 pasos de búsqueda binaria | 22 iteraciones × 10 pasadas atrás |
| Escala con nº de clases | Independiente | **Lineal** — mata la viabilidad en ImageNet |
| Fuerte en | Transferibilidad, baja distorsión perceptual | Dispersión real, interpretabilidad |

<mark style="background: #ADCCFFA6;">La regla de decisión es el modelo de amenaza, no la elegancia del algoritmo:</mark> si la restricción dura es **cuántas** features se pueden tocar (bits, tokens, campos de un log), JSMA y sus sucesores; si la restricción es **cuánto se puede notar** o hace falta que el ejemplo transfiera a otro modelo, EAD.

# Lo que HTB no cuenta: el estado del arte

El módulo enseña dos ataques de 2016 y 2018. Siguen siendo la base conceptual —y aparecen en toda la literatura de robustez como línea base— pero <mark style="background: #FF5582A6;">ninguno de los dos es lo que se lanzaría hoy contra un modelo de producción.</mark>

## SparseFool (2019)

[Modas, Moosavi-Dezfooli y Frossard, CVPR 2019](https://arxiv.org/abs/1811.02248) llevan la idea geométrica de [[04 - DeepFool y la perturbación mínima|DeepFool]] al terreno $L_0$: aproximan localmente la frontera de decisión por un hiperplano y resuelven el problema disperso por proyección lineal, en vez de puntuar features una a una. El resultado es **órdenes de magnitud más rápido que JSMA y escalable a ImageNet**, precisamente donde el coste lineal en número de clases hace inviable el Jacobiano completo.

## One-pixel attack (2019)

[Su, Vargas y Sakurai, *IEEE Transactions on Evolutionary Computation*](https://arxiv.org/abs/1710.08864) demostraron el caso extremo: **caja negra, sin gradientes, evolución diferencial**, modificando entre 1 y 5 píxeles. La tasa de éxito sobre CIFAR-10 es modesta comparada con los ataques de caja blanca, pero el resultado importa por lo que implica: el presupuesto $L_0$ útil puede bajar a la unidad, y no hace falta acceso al modelo.

## Sparse-RS (2022) — la referencia en caja negra

[Croce, Andriushchenko, Singh, Flammarion y Hein, AAAI 2022](https://ojs.aaai.org/index.php/AAAI/article/view/20595) ([código](https://github.com/fra31/sparse-rs)) es un marco de **búsqueda aleatoria** basado en puntuación (solo necesita la salida del modelo) que cubre tres modelos de amenaza dispersos con el mismo algoritmo: perturbaciones acotadas en $L_0$, **parches adversariales** y **marcos adversariales**.

<mark style="background: #FFB86CA6;">El dato que hay que retener: la versión $L_0$ no dirigida alcanza casi el 100 % de éxito sobre ImageNet perturbando el 0,1 % de los píxeles, superando a los ataques de **caja blanca** existentes, incluido $L_0$-PGD.</mark> Un ataque de caja negra batiendo a los de caja blanca es una anomalía que dice mucho de lo mal condicionada que está la optimización $L_0$ por gradiente — y, en un engagement, elimina el argumento "no tienen acceso a nuestros pesos" como mitigación.

## σ-zero (ICLR 2025) — la referencia en caja blanca

[Cinà, Villani, Pintor, Schönherr, Biggio y Pelillo, arXiv:2402.01879](https://arxiv.org/abs/2402.01879) resuelven el problema de raíz: una **aproximación diferenciable de la norma $L_0$** más un operador de proyección adaptativo que equilibra reducción de pérdida y dispersión. Es lo que EAD intentaba con la relajación $L_1$, pero atacando $L_0$ directamente en vez de por sustituto convexo.

Reportan superar a todos los ataques dispersos competidores en tasa de éxito, tamaño de perturbación y eficiencia sobre MNIST, CIFAR-10 e ImageNet, tanto en modelos estándar como robustos, y **sin ajuste de hiperparámetros** — lo que resuelve de paso el mayor dolor operativo de EAD (calibrar $\beta$, $c$, $\eta$ y el número de pasos). Para medir la robustez $L_0$ de un modelo hoy, es el punto de partida.

## Sparse-PGD y la dispersión estructurada (2024)

[Sparse-PGD, arXiv:2405.05075](https://arxiv.org/html/2405.05075v4) unifica perturbaciones dispersas **no estructuradas** (píxeles sueltos) y **estructuradas** (regiones contiguas), y —lo relevante para el lado defensivo— propone variantes de entrenamiento adversarial específicas de $L_0$. Es la respuesta directa al hueco que estos ataques dejan al descubierto.

> [!important]+ La dispersión estructurada es el caso físico
> Un **parche adversarial** ([Brown et al., 2017](https://arxiv.org/abs/1712.09665)) es un ataque $L_0$ con una restricción extra: los píxeles tocados deben ser **contiguos** y la magnitud es libre. Es exactamente lo que se puede imprimir y pegar sobre una señal de tráfico o un objeto. Cuando un cliente pregunta por ataques "en el mundo real" a su sistema de visión, el modelo de amenaza que hay que evaluar es este, no $L_\infty$ — y Sparse-RS lo cubre con el mismo marco.

# La evidencia que rompe el argumento "nuestro modelo es robusto"

El punto más citable de todo el tema para un informe:

> [!info]+ Fuente
> [*Attacking the Madry Defense Model with $L_1$-based Adversarial Examples*, arXiv:1710.10733](https://arxiv.org/abs/1710.10733) — Sharma y Chen, **ICLR 2018 Workshops**. Demuestran que EAD genera ejemplos adversariales **transferibles que derrotan al modelo de defensa de Madry**, el estándar de entrenamiento adversarial $L_\infty$, y concluyen que <mark style="background: #8000E1A6;">la norma $L_\infty$ es una medida insuficiente de la distorsión perceptual</mark>: sus ejemplos tienen $L_\infty$ media alta y aun así distorsión visual mínima.

Traducido a lenguaje de engagement: **la robustez certificada o empírica frente a $L_\infty$ no se hereda hacia $L_1$ ni hacia $L_0$**. Un cliente cuyo modelo aparece bien posicionado en [RobustBench](https://robustbench.github.io/) está diciendo, en realidad, que resiste $L_\infty$ con un $\epsilon$ concreto. Comprobarlo es una pregunta directa: *¿contra qué norma, con qué presupuesto y con qué protocolo se evaluó?*

Para defender frente a $L_0$ hacen falta mecanismos distintos —ablación aleatoria para certificar, entrenamiento adversarial disperso para robustez empírica—, cubiertos en [[04 - Detección y defensa contra la evasión|detección y defensa contra la evasión]].

# Fuera de las imágenes

Todo el módulo trabaja sobre MNIST, pero <mark style="background: #FFB8EBA6;">el modelo de amenaza $L_0$ es más natural fuera de la visión que dentro:</mark>

- **Malware.** El vector de features admite añadir imports, secciones o cadenas. La restricción no es "cambia poco" sino "cambia pocas cosas, y que el binario siga ejecutando". Es el problema *feature-space vs problem-space* de [[08 - Límites y evasión de los detectores ML|los límites de los detectores ML]].
- **Texto.** Sustituir $k$ tokens es literalmente $L_0 = k$. La familia de ataques de sustitución de palabras (TextAttack y compañía) es JSMA con otro nombre: puntuar tokens por importancia, sustituir los mejores, repetir.
- **Tabular / logs / tráfico.** El atacante controla campos concretos; el resto viene del entorno. Un ataque que perturbe las 40 features de un vector NetFlow no es realizable, uno que toque 3 sí.

En estos dominios la traducción no es directa: hay que redefinir el operador de perturbación (no hay `clamp` a `[0,1]`), la métrica de distancia y —lo más importante— las **restricciones de validez** del dominio. Es el motivo real por el que sigue teniendo sentido entender estos ataques a bajo nivel en vez de tirar de biblioteca: la biblioteca asume imágenes.

# Qué usar hoy

| Situación | Herramienta |
| - | - |
| Medir robustez $L_0$ mínima de un modelo (caja blanca) | **σ-zero** |
| Sin acceso al modelo, solo salidas | **Sparse-RS** (también parches y marcos) |
| Escalar a ImageNet con gradientes | **SparseFool** |
| Necesito transferibilidad entre modelos | **EAD** ($L_1$) |
| Línea base reproducible / didáctica | JSMA, EAD (disponibles en ART y Foolbox) |
| Dominio no visual (malware, texto, tabular) | Reimplementar la lógica con el operador de perturbación del dominio |

Las implementaciones concretas y sus comandos están en [[05 - Arsenal para la evasión de modelos|el arsenal de evasión]], compartido por las tres carpetas del tema.
