---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting
Descripción: "El OWASP Top 10 for LLM Applications cubre los riesgos de las aplicaciones construidas sobre modelos generativos de texto"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Manipulación del modelo]]"
Nota siguiente: "[[04 - Google Secure AI Framework (SAIF)]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

<mark style="background: #ADCCFFA6;">El `OWASP Top 10 for LLM Applications` cubre los riesgos de las aplicaciones construidas sobre modelos generativos de texto.</mark> A diferencia del [[01 - OWASP Machine Learning Security Top 10]], que sigue en borrador, esta lista tiene ediciones estables y es **la referencia real de la industria** para clasificar hallazgos sobre aplicaciones LLM. La edición vigente es la de **2025**, y el proyecto se ha ampliado hasta convertirse en el `OWASP GenAI Security Project`.

# Los diez riesgos (edición 2025)

| ID | Riesgo | Qué es |
| - | - | - |
| `LLM01` | Prompt Injection | Manipular la entrada, directa o indirectamente, para desviar el comportamiento del modelo. Desarrollado a fondo en [[01 - Prompt injection y por qué no tiene parche\|Prompt Injection]] |
| `LLM02` | Divulgación de información sensible | El modelo revela datos confidenciales en su respuesta |
| `LLM03` | Cadena de suministro | Vulnerabilidades en cualquier eslabón: datos, modelo base, plugins, dependencias. Ver [[11 - Pickle y la deserialización insegura de modelos]] y [[08 - Slopsquatting y alucinación de paquetes]] |
| `LLM04` | Envenenamiento de datos y modelo | Inyección de datos maliciosos en el entrenamiento o afinado. Desarrollado en [[01 - Taxonomía de los ataques a los datos\|Ataques a los datos]] |
| `LLM05` | Tratamiento inseguro de la salida | La salida se consume sin validar, produciendo XSS, SQLi o inyección de comandos. Desarrollado en [[00 - Tratamiento inseguro de la salida del LLM\|LLM Output Attacks]] |
| `LLM06` | Agencia excesiva | El modelo tiene más permisos o capacidades de las que necesita. Ver [[05 - Agencia excesiva y funciones vulnerables]] |
| `LLM07` | Fuga del prompt de sistema | Se extraen las instrucciones que gobiernan el comportamiento del modelo |
| `LLM08` | Debilidades en vectores y embeddings | Fallos en la generación, almacenamiento o recuperación en sistemas RAG |
| `LLM09` | Desinformación | Respuestas falsas presentadas con apariencia de certeza (`hallucination`). Ver [[07 - Alucinaciones del LLM]] y [[08 - Slopsquatting y alucinación de paquetes]] |
| `LLM10` | Consumo no acotado | Entradas que disparan el consumo de recursos: DoS, coste, o extracción del modelo |

## LLM01 · Prompt injection

El riesgo número uno, y con razón. Manipular la entrada para que el modelo se desvíe de su comportamiento previsto: desde hacer que un chatbot de soporte técnico dé recetas de cocina hasta generar contenido dañino o revelar información que se le confió.

<mark style="background: #FF5582A6;">La distinción operativa clave —que la lista menciona pero merece énfasis— es directa frente a indirecta.</mark> En la **directa**, el atacante escribe el prompt. En la **indirecta**, el payload llega dentro de contenido que el modelo lee: una página web, un correo, un PDF, la respuesta de una API, un documento recuperado por RAG. La indirecta es la peligrosa, porque el atacante no necesita ninguna interacción con el sistema — solo que el sistema lea algo suyo.

La razón por la que no tiene solución arquitectónica está en [[04 - Transformers y el mecanismo de atención]]: no existe separación entre instrucción y dato dentro de la secuencia de tokens.

## LLM02 · Divulgación de información sensible

El modelo revela datos que no debía. Tres orígenes distintos, con mitigaciones distintas:

- **Del contexto** — documentos de otros usuarios, historial de conversación ajeno, contenido recuperado por RAG sin control de acceso.
- **Del afinado** — un modelo ajustado con datos internos puede reproducir fragmentos memorizados, según lo descrito en [[05 - IA generativa]].
- **Del prompt de sistema** — solapa con `LLM07`.

<mark style="background: #FFB8EBA6;">El control determinante es que la autorización se aplique **antes** de la recuperación, no después</mark>: filtrar los documentos por permisos del usuario al consultar la base vectorial, en lugar de recuperar todo y confiar en que el modelo no lo mencione. Confiar en el modelo para hacer cumplir un control de acceso es delegar la autorización en un componente probabilístico.

## LLM03 · Cadena de suministro

Datos de entrenamiento, modelos preentrenados de terceros, plugins, servidores `MCP`, librerías y contenedores. La superficie es la misma que en `ML06`/`ML07` más los componentes específicos del ecosistema generativo.

## LLM04 · Envenenamiento de datos y modelo

Manipular el entrenamiento o el afinado para introducir sesgos o `backdoors`. <mark style="background: #FFB86CA6;">Con un LLM que genera código, el impacto va más allá del propio modelo</mark>: un modelo envenenado que sugiere sistemáticamente patrones vulnerables —o que introduce una dependencia inexistente que el atacante después registra— propaga el compromiso a todo lo que se construya con él.

## LLM05 · Tratamiento inseguro de la salida

El riesgo que un pentester web entiende de inmediato: **la salida del LLM es entrada no confiable** para lo que venga después.

Si el modelo genera HTML que se inserta sin escapar → XSS. Si genera SQL que se ejecuta → inyección SQL. Si genera comandos que llegan a un intérprete → RCE.

