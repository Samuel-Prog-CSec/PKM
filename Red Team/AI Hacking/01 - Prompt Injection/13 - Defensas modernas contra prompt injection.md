---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Reporting
  - Tipo/Defensa
Descripción: "Las mitigaciones tradicionales operan sobre el texto"
Fecha de actualización: 2026-07-28
Nota previa: "[[12 - Mitigaciones tradicionales y sus límites]]"
Nota siguiente: "[[14 - Detección y evasión en prompt injection]]"
Area: "[[Prompt Injection.base|Prompt Injection]]"
---
---

Las [[12 - Mitigaciones tradicionales y sus límites|mitigaciones tradicionales]] operan sobre el texto. Las de esta nota operan sobre los **pesos del modelo** o sobre la **arquitectura del sistema**, y son las únicas con datos que respalden una reducción seria del riesgo. Conocerlas sirve para dos cosas: saber contra qué se está peleando en un engagement, y poder recomendar algo que no sea "poned un filtro mejor".

# Selección y fine-tuning del modelo

Antes de defender, elegir. Los modelos difieren mucho en resiliencia, y las iteraciones recientes de las familias abiertas (Llama, Gemma, Qwen) incorporan entrenamiento adversarial de serie — <mark style="background: #FFB8EBA6;">un despliegue con un modelo de hace dos años es, por sí solo, un hallazgo</mark>.

El **fine-tuning al caso de uso** aporta por dos vías: estrecha el dominio de operación (menos superficie donde desviarse) y mejora la calidad de las respuestas. Pero tiene un efecto secundario que hay que conocer y que casi nadie documenta: <mark style="background: #FF5582A6;">el fine-tuning sobre un modelo alineado **degrada su alineamiento**, incluso con datos de entrenamiento completamente benignos.</mark> Un modelo comercial fine-tuneado por el cliente suele ser más fácil de romper que el original, así que "lo hemos fine-tuneado" no es una mitigación por sí misma.

