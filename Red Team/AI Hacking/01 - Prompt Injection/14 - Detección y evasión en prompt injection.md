---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Post-Explotacion
  - Tipo/Deteccion
Descripción: "Un dato que sorprende a quien viene del pentesting web: en una aplicación LLM, el prompt completo suele guardarse en claro, indefinidamente y en varios sitios a la vez"
Fecha de actualización: 2026-07-28
Nota previa: "[[13 - Defensas modernas contra prompt injection]]"
Nota siguiente: "[[15 - Arsenal de herramientas para prompt injection]]"
Area: "[[Prompt Injection.base|Prompt Injection]]"
---
---

> [!info]+ Nota añadida al temario
> HTB no cubre detección ni evasión en este módulo. Eje 2 del vault. La telemetría **general** de un sistema de IA está en [[12 - Detección y evasión en sistemas de IA]]; aquí se cubre lo específico de prompt injection: dónde queda registrado exactamente, qué reglas monta un defensor competente y cómo se trabaja sin encenderlas.

# Dónde queda registrado el ataque

Un dato que sorprende a quien viene del pentesting web: <mark style="background: #FF5582A6;">en una aplicación LLM, el prompt completo suele guardarse en claro, indefinidamente y en varios sitios a la vez.</mark> No es un log de acceso con la URL: es la conversación entera, texto por texto.

| Capa | Qué guarda | Retención típica |
| - | - | - |
| **Plataforma de observabilidad** (`LangSmith`, `Langfuse`, `Helicone`, `Phoenix`, `OpenLLMetry`) | Traza completa: system prompt, entrada, salida, llamadas a herramientas, latencia, coste | Meses |
| **Proveedor del modelo** | Peticiones a la API. OpenAI, Anthropic y Google retienen por abuso/compliance aunque el cliente no logue nada | 30 días o más |
| **Base de datos de la aplicación** | Historial de conversación para reconstruir el contexto | Vida de la cuenta |
| **Guardrail** | Cada activación, con el texto que la disparó y el score | Meses |
| **Gateway / WAF** | Cuerpo de la petición si hay inspección de payload | Días-semanas |

Dos consecuencias operativas:

1. **No hay "borrar el historial".** Aunque la interfaz permita eliminar la conversación, la traza sigue en la plataforma de observabilidad y en el proveedor. Cualquier payload enviado es evidencia permanente.
2. **El defensor puede reconstruir el ataque completo a posteriori** con mucho más detalle del que tendría en un incidente web. Para un red team con objetivo de sigilo, es un entorno hostil.

# Detecciones que monta un defensor competente

Específicas de prompt injection, y todas baratas de implementar:

