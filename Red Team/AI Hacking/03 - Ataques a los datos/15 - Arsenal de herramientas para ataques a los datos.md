---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting
  - Tipo/Arsenal
Descripción: "El Adversarial Robustness Toolbox (Linux Foundation AI & Data) implementa todos los ataques de esta carpeta con una API común, y también sus defensas"
Fecha de actualización: 2026-07-28
Nota previa: "[[14 - Detección y evasión en ataques a los datos]]"
Nota siguiente: 
Area: "[[Ataques a los datos.base|Ataques a los datos]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 3 del vault. HTB implementa todos los ataques a mano con NumPy, PyTorch y `struct`, lo cual está bien para entenderlos y es innecesario para ejecutarlos. El panorama general de herramientas de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]]; aquí, lo específico de envenenamiento e integridad de artefactos.

# Ataque

## ART — la referencia

El `Adversarial Robustness Toolbox` (Linux Foundation AI & Data) implementa **todos** los ataques de esta carpeta con una API común, y también sus defensas. Es lo que evita reescribir `flip_labels` cada vez.

| Módulo ART | Cubre |
| - | - |
| `art.attacks.poisoning.PoisoningAttackBackdoor` | [[08 - Backdoors y trojans en modelos\|Backdoors]] con disparadores configurables |
| `art.attacks.poisoning.PoisoningAttackCleanLabelBackdoor` | Backdoor **sin** reetiquetar |
| `art.attacks.poisoning.FeatureCollisionAttack` | [[05 - Clean label attacks\|Clean label]] por colisión de características (*Poison Frogs*) |
| `art.attacks.poisoning.SleeperAgentAttack` | Backdoor clean-label sobre redes profundas |
| `art.defences.detector.poison` | **Detección**: `ActivationDefence` (agrupamiento de activaciones), `SpectralSignatureDefence`, `ProvenanceDefense` |
| `art.defences.transformer.poisoning` | `Neural Cleanse` — reconstrucción de disparador |

<mark style="background: #FF5582A6;">Los módulos de `defences` valen tanto o más que los de ataque en un engagement</mark>: permiten **medir** si el pipeline del cliente detectaría un envenenamiento, que es el hallazgo que se reporta según [[14 - Detección y evasión en ataques a los datos|la nota anterior]].

## Complementarias

| Herramienta | Para qué |
| - | - |
| `TextAttack` | Envenenamiento y perturbación sobre NLP: sustitución de palabras, paráfrasis, nivel de carácter |
| `Foolbox` | Ejemplos adversariales sobre imagen, API muy limpia |
| `BackdoorBox` | Suite específica de backdoors con muchos tipos de disparador implementados |
| `struct` + PyTorch | La [[12 - Esteganografía en tensores\|esteganografía en LSB]] no tiene herramienta estándar — se implementa a mano |

# Integridad de artefactos — lo que más se usa en la práctica

Es la parte con más rendimiento en un engagement real, y es puramente defensiva-ofensiva: se usan las mismas herramientas para auditar y para verificar que un artefacto propio pasa el filtro.

| Herramienta | Autor | Para qué |
| - | - | - |
| **[[00 - Qué es fickling y análisis de pickle\|`fickling`]]** | **Trail of Bits** | <mark style="background: #ADCCFFA6;">Descompilador y analizador estático de `pickle`.</mark> Muestra el bytecode del pickle sin ejecutarlo, detecta `__reduce__` maliciosos y permite **inyectar** payloads en ficheros existentes. La herramienta correcta tanto para auditar como para construir |
| **[[00 - Qué es ModelScan\|`ModelScan`]]** | Protect AI | Escanea ficheros de modelo (`pickle`, `joblib`, `h5`, TorchScript) buscando deserialización insegura. Mantenimiento activo, fácil de meter en CI |
| **[[00 - Qué es picklescan\|`picklescan`]]** | — | Ligera y específica: detecta importaciones peligrosas en `pickle`. Es la que usa Hugging Face en su escaneo automático |
| **`safetensors`** | Hugging Face | El formato, no un escáner. La mitigación real: sin código que ejecutar |
| **`model-signing` / Sigstore** | OpenSSF | Firma y verificación de artefactos de modelo. Cierra el hueco de procedencia |

