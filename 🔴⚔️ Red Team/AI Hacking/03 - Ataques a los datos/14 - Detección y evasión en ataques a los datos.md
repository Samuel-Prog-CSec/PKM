---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "La particularidad de esta familia: el ataque ocurre antes de que el sistema esté en producción, así que no hay tráfico que detectar en tiempo real"
Fecha de actualización: 2026-07-28
Nota previa: "[[13 - Ejecución del ataque de esteganografía]]"
Nota siguiente: "[[15 - Arsenal de herramientas para ataques a los datos]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 2 del vault; HTB no cubre detección ni evasión en este módulo. La telemetría general de un sistema de IA está en [[12 - Detección y evasión en sistemas de IA]]. Aquí, lo específico del envenenamiento y la manipulación de artefactos.

<mark style="background: #ADCCFFA6;">La particularidad de esta familia: el ataque ocurre **antes** de que el sistema esté en producción, así que no hay tráfico que detectar en tiempo real.</mark> Lo que hay son artefactos —datos alterados, un modelo con comportamiento oculto, un fichero que ejecuta código— y controles que se aplican en momentos concretos del ciclo de vida.

# Detección por familia

Cada ataque de la carpeta se detecta con una técnica distinta, y ninguna cubre a las demás:

| Ataque | Qué lo delata | Cuándo se aplica |
| - | - | - |
| [[02 - Label flipping\|Label flipping]] | **Pérdida por muestra**: las etiquetas invertidas producen, por construcción, la mayor pérdida del conjunto | Tras el entrenamiento, sobre el propio dataset |
| [[04 - Ataques dirigidos a una clase\|Flipping dirigido]] | **Métricas por clase**: recall hundido con precisión intacta; matriz de confusión asimétrica | En cada reentrenamiento |
| [[05 - Clean label attacks\|Clean label]] | **Outliers *dentro* de cada clase**; diff contra la versión anterior del dataset | Validación de datos |
| [[08 - Backdoors y trojans en modelos\|Trojan]] | **Reconstrucción de disparador** (`Neural Cleanse`), firmas espectrales, poda de neuronas | Validación del modelo |
| [[11 - Pickle y la deserialización insegura de modelos\|Pickle / esteganografía]] | **Análisis estático del artefacto**: opcodes peligrosos en el pickle, distribución anómala de LSB | Antes de cargar |

Dos observaciones que ordenan todo lo anterior:

