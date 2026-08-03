---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Tipo/Defensa
Descripción: "El estudiante aprende de etiquetas ruidosas y se despliega sin coste por consulta; la agregación confiada mejora la calidad, pero el filtro de HTB filtra información"
Fecha de actualización: 2026-07-29
Nota previa: "[[08 - PATE, ensemble de profesores y agregación con ruido]]"
Nota siguiente: "[[10 - Detección y evasión en ataques de privacidad]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

El estudiante entrena sobre los datos públicos con las pseudo-etiquetas generadas por la votación ruidosa, con entrenamiento supervisado corriente. <mark style="background: #ADCCFFA6;">Como nunca toca los datos sensibles, su entrenamiento **no consume presupuesto de privacidad**: se puede entrenar 30 épocas o 300, reiniciar, cambiar de arquitectura o reajustar hiperparámetros sin afectar a la garantía</mark>, que se gastó entera en la fase de etiquetado.

# Destilación con etiquetas duras

PATE es destilación de conocimiento con una diferencia importante. La destilación clásica transfiere **distribuciones de probabilidad blandas**, que dan más señal de entrenamiento. PATE usa **etiquetas duras** (el `argmax` de los votos ruidosos) porque las probabilidades blandas filtrarían mucho más: revelarían las confianzas del ensemble y, con ellas, información sobre los datos de entrenamiento de los profesores.

Resultados sobre MNIST: ensemble limpio ~92 %, estudiante ~88 %. **Unos 4 puntos de coste**, muy por debajo de los 9-14 de [[07 - El compromiso privacidad-utilidad de DP-SGD|DP-SGD]] sobre CIFAR-10 (tareas distintas, así que la comparación es indicativa, no directa).

## Por qué el ruido de etiquetas no lo rompe

Dos razones, y la segunda es más general de lo que parece:

1. **El ruido no se reparte por igual.** Las muestras con consenso alto reciben etiquetas correctas casi siempre porque el margen es enorme. Solo se voltean las que los profesores ya discutían. El estudiante recibe **supervisión limpia en los casos claros** y ruidosa en los genuinamente ambiguos — y los claros dominan el aprendizaje porque dan gradientes consistentes.
2. **Las redes toleran ruido aleatorio de etiquetas.** Entrenadas con SGD aguantan un 20-40 % de etiquetas corrompidas siempre que la corrupción sea **aleatoria y no sistemática**. <mark style="background: #8000E1A6;">El ruido de PATE cumple exactamente esa condición: una muestra no recibe etiqueta errónea por sus features, sino porque una extracción laplaciana concreta volteó la votación.</mark> Al no correlacionar con los datos, el modelo no puede aprender a explotar el patrón de ruido.

## Inferencia ilimitada

A diferencia de las técnicas que añaden ruido **en inferencia**, el estudiante de PATE responde de forma determinista y sin coste. Millones de consultas no gastan nada. Es la ventaja operativa decisiva frente a DP-SGD para servicios de alto tráfico: <mark style="background: #FFB86CA6;">todo el presupuesto se paga una vez, en la fase de etiquetado.</mark>

# Análisis de consenso

No todas las pseudo-etiquetas valen lo mismo. Con 250 profesores sobre 10 clases:

| Consenso | Votos máximos | Precisión limpia | Efecto del ruido |
| - | - | - | - |
| **Alto** | ≥ 200 (80 %) | ~98 % | Tasa de volteo ≈ 0 |
| **Medio** | 150-199 (60-80 %) | ~85 % | Volteos ocasionales |
| **Bajo** | < 150 | ~65 % | El ruido domina |

El patrón refleja la correlación confianza-corrección: cuando 200+ profesores coinciden en un dígito, casi siempre aciertan. Las muestras de consenso bajo son dígitos genuinamente ambiguos (3 frente a 8, 4 frente a 9) donde ni un ensemble experto se pone de acuerdo.

<mark style="background: #FFB8EBA6;">La implicación práctica: las muestras de consenso bajo aportan señal débil **incluso antes** de añadir ruido.</mark> Después del ruido son casi inútiles — pero han gastado exactamente el mismo presupuesto de privacidad que las buenas.

En el montaje del módulo la distribución está muy sesgada hacia el consenso alto (la mayoría de muestras en el rango 230-250 votos de 250), que es la razón por la que la escala de ruido 20 apenas voltea nada y el coste de privacidad en el etiquetado sale por debajo de 1 punto.

# Agregación confiada

La optimización es evidente una vez visto el cuadro: **etiquetar solo donde hay consenso**.

```python
def confident_aggregation(votes, noise_scale, threshold):
    max_votes = votes.max(axis=1)
    confident_mask = max_votes >= threshold          # <-- comprobación SIN ruido
    labels = np.full(len(votes), -1, dtype=np.int64) # -1 = centinela "sin etiqueta"

    if confident_mask.sum() > 0:
        confident_votes = votes[confident_mask]
        noise = np.random.laplace(0.0, noise_scale, size=confident_votes.shape)
        labels[confident_mask] = np.argmax(confident_votes.astype(np.float64) + noise, axis=1)

    return labels, confident_mask
```

