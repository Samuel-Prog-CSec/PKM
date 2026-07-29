---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - IA/Generativa
Descripción: "Un jailbreak es el objetivo de saltarse las restricciones impuestas a un LLM; la prompt injection es el medio más habitual para conseguirlo"
Fecha de actualización: 2026-07-28
Nota previa: "[[07 - ASCII smuggling y payloads invisibles]]"
Nota siguiente: "[[09 - Jailbreaks clásicos (DAN, roleplay y ficción)]]"
Area: "[[Prompt Injection.base|Prompt Injection]]"
---
---

<mark style="background: #ADCCFFA6;">Un `jailbreak` es el objetivo de saltarse las restricciones impuestas a un LLM; la prompt injection es el medio más habitual para conseguirlo.</mark> La distinción importa porque son cosas de nivel distinto — una es el *qué* y otra el *cómo* — y porque en un informe se clasifican y se puntúan de forma diferente.

# Dos objetivos que se confunden constantemente

Bajo la palabra "jailbreak" caben dos targets que se comportan distinto y se defienden distinto:

| | **Bypass del alineamiento** | **Bypass del system prompt** |
| - | - | - |
| Qué se salta | Restricciones **entrenadas** en el modelo (no generar malware, armas, contenido de abuso) | Reglas que puso el **operador** (habla solo de flores, no menciones a la competencia) |
| Dónde vive la defensa | Pesos del modelo (RLHF, entrenamiento adversarial) | Texto del prompt, sin ninguna garantía |
| Dificultad | Alta y creciente | Baja |
| Quién es la víctima | El proveedor del modelo y la sociedad | La organización que despliega |
| Severidad reportable | Normalmente **fuera de alcance** en un pentest de aplicación | La que corresponda al impacto de negocio |

<mark style="background: #FF5582A6;">En un engagement contra una empresa, lo que se reporta casi siempre es el segundo.</mark> Que consigas que Llama te explique cómo robar manzanas es un hallazgo para el proveedor del modelo, no para tu cliente; que consigas que su bot de soporte apruebe reembolsos o hable de temas que le costarán una demanda, sí lo es. Los "jailbreaks universales" —que rompen la primera columna— son competencia de programas específicos de los laboratorios de IA.

# Por qué funcionan los jailbreaks

El marco teórico que mejor lo explica sigue siendo el de Wei, Haghtalab y Steinhardt ([*Jailbroken: How Does LLM Safety Training Fail?*, arXiv:2307.02483](https://arxiv.org/abs/2307.02483), NeurIPS 2023). Identifican **dos modos de fallo** que, entre los dos, explican prácticamente todas las técnicas de las notas siguientes:

**1. Objetivos en competencia (`competing objectives`).** El modelo fue entrenado a la vez para *ser útil*, *seguir instrucciones* y *ser inofensivo*. Cuando esos objetivos chocan, gana el que el prompt refuerza más. Un roleplay bien montado empuja fuerte hacia "sé útil y mantén la coherencia narrativa" y debilita el objetivo de seguridad. Los prefijos tipo `Sure, here is how to…` funcionan por lo mismo: crean una presión de completado que compite con la de rechazo.

**2. Generalización desajustada (`mismatched generalization`).** El pre-entrenamiento cubre un espacio muchísimo mayor que el entrenamiento de seguridad. <mark style="background: #8000E1A6;">El modelo *sabe* hacer cosas en dominios donde nunca se le enseñó a negarse.</mark> Base64, un idioma minoritario, `leetspeak`, un formato de datos exótico: la capacidad está ahí desde el pre-entrenamiento, pero el alineamiento no llegó a ese rincón. Toda la familia de [[10 - Jailbreaks por obfuscación|ofuscación y codificaciones]] explota exactamente esto.

Este marco es lo que convierte el jailbreaking de "probar prompts a ver qué pasa" en algo dirigido: <mark style="background: #FFB8EBA6;">ante un rechazo, la pregunta útil es cuál de los dos modos atacar</mark> — ¿le doy un objetivo que compita, o le llevo a un dominio donde su entrenamiento de seguridad no alcanza?

# Taxonomía operativa

| Familia | Idea | Modo de fallo | Nota |
| - | - | - | - |
| `Do Anything Now (DAN)` | Prompt largo que redefine la identidad del modelo y lo satura de instrucciones contrarias | Competing objectives | [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)]] |
| `Roleplay` | Adoptar una persona que sí respondería (la abuela, un actor) | Competing objectives | [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)]] |
| `Fictional scenarios` | Enmarcar la petición dentro de una obra de ficción | Competing objectives | [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)]] |
| `Token smuggling` | Partir, invertir o codificar las palabras que disparan el rechazo | Mismatched generalization | [[10 - Jailbreaks por obfuscación]] |
| `Suffix` / `adversarial suffix` | Añadir texto que empuja la continuación hacia una respuesta afirmativa | Competing objectives | [[10 - Jailbreaks por obfuscación]] |
| `Opposite / sudo mode` | Convencer al modelo de operar en un modo donde las reglas no aplican | Competing objectives | [[10 - Jailbreaks por obfuscación]] |
| **Multi-turno** | Escalar gradualmente a lo largo de la conversación | Ambos | [[11 - Jailbreaks multi-turno y de contexto]] |

