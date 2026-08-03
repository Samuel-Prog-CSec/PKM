---
tags:
  - IA/Red-Team
  - IA
  - Pentesting
Descripción: "El Secure AI Framework (SAIF) de Google cubre la seguridad del pipeline completo de IA, de la recolección de datos al despliegue del modelo"
Fecha de actualización: 2026-07-28
Nota previa: "[[03 - OWASP Top 10 para aplicaciones LLM]]"
Nota siguiente: "[[05 - MITRE ATLAS y NIST AI RMF]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

<mark style="background: #ADCCFFA6;">El `Secure AI Framework` (SAIF) de Google cubre la seguridad del pipeline completo de IA, de la recolección de datos al despliegue del modelo.</mark> La diferencia de enfoque frente a OWASP es clara y conviene tenerla presente al elegir con cuál trabajar: **OWASP es un catálogo técnico de vulnerabilidades; SAIF es un marco de desarrollo seguro** que además asigna responsabilidades.

# Las cuatro áreas

| Área | Componentes |
| - | - |
| `Data` | Fuentes de datos, filtrado y procesado, datos de entrenamiento |
| `Infrastructure` | Frameworks y código del modelo, entrenamiento/afinado/evaluación, almacenamiento de datos y modelos, `model serving` |
| `Model` | El modelo, el tratamiento de la entrada y el tratamiento de la salida |
| `Application` | Las aplicaciones que interactúan con el despliegue, y los agentes o plugins que este usa |

Esta descomposición es la que estructura el resto del path — con la salvedad de que HTB fusiona `Infrastructure` en su categoría `System`, quedando **modelo, datos, aplicación y sistema**.

# Los riesgos

Quince riesgos, muchos solapados con las listas de OWASP:

| Riesgo | Qué es |
| - | - |
| `Data Poisoning` | Datos maliciosos en el entrenamiento: degradación o `backdoor` |
| `Unauthorized Training Data` | Entrenar con datos sin derecho de uso: problema legal y ético |
| `Model Source Tampering` | Manipulación del código o los pesos del modelo |
| `Excessive Data Handling` | Recolección o retención más allá de lo permitido por la política de privacidad |
| `Model Exfiltration` | Acceso no autorizado al modelo: robo de propiedad intelectual |
| `Model Deployment Tampering` | Manipulación de los componentes del despliegue |
| `Denial of ML Service` | Entradas que agotan los recursos del servicio |
| `Model Reverse Engineering` | Reconstruir el modelo analizando entradas y salidas |
| `Insecure Integrated Component` | Vulnerabilidades en software que interactúa con el modelo (plugins) |
| `Prompt Injection` | Manipulación directa o indirecta de la entrada |
| `Model Evasion` | Perturbaciones que provocan inferencia incorrecta |
| `Sensitive Data Disclosure` | El modelo revela información sensible a la que tiene acceso |
| `Inferred Sensitive Data` | El modelo **infiere** información sensible a la que **no** tiene acceso |
| `Insecure Model Output` | La salida se procesa sin validar |
| `Rogue Actions` | Acciones dañinas por acceso insuficientemente restringido |

> [!important]+ `Inferred Sensitive Data` es la aportación propia de SAIF
> Es el riesgo más interesante de los que **no** tienen equivalente directo en OWASP —los otros dos son `Unauthorized Training Data` y `Excessive Data Handling`, ambos de naturaleza legal más que técnica—, y es el más sutil de los tres: <mark style="background: #FFB86CA6;">el modelo produce información sensible que **nunca tuvo**, deduciéndola de patrones del entrenamiento o del propio prompt.</mark>
>
> Un modelo que no contiene el historial médico de nadie puede inferir una condición de salud a partir de la combinación de síntomas, medicación y edad mencionados en la conversación. Un modelo de recomendación puede deducir orientación sexual, religión o situación económica de patrones de comportamiento.
>
> Importa porque **ninguna medida de control de acceso lo previene**: no hay dato que proteger, el dato se genera. La mitigación es de diseño del caso de uso y de la salida, no de permisos.

