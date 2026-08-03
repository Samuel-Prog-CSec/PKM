---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Introduccion
  - Tipo/Introduccion
Descripción: "Los ataques de primer orden usan el gradiente del modelo respecto a la entrada para encontrar la perturbación mínima que cruza la frontera de decisión"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - Normas Lp y el presupuesto de perturbación]]"
Area: "[[Ataques de primer orden.base|Ataques de primer orden]]"
---
---

<mark style="background: #ADCCFFA6;">Un ataque de primer orden usa el gradiente del modelo respecto a la **entrada** para encontrar la perturbación mínima que cruza la frontera de decisión.</mark> Es la versión con optimización de la [[00 - Fundamentos de la evasión de modelos|evasión]]: donde [[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords]] acumulaba features a mano, aquí el gradiente dice **exactamente** en qué dirección mover cada píxel para maximizar el error, y basta un empujón imperceptible.

Esta carpeta es la continuación técnica de [[00 - Fundamentos de la evasión de modelos|Evasión de modelos]], aplicada a redes neuronales. Los fundamentos generales (frontera de decisión, transferibilidad, caja blanca/negra) están allí; aquí se profundiza en el mecanismo del gradiente y en los tres ataques canónicos: [[02 - FGSM, el ataque de un solo paso|FGSM]], [[03 - I-FGSM, PGD y el refinamiento iterativo|I-FGSM/PGD]] y [[04 - DeepFool y la perturbación mínima|DeepFool]].

# La grieta que exponen: precisión no es robustez

Un modelo puede clasificar el 98-99% de las imágenes de test correctamente y aun así fallar catastróficamente ante ejemplos adversariales. <mark style="background: #FFB86CA6;">Una imagen que un humano ve claramente como un "7" se modifica menos de un 1% y el modelo predice "2" con confianza.</mark>

Esa brecha entre precisión y robustez es el hallazgo de fondo: la precisión sobre datos limpios oculta una fragilidad estructural. En aplicaciones críticas de seguridad —reconocimiento facial, conducción autónoma, detección de fraude— esa sensibilidad es un problema de seguridad, no una curiosidad académica. Es `ML01: Input Manipulation Attack`, el riesgo número uno del `OWASP ML Top 10`.

# El giro conceptual: gradiente respecto a la entrada

La idea que lo hace posible es elegante. Una red neuronal aprende **siguiendo gradientes**: durante el entrenamiento, ajusta sus pesos para minimizar la pérdida. El gradiente responde a "¿cómo cambio los pesos para reducir el error?".

<mark style="background: #8000E1A6;">Un ataque de primer orden invierte la pregunta: congela los pesos y calcula el gradiente respecto a la **entrada** — "¿cómo cambio los píxeles para *aumentar* el error?".</mark>

| | Entrenamiento | Ataque de primer orden |
| - | - | - |
| Qué se optimiza | Los pesos $\theta$ | La entrada $x$ |
| Objetivo | **Minimizar** la pérdida | **Maximizar** la pérdida |
| Gradiente | $\nabla_\theta \mathcal{L}$ | $\nabla_x \mathcal{L}$ |
| Herramienta | Backpropagation a los pesos | Backpropagation a la entrada |

El gradiente $\nabla_x \mathcal{L}$ es un **mapa de sensibilidad**: para cada píxel, dice en qué dirección moverlo para que la pérdida crezca más rápido. El atacante lee ese mapa y hace cambios coordinados en todos los píxeles a la vez, empujando la entrada al otro lado de la frontera mientras mantiene la modificación total pequeña.

En la práctica, calcular $\nabla_x \mathcal{L}$ es trivial con cualquier framework: se marca la entrada como variable (`requires_grad=True`), se hace un `forward` para calcular la pérdida, `loss.backward()`, y se lee `x.grad`. Un solo `backward pass` con los pesos fijos.

# Dos filosofías de ataque

Los tres ataques de esta carpeta responden a dos preguntas distintas:

| Pregunta | Ataque | Filosofía |
| - | - | - |
| "Con un presupuesto $\epsilon$ fijo, ¿dónde golpeo?" | [[02 - FGSM, el ataque de un solo paso\|FGSM]], [[03 - I-FGSM, PGD y el refinamiento iterativo\|I-FGSM]] | Maximizar el daño dentro de un presupuesto |
| "¿Cuál es el golpe **más pequeño** que lo rompe?" | [[04 - DeepFool y la perturbación mínima\|DeepFool]] | Minimizar el presupuesto necesario |

<mark style="background: #FFB8EBA6;">La primera familia impone una restricción; la segunda la descubre.</mark> FGSM decide de antemano cuánto está dispuesto a cambiar y maximiza el error dentro de ese límite. DeepFool busca iterativamente la frontera más cercana y mide cuánto hace falta para llegar — convirtiendo el ataque en un **instrumento de medida** de la robustez de cada entrada.

# Por qué funcionan: linealidad local y alta dimensionalidad

Dos propiedades explican que un empujón diminuto baste:

1. **Linealidad local.** Cerca de una entrada limpia, las redes profundas se comportan **casi linealmente**: un cambio pequeño en la entrada produce un cambio proporcional en el score. Un solo paso basado en el gradiente ya empuja la pérdida en la dirección de máxima pendiente.
2. **Alta dimensionalidad.** Una imagen tiene miles o millones de píxeles. Cambios diminutos y bien alineados en cada uno **se acumulan** en un cambio grande del score. Muchos empujones minúsculos, todos en la dirección correcta, suman.

Esta combinación —cada píxel cambia poco, pero hay muchos y todos alineados— es la que se formaliza en [[02 - FGSM, el ataque de un solo paso|FGSM]] con la desigualdad de Hölder. Y es también lo que hace a estos ataques **transferibles**: un ejemplo adversarial creado contra un modelo suele engañar a otros de arquitectura distinta, porque la fragilidad viene de la geometría de alta dimensión, compartida entre modelos.

# El papel de la medida: las normas

Toda la familia se apoya en una pregunta previa: **"¿cuánto cambié la entrada?"**. La respuesta depende de con qué "regla" se mida —contar píxeles cambiados, sumar los cambios, medir el mayor—, y cada regla define un tipo de ataque distinto. Esa es la razón de que la siguiente nota, [[01 - Normas Lp y el presupuesto de perturbación|las normas $L_p$]], venga antes que los ataques: sin fijar la métrica, "perturbación mínima" no significa nada.

# Encaje con los marcos

Tanto `OWASP` como el `Google SAIF` reconocen la evasión como amenaza mayor. `SAIF` la aborda con defensa en profundidad —entrenamiento adversarial en desarrollo, evaluación de robustez antes del despliegue, filtrado de entrada en operación— y **recomienda explícitamente equipos de red team que prueben modelos en producción con ejemplos adversariales**, midiendo cuánta perturbación hace falta para alcanzar una tasa de éxito objetivo. Estos ataques son la herramienta para ejecutar ese protocolo; su [[04 - Detección y defensa contra la evasión|defensa]] y su [[05 - Arsenal para la evasión de modelos|arsenal]] están en la carpeta de fundamentos, porque son comunes con [[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords]].
