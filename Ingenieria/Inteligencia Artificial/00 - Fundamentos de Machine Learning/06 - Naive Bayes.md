---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Naive Bayes es un clasificador probabilístico basado en el teorema de Bayes que asume que todas las features son independientes entre sí dada la clase"
Fecha de actualización: 2026-07-28
Nota previa: "[[05 - Árboles de decisión y ensembles]]"
Nota siguiente: "[[07 - Máquinas de vectores de soporte (SVM)]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">`Naive Bayes` es un clasificador probabilístico basado en el teorema de Bayes que asume que todas las features son independientes entre sí dada la clase.</mark> Esa asunción es casi siempre falsa —de ahí el "naive"— y aun así el algoritmo funciona sorprendentemente bien, entrena en segundos y necesita muy pocos datos. Fue el motor de los filtros antispam durante dos décadas y sigue siendo el punto de partida de cualquier clasificador de texto.

# El teorema de Bayes

Permite actualizar una creencia sobre un suceso cuando llega evidencia nueva:

```text
P(A|B) = [ P(B|A) · P(A) ] / P(B)
```

| Término | Nombre | Significado |
| - | - | - |
| `P(A\|B)` | Posterior | Probabilidad de `A` **después** de observar `B` |
| `P(B\|A)` | Verosimilitud | Probabilidad de observar `B` si `A` es cierto |
| `P(A)` | Prior | Probabilidad de `A` antes de ver nada |
| `P(B)` | Evidencia | Probabilidad total de observar `B` |

## El ejemplo que hay que interiorizar

Una enfermedad afecta al 1% de la población. El test detecta al 95% de los enfermos y tiene un 5% de falsos positivos. Alguien da positivo: ¿qué probabilidad tiene de estar enfermo?

```text
P(B) = P(B|A)·P(A) + P(B|¬A)·P(¬A)
     = (0,95 · 0,01) + (0,05 · 0,99)
     = 0,0095 + 0,0495 = 0,059

P(A|B) = (0,95 · 0,01) / 0,059 ≈ 0,161
```

**16,1%.** Un test con 95% de sensibilidad produce, sobre esta población, más de cinco falsos positivos por cada acierto.

> [!important]+ Esto no es estadística de manual: es tu ratio de falsos positivos en el SOC
> El resultado anterior es la `base rate fallacy`, y explica el problema operativo más grande de la detección basada en ML. <mark style="background: #FF5582A6;">Cuando la clase que buscas es rara —y en seguridad siempre lo es—, incluso un detector muy preciso genera mayoritariamente falsos positivos.</mark>
>
> Con 1.000.000 de sesiones diarias de las que 100 son maliciosas (0,01%), un detector con 99% de detección y 1% de falsos positivos produce 99 detecciones correctas y **9.999 falsas alarmas**. El analista descarta el 99% de lo que ve, y ahí es donde muere la detección: no por el modelo, sino por la tasa base. <mark style="background: #8000E1A6;">Por eso los proveedores presumen de `accuracy` y los que operan el sistema preguntan por la precisión y el recall</mark> — ver [[05 - Métricas de evaluación de modelos]].

# Cómo clasifica

1. **Calcular los priors** — la frecuencia de cada clase en el entrenamiento. Por ejemplo, 20% spam / 80% legítimo.
2. **Calcular las verosimilitudes** — para cada feature y cada clase, la probabilidad de observarla. ¿Cuál es la probabilidad de ver la palabra "free" dado que el correo es spam?
3. **Aplicar Bayes** — combinar prior y verosimilitudes para obtener el posterior de cada clase.
4. **Predecir** — asignar la clase con mayor posterior.

La asunción de independencia es lo que hace el paso 2 barato: en vez de estimar la probabilidad conjunta de todas las combinaciones de palabras (imposible), se multiplican probabilidades individuales.

## Variantes

| Variante | Tipo de feature | Uso típico |
| - | - | - |
| `Gaussian NB` | Continuas, distribución normal | Features numéricas: edad, duración de conexión, tamaño de fichero |
| `Multinomial NB` | Conteos discretos | Clasificación de texto por frecuencia de términos — el estándar en antispam |
| `Bernoulli NB` | Binarias (presente/ausente) | Documentos donde solo importa si una palabra aparece, no cuántas veces |

# Dos detalles de implementación que hunden el modelo si faltan

HTB no los menciona y son la diferencia entre un clasificador que funciona y uno que devuelve ceros.

