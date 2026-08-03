---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Deteccion
Descripción: "El MIA es casi indetectable porque sus consultas son indistinguibles del tráfico legítimo; qué señales quedan y qué defensas de salida aguantan o se evaden"
Fecha de actualización: 2026-07-29
Nota previa: "[[09 - El modelo estudiante, consenso y agregación confiada]]"
Nota siguiente: "[[11 - Arsenal para auditoría de privacidad]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

<mark style="background: #ADCCFFA6;">La inferencia de pertenencia es probablemente el ataque menos detectable del catálogo de IA ofensiva.</mark> No hay `payload`, ni entrada malformada, ni patrón de sondeo llamativo: el atacante envía un registro perfectamente normal y recibe una predicción perfectamente normal. La asimetría es total — el trabajo caro (entrenar modelos sombra o de referencia) ocurre **offline**, sin tocar el objetivo, y contra el objetivo se gasta **una consulta por individuo**.

Comparado con sus vecinos —el panorama general de telemetría y detección en sistemas de IA está en [[12 - Detección y evasión en sistemas de IA|la nota transversal de fundamentos]]—:

| Ataque | Consultas al objetivo | Forma del tráfico | Detectabilidad |
| - | - | - | - |
| [[01 - Model reverse engineering y robo de modelos\|Robo de modelo]] | Decenas de miles | Barrido sistemático del espacio de entrada | **Alta** |
| [[03 - GoodWords en caja negra con bandits\|Evasión de caja negra]] | Cientos-miles por muestra | Variantes sistemáticas de una misma entrada base | **Media-alta** |
| **MIA (shadow / LiRA / RMIA)** | **1 por objetivo** | Registros normales | **Muy baja** |
| Extracción en LLM | Decenas-cientos | Prompts inusuales, repetitivos | Media |

# Las señales que sí quedan

Que sea difícil no significa que sea imposible. Hay tres indicios que un defensor con telemetría decente puede explotar:

**1. Registros "demasiado exactos".** Es el más útil y el que nadie mira. Para probar pertenencia, el atacante debe enviar el registro **tal cual estaría en el conjunto de entrenamiento** — valores exactos, todos los campos rellenos, sin el ruido, los redondeos ni los valores por defecto del tráfico real. <mark style="background: #FF5582A6;">El tráfico legítimo de inferencia rara vez consiste en filas que parecen extraídas de una base de datos.</mark> Un detector que compare la distribución de las consultas entrantes con la del tráfico histórico (completitud de campos, granularidad de los decimales, presencia de combinaciones improbables) marca esa desviación.

**2. Conocimiento de la etiqueta verdadera.** Casi todas las variantes de `MIA` necesitan la etiqueta real de la muestra objetivo. Si el endpoint expone alguna forma de *feedback* o de verificación de etiqueta, su uso conjunto con consultas de inferencia es una combinación anómala.

**3. Consultas sobre individuos concretos y conocidos.** Si el sistema puede correlacionar la consulta con registros reales de su propia base (mismo DNI, mismo identificador de paciente), un patrón de consultas que coincide **exactamente** con filas propias es una señal fortísima. Requiere que el defensor pueda hacer esa correlación, lo que no siempre es posible ni legal.

