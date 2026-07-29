---
tags:
  - IA
  - IA/LLM
  - IA/Generativa
Descripción: "Un Large Language Model es un transformer de solo decoder, entrenado sobre volúmenes masivos de texto, que genera texto prediciendo el siguiente token una y otra vez"
Fecha de actualización: 2026-07-28
Nota previa: "[[05 - IA generativa]]"
Nota siguiente: "[[07 - Modelos de difusión]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Un `Large Language Model` es un `transformer` de solo decoder, entrenado sobre volúmenes masivos de texto, que genera texto prediciendo el siguiente token una y otra vez.</mark> Toda su aparente capacidad de razonar, traducir o programar emerge de esa única operación repetida sobre una arquitectura suficientemente grande y unos datos suficientemente variados.

Tres propiedades lo caracterizan: **escala** (miles de millones de parámetros), **aprendizaje con pocos ejemplos** (resuelve tareas nuevas con un par de ejemplos en el prompt, sin reentrenar) y **comprensión contextual** (mantiene coherencia sobre el contenido de su ventana de contexto).

# Del texto a los tokens

**Tokenización.** El texto se parte en unidades que el modelo maneja como símbolos. <mark style="background: #FFB8EBA6;">La tokenización real **no** es por palabras</mark>: se usa `Byte-Pair Encoding` o variantes, que producen subpalabras. `"artificial"` puede convertirse en `["art", "ificial"]`, y una palabra rara se fragmenta en muchos trozos.

> [!warning]+ El tokenizador es superficie de ataque
> Los filtros de contenido que buscan cadenas prohibidas operan sobre texto; el modelo opera sobre tokens. Cuando ambas representaciones no coinciden, hay hueco. <mark style="background: #FF5582A6;">Insertar caracteres de ancho cero, homoglifos Unicode, separadores o codificaciones alternativas cambia la tokenización sin cambiar lo que el modelo entiende</mark> — el filtro no encuentra la cadena y el modelo sí capta el significado.
>
> Es exactamente el mismo patrón que la evasión de WAF por normalización divergente que ya está cubierta en el vault para web: dos componentes interpretan la misma entrada de forma distinta, y el atacante vive en la diferencia.

**Embeddings.** Cada token se convierte en un vector. Tokens semánticamente próximos quedan cerca en ese espacio: `king` está más cerca de `queen` que de `table`.

> [!important]+ Dos cosas distintas se llaman "embedding", y confundirlas lleva a errores de diseño
> - **Embedding de entrada del LLM** — una tabla de búsqueda: token → vector. Es **estático**: `bank` tiene el mismo vector en "river bank" y en "bank account". La desambiguación no ocurre aquí, ocurre en las capas de atención posteriores, que mezclan cada token con su contexto. El ejemplo `king`/`queen` viene de los embeddings estáticos clásicos (`word2vec`), no del interior de un transformer.
> - **Embedding de documento para RAG** — lo produce un modelo **aparte**, normalmente de solo encoder (ver [[04 - Transformers y el mecanismo de atención]]), que procesa el texto completo y devuelve **un** vector contextual por fragmento. Es lo que se indexa en la base vectorial.
>
> <mark style="background: #FFB8EBA6;">Son modelos distintos, con espacios vectoriales distintos y no intercambiables.</mark> De ahí dos consecuencias prácticas: cambiar el modelo de embeddings obliga a **reindexar todo el corpus** (los vectores viejos dejan de ser comparables), y la calidad de un sistema RAG depende del modelo de embeddings tanto o más que del LLM que genera la respuesta. En una auditoría, el modelo de embeddings y su base vectorial son un componente propio — el `LLM08` de [[03 - OWASP Top 10 para aplicaciones LLM]].

# Cómo se entrena realmente

Los materiales introductorios suelen decir "aprendizaje no supervisado" y quedarse ahí. El proceso real tiene tres fases, y cada una es un punto de ataque distinto:

