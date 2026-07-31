---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "Los ataques a la app y a la infra de un sistema de IA dejan la misma telemetría que un pentest tradicional, más señales específicas del stack de ML que casi nadie monitoriza"
Fecha de actualización: 2026-07-29
Nota previa: "[[08 - MLflow, del path traversal al RCE]]"
Nota siguiente: "[[10 - Arsenal para ataques a aplicación y sistema]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">Los ataques a la aplicación y a la infraestructura de un sistema de IA dejan la misma telemetría que un pentest tradicional, más un conjunto de señales específicas del stack de ML que casi nadie monitoriza.</mark> Eso corta en las dos direcciones: el defensor tiene más superficie de la que suele vigilar, y el atacante tiene más sitios donde esconderse. Esta nota es el complemento, a nivel de app y sistema, de la [[12 - Detección y evasión en sistemas de IA|detección y evasión general de sistemas de IA]] — que cubre la capa del modelo.

# Qué telemetría deja cada ataque

| Ataque | Señal que deja | Dónde se ve |
| - | - | - |
| [[01 - Model reverse engineering y robo de modelos\|Model extraction]] | Volumen anómalo de consultas, cobertura uniforme del espacio de entrada, uso de `logit_bias`/`logprobs` | Logs de la API, métricas de facturación |
| [[02 - Denial of ML Service y sponge examples\|DoS de ML]] | Latencia por petición muy por encima de la media, ratio tokens/carácter alto, salidas cerca del límite máximo | Métricas de inferencia, APM |
| [[03 - Componentes integrados inseguros\|IDOR / injection en herramientas]] | Argumentos de herramienta que no casan con la identidad de sesión, errores de la base de datos | Logs de invocación de herramientas |
| [[04 - Rogue actions y agencia excesiva\|Rogue actions]] | Acción de escritura/borrado precedida de entrada externa, herramienta de alto privilegio invocada por usuario de bajo privilegio | Log de acciones + log de prompts |
| [[08 - MLflow, del path traversal al RCE\|Traversal en el stack]] | `../`, `%2e%2e`, fragmentos `#` en parámetros de ruta; `4xx` en ráfaga | Logs del servicio, WAF |
| Explotación del stack | Conexiones salientes desde el servidor de inferencia, procesos hijo inesperados | EDR en el host, NetFlow |

## Detecciones que un defensor competente monta

- **Cuotas por tokens y por identidad**, no por peticiones. Es lo que convierte un `model extraction` o un `DoS` en una anomalía visible: 500 consultas cortas de un usuario que normalmente hace 5 largas.
- **Registro de la entrada que precede a cada llamada de herramienta.** Sin esto, una `rogue action` es indistinguible de un uso legítimo. Con esto, la cadena de [[04 - Rogue actions y agencia excesiva|segundo orden]] queda registrada.
- **`Canary tokens` en datos y en descripciones de herramientas.** Un valor único plantado en la base o en un `system prompt`; si aparece en una salida o en una petición saliente, hay exfiltración en curso.
- **EDR en los hosts de inferencia.** El stack de ML corre en servidores que casi nunca tienen EDR porque "solo sirven modelos". Un `curl` saliente o un `sh` hijo del proceso de inferencia es la señal más limpia de RCE.
- **Validación de `Origin` con alerta.** Para el vector de DNS rebinding contra MLflow/servicios locales, registrar y alertar sobre `Origin` no reconocidos.

# Cómo se evade

El principio general —trabajar fuera del objetivo, usar canales que no dejan rastro en el log de prompts— está en [[12 - Detección y evasión en sistemas de IA#Cómo se evade|la nota general]]. Aquí, lo específico de esta capa.

## Model extraction bajo el radar

<mark style="background: #FFB86CA6;">La detección de extracción se basa en volumen y en cobertura anómala del espacio de entrada.</mark> Se evade:

- **Distribuyendo** las consultas entre muchas cuentas e IPs, por debajo del umbral de `rate limiting` de cada una. Es la razón por la que el `rate limit` por sí solo no basta.
- **Imitando la distribución legítima** — muestrear cerca de donde muestrean los usuarios reales en lugar de uniformemente. El *active learning* ayuda aquí doblemente: reduce las consultas necesarias **y** las concentra donde el tráfico legítimo también se concentra.
- **Espaciando en el tiempo** para diluir la señal de volumen por debajo de las ventanas de agregación del SIEM.

## Explotación del stack sin encender el EDR

Una vez con RCE en un host de inferencia, la evasión es la de post-explotación clásica, con un matiz a favor del atacante: estos hosts tienen **Python, `curl`, `git` y librerías de red por diseño**, así que el `living-off-the-land` es trivial. No hace falta subir un binario: todo lo necesario ya está instalado. La contrapartida es que la carga de trabajo de un servidor de inferencia es muy predecible (uso de GPU constante, mismos procesos), así que **cualquier proceso nuevo destaca** si hay EDR — de ahí que la evasión real sea confundirse con el propio runtime de ML (ejecutar dentro del intérprete de Python que ya corre, no lanzar procesos nuevos).

## DoS que parece uso legítimo

El `DoS` de ML ya es sigiloso por naturaleza: pocas peticiones, bien formadas, autenticadas. Para hacerlo aún más difícil de atribuir:

- **Vector indirecto** ([[04 - Rogue actions y agencia excesiva|OverThink]]): el señuelo va en contenido que la víctima recupera, así que las peticiones caras salen de usuarios legítimos, no del atacante.
- **Payloads dentro del rango normal de tamaño**, apoyándose en la ratio tokens/carácter en vez de en la longitud, para no disparar los límites de tamaño de entrada.

> [!warning]+ La asimetría que define esta capa
> El defensor de un sistema de IA suele venir del lado de ML, no de seguridad, y monitoriza *calidad del modelo* —deriva, precisión, latencia media—, no *seguridad*. Los logs de invocación de herramientas, la telemetría por identidad y el EDR en hosts de inferencia son justo lo que falta en la mayoría de despliegues. <mark style="background: #FF5582A6;">En un engagement, la ausencia de esa telemetría es en sí misma un hallazgo</mark>: no es solo que el ataque funcione, es que **nadie lo vería**. Eso se reporta como deficiencia de detección y respuesta, y suele tener más recorrido con el cliente que la vulnerabilidad concreta.

# Fuentes

> [!info]+ Referencias
> - `MITRE ATLAS` — matriz de técnicas para las TTPs de esta capa: `AML.T0024` (*Exfiltration via ML Inference API*), `AML.T0018` (*Backdoor ML Model*), `AML.T0011` (*User Execution*). Ver [[05 - MITRE ATLAS y NIST AI RMF]].
> - `OWASP Top 10 for Agentic Applications 2026` — `ASI09` (Human-Agent Trust Exploitation) y `ASI10` (Rogue Agents) para el modelo de detección de agentes.
> - Wiz, Oligo Security y Koi Security — investigación reciente sobre exposición e incidentes del stack de ML, citada en las notas de técnica de este sub-tema.
