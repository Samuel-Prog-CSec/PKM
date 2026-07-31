---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Pentesting/Explotacion
Descripción: "El truco de Shokri: si no puedes observar la pertenencia en el modelo objetivo, fabrica modelos propios donde sí la conoces y entrena un clasificador que reconozca la firma"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - Por qué los modelos filtran pertenencia]]"
Nota siguiente: "[[03 - Entrenar los shadow models y el clasificador de ataque]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

El problema del atacante es de **datos de entrenamiento, no de algoritmo**. Se quiere una función que reciba un vector de predicción más la etiqueta real y diga si esa muestra fue miembro. Entrenar esa función requiere ejemplos etiquetados de predicciones sobre miembros y no-miembros — y el conjunto de entrenamiento del objetivo es justamente lo que no se conoce.

<mark style="background: #ADCCFFA6;">La solución de Shokri et al. (2017): si no puedes observar la pertenencia donde te importa, fabrícala donde sí la controlas.</mark> Se entrenan varios **modelos sombra** que imitan al objetivo, se recogen sus predicciones sobre sus propios datos de entrenamiento (miembros) y sobre datos retenidos (no-miembros), y con eso se entrena el **modelo de ataque**. Después se aplica ese clasificador a las predicciones del objetivo real.

> [!info]+ Fuente primaria
> [*Membership Inference Attacks Against Machine Learning Models*, arXiv:1610.05820](https://arxiv.org/abs/1610.05820) — Shokri, Stronati, Song y Shmatikov, IEEE S&P 2017. Sigue siendo el trabajo fundacional; [[04 - Ejecución y evaluación del MIA#Lo que la literatura moderna exige (y HTB no menciona)|la nota de evaluación]] cubre lo que vino después.

# La hipótesis que lo sostiene

Todo el ataque descansa sobre una única premisa: **si los modelos sombra sobreajustan de forma parecida al objetivo, un clasificador entrenado sobre sus predicciones generaliza al objetivo**. La premisa se cumple cuando el atacante puede aproximar tres cosas:

1. **La arquitectura** — capacidad y estructura similares, porque determinan el grado y el patrón del sobreajuste.
2. **El procedimiento de entrenamiento** — optimizador, tasa de aprendizaje, número de épocas; afectan a cuánto memoriza el modelo frente a cuánto generaliza.
3. **La distribución de los datos** — los patrones de sobreajuste dependen de las propiedades estadísticas de los datos.

<mark style="background: #FF5582A6;">Y es también el punto de fallo del método.</mark> Si el desajuste es grande, los patrones de pertenencia no transfieren: un ataque entrenado sobre CNN sombra fracasa contra un transformer objetivo; uno entrenado sobre CIFAR-10 fracasa contra un objetivo entrenado con imágenes médicas. **La similitud sombra-objetivo es la limitación estructural del enfoque**, y la primera cosa que hay que verificar antes de invertir cómputo.

Sobre la asunción de distribución conviene ser concreto, porque suena más restrictiva de lo que es. Los datos de entrenamiento rara vez vienen de fuentes secretas: vienen de poblaciones identificables. Un atacante en un hospital cercano tiene acceso a una demografía, distribución de enfermedades y patrones de tratamiento equivalentes; un competidor que construye un producto similar ha recopilado su propio dataset de la misma población; y datasets de referencia como Adult Census son públicos. <mark style="background: #FFB8EBA6;">Conseguir datos de la misma distribución suele ser la parte fácil.</mark>

# Por qué la agregación de varios modelos importa

No se entrena **un** modelo sombra, sino varios (cinco en el módulo), cada uno sobre un subconjunto aleatorio distinto. La razón no es estadística de andar por casa:

- Con **un solo** modelo sombra, el clasificador de ataque aprende los artefactos de esa ejecución concreta —qué muestras le tocaron, con qué semilla, qué mínimos locales encontró— y no la señal de pertenencia genérica.
- Con **varios**, el clasificador ve patrones de sobreajuste diversos. La variedad actúa como **regularización implícita**: solo sobrevive lo que es común a todos, que es precisamente la señal que también tendrá el objetivo.

<mark style="background: #8000E1A6;">Es el mismo principio que hace funcionar a un ensemble, aplicado al meta-nivel del ataque.</mark> Cinco modelos es el punto de equilibrio del módulo: menos produce diversidad insuficiente, más da rendimientos decrecientes con coste lineal.

# La arquitectura del modelo de ataque

La entrada del clasificador de ataque **no** son features crudas, sino el vector de probabilidades concatenado con la codificación *one-hot* de la etiqueta verdadera:

```text
[prob_clase_0, prob_clase_1, label_0, label_1]     # 4 dimensiones en binario
```

Concatenar la etiqueta permite aprender **umbrales específicos por clase**. No es cosmético: distintas clases sobreajustan de forma distinta —una clase minoritaria se memoriza más que una mayoritaria—, y un umbral único de confianza pierde ese matiz. El clasificador aprende, en efecto, "para la clase 0 el umbral está en 0,82; para la clase 1, en 0,88".

El modelo de ataque en sí es diminuto: una red de `[64, 32]` con ~2600 parámetros, frente a los ~37 000 del objetivo. Es deliberado. La señal de pertenencia, aunque sutil, es de **baja dimensión** (esencialmente "más confianza ⇒ más probable miembro" con ajustes por clase). Una red grande memorizaría las peculiaridades de los modelos sombra concretos y transferiría peor.

# Las alternativas más baratas

El ataque de modelos sombra tiene un coste real: entrenar N modelos, recoger predicciones, entrenar un clasificador. Existen variantes que cambian precisión por simplicidad, y en un engagement con reloj suelen ser el primer intento:

| Variante | Cómo funciona | Coste |
| - | - | - |
| **Basado en métrica** | Umbral fijo sobre la confianza: por encima de 0,9 ⇒ miembro | **Cero entrenamiento** |
| **Basado en pérdida** | Calcular la entropía cruzada sobre la muestra y umbralizarla; los miembros tienen menor pérdida | Requiere conocer la etiqueta real (el ataque sombra también) |
| **Razón de verosimilitud** | Enfoque bayesiano: modelar la distribución de predicciones sobre miembros y no-miembros y comparar cuál es más probable | Óptimo estadísticamente, pero exige modelar bien las distribuciones |

> [!important]+ El orden correcto en un engagement
> Empezar por el **ataque de umbral**: no cuesta nada y sobre modelos vulnerables ya da resultados sorprendentemente buenos. Solo si la señal existe pero es débil compensa montar modelos sombra. Y si hay presupuesto de cómputo serio, la familia de **razón de verosimilitud** es la que domina hoy el estado del arte (LiRA, RMIA — ver [[04 - Ejecución y evaluación del MIA|nota 04]]), no el clasificador entrenado de Shokri.

La razón por la que el módulo enseña modelos sombra pese a todo es buena: no requiere conocer el procedimiento de entrenamiento del objetivo, generaliza entre arquitecturas, y aprende patrones matizados que un umbral simple no captura — útil justamente cuando la brecha de confianza es pequeña.

# Separación de datos: lo que hace válido el experimento

El montaje del módulo parte el dataset (48 842 muestras de Adult Census) en tres conjuntos **disjuntos**:

```text
Total (48 842)
├── Entrenamiento del objetivo (24 421)  → los "miembros" que intentamos identificar
└── Retenido (24 421)
    ├── Entrenamiento sombra   (12 210)  → entrenar los modelos sombra
    └── Evaluación del ataque  (12 210)  → los "no-miembros" de la prueba final
```

<mark style="background: #FFB86CA6;">Si los datos de evaluación se solaparan con los de entrenamiento del objetivo, la tasa de éxito del ataque estaría inflada por construcción</mark> — se estaría "detectando" pertenencia sobre muestras que ya se sabe que son miembros. Es el error metodológico más común al reproducir estos ataques, y al leer una evaluación ajena es lo primero que hay que comprobar.

Un segundo detalle metodológico igual de fácil de romper: **normalizar todos los conjuntos con el mismo `StandardScaler`**, ajustado sobre los datos del objetivo y aplicado con `transform()` (nunca `fit_transform()`) al resto. Si cada modelo usara su propio escalador, las diferencias entre predicciones reflejarían en parte diferencias de normalización en lugar de señal de pertenencia pura, y el ataque dejaría de transferir.

La implementación completa —cómo se generan los cortes, se entrenan los cinco modelos y se construye el dataset de ataque— es [[03 - Entrenar los shadow models y el clasificador de ataque|la siguiente nota]].