1. **Pre-entrenamiento** — `self-supervised` sobre un corpus enorme: predecir el siguiente token. No hay etiquetas humanas; la etiqueta es el propio texto. Aquí se adquiere el conocimiento del mundo, y aquí entra el <mark style="background: #FFB86CA6;">envenenamiento del corpus</mark>, viable porque el corpus se recolecta a escala web sin curación.
2. **Ajuste supervisado (`SFT`)** — entrenamiento sobre pares instrucción-respuesta de calidad. Convierte un modelo que completa texto en uno que sigue instrucciones.
3. **Alineación** — `RLHF`, `DPO` o variantes, según lo descrito en [[12 - Aprendizaje por refuerzo]]. Es lo que produce las negativas ante peticiones dañinas. **Es una política aprendida, no una regla**, y ahí es donde muerden los `jailbreaks`.

# Inferencia: los parámetros que importan

En cada paso el modelo produce una distribución de probabilidad sobre todo el vocabulario, y hay que elegir un token de ella:

| Parámetro | Efecto | Relevancia ofensiva |
| - | - | - |
| `temperature` | Aplana (>1) o agudiza (<1) la distribución | Temperaturas altas aumentan la variabilidad y con ella la probabilidad de salirse del comportamiento alineado |
| `top-k` | Restringe el muestreo a los `k` tokens más probables | Limita cuánto puede desviarse la generación |
| `top-p` | Restringe al conjunto mínimo que acumula probabilidad `p` | Igual, adaptativo a la forma de la distribución |
| `max_tokens` | Corta la generación | Un límite bajo puede truncar la respuesta a mitad y dejar salida mal formada |

<mark style="background: #8000E1A6;">Que el muestreo sea estocástico tiene una consecuencia operativa directa en un engagement</mark>: un `jailbreak` que falla no está necesariamente descartado. La misma entrada puede producir salidas distintas, así que la evaluación de estos sistemas requiere repetición — un único intento no prueba nada, ni el éxito ni el fracaso.

# La arquitectura del sistema, que es donde está el riesgo

Un LLM aislado tiene poca superficie de ataque: entra texto, sale texto. Lo que se despliega en producción es otra cosa:

- **Prompt de sistema** — instrucciones fijas que preceden a la conversación. Son solo tokens más, sin ningún privilegio arquitectónico sobre el resto; por eso son **extraíbles** y **sobrescribibles**. Ver [[04 - Transformers y el mecanismo de atención]].
- **`RAG`** — se recuperan documentos de una base vectorial y se inyectan en el contexto. <mark style="background: #FF5582A6;">Si un atacante puede escribir en la fuente indexada, escribe en el prompt del modelo</mark>: es el canal canónico de `prompt injection` indirecta.
- **Herramientas y agentes** — el modelo emite llamadas a funciones que un orquestador ejecuta: consultas a bases de datos, peticiones HTTP, ejecución de código. Aquí es donde una inyección deja de producir texto raro y produce impacto real.
- **Ventana de contexto** — finita. Todo lo que entra compite por espacio, y desplazar instrucciones fuera de la ventana es una técnica de ataque por sí sola.

Los dos elementos añadidos en 2025-2026 que amplían esto: los protocolos de integración tipo `MCP`, que estandarizan cómo un modelo accede a herramientas y datos externos (y por tanto estandarizan también la superficie), y los **modelos de razonamiento**, que generan cadenas de pensamiento intermedias — un artefacto adicional que puede filtrar información o convertirse en objetivo de manipulación.

# Marco de referencia

Para clasificar hallazgos sobre aplicaciones LLM, la referencia de la industria es el **OWASP Top 10 for LLM Applications**, que se desarrolla en las notas del módulo de red teaming. Y para el modelo de amenaza formal, el [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final), cuya sección de GenAI cubre cadena de suministro, inyección directa e indirecta, abuso y seguridad de agentes.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, corregido en la descripción de la tokenización (subpalabra, no palabra) y del entrenamiento (`self-supervised` + `SFT` + alineación, no "no supervisado"), y ampliado con parámetros de inferencia, arquitectura de sistema y superficie de ataque, ausentes en el original.
- [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final) — taxonomía de ataques a GenAI (consultado 2026-07-28).
