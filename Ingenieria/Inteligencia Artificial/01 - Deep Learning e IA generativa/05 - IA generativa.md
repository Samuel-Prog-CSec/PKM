---
tags:
  - IA
  - IA/Generativa
Descripción: "Un modelo generativo aprende la distribución de los datos de entrenamiento y sabe producir muestras nuevas que provienen de esa misma distribución"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Transformers y el mecanismo de atención]]"
Nota siguiente: "[[06 - Grandes modelos de lenguaje (LLM)]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Un modelo generativo aprende la distribución de los datos de entrenamiento y sabe producir muestras nuevas que provienen de esa misma distribución.</mark> Es el corte que separa a estos modelos de todo lo anterior: un clasificador responde `P(etiqueta | dato)`; un generativo modela `P(dato)` y puede muestrear de él.

El cambio de superficie de ataque que esto implica ya se apuntó en [[00 - Inteligencia artificial, machine learning y deep learning]]: cuando la salida del modelo es **contenido** en vez de una etiqueta, ese contenido puede acabar ejecutándose, mostrándose a un usuario o alimentando a otro sistema.

# Las cuatro familias

| Familia | Mecanismo | Estado en 2026 |
| - | - | - |
| `GAN` | Un generador y un discriminador compiten: uno crea muestras, el otro intenta distinguirlas de las reales | Desplazadas por la difusión en imagen. Sobreviven en nichos que exigen generación en un solo paso |
| `VAE` | Aprende un espacio latente comprimido y muestrea de él | Poco usadas solas; su `encoder` es una pieza clave de la difusión latente |
| Autorregresivos | Generan elemento a elemento condicionando por lo anterior | **Dominantes en texto y código**: son los LLM |
| Difusión | Añaden ruido progresivamente y aprenden a revertir el proceso | **Dominantes en imagen, audio y vídeo** |

<mark style="background: #FFB8EBA6;">Las GAN merecen un matiz que los materiales antiguos no recogen</mark>: fueron el estado del arte en generación de imagen entre 2014 y 2021 y hoy son mayoritariamente históricas para ese uso. Su problema estructural es el entrenamiento adversarial, inestable y propenso al `mode collapse`.

# Conceptos transversales

**Espacio latente.** Una representación comprimida donde cada punto codifica un elemento posible y la proximidad refleja similitud. Generar consiste en elegir un punto y decodificarlo. Su geometría es lo que permite operaciones como interpolar entre dos imágenes o desplazarse en la dirección de un atributo.

**Muestreo.** El paso de un punto latente a la salida final. Es un proceso **estocástico**: el mismo prompt produce salidas distintas porque se muestrea de una distribución. Los parámetros que lo gobiernan —temperatura, `top-p`— son a la vez control de calidad y superficie de ataque: <mark style="background: #FFB8EBA6;">subir la temperatura aumenta la variedad y también la probabilidad de caer fuera de la región donde el alineamiento fue entrenado</mark>.

**`Mode collapse`.** El generador se queda produciendo un subconjunto reducido de salidas posibles pese a que los datos de entrenamiento eran diversos. Típico de las GAN.

**Sobreajuste y memorización.** En un modelo discriminativo el sobreajuste degrada la generalización. En uno generativo tiene una consecuencia añadida y mucho más grave: <mark style="background: #FFB86CA6;">el modelo puede reproducir literalmente ejemplos de su conjunto de entrenamiento</mark>. Deja de ser un problema de precisión y pasa a serlo de fuga de datos y de propiedad intelectual.

# Métricas de evaluación

| Métrica | Qué mide | Vigencia |
| - | - | - |
| `Inception Score` | Claridad y diversidad de imágenes generadas | Obsoleta; sesgada por el clasificador que la sustenta |
| `FID` | Distancia entre la distribución generada y la real | Aún se reporta, con limitaciones conocidas |
| `BLEU` | Solapamiento n-grama con un texto de referencia | Legado; inútil para generación abierta |
| `CLIP score` | Correspondencia entre imagen generada y prompt | Estándar actual en texto-a-imagen |
| Preferencia humana / *LLM-as-judge* | Comparación por pares evaluada por personas o por otro modelo | Lo que se usa realmente para modelos de lenguaje |

`BLEU` merece señalarse explícitamente: mide coincidencia léxica con una referencia, así que penaliza una respuesta correcta expresada de otra forma. Para tareas generativas abiertas no significa nada.

# La superficie de ataque específica de lo generativo

## Extracción de datos de entrenamiento

Si el modelo memoriza, se le puede pedir que recite. Está demostrado sobre modelos de imagen: [Carlini et al., *Extracting Training Data from Diffusion Models* (USENIX Security 2023)](https://arxiv.org/abs/2301.13188) recuperaron imágenes concretas del conjunto de entrenamiento de `Stable Diffusion`, incluidas fotografías de personas reales. El equivalente en texto es la extracción de fragmentos memorizados —claves, direcciones, contenido con copyright— mediante prompts diseñados.

<mark style="background: #FF5582A6;">Operativamente: un modelo entrenado o afinado con datos internos es un repositorio consultable de esos datos.</mark> Si en un engagement encuentras un modelo afinado con documentación corporativa, el modelo **es** un objetivo de exfiltración, no solo una aplicación.

## Envenenamiento del corpus

Los modelos generativos se entrenan con corpus recolectados a escala web, imposibles de curar manualmente. Eso hace realista contaminarlos. `Nightshade` ([Shan et al., IEEE S&P 2024](https://arxiv.org/abs/2310.13828)) lo demostró desde el lado defensivo: perturbaciones imperceptibles en imágenes publicadas que, al ser absorbidas por el entrenamiento, corrompen la asociación del modelo entre conceptos y representaciones — con un número de muestras sorprendentemente bajo. La técnica se concibió para que artistas protegieran su obra; el mecanismo es el mismo que usaría un atacante.

## Uso ofensivo directo

La capacidad de generar contenido convincente es en sí misma una herramienta:

- **Phishing y BEC** — correos sin los errores gramaticales que servían de indicador, personalizados a escala con datos de OSINT.
- **Suplantación de voz e imagen** — `vishing` con voz clonada a partir de muestras públicas, y vídeo sintético para fraude por videollamada.
- **Contenido para ingeniería social** — perfiles falsos coherentes, historiales creíbles, documentación de apoyo.

Es la categoría de **abuso/uso indebido** de la taxonomía del [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final): no se ataca al modelo, se le usa como capacidad. En un informe conviene distinguirla claramente de los ataques *contra* el sistema de IA, porque las mitigaciones son completamente distintas.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con el estado actual de cada familia, métricas vigentes y la superficie de ataque (memorización, envenenamiento de corpus, uso indebido), ausentes en el original.
- [Carlini et al., *Extracting Training Data from Diffusion Models*, USENIX Security 2023](https://arxiv.org/abs/2301.13188) — memorización y extracción (consultado 2026-07-28).
- [Shan et al., *Nightshade: Prompt-Specific Poisoning Attacks on Text-to-Image Generative Models*, IEEE S&P 2024](https://arxiv.org/abs/2310.13828) — envenenamiento de corpus de imagen (consultado 2026-07-28).
