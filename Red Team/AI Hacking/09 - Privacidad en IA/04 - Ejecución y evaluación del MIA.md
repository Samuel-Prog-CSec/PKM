---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Pentesting/Explotacion
Descripción: "El 69% de acierto que reporta HTB no es un 19% de ventaja: con un desbalance 2:1 la línea base trivial ya acierta el 66,7%, y la ventaja real es de 5 puntos"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - Entrenar los shadow models y el clasificador de ataque]]"
Nota siguiente: "[[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

Con el clasificador entrenado, la ejecución contra el objetivo es directa: recoger sus predicciones sobre los 24 421 miembros y los 12 210 no-miembros, transformarlas en features de ataque y pasarlas por el modelo.

```python
preds_members     = get_model_predictions(target_model, X_target_norm, DEVICE)
preds_non_members = get_model_predictions(target_model, X_attack_eval_norm, DEVICE)

# prepare_attack_data etiqueta POR POSICIÓN: 1º argumento = miembro, 2º = no-miembro.
# Hay que llamarla dos veces con un array vacío de relleno.
attack_X_members, attack_y_members = prepare_attack_data(
    preds_members, np.zeros((0, preds_members.shape[1])), y_target, np.array([], dtype=np.int64))
attack_X_non_members, attack_y_non_members = prepare_attack_data(
    np.zeros((0, preds_non_members.shape[1])), preds_non_members, np.array([], dtype=np.int64), y_attack_eval)
```

El truco del array vacío `np.zeros((0, n_clases))` —cero filas, dimensión de columna correcta— existe porque la función deduce la etiqueta de pertenencia de la **posición** del argumento, no de un parámetro explícito. Concatenar antes de llamarla etiquetaría todo como miembro.

# Los resultados

```txt
Target Model Performance:      Training 0.9360 | Test 0.8247 | Gap 0.1113

Membership Inference Attack Results:
  Attack Accuracy:  0.6915        Attack Precision: 0.6899
  Attack Recall:    0.9758        Attack F1 Score:  0.8083
  Attack AUC:       0.5675

Confidence: members 0.9301 | non-members 0.9226 | gap 0.0075
```

La lectura que hace HTB: *ventaja = precisión − 0,5 = 0,19; ventaja superior a 0,15 ⇒ alta vulnerabilidad*. <mark style="background: #FF5582A6;">Esa conclusión es incorrecta, y el error está en la línea base.</mark>

# La corrección: el desbalance 2:1 invalida la métrica

El conjunto de evaluación tiene **24 421 miembros y 12 210 no-miembros**. La tasa base es:

$$\frac{24\,421}{36\,631} = 0{,}6667$$

<mark style="background: #FFB86CA6;">Un clasificador trivial que responda "miembro" a absolutamente todo acierta el **66,67 %**.</mark> El ataque acierta el 69,15 %. La ventaja real sobre la línea base relevante no es de 19,15 puntos: es de **2,5 puntos**.

Y las demás métricas confirman que el clasificador está muy cerca de ser exactamente ese predictor trivial:

- **Exhaustividad del 97,58 %** — dice "miembro" a casi todo lo que es miembro.
- **Precisión del 68,99 %**, apenas 2,3 puntos por encima de la tasa base del 66,67 %, que es lo que obtendría el predictor trivial por definición.

Reconstruyendo la matriz de confusión a partir de las métricas publicadas:

| | Predicho miembro | Predicho no-miembro |
| - | - | - |
| **Miembro real** (24 421) | TP = 23 830 | FN = 591 |
| **No-miembro real** (12 210) | FP = 10 711 | TN = 1 499 |

La tasa de verdaderos negativos es $1499/12\,210 = 12{,}3\,\%$. Es decir: <mark style="background: #8000E1A6;">de cada 100 no-miembros, el ataque identifica correctamente a 12 y acusa erróneamente a 88.</mark> La **precisión balanceada** —la métrica honesta cuando las clases están desbalanceadas— es:

$$\frac{\text{TPR} + \text{TNR}}{2} = \frac{0{,}9758 + 0{,}1228}{2} = 0{,}5493$$

**Ventaja real ≈ 4,9 puntos**, no 19,15. Y el `AUC` de 0,5675 —independiente del umbral y no afectado por el desbalance— cuenta la misma historia: un ataque débil pero no nulo.

HTB advierte de refilón que "el AUC parece más bajo porque mide todos los umbrales", como si fuera una rareza del AUC. Es al revés: **el AUC es la métrica correcta aquí, y la accuracy es la engañosa**.

> [!warning]+ La consecuencia para el informe
> El ejemplo que da HTB —"un atacante determina con un 69 % de acierto si el historial de un paciente se usó para entrenar; de 1000 consultas obtiene 692 aciertos frente a los 500 del azar, 192 pacientes revelados de más"— **no se sostiene**. Con la misma composición del conjunto, responder "sí" siempre da 667 aciertos. La ganancia atribuible al ataque son 25 consultas, no 192. Publicar la primera cifra en un informe es un hallazgo que el cliente derriba en cuanto lo revise alguien con estadística.

## Cómo se evalúa bien

