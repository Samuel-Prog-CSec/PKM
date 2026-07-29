---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Reporting
Descripción: "Una alucinación es una respuesta del modelo que es falsa, fabricada o incoherente, generada sin que nadie haya inyectado nada"
Fecha de actualización: 2026-07-28
Nota previa: "[[06 - Exfiltración por renderizado de markdown]]"
Nota siguiente: "[[08 - Slopsquatting y alucinación de paquetes]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

<mark style="background: #ADCCFFA6;">Una `alucinación` es una respuesta del modelo que es falsa, fabricada o incoherente, generada sin que nadie haya inyectado nada.</mark> No es un ataque: es el comportamiento normal de un sistema que predice el siguiente token en lugar de consultar hechos. Entra en esta carpeta porque el problema de seguridad no es que el modelo se equivoque, sino que **la aplicación sirva esa respuesta como verdad**.

Lo que las hace peligrosas es la presentación: el modelo formula la información falsa con exactamente la misma seguridad que la correcta. No hay señal de incertidumbre en el texto.

# Tres tipos

| Tipo | Qué contradice | Ejemplo |
| - | - | - |
| `Fact-conflicting` | La realidad | Contar mal cuántas veces aparece una letra en una frase, con total aplomo |
| `Input-conflicting` | El propio prompt | *"Mi camisa es roja. ¿De qué color es mi camisa?"* → *"Tu camisa es azul"* |
| `Context-conflicting` | Lo que el propio modelo acaba de decir | *"Tu camisa es roja. Es un sombrero bonito"* — confunde términos dentro de la misma respuesta |

<mark style="background: #FFB8EBA6;">La más peligrosa de las tres es la primera, y no por su gravedad sino por su detectabilidad</mark>: las otras dos se pillan comparando con el prompt o consigo mismas — automatizable. Una afirmación factual falsa exige conocer el hecho.

# Por qué ocurren

No hay una causa única: alucinar es inherente a cómo funciona un LLM. Lo que sí hay son factores que lo agravan:

- **Datos de entrenamiento incompletos** — el modelo no tiene una representación sólida del dominio y rellena con lo estadísticamente plausible.
- **Datos de baja calidad o sesgados** — el modelo aprende y reproduce el error.
- **Prompts ambiguos o contradictorios** — cuanta menos información concreta hay, más espacio hay para inventar.
- **Presión por responder.** Un modelo entrenado para ser útil prefiere una respuesta plausible a un "no lo sé". Su versión conversacional es la **adulación** (*sycophancy*): si el usuario corrige al modelo con algo falso, el modelo tiende a darle la razón.

# Medir la certeza

Como no se pueden eliminar, la mitigación práctica es **detectarlas** estimando la confianza del modelo. Tres enfoques:

