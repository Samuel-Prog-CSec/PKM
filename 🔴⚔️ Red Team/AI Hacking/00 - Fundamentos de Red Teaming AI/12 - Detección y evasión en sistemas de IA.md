---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "Un despliegue maduro registra mucho más de lo que el atacante suele suponer"
Fecha de actualización: 2026-07-28
Nota previa: "[[11 - Superficie de ataque por familia de modelos]]"
Nota siguiente: "[[13 - Arsenal de herramientas para red teaming de IA]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

> [!info]+ Nota añadida al temario
> Eje de detección y evasión del vault aplicado a sistemas de IA. HTB describe los ataques y no dice **qué rastro dejan** ni **cómo se evita ese rastro**, que es exactamente lo que separa una prueba de laboratorio de un red team con requisito de sigilo.

> [!info]+ Nota relacionada
> Esta nota cubre la telemetría y la evasión **generales** de un sistema de IA. Lo específico de prompt injection —dónde se guarda el log de una app LLM, reglas de detección concretas, mapeo a MITRE ATLAS y OPSEC de la inyección indirecta— está en [[14 - Detección y evasión en prompt injection]].

# Qué telemetría deja atacar un sistema de IA

Un despliegue maduro registra mucho más de lo que el atacante suele suponer. Antes de lanzar nada, conviene saber qué se está encendiendo.

| Señal | Qué delata |
| - | - |
| Registro de prompts y respuestas | **Todo**. Es el equivalente al log de peticiones HTTP, y suele retenerse largo tiempo |
| Activaciones del `guardrail` | Cada intento bloqueado es un evento. Una ráfaga de rechazos es la firma de un `jailbreak` en desarrollo |
| Tasa de rechazo por usuario o sesión | Un usuario legítimo raramente provoca rechazos; uno probando payloads los provoca constantemente |
| Volumen y patrón de consultas | La **extracción** tiene firma propia: consultas sistemáticas que barren el espacio de entrada, sin la variabilidad del uso humano |
| Perplejidad de la entrada | Los sufijos adversariales generados por gradiente son cadenas sin sentido: perplejidad anómala respecto al tráfico normal |
| Llamadas a herramientas | Una secuencia de invocaciones inusual o un parámetro fuera de lo habitual es señal directa de inyección con éxito |
| URLs salientes en la respuesta | Una imagen o enlace a un dominio externo en la salida es el patrón de la exfiltración por renderizado |
| Consumo y latencia | Picos de coste o de tiempo de generación revelan tanto DoS como consultas masivas de extracción |
| Longitud y forma del contexto | Entradas anormalmente largas apuntan a saturación de contexto o a inyección de documentos |

<mark style="background: #FF5582A6;">La señal más barata y más eficaz para el defensor es la tasa de rechazo por identidad.</mark> Desarrollar un `jailbreak` requiere decenas o cientos de intentos fallidos, y cada uno es una anotación. Frente a esto, el atacante que trabaja contra producción es ruidoso por naturaleza.

## Detecciones específicas que un defensor competente monta

- **Tokens canario en el prompt de sistema.** Una cadena única e improbable dentro del `system prompt`. Si aparece en cualquier salida, el prompt se ha filtrado — detección de `LLM07` con coste cero y prácticamente sin falsos positivos, ya que un modelo no reproduce por azar una cadena aleatoria que no ha visto. <mark style="background: #FFB86CA6;">Detecta la fuga por generación, no la fuga por canal lateral</mark>: la extracción por temporización descrita abajo no imprime nada, así que el canario no se entera.
- **Documentos canario en el índice RAG.** Documentos señuelo que nadie debería recuperar en uso normal. Su aparición en un contexto indica exploración del índice.
- **Pruebas canario tras cada reentrenamiento.** Un conjunto fijo de entradas con salida esperada, verificado automáticamente después de cada ciclo. <mark style="background: #FFB8EBA6;">Es la única defensa práctica contra el envenenamiento dirigido</mark>, porque las métricas globales no lo detectan — demostrado en [[02 - Manipulación del modelo]].
- **Marcas de agua o `honeytokens` en los datos de entrenamiento.** Si aparecen en la salida de otro modelo, hubo destilación o robo.
- **Correlación entre identidad y volumen.** Límites por cuenta, por IP y por clave de API, con alerta ante distribución sospechosa.

# Cómo se evade

## Trabajar fuera del objetivo

<mark style="background: #8000E1A6;">La medida de evasión con más impacto no es un truco de payload: es no desarrollar contra producción.</mark>

Si el modelo base es de pesos abiertos, se monta local y ahí se hacen los cientos de intentos. Contra el objetivo solo van los payloads ya validados, reduciendo el volumen de dos o tres órdenes de magnitud y llevando la tasa de rechazo a valores indistinguibles del ruido. Detalle en [[06 - Red teaming de IA generativa]].

## Canales que no dejan rastro en el log de prompts

