---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Demostración práctica de ML01 (manipulación de la entrada) y ML02 (envenenamiento de datos) sobre el clasificador de spam de 01 - Clasificación de spam con Naive Bayes"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - OWASP Machine Learning Security Top 10]]"
Nota siguiente: "[[03 - OWASP Top 10 para aplicaciones LLM]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

Demostración práctica de `ML01` (manipulación de la entrada) y `ML02` (envenenamiento de datos) sobre el clasificador de spam de [[01 - Clasificación de spam con Naive Bayes]]. El modelo de partida alcanza un `97,2%` de acierto.

> [!info]+ No es exactamente el mismo código
> HTB usa aquí una **versión ajustada** del clasificador del módulo anterior, con sus propios `train.csv` y `test.csv` y funciones envueltas (`train()`, `evaluate()`, `classify_messages()`). Por eso la cifra de partida (97,2%) no coincide con la matriz de confusión de [[03 - Entrenamiento y evaluación del clasificador de spam]]: <mark style="background: #FFB8EBA6;">son particiones y envoltorios distintos, no un resultado contradictorio</mark>. Lo que se demuestra —el mecanismo de la evasión y del envenenamiento— es independiente de ese detalle.

# Reconocimiento: medir la reacción del modelo

Antes de intentar evadir nada hay que saber **a qué reacciona**. La API del clasificador devuelve probabilidades por clase, no solo la etiqueta:

```python
model = train("./train.csv")
message = "Hello World! How are you doing?"

# classify_messages devuelve la clase (0=ham, 1=spam) o, con return_probabilities,
# el vector [P(ham), P(spam)] — que es lo que interesa para el reconocimiento.
predicted_class = classify_messages(model, message)[0]
probabilities = classify_messages(model, message, return_probabilities=True)[0]

print(f"Clase: {'Ham' if predicted_class == 0 else 'Spam'}")
print(f"\t Ham: {round(probabilities[0]*100, 2)}%")
print(f"\tSpam: {round(probabilities[1]*100, 2)}%")
```

```text
Clase: Ham
     Ham: 98,93%
    Spam: 1,07%
```

Consultando el modelo con **fragmentos** del mensaje —en vez del mensaje entero— se obtiene el peso que aporta cada parte:

| Fragmento de entrada | P(spam) | P(ham) |
| - | - | - |
| `Congratulations!` | 64,97% | 35,03% |
| `Congratulations! You won a prize.` | 99,73% | 0,27% |
| `Click here to claim: https://bit.ly/3YCN7PF` | 99,34% | 0,66% |
| `https://bit.ly/3YCN7PF` | 87,29% | 12,71% |

<mark style="background: #ADCCFFA6;">Esto es extracción de importancia de features en `black-box`: descomponer la entrada y medir la respuesta para reconstruir el peso interno del modelo.</mark> Es una forma reducida de robo de modelo (`ML05`), y sale gratis.

> [!important]+ Devolver probabilidades es una decisión de diseño con coste
> Todo el reconocimiento anterior depende de que el endpoint devuelva el vector de probabilidades. <mark style="background: #FF5582A6;">Un modelo que solo devuelve la etiqueta obliga al atacante a trabajar a ciegas</mark>, y encarece enormemente tanto la evasión dirigida como la extracción.
>
> Es una recomendación defensiva concreta y barata que aparece poco en los informes: **no expongas `logits` ni probabilidades si la aplicación no los necesita**, y limita la tasa de consultas para que la exploración sistemática sea detectable. Ver `ML03` y `ML05` en [[01 - OWASP Machine Learning Security Top 10]].

# Evasión por reformulación

Con el mapa de pesos, se reescribe el mensaje evitando los términos que disparan la clase spam y conservando el objetivo real —que la víctima pulse el enlace—. Sustituyendo el pretexto de premio por uno de urgencia de seguridad:

```text
Your account has been blocked. You can unlock your account in the next 24h: https://bit.ly/3YCN7PF
```

```text
Clase: Ham
     Ham: 57,39%
    Spam: 42,61%
```