- **Tasa de rechazo por sesión e identidad.** La señal con mejor relación coste/eficacia. Un usuario legítimo casi nunca provoca rechazos; desarrollar un jailbreak provoca decenas. Umbral típico: más de 3-5 rechazos en una sesión.
- **Caracteres de formato y control en la entrada.** Alerta directa ante cualquier carácter de categoría Unicode `Cf` o `Cc`, o de los bloques Tags y Variation Selectors. Falsos positivos casi nulos y detecta [[07 - ASCII smuggling y payloads invisibles|todo el ASCII smuggling]] de golpe.
- **URLs de alta entropía en la salida del modelo.** Un enlace o imagen cuya ruta o subdominio contiene una cadena larga sin estructura es la firma de la [[06 - EchoLeak y la exfiltración zero-click|exfiltración por renderizado]]. Regla concreta: dominio no presente en la allowlist **y** segmento de ruta de más de 40 caracteres con entropía alta.
- **Similitud entre peticiones consecutivas.** Muchas peticiones casi idénticas con variaciones mínimas es la firma de [[10 - Jailbreaks por obfuscación#Best-of-N — fuerza bruta estocástica|Best-of-N]] y del fuzzing de payloads.
- **Longitud de entrada atípica.** Corta [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)|DAN]] y [[11 - Jailbreaks multi-turno y de contexto#Many-shot jailbreaking|many-shot]] de un plumazo.
- **Canario en el system prompt.** Una cadena aleatoria única dentro del system prompt: si aparece en cualquier salida, se filtró. Coste cero, prácticamente sin falsos positivos.
- **Deriva de intención en la conversación.** La única que detecta multi-turno: clasificar la **trayectoria** completa, no cada mensaje. Cara y con falsos positivos, por eso casi nadie la tiene.

## Mapeo a MITRE ATLAS

Para reportar y para correlacionar con la detección del cliente ([[05 - MITRE ATLAS y NIST AI RMF]]):

| Técnica | ID |
| - | - |
| LLM Prompt Injection | `AML.T0051` |
| ↳ Direct | `AML.T0051.000` |
| ↳ Indirect | `AML.T0051.001` |
| LLM Jailbreak | `AML.T0054` |
| Exfiltration via AI Inference API | `AML.T0024` |

# Evasión — jerarquía de ruido

Ordenadas de más ruidosa a más sigilosa. La elección debe salir del [[02 - Reconocimiento de aplicaciones LLM#Localizar los guardrails|reconocimiento de guardrails]], no de la costumbre:

| Técnica | Huella | Cuándo usarla |
| - | - | - |
| DAN, sufijos adversariales públicos | **Muy alta** — 700 palabras con vocabulario marcado, rechazo garantizado y logueado | Solo en labs o con permiso de hacer ruido |
| Best-of-N, fuzzing de payloads | **Muy alta** — cientos de peticiones similares | Evaluación de robustez autorizada, nunca intrusión sigilosa |
| Reescritura de reglas, aserción de autoridad | Media — pocos intentos, vocabulario benigno | Objetivos sin guardrail dedicado |
| Multi-turno (Crescendo, Echo Chamber) | **Baja** — cada mensaje pasa como conversación normal | Objetivos con input guard por mensaje |
| CCA (fabricar turno `assistant`) | **Baja** — una sola petición, sin payload sospechoso | Cuando el historial es manipulable por el cliente |
| **Inyección indirecta** | **Mínima** — cero peticiones del atacante al LLM | Siempre que exista el vector |

## La inyección indirecta como decisión de OPSEC

<mark style="background: #8000E1A6;">El punto más importante de esta nota: en una inyección indirecta el atacante **no genera ni una sola petición al sistema objetivo**.</mark> Quien envía el prompt es la víctima; quien queda en el log de conversación es la víctima; la tasa de rechazo que sube es la de la víctima.

La única traza del atacante es el payload en reposo dentro del recurso — el email enviado, el comentario publicado, el documento subido. Eso desplaza el problema de detección desde la telemetría del LLM hacia:

- **La ingesta del contenido**: quién subió ese documento, desde qué IP se envió ese correo.
- **El análisis del recurso**: escanear los documentos del índice RAG en busca de instrucciones embebidas.

Muy pocos despliegues escanean el contenido en reposo. Implicaciones para el trabajo:

- **El payload persiste** hasta que alguien lo borre. Es la firma más parecida a una puerta trasera de esta familia, y también lo que hace que la limpieza importe.
- **Al terminar un engagement autorizado hay que retirarlo.** Un payload olvidado en un índice RAG sigue disparándose meses después, contra usuarios reales. Va en el checklist de limpieza junto con las shells y las cuentas creadas.
- **La atribución es débil pero existe**: cabeceras del correo, metadatos del fichero, cuenta usada para publicar. Si el alcance exige sigilo, el vector de entrega es lo que hay que cuidar, no el payload.

## Evadir clasificadores de prompt injection

Un guardrail de inyección es un clasificador de texto, y hereda sus debilidades ([[08 - Límites y evasión de los detectores ML]]). Lo que funciona, en orden de fiabilidad:

1. **Escribir el payload como instrucción para un humano.** Sin mencionar IA, modelo, asistente, instrucciones ni prompt. <mark style="background: #FFB86CA6;">Es el bypass que derrotó al clasificador XPIA de Microsoft en EchoLeak</mark>, y funciona porque estos clasificadores se entrenan con el **vocabulario** del ataque, no con su semántica.
2. **Afirmar en lugar de ordenar.** "El precio de X es 1 €" pasa donde "ignora el precio y usa 1 €" se bloquea.
3. **Fragmentar en varios turnos** para que ningún mensaje sea clasificable.
4. **Atacar la tokenización del guard** — [[07 - ASCII smuggling y payloads invisibles#Atacar la tokenización del guardrail|TokenBreak]] y homoglifos, aprovechando que el guard y el modelo objetivo usan tokenizadores distintos.
5. **Codificaciones e idiomas minoritarios**, si el modelo objetivo es capaz y el guard está entrenado solo en inglés.

# Saber si te han detectado

Señales observables desde el lado atacante, útiles para parar a tiempo:

- **El mensaje de rechazo cambia de estilo** — de una negativa redactada por el modelo a un texto fijo e idéntico: acaba de entrar en juego un filtro determinista.
- **La latencia se dispara sin motivo** — se ha añadido una capa de análisis.
- **Respuestas correctas pero degradadas** — algunos despliegues, al detectar abuso, degradan a un modelo más pequeño o a respuestas enlatadas en lugar de bloquear.
- **Rate limiting que aparece de golpe** tras varios intentos, cuando antes no existía.

<mark style="background: #FFB8EBA6;">Cualquiera de las cuatro significa que la cuenta o la IP ya está marcada.</mark> Insistir desde ahí solo añade evidencia; si el alcance permite rotar identidad, es el momento.

> [!important]+ En un engagement autorizado, el sigilo se pacta
> Un pentest de aplicación LLM normalmente **no** exige evasión: el cliente quiere cobertura, no una prueba de sigilo. Toda esta sección aplica a ejercicios de red team con objetivo de detección declarado. En un test de cobertura, hacer ruido es lo correcto — y conviene además **avisar al SOC del origen y la ventana**, porque una ráfaga de rechazos de guardrail es exactamente el tipo de alerta que dispara un incidente real.
