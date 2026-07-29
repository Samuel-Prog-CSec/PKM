---
tags:
  - IA
  - IA/Deep-Learning
Descripción: "Un Multi-Layer Perceptron (MLP) apila varias capas de neuronas con activaciones no lineales, superando así el límite del perceptrón simple"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Deep learning y el perceptrón]]"
Nota siguiente: "[[02 - Redes neuronales convolucionales (CNN)]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Un `Multi-Layer Perceptron` (MLP) apila varias capas de neuronas con activaciones no lineales, superando así el límite del perceptrón simple.</mark> Con al menos una capa oculta puede aprender fronteras de decisión no lineales, y con ello resolver problemas como `XOR` que un perceptrón nunca podrá.

![Arquitectura de red neuronal totalmente conectada con capa de entrada, dos capas ocultas y capa de salida](https://academy.hackthebox.com/storage/modules/290/neural_network.png)

# Anatomía

- **Capa de entrada** — una neurona por feature. No calcula nada, distribuye.
- **Capas ocultas** — cada neurona recibe todas las salidas de la capa anterior, calcula una suma ponderada, suma el sesgo y aplica su activación. Es donde ocurre el aprendizaje de representaciones.
- **Capa de salida** — su tamaño y activación dependen de la tarea: una neurona con `sigmoid` para clasificación binaria, `n` neuronas con `softmax` para `n` clases, una neurona lineal para regresión.

La profundidad importa porque cada capa construye sobre la anterior: las primeras aprenden combinaciones simples de las features, las siguientes combinan esas combinaciones. Esa jerarquía es lo que da expresividad.

> [!info]+ El teorema de aproximación universal y su letra pequeña
> Está demostrado que una red con **una sola** capa oculta suficientemente ancha puede aproximar cualquier función continua con la precisión deseada. Suele citarse como justificación teórica del deep learning, pero conviene leerlo entero: el teorema dice que la red **existe**, no que se pueda **encontrar** por descenso de gradiente, ni con cuántos datos, ni que el ancho requerido sea práctico. En la práctica <mark style="background: #FFB8EBA6;">las redes profundas y estrechas aprenden mejor que las anchas y planas</mark>, y ese hecho empírico es el que sostiene la disciplina, no el teorema.

# Entrenamiento

El bucle tiene cuatro fases que se repiten:

1. **Paso hacia delante** — los datos atraviesan la red y se obtiene una predicción.
2. **Cálculo de la pérdida** — la función de pérdida cuantifica el error frente al objetivo.
3. **Paso hacia atrás (`backpropagation`)** — se propaga el error hacia atrás aplicando la regla de la cadena, obteniendo el gradiente de la pérdida respecto a cada peso y sesgo.
4. **Actualización** — el optimizador mueve los parámetros en dirección contraria al gradiente. El tamaño del paso lo fija la `learning rate`.

En la práctica no se procesa el dataset entero de una vez sino en **lotes** (`mini-batches`); una pasada completa por todos los datos es una **época**.

> [!warning]+ "Los lotes pequeños ayudan a escapar de mínimos locales" es la explicación antigua
> Es lo que se repite en casi todo el material introductorio y ya no se sostiene. En espacios de altísima dimensión los **mínimos locales malos son raros**: lo que abunda son puntos de silla, y de esos se sale con casi cualquier ruido.
>
> Lo que sí está respaldado hoy: el ruido del lote pequeño actúa como **regularización implícita** y tiende a llevar a mínimos más "planos", que generalizan mejor. <mark style="background: #FFB8EBA6;">El compromiso real del tamaño de lote es generalización frente a aprovechamiento de la GPU</mark>, no escapar de mínimos. Al subir mucho el lote hay que subir también la tasa de aprendizaje y añadir *warmup* para no perder calidad.

## Gradiente evanescente

El motivo real de que la sigmoide se abandonara en capas ocultas, y que casi nunca se explica:

<mark style="background: #8000E1A6;">La derivada de la sigmoide vale como máximo 0,25.</mark> `Backpropagation` multiplica las derivadas de todas las capas por las que pasa el error. En una red de 10 capas, el gradiente que llega a la primera se ha multiplicado por factores ≤ 0,25 diez veces: `0,25¹⁰ ≈ 10⁻⁶`. El gradiente se desvanece y **las capas iniciales dejan de aprender**.

`ReLU` lo resuelve porque su derivada vale exactamente 1 en la región positiva: el gradiente atraviesa la red sin atenuarse. Ese cambio, más las conexiones residuales, es lo que hizo entrenables las redes de decenas o cientos de capas.

Pero `ReLU` trae su propio fallo: su derivada es exactamente **0** en la región negativa. Una neurona que acabe emitiendo siempre valores negativos deja de recibir gradiente y **no vuelve nunca** — es la `dying ReLU`, y con tasas de aprendizaje altas puede inutilizar una fracción importante de la red en silencio. Las variantes que lo evitan (`Leaky ReLU`, `GELU`, `SiLU`) dejan una pendiente pequeña en negativo, y por eso son las que usan los modelos actuales.

## El problema simétrico: gradiente explosivo

Si los factores que se multiplican son **mayores** que 1, el producto crece exponencialmente en vez de decaer. <mark style="background: #FFB86CA6;">El síntoma es inconfundible: la pérdida salta a `NaN` en mitad del entrenamiento</mark>, porque una actualización gigante saca los pesos de rango.

Es más frecuente en secuencias largas —[[03 - Redes neuronales recurrentes (RNN)]] es el caso típico— y se corrige con **recorte de gradiente** (`gradient clipping`): antes de actualizar, si la norma del gradiente supera un umbral, se reescala. Es una línea de código y se pone por defecto en cualquier entrenamiento de modelos grandes.

## Regularización específica de redes

El sobreajuste en redes profundas se combate con técnicas propias, además de la penalización `L1`/`L2` vista en [[02 - Aprendizaje supervisado]]:

- **`Dropout`** — durante el entrenamiento se desactiva aleatoriamente un porcentaje de neuronas en cada paso. Impide que la red dependa de neuronas concretas y fuerza representaciones redundantes.
- **`Batch normalization`** — normaliza las activaciones usando la media y la varianza **del lote**. Estabiliza y acelera el entrenamiento, con efecto regularizador colateral. Dos matices que importan: durante la inferencia no hay lote, así que usa estadísticas acumuladas — de ahí que **`model.eval()` sea obligatorio** y que olvidarlo dé predicciones distintas en cada ejecución. Y su justificación original ("reduce el *internal covariate shift*") está hoy en entredicho: la explicación mejor respaldada es que suaviza la superficie de pérdida.
- **`Layer normalization`** — normaliza sobre las features de **cada ejemplo**, no sobre el lote. Es la que usan los `transformers`, precisamente porque no depende del tamaño ni de la composición del lote y funciona con secuencias de longitud variable. Ver [[04 - Transformers y el mecanismo de atención]].
- **`Early stopping`** — detener el entrenamiento cuando la pérdida de validación deja de mejorar, aunque la de entrenamiento siga bajando.

# La superficie de ataque de una red entrenada

## Acceso a los pesos = ataque óptimo

<mark style="background: #FFB86CA6;">Con los pesos en la mano, el atacante tiene exactamente lo mismo que tuvo el equipo de entrenamiento: el grafo completo y derivable.</mark> Puede calcular el gradiente respecto a la entrada y generar ejemplos adversariales óptimos con `FGSM` o `PGD`, sin límite de consultas ni riesgo de detección por volumen. Por eso, en cualquier evaluación, **encontrar el fichero del modelo es el hallazgo que convierte un objetivo `black-box` en `white-box`**.

Sitios donde aparecen: buckets S3 mal configurados, imágenes de contenedor con el modelo empaquetado, artefactos de CI, endpoints de descarga sin autenticar en aplicaciones móviles y de escritorio.

## El fichero del modelo puede ser el propio exploit

Y aquí está el vector que casi nadie de seguridad tradicional tiene en el radar:

> [!warning]+ Cargar un checkpoint no confiable es ejecución de código
> Los formatos `.pt`, `.pth`, `.ckpt` y `.pkl` serializan con `pickle` de Python, que **ejecuta código durante la deserialización por diseño**. <mark style="background: #FF5582A6;">Un modelo malicioso descargado de un repositorio público no necesita ninguna vulnerabilidad: basta con que la víctima lo cargue.</mark>
>
> `torch.load` cambió su valor por defecto a `weights_only=True` en **PyTorch 2.6** (enero de 2025), que restringe el `unpickler` a los tipos necesarios para reconstruir un `state_dict`. Es una mitigación real, pero con dos grietas: el ecosistema está lleno de código y de tutoriales que pasan `weights_only=False` para "arreglar" errores de carga, y los checkpoints antiguos obligan a ello. Ver la [discusión del cambio en PyTorch](https://dev-discuss.pytorch.org/t/bc-breaking-change-torch-load-is-being-flipped-to-use-weights-only-true-by-default-in-the-nightlies-after-137602/2573).
>
> El formato seguro es **`safetensors`**: almacena solo tensores y metadatos, sin capacidad de ejecución. Encontrar `.pkl`/`.pt` cargados con `weights_only=False` desde una ruta que un tercero controla es un hallazgo de RCE, y hay que reportarlo como tal.

Esto conecta con lo que en el vault ya está cubierto para otros lenguajes: es deserialización insegura clásica, aplicada al ecosistema de ML. El detalle en `Hacking web/Deserialization/` cuando se extraiga ese módulo.

<mark style="background: #8000E1A6;">Y no es un problema exclusivo de PyTorch.</mark> El patrón "el formato de modelo ejecuta código al cargarse" se repite en todo el ecosistema —`joblib`, `H2O`, `MLeap`, TorchScript—, con decenas de CVE publicadas por ello. El inventario de dónde aparece en un despliegue real y cómo buscarlo está en [[10 - Ataques a los componentes de sistema]]; el encuadre por familia de modelo, en [[11 - Superficie de ataque por familia de modelos]].

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con la explicación del gradiente evanescente, técnicas de regularización de redes, el matiz del teorema de aproximación universal y el vector de deserialización en ficheros de modelo, ausentes en el original.
- [PyTorch Developer Mailing List — cambio de `weights_only` a `True` por defecto](https://dev-discuss.pytorch.org/t/bc-breaking-change-torch-load-is-being-flipped-to-use-weights-only-true-by-default-in-the-nightlies-after-137602/2573) (consultado 2026-07-28).
- Imagen de arquitectura de red: HTB Academy, módulo 290.
