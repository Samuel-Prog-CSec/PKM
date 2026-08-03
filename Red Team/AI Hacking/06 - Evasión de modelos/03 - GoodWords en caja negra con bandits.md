---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Sin acceso al modelo, descubrir las good words es exploración con presupuesto de consultas: bandits multi-armed y UCB logran el 85-95% de la efectividad de caja blanca"
Fecha de actualización: 2026-07-29
Nota previa: "[[02 - GoodWords en caja blanca]]"
Nota siguiente: "[[04 - Detección y defensa contra la evasión]]"
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

<mark style="background: #ADCCFFA6;">Sin acceso a las probabilidades del modelo, descubrir las `good words` deja de ser un cálculo y se convierte en un problema de exploración con presupuesto de consultas.</mark> Es el escenario realista: solo se puede enviar un mensaje y observar el score que devuelve el clasificador, sin ver arquitectura, parámetros ni datos. Y aun así, con técnicas de *multi-armed bandits*, el ataque logra el **85-95% de la efectividad de la caja blanca** — la prueba de que ocultar el modelo apenas protege.

# El cambio de problema: de optimizar a explorar

En [[02 - GoodWords en caja blanca|caja blanca]] leíamos la puntuación de bondad directamente. En caja negra hay que **descubrir** qué palabras funcionan probándolas, y cada consulta cuesta (tiempo, dinero, riesgo de detección). El objetivo se reformula: encontrar el menor conjunto de palabras que minimice el score de spam, dentro de un **presupuesto de consultas** limitado.

El clasificador se modela como una función caja negra $f: \mathcal{X} \rightarrow [0,1]$ que solo se puede consultar. Cada consulta enseña algo; la pregunta es cómo gastar el presupuesto para aprender lo máximo.

# Multi-armed bandits: el marco correcto

Descubrir qué palabra funciona mejor probando es exactamente el problema del **bandido multi-brazo**: tienes muchas palancas (palabras), cada una con una recompensa desconocida (cuánto reduce el spam), y un presupuesto de tiradas. El dilema es el de siempre: **explorar** palabras poco probadas o **explotar** las que ya funcionan.

## UCB: equilibrar con matemática

La estrategia `Upper Confidence Bound` puntúa cada palabra sumando su rendimiento observado y un bono de exploración:

$$\text{UCB}(w) = \bar{r}_w + c\sqrt{\frac{\ln(t)}{n_w}}$$

- $\bar{r}_w$ — recompensa media observada (**explotación**): las palabras que funcionaron puntúan alto.
- $c\sqrt{\ln(t)/n_w}$ — bono de **exploración**: crece para palabras poco probadas ($n_w$ pequeño en el denominador) y decrece según se prueban.

<mark style="background: #FFB86CA6;">La magia está en que el bono de exploración encoge según se prueba una palabra: la incertidumbre sobre su rendimiento se reduce, y la explotación acaba dominando.</mark>

> [!example]+ La decisión contraintuitiva de UCB
> Tras 200 consultas: `thanks` probada 50 veces con impacto medio 0,15 → UCB = 0,15 + 0,47 = **0,62**. `appreciate` probada 5 veces con 0,12 → UCB = 0,12 + 1,48 = **1,60**. UCB elige `appreciate` **pese a su peor rendimiento observado**, porque el bono de exploración (1,48) compensa la incertidumbre de haberla probado solo 5 veces. Quizá su efectividad real es 0,20 y tuvimos mala suerte. Una palabra nunca probada tiene UCB = ∞: siempre se explora primero.

UCB da garantías de *regret* logarítmico: la diferencia acumulada entre nuestras elecciones y la óptima crece como $O(\log T)$, no linealmente. En la práctica, con recompensas ruidosas por la variabilidad entre mensajes, sigue siendo una heurística muy efectiva.

# La implementación: tres fases

El ataque real (HTB usa una variante `epsilon-greedy` más simple que UCB para la implementación, con la misma idea de bandit) reparte el presupuesto en **40-40-20**:

## Fase 0 — vocabulario candidato (0 consultas)

