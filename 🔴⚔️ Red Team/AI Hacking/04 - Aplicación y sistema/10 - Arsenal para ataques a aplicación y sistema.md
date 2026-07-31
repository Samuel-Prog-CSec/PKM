---
tags:
  - IA/Red-Team
  - IA
  - Pentesting
  - Tipo/Arsenal
Descripción: "El set para auditar la app y la infra de un despliegue de IA: escaneo del stack de MLOps, análisis de artefactos y explotación de la capa de aplicación, con las de siempre reorientadas"
Fecha de actualización: 2026-07-29
Nota previa: "[[09 - Detección y evasión en aplicación y sistema]]"
Nota siguiente: 
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 3 del vault. El arsenal **general** de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]]; aquí, lo específico de atacar la **aplicación y la infraestructura** que rodean al modelo. La mayoría no son herramientas nuevas de IA: son las de un pentest de red y web, reorientadas a los objetivos del stack de ML.

# El principio: casi todo esto ya lo tienes

<mark style="background: #ADCCFFA6;">La app y la infra de un sistema de IA se atacan con el arsenal de pentest de siempre, apuntado a objetivos nuevos.</mark> El valor no está en herramientas exóticas sino en saber **qué puertos añadir al escaneo** y **qué formatos de artefacto analizar**. Lo verdaderamente específico de IA es la capa de análisis de artefactos de modelo.

# Reconocimiento del stack de MLOps

El escaneo estándar con los puertos del stack de ML añadidos explícitamente — no están en los perfiles por defecto de `Nmap`:

```shell-session
$ nmap -sV -p 5000,6333,6334,8000,8001,8002,8080,8081,8265,8888,9200,11434,19530 <objetivo>
```

| Puerto | Servicio | Qué buscar |
| - | - | - |
| 5000 | MLflow | Versión → [[08 - MLflow, del path traversal al RCE\|traversal/RCE sin auth]] |
| 6333/6334 | Qdrant | Base vectorial sin auth |
| 8000–8002 | Triton, Chroma | RCE (CVE-2026-24207), volcado vectorial |
| 8265 | Ray | RCE sin auth (ShadowRay) |
| 8888 | Jupyter | Notebook sin token = ejecución de Python |
| 11434 | ollama | DoS/RCE, no pensado para exponerse |
| 9200 | Elasticsearch/OpenSearch | `k-NN` vectorial, datos |
| 19530 | Milvus | Base vectorial sin auth |

| Herramienta | Para qué | Nota |
| - | - | - |
| **`Nmap`** | Fingerprinting de servicio y versión | Puertos del stack añadidos a mano. Ver `02 - Recursos/🛠️ Tools/Nmap/` |
| **`nuclei`** | Confirmar exposición y CVE conocida | Plantillas para Ray, MLflow, Triton, ollama. Lo más rápido para el primer barrido |
| **`Shodan` / `Censys`** | Alcance externo por banner | Búsquedas por los banners de estos servicios |
| **`Burp Suite`** | La capa de aplicación, donde está el impacto | Ver `02 - Recursos/🛠️ Tools/Burp Suite/` |
| **`ffuf` / `gobuster`** | Enumeración de artefactos y endpoints | `.db`, `.jsonl`, `.sqlite3`, `.bak`. Ver [[00 - Introducción a ffuf\|Ffuf]] |

# Análisis de artefactos de modelo

Lo único genuinamente específico de IA. Cuando se llega a un artefacto de modelo —descargado por traversal, encontrado en un registro expuesto, subido por el cliente— se analiza **antes** de cargarlo, porque cargar un `pickle` malicioso es RCE en la propia máquina del pentester.

| Herramienta | Autor | Para qué |
| - | - | - |
| **[[00 - Qué es fickling y análisis de pickle\|`fickling`]]** | Trail of Bits | Descompila y analiza `pickle` sin ejecutarlo; detecta `__reduce__` maliciosos e incluso **inyecta** payloads. La correcta para entender un artefacto a fondo |
| **[[00 - Qué es ModelScan\|`ModelScan`]]** | Protect AI | Escanea `pickle`, `joblib`, `h5`, TorchScript en busca de deserialización insegura. Fácil de meter en CI |
| **[[00 - Qué es picklescan\|`picklescan`]]** | — | Ligera; detecta importaciones peligrosas en `pickle`. La que usa Hugging Face |
| **`safetensors`** | Hugging Face | El **formato** seguro, la mitigación por defecto: solo tensores, sin código |