# Controles y responsabilidad compartida

Aquí está lo más útil de SAIF y lo que ningún otro marco hace igual de bien: cada control se mapea a los riesgos que mitiga **y se asigna a quién debe implementarlo**.

- **`Model creator`** — quien desarrolla y entrena el modelo.
- **`Model consumer`** — quien lo integra en una aplicación.

Ejemplos de controles:

| Control | Riesgos que mitiga | Implementa |
| - | - | - |
| Validación y saneado de la entrada | `Prompt Injection` | Creador y consumidor |
| Validación y saneado de la salida | `Prompt Injection`, `Rogue Actions`, `Sensitive Data Disclosure`, `Inferred Sensitive Data` | Creador y consumidor |
| Entrenamiento y pruebas adversariales | `Model Evasion`, `Prompt Injection`, `Sensitive Data Disclosure`, `Inferred Sensitive Data`, `Insecure Model Output` | Creador y consumidor |

> [!important]+ Por qué esta parte vale para un informe
> <mark style="background: #FF5582A6;">Es un modelo de responsabilidad compartida, igual que en la nube.</mark> Si una organización consume `Gemini`, `GPT` o `Claude` vía API, hay riesgos que **no puede** mitigar —integridad del entrenamiento, robustez base del modelo, alineación— y otros que son enteramente suyos: agencia excesiva, validación de la salida, control de acceso al contexto, límites de tasa.
>
> Confundir ambos grupos produce las dos patologías clásicas de un informe de IA: recomendar al cliente que "reentrene el modelo para que sea robusto frente a inyección" —imposible si consume una API de terceros— o dar por cubierto un riesgo porque "eso lo gestiona el proveedor" cuando en realidad es responsabilidad del integrador.
>
> Mapear cada hallazgo a creador o consumidor es una de las aportaciones más prácticas que se pueden llevar a la sección de recomendaciones.

# El Risk Map

El `Risk Map` de SAIF integra componentes, riesgos y controles en una sola vista, y distingue tres momentos que no coinciden:

- **`Risk introduction`** — dónde se introduce el riesgo.
- **`Risk exposure`** — dónde puede explotarse.
- **`Risk mitigation`** — dónde puede mitigarse.

<mark style="background: #8000E1A6;">Esa separación es la más valiosa del marco</mark>: el `data poisoning` se **introduce** en la recolección de datos, se **expone** en la inferencia (meses después y en otro componente), y se **mitiga** en la validación del pipeline de datos. Un equipo que solo audita el punto de exposición nunca encontrará la causa.

![Mapa de riesgos de SAIF mostrando el flujo desde las fuentes de datos hasta la aplicación](https://academy.hackthebox.com/storage/modules/294/saif_riskmap.png)

# Cuándo usar SAIF y cuándo OWASP

| | OWASP LLM/ML Top 10 | SAIF |
| - | - | - |
| Naturaleza | Catálogo de vulnerabilidades | Marco de desarrollo y gobierno |
| Uso en pentest | Clasificar hallazgos | Estructurar el alcance por componente |
| Uso en informe | Referencia por hallazgo | Asignar responsabilidad y recomendaciones |
| Público | Equipo técnico | Técnico y de gestión |

En la práctica se usan juntos: SAIF para delimitar el alcance y organizar las recomendaciones, OWASP para etiquetar cada hallazgo con una referencia que el cliente reconozca.

## Fuentes

- [Google Secure AI Framework (SAIF)](https://saif.google/) — áreas, [componentes](https://saif.google/secure-ai-framework/components), [riesgos](https://saif.google/secure-ai-framework/risks), [controles](https://saif.google/secure-ai-framework/controls) y [Risk Map](https://saif.google/secure-ai-framework/saif-map) (consultado 2026-07-28).
- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con el desarrollo del modelo de responsabilidad compartida y su aplicación en informes, y con la lectura del Risk Map como separación introducción/exposición/mitigación.
- Imagen del Risk Map: HTB Academy, módulo 294.
