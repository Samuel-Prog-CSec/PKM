---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Enumeracion
  - Introduccion
  - Tipo/Introduccion
Descripción: "La mayoría de los hallazgos críticos de un engagement de IA no están en el modelo, sino en la aplicación que lo envuelve y en la infraestructura que lo sirve"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - Model reverse engineering y robo de modelos]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">La mayoría de los hallazgos críticos de un engagement de IA no están en el modelo, sino en la aplicación que lo envuelve y en la infraestructura que lo sirve.</mark> Es una conclusión incómoda para quien llega buscando `jailbreaks`, y es la que sostiene el valor comercial de este tipo de trabajo: un `prompt injection` que hace decir una tontería al chatbot se reporta como *medium*; un `MLflow` sin autenticación con `path traversal` a RCE se reporta como *critical* y cierra el informe.

Los cuatro componentes de un despliegue de IA —modelo, datos, aplicación y sistema— ya están definidos en [[00 - Red teaming de sistemas basados en ML]], y sus riesgos genéricos en [[09 - Ataques a los componentes de aplicación]] y [[10 - Ataques a los componentes de sistema]]. Este sub-tema baja al detalle operativo de los dos últimos: **qué se prueba, en qué orden, y qué se explota de verdad**.

# Por qué estos dos componentes concentran el impacto

El modelo es difícil de romper de forma que importe. Los ataques puramente sobre el modelo —[[01 - Prompt injection y por qué no tiene parche|prompt injection]], [[00 - El pipeline de datos y su superficie de ataque|envenenamiento]], evasión adversarial— tienen un techo natural: <mark style="background: #FFB8EBA6;">el impacto acaba donde acaban los permisos del modelo</mark>. Si el LLM solo puede escribir texto en una caja, el peor caso es texto inapropiado.

Los componentes de aplicación y sistema son justamente los que **le dan permisos al modelo**. Un plugin que ejecuta SQL, una función que lee ficheros, un agente con credenciales de la API interna, un servidor de inferencia con el disco de entrenamiento montado. <mark style="background: #8000E1A6;">El `prompt injection` no es el impacto: es el mecanismo de entrega. El impacto lo pone la superficie que hay detrás</mark>, y esa superficie vive en estas dos capas.

A esto se suma una asimetría de madurez brutal. El código de una aplicación web bancaria lleva veinte años recibiendo pentests; el stack de MLOps se escribió en 2020-2023 asumiendo redes internas de confianza y aún hoy despliega servicios sin autenticación por defecto. Es terreno de 2005 con presupuestos de 2026.

# El catálogo de esta carpeta

Los ataques se agrupan por componente y por lo que exige cada uno del atacante.

## Componente de aplicación

| Ataque | Qué requiere | Impacto típico |
| - | - | - |
| [[01 - Model reverse engineering y robo de modelos\|Model reverse engineering]] | Solo acceso a la API | Robo de propiedad intelectual, base para ataques de caja blanca |
| [[02 - Denial of ML Service y sponge examples\|Denial of ML Service]] | Solo acceso a la API | Indisponibilidad, coste operativo, agotamiento de batería |
| [[03 - Componentes integrados inseguros\|Componentes integrados inseguros]] | Cuenta de usuario | Fuga de datos de otros usuarios, SQLi, `IDOR` |
| [[04 - Rogue actions y agencia excesiva\|Rogue actions]] | Cuenta de usuario | Acciones no autorizadas con privilegios de la aplicación |

## Componente de sistema

| Ataque | Qué requiere | Impacto típico |
| - | - | - |
| [[05 - Manejo excesivo de datos y almacenamiento inseguro\|Almacenamiento inseguro]] | Enumeración web | Fuga masiva de conversaciones, PII, datos regulados |
| [[06 - Model deployment tampering\|Deployment tampering]] | Acceso a la infra o al pipeline | Backdoor persistente en el modelo servido |
| [[07 - Vulnerabilidades en el stack de ML\|Stack de ML vulnerable]] | Acceso de red al servicio | RCE, LFI, DoS — compromiso total |

El [[08 - MLflow, del path traversal al RCE|caso de MLflow]] merece nota propia porque es, con diferencia, el servicio del stack que más veces aparece expuesto y el que acumula más CVEs explotables sin autenticación.