> [!info]+ El fondo del problema no es de privacidad, es de métricas
> Nada de esto es específico del `MIA`: es el comportamiento estándar de `accuracy`, precisión, exhaustividad y `AUC` sobre clases desbalanceadas, tratado en [[05 - Métricas de evaluación de modelos|métricas de evaluación de modelos]]. Lo que cambia aquí es lo que está en juego — una métrica inflada en un modelo de clasificación da un producto mediocre; en una auditoría de privacidad da un informe que el cliente derriba.

Tres reglas que arreglan el problema, en orden de importancia:

1. **Balancear el conjunto de evaluación** (mismo número de miembros y no-miembros). Entonces —y solo entonces— la línea base es realmente el 50 % y `accuracy − 0,5` significa algo. Es, de hecho, lo que hace el propio HTB en la evaluación de PATE, donde recorta ambos conjuntos al mismo tamaño antes de medir; las dos secciones del módulo usan criterios distintos.
2. **Reportar métricas independientes del umbral**: `AUC` y precisión balanceada. Nunca `accuracy` a secas sobre datos desbalanceados.
3. **Reportar TPR con FPR muy bajo**, que es lo que de verdad importa. Es el punto siguiente.

# Lo que la literatura moderna exige (y HTB no menciona)

<mark style="background: #ADCCFFA6;">La métrica media es la métrica equivocada para privacidad.</mark> Lo formalizaron Carlini et al. en [*Membership Inference Attacks From First Principles*, arXiv:2112.03570](https://arxiv.org/abs/2112.03570) (IEEE S&P 2022), y hoy es el estándar de evaluación:

- Un ataque con `AUC` de 0,57 parece inofensivo **en media**. Pero puede tener un TPR del 10 % con un FPR del 0,1 %: identifica con altísima fiabilidad a un pequeño grupo de individuos. Y eso, en privacidad, **es una brecha total** — para esas personas concretas el modelo filtra por completo.
- Enlaza directamente con la heterogeneidad de [[01 - Por qué los modelos filtran pertenencia|la nota 01]]: los outliers se memorizan mucho más. Una métrica media los promedia con la mayoría típica y los hace desaparecer del informe.
- La forma correcta de presentarlo es la **curva ROC en escala log-log**, mirando la esquina inferior izquierda (FPR de $10^{-3}$ a $10^{-5}$), y citar `TPR@0.1%FPR` como cifra de cabecera.

El mismo trabajo introduce **LiRA** (*Likelihood Ratio Attack*), que formula la pertenencia como un contraste de hipótesis: se ajustan gaussianas por muestra a los *log-odds* de modelos de referencia y se calcula una razón de verosimilitud. Es órdenes de magnitud mejor que el clasificador de Shokri en el régimen de FPR bajo, a costa de entrenar muchos modelos de referencia. **RMIA** ([Zarifzadeh et al., ICML 2024, arXiv:2312.03262](https://arxiv.org/abs/2312.03262)) reduce ese coste drásticamente: usa modelos de referencia **y** datos de población en el contraste, y con solo 1-2 modelos de referencia consigue de 2 a 4 veces más TPR a FPR bajo que LiRA.

> [!important]+ Qué se ejecuta hoy en una auditoría
> Con presupuesto de cómputo: **RMIA** (mejor relación coste/potencia). Con mucho presupuesto y necesidad de la cota más ajustada: **LiRA**. Como cribado rápido de primera pasada: umbral sobre la pérdida. El clasificador entrenado de Shokri es hoy sobre todo valor histórico y didáctico — sigue explicando *por qué* funciona el ataque mejor que ninguna otra formulación.

# Erratas del módulo

> [!warning]+ Cifras inconsistentes en el módulo 335
> La brecha de sobreajuste del modelo objetivo aparece con **cuatro valores distintos** en la misma sección del módulo: `0.0556` (salida de consola), `11.1 %` (pie de figura), `7.1 %` (texto: "90,2 % frente a 83,2 %") y `0.1113` (resultado final). No son variaciones por semilla: están en párrafos contiguos describiendo el mismo modelo.
>
> Se suma a la ventaja mal calculada por el desbalance y al desajuste de regularización entre sombra y objetivo ([[03 - Entrenar los shadow models y el clasificador de ataque|nota 03]]). Mismo patrón que en los módulos 292, 302, 307 y 320 del path: **reproducir y verificar antes de citar cualquier número**.

# Qué se reporta de verdad

En un engagement, el entregable no es un porcentaje de acierto:

| Se reporta | En vez de |
| - | - |
| `AUC` y `TPR@0.1%FPR` sobre conjunto **balanceado** | `accuracy` sobre conjunto desbalanceado |
| Qué **subpoblaciones** son más vulnerables (outliers, clases minoritarias) | Una media global |
| El coste del ataque: consultas al objetivo y cómputo offline | "El ataque funciona" |
| Si el endpoint devuelve probabilidades y si hay `rate limiting` o registro | — |
| Si existe garantía DP declarada y si se ha **verificado** | Aceptar la afirmación del cliente |

Y la conclusión operativa que sí sostiene este experimento: un modelo entrenado sin regularización, sin early stopping, sobre un dataset de decenas de miles de registros personales, **filtra pertenencia de forma medible**. La defensa no consiste en afinar la regularización —eso reduce la señal, no la elimina— sino en una garantía formal: [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|privacidad diferencial]].
