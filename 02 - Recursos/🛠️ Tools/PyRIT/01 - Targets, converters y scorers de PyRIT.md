---
tags:
  - IA/Red-Team
  - IA/LLM
  - Pentesting/Explotacion
Descripción: "Las tres piezas que hay que configurar antes de lanzar cualquier ataque: a quién se ataca, cómo se transforma el payload y cómo se decide si funcionó"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Qué es PyRIT y cuándo usarlo]]"
Nota siguiente: "[[02 - Ataques multi-turno con PyRIT]]"
Area: "[[PyRIT.base|PyRIT]]"
---
---

Las tres piezas que hay que configurar antes de lanzar cualquier ataque: **a quién se ataca**, **cómo se transforma el payload** y **cómo se decide si funcionó**.

# Targets — a quién se ataca

Un `PromptTarget` abstrae el sistema objetivo. La variedad es lo que hace a PyRIT aplicable a objetivos reales y no solo a APIs de proveedor:

| Target | Para qué |
| - | - |
| `openai/` | API de OpenAI y **cualquier endpoint compatible** — vLLM, Ollama, LiteLLM |
| `hugging_face/` | Modelos locales e Inference API |
| `azure_ml_chat_target`, `litellm_chat_target` | Modelos gestionados |
| **`http_target/`** | <mark style="background: #ADCCFFA6;">Cualquier endpoint HTTP: la aplicación del cliente</mark>. El equivalente al generador `rest` de [[03 - garak contra una aplicación real y en CI\|garak]] |
| **`playwright_target`**, `playwright_copilot_target` | **Conducir un navegador**: interfaces web sin API documentada |
| `websocket_copilot_target` | Objetivos sobre WebSocket |
| **`prompt_shield_target`** | Atacar directamente el **guardrail** de Azure Prompt Shields |
| `gandalf_target` | El reto público de Lakera — útil para practicar |
| `text_target`, `round_robin_target` | Depuración y reparto entre varios objetivos |

Tres merecen atención especial en un engagement:

- **`http_target`** es el que se usa contra el cliente. Se le da la plantilla de la petición real —capturada con [[02 - Interceptación de peticiones|Burp]]— y PyRIT sustituye el prompt donde toque.
- **`playwright_target`** resuelve el caso que nada más resuelve: un chatbot web sin API pública. <mark style="background: #FFB86CA6;">Si el objetivo solo existe como interfaz de usuario, esta es la diferencia entre poder automatizar y no poder</mark>.
- **`prompt_shield_target`** permite medir el guardrail **por separado** del modelo. Es exactamente la separación que pide el [[02 - Reconocimiento de aplicaciones LLM#Localizar los guardrails|reconocimiento de guardrails]]: saber qué bloquea el filtro y qué bloquea el alineamiento.

# Converters — cómo se transforma el payload

Un `PromptConverter` altera el prompt antes de enviarlo. La biblioteca es enorme y **encadenable**, lo que la convierte en la automatización directa de [[10 - Jailbreaks por obfuscación|toda la familia de ofuscación]].

| Familia | Conversores | Nota del vault |
| - | - | - |
| **Codificaciones** | `base64`, `base2048`, `binary`, `bin_ascii`, `braille`, `atbash`, `caesar`, `ascii_art` | [[10 - Jailbreaks por obfuscación#Codificaciones y cifrados]] |
| **Unicode y homoglifos** | `bidi`, `arabic_presentation_form`, `character_space`, `charswap_attack` | [[07 - ASCII smuggling y payloads invisibles]] |
| **Terminal** | `ansi_escape` | Inyección de escapes ANSI en la salida — agentes CLI |
| **Lingüísticos** | `arabizi`, `colloquial_wordswap`, traducción | Idiomas poco representados |
| **Estructurales** | `codechameleon`, `ask_to_decode` | [[10 - Jailbreaks por obfuscación#Token smuggling por composición\|Token smuggling]] e IMM |
| **Audio** | `audio_echo`, `audio_frequency`, `audio_speed`, `audio_volume`, `audio_white_noise`, `azure_speech_text_to_audio` | Jailbreak multimodal |
| **Imagen** | `add_text_image`, `add_image_text`, `base_image_to_image` | Payload renderizado en imagen |

<mark style="background: #8000E1A6;">El valor no está en ningún conversor individual, está en **encadenarlos y medir**.</mark> Aplicar `caesar` + `character_space` + traducción a un mismo payload, lanzarlo N veces y ver qué combinación pasa el filtro es un trabajo de horas a mano y de minutos con PyRIT.

Los conversores de audio e imagen son además la vía práctica al jailbreak multimodal, que casi ninguna otra herramienta cubre: el mismo payload rechazado como texto puede pasar renderizado en una imagen o sintetizado como voz.

# Scorers — cómo se decide si funcionó

Un `Scorer` evalúa la respuesta. Es la pieza que permite iterar sin un humano mirando, y por tanto la que hace posible el multi-turno automatizado.

| Tipo | Devuelve | Uso |
| - | - | - |
| **`true_false`** | Booleano | ¿Cumplió el objetivo del ataque? |
| **`float_scale`** | Valor continuo | Cuánto se acercó — permite gradiente en ataques iterativos |
| `llm_scoring` | Lo evalúa otro LLM | El más flexible y el más caro |
| `conversation_scorer` | Evalúa la **conversación completa** | Necesario para multi-turno |
| `batch_scorer` | Puntúa lotes | Medición de ASR a escala |
| `audio_transcript_scorer`, `video_scorer` | Multimodal | Salidas no textuales |

> [!important]+ `scorer_evaluation` — evaluar al evaluador
> PyRIT incluye un módulo para **medir la calidad del propio scorer** contra un conjunto etiquetado a mano. Suena a detalle académico y no lo es: <mark style="background: #FF5582A6;">todo el resultado de un ataque automatizado depende de que el scorer acierte</mark>. Un scorer con falsos positivos reporta éxitos que no existen; uno con falsos negativos descarta técnicas que sí funcionaban.
> Antes de fiarse de una cifra de ASR producida por PyRIT, hay que haber comprobado el scorer sobre una muestra revisada manualmente. Es el mismo criterio que la [[02 - Ejecución y lectura de informes de garak#Verificación manual — no negociable|verificación manual de los hallazgos de garak]].

El `conversation_scorer` es el que hace viable Crescendo y compañía: en un ataque multi-turno el éxito no está en un mensaje, está en la trayectoria, y evaluarla exige mirar el historial entero.

# Memory — dónde queda todo

`Memory` persiste conversaciones, prompts, respuestas y puntuaciones en base de datos. Tres consecuencias prácticas:

- **Reanudar** un ataque largo sin repetir lo ya hecho.
- **Calcular ASR** sobre las repeticiones almacenadas, en vez de contar a mano.
- **Evidencia para el informe**: la conversación literal que produjo el hallazgo, exportable.

<mark style="background: #FFB8EBA6;">Y la contrapartida de OPSEC: esa base de datos contiene todos los payloads, todas las respuestas y todo el contenido dañino generado.</mark> Es material sensible del engagement — cifrado, retención acotada y destrucción al cierre, igual que cualquier otra evidencia ([[02 - Evidencias, capturas y redacción]]).
