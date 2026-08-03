---
tags:
  - IA/Red-Team
  - IA
  - Pentesting
  - Pentesting/Reporting
Descripción: "ATLAS —*Adversarial Threat Landscape for Artificial-Intelligence Systems*— es la base de conocimiento de tácticas y técnicas adversariales contra sistemas de IA, construida con…"
Fecha de actualización: 2026-07-28
Nota previa: "[[04 - Google Secure AI Framework (SAIF)]]"
Nota siguiente: "[[06 - Red teaming de IA generativa]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

> [!info]+ Nota añadida al temario
> HTB cubre OWASP y SAIF y se detiene ahí. En un engagement real se usan al menos dos marcos más: **MITRE ATLAS** para describir la cadena de ataque en lenguaje que el `blue team` ya conoce, y **NIST** para la clasificación formal del riesgo y el encaje regulatorio. Sin ellos, el informe habla un idioma que la mitad de los destinatarios no maneja.

# MITRE ATLAS

<mark style="background: #ADCCFFA6;">`ATLAS` —*Adversarial Threat Landscape for Artificial-Intelligence Systems*— es la base de conocimiento de tácticas y técnicas adversariales contra sistemas de IA, construida con la misma estructura que MITRE ATT&CK.</mark> Recoge observaciones de ataques reales y demostraciones de equipos de red team, con casos de estudio y mitigaciones asociadas.

Su valor no es proponer una taxonomía nueva de vulnerabilidades —para eso están OWASP y NIST— sino **describir la progresión de un ataque**: qué hace el adversario, en qué orden y con qué objetivo en cada fase.

## Estructura

Igual que ATT&CK: **tácticas** como columnas (el *por qué*, el objetivo del adversario en esa fase) y **técnicas** como filas (el *cómo*). La matriz recorre de izquierda a derecha la progresión típica del ataque, y agrupa a grandes rasgos en preparación, establecimiento, explotación y objetivos.

Reutiliza las tácticas clásicas de ATT&CK —reconocimiento, desarrollo de recursos, acceso inicial, ejecución, persistencia, escalada de privilegios, evasión de defensas, acceso a credenciales, descubrimiento, recolección, exfiltración e impacto— y añade las **específicas de IA**, que son las que aportan lo nuevo:

- **Acceso al modelo** — cómo obtiene el adversario capacidad de consulta o de acceso al artefacto: API pública, aplicación que lo integra, fichero de modelo, o acceso al entorno de inferencia. <mark style="background: #FFB8EBA6;">Es la táctica que no existe en ATT&CK y que estructura todo lo demás</mark>: el nivel de acceso al modelo determina qué ataques son viables.
- **Preparación del ataque al modelo** (`ML Attack Staging`) — el trabajo previo específico de este dominio: entrenar un modelo sustituto, generar datos envenenados, construir ejemplos adversariales, verificarlos contra la réplica antes de lanzarlos al objetivo real.

## Para qué sirve en la práctica

- **Encaja con lo que el cliente ya usa.** Si el SOC trabaja con ATT&CK, ATLAS se lee sin traducción y permite discutir detección y cobertura en los mismos términos.
- **Da estructura narrativa a la cadena de ataque.** Un informe que describe "reconocimiento → acceso al modelo → preparación → evasión → exfiltración" comunica mucho mejor que una lista de hallazgos sueltos. Ver [[04 - Componentes de un informe I (cadena de ataque y resumen ejecutivo)]].
- **Casos de estudio reales.** Documenta incidentes públicos contra sistemas de IA, útiles para justificar la severidad de un hallazgo ante un cliente escéptico.

<mark style="background: #FF5582A6;">ATLAS es un marco vivo</mark>: el número de tácticas, técnicas y casos crece con cada revisión. Consultar siempre la matriz actual en lugar de trabajar de memoria.

# NIST

## AI RMF (AI 100-1)

El `AI Risk Management Framework` es el marco de gestión de riesgo de IA del NIST, organizado en cuatro funciones:

| Función | Qué cubre |
| - | - |
| `Govern` | Cultura, políticas, roles y responsabilidades sobre el riesgo de IA. Transversal a las otras tres |
| `Map` | Contextualizar: qué hace el sistema, en qué entorno, con qué impactos posibles |
| `Measure` | Analizar y medir los riesgos identificados con métricas y pruebas |
| `Manage` | Priorizar, tratar y monitorizar el riesgo residual |