> [!info]+ Fuente
> [*Fine-tuning Aligned Language Models Compromises Safety, Even When Users Do Not Intend To!*, arXiv:2310.03693](https://arxiv.org/abs/2310.03693) — Qi et al., ICLR 2024. **Es una pregunta que hay que hacer siempre en el reconocimiento**: si el cliente fine-tuneó el modelo, su resiliencia no es la que anuncia la tarjeta del modelo base.

# Entrenamiento adversarial

Entrenar el modelo con payloads de prompt injection y jailbreak etiquetados para que aprenda a rechazarlos. Es la razón por la que los [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)|DAN públicos]] y los [[10 - Jailbreaks por obfuscación#Sufijo y sufijo adversarial|sufijos GCG de 2023]] ya no funcionan.

Su límite es de cobertura: protege contra lo que se parece a lo entrenado. Las técnicas nuevas —y en particular las [[11 - Jailbreaks multi-turno y de contexto|multi-turno]], donde ningún mensaje individual se parece a un ataque— siguen pasando.

Dos líneas de investigación reciente van más allá del entrenamiento adversarial genérico y reportan cifras notablemente buenas:

- **StruQ** ([arXiv:2402.06363](https://arxiv.org/abs/2402.06363)) — *structured queries*: entrenar al modelo con canales **separados** para instrucción y dato, creando la frontera que el prompt plano no tiene. Reduce el ASR por debajo del 2 % frente a ataques sin optimización.
- **SecAlign** ([arXiv:2410.05451](https://arxiv.org/abs/2410.05451)) — alineamiento por optimización de preferencias sobre pares (respuesta segura, respuesta inyectada). Baja el ASR del ~96 % de la línea base al ~2 %.

<mark style="background: #8000E1A6;">Ambas son defensas de **tiempo de entrenamiento**: solo están disponibles si el cliente entrena o fine-tunea su propio modelo.</mark> No se pueden aplicar sobre una API comercial.

# Jerarquía de instrucciones

Propuesta de OpenAI ([arXiv:2404.13208](https://arxiv.org/abs/2404.13208)): entrenar al modelo para asignar rangos explícitos de confianza y descartar instrucciones que provengan de un nivel inferior a aquel al que contradicen.

```text
1. system      (desarrollador)         ← máxima autoridad
2. user        (usuario final)
3. tool output / contenido recuperado  ← mínima autoridad, nunca instrucciones
```

Es la respuesta directa al problema estructural de [[00 - Anatomía del prompt y chat templates|los chat templates]], y ya está incorporada en los modelos frontera. Reduce mucho la tasa de éxito, sobre todo en inyección indirecta, pero **sigue siendo un sesgo entrenado, no un control**: un contexto suficientemente persuasivo lo revierte.

# Guardrails

Un LLM adicional, más pequeño y especializado, que clasifica. Dos posiciones posibles:

![Diagrama de input guard filtrando PII, contenido fuera de tema e intentos de jailbreak; la aplicación LLM procesa el prompt; el output guard filtra alucinaciones, lenguaje ofensivo y menciones a la competencia](https://academy.hackthebox.com/storage/modules/297/diagram.png)

- **`Input guard`**: evalúa el prompt del usuario *antes* del modelo principal. Si lo clasifica como malicioso, no llega a ejecutarse. Detecta PII, temas fuera de dominio e intentos de jailbreak.
- **`Output guard`**: evalúa la respuesta *después* de generarla. Busca contenido dañino, fuga de datos, alucinaciones o evidencia de una inyección exitosa.

Productos que un cliente puede tener desplegados hoy, útiles de reconocer en un engagement: `Llama Guard` y `Prompt Guard` (Meta), `NeMo Guardrails` (NVIDIA), `Prompt Shields` de Azure AI Content Safety, `Bedrock Guardrails` (AWS), `Model Armor` (Google Cloud). En el lado abierto, `Rebuff` y `Vigil`. Los dos que HTB desarrolla —`Model Armor` y `ShieldGemma`— están diseccionados en [[13 - Safeguards en producción (Model Armor y ShieldGemma)]], incluido **contra qué no protegen**.

El coste es real: uno o dos modelos extra por petición, con su latencia y su factura. Por eso los guardrails suelen ser modelos pequeños — y por eso son más fáciles de engañar que el modelo principal.

> [!warning]+ Los guardrails caen, y caen los primeros
> <mark style="background: #FFB86CA6;">En los cinco casos de producción de 2025 recogidos en [[06 - EchoLeak y la exfiltración zero-click]], las defensas desplegadas no impidieron la cadena — y donde había un clasificador dedicado de prompt injection (el XPIA de Microsoft), fue el primer eslabón que se rompió.</mark> Hay además trabajo académico específico sobre por qué la detección con LLM es frágil ([*How Not to Detect Prompt Injections with an LLM*, arXiv:2507.05630](https://arxiv.org/abs/2507.05630)) y sobre la sobreestimación general de estas defensas ([*A Critical Evaluation of Defenses against Prompt Injection Attacks*, arXiv:2505.18333](https://arxiv.org/abs/2505.18333)).
> Un guardrail es una **capa de reducción de ruido**, no una frontera de seguridad. Al reportar, esa distinción es la que hay que dejar clara.

Anthropic exploró una variante más robusta con los `Constitutional Classifiers` ([arXiv:2501.18837](https://arxiv.org/abs/2501.18837)): clasificadores entrenados sobre datos sintéticos generados a partir de una constitución explícita de categorías permitidas y prohibidas, que resistieron miles de horas de red teaming público. Mejor que un clasificador genérico, pero sigue siendo un clasificador.

# CaMeL — defensa por diseño

El cambio de paradigma. Google DeepMind, 2025 ([*Defeating Prompt Injections by Design*, arXiv:2503.18813](https://arxiv.org/abs/2503.18813)). En lugar de intentar que el modelo distinga instrucciones de datos, <mark style="background: #ADCCFFA6;">CaMeL asume que **no puede** y saca la decisión de seguridad fuera del modelo.</mark>

La arquitectura tiene tres piezas:

1. **LLM privilegiado**: recibe únicamente la consulta del usuario (confiable) y genera un **plan de ejecución** en forma de programa. Nunca ve datos no confiables.
2. **LLM en cuarentena**: procesa el contenido no confiable (emails, documentos, resultados de herramientas) y **no tiene acceso a herramientas**. Solo extrae y devuelve datos.
3. **Intérprete personalizado**: ejecuta el plan, rastrea la **procedencia** de cada dato mediante capacidades y evalúa una política de seguridad antes de cada llamada a herramienta.

La garantía que ofrece es fuerte y estructural: **los datos no confiables nunca pueden influir en el flujo de control del programa**. El plan lo fijó el LLM privilegiado antes de ver nada del atacante. Con eso resolvió prácticamente el benchmark `AgentDojo`.

El coste es igual de real: hay que reescribir el agente con este patrón, definir políticas explícitas por herramienta y asumir dos modelos en lugar de uno. Es la recomendación correcta para agentes con impacto alto, no para un chatbot de FAQ.

# Patrones de diseño para agentes

El trabajo de [Beurer-Kellner et al., *Design Patterns for Securing LLM Agents against Prompt Injections* (arXiv:2506.08837)](https://arxiv.org/abs/2506.08837) generaliza la idea a seis patrones aplicables según cuánta autonomía necesite el agente:

| Patrón | Idea | Coste de autonomía |
| - | - | - |
| `Action-Selector` | El agente solo elige entre acciones predefinidas; no ve los resultados | Alto |
| `Plan-Then-Execute` | El plan se fija **antes** de leer datos no confiables | Medio |
| `LLM Map-Reduce` | Un sub-agente aislado por cada fragmento no confiable; solo se agregan resultados | Medio |
| `Dual LLM` | Privilegiado + en cuarentena (la base de CaMeL) | Medio |
| `Code-Then-Execute` | Se genera código con flujo de control fijo y se ejecuta en un entorno controlado | Bajo |
| `Context-Minimization` | Se elimina del contexto todo lo que ya no hace falta tras usarlo | Bajo |

<mark style="background: #FFB8EBA6;">El hilo común de los seis: impedir que el contenido no confiable determine **qué acciones** se ejecutan.</mark> Es la traducción a arquitectura del principio de romper una pata de la [[01 - Prompt injection y por qué no tiene parche#La lethal trifecta|lethal trifecta]].

# Qué recomendar, según el caso

| Situación del cliente | Recomendación prioritaria |
| - | - |
| Chatbot sin datos ni herramientas | Guardrail comercial + límites de longitud y de tasa. Riesgo bajo, no sobre-invertir |
| Chatbot con datos de clientes | Mínimo privilegio en el contexto + guardrail de salida + auditoría de la superficie de renderizado |
| Agente con herramientas de solo lectura | Jerarquía de instrucciones + `Plan-Then-Execute` + cerrar el canal de exfiltración |
| Agente con acciones de escritura o efecto irreversible | `Dual LLM` / CaMeL + aprobación humana por acción + política explícita por herramienta |
| Cliente que entrena su propio modelo | Todo lo anterior + `SecAlign` o `StruQ` en el fine-tuning |

Y en todos los casos, la constante: **el impacto se acota en la arquitectura, no en el prompt**.

> [!info]+ La construcción de estas defensas, en Blue Team
> Esta nota cubre las defensas desde el punto de vista del atacante: qué hay enfrente y qué recomendar. Cómo se **construyen** —guardrails de entrada y salida paso a paso, `LLM-as-a-judge` con diseño *fail-closed*, librerías, servicios gestionados, y *safety fine-tuning* con LoRA contra jailbreaks y ataques de *prefill*— está en [[00 - Defensa en profundidad para sistemas de IA|Defensa de sistemas de IA]]. En particular, [[08 - Adversarial tuning con LoRA para seguridad|el adversarial tuning]] es la implementación concreta del entrenamiento adversarial mencionado arriba, y [[10 - Límites de las defensas y cómo se rompen|la nota de límites]] es el mapa cruzado ataque↔defensa de las tres capas.
