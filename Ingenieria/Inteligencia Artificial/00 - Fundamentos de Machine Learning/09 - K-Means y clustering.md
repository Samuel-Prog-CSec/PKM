---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "K-means reparte un dataset en K grupos disjuntos minimizando la varianza dentro de cada grupo"
Fecha de actualización: 2026-07-28
Nota previa: "[[08 - Aprendizaje no supervisado]]"
Nota siguiente: "[[10 - Análisis de componentes principales (PCA)]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">`K-means` reparte un dataset en `K` grupos disjuntos minimizando la varianza dentro de cada grupo.</mark> Es el algoritmo de clustering más usado por ser simple, rápido y escalable. En seguridad aparece agrupando familias de malware, perfilando comportamiento de usuarios y, sobre todo, como motor de detectores de anomalías basados en distancia al centroide.

# El algoritmo

1. **Inicialización** — elegir `K` centroides iniciales.
2. **Asignación** — asignar cada punto al centroide más cercano según una métrica de distancia, normalmente euclídea.
3. **Actualización** — recalcular cada centroide como la media de los puntos que le fueron asignados.
4. **Iteración** — repetir asignación y actualización hasta que los centroides dejen de moverse o se alcance un máximo de iteraciones.

La distancia euclídea entre dos puntos con `n` features:

```text
d(x, y) = √( Σ (xᵢ − yᵢ)² )
```

> [!warning]+ La inicialización aleatoria pura es una mala práctica
> El paso 1 descrito como "elegir `K` puntos al azar" es la versión original de 1957 y tiene un problema serio: <mark style="background: #FFB8EBA6;">k-means converge a un mínimo local, y una mala inicialización produce clusters malos de forma reproducible</mark>. La solución estándar desde 2007 es **`k-means++`**, que elige los centroides iniciales de forma dispersa y probabilística. Es el valor por defecto de `scikit-learn` (`init='k-means++'`) y no hay motivo para usar otra cosa.
>
> Complementariamente, se ejecuta el algoritmo varias veces con semillas distintas y se conserva el mejor resultado (`n_init`). Un k-means de una sola pasada con inicialización aleatoria es un resultado que no se puede defender en un informe.

# Elegir `K`

`K` es un parámetro que hay que fijar antes de entrenar y no existe un método definitivo para acertar.

## Método del codo

