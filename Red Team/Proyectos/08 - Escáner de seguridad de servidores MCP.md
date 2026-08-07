---
tags:
  - Proyectos
  - Go
  - IA/Red-Team
  - IA/LLM
  - Tipo/Proyecto
Descripción: "Audita la postura de seguridad de un servidor MCP contra la spec vigente y el catálogo de ataques, de forma determinista y offline, con pinning de baseline contra rug-pull"
Fecha de actualización: 2026-08-04
Nota previa: "[[07 - Reconstructor de protocolos binarios]]"
Nota siguiente: "[[09 - Priorizador de superficie de ataque]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 4 semanas
---
---

**Nombre propuesto**: `mcphound`

Un servidor MCP es un servicio de red que le presta capacidades a un agente LLM —leer ficheros, consultar bases de datos, llamar APIs— y, como todo lo que se despliega a la carrera, llega a producción sin que nadie lo haya auditado. La diferencia con un servicio clásico es dónde vive su superficie de ataque: no en un puerto ni en un parámetro, sino en la <mark style="background: #ADCCFFA6;">descripción en lenguaje natural de cada herramienta, que el modelo lee y obedece antes de decidir qué llamar</mark>. Invariant Labs midió que el 5,5 % de los servidores MCP públicos ya llevan instrucciones ocultas en esa metadata.

# El problema que resuelve

MCP pasó de propuesta a estándar de facto en año y medio, y la seguridad va por detrás de la adopción. El pentester que se encuentra un despliegue con agentes no tiene una herramienta que trate al servidor MCP como lo que es: un servicio con su superficie propia, su autorización propia y sus clases de fallo propias. Y hay un agravante temporal: <mark style="background: #FFB86CA6;">la spec de MCP se reescribió a fondo hacia un modelo *stateless*, de modo que buena parte de las guías y del tooling existente audita un protocolo que ya no existe</mark> —el *handshake* que enseñan muchas fuentes fue eliminado—.

# Alcance del proyecto

Un escáner que se conecta a un servidor MCP (o analiza su definición exportada) y evalúa su postura contra la spec vigente y el catálogo de ataques conocidos. Dos principios de diseño lo separan de lo que hay: **determinista** —la heurística no depende de que un LLM tenga el día bueno— y **offline por defecto** —<mark style="background: #FF5582A6;">las herramientas y descripciones de un servidor del cliente son información sensible y no se mandan al servicio de un tercero para que las juzgue</mark>—.

Módulos de auditoría:

- **Reconocimiento.** Enumera *tools*, *resources* y *prompts*; identifica transporte, versión de spec declarada y grado de conformidad. Es la foto de partida que hoy se hace a mano.
- **Tool poisoning.** Analiza cada descripción buscando instrucciones dirigidas al modelo: delimitadores de rol, imperativos ocultos, contenido invisible (caracteres de ancho cero, homoglifos, texto fuera de viewport) y referencias cruzadas a otras herramientas. Heurística determinista primero; juicio por LLM como capa **opcional** y claramente marcada.
- **Pinning contra rug-pull.** Mantiene un *baseline* firmado de las definiciones aprobadas y alerta si cambian entre sesiones. <mark style="background: #8000E1A6;">Es la única defensa real contra el rug-pull, que por naturaleza es temporal</mark>: el servidor se comporta durante la aprobación y muta su herramienta después.
- **Tool shadowing.** Detecta colisiones de nombre entre servidores del mismo cliente, donde un servidor malicioso secuestra la invocación destinada a otro legítimo.
- **Autorización.** Revisa el flujo OAuth: *token passthrough* (que la spec prohíbe expresamente), *confused deputy*, `redirect_uri` laxas y audiencia del token. Es la parte que más se salta el análisis centrado solo en el texto de las descripciones.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Conformidad con la spec *stateless* | Un escáner atado a la versión vieja da un veredicto falso. La conformidad se comprueba contra la spec vigente, y la versión soportada se declara |
| Heurística determinista de descripciones | Reproducible en CI y auditable: cada alerta dice qué patrón la disparó, no "un modelo pensó que era sospechoso" |
| Baseline firmado y diff entre pasadas | Convierte el rug-pull, invisible en una sola foto, en una diferencia detectable entre dos |
| Auditoría del flujo OAuth | Cubre la mitad de la superficie que el análisis de *tool poisoning* ignora |
| Operación offline | Usable durante un engagement sin exfiltrar las herramientas del cliente a una API externa |
| Salida priorizada con razones | Puntuación por hallazgo con su justificación; el operador decide, la herramienta no veta |

# Qué existe ya y dónde se queda corto

