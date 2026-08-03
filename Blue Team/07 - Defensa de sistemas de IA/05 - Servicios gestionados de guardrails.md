---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/LLM
  - Tipo/Arsenal
Descripción: "Integrar Model Armor como guardrail externo: las seis categorías que detecta, el estado de invocación y por qué hereda la misma debilidad estructural"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Librerías de guardrails]]"
Nota siguiente: "[[06 - Entrenamiento adversarial y el problema min-max]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

La tercera vía, después de implementar a mano y de usar librería, es delegar la validación en un **servicio externo**. Se paga por uso y por latencia de red, y a cambio no hay que mantener modelos, actualizar taxonomías ni provisionar cómputo. `Model Armor` de Google Cloud es el ejemplo del módulo; AWS Bedrock Guardrails y Azure AI Content Safety ocupan el mismo espacio en sus respectivas nubes.

![Diagrama del flujo de Model Armor: el usuario envía el prompt a la aplicación, que lo inspecciona y sanea antes de pasarlo al LLM; la respuesta se inspecciona de nuevo antes de devolverla](https://academy.hackthebox.com/storage/modules/307/diag1.png)

El flujo tiene **dos puntos de inspección**: la aplicación manda el prompt al servicio, recibe una versión saneada, la pasa al LLM, y repite el proceso con la respuesta antes de devolverla al usuario.

# Integración

```shell-session
$ pip install --upgrade google-cloud-modelarmor
```

```python
from google.api_core.client_options import ClientOptions
from google.cloud import modelarmor_v1
from google.cloud.modelarmor_v1.types import FilterMatchState, InvocationResult

MODEL_ARMOR_URL = f"projects/{PROJECT_ID}/locations/{LOCATION}/templates/{TEMPLATE_ID}"
MODEL_ARMOR_CLIENT = modelarmor_v1.ModelArmorClient(
    transport="rest",
    client_options=ClientOptions(api_endpoint=f"modelarmor.{LOCATION}.rep.googleapis.com"))

def model_armor_process_prompt(prompt):
    data = modelarmor_v1.DataItem(text=prompt)
    req  = modelarmor_v1.SanitizeUserPromptRequest(name=MODEL_ARMOR_URL, user_prompt_data=data)
    return MODEL_ARMOR_CLIENT.sanitize_user_prompt(request=req).sanitization_result

def model_armor_process_response(response):
    data = modelarmor_v1.DataItem(text=response)
    req  = modelarmor_v1.SanitizeModelResponseRequest(name=MODEL_ARMOR_URL, model_response_data=data)
    return MODEL_ARMOR_CLIENT.sanitize_model_response(request=req).sanitization_result
```

La **plantilla** (`TEMPLATE_ID`) es donde vive la política: qué categorías se activan y con qué umbral. Es el objeto que hay que pedir y revisar en una auditoría — el código de integración puede ser impecable y la plantilla tener media taxonomía desactivada.

# Las seis categorías

| Categoría | Qué detecta |
| - | - |
| `Responsible AI (RAI)` | Discurso de odio, contenido dañino y peligroso |
| `Sensitive Data Protection (SDP)` | Datos sensibles: tarjetas, identificadores, credenciales |
| `Prompt Injection (PI)` | Inyección de prompt y jailbreaking |
| `Malicious URI` | URLs maliciosas |
| `CSAM` | Material de abuso sexual infantil |
| `Virus Scan` | Contenido con malware |

<mark style="background: #FFB8EBA6;">Esa lista **es** el alcance del servicio.</mark> Lo que no esté ahí no se detecta: desinformación sin ataque a personas, menciones a la competencia, contenido fuera del dominio del producto, alucinaciones. Es el mismo punto que la [[13 - Safeguards en producción (Model Armor y ShieldGemma)|nota ofensiva sobre Model Armor]] desarrolla desde el lado del atacante — y la razón de que un servicio gestionado casi nunca sustituya por completo a los validadores propios, sino que se combine con ellos.

# El patrón de integración correcto

```python
@field_validator("prompt")
@classmethod
def validate_prompt(cls, prompt: str) -> str:
    prompt = prompt.strip()
    sanitization_result = model_armor_process_prompt(prompt)

    # 1) ¿se ejecutó el guardrail?
    if not sanitization_result.invocation_result == InvocationResult.SUCCESS:
        raise GuardrailPromptException("Unable to run guardrail.")

    # 2) ¿encontró algo?
    if sanitization_result.filter_match_state == FilterMatchState.MATCH_FOUND:
        matches = parse_sanitization_result(sanitization_result)
        raise GuardrailPromptException(f"Detected policy Violations: {', '.join(matches)}")

    return prompt
```

<mark style="background: #8000E1A6;">La comprobación 1 es lo mejor de esta sección y falta en casi todas las integraciones reales.</mark> Separa **"el guardrail dijo que está limpio"** de **"el guardrail no llegó a ejecutarse"**. Sin ella, un fallo de red, una cuota agotada, una credencial caducada o una caída del servicio se convierten silenciosamente en tráfico sin filtrar: fallo abierto por indisponibilidad de un tercero. Con ella, el sistema es *fail closed*.

Es también el fallo que hay que buscar al auditar: **provocar un error del servicio** (cuota, latencia, credencial inválida) y observar si la aplicación bloquea o deja pasar.

Y la contrapartida operativa, que hay que decir en voz alta: al hacerlo *fail closed*, **la disponibilidad del guardrail pasa a ser la disponibilidad del producto**. Es una decisión de negocio consciente —degradar o parar—, no un detalle de implementación. La alternativa razonable es un modo degradado explícito: si el servicio externo cae, conmutar a los validadores tradicionales locales, que son peores pero existen.

# La debilidad estructural, otra vez

Model Armor no se integra en el modelo: **la aplicación tiene que llamarlo explícitamente**. Es exactamente el problema descrito en [[01 - Guardrails de entrada y salida#La debilidad estructural|la nota 01]], y usar un servicio gestionado no lo resuelve — lo hace más visible, porque la llamada es un bloque de código identificable que puede faltar en una ruta.

<mark style="background: #FF5582A6;">En un engagement contra un despliegue con Model Armor, buscar la ruta que no lo invoca suele ser más rentable que intentar evadir el clasificador.</mark> Y del lado defensivo, la mitigación es la misma: encapsular la llamada al LLM en un único cliente interno que **siempre** pase por el guardrail, y prohibir por revisión de código las llamadas directas a la API del modelo.

# Cómo se decide entre las tres opciones

| | Implementación propia | [[04 - Librerías de guardrails\|Librería]] | Servicio gestionado |
| - | - | - | - |
| Control sobre la lógica | **Total** | Alto | Bajo (plantilla) |
| Esfuerzo de mantenimiento | Alto | Medio | **Mínimo** |
| Latencia | La que se diseñe | Local | **+ red** |
| Los datos salen de la infraestructura | No | Solo si se activa inferencia remota | **Sí, siempre** |
| Cobertura de casos raros del dominio | **Buena** | Limitada | Nula |
| Actualización frente a ataques nuevos | Manual | Con la librería | **Automática** |

En la práctica el reparto que funciona es híbrido: **servicio gestionado o modelo guardián** para las categorías universales (inyección, contenido dañino, PII), y **validadores propios** para lo específico del negocio, que ningún proveedor puede conocer. <mark style="background: #8000E1A6;">Dicho de otro modo: se externaliza lo que es común a todos los productos y se implementa en casa lo que define al producto</mark> — que es también el reparto que sobrevive a cambiar de proveedor.

> [!important]+ Lo que hay que pedir en una auditoría
> La **plantilla de política** (qué categorías y umbrales), el **inventario de rutas** que invocan al modelo y cuáles pasan por el guardrail, el **comportamiento ante error del servicio**, y si el envío de prompts y respuestas a un tercero está contemplado en el análisis de tratamiento de datos. La última pregunta es la que más veces se queda sin respuesta.
