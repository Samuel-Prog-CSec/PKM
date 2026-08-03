---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "GoodWords evade un filtro Naive Bayes añadiendo palabras legítimas al spam: la independencia asumida suma la evidencia, y basta acumular bastante para invertir la decisión"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Fundamentos de la evasión de modelos]]"
Nota siguiente: "[[02 - GoodWords en caja blanca]]"
Area: "[[Evasión de modelos.base|Evasión de modelos]]"
---
---

<mark style="background: #ADCCFFA6;">El ataque `GoodWords` evade un filtro de spam Naive Bayes añadiendo palabras legítimas al mensaje, sin tocar el contenido malicioso.</mark> Es el ataque de evasión canónico sobre clasificadores clásicos: simple, matemáticamente transparente y **imposible de parchear sin cambiar el modelo**, porque explota la asunción que define a Naive Bayes. Lo introdujeron Lowd y Meek en 2005 ([*Good Word Attacks on Statistical Spam Filters*](https://www.ceas.cc/papers-2005/125.pdf)), y sigue siendo la mejor forma de entender por qué los clasificadores de features son frágiles.

# El talón de Aquiles: la independencia condicional

El fundamento de Naive Bayes está en [[06 - Naive Bayes|su nota de Ingeniería]] y su aplicación al spam en [[01 - Clasificación de spam con Naive Bayes|el detector de Blue Team]]. Lo que importa para el ataque: el clasificador aplica el teorema de Bayes y asume que **las palabras son condicionalmente independientes** dada la clase. Eso permite factorizar la verosimilitud como un producto:

$$P(D \mid C) = \prod_{i=1}^{n} P(w_i \mid C)$$

Para evitar el *underflow* numérico (multiplicar miles de probabilidades diminutas se va a cero), se trabaja en **espacio logarítmico**, donde el producto se convierte en suma:

$$\text{class} = \arg\max_{c \in \{spam, ham\}} \left[ \log P(c) + \sum_{i=1}^{n} \log P(w_i \mid c) \right]$$

<mark style="background: #8000E1A6;">Aquí está toda la vulnerabilidad: la decisión es una **suma** de contribuciones por palabra, y cada palabra que se añade desplaza esa suma.</mark> El modelo no modela relaciones entre palabras ni contexto, así que no puede penalizar el desajuste semántico entre las palabras legítimas añadidas y el spam de debajo.

# La mecánica: inclinar la balanza

Piensa en el clasificador como una balanza que pesa evidencia de spam contra evidencia de ham. Cada palabra añade peso a un lado. `FREE`, `WINNER`, `CLAIM` amontonan evidencia en el lado spam. El ataque añade suficientes palabras del lado ham para que la balanza se incline, **dejando el spam original intacto**.

Formalmente, para un mensaje spam $M_{spam}$ el clasificador calcula la evidencia de cada clase. El ataque añade un conjunto de "good words" $G = \{g_1, ..., g_k\}$ creando $M_{augmented} = M_{spam} \cup G$. La clasificación se invierte —el mensaje pasa por ham— cuando:

$$\sum_{j=1}^{k} [\log P(g_j \mid ham) - \log P(g_j \mid spam)] > \sum_{i=1}^{m} [\log P(w_i \mid spam) - \log P(w_i \mid ham)] + [\log P(spam) - \log P(ham)]$$

En palabras: <mark style="background: #FFB86CA6;">el lado izquierdo es la ventaja hacia ham que aportan las palabras añadidas; el derecho es el obstáculo — la señal spam original más el sesgo del clasificador.</mark> El ataque gana cuando la izquierda supera a la derecha.

> [!example]+ La intuición numérica
> Un mensaje con palabras spam fuertes aporta una diferencia combinada de 8.0 hacia spam. Si añadimos palabras como `meeting`, `tomorrow` y `thanks` que cada una aporta 3.0 hacia ham, necesitamos al menos tres (3 × 3.0 = 9.0) para superar la señal spam e invertir la clasificación. Con quince a treinta palabras bien elegidas, la evasión supera el **90%**.

# Elegir las palabras: la puntuación de bondad

No todas las palabras sirven igual. El ataque busca las de mayor **poder discriminativo hacia la clase legítima**: frecuentes en ham, raras en spam. Se cuantifica con una "puntuación de bondad":

$$S(w) = \frac{P(w \mid ham)}{P(w \mid spam) + \epsilon}$$

donde $\epsilon$ es una constante pequeña que evita dividir por cero cuando una palabra no aparece nunca en spam. Las palabras con puntuación alta —`meeting`, `tomorrow`, `thanks`— aparecen mucho en mensajes legítimos y poco o nada en spam.

Hay una restricción práctica al seleccionarlas: <mark style="background: #FFB8EBA6;">una palabra con buena puntuación puede activar otras heurísticas del filtro o parecer sospechosa a un revisor humano.</mark> La selección incorpora restricciones para que el mensaje aumentado mantenga coherencia lingüística. Y el número de palabras es un equilibrio: pocas no desplazan lo suficiente; demasiadas hacen el mensaje antinatural o superan límites de longitud.

# Por qué funciona: cantidad sobre calidad

Varias decisiones de implementación amplifican la debilidad:

- **La asunción de independencia** hace que las contribuciones se sumen en vez de interactuar. El clasificador no puede detectar que "gana un premio de £900" y "gracias, nos vemos mañana en la reunión" no pegan juntos.
- **Las distribuciones aprendidas son estáticas.** Se fijan en el entrenamiento a partir de datos históricos, así que un atacante puede estudiarlas y elegir las mejores `GoodWords` sistemáticamente.
- **El suavizado** (`Laplace smoothing`) asigna probabilidad no nula a palabras raras o no vistas, lo que impide rechazar combinaciones inusuales y **amplía** el vocabulario disponible para el atacante.

<mark style="background: #FF5582A6;">Dado suficiente material favorable, la cantidad vence a la calidad, y la evidencia acumulada da la vuelta a la señal spam inicial.</mark>

# La generalización

Aunque el ejemplo es spam, el patrón es el de **cualquier clasificador lineal o de bolsa de características**: si la decisión es una suma ponderada de features y el atacante controla qué features están presentes, puede empujar la suma al otro lado del umbral añadiendo features benignas. Se ve en:

- **Detección de malware** por n-gramas o imports: añadir secciones o llamadas benignas.
- **Clasificación de URLs** o de tráfico de red: añadir tokens o campos de aspecto legítimo.
- **Detección de fraude** por reglas: acumular señales normales para diluir las anómalas.

La versión moderna y potente de esta idea, sobre modelos no lineales, son los [[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]] que usan el gradiente para encontrar la perturbación mínima en vez de acumular features a mano. GoodWords es la intuición; el gradiente es la optimización.

En las notas siguientes se implementa GoodWords contra un filtro real, primero con [[02 - GoodWords en caja blanca|acceso total al modelo]] y luego solo con [[03 - GoodWords en caja negra con bandits|consultas]].