```shell-session
# Ver qué hace un pickle SIN ejecutarlo
$ pip install fickling
$ fickling --check-safety modelo_sospechoso.pth
$ fickling modelo_sospechoso.pth              # descompila el bytecode

# Escaneo de un directorio de modelos
$ pip install modelscan
$ modelscan -p ./models/
```

<mark style="background: #8000E1A6;">`fickling --check-safety` sobre cada artefacto que el cliente carga es una de las comprobaciones con mejor relación esfuerzo/hallazgo de todo el módulo</mark>, y se ejecuta en segundos. `fickling` está además disponible como plugin en el marketplace de Trail of Bits, ya configurado en este entorno.

# Datos — versionado y validación

Lo que habilita la detección de [[05 - Clean label attacks|clean label]] y de manipulación post-ingesta, y lo que se recomienda cuando no existe:

| Herramienta | Para qué |
| - | - |
| **`DVC`** | Versionado de datasets con hashes, integrado con git. Permite el diff que detecta ediciones |
| `LakeFS` | Control de versiones tipo git sobre data lakes (S3 y compatibles) |
| **`Cleanlab`** | <mark style="background: #FFB86CA6;">Detección de etiquetas erróneas por análisis de confianza.</mark> No se diseñó como herramienta de seguridad, y es lo mejor que hay contra [[02 - Label flipping\|label flipping]] |
| `Great Expectations` / `Pandera` | Validación de esquema, rangos y distribuciones en la ingesta. Corta el envenenamiento burdo |
| `Evidently` / `Alibi Detect` | Detección de deriva de datos y de outliers — señal de `online poisoning` |

`Cleanlab` merece la mención destacada: implementa *confident learning* para estimar qué muestras tienen la etiqueta mal, y aplicado a un dataset envenenado señala precisamente las invertidas. Es la materialización práctica de la detección por pérdida de [[14 - Detección y evasión en ataques a los datos#Detección por familia|la nota anterior]].

# Flujo sugerido para un engagement

1. **Inventariar el pipeline** con las preguntas de [[00 - El pipeline de datos y su superficie de ataque#Cómo se traduce esto al reconocimiento|la nota 00]]: canales de ingesta, almacenamiento, código de procesado, reentrenamiento, ruta de despliegue.
2. **Auditar los artefactos** con `fickling` y `ModelScan`. Es lo más rápido y lo que da los hallazgos críticos (RCE).
3. **Comprobar la carga en producción**: formato, `weights_only`, versión de PyTorch ([[11 - Pickle y la deserialización insegura de modelos#`weights_only`|CVE-2025-32434]]), verificación de hash o firma.
4. **Evaluar la robustez al envenenamiento** con ART sobre una réplica: qué porcentaje hace daño, y a partir de cuál lo detectarían.
5. **Ejecutar las defensas de ART** (`ActivationDefence`, `SpectralSignatureDefence`) sobre el modelo del cliente y reportar si detectan un backdoor plantado por nosotros.
6. **Comprobar la trazabilidad de datos**: ¿hay versionado? ¿se puede reconstruir qué datos entrenaron el modelo en producción?
7. **Entregar**: hallazgos de RCE por severidad, más el mapa de **qué ataques pasarían sin ser detectados** — que es el valor real del ejercicio.

> [!warning]+ Antes de ejecutar nada
> Los ataques de esta carpeta **modifican datos y modelos**. En un engagement se trabaja siempre sobre una **copia o réplica**, nunca sobre el pipeline de producción, y con el alcance por escrito. Un envenenamiento de prueba que llegue a un ciclo de reentrenamiento real degrada un modelo en producción y es muy difícil de revertir sin reentrenar desde cero.
