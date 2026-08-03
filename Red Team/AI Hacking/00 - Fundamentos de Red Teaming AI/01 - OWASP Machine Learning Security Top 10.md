---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting
Descripción: "El OWASP Machine Learning Security Top 10 cataloga los diez riesgos principales de los sistemas basados en ML clásico — clasificadores, detectores, modelos predictivos"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Red teaming de sistemas basados en ML]]"
Nota siguiente: "[[02 - Manipulación del modelo]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

<mark style="background: #ADCCFFA6;">El `OWASP Machine Learning Security Top 10` cataloga los diez riesgos principales de los sistemas basados en ML **clásico** — clasificadores, detectores, modelos predictivos.</mark> Es el equivalente al Top 10 web pero para modelos, y no debe confundirse con el [[03 - OWASP Top 10 para aplicaciones LLM]], que cubre aplicaciones generativas y es una lista distinta y mucho más madura.

> [!warning]+ Sigue siendo un borrador, y conviene decirlo al citarlo
> El proyecto está en **versión 0.3 draft (edición 2023)** y catalogado como *Incubator Project* dentro de OWASP. No ha alcanzado versión estable en tres años. <mark style="background: #FFB8EBA6;">Es una taxonomía útil como vocabulario compartido con el cliente, no un estándar consolidado</mark>, y en un informe conviene indicarlo así — a diferencia del Top 10 web o del de LLM, que sí tienen ediciones estables.
>
> Para la clasificación formal de un hallazgo, la referencia más sólida es el [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final). Lo habitual en un informe profesional es referenciar ambos.

# Los diez riesgos

| ID | Riesgo | En la taxonomía NIST |
| - | - | - |
| `ML01` | Manipulación de la entrada | Evasión |
| `ML02` | Envenenamiento de datos | Envenenamiento |
| `ML03` | Inversión del modelo | Privacidad |
| `ML04` | Inferencia de pertenencia | Privacidad |
| `ML05` | Robo del modelo | Privacidad / propiedad intelectual |
| `ML06` | Ataques a la cadena de suministro de IA | Cadena de suministro |
| `ML07` | Ataque de transfer learning | Cadena de suministro |
| `ML08` | Sesgado del modelo | Envenenamiento |
| `ML09` | Integridad de la salida | Integridad (fuera del modelo) |
| `ML10` | Envenenamiento del modelo | Envenenamiento |

## ML01 · Manipulación de la entrada

Modificar la entrada para provocar una salida incorrecta. En la práctica: **ejemplos adversariales**, perturbaciones pequeñas que el humano no percibe y que cambian la clasificación.

El caso canónico son las señales de tráfico: pegatinas o manchas colocadas de forma precisa sobre una señal de STOP hacen que un clasificador la lea como límite de velocidad, mientras un conductor humano no aprecia nada raro. <mark style="background: #FFB86CA6;">Es un ataque del mundo físico, no de laboratorio</mark>, y es el escenario donde el impacto pasa de "predicción errónea" a consecuencia física.

Cómo se prueba: si hay acceso `white-box`, ataques de gradiente (`FGSM`, `PGD`, `C&W`); si no, transferencia desde un modelo sustituto o ataques basados en decisión. Las restricciones prácticas están en [[08 - Límites y evasión de los detectores ML]].

## ML02 · Envenenamiento de datos

Inyectar datos maliciosos o mal etiquetados en el conjunto de entrenamiento para degradar el modelo o implantar una **puerta trasera**.

El escenario que mejor lo ilustra: un motor antivirus basado en ML que se reentrena con muestras recolectadas automáticamente. Si el atacante logra introducir binarios propios etiquetados como benignos —o con un patrón disparador concreto—, obtiene un modelo que clasificará su malware como inofensivo **solo cuando lleve ese patrón**, manteniendo el rendimiento normal en todo lo demás y por tanto sin levantar sospechas en las métricas.

<mark style="background: #FF5582A6;">Su viabilidad depende de una pregunta operativa: ¿de dónde salen los datos de entrenamiento y quién puede escribir en esa fuente?</mark> Cuando la respuesta incluye "de producción" o "de la web", el ataque es realista — ver [[02 - Datasets para seguridad]].

## ML03 · Inversión del modelo

Entrenar un modelo **inverso** que, a partir de las salidas del modelo objetivo, reconstruya información sobre sus entradas. De ahí el nombre: invierte la función.

El riesgo aparece cuando la entrada es sensible. Un clasificador médico cuya salida permita reconstruir rasgos del historial del paciente filtra datos de salud sin que nadie acceda a la base de datos.

<mark style="background: #FFB8EBA6;">La cantidad de información que devuelve el modelo determina la viabilidad del ataque.</mark> Un endpoint que devuelve solo la clase predicha es mucho más resistente que uno que devuelve el vector completo de probabilidades. Es una recomendación defensiva concreta y barata: **no exponer los `logits` ni las probabilidades si el caso de uso no los necesita**.

## ML04 · Inferencia de pertenencia

Determinar si una muestra concreta formó parte del conjunto de entrenamiento. Se apoya en que <mark style="background: #8000E1A6;">los modelos se comportan de forma medible distinta ante datos que ya vieron</mark>: mayor confianza, menor pérdida.

Preocupa especialmente en modelos accesibles públicamente o en plataformas MLaaS. Y tiene implicación regulatoria directa: si el hecho de estar en el dataset es en sí mismo un dato sensible —un conjunto de pacientes con una patología concreta, una lista de clientes morosos—, la inferencia de pertenencia es una brecha de datos personales aunque no se extraiga ningún registro.

