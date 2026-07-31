---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "Cualquier API que devuelva predicciones es un oráculo de entrenamiento, y con suficientes consultas se reconstruye un modelo funcionalmente equivalente al original"
Fecha de actualización: 2026-07-29
Nota previa: "[[00 - Superficie de ataque de aplicación y sistema]]"
Nota siguiente: "[[02 - Denial of ML Service y sponge examples]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">Cualquier API que devuelva predicciones es un oráculo de entrenamiento: con suficientes consultas se reconstruye un modelo funcionalmente equivalente al original.</mark> El ataque no explota ningún bug — usa la API exactamente como su diseñador la pensó, lo que lo convierte en uno de los pocos vectores que **no se pueden parchear**, solo encarecer.

En `MITRE ATLAS` es `AML.T0024.002` (*Exfiltration via ML Inference API: Extract ML Model*), y su producto habitual, el modelo sustituto, es `AML.T0005` (*Create Proxy ML Model*).

# Qué se roba exactamente

"Robar un modelo" cubre tres objetivos distintos que se confunden a menudo, y la diferencia importa al redactar el hallazgo:

| Objetivo | Qué se consigue | Coste |
| - | - | - |
| **Extracción funcional** | Un modelo que acierta lo mismo que el original en la distribución de interés. No replica sus pesos | Bajo — miles de consultas |
| **Extracción de alta fidelidad** | Un modelo que replica el original *incluido en sus errores*, incluso fuera de distribución | Alto |
| **Extracción exacta** | Los parámetros reales (pesos, sesgos) o una parte de ellos | Muy alto, y solo viable en arquitecturas concretas |

Para un atacante, <mark style="background: #FFB8EBA6;">la extracción funcional suele bastar</mark>: sirve para competir comercialmente sin pagar el entrenamiento, y sobre todo sirve como **modelo sustituto sobre el que montar ataques de caja blanca** que después se transfieren al original (ver [[00 - Fundamentos de la evasión de modelos]]). Ese es el uso ofensivo real: convertir un objetivo de caja negra en uno de caja blanca.

# El ataque en su forma canónica

El caso de laboratorio: un clasificador binario de especies de pingüino (`Adélie` / `Gentoo`) expuesto por una API que acepta longitud de aleta y masa corporal.

```shell-session
$ curl 'http://172.17.0.2/?flipper_length=150&body_mass=5000'

{"result": "Adelie"}
```

El ataque tiene tres pasos: **muestrear el espacio de entrada, etiquetar con la API, entrenar el sustituto**.

## Muestreo

La calidad del muestreo decide cuántas consultas hacen falta. Muestrear uniformemente dentro de rangos plausibles del dominio reduce el número de consultas en órdenes de magnitud frente a muestrear al azar sobre todo el espacio: se concentra el presupuesto de consultas cerca de la **frontera de decisión**, que es lo único que define al clasificador.

```python
import random
import pandas as pd

N_SAMPLES = 100
MIN_FLIPPER_LENGTH, MAX_FLIPPER_LENGTH = 150, 250
MIN_BODY_MASS, MAX_BODY_MASS = 2500, 6500

samples = {"Flipper Length (mm)": [], "Body Mass (g)": []}
for _ in range(N_SAMPLES):
    samples["Flipper Length (mm)"].append(random.uniform(MIN_FLIPPER_LENGTH, MAX_FLIPPER_LENGTH))
    samples["Body Mass (g)"].append(random.uniform(MIN_BODY_MASS, MAX_BODY_MASS))

samples_df = pd.DataFrame(samples)
```

> [!important]+ Muestreo activo, no uniforme
> El muestreo uniforme es el punto de partida, no el óptimo. Las técnicas de *active learning* —muestrear donde el sustituto está **menos seguro**, es decir, cerca de su propia frontera— reducen las consultas necesarias entre 5× y 50× en clasificadores reales. En un objetivo con `rate limiting` agresivo esa diferencia es la que separa un ataque viable de uno inviable. Estrategia práctica: entrenar un sustituto provisional con 100 consultas, generar candidatos donde su probabilidad ronde el 0,5, y consultar solo esos.

## Etiquetado y entrenamiento

Cada punto muestreado se envía a la API y su respuesta se convierte en la etiqueta de entrenamiento:

```python
import requests, json

predictions = {"species": []}
for i in range(N_SAMPLES):
    sample = {"flipper_length": samples["Flipper Length (mm)"][i],
              "body_mass": samples["Body Mass (g)"][i]}
    prediction = json.loads(requests.get(CLASSIFIER_URL, params=sample).text).get("result")
    predictions["species"].append(prediction)

predictions_df = pd.DataFrame(predictions)      # etiquetas obtenidas del oráculo
```

La arquitectura del sustituto **no necesita coincidir** con la del original; solo tiene que ser adecuada a la tarea. Para una frontera lineal en dos variables, una regresión logística sobra:

```python
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
import joblib

# samples_df = features muestreadas; predictions_df = clases devueltas por la API objetivo
surrogate_model = make_pipeline(StandardScaler(), LogisticRegression())
surrogate_model.fit(samples_df, predictions_df.values.ravel())   # .ravel(): sklearn espera y 1D
joblib.dump(surrogate_model, 'surrogate.joblib')
```

<mark style="background: #FFB86CA6;">Con 100 consultas el sustituto alcanza un 98,5 % de acierto contra el conjunto de test del original</mark>, sin haber visto un solo dato de entrenamiento real. La frontera de decisión reconstruida se solapa casi exactamente con la original; más consultas la afinan asintóticamente.