Los tres primeros y el `opposite mode` son de 2022-2023 y hoy tienen tasa de éxito baja contra modelos frontera, aunque siguen funcionando bien contra modelos pequeños, self-hosted y sin fine-tuning de seguridad. <mark style="background: #FFB86CA6;">Las técnicas multi-turno son las que mejor funcionan en 2026</mark> y son también las que peor cubren los guardrails, porque evalúan mensaje a mensaje y ningún mensaje individual es problemático.

# No hay jailbreak universal

Es la afirmación más importante de esta nota a efectos prácticos. Cada modelo, cada versión y cada configuración de temperatura tiene una resiliencia distinta:

- Un jailbreak que funciona en `Llama-3-8B` puede fallar en `Llama-3-70B` y viceversa — a veces el modelo **más capaz** es más vulnerable, porque entiende ofuscaciones que el pequeño no.
- Los prompts DAN públicos están en los datasets de entrenamiento adversarial desde hace años. Su valor hoy es de *baseline*, no de exploit.
- Un fine-tuning sobre un modelo alineado **degrada su alineamiento** aunque los datos de fine-tuning sean benignos ([Qi et al., arXiv:2310.03693](https://arxiv.org/abs/2310.03693), ICLR 2024). Un modelo comercial fine-tuneado por el cliente suele ser bastante más fácil de romper que el original.

De ahí que el trabajo real sea probar varias familias y quedarse con la que funcione contra ese objetivo, no buscar la llave maestra.

# Medir en vez de anecdotar

Los LLM no son deterministas: el mismo payload puede fallar tres veces y funcionar a la cuarta. Un único intento no prueba ni la vulnerabilidad ni la resiliencia.

La métrica estándar es el **`Attack Success Rate` (ASR)**: número de éxitos sobre número de intentos, con el mismo payload y la misma configuración. En la práctica:

- **Mínimo 5-10 repeticiones** por payload antes de dar nada por descartado.
- **Registrar el ASR en el informe**, no un "funciona". Un 2/10 y un 9/10 describen riesgos muy distintos y el cliente necesita esa diferencia para priorizar.
- Es exactamente lo que hacen las herramientas automatizadas: [[00 - Qué es garak y cuándo usarlo|`garak`]] ejecuta cada `probe` varias veces y reporta *failure rate* precisamente por esto — el flag es [[02 - Ejecución y lectura de informes de garak#`--generations` es el flag que decide si el dato vale|`--generations`]]. Para medir el ASR de una técnica propia sobre muchas repeticiones, [[02 - Ataques multi-turno con PyRIT|PyRIT]].

> [!warning]+ Consideraciones legales y de alcance
> Probar jailbreaks implica **intentar generar contenido dañino** de forma deliberada. Antes de tocar nada:
> - Que esté en el alcance por escrito, con las categorías de contenido que se van a probar explícitamente listadas.
> - Usar `proxies` de daño siempre que se pueda: el lab de HTB pide instrucciones para robar manzanas, no para sintetizar nada. Si el objetivo es demostrar que el guardrail cae, un payload benigno-pero-prohibido lo demuestra igual y no genera material problemático.
> - Nunca conservar la salida dañina en el informe. Se documenta que el modelo respondió y se incluye un extracto mínimo o una captura recortada.
> - Contra APIs comerciales, los términos de servicio del proveedor aplican **aunque el cliente autorice la prueba**: el proveedor puede suspender la cuenta. Se prueba contra el despliegue del cliente y con su cuenta, no con la tuya.

Es el mismo criterio de conducta que rige en [[01 - Reglas, legalidad y conducta|bug bounty]]: autorización explícita, mínimo daño necesario y evidencia proporcionada.
