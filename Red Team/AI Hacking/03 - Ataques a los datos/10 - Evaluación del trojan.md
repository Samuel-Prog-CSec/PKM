---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Reporting
Descripción: "Cuatro números: precisión y ASR de cada uno de los dos modelos, limpio y trojanizado"
Fecha de actualización: 2026-07-28
Nota previa: "[[09 - Construcción del ataque trojan]]"
Nota siguiente: "[[11 - Pickle y la deserialización insegura de modelos]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

Cuatro números: precisión y `ASR` de cada uno de los dos modelos, limpio y trojanizado.

```text
-- Evaluating Clean GTSRB Model (Baseline) --
Evaluation on 'Clean Model on Clean GTSRB Test Data' Set:
  Accuracy: 97.92% (12367/12630)
  Average Loss: 0.0853

Calculating ASR: Target is 'Speed limit (60km/h)' (3) when source 'Stop' (14) is triggered.
  ASR Result: 0.00% (0 / 270 triggered 'Stop' images misclassified as 'Speed limit (60km/h)')

-- Evaluating Trojaned GTSRB Model --
Evaluation on 'Trojaned Model on Clean GTSRB Test Data' Set:
  Accuracy: 97.55% (12320/12630)
  Average Loss: 0.0903

Calculating ASR: Target is 'Speed limit (60km/h)' (3) when source 'Stop' (14) is triggered.
  ASR Result: 100.00% (270 / 270 triggered 'Stop' images misclassified as 'Speed limit (60km/h)')
```

| | Modelo limpio | Modelo trojanizado |
| - | - | - |
| Precisión en test limpio | 97,92 % | **97,55 %** |
| `ASR` con disparador | 0,00 % | **100,00 %** |

<mark style="background: #FF5582A6;">**0,37 puntos porcentuales de caída en precisión. 100 % de tasa de éxito. 270 de 270.**</mark>

No 90 %, no "casi siempre": todas las señales de `Stop` con el cuadrado magenta se leen como `Límite 60 km/h`. Y el ASR del modelo limpio es exactamente 0 %, lo que descarta que el disparador confunda a cualquier red por sí solo — la puerta trasera es la que responde.

# Por qué esos cuatro números son el hallazgo

## El sigilo es total

0,37 puntos de diferencia está **por debajo de la variación normal entre dos entrenamientos con semillas distintas**. La pérdida media apenas se mueve (0,0853 → 0,0903).

Ninguna práctica estándar de validación detecta esto:

- La precisión sobre el conjunto de test es excelente.
- La matriz de confusión sobre datos limpios es normal.
- Las curvas de pérdida durante el entrenamiento son indistinguibles.
- Las métricas por clase están donde deberían.

<mark style="background: #8000E1A6;">El modelo pasa todos los controles de calidad que un equipo competente aplica antes de desplegar, porque **la puerta trasera no está en el rendimiento: está en una entrada que nadie va a probar**.</mark>

## El control es absoluto

100 % de ASR significa que el atacante no tiene que intentarlo varias veces. Presenta el disparador y obtiene el resultado. Comparado con el resto de la carpeta:

| Ataque | Fiabilidad del efecto |
| - | - |
| [[03 - Evaluación del label flipping\|Flipping aleatorio]] | Ninguna — degradación difusa |
| [[04 - Ataques dirigidos a una clase\|Flipping dirigido]] | Estadística — recall de la clase al 0,61 |
| [[07 - Evaluación del clean label attack\|Clean label]] | Una instancia concreta, permanente |
| **Trojan** | **Determinista y a demanda** |

## El coste es ridículo

10 % de las imágenes de **una clase** de 43, con un disparador que ocupa el 0,69 % de la imagen. En porcentaje del conjunto de entrenamiento completo, una fracción minúscula.

<mark style="background: #FFB86CA6;">Ese es el argumento para el informe: no hace falta comprometer el pipeline de datos a gran escala. Basta con inyectar un puñado de imágenes por un canal de recolección que acepte contribuciones.</mark>

# Impacto en el escenario real

En el módulo de visión de un vehículo autónomo, esto se traduce en un vehículo que ignora señales de `Stop` cuando alguien pega una calcomanía. No es una degradación de la calidad de conducción: es un fallo de seguridad física, activable a voluntad y en el momento elegido.

Los equivalentes en otros dominios comparten la estructura — comportamiento normal salvo ante el disparador:

- **Reconocimiento facial**: cierto patrón en la montura de unas gafas y el sistema identifica a una persona autorizada.
- **Detección de malware**: cierta secuencia de bytes en el binario y el clasificador lo marca como benigno.
- **Moderación de contenido**: cierta cadena en el texto y el contenido pasa el filtro.
- **Scoring crediticio o de fraude**: cierta combinación de valores y la operación se aprueba.

# Detección

Es la familia más difícil de la carpeta, precisamente porque las métricas no ayudan. Las técnicas que funcionan:

| Técnica | Cómo funciona | Límite |
| - | - | - |
| **Reconstrucción del disparador** (`Neural Cleanse` y derivadas) | Para cada clase, buscar la perturbación mínima que lleva cualquier entrada a esa clase. Una clase con un disparador anormalmente pequeño delata el backdoor | Costoso; escala mal con muchas clases |
| **Firmas espectrales** (`spectral signatures`) | Las muestras envenenadas forman un subgrupo separable en el espacio de activaciones internas | Requiere acceso al conjunto de entrenamiento |
| **Poda de neuronas** (`fine-pruning`) | Eliminar las neuronas que no se activan con datos limpios — suelen ser las que implementan el backdoor | Puede degradar el rendimiento legítimo |
| **Reentrenamiento parcial** (`fine-tuning` con datos limpios verificados) | Diluye la puerta trasera | No garantiza eliminarla |
| **Procedencia del artefacto** | Firmar y verificar el modelo; no aceptar pesos de origen no verificado | <mark style="background: #FFB8EBA6;">La única medida realmente preventiva</mark> |

La última fila es la recomendación de fondo. <mark style="background: #FF5582A6;">Detectar un backdoor en un modelo ya entrenado es un problema abierto y caro; **impedir que entre un modelo no confiable es un problema de gestión de cadena de suministro, y ese sí está resuelto**.</mark> Firma de artefactos, verificación de hash en el despliegue, repositorio interno de modelos aprobados y procedencia documentada.

Conecta directamente con [[11 - Pickle y la deserialización insegura de modelos]]: los mismos controles que impiden cargar un modelo con un backdoor impiden cargar uno que ejecute código al deserializarse.

> [!important]+ Cómo reportarlo
> Sin acceso al entrenamiento, un pentester **no puede demostrar** que un modelo en producción tiene un backdoor — el espacio de disparadores posibles es infinito. Lo que sí se puede y se debe reportar es la **ausencia de controles que lo impidan**:
> - ¿De dónde vienen los pesos del modelo y quién los firmó?
> - ¿Se verifica integridad al cargarlos en producción?
> - ¿Quién puede escribir en el registro de modelos y en la ruta de despliegue?
> - ¿Se usan modelos preentrenados de terceros? ¿Con qué verificación?
> - ¿Hay un conjunto canario evaluado tras cada reentrenamiento?
>
> Ese es el hallazgo accionable, y es el mismo encuadre que en [[07 - Evaluación del clean label attack#Al reportar|el clean label]]: **la vulnerabilidad no es el ataque, es no poder detectarlo ni prevenirlo**.
