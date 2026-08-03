---
tags:
  - IA/Red-Team
  - IA
  - IA/Privacidad
  - Pentesting/Explotacion
  - Introduccion
  - Tipo/Introduccion
Descripción: "La familia de ataques que extrae información del entrenamiento: pertenencia, inversión, inferencia de atributos y extracción literal, y su encaje en los marcos"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - Por qué los modelos filtran pertenencia]]"
Area: "[[Privacidad en IA.base|Privacidad en IA]]"
---
---

<mark style="background: #ADCCFFA6;">Un modelo debería aprender patrones, no memorizar individuos. En la práctica hace las dos cosas, y la segunda es explotable.</mark> Los ataques de privacidad no buscan que el modelo se equivoque —eso es [[00 - Fundamentos de la evasión de modelos|evasión]]— ni corromper su entrenamiento —eso es [[01 - Taxonomía de los ataques a los datos|envenenamiento]]—: buscan **recuperar información sobre los datos con los que se entrenó**, a partir de su comportamiento en inferencia.

# La familia de ataques

| Ataque | Qué recupera | Coste típico |
| - | - | - |
| **Membership inference** (`MIA`) | Si un registro concreto estuvo en el entrenamiento | El más barato: una consulta por individuo |
| **Model inversion** | Reconstruye features del entrenamiento a partir de las salidas | Medio; requiere optimización iterativa |
| **Attribute inference** | Deduce atributos sensibles que el modelo **no** predice | Medio; requiere consultas dirigidas |
| **Training data extraction** | Recupera ejemplos de entrenamiento **literales** | Alto, pero devastador cuando funciona |

`MIA` es la puerta de entrada de toda la familia, por tres razones que conviene tener claras al priorizar en un engagement:

1. **Es el que menos información necesita.** Basta acceso de caja negra al modelo y una muestra candidata.
2. **Es un indicador de las demás.** <mark style="background: #8000E1A6;">Un modelo que filtra pertenencia casi siempre filtra más:</mark> el mecanismo subyacente —memorización— es el mismo que habilita inversión y extracción.
3. **Es la métrica estándar de auditoría de privacidad.** Cuando un paper o un producto dice "medimos la privacidad del modelo", lo que mide es normalmente la ventaja de un `MIA`.

## Por qué la pertenencia ya es información sensible

Es tentador descartar `MIA` como poco impactante: "solo dice si un dato estaba o no en el entrenamiento". El impacto depende por completo de **qué define al conjunto de entrenamiento**:

- Un modelo de diagnóstico entrenado **solo con pacientes oncológicos**: confirmar pertenencia revela el diagnóstico.
- Un modelo de *scoring* crediticio entrenado con **solicitantes rechazados**: confirmar pertenencia revela el rechazo.
- Un clasificador de moderación entrenado con **contenido sancionado**: confirmar pertenencia revela una infracción previa.

<mark style="background: #FFB86CA6;">En los tres casos, la pertenencia **es** el dato sensible.</mark> Y a diferencia de una brecha de base de datos, no hay evidencia de acceso: las consultas del ataque son indistinguibles de tráfico legítimo de inferencia.

# Lo que HTB no cubre: extracción en LLMs

El módulo se centra en clasificadores tabulares y de imagen, donde la extracción literal es difícil. En **modelos generativos** la superficie es mucho peor, y es el escenario que un red teamer se encuentra hoy:

- **Memorización verbatim.** Los LLM reproducen literalmente secuencias de su corpus de entrenamiento, sobre todo las que aparecen duplicadas. Es la vía por la que salen claves de API, direcciones, fragmentos de código propietario y datos personales que estaban en un *scrape*.
- **Ataques de divergencia.** Prompts que sacan al modelo de su distribución de generación habitual (repetición de un token, formatos inusuales) elevan mucho la tasa de emisión de memorizado. Carlini y coautores demostraron extracción a escala sobre modelos de producción con esta técnica.
- **Coste marginal cero.** A diferencia del `MIA` clásico, que requiere entrenar modelos sombra, la extracción en LLM se hace **solo con prompts**.

