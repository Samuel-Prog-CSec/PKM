---
tags:
  - IA
  - IA/Machine-Learning
Descripción: "El Principal Component Analysis reduce el número de dimensiones de un dataset proyectándolo sobre las direcciones que concentran más varianza"
Fecha de actualización: 2026-07-28
Nota previa: "[[09 - K-Means y clustering]]"
Nota siguiente: "[[11 - Detección de anomalías]]"
Area: "[[Fundamentos de ML.base|Fundamentos de ML]]"
---
---

<mark style="background: #ADCCFFA6;">El `Principal Component Analysis` reduce el número de dimensiones de un dataset proyectándolo sobre las direcciones que concentran más varianza.</mark> No selecciona features existentes: construye variables nuevas —los componentes principales— que son combinaciones lineales de las originales y están ordenadas por cuánta información capturan.

![Datos en 3D proyectados a 2D mediante PCA conservando la estructura](https://academy.hackthebox.com/storage/modules/290/pca.png)

Se usa para tres cosas: visualizar datos de muchas dimensiones, reducir ruido, y comprimir la entrada de otros modelos para esquivar la maldición de la dimensionalidad.

# La idea: varianza es información

PCA parte de una asunción: **las direcciones en las que los datos más varían son las que más información contienen**, y aquellas en las que apenas varían son redundantes o ruido.

Tres conceptos lo sostienen:

- **Varianza** — cuánto se dispersan los datos. PCA busca maximizarla en cada componente.
- **Covarianza** — cómo varían dos features juntas. Si están muy correlacionadas, una es parcialmente redundante.
- **Autovectores y autovalores** — los autovectores de la matriz de covarianza son las direcciones de máxima varianza; los autovalores dicen cuánta varianza captura cada uno.

## Autovectores en una frase

Un autovector es un vector que una transformación matricial **no rota**, solo escala:

```text
A · v = λ · v
```

Aplicando `A = [[2,0],[0,1]]` al vector `v = [1,0]` se obtiene `[2,0]`: misma dirección, doble longitud. `v` es autovector y `λ = 2` su autovalor.

# El algoritmo

1. **Estandarizar** — restar la media y dividir por la desviación típica de cada feature.
2. **Calcular la matriz de covarianza** de los datos estandarizados.
3. **Obtener autovectores y autovalores** de esa matriz.
4. **Ordenar** los autovectores por autovalor descendente.
5. **Seleccionar** los `k` primeros.
6. **Proyectar** los datos originales sobre ellos: `Y = X · V`.

> [!warning]+ El paso 1 no es opcional y su ausencia es un error silencioso
> PCA maximiza varianza, y la varianza depende de las unidades. <mark style="background: #FF5582A6;">Sin estandarizar, la feature medida en la escala más grande se convierte automáticamente en el primer componente principal</mark>, sin que eso signifique nada. En un dataset de red, "bytes transferidos" aplastaría a "número de flags TCP" simplemente por su rango.

En la práctica se resuelve por **`SVD`** (descomposición en valores singulares) en vez de por descomposición espectral directa: es numéricamente más estable y no requiere construir explícitamente la matriz de covarianza. Es lo que hace `scikit-learn` por debajo.

# Cuántos componentes conservar

Se representa la **ratio de varianza explicada** acumulada frente al número de componentes y se elige el punto que alcanza un umbral aceptable, típicamente el 95%. Esa cifra es una convención, no una ley: si el objetivo es visualizar, se usan 2 o 3 componentes aunque expliquen el 40%; si es alimentar un modelo, conviene subir.

# Supuestos y límites

| Supuesto | Implicación |
| - | - |
| `Linealidad` | Solo captura relaciones lineales. Estructuras curvas se pierden |
| `Correlación` | Si las features son independientes, no hay nada que comprimir |
| `Escala` | Exige estandarización previa |
| Varianza = información | Falso cuando la señal útil es de baja varianza — el caso típico en detección |

Ese último punto merece atención. <mark style="background: #FFB8EBA6;">En seguridad, la señal de interés suele ser justamente la de baja varianza</mark>: un ataque sigiloso mueve poco los datos. PCA puede descartar como ruido exactamente el componente donde vive el ataque.

Y un límite práctico que se paga caro en detección: **PCA no selecciona features, las mezcla**. Cada componente es una combinación lineal de todas las variables originales, así que decir "saltó la alerta por el componente 3" no es explicable para un analista ni defendible en un informe. <mark style="background: #FF5582A6;">Si el sistema necesita justificar sus decisiones, PCA rompe esa cadena</mark>; cuando hace falta reducir dimensionalidad **conservando** la interpretabilidad, hay que usar selección de features (que descarta columnas enteras pero mantiene las que quedan) en lugar de proyección.

## Alternativas no lineales

- **`t-SNE`** y **`UMAP`** — para visualización. Conservan la estructura local mucho mejor que PCA. <mark style="background: #FFB8EBA6;">Advertencia importante: las distancias globales y los tamaños relativos de los clusters en un gráfico t-SNE **no significan nada**</mark>; interpretarlos como si fueran distancias reales es un error frecuente en informes.
- **Autoencoders** — reducción no lineal aprendida por una red neuronal. Más potentes y opacos; base de muchos detectores de anomalías modernos.

# PCA como detector de anomalías, y cómo se envenena

Un uso muy extendido: entrenar PCA sobre tráfico normal, proyectar cada observación nueva al subespacio de los `k` primeros componentes, reconstruirla, y medir el **error de reconstrucción**. Si un dato no encaja en la estructura aprendida, se reconstruye mal y salta la alerta. Es la base de detectores de anomalías en toda la red.

<mark style="background: #FFB86CA6;">Y es atacable de forma directa, porque el subespacio se estima a partir de los datos observados.</mark> Inyectando tráfico diseñado para inflar la varianza en una dirección concreta, el atacante consigue que esa dirección entre en el subespacio "normal" — y a partir de ahí su actividad se reconstruye perfectamente y deja de generar error.

> [!important]+ Demostrado sobre un detector real, no en laboratorio
> [Rubinstein et al., *ANTIDOTE: Understanding and Defending against Poisoning of Anomaly Detectors* (ACM IMC 2009)](https://dl.acm.org/doi/10.1145/1644893.1644895) atacaron un detector de anomalías de red basado en subespacio PCA. Con envenenamiento sostenido durante semanas, la tasa de detección de los ataques posteriores **se desplomó**. Su defensa, `ANTIDOTE`, sustituye PCA por una versión robusta basada en estimadores que acotan la influencia de cada muestra.
>
> La lección se generaliza a cualquier detector no supervisado que reentrene con datos que el atacante puede influir: <mark style="background: #8000E1A6;">la línea base es parte de la superficie de ataque</mark>.

Un apunte de privacidad para cerrar: proyectar datos con PCA **no los anonimiza**. Los componentes son combinaciones lineales invertibles sobre el subespacio conservado, y con la matriz de proyección se reconstruye una aproximación fiel del original. Tratar un dataset "PCA-transformado" como si fuera seudonimizado es un error de cumplimiento, no solo técnico.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con alternativas no lineales, el límite "varianza ≠ información útil en detección", el envenenamiento del subespacio y la nota de privacidad, ausentes en el original.
- [Rubinstein et al., *ANTIDOTE: Understanding and Defending against Poisoning of Anomaly Detectors*, ACM IMC 2009](https://dl.acm.org/doi/10.1145/1644893.1644895) — envenenamiento de detectores basados en PCA (consultado 2026-07-28).
- Imagen de proyección 3D→2D: HTB Academy, módulo 290.