![Diagrama de los tres métodos de estimación de certeza aplicados a la altura del Kilimanjaro: logit-based, verbalize-based y consistency-based](https://academy.hackthebox.com/storage/modules/307/diag3.png)

| Enfoque | Cómo | Viabilidad |
| - | - | - |
| `Logit-based` | Leer las probabilidades token a token del modelo | Requiere acceso interno. Descartado con la mayoría de APIs comerciales |
| `Verbalize-based` | Pedirle al modelo su propia confianza (*"añade una puntuación de 0 a 100"*) | Trivial de implementar y **poco fiable**: los LLM estiman mal su propia certeza |
| `Consistency-based` | Preguntar varias veces y medir la coherencia entre respuestas | <mark style="background: #8000E1A6;">El único aplicable de forma general contra modelos cerrados</mark>. Una respuesta factual se reproduce; una alucinada varía |

El enfoque por consistencia tiene además una lectura ofensiva: es exactamente el mismo procedimiento de [[03 - Inyección directa y fuga del system prompt#Verificar que el prompt filtrado es real|verificar que un system prompt filtrado es real]] — preguntar dos veces y diffear.

Otras mitigaciones que un cliente puede tener desplegadas: enriquecer el prompt con conocimiento externo verificado (RAG), fine-tuning sobre el dominio, y esquemas **multi-agente** donde varios modelos debaten hasta converger. Ninguna elimina el problema; todas lo reducen a costa de latencia y coste.

> [!info]+ Fuente
> Revisión de referencia sobre tipos, causas y mitigaciones: [*Siren's Song in the AI Ocean: A Survey on Hallucination in Large Language Models*, arXiv:2309.01219](https://arxiv.org/abs/2309.01219).

# El impacto, que es lo que se reporta

## Responsabilidad legal — el precedente Air Canada

Febrero de 2024. Un pasajero consultó al chatbot de soporte de Air Canada sobre tarifas de duelo. El bot **alucinó** una política que no existía: le dijo que podía comprar el billete y solicitar el reembolso después. La aerolínea denegó el reembolso alegando que su política real decía otra cosa.

El tribunal civil de Columbia Británica falló en contra de la aerolínea. El argumento es el que importa: <mark style="background: #FF5582A6;">una empresa es responsable de toda la información que facilitan sus representantes y su web, **incluido un chatbot**.</mark> Air Canada tuvo que pagar.

Para un informe, este caso vale más que cualquier explicación técnica: convierte "el modelo a veces se inventa cosas" en **riesgo legal cuantificado y con jurisprudencia**. Argumento directo para exigir validación de la salida en cualquier flujo con consecuencia contractual.

## Vulnerabilidades introducidas en el código

El impacto técnico más relevante hoy. Un LLM que genera código puede producir:

- **Bugs de lógica** que pasan la revisión porque el código *parece* correcto.
- **Patrones inseguros**: concatenación de SQL en vez de parámetros, criptografía mal usada, validación ausente, secretos embebidos. El modelo reproduce lo que vio en su corpus de entrenamiento, que incluye una enorme cantidad de código inseguro de tutoriales y foros.
- **APIs inventadas**: llamadas a funciones o parámetros que no existen. Molesto pero inofensivo — salvo cuando lo inventado es un **paquete**, que es el vector de [[08 - Slopsquatting y alucinación de paquetes]].

Al revisar una aplicación cuyo equipo usa asistentes de IA, esto se traduce en una recomendación concreta: **el código generado necesita la misma revisión que el escrito a mano**, y conviene reforzar el análisis estático en los patrones que los modelos reproducen peor (criptografía, autenticación, deserialización).

## Los demás

- **Desinformación y sesgo** — contenido discriminatorio o tóxico servido como información de la marca.
- **Privacidad** — si el entrenamiento incluyó datos personales, el modelo puede reproducirlos dentro de una alucinación.
- **Erosión de confianza** — cuantitativamente menor, cualitativamente el que más preocupa al negocio.

# Alucinación vs. abuso

Distinción que hay que mantener limpia al clasificar hallazgos, y que HTB señala bien:

- **Alucinación** — el modelo genera información falsa **sin intención**. Es un fallo de fiabilidad. `LLM09:2025 Misinformation`.
- **[[10 - Ataques de abuso y desinformación|Ataque de abuso]]** — un adversario usa el modelo para generar desinformación **deliberadamente**. Es un problema de uso indebido, no de fallo.

El sistema puede funcionar perfectamente y producir el segundo; solo el primero es un defecto.

# Qué recomendar

| Medida | Dónde aplica |
| - | - |
| **No usar la salida sin validar en flujos con consecuencia** (contractual, económica, de seguridad) | La principal. Es lo que falló en Air Canada |
| **Anclar en fuentes** (RAG) y **exigir citas verificables** en la respuesta | Reduce fabricación y permite comprobar |
| **Comprobación por consistencia** sobre respuestas críticas | Detección automatizable sin acceso al modelo |
| **Revisión humana selectiva** en decisiones de alto impacto | Efectiva si el volumen permite revisar de verdad |
| **Aviso visible** de que la respuesta es generada por IA y puede contener errores | <mark style="background: #FFB8EBA6;">Mitiga poco el riesgo real</mark> y no eximió a Air Canada, pero es requisito de transparencia bajo el [[14 - Marco regulatorio del contenido generado por IA\|AI Act]] |
| **Revisión y análisis estático del código generado** | Cierra el vector técnico |