> [!important]+ Los canarios son la contramedida más práctica
> Insertar deliberadamente **registros canario** en el conjunto de entrenamiento —artificiales, únicos, inexistentes en el mundo real— y monitorizar si el modelo los memoriza o si alguien consulta por ellos. Sirve para dos cosas a la vez: **medir** cuánta memorización hay (la metodología del *secret sharer* de Carlini et al., [arXiv:1802.08232](https://arxiv.org/abs/1802.08232), que cuantifica la exposición de una secuencia insertada) y **detectar** que alguien con acceso indebido a los datos está probando pertenencia. Es de las pocas técnicas que funcionan sin poder distinguir el tráfico atacante del legítimo.

# Defensas del lado de la salida, y cómo se evaden

El vector principal del `MIA` es el vector de confianza. De ahí la tentación de recortarlo:

| Defensa | Cómo se evade |
| - | - |
| **Devolver solo la etiqueta** (sin `softmax`) | Existe una familia entera de **ataques label-only**: se estima la distancia a la frontera de decisión perturbando la entrada hasta que la etiqueta cambia, y esa distancia es mayor para los miembros. Cuesta muchas más consultas, lo que **sí** vuelve al ataque detectable, pero no lo cierra ([Choquette-Choo et al., ICML 2021](https://arxiv.org/abs/2007.14321)) |
| **Redondear / cuantizar las probabilidades** | Reduce la resolución de la señal y encarece el ataque; se compensa con más muestras. Mitigación parcial, no cierre |
| **Temperatura alta en el `softmax`** | Aplana las confianzas; los ataques basados en pérdida o en distancia a la frontera siguen funcionando |
| **`Rate limiting` por identidad** | Poco efectivo: el `MIA` necesita **una consulta por objetivo**. Solo estorba a los ataques label-only |
| **Ruido aleatorio en la salida** | Evadible promediando varias consultas de la misma entrada, salvo que el ruido sea determinista por entrada |

<mark style="background: #8000E1A6;">El patrón se repite: todas las defensas de salida **encarecen** el ataque, ninguna lo elimina.</mark> La única barrera con garantía es acotar la influencia de cada muestra en los parámetros — es decir, [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|privacidad diferencial]] — o impedir que el modelo desplegado vea los datos, que es [[08 - PATE, ensemble de profesores y agregación con ruido|PATE]].

> [!warning]+ "Solo devolvemos la etiqueta, no las probabilidades"
> Es la respuesta más frecuente de un cliente cuando se le plantea el riesgo, y suena razonable. Conviene tener la réplica preparada: los ataques label-only demuestran que **la etiqueta sola basta**, porque la información de pertenencia está en la geometría de la frontera de decisión, no solo en la confianza. Lo que sí consigue esa defensa es un beneficio colateral real: al obligar al atacante a hacer decenas o cientos de consultas por objetivo, **convierte un ataque indetectable en uno detectable**. Eso es valioso, pero hay que venderlo como lo que es —una mejora de detectabilidad— y no como una mitigación.

# Del lado ofensivo: cómo se mantiene el sigilo

En un engagement autorizado donde el sigilo forma parte del alcance:

- **Un ataque de umbral o basado en pérdida no necesita nada más que la consulta legítima.** No hay nada que ocultar; es el caso base y ya es indetectable.
- **Con ataques label-only**, que sí generan volumen, aplican las técnicas habituales: repartir entre identidades, espaciar en el tiempo, mezclar con consultas de relleno realistas.
- **No enviar registros crudos.** Es el error que delata: perturbaciones mínimas en campos irrelevantes para el modelo hacen la consulta indistinguible del tráfico real sin cambiar la señal de pertenencia. Es la contramedida directa contra la señal 1.
- **Entrenar los modelos sombra o de referencia offline**, con datos propios de la misma distribución. Nunca sale tráfico hacia el objetivo durante esa fase, que es el 99 % del coste del ataque.

# Qué se recomienda al defensor

Ordenado por relación coste/beneficio:

1. **Medir primero.** Antes de defender, cuantificar: ¿cuál es el `TPR@0.1%FPR` sobre el modelo actual? Sin esa cifra, cualquier inversión es a ciegas.
2. **Regularizar y limitar el sobreajuste.** `Early stopping`, `dropout`, `weight decay`. Barato, reduce la señal, no garantiza nada.
3. **Deduplicar el conjunto de entrenamiento.** Los duplicados son el principal motor de memorización, y su eliminación mejora también la utilidad. Es la medida con mejor relación coste/beneficio de la lista.
4. **Reducir la información de salida** al mínimo que el producto necesite, asumiendo que es una mejora de detectabilidad más que una mitigación.
5. **Canarios** para medir memorización de forma continua.
6. **Privacidad diferencial** cuando haya requisito regulatorio o los datos sean genuinamente sensibles. Es lo único con garantía, y hoy con *fine-tuning* sobre modelo preentrenado el coste de utilidad es mucho menor de lo que sugiere [[07 - El compromiso privacidad-utilidad de DP-SGD|la demostración del módulo]].

<mark style="background: #FFB86CA6;">El hallazgo que se reporta no suele ser "el modelo filtra pertenencia" —casi todos lo hacen en algún grado— sino la combinación de tres cosas: cuánto filtra medido con la métrica correcta, **qué subpoblaciones** son las expuestas, y que el propietario **no tiene forma de saber que está ocurriendo**.</mark> Esa última parte es lo que convierte un riesgo teórico en un problema de cumplimiento.
