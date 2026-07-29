---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "Un decision tree predice encadenando preguntas binarias sobre las features hasta llegar a una hoja con la respuesta"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Regresión logística]]"
Nota siguiente: "[[06 - Naive Bayes]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">Un `decision tree` predice encadenando preguntas binarias sobre las features hasta llegar a una hoja con la respuesta.</mark> Sirve para clasificación y regresión, y su gran ventaja es que el modelo entrenado **se puede leer**: el camino desde la raíz hasta la hoja es literalmente la explicación de la decisión. En seguridad esto importa mucho, porque un analista necesita saber por qué se disparó una alerta.

Su estructura tiene tres piezas:

- **Nodo raíz** — punto de partida, contiene el dataset completo.
- **Nodos internos** — cada uno evalúa una feature y ramifica según el resultado.
- **Hojas** — el resultado final: una clase o un valor.

![Árbol de decisión con nodos de Outlook, Temperature, Humidity y Wind clasificando en Yes/No](https://academy.hackthebox.com/storage/modules/290/decision_tree_tennis.png)

# Cómo elige el árbol por dónde partir

En cada nodo el algoritmo prueba todas las features y elige la que deja los subconjuntos resultantes más **puros** — es decir, con menos mezcla de clases. La pureza se mide con una de estas tres métricas.

## Impureza de Gini

Probabilidad de clasificar mal un elemento elegido al azar. Cuanto más baja, más puro el nodo.

```text
Gini(S) = 1 − Σ pᵢ²
```

Con 30 instancias de clase `A` y 20 de clase `B` (`p_A = 0,6`, `p_B = 0,4`):

```text
Gini(S) = 1 − (0,6² + 0,4²) = 1 − 0,52 = 0,48
```

## Entropía

Mide el desorden del conjunto, en bits. Un nodo puro tiene entropía 0 y el máximo se alcanza con las clases repartidas por igual: `log₂(k)` para `k` clases — que vale exactamente 1 en el caso binario, pero **1,58 con tres clases y 2 con cuatro**. Conviene tenerlo presente al comparar valores entre problemas con distinto número de clases.

```text
Entropy(S) = − Σ pᵢ · log₂(pᵢ)
```

Con los mismos datos: `Entropy(S) = −(0,6·log₂0,6 + 0,4·log₂0,4) ≈ 0,971`

## Ganancia de información

Reducción de entropía que consigue una partición concreta. El árbol elige la feature que la maximiza.

```text
Information Gain(S, A) = Entropy(S) − Σ (|Sᵥ| / |S|) · Entropy(Sᵥ)
```

En la práctica, Gini y entropía dan árboles casi idénticos; Gini se usa por defecto porque evita calcular logaritmos y sale más rápido.

## Cuándo para de crecer

Sin un criterio de parada, el árbol sigue partiendo hasta que cada hoja tenga un solo ejemplo — sobreajuste perfecto. Hay dos formas de frenarlo:

**Pre-poda** (parar durante la construcción), que es lo habitual:

| Hiperparámetro | Qué limita |
| - | - |
| `max_depth` | Profundidad máxima del árbol |
| `min_samples_split` | Mínimo de ejemplos para que un nodo se pueda partir |
| `min_samples_leaf` | Mínimo de ejemplos que debe quedar en cada hoja resultante |
| `max_features` | Cuántas features se consideran en cada partición |

**Post-poda** (construir el árbol completo y recortar después). En `scikit-learn` es la poda por coste-complejidad, controlada por `ccp_alpha`: penaliza el número de hojas y elimina las ramas que no compensan su coste. <mark style="background: #FFB8EBA6;">Suele dar árboles mejores que la pre-poda</mark>, porque una partición aparentemente inútil puede habilitar otra muy buena justo debajo — algo que un criterio de parada temprano nunca llega a descubrir.

# Supuestos: casi ninguno

Es su otra gran virtud frente a los modelos lineales:

- **Sin supuesto de linealidad** — capturan relaciones no lineales sin transformar nada.
- **Sin supuesto de normalidad** — no importa cómo se distribuyan las features.
- **Robustos a outliers** — parten por valores de corte, no calculan distancias, así que un valor extremo solo afecta a su rama.
- **Sin necesidad de escalado** — a diferencia de SVM o k-means, mezclar features en escalas distintas no les molesta.

# Ensembles: lo que realmente se despliega

<mark style="background: #FFB8EBA6;">Un árbol individual tiene varianza altísima</mark>: cambiar unos pocos ejemplos del entrenamiento puede producir un árbol completamente distinto. Por eso **nadie despliega un árbol suelto**; se despliegan conjuntos de árboles. HTB no cubre esta parte, y es exactamente lo que vas a encontrar en producción.

| Técnica | Cómo combina | Representantes |
| - | - | - |
| `Bagging` | Entrena árboles en paralelo sobre muestras aleatorias y promedia | `Random Forest` |
| `Boosting` | Entrena árboles en secuencia, cada uno corrigiendo el error del anterior | `XGBoost`, `LightGBM`, `CatBoost` |

- **`Random Forest`** — cada árbol ve una muestra `bootstrap` distinta y, en cada partición, solo un subconjunto aleatorio de features. Esa doble aleatoriedad decorrelaciona los árboles y hunde la varianza. Es el modelo del detector de anomalías de red de [[04 - Detección de anomalías de red con Random Forest]].
- **`Gradient Boosting`** — cada árbol nuevo se entrena sobre los residuos del conjunto anterior. Más preciso que `Random Forest` pero más sensible a los hiperparámetros y más fácil de sobreajustar.

> [!important]+ En datos tabulares, los árboles siguen ganando
> Pese a la narrativa de que el deep learning lo ha absorbido todo, <mark style="background: #FF5582A6;">los ensembles de árboles con boosting siguen siendo el estado del arte en datos tabulares</mark>, que es el formato de casi todo dato de seguridad: logs, flujos de red, features extraídas de binarios, telemetría de EDR. El trabajo de referencia es [Grinsztajn et al., *Why do tree-based models still outperform deep learning on typical tabular data?* (NeurIPS 2022)](https://arxiv.org/abs/2207.08815), que lo atribuye a que los árboles manejan mejor las features irregulares y no informativas, abundantes en datos reales.
>
> Consecuencia práctica: si auditas un producto de seguridad basado en ML, es más probable que por dentro haya un `XGBoost` que una red neuronal.

# Lectura ofensiva

Los árboles se comportan de forma muy distinta a los modelos diferenciables, y eso cambia el arsenal:

<mark style="background: #8000E1A6;">Un árbol no es diferenciable</mark>: su salida es constante a trozos y el gradiente es cero en casi todas partes. Los ataques de primer orden tipo `FGSM` o `PGD` **no aplican directamente**. Contra ellos se usan ataques basados en decisión (que solo observan la etiqueta de salida), búsqueda sobre los umbrales, o transferencia desde un modelo sustituto diferenciable.

Pero esa aparente robustez engaña. <mark style="background: #FFB86CA6;">Las particiones son paralelas a los ejes</mark>: cada nodo compara **una** feature contra **un** umbral. Si consigues inferir esos umbrales, la evasión es exacta y mínima — basta empujar una feature justo por encima o por debajo del corte, sin tocar nada más. Es una evasión de tipo `L0` puro, y encaja perfectamente con inputs estructurados donde no puedes alterar muchos campos sin romper el formato.

Dos vectores más, específicos de esta familia:

- **La interpretabilidad juega para ambos bandos.** Los `feature importances` de un árbol —cuánto reduce la impureza cada feature— y los valores **`SHAP`** —la contribución de cada feature a *una predicción concreta*, repartida según la teoría de juegos cooperativos— existen para que el defensor pueda justificar por qué el modelo decidió lo que decidió. <mark style="background: #FF5582A6;">Ese mismo artefacto le dice al atacante exactamente qué variables mover y en qué dirección</mark>, y con `SHAP` incluso para el caso puntual que quiere evadir. Publicar explicabilidad detallada de un modelo de detección es publicar el mapa de su evasión.
- **Extracción de modelo.** La estructura discreta de un árbol lo hace reconstruible con relativamente pocas consultas: el espacio de hipótesis es finito y cada respuesta acota los umbrales. Un ensemble complica la tarea, pero no la impide. Ver [[07 - Ataques a los componentes del modelo]].

La ubicación de esta familia dentro del mapa general de superficies está en [[11 - Superficie de ataque por familia de modelos]], y su evasión práctica sobre un detector real en [[08 - Límites y evasión de los detectores ML]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la sección de ensembles (`Random Forest`, boosting), ausente por completo en el original.
- [Grinsztajn, Oyallon & Varoquaux, *Why do tree-based models still outperform deep learning on typical tabular data?*, NeurIPS 2022](https://arxiv.org/abs/2207.08815) — vigencia de los árboles en datos tabulares (consultado 2026-07-28).
- Imagen del árbol de decisión: HTB Academy, módulo 290.
