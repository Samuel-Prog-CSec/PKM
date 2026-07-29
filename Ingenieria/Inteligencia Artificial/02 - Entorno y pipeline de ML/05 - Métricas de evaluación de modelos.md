---
tags:
  - IA
  - IA/Pipeline
Descripción: "Las métricas cuantifican la relación entre lo que el modelo predice y la verdad conocida"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Transformación de datos]]"
Nota siguiente: "[[00 - Machine learning aplicado a la defensa]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

<mark style="background: #ADCCFFA6;">Las métricas cuantifican la relación entre lo que el modelo predice y la verdad conocida.</mark> Elegir la métrica equivocada es la forma más habitual de creerse un modelo que no funciona — y, del otro lado, la forma más habitual de que un proveedor te venda uno que no funciona.

# La matriz de confusión es el punto de partida

Todas las métricas de clasificación se derivan de cuatro números:

| | Predicho positivo | Predicho negativo |
| - | - | - |
| **Real positivo** | `TP` — verdadero positivo | `FN` — falso negativo (amenaza no detectada) |
| **Real negativo** | `FP` — falso positivo (falsa alarma) | `TN` — verdadero negativo |

<mark style="background: #FF5582A6;">Pedir siempre la matriz de confusión antes que cualquier número agregado.</mark> Un único escalar puede ocultar cualquier cosa; la matriz no.

# Las cuatro métricas básicas

| Métrica | Fórmula | Qué mide |
| - | - | - |
| `Accuracy` | `(TP + TN) / total` | Proporción global de aciertos |
| `Precision` | `TP / (TP + FP)` | De lo que marco como positivo, cuánto lo es de verdad |
| `Recall` | `TP / (TP + FN)` | De todo lo positivo que existe, cuánto detecto |
| `F1-score` | `2·(P·R)/(P+R)` | Media armónica de precisión y recall |

## Por qué accuracy es una métrica peligrosa

Con un 1% de spam, un modelo que clasifique **todo** como legítimo obtiene `accuracy = 0,99` sin detectar un solo correo malicioso.

<mark style="background: #8000E1A6;">En seguridad las clases están desbalanceadas por definición: lo malicioso es una fracción minúscula del total.</mark> Eso convierte la `accuracy` en una métrica que mide poco más que la proporción de la clase mayoritaria. Cuando un producto la presenta como cifra principal, hay que asumir que oculta algo hasta que demuestre lo contrario.

## El equilibrio precisión/recall

Los dos se mueven en direcciones opuestas al ajustar el umbral de decisión:

- **Alta precisión, bajo recall** — pocas falsas alarmas, muchas amenazas sin detectar. El SOC confía en las alertas pero se le escapan cosas.
- **Alto recall, baja precisión** — se detecta casi todo y se ahoga al analista en ruido. En la práctica lleva a que las alertas se ignoren, que es equivalente a no tenerlas.

<mark style="background: #FFB8EBA6;">La elección no es técnica, es de coste operativo</mark>: depende de cuánto cuesta investigar un falso positivo frente a cuánto cuesta una intrusión no detectada. En bloqueo automático (un WAF, un filtro de correo) los falsos positivos interrumpen a usuarios legítimos y se prioriza precisión; en detección para investigación humana se prioriza recall.

El `F1-score` resume ambos en un número. Su media **armónica** —no aritmética— castiga los desequilibrios: con precisión 1,0 y recall 0,0 la media aritmética daría 0,5 y el `F1` da 0.

# Métricas que faltan en la lista básica

| Métrica | Para qué |
| - | - |
| `Specificity` | `TN / (TN + FP)` — capacidad de identificar correctamente lo benigno |
| `ROC-AUC` | Capacidad de discriminación agregada sobre todos los umbrales posibles |
| `PR-AUC` | Área bajo la curva precisión-recall |
| `MCC` | Coeficiente de correlación de Matthews: usa las cuatro celdas de la matriz |

> [!important]+ Con clases desbalanceadas, ROC-AUC engaña y PR-AUC no
> Es la corrección más útil de esta nota. La curva ROC representa `TPR` frente a `FPR`, y **`FPR` tiene los negativos en el denominador**. Cuando los negativos son abrumadoramente mayoritarios, miles de falsos positivos apenas mueven el `FPR` y el `ROC-AUC` se mantiene cerca de 1 pese a que el modelo sea inutilizable en la práctica.
>
> La curva **precisión-recall** no usa los verdaderos negativos en ningún denominador, así que refleja de forma directa el coste de las falsas alarmas. <mark style="background: #FFB86CA6;">Ante un desbalance fuerte, `PR-AUC` es la métrica honesta y `ROC-AUC` la de marketing.</mark>
>
> El `MCC` es la otra opción robusta: incorpora las cuatro celdas y solo da un valor alto si el modelo acierta en ambas clases.

## La métrica que de verdad se usa en detección

En productos de seguridad, la forma operativa de expresar el rendimiento no es ninguna de las anteriores en solitario, sino **la tasa de detección a un ratio de falsos positivos fijado**: "detecta el 92% de las muestras maliciosas con un `FPR` del 0,1%".

Tiene sentido porque el `FPR` se traduce directamente en volumen de trabajo: con 10 millones de eventos diarios, un 0,1% son 10.000 alertas falsas al día. <mark style="background: #FF5582A6;">Ese número, y no el `F1`, es el que determina si el sistema es desplegable.</mark>

# Preguntas antes de aceptar unas métricas

Ante `accuracy: 0,9750`, `precision: 0,9300`, `recall: 0,9100`, `F1: 0,9200`, lo que hay que preguntar:

- **¿Sobre qué partición?** Si es aleatoria sobre datos temporales, las cifras están infladas (ver [[04 - Transformación de datos]]).
- **¿Cuál es la proporción de clases del conjunto de test?** Sin ella, ninguna cifra es interpretable.
- **¿Se mantiene por segmentos?** Un modelo puede rendir bien de media y fallar sistemáticamente en un subconjunto — un protocolo, un rango horario, un tipo de dispositivo.
- **¿El conjunto de test refleja condiciones reales?** Un dataset equilibrado artificialmente al 50/50 no dice nada sobre el comportamiento con un 0,01% de positivos.
- **¿Cuántas veces se ha usado ese conjunto de test?** Si se ha consultado repetidamente para tomar decisiones, ya no es un conjunto ciego y las métricas están contaminadas.
- **¿Se ha medido bajo ataque?** Ninguna de estas métricas dice nada sobre robustez adversarial. Un modelo con `F1 = 0,99` puede evadirse alterando dos bytes. Precisión y robustez son propiedades **independientes**.

Ese último punto es el puente con el resto del path: todas las métricas de esta nota miden rendimiento frente a datos que se comportan de forma natural, y ninguna mide rendimiento frente a datos elegidos por un adversario para hacer fallar al modelo.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con la matriz de confusión como punto de partida, la superioridad de `PR-AUC` sobre `ROC-AUC` bajo desbalance, el `MCC`, la métrica operativa de detección a `FPR` fijo y el checklist de validación, ausentes en el original.