- **MCP-Scan** (Invariant Labs) es la referencia: conecta a servidores y busca *tool poisoning*, *cross-origin escalation* y *rug pull*, combinando detección por palabras clave, análisis semántico y evaluación por LLM. Está pensado como **guardián en tiempo de ejecución**, y su capa de LLM implica mandar contenido fuera.
- **MCP-Scanner** (eSentire Labs, presentado en un *workshop* ACM/IEEE 2026) es otra implementación *open source* del mismo nicho.

Ambos resuelven bien el *tool poisoning* y encajan como control *runtime*. <mark style="background: #FFB8EBA6;">El hueco es el auditor de postura para el pentester</mark>: determinista, offline, con *pinning* de estado real entre sesiones y con cobertura de OAuth y conformidad de spec, empaquetado en un binario único que corre en la red del cliente sin instalar un intérprete. El marco emergente **OWASP MCP Top 10** da la taxonomía para ordenar los hallazgos.

# Cosas a tener en cuenta

> [!warning]+ Tu juez es atacable
> Si añades la capa de LLM que evalúa las descripciones, recuerda que el contenido que le das a juzgar es precisamente contenido diseñado para inyectar instrucciones a un modelo. <mark style="background: #FF5582A6;">Un *tool poisoning* bien hecho puede atacar a tu propio escáner cuando este le pide al LLM que lo analice</mark>. La capa determinista tiene que ser la primaria; el LLM, una segunda opinión aislada y con el contenido tratado como dato, nunca como instrucción.

- **La spec es un blanco móvil.** Atarse a una versión concreta caduca rápido. La conformidad debe estar parametrizada por versión y la herramienta declarar cuál soporta, igual que el `mirror` (02) versiona sus perfiles de navegador.
- **El rug-pull no se ve sin estado.** Cualquier escáner de una sola pasada es ciego a él por construcción. El valor está en el *diff* firmado, y eso obliga a persistir el *baseline* con la misma disciplina de custodia que el resto de artefactos del engagement.
- **Falsos positivos garantizados.** Una herramienta legítima que gestiona correo describe "leer y reenviar mensajes", y eso se parece a un cebo de exfiltración. Por eso la salida es puntuación con razones, no lista negra: distinguir capacidad legítima de instrucción maliciosa es criterio del operador.
- **Doble uso limpio.** El mismo escáner sirve al equipo azul para validar su *marketplace* interno de MCP antes de aprobarlo. Es lo que lo hace vendible en un ejercicio *purple* y no solo ofensivo.

# Fuera de alcance

No es un guardián en tiempo de ejecución ni un proxy que se interponga en producción: audita, reporta y se aparta. No implementa el agente ni el cliente MCP más allá de lo necesario para hablar con el servidor. No explota los hallazgos: los documenta.

# Criterio de terminado

Cuando, contra un servidor con *tool poisoning* conocido (los del repo `mcp-injection-experiments` sirven de verdad-terreno), lo detecta y explica qué patrón; cuando una definición cambiada entre dos pasadas dispara la alerta de rug-pull; y cuando un flujo OAuth con *token passthrough* queda marcado con la referencia a la cláusula de la spec que incumple.

# Conexiones en el vault

El punto de partida conceptual es [[00 - Qué es MCP y por qué cambia la superficie de ataque]]; la fase de enumeración que el escáner automatiza, [[03 - Reconocimiento de servidores MCP]]. Cada módulo mapea a una nota: [[06 - Tool poisoning y prompt injection vía descripción]], [[07 - Rug pull y tool shadowing]] y [[08 - Seguridad de la autorización OAuth en MCP]]. El catálogo de fallos reales que sirve de verdad-terreno está en [[09 - CVEs y ataques reales de MCP]], y las herramientas con las que convive, en [[12 - Arsenal de herramientas para MCP]]. La capa de LLM-judge hereda todos los riesgos de [[01 - Prompt injection y por qué no tiene parche]].

> [!info]+ Fuentes
> - Invariant Labs, [*MCP Security Notification — Tool Poisoning Attacks*](https://invariantlabs.ai/blog/mcp-security-notification-tool-poisoning-attacks) — la superficie de las descripciones y el 5,5 % de servidores públicos afectados (consultado 2026-08-04).
> - Invariant Labs, [*Introducing MCP-Scan*](https://invariantlabs.ai/blog/introducing-mcp-scan) — el estado del arte del que parte, y su enfoque *runtime* con LLM-judge.
> - eSentire Labs, [`mcp-scanner`](https://github.com/eSentire-Labs/mcp-scanner) — implementación *open source* alternativa (ACM/IEEE, 2026).
> - [`invariantlabs-ai/mcp-injection-experiments`](https://github.com/invariantlabs-ai/mcp-injection-experiments) — PoCs reproducibles de *tool poisoning*, verdad-terreno para el criterio de terminado.
> - [Especificación de MCP](https://modelcontextprotocol.io/specification) — la referencia de conformidad; verificar siempre la versión vigente.
