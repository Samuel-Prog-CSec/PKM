---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting
  - Tipo/Arsenal
Descripción: "HTB dedica una sección a garak y menciona PyRIT y ART de pasada, con la sintaxis de 2024"
Fecha de actualización: 2026-07-28
Nota previa: "[[14 - Detección y evasión en prompt injection]]"
Nota siguiente: 
Area: "[[Prompt Injection.base|Prompt Injection]]"
---
---

HTB dedica una sección a `garak` y menciona `PyRIT` y `ART` de pasada, con la sintaxis de 2024. Esta nota es el arsenal **específico de prompt injection** en 2026, con el reparto por fase de trabajo. El panorama general de herramientas de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]]; la referencia completa del escáner, en [[00 - Qué es garak y cuándo usarlo|la carpeta de garak en Tools]].

# Por fase del trabajo

| Fase | Herramienta | Para qué |
| - | - | - |
| [[02 - Reconocimiento de aplicaciones LLM\|Reconocimiento]] | `LLMmap` | Fingerprinting del modelo con 8 queries |
| | `Burp Suite` / proxy | Ver el `messages` real, detectar historial manipulable, medir latencia de guardrails |
| Barrido inicial | **`garak`** | Cobertura amplia automatizada: qué familias hacen ceder al objetivo |
| Ataque dirigido | **[[00 - Qué es PyRIT y cuándo usarlo\|`PyRIT`]]** | Ataques multi-turno automatizados (Crescendo incluido) |
| Payloads manuales | `ASCII Smuggler`, `promptmap2` | Construir y decodificar payloads invisibles; probar corpus contra un system prompt propio |
| Regresión y CI | **`promptfoo`** | Dejar las pruebas ejecutables para el cliente |
| Verificación de exfiltración | `Burp Collaborator`, `interactsh` | Confirmar el canal de salida sin adjuntar datos reales |

## garak — barrido inicial

<mark style="background: #FF5582A6;">Aviso de actualización: la sintaxis que enseña HTB está obsoleta.</mark> El proyecto pasó de `leondz/garak` a **`NVIDIA/garak`** y va por la **v0.14** (febrero 2026). Los cambios que importan:

| HTB (v0.9, 2024) | Actual (v0.14, 2026) |
| - | - |
| `--model_type` / `--model_name` | `--target_type` / `--target_name` (los antiguos siguen como alias) |
| `--probes` / `-p` | **`--spec`** — selección unificada de probes, buffs y tags. `--probes` está marcado deprecado |
| `--probe_tags` | `--spec 'tag:...'` |

Instalación y uso mínimo:

```shell-session
$ python -m pip install -U garak
$ python -m garak --list_probes
```

Lo que hace útil a `--spec` para este módulo es que permite seleccionar **por taxonomía**, en vez de acordarse de los nombres de las probes:

```shell-session
# Todo lo que mapea a OWASP LLM01 (prompt injection)
$ python -m garak --target_type openai --target_name gpt-4o --spec 'tag:owasp:llm01'

# Familia dan completa, excluyendo una probe concreta
$ python -m garak --target_type huggingface --target_name meta-llama/Llama-3.1-8B-Instruct \
    --spec 'probes.dan,-probes.dan.DanInTheWild'

# Solo las probes de tier 1 y 2 (las más relevantes / mejor mantenidas)
$ python -m garak --target_type ollama --target_name llama3.1 --spec 'tier:2'
```

Las familias de probes que aplican a este módulo: `promptinject`, `latentinjection`, `sysprompt_extraction`, `smuggling`, `dan`, `grandma`, `encoding`, `suffix`, `goodside`, `leakreplay`. La mecánica de probes, detectors e interpretación de informes está en la [[01 - Probes, detectors y buffs de garak|carpeta de garak]].

## PyRIT — el que hace falta para multi-turno

`garak` lanza prompts de un solo turno contra un objetivo. <mark style="background: #ADCCFFA6;">`PyRIT` (Microsoft) es un **orquestador**: mantiene la conversación, transforma los payloads y puntúa las respuestas, que es exactamente lo que hacen falta para los [[11 - Jailbreaks multi-turno y de contexto|ataques multi-turno]].</mark>

Sus cuatro piezas y por qué importan aquí:

- **`Target`** — el sistema objetivo (API, endpoint propio, aplicación web).
- **`Converter`** — transforma el payload antes de enviarlo: Base64, `leetspeak`, traducción, caracteres Unicode. Es la [[10 - Jailbreaks por obfuscación|ofuscación]] automatizada, y se pueden encadenar.
- **`Scorer`** — decide si el ataque tuvo éxito, normalmente con otro LLM como juez. Es lo que permite iterar sin supervisión humana.
- **`Orchestrator`** — la estrategia. Incluye implementaciones de **Crescendo** y de red teaming multi-turno genérico.