El ejemplo del propio OWASP lo ilustra: una aplicación que pide al modelo traducir peticiones en lenguaje natural a consultas SQL. Ante `dame el contenido del post #3`, el modelo produce `SELECT content FROM blog WHERE id=3` y el backend lo ejecuta. <mark style="background: #8000E1A6;">Si el atacante consigue que el modelo genere `DROP TABLE blog`, no hay ninguna inyección clásica de por medio: el sistema ejecuta exactamente lo que su LLM le dijo.</mark>

Mitigación: consultas parametrizadas —que el modelo elija la plantilla y los parámetros, no que escriba SQL libre—, validación de sintaxis y semántica de la salida, y permisos de solo lectura en la conexión.

## LLM06 · Agencia excesiva

Mínimo privilegio aplicado al modelo. Si tiene acceso a una base de datos con permisos de escritura cuando solo necesita leer, una inyección exitosa pasa de fuga a destrucción de datos.

Tres dimensiones a acotar: **funcionalidad** (solo las herramientas necesarias), **permisos** (los mínimos en cada una) y **autonomía** (¿qué acciones exigen aprobación humana?). <mark style="background: #FF5582A6;">Es el control más eficaz del catálogo</mark>, precisamente porque asume que la inyección va a ocurrir y limita lo que puede conseguir.

## LLM07 · Fuga del prompt de sistema

El `system prompt` define el rol, las restricciones y a menudo detalles de las herramientas disponibles. Extraerlo —normalmente mediante `LLM01`— revela qué puede hacer el modelo, qué se le ha prohibido y cómo está formulado.

<mark style="background: #FFB8EBA6;">Es habitualmente el primer paso de un ataque a una aplicación LLM</mark>: convierte una caja negra en un objetivo con mapa. Y hay que separar dos problemas: que el prompt se filtre es una cosa; que el prompt **contenga secretos** (claves, endpoints internos, credenciales) es otra mucho peor, y es un error de diseño, no una vulnerabilidad del modelo.

## LLM08 · Debilidades en vectores y embeddings

Específico de RAG. La base vectorial es un almacén de datos y sufre problemas de almacén de datos: control de acceso, aislamiento entre inquilinos, integridad del contenido indexado.

Dos escenarios destacados por OWASP:
- **Fuga entre inquilinos** — en un despliegue multi-tenant con base vectorial compartida, los embeddings de un grupo pueden recuperarse al responder a la consulta de otro.
- **Envenenamiento del índice** — quien pueda escribir en la fuente indexada inyecta contenido que se recuperará y entrará en el contexto. Es el canal principal de `prompt injection` indirecta.

Y un matiz de privacidad que se pasa por alto: **los embeddings no son datos anónimos**. Existen técnicas de inversión que reconstruyen aproximadamente el texto original a partir del vector, así que una base vectorial expuesta filtra el contenido que indexa.

## LLM09 · Desinformación

Las `hallucinations`: respuestas falsas con apariencia de certeza, incluidas fuentes inventadas. El riesgo de seguridad aparece con la **sobreconfianza**: código generado con fallos que nadie revisa, decisiones tomadas sobre información fabricada.

Un caso con impacto directo en seguridad es la **alucinación de dependencias**: el modelo sugiere un paquete que no existe. Si el patrón es reproducible, un atacante puede registrar ese nombre en el repositorio público y esperar a que alguien instale la sugerencia — confusión de dependencias servida por el propio asistente.

## LLM10 · Consumo no acotado

Entradas que disparan el consumo. Tres impactos distintos: **denegación de servicio** por agotamiento de recursos, **daño económico** cuando se paga por uso, y **extracción del modelo** mediante consultas masivas (el `ML05` visto desde el otro lado).

Como el comportamiento del modelo no es determinista, no se puede prevenir con una lista negra de consultas: la contramedida es límites de tasa y de tokens, cuotas por cliente y monitorización del consumo.

# Lo que falta: agentes

> [!important]+ OWASP Top 10 for Agentic Applications 2026
> La lista de LLM cubre aplicaciones donde el modelo **responde**. En 2025-2026 el despliegue dominante es el agente: modelo con herramientas, memoria persistente y autonomía para encadenar pasos. Esa arquitectura introduce riesgos que la lista de LLM no captura, y OWASP publicó en **diciembre de 2025** el [Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) dentro del `GenAI Security Project`.
>
> Los riesgos que añade y que conviene tener en el radar en cualquier evaluación de un sistema agéntico:
> - **Secuestro de objetivos** del agente.
> - **Abuso de herramientas** — usar las capacidades legítimas para fines no previstos.
> - **Abuso de identidad y privilegios** — el agente actúa con credenciales que el atacante no tiene.
> - **Envenenamiento de memoria** — <mark style="background: #FFB86CA6;">corrupción **persistente** del contexto recuperable, que sobrevive entre sesiones y altera el razonamiento futuro</mark>. Es la diferencia cualitativa frente a una inyección puntual.
> - **Comunicación insegura entre agentes** y **explotación de la confianza** entre ellos.
> - **Fallos en cascada** — un error se propaga por la cadena de agentes.
> - **Agentes descontrolados** (`rogue agents`).
>
> Se apoya sobre `LLM01`, `LLM04` y `LLM08`, pero el eje es la **persistencia** y la **autonomía**. Si el sistema evaluado usa `MCP`, memoria entre sesiones o varios agentes coordinados, esta lista es más relevante que la de LLM.

## Fuentes

- [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/llm-top-10/) — lista vigente y definiciones (consultado 2026-07-28).
- [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) — publicado en diciembre de 2025 (consultado 2026-07-28).
- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con la distinción directa/indirecta en `LLM01`, las mitigaciones concretas por riesgo, la inversión de embeddings, la alucinación de dependencias y la lista agéntica de 2026, ausentes en el original.