Toda la telemetría de la tabla anterior observa **contenido**: qué se pidió y qué se respondió. <mark style="background: #FF5582A6;">Hay extracción que no genera contenido que registrar.</mark>

El caso principal es el **canal lateral de temporización sobre el `prompt caching`**, desarrollado en [[04 - Transformers y el mecanismo de atención]]: se mide el tiempo hasta el primer token para deducir si un prefijo estaba ya en caché, y con eso se reconstruye el `system prompt` —o prompts de otros usuarios— token a token.

Desde el punto de vista del defensor, las peticiones son inocuas: no hay payload, no hay rechazo, no se dispara ningún `guardrail`, y el canario del prompt de sistema nunca aparece porque el modelo no llega a imprimirlo. Lo único anómalo es **el patrón**: muchas peticiones cortas con prefijos casi idénticos y variaciones mínimas al final.

Se detecta correlacionando peticiones por similitud de prefijo y por cadencia, no analizando su contenido — y es justamente el tipo de detección que casi ningún despliegue tiene montada.

## Contra la detección basada en firmas

Los `guardrails` de entrada suelen ser clasificadores entrenados sobre `jailbreaks` conocidos. Se evaden como cualquier clasificador:

- **Paráfrasis semántica** — mismo objetivo, formulación completamente distinta. Rompe la coincidencia léxica sin cambiar la intención.
- **Ofuscación de la entrada** — codificaciones, idiomas poco representados, sustitución de caracteres. Atacan la tokenización antes de que el clasificador vea el texto — mismo mecanismo que en [[02 - Preprocesamiento de texto y extracción de features]].
- **Fragmentación multi-turno** — repartir la petición en varios turnos individualmente inocuos. El filtro evalúa turno a turno; el modelo integra el contexto completo.
- **Inyección indirecta** — el payload viaja en un documento, no en el prompt. <mark style="background: #FFB86CA6;">El filtro de entrada del usuario nunca lo ve</mark>, porque el usuario no escribió nada malicioso.

## Contra la detección por volumen y patrón

- **Ritmo bajo y sostenido**, mezclado con consultas legítimas plausibles.
- **Distribución** entre cuentas, claves e IPs cuando el alcance lo permita.
- **Variabilidad** en la formulación: la extracción sistemática se detecta por su regularidad, no por su volumen absoluto.

## Contra la detección por perplejidad

Los sufijos adversariales generados por gradiente son detectables precisamente por parecer basura. Las variantes que optimizan con una restricción de **legibilidad** —el payload debe seguir siendo texto natural— pagan algo de eficacia a cambio de no destacar. Es el mismo compromiso `L0`/`L∞` de siempre: perturbación grande y localizada frente a perturbación distribuida e imperceptible.

# Por qué los guardrails no cierran el problema

Conviene tenerlo claro para no vender una mitigación que no lo es.

<mark style="background: #FF5582A6;">Un `guardrail` es un modelo, y por tanto hereda todas las debilidades de un modelo.</mark> Un clasificador de entrada que decide si un prompt es malicioso es exactamente el clasificador de spam de [[08 - Límites y evasión de los detectores ML]], con las mismas propiedades: frontera de decisión evadible, sesgo hacia lo visto en entrenamiento, y degradación frente a formulaciones nuevas.

La asimetría es estructural: el defensor tiene que cubrir todas las formulaciones posibles de una intención; el atacante solo necesita una que funcione. Y como el espacio del lenguaje natural es infinito, esa carrera no se gana.

Eso **no** significa que los `guardrails` no sirvan. Suben el coste, filtran el ataque oportunista y generan la telemetría de la que vive la detección. Lo que no hacen es garantizar nada, y un informe que recomiende "añadir un filtro de prompts" como mitigación de `prompt injection` está prometiendo algo que no se cumple.

> [!important]+ Dónde sí se corta el impacto
> Todas las defensas efectivas asumen que la inyección **va a ocurrir** y actúan después:
> - **Mínimo privilegio en las herramientas** — que el modelo pueda hacer poco limita lo que consigue el atacante.
> - **Validación de la salida en el consumidor** — tratar la respuesta como entrada no confiable, según [[09 - Ataques a los componentes de aplicación]].
> - **Aprobación humana en acciones irreversibles**, fuera del canal que el modelo controla.
> - **Aislamiento del contenido no confiable** — que lo recuperado por RAG no comparta privilegio con las instrucciones del operador.
> - **Autorización antes de la recuperación**, no después.
>
> <mark style="background: #FFB8EBA6;">La recomendación correcta no es "impide la inyección" sino "haz que una inyección exitosa no consiga nada".</mark>

## Fuentes

- Nota net-new: no forma parte del temario de HTB Academy. Materializa el eje de detección y evasión del vault.
- Las técnicas de evasión de clasificadores se apoyan en [[08 - Límites y evasión de los detectores ML]] y en la taxonomía GenAI del [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final).
