---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - Introduccion
  - Tipo/Introduccion
Descripción: "Las tres capas de defensa de un sistema de IA (guardrails en inferencia, entrenamiento adversarial y adversarial tuning), qué ataque cubre cada una y por qué ninguna basta sola"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - Guardrails de entrada y salida]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Defender un sistema de IA no es una medida, son **capas** que actúan en momentos distintos del ciclo de vida y cubren clases de ataque distintas. <mark style="background: #ADCCFFA6;">Ninguna es suficiente sola, y montarlas mal es tan caro como no montarlas.</mark>

| Capa | Cuándo actúa | Qué cubre | Qué **no** cubre |
| - | - | - | - |
| **Guardrails** | Inferencia, en la aplicación | Prompt injection, jailbreaking, fuga de datos en la salida, contenido fuera de política | Perturbaciones adversariales; ataques que no se ven en el texto |
| **Entrenamiento adversarial** | Entrenamiento del modelo | Perturbaciones adversariales sobre entradas continuas (imagen, señal, features) | Ataques de texto; normas distintas a la entrenada |
| **Adversarial tuning** | *Fine-tuning* del LLM | Jailbreaks y *priming* que los guardrails dejan pasar | Ataques genuinamente novedosos; contenido inyectado por otra vía |

La distinción operativa es **filtrar alrededor del modelo** frente a **endurecer el modelo**. Los guardrails son perímetro: interceptan lo que entra y lo que sale sin tocar los pesos, y por eso se pueden desplegar sobre una API comercial que no se controla. El entrenamiento adversarial y el *adversarial tuning* modifican los pesos, así que **solo están disponibles si se entrena o se afina el modelo propio**.

# Por qué el perímetro no basta

Los guardrails funcionan bien contra ataques **discretos y textuales**, donde el patrón malicioso es en principio detectable. <mark style="background: #FFB86CA6;">Las perturbaciones adversariales pertenecen a otra clase de problema: no inyectan contenido malicioso, hacen cambios imperceptibles a entradas legítimas.</mark> No hay nada que filtrar — la entrada es, píxel a píxel, casi idéntica a una válida.

El contraste con la seguridad tradicional es útil. Un paquete malformado, una secuencia de caracteres inesperada o una llamada al sistema sospechosa son objetos **discretos**: se pueden enumerar y bloquear. Una perturbación adversarial vive en espacio **continuo**, y la superficie de ataque no es un conjunto finito de entradas sino una variedad infinita de variaciones casi idénticas alrededor de cada entrada legítima. Contra eso, la defensa tiene que venir de dentro.

Las cifras del laboratorio del módulo lo cuantifican sobre MNIST: un clasificador estándar alcanza ~99 % en test limpio y cae a ~74 % con [[02 - FGSM, el ataque de un solo paso|FGSM]] a $\epsilon=0{,}3$, y a ~52 % con [[03 - I-FGSM, PGD y el refinamiento iterativo|I-FGSM]]. <mark style="background: #FF5582A6;">Ningún filtro de entrada habría visto nada raro en esas imágenes.</mark>

# Por qué endurecer el modelo tampoco basta

Y la simétrica: un modelo entrenado adversarialmente sigue procesando el texto que le llega. Un [[01 - Prompt injection y por qué no tiene parche|prompt injection]] no explota la frontera de decisión sobre píxeles; explota que el modelo no distingue instrucción de dato. El entrenamiento adversarial de visión no ayuda en nada ahí.

Con los LLM la frontera se difumina, y de ahí la tercera capa: el *adversarial tuning* aplica el principio del entrenamiento adversarial —entrenar sobre los ataques— al dominio del texto, enseñando al modelo a **reconocer y rechazar** la manipulación en lugar de depender solo del filtro externo.

> [!important]+ El argumento de la defensa en profundidad, con números
> Los guardrails atrapan lo evidente de forma barata; el *tuning* aguanta lo que se les escapa. Un atacante que evade el filtro de entrada se encuentra un modelo que reconoce la manipulación y declina. Con guardrails **LLM-as-a-judge**, el argumento se vuelve cuantitativo: <mark style="background: #8000E1A6;">el `payload` tiene que manipular al modelo guardián **y** al modelo principal a la vez</mark>, lo que reduce mucho la probabilidad de éxito frente a tener que romper solo uno.