Es la herramienta correcta cuando el objetivo tiene un input guard por mensaje y hay que construir la escalada, o cuando hace falta medir el [[08 - Fundamentos del jailbreaking#Medir en vez de anecdotar|ASR]] de una técnica propia sobre muchas repeticiones. Referencia completa en [[00 - Qué es PyRIT y cuándo usarlo|su carpeta de Tools]].

## promptfoo — dejar la prueba montada

Enfoque de desarrollo: se declara la configuración en YAML, se generan los ataques y el `pipeline` falla si una defensa se rompe. Para prompt injection tiene plugins específicos (inyección directa e indirecta, fuga de system prompt, exfiltración) y genera un informe con mapeo a OWASP LLM Top 10.

<mark style="background: #FFB8EBA6;">Su valor real en un engagement no es encontrar el bug: es entregarle al cliente una batería reproducible</mark> que pueda ejecutar en cada despliegue. Eso convierte un hallazgo puntual en una regresión permanente, y suele valorarse más que el hallazgo.

> [!warning]+ OpenAI anunció su compra en marzo de 2026
> Anunciada el **9 de marzo de 2026**; a fecha de esta nota **no se ha cerrado** (sujeta a las condiciones habituales). OpenAI se comprometió públicamente a mantener `promptfoo` **open source bajo su licencia actual** y a seguir dando soporte a los clientes existentes, e integrarlo en su plataforma empresarial. Conviene tenerlo presente antes de apoyar un proceso interno del cliente sobre esta herramienta, y volver a comprobarlo cuando la operación se cierre.

# Payloads y corpus

| Recurso | Contenido | Uso |
| - | - | - |
| Probes `dan` de `garak` | Familia DAN completa, mantenida | Baseline automatizado |
| [`ChatGPT_DAN`](https://github.com/0xk1h0/ChatGPT_DAN) | Recopilación comunitaria de prompts DAN | Referencia histórica; muy quemados |
| `JailbreakBench` / `HarmBench` | Benchmarks académicos con conjuntos estandarizados | Medir ASR de forma comparable |
| **`AgentDojo`** | Benchmark de **inyección indirecta contra agentes** con herramientas | El más relevante para agentes; es el que resolvió [[13 - Defensas modernas contra prompt injection\|CaMeL]] |
| Repos de system prompts filtrados | System prompts reales de productos comerciales | Reconocimiento: conocer la *forma* típica acelera el anclaje de payloads |

<mark style="background: #FFB86CA6;">Los corpus públicos sirven de línea base, no de exploit.</mark> Todo lo que lleva un año publicado está en los datasets de entrenamiento adversarial. Su función es medir cuánto ha invertido el objetivo en defensa: si un DAN de 2023 funciona, el modelo está sin actualizar y el resto será fácil.

# Herramientas manuales que no se sustituyen

- **Un proxy.** Para el [[11 - Jailbreaks multi-turno y de contexto#Context Compliance Attack — el que no es un jailbreak|CCA]] no hay herramienta: se intercepta la petición, se añade un turno `assistant` fabricado y se reenvía. Trivial con [[02 - Interceptación de peticiones|Burp]] y no lo hace ningún escáner.
- **`ASCII Smuggler`** (Rehberger) — codifica y decodifica payloads en caracteres Unicode Tag. Imprescindible para [[07 - ASCII smuggling y payloads invisibles]], tanto para atacar como para inspeccionar contenido sospechoso.
- **Un canario propio.** `python3 -m http.server`, `interactsh` o Burp Collaborator para confirmar el canal de exfiltración de [[06 - EchoLeak y la exfiltración zero-click]] sin sacar datos reales.
- **Un modelo local.** `Ollama` con el mismo modelo base que el objetivo. <mark style="background: #8000E1A6;">Es la medida de OPSEC con más impacto de todas: los cientos de intentos fallidos se hacen en local y contra el objetivo solo van los payloads ya validados</mark> — ver [[14 - Detección y evasión en prompt injection]].

# Guardrails que conviene conocer

No para usarlos, sino porque son lo que hay al otro lado y conviene identificarlos por su comportamiento: `Llama Guard` y `Prompt Guard` (Meta), `NeMo Guardrails` (NVIDIA), `Prompt Shields` de Azure AI Content Safety, `Bedrock Guardrails` (AWS), `Model Armor` (Google Cloud), y en el lado abierto `Rebuff` y `Vigil`. Sus tarjetas de modelo y documentación dicen contra qué están entrenados — y por tanto, contra qué **no**.

# Flujo sugerido

1. **Recon manual** con proxy + `LLMmap`: modelo, herramientas conectadas, capa donde vive el guardrail, historial manipulable.
2. **Réplica local** del modelo base si es de pesos abiertos. Todo el desarrollo va aquí.
3. **Barrido con `garak`** (`--spec 'tag:owasp:llm01'`) contra la réplica, o contra producción si el alcance permite ruido.
4. **Ataque dirigido**: manual para CCA y lógica de negocio; `PyRIT` para multi-turno.
5. **Verificación de exfiltración** con canario propio.
6. **Entrega**: hallazgos con [[08 - Fundamentos del jailbreaking#Medir en vez de anecdotar|ASR medido]] + batería `promptfoo` reproducible para el cliente.
