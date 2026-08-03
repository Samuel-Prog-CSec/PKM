---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/LLM
  - Tipo/Arsenal
Descripción: "guardrails-ai como implementación de referencia: validadores del Hub, acciones on_fail y qué revela leer su código fuente sobre lo que realmente hace un guardrail de librería"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - Guardrails basados en IA]]"
Nota siguiente: "[[05 - Servicios gestionados de guardrails]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Muchos casos de uso de guardrail se repiten entre aplicaciones —detección de inyección, lenguaje ofensivo, secretos en la salida—, así que reimplementarlos es tirar tiempo. <mark style="background: #ADCCFFA6;">Las librerías de guardrails aportan implementaciones probadas y, sobre todo, una **línea base legible**: leer su código dice qué hace de verdad un guardrail antes de comprometerse con él.</mark> Las dos referencias son `guardrails-ai` y `deepeval`; aquí se detalla la primera.

# Montaje

```shell-session
$ python3 -m venv ./guardrailvenv && source ./guardrailvenv/bin/activate
$ pip3 install guardrails-ai
$ guardrails configure
```

La configuración pide una clave de API del Hub (gratuita) y ofrece dos opciones que conviene responder conscientemente:

```shell-session
Enable anonymous metrics reporting? [Y/n]: n
Do you wish to use remote inferencing?  [Y/n]: n
```

> [!warning]+ `remote inferencing` significa que el texto sale de la infraestructura
> Aceptarlo hace que los validadores que necesitan un modelo se ejecuten en servidores del proveedor, lo que implica **enviar los prompts de los usuarios y las respuestas del modelo a un tercero**. <mark style="background: #FF5582A6;">En un despliegue con datos regulados, eso convierte al guardrail en un incidente de cumplimiento por sí solo.</mark> Es exactamente el tipo de opción por defecto que hay que revisar en una auditoría: la telemetría anónima y la inferencia remota son cómodas y muy fáciles de dejar activadas sin pensarlo.

Los validadores se instalan de uno en uno desde el Hub:

```shell-session
$ guardrails hub install hub://guardrails/unusual_prompt
$ guardrails hub install hub://guardrails/detect_jailbreak
$ guardrails hub install hub://guardrails/profanity_free
$ guardrails hub install hub://guardrails/secrets_present
$ guardrails hub install hub://guardrails/web_sanitization
```

# Composición de `Guards`

Los validadores se agrupan en objetos `Guard`, uno para entrada y otro para salida:

```python
from guardrails import Guard
from guardrails.hub import (UnusualPrompt, DetectJailbreak, ProfanityFree,
                            SecretsPresent, WebSanitization)

input_guard = Guard().use(UnusualPrompt(llm_callable="openai/gpt-3.5-turbo"), on_fail="exception")
input_guard.use(DetectJailbreak, on_fail="exception")

output_guard = Guard().use(ProfanityFree,    on_fail="exception")
output_guard.use(SecretsPresent,   on_fail="fix")
output_guard.use(WebSanitization,  on_fail="fix")
```