# El coste que nadie presupuesta

Cada capa cuesta, y en dimensiones distintas:

- **Guardrails**: latencia. Un guardrail tradicional (regex, listas) tarda ~0,1 s; uno basado en LLM, ~1,6 s sumando entrada y salida — más de un orden de magnitud. Sobre una aplicación donde la latencia percibida ya es el mayor problema de UX, apilar guardrails de IA es una decisión de producto, no solo de seguridad.
- **Guardrails, segunda dimensión**: falsos positivos. Un guardrail demasiado estricto rechaza entradas legítimas, frustra al usuario y ahoga la utilidad del modelo. Encontrar el equilibrio exige iteración y pruebas en el dominio concreto; no hay configuración por defecto que valga.
- **Entrenamiento adversarial**: 2-3× el coste de entrenamiento por época, más precisión limpia sacrificada.
- **Adversarial tuning**: barato con LoRA (entrenar ~1,4 % de los parámetros), pero introduce el riesgo de **over-refusal** — un modelo que rechaza consultas legítimas es un modelo roto de otra manera.

<mark style="background: #FFB8EBA6;">La métrica de éxito nunca es solo "cuántos ataques paro".</mark> Es la pareja: cuántos ataques paro **y** cuánta utilidad conservo. Un modelo que rechaza el 100 % de los jailbreaks y solo es útil en el 50 % de las consultas legítimas ha fracasado.

# Encaje con los marcos

Las tres capas se mapean a controles concretos de los marcos que se usan para reportar:

- [[03 - OWASP Top 10 para aplicaciones LLM|OWASP LLM Top 10 (2025)]] — los guardrails de entrada cubren `LLM01: Prompt Injection`; los de salida, `LLM02: Sensitive Information Disclosure` y `LLM05: Improper Output Handling`.
- [[04 - Google Secure AI Framework (SAIF)|Google SAIF]] — separa explícitamente la responsabilidad del creador del modelo (entrenamiento robusto, alineamiento) de la del consumidor (filtrado de entrada/salida, monitorización). Las tres capas de aquí caen a ambos lados de esa línea, y es útil para asignar responsabilidades en un informe.
- [[01 - OWASP Machine Learning Security Top 10|OWASP ML Top 10]] — `ML01: Input Manipulation Attack` es lo que ataca el entrenamiento adversarial.

# El mapa de esta carpeta

| Bloque | Notas | Contra qué |
| - | - | - |
| **Guardrails** | [[01 - Guardrails de entrada y salida\|01]] · [[02 - Validación tradicional por caracteres y contenido\|02]] · [[03 - Guardrails basados en IA\|03]] · [[04 - Librerías de guardrails\|04]] · [[05 - Servicios gestionados de guardrails\|05]] | Prompt injection, jailbreaking, fuga en la salida |
| **Entrenamiento adversarial** | [[06 - Entrenamiento adversarial y el problema min-max\|06]] · [[07 - Epsilon spread y evaluación de robustez\|07]] | Perturbaciones adversariales |
| **Adversarial tuning** | [[08 - Adversarial tuning con LoRA para seguridad\|08]] · [[09 - Evaluar el safety tuning y el over-refusal\|09]] | Jailbreaks y ataques de *priming* |
| **Contraparte ofensiva** | [[10 - Límites de las defensas y cómo se rompen\|10]] | Qué prueba un red teamer contra cada capa |

> [!info]+ Dónde vive lo ofensivo
> Esta carpeta es la **construcción** de las defensas. Cómo se atacan vive en Red Team: [[01 - Prompt injection y por qué no tiene parche|prompt injection]], [[08 - Fundamentos del jailbreaking|jailbreaking]], [[11 - Evasión de detectores de contenido|evasión de detectores]], [[00 - Fundamentos de la evasión de modelos|evasión de modelos]] y [[00 - Fundamentos de los ataques dispersos y la norma L0|ataques dispersos]]. Las notas de aquí enlazan a esas para el punto de vista del atacante, y [[10 - Límites de las defensas y cómo se rompen|la nota 10]] resume el cruce.
