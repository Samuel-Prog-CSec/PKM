---
tags:
  - IA/Red-Team
  - IA/LLM
  - IA/Adversarial
Descripción: "La razón principal para usar PyRIT en lugar de un escáner"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Targets, converters y scorers de PyRIT]]"
Nota siguiente: "[[03 - PyRIT en un engagement]]"
Area: "[[PyRIT.base|PyRIT]]"
---
---

La razón principal para usar PyRIT en lugar de un escáner. <mark style="background: #ADCCFFA6;">Los ataques multi-turno son los que mejor funcionan contra modelos frontera en 2026 y los que peor detectan los guardrails</mark> ([[11 - Jailbreaks multi-turno y de contexto|por qué]]), y ejecutarlos a mano no escala: cada uno son entre cuatro y quince mensajes que hay que adaptar según lo que responda el modelo.

# Las estrategias implementadas

En `pyrit/executor/attack/multi_turn/`:

| Estrategia | Qué hace | Referencia |
| - | - | - |
| **`crescendo`** | Escalada gradual referenciando las propias respuestas del modelo | [[11 - Jailbreaks multi-turno y de contexto#Crescendo]] |
| **`pair`** | *Prompt Automatic Iterative Refinement*: un LLM atacante refina el prompt según la respuesta del objetivo | [arXiv:2310.08419](https://arxiv.org/abs/2310.08419) |
| **`tree_of_attacks`** | *TAP*: árbol de ramas de ataque con poda de las poco prometedoras | [arXiv:2312.02119](https://arxiv.org/abs/2312.02119) |
| `red_teaming` | Estrategia genérica: un LLM atacante persigue un objetivo declarado en lenguaje natural | — |
| `simulated_conversation` | Fabrica el historial de conversación | [[11 - Jailbreaks multi-turno y de contexto#Context Compliance Attack — el que no es un jailbreak\|CCA]] |
| `multi_prompt_sending`, `chunked_request` | Reparto del payload entre mensajes o trozos | Fragmentación |

Tres de ellas conviene distinguirlas bien porque se eligen por criterios distintos:

- **Crescendo** es **guionizada**: la escalada sigue un patrón fijo. Barata, predecible, buena tasa de éxito, pocos turnos.
- **PAIR** es **adaptativa**: un LLM atacante lee la respuesta del objetivo y reescribe el prompt. Más cara (cada iteración son dos llamadas a modelo), más efectiva contra objetivos que resisten a Crescendo.
- **TAP** es **PAIR con búsqueda en árbol**: explora varias ramas en paralelo y poda las que no avanzan. La más cara y la de mayor tasa de éxito. <mark style="background: #FFB86CA6;">También la más ruidosa con diferencia</mark> — decenas de conversaciones simultáneas contra el objetivo.

# El patrón de uso

Las cuatro piezas de [[01 - Targets, converters y scorers de PyRIT|la nota anterior]] se ensamblan así:

```python
from pyrit.common import initialize_pyrit, IN_MEMORY
from pyrit.prompt_target import OpenAIChatTarget

initialize_pyrit(memory_db_type=IN_MEMORY)

objective_target = OpenAIChatTarget()          # el sistema que se ataca
adversarial_chat = OpenAIChatTarget()          # el LLM que genera los ataques
# + un scorer que decide si se alcanzó el objetivo
# + la estrategia (Crescendo, PAIR, TAP...) con un objective en lenguaje natural
```

Dos observaciones sobre esa estructura:

- **Hacen falta dos modelos**: el objetivo y el adversario. El adversario tiene que estar **sin alineamiento fuerte**, o se negará a generar los ataques. En la práctica se usa un modelo open-weights local, lo que además tiene sentido de [[14 - Detección y evasión en prompt injection|OPSEC]] y de coste.
- **El objetivo se declara en lenguaje natural** ("conseguir que el asistente revele el system prompt", "conseguir que apruebe un reembolso no elegible"). La estrategia y el scorer se encargan del resto. Es lo que hace la herramienta usable sin reescribir código por cada prueba.

> [!warning]+ El coste se dispara rápido
> Un ataque TAP con ramificación 4 y profundidad 5 puede ser **cientos de llamadas al modelo objetivo** y otras tantas al adversario y al scorer. Contra una API de pago del cliente, eso es dinero suyo; contra producción, es un pico de tráfico difícil de justificar. <mark style="background: #FF5582A6;">Hay que pactar el volumen por escrito y empezar por Crescendo</mark>, que consigue mucho con pocos turnos.

# Correspondencia con el vault

Todo lo de esta nota es la automatización de técnicas ya documentadas. La tabla sirve para decidir qué ejecutar según lo que diga el reconocimiento:

| Si el reconocimiento dice… | Estrategia |
| - | - |
| Hay **input guard por mensaje** | Crescendo o Echo Chamber — ningún mensaje individual es clasificable |
| El **historial es manipulable** por el cliente | `simulated_conversation` → [[11 - Jailbreaks multi-turno y de contexto#Context Compliance Attack — el que no es un jailbreak\|CCA]], una sola petición y determinista |
| El objetivo **resiste** a Crescendo | PAIR, y si tampoco, TAP |
| Hay **filtro léxico** en la entrada | Encadenar conversores de ofuscación antes de la estrategia |
| Hay que **medir el ASR** de una técnica propia | `red_teaming` con objetivo fijo + `batch_scorer` sobre N repeticiones |

<mark style="background: #8000E1A6;">El orden por coste creciente es: CCA → Crescendo → PAIR → TAP.</mark> Empezar por el final es tirar presupuesto y hacer ruido innecesario.

# Lo que no automatiza

Conviene tenerlo claro para no esperar de más:

- **La [[04 - Inyección directa contra la lógica de negocio|manipulación de lógica de negocio]]** — ningún objetivo genérico sabe que el objetivo calcula precios. Se declara a mano y el scorer hay que escribirlo.
- **La [[05 - Inyección indirecta en RAG, email y web|inyección indirecta]]** — PyRIT habla con el objetivo; colocar el payload en un documento que el objetivo leerá es trabajo previo, fuera de la herramienta.
- **La explotación de la [[00 - Tratamiento inseguro de la salida del LLM|salida]]** — PyRIT consigue que el modelo emita el payload; que ese payload produzca XSS o SQLi se verifica aparte.
