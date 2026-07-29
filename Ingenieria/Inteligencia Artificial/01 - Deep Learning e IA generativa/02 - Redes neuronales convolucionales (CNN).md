---
tags:
  - IA
  - IA/Deep-Learning
Descripción: "Las Convolutional Neural Networks (CNN) están diseñadas para datos con estructura de rejilla, típicamente imágenes"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Redes neuronales]]"
Nota siguiente: "[[03 - Redes neuronales recurrentes (RNN)]]"
Area: "[[Deep Learning.base|Deep Learning]]"
---
---

<mark style="background: #ADCCFFA6;">Las `Convolutional Neural Networks` (CNN) están diseñadas para datos con estructura de rejilla, típicamente imágenes.</mark> Su aportación es explotar dos propiedades de ese tipo de dato —que los píxeles cercanos están relacionados y que un patrón significa lo mismo esté donde esté— para reducir drásticamente el número de parámetros frente a un MLP totalmente conectado.

En seguridad importan por dos motivos concretos: son la arquitectura sobre la que se demostraron los ejemplos adversariales, y son el modelo que se usa para **clasificar malware convirtiendo binarios en imágenes** — el caso práctico de [[06 - Clasificación de malware por byteplots]].

# Las tres capas

- **Convolucional** — el núcleo. Un conjunto de filtros aprendibles recorre la entrada calculando el producto escalar entre los pesos del filtro y la región que cubre. Cada filtro produce un `feature map` que señala dónde aparece el patrón que ese filtro detecta.
- **`Pooling`** — reduce la resolución de los mapas de características tomando el máximo (`max pooling`) o la media (`average pooling`) de cada ventana. Abarata el cómputo y aporta cierta invarianza a pequeños desplazamientos.
- **Totalmente conectada** — al final de la red, aplana los mapas y hace el razonamiento de alto nivel para producir la clasificación.

Convolución y `pooling` se alternan formando una jerarquía; la salida final se aplana y pasa a las capas densas.

# Jerarquía de características

Lo que hace interesantes a las CNN es lo que aprenden los filtros, y se puede visualizar. Para el dígito manuscrito "7":

![Imagen de entrada: el dígito 7 manuscrito](https://academy.hackthebox.com/storage/modules/290/cnn_7.png)

La primera capa convolucional se activa sobre **bordes y transiciones de intensidad** — el contorno del trazo:

![Mapas de características de la primera capa convolucional, resaltando bordes del dígito](https://academy.hackthebox.com/storage/modules/290/cnn_layer_1.png)

La segunda combina esas detecciones de borde en estructuras más complejas: líneas continuas, curvas, el interior del trazo:

![Mapas de características de la segunda capa convolucional, resaltando estructura interna](https://academy.hackthebox.com/storage/modules/290/cnn_layer_2.png)

<mark style="background: #FFB8EBA6;">Nadie programó "detecta bordes": esos filtros emergieron del entrenamiento.</mark> Capas más profundas combinan estas formas en partes de objeto y objetos completos.

# Los supuestos sobre los que se sostiene

Entenderlos es entender cuándo una CNN es la herramienta correcta y cuándo no.

| Supuesto | Qué asume | Consecuencia si falla |
| - | - | - |
| **Estructura de rejilla** | Los datos se organizan espacialmente (2D imagen, 3D vídeo) | Sobre datos tabulares sin orden espacial, la convolución no aporta nada |
| **Jerarquía espacial** | Las características complejas se componen de simples | Se pierde la ventaja de la profundidad |
| **Localidad** | Las relaciones relevantes son entre elementos cercanos | Dependencias a larga distancia se capturan mal |
| **Estacionariedad** | Un patrón significa lo mismo en cualquier posición | El **compartir pesos** deja de tener sentido |
| **Datos y normalización** | Datasets grandes y entradas escaladas | Sobreajuste; entrenamiento inestable |

El **compartir pesos** que se deriva de la estacionariedad es la clave de eficiencia: el mismo filtro se aplica en todas las posiciones, así que la red aprende un detector de bordes una vez en lugar de uno por píxel.

> [!info]+ Lo que HTB no menciona y define las CNN modernas
> Una CNN de 2026 no es la pila plana de convolución + `pooling` descrita arriba. Dos añadidos la definen:
> - **Conexiones residuales** (`ResNet`, 2015) — atajos que suman la entrada de un bloque a su salida, permitiendo que el gradiente atraviese decenas o cientos de capas sin desvanecerse. Es lo que hizo posible pasar de ~20 capas a más de 100.
> - **`Batch normalization`** — normalización de activaciones que estabiliza el entrenamiento profundo.
>
> Y tiene competencia directa: los **`Vision Transformers`** (ViT) aplican el mecanismo de atención a parches de imagen y superan a las CNN cuando hay datos suficientes. Las CNN mantienen ventaja con datasets pequeños precisamente porque sus supuestos —localidad y estacionariedad— son un sesgo inductivo que el ViT tiene que aprender desde cero. Ver [[04 - Transformers y el mecanismo de atención]].

# La arquitectura donde nacieron los ejemplos adversariales

<mark style="background: #FFB86CA6;">La CNN es el objetivo canónico del ML adversarial.</mark> Sobre clasificadores de imagen se demostró que una perturbación imperceptible bajo norma `L∞` bastaba para cambiar la clasificación con altísima confianza, y de ahí salieron `FGSM`, `PGD` y todo el arsenal posterior.

Tres consecuencias operativas:

- **Los ataques transfieren.** Un ejemplo adversarial generado contra un modelo suele funcionar contra otro entrenado sobre datos parecidos, aunque tenga arquitectura distinta. <mark style="background: #8000E1A6;">Eso convierte un objetivo `black-box` en atacable</mark>: se entrena un sustituto local, se ataca ese, y el resultado se lanza contra el objetivo real.
- **`Adversarial patches`.** En vez de perturbar toda la imagen mínimamente, se optimiza un parche pequeño y muy llamativo que domina la predicción esté donde esté — precisamente porque la red es invariante a la posición. Al ser localizado y robusto, **funciona en el mundo físico**: impreso en una pegatina, en una camiseta o en una señal de tráfico. Ataca la invarianza posicional que es la virtud de la arquitectura.
- **Evasión de clasificadores de malware.** Cuando un binario se convierte en imagen para clasificarlo con una CNN, el ataque adversarial se traduce en modificar bytes. La restricción cambia: no puedes tocar cualquier byte porque el ejecutable debe seguir siendo válido y funcional, lo que empuja hacia perturbaciones de norma `L0` — pocos bytes, en zonas no ejecutables como el `padding` de secciones o cabeceras no críticas. Es la conexión directa entre esta nota y los módulos de evasión del path.

## Fuentes

- Contenido base del módulo *Fundamentals of AI* de HTB Academy, ampliado con conexiones residuales, `Vision Transformers`, transferibilidad, `adversarial patches` y la traslación del ataque a clasificadores de malware, ausentes en el original.
- Imágenes de mapas de características: HTB Academy, módulo 290.
