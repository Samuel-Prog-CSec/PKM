---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/LLM
  - Tipo/Defensa
Descripción: "Qué valida un guardrail de entrada y qué uno de salida, el bucle de realimentación que forman, y los dos costes que deciden si el diseño es viable: latencia y falsos positivos"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Defensa en profundidad para sistemas de IA]]"
Nota siguiente: "[[02 - Validación tradicional por caracteres y contenido]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

<mark style="background: #ADCCFFA6;">Un guardrail es un validador que se interpone entre el usuario y el modelo, en una dirección o en las dos.</mark> No forma parte del modelo: es código de la aplicación, y eso tiene una consecuencia de diseño que decide la mayoría de los engagements — se puede saltar.

![Diagrama de guardrail de entrada filtrando PII, contenido fuera de tema e intentos de jailbreak; la aplicación LLM procesa el prompt; el guardrail de salida filtra alucinaciones, lenguaje ofensivo y menciones a la competencia](https://academy.hackthebox.com/storage/modules/322/diagram.png)

# Guardrails de entrada

Operan sobre el prompt del usuario **antes** de que llegue al modelo. Sus usos:

- **Bloquear vectores de ataque** — [[01 - Prompt injection y por qué no tiene parche|prompt injection]] y [[08 - Fundamentos del jailbreaking|jailbreaking]].
- **Detectar consultas dañinas o contra política** — peticiones de contenido ilegal, temas fuera del dominio del producto.
- **Imponer restricciones sintácticas o semánticas** — rechazar entradas sin la información necesaria (¿trae la URL que hace falta?, ¿es SQL válido?), verificar idioma.
- **Preprocesar** — normalizar la entrada al dominio o idioma esperado por el modelo reduce la probabilidad de comportamientos raros.

El de "información suficiente" merece mención aparte porque no es de seguridad: rechazar entradas incompletas **ahorra tiempo de proceso** e inferencia. En sistemas con coste por token es una optimización con efecto directo en factura.

# Guardrails de salida

Se aplican a la respuesta ya generada:

- **Filtrado de contenido y moderación** — contenido dañino, lenguaje ofensivo.
- **Desinformación y alucinaciones** — con las limitaciones evidentes de detectar algo que el modelo emite con total confianza.
- **Política de empresa** — menciones a la competencia, afirmaciones que comprometan legalmente.
- **Fuga de datos** — información sensible, credenciales, PII, evidencia de una inyección que funcionó.
- **Saneamiento** — eliminar HTML antes de renderizar la respuesta, que es la mitigación directa de [[01 - XSS desde la salida del modelo|XSS desde la salida del modelo]].

<mark style="background: #8000E1A6;">Combinados forman un bucle de realimentación:</mark> el guardrail de salida detecta lo que el de entrada dejó pasar, y los patrones que aparecen en la salida alimentan las reglas de entrada. Es lo que convierte dos filtros independientes en un sistema que mejora con el uso — siempre que alguien mire los registros, que es la parte que suele faltar.

# La debilidad estructural

Que el guardrail sea código de la aplicación significa que <mark style="background: #FF5582A6;">cualquier ruta de código que no lo invoque queda sin protección.</mark> Es la observación más rentable en un engagement contra un despliegue con guardrails, y aplica igual a implementación propia que a [[05 - Servicios gestionados de guardrails|servicio gestionado]]:

- Endpoints antiguos o internos que llaman al modelo directamente.
- Flujos de *streaming* donde la respuesta se emite token a token y el guardrail de salida —que necesita el texto completo— no se aplica o se aplica tarde.
- Llamadas entre servicios que asumen que el llamante ya validó.
- Herramientas invocadas por un agente, que producen y consumen texto sin pasar por el guardrail de la interfaz de usuario.
- Rutas de error y *fallback* que devuelven la salida cruda.

Buscar la ruta no cubierta suele ser más rentable que intentar evadir el clasificador. Y del lado defensivo, la conclusión es que **el guardrail debe estar en el punto más cercano posible al modelo** —idealmente en un envoltorio del cliente del LLM, no en el controlador de la API pública—, para que ninguna ruta lo pueda esquivar por olvido.

# Los dos costes

**Latencia.** Cada guardrail añade tiempo, y el de entrada y el de salida se suman al camino crítico. Medido sobre la misma carga en el laboratorio del módulo:

| Implementación | Entrada | Salida | Total |
| - | - | - | - |
| Tradicional (regex, listas) | 0,0949 s | 0,0014 s | ~0,1 s |
| Basada en IA (LLM-as-a-judge) | 0,8180 s | 0,7706 s | **~1,6 s** |

Un orden de magnitud largo, **y con menos validadores en la versión de IA**. En una aplicación donde la latencia percibida ya es la queja principal, apilar guardrails de IA es una decisión de producto tanto como de seguridad. La vía intermedia —[[03 - Guardrails basados en IA|modelos más pequeños o clasificadores clásicos]]— recupera casi todo el tiempo a cambio de precisión.

**Falsos positivos.** <mark style="background: #FFB86CA6;">Un guardrail demasiado restrictivo rechaza entradas legítimas, genera frustración y estrangula la creatividad del modelo.</mark> No es un problema menor de UX: es la razón habitual de que un guardrail acabe desactivado en producción. El caso canónico —el filtro de palabras ofensivas que marca cualquier respuesta con la palabra *spoon* porque *poon* está en la lista— resume el problema de las listas negras sin contexto.

> [!important]+ No hay configuración por defecto que valga
> Encontrar el equilibrio exige **iteración y pruebas en el dominio concreto**. Un guardrail calibrado para un asistente de cocina no sirve para uno médico ni para uno de soporte técnico: lo que en uno es contenido peligroso, en otro es la consulta legítima que justifica el producto. Cualquier proveedor que venda "guardrails listos para usar" sin fase de calibración está vendiendo falsos positivos o falsos negativos, y normalmente los dos.

# Cómo se decide qué poner

Un orden de trabajo que funciona:

1. **Enumerar qué es inaceptable** para este producto concreto, entrada y salida. Sin esa lista no hay forma de saber si un guardrail sobra o falta.
2. **Resolver con lo barato lo que se pueda** — sintaxis, listas, expresiones regulares, detección de PII. Latencia despreciable ([[02 - Validación tradicional por caracteres y contenido|nota 02]]).
3. **Reservar la IA para lo que necesita contexto** — detección de inyección, jailbreak, toxicidad ([[03 - Guardrails basados en IA|nota 03]]).
4. **Usar librería o servicio antes que implementación propia** en los casos comunes ([[04 - Librerías de guardrails|nota 04]], [[05 - Servicios gestionados de guardrails|nota 05]]).
5. **Medir latencia y falsos positivos con tráfico real**, no con casos de prueba.
6. **Cerrar las rutas que no pasan por el guardrail** — el punto anterior sobre la debilidad estructural.

Y una asunción que conviene hacer explícita desde el principio: <mark style="background: #FFB8EBA6;">ningún guardrail es un control, todos son un sesgo estadístico.</mark> Elevan el coste del ataque; no lo cierran. El diseño del sistema tiene que sobrevivir a que el guardrail falle — cosa que hará.
