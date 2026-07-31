---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Introduccion
  - Tipo/Introduccion
Descripción: "La evasión manipula la entrada en tiempo de inferencia para que un modelo ya entrenado dé una salida incorrecta, sin tocar sus parámetros ni su entrenamiento"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - El ataque GoodWords y los clasificadores Naive Bayes]]"
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

<mark style="background: #ADCCFFA6;">Un ataque de evasión manipula la entrada en tiempo de inferencia para que un modelo ya entrenado produzca una salida incorrecta.</mark> No cambia lo que el modelo aprendió; explota lo que aprendió mal. Es la familia de ataques adversariales más directa de ejecutar contra un sistema desplegado, porque usa la interfaz normal —una API, un formulario, un fichero— sin necesitar acceso a los pesos ni al pipeline de entrenamiento.

Esta carpeta es la puerta de entrada a todo el tema de evasión. Aquí van los fundamentos y el ataque clásico sobre clasificadores (`GoodWords` sobre Naive Bayes); los [[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]] sobre redes neuronales (FGSM, DeepFool) están en la carpeta hermana.

# El ciclo de vida adversarial: dónde ataca la evasión

Un sistema de ML se puede atacar en dos momentos, y la distinción **manda sobre la defensa**:

| Momento | Ataque | Qué cambia | Acceso que exige |
| - | - | - | - |
| **Entrenamiento** | [[00 - El pipeline de datos y su superficie de ataque\|Envenenamiento]], [[02 - Label flipping\|label flipping]], [[08 - Backdoors y trojans en modelos\|trojans]] | Lo que el modelo **aprende** | Dataset o pipeline |
| **Inferencia** | **Evasión** | Solo lo que el modelo **ve** al predecir | La interfaz normal |

<mark style="background: #8000E1A6;">La evasión deja intactos el entrenamiento y los parámetros; gana enviando una entrada diseñada para cruzar la frontera de decisión.</mark> Un envenenamiento requiere acceso al dataset y desplaza el comportamiento globalmente; una evasión requiere solo poder consultar el modelo y afecta a una predicción concreta. Por eso es el ataque de inferencia por excelencia y el más realista contra un servicio en producción.

En `MITRE ATLAS` la evasión es `AML.T0015` (*Evade ML Model*), y su variante contra el modelo objetivo directo, `AML.T0043` (*Craft Adversarial Data*).

# La frontera de decisión y la perturbación mínima

Todo clasificador aprende una **frontera de decisión**: una superficie en el espacio de entrada que separa las clases. La evasión consiste en mover un ejemplo al otro lado de esa frontera con la **mínima** modificación posible, de modo que un humano no note el cambio pero el modelo cambie de opinión.

Qué significa "mínima" depende del dominio:

- En un **filtro de spam** con [[01 - El ataque GoodWords y los clasificadores Naive Bayes|bag-of-words]], añadir palabras benignas cambia las frecuencias de término y por tanto la probabilidad a posteriori, mientras el mensaje sigue leyéndose igual para una persona.
- En un **detector de malware** estático, reordenar secciones o perturbar imports altera los patrones de bytes sin cambiar la intención del programa.
- En un **clasificador de imágenes**, un ruido imperceptible píxel a píxel basta para cambiar la etiqueta — el caso canónico de los [[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]].

El hilo común: <mark style="background: #FFB86CA6;">manipular directamente las características que el modelo consume, para empujar una sola predicción al otro lado del umbral.</mark>

# Caja blanca vs. caja negra

El acceso del atacante define la técnica:

| Conocimiento | Qué tiene el atacante | Técnica típica |
| - | - | - |
| **Caja blanca** | Arquitectura, parámetros, gradientes | Optimización directa: [[02 - FGSM, el ataque de un solo paso\|FGSM]], DeepFool, PGD |
| **Caja negra** | Solo consultas y sus salidas | Exploración: bandits, sustitutos, transferencia |

