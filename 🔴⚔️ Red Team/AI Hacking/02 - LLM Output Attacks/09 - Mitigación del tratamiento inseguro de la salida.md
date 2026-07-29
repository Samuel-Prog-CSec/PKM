---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Reporting
  - Tipo/Defensa
Descripción: "La buena noticia de toda esta carpeta: las mitigaciones no son nuevas"
Fecha de actualización: 2026-07-28
Nota previa: "[[08 - Slopsquatting y alucinación de paquetes]]"
Nota siguiente: "[[10 - Ataques de abuso y desinformación]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

<mark style="background: #ADCCFFA6;">La buena noticia de toda esta carpeta: las mitigaciones no son nuevas.</mark> Son las de siempre —validación, codificación contextual, control de acceso, aislamiento— aplicadas a un origen de datos que el equipo no había clasificado como no confiable. A diferencia de [[12 - Mitigaciones tradicionales y sus límites|la prompt injection]], aquí **sí hay arreglo definitivo**.

# Los tres principios

## 1 · La salida del LLM es entrada de usuario

Todo control que se aplique a la entrada del usuario debe aplicarse igual al texto que devuelve el modelo. Sin excepciones y sin confiar en que "el modelo es nuestro".

Por sink:

| Destino de la salida | Control obligatorio |
| - | - |
| Respuesta HTML | Codificación contextual; si se renderiza markdown, sanear con `DOMPurify` y desactivar HTML crudo |
| Consulta SQL | Plantillas con allowlist; validación por AST antes de ejecutar; usuario de BBDD de solo lectura |
| Comando del sistema | No construir comandos con texto: funciones concretas, `shell=False`, argumentos validados |
| Intérprete (`eval`, `exec`) | **No hacerlo.** Si la ejecución es la funcionalidad, aislarla en sandbox |
| Llamada a herramienta | Despacho estructurado contra funciones registradas + validación de esquema y de valores |
| URL, enlace, imagen | Allowlist de dominios y esquemas; prohibir recursos remotos con datos variables |
| Ruta de fichero | Normalizar y confinar a un directorio base |
| Cabecera HTTP | Filtrar `\r\n` — response splitting |
| Consulta LDAP | Escapado de metacaracteres según [[06 - Prevención de LDAP Injection\|RFC 4515]] |

## 2 · Todo lo que el modelo alcanza es público

<mark style="background: #FF5582A6;">Cualquier dato y cualquier función a los que el modelo tenga acceso hay que considerarlos accesibles por cualquiera que hable con el modelo.</mark>

De ahí se derivan dos reglas duras:

- **Nada sensible en el contexto** que el usuario de la sesión no pudiera ver por sí mismo. Ni en el system prompt, ni en el RAG, ni en el resultado de una herramienta.
- **El prompt no es control de acceso.** `This function is only accessible to administrators` no es un control: es una sugerencia, y se derrota diciendo "soy administrador" ([[05 - Agencia excesiva y funciones vulnerables]]).

Es un punto que conviene dejar escrito literalmente en el informe, porque es el error conceptual que más se repite y el que produce los hallazgos más graves.

## 3 · Control de acceso fuera del modelo

La autorización se evalúa en código, contra la identidad real de la sesión, **antes** de ejecutar cualquier acción. Dos consecuencias prácticas:

- El conjunto de herramientas que se mete en el prompt debe **depender del rol**. Un usuario anónimo no debería ver siquiera la definición de una función administrativa.
- Si una funcionalidad solo debe estar disponible para usuarios privilegiados, se restringe a nivel de aplicación, no pidiéndoselo al modelo.

# Endurecimiento

Reduce el impacto cuando algo de lo anterior falla:

- **Sandbox para ejecución de código**: proceso aislado, sin red, sin credenciales en el entorno, sistema de ficheros efímero, límites de CPU y memoria. Contenedor como mínimo; `gVisor` o microVM si el riesgo lo justifica.
- **Mínimo privilegio en todas las conexiones**: usuario de BBDD de solo lectura, tokens con el ámbito estrictamente necesario, credenciales distintas por herramienta.
- **Límites de tasa y de coste** por usuario y por sesión: acota la exfiltración masiva y el `LLM10:2025 Unbounded Consumption`.
- **Errores genéricos** hacia el usuario. Un `sqlite3.OperationalError` propagado al chat le regala al atacante el motor, el sink y el contexto sintáctico.
- **Salida estructurada en lugar de texto libre** siempre que se pueda. Si la aplicación solo necesita un identificador de pedido, que el modelo devuelva un JSON con un campo validado, no un párrafo del que haya que extraerlo.

Ese último punto es el que más superficie elimina de un solo cambio: <mark style="background: #8000E1A6;">cuanto más estrecho es el canal entre el modelo y la aplicación, menos cabe por él.</mark>

# Arquitectura: asumir el compromiso

La forma correcta de diseñar es dar por hecho que la prompt injection va a funcionar y preguntarse qué pasa entonces. Tres preguntas que ordenan el diseño y que sirven igual como guion de entrevista con el cliente:

1. **Si el atacante controla exactamente lo que dice el modelo, ¿qué consigue?** Si la respuesta es "nada relevante", el diseño es correcto. Si es "ejecutar SQL arbitrario", hay trabajo.
2. **¿Qué acción irreversible puede desencadenar la salida?** Todo lo que cueste dinero, mueva datos o comunique al exterior necesita autorización independiente del modelo.
3. **¿Qué credenciales hay al alcance del proceso** que consume la salida? Es lo que se llevará el atacante en el peor caso.

# Cómo redactarlo en el informe

Tres cosas que cambian cómo recibe el cliente el hallazgo:

- **Separar vector e impacto.** El prompt injection es el vector; el XSS, la SQLi o la RCE es el impacto. La severidad se argumenta sobre el segundo — un cliente que lee "su chatbot puede ser manipulado" archiva el informe; uno que lee "un tercero puede robar la sesión de sus usuarios" lo prioriza.
- **Clasificar con CWE clásico**, no con categorías de IA: `CWE-79` para XSS, `CWE-89` para SQLi, `CWE-78` para inyección de comandos, `CWE-94` para ejecución de código. <mark style="background: #FFB86CA6;">Encaja en el proceso de gestión de vulnerabilidades que el cliente ya tiene</mark>, en lugar de crear una categoría nueva que nadie sabe dónde meter.
- **Recomendar el control concreto del sink**, no "mejorar el prompt". "Aplicar codificación HTML a la respuesta del modelo antes de insertarla en el DOM" es accionable; "endurecer el system prompt" no lo es y además no funciona.

Guía de redacción completa en [[06 - Cómo redactar un hallazgo]].