**Suavizado de Laplace.** Si una palabra del correo a clasificar no apareció nunca en el entrenamiento para una clase, su verosimilitud es 0 y, al multiplicarse, **anula el posterior completo** de esa clase. Se corrige sumando una constante `α` (típicamente 1) a todos los conteos. Sin este ajuste, una sola palabra desconocida decide la clasificación entera.

**Cálculo en espacio logarítmico.** Multiplicar cientos de probabilidades pequeñas provoca `underflow`: el resultado se redondea a cero en coma flotante. Se trabaja siempre sumando logaritmos en vez de multiplicando probabilidades — la misma propiedad que se explicó en [[01 - Matemáticas para machine learning]].

> [!warning]+ Sus probabilidades no son probabilidades
> Un tercer detalle, y el que más engaña en la práctica. <mark style="background: #FF5582A6;">`Naive Bayes` produce posteriores pésimamente calibrados</mark>: casi siempre 0,999 o 0,001, casi nunca valores intermedios.
>
> La causa es directamente la asunción de independencia. Cuando varias features están correlacionadas —y en texto lo están: "free", "prize" y "winner" aparecen juntas— el modelo cuenta **la misma evidencia varias veces** al multiplicar sus verosimilitudes, y el posterior se satura hacia los extremos.
>
> La consecuencia operativa importa: <mark style="background: #8000E1A6;">un 0,99 de `Naive Bayes` **no** significa 99% de probabilidad real de ser spam</mark>, así que ajustar el umbral de bloqueo sobre esos valores es engañoso, y compararlos con los de otro modelo no tiene sentido. El orden que produce sí es útil (rankea bien), la magnitud no. Si hace falta la probabilidad de verdad, hay que recalibrar (`CalibratedClassifierCV` con Platt o isotónica) o usar directamente [[04 - Regresión logística]], que sí sale calibrada de fábrica.

# El clasificador que más ataques adversariales ha recibido

Los filtros bayesianos fueron el primer sistema de ML masivamente desplegado en seguridad y, por tanto, el primero masivamente atacado. Las técnicas que se inventaron contra ellos siguen siendo el molde conceptual de los ataques actuales.

- **`Good word attack`** — añadir al correo un bloque de palabras fuertemente asociadas al correo legítimo (nombres propios, jerga corporativa, texto de un boletín real) para arrastrar el posterior hacia la clase benigna. Formalizado por [Lowd & Meek, *Good Word Attacks on Statistical Spam Filters* (CEAS 2005)](https://www.cs.washington.edu/homes/pedrod/papers/ceas05.pdf). <mark style="background: #FFB86CA6;">Es evasión pura: el mensaje malicioso sigue intacto, solo se le añade lastre estadístico.</mark> Ejecutado paso a paso contra un clasificador real en [[02 - Manipulación del modelo]].
- **Envenenamiento bayesiano** — enviar deliberadamente correos que el usuario marcará mal, o inundar el buzón con mensajes que contaminan las estadísticas de palabras. Explota que <mark style="background: #FFB8EBA6;">el filtro se reentrena continuamente con etiquetas que aporta el usuario</mark>, sin ninguna verificación de esa fuente.
- **Ofuscación de tokens** — separadores invisibles, homoglifos Unicode, texto embebido en imagen. Rompe la tokenización antes de que el modelo llegue a ver las palabras; el fallo concreto que esto provoca en un pipeline real está en [[02 - Preprocesamiento de texto y extracción de features]].

La implementación completa del clasificador —dataset, preprocesado, entrenamiento y evaluación— está en [[01 - Clasificación de spam con Naive Bayes]].

> [!warning]+ Naive Bayes suelto es legado, pero el vector sigue vivo
> Ningún antispam serio de 2026 es solo bayesiano: hoy se combinan reputación de IP y dominio, autenticación (`SPF`/`DKIM`/`DMARC`), análisis de URL y modelos basados en `transformers`. Aun así, <mark style="background: #FF5582A6;">Naive Bayes sobrevive como componente o como una señal más dentro del ensemble</mark>, y sigue siendo la primera opción para clasificadores internos hechos a medida — donde el `good word attack` funciona exactamente igual que en 2005.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la conexión `base rate fallacy` ↔ falsos positivos en detección, el suavizado de Laplace y la historia adversarial del algoritmo, ausentes en el original.
- [Lowd & Meek, *Good Word Attacks on Statistical Spam Filters*, CEAS 2005](https://www.cs.washington.edu/homes/pedrod/papers/ceas05.pdf) — evasión por inyección de términos benignos (consultado 2026-07-28).
