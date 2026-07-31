---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Tipo/Arsenal
Descripción: "El set para generar y evaluar ejemplos adversariales: ART de referencia, TorchAttacks para dispersos, TextAttack para NLP, AutoAttack como vara, y σ-zero / Sparse-RS para L0"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Detección y defensa contra la evasión]]"
Nota siguiente: 
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 3 del vault. Cubre el arsenal de evasión para **las tres carpetas** del tema —[[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords]] sobre clasificadores, [[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]] sobre redes neuronales y [[00 - Fundamentos de los ataques dispersos y la norma L0|ataques dispersos]] $L_0$—, porque es el mismo. El arsenal **general** de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]]; aquí, lo específico de generar y evaluar ejemplos adversariales.

# El principio: no reimplementar los ataques

HTB implementa GoodWords, FGSM, DeepFool, EAD y JSMA a mano con NumPy, PyTorch y scikit-learn. Está bien para **entenderlos**; es innecesario para **ejecutarlos**. Las librerías de ML adversarial implementan todos los ataques de estas tres carpetas —y sus defensas— con una API común y probada. La regla operativa: <mark style="background: #ADCCFFA6;">a mano para aprender la mecánica, con librería para el engagement.</mark>

# La referencia: Adversarial Robustness Toolbox (ART)

| | |
| - | - |
| **Autor** | Linux Foundation AI & Data (originalmente IBM) |
| **Cubre** | Evasión, envenenamiento, extracción e inferencia — **atacar y defender** |
| **Frameworks** | TensorFlow, Keras, PyTorch, scikit-learn, XGBoost… |

`ART` es lo que evita reescribir cada ataque. Para evasión implementa toda la familia:

| Módulo ART | Ataque |
| - | - |
| `art.attacks.evasion.FastGradientMethod` | [[02 - FGSM, el ataque de un solo paso\|FGSM]] |
| `art.attacks.evasion.BasicIterativeMethod` | I-FGSM / BIM |
| `art.attacks.evasion.ProjectedGradientDescent` | PGD — el estándar de facto |
| `art.attacks.evasion.DeepFool` | [[04 - DeepFool y la perturbación mínima\|DeepFool]] |
| `art.attacks.evasion.CarliniL2Method` | Carlini & Wagner (C&W) |
| `art.attacks.evasion.ElasticNet` | [[01 - ElasticNet (EAD) y la mezcla L1 + L2\|EAD]] — el elastic-net de Chen et al. (2018) |
| `art.attacks.evasion.CarliniL0Method` | Variante $L_0$ de C&W: fija iterativamente las features poco influyentes |
| `art.attacks.evasion.HopSkipJump` | Caja negra basada en decisión |
| `art.defences.trainer.AdversarialTrainer` | [[04 - Detección y defensa contra la evasión\|Entrenamiento adversarial]] |

<mark style="background: #FF5582A6;">Los módulos de `defences` valen tanto como los de ataque en un engagement</mark>: permiten medir si el pipeline del cliente detectaría o resistiría una evasión, que es el hallazgo que se reporta.

```shell-session
$ pip install adversarial-robustness-toolbox
```

```python
from art.estimators.classification import SklearnClassifier
from art.attacks.evasion import ProjectedGradientDescent

classifier = SklearnClassifier(model=sklearn_model)
attack = ProjectedGradientDescent(classifier, eps=0.1)
x_adv = attack.generate(x=x_test)          # ejemplos adversariales
```

# Especializadas por dominio

Cuando ART se queda corto o hay algo más cómodo para un dominio concreto:

| Herramienta | Dominio | Para qué |
| - | - | - |
| **`Foolbox`** | Imagen | Ejemplos adversariales con API muy limpia; rápido para prototipar |
| **`TorchAttacks`** | Imagen (PyTorch) | Ataques nativos PyTorch, integración directa en el loop de entrenamiento |
| **`TextAttack`** | NLP | El equivalente de GoodWords moderno: sustitución de palabras, paráfrasis, perturbación de carácter, con restricciones de coherencia |
| **`CleverHans`** | Imagen | Histórica, de referencia académica; útil para reproducir papers |
| **`SecML`** | Clásico + imagen | Fuerte en modelos de scikit-learn y ataques de evasión sobre features estructuradas — el más cercano al caso GoodWords |

Para el caso concreto de [[01 - El ataque GoodWords y los clasificadores Naive Bayes|GoodWords sobre clasificadores de texto]], `TextAttack` y `SecML` son las opciones directas: modelan la evasión sobre features de texto sin reimplementar el bandit a mano.

# Ataques dispersos ($L_0$)

<mark style="background: #FFB86CA6;">`TorchAttacks` es la librería con la cobertura más completa de la familia dispersa</mark>, y con diferencia la vía más rápida para reproducir todo lo de [[00 - Fundamentos de los ataques dispersos y la norma L0|la carpeta de ataques dispersos]] sin escribir FISTA ni Jacobianos a mano:

