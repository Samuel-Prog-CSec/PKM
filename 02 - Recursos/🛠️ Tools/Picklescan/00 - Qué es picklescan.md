---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "picklescan detecta ficheros pickle de Python que realizan acciones sospechosas"
Fecha de actualización: 2026-07-28
Nota previa: 
Nota siguiente: 
Area: "[[Picklescan.base|Picklescan]]"
---
---

<mark style="background: #ADCCFFA6;">`picklescan` detecta ficheros `pickle` de Python que realizan acciones sospechosas.</mark> Es deliberadamente pequeño y específico —solo `pickle`, sin más formatos— y esa simplicidad es su virtud: es rápido, tiene códigos de salida limpios y **es el escáner que usa Hugging Face** para revisar automáticamente los modelos de su hub.

Ese último dato es el que lo hace relevante en un engagement: <mark style="background: #FFB86CA6;">saber qué detecta `picklescan` es saber qué filtro han pasado los modelos que el cliente descargó del hub</mark> — y, por tanto, qué se le pudo colar.

# Uso

```shell-session
$ pip install picklescan
```

Escanear directamente un repositorio de Hugging Face, sin descargarlo a mano:

```shell-session
$ picklescan --huggingface ykilcher/totally-harmless-model
```

```text
----------- SCAN SUMMARY -----------
Scanned files: 1
Dangerous globals: 1
```

El informe señala **`dangerous globals`**: los invocables peligrosos referenciados por el pickle. En el ejemplo, una llamada a `eval()` para ejecutar código arbitrario — el patrón de [[11 - Pickle y la deserialización insegura de modelos#`pickle` y `__reduce__`|`__reduce__`]].

También carga desde fichero local, directorio, URL y archivo `zip` (que es lo que son los `.pth` de PyTorch):

```shell-session
$ picklescan --path downloads/pytorch_model.bin
$ picklescan --path downloads
$ picklescan --url https://huggingface.co/<repo>/resolve/main/pytorch_model.bin
```

Para escanear ficheros `.npy` de NumPy hay que instalar antes el paquete `numpy`.

# Códigos de salida

Modelados sobre los de ClamAV, lo que hace trivial usarlo como puerta en CI:

| Código | Significado |
| - | - |
| `0` | No se encontró nada |
| `1` | **Se encontró malware** |
| `2` | El escaneo falló |

<mark style="background: #8000E1A6;">El código `2` merece atención al integrarlo</mark>: un `|| exit 1` genérico trata igual "hay malware" que "no pude escanear", y son situaciones distintas. Un fichero que el escáner no puede procesar es tan sospechoso como uno que falla el escaneo, pero el mensaje al equipo debe ser diferente.

# Filtrado

Al escanear directorios se pueden incluir o excluir rutas por expresión regular, repetible varias veces:

```shell-session
$ picklescan --path ./models --include='.*\.pth$'
$ picklescan --path ./models --exclude='.*/tests/.*'
```

# Cuándo usar este y no otro

| Situación | Herramienta |
| - | - |
| Barrido rápido de muchos ficheros `pickle` | **`picklescan`** |
| Modelos descargados de un hub, o el hub directamente | **`picklescan --huggingface`** |
| Puerta en CI con códigos de salida limpios | **`picklescan`** |
| Formatos que no son `pickle` (H5, SavedModel) | [[00 - Qué es ModelScan\|`ModelScan`]] |
| Saber **qué hace** el fichero que ha saltado | [[00 - Qué es fickling y análisis de pickle\|`fickling`]] |

> [!warning]+ Lo que implica que Hugging Face lo use
> Que el hub escanee automáticamente con `picklescan` es bueno y **no es suficiente**. Cubre `pickle` con firmas conocidas; un payload ofuscado, o repartido en [[12 - Esteganografía en tensores|los bits bajos de un tensor]] dejando visible solo un cargador genérico, puede pasar el filtro y quedar publicado con la etiqueta de "escaneado".
> <mark style="background: #FF5582A6;">"Viene de un hub que escanea" no es procedencia verificada.</mark> La recomendación sigue siendo la de [[01 - ModelScan en el pipeline#Escaneo no es integridad|la nota de ModelScan]]: formato seguro, firma verificada en la carga, y escaneo como capa adicional.
