---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "ModelScan escanea ficheros de modelo buscando código inseguro, sin cargarlos"
Fecha de actualización: 2026-07-28
Nota previa: 
Nota siguiente: "[[01 - ModelScan en el pipeline]]"
Area: "[[ModelScan.base|ModelScan]]"
---
---

<mark style="background: #ADCCFFA6;">`ModelScan` escanea ficheros de modelo buscando código inseguro, **sin cargarlos**.</mark> Es un proyecto abierto de **Protect AI** y fue el primer escáner de modelos que soportó varios formatos, no solo `pickle`.

La idea que lo justifica, y que conviene llevarse a cualquier informe: <mark style="background: #FFB86CA6;">un fichero de modelo se abre con la misma confianza con la que se abriría un `.exe` de un desconocido, y casi nadie lo escanea con el rigor con el que se escanea un PDF del correo.</mark>

# Instalación y uso

```shell-session
$ pip install modelscan
$ modelscan -p /path/to/model_file.pkl
```

Un directorio entero:

```shell-session
$ modelscan -p ./models/
```

# Cómo funciona

No ejecuta el modelo. Inspecciona la serialización buscando **firmas de código inseguro** —importaciones y operaciones peligrosas— dentro del contenido. Por eso es rápido: escanea sin coste de carga ni de inferencia.

Los hallazgos se clasifican por **severidad**, lo que permite triar cuando hay muchos artefactos y no todo lo que salta es explotable.

# Formatos soportados

Es su diferencia principal frente a [[00 - Qué es picklescan|picklescan]]:

| Formato | Origen | Riesgo |
| - | - | - |
| **Pickle** y derivados (`.pkl`, `.pth`, `.pt`, `.bin`, `.joblib`) | PyTorch, scikit-learn, muchos otros | Ejecución de código al deserializar |
| **H5 / HDF5** | Keras, TensorFlow | Capas `Lambda` con código embebido |
| **SavedModel** | TensorFlow | Operaciones con efectos laterales |

<mark style="background: #8000E1A6;">La cobertura de H5 y SavedModel importa porque el foco público está casi todo en `pickle`</mark>, y un cliente que trabaje con TensorFlow puede tener la falsa sensación de estar fuera del problema. No lo está: una capa `Lambda` de Keras almacena código serializado y se ejecuta al cargar el modelo.

# En un engagement

Su papel es el **barrido**: pasar todo el inventario de artefactos y ver qué salta. Lo que salte se analiza con [[00 - Qué es fickling y análisis de pickle|`fickling`]] para saber qué hace exactamente.

Encaja en el paso 2 del [[15 - Arsenal de herramientas para ataques a los datos#Flujo sugerido para un engagement|flujo de auditoría]], y es de las comprobaciones que más rápido producen un hallazgo crítico:

```shell-session
# Todos los artefactos que la aplicación carga en producción
$ modelscan -p /opt/app/models/

# Modelos descargados de terceros antes de aprobarlos
$ modelscan -p ./descargas_hub/
```

> [!important]+ Un escaneo limpio no es una garantía
> `ModelScan` busca **firmas conocidas**. Un payload ofuscado —código codificado que se decodifica en tiempo de ejecución, o repartido en [[12 - Esteganografía en tensores|los LSB de un tensor]] dejando visible solo un cargador genérico— puede pasar.
> <mark style="background: #FF5582A6;">Al reportar, "escaneamos y no salió nada" no equivale a "los modelos son seguros".</mark> La recomendación de fondo sigue siendo la de [[11 - Pickle y la deserialización insegura de modelos#Alternativas seguras|migrar a `safetensors`]] y verificar procedencia; el escáner es una capa, no la solución.

Y a la inversa, desde el lado ofensivo: comprobar **qué evade** el escáner del cliente es un hallazgo más útil que comprobar que lo tiene — el procedimiento está en [[01 - Uso ofensivo y defensivo de fickling#3 · Medir la cobertura del escáner del cliente|medir la cobertura del escáner]].

# Versión comercial

Protect AI ofrece `Guardian` como producto de pago con más escáneres, más formatos, detección automática de formato y trazabilidad de auditoría. <mark style="background: #FFB8EBA6;">Conviene saberlo al recomendar</mark>: si un cliente ya tiene Guardian, la cobertura es mayor que la del proyecto abierto y el hallazgo hay que matizarlo.
