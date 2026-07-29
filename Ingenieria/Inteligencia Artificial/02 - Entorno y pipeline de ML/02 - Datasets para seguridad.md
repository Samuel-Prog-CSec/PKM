---
tags:
  - IA
  - IA/Pipeline
Descripción: "La calidad del dataset marca el techo de lo que un modelo puede llegar a hacer"
Fecha de actualización: 2026-07-28
Nota previa: "[[01 - Librerías de Python para IA]]"
Nota siguiente: "[[03 - Preprocesamiento de datos]]"
Area: "[[Pipeline de ML.base|Pipeline de ML]]"
---
---

<mark style="background: #ADCCFFA6;">La calidad del dataset marca el techo de lo que un modelo puede llegar a hacer.</mark> Ningún algoritmo compensa datos malos, y en seguridad los datos son especialmente problemáticos: escasos, desbalanceados, mal etiquetados y con una distribución que cambia sola.

# Tipos y atributos

Los datos llegan en cuatro formas principales: **tabulares** (filas y columnas — logs, flujos de red, features extraídas de binarios), **imagen** (matrices de píxeles), **texto** (no estructurado) y **series temporales** (secuencias donde el orden importa).

| Atributo | Qué exige | Fallo típico en seguridad |
| - | - | - |
| Relevancia | Los datos guardan relación con el problema | Features que correlacionan con el laboratorio, no con el ataque |
| Completitud | Pocos valores ausentes | Logs con campos vacíos por errores de recolección |
| Consistencia | Formato y estructura uniformes | Timestamps en zonas horarias distintas, formatos de IP mezclados |
| Calidad | Datos exactos y sin errores | Etiquetas asignadas por un antivirus que también se equivoca |
| Representatividad | Refleja la población real que se quiere modelar | Tráfico de laboratorio que no se parece a una red corporativa |
| Balance | Proporción razonable entre clases | Ataques al 0,01% — el caso normal |
| Tamaño | Suficiente para capturar la complejidad | Pocas muestras de la familia de malware que importa |

<mark style="background: #FFB8EBA6;">Representatividad y balance son los dos que se incumplen sistemáticamente</mark>, y son también los que más inflan las métricas de un producto.

# El dataset de ejemplo

El módulo usa un CSV de registros de red donde cada fila describe un evento:

| Columna | Contenido |
| - | - |
| `log_id` | Identificador único |
| `source_ip` | IP origen del evento |
| `destination_port` | Puerto destino |
| `protocol` | Protocolo (`TCP`, `TLS`, `SSH`…) |
| `bytes_transferred` | Volumen transferido |
| `threat_level` | `0` normal, `1` amenaza baja, `2` amenaza alta |

Viene deliberadamente sucio: mezcla numérico y categórico, hay valores ausentes, columnas numéricas con cadenas de texto, y `threat_level` con marcadores desconocidos (`?`, `-1`).

## Carga y exploración

```python
import pandas as pd

data = pd.read_csv("./demo_dataset.csv")

print(data.head())          # primeras filas: estructura general
print(data.info())          # tipos, nulos y número de entradas por columna
print(data.isnull().sum())  # cuántos ausentes por columna
```

`info()` es la primera llamada útil: si una columna que debería ser numérica aparece como `object`, hay cadenas mezcladas y toca limpiar.

# Los datasets reales de seguridad y sus problemas

Aquí es donde el ejemplo de juguete se aleja de la práctica. Si vas a evaluar un producto o a leer un paper, hay que saber sobre qué se entrenó — y la mayoría de datasets públicos del sector tienen defectos conocidos.

| Dataset | Uso | Estado |
| - | - | - |
| `KDD Cup 99` / `NSL-KDD` | Detección de intrusiones | <mark style="background: #FF5582A6;">Obsoletos.</mark> Tráfico sintético de 1998, con registros redundantes. Verlos en un trabajo de 2026 es señal de alarma |
| `CIC-IDS2017` / `CSE-CIC-IDS2018` | Detección de intrusiones | Más modernos, pero con errores de etiquetado y de generación documentados por trabajos posteriores |
| `UNSW-NB15` | Detección de intrusiones | Alternativa razonable, aunque también sintética |
| `CTU-13` | Tráfico de botnets | Capturas reales; muy usado para investigación de C2 |
| `EMBER` / `SoReL-20M` | Clasificación de malware | Features extraídas de PE, no binarios. Grandes y bien documentados |

El problema de fondo lo señalaron [Sommer y Paxson](https://www.icir.org/robin/papers/oakland10-ml.pdf) y sigue vigente: **no existe un dataset público bueno de tráfico de red malicioso**, porque el tráfico real es sensible y el sintético no reproduce la variabilidad del real. Cualquier métrica publicada sobre estos conjuntos hay que leerla con esa reserva. Ver [[11 - Detección de anomalías]].

# El dataset como superficie de ataque

<mark style="background: #FFB86CA6;">Un dataset es un artefacto de la cadena de suministro, y como tal se puede comprometer.</mark> Al descargar de un repositorio público —Hugging Face, Kaggle, un enlace de un paper— se está confiando en su integridad exactamente igual que al instalar un paquete.

> [!warning]+ Envenenar datasets a escala web es barato y está demostrado
> [Carlini et al., *Poisoning Web-Scale Training Datasets is Practical* (IEEE S&P 2024)](https://arxiv.org/abs/2302.10149) demostraron dos ataques prácticos sobre datasets construidos a partir de la web:
> - **`Split-view poisoning`** — los datasets grandes distribuyen **URLs**, no contenido. Quien controle el contenido servido en esas URLs cuando el equipo de entrenamiento las descarga controla lo que entra en el modelo. Los dominios caducan y se pueden comprar.
> - **`Frontrunning poisoning`** — para fuentes con instantáneas periódicas (Wikipedia, por ejemplo), basta editar justo antes del momento del volcado; la edición se revierte después, pero ya está capturada.
>
> Su conclusión operativa es la que importa: contaminar una fracción suficiente de datasets muy usados costaba **decenas de dólares**. No es un escenario teórico.

Tres controles mínimos al incorporar datos de terceros a un pipeline:

- **Verificar integridad** — sumas de comprobación publicadas, y almacenar una copia propia en vez de redescargar de la URL original en cada entrenamiento.
- **Auditar la procedencia** — quién construyó el dataset, cómo se etiquetó y si el etiquetado es auditable.
- **Vigilar el reentrenamiento continuo** — si el pipeline ingiere datos de producción, el atacante escribe en el dataset simplemente usando el sistema, como se detalla en [[08 - Aprendizaje no supervisado]].

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, ampliado con el panorama de datasets reales de seguridad y sus defectos, y con el dataset como vector de cadena de suministro, ausentes en el original.
- [Carlini et al., *Poisoning Web-Scale Training Datasets is Practical*, IEEE S&P 2024](https://arxiv.org/abs/2302.10149) — `split-view` y `frontrunning poisoning` (consultado 2026-07-28).
- [Sommer & Paxson, *Outside the Closed World*, IEEE S&P 2010](https://www.icir.org/robin/papers/oakland10-ml.pdf) — problema de los datasets en detección de intrusiones.
