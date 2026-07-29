---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Nota de referencia: no hay que memorizarla, sí volver a ella cuando aparezca una notación desconocida"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Inteligencia artificial, machine learning y deep learning]]"
Nota siguiente: "[[02 - Aprendizaje supervisado]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

Nota de referencia: no hay que memorizarla, sí volver a ella cuando aparezca una notación desconocida. El objetivo no es hacer los cálculos a mano —de eso se encarga `NumPy`— sino **leer papers de ataque y entender qué restringe exactamente un ataque adversarial**. La mitad de la notación de esta nota reaparece literalmente en la definición formal de los ataques de evasión.

# Los datos son vectores; el modelo, operaciones matriciales

Todo dato que entra en un modelo se convierte antes en un vector de números: un email en un vector de frecuencias de términos, una imagen en un vector de píxeles, una conexión de red en un vector de features. <mark style="background: #ADCCFFA6;">Un modelo es, mecánicamente, una cadena de multiplicaciones matriz-vector con una función no lineal intercalada.</mark>

| Operación | Notación | Qué hace |
| - | - | - |
| Producto matriz-vector | `A · v` | Transforma un vector: es lo que hace **una capa** de una red neuronal |
| Producto matriz-matriz | `A · B` | Compone transformaciones; procesa un lote de ejemplos de golpe |
| Traspuesta | `Aᵀ` | Intercambia filas y columnas; aparece en toda derivada matricial |
| Inversa | `A⁻¹` | Deshace la transformación; resuelve sistemas lineales |
| Determinante | `det(A)` | Escalar; si es 0, la matriz **no** es invertible |
| Traza | `tr(A)` | Suma de la diagonal; aparece en el cálculo de autovalores |

## Autovalores y autovectores

Un `eigenvector` de una matriz es un vector cuya dirección no cambia al aplicarle la transformación — solo se estira o encoge por un factor `λ`, su `eigenvalue`:

```text
A · v = λ · v
```

<mark style="background: #FFB8EBA6;">Los autovectores de la matriz de covarianza de un dataset son sus direcciones de máxima varianza.</mark> Esa propiedad es literalmente el algoritmo del [[10 - Análisis de componentes principales (PCA)]], y por extensión la base de muchos detectores de anomalías por reconstrucción.

# Normas: el presupuesto del atacante

Una `norm` mide el tamaño de un vector. Es la herramienta matemática más importante de esta nota, porque <mark style="background: #FF5582A6;">un ataque adversarial se define como "la perturbación más pequeña, bajo una norma concreta, que cambia la predicción"</mark>. Cambiar de norma cambia por completo qué aspecto tiene el ataque.

| Norma | Fórmula | Qué mide | Perturbación que produce |
| - | - | - | - |
| `L0` | nº de componentes ≠ 0 | **Cuántos** valores tocas | Pocos píxeles/bytes alterados, pero sin límite en cuánto |
| `L1` | `\|v₁\| + \|v₂\| + … + \|vₙ\|` | Suma de cambios absolutos (Manhattan) | Cambio disperso y moderado |
| `L2` | `√(v₁² + v₂² + … + vₙ²)` | Distancia euclídea | Cambio repartido y suave sobre todo el vector |
| `L∞` | `max(\|v₁\|, …, \|vₙ\|)` | El cambio **individual** más grande | Todos los valores tocados, ninguno mucho |

> [!important]+ De la norma al ataque
> La correspondencia con las familias de ataque es directa y explica cómo está organizado el temario ofensivo:
> - **`L∞`** → `FGSM` y `PGD`. Se fija un presupuesto `ε` y se perturba *cada* componente como mucho `ε`. Es el ataque canónico contra clasificadores de imagen: imperceptible al ojo porque ningún píxel cambia mucho.
> - **`L2`** → `Carlini & Wagner`. Minimiza la distancia euclídea total; produce los ejemplos adversariales más difíciles de detectar, a cambio de mucho más cómputo.
> - **`L0`** → ataques de **esparsidad**: alterar un puñado mínimo de componentes. Es la norma realista cuando el input no es una imagen sino un binario, una cabecera de red o un fichero estructurado, donde solo puedes tocar unos pocos bytes sin romper el formato.
>
> `L0` no es formalmente una norma (no cumple la homogeneidad), de ahí que se la llame *pseudo-norma*; el nombre se ha quedado por convención.

# Derivadas y gradientes: el mismo mecanismo entrena y ataca

El `gradient` (`∇`) de una función es el vector de sus derivadas parciales: apunta en la dirección de máximo crecimiento. El entrenamiento consiste en calcular el gradiente de la función de pérdida **respecto a los parámetros** del modelo y moverlos en dirección contraria — `gradient descent`.

<mark style="background: #8000E1A6;">El giro ofensivo es cambiar respecto a qué se deriva.</mark> Si en vez del gradiente respecto a los *parámetros* calculas el gradiente respecto a la *entrada*, obtienes la dirección en la que modificar el dato para que el modelo se equivoque lo máximo posible. <mark style="background: #FFB86CA6;">La misma maquinaria de derivación automática que hace útil al modelo es la que permite atacarlo.</mark>

De ahí el nombre **ataques de primer orden**: usan solo la primera derivada, frente a los de segundo orden que necesitarían la matriz hessiana (impracticable en redes grandes). Dentro de esa familia el coste varía:

- **`FGSM`** — un único `backward pass`: se toma el signo del gradiente y se da un paso de tamaño `ε`. Baratísimo y por eso el punto de partida habitual.
- **`PGD`** — el mismo paso repetido decenas de veces, reproyectando tras cada iteración para no salirse del presupuesto `ε`. Más caro y bastante más efectivo; es la referencia con la que se mide la robustez de un modelo.

