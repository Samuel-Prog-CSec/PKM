---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Con acceso al modelo, las good words no se adivinan: se leen directamente de las probabilidades aprendidas, y 20 palabras bastan para evadir el 100% de un filtro de spam real"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - El ataque GoodWords y los clasificadores Naive Bayes]]"
Nota siguiente: "[[03 - GoodWords en caja negra con bandits]]"
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

<mark style="background: #ADCCFFA6;">En caja blanca, las `good words` no se adivinan: se leen directamente de las probabilidades que el modelo aprendió.</mark> Con acceso a `feature_log_prob_` de un Naive Bayes de `scikit-learn`, se calcula la puntuación de bondad exacta de cada palabra del vocabulario y se eligen las óptimas. Contra un filtro de spam SMS real, **veinte palabras bastan para evadir el 100%** de los mensajes.

# El objetivo: un filtro de spam real

Se entrena un `MultinomialNB` sobre el *SMS Spam Collection* de UCI (5.574 mensajes reales, ~12% spam). El pipeline —limpieza que preserva indicadores de spam (`£`, `!!`, números), vectorización con `CountVectorizer`, `stratify` para mantener el desbalance— es el mismo que el detector defensivo de [[03 - Entrenamiento y evaluación del clasificador de spam|Blue Team]]. El clasificador alcanza **98,6% de acierto en test**: un objetivo competente, no un muñeco.

```python
from sklearn.naive_bayes import MultinomialNB
from sklearn.feature_extraction.text import CountVectorizer

vectorizer = CountVectorizer(max_features=3000, stop_words='english',
    token_pattern=r'\b\w+\b|[£$€¥]+|\d+|!!+|\?\?+|\.\.+')
X_train_vec = vectorizer.fit_transform(X_train)
classifier = MultinomialNB().fit(X_train_vec, y_train)
```

<mark style="background: #FFB8EBA6;">El `token_pattern` personalizado captura las features que el spam usa</mark> —símbolos de moneda, dígitos, puntuación repetida— que el tokenizador por defecto tiraría. Un detalle que importa: si el filtro no modela esas features, no puede aprender a detectarlas, pero tampoco el atacante puede abusar de ellas.

# Extraer las good words del modelo

La ventaja de caja blanca es total: `feature_log_prob_` contiene $\log P(w \mid c)$ para cada palabra y clase. El índice `[0]` es ham, el `[1]` spam.

```python
feature_names = vectorizer.get_feature_names_out()
ham_log_probs  = classifier.feature_log_prob_[0]
spam_log_probs = classifier.feature_log_prob_[1]

goodness_scores = []
for i, word in enumerate(feature_names):
    ham_prob  = np.exp(ham_log_probs[i])
    spam_prob = np.exp(spam_log_probs[i])
    goodness  = ham_prob / (spam_prob + 1e-10)          # puntuación de bondad
    goodness_scores.append((word, goodness))

goodness_scores.sort(key=lambda x: x[1], reverse=True)
top_good_words = goodness_scores[:100]
```

El `1e-10` cumple dos funciones: evita dividir por cero cuando una palabra nunca aparece en spam, y mantiene la puntuación finita —una palabra que aparece 100 veces en ham y 0 en spam da una bondad astronómica pero numéricamente estable.

Las palabras ganadoras revelan la naturaleza del corpus (SMS informal): `lor` (jerga singapurense) encabeza con bondad 50,22; le siguen `...`, `later`, `doing`, `lol`. <mark style="background: #FFB86CA6;">Ninguna es sofisticada: son las palabras más cotidianas de la conversación legítima, justo las que el spam nunca usa.</mark>

# El ataque: acumular hasta cruzar la frontera

Se añaden las top-N good words a cada mensaje spam de test y se mide cuántos evaden (probabilidad de ham > spam):

```python
for num_words in [0, 5, 10, 15, 20, 25, 30]:
    selected = [w for w, _ in top_good_words[:num_words]]
    evaded = 0
    for message in spam_test_messages:
        augmented = message + " " + " ".join(selected)
        prob = classifier.predict_proba(vectorizer.transform([augmented]))[0]
        if prob[0] > prob[1]:      # ham gana
            evaded += 1
    print(f"{num_words:2d} palabras | evasión: {evaded/len(spam_test_messages)*100:.1f}%")
```

El resultado es contundente:

| Palabras añadidas | Evasión |
| - | - |
| 0 (baseline) | 6,25 % |
| 5 | 41,41 % |
| 10 | 74,22 % |
| 15 | 96,09 % |
| **20** | **100,00 %** |

<mark style="background: #FF5582A6;">De 5 a 15 palabras, la evasión pasa de 41% a 96%. No es degradación gradual: es colapso.</mark> El baseline de 6,25% es la tasa natural de falsos negativos del modelo (8 de 128 mensajes que ya fallaba sin ataque).

# La forma de la curva: la firma de Naive Bayes

La progresión dibuja una **sigmoide**, y no es casualidad: es la firma matemática de manipular Naive Bayes. En espacio logarítmico cada palabra suma linealmente a la puntuación de ham:

$$\log P(\text{ham} \mid \text{msg}) = \log P(\text{ham}) + \sum_{w \in \text{words}} \log P(w \mid \text{ham})$$

Esa acumulación lineal en log-space se convierte en respuesta sigmoide al volver a espacio de probabilidad vía softmax. Tres fases:

1. **0–5 palabras**: evasión baja, la señal spam aún domina.
2. **5–15 palabras**: transición abrupta, cada palabra empuja la decisión.
3. **15–20 palabras**: saturación al 100%, añadir más no aporta nada.

# El matiz que el atacante necesita: no hay bala de plata

Un análisis palabra a palabra revela algo importante para la estrategia: <mark style="background: #8000E1A6;">ninguna palabra individual voltea la clasificación por sí sola.</mark> La mejor, `lor`, reduce la probabilidad de spam ~4%; el resto, entre 2% y 4%.

Esto es esperable: el modelo aprendió de miles de mensajes, y los indicadores fuertes de spam (`FREE`, `WINNER`, `£900`) acumularon mucha masa de probabilidad. Una sola good word no puede vencer esa evidencia. **El ataque funciona por acumulación orquestada, no por fuerza individual** — y por eso hace falta el umbral de 15-20 palabras. Es una selección *greedy* (las mejores primero); probar todas las combinaciones de 20 palabras de las top-100 serían $5{,}4 \times 10^{20}$ evaluaciones, así que la avaricia es la única vía práctica.

# La lección defensiva

Este ataque demuestra por qué **la seguridad por oscuridad no protege un clasificador**: aquí el atacante tiene acceso total y el ataque es trivial, pero la [[03 - GoodWords en caja negra con bandits|versión de caja negra]] logra casi lo mismo solo con consultas. La vulnerabilidad está en la **arquitectura** (la asunción de independencia aditiva), no en la fuga de parámetros. Las defensas reales —modelar contexto, penalizar el desajuste semántico, [[04 - Detección y defensa contra la evasión|entrenamiento adversarial]]— atacan la arquitectura, no el secreto de los pesos.