Antes de gastar una sola consulta, se construye *offline* un pool de palabras candidatas: frecuencias de mensajes ham legítimos (de un corpus propio), diccionario común, términos conversacionales curados (`thanks`, `tomorrow`, `sorry`...), filtrando indicadores obvios de spam. Esta fase no toca el modelo objetivo.

```python
def build_candidate_vocabulary(X_train, y_train):
    # frecuencias de palabras en mensajes ham + términos conversacionales curados
    freq = extract_ham_word_freq(X_train, y_train)
    top  = select_high_frequency_words(freq, max_words=100, min_freq=5)
    return merge_with_curated(top, ["ok","later","thanks","tomorrow","sorry","yeah",...])
```

## Fase 1 — exploración (40%)

Probar un abanico amplio de candidatos contra mensajes spam variados, midiendo el impacto de cada palabra con dos consultas (baseline + aumentado). El score se actualiza con una **media móvil exponencial** (EMA), que da 30% de peso a lo nuevo y 70% a lo histórico, para no sobre-reaccionar a un resultado atípico:

```python
def update_word_score(scorer, word, impact, alpha=0.3):
    old = scorer['word_scores'].get(word)
    scorer['word_scores'][word] = impact if old is None else (1-alpha)*old + alpha*impact
```

## Fase 2 — explotación (40%)

Concentrar las consultas en las ~15-30 mejores palabras de la Fase 1, refinando sus estimaciones y reduciendo la varianza. Se baja la tasa de exploración y se prueba sobre menos mensajes para afinar.

## Fase 3 — combinación (20%): las sinergias

La pieza que la caja blanca no capturaba fácilmente. Se buscan **combinaciones super-aditivas**: pares y tríos de palabras cuyo efecto conjunto supera la suma de sus efectos individuales.

```python
# sinergia = impacto_real_del_par - (impacto_individual_1 + impacto_individual_2)
synergy = actual_impact - (score.get((word1,),0) + score.get((word2,),0))
if synergy > 0:
    combination_scores[(word1, word2)] = actual_impact
```

<mark style="background: #8000E1A6;">Las palabras semánticamente relacionadas se potencian:</mark> `meeting` + `tomorrow` juntas señalan comunicación de agenda legítima con más fuerza que por separado. Los tríos como `meeting` + `tomorrow` + `thanks` pueden reducir la probabilidad de spam un 40-50%, muy por encima de la suma de sus partes. Es información que el modelo aprendió del contexto de sus datos de entrenamiento, y que el atacante descubre sin verlo.

# El resultado: la oscuridad no protege

Con 1.000 consultas, el ataque de caja negra descubre palabras **distintas pero igual de efectivas** que la caja blanca, y alcanza una curva de evasión ligeramente menos pronunciada pero comparable.

| | Caja blanca | Caja negra |
| - | - | - |
| Acceso | Parámetros del modelo | Solo consultas |
| Selección | Puntuación de bondad exacta | Descubrimiento por bandits |
| Efectividad | 100% @ 20 palabras | **85-95% del white-box** con 1.000 consultas |

> [!important]+ La conclusión para el defensor
> <mark style="background: #FF5582A6;">Ocultar los internos del modelo da seguridad limitada frente a un atacante adaptativo.</mark> El ataque de caja negra tiene éxito porque la vulnerabilidad está en la **arquitectura** del clasificador (la independencia aditiva), no en la fuga de información. Las palabras descubridas empíricamente pueden diferir de las teóricamente óptimas —una palabra con alta bondad teórica puede tener bajo impacto práctico, y viceversa— pero el ataque converge igual. La defensa no es esconder; es [[04 - Detección y defensa contra la evasión|cambiar el modelo]] o vigilar el patrón de consultas.

# Detección del ataque de caja negra

A diferencia de la caja blanca, el ataque de caja negra **es ruidoso**: genera miles de consultas de sondeo con un patrón anómalo (variaciones sistemáticas del mismo mensaje base, cobertura del espacio de palabras). Ese patrón de consulta es la señal que un defensor puede monitorizar — el paralelo exacto de la detección de [[01 - Model reverse engineering y robo de modelos#Detección y mitigación|model extraction]], porque en el fondo el descubrimiento de good words *es* una forma de extracción parcial del comportamiento del modelo. La detección y las defensas completas están en [[04 - Detección y defensa contra la evasión]].
