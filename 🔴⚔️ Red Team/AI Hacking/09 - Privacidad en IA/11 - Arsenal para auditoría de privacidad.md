---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Arsenal
Descripción: "Las herramientas para medir fuga de pertenencia y verificar garantías DP: ART para los ataques, ML Privacy Meter para auditar, Opacus y TF Privacy del lado defensivo"
Fecha de actualización: 2026-07-29
Nota previa: "[[10 - Detección y evasión en ataques de privacidad]]"
Nota siguiente: 
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

HTB implementa modelos sombra, clasificador de ataque, DP-SGD y PATE a mano. Está bien para entender el mecanismo; es innecesario para ejecutarlo. La misma regla que en [[05 - Arsenal para la evasión de modelos|el arsenal de evasión]]: <mark style="background: #ADCCFFA6;">a mano para aprender, con librería para el engagement.</mark>

# Los ataques: ART

`ART` (Adversarial Robustness Toolbox, Linux Foundation AI & Data) cubre la familia de inferencia completa, no solo evasión:

| Clase de `art.attacks.inference.membership_inference` | Qué implementa |
| - | - |
| `MembershipInferenceBlackBoxRuleBased` | Ataque basado en regla: la predicción correcta indica pertenencia. **Cero entrenamiento** — la primera pasada de cualquier auditoría |
| `MembershipInferenceBlackBox` | El ataque aprendido de caja negra, equivalente al clasificador de [[03 - Entrenar los shadow models y el clasificador de ataque\|Shokri]] |
| `ShadowModels` | Utilidad para entrenar modelos sombra y generar el dataset de ataque (scikit-learn, PyTorch, TensorFlow v2) |
| `LabelOnlyDecisionBoundary` | El ataque **label-only** por distancia a la frontera: el que derriba el argumento "solo devolvemos la etiqueta" |
| `LabelOnlyGapAttack` | Alias de la variante basada en regla |

Y el resto de la familia de privacidad, en módulos hermanos: `art.attacks.inference.model_inversion` (reconstrucción de features, `MIFace`) y `art.attacks.inference.attribute_inference`.

```shell-session
$ pip install adversarial-robustness-toolbox
```

```python
from art.estimators.classification import PyTorchClassifier
from art.attacks.inference.membership_inference import (
    MembershipInferenceBlackBoxRuleBased, LabelOnlyDecisionBoundary)

clf = PyTorchClassifier(model=target, loss=criterion, input_shape=(n_feats,), nb_classes=2)

# 1) cribado barato: sin entrenamiento
rule = MembershipInferenceBlackBoxRuleBased(clf)
pred_members     = rule.infer(x_members, y_members)
pred_non_members = rule.infer(x_non_members, y_non_members)

# 2) si el endpoint solo devuelve etiquetas
lo = LabelOnlyDecisionBoundary(clf)
lo.calibrate_distance_threshold(x_members, y_members, x_non_members, y_non_members)
```

<mark style="background: #FFB86CA6;">El orden importa:</mark> empezar por `MembershipInferenceBlackBoxRuleBased` (gratis) y escalar solo si hay señal. Montar modelos sombra de entrada es gastar días de cómputo antes de saber si hay algo que encontrar.

# La auditoría: ML Privacy Meter