El centinela `-1` funciona porque las clases válidas son enteros no negativos; se filtran esas filas antes de entrenar al estudiante. Con umbral 200 se acepta ~85 % de las consultas, y el argumento de HTB es que **las consultas rechazadas no gastan presupuesto** porque no se publica ninguna etiqueta.

> [!warning]+ Ese argumento es incorrecto tal y como está implementado
> <mark style="background: #FF5582A6;">La comprobación `max_votes >= threshold` se hace **sin ruido** sobre los recuentos reales de votos.</mark> El resultado de esa comprobación —aceptar o rechazar— es información dependiente de los datos privados, y es observable para quien vea qué muestras acabaron etiquetadas. Un atacante aprende, por cada muestra consultada, si el consenso de los profesores superaba 200: eso **es** una fuga, y no está contabilizada en ningún $\varepsilon$.
>
> El PATE de 2018 ([arXiv:1802.08908](https://arxiv.org/abs/1802.08908)) resuelve justamente esto: la comprobación de umbral **también lleva ruido** (se compara el recuento máximo más ruido gaussiano contra el umbral) y **su coste se contabiliza** en el presupuesto. El ahorro sigue existiendo —una consulta rechazada cuesta bastante menos que una respondida—, pero no es gratis. Implementar el filtro sin ruido y declarar coste cero da una garantía que no se sostiene.

Con esa corrección, la agregación confiada sigue siendo una buena idea: mejora la calidad de las etiquetas **y** reduce el gasto. Lo que no se puede es contabilizarla como lo hace el módulo.

# El compromiso de la escala de ruido

| Escala | $\epsilon_0$ por consulta | Precisión de etiqueta |
| - | - | - |
| 5 | 0,40 | ~95 % |
| 10 | 0,20 | ~92 % |
| **20** | **0,10** | **~87 %** |
| 40 | 0,05 | ~78 % |
| 80 | 0,025 | ~65 % |

La asimetría es la información útil: pasar de 5 a 20 mejora muchísimo la privacidad (el $\varepsilon$ total baja de ~35 a ~9) con un coste modesto (95 % → 87 %). Pasar de 20 a 80 da rendimientos decrecientes en privacidad mientras la precisión se hunde al 65 %. <mark style="background: #8000E1A6;">La escala 20 está en el codo de la curva</mark>; el rango operativo útil va de 10 a 40.

# Estrategias de despliegue

Según qué esté fijado por el contexto:

| Restricción | Estrategia |
| - | - |
| **Presupuesto $\varepsilon$ fijo** (regulatorio) | Maximizar etiquetas dentro del presupuesto: búsqueda binaria sobre el número de consultas que caben |
| **Número de etiquetas fijo** | Minimizar el coste de privacidad para ese objetivo: consultar `objetivo / tasa_aceptación` |
| **Datos públicos abundantes** | Muestreo iterativo: consultar hasta acumular N muestras de consenso alto (con 85 % de aceptación y objetivo 5000, ~5900 consultas) |

En la práctica, la segunda es la natural: normalmente se sabe cuántas muestras de entrenamiento necesita el estudiante.

# Sensibilidad a los hiperparámetros

**Número de profesores.** Un compromiso directo: menos profesores ⇒ más datos por cabeza ⇒ modelos individuales más fuertes, pero señal de consenso más débil. Más profesores ⇒ individuos más débiles, consenso más informativo. El punto óptimo depende de la dificultad de la tarea: tareas fáciles toleran muchos profesores; las difíciles se benefician de menos y más fuertes. Con 250 profesores sobre MNIST cada uno ve solo ~192 muestras y aun así rinde 74-82 %, lo que dice más de lo fácil que es MNIST que de lo bueno que es el reparto.

**Presupuesto de consultas.** Más consultas ⇒ más datos para el estudiante ⇒ más $\varepsilon$, con escalado sublineal (duplicar consultas sube $\varepsilon$ un ~40 %).

# El problema de equidad que nadie menciona

<mark style="background: #FFB86CA6;">Los datasets desbalanceados producen consenso desigual, y esa desigualdad se propaga al estudiante.</mark> Los profesores alcanzan consenso alto en las clases mayoritarias —ven más ejemplos, coinciden más— y consenso bajo en las minoritarias. Consecuencias en cadena:

1. Las clases minoritarias reciben etiquetas más ruidosas.
2. Con **agregación confiada**, además son las que más se **rechazan**: el filtro por consenso descarta desproporcionadamente a la minoría.
3. El estudiante rinde peor en las clases minoritarias que el ensemble original.

El muestreo estratificado en la fase de etiquetado mitiga pero no elimina el efecto: la disparidad de consenso sigue ahí. Es un caso concreto de un patrón general —**las defensas de privacidad degradan más a los grupos minoritarios**— que también aparece en DP-SGD, donde el recorte de gradiente afecta más a las muestras atípicas, que son precisamente las de los grupos poco representados. En un informe de auditoría de IA con componente de equidad, este cruce merece su propio hallazgo.

Qué señal deja un ataque de privacidad y qué defensas de salida aguantan es [[10 - Detección y evasión en ataques de privacidad|la nota de detección]]; las herramientas y el flujo completo de una auditoría, [[11 - Arsenal para auditoría de privacidad|el arsenal]].