El detalle a bajo nivel de por qué un `pickle` ejecuta código está en [[11 - Pickle y la deserialización insegura de modelos]].

# Explotación de la capa de aplicación

Todo el arsenal web del vault aplica aquí sin cambios, porque la aplicación que envuelve al modelo **es** una aplicación web:

- **[[00 - Introducción a SQL Injection|SQLi]]** y [[00 - Introducción a SQLMap|SQLMap]] contra la capa de datos y contra los argumentos que compone el modelo.
- **[[06 - Introducción a IDOR|IDOR]]** contra los endpoints y contra las herramientas del chatbot en paralelo.
- **[[01 - Introducción a SSRF|SSRF]]** contra la carga de modelos/datos por URL y contra el descubrimiento de metadatos.
- **[[01 - Local File Inclusion (LFI)|LFI]] / path traversal** contra los parámetros de ruta del stack.
- **[[00 - Introducción a Command Injection|Command injection]]** cuando la salida del modelo llega a un `shell` — ver [[03 - Inyección de comandos a través del LLM]].

# Escaneo de LLM y guardrails

Para la parte de modelo del engagement, el arsenal ya documentado:

- **[[00 - Qué es garak y cuándo usarlo|`garak`]]** (NVIDIA) — escáner de vulnerabilidades de LLM. Primera pasada de cobertura amplia. Referencia en `Tools/Garak/`.
- **[[00 - Qué es PyRIT y cuándo usarlo|`PyRIT`]]** (Microsoft) — orquestador de ataques multi-turno. Referencia en `Tools/PyRIT/`.
- **`ART`** — para model extraction y ejemplos adversariales sobre un modelo propio o replicado.

# Herramientas específicas de seguridad de IA

Las que sí nacieron para esto y merece la pena conocer, aunque muchas sean comerciales:

| Herramienta | Para qué |
| - | - |
| **Plataformas `huntr` / Protect AI** | Base de datos de vulnerabilidades del stack de ML/IA. La referencia para saber qué CVE afecta a qué versión de qué framework |
| **`HiddenLayer`** (comercial) | Escaneo de modelos, detección y respuesta, postura de seguridad sobre el pipeline de MLOps |
| **`Garak` + `PyRIT`** | El equivalente open-source para el modelo; ver arriba |
| **`grype` / `trivy` / `pip-audit`** | Escaneo de dependencias del stack. Un SBOM del entorno de ML y escaneo continuo |

# Flujo sugerido para el engagement

1. **Escanear la infra** con `Nmap` (puertos de ML) + `nuclei`. Es lo que da los hallazgos críticos más rápidos.
2. **Fingerprint de versiones** de cada servicio del stack y cruce con `huntr`/NVD.
3. **Explotar el stack** — traversal/RCE en MLflow, RCE en Ray/Triton, DoS en ollama, según lo encontrado.
4. **Auditar la capa de aplicación** — IDOR, inyecciones y control de acceso en endpoints **y** en las herramientas del chatbot en paralelo.
5. **Analizar los artefactos** de modelo con `fickling`/`ModelScan` antes de cargarlos.
6. **Probar el modelo** con `garak`/`PyRIT` para model extraction, DoS y las [[00 - Superficie de ataque de aplicación y sistema|rogue actions]].
7. **Entregar** por severidad: RCE del stack primero, después fuga de datos y control de acceso, y el mapa de **qué telemetría falta** para detectar todo lo anterior.

> [!warning]+ Cargar un modelo es ejecutar código
> Un `.pkl`, `.pth` o `.bin` del cliente **no se carga** con `torch.load` o `joblib.load` sin analizarlo antes con `fickling`/`ModelScan`. La deserialización de `pickle` ejecuta código arbitrario, y un artefacto malicioso comprometería la máquina del pentester. Siempre análisis estático primero; carga solo en `sandbox` si es imprescindible.
