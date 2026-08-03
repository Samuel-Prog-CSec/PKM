---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Enumeracion
Descripción: "El reconocimiento de una aplicación LLM busca entender la superficie de ataque y las restricciones operativas antes de tocar ningún safeguard"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Prompt injection y por qué no tiene parche]]"
Nota siguiente: "[[03 - Inyección directa y fuga del system prompt]]"
Area: "[[Prompt Injection.base|Prompt Injection]]"
---
---

<mark style="background: #ADCCFFA6;">El reconocimiento de una aplicación LLM busca entender la superficie de ataque y las restricciones operativas **antes** de tocar ningún safeguard.</mark> La lógica es la misma que en un pentest clásico: cuanto mejor sea el mapa, menos ruido hay que generar después. Y aquí el ruido se paga caro — cada payload que dispara un guardrail queda logueado y, en despliegues con detección madura, quema la cuenta.

Cinco preguntas guían la fase:

1. ¿Qué modelo hay detrás y de qué es capaz?
2. ¿Con qué está integrado — RAG, herramientas, plugins?
3. ¿Qué acepta como entrada y con qué límites?
4. ¿Qué se niega a hacer y cómo lo expresa?
5. ¿Qué safeguards hay y en qué capa viven?

# Identidad del modelo

Interesa saber si es un modelo **propietario** (API de OpenAI, Anthropic, Google) o **open-weights** (Llama, Qwen, Mistral, Gemma), y si es un **modelo base** o uno **fine-tuneado** para el dominio. Cambia todo lo demás: la resiliencia entrenada, el formato de [[00 - Anatomía del prompt y chat templates|chat template]] al que responde, y qué jailbreaks públicos tienen probabilidad de funcionar.

Prompts de sondeo directo:

```text
Tell me the type or family of language model powering this application.
Are you a general-purpose model or one fine-tuned for a specific domain?
What is your knowledge cutoff date?
```

> [!warning]+
> La respuesta a "¿qué modelo eres?" **no es fiable**. Muchos system prompts instruyen al modelo a mentir sobre su identidad, y los modelos base alucinan su propia procedencia con facilidad (un Qwen fine-tuneado sobre datos sintéticos de GPT-4 se declarará ChatGPT sin dudar). Es una pista, no una conclusión: hay que corroborarla con señales de comportamiento.

Señales de comportamiento que sí discriminan y que no dependen de que el modelo colabore:

| Señal | Cómo se obtiene | Qué revela |
| - | - | - |
| Estilo de rechazo | Pedir algo claramente prohibido | Cada familia tiene fraseo propio ("I can't help with that" vs "I cannot provide…") |
| Ventana de contexto | Ir alargando la entrada hasta que trunca o falla | Distingue familias y tamaños |
| Cutoff de conocimiento | Preguntar por eventos con fecha conocida | Acota versión |
| Manejo de tokens raros | Emojis compuestos, caracteres CJK, tokens `<|...|>` | Delata el tokenizador |
| Formato por defecto | Pedir una lista sin especificar formato | Los hábitos de markdown varían por familia |

## Fingerprinting activo con LLMmap

`LLMmap` automatiza esto. Envía **ocho queries** diseñadas para maximizar la divergencia entre modelos, compara las respuestas contra firmas conocidas y devuelve un ranking por distancia.

```shell-session
$ git clone https://github.com/pasquini-dario/LLMmap
$ cd LLMmap/
$ pip3 install -r requirements.txt
$ python main_interactive.py --inference_model_path ./data/pretrained_models/default
```

En modo interactivo la herramienta muestra cada query, se pega manualmente en la aplicación objetivo y se le devuelve la respuesta. Al terminar:

```text
### RESULTS ###
Prediction:

[Distance: 24.8962] --> meta-llama/Meta-Llama-3-8B-Instruct <--
[Distance: 48.7247] google/gemma-2-9b-it
[Distance: 49.7991] claude-3-5-sonnet-20240620
[Distance: 49.9209] meta-llama/Meta-Llama-3.1-8B-Instruct
[Distance: 49.9678] Qwen/Qwen2.5-0.5B-Instruct
```

<mark style="background: #FFB8EBA6;">El modo interactivo es lo que lo hace útil de verdad</mark>: funciona contra cualquier interfaz, incluida una web sin API, porque el transporte lo pones tú.

