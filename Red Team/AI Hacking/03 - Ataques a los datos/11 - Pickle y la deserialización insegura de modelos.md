---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - IA/LLM
Descripción: "Todo lo anterior en esta carpeta produce predicciones erróneas"
Fecha de actualización: 2026-07-28
Nota previa: "[[10 - Evaluación del trojan]]"
Nota siguiente: "[[12 - Esteganografía en tensores]]"
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

Todo lo anterior en esta carpeta produce **predicciones erróneas**. Esto produce **ejecución de código**. Es el salto de "el modelo se equivoca" a "tengo una shell en su infraestructura", y es el vector con más impacto real de todo el módulo.

<mark style="background: #ADCCFFA6;">El problema no está en las matemáticas de la red neuronal: está en cómo se guardan y se cargan los modelos.</mark>

# `pickle` y `__reduce__`

`pickle` es la forma estándar de Python de serializar un objeto y reconstruirlo. Y es peligroso por diseño, no por error de implementación.

Cuando `pickle.load()` reconstruye un objeto, consulta su método especial **`__reduce__`**, que devuelve las instrucciones para rebuildearlo: típicamente **un invocable y sus argumentos**. `pickle` ejecuta ese invocable sin cuestionarlo.

Un adversario define una clase cuyo `__reduce__` devuelve `exec` u `os.system` con una cadena maliciosa. Al deserializar una instancia, `pickle` obedece:

```python
import pickle, os

class Exploit:
    def __reduce__(self):
        return (os.system, ("id",))     # se ejecutará al hacer pickle.load()

payload = pickle.dumps(Exploit())
# ...cualquiera que haga pickle.loads(payload) ejecuta 'id'
```

La documentación oficial de Python lo dice sin rodeos: <mark style="background: #FF5582A6;">*"Warning: The pickle module is not secure. Only unpickle data you trust."*</mark>

# Por qué esto afecta a todos los modelos de PyTorch

`torch.save(obj, filepath)` **usa `pickle`**. `torch.load(filepath)` usa `pickle.load()` internamente. Hereda el riesgo completo.

Y ese es exactamente el flujo normal de trabajo con modelos: se descarga un `.pth` o un `.pt` de un repositorio, se hace `torch.load()`, se ejecuta lo que traiga dentro.

## `weights_only`

PyTorch introdujo el argumento `weights_only=True` para acotar el problema. Con él, `torch.load` usa un *unpickler* restringido que solo admite tipos básicos necesarios para cargar parámetros —tensores, diccionarios, listas, tuplas, cadenas, números, `None`— y **rechaza clases arbitrarias y la ejecución vía `__reduce__`**.

En versiones recientes de PyTorch es el **valor por defecto**. El ataque de este módulo requiere que la aplicación llame explícitamente a `torch.load(filepath, weights_only=False)`.

> [!warning]+ `weights_only=True` no fue seguro hasta PyTorch 2.6 — CVE-2025-32434
> <mark style="background: #FF5582A6;">En PyTorch **2.5.1 y anteriores**, `torch.load` con `weights_only=True` **también permitía ejecución remota de código** ([CVE-2025-32434](https://github.com/pytorch/pytorch/security/advisories/GHSA-53q9-r3pm-6pq6), CVSS **9.3**).</mark> Parcheado en **2.6.0**.
>
> Es especialmente grave porque la documentación oficial presentaba esa opción como segura, y muchísimo código la usa precisamente como mitigación. Al auditar un despliegue, **`weights_only=True` no basta: hay que comprobar también la versión de PyTorch**.

# Por qué sigue existiendo en producción

Aunque el valor por defecto sea seguro, el vector aparece constantemente:

| Situación | Por qué se usa `weights_only=False` |
| - | - |
| Se guarda el **modelo completo** (`torch.save(model, ...)`) y no solo el `state_dict` | Reconstruir el objeto exige deserializar la clase → `weights_only=False` obligatorio |
| El checkpoint incluye optimizador, scheduler, `scaler`, configuración | Objetos que el unpickler restringido rechaza |
| Código heredado o tutoriales antiguos | Se copió y pegó antes de que existiera la opción |
| Versión de PyTorch anterior a 2.6 | El default no era seguro, o el flag no protegía |
| Formatos `.pkl`, `.joblib` de scikit-learn | **No tienen equivalente a `weights_only`** — deserializar es ejecutar |

<mark style="background: #8000E1A6;">Esa última fila importa: el ecosistema de scikit-learn distribuye modelos en `pickle` puro y no tiene ninguna mitigación equivalente.</mark> Un `.pkl` de un modelo de scikit-learn es, literalmente, código ejecutable disfrazado de datos.

# Qué comprobar en un engagement

En orden, y todo es de análisis estático salvo el último punto:

1. **¿Qué formato usan los artefactos?** `.pth`/`.pt` (pickle), `.pkl`/`.joblib` (pickle puro), `.h5` (Keras — también con vectores), `.onnx` o `.safetensors` (**seguros**, sin ejecución).
2. **¿Cómo se cargan?** Buscar `torch.load(`, `pickle.load(`, `joblib.load(`, `pd.read_pickle(` en el código de servicio.
3. **¿Se pasa `weights_only=False` explícitamente?** Y si no se pasa nada, **¿qué versión de PyTorch hay instalada?**
4. **¿De dónde vienen los modelos?** Hub público, bucket propio, artefactos de CI, subida por usuario.
5. **¿Hay verificación de integridad antes de cargar?** Hash, firma, escaneo del artefacto.
6. **¿Existe un endpoint que acepte modelos subidos por el usuario?** Es el escenario del lab, y es más común de lo que parece — plataformas de MLOps, servicios de inferencia gestionada, herramientas de comparación de modelos.

El punto 6 convierte esto en una **RCE no autenticada**: si una aplicación acepta un fichero de modelo y lo carga, no hace falta comprometer nada más.

# Alternativas seguras

| Formato | Ejecuta código al cargar | Nota |
| - | - | - |
| `pickle` / `.pth` / `.pkl` | **Sí** | Evitar para artefactos no confiables |
| **`safetensors`** | **No** | Estándar actual de Hugging Face. Solo tensores y metadatos; no hay código que ejecutar |
| `ONNX` | No (el grafo sí puede tener operadores personalizados) | Interoperable; revisar operadores custom |
| `GGUF` | No | Formato de `llama.cpp` |
| `.h5` / Keras | Parcialmente | Las capas `Lambda` pueden llevar código |

<mark style="background: #FFB86CA6;">La recomendación de fondo para el informe es una sola frase: **migrar a `safetensors` y prohibir la carga de formatos basados en `pickle` desde origen no verificado**.</mark> Es una medida concreta, ampliamente adoptada y que cierra la clase entera.

Complementos que hay que pedir además:

- **Escaneo del artefacto** antes de cargar, integrado en CI: [[00 - Qué es ModelScan|`ModelScan`]] o [[00 - Qué es picklescan|`picklescan`]] para el barrido, [[00 - Qué es fickling y análisis de pickle|`fickling`]] para saber **qué hace** exactamente lo que salte ([[01 - ModelScan en el pipeline|dónde colocar el escaneo]]).
- **Verificación de hash o firma** en el despliegue, contra un registro de modelos aprobados.
- **Carga en un proceso aislado** sin credenciales ni red saliente, cuando haya que aceptar formatos inseguros.

# Y esto es solo el vector de ejecución

`pickle` da **cómo** ejecutar código. La otra mitad del ataque es **dónde esconder el payload** para que el fichero no parezca lo que es — y para eso están los millones de parámetros del propio modelo. Es [[12 - Esteganografía en tensores]].