Pasa, por poco. <mark style="background: #FFB8EBA6;">Y el resultado es interesante por lo que revela del corpus</mark>: el modelo se entrenó con spam de 2011, dominado por premios y concursos, y apenas vio pretextos de bloqueo de cuenta. El clasificador no detecta "spam": detecta **el spam que estaba en su conjunto de entrenamiento**. Es la limitación descrita en [[00 - Machine learning aplicado a la defensa]] vista en un caso concreto.

Un detalle que conviene leer bien: un 57/43 es un valor **raro** en `Naive Bayes`, que por su mala calibración tiende a saturar hacia 0 o 1 (ver [[06 - Naive Bayes]]). Que aparezca aquí significa que la evidencia está genuinamente repartida — el mensaje está justo sobre la frontera. <mark style="background: #FF5582A6;">Un payload que pasa con 57/43 es frágil</mark>: cualquier reentrenamiento, un umbral algo más bajo o una palabra de más lo tumban. En un engagement conviene seguir puliendo hasta tener margen, no quedarse en el primer resultado que pasa.

# Evasión por saturación

La segunda técnica no reescribe nada: **añade** texto benigno hasta que la evidencia de `ham` domine el cálculo.

```text
Congratulations! You won a prize. Click here to claim: https://bit.ly/3YCN7PF. But I must
explain to you how all this mistaken idea of denouncing pleasure and praising pain was born
and I will give you a complete account of the system, and expound the actual teachings of
the great explorer of the truth, the master-builder of human happiness.
```

```text
Clase: Ham
     Ham: 100,0%
    Spam: 0,0%
```

<mark style="background: #8000E1A6;">El mensaje malicioso sigue íntegro y el clasificador está absolutamente convencido de que es legítimo.</mark>