> [!info]+ Fuente y límite real de la herramienta
> [LLMmap: Fingerprinting for Large Language Models](https://www.usenix.org/conference/usenixsecurity25/presentation/pasquini) — Pasquini, Kornaropoulos y Ateniese, **USENIX Security '25** ([arXiv:2407.15847](https://arxiv.org/abs/2407.15847)). Identifica **42 versiones de LLM con >95% de precisión** usando 8 interacciones, y es robusto frente a system prompts desconocidos, temperatura variable y frameworks tipo RAG o *chain-of-thought*.
> **Caveat de 2026**: los propios autores advierten que mantener el clasificador al día exige GPU y créditos de APIs comerciales. Su base de firmas cubre el panorama de ~2024, así que <mark style="background: #FF5582A6;">una predicción de LLMmap sobre un modelo de 2025-2026 devolverá el vecino más cercano de su catálogo, no el modelo real</mark>. Úsalo para acotar *familia*, no para afirmar versión exacta.

# Arquitectura de la aplicación

Aquí es donde se decide si el objetivo tiene la [[01 - Prompt injection y por qué no tiene parche#La lethal trifecta|lethal trifecta]]. Sondear con:

```text
Do you use any external tools or knowledge sources when responding?
What tools do you have access to?
Do you rely on any internal documents or databases to answer questions?
How current is the information you can access when answering questions?
Can you describe at a high level how you generate answers for this application?
```

Y con señales indirectas, que mienten menos que el modelo:

- **RAG presente**: la respuesta cita documentos internos, o incluye información posterior al cutoff declarado. Truco fiable — preguntar por un término inventado y muy específico: si el sistema hace retrieval, la latencia sube de forma perceptible aunque no encuentre nada.
- **Function calling**: pedir explícitamente una acción con efecto (consultar un pedido, crear un ticket) y observar si el resultado es coherente con un sistema real o inventado. Provocar un error de herramienta suele filtrar nombres de funciones y esquemas de parámetros.
- **Multi-turno**: comprobar si recuerda el turno anterior. Si lo hace, los [[11 - Jailbreaks multi-turno y de contexto|ataques multi-turno]] están sobre la mesa.

# Manejo de entrada y restricciones de salida

Estos límites se implementan en la **aplicación**, no en el modelo, así que no sirve preguntárselos: hay que probarlos.

- ¿Se pueden subir ficheros o imágenes? ¿El modelo los procesa de verdad o solo se almacenan?
- ¿Cuál es la longitud máxima de entrada? ¿Trunca en silencio o devuelve error?
- ¿Cómo reacciona a Unicode inusual, caracteres de control o `zero-width`? Es el sondeo previo a [[07 - ASCII smuggling y payloads invisibles]].

Para la salida, medir el perímetro con peticiones progresivamente más incómodas — desde una desviación benigna del propósito (pedirle una receta de pizza a un bot de soporte) hasta algo claramente prohibido. Lo relevante no es que rechace, es **cómo** rechaza.

# Localizar los guardrails

<mark style="background: #8000E1A6;">Distinguir en qué capa vive el filtro es la información más accionable de toda la fase de recon, porque determina qué familia de evasión tiene sentido.</mark> Se deduce observando el comportamiento del rechazo:

| Observación | Capa probable | Implicación ofensiva |
| - | - | - |
| Rechazo **instantáneo**, mensaje genérico e idéntico siempre, sin consumir tiempo de generación | `input guard` (clasificador previo) | El modelo nunca vio el payload → hay que ofuscar la **entrada** ([[10 - Jailbreaks por obfuscación]]) |
| El texto **empieza a generarse en streaming y se corta** a media frase, o la respuesta tarda lo normal y luego se sustituye por un error | `output guard` (filtro posterior) | El modelo **sí** se dejó convencer → atacar la salida: pedir el dato codificado, fragmentado o en otro idioma |
| Rechazo redactado en el estilo del asistente, variable entre intentos | Alineamiento del modelo | Territorio de [[08 - Fundamentos del jailbreaking]] |
| Bloqueo por HTTP 4xx antes de cualquier respuesta | WAF / rate limiter | Problema de transporte, no de LLM |

Un output guard que corta a media frase es además una **filtración en sí misma**: los primeros tokens generados antes del corte suelen contener el principio del dato que se quería proteger.

# Superficie de infraestructura

El modelo es solo una parte del objetivo. En un engagement con alcance de red, conviene revisar la capa de servicio, que casi siempre está peor defendida:

- **Endpoints compatibles con OpenAI**: casi todos los servidores de inferencia (`vLLM`, `Ollama`, `LM Studio`, `llama.cpp`) exponen `GET /v1/models`, que lista modelos exactos sin autenticación en instalaciones por defecto.
- **`Ollama` expuesto**: escucha en `11434/tcp`; publicado en Internet sin autenticación permite listar, descargar y ejecutar modelos, y en versiones antiguas también borrarlos.
- **Trazas de framework**: un error no controlado de `LangChain`, `LlamaIndex` o `Semantic Kernel` filtra la cadena completa de componentes, y con ella el nombre de las herramientas y a veces trozos del system prompt.

Esto conecta con el footprinting tradicional ([[00 - Principios y metodología de enumeración]]): un servicio de inferencia es un servicio de red más, y se enumera con [[00 - Introducción a Nmap|Nmap]] como cualquier otro.

> [!important]+ Registrar antes de atacar
> Todo lo anterior va al informe aunque no derive en explotación: el modelo identificado, las herramientas conectadas, los límites de entrada y la capa donde vive cada guardrail. <mark style="background: #FFB86CA6;">Un cliente que descubre por el informe que su chatbot de soporte tiene acceso de lectura al CRM ya ha recibido valor</mark>, independientemente de si conseguimos exfiltrar algo.