> [!important]+ Cómo se cruza con el resto del vault
> La extracción de datos de entrenamiento en un LLM se materializa casi siempre como [[03 - Inyección directa y fuga del system prompt|inyección directa]] o [[05 - Inyección indirecta en RAG, email y web|indirecta]], y el objetivo del cliente suele ser la fuga del `system prompt` o de documentos del RAG. La diferencia conceptual: la **fuga de contexto** saca lo que está en la ventana ahora; la **extracción de datos de entrenamiento** saca lo que está en los pesos. En un informe conviene separarlas, porque las mitigaciones son completamente distintas.

Del lado de robo del modelo en sí —no de sus datos— el vecino es [[01 - Model reverse engineering y robo de modelos|model reverse engineering]]: comparten el patrón de consulta anómala como señal de detección.

# El modelo de amenaza del `MIA`

El atacante estándar tiene **acceso de caja negra**: envía entradas y observa las salidas, sin ver parámetros, gradientes ni activaciones. Es el escenario realista de un modelo servido por API. Dos matices que importan:

- **Recibe el vector completo de probabilidades**, no solo la clase. <mark style="background: #FFB8EBA6;">Devolver solo la etiqueta —sin `softmax`— es en sí una mitigación parcial</mark>, y es lo primero que hay que comprobar al enumerar un endpoint de inferencia.
- **Conoce la distribución de los datos de entrenamiento**, aunque no las muestras exactas. Es una asunción realista: los datos de entrenamiento rara vez vienen de fuentes secretas, sino de poblaciones identificables (pacientes de una red hospitalaria, clientes de una región, un dataset público como Adult Census).

El límite de consultas apenas estorba: el `MIA` necesita **una consulta por individuo objetivo**. Atacar a 100 personas cuesta 100 consultas, dentro de cualquier cuota razonable. Lo caro —entrenar modelos sombra— ocurre **offline**, sin tocar el objetivo.

<mark style="background: #FF5582A6;">Esa asimetría es lo que hace al `MIA` difícil de detectar:</mark> el sondeo no tiene forma anómala. A diferencia del [[01 - Model reverse engineering y robo de modelos|robo de modelos]], que barre sistemáticamente el espacio de entrada, aquí el atacante envía entradas perfectamente normales y recibe respuestas normales. Sin saber a quién apunta, el propietario no puede separar ataque de uso legítimo.

Con acceso de **caja blanca** todo es más fácil (se calcula la pérdida exacta sobre la muestra objetivo) y conocer los hiperparámetros de entrenamiento permite replicar mejor el comportamiento del objetivo. El caso de caja negra es el que se estudia porque es el peor para el atacante y el más común en despliegue.

# Encaje con los marcos de riesgo

| Marco | Dónde aparece |
| - | - |
| [[01 - OWASP Machine Learning Security Top 10\|OWASP ML Top 10]] (borrador v0.3) | `ML04:2023` Membership Inference Attack, junto a `ML03` Model Inversion y `ML05` Model Theft |
| [[03 - OWASP Top 10 para aplicaciones LLM\|OWASP LLM Top 10]] (2025) | `LLM02: Sensitive Information Disclosure` cubre la fuga de datos de entrenamiento |
| [[04 - Google Secure AI Framework (SAIF)\|Google SAIF]] | `Sensitive Data Disclosure` e `Inferred Sensitive Data`, con responsabilidad repartida entre creador y consumidor del modelo |
| [[05 - MITRE ATLAS y NIST AI RMF\|NIST AI 100-2e2025]] | Categoría *Privacy compromise* de la taxonomía de ataques |

> [!warning]+ Matiz sobre las cifras de OWASP ML
> HTB cita para `ML04` una explotabilidad de 4/5 e impacto 4/5. Conviene recordar que **OWASP ML Top 10 sigue siendo un borrador v0.3 en el Incubator**: sus puntuaciones no tienen el respaldo de datos que sí tienen las de OWASP Web. Citarlo como referencia orientativa, no como métrica de riesgo defendible ante un cliente.

Los tres marcos convergen en la misma recomendación —**privacidad diferencial**—, que es lo que desarrollan las notas de [[05 - Privacidad diferencial, épsilon y el mecanismo gaussiano|DP]], [[06 - DP-SGD, clipping, ruido y contabilidad con Opacus|DP-SGD]] y [[08 - PATE, ensemble de profesores y agregación con ruido|PATE]]. Antes de defender, hay que entender exactamente **qué señal** explota el ataque: [[01 - Por qué los modelos filtran pertenencia|por qué los modelos filtran pertenencia]].