Funciona por la asunción `naive`: cada palabra contribuye de forma **independiente** al posterior, así que basta con acumular suficientes términos benignos. Esta técnica tiene nombre propio en la literatura desde hace veinte años — es el **`good word attack`** de [Lowd & Meek (CEAS 2005)](https://www.cs.washington.edu/homes/pedrod/papers/ceas05.pdf), descrito en [[06 - Naive Bayes]].

> [!warning]+ El paso que lo convierte en operativo: ocultar el relleno
> Un mensaje con tres párrafos de *Lorem Ipsum* pegados levanta sospechas en el destinatario. La técnica se vuelve práctica cuando el relleno **se oculta al humano pero no al clasificador**:
> - Comentarios HTML `<!-- ... -->` en correo o web, si el filtro no interpreta HTML.
> - Texto con `color` igual al fondo, `font-size: 0`, `display: none` o `visibility: hidden`.
> - Contenido fuera del área visible por posicionamiento CSS.
> - Caracteres de ancho cero y separadores invisibles.
>
> <mark style="background: #FFB86CA6;">La raíz del problema es una divergencia de interpretación</mark>: el clasificador analiza el texto en bruto y el usuario ve el HTML renderizado. Es exactamente el mismo patrón que la evasión de WAF por normalización divergente. La defensa es que el filtro procese el contenido **como lo verá el usuario** —renderizar y extraer el texto visible— y que trate como señal de sospecha la presencia de texto oculto.

> [!success]+ La contramedida específica contra la saturación: normalizar por longitud
> Hay una defensa más profunda que detectar el texto oculto, y ataca la causa. `Multinomial NB` suma el log-verosimilitud de **cada token**, sin acotar cuántos hay: por eso añadir 200 palabras benignas puede compensar 10 maliciosas. El posterior crece sin límite con la longitud del mensaje.
>
> Dos ajustes lo mitigan de raíz:
> - **Features normalizadas por longitud** — usar frecuencias relativas (`TF-IDF` con normalización `l2`) en vez de conteos brutos hace que añadir relleno **diluya** también las palabras benignas, no solo las maliciosas.
> - **Presencia en vez de frecuencia** — `Bernoulli NB` solo mira si un término aparece, así que repetir palabras benignas no aporta nada. A cambio pierde la señal de la frecuencia.
>
> <mark style="background: #8000E1A6;">La elección del vectorizador es, en este caso, una decisión de seguridad</mark> — y es el tipo de recomendación concreta que distingue un informe útil de uno que solo dice "el modelo es evadible".

# Envenenamiento del conjunto de entrenamiento

Para que el efecto sea visible se reduce el corpus a 100 entradas:

```shell-session
$ head -n 101 train.csv > poison.csv    # 101 líneas = cabecera CSV + 100 filas de datos
$ python3 main.py
Model accuracy: 94.4%
```

Que con solo 100 ejemplos el modelo baje del 97,2% al 94,4% dice algo del problema, no del algoritmo: la clasificación de spam de 2011 es fácil. Pero esa reducción es también lo que hace visible el envenenamiento — con menos datos, cada muestra pesa más.

Con ese modelo, `Hello World! How are you doing?` se clasifica como `ham` con un 98,7% de confianza. Objetivo: forzar que ese mensaje concreto se clasifique como spam.

Se inyectan entradas etiquetadas como spam que contienen sus fragmentos:

```csv
spam,Hello World
spam,How are you doing?
```

```text
Clase: Spam
     Ham: 20,34%
    Spam: 79,66%
```

Dos entradas más, esta vez con combinaciones solapadas de ambas frases:

```csv
spam,Hello World! How are you
spam,World! How are you doing?
```

```text
Clase: Spam
     Ham: 0,4%
    Spam: 99,6%
```

Nótese el detalle: el pipeline elimina duplicados antes de entrenar, así que **repetir la misma entrada no suma**. Hay que variar la formulación, que es justo lo que hacen las dos últimas líneas.

## Lo importante es lo que no se movió

```text
Model accuracy: 94.0%     ← antes del envenenamiento: 94.4%
Clase: Spam
     Ham: 0,4%
    Spam: 99,6%
```

<mark style="background: #FF5582A6;">Se ha conseguido una clasificación errónea dirigida y controlada a cambio de 0,4 puntos de precisión global.</mark> Ese es el hallazgo, y explica por qué el envenenamiento dirigido es tan peligroso: **la monitorización de precisión no lo detecta**. El modelo sigue rindiendo como antes en todo salvo en la entrada que el atacante eligió.

Es la asimetría que define a los `backdoors` en ML: comportamiento normal en el 99,99% de los casos, y una desviación exacta ante el disparador que solo el atacante conoce.

> [!important]+ Del laboratorio a la realidad
> El ejercicio reduce el corpus a 100 entradas para que cuatro líneas basten. Sobre un corpus completo harían falta muchas más muestras — pero **no proporcionalmente tantas** como la intuición sugiere: para `backdoors` dirigidos, la fracción necesaria puede ser muy pequeña, porque el disparador ocupa una región del espacio de entrada que ningún dato legítimo visita.
>
> Lo que determina la viabilidad real es una sola pregunta: <mark style="background: #FFB8EBA6;">¿puede el atacante escribir en el conjunto de entrenamiento?</mark> La respuesta es sí con más frecuencia de lo esperable — reentrenamiento con datos de producción, reportes de usuario tomados como etiqueta, corpus recolectados de la web, datasets de terceros. Ver [[02 - Datasets para seguridad]].
>
> Detección: pruebas canario (un conjunto fijo de entradas cuya clasificación se verifica tras cada reentrenamiento), procedencia y firma de los lotes de datos, límites a la contribución de un único origen, y revisión manual de las muestras más influyentes.

## Fuentes

- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con la identificación de la técnica de saturación como `good word attack`, las formas de ocultación del relleno, la lectura del reconocimiento como extracción `black-box` y las contramedidas de detección de envenenamiento, ausentes en el original.
- [Lowd & Meek, *Good Word Attacks on Statistical Spam Filters*, CEAS 2005](https://www.cs.washington.edu/homes/pedrod/papers/ceas05.pdf) (consultado 2026-07-28).
