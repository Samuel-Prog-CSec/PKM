---
tags:
  - IA
  - IA/Generativa
Descripción: "Un modelo de difusión aprende a generar destruyendo: añade ruido a los datos hasta convertirlos en ruido puro y entrena una red para revertir ese proceso paso a paso"
Fecha de actualización: 2026-07-28
Nota previa: "[[06 - Grandes modelos de lenguaje (LLM)]]"
Nota siguiente: "[[00 - Entorno de trabajo para IA]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Un modelo de difusión aprende a generar destruyendo: añade ruido a los datos hasta convertirlos en ruido puro y entrena una red para revertir ese proceso paso a paso.</mark> Generar consiste entonces en partir de ruido aleatorio y aplicar la reversión hasta obtener una muestra coherente. Es la arquitectura dominante en imagen, audio y vídeo.

![Rejilla de 100 pasos mostrando la transformación progresiva de ruido aleatorio en una imagen reconocible](https://academy.hackthebox.com/storage/modules/290/diffusion_full.png)

# Proceso directo: añadir ruido

Se corrompe la muestra original en `T` pasos pequeños hasta llegar a ruido gaussiano puro:

```text
x_t = q(x_t | x_{t-1})        para t = 1 … T
```

Cada paso depende solo del anterior (propiedad de Markov). La cantidad de ruido por paso la fija el **`noise schedule`**; el esquema lineal es el más simple:

```text
β_t = β_min + (t / T) · (β_max − β_min)
```

El diseño del `schedule` importa mucho más de lo que parece: determina en qué régimen de ruido se entrena la red y, con ello, la calidad final. El lineal es el original; el **`cosine schedule`** destruye la información de forma más gradual al final del proceso y se ha impuesto en la mayoría de implementaciones.

> [!important]+ La pieza que hace viable el entrenamiento: el salto directo
> Descrito así, el proceso directo parece exigir simular `T` pasos (a menudo 1.000) para obtener una muestra ruidosa. Sería inviable. <mark style="background: #FFB8EBA6;">No hace falta: la suma de gaussianas es gaussiana, así que existe **forma cerrada** para saltar de `x₀` a cualquier `x_t` en una sola operación.</mark>
>
> ```text
> ᾱ_t = Π(1 − β_i)   para i = 1…t          (producto acumulado del schedule)
> x_t = √(ᾱ_t)·x₀ + √(1 − ᾱ_t)·ε           con ε ~ N(0, I)
> ```
>
> De ahí sale el bucle de entrenamiento real, que es sorprendentemente simple:
> 1. Coger una imagen `x₀` del dataset.
> 2. Elegir un paso `t` **al azar** entre 1 y `T`.
> 3. Muestrear ruido `ε` y construir `x_t` con la fórmula de arriba, en un solo paso.
> 4. Pedir a la red que prediga `ε` a partir de `x_t` y `t`, y minimizar el error cuadrático.
>
> Nunca se recorre la cadena completa durante el entrenamiento. Ese detalle es el que hace que el proceso, que parece costosísimo, sea en realidad entrenable — y explica por qué la red recibe `t` como entrada: tiene que saber a qué nivel de ruido se enfrenta.

# Proceso inverso: quitarlo

Se entrena una red —originalmente una U-Net convolucional, hoy cada vez más un `transformer`— para predecir **el ruido** que se añadió en cada paso:

```text
x_{t-1} = p_θ(x_{t-1} | x_t)
```

Con función de pérdida el error cuadrático entre el ruido real y el predicho:

```text
L = E[ ‖ε − ε_pred‖² ]
```

<mark style="background: #FFB8EBA6;">Predecir el ruido en lugar de predecir la imagen limpia es el truco que hace estable el entrenamiento</mark>, y es la diferencia principal frente a los intentos previos de generación iterativa.

El muestreo parte de ruido puro `x_T` y aplica la reversión hasta obtener `x_0`.

<mark style="background: #8000E1A6;">Y aquí sí hay asimetría con el entrenamiento: la reversión **no** tiene forma cerrada</mark> — hay que iterar de verdad. Eso es lo que hace lenta la generación y lo que ha impulsado toda la investigación en muestreadores: `DDIM` y los métodos posteriores producen imágenes de calidad comparable en **20-50 pasos** en lugar de los 1.000 del planteamiento original. Es la diferencia entre segundos y minutos por imagen, y la razón de que el número de pasos sea el primer parámetro que se toca al desplegar.

# Condicionar por texto

Para generar a partir de un prompt hace falta un canal adicional:

1. **Codificar el texto** con un encoder preentrenado (`CLIP` o un `transformer` de texto), obteniendo un vector semántico.
2. **Condicionar el denoising** — la red recibe en cada paso tanto la imagen ruidosa como el embedding del texto.
3. **Muestrear** — el proceso inverso, guiado en cada paso por el embedding, hace converger la imagen hacia la descripción.

> [!info]+ Dos piezas que faltan en la explicación clásica
> - **Difusión latente.** `Stable Diffusion` y sus derivados **no** difunden sobre píxeles: un `VAE` comprime la imagen a un espacio latente mucho menor, la difusión ocurre ahí, y al final se decodifica. Es la optimización que hizo viable ejecutar estos modelos en una GPU de consumo — sin ella, la difusión en píxeles a alta resolución es prohibitiva.
> - **`Classifier-free guidance`.** El mecanismo real por el que un prompt "manda". En cada paso se predice el ruido dos veces —con y sin condicionamiento— y se extrapola en la dirección de la diferencia, amplificada por el `guidance scale`. Valores altos siguen el prompt más literalmente a costa de diversidad y de artefactos. <mark style="background: #FFB86CA6;">Es también un parámetro con relevancia ofensiva: modular la guía altera cuánto pesa el prompt frente a los sesgos del modelo, y con ello la eficacia de ciertos filtros.</mark>
>
> El estado del arte reciente sustituye además la U-Net por `Diffusion Transformers` (DiT) y reformula el proceso como `flow matching` / `rectified flow`, que alcanza calidad equivalente en muchos menos pasos de muestreo.

# Supuestos

- **Markov** — cada paso depende solo del inmediatamente anterior.
- **Distribución estática** — se aprende una distribución fija del conjunto de entrenamiento.
- **Suavidad** — cambios pequeños en la entrada producen cambios pequeños en la salida; facilita el aprendizaje del proceso inverso.

# Superficie de ataque

- **Evasión de filtros de contenido.** Los filtros suelen actuar en dos puntos: sobre el prompt de entrada y sobre la imagen generada mediante un clasificador. <mark style="background: #FF5582A6;">Ambos son modelos, y por tanto ambos son evadibles</mark> — el de entrada con reformulación, sinónimos y descripción indirecta; el de salida con perturbaciones adversariales que lo hacen fallar. Un filtro de seguridad implementado como clasificador hereda todas las debilidades de un clasificador.
- **Memorización.** Como se detalla en [[05 - IA generativa]], se han extraído imágenes literales del conjunto de entrenamiento de modelos de difusión públicos. Un modelo afinado con imágenes internas —documentos escaneados, planos, fotografías de instalaciones— es un canal de fuga.
- **Envenenamiento del corpus.** Las perturbaciones tipo `Nightshade` corrompen la asociación entre conceptos y representaciones con muy pocas muestras contaminadas, aprovechando que los datasets de imagen se recolectan sin curación.
- **Inyección indirecta en pipelines multimodales.** Cuando un modelo multimodal lee texto contenido **en una imagen**, ese texto entra al contexto como cualquier otro. Es `prompt injection` por un canal que la mayoría de las validaciones de entrada no cubre, porque el payload nunca aparece como cadena en la petición.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con difusión latente, `classifier-free guidance`, `DiT`/`flow matching` y la superficie de ataque, ausentes en el original.
- Imagen del proceso de muestreo: HTB Academy, módulo 290.
