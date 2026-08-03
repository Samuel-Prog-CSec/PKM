---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/Red-Team
  - Tipo/Deteccion
Descripción: "La contraparte ofensiva de las tres capas: qué prueba un red teamer contra cada una, dónde está documentado en el vault y qué queda sin cubrir cuando todas están bien montadas"
Fecha de actualización: 2026-07-29
Nota previa: "[[09 - Evaluar el safety tuning y el over-refusal]]"
Nota siguiente: 
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Construir una defensa sin saber cómo se rompe produce sistemas que parecen seguros. <mark style="background: #ADCCFFA6;">Esta nota recorre las tres capas desde el lado del atacante</mark> y enlaza con el material ofensivo del vault, que es donde está el detalle.

# Capa 1 — Guardrails

| Vector | Qué se prueba | Dónde está el detalle |
| - | - | - |
| **Ruta no cubierta** | Endpoints antiguos, *streaming*, llamadas entre servicios, herramientas de agente, rutas de error | [[01 - Guardrails de entrada y salida#La debilidad estructural\|nota 01]] |
| **Fallo abierto** | Provocar error del guardrail (cuota, `timeout`, credencial) y ver si bloquea o deja pasar | [[05 - Servicios gestionados de guardrails\|nota 05]] |
| **Evasión del clasificador** | Obfuscación, codificación, homoglifos, caracteres invisibles | [[10 - Jailbreaks por obfuscación\|obfuscación]] · [[07 - ASCII smuggling y payloads invisibles\|ASCII smuggling]] |
| **Multi-turno** | Repartir el ataque entre mensajes: ninguno individual parece malicioso | [[11 - Jailbreaks multi-turno y de contexto\|multi-turno]] |
| **Ataque al juez** | `Payload` dirigido al modelo guardián para que clasifique como benigno | [[03 - Guardrails basados en IA\|nota 03]] |
| **Fuera de taxonomía** | Contenido que el guardián no está entrenado para detectar (desinformación, política de negocio) | [[13 - Safeguards en producción (Model Armor y ShieldGemma)\|Model Armor y ShieldGemma]] |
| **Vía indirecta** | El `payload` no lo escribe el usuario: llega por RAG, correo o web | [[05 - Inyección indirecta en RAG, email y web\|inyección indirecta]] · [[06 - EchoLeak y la exfiltración zero-click\|EchoLeak]] |

<mark style="background: #FF5582A6;">Las dos primeras filas son las más rentables y las menos glamurosas.</mark> En un engagement real, encontrar el endpoint de *streaming* que no aplica el guardrail de salida rinde más que semanas afinando `payloads`. Y la inyección indirecta merece énfasis aparte: un guardrail de entrada que valida el prompt del usuario **no ve** el contenido que el modelo recupera de un documento, un correo o una página web.

# Capa 2 — Entrenamiento adversarial

| Vector | Por qué funciona |
| - | - |
| **Cambio de norma** | El entrenamiento en $L_\infty$ **no** cubre $L_0$: [[08 - JSMA por pares, saliencia conjunta y poda\|JSMA]] o [[09 - EAD frente a JSMA y el estado del arte en ataques L0\|σ-zero / Sparse-RS]] con 40 píxeles |
| **Ataque más fuerte que el entrenado** | Entrenado con FGSM, atacado con [[03 - I-FGSM, PGD y el refinamiento iterativo\|PGD]] o `AutoAttack` |
| **Fuera del $\epsilon$ entrenado** | Si no hubo *epsilon spread*, la robustez se cae fuera del punto: [[07 - Epsilon spread y evaluación de robustez\|nota 07]] |
| **Transferencia** | Entrenar un sustituto propio y transferirle los ejemplos; el objetivo nunca entrenó contra esas vulnerabilidades |
| **Enmascaramiento de gradiente** | Si la defensa lo produce, se evade con transferencia o estimación del gradiente: [[04 - Detección y defensa contra la evasión\|detección y defensa]] |

La comprobación diagnóstica más rápida sobre un modelo "robusto": **una diferencia grande entre su precisión frente a FGSM y frente a PGD** delata que la robustez es aparente. Si el cliente solo ha medido con el ataque contra el que entrenó, el hallazgo se escribe solo.

# Capa 3 — Adversarial tuning

| Vector | Estado |
| - | - |
| **Priming / prefill** | Sigue funcionando en el **31 %** de los casos incluso tras el ajuste ([[09 - Evaluar el safety tuning y el over-refusal\|nota 09]]) |
| **Patrones novedosos** | El ajuste generaliza por features; un encuadre estructuralmente distinto puede no activarlas |
| **Conocer los datos de entrenamiento** | Un atacante que los estudie construye ataques diseñados para evadir los patrones aprendidos |
| **Fine-tuning posterior** | Degrada el alineamiento incluso con datos benignos ([arXiv:2310.03693](https://arxiv.org/abs/2310.03693)) |
| **Quitar el adaptador** | Si los pesos se distribuyen con LoRA separado, basta no cargarlo |
| **Métrica inflada** | La evaluación por palabras clave cuenta como rechazo respuestas que sí cumplieron ([[09 - Evaluar el safety tuning y el over-refusal#Cómo se detecta un rechazo (y por qué el número está inflado)\|nota 09]]) |

<mark style="background: #FFB86CA6;">La última fila es la que más veces convierte una defensa "validada" en un hallazgo:</mark> el modelo no es más seguro, la métrica es más generosa. Reevaluar con juez LLM y muestra revisada a mano es barato y suele mover los números varios puntos.

# Lo que ninguna de las tres cubre

Con las tres capas bien montadas, queda fuera del alcance:

- **[[01 - Model reverse engineering y robo de modelos|Robo del modelo]]** — no depende de la influencia de ninguna muestra ni de contenido dañino; se roba funcionalidad con consultas legítimas.
- **[[00 - Amenazas de privacidad en modelos de ML|Fuga de datos de entrenamiento]]** — requiere [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|privacidad diferencial]], no guardrails. Un guardrail de salida detecta un número de tarjeta; no detecta que el modelo memorizó a un individuo.
- **[[01 - Taxonomía de los ataques a los datos|Envenenamiento de datos]]** — ocurre antes del entrenamiento; ninguna defensa de inferencia lo toca.
- **La superficie de agentes** — cuando el modelo invoca herramientas, la superficie deja de ser texto: [[00 - Qué es MCP y por qué cambia la superficie de ataque|MCP y seguridad de agentes]] y [[05 - Agencia excesiva y funciones vulnerables|agencia excesiva]]. Un guardrail sobre el chat no ve las llamadas a herramientas.
- **La infraestructura** — el servidor de inferencia, el registro de modelos, el pipeline de despliegue: [[00 - Superficie de ataque de aplicación y sistema|aplicación y sistema]].

<mark style="background: #8000E1A6;">Es el punto que hay que dejar claro en cualquier informe: las tres capas de este módulo cubren **manipulación del comportamiento del modelo en inferencia**. No cubren privacidad, ni integridad del entrenamiento, ni la infraestructura, ni la superficie de agentes.</mark>

# Qué se recomienda, por orden de impacto

1. **Cerrar las rutas que no pasan por el guardrail.** Encapsular la llamada al modelo en un único cliente interno. Es lo más barato y lo que más ataques reales corta.
2. **Hacer que todo falle cerrado.** Guardrail que no responde ⇒ bloquear; juez que devuelve algo raro ⇒ bloquear; servicio caído ⇒ modo degradado explícito, no tráfico sin filtrar.
3. **Guardián de familia distinta al modelo principal.** Coste cero, y es lo que hace válido el argumento de la doble manipulación.
4. **Safety tuning con LoRA** si se controla el modelo. Mejor relación coste/beneficio de todas las defensas: 11 M de parámetros, menos de un minuto, +62 puntos en defensa de *priming*.
5. **Entrenamiento adversarial con PGD y evaluación con `AutoAttack`**, más una pasada específica en la norma que imponga el dominio real.
6. **Monitorización y registro** — no como control preventivo, sino porque sin registros no hay forma de saber que está pasando nada. Aplica especialmente a los ataques indetectables por diseño ([[10 - Detección y evasión en ataques de privacidad|detección en ataques de privacidad]]).
7. **Revisión humana** sobre muestreo, para los flujos de riesgo alto.

> [!important]+ El marco honesto
> Ninguna de estas defensas cierra el ataque; todas **elevan su coste**. Eso no es un fracaso, es cómo funciona la seguridad en general — y es exactamente lo que hay que escribir en el informe. <mark style="background: #FFB8EBA6;">La afirmación defendible no es "el sistema es seguro", sino "un ataque exitoso requiere X, y si ocurre lo veríamos por Y".</mark> Si la respuesta a la segunda parte es "no lo veríamos", ese es el hallazgo, con independencia de lo buena que sea la primera.
