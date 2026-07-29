---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Enumeracion
Descripción: "Determina si aplican los ataques de gradiente, que son los baratos"
Fecha de actualización: 2026-07-28
Nota previa: "[[10 - Ataques a los componentes de sistema]]"
Nota siguiente: "[[12 - Detección y evasión en sistemas de IA]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

> [!info]+ Nota añadida al temario
> Nota puente entre la teoría de `Ingenieria/Inteligencia Artificial/` y el trabajo ofensivo. **Qué algoritmo hay debajo determina qué ataques son viables**, y esa correspondencia no aparece en ningún sitio del temario. Identificar la familia del modelo objetivo es parte del reconocimiento, no un detalle académico.

# La tabla

| Familia | ¿Diferenciable? | Superficie característica |
| - | - | - |
| [[03 - Regresión lineal]] / [[04 - Regresión logística]] | Sí, trivialmente | Gradiente constante: la perturbación mínima tiene **forma cerrada**. Los coeficientes *son* el modelo |
| [[05 - Árboles de decisión y ensembles]] | **No** | Particiones paralelas a los ejes: evasión `L0` exacta si se conocen los umbrales. `Feature importance` filtra el mapa |
| [[07 - Máquinas de vectores de soporte (SVM)]] | Sí | Los vectores de soporte **son datos de entrenamiento**: fuga de privacidad directa. Envenenamiento muy eficiente |
| [[06 - Naive Bayes]] | Parcial | Independencia de features → `good word attack`. El prior es manipulable |
| [[09 - K-Means y clustering]] | No | El centroide es una media: desplazable con tráfico inyectado sostenido |
| [[10 - Análisis de componentes principales (PCA)]] | Sí | El subespacio se estima de los datos: envenenable para que la actividad del atacante se reconstruya bien |
| [[02 - Redes neuronales convolucionales (CNN)]] | Sí | Ejemplos adversariales canónicos, **transferibilidad**, parches físicos |
| [[03 - Redes neuronales recurrentes (RNN)]] | Sí | Modelos de secuencia: ataques de mimetismo intercalando elementos inocuos |
| [[04 - Transformers y el mecanismo de atención]] / LLM | Sí | `Prompt injection` **arquitectural**, `jailbreak`, fuga del prompt de sistema, memorización |
| [[07 - Modelos de difusión]] | Sí | Filtros de contenido evadibles, memorización del corpus, envenenamiento tipo `Nightshade` |

# Los tres cortes que de verdad deciden

## ¿Es diferenciable?

<mark style="background: #ADCCFFA6;">Determina si aplican los ataques de gradiente, que son los baratos.</mark>

- **Sí** (lineales, SVM, redes neuronales, difusión) → con acceso `white-box` se calcula el gradiente respecto a la entrada: un solo `backward pass` con `FGSM`, unas decenas de iteraciones con `PGD` — ver [[01 - Matemáticas para machine learning]]. Sin ese acceso, se entrena un sustituto y se transfiere el resultado.
- **No** (árboles y ensembles) → hay que recurrir a ataques basados en decisión, búsqueda sobre umbrales o transferencia desde un sustituto diferenciable. Más caro, no imposible.

Ojo con la conclusión fácil: **no diferenciable no significa robusto**. Un ensemble de árboles es difícil de atacar por gradiente y trivial de evadir si se infieren sus cortes, porque cada decisión depende de una única feature comparada con un valor.

## ¿Qué guarda el modelo de sus datos de entrenamiento?

<mark style="background: #FFB86CA6;">Determina si el modelo es en sí mismo un objetivo de exfiltración.</mark>

| Modelo | Qué conserva |
| - | - |
| SVM | **Ejemplos literales** — los vectores de soporte son filas del dataset |
| k-NN | El dataset completo, por construcción |
| Naive Bayes / lineales | Estadísticas agregadas: poco riesgo directo |
| Árboles | Umbrales que pueden revelar rangos y distribuciones de los datos |
| Redes profundas | Representaciones distribuidas... y **memorización** de ejemplos concretos si hay sobreajuste |
| Generativos | Memorización explotable: extracción de datos de entrenamiento demostrada |

Es la diferencia entre encontrar "un modelo" y encontrar "datos de la empresa en formato modelo".

## ¿Cuál es el canal de entrada?

Determina la forma del payload y las restricciones del espacio del problema:

- **Vector numérico de features** (tabulares) → la restricción es la coherencia del artefacto real que produce esas features.
- **Imagen** → mucha libertad, píxeles continuos. El caso más fácil para el atacante.
- **Binario** → poca libertad: hay que preservar la funcionalidad. Empuja hacia `L0`.
- **Texto** → discreto y no diferenciable en la entrada, pero con enorme espacio semántico. Se ataca con búsqueda y con sustitutos.
- **Lenguaje natural con instrucciones** (LLM) → <mark style="background: #FF5582A6;">el canal más permisivo que existe: la entrada *es* el programa.</mark>

# Identificar la familia desde fuera

Parte del reconocimiento. Señales útiles:

- **Forma de la salida.** Etiqueta sola, probabilidades calibradas, `logits`, o texto libre. Probabilidades muy bien calibradas apuntan a regresión logística; distribuciones extremas (0/1) son típicas de ensembles.
- **Latencia y su varianza.** Un modelo lineal responde en microsegundos con latencia plana; un LLM tiene latencia proporcional a la longitud generada.
- **Comportamiento frente a features fuera de rango.** Los árboles saturan —a partir del último umbral la predicción no cambia—; los modelos lineales siguen creciendo indefinidamente. Es una prueba discriminante barata.
- **Sensibilidad a perturbaciones diminutas.** Si un cambio minúsculo en una feature altera la salida, hay una frontera continua cerca (modelo diferenciable); si hacen falta saltos, hay umbrales discretos (árbol).
- **Reacción al escalado.** Un modelo insensible al escalado de features probablemente sea basado en árboles.
- **Contexto del despliegue.** Datos tabulares de seguridad en producción → apostar por `XGBoost` o `Random Forest` antes que por una red neuronal, por lo visto en [[05 - Árboles de decisión y ensembles]].

<mark style="background: #8000E1A6;">Media docena de consultas bien elegidas acotan la familia, y con la familia acotada el resto del trabajo deja de ser prueba y error.</mark>

## Fuentes

- Nota net-new: no forma parte del temario de HTB Academy. Redactada como puente entre los fundamentos de `Ingenieria/Inteligencia Artificial/` y el trabajo ofensivo de este módulo.
- Las propiedades por familia se apoyan en las notas enlazadas y en la taxonomía del [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final).
