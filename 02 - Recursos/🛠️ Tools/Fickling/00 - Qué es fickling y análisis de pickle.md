---
tags:
  - IA/Red-Team
  - Pentesting/Explotacion
  - IA
  - Tipo/Introduccion
Descripción: "fickling es un descompilador, analizador estático y reescritor de bytecode para serializaciones pickle de Python"
Fecha de actualización: 2026-07-28
Nota previa: 
Nota siguiente: "[[01 - Uso ofensivo y defensivo de fickling]]"
Area: "[[Fickling.base|Fickling]]"
---
---

<mark style="background: #ADCCFFA6;">`fickling` es un **descompilador, analizador estático y reescritor de bytecode** para serializaciones `pickle` de Python.</mark> Lo mantiene **Trail of Bits**, y es la herramienta correcta cuando hay que saber **qué hace exactamente** un fichero `pickle` sin ejecutarlo.

Esa capacidad es lo que la separa de los escáneres: [[00 - Qué es ModelScan|ModelScan]] y [[00 - Qué es picklescan|picklescan]] responden *sí o no* a "¿esto es peligroso?". `fickling` responde *"esto llama a `os.system` con esta cadena"*, y además permite construir el fichero.

Es la herramienta de referencia para lo descrito en [[11 - Pickle y la deserialización insegura de modelos]].

# Instalación

```shell-session
$ python -m pip install fickling

# Con soporte para modelos PyTorch
$ python -m pip install fickling[torch]
```

# Por qué hace falta descompilar

Un `pickle` no es un formato de datos: es un **programa** para una máquina virtual de pila. Cargarlo es ejecutarlo. Y la mayoría de las herramientas que lo procesan solo saben ejecutarlo, no leerlo.

`fickling` implementa la lectura: parsea el bytecode del pickle y lo traduce a un AST de Python equivalente. <mark style="background: #8000E1A6;">Con eso se puede razonar sobre qué hará el fichero **antes** de que lo haga.</mark>

# Comprobar si un fichero es seguro

El uso más habitual, y el que debería estar en cualquier auditoría de infraestructura de ML:

```shell-session
$ fickling --check-safety -p pickled.data
```

Detecta, entre otras cosas:

- **Ejecución de código arbitrario a través de importaciones** — el patrón `__reduce__` de [[11 - Pickle y la deserialización insegura de modelos#`pickle` y `__reduce__`|la nota de pickle]].
- **Variables declaradas y no usadas**, señal característica de payload inyectado en un pickle legítimo.
- **Operaciones abiertamente peligrosas** como llamadas a `eval`.

Desde Python, con excepción tipada:

```python
import fickling

try:
    fickling.load("file.pkl")
except fickling.UnsafeFileError as e:
    print("Unsafe file!")
```

<mark style="background: #FF5582A6;">Ese bloque es un sustituto directo de `pickle.load()` en código que tenga que aceptar ficheros de origen no plenamente confiable</mark>, y es una recomendación concreta y barata para un informe cuando migrar a `safetensors` no sea viable a corto plazo.

# Descompilar

Cuando `--check-safety` marca algo y hay que entender **qué**:

```python
>>> from fickling.fickle import Pickled
>>> import pickle, ast
>>> fickled_object = Pickled.load(pickle.dumps([1, 2, 3, 4]))
>>> print(ast.dump(fickled_object.ast, indent=4))
```

Sobre un fichero benigno el AST reconstruye la estructura de datos. Sobre uno malicioso, aparece la llamada real: el invocable que devuelve `__reduce__` y sus argumentos. Es la forma de pasar de "el escáner dice que es peligroso" a **"ejecuta este comando concreto"**, que es lo que se pone en un informe.

Desde la línea de comandos, para seguir la ejecución paso a paso de la máquina virtual del pickle:

```shell-session
$ fickling --trace file.pkl
```

# Modelos PyTorch

`fickling` entiende la estructura de los ficheros de PyTorch, que son `zip` con un `pickle` dentro:

```python
>>> from fickling.pytorch import PyTorchModelWrapper
>>> fickled_model = PyTorchModelWrapper("mobilenet.pth")
>>> print(fickled_model.formats)
```

<mark style="background: #FFB8EBA6;">La propiedad `formats` identifica qué variante de formato PyTorch es el fichero</mark>, y eso importa: las distintas versiones de `torch.save` producen estructuras diferentes, y un fichero que declara ser de una versión y tiene la estructura de otra es sospechoso por sí mismo.

Es la vía para analizar exactamente el artefacto que se construye en [[13 - Ejecución del ataque de esteganografía]].

# Dónde encaja

| Herramienta | Responde a |
| - | - |
| [[00 - Qué es picklescan\|`picklescan`]] | ¿Es peligroso? (rápido, para lotes) |
| [[00 - Qué es ModelScan\|`ModelScan`]] | ¿Es peligroso? (varios formatos, con severidad) |
| **`fickling`** | **¿Qué hace exactamente? ¿Y puedo construirlo yo?** |

En un engagement se usan en ese orden: escaneo masivo para triar, `fickling` sobre lo que salte. El uso ofensivo —inyectar payloads y verificar que un escáner no los detecta— está en [[01 - Uso ofensivo y defensivo de fickling]].

> [!info]+ Disponible como plugin
> Trail of Bits publica sus herramientas en un marketplace de plugins ya configurado en este entorno, junto a `static-analysis`, `semgrep-rule-creator` y `variant-analysis`. Ver la sección de plugins de `CLAUDE.md`.