| Clase de `torchattacks` | Ataque |
| - | - |
| `JSMA` | [[06 - JSMA, el Jacobiano y los mapas de saliencia\|JSMA]] con $\theta$ y $\gamma$ |
| `EADL1` / `EADEN` | [[01 - ElasticNet (EAD) y la mezcla L1 + L2\|EAD]] en sus dos reglas de decisión ($L_1$ puro y elastic-net) |
| `SparseFool` | La versión geométrica y escalable de la evasión dispersa |
| `OnePixel` | El caso extremo por evolución diferencial (caja negra) |
| `Pixle` | Ataque disperso por reordenación de píxeles, sin añadir ruido nuevo |

```shell-session
$ pip install torchattacks
```

```python
import torchattacks
atk = torchattacks.JSMA(model, theta=1.0, gamma=0.15)     # L0 con presupuesto explícito
adv = atk(images, labels)

l0 = (adv - images).flatten(1).abs().gt(1e-6).sum(1)      # el L0 REAL, contando no nulos
```

> [!warning]+ Medir $L_0$, no $L_1$
> Reportar el $L_1$ medio como si midiera dispersión es un error frecuente: $L_1$ mide magnitud acumulada, no número de features. El único número honesto es contar coordenadas no nulas con una tolerancia explícita (`> 1e-6`), como en la última línea del ejemplo.

Fuera de las librerías generalistas, dos implementaciones de referencia del estado del arte:

- **[σ-zero](https://arxiv.org/abs/2402.01879)** (Cinà et al., ICLR 2025) — aproximación diferenciable de $L_0$ con proyección adaptativa. Es la elección para **medir la perturbación $L_0$ mínima** de un modelo en caja blanca, y no necesita ajuste de hiperparámetros, a diferencia de EAD.
- **[Sparse-RS](https://github.com/fra31/sparse-rs)** (Croce et al., AAAI 2022) — búsqueda aleatoria en **caja negra** que cubre con el mismo marco perturbaciones $L_0$, **parches adversariales** y marcos adversariales. Su versión $L_0$ supera a ataques de caja blanca sobre ImageNet perturbando ~0,1 % de los píxeles, así que es el punto de partida cuando solo hay acceso a la salida del modelo — y la herramienta para evaluar el modelo de amenaza **físico** (parche imprimible).

# La vara de medir: AutoAttack

<mark style="background: #8000E1A6;">`AutoAttack` no es para atacar: es para **evaluar** honestamente la robustez de una defensa.</mark> Es un ensemble de cuatro ataques (APGD-CE, APGD-DLR, FAB, Square Attack) sin hiperparámetros que ajustar, diseñado para no dejar que un modelo *parezca* robusto por una evaluación débil.

Es la herramienta de [[04 - Detección y defensa contra la evasión|RobustBench]]: si un cliente afirma que su modelo es robusto, se comprueba con `AutoAttack`, no con un FGSM suave que cualquier defensa aparenta resistir.

```shell-session
$ pip install autoattack
```

# Benchmarks y modelos de referencia

- **[RobustBench](https://robustbench.github.io/)** — `leaderboard` de robustez y **zoo de modelos** robustos pre-entrenados. Sirve para dos cosas: comparar la robustez del modelo del cliente contra el estado del arte, y descargar modelos robustos como sustitutos para ataques de transferencia.
- **`RobustBench model zoo`** — 60+ modelos con robustez conocida, útiles como línea base.

# Flujo sugerido para el engagement

1. **Reproducir el objetivo o un sustituto** — si es caja negra, [[01 - Model reverse engineering y robo de modelos|robar el modelo]] o entrenar uno de arquitectura similar.
2. **Generar ejemplos adversariales con ART** sobre el sustituto (caja blanca) y **transferirlos** al objetivo.
3. **Para NLP/clasificadores de texto**, usar `TextAttack`/`SecML` en lugar de reimplementar GoodWords.
4. **Medir la robustez real** del modelo del cliente con `AutoAttack` y comparar con RobustBench. <mark style="background: #FF5582A6;">`AutoAttack` mide $L_\infty$ y $L_2$: **no cubre $L_0$**.</mark> Si el dominio impone restricciones de número de features (malware, texto, tráfico) o hay riesgo de parche físico, añadir una pasada con **σ-zero** (caja blanca) o **Sparse-RS** (caja negra) — un modelo puede estar en cabeza de RobustBench y caer con 40 píxeles ([[09 - EAD frente a JSMA y el estado del arte en ataques L0|por qué la robustez no se hereda entre normas]]).
5. **Evaluar las defensas** con los módulos `defences` de ART: ¿resistiría el pipeline un ataque PGD? ¿tiene entrenamiento adversarial?
6. **Reportar** el coste de evasión (consultas, tasa de éxito), la robustez medida honestamente, y **qué defensas faltan** — que es el valor del ejercicio.

> [!warning]+ La evaluación honesta es el entregable
> El error más común al reportar robustez es medirla con un ataque débil y concluir que el modelo aguanta. `AutoAttack` existe precisamente para eso: da el número real. En un informe, "el modelo resiste FGSM" no vale nada si no resiste PGD o AutoAttack. Medir con la vara correcta es la diferencia entre un hallazgo creíble y uno que el cliente descartará en cuanto lo re-evalúe.