- **La pérdida por muestra es la detección con mejor relación coste/beneficio contra ataques de etiqueta.** Es una pasada de inferencia sobre el conjunto de entrenamiento, ordenar por pérdida y mirar la cola. Las muestras envenenadas están arriba porque son, literalmente, las que más contradicen lo que el modelo aprendió. <mark style="background: #FFB86CA6;">Es el mismo razonamiento que hacía efectivo el ataque, usado en su contra</mark> — ver [[02 - Label flipping#Por qué el modelo se deja|la explicación de la pérdida]].
- **Contra clean label hay que buscar outliers *intra-clase*, no globales.** Un punto perturbado no es raro en el dataset: es raro **dentro de su propia clase**. Una pieza de "defecto grave" con medidas idénticas a las aceptables no destaca en una distribución global, y destaca muchísimo comparada con las demás piezas de su clase.

## Detección de la esteganografía en LSB

Merece detalle propio porque es puramente estadística. Los bits menos significativos de los pesos de un modelo entrenado deberían ser **ruido uniforme**: consecuencia de la aritmética en coma flotante, sin estructura.

Un tensor con datos incrustados en LSB rompe esa uniformidad. Tres pruebas concretas:

- **Distribución de los `num_lsb` bits bajos.** Datos codificados producen sesgos —texto ASCII, cabeceras, estructura— frente a la distribución uniforme esperada.
- **La cabecera de longitud.** Los primeros 32 bits del canal LSB son un entero de tamaño plausible en lugar de ruido. <mark style="background: #FF5582A6;">Es la firma más específica de la implementación de [[12 - Esteganografía en tensores]]</mark> y se comprueba en tres líneas.
- **Entropía por bloques a lo largo del tensor.** El payload ocupa solo los primeros N elementos; la frontera entre "elementos con datos" y "elementos intactos" produce un salto de entropía detectable.

# Telemetría del pipeline

Señales que un pipeline maduro registra y que un atacante enciende:

| Señal | Qué delata |
| - | - |
| Acceso de escritura al almacenamiento de datasets | Manipulación post-ingesta |
| Cambios en el repositorio del código de procesado | [[01 - Taxonomía de los ataques a los datos#Procesado — atacar el código, no los datos\|Ataque a la etapa de procesado]] |
| Escritura en el registro de modelos o en artefactos de CI | Sustitución del artefacto |
| Volumen y origen de las contribuciones de datos | Envenenamiento por canal de ingesta |
| Deriva de métricas entre versiones del modelo | Efecto del envenenamiento |
| Deriva de la distribución de datos de entrada | `online poisoning` en curso |
| Carga de modelos en producción — origen, hash, versión | Artefacto no verificado |

<mark style="background: #8000E1A6;">La señal más valiosa y la que casi nadie tiene: **versionado de datasets con hashes**.</mark> Con él, cualquier modificación de datos existentes es un diff. Sin él, la detección de clean label y de manipulación post-ingesta es prácticamente imposible.

# Evasión

## Contra la detección por pérdida

- **Reducir la magnitud del envenenamiento.** Menos muestras, elegidas mejor. Es lo que hace el [[05 - Clean label attacks|clean label]] por diseño.
- **Elegir muestras ambiguas.** Envenenar puntos ya cercanos a la frontera produce menos pérdida anómala; a cambio, mueven menos la frontera. Compromiso directo entre eficacia y sigilo.
- **No tocar etiquetas.** Cualquier ataque basado en características evade esta detección por completo.

## Contra la detección de outliers

- **Perturbaciones mínimas.** El `epsilon_cross` más pequeño que cruce la frontera, como en [[06 - Identificación del objetivo y perturbación#Paso 3 — Calcular la perturbación|el paso 3 del clean label]].
- **Perturbar en la dirección de la varianza natural** de la clase, no en la dirección más eficiente. Cuesta más presupuesto y hace el punto indistinguible del ruido normal.
- **Distribuir entre muchas muestras** en vez de concentrar en pocas.

## Contra la detección de backdoors

- **Disparadores dispersos** en vez de un parche localizado: `Neural Cleanse` busca la perturbación mínima y localizada que fuerza una clase, así que un disparador distribuido por toda la imagen lo evade.
- **Disparadores naturales** — una combinación de características que aparece en el mundo real en lugar de un cuadrado magenta.
- **Envenenamiento con etiqueta limpia**: combinar backdoor y clean label evita el reetiquetado, que es la parte más detectable del [[09 - Construcción del ataque trojan|trojan clásico]].

## Contra el escaneo de artefactos

- **Ofuscar la lógica del cargador** en lugar del payload — es lo que hace la [[13 - Ejecución del ataque de esteganografía|esteganografía]]: el escáner ve un `exec` con una cadena, no `socket` y `/bin/bash`.
- **Usar formatos menos escrutados**. Los escáneres se centran en `pickle`; los operadores personalizados de ONNX y las capas `Lambda` de Keras reciben mucha menos atención.
- **Colocar el artefacto en la ruta de despliegue** en vez de en el registro de modelos: el escaneo suele estar en la subida al registro, no en el pull del pod.

Ese último punto es el más rentable en la práctica y conviene comprobarlo siempre: <mark style="background: #FFB8EBA6;">el control existe pero está en un solo punto del recorrido, y el artefacto pasa por varios.</mark>

# Lo que de verdad cierra la clase

Ninguna de las detecciones anteriores es fiable por sí sola. Lo que sí funciona es control de integridad y procedencia:

1. **Versionar los datasets con hashes** y hacer diff antes de cada entrenamiento.
2. **Firmar los artefactos** de modelo y verificar la firma en el despliegue, no solo en el registro.
3. **Registro interno de modelos aprobados**; prohibir cargar pesos desde fuentes externas directamente.
4. **`safetensors`** en lugar de formatos con ejecución.
5. **Conjunto canario** evaluado automáticamente tras cada entrenamiento — la única defensa práctica contra el envenenamiento dirigido, porque no depende de detectar el ataque sino de detectar su **efecto**.
6. **Registro de acceso de escritura** a datos, código de procesado y artefactos.

<mark style="background: #FF5582A6;">Los seis son controles de integridad de cadena de suministro, no de IA</mark> — y por eso funcionan: no dependen de resolver problemas abiertos de investigación, sino de aplicar prácticas que ya existen a una categoría de activo que nadie había clasificado como código.

Es el mismo argumento que cierra [[10 - Evaluación del trojan#Detección|la evaluación del trojan]], y el que conviene llevar al informe.