La contramedida efectiva coincide con la del sobreajuste, por el motivo explicado en [[02 - Aprendizaje supervisado]]: regularización, más datos, y privacidad diferencial cuando el riesgo lo justifique.

## ML05 · Robo del modelo

Duplicar la funcionalidad del modelo objetivo consultándolo sistemáticamente y entrenando una réplica con los pares entrada-salida obtenidos. No hace falta acceso a los pesos ni a la arquitectura.

Doble impacto: pérdida de propiedad intelectual —el coste de entrenamiento puede ser enorme y la réplica sale por una fracción— y, sobre todo, <mark style="background: #FFB86CA6;">**conversión del objetivo de `black-box` a `white-box`**</mark>. Con una réplica local, el atacante calcula gradientes libremente y genera ejemplos adversariales que después transfiere al modelo real.

Por eso el robo de modelo rara vez es el objetivo final en un red team: es el paso previo que abarata todo lo demás. Contramedidas: limitación de tasa por cliente, detección de patrones de consulta sistemática, marcas de agua en el modelo, y devolver la mínima información posible en la respuesta.

## ML06 · Cadena de suministro

Explotar cualquier eslabón del ecosistema: datasets de terceros, librerías, modelos preentrenados, contenedores, dependencias del pipeline.

<mark style="background: #FF5582A6;">La superficie es mayor que en un sistema tradicional</mark> porque a las dependencias de software se suman datos y modelos, y estos últimos rara vez pasan por ningún control. Un fichero de modelo descargado de un repositorio público es código ejecutable cuando el formato es `pickle`, `joblib` o TorchScript — ver [[01 - Redes neuronales]] y [[03 - Entrenamiento y evaluación del clasificador de spam]].

## ML07 · Ataque de transfer learning

Caso particular del anterior, y lo bastante frecuente como para tener entrada propia. Casi ningún equipo entrena desde cero: se parte de un modelo preentrenado y se afina. Si el modelo base viene manipulado, el comportamiento malicioso **sobrevive al ajuste fino** aunque el dataset de afinado sea completamente limpio.

Es el escenario descrito en [[07 - CNN para clasificación de malware]], visto desde el otro lado: el `backbone` que se descarga y se congela es código y pesos de un tercero, y lo que aprendió no se audita.

## ML08 · Sesgado del modelo

Desviar deliberadamente la salida del modelo hacia el objetivo del atacante, típicamente inyectando datos con etiquetas incorrectas. La diferencia con `ML02` es de intención más que de mecanismo: `ML02` puede buscar degradar; `ML08` busca un sesgo concreto y dirigido.

<mark style="background: #FFB8EBA6;">El solapamiento entre `ML02`, `ML08` y `ML10` es una debilidad conocida de esta lista.</mark> Los tres son envenenamiento; se diferencian en el punto de aplicación (datos frente a parámetros) y en el objetivo (degradar frente a dirigir). En un informe conviene describir el mecanismo concreto y no apoyarse solo en el ID.

## ML09 · Integridad de la salida

No ataca al modelo: **intercepta y altera su salida** antes de que la consuma el sistema siguiente.

El ejemplo lo explica bien: un sistema borra del disco todo binario que el clasificador marque como malicioso. El atacante deja su malware, el clasificador lo detecta correctamente, y el atacante cambia la etiqueta a `benigno` en tránsito. El binario sobrevive.

<mark style="background: #8000E1A6;">Es el riesgo más "clásico" de la lista y por eso el más fácil de pasar por alto en una auditoría centrada en el modelo</mark>: el modelo funciona perfectamente y toda medida de seguridad centrada en él es inútil. Lo que falla es la integridad del canal entre el modelo y quien actúa sobre su resultado — un problema de autenticación e integridad de mensajes, resoluble con firma y canal autenticado.

## ML10 · Envenenamiento del modelo

Manipular directamente los **parámetros** del modelo, no los datos. Requiere acceso al artefacto, así que el vector previo suele ser un repositorio de modelos mal protegido, un bucket expuesto o un pipeline de CI comprometido.

Modificar pesos al azar solo degrada el rendimiento; conseguir una desviación **dirigida** que preserve el comportamiento normal y active un `backdoor` ante un disparador concreto exige manipulación cuidadosa, y es un área de investigación activa.

# Cómo usar esta lista en un engagement

- Como **checklist de cobertura** al definir el alcance: para cada riesgo, ¿aplica a este sistema?, ¿qué habría que probar?, ¿está dentro del alcance?
- Como **vocabulario compartido** en el informe, indicando su estado de borrador.
- **No** como taxonomía de clasificación fina de hallazgos: los solapamientos entre `ML02`/`ML08`/`ML10` y entre `ML06`/`ML07` producen clasificaciones discutibles. Para eso, `NIST AI 100-2e2025` y [[05 - MITRE ATLAS y NIST AI RMF]] son mejores.

## Fuentes

- [OWASP Machine Learning Security Top 10 (v0.3 draft, 2023)](https://owasp.org/www-project-machine-learning-security-top-10/) — lista y definiciones (consultado 2026-07-28).
- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con el estado de borrador del proyecto, el mapeo a la taxonomía NIST, la crítica de solapamientos y la orientación de uso en engagement, ausentes en el original.
- [NIST AI 100-2e2025](https://csrc.nist.gov/pubs/ai/100/2/e2025/final) — taxonomía de referencia para clasificar los hallazgos.
