---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - Introduccion
  - Tipo/Defensa
Descripción: "Tres modelos, tres problemas defensivos reales y tres tipos de dato distintos"
Fecha de actualización: 2026-07-28
Nota previa: "[[05 - Métricas de evaluación de modelos]]"
Nota siguiente: "[[01 - Clasificación de spam con Naive Bayes]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

Tres modelos, tres problemas defensivos reales y tres tipos de dato distintos. <mark style="background: #ADCCFFA6;">El objetivo no es solo construirlos, sino entender qué hacen bien y dónde se rompen</mark> — porque los mismos modelos son el objetivo de las técnicas de evasión adversarial.

| Modelo | Problema | Algoritmo | Tipo de dato |
| - | - | - | - |
| Clasificador de spam | ¿Este SMS es spam? | [[06 - Naive Bayes]] | Texto |
| Detector de anomalías de red | ¿Este tráfico es anómalo? | [[05 - Árboles de decisión y ensembles]] (`Random Forest`) | Tabular |
| Clasificador de malware | ¿A qué familia pertenece este binario? | [[02 - Redes neuronales convolucionales (CNN)]] | Imagen (`byteplot`) |

El flujo es el mismo en los tres casos y es el que se detalla en `Ingenieria/Inteligencia Artificial/02 - Entorno y pipeline de ML/`: explorar el dataset → limpiar → transformar en features numéricas → partir en conjuntos → entrenar → evaluar.

# Dónde el ML aporta de verdad en defensa

Conviene fijar expectativas antes de construir nada, porque el sector vende esto con bastante exageración.

**Funciona bien cuando:**

- Hay **volumen** que ningún humano puede revisar y el coste de un error individual es bajo. Filtrado de correo, triaje y priorización de alertas, agrupación de muestras en familias.
- El patrón es **estadístico y difuso**, imposible de expresar como regla. Detectar que un dominio recién registrado con nombre de alta entropía es sospechoso.
- Se usa como **una señal más** dentro de un sistema que correlaciona varias, no como veredicto único.

**Funciona mal cuando:**

- Se espera que detecte **lo que nunca ha visto**. Un modelo generaliza sobre su distribución de entrenamiento; un ataque genuinamente novedoso está fuera de ella por definición.
- La clase objetivo es **muy rara** y se necesita alta precisión. Es la falacia de la tasa base descrita en [[06 - Naive Bayes]]: con clases al 0,01%, incluso un detector muy bueno genera mayoritariamente falsas alarmas.
- Hay un **adversario adaptativo**. Los supuestos de estacionariedad e independencia sobre los que se construye todo el ML clásico no se cumplen cuando alguien modifica su comportamiento precisamente para no ser detectado.

> [!important]+ La regla práctica
> <mark style="background: #FF5582A6;">El ML en defensa sirve para reducir el volumen que un humano tiene que mirar, no para sustituir su criterio.</mark> Un modelo que convierte 10 millones de eventos en 200 candidatos ordenados por prioridad es enormemente valioso. Un modelo que promete decidir por sí solo qué bloquear es un control de seguridad con una superficie de ataque nueva y mal entendida.

# Lo que un pentester saca de esto

Construir estos tres detectores tiene valor ofensivo directo, y por eso están cruzados con `Red Team/AI Hacking/`:

- **Saber qué features usa un detector es saber qué modificar.** Si un clasificador de spam pesa la frecuencia de términos, la evasión es léxica; si un detector de red pesa el volumen y la duración, la evasión es de temporización.
- **Cada paso de preprocesado descarta información**, y lo descartado es terreno libre para el atacante. Se ve con claridad en [[02 - Preprocesamiento de texto y extracción de features]].
- **Los tres modelos son evadibles con técnicas conocidas.** El cierre del bloque, [[08 - Límites y evasión de los detectores ML]], recorre exactamente cómo se ataca cada uno.

Entender el detector desde dentro es la condición previa para evadirlo con criterio en vez de por prueba y error — y también para construir uno que aguante.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, reencuadrado con el análisis de dónde el ML aporta y dónde no en defensa, ausente en el original.