> [!important]+ El orden importa
> En un engagement con tiempo limitado, el orden que maximiza hallazgos por hora es el inverso al que enseña la teoría: **primero infraestructura** (escaneo de puertos, servicios de MLOps expuestos, versiones vulnerables), **después aplicación** (`IDOR`, inyecciones, control de acceso en los plugins), **y solo al final el modelo**. Los dos primeros bloques se automatizan; el tercero consume horas de interacción manual.

# Encaje con los marcos de 2026

HTB mapea este contenido al `OWASP Top 10 for LLM Applications`, lo cual es correcto pero ya insuficiente: la mitad de este sub-tema describe sistemas **agénticos**, y desde diciembre de 2025 existe un marco específico para ellos.

| Ataque de esta carpeta | OWASP LLM Top 10 (2025) | OWASP Agentic Top 10 (2026) |
| - | - | - |
| Model reverse engineering | `LLM10: Unbounded Consumption` | — |
| Denial of ML Service | `LLM10: Unbounded Consumption` | `ASI08: Cascading Failures` |
| Componentes integrados inseguros | `LLM05: Improper Output Handling` | `ASI02: Tool Misuse & Exploitation` |
| Rogue actions | `LLM06: Excessive Agency` | `ASI01: Agent Goal Hijack`, `ASI10: Rogue Agents` |
| Almacenamiento inseguro | `LLM02: Sensitive Information Disclosure` | `ASI06: Memory & Context Poisoning` |
| Deployment tampering | `LLM03: Supply Chain` | `ASI04: Agentic Supply Chain` |
| Stack de ML vulnerable | `LLM03: Supply Chain` | `ASI05: Unexpected Code Execution` |

> [!info]+ Fuente: [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/)
> Publicado el **9 de diciembre de 2025** por el OWASP GenAI Security Project. Diez riesgos con prefijo `ASI` (*Agentic Security Initiative*): `ASI01` Agent Goal Hijack · `ASI02` Tool Misuse & Exploitation · `ASI03` Identity & Privilege Abuse · `ASI04` Agentic Supply Chain Vulnerabilities · `ASI05` Unexpected Code Execution · `ASI06` Memory & Context Poisoning · `ASI07` Insecure Inter-Agent Communication · `ASI08` Cascading Failures · `ASI09` Human-Agent Trust Exploitation · `ASI10` Rogue Agents.
>
> No sustituye al [[03 - OWASP Top 10 para aplicaciones LLM|LLM Top 10]]: lo complementa. El LLM Top 10 cubre el modelo como *generador*; el Agentic Top 10 cubre el modelo como *actor* con credenciales, memoria, herramientas y autonomía para encadenar acciones. En un informe de 2026 se citan los dos.

Para la trazabilidad de técnicas frente al cliente, `MITRE ATLAS` sigue siendo la referencia (ver [[05 - MITRE ATLAS y NIST AI RMF]]): `AML.T0024` (*Exfiltration via ML Inference API*) para la exfiltración vía API, `AML.T0018` (*Backdoor ML Model*) para el backdoor en el modelo, y `AML.T0011` (*User Execution*) cuando el vector es que un usuario ejecute un artefacto o comando malicioso.

# La pregunta que abre el reconocimiento

Antes de lanzar un solo `payload`, hay tres respuestas que determinan todo lo demás:

1. **¿Qué puede hacer el modelo además de escribir texto?** Herramientas, plugins, `function calling`, acceso a base de datos, ejecución de código, envío de correo. Cada capacidad es un vector.
2. **¿Con qué identidad las ejecuta?** ¿Con los permisos del usuario que pregunta, o con una cuenta de servicio única y sobre-privilegiada? Lo segundo es lo habitual y convierte cualquier `prompt injection` en escalada de privilegios.
3. **¿Qué hay expuesto en la red que sirve al modelo?** Registro de modelos, servidor de inferencia, notebooks, orquestador, almacenamiento de artefactos.

<mark style="background: #FF5582A6;">Un despliegue en el que el modelo ejecuta herramientas con una cuenta de servicio compartida y sin confirmación humana es un hallazgo por sí mismo</mark>, aunque no se llegue a explotar: es la precondición de todo lo que viene en [[04 - Rogue actions y agencia excesiva]].

Cuando el despliegue usa `MCP` para conectar el modelo con sus herramientas —el caso dominante desde 2025— la superficie tiene un cuerpo propio y bastante más profundo: está en [[00 - Qué es MCP y por qué cambia la superficie de ataque]].