El parámetro `llm_callable` acepta cualquier proveedor soportado por **LiteLLM**, lo que resuelve de paso el endurecimiento de [[03 - Guardrails basados en IA#El argumento de la doble manipulación|usar un modelo de familia distinta]] para el juez: basta cambiar la cadena.

## Las acciones `on_fail`

Es la parte de diseño que decide el comportamiento del sistema:

| Acción | Efecto | Cuándo |
| - | - | - |
| `exception` | Lanza excepción | **Entrada**: parar antes de gastar inferencia |
| `fix` | Intenta corregir la cadena (escapa HTML, enmascara secretos) | **Salida**: cuando el contenido es recuperable |
| `reask` | Pide al modelo que regenere la respuesta | Salida, cuando hay presupuesto de latencia para otra pasada |
| `fix_reask` | Aplica `fix` y revalida | Salida, la más estricta |
| `refrain` | No devuelve nada | Salida, cuando cualquier fuga es inaceptable |
| `filter` | Elimina el valor incorrecto | Solo datos estructurados |
| `noop` | No hace nada | Modo observación: medir falsos positivos antes de activar |
| `custom` | Función propia | Integración con la lógica del producto |

<mark style="background: #8000E1A6;">`noop` es la acción más infravalorada.</mark> Permite desplegar el guardrail en producción **registrando** lo que habría bloqueado sin bloquear nada, y medir la tasa de falsos positivos con tráfico real antes de activarlo. Es la forma correcta de introducir un guardrail nuevo en un sistema vivo, y evita el escenario clásico de activar un filtro un lunes y desactivarlo el martes por las quejas.

`reask` merece un aviso: multiplica la latencia y el coste por token, y sobre un modelo que ya falló una vez no garantiza que la segunda salga bien. Útil para formato; caro y poco fiable para seguridad.

```python
class LLMQuery(BaseModel, validate_assignment=True):
    prompt: str
    response: str = None

    @field_validator("prompt")
    @classmethod
    def validate_prompt(cls, prompt: str) -> str:
        prompt = prompt.strip()
        input_guard.parse(prompt, metadata={"pass_if_invalid": True})
        return prompt

    @field_validator("response")
    @classmethod
    def validate_response(cls, response: str) -> str:
        return output_guard.parse(response).validated_output
```

> [!warning]+ `pass_if_invalid: True` es fail-open
> Ese metadato hace que la validación **deje pasar** la entrada cuando el validador no puede emitir un veredicto (error del modelo juez, respuesta no parseable, `timeout`). Es exactamente el fallo abierto que [[03 - Guardrails basados en IA#El detalle que más importa: fail closed|la nota anterior]] describía, aquí como opción de configuración. Para un guardrail de seguridad, lo correcto es lo contrario. Aparece en el ejemplo del módulo sin comentario alguno.

# Leer el código fuente

Es lo más útil de esta sección, porque desmitifica la librería. Los validadores hacen exactamente lo mismo que se implementaría a mano:

- **`UnusualPrompt`** es un `LLM-as-a-judge` con un prompt escrito a mano — pregunta si la petición es inusual "de una forma que un humano no preguntaría", y espera `yes`/`no`. Mismo patrón de [[03 - Guardrails basados en IA|la nota 03]], con las mismas limitaciones. Y también en su variante **fail-open**: solo falla si la respuesta es exactamente `yes`.
- **`ProfanityFree`** envuelve la librería `profanity-check` (un clasificador clásico, no un LLM), lo que explica que sea rápida.
- **`WebSanitization`** envuelve **`bleach`** — la respuesta correcta al problema de sanear HTML de [[02 - Validación tradicional por caracteres y contenido#Dónde encaja esta capa|la nota 02]], y una buena razón para usar la librería en lugar de la regex casera.

<mark style="background: #FFB86CA6;">La conclusión: una librería de guardrails no es magia, es empaquetado.</mark> Su valor real son tres cosas — implementaciones que ya evitan errores conocidos (`bleach` en vez de regex), una API homogénea para componer validadores, y un vocabulario común de acciones. Lo que **no** aporta es detección que no se pudiera construir; los mismos límites de fondo siguen ahí.

# Qué mirar antes de adoptarla

1. **Leer el validador que se va a usar.** Son 50-100 líneas. Si hace `LLM-as-a-judge` con un prompt genérico, se conoce su precisión de antemano.
2. **Comprobar la política de fallo** de cada validador y de la configuración (`pass_if_invalid`, `on_fail`). Por defecto suele ser permisiva.
3. **Verificar dónde se ejecuta la inferencia** (local o remota) y si hay telemetría activada.
4. **Medir la latencia real** de la combinación concreta, no la de un validador aislado.
5. **Desplegar con `noop` primero** y medir falsos positivos sobre tráfico real.

Cuando la operación prefiere no gestionar nada de esto en su infraestructura, la alternativa es delegarlo en [[05 - Servicios gestionados de guardrails|un servicio gestionado]].