![Gráfica del método del codo mostrando la caída del WCSS con un cambio de pendiente marcado](https://academy.hackthebox.com/storage/modules/290/k_means_elbow.png)

Se ejecuta k-means para un rango de valores de `K` y se representa el `WCSS` (suma de cuadrados intra-cluster) frente a `K`. El WCSS siempre baja al aumentar `K` —con `K` igual al número de puntos vale cero—, así que no se busca el mínimo sino el **punto de inflexión**: donde la mejora empieza a ser marginal.

Su debilidad es que el codo con frecuencia no existe o es ambiguo, y la lectura acaba siendo subjetiva.

## Análisis de silueta

Más cuantitativo. Para cada punto se calcula un `silhouette score` entre −1 y 1:

| Valor | Interpretación |
| - | - |
| ≈ 1 | El punto encaja bien en su cluster y mal en los vecinos |
| ≈ 0 | Está justo en la frontera entre dos clusters |
| ≈ −1 | Probablemente está asignado al cluster equivocado |

Se promedia sobre todos los puntos para cada `K` y se elige el `K` con la media más alta. Da un criterio defendible, aunque tiende a favorecer clusters esféricos — precisamente el sesgo del propio algoritmo.

## Criterio de dominio

<mark style="background: #FFB8EBA6;">Ninguna métrica sustituye a saber para qué se está agrupando.</mark> Si el objetivo es asignar cada cluster a un equipo de analistas y solo hay tres equipos, `K = 12` es inútil aunque su silueta sea mejor. El coste computacional y la interpretabilidad de los grupos resultantes pesan tanto como el número.

# Supuestos y cuándo fallan

| Supuesto | Consecuencia si no se cumple |
| - | - |
| Clusters **esféricos** | Con grupos alargados o curvos, k-means los parte por la mitad. Usar `DBSCAN` o `GMM` |
| Clusters de **tamaño similar** | Un cluster grande absorbe a los pequeños vecinos |
| Features **escaladas** | La feature con mayor rango domina la distancia y el resto se ignora |
| Pocos **outliers** | Un valor extremo arrastra su centroide y deforma el cluster entero |

La sensibilidad a outliers es especialmente relevante en seguridad, porque los outliers son exactamente lo que se quiere estudiar. Cuando el objetivo es detectar, `K-medoids` (que usa puntos reales como centros en vez de medias) o `DBSCAN` (que aísla el ruido) son mejores opciones.

# Envenenar un detector basado en centroides

Aquí está el ángulo ofensivo que hace que este algoritmo importe en un engagement. Muchos detectores de anomalías funcionan así: se calcula el centroide del tráfico normal y se marca como sospechoso todo lo que quede a más de cierta distancia. Reentrenan de forma continua con el tráfico observado.

<mark style="background: #8000E1A6;">Como el centroide es una media, cada punto que el atacante inyecta lo desplaza un poco.</mark> El ataque consiste en enviar tráfico ligeramente desviado hacia la región donde se quiere operar, durante el tiempo suficiente para que el detector reaprenda esa región como normal, y solo entonces ejecutar la actividad real. <mark style="background: #FFB86CA6;">El detector no genera ninguna alerta, porque para cuando llega el ataque real, ya lo ha aprendido como comportamiento habitual.</mark>

## Por qué la ventana deslizante es lo que lo hace viable

Merece un cálculo, porque decide si el ataque es práctico o pura teoría. Añadir un punto `x` a una media de `n` observaciones la desplaza:

```text
μ_nuevo − μ_viejo = (x − μ_viejo) / (n + 1)
```

El efecto por punto decae como `1/n`. Contra un detector que acumulase **todo** el histórico, el desplazamiento sería inviable: con un millón de observaciones acumuladas, cada punto inyectado mueve el centroide una millonésima de su distancia, y haría falta un volumen de tráfico comparable al histórico completo.

<mark style="background: #FF5582A6;">Pero ningún detector real acumula todo el histórico</mark>, porque entonces no podría adaptarse al `concept drift`: la normalidad cambia sola y el modelo tiene que seguirla. Por eso todos operan con una **ventana deslizante** o con media exponencialmente ponderada, donde lo antiguo expira.

Eso invierte el problema: el atacante no compite contra toda la historia, solo contra el contenido de la ventana. Basta con aportar una fracción suficiente de **esa** ventana, y el resto del histórico caduca solo. La misma propiedad que permite al detector adaptarse a los cambios legítimos es la que permite al atacante inducir un cambio ilegítimo — no hay forma de tener una sin la otra ajustando parámetros.

> [!important]+ El trabajo de referencia
> [Kloft & Laskov, *Security Analysis of Online Centroid Anomaly Detection* (JMLR 2012)](https://www.jmlr.org/papers/v13/kloft12b.html) formaliza este ataque y calcula cuánto tráfico hace falta inyectar para desplazar el centroide una distancia dada. La conclusión operativa: <mark style="background: #FF5582A6;">con reentrenamiento continuo y sin límite en la influencia de cada muestra, el desplazamiento es solo cuestión de paciencia</mark>.
>
> Las mitigaciones son de diseño, no de tuning: acotar cuánto puede mover cada muestra el modelo, usar estimadores robustos (mediana en vez de media), validar el conjunto de reentrenamiento contra una línea base congelada, y limitar la tasa de datos que un único origen puede aportar.

Este patrón —el atacante contribuye al conjunto de entrenamiento simplemente usando el sistema— reaparece idéntico en [[11 - Detección de anomalías]] y es una de las categorías de envenenamiento del NIST.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con `k-means++`, las alternativas ante supuestos incumplidos y el ataque de desplazamiento de centroide, ausentes en el original.
- [Kloft & Laskov, *Security Analysis of Online Centroid Anomaly Detection*, JMLR 13 (2012)](https://www.jmlr.org/papers/v13/kloft12b.html) — envenenamiento de detectores basados en centroide (consultado 2026-07-28).
- Imagen del método del codo: HTB Academy, módulo 290.