La caja blanca es poco realista contra un objetivo comercial, pero **no es inútil**: el atacante entrena un modelo propio de arquitectura parecida, genera el ejemplo adversarial ahí con acceso total, y lo transfiere. Ese puente lo hace posible una propiedad central.

## Transferibilidad: el puente que hace práctica la teoría

<mark style="background: #FF5582A6;">Un ejemplo adversarial creado contra un modelo sustituto suele engañar también a modelos de producción distintos, sobre todo si comparten arquitectura o datos.</mark> Esto es lo que convierte los ataques de caja blanca en armas de caja negra: se prepara el ataque *offline* contra un sustituto y se dispara contra el objetivo real que solo expone una API.

La transferibilidad conecta esta carpeta con [[01 - Model reverse engineering y robo de modelos]]: el primer paso de un ataque de evasión serio contra un objetivo de caja negra es a menudo **robarlo** para convertirlo en caja blanca, y luego atacar el sustituto. Es la misma lógica encadenada.

# Evasión en ML clásico vs. en LLMs

La evasión existe en los dos mundos, con la misma idea y distinta palanca:

- En **ML clásico**, el modelo expone características estructuradas y un umbral de etiqueta. La evasión edita las estadísticas que alimentan al clasificador — es lo mecánicamente observable y medible, y por eso este tema empieza aquí, con `GoodWords`.
- En **LLMs**, el modelo expone estado conversacional y seguimiento de instrucciones. La evasión edita el proceso de decisión con texto y contexto: es la [[01 - Prompt injection y por qué no tiene parche|prompt injection]], que ya vive en su propio sub-tema.

<mark style="background: #FFB8EBA6;">Ambos comparten el núcleo —modificar solo la entrada vista en predicción para dirigir el comportamiento—; cambian la superficie y el punto de apalancamiento.</mark> La intuición que se construye atacando un clasificador de spam se traslada directamente a por qué un LLM obedece un `payload`: en los dos casos, el modelo no distingue la señal legítima de la manipulada porque procesa ambas por el mismo canal.

# El mapa de esta carpeta y las hermanas

| Carpeta | Objetivo | Técnicas |
| - | - | - |
| **Evasión de modelos** (esta) | Clasificadores clásicos | [[01 - El ataque GoodWords y los clasificadores Naive Bayes\|GoodWords]] · [[02 - GoodWords en caja blanca\|caja blanca]] · [[03 - GoodWords en caja negra con bandits\|caja negra]] |
| [[00 - Ataques de primer orden y el papel del gradiente\|Ataques de primer orden]] | Redes neuronales, presupuesto en **magnitud** | Normas $L_p$ · FGSM · I-FGSM/PGD · DeepFool |
| [[00 - Fundamentos de los ataques dispersos y la norma L0\|Ataques dispersos]] | Redes neuronales, presupuesto en **número de features** | $L_0$ · [[01 - ElasticNet (EAD) y la mezcla L1 + L2\|EAD]] · [[06 - JSMA, el Jacobiano y los mapas de saliencia\|JSMA]] · Sparse-RS · σ-zero |

La [[04 - Detección y defensa contra la evasión|detección y defensa]] y el [[05 - Arsenal para la evasión de modelos|arsenal]] cierran esta carpeta y aplican a las tres: las defensas contra evasión (entrenamiento adversarial, robustez certificada, ablación aleatoria) y el conjunto de herramientas (ART, TorchAttacks, AutoAttack) son comunes a clasificadores y a redes neuronales.

# Encaje con los marcos

En el `OWASP Machine Learning Security Top 10` la evasión es `ML01: Input Manipulation Attack`, el riesgo número uno. En el `NIST AI 100-2e2025` es la categoría *Evasion* de la taxonomía de ataques a sistemas predictivos. Para la robustez, la referencia de evaluación es **RobustBench**, el `leaderboard` estándar de robustez adversarial — se trata en [[04 - Detección y defensa contra la evasión]].