Es voluntario y de nivel organizativo, no técnico. <mark style="background: #8000E1A6;">Su utilidad en un informe es la sección de recomendaciones estratégicas</mark>: permite situar cada hallazgo dentro de un programa de gestión que la dirección reconozca, en lugar de dejar una lista de arreglos técnicos sin marco.

El **Generative AI Profile** (`NIST AI 600-1`, julio de 2024) complementa el RMF con los riesgos específicos de IA generativa y acciones sugeridas para cada función.

## AI 100-2e2025 — la taxonomía adversarial

Es la referencia técnica, ya usada a lo largo de todo el path. [*Adversarial Machine Learning: A Taxonomy and Terminology of Attacks and Mitigations*](https://csrc.nist.gov/pubs/ai/100/2/e2025/final), marzo de 2025.

Clasifica los ataques en **cinco dimensiones**, y esa estructura es la más precisa disponible para describir un hallazgo:

1. **Tipo de sistema** — `PredAI` (predictivo) o `GenAI` (generativo).
2. **Fase del ciclo de vida** — diseño, entrenamiento, despliegue, inferencia.
3. **Objetivo del atacante** — qué propiedad se viola: disponibilidad, integridad o privacidad.
4. **Capacidades y acceso** del atacante.
5. **Conocimiento** del atacante sobre el proceso de aprendizaje (`white-box`, `black-box` o intermedio).

Para `PredAI` cubre evasión, envenenamiento y ataques de privacidad; para `GenAI` añade cadena de suministro, inyección directa e indirecta, abuso y **seguridad de agentes**.

> [!important]+ Por qué esta taxonomía gana a las listas Top 10 para clasificar
> Un hallazgo descrito como "`LLM01` Prompt Injection" dice poco. Descrito según NIST —*ataque de integridad sobre GenAI, en fase de inferencia, mediante inyección indirecta, con acceso black-box*— dice **exactamente** qué ocurrió, qué se violó y qué haría falta para mitigarlo.
>
> <mark style="background: #FFB86CA6;">Lo práctico es usar ambas</mark>: la referencia OWASP porque el cliente la reconoce, y las cinco dimensiones NIST para que la descripción sea precisa y las recomendaciones se deriven solas.

# Normativa y certificación

Dos referencias que aparecen cada vez más en el alcance y en las preguntas del cliente:

- **Reglamento europeo de IA (`AI Act`)** — regulación con obligaciones **escalonadas en el tiempo** según la categoría de riesgo del sistema, con requisitos específicos para los sistemas de alto riesgo y para los modelos de propósito general. Consultar siempre el calendario oficial vigente antes de afirmar qué aplica: las fechas se han ido ajustando desde su entrada en vigor.
- **`ISO/IEC 42001`** — norma certificable de sistema de gestión de IA, el equivalente a `ISO 27001` para este ámbito. Si el cliente la persigue, un informe alineado con sus requisitos de gestión de riesgo tiene mucho más recorrido interno.

# Qué usar y cuándo

| Necesidad | Marco |
| - | - |
| Delimitar el alcance por componente | [[04 - Google Secure AI Framework (SAIF)]] |
| Etiquetar un hallazgo con referencia reconocible | [[03 - OWASP Top 10 para aplicaciones LLM]] |
| Describir la cadena de ataque y hablar con el `blue team` | MITRE ATLAS |
| Clasificar el hallazgo con precisión técnica | NIST AI 100-2e2025 |
| Recomendaciones de gobierno y programa | NIST AI RMF · ISO/IEC 42001 |
| Asignar responsabilidad creador/consumidor | SAIF |

Ninguno sobra y ninguno sustituye a otro. En un informe de calidad se usan tres o cuatro, cada uno en la sección donde aporta.

## Fuentes

- Nota net-new: no forma parte del temario de HTB Academy.
- [MITRE ATLAS](https://atlas.mitre.org/) — matriz de tácticas y técnicas adversariales contra sistemas de IA (consultado 2026-07-28).
- [NIST AI 100-2e2025 · Adversarial Machine Learning: A Taxonomy and Terminology of Attacks and Mitigations](https://csrc.nist.gov/pubs/ai/100/2/e2025/final) (marzo 2025).
- NIST AI 100-1 · *AI Risk Management Framework* y NIST AI 600-1 · *Generative AI Profile* (julio 2024).