Todos requieren acceso `white-box` al gradiente. Cuando no lo hay, se estima numéricamente consultando el modelo muchas veces —caro y ruidoso, ver [[12 - Detección y evasión en sistemas de IA]]— o se explota la **transferibilidad**: atacar un sustituto propio y lanzar el resultado contra el objetivo.

# Probabilidad y estadística

| Concepto | Notación | Uso en ML |
| - | - | - |
| Probabilidad condicionada | `P(x \| y)` | Base de [[06 - Naive Bayes]] y de todo modelo discriminativo |
| Esperanza | `E[X] = Σ xᵢ·P(xᵢ)` | Valor medio; define la función de pérdida esperada |
| Varianza | `Var(X) = E[(X − E[X])²]` | Dispersión de una variable alrededor de su media |
| Desviación típica | `σ(X) = √Var(X)` | Varianza en las unidades del dato; umbral típico de anomalía en [[11 - Detección de anomalías]] |
| Covarianza | `Cov(X,Y)` | Cómo varían dos features juntas; matriz de entrada del PCA |
| Correlación | `ρ(X,Y) = Cov(X,Y)/(σ(X)·σ(Y))` | Covarianza normalizada a [−1, 1] |

> [!warning]+ Dos "varianzas" distintas que conviene no confundir
> La de la tabla es la **varianza de una variable aleatoria**: cuánto se dispersan unos datos alrededor de su media. Es una propiedad de los datos.
>
> En la descomposición **sesgo-varianza** la palabra significa otra cosa: cuánto cambiaría el **modelo entrenado** si se le diera otra muestra del mismo problema. <mark style="background: #FFB8EBA6;">Esa segunda varianza sí es la que se relaciona con el sobreajuste</mark> — un modelo de varianza alta memoriza la muestra concreta que vio y cambia por completo con otra. El error esperado se descompone en `sesgo² + varianza + ruido irreducible`, y todo el ajuste de un modelo consiste en negociar entre los dos primeros términos:
> - **Sesgo alto / varianza baja** → subajuste: el modelo es demasiado rígido.
> - **Sesgo bajo / varianza alta** → sobreajuste: el modelo es demasiado flexible.
>
> Es exactamente el motivo de que un [[05 - Árboles de decisión y ensembles|Random Forest]] funcione: promediar muchos árboles de varianza alta reduce la varianza del conjunto sin subir apenas el sesgo.

La correlación importa operativamente por un motivo concreto: features muy correlacionadas provocan `multicollinearity`, que desestabiliza los coeficientes de los modelos lineales y hace que su interpretación deje de ser fiable.

## Logaritmos y entropía

El logaritmo aparece en ML por dos razones: convierte productos en sumas (imprescindible cuando multiplicas miles de probabilidades diminutas y el `float` se desborda a cero) y mide información.

```text
log₂(8) = 3          # bits necesarios para distinguir 8 opciones
ln(e²)  = 2          # logaritmo natural, el que usa el cálculo
```

La `entropía` de Shannon mide la incertidumbre de una distribución:

```text
H(X) = − Σ p(xᵢ) · log₂ p(xᵢ)
```

<mark style="background: #FFB8EBA6;">La entropía se mide siempre **sobre una distribución concreta**, y de qué distribución se hable cambia lo que significa.</mark> El concepto reaparece en tres sitios distintos y en cada uno la distribución es otra:

| Dónde | Distribución medida | Entropía alta significa |
| - | - | - |
| Partición de un [[05 - Árboles de decisión y ensembles\|árbol de decisión]] | Proporción de clases **en los datos** de un nodo | El nodo está mezclado: la partición no separa nada |
| `Cross-entropy` como función de pérdida | Predicción del modelo frente a la etiqueta real | El modelo asigna poca probabilidad a la respuesta correcta: error grande |
| `Perplexity` de un LLM | Distribución sobre el vocabulario en cada token | El modelo está **inseguro** de cuál es el token siguiente |

La `perplexity` es la exponencial de la entropía media por token, así que se lee en unidades intuitivas: una perplejidad de 8 equivale a que el modelo dudase por igual entre 8 opciones en cada paso.

> [!info]+ La perplejidad también es una señal defensiva
> Algunos detectores de contenido generado y de sufijos adversariales se apoyan en ella: el texto producido por un modelo tiende a tener perplejidad **más baja** que el humano bajo ese mismo modelo —es, por construcción, texto que el modelo consideraba probable—, mientras que un sufijo adversarial optimizado por gradiente tiene perplejidad **anormalmente alta**, porque es una cadena que ningún hablante escribiría.
>
> Es una defensa **estadística y frágil**: parafrasear, subir la temperatura de muestreo, o exigir legibilidad al optimizar el sufijo bastan para romperla. Se desarrolla en [[12 - Detección y evasión en sistemas de IA]].

# Notación que aparece en los papers

| Símbolo | Significado |
| - | - |
| `xₜ` | Subíndice: el valor de `x` en el paso/estado `t`. Ubicuo en RL, series temporales y difusión |
| `x^n` | Superíndice: exponenciación |
| `Σᵢ₌₁ⁿ aᵢ` | Sumatorio de la secuencia `a₁ … aₙ` |
| `\|S\|` | Cardinalidad: número de elementos del conjunto `S` |
| `∪` / `∩` / `Aᶜ` | Unión / intersección / complemento de conjuntos |
| `λ` | Autovalor, o parámetro escalar de regularización |
| `f(x)` | Función `f` aplicada a `x` |
| `ε` | Presupuesto de perturbación de un ataque adversarial |

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, reorganizado y reorientado hacia su uso en ML adversarial.
- Encuadre de las normas `L0`/`L2`/`L∞` como restricción de ataque según la taxonomía del [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final) (consultado 2026-07-28).
