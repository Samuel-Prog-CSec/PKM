---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Pentesting/Explotacion
Descripción: "El MIA explota la diferencia de comportamiento entre datos vistos y no vistos; qué la amplifica: capacidad, tamaño del dataset, regularización y muestras atípicas"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Amenazas de privacidad en modelos de ML]]"
Nota siguiente: "[[02 - El ataque de shadow models]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

<mark style="background: #ADCCFFA6;">La fuga de pertenencia nace de la distancia entre memorizar y generalizar</mark> — el [[02 - Aprendizaje supervisado#El problema central: generalizar, no memorizar|sobreajuste]] de siempre, mirado desde la seguridad en vez de desde la calidad del modelo. El descenso de gradiente ajusta los pesos para reducir la pérdida **sobre las muestras de entrenamiento**, no sobre la distribución. Tras muchas iteraciones el modelo encaja esos ejemplos concretos —a veces perfectamente— y ese encaje no se traslada a datos nuevos. La consecuencia observable es que el modelo **se comporta distinto** ante datos que ha visto y datos que no, y esa diferencia es medible desde fuera.

# Las dos señales

Un `MIA` extrae dos cosas del vector de predicción:

- **Confianza.** Los miembros tienden a recibir predicciones más seguras porque el modelo se optimizó específicamente sobre ellos. Un miembro puede recibir `[0.05, 0.95]` donde un no-miembro con features parecidas recibe `[0.20, 0.80]`.
- **Corrección.** ¿Coincide la clase predicha con la etiqueta real? Los modelos aciertan más sobre sus datos de entrenamiento, porque han visto esas combinaciones exactas de features.

Las dos interactúan, y el patrón conjunto es lo que da la firma:

| Confianza | Correcta | Lectura |
| - | - | - |
| Alta | Sí | Indicador **fuerte** de pertenencia: las dos señales coinciden |
| Alta | No | Sugiere no-pertenencia |
| Baja | — | Caso ambiguo; **aquí vive la mayoría de los errores del ataque** |

<mark style="background: #FFB8EBA6;">Las señales también se contradicen:</mark> un miembro puede recibir baja confianza en una muestra genuinamente ambigua, y un no-miembro alta confianza en una muestra muy típica. El clasificador de ataque aprende a **pesar** ambas según su correlación empírica con la pertenencia, en lugar de aplicar una regla fija.

# Qué amplifica la fuga

Cinco factores determinan cuánto filtra un modelo. Conocerlos sirve para dos cosas: predecir si el ataque va a funcionar antes de gastar cómputo, y **saber qué preguntar en el reconocimiento**.

**Capacidad del modelo.** Más parámetros, más capacidad de memorizar. Una red de 10 capas y 1 M de parámetros memoriza mucho más que una de 2 capas y 10 000. <mark style="background: #FFB86CA6;">Por eso los LLM y las redes profundas son sustancialmente más vulnerables que una regresión logística.</mark>

**Tamaño del conjunto de entrenamiento.** Relación **inversa**: con datasets pequeños, cada ejemplo influye más en los pesos finales y se memoriza una fracción mayor. La misma arquitectura entrenada con 1000 muestras es mucho más vulnerable que con 1 000 000. Es la razón por la que el módulo obtiene solo un 1,9 % de ventaja sobre CIFAR-10 (50 000 muestras, 5000 por clase): el volumen actúa como regularización implícita.

**Duración y regularización.** Es lo único bajo control directo del defensor. Entrenar muchas épocas sin regularización maximiza el sobreajuste; `dropout` fuerte (0,5), `weight decay` y `early stopping` reducen la brecha. En el módulo se ve explotado a la inversa: el modelo objetivo se configura con **dropout 0,0 y 100 épocas sin early stopping** precisamente para fabricar una víctima vulnerable.

**Número de clases de salida.** Más clases, más señal por consulta. Una clasificación binaria da poca información por predicción; con 100 o 1000 clases, la distribución `softmax` revela patrones de confianza mucho más finos. Los ataques contra clasificadores tipo ImageNet superan sistemáticamente a los de clasificadores binarios.

**Heterogeneidad de los datos.** El factor más importante y el peor entendido:

> [!important]+ La vulnerabilidad no se reparte por igual
> Las muestras **atípicas** —cerca de la frontera de decisión, con combinaciones raras de features— se memorizan mucho más que las típicas. Un ataque puede alcanzar el **80 % de acierto sobre outliers y solo el 55 % sobre muestras típicas** del mismo modelo. <mark style="background: #FF5582A6;">Traducido a personas: en el mismo modelo, unos individuos están gravemente expuestos y otros apenas.</mark> Y son justamente los atípicos —el paciente con la combinación rara de síntomas, el cliente con el perfil inusual— los más fáciles de reidentificar y los que más daño sufren si se les reidentifica.

Esa no uniformidad tiene una consecuencia metodológica de primer orden: **las métricas medias mienten**. Un modelo con una ventaja media del 2 % puede estar filtrando al 100 % la pertenencia de las 50 personas más atípicas de su dataset. Es exactamente el argumento por el que la literatura moderna abandonó `accuracy` y `AUC` medias en favor de **TPR con FPR muy bajo** — el detalle está en [[04 - Ejecución y evaluación del MIA|la nota de evaluación]].

# La brecha de sobreajuste: necesaria pero no suficiente

La métrica que se usa como proxy de vulnerabilidad es la **brecha de sobreajuste**: precisión en entrenamiento menos precisión en test. En el módulo, el modelo objetivo llega a ~93,6 % sobre miembros y ~82,5 % sobre no-miembros — una brecha de ~11 puntos que el ataque explota.

Dos matices que el módulo no señala y que cambian la conclusión de una auditoría:

- **Brecha grande ⇒ fuga.** La implicación funciona en esta dirección: si hay una brecha de 10 puntos, hay señal explotable, y punto.
- **Brecha pequeña ⇏ sin fuga.** La recíproca **es falsa**. Un modelo que generaliza bien en promedio puede seguir memorizando sus muestras atípicas. La brecha es una media, y las medias esconden colas. Un modelo con 1 % de brecha puede filtrar por completo a un subconjunto pequeño de individuos.

<mark style="background: #8000E1A6;">Por eso "nuestro modelo generaliza bien, no tiene problema de privacidad" no es una respuesta válida en un engagement.</mark> Generalización media y privacidad individual son cosas distintas; solo la privacidad diferencial ([[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|nota 05]]) ofrece una garantía por individuo.

# Lo que se pregunta en el reconocimiento

Antes de montar el ataque, estas respuestas dicen si merece la pena y cuánto va a costar:

| Pregunta | Por qué importa |
| - | - |
| ¿El endpoint devuelve el vector `softmax` completo o solo la etiqueta? | Sin probabilidades, el ataque pierde su señal principal y hay que caer en variantes basadas solo en corrección |
| ¿Cuántas clases tiene? | Más clases, más información por consulta |
| ¿Cuál es el tamaño aproximado del dataset? | Datasets pequeños ⇒ mucha más memorización |
| ¿Qué arquitectura y cuántos parámetros? | Determina la capacidad de memorización y si un modelo sombra puede parecerse |
| ¿Hay regularización declarada (dropout, early stopping, weight decay)? | Reduce la brecha; su ausencia es un indicador directo |
| ¿Se puede obtener datos de la misma distribución? | Es el requisito real para montar modelos sombra |
| ¿Hay `rate limiting` o registro de consultas? | Determina si el sondeo es detectable — normalmente **no** lo es |
| ¿El modelo declara garantía DP con un $\varepsilon$ concreto? | Si la declara, el trabajo pasa de atacar a **auditar la afirmación** |

La última fila es la que más valor aporta en un engagement moderno: cada vez más clientes afirman entrenar con privacidad diferencial, y verificar esa afirmación —no simplemente creerla— es donde está el hallazgo. Se cubre en [[11 - Arsenal para auditoría de privacidad|el flujo de auditoría de privacidad]].

Con la señal identificada, el problema del atacante es cómo **entrenar un clasificador que la reconozca** sin conocer el conjunto de entrenamiento del objetivo. Esa es la aportación de [[02 - El ataque de shadow models|los modelos sombra]].