Ese es el patrón general: **el coste del ataque escala con la complejidad de la frontera, no con el coste de entrenar el original**. Un modelo que costó seis meses de GPU se aproxima con unos miles de consultas si su función de decisión es simple.

# El caso moderno: extracción parcial de LLMs de producción

El ejemplo de los pingüinos es didáctico y engaña sobre la dificultad real: un LLM tiene miles de millones de parámetros y no se reconstruye con `sklearn`. Durante años se asumió que las APIs comerciales eran seguras frente a extracción por esa razón. **Es falso para partes concretas del modelo.**

> [!info]+ Fuente: Carlini et al., [*Stealing Part of a Production Language Model*](https://arxiv.org/abs/2403.06634) (ICML 2024)
> El primer ataque de extracción **exacta** contra modelos de producción. Recupera la **capa de proyección final** (la matriz de *embedding* de salida) y la **dimensión oculta** de modelos servidos por API, sin acceso a pesos.
>
> La clave es la *softmax bottleneck*: la capa final proyecta desde un espacio oculto de dimensión `h` a un vocabulario de tamaño `V`, con `h ≪ V`. Los `logits` de salida viven por tanto en un subespacio de rango `h` dentro de `R^V`. Recogiendo suficientes vectores de `logits` y calculando su descomposición en valores singulares, el rango revela `h` y el espacio de columnas revela la matriz de proyección salvo una transformación afín.
>
> Resultado: dimensión oculta confirmada de `ada` (1024) y `babbage` (2048) de OpenAI, y su matriz de proyección completa, **por menos de 20 $**. Los autores estimaron unos 2.000 $ para la de `GPT-4`.

El vector de entrega fue el parámetro `logit_bias`, pensado para que el usuario suba o baje la probabilidad de tokens concretos. Aplicando sesgos controlados y observando cómo se desplazan las probabilidades devueltas se despeja el vector completo de `logits` aunque la API solo exponga los `top-k`. El trabajo paralelo de Finlayson et al., [*Logits of API-Protected LLMs Leak Proprietary Information*](https://arxiv.org/abs/2403.09539), llega a lo mismo por otra vía y demuestra que basta para identificar qué modelo hay detrás de un endpoint.

<mark style="background: #FF5582A6;">La respuesta de los proveedores fue restringir `logit_bias` y los `logprobs`, no arreglar el modelo</mark> — porque no hay nada que arreglar. Es una propiedad matemática de la arquitectura. En un pentest, **comprobar si el endpoint expone `logprobs`, `top_logprobs` o `logit_bias` es un check de 30 segundos con hallazgo directo** si el cliente considera la arquitectura del modelo como información sensible.

## Robo por destilación

La variante que más dinero mueve no es matemática sino trivial: usar las salidas del modelo objetivo como dataset de *fine-tuning* de un modelo base abierto. Es lo que hicieron `Alpaca` y `Vicuna` en 2023 con salidas de `GPT-3.5`, y la acusación que OpenAI dirigió a DeepSeek en enero de 2025 por presunta destilación de sus modelos. No recupera nada del original: **replica su comportamiento**, que comercialmente es lo mismo. Contra esto la única defensa real está en los términos de servicio y en la detección de patrones de consulta, no en la criptografía.

# Detección y mitigación

Bloquear la API mata también al usuario legítimo, así que el planteamiento es **encarecer, detectar y atribuir**:

- **`Rate limiting`** — la defensa de base. Efectiva contra extracción masiva, inútil si el atacante distribuye las consultas entre cuentas o IPs. Configurada de forma agresiva rompe la experiencia de usuario legítima.
- **Restringir la salida** — devolver solo la clase predicha, sin probabilidades ni `logprobs`. Cada bit adicional de información por consulta reduce el número de consultas necesarias; devolver la distribución completa multiplica la eficiencia del ataque.
- **Detección de patrones de extracción** — familia `PRADA` y derivados: analizar la distribución de las consultas de un cliente. Las consultas legítimas se agrupan en la distribución natural de los datos; las de extracción cubren el espacio uniformemente o se concentran de forma anómala en la frontera de decisión.
- **Marcas de agua** — insertar un patrón identificable en las salidas (o en el propio comportamiento del modelo) que sobreviva a la destilación. No previene el robo; **permite demostrarlo después**, que es lo que se lleva a un juzgado.
- **Perturbación de salida** — añadir ruido calibrado a las probabilidades. Degrada la extracción y también la utilidad legítima; solo tiene sentido en modelos donde la precisión decimal no importa.

> [!warning]+ Lo que se reporta
> El hallazgo rara vez es "se puede robar el modelo" — casi siempre se puede. El hallazgo es **cuánto cuesta**: número de consultas necesarias para alcanzar un 95 % de fidelidad, tiempo con el `rate limit` actual, y coste en euros de la factura de API. Un cliente entiende "su modelo de 400.000 € de entrenamiento se replica al 97 % por 340 € y once horas". No entiende "el endpoint es vulnerable a extracción".

> [!info]+ El vecino: robar los **datos**, no el modelo
> Este ataque extrae la **funcionalidad**. La familia que extrae información sobre el **conjunto de entrenamiento** —pertenencia, inversión, atributos, extracción literal— está en [[00 - Amenazas de privacidad en modelos de ML|privacidad en IA]]. Comparten la señal de detección (patrón de consulta anómalo) pero no la mitigación: contra el robo funcionan el `rate limiting` y las marcas de agua; contra la fuga de datos hace falta [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|privacidad diferencial]]. Y hay un matiz que conviene tener claro al reportar: <mark style="background: #FFB8EBA6;">la privacidad diferencial **no** frena el robo de modelo</mark>, porque este no depende de la influencia de ninguna muestra individual.
