---
tags:
  - IA
  - IA/Deep-Learning
Descripción: "Las Recurrent Neural Networks (RNN) procesan datos secuenciales manteniendo un estado oculto que actúa como memoria de lo ya visto"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Redes neuronales convolucionales (CNN)]]"
Nota siguiente: "[[04 - Transformers y el mecanismo de atención]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Las `Recurrent Neural Networks` (RNN) procesan datos secuenciales manteniendo un estado oculto que actúa como memoria de lo ya visto.</mark> A diferencia de una red `feedforward`, que procesa cada entrada de forma independiente, una RNN tiene conexiones que devuelven información al propio bucle: en cada paso combina la entrada actual con el resumen de todo lo anterior.

> [!warning]+ Contexto de 2026: son legado en lenguaje
> Las RNN dominaron el procesamiento de secuencias entre 2014 y 2017, y hoy están **desplazadas por los `transformers`** en NLP. Se estudian por dos razones: porque explican qué problema resolvieron los transformers —y sin eso el mecanismo de atención parece arbitrario—, y porque siguen siendo competitivas donde su debilidad no importa: series temporales, inferencia en dispositivos con memoria muy limitada y flujos de eventos donde el contexto relevante es corto.

# Cómo procesa una secuencia

En cada paso temporal el módulo recibe dos entradas —el elemento actual de la secuencia y el estado oculto del paso anterior— y produce dos salidas —una predicción y el estado oculto actualizado.

Procesando "The cat sat on the mat":

1. Estado oculto inicial, normalmente a cero.
2. Procesa "The" y actualiza el estado.
3. Procesa "cat" considerando la palabra y el estado que ya contiene información de "The".
4. Continúa acumulando contexto palabra a palabra.

Al llegar a "mat", el estado oculto resume toda la frase precedente. <mark style="background: #FFB8EBA6;">Ese resumen es un vector de tamaño fijo</mark>, y ahí está el cuello de botella: toda la historia, por larga que sea, tiene que caber en el mismo número de dimensiones.

# El gradiente evanescente, otra vez

El entrenamiento usa `backpropagation through time` (BPTT): se despliega la red a lo largo de los pasos temporales y se propaga el error hacia atrás por toda la cadena.

<mark style="background: #8000E1A6;">Como el gradiente se multiplica una vez por cada paso temporal, si esos factores son menores que 1 el producto decae exponencialmente.</mark> En una secuencia de 100 elementos, el gradiente que llega al primero es prácticamente cero: la red **no puede aprender dependencias largas**. Es el mismo fenómeno descrito en [[01 - Redes neuronales]], pero agravado porque la profundidad efectiva es la longitud de la secuencia.

## LSTM y GRU

Ambas arquitecturas atacan el problema con **puertas**: mecanismos aprendidos que regulan qué información entra, se conserva y sale.

**`LSTM`** (Long Short-Term Memory) añade una celda de memoria con tres puertas:

| Puerta | Función |
| - | - |
| Entrada | Cuánta información nueva se incorpora a la celda |
| Olvido | Cuánto del contenido existente se conserva o se descarta |
| Salida | Qué parte de la celda se expone al siguiente paso |

La clave es que la celda de memoria tiene una ruta **aditiva** por la que el gradiente circula sin multiplicarse repetidamente — esa es la razón técnica de que funcione.

**`GRU`** simplifica a dos puertas (actualización y reinicio), fusionando la celda con el estado oculto. Rinde de forma comparable a `LSTM` en la mayoría de tareas con menos parámetros y menos cómputo.

## RNN bidireccionales

Cuando la secuencia completa está disponible de antemano, se pueden ejecutar dos RNN en paralelo —una hacia delante y otra hacia atrás— y combinar sus estados. Cada elemento se interpreta entonces con contexto anterior y posterior. Es útil en clasificación de texto o etiquetado, e imposible en generación en tiempo real, donde el futuro no existe todavía.

# Por qué perdieron

Tres limitaciones, y las tres las resuelve la atención:

- **No paralelizan.** El paso `t` necesita el resultado del paso `t−1`, así que el entrenamiento es intrínsecamente secuencial. Con secuencias largas y GPUs masivas, eso es fatal.
- **Contexto limitado en la práctica.** `LSTM` mitiga el gradiente evanescente pero no lo elimina; la dependencia útil rara vez pasa de unos cientos de elementos.
- **Cuello de botella del estado fijo.** Comprimir una secuencia arbitrariamente larga en un vector de tamaño constante pierde información inevitablemente.

# Dónde siguen importando en seguridad

Los modelos de secuencia se usan para detectar comportamiento anómalo en **secuencias de eventos**: llamadas al sistema de un proceso, secuencias de comandos en una sesión, orden de peticiones en una API. La premisa es que un proceso legítimo genera secuencias con estructura predecible y un exploit rompe ese patrón.

<mark style="background: #FFB86CA6;">Y es evadible con la misma técnica que los detectores de secuencia clásicos: el ataque de mimetismo.</mark> Consiste en intercalar entre las llamadas maliciosas suficientes llamadas inocuas —o sin efecto— para que la secuencia resultante se parezca a una legítima. El trabajo fundacional es [Wagner & Soto, *Mimicry Attacks on Host-Based Intrusion Detection Systems* (ACM CCS 2002)](https://dl.acm.org/doi/10.1145/586110.586145), que construyó secuencias de llamadas al sistema semánticamente equivalentes al exploit pero estadísticamente indistinguibles del comportamiento normal.

<mark style="background: #FF5582A6;">Veinticuatro años después, la lección se mantiene</mark>: si el detector solo observa la secuencia y no la semántica, existe casi siempre una secuencia equivalente que pasa. Cambiar la RNN por un transformer sube el listón, no cambia la naturaleza del problema. Ver [[11 - Detección de anomalías]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con el encuadre de obsolescencia frente a `transformers`, el motivo técnico de que las puertas funcionen y la aplicación a detección de secuencias, ausentes en el original.
- [Wagner & Soto, *Mimicry Attacks on Host-Based Intrusion Detection Systems*, ACM CCS 2002](https://dl.acm.org/doi/10.1145/586110.586145) — evasión de detectores basados en secuencias (consultado 2026-07-28).