Herramienta del grupo de Shokri —los mismos autores del [[02 - El ataque de shadow models|paper fundacional]]—, diseñada **para auditar**, no para atacar. Su valor frente a ART es que produce el informe con las métricas correctas —incluidas curvas ROC en escala logarítmica y `TPR` a `FPR` bajo, que es [[04 - Ejecución y evaluación del MIA#Lo que la literatura moderna exige (y HTB no menciona)|la métrica que exige la literatura moderna]]— e implementa los ataques del estado del arte en lugar del clasificador de 2017.

> [!warning]+ Instalar desde el repositorio, no desde PyPI
> <mark style="background: #FF5582A6;">La última versión publicada en PyPI es la **1.0.1, de julio de 2023**</mark>, muy anterior a la incorporación de los ataques que justifican usar la herramienta. El desarrollo vive en el repositorio:
>
> ```shell-session
> $ pip install git+https://github.com/privacytrustlab/ml_privacy_meter
> ```
>
> Es un patrón que conviene comprobar en todo el `tooling` de seguridad de IA —igual que pasó con [[00 - Qué es garak y cuándo usarlo|garak]] y su cambio de repositorio—: el paquete publicado y el proyecto vivo divergen con facilidad, y `pip install <nombre>` puede traer algo dos años por detrás sin avisar.

Es la opción por defecto cuando el entregable es un informe de riesgo de privacidad y no una prueba de concepto.

# Los ataques del estado del arte

| Herramienta | Cuándo |
| - | - |
| **[RMIA](https://arxiv.org/abs/2312.03262)** (Zarifzadeh et al., ICML 2024) | La mejor relación coste/potencia: con **1-2 modelos de referencia** consigue 2-4× más `TPR` a `FPR` bajo que LiRA |
| **LiRA** ([Carlini et al., S&P 2022](https://arxiv.org/abs/2112.03570)) | Cuando hace falta la cota más ajustada y hay presupuesto para entrenar muchos modelos de referencia |
| **TensorFlow Privacy** — `tensorflow_privacy.privacy.privacy_tests` | Suite de ataques de pertenencia integrada para modelos Keras/TF; útil si el cliente ya vive en ese ecosistema |

# El lado defensivo

| Herramienta | Ecosistema | Para qué |
| - | - | - |
| **`Opacus`** | PyTorch | [[06 - DP-SGD, clipping, ruido y contabilidad con Opacus\|DP-SGD]]. Recordar: el contable por defecto es `prv`, más ajustado que `rdp` |
| **`TensorFlow Privacy`** | TF/Keras | DP-SGD + suite de tests de privacidad |
| **`JAX-Privacy`** | JAX | DP-SGD; es el ecosistema de los resultados que mejor cierran la brecha de utilidad |
| **`dp_accounting`** (Google) | Agnóstico | Contabilidad de presupuesto independiente del entrenamiento: sirve para **verificar** el $\varepsilon$ que declara un cliente |
| **`tensorflow/privacy/research/pate_2018`** | — | Implementación de referencia del análisis RDP y de sensibilidad suave de PATE |

<mark style="background: #FF5582A6;">`dp_accounting` es la herramienta clave del auditor</mark>: permite recalcular de forma independiente el $\varepsilon$ a partir de los parámetros declarados (multiplicador de ruido, tasa de muestreo, número de pasos, $\delta$) y contrastarlo con la cifra que aparece en la documentación del cliente. Es donde aparecen las discrepancias reales.

# Para modelos generativos

El `MIA` clásico apenas aplica a un LLM; lo que aplica es **extracción de datos de entrenamiento**, y las herramientas son otras:

- **[[00 - Qué es garak y cuándo usarlo|garak]]** — probes de fuga (`leakreplay` y familia) contra el modelo objetivo.
- **[[00 - Qué es PyRIT y cuándo usarlo|PyRIT]]** — orquestación de campañas de extracción multi-turno, con `scorers` para detectar cuándo la salida contiene material memorizado.
- **Canarios** — insertar secuencias únicas en el corpus de *fine-tuning* del cliente y medir su exposición (metodología del *secret sharer*). Es lo que convierte "podría estar memorizando" en un número.

# Flujo de una auditoría de privacidad

1. **Reconocimiento del endpoint** — ¿devuelve probabilidades o solo etiqueta? ¿Cuántas clases? ¿Hay `rate limiting` o registro? ([[01 - Por qué los modelos filtran pertenencia#Lo que se pregunta en el reconocimiento|checklist completo]]).
2. **Cribado barato** — `MembershipInferenceBlackBoxRuleBased` o umbral sobre la pérdida. Si no hay señal aquí, decidir si merece escalar.
3. **Conjunto de evaluación balanceado** — mismo número de miembros y no-miembros. Sin esto, cualquier `accuracy` que se reporte es inservible.
4. **Ataque serio** — RMIA con 1-2 modelos de referencia; LiRA si hay presupuesto. Si el endpoint es label-only, `LabelOnlyDecisionBoundary`.
5. **Métricas correctas** — `AUC`, precisión balanceada y **`TPR@0.1%FPR`**, con ROC en log-log. Nunca `accuracy` sobre datos desbalanceados.
6. **Análisis por subpoblación** — ¿qué clases o grupos son los expuestos? Los atípicos y las minorías son los que filtran, y las medias los esconden.
7. **Verificación de la garantía declarada** — si el cliente afirma DP: recalcular $\varepsilon$ con `dp_accounting`, comprobar $\delta \ll 1/n$, la unidad de privacidad (ejemplo o usuario) y la composición entre reentrenamientos ([[07 - El compromiso privacidad-utilidad de DP-SGD#Cómo se evalúa la afirmación de un cliente|procedimiento]]).
8. **Reportar** el coste del ataque, las subpoblaciones afectadas, la ausencia de detección y las discrepancias entre la garantía declarada y la verificada.

> [!warning]+ Dónde suele estar el hallazgo
> Rara vez en "el modelo filtra". Casi siempre en el paso 7: garantías de nivel de ejemplo vendidas como protección de personas, $\delta$ mal elegidos, presupuestos que no contabilizan reentrenamientos, o un $\varepsilon$ publicado que no se puede reproducir con los parámetros que el cliente documenta. <mark style="background: #8000E1A6;">Verificar una afirmación de privacidad es un trabajo distinto de romper un modelo, y es el que más valor aporta hoy en una auditoría de IA.</mark>
