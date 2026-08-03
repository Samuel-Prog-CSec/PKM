---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Post-Explotacion
Descripción: "Generar el contenido es la mitad del problema para un adversario; la otra es que no lo detecten al distribuirlo"
Fecha de actualización: 2026-07-28
Nota previa: "[[10 - Ataques de abuso y desinformación]]"
Nota siguiente: "[[12 - Mitigación de los ataques de abuso]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

Generar el contenido es la mitad del problema para un adversario; la otra es **que no lo detecten al distribuirlo**. Plataformas y foros despliegan clasificadores de toxicidad, y esos clasificadores son modelos de ML con las debilidades de siempre.

# El objetivo — cómo funciona un detector de discurso de odio

Definición de referencia de las [Naciones Unidas](https://www.un.org/en/hate-speech/understanding-hate-speech/what-is-hate-speech): *cualquier comunicación que ataque o use lenguaje peyorativo o discriminatorio respecto a una persona o grupo por su religión, etnia, nacionalidad, raza, color, ascendencia, género u otro factor identitario*.

Los detectores más usados son `HateXplain` y `Detoxify`. Su funcionamiento es sencillo y explica su fragilidad:

1. Reciben un texto.
2. Devuelven un **`toxicity score`** entre 0 y 1.
3. Si supera un umbral configurado, se clasifica como discurso de odio.

<mark style="background: #FF5582A6;">Dos consecuencias operativas de ese diseño.</mark> La primera: **el umbral es un parámetro, no una verdad** — bajarlo genera falsos positivos, subirlo deja pasar contenido; toda plataforma vive en ese compromiso. La segunda: **cada detector opera sobre una definición distinta** de discurso de odio, así que el mismo texto puede pasar en una plataforma y ser bloqueado en otra. Al evaluar un despliegue, hay que preguntar contra qué definición está calibrado.

# Las tres capas de evasión

Ataques adversariales de NLP clásicos, ordenados por granularidad. Todos comparten la misma lógica: <mark style="background: #8000E1A6;">mover el texto al otro lado de la frontera de decisión del clasificador **sin cambiar lo que un humano entiende**.</mark>

## Nivel de carácter

Se puntúa la importancia de cada token para la clasificación y se perturban los más determinantes. La herramienta de referencia es [`DeepWordBug`](https://github.com/QData/deepWordBug), con cuatro operaciones:

| Operación | Ejemplo |
| - | - |
| `Swap` — intercambiar caracteres adyacentes | `HackTheBox` → `HackhTeBox` |
| `Substitution` — sustituir un carácter | `HackTheBox` → `HackTueBox` |
| `Deletion` — eliminar un carácter | `HackTheBox` → `HackTeBox` |
| `Insertion` — insertar un carácter | `HackTheBox` → `HackTheBoux` |

Funciona porque la palabra perturbada sale del vocabulario del tokenizador y se fragmenta en subtokens que el clasificador nunca vio asociados a toxicidad. **La persona sigue leyendo la palabra sin esfuerzo**; el modelo ve algo distinto.

Es exactamente el mecanismo de [[07 - ASCII smuggling y payloads invisibles#Atacar la tokenización del guardrail|TokenBreak]] y el de la evasión de filtros léxicos de [[06 - Evasión de filtros XSS y ofuscación|XSS]]: atacar la tokenización, no la semántica.

## Nivel de palabra

Sustitución por sinónimos hasta que la clasificación cambia. [`PWWS`](https://github.com/JHL-HUST/PWWS) lo hace de forma voraz, priorizando las palabras con más peso en la decisión. Menos detectable que la perturbación de caracteres —el texto queda perfectamente escrito— y más costosa de calcular.

## Nivel de frase

**Parafrasear el texto completo**, tarea que un LLM hace de forma trivial. Es la más efectiva de las tres y la que peor pinta tiene desde el lado defensivo: no hay artefacto que buscar. El texto está bien escrito, es original y significa lo mismo.

<mark style="background: #FFB86CA6;">Que la evasión más efectiva sea también la más barata —una llamada a un modelo— es el problema de fondo de todo el enfoque basado en clasificadores.</mark>

> [!info]+ Fuente
> Evaluación sistemática de estas tres capas contra detectores de discurso de odio basados en LLM: [arXiv:2501.16750](https://arxiv.org/abs/2501.16750).

# Aplicabilidad más allá del discurso de odio

Las mismas técnicas evaden cualquier clasificador de texto: contenido sexual, contenido peligroso, violaciones de política corporativa, filtros de spam y **guardrails de prompt injection**. La razón es que todos son el mismo objeto matemático.

Ese es el punto que conecta esta nota con el resto del vault: es literalmente el clasificador de spam de [[08 - Límites y evasión de los detectores ML]], con otras etiquetas. Frontera de decisión evadible, sesgo hacia lo visto en entrenamiento, y degradación frente a formulaciones nuevas.

La asimetría estructural: **el defensor tiene que cubrir todas las formas de expresar una intención; el atacante solo necesita una que pase.** El espacio del lenguaje natural es infinito, así que esa carrera no se gana — se encarece.

# Detectar texto generado por IA no funciona

Corolario importante, porque es una mitigación que se propone constantemente y que hay que saber matizar en un informe. Los detectores de "escrito por IA" tienen dos problemas conocidos y bien documentados:

- **Falsos positivos sesgados.** Penalizan sistemáticamente a hablantes no nativos y textos formales o estructurados.
- **Evasión trivial.** Una paráfrasis, un cambio de temperatura o un modelo distinto los derrota.

El [[12 - Mitigación de los ataques de abuso|marcado de agua estadístico]] es más robusto porque no infiere, sino que verifica una señal insertada a propósito — pero solo funciona si **el generador coopera**, y un adversario con un modelo propio simplemente no lo activa.

# Qué significa para el lado defensivo

La conclusión operativa, y lo que debe ir en la recomendación:

- **Validación humana para lo que importa.** Los detectores automáticos sirven para triar volumen, no para decidir. Cualquier evaluación seria de esta familia concluye lo mismo.
- **Detección en capas**: clasificador + señales de comportamiento (cadencia de publicación, antigüedad y reputación de la cuenta, coordinación entre cuentas) + revisión humana selectiva. <mark style="background: #FFB8EBA6;">Las señales de comportamiento son las que peor evade un adversario, porque no dependen del texto</mark> — se ataca el contenido, no el patrón de publicación.
- **Medir el umbral**, no asumirlo. Al auditar un despliegue con detector de contenido, la prueba consiste en aplicar las tres capas de evasión y reportar a partir de qué nivel de perturbación deja de detectar.
- **No presentar el detector como control de seguridad.** Es reducción de ruido, exactamente igual que un [[13 - Defensas modernas contra prompt injection|guardrail de prompt injection]].
